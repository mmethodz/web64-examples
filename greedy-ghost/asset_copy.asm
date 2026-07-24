; Web64 IDE Example
; Name: Ghost Chase C Support
; Description: C-callable video, asset-copy, SID, raster, HUD, and scene routines.

BORDER=$d020
BACKGROUND=$d021
SCREEN_RAM=$0400
COLOR_RAM=$d800
VIC_MEMORY=$d018
RASTER=$d012
SPR_ENABLE=$d015
SPR_MC=$d01c
SPR_PTR0=$07f8
SPR_PTR1=$07f9
SPR_PTR2=$07fa
SPR_PTR3=$07fb
SPR_MC0=$d025
SPR_MC1=$d026
SPR_COLOR0=$d027
SPR_COLOR1=$d028
SPR_COLOR2=$d029
SPR_COLOR3=$d02a
SID=$d400
PLAYER_SPRITE_PTR=$c0
COIN_SPRITE_PTR=$c4
ENEMY_SPRITE_PTR=$d0
HUD_ROW=$03c0
DIGIT_ZERO=$20
HEART_CHAR=$2a

_setup_video:
    sei
    lda #$00
    sta CIA1_DDRA
    sta CIA1_DDRB
    sta BORDER
    sta BACKGROUND
    lda #%00011000
    sta VIC_MEMORY
    rts

_wait_frame:
wait_not_f8:
    lda RASTER
    cmp #$f8
    beq wait_not_f8
wait_f8:
    lda RASTER
    cmp #$f8
    bne wait_f8
    rts

_sprite_init:
    lda #PLAYER_SPRITE_PTR
    sta SPR_PTR0
    lda #COIN_SPRITE_PTR
    sta SPR_PTR1
    lda #ENEMY_SPRITE_PTR
    sta SPR_PTR2
    sta SPR_PTR3
    lda #%00001111
    sta SPR_ENABLE
    sta SPR_MC
    lda #c_joy_multicolor_1
    sta SPR_MC0
    lda #c_joy_multicolor_2
    sta SPR_MC1
    lda #c_joy_sprite_color
    sta SPR_COLOR0
    lda #bank_2_sprite_color
    sta SPR_COLOR1
    lda #$02
    sta SPR_COLOR2
    lda #$0a
    sta SPR_COLOR3
    rts

_sid_init:
    ldx #$18
    lda #0
sid_clear:
    sta SID,x
    dex
    bpl sid_clear
    lda #$0f
    sta SID+$18
    lda #$09
    sta SID+$05
    lda #$86
    sta SID+$06
    lda #$08
    sta SID+$0c
    lda #$86
    sta SID+$0d
    lda #$08
    sta SID+$13
    lda #$a8
    sta SID+$14
    lda #$11
    sta SID+$04
    lda #$21
    sta SID+$0b
    lda #$41
    sta SID+$12
    rts

_play_sid:
    inc sid_delay
    lda sid_delay
    cmp #8
    bcc sid_done
    lda #0
    sta sid_delay
    inc sid_step
    lda sid_step
    and #$0f
    tax
    lda lead_lo,x
    sta SID+$00
    lda lead_hi,x
    sta SID+$01
    lda bass_lo,x
    sta SID+$07
    lda bass_hi,x
    sta SID+$08
    lda chord_lo,x
    sta SID+$0e
    lda chord_hi,x
    sta SID+$0f
sid_done:
    rts

_clear_screen:
    ldx #0
    lda #0
clear_loop:
    sta SCREEN_RAM+$0000,x
    sta SCREEN_RAM+$0100,x
    sta SCREEN_RAM+$0200,x
    sta SCREEN_RAM+$02e8,x
    inx
    bne clear_loop
    rts

_paint_scene:
    ldx #$27
paint_loop:
    lda #$06
    sta COLOR_RAM+$0028,x
    sta COLOR_RAM+$0050,x
    sta COLOR_RAM+$0370,x
    lda #$0e
    sta COLOR_RAM+$0078,x
    sta COLOR_RAM+$00a0,x
    sta COLOR_RAM+$0348,x
    lda #$03
    sta COLOR_RAM+$00c8,x
    sta COLOR_RAM+$02f8,x
    lda #$01
    sta COLOR_RAM+$01e0,x
    sta COLOR_RAM+$0208,x
    dex
    bpl paint_loop
    rts

_pulse_scene:
    inc scene_phase
    lda scene_phase
    and #$03
    bne pulse_done
    ldx #$27
pulse_loop:
    txa
    clc
    adc scene_phase
    and #$1f
    tay
    lda shade_chars,y
    sta SCREEN_RAM+$0028,x
    lda scene_phase
    lsr
    clc
    adc wave_x,x
    and #$1f
    tay
    lda shade_chars,y
    sta SCREEN_RAM+$0370,x
    dex
    bpl pulse_loop
