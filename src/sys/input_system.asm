INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"

SECTION "Input System", ROM0

process_spawns::
	; stop spawns if game over
	ld hl, game_over_flag
	ld a, [hl]
	cp 0
	ret nz
	;; (Independent special spawner removed) — special is now selected per-burst opposite to black
	;; Every SPAWN_BURST_SECONDS seconds, spawn SPAWN_BURST_COUNT balls
	;; Mix RNG each frame to avoid periodic repeats
	ld hl, rng_tick
	inc [hl]
	ld a, [hl]
	ld hl, ball_rand
	add [hl]
	ld [hl], a
	;; Increment frame counter
	ld hl, ball_burst_frame_count
	inc [hl]
	ld a, [hl]
	cp SPAWN_FPS_FRAMES
	jr nz, .no_burst

	;; one second passed
	xor a
	ld [hl], a        ; reset frame counter to 0
	ld hl, ball_burst_seconds
	inc [hl]
	ld a, [hl]
	cp SPAWN_BURST_SECONDS
	jr nz, .no_burst

	;; time to spawn a burst, but cap by MAX_BALLS
	xor a
	ld [hl], a        ; reset seconds to 0
	; reset per-burst stagger accumulator (start with a base delay so the first ball also waits)
	ld hl, ball_burst_stagger
	ld a, STAGGER_BASE_FRAMES
	ld [hl], a
	; reset per-burst spawn index
	ld hl, ball_burst_spawn_idx
	xor a
	ld [hl], a
	; choose a random base index for this burst
	ld d, 0
	ld e, BALL_SPAWN_POS_COUNT-1
	call rand_range              ; A = base index
	ld hl, ball_burst_base_idx
	ld [hl], a
	; compute capacity = MAX_BALLS - current_ball_count
	ld a, TAG_BALL
	call man_count_by_tag
	ld c, a                 ; c = current balls
	ld a, MAX_BALLS
	sub c
	jr z, .no_burst         ; capacity == 0
	jr c, .no_burst         ; capacity < 0 (shouldn't happen with unsigned)
	; choose b = min(SPAWN_BURST_COUNT, capacity)
	ld b, SPAWN_BURST_COUNT
	cp b
	jr nc, .have_quota      ; if capacity >= SPAWN_BURST_COUNT, keep b
	ld b, a                 ; else b = capacity
.have_quota:
	; choose a fair index in [0..b-1] for the black ball in this burst (no repeats until all used)
	call black_select_begin    ; preserves B
	; choose the special index as the opposite of the black within this burst
	call special_select_prepare ; uses B (burst size) and black index to derive special index
.burst_loop:
	push bc
	call spawn_ball_random
	; paint black and special if this spawn index matches their chosen indices
	; increment stagger for next spawn in this burst
	ld hl, ball_burst_stagger
	ld a, [hl]
	add STAGGER_STEP_FRAMES
	cp STAGGER_MAX_FRAMES
	jr c, .st_no_cap
	ld a, STAGGER_MAX_FRAMES
.st_no_cap:
	ld [hl], a
	; increment per-burst spawn index
	ld hl, ball_burst_spawn_idx
	inc [hl]
	pop bc
	dec b
	jr nz, .burst_loop
	; end of burst

.no_burst:
	ret


;; spawn_ball_random: create a ball entity at a random X
spawn_ball_random::
	;; copy ROM template sc_ball_entity -> temp_entity (12 bytes)
	ld hl, sc_ball_entity
	ld de, temp_entity
	ld b, 12
	call memcpy_256

	;; patch sprite Y/X at temp_entity+4
	ld hl, temp_entity
	ld bc, 4
	add hl, bc
	ld [hl], SPAWN_Y_START    ;; visible near top of screen
	inc hl
	; Preserve pointer to X on the stack while we compute the index
	push hl
	; idx = (base_idx + spawn_idx * STRIDE) % COUNT
	ld hl, ball_burst_spawn_idx
	ld c, [hl]                   ; c = spawn_idx
	ld b, BALL_SPAWN_STRIDE
	xor a                        ; a = 0
.mul_loop:
	add c                        ; a += spawn_idx
	dec b
	jr nz, .mul_loop             ; a = spawn_idx * STRIDE
	ld hl, ball_burst_base_idx
	add [hl]                     ; a += base_idx
.mod_loop:
	cp BALL_SPAWN_POS_COUNT
	jr c, .have_idx
	sub BALL_SPAWN_POS_COUNT
	jr .mod_loop
.have_idx:
	; Load X from table and write it
	ld hl, ball_spawn_positions_x
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	pop hl                       ; restore pointer to X
	ld [hl], a                   ; write X

	; Create entity first, then paint black directly on components to avoid any copy issues

	;; patch physics at temp_entity + 8 (vy, vx)
	ld hl, temp_entity
	ld bc, 8
	add hl, bc
	ld a, 2
	ld [hl], a
	inc hl
	xor a
	ld [hl], a
	; write per-entity start delay into next byte (physics + CMP_PHYSICS_DELAY)
	inc hl
	ld a, [ball_burst_stagger]
	ld [hl], a

	;; create entity
	ld hl, temp_entity
	call create_one_entity
	; If this spawn is the chosen black or special, paint it now in components_sprite
	call black_maybe_paint_last_entity_black
	call special_maybe_paint_last_entity_special
	ret


read_input_and_apply::
	; If game is over, only listen for Start to restart the scene
	ld hl, game_over_flag
	ld a, [hl]
	cp 0
	jr z, .normal_input
	; Select buttons group (P15 low)
	ld a, P1_SELECT_BUTTONS    ; select buttons (A,B,Select,Start)
	ld [rP1], a
	ld a, [rP1]
	cpl
	and P1_BTN_START
	jr z, .end_input
	; Restart scene
	call sc_game_init
.end_input:
	ret

.normal_input:
	;; Read P1 register (note: Game Boy P1 has bits cleared when pressed; here
	;; we expect the hardware wired such that pressed bits will be 0. Depending
	;; on your platform you may need to invert. We'll read and invert to get 1=pressed.
	;; Read directions group: select directions by writing selector
	ld a, P1_SELECT_DPAD       ; select directions (P14 low)
	ld [rP1], a
	ld a, [rP1]
	cpl
	and P1_LOW_NIBBLE
	ld b, a
	ld d, a    ;; save directions mask in D so we don't lose it when reading player pos

	;; --- apply movement to player now (use D which holds directions mask)
	;; write player physics at components_physics (entity 0)
	ld hl, components_physics
	;; compute vy and vx: up = -1, down = +1, left = -1, right = +1
	ld a, 0
	ld c, a
	ld a, d
	bit 2, a
	jr z, .move_no_up
	ld c, -1
.move_no_up:
	ld a, d
	bit 3, a
	jr z, .move_no_down
	ld c, 1
.move_no_down:
	ld [hl], c
	inc hl
	ld a, 0
	ld c, a
	ld a, d
	bit 0, a
	jr z, .move_no_right
	ld c, 1
.move_no_right:
	ld a, d
	bit 1, a
	jr z, .move_no_left
	ld c, -1
.move_no_left:
	ld [hl], c
	
	ret