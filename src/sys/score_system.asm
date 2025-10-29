INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"

SECTION "Score State", WRAM0

score_thousands:: ds 1
score_hundreds::  ds 1
score_tens::      ds 1
score_ones::      ds 1
score_dirty::     ds 1

SECTION "Score Code", ROM0

; Initialize score to 0000 and draw it
score_init::
    xor a
    ld hl, score_thousands
    ld [hl], a
    inc hl
    ld [hl], a
    inc hl
    ld [hl], a
    inc hl
    ld [hl], a
    ; mark dirty and draw once during init (LCD is off here)
    ld hl, score_dirty
    ld [hl], a ; already 0
    inc [hl]   ; set to 1
    ; Draw with LCD state considered
    call score_draw
    ret

; Add 100 points (cap at 9999). Does nothing if game is over.
score_add_100::
    ; if game over, ignore updates
    ld hl, game_over_flag
    ld a, [hl]
    or a
    ret nz
    ; inc hundreds
    ld hl, score_hundreds
    ld a, [hl]
    inc a
    cp 10
    jr c, .store_h
    ; carry to thousands
    xor a           ; a = 0 for hundreds
    ld [hl], a
    ld hl, score_thousands
    ld a, [hl]
    cp 9
    jr z, .cap
    inc a
    ld [hl], a
    jr .mark_dirty
.cap:
    ld a, 9
    ld [hl], a
    jr .mark_dirty
.store_h:
    ld [hl], a
.mark_dirty:
    ; mark dirty to repaint in the frame loop (avoid multiple VBlank waits here)
    ld hl, score_dirty
    ld a, 1
    ld [hl], a
    ret

; Draw 4 digits at SCORE_ROW,SCORE_COL: thousands,hundreds,tens,ones
; Waits for VBlank if LCD ON to safely write BG map
score_draw::
    ; If LCD is ON, wait for VBlank; else skip wait
    ld a, [rLCDC]
    bit rLCDC_LCD_ENABLE, a
    jr z, .no_wait
.wait:
    ld a, [rLY]
    cp VBLANK_START_LINE
    jr c, .wait
.no_wait:
    ; Position to score start
    LD_DE_BG SCORE_ROW, SCORE_COL
    ; thousands
    ld a, [score_thousands]
    add a, TID_DIGIT_BASE
    ld [de], a
    inc de
    ; hundreds
    ld a, [score_hundreds]
    add a, TID_DIGIT_BASE
    ld [de], a
    inc de
    ; tens
    ld a, [score_tens]
    add a, TID_DIGIT_BASE
    ld [de], a
    inc de
    ; ones
    ld a, [score_ones]
    add a, TID_DIGIT_BASE
    ld [de], a
    ret

; Call once per frame; if dirty, draw and clear
score_update_ui::
    ld hl, score_dirty
    ld a, [hl]
    or a
    ret z
    xor a
    ld [hl], a
    call score_draw
    ret

; Subtract 500 points (clamp at 0000). Does nothing if game is over.
score_sub_500::
    ; if game over, ignore updates
    ld hl, game_over_flag
    ld a, [hl]
    or a
    ret nz
    ; if thousands==0 and hundreds<5 -> clamp to 0000
    ld hl, score_thousands
    ld a, [hl]
    or a
    jr nz, .check_hundreds
    ; thousands == 0
    ld hl, score_hundreds
    ld a, [hl]
    cp 5
    jr nc, .sub_direct
    ; clamp to zero
    xor a
    ld hl, score_thousands
    ld [hl], a
    ld hl, score_hundreds
    ld [hl], a
    ld hl, score_tens
    ld [hl], a
    ld hl, score_ones
    ld [hl], a
    jr .mark
.check_hundreds:
    ; thousands > 0
    ld hl, score_hundreds
    ld a, [hl]
    cp 5
    jr nc, .sub_direct_from_a
    ; need borrow from thousands: thousands-- ; hundreds = hundreds + 10 - 5 = +5
    ld hl, score_thousands
    ld a, [hl]
    dec a
    ld [hl], a
    ld hl, score_hundreds
    ld a, [hl]
    add 5
    ld [hl], a
    jr .mark
.sub_direct:
    ; a = hundreds, a >= 5 from earlier compare
    sub 5
    ld [hl], a
    jr .mark
.sub_direct_from_a:
    ; HL currently set to score_hundreds? Ensure it.
    ; a = hundreds, a >= 5
    sub 5
    ld hl, score_hundreds
    ld [hl], a
.mark:
    ; mark dirty so UI updates next frame
    ld hl, score_dirty
    ld a, 1
    ld [hl], a
    ret

; Add 200 points (cap at 9999). Does nothing if game is over.
score_add_200::
    ; if game over, ignore updates
    ld hl, game_over_flag
    ld a, [hl]
    or a
    ret nz
    ; hundreds += 2 with carry to thousands
    ld hl, score_hundreds
    ld a, [hl]
    add 2
    cp 10
    jr c, .store_h200
    ; carry to thousands
    sub 10
    ld [hl], a
    ld hl, score_thousands
    ld a, [hl]
    cp 9
    jr z, .cap200
    inc a
    ld [hl], a
    jr .mark_dirty200
.cap200:
    ld a, 9
    ld [hl], a
    jr .mark_dirty200
.store_h200:
    ld [hl], a
.mark_dirty200:
    ld hl, score_dirty
    ld a, 1
    ld [hl], a
    ret