pulse_done:
    rts

asm_draw_score:
    ldx #$27
    lda #$00
hud_clear:
    sta SCREEN_RAM+HUD_ROW,x
    dex
    bpl hud_clear

    lda _score
    ldx #0
score_tens_loop:
    cmp #10
    bcc score_digits_ready
    sec
    sbc #10
    inx
    jmp score_tens_loop
score_digits_ready:
    clc
    adc #DIGIT_ZERO
    sta SCREEN_RAM+HUD_ROW+$02
    txa
    clc
    adc #DIGIT_ZERO
    sta SCREEN_RAM+HUD_ROW+$01
    lda #HEART_CHAR
    sta SCREEN_RAM+HUD_ROW+$24
    lda _lives
    clc
    adc #DIGIT_ZERO
    sta SCREEN_RAM+HUD_ROW+$26

    lda #$07
    sta COLOR_RAM+HUD_ROW+$01
    sta COLOR_RAM+HUD_ROW+$02
    lda #$0a
    sta COLOR_RAM+HUD_ROW+$24
    lda #$01
    sta COLOR_RAM+HUD_ROW+$26
    rts

_copy_charset:
    ldx #$00
copy_char_loop:
    lda bumps_chars+$0000,x
    sta $2000,x
    lda bumps_chars+$0100,x
    sta $2100,x
    lda bumps_chars+$0200,x
    sta $2200,x
    lda bumps_chars+$0300,x
    sta $2300,x
    lda bumps_chars+$0400,x
    sta $2400,x
    lda bumps_chars+$0500,x
    sta $2500,x
    lda bumps_chars+$0600,x
    sta $2600,x
    lda bumps_chars+$0700,x
    sta $2700,x
    inx
    bne copy_char_loop
    rts

_copy_sprites:
    ldx #0
copy_player_loop:
    lda c_joy_sprites,x
    sta $3000,x
    inx
    bne copy_player_loop
    ldx #0
copy_coin_page0:
    lda bank_2_sprites+$0000,x
    sta $3100,x
    inx
    bne copy_coin_page0
    ldx #0
copy_coin_page1:
    lda bank_2_sprites+$0100,x
    sta $3200,x
    inx
    bne copy_coin_page1
    ldx #0
copy_coin_tail:
    lda bank_2_sprites+$0200,x
    sta $3300,x
    inx
    cpx #$40
    bne copy_coin_tail
    ldx #0
copy_enemy_loop:
    lda enemy_sprites,x
    sta $3400,x
    inx
    bne copy_enemy_loop
    rts

sid_delay: .byte 0
sid_step: .byte 0
scene_phase: .byte 0

lead_lo: .byte $25,$6b,$b6,$0d,$6b,$d5,$4b,$d1,$25,$d1,$4b,$d5,$6b,$0d,$b6,$6b
lead_hi: .byte $11,$12,$13,$15,$16,$17,$19,$1a,$1c,$1a,$19,$17,$16,$15,$13,$12
bass_lo: .byte $12,$12,$35,$35,$12,$12,$46,$46,$25,$25,$58,$58,$25,$25,$46,$46
bass_hi: .byte $08,$08,$09,$09,$08,$08,$0a,$0a,$09,$09,$0b,$0b,$09,$09,$0a,$0a
chord_lo:.byte $b6,$b6,$0d,$0d,$4b,$4b,$d1,$d1,$6b,$6b,$25,$25,$d5,$d5,$6b,$6b
chord_hi:.byte $13,$13,$15,$15,$19,$19,$1a,$1a,$16,$16,$1c,$1c,$17,$17,$12,$12

shade_chars:
    .byte $1a,$1a,$1a,$1a,$1a,$1a,$1a,$1a
    .byte $17,$16,$15,$14,$13,$12,$11,$10
    .byte $0f,$0e,$0d,$0c,$0b,$0a,$09,$08
    .byte $07,$06,$05,$04,$03,$02,$01,$00
wave_x:
    .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
    .byte $0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00
    .byte $00,$01,$02,$03,$04,$05,$06,$07

.incbin c_joy_sprites, "assets/sprites/c-joy.spr"
.include "assets/sprites/c-joy.inc"
.incbin bank_2_sprites, "assets/sprites/bank-2.spr"
.include "assets/sprites/bank-2.inc"
.incbin enemy_sprites, "assets/sprites/enemy.spr"
.include "assets/sprites/enemy.inc"
.incbin bumps_chars, "assets/chars/bumps.chr"
.include "assets/chars/bumps.inc"