INCLUDE "utils/constants.inc"
INCLUDE "man/entity_manager.inc"
SECTION "Physics System Code", ROM0

;;sys_render_init::


sys_physics_update_one_entity::
	; GA-like gravity for balls (tag-based)
	ld h, CMP_INFO_H
	ld l, e
	inc l
	ld a, [hl]
	cp TAG_BALL
	jr nz, .no_gravity
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
	; clear USED|ALIVE bits in components_info
	ld h, CMP_INFO_H
	ld l, e
	res CMP_BIT_USED, [hl]
	res CMP_BIT_ALIVE, [hl]
	; decrement alive_entities
	ld hl, alive_entities
	dec [hl]
	; zero sprite component (4 bytes) so OAM hides it
	ld h, CMP_SPRITE_H
	ld l, e
	xor a
	ld b, SIZEOF_CMP
	call memset_256
.no_despawn:
	ret

sys_physics_update::
	
	ld hl, sys_physics_update_one_entity
	call man_entity_for_each

ret