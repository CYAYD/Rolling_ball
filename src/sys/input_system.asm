INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"

SECTION "Input System", ROM0

process_spawns::
	;; Check if any spawn requested
	ld hl, ball_want_buttons
	ld a, [hl]
	and a
	cp 0
	jr z, .no_spawn_requests

	;; if requested, check debounce and spawn for each requested button
	;; only spawn once per press using ball_a_last as debounce for A/B combined
	ld hl, ball_a_last
	ld a, [hl]
	cp 0
	jr nz, .clear_want_and_return

	;; find player position (use current sprite components after physics update)
	ld hl, components_info    ;; hl points to info array
	ld de, components_sprite  ;; de points to sprite array (parallel)
	ld b, MAX_ENTITIES        ;; use b as counter

.find_player_loop2:
	inc hl
	ld a, [hl]
	cp TAG_PLAYER
	jr z, .found_player2
	dec hl
	ld bc, SIZEOF_CMP
	add hl, bc
	;; advance de by SIZEOF_CMP
	inc de
	inc de
	inc de
	inc de
	dec b
	jr nz, .find_player_loop2

	;; fallback
	ld de, components_sprite

.found_player2:
	ld a, [de]
	ld b, a
	inc de
	ld a, [de]
	ld c, a

	;; copy ROM template sc_ball_entity -> temp_entity (12 bytes)
	ld hl, sc_ball_entity
	ld de, temp_entity
	ld b, 12
	call memcpy_256

	;; compute hl = temp_entity + 4 (sprite Y/X)
	ld hl, temp_entity
	ld bc, 4
	add hl, bc

	;; write spawned sprite Y = player_y - 16
	ld a, b
	sub $10
	ld [hl], a
	inc hl
	;; write spawned sprite X = player_x + 4
	ld a, c
	add $04
	ld [hl], a

	;; patch physics at temp_entity + 8
	ld hl, temp_entity
	ld bc, 8
	add hl, bc
	ld a, -2
	ld [hl], a
	inc hl
	xor a
	ld [hl], a

	;; create entity from temp_entity
	ld hl, temp_entity
	call create_one_entity

	;; set debounce flag: write 1 into WRAM byte ball_a_last
	ld hl, ball_a_last
	ld a, 1
	ld [hl], a

.clear_want_and_return:
	;; clear request flags
	ld hl, ball_want_buttons
	xor a
	ld [hl], a

.no_spawn_requests:
	ret

	
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


	;; Read buttons group for A: select buttons by writing 0x10
	ld a, %00010000    ; 0x10 = select buttons (P15)
	ld [rP1], a
	ld a, [rP1]
	cpl
	and %00001111
	ld c, a    ;; c = buttons pressed mask (bit0=A, bit1=B,...)

	;; Rising edge detection: c <- (curr & ~prev)
	ld hl, prev_buttons
	ld a, [hl]    ;; a = prev
	ld b, a       ;; b = prev

	ld a, c       ;; a = curr
	ld e, a

	ld a, b       ;; a = prev
	cpl            ;; a = ~prev
	and e         ;; a = (~prev) & curr  = rising
	ld c, a       ;; c = rising edges mask

	;; store current buttons into prev_buttons
	ld hl, prev_buttons
	ld a, e
	ld [hl], a
	;; Check buttons group explicitly: only A or B should spawn the ball.
	;; Prevent spawning if any direction is pressed (require d == 0)
	;; c currently holds the buttons mask (bit0=A, bit1=B,...)
	;; d holds the directions mask (bit0=Right,...)
	ld a, d
	cp 0
	jr nz, .clear_debounce_and_return    ;; if any direction pressed, don't spawn

	ld a, c
	and P1_BTN_A
	jr nz, .button_pressed    ;; A pressed
	ld a, c
	and P1_BTN_B
	jr z, .clear_debounce_and_return     ;; neither A nor B pressed -> no spawn

.button_pressed:
	;; Button just requested spawn: set flag in WRAM and return
	;; set bit0 if A, bit1 if B
	ld hl, ball_want_buttons
	ld a, [hl]
	;; set bit0 (A) or bit1 (B) depending on c
	ld a, c
	and P1_BTN_A
	jr z, .check_b
	;; set A bit
	ld hl, ball_want_buttons
	ld a, [hl]
	or %00000001
	ld [hl], a
	jr .end_input
.check_b:
	ld a, c
	and P1_BTN_B
	jr z, .end_input
	ld hl, ball_want_buttons
	ld a, [hl]
	or %00000010
	ld [hl], a

.clear_debounce_and_return:
	;; clear debounce flag when no button/direction condition holds
	ld hl, ball_a_last
	xor a
	ld [hl], a

	ret

.end_input:
	ret