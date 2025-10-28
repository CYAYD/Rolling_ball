INCLUDE "utils/constants.inc"
INCLUDE "utils/macros.inc"

SECTION "Timer State", WRAM0

timer_frames::
    ds 1 ; counts frames 0..59

timer_seconds::
    ds 1 ; remaining seconds (0..60)

SECTION "Timer Code", ROM0

; Initialize timer to 60 seconds and 0 frames
timer_init::
    xor a
    ld [timer_frames], a
    ld a, 60
    ld [timer_seconds], a
    ; reset physics speed to normal when timer starts
    call sys_physics_set_normal
    call timer_draw
    ret

; Update timer once per frame; every 60 frames, decrement seconds (to 0 min)
; and redraw on BG.
timer_update::
    ; Si el juego ya terminó, no actualizar más el timer
    ld hl, game_over_flag
    ld a, [hl]
    or a
    ret nz
    ; increment frame counter
    ld hl, timer_frames
    ld a, [hl]
    inc a
    cp SPAWN_FPS_FRAMES ; 60
    jr c, timer_store_only
    ; rollover and tick one second
    xor a
    ld [hl], a
    ; decrement seconds if > 0
    ld a, [timer_seconds]
    or a
    jr z, .draw
    dec a
    ld [timer_seconds], a
    ; speed up falls when reaching 30 seconds
    cp 30
    jr nz, .draw
    call sys_physics_set_fast
.draw:
    call timer_draw
    ; If timer reached 0, trigger game over once
    ld a, [timer_seconds]
    or a
    ret nz
    call sc_game_over
    ret
timer_store_only:
    ld [hl], a
    ret

; Helper: split seconds into tens/ones
; Input: [timer_seconds]
; Output: b = tens, a = ones
timer_split10::
    ld a, [timer_seconds]
    ld b, 0
.split_loop:
    cp 10
    jr c, .done
    sub 10
    inc b
    jr .split_loop
.done:
    ret

; Render the digits to the BG map
; Position via LD_DE_BG SCORE_ROW, SCORE_SECS_COL
; Writes TID for tens then ones

timer_draw::
    call timer_split10       ; a = ones, b = tens
    ; If LCD is ON, wait for VBlank before touching BG map; if OFF, skip wait
    ld a, [rLCDC]
    bit rLCDC_LCD_ENABLE, a
    jr z, .no_wait
.wait_vblank:
    ld a, [rLY]
    cp VBLANK_START_LINE
    jr c, .wait_vblank
.no_wait:
    ; write tens digit
    ld a, b
    add a, TID_DIGIT_BASE
    LD_DE_BG SCORE_ROW, SCORE_SECS_COL
    ld [de], a
    inc de
    ; write ones digit
    ld a, [timer_seconds]
.ones_reduce:
    cp 10
    jr c, .ones_ready
    sub 10
    jr .ones_reduce
.ones_ready:
    add a, TID_DIGIT_BASE
    ld [de], a
    ret
