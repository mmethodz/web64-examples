; EVENT HORIZON — stock PAL C64, Web64 native assembler.
; Specialised polar shader + phase-interleaved charsets + 8 hardware sprites.
; No recorded frames, browser drawing, REU, cartridge or unofficial opcodes.
* = $0801
    .byte $0b,$08,$0a,$00,$9e
    .text "2064"
    .byte 0,0,0
* = $0810
start:
    sei
    cld
    ldx #$ff
    txs
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d
    lda #0
    sta $d01a
    sta $d015
    sta $d020
    sta $d021
    sta $d011
    sta $dc0e
    sta $dc0f
    lda #$35
    sta $01
    lda #<nmi
    sta $fffa
    lda #>nmi
    sta $fffb
    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff
    lda $dd02
    ora #3
    sta $dd02
    lda $dd00
    and #$fc
    ora #2
    sta $dd00
    ldx #0
clear_state:
    lda #0
    sta state,x
    inx
    cpx #state_end-state
    bne clear_state
    lda #$c0
    sta front_mode
    lda #$50
    sta core_front
    lda #$18
    sta $d016
    ldx #0
init_colors:
    lda color_map,x
    sta $d800,x
    lda color_map+$100,x
    sta $d900,x
    lda color_map+$200,x
    sta $da00,x
    lda color_map+$300,x
    sta $db00,x
    lda #255
    sta $7000,x
    sta $7100,x
    sta $7200,x
    sta $7300,x
    sta $7400,x
    sta $7500,x
    sta $7600,x
    sta $7700,x
    inx
    bne init_colors
    ldx #0
init_footer:
    lda footer_screen,x
    sta $7370,x
    sta $7770,x
    inx
    cpx #120
    bne init_footer
    lda #0
    sta $d017
    sta $d01c
    sta $d01b
    lda #$0f
    sta $d01d
    lda #0
    ldx #0
init_sid:
    sta $d400,x
    inx
    cpx #25
    bne init_sid
    lda #15
    sta $d418
    lda #$08
    sta $d405
    lda #$89
    sta $d406
    lda #$02
    sta $d40c
    lda #$69
    sta $d40d
    lda #$05
    sta $d413
    lda #$07
    sta $d414
    jsr prepare_phases
    jsr draw_screen0
    jsr draw_screen1
    jsr core_render
    jsr core_render
    jsr update_sprites
    lda #$ff
    sta $d015
    lda #48
    sta $d012
    lda #$1b
    sta $d011
    lda #1
    sta $d019
    sta $d01a
    cli

main:
    lda frame_counter
    cmp consumed_frame
    beq main
    sta consumed_frame
    ; CIA timer B measures the real render window, including IRQs and VIC DMA.
    lda #0
    sta $dc0f
    lda #$ff
    sta $dc06
    sta $dc07
    lda #$11
    sta $dc0f
    jsr input
    jsr music
    lda paused
    bne no_animation_step
    inc animation_clock
    bne no_animation_step
    inc animation_clock+1
no_animation_step:
    jsr prepare_phases
    jsr update_sprites
    jsr core_render
    lda front_mode
    and #$10
    bne draw_first
    jsr draw_screen1
    jmp draw_complete
draw_first:
    jsr draw_screen0
draw_complete:
    sec
    lda #$ff
    sbc $dc06
    sta render_cycles
    lda #$ff
    sbc $dc07
    sta render_cycles+1
    cmp peak_cycles+1
    bcc measured
    bne new_peak
    lda render_cycles
    cmp peak_cycles
    bcc measured
new_peak:
    lda render_cycles
    sta peak_cycles
    lda render_cycles+1
    sta peak_cycles+1
measured:
    inc completed_frames
    bne completed_counted
    inc completed_frames+1
completed_counted:
    lda #1
    sta buffer_ready
    jmp main

.include "engine.inc"
.include "raster-prism.inc"
.include "music.inc"
.include "vector-core.inc"
.include "polar-kernel.inc"
.include "visual-data.inc"
