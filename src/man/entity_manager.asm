INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"

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
; game over flag: 0=running, 1=over
game_over_flag: DS 1

; temporary buffer to build an entity in WRAM before allocating
last_temp_entity: DS 1
temp_entity: DS 12

; last allocated entity offset (low byte within component arrays) [unused now]
last_alloc_offset: DS 1

; RNG seed for spawn_ball_random
ball_rand: DS 1

; Periodic burst spawner counters
ball_burst_frame_count: DS 1   ; 0..59 frames
ball_burst_seconds: DS 1       ; seconds counter
; last spawn X (for separation)
ball_last_spawn_x: DS 1
; last spawn index for preset table
ball_last_spawn_index: DS 1
; rng tick mixes into RNG each frame to avoid periodic repeats
rng_tick: DS 1
; per-burst stagger delay accumulator (frames)
ball_burst_stagger: DS 1
; per-burst base index and spawn counter for preset positions
ball_burst_base_idx: DS 1
ball_burst_spawn_idx: DS 1
; per-burst chosen index that will be black among spawned balls
ball_burst_black_idx: DS 1
; mask of used black indices (bits 0..SPAWN_BURST_COUNT-1), to avoid repeats until all used
ball_black_used_mask: DS 1

SECTION "Entity Manager Code", ROM0

man_entity_init::

  .zero_alive_entities
	xor a
	ld [alive_entities], a

	;; no spawn-related flags to clear
	;; initialize RNG seed for ball spawn: mix with current LY
	ld hl, ball_rand
	ld a, [rLY]
	xor $55
	or a
	jr nz, .seed_ok
	ld a, $7B          ; ensure non-zero seed to avoid LFSR lock
.seed_ok:
	ld [hl], a

	;; initialize burst counters
	ld hl, ball_burst_frame_count
	xor a
	ld [hl], a
	ld hl, ball_burst_seconds
	ld [hl], a
    ; init last spawn x marker to 0xFF (none)
    ld hl, ball_last_spawn_x
    ld a, $FF
    ld [hl], a
	; init last spawn index marker to 0xFF (none)
	ld hl, ball_last_spawn_index
	ld [hl], a
	; init rng tick to 0
	ld hl, rng_tick
	xor a
	ld [hl], a
    ; init stagger accumulator to 0
    ld hl, ball_burst_stagger
    ld [hl], a
	; init base idx and spawn idx to 0
	ld hl, ball_burst_base_idx
	ld [hl], a
	ld hl, ball_burst_spawn_idx
	ld [hl], a
	; init black index to 0
	ld hl, ball_burst_black_idx
	ld [hl], a
	; init black used mask to 0
	ld hl, ball_black_used_mask
	ld [hl], a
	; init game over flag = 0
	ld hl, game_over_flag
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

	; remember low-byte offset of this allocated slot, but preserve HL
	push hl
	ld a, l
	ld hl, last_alloc_offset
	ld [hl], a
	pop hl

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