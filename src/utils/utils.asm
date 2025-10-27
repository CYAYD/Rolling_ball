INCLUDE "utils/constants.inc"

SECTION "Utils", ROM0


lcd_off::
	di
	call wait_vblank_start
	ld hl, rLCDC
	res rLCDC_LCD_ENABLE, [hl]
	ei
	ret

lcd_on::
	ld hl, rLCDC
	set rLCDC_LCD_ENABLE, [hl]
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VBLANK:
;;
;; DESTROYS: AF, HL
wait_vblank_start::
	ld hl, rLY
	ld a, VBLANK_START_LINE
	.loop:
	 cp [hl]
	jr nz, .loop
	ret

memcpy_256::
      ld a, [hl+]
      ld [de], a
      inc de
      dec b
   jr nz, memcpy_256
   ret

memset_256::
      ld [hl+], a
      dec b
   jr nz, memset_256
   ret

; Copia BC bytes desde HL → DE
memcpy_bc::
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, memcpy_bc
    ret

simulated_call_hl::
	jp hl

; -------------------------------------------------------
; rand8: 8-bit Galois LFSR RNG (inspired by GA-style utils)
; Uses ball_rand (WRAM) as seed/state
; Returns: A = next pseudo-random byte
; Clobbers: A, HL, B
rand8::
	ld hl, ball_rand
	ld a, [hl]
	ld b, a
	srl a                ; shift right, old bit0 in carry
	jr nc, .no_xor
	xor $B8              ; taps polynomial when LSB was 1
.no_xor:
	ld [hl], a
	ret

; -------------------------------------------------------
; mul8_high: high byte of 8-bit * 8-bit multiply
; In:  A = multiplicand, B = multiplier
; Out: A = high byte of (A*B)
; Clobbers: C, H, L
mul8_high::
	; In: A = multiplicand, B = multiplier
	; Out: A = high byte of (A*B)
	ld h, 0
	ld l, 0
	ld c, 8
.mul_loop:
	bit 0, a
	jr z, .no_add
	; HL += B
	ld e, l
	ld d, h
	ld a, e
	add a, b
	ld l, a
	ld a, d
	adc a, 0
	ld h, a
.no_add:
	; B <<= 1, A >>= 1
	sla b
	srl a
	dec c
	jr nz, .mul_loop
	ld a, h
	ret

; -------------------------------------------------------
; rand_range: returns a random integer in [min, max]
; In:  D = min, E = max
; Out: A = random value in range
; Clobbers: B
rand_range::
	; Compute n = (max - min + 1) in B
	ld a, e
	sub d
	inc a
	ld b, a
	ld c, b          ; save n in C (rand8 clobbers B)
	; Get random byte r in A
	call rand8
	ld b, c          ; restore n to B for multiply
	; Multiply high byte: (r * n) >> 8
	call mul8_high
	add a, d
	ret
