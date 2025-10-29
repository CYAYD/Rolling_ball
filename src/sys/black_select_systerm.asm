INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"

SECTION "Black Select System Code", ROM0

; black_select_begin: pick a fair index in [0..B-1] and store in ball_burst_black_idx
; In:  B = burst count
; Out: ball_burst_black_idx = chosen index
; Clobbers: AF, DE, HL (B preserved)
black_select_begin::
    push bc
    call choose_fair_black_index   ; A = index in [0..B-1]
    ld hl, ball_burst_black_idx
    ld [hl], a
    pop bc
    ret

; black_maybe_paint_temp_entity_black: if current spawn index matches chosen index, set TID to black
; In:  HL -> temp_entity X byte
; Uses: ball_burst_spawn_idx, ball_burst_black_idx
; Clobbers: AF, HL
black_maybe_paint_temp_entity_black::
    push hl
    ld hl, ball_burst_spawn_idx
    ld a, [hl]
    ld hl, ball_burst_black_idx
    cp [hl]
    pop hl
    jr nz, .no_black
    inc hl                  ; -> TID
    ld a, TID_BALL_BLACK
    ld [hl], a
.no_black:
    ret

;; choose_fair_black_index
;; In:  B = burst count (b)
;; Out: A = chosen index in [0..b-1]
;; Side: Updates ball_black_used_mask to include the chosen index
;; Clobbers: AF, DE, HL, C (B preserved)
choose_fair_black_index::
    push de
    push hl
    ; Load used mask in E
    ld hl, ball_black_used_mask
    ld e, [hl]
    ; Start idx = ball_rand % SPAWN_BURST_COUNT
    ld hl, ball_rand
    ld a, [hl]
.mod5:
    cp SPAWN_BURST_COUNT
    jr c, .idx_ready
    sub SPAWN_BURST_COUNT
    jr .mod5
.idx_ready:
    ld d, a                  ; D = idx
    ld l, SPAWN_BURST_COUNT  ; L = tries remaining
.try_loop:
    ; if idx >= b, skip
    ld a, d
    cp b
    jr nc, .next_idx
    ; compute bit mask C = (1 << idx)
    ld a, d
    and a
    jr z, .mask_is_one
    ld a, 1
    ld c, d
.shift_loop:
    sla a
    dec c
    jr nz, .shift_loop
    jr .mask_ready
.mask_is_one:
    ld a, 1
.mask_ready:
    ld c, a
    ; if (used_mask & C) == 0, found
    ld a, e
    and c
    jr z, .found
.next_idx:
    ; idx = (idx + 1) % SPAWN_BURST_COUNT
    ld a, d
    inc a
    cp SPAWN_BURST_COUNT
    jr c, .store_idx
    xor a
.store_idx:
    ld d, a
    dec l
    jr nz, .try_loop
    ; All indices used (for current b). Reset mask and pick random in [0..b-1]
    xor a
    ld e, a                  ; E = 0
    ld hl, ball_black_used_mask
    ld [hl], e
    ld hl, ball_rand
    ld a, [hl]
.mod_b:
    cp b
    jr c, .have_d
    sub b
    jr .mod_b
.have_d:
    ld d, a
    ; compute bit mask C = (1 << d)
    ld a, d
    and a
    jr z, .mask_one2
    ld a, 1
    ld c, d
.shift2:
    sla a
    dec c
    jr nz, .shift2
    jr .mask_ok2
.mask_one2:
    ld a, 1
.mask_ok2:
    ld c, a
.found:
    ; set bit and write mask back
    ld a, e
    or c
    ld e, a
    ld hl, ball_black_used_mask
    ld [hl], e
    ld a, d                  ; return chosen index in A
    pop hl
    pop de
    ret

; black_maybe_paint_last_entity_black: if current spawn index matches chosen index,
; paint the last allocated entity's sprite TID to black directly in components_sprite.
; Uses: ball_burst_spawn_idx, ball_burst_black_idx, last_alloc_offset
; Clobbers: AF, HL
black_maybe_paint_last_entity_black::
    ; compare spawn idx vs chosen black idx
    ld hl, ball_burst_spawn_idx
    ld a, [hl]
    ld hl, ball_burst_black_idx
    cp [hl]
    ret nz
    ; get last allocated offset
    ld hl, last_alloc_offset
    ld a, [hl]
    ld h, CMP_SPRITE_H
    ld l, a
    inc l                 ; -> X
    inc l                 ; -> TID
    ld a, TID_BALL_BLACK
    ld [hl], a
    ret

; special_select_prepare: choose the special index as the opposite of the black within the burst
; In:  B = burst count (b)
; Uses: ball_burst_black_idx
; Out: ball_burst_special_idx = (black_idx + floor(b/2)) % b
; Clobbers: AF, HL
special_select_prepare::
    push bc
    ; read black index in A
    ld hl, ball_burst_black_idx
    ld a, [hl]
    ; compute half = b >> 1 in C
    pop bc
    ld c, b
    srl c
    ; A = black_idx + half
    add a, c
.mod_b:
    cp b
    jr c, .store
    sub b
    jr .mod_b
.store:
    ld hl, ball_burst_special_idx
    ld [hl], a
    ret

; special_maybe_paint_last_entity_special: if current spawn index matches special index,
; paint the last allocated entity's sprite TID to special in components_sprite.
; Uses: ball_burst_spawn_idx, ball_burst_special_idx, last_alloc_offset
; Clobbers: AF, HL
special_maybe_paint_last_entity_special::
    ; compare spawn idx vs chosen special idx
    ld hl, ball_burst_spawn_idx
    ld a, [hl]
    ld hl, ball_burst_special_idx
    cp [hl]
    ret nz
    ; get last allocated offset
    ld hl, last_alloc_offset
    ld a, [hl]
    ld h, CMP_SPRITE_H
    ld l, a
    inc l                 ; -> X
    inc l                 ; -> TID
    ld a, TID_BALL_SPECIAL
    ld [hl], a
    inc l                 ; -> ATTR
    xor a                 ; default OBJ0 palette for clarity
    ld [hl], a
    ret