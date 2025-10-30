; Title scene shared definitions and small macros
; Palette: black background, white glyphs (DMG)
DEF TITLE_PAL        EQU %00011011

; Dedicated blank tile index in VRAM (do not collide with letter tiles 0..39)
DEF TITLE_BLANK_TID  EQU 63

; Title screen view size (visible area we clear)
DEF TITLE_VIEW_WIDTH   EQU 20
DEF TITLE_VIEW_HEIGHT  EQU 18

; Title tileset metadata
DEF TITLE_TILE_COUNT   EQU 40    ; tiles in letras_grande.z80 to copy

; Title tileset layout (letras_grande.z80):
; Each letter uses 2x2 tiles as contiguous blocks of 4
DEF TID_R_BASE  EQU 0
DEF TID_O_BASE  EQU 4
DEF TID_L_BASE  EQU 8
DEF TID_I_BASE  EQU 12
DEF TID_N_BASE  EQU 16
DEF TID_G_BASE  EQU 20
DEF TID_B_BASE  EQU 24
DEF TID_A_BASE  EQU 28
DEF TID_S_BASE  EQU 32
DEF TID_BALL0   EQU 36
DEF TID_STREAK  EQU 38   ; tile to draw above each ball (streak lines)

; String layout
DEF TITLE_ROLLING_ROW      EQU 6
DEF TITLE_ROLLING_COL_START EQU 2
DEF TITLE_BALLS_ROW        EQU 10
DEF TITLE_BALLS_COL_START  EQU 5
DEF TITLE_LETTER_STEP      EQU 2   ; columns between 2x2 letters

; Diamonds positions (rows/cols)
DEF D1_ROW EQU 1
DEF D2_ROW EQU 1
DEF D3_ROW EQU 1
DEF D4_ROW EQU 4
DEF D5_ROW EQU 4
DEF D6_ROW EQU 14
DEF D7_ROW EQU 14

DEF D1_COL EQU 3
DEF D2_COL EQU 9
DEF D3_COL EQU 15
DEF D4_COL EQU 2
DEF D5_COL EQU 18
DEF D6_COL EQU 3
DEF D7_COL EQU 17

; Map decode padding constants
DEF TITLE_PAD_NIBBLES_4BIT EQU $77   ; two 4-bit blanks (legacy path only)
DEF TITLE_8BIT_SIZE_THRESHOLD EQU 360 ; bytes to consider 8-bit map


; Helper macro: place a ball with a streak one row above
; Usage: PLACE_BALL_STREAK row, col
; Requires: LD_DE_BG macro, TID_BALL0, TID_STREAK
MACRO PLACE_BALL_STREAK
    LD_DE_BG \1, \2
    ld a, TID_BALL0
    ld [de], a
    LD_DE_BG (\1 - 1), \2
    ld a, TID_STREAK
    ld [de], a
ENDM
