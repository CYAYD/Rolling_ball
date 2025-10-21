INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"

DEF VRAM_TILE_20 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

SECTION "Scene Game", ROM0

create_one_entity:
	
	push hl
   
   .reserve_space_for_entity
	call man_entity_alloc
   
   .copy_info_cmp
	ld d, h
	ld e, l
	pop hl
	push hl
	push de
	ld b, SIZEOF_CMP
	call memcpy_256

   .copy_sprite_cmp
	pop de
	pop hl
	ld d, CMP_SPRITE_H
	ld bc, SIZEOF_CMP
	add hl, bc
	push hl
	push de
	ld b, c
	call memcpy_256
   
   .copy_physics_cmp
   	pop de
   	pop hl
   	ld d, CMP_PHYSICS_H
	ld bc, SIZEOF_CMP
	add hl, bc
	ld b, c
	call memcpy_256

	ld hl, ball_sprite
	ld de, VRAM_TILE_BALL
	ld b, VRAM_TILE_SIZE
	call memcpy_256

	ret

sc_game_init::

	call lcd_off

   .init_managers_and_systems
	call man_entity_init
	call sys_render_init

   .init_palettes_and_tiles
	SET_BGP DEFAULT_PAL
   	SET_OBP1 DEFAULT_PAL
   	MEMCPY_256 sc_game_fence_tiles, VRAM_TILE_20, 2*VRAM_TILE_SIZE
   	 
   .enable_objects
   	ld hl, rLCDC
   	set rLCDC_OBJ_ENABLE, [hl]
   	set rLCDC_OBJ_16x8, [hl]

   .creat_entities
  	ld hl, sc_game_entity_1
	call create_one_entity

	ld hl, sc_game_entity_2
	call create_one_entity
   


   	call lcd_on
	
	ret

sc_game_run::
	
	.loop:
		call sys_physics_update
		call read_input_and_apply
		call process_spawns
		call sys_render_update
	jr .loop

	
	ret