; Original three-voice SID sequence: TIDAL LOCK.
; Five PAL frames per sixteenth note, hardware ADSR, pulse-width motion.
music:
    inc song_tick
    lda song_tick
    cmp #5
    bcc music_sustain
    lda #0
    sta song_tick
    ldx song_step
    lda bass_notes,x
    tay
    lda frequency_lo,y
    sta $d400
    lda frequency_hi,y
    sta $d401
    lda #$21
    sta $d404
    lda lead_notes,x
    tay
    lda frequency_lo,y
    sta $d407
    lda frequency_hi,y
    sta $d408
    lda #$41
    sta $d40b
    txa
    and #3
    bne hat
    lda #$11
    sta $d412
    lda #$f4
    sta $d414
    jmp note_started
hat:
    lda #$81
    sta $d412
    lda #$05
    sta $d414
note_started:
    inc song_step
    lda song_step
    and #127
    sta song_step
music_sustain:
    ldx animation_clock
    lda pulse_width,x
    sta $d409
    lda #$06
    sta $d40a
    ldx song_tick
    lda kick_high,x
    sta $d40f
    lda #0
    sta $d40e
    cpx #4
    bne music_done
    lda #$20
    sta $d404
    lda #$40
    sta $d40b
    lda #0
    sta $d412
music_done:
    rts
