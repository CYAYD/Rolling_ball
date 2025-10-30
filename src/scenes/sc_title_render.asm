INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"
INCLUDE "src/scenes/sc_title_defs.inc"

SECTION "Scene Title Render", ROM0

; 2x2 letter order remap within each 4-tile block
; Column-major: TL, BL, TR, BR (matches export)
letter_quad_order:
    DB 0,2,1,3

; Optional 4-bit map remap table (0..15) -> VRAM tile indices
; Identity mapping by default. Kept for compatibility with the old decoder.
EXPORT title_remap_table
title_remap_table:
    DB 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

; Draw a 2x2 letter at DE using base tile in A and letter_quad_order
; Inputs:
;   DE = BG map address (top-left of 2x2)
;   A  = base tile index (start of 4-tile block)
; Clobbers: A, B, HL
EXPORT draw_2x2_at

draw_2x2_at:
    ld b, a                 ; B = base tile index
    ld hl, letter_quad_order

    ; TL at [DE]
    ld a, [hl]
    add b
    ld [de], a
    inc hl

    ; TR at [DE+1]
    inc e
    ld a, [hl]
    add b
    ld [de], a
    inc hl

    ; move to next row, same col (DE = DE - 1 + BG_WIDTH)
    dec e
    ld a, e
    add BG_WIDTH
    ld e, a
    jr nc, .no_carry_d2
    inc d
.no_carry_d2:
    ; BL at [DE]
    ld a, [hl]
    add b
    ld [de], a
    inc hl

    ; BR at [DE+1]
    inc e
    ld a, [hl]
    add b
    ld [de], a
    ret

; Compose the screen text and diamonds
EXPORT draw_title_compose

draw_title_compose:
    ; "ROLLING" on TITLE_ROLLING_ROW, from TITLE_ROLLING_COL_START
    LD_DE_BG TITLE_ROLLING_ROW, (TITLE_ROLLING_COL_START + TITLE_LETTER_STEP*0)
    ld a, TID_R_BASE
    call draw_2x2_at
    LD_DE_BG TITLE_ROLLING_ROW, (TITLE_ROLLING_COL_START + TITLE_LETTER_STEP*1)
    ld a, TID_O_BASE
    call draw_2x2_at
    LD_DE_BG TITLE_ROLLING_ROW, (TITLE_ROLLING_COL_START + TITLE_LETTER_STEP*2)
    ld a, TID_L_BASE
    call draw_2x2_at
    LD_DE_BG TITLE_ROLLING_ROW, (TITLE_ROLLING_COL_START + TITLE_LETTER_STEP*3)
    ld a, TID_L_BASE
    call draw_2x2_at
    LD_DE_BG TITLE_ROLLING_ROW, (TITLE_ROLLING_COL_START + TITLE_LETTER_STEP*4)
    ld a, TID_I_BASE
    call draw_2x2_at
    LD_DE_BG TITLE_ROLLING_ROW, (TITLE_ROLLING_COL_START + TITLE_LETTER_STEP*5)
    ld a, TID_N_BASE
    call draw_2x2_at
    LD_DE_BG TITLE_ROLLING_ROW, (TITLE_ROLLING_COL_START + TITLE_LETTER_STEP*6)
    ld a, TID_G_BASE
    call draw_2x2_at

    ; "BALLS" on TITLE_BALLS_ROW, centered
    LD_DE_BG TITLE_BALLS_ROW, (TITLE_BALLS_COL_START + TITLE_LETTER_STEP*0)
    ld a, TID_B_BASE
    call draw_2x2_at
    LD_DE_BG TITLE_BALLS_ROW, (TITLE_BALLS_COL_START + TITLE_LETTER_STEP*1)
    ld a, TID_A_BASE
    call draw_2x2_at
    LD_DE_BG TITLE_BALLS_ROW, (TITLE_BALLS_COL_START + TITLE_LETTER_STEP*2)
    ld a, TID_L_BASE
    call draw_2x2_at
    LD_DE_BG TITLE_BALLS_ROW, (TITLE_BALLS_COL_START + TITLE_LETTER_STEP*3)
    ld a, TID_L_BASE
    call draw_2x2_at
    LD_DE_BG TITLE_BALLS_ROW, (TITLE_BALLS_COL_START + TITLE_LETTER_STEP*4)
    ld a, TID_S_BASE
    call draw_2x2_at

    ; Diamonds (single tiles) with streak above
    PLACE_BALL_STREAK D1_ROW, D1_COL
    PLACE_BALL_STREAK D2_ROW, D2_COL
    PLACE_BALL_STREAK D3_ROW, D3_COL
    PLACE_BALL_STREAK D4_ROW, D4_COL
    PLACE_BALL_STREAK D5_ROW, D5_COL
    PLACE_BALL_STREAK D6_ROW, D6_COL
    PLACE_BALL_STREAK D7_ROW, D7_COL
    ret
