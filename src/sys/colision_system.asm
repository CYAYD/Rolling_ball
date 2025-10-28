INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"

SECTION "Collision System WRAM", WRAM0
coll_player_y: DS 1
coll_player_x: DS 1

SECTION "Collision System Code", ROM0

; sys_collision_update: detect player-ball overlap and despawn ball
sys_collision_update::
    ; Default player cache to 0xFF (not found)
    ld a, $FF
    ld hl, coll_player_y
    ld [hl], a
    ld hl, coll_player_x
    ld [hl], a

    ; Find player entity and cache its Y,X
    ld e, 0
.find_player_loop:
    ld h, CMP_INFO_H
    ld l, e
    ld a, [hl]
    and VALID_ENTITY
    cp VALID_ENTITY
    jr nz, .next_find_player
    ld h, CMP_INFO_H
    ld l, e
    inc l
    ld a, [hl]
    cp TAG_PLAYER
    jr nz, .next_find_player
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
    jr .have_player
.next_find_player:
    ld a, e
    add SIZEOF_CMP
    ld e, a
    cp SIZEOF_ARRAY_CMP
    jr nz, .find_player_loop
.have_player:
    ; If no player found, nothing to do
    ld hl, coll_player_y
    ld a, [hl]
    cp $FF
    ret z

    ; Iterate balls and test AABB with player
    ld e, 0
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
    ; Read ball Y,X
    ld h, CMP_SPRITE_H
    ld l, e
    ld b, [hl]           ; B = ball_y
    inc l
    ld c, [hl]           ; C = ball_x
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
    ; Check sprite TID of the colliding ball: components_sprite + 2
    ld h, CMP_SPRITE_H
    ld l, e
    inc l
    inc l
    ld a, [hl]
    cp TID_BALL_BLACK
    jp nz, .despawn_only_ball
    ; --- Black ball hit: trigger game over ---
    call sc_game_over
    ret

.despawn_only_ball:
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

.next_ball:
    ld a, e
    add SIZEOF_CMP
    ld e, a
    cp SIZEOF_ARRAY_CMP
    jp nz, .balls_loop
    ret