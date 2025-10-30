INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"
INCLUDE "src/assets/letras_grande.z80"
INCLUDE "src/assets/pantalla_inicio.z80"

SECTION "Scene Title", ROM0

; Initialize the title screen: load tiles and tilemap, set BG on
sc_title_init::
    call lcd_off

    ; Reset scroll
    xor a
    ld hl, rSCY
    ld [hl], a
    ld hl, rSCX
    ld [hl], a

    ; Palettes (DMG): black background, white glyphs
    ; 0->black, 1->dark gray, 2->light gray, 3->white
    SET_BGP TITLE_PAL

    ; Copy title tiles into VRAM starting at $8000
    ld hl, TitleTiles
    ld de, VRAM_TILE_START
    ld c, 40                 ; 40 tiles (0..39), 16 bytes each
.copy_tiles_loop:
    ld b, 16                 ; bytes per tile
    call memcpy_256          ; copies 16 bytes, advances HL/DE
    dec c
    jr nz, .copy_tiles_loop

    ; Ensure we have a dedicated BLANK tile (do NOT use 7 because O uses 4..7)
    ld hl, title_blank_tile
    ld de, VRAM_TILE_START + (TITLE_BLANK_TID * VRAM_TILE_SIZE)
    ld b, VRAM_TILE_SIZE
    call memcpy_256

    ; Clear BG MAP 20x18 area to BLANK tile (7) to avoid showing tile 0 everywhere
    ld de, BG_MAP0
    ld b, 18                 ; rows
.clear_rows:
    ld c, 20                 ; cols
    ld a, TITLE_BLANK_TID    ; our blank tile index (dedicated)
.clear_cols:
    ld [de], a
    inc de
    dec c
    jr nz, .clear_cols
    ; move DE to next BG row (BG_WIDTH=32)
    ld a, 32-20
    add e
    ld e, a
    jr nc, .no_carry1
    inc d
.no_carry1:
    dec b
    jr nz, .clear_rows

    ; Compose title directly with known tiles from letras_grande
    ; This bypasses the 4-bit map limitation (only 16 indices) and uses
    ; the 2x2 letters defined as groups of 4 tiles in TitleTiles.
    call draw_title_compose
    jp .decode_done         ; skip old map decode entirely for stability

    ; Decide map format by size: if (LabelEnd-Label) >= 360 -> 8-bit, else 4-bit
    ld bc, LabelEnd - Label
    ld a, b
    cp 1
    jr c, .decode_4bit              ; < 256 bytes -> definitely 4-bit
    jr nz, .decode_8bit             ; >= 512 bytes -> 8-bit
    ; b == 1 -> compare low byte with $68 (360)
    ld a, c
    cp $68
    jr nc, .decode_8bit

.decode_4bit:
    ; Copy the title tilemap encoded in 4-bit nibbles (two tiles per byte)
    ; Label may be shorter than 20x18 bytes; when we run out, pad with $77 (blank idx).
    ; Use DE = source pointer (Label), HL = destination pointer (BG_MAP0)
    ld de, Label            ; DE = source nibble bytes
    ld hl, BG_MAP0          ; HL = BG destination
    ld b, LabelHeight       ; B = rows
.copy_rows_4:
    ld c, LabelWidth/2      ; C = bytes per row (10)
.copy_pair:
    ; if DE < LabelEnd -> read; else A=$77 (two blanks)
    push bc
    ld a, e
    sub LOW(LabelEnd)
    ld a, d
    sbc a, HIGH(LabelEnd)
    pop bc
    jr nc, .pad_byte        ; DE >= LabelEnd -> pad
    ld a, [de]
    inc de
    jr .have_byte
.pad_byte:
    ld a, $77
.have_byte:
    ; GBMB 0.5-plane packs two tile indices per byte as [hi|lo].
    ; We support an optional 16-entry remap table to align map indices
    ; with the tiles exported in letras_grande.z80. Default is identity.

    ; --- Left tile: HIGH nibble ---
    push af                 ; save original byte
    swap a                  ; move high into low
    and $0F                 ; idx = high nibble
    ; apply remap: a = remap[a]
    push hl
    ld hl, title_remap_table
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hl]
    pop hl
    ld [hl], a              ; left tile
    inc hl

    ; --- Right tile: LOW nibble ---
    pop af                  ; restore original
    and $0F                 ; idx = low nibble
    ; apply remap: a = remap[a]
    push hl
    ld hl, title_remap_table
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hl]
    pop hl
    ld [hl], a              ; right tile
    inc hl
    dec c
    jr nz, .copy_pair
    ; advance HL to next BG row start (BG_WIDTH=32)
    ld a, 32-LabelWidth
    add l
    ld l, a
    jr nc, .no_carry2
    inc h
.no_carry2:
    dec b
    jr nz, .copy_rows_4
    jp .decode_done

.decode_8bit:
    ; 8-bit map: one tile per byte, straight copy with padding to blank (7)
    ld de, Label            ; source
    ld hl, BG_MAP0          ; destination
    ld b, LabelHeight
.copy_rows_8:
    ld c, LabelWidth        ; 20 bytes per row
.copy_8_loop:
    ; if DE < LabelEnd -> read; else A=7
    push bc
    ld a, e
    sub LOW(LabelEnd)
    ld a, d
    sbc a, HIGH(LabelEnd)
    pop bc
    jr nc, .pad_byte8
    ld a, [de]
    inc de
    jr .have_byte8
