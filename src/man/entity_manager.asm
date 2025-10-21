INCLUDE "man/entity_manager.inc"

SECTION "Entity Manager Data", WRAM0[$C000]

components:

EXPORT DEF CMP_INFO_H	 = HIGH(@)
components_info: 		DS SIZEOF_ARRAY_CMP
DS ALIGN[8]

EXPORT DEF CMP_SPRITE_H  = HIGH(@)
components_sprite: 	DS SIZEOF_ARRAY_CMP
DS ALIGN[8]

EXPORT DEF CMP_PHYSICS_H = HIGH(@)
components_physics: 	DS SIZEOF_ARRAY_CMP
DS ALIGN[8]

alive_entities: DS 1

ball_a_last: DS 1

; temporary buffer to build an entity in WRAM before allocating
last_temp_entity: DS 1
temp_entity: DS 12

ball_want_buttons: DS 1
prev_buttons: DS 1

SECTION "Entity Manager Code", ROM0

man_entity_init::

  .zero_alive_entities
	xor a
	ld [alive_entities], a

	;; clear spawn debounce and request flags
	ld hl, ball_a_last
	ld [hl], a
	ld hl, ball_want_buttons
	ld [hl], a
	ld hl, prev_buttons
	ld [hl], a
  
  .zero_cmps_info
	ld hl, components_info
	ld b, SIZEOF_ARRAY_CMP
	xor a
	call memset_256

  .zero_cmps_sprite
  ld hl, components_sprite
	ld b, SIZEOF_ARRAY_CMP
	call memset_256

	ret

man_entity_alloc::
  .one_more_alice_entity
		ld hl, alive_entities
		inc [hl]
	
  .find_first_free_slot
		ld hl, (components_info - SIZEOF_CMP)
		ld de, SIZEOF_CMP
	.loop:
		add hl, de
		bit CMP_BIT_USED, [hl]
	jr nz, .loop
		
	.found_free_slot:
	ld [hl], RESERVED_COMPONENT

	ret

man_entity_get_components::
	ld hl, components_sprite
	ld b, SIZEOF_ARRAY_CMP
	ret

man_entity_for_each::
	ld a, [alive_entities]

	.check_if_zero_entities
		cp 0
		ret z

	.process_alive_entities
		ld de, components_info
		ld b, a

	.loop
		
		.check_if_valid
			ld a, [de]
			and VALID_ENTITY
			cp VALID_ENTITY
			jr nz, .next

		.process
			push bc
			push hl
			push de
			call simulated_call_hl
			pop de
			pop hl
			pop bc

		.check_end
			dec b
			ret z

		.next
			ld a, e
			add SIZEOF_CMP
			ld e, a
	jr .loop