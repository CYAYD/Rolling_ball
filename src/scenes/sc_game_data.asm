INCLUDE "man/entity_manager.inc"
INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"
INCLUDE "src/assets/tiles.z80"
INCLUDE "src/assets/tilemap.z80"

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


; ----- Carga tiles del mapa en VRAM -----
   ld hl, TileLabel
   ld de, $8000
   ld bc, (TileLabelEnd - TileLabel) / 16

   .copy_loop:
      ld b, 16
      call memcpy_256
      dec bc
      ld a, b
      or c
      jr nz, .copy_loop



   ; --- Cargar el tilemap en VRAM --------------------------
   ld hl, tilemap       ; Dirección del tilemap ROM
   ld de, $9800         ; VRAM background map
   ld bc, 32*32         ; 360 bytes
   call memcpy_bc       ; OJO, NO memcpy_256

   ; Ahora cargamos los tiles de sprites OBJ (después del BG para evitar sobrescrituras)
   ; Pelota normal (8x16): arriba = ball_sprite, abajo = blank
   MEMCPY_256 ball_sprite, VRAM_TILE_BALL, VRAM_TILE_SIZE
   MEMCPY_256 blank_tile, VRAM_TILE_BALL + VRAM_TILE_SIZE, VRAM_TILE_SIZE
   ; Pelota negra (8x16): usar el mismo tile arriba y abajo para que se vea "entera"
   MEMCPY_256 black_ball, VRAM_TILE_BALL_BLACK, VRAM_TILE_SIZE
   
   ; Corazón 16x16 usando dos sprites 8x16: izquierda ($66,$67) y derecha ($68,$69)
   ; Izquierda: top-left (0..15), bottom-left (16..31)
   ld hl, corazon                    ; top-left
   ld de, VRAM_TILE_HEART
   ld b, VRAM_TILE_SIZE
   call memcpy_256
   
   ; Número '1' (8x16): usamos el mismo tile arriba y abajo en $60, $61
   ld hl, uno_numero                    ; top
   ld de, VRAM_TILE_ONE
   ld b, VRAM_TILE_SIZE
   call memcpy_256

   ; bottom of the 8x16 slot: use blank_tile so the '1' is effectively 8x8
   MEMCPY_256 blank_tile, VRAM_TILE_ONE + VRAM_TILE_SIZE, VRAM_TILE_SIZE
   ld hl, corazon
   ld bc, VRAM_TILE_SIZE
   add hl, bc                        ; bottom-left
   ld de, VRAM_TILE_HEART + VRAM_TILE_SIZE
   ld b, VRAM_TILE_SIZE
   call memcpy_256
   ; Derecha: top-right (32..47), bottom-right (48..63)
   ld hl, corazon
   ld bc, VRAM_TILE_SIZE
   add hl, bc
   add hl, bc                        ; hl = corazon + 32
   ld de, VRAM_TILE_HEART_R
   ld b, VRAM_TILE_SIZE
   call memcpy_256
   ld hl, corazon
   ld bc, VRAM_TILE_SIZE
   add hl, bc
   add hl, bc
   add hl, bc                        ; hl = corazon + 48
   ld de, VRAM_TILE_HEART_R + VRAM_TILE_SIZE
   ld b, VRAM_TILE_SIZE
   call memcpy_256

   
   .enable_objects
      ld hl, rLCDC
      set rLCDC_OBJ_ENABLE, [hl]
      set rLCDC_OBJ_16x8, [hl]
      ; Asegurar fondo encendido y mapa en $9800
      ld hl, rLCDC
      set 0, [hl]   ; BG enable
      res 3, [hl]   ; BG map select = $9800

    .creat_entities
      ld hl, sc_game_entity_1

   
   call create_one_entity

   ; Create heart UI entity (left half)
   ld hl, sc_heart_entity
   call create_one_entity
   ; Create heart right half (second sprite, X + 8)
   ld hl, sc_heart_right_entity
   call create_one_entity
   ; Create number '1' to the right of the heart
   ld hl, sc_one_entity
   call create_one_entity

   call lcd_on
   
   ret

sc_game_run::
   
   .loop:
      call sys_physics_update
      call read_input_and_apply
      call process_spawns
      call sys_collision_update
      call sys_render_update
   jr .loop

   
   ret