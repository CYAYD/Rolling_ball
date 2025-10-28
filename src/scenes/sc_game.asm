INCLUDE "man/entity_manager.inc"


SECTION "Scene Game Data", ROM0


uno_numero::
   DB $00,$00,$00,$00,$18,$18,$38,$38
   DB $18,$18,$18,$18,$18,$18,$3C,$3C

corazon::
   DB $00,$00,$00,$00,$00,$00,$00,$00
   DB $3C,$3C,$7E,$42,$CF,$81,$DF,$80
   DB $FF,$80,$7F,$40,$3F,$20,$1F,$10
   DB $0F,$08,$07,$04,$03,$02,$01,$01
   DB $00,$00,$00,$00,$00,$00,$00,$00
   DB $78,$78,$FC,$84,$FE,$02,$FE,$02
   DB $FE,$02,$FC,$04,$F8,$08,$F0,$10
   DB $E0,$20,$C0,$40,$80,$80,$00,$00

ball_sprite::
   DB $3C,$3C,$42,$42,$F9,$81,$BD,$C1
   DB $BD,$C1,$9F,$E1,$42,$7E,$3C,$3C

black_ball::
   DB $3C,$3C,$7E,$7E,$FF,$FF,$FF,$FF
   DB $FF,$FF,$FF,$FF,$7E,$7E,$3C,$3C

; A blank 8x8 tile (all zeros) to use as the lower half in 8x16 mode
blank_tile::
   DB $00,$00,$00,$00,$00,$00,$00,$00
   DB $00,$00,$00,$00,$00,$00,$00,$00

sc_game_fence_tiles::
   DB $81,$FF,$C3,$FF,$BD,$FF,$99,$E7
   DB $99,$E7,$99,$E7,$99,$E7,$99,$E7
   DB $99,$E7,$99,$E7,$99,$FF,$A5,$E7
   DB $A5,$E7,$A5,$FF,$99,$FF,$FF,$FF

; 8x8 tiles for "GAME OVER" letters (simple blocky glyphs)
tile_G::
   DB $3C,$3C,$42,$42,$80,$BE,$80,$BE
   DB $9E,$9E,$82,$82,$42,$42,$3C,$3C
tile_A::
   DB $3C,$3C,$42,$42,$81,$81,$81,$81
   DB $FF,$FF,$81,$81,$81,$81,$81,$81
tile_M::
   DB $81,$81,$C3,$C3,$A5,$A5,$99,$99
   DB $81,$81,$81,$81,$81,$81,$81,$81
tile_E::
   DB $FF,$FF,$80,$80,$80,$80,$FE,$FE
   DB $80,$80,$80,$80,$80,$80,$FF,$FF
tile_O::
   DB $3C,$3C,$42,$42,$81,$81,$81,$81
   DB $81,$81,$81,$81,$42,$42,$3C,$3C
tile_V::
   DB $81,$81,$81,$81,$81,$81,$42,$42
   DB $24,$24,$24,$24,$18,$18,$18,$18
tile_R::
   DB $FE,$FE,$81,$81,$81,$81,$FE,$FE
   DB $A0,$A0,$90,$90,$88,$88,$84,$84

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
   DB 32, 16, $62, %00000000                         ;; CMP_SPRITE (TID $62 - after copying)
   DB 0, 0, 0, 0                                     ;; CMP_PHYSICS (vy=0 initial, vx=0)

; Heart entity (static UI in top-right)
sc_heart_entity::
   DB ENTITY_WITH_ALL, TAG_HEART, 0, 0                ;; CMP_INFO (tag as HEART)
   DB 16, 112, $66, %00000000                        ;; CMP_SPRITE (Y=16, X=104, TID $66)
   DB 0, 0, 0, 0                                     ;; CMP_PHYSICS (no movement)

; Right half of 16x16 heart (second sprite side-by-side)
sc_heart_right_entity::
   DB ENTITY_WITH_ALL, TAG_HEART, 0, 0
   DB 16, 120, $68, %00000000                        ;; Y=16 (top), X = left+8, TID $68
   DB 0, 0, 0, 0

; Second heart (to the right): left and right halves
sc_heart2_entity::
   DB ENTITY_WITH_ALL, TAG_HEART, 0, 0
   DB 16, 128, $66, %00000000                        ;; Y=16, X=120, TID $66 (left half)
   DB 0, 0, 0, 0

sc_heart2_right_entity::
   DB ENTITY_WITH_ALL, TAG_HEART, 0, 0
   DB 16, 136, $68, %00000000                        ;; Y=16, X=128, TID $68 (right half)
   DB 0, 0, 0, 0

; Third heart (further right): left and right halves
sc_heart3_entity::
   DB ENTITY_WITH_ALL, TAG_HEART, 0, 0
   DB 16, 144, $66, %00000000                        ;; Y=16, X=136, TID $66 (left half)
   DB 0, 0, 0, 0

sc_heart3_right_entity::
   DB ENTITY_WITH_ALL, TAG_HEART, 0, 0
   DB 16, 152, $68, %00000000                        ;; Y=16, X=144, TID $68 (right half)
   DB 0, 0, 0, 0

; Preset X positions for ball spawns (OAM X coordinates)
ball_spawn_positions_x::
   ; Interleaved across left/center/right to ensure early indices already cover the screen
   DB 16, 144, 80, 112, 48, 160, 96, 128, 64, 32