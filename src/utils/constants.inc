DEF rLY					equ $FF44
DEF rBGP				equ $FF47
DEF rOBP1				equ $FF48
DEF rOBP2				equ $FF49
DEF rLCDC				equ $FF40
DEF rDIV                equ $FF04


DEF OAM_START	equ $FE00
DEF OAM_SIZE	equ 4*40

DEF rLCDC_OBJ_ENABLE	equ 1
DEF rLCDC_OBJ_16x8		equ 2
DEF rLCDC_LCD_ENABLE	equ 7

DEF	DEFAULT_PAL			equ %11100100
DEF VBLANK_START_LINE	equ $90
DEF VRAM_TILE_START		equ $8000
DEF VRAM_TILE_SIZE		equ $10
DEF VRAM_TILE_32		equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

DEF rP1               equ $FF00

;; P1 low nibble masks (after selecting the group and inverting),
;; common mapping: bit0=Right, bit1=Left, bit2=Up, bit3=Down (pressed=1)
DEF P1_RIGHT          equ %00000001
DEF P1_LEFT           equ %00000010
DEF P1_UP             equ %00000100
DEF P1_DOWN           equ %00001000

;; P1 button group masks (after selecting the button group and inverting):
;; bit0 = A, bit1 = B, bit2 = Select, bit3 = Start (pressed=1)
DEF P1_BTN_A          equ %00000001
DEF P1_BTN_B          equ %00000010
DEF P1_BTN_SELECT     equ %00000100
DEF P1_BTN_START      equ %00001000

DEF VRAM_TILE_BALL    equ VRAM_TILE_START + ($22 * VRAM_TILE_SIZE)
DEF VRAM_TILE_BALL_BLACK equ VRAM_TILE_START + ($24 * VRAM_TILE_SIZE)

; Sprite tile IDs
DEF TID_BALL          equ $22
DEF TID_BALL_BLACK    equ $24

; --- Spawn/burst config ---
DEF SPAWN_FPS_FRAMES      equ $3C    ; 60 frames per second
DEF SPAWN_BURST_SECONDS   equ 5      ; burst period in seconds
DEF SPAWN_BURST_COUNT     equ 5      ; balls per burst (spread coverage)

; Limits
DEF MAX_BALLS             equ 12     ; maximum balls active at once

; Spawn position config
DEF SPAWN_X_MIN           equ 8      ; keep fully on-screen (OAM X has +8 offset)
DEF SPAWN_X_MAX           equ 168    ; inclusive max to keep fully visible: OAM X in [8..168]
DEF SPAWN_Y_START         equ 0      ; spawn off-screen above (OAM Y < 16 is not visible)

; Off-screen/despawn thresholds (OAM coordinates)
DEF OAM_Y_INVISIBLE       equ 160    ; Y >= 160 is not drawn
DEF OFFSCREEN_Y_THRESHOLD equ 168    ; despawn when falling below this

; GA-style falling behavior
DEF GRAVITY_BALL          equ 1      ; vy += 1 per frame
DEF VY_MAX_BALL           equ 1      ; clamp vertical speed (slow fall)
DEF BALL_FALL_DIV         equ 2      ; apply fall (gravity+move) every 2 frames
DEF MIN_SPAWN_SEPARATION  equ 16     ; enforce min distance between consecutive spawns

; --- Collision box sizes (in pixels) ---
; Using OBJ in 8x16 mode for both player and ball
DEF PLAYER_WIDTH          equ 8
DEF PLAYER_HEIGHT         equ 16
DEF BALL_WIDTH            equ 8
DEF BALL_HEIGHT           equ 16

; Preset spawn positions table size (X positions)
DEF BALL_SPAWN_POS_COUNT  equ 10
DEF BALL_SPAWN_STRIDE     equ 3      ; coprime with 10 to ensure unique sequence

; Staggered start configuration (frames)
DEF STAGGER_BASE_FRAMES   equ 60     ; base delay before the first ball starts (~1.0s)
DEF STAGGER_STEP_FRAMES   equ 48     ; delay increment between balls (~0.8s)
DEF STAGGER_MAX_FRAMES    equ 252    ; cap fits 5-ball burst: 60,108,156,204,252

