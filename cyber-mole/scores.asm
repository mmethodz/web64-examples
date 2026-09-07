; Versioned, bounded high-score persistence through the native Web64 disk API.
load_scores:
    jsr disk_enter
    cm_load score_name, 6, 8, SCORES, $cf40
    sta disk_status
    jsr disk_leave
    lda disk_status
    and #$bf
    bne default_score_table
    jsr cm_last_end
    cmp #$40
    bne default_score_table
    cpx #$cf
    bne default_score_table
    lda SCORES
    cmp #67
    bne default_score_table
    lda SCORES+1
    cmp #89
    bne default_score_table
    lda SCORES+2
    cmp #83
    bne default_score_table
    lda SCORES+3
    cmp #1
    bne default_score_table
    jsr score_checksum
    cmp SCORES+4
    bne default_score_table
    jmp score_table_loaded
default_score_table:
    ldx #63
copy_default_scores:
    lda default_scores,x
    sta SCORES,x
    dex
    bpl copy_default_scores
score_table_loaded:
    lda #1
    sta high_loaded
    rts

score_checksum:
    ldx #63
    lda #0
score_checksum_loop:
    eor SCORES,x
    dex
    cpx #7
    bne score_checksum_loop
    rts

cyber_scores:
    lda #0
    sta game_mode
    sta score_save_finished
    jsr clear_screen
    lda #<score_title
    sta SRC
    lda #>score_title
    sta SRC+1
    lda #<(SCREEN+90)
    sta PTR
    lda #>(SCREEN+90)
    sta PTR+1
    jsr write_text
    lda #<game_over_text
    sta SRC
    lda #>game_over_text
    sta SRC+1
    lda won_game
    beq score_not_win
    lda #<complete_text
    sta SRC
    lda #>complete_text
    sta SRC+1
score_not_win:
    lda #<(SCREEN+202)
    sta PTR
    lda #>(SCREEN+202)
    sta PTR+1
    jsr write_text
    ; Find the first strictly lower six-digit score, preserving ties.
    ldx #0
find_rank:
    lda score+2
    cmp SCORES+10,x
    bcc next_rank
    bne insert_score
    lda score+1
    cmp SCORES+9,x
    bcc next_rank
    bne insert_score
    lda score
    cmp SCORES+8,x
    bcc next_rank
    bne insert_score
next_rank:
    txa
    clc
    adc #6
    tax
    cpx #30
    bne find_rank
    lda #255
    sta rank_offset
    jmp score_draw
insert_score:
    stx rank_offset
    ldx #23
shift_scores:
    cpx rank_offset
    bcc store_score
    lda SCORES+8,x
    sta SCORES+14,x
    dex
    bpl shift_scores
store_score:
    ldx rank_offset
    lda score
    sta SCORES+8,x
    lda score+1
    sta SCORES+9,x
    lda score+2
    sta SCORES+10,x
    lda #2
    sta SCORES+11,x
    lda #9
    sta SCORES+12,x
    lda #20
    sta SCORES+13,x
score_draw:
    jsr draw_scores
    lda rank_offset
    cmp #255
    bne scores_have_entry
    jmp scores_no_entry
scores_have_entry:
    lda #<score_enter
    sta SRC
    lda #>score_enter
    sta SRC+1
    lda #<(SCREEN+642)
    sta PTR
    lda #>(SCREEN+642)
    sta PTR+1
    jsr write_text
    lda #<score_help
    sta SRC
    lda #>score_help
    sta SRC+1
    lda #<(SCREEN+720)
    sta PTR
    lda #>(SCREEN+720)
    sta PTR+1
    jsr write_text
    lda #0
    sta initials_cursor
    sta score_joy_old
    jsr wait_release
initials_loop:
    jsr score_frame
    jsr read_joystick
    lda joy
    cmp score_joy_old
    beq initials_loop
    sta score_joy_old
    and #16
    bne initials_done
    lda rank_offset
    clc
    adc initials_cursor
    tax
    lda joy
    and #1
    beq initials_not_up
    inc SCORES+11,x
    lda SCORES+11,x
    cmp #27
    bcc initials_redraw
    lda #1
    sta SCORES+11,x
    jmp initials_redraw
initials_not_up:
    lda joy
    and #2
    beq initials_not_down
    dec SCORES+11,x
    bne initials_redraw
    lda #26
    sta SCORES+11,x
    jmp initials_redraw
