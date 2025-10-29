INCLUDE "utils/constants.inc"
INCLUDE "man/entity_manager.inc"
SECTION "Physics State", WRAM0

; Current fall rate divider for balls (frames between gravity ticks)
; Initialized to BALL_FALL_DIV; can be set to 1 to speed up
ball_fall_div:: DS 1
SECTION "Physics System Code", ROM0

;;sys_render_init::


sys_physics_update_one_entity::
	; If this is a ball, handle delay and gravity
	ld h, CMP_INFO_H
	ld l, e
	inc l
	ld a, [hl]
	cp TAG_BALL
	jr nz, .no_gravity
	; check per-entity delay (physics byte +2)
	ld h, CMP_PHYSICS_H
	ld l, e
	inc hl
	inc hl
	ld a, [hl]
	cp 0
	jr z, .no_delay
	dec [hl]
	ret                    ; skip movement this frame while delaying
.no_delay:
	; rate divider for balls: only update every BALL_FALL_DIV frames
	ld h, CMP_PHYSICS_H
	ld l, e
	inc hl
	inc hl
	inc hl
	ld a, [hl]
	inc a                ; a = tick+1
	ld b, a              ; save new tick in b
	push hl              ; save pointer to tick
	ld hl, ball_fall_div
	ld a, b              ; a = tick
	cp [hl]              ; compare tick with current divider
	pop hl
	jr c, .store_tick_and_ret_b
	xor a                ; reset tick
	ld [hl], a
	jr .after_tick_b
.store_tick_and_ret_b:
	ld a, b
	ld [hl], a
	ret
.after_tick_b:
	; increment vy and clamp
	ld h, CMP_PHYSICS_H
	ld l, e
	ld a, [hl]
	add GRAVITY_BALL
	ld b, a
	ld a, VY_MAX_BALL
	cp b
	jr nc, .grav_store
	ld b, a
.grav_store:
	ld a, b
	ld [hl], a
.no_gravity:

   .hl_phy_de_spr
   	ld h, CMP_PHYSICS_H	
   	ld d, CMP_SPRITE_H
   	ld l, e 

   .y_plus_vy
	ld a, [de]
	add [hl]
	ld [de], a

	inc hl
	inc de

  .x_plus_vx
	ld a, [de]
	add [hl]
	ld [de], a

	; After applying movement, check if off-screen and despawn if needed
	dec de                   ; de -> sprite Y again
	ld a, [de]
	cp OFFSCREEN_Y_THRESHOLD
	jr c, .no_despawn
	; Use common despawn routine to avoid duplicated logic
	call despawn_entity_at_e
.no_despawn:
	ret

sys_physics_update::
	; stop physics updates if game over
	ld hl, game_over_flag
	ld a, [hl]
	cp 0
	ret nz
	
	ld hl, sys_physics_update_one_entity
	call man_entity_for_each

ret

; Initialize physics configurable parameters
sys_physics_set_normal::
	ld hl, ball_fall_div
	ld a, BALL_FALL_DIV
	ld [hl], a
	ret

sys_physics_set_fast::
	ld hl, ball_fall_div
	ld a, 1
	ld [hl], a
	ret