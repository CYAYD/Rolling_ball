INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"

SECTION "Collision System WRAM", WRAM0
coll_player_y: DS 1
coll_player_x: DS 1
heart_best_off: DS 1
heart_best_x: DS 1

SECTION "Collision System Code", ROM0

; sys_collision_update: detect player-ball overlap and despawn ball
sys_collision_update::
    ; Default player cache to 0xFF (not found)
    ld a, $FF
    ld hl, coll_player_y
    ld [hl], a
    ld hl, coll_player_x
    ld [hl], a

    ; Find player entity and cache its Y,X (use shared finder)
    ld a, TAG_PLAYER
    call man_find_first_by_tag
    cp 0
    jr z, .have_player
    ; E holds player offset
    ; Cache sprite Y and X
    ld h, CMP_SPRITE_H
    ld l, e
    ld a, [hl]
    ld hl, coll_player_y
    ld [hl], a
    ld h, CMP_SPRITE_H
    ld l, e
    inc l
    ld a, [hl]
    ld hl, coll_player_x
    ld [hl], a
.have_player:
    ; If no player found, nothing to do
    ld hl, coll_player_y
    ld a, [hl]
    cp $FF
    ret z

    ; Iterate balls and test AABB with player
    ld e, 0



; Define colisiones del jugador con la pared
DEF PLAYER_MIN_X    EQU 16    ; borde izquierdo (píxeles)
DEF PLAYER_MAX_X    EQU 152   ; borde derecho (píxeles)
DEF PLAYER_MIN_Y    EQU 16    ; borde superior (píxeles)
DEF PLAYER_MAX_Y    EQU 136   ; borde inferior (píxeles)

    ; Recuperar Y cached
    ld hl, coll_player_y
    ld a, [hl]

    ; Si Y < PLAYER_MIN_Y -> fijar a PLAYER_MIN_Y y anular vy
    cp PLAYER_MIN_Y
    jr nc, .check_y_max     ; si A >= MIN, saltar
    ld a, PLAYER_MIN_Y
    ; escribir nuevo Y en sprite (CMP_SPRITE_H + E)
    ld h, CMP_SPRITE_H
    ld l, e
    ld [hl], a
    ; anular vy en components_physics (byte 0)
    ld hl, components_physics
    xor a
    ld [hl], a
    jr .after_y_check

.check_y_max:
    ; Si Y > PLAYER_MAX_Y -> fijar a PLAYER_MAX_Y y anular vy
    ld hl, coll_player_y
    ld a, [hl]
    cp PLAYER_MAX_Y
    jr c, .after_y_check   ; si A < MAX, OK
    jr z, .after_y_check   ; si == MAX, OK
    ; si A > MAX:
    ld a, PLAYER_MAX_Y
    ld h, CMP_SPRITE_H
    ld l, e
    ld [hl], a
    ld hl, components_physics
    xor a
    ld [hl], a

.after_y_check:

    ; Recuperar X cached
    ld hl, coll_player_x
    ld a, [hl]

    ; Si X < PLAYER_MIN_X -> fijar y anular vx
    cp PLAYER_MIN_X
    jr nc, .check_x_max    ; si A >= MIN, saltar
    ld a, PLAYER_MIN_X
    ld h, CMP_SPRITE_H
    ld l, e
    inc l                  ; X offset = sprite base + 1
    ld [hl], a
    ; anular vx en components_physics (byte 1)
    ld hl, components_physics
    inc hl                  ; vx está en siguiente byte tras vy
    xor a
    ld [hl], a
    jr .after_x_check

.check_x_max:
    ld hl, coll_player_x
    ld a, [hl]
    cp PLAYER_MAX_X
    jr c, .after_x_check   ; si A < MAX, OK
    jr z, .after_x_check
    ; si A > MAX:
    ld a, PLAYER_MAX_X
    ld h, CMP_SPRITE_H
    ld l, e
    inc l
    ld [hl], a
    ld hl, components_physics
    inc hl
    xor a
    ld [hl], a

.after_x_check:
    ; Actualiza las caches coll_player_x/y con los valores posiblemente corregidos
    ld h, CMP_SPRITE_H
    ld l, e
    ld a, [hl]
    ld hl, coll_player_y
    ld [hl], a
    ld h, CMP_SPRITE_H
    ld l, e
    inc l
    ld a, [hl]
    ld hl, coll_player_x
    ld [hl], a



.balls_loop:
    ld h, CMP_INFO_H
    ld l, e
    ld a, [hl]
    and VALID_ENTITY
    cp VALID_ENTITY
    jp nz, .next_ball
    ld h, CMP_INFO_H
    ld l, e
    inc l
    ld a, [hl]
    cp TAG_BALL
    jp nz, .next_ball
    ; Read ball Y,X via helper
    call man_get_sprite_yx_at_e
    ; Vertical overlap test
    ld hl, coll_player_y
    ld a, [hl]
    add PLAYER_HEIGHT
    cp b
    jp z, .next_ball
    jp c, .next_ball
    ld a, b
    add BALL_HEIGHT
    ld hl, coll_player_y
    cp [hl]
    jp z, .next_ball
    jp c, .next_ball
    ; Horizontal overlap test
    ld hl, coll_player_x
    ld a, [hl]
    add PLAYER_WIDTH
    cp c
    jp z, .next_ball
    jp c, .next_ball
    ld a, c
    add BALL_WIDTH
    ld hl, coll_player_x
    cp [hl]
    jp z, .next_ball
    jp c, .next_ball
    ; Collision detected: if ball is black, remove player, balls, heart and number (clear all entities).
    ; Otherwise, despawn only this ball.
    ; Check sprite TID of the colliding ball
    call man_get_sprite_tid_at_e
    cp TID_BALL_BLACK
    jp nz, .check_special
    ; Penalización por pelota negra: -500 (hasta 0000)
    call score_sub_500
    ; --- Black ball hit: lose a heart, or game over if only one heart remains ---
    ; Use hearts_left counter for robustness
    ld hl, hearts_left
    ld a, [hl]
    cp 1
    jp z, .trigger_game_over
    dec a
    ld [hl], a
    ; remove one heart pair visually and despawn this black ball
    push de                  ; preserve current ball entity offset in E
    call remove_one_heart_pair
    pop de
    call despawn_entity_at_e
    ret

