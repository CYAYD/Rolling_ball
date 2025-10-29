INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"

SECTION "Scene Game Over", ROM0

; --- GAME OVER flow ---
sc_game_over::
   ; set game over flag
   ld hl, game_over_flag
   ld a, 1
   ld [hl], a
   ; disable OBJ to hide any sprites immediately
   ld hl, rLCDC
   res rLCDC_OBJ_ENABLE, [hl]
   ; clear all component arrays and counters (WRAM)
   ld hl, components_info
   ld b, SIZEOF_ARRAY_CMP
   xor a
   call memset_256
   ld hl, components_sprite
   ld b, SIZEOF_ARRAY_CMP
   call memset_256
   ld hl, components_physics
   ld b, SIZEOF_ARRAY_CMP
   call memset_256
   ld hl, alive_entities
   xor a
   ld [hl], a
   ; Safely draw GAME OVER on BG with LCD off to allow VRAM writes
   call lcd_off
   call draw_game_over
   call lcd_on
   ret

; Draws "GAME OVER" and a two-line restart prompt centered-ish
; Depends on glyph tiles defined globally in sc_game.asm: tile_G/A/M/E/O/V/R and tile_P/S/T
; Uses tile $57 as a guaranteed blank/space tile

draw_game_over::
   ; Copy letter tiles to BG VRAM using named tile IDs
   MEMCPY_GLYPH tile_G, TID_G
   MEMCPY_GLYPH tile_A, TID_A
   MEMCPY_GLYPH tile_M, TID_M
   MEMCPY_GLYPH tile_E, TID_E
   MEMCPY_GLYPH tile_O, TID_O
   MEMCPY_GLYPH tile_V, TID_V
   MEMCPY_GLYPH tile_R, TID_R
   ; Also copy a guaranteed blank tile for space
   MEMCPY_GLYPH blank_tile, TID_SPACE
   ; Copy additional letters for prompt
   MEMCPY_GLYPH tile_P, TID_P
   MEMCPY_GLYPH tile_S, TID_S
   MEMCPY_GLYPH tile_T, TID_T

   ; Write "GAME OVER" centered-ish at configured row/col
   LD_DE_BG GAME_OVER_ROW, GAME_OVER_COL
   ld a, TID_G ; G
   ld [de], a
   inc de
   ld a, TID_A ; A
   ld [de], a
   inc de
   ld a, TID_M ; M
   ld [de], a
   inc de
   ld a, TID_E ; E
   ld [de], a
   inc de
   ld a, TID_SPACE  ; space
   ld [de], a
   inc de
   ld a, TID_O ; O
   ld [de], a
   inc de
   ld a, TID_V ; V
   ld [de], a
   inc de
   ld a, TID_E ; E
   ld [de], a
   inc de
   ld a, TID_R ; R
   ld [de], a

   ; Write restart prompt on two lines below: "PRESS START" and "TO RESTART"
   ; Line 1: configured -> "PRESS START" (one blank row between title and prompt)
   LD_DE_BG RESTART1_ROW, RESTART1_COL
   ld a, TID_P ; P
   ld [de], a
   inc de
   ld a, TID_R ; R
   ld [de], a
   inc de
   ld a, TID_E ; E
   ld [de], a
   inc de
   ld a, TID_S ; S
   ld [de], a
   inc de
   ld a, TID_S ; S
   ld [de], a
   inc de
   ld a, TID_SPACE ; space
   ld [de], a
   inc de
   ld a, TID_S ; S
   ld [de], a
   inc de
   ld a, TID_T ; T
   ld [de], a
   inc de
   ld a, TID_A ; A
   ld [de], a
   inc de
   ld a, TID_R ; R
   ld [de], a
   inc de
   ld a, TID_T ; T
   ld [de], a
   inc de

   ; Line 2: configured -> "TO RESTART"
   LD_DE_BG RESTART2_ROW, RESTART2_COL
   ld a, TID_T ; T
   ld [de], a
   inc de
   ld a, TID_O ; O
   ld [de], a
   inc de
   ld a, TID_SPACE ; space
   ld [de], a
   inc de
   ld a, TID_R ; R
   ld [de], a
   inc de
   ld a, TID_E ; E
   ld [de], a
   inc de
   ld a, TID_S ; S
   ld [de], a
   inc de
   ld a, TID_T ; T
   ld [de], a
   inc de
   ld a, TID_A ; A
   ld [de], a
   inc de
   ld a, TID_R ; R
   ld [de], a
   inc de
   ld a, TID_T ; T
   ld [de], a
   inc de
   ret