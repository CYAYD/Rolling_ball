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

; Load DE with BG map address for row,col
; Usage: LD_DE_BG row, col
MACRO LD_DE_BG
    ld de, BG_MAP0 + ((\1) * BG_WIDTH) + (\2)
ENDM

; Copy an 8x8 glyph tile into VRAM tile memory for a given tile ID
; Usage: MEMCPY_GLYPH label, TID
MACRO MEMCPY_GLYPH
    MEMCPY_256 \1, VRAM_TILE_START + ((\2) * VRAM_TILE_SIZE), VRAM_TILE_SIZE
ENDM
