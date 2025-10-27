INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"

SECTION "Black Ball System WRAM", WRAM0
black_ball_offset: DS 1

SECTION "Black Ball System Code", ROM0

; Initialize black ball tracking (optional call from init if needed)
black_ball_init::
    ld hl, black_ball_offset
    ld a, $FF
    ld [hl], a
    ret

; sys_black_ball_update: Occasionally pick one existing ball and swap its TID to black
; Guarantee only one black ball at a time
sys_black_ball_update::
    ; If a black ball is currently tracked, verify it still exists and is a ball
    ld hl, black_ball_offset
    ld a, [hl]
    cp $FF
    jr z, .maybe_pick_new
    ; A holds offset E of the black ball
    ld e, a
    ; check VALID_ENTITY
    ld h, CMP_INFO_H
    ld l, e
    ld a, [hl]
    and VALID_ENTITY
    cp VALID_ENTITY
    jr nz, .clear_black
    ; check TAG == TAG_BALL
    ld h, CMP_INFO_H
    ld l, e
    inc l
    ld a, [hl]
    cp TAG_BALL
    jr nz, .clear_black
    ; still valid -> keep as black, do nothing this frame
    ret
.clear_black:
    ld hl, black_ball_offset
    ld a, $FF
    ld [hl], a
    ; fall through to maybe pick new

.maybe_pick_new:
    ; Low probability trigger: ~1/256 chance per frame
    call rand8
    cp 0
    jr nz, .no_change
    ; Ensure there is at least one ball
    ; Count balls
    ld c, 0                 ; C = count
    ld e, 0
.cnt_loop:
    ld h, CMP_INFO_H
    ld l, e
    ld a, [hl]
    and VALID_ENTITY
    cp VALID_ENTITY
    jr nz, .cnt_next
    ld h, CMP_INFO_H
    ld l, e
    inc l
    ld a, [hl]
    cp TAG_BALL
    jr nz, .cnt_next
    inc c
.cnt_next:
    ld a, e
    add SIZEOF_CMP
    ld e, a
    cp SIZEOF_ARRAY_CMP
    jr nz, .cnt_loop
    ld a, c
    cp 0
    jr z, .no_change
    dec a                   ; A = count-1 (max index)
    ld d, 0
    ld e, a
    call rand_range         ; A = k in [0..count-1]
    ld b, a                 ; B = target index among balls
    ; Iterate to the k-th ball and switch its TID
    ld e, 0
.pick_loop:
    ld h, CMP_INFO_H
    ld l, e
    ld a, [hl]
    and VALID_ENTITY
    cp VALID_ENTITY
    jr nz, .pick_next
    ld h, CMP_INFO_H
    ld l, e
    inc l
    ld a, [hl]
    cp TAG_BALL
    jr nz, .pick_next
    ; this is a ball
    ld a, b
    cp 0
    jr z, .make_black
    dec b
    jr .pick_next
.pick_next:
    ld a, e
    add SIZEOF_CMP
    ld e, a
    cp SIZEOF_ARRAY_CMP
    jr nz, .pick_loop
    jr .no_change           ; safety
.make_black:
    ; Set its sprite TID to black (top tile); CMP_SPRITE_TID is at +2 from sprite base
    ld h, CMP_SPRITE_H
    ld l, e
    inc l
    inc l
    ld a, TID_BALL_BLACK
    ld [hl], a
    ; Track this black ball's offset
    ld hl, black_ball_offset
    ld a, e
    ld [hl], a
    ret

.no_change:
    ret
