INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"
INCLUDE "src/assets/letras_grande.z80"
INCLUDE "src/assets/pantalla_inicio.z80"
INCLUDE "src/scenes/sc_title_defs.inc"

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
    ld c, TITLE_TILE_COUNT    ; tiles to copy (letras_grande)
.copy_tiles_loop:
    ld b, VRAM_TILE_SIZE      ; bytes per tile
    call memcpy_256          ; copies 16 bytes, advances HL/DE
    dec c
    jr nz, .copy_tiles_loop

    ; Ensure we have a dedicated BLANK tile (do NOT use 7 because O uses 4..7)
    ld hl, title_blank_tile
    ld de, VRAM_TILE_START + (TITLE_BLANK_TID * VRAM_TILE_SIZE)
    ld b, VRAM_TILE_SIZE
    call memcpy_256

    ; Clear BG MAP area to BLANK tile to avoid showing tile 0 everywhere
    ld de, BG_MAP0
    ld b, TITLE_VIEW_HEIGHT   ; rows
.clear_rows:
    ld c, TITLE_VIEW_WIDTH    ; cols
    ld a, TITLE_BLANK_TID    ; our blank tile index (dedicated)
.clear_cols:
    ld [de], a
    inc de
    dec c
    jr nz, .clear_cols
    ; move DE to next BG row
    ld a, BG_WIDTH - TITLE_VIEW_WIDTH
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
    ; b == 1 -> compare low byte with LOW(TITLE_8BIT_SIZE_THRESHOLD)
    ld a, c
    cp LOW(TITLE_8BIT_SIZE_THRESHOLD)
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
    ld a, TITLE_PAD_NIBBLES_4BIT
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
    ; advance HL to next BG row start
    ld a, BG_WIDTH-LabelWidth
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
    ld a, TITLE_BLANK_TID
.have_byte8:
    ld [hl], a
    inc hl
    dec c
    jr nz, .copy_8_loop
    ; advance HL to next BG row start
    ld a, BG_WIDTH-LabelWidth
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


; Wait on title screen until A is pressed
sc_title_run::
.loop:
    ; Select buttons group (P15 low) and read A
    ld a, P1_SELECT_BUTTONS
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