.check_special:
    ; Special ball: +200 puntos y eliminar la pelota
    cp TID_BALL_SPECIAL
    jr nz, .despawn_only_ball
    call score_add_200
    call despawn_entity_at_e
    ret

.trigger_game_over:
    call sc_game_over
    ret

.despawn_only_ball:
    ; Normal ball: +100 puntos y eliminar la pelota
    call score_add_100
    ; Usa la rutina genérica de despawn para no duplicar lógica
    call despawn_entity_at_e

.next_ball:
    ld a, e
    add SIZEOF_CMP
    ld e, a
    cp SIZEOF_ARRAY_CMP
    jp nz, .balls_loop
    ret

; (removed) count_heart_halves no longer used; rely on hearts_left counter

; remove_one_heart_pair: remove the rightmost heart (two 8x16 sprites with TAG_HEART)
; Clobbers: AF, BC, DE, HL
remove_one_heart_pair::
    ; init best_x = 0x00, best_off = 0xFF (not found)
    ld hl, heart_best_x
    xor a
    ld [hl], a
    ld hl, heart_best_off
    ld a, $FF
    ld [hl], a
    ; scan all entities for TAG_HEART and track max X
    ld e, 0
.scan_hearts:
    ld h, CMP_INFO_H
    ld l, e
    ld a, [hl]
    and VALID_ENTITY
    cp VALID_ENTITY
    jr nz, .next_scan
    inc l                 ; info+1 = TAG
    ld a, [hl]
    cp TAG_HEART
    jr nz, .next_scan
    ; read X
    ld h, CMP_SPRITE_H
    ld l, e
    inc l
    ld a, [hl]
    ld hl, heart_best_x
    cp [hl]
    jr c, .next_scan
    ; a >= best_x, update
    ld [hl], a
    ld hl, heart_best_off
    ld [hl], e
.next_scan:
    ld a, e
    add SIZEOF_CMP
    ld e, a
    cp SIZEOF_ARRAY_CMP
    jr nz, .scan_hearts
    ; if none found, return
    ld hl, heart_best_off
    ld a, [hl]
    cp $FF
    ret z
    ; plan removal: pick selected heart entity and determine its counterpart before despawning
    ld e, a               ; E = offset of chosen heart entity
    ; read Y,X,TID first
    ld h, CMP_SPRITE_H
    ld l, e
    ld b, [hl]           ; B = Y
    inc l
    ld c, [hl]           ; C = X
    inc l
    ld a, [hl]           ; A = TID
    ; compute neighbor X in D
    ld d, c
    cp TID_HEART_R
    jr nz, .assume_left
    ; was right half, neighbor is left at X-8
    ld a, d
    sub 8
    ld d, a
    jr .have_neighbor
.assume_left:
    ; assume left half, neighbor is right at X+8
    ld a, d
    add 8
    ld d, a
.have_neighbor:
    ; despawn selected entity now
    push de              ; save neighbor X in D and selection offset in E via stack
    push bc              ; save B=C=Y,X (for matching)
    ; Ensure E equals selected offset; restore from heart_best_off
    ld hl, heart_best_off
    ld e, [hl]
    call despawn_entity_at_e
    pop bc               ; restore B=Y, C=X of selected
    pop de               ; restore D=neighbor X
    ; scan again to find TAG_HEART with same Y, neighbor X
    ld e, 0
.scan_pair:
    ld h, CMP_INFO_H
    ld l, e
    ld a, [hl]
    and VALID_ENTITY
    cp VALID_ENTITY
    jr nz, .next_pair
    inc l
    ld a, [hl]
    cp TAG_HEART
    jr nz, .next_pair
    ; compare Y and X
    ld h, CMP_SPRITE_H
    ld l, e
    ld a, [hl]
    cp b
    jr nz, .next_pair
    inc l
    ld a, [hl]
    cp d
    jr nz, .next_pair
    ; found counterpart
    call despawn_entity_at_e
    jr .done_pair
.next_pair:
    ld a, e
    add SIZEOF_CMP
    ld e, a
    cp SIZEOF_ARRAY_CMP
    jr nz, .scan_pair
.done_pair:
    ret

; despawn_entity_at_e: clear USED|ALIVE, dec alive_entities, zero sprite component at offset E
despawn_entity_at_e::
    ld h, CMP_INFO_H
    ld l, e
    res CMP_BIT_USED, [hl]
    res CMP_BIT_ALIVE, [hl]
    ld hl, alive_entities
    dec [hl]
    ld h, CMP_SPRITE_H
    ld l, e
    xor a
    ld b, SIZEOF_CMP
    call memset_256
    ret