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
