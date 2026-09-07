; Runtime state / phase bands / hardware-sprite composition / frame publication.
input:
    lda #$ff
    sta $dc02
    lda #0
    sta $dc03
    lda #$7f
    sta $dc00
    lda $dc01
    and #$10
    cmp old_space
    beq input_done
    sta old_space
    cmp #0
    bne input_done
    lda paused
    eor #1
    sta paused
input_done:
    rts

prepare_phases:
    lda animation_clock
    and #1
    asl
    sta next_charset
    lda animation_clock
    lsr
    and #15
    sta travel_phase
    lda animation_clock
    lsr
    sta ripple_clock
    ldx #0
phase_loop:
    txa
    asl
    asl
    asl
    clc
    adc ripple_clock
    tay
    lda ripple_table,y
    clc
    adc travel_phase
    and #15
    sta band_phases,x
    inx
    cpx #24
    bne phase_loop
    rts

update_sprites:
    lda core_front
    and #1
    asl
    asl
    clc
    adc #$40
    sta $73f8
    sta $77f8
    clc
    adc #1
    sta $73f9
    sta $77f9
    clc
    adc #1
    sta $73fa
    sta $77fa
    clc
    adc #1
    sta $73fb
    sta $77fb
    lda #136
    sta $d000
    sta $d004
    lda #184
    sta $d002
    sta $d006
    lda #118
    sta $d001
    sta $d003
    lda #139
    sta $d005
    sta $d007
    lda #1
    sta $d027
    sta $d028
    sta $d029
    sta $d02a
    lda #0
    sta sprite_high
    ldx animation_clock
    ldy #0
orbit_loop:
    lda orbit_x_lo,x
    sta $d008,y
    lda orbit_x_hi,x
    beq orbit_low
    lda sprite_masks,y
    ora sprite_high
    sta sprite_high
orbit_low:
    lda orbit_y,x
    sta $d009,y
    txa
    clc
    adc #64
    tax
    iny
    iny
    cpy #8
    bne orbit_loop
    lda sprite_high
    sta $d010
    lda animation_clock
    lsr
    and #3
    clc
    adc #$fc
    sta $73fc
    sta $73fd
    sta $73fe
    sta $73ff
    sta $77fc
    sta $77fd
    sta $77fe
    sta $77ff
    lda #1
    sta $d02b
    sta $d02d
    lda #1
    sta $d02c
    sta $d02e
    rts

; Palette bands have a three-line lead before the badline fetch.
; A separate cycle-stabilised section may own the footer; never wait in a hot draw.
irq:
    pha
    txa
    pha
    tya
    pha
    lda #1
    sta $d019
    ldx raster_row
    cpx #22
    beq footer_irq
    lda raster_dark,x
    sta $d022
    lda raster_light,x
    sta $d023
    cpx #0
    bne irq_next
    lda #$18
    sta $d016
    lda front_mode
    sta $d018
irq_next:
    inc raster_row
    lda raster_next,x
    sta $d012
    jmp irq_return
footer_irq:
    lda buffer_ready
    beq frame_not_ready
    lda front_mode
    eor #$10
    and #$f0
    ora next_charset
    sta front_mode
    lda #0
    sta buffer_ready
    jmp flip_done
frame_not_ready:
    lda frame_counter
    ora frame_counter+1
    beq flip_done
    inc missed_frames
    bne flip_done
    inc missed_frames+1
flip_done:
    lda #$08
    sta $d016
    lda front_mode
    and #$f0
    ora #$0e
    sta $d018
    inc frame_counter
    bne frame_counted
    inc frame_counter+1
frame_counted:
    lda #0
    sta raster_row
    sta $d012
    lda #$9b
    sta $d011
    lda #<prism_arm
    sta $fffe
    lda #>prism_arm
    sta $ffff
irq_return:
    pla
    tay
    pla
    tax
    pla
    rti
nmi:
    rti

state:
frame_counter: .word 0
consumed_frame: .byte 0
buffer_ready: .byte 0
front_mode: .byte $c0
next_charset: .byte 0
raster_row: .byte 0
animation_clock: .word 0
missed_frames: .word 0
completed_frames: .word 0
render_cycles: .word 0
peak_cycles: .word 0
travel_phase: .byte 0
ripple_clock: .byte 0
sprite_high: .byte 0
paused: .byte 0
old_space: .byte 0
song_tick: .byte 0
song_step: .byte 0
core_front: .byte $50
core_back: .byte $51
core_half: .byte 0
band_phases: .fill 24,0
state_end:
sprite_masks: .byte $10,0,$20,0,$40,0,$80,0
kick_high: .byte $30,$16,$0c,$06,$03