.pad_byte8:
    ld a, 7
.have_byte8:
    ld [hl], a
    inc hl
    dec c
    jr nz, .copy_8_loop
    ; advance HL to next BG row start (BG_WIDTH=32)
    ld a, 32-LabelWidth
    add l
    ld l, a
    jr nc, .no_carry8
    inc h
.no_carry8:
    dec b
    jr nz, .copy_rows_8

.decode_done:

    ; Ensure BG enabled, OBJ disabled, BG map = $9800, BG tiles from $8000
    ld hl, rLCDC
    res rLCDC_OBJ_ENABLE, [hl]   ; disable sprites on title
    res rLCDC_OBJ_16x8, [hl]     ; 8x8 mode (irrelevant if OBJ off)
    set 0, [hl]                  ; BG enable
    res 3, [hl]                  ; BG map select = $9800
    set 4, [hl]                  ; BG tile data select = $8000 (unsigned)

    call lcd_on
    ret

; Local blank 8x8 tile for background
title_blank_tile:
    DB $00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00

; Local palette constant for title: black background, white glyphs
DEF TITLE_PAL EQU %00011011
DEF TITLE_BLANK_TID EQU 63

; Optional 4-bit map remap table (0..15) -> VRAM tile indices
; Default identity mapping. If letters still appear scrambled,
; adjust these 16 values to match the tile order in TitleTiles.
title_remap_table:
    DB 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

; -------------------------------------------------------
; Title composition using letras_grande layout
; Each letter uses 2x2 tiles, contiguous blocks of 4:
; 0-3=R, 4-7=O, 8-11=L, 12-15=I, 16-19=N, 20-23=G,
; 24-27=B, 28-31=A, 32-35=S, 36-38=ball frames.

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

; 2x2 letter order remap within each 4-tile block
; By default: [TL, TR, BL, BR] = [base+0, base+1, base+2, base+3]
letter_quad_order:
    ; Column-major: TL, BL, TR, BR (matches your export)
    DB 0,2,1,3

; Draw a 2x2 letter at DE using base tile in A and letter_quad_order
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

    ; move to next row, same col (DE = DE - 1 + 32)
    dec e
    ld a, e
    add 32
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
draw_title_compose:
    ; "ROLLING" on row 6, col 2..17 (no spacing between letters)
    LD_DE_BG 6, 2
    ld a, TID_R_BASE
    call draw_2x2_at
    LD_DE_BG 6, 4
    ld a, TID_O_BASE
    call draw_2x2_at
    LD_DE_BG 6, 6
    ld a, TID_L_BASE
    call draw_2x2_at
    LD_DE_BG 6, 8
    ld a, TID_L_BASE
    call draw_2x2_at
    LD_DE_BG 6, 10
    ld a, TID_I_BASE
    call draw_2x2_at
    LD_DE_BG 6, 12
    ld a, TID_N_BASE
    call draw_2x2_at
    LD_DE_BG 6, 14
    ld a, TID_G_BASE
    call draw_2x2_at

    ; "BALLS" on row 10, centered
    LD_DE_BG 10, 5
    ld a, TID_B_BASE
    call draw_2x2_at
    LD_DE_BG 10, 7
    ld a, TID_A_BASE
    call draw_2x2_at
    LD_DE_BG 10, 9
    ld a, TID_L_BASE
    call draw_2x2_at
    LD_DE_BG 10, 11
    ld a, TID_L_BASE
    call draw_2x2_at
    LD_DE_BG 10, 13
    ld a, TID_S_BASE
    call draw_2x2_at

    ; Diamonds (single tiles), use first frame
    LD_DE_BG 1, 3
    ld a, TID_BALL0
    ld [de], a
    ; streak above
    LD_DE_BG 0, 3
    ld a, TID_STREAK
    ld [de], a
    LD_DE_BG 1, 9
    ld a, TID_BALL0
    ld [de], a
    LD_DE_BG 0, 9
    ld a, TID_STREAK
    ld [de], a
    LD_DE_BG 1, 15
    ld a, TID_BALL0
    ld [de], a
    LD_DE_BG 0, 15
    ld a, TID_STREAK
    ld [de], a
    LD_DE_BG 4, 2
    ld a, TID_BALL0
    ld [de], a
    LD_DE_BG 3, 2
    ld a, TID_STREAK
    ld [de], a
    LD_DE_BG 4, 18
    ld a, TID_BALL0
    ld [de], a
    LD_DE_BG 3, 18
    ld a, TID_STREAK
    ld [de], a
    LD_DE_BG 14, 3
    ld a, TID_BALL0
    ld [de], a
    LD_DE_BG 13, 3
    ld a, TID_STREAK
    ld [de], a
    LD_DE_BG 14, 17
    ld a, TID_BALL0
    ld [de], a
    LD_DE_BG 13, 17
    ld a, TID_STREAK
    ld [de], a
    ret

; Wait on title screen until A is pressed
sc_title_run::
.loop:
    ; Select buttons group (P15 low) and read A
    ld a, %00010000
    ld [rP1], a
    ld a, [rP1]
    cpl
    and P1_BTN_A
    jr z, .no_press
    ret
.no_press:
    ; simple frame pacing
    call wait_vblank_start
    jr .loop
