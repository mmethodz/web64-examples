; Aurora plasma kernel, included inside plasma_frame().
; No RTS here: the enclosing C function supplies its return.
    inc ap_phase
    inc ap_phase
    lda ap_phase
    sta ap_angle
    ldy #0
ap_columns:
    ldx ap_angle
    lda ap_sine,x
    sta ap_columns_cache,y
    clc
    lda ap_angle
    adc #5
    sta ap_angle
    iny
    cpy #40
    bne ap_columns

    lda #<$0478
    sta ap_screen_store+1
    lda #>$0478
    sta ap_screen_store+2
    lda #<$d878
    sta ap_colour_store+1
    lda #>$d878
    sta ap_colour_store+2
    lda ap_phase
    eor #$ff
    sta ap_angle
    lda #18
    sta ap_rows
ap_row:
    ldx ap_angle
    lda ap_sine,x
    sta ap_add_row+1
    ldy #39
ap_cell:
    lda ap_columns_cache,y
    clc
ap_add_row:
    adc #0
    lsr
    tax
    lda ap_palette,x
ap_colour_store:
    sta $d878,y
    lda ap_glyphs,x
ap_screen_store:
    sta $0478,y
    dey
    bpl ap_cell
    clc
    lda ap_screen_store+1
    adc #40
    sta ap_screen_store+1
    bcc ap_screen_ok
    inc ap_screen_store+2
ap_screen_ok:
    clc
    lda ap_colour_store+1
    adc #40
    sta ap_colour_store+1
    bcc ap_colour_ok
    inc ap_colour_store+2
ap_colour_ok:
    clc
    lda ap_angle
    adc #9
    sta ap_angle
    dec ap_rows
    bne ap_row
    jmp ap_done
ap_phase: .byte 0
ap_angle: .byte 0
ap_rows: .byte 0
ap_columns_cache: .fill 40,0
ap_palette:
    .byte 6,6,6,14,14,3,3,1,1,3,3,14,14,6,6,4
    .byte 4,4,10,10,7,7,1,1,7,7,10,10,4,4,6,6
ap_glyphs:
    .byte 128,130,133,137,141,143,141,139,135,132,130,133,137,141,143,141
    .byte 137,133,130,133,137,141,143,141,137,133,130,133,137,141,143,139
ap_sine:
    .byte 16,16,16,17,17,17,18,18,19,19,19,20,20,20,21,21
    .byte 21,22,22,22,23,23,23,24,24,24,25,25,25,26,26,26
    .byte 26,27,27,27,27,28,28,28,28,29,29,29,29,29,30,30
    .byte 30,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31
    .byte 31,31,31,31,31,31,31,31,31,31,31,30,30,30,30,30
    .byte 30,30,30,29,29,29,29,29,28,28,28,28,27,27,27,27
    .byte 26,26,26,26,25,25,25,24,24,24,23,23,23,22,22,22
    .byte 21,21,21,20,20,20,19,19,19,18,18,17,17,17,16,16
    .byte 16,15,15,14,14,14,13,13,12,12,12,11,11,11,10,10
    .byte 10,9,9,9,8,8,8,7,7,7,6,6,6,5,5,5
    .byte 5,4,4,4,4,3,3,3,3,2,2,2,2,2,1,1
    .byte 1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1
    .byte 1,1,1,2,2,2,2,2,3,3,3,3,4,4,4,4
    .byte 5,5,5,5,6,6,6,7,7,7,8,8,8,9,9,9
    .byte 10,10,10,11,11,11,12,12,12,13,13,14,14,14,15,15
ap_done:
