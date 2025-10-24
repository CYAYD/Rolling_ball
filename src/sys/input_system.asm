INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"

SECTION "Input System", ROM0

process_spawns::
	;; Every SPAWN_BURST_SECONDS seconds, spawn SPAWN_BURST_COUNT balls
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

	;; time to spawn a burst of SPAWN_BURST_COUNT balls
	xor a
	ld [hl], a        ; reset seconds to 0
	ld b, SPAWN_BURST_COUNT
.burst_loop:
	push bc
	call spawn_ball_random
	pop bc
	dec b
	jr nz, .burst_loop

.no_burst:
	ret


;; spawn_ball_random: create a ball entity at a random X (0..152)
spawn_ball_random::
	;; use GA-style rand8 (LFSR) to get random byte
	call rand8

	;; derive X from lower 7 bits and clamp to 0..152
	and %01111111            ; 0..127
	cp 152
	jr c, .ok_x              ; if a < 152 keep it
	ld a, 152
.ok_x:
	ld e, a

	;; copy ROM template sc_ball_entity -> temp_entity (12 bytes)
	ld hl, sc_ball_entity
	ld de, temp_entity
	ld b, 12
	call memcpy_256

	;; patch sprite Y/X at temp_entity+4
	ld hl, temp_entity
	ld bc, 4
	add hl, bc
	ld [hl], 16    ;; visible near top of screen
	inc hl
	ld a, e
	ld [hl], a     ;; X

	;; patch physics at temp_entity + 8 (vy, vx)
	ld hl, temp_entity
	ld bc, 8
	add hl, bc
	ld a, 2
	ld [hl], a
	inc hl
	xor a
	ld [hl], a

	;; create entity
	ld hl, temp_entity
	call create_one_entity
	ret

read_input_and_apply::
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