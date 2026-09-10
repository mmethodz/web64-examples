; CYCLE LAB: an editable frame-budget experiment.
; IRQ entry/body, display badlines and a deliberately expensive idle loop.
; Run on PAL. Profiling derives the actual model rather than assuming 312x63.
start:
    sei
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d
    lda #$35
    sta $01
    lda #<raster_irq
    sta $fffe
    lda #>raster_irq
    sta $ffff
    lda #$1b
    sta $d011
    lda #50
    sta $d012
    lda #1
    sta $d019
    sta $d01a
    lda #0
    sta $d020
    sta $d021
    ldx #0
clear:
    lda #32
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    lda #3
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    inx
    bne clear
    cli

; Busy waiting still counts as CPU work. It is not a claim of useful work.
idle:
    jmp idle

raster_irq:
    pha
    txa
    pha
    tya
    pha
    inc $d020
    jsr paint_row
    dec $d020
    lda #1
    sta $d019
    pla
    tay
    pla
    tax
    pla
    rti

; Inspect this named PC range separately from the polling loop.
; LDA absolute,X can have a read page penalty; STA absolute,X is fixed cost.
paint_row:
    ldx #39
paint_loop:
    lda message,x
    sta $0400,x
    dex
    bpl paint_loop
    inc $d021
    rts
paint_end:

; Native screen codes: CYCLE LAB / IRQ + BADLINES + CPU
message:
    .byte 3,25,3,12,5,32,12,1,2,32,47,32,9,18,17,32,43,32,2,1
    .byte 4,12,9,14,5,19,32,43,32,3,16,21,32,32,32,32,32,32,32,32
