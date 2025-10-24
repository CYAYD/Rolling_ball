DEF rLY					equ $FF44
DEF rBGP				equ $FF47
DEF rOBP1				equ $FF48
DEF rOBP2				equ $FF49
DEF rLCDC				equ $FF40


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

; --- Spawn/burst config ---
DEF SPAWN_FPS_FRAMES      equ $3C    ; 60 frames per second
DEF SPAWN_BURST_SECONDS   equ 5      ; burst period in seconds
DEF SPAWN_BURST_COUNT     equ 3      ; balls per burst

