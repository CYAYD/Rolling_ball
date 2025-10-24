INCLUDE "man/entity_manager.inc"

SECTION "Scene Game Data", ROM0

ball_sprite::
   DB $3C,$3C,$42,$42,$F9,$81,$BD,$C1
   DB $BD,$C1,$9F,$E1,$42,$7E,$3C,$3C

sc_game_fence_tiles::
   DB $81,$FF,$C3,$FF,$BD,$FF,$99,$E7
   DB $99,$E7,$99,$E7,$99,$E7,$99,$E7
   DB $99,$E7,$99,$E7,$99,$FF,$A5,$E7
   DB $A5,$E7,$A5,$FF,$99,$FF,$FF,$FF

sc_game_entity_1::
   DB  ENTITY_WITH_ALL,  TAG_PLAYER,   0, 0                 ;; CMP_INFO
   DB 32, 16, $20, %00000000                       ;; CMP_SPRITE
   DB  0,  0,   0, 0                               ;; CMP_PHYSICS

sc_game_entity_2:: 
   DB  ENTITY_WITH_ALL,  0,   0, 0                 ;; CMP_INFO
   DB 32, 120, $20, %00000000                      ;; CMP_SPRITE
   DB  -1,  0,   0, 0                               ;; CMP_PHYSICS

   sc_ball_entity::
   DB ENTITY_WITH_ALL, TAG_BALL, 0, 0               ;; CMP_INFO (tag as BALL)
   DB 32, 16, $22, %00000000                         ;; CMP_SPRITE (TID $22 - after copying)
   DB 1, 0, 0, 0                                     ;; CMP_PHYSICS (vy=+1 initial, vx=0)

; Preset X positions for ball spawns (OAM X coordinates)
ball_spawn_positions_x::
   DB 16, 32, 48, 64, 80, 96, 112, 128, 144, 160