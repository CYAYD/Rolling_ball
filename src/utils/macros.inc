MACRO SET_BGP
	ld a, \1
   	ld [rBGP], a
ENDM


MACRO SET_OBP1
	ld a, \1
   	ld [rOBP1], a
ENDM


MACRO MEMCPY_256
	ld hl, \1
   	ld de, \2
   	ld b, \3
   	call memcpy_256
ENDM
