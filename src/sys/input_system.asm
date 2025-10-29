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
	call count_balls
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

;; spawn_special_ball_random: create a special ball (+200) at a random X
spawn_special_ball_random::
	;; copy ROM template sc_ball_entity -> temp_entity (12 bytes)
	ld hl, sc_ball_entity
	ld de, temp_entity
	ld b, 12
	call memcpy_256

	;; patch sprite Y/X at temp_entity+4
	ld hl, temp_entity
	ld bc, 4
	add hl, bc
	ld [hl], SPAWN_Y_START    ;; Spawn slightly off-screen so it falls in like las otras
	inc hl                    ;; HL -> X
	; choose random X in [SPAWN_X_MIN..SPAWN_X_MAX]
	ld d, SPAWN_X_MIN
	ld e, SPAWN_X_MAX
	call rand_range           ; A = random X
	ld [hl], a                ; write X

	; patch TID to special at temp_entity + 6
	inc hl                    ;; -> TID
	ld a, TID_BALL_SPECIAL
	ld [hl], a
	; set ATTR = 0 (use default OBJ0 palette) to ensure visibility while we validate graphics
	inc hl                    ;; -> ATTR
	xor a
	ld [hl], a

	;; patch physics at temp_entity + 8 (vy, vx)
	ld hl, temp_entity
	ld bc, 8
	add hl, bc
	ld a, 2
	ld [hl], a                ; vy = 2
	inc hl
	xor a
	ld [hl], a                ; vx = 0
	; write per-entity start delay = 0
	inc hl
	xor a
	ld [hl], a

	;; create entity
	ld hl, temp_entity
	call create_one_entity
	ret

read_input_and_apply::
	; If game is over, only listen for Start to restart the scene
	ld hl, game_over_flag
	ld a, [hl]
	cp 0
	jr z, .normal_input
	; Select buttons group (P15 low)
	ld a, %00010000    ; 0x10 = select buttons (A,B,Select,Start)
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
	;; Read directions group: select directions by writing 0x20
	ld a, %00100000    ; 0x20 = select directions (P14)
	ld [rP1], a
	ld a, [rP1]
	cpl
	and %00001111
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


	;; Button-based spawn removed; only movement handled here
	ret

;; convert_random_normal_ball_to_special: pick one normal ball (if any) and make it special
;; Uses two passes: count normals, choose random index k in [0..count-1], then apply
convert_random_normal_ball_to_special::
	; First pass: count normal balls (TAG_BALL with TID == TID_BALL)
	xor a
	ld c, a                  ; c = count
	ld e, 0
.crn_scan:
	ld h, CMP_INFO_H
	ld l, e
	ld a, [hl]
	and VALID_ENTITY
	cp VALID_ENTITY
	jr nz, .crn_next
	inc l                    ; info+1 = TAG
	ld a, [hl]
	cp TAG_BALL
	jr nz, .crn_next
	; check TID at sprite+2
	ld h, CMP_SPRITE_H
	ld l, e
	inc l
	inc l
	ld a, [hl]
	cp TID_BALL
	jr nz, .crn_next
	inc c
.crn_next:
	ld a, e
	add SIZEOF_CMP
	ld e, a
	cp SIZEOF_ARRAY_CMP
	jr nz, .crn_scan
	; if no normals, nothing to do
	ld a, c
	or a
	ret z
	; choose k in [0..c-1]
	dec a                    ; A = c-1
	ld d, 0
	ld e, a
	call rand_range          ; A = k
	ld b, a                  ; B = k (target index)
	; Second pass: find k-th normal and convert
	ld e, 0
.crn_scan2:
	ld h, CMP_INFO_H
	ld l, e
	ld a, [hl]
	and VALID_ENTITY
	cp VALID_ENTITY
	jr nz, .crn2_next
	inc l
	ld a, [hl]
	cp TAG_BALL
	jr nz, .crn2_next
	ld h, CMP_SPRITE_H
	ld l, e
	inc l
	inc l
	ld a, [hl]
	cp TID_BALL
	jr nz, .crn2_next
	; this is a normal ball: if B==0, convert it; else decrement B
	ld a, b
	or a
	jr nz, .crn2_dec
	; convert: set TID to special and ensure ATTR=0 (default palette)
	ld a, TID_BALL_SPECIAL
	ld [hl], a               ; write TID
	inc l                    ; -> ATTR
	xor a
	ld [hl], a
	ret
.crn2_dec:
	dec b
.crn2_next:
	ld a, e
	add SIZEOF_CMP
	ld e, a
	cp SIZEOF_ARRAY_CMP
	jr nz, .crn_scan2
	ret



;; count_balls: returns the number of active ball entities in A (by TAG)
count_balls::
	xor a
	ld c, a                 ; c = count
	ld e, 0
.cb_loop:
	; check VALID_ENTITY in components_info
	ld h, CMP_INFO_H
	ld l, e
	ld a, [hl]
	and VALID_ENTITY
	cp VALID_ENTITY
	jr nz, .cb_next
	; check TAG at offset +1
	ld h, CMP_INFO_H
	ld l, e
	inc l
	ld a, [hl]
	cp TAG_BALL
	jr nz, .cb_next
	inc c
.cb_next:
	ld a, e
	add SIZEOF_CMP
	ld e, a
	cp SIZEOF_ARRAY_CMP
	jr nz, .cb_loop
	ld a, c
	ret


;; normalize_all_balls_normal: set all balls' sprite TID to TID_BALL
normalize_all_balls_normal::
	ld e, 0
.norm_loop:
	; check VALID_ENTITY
	ld h, CMP_INFO_H
	ld l, e
	ld a, [hl]
	and VALID_ENTITY
	cp VALID_ENTITY
	jr nz, .norm_next
	; check TAG == BALL
	inc l
	ld a, [hl]
	cp TAG_BALL
	jr nz, .norm_next
	; write TID_BALL at components_sprite + 2
	ld h, CMP_SPRITE_H
	ld l, e
	inc l
	inc l
	ld a, TID_BALL
	ld [hl], a
.norm_next:
	ld a, e
	add SIZEOF_CMP
	ld e, a
	cp SIZEOF_ARRAY_CMP
	jr nz, .norm_loop
	ret

;; select_random_black_ball: ensure only one black ball by normalizing all,
;; then pick a random active ball and set its TID to TID_BALL_BLACK