initials_not_down:
    lda joy
    and #4
    beq initials_not_left
    lda initials_cursor
    beq initials_redraw
    dec initials_cursor
    jmp initials_redraw
initials_not_left:
    lda joy
    and #8
    beq initials_redraw
    lda initials_cursor
    cmp #2
    bcs initials_redraw
    inc initials_cursor
initials_redraw:
    jsr draw_scores
    jmp initials_loop
initials_done:
    jsr wait_release
    jsr score_checksum
    sta SCORES+4
    lda #<score_saving
    sta SRC
    lda #>score_saving
    sta SRC+1
    jsr write_score_status
    jsr disk_enter
    jsr save_score_file
    sta disk_status
    jsr disk_leave
    lda #1
    sta score_save_finished
scores_no_entry:
    lda #<score_saved
    sta SRC
    lda #>score_saved
    sta SRC+1
    lda disk_status
    and #$bf
    beq score_saved_message
    lda #<score_ram
    sta SRC
    lda #>score_ram
    sta SRC+1
score_saved_message:
    jsr write_score_status
    jsr wait_release
score_wait:
    jsr score_frame
    jsr read_joystick
    lda joy
    and #16
    beq score_wait
    jmp wait_release

; Saving, saved and RAM-only messages have different lengths. Own the whole
; bottom row, including its hires color, so no previous suffix can survive.
write_score_status:
    ldx #39
score_status_clear:
    lda #32
    sta SCREEN+880,x
    lda #3
    sta COLOR+880,x
    dex
    bpl score_status_clear
    lda #<(SCREEN+882)
    sta PTR
    lda #>(SCREEN+882)
    sta PTR+1
    jmp write_text

draw_scores:
    ldx #0
    stx score_row
score_row_loop:
    ldx score_row
    lda score_row_lo,x
    sta PTR
    lda score_row_hi,x
    sta PTR+1
    txa
    asl
    sta TEMP
    asl
    clc
    adc TEMP
    tax
    ldy #0
    lda score_row
    clc
    adc #49
    sta (PTR),y
    iny
    lda #46
    sta (PTR),y
    ldy #4
    lda SCORES+11,x
    sta (PTR),y
    iny
    lda SCORES+12,x
    sta (PTR),y
    iny
    lda SCORES+13,x
    sta (PTR),y
    ldy #10
    lda SCORES+10,x
    jsr score_bcd
    lda SCORES+9,x
    jsr score_bcd
    lda SCORES+8,x
    jsr score_bcd
    inc score_row
    lda score_row
    cmp #5
    bne score_row_loop
    rts
score_bcd:
    pha
    lsr
    lsr
    lsr
    lsr
    ora #48
    sta (PTR),y
    iny
    pla
    and #15
    ora #48
    sta (PTR),y
    iny
    rts
score_frame:
    jsr cyber_wait_frame
    jsr tick_animation
    jsr tick_music
    lda bit_anim+6
    clc
    adc #$c0
    sta $07f8
    lda #1
    sta $d015
    lda #0
    sta $d010
    lda #170
    sta $d000
    lda #204
    sta $d001
    lda frame_counter
    lsr
    lsr
    and #7
    tax
    lda pulse_colors,x
    sta $d027
    lda rank_offset
    cmp #255
    beq score_frame_done
    ldx #0
score_cursor_row:
    cmp #6
    bcc score_cursor_found
    sec
    sbc #6
    inx
    bne score_cursor_row
score_cursor_found:
    lda score_row_lo,x
    clc
    adc #4
    sta PTR
    lda score_row_hi,x
    adc #$d4
    sta PTR+1
    ldy #2
    lda #3
score_cursor_clear:
    sta (PTR),y
    dey
    bpl score_cursor_clear
    ldy initials_cursor
    lda frame_counter
    and #8
    lsr
    lsr
    lsr
    clc
    adc #6
    sta (PTR),y
score_frame_done:
    rts
score_save_finished: .byte 0
rank_offset: .byte 255
score_joy_old: .byte 0
initials_cursor: .byte 0
score_row: .byte 0
score_row_lo: .byte <(SCREEN+291),<(SCREEN+371),<(SCREEN+451),<(SCREEN+531),<(SCREEN+611)
score_row_hi: .byte >(SCREEN+291),>(SCREEN+371),>(SCREEN+451),>(SCREEN+531),>(SCREEN+611)
