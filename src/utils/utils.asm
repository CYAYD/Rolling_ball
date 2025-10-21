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
