INCLUDE "utils/constants.inc"
SECTION "Physics System Code", ROM0

;;sys_render_init::


sys_physics_update_one_entity::
	
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
ret

sys_physics_update::
	
	ld hl, sys_physics_update_one_entity
	call man_entity_for_each

ret