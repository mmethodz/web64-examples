; Logical word/paragraph navigation over the two physical document spans.
; Commands never move the gap, touch text/history, or consume pending dirty2.
; Public _fastcall inputs use A (signed direction) or A/X (paragraph number).
; $fb/$fc = physical cursor, $fd/$fe = bytes before the next gap/end boundary.
; Indexed chunks amortize 16-bit bookkeeping across up to 256 document bytes.

_move_word:
    cmp #$80
    bcs mn_move_left
    jsr mn_forward_setup
    lda #0
    sta mn_kind
    jsr mn_forward
    inc mn_kind
    jmp mn_forward
mn_move_left:
    jsr mn_backward_setup
    lda #1
    sta mn_kind
    jsr mn_backward
    dec mn_kind
    jmp mn_backward

_select_word:
    lda #0
    beq mn_select
_select_paragraph:
    lda #2
mn_select:
    sta mn_kind
    jsr mn_backward_setup
    jsr mn_backward
    lda _doc+6
    sta _doc+8
    lda _doc+7
    sta _doc+9
    jsr mn_forward_setup
    jsr mn_forward
    lda mn_kind
    cmp #2
    bne mn_selected
    lda _doc+6
    cmp _doc+4
    bne mn_include_break
    lda _doc+7
    cmp _doc+5
    beq mn_selected
mn_include_break:
    inc _doc+6
    bne mn_selected
    inc _doc+7
mn_selected:
    lda #1
    sta _doc+12
    rts

_goto_paragraph:
    sta mn_paragraph
    stx mn_paragraph+1
    lda #0
    sta _doc+6
    sta _doc+7
    lda mn_paragraph
    ora mn_paragraph+1
    beq mn_goto_done
    jsr mn_decrement_paragraph
    beq mn_goto_done
    jsr mn_forward_setup
    lda #3
    sta mn_kind
    jmp mn_forward
mn_goto_done:
    rts

; Word semantics deliberately match the C editing policy: digits, $41-$5a,
; and $c1-$da. Other PETSCII, tabs, layout/style tokens are separators.
; A is preserved, C is set exactly for a word byte.
mn_is_word:
    cmp #65
    bcc mn_word_digit
    cmp #91
    bcc mn_word_yes
    cmp #193
    bcc mn_word_no
    cmp #219
    bcc mn_word_yes
mn_word_no:
    clc
    rts
mn_word_digit:
    cmp #48
    bcc mn_word_no
    cmp #58
    bcs mn_word_no
mn_word_yes:
    sec
    rts

; Map insertion position, including EOF, without reading any gap byte.
mn_map:
    lda #0
    sta mn_part
    lda _doc+6
    sta $fb
    lda _doc+7
    sta $fc
    cmp _doc+1
    bcc mn_mapped
    bne mn_after_gap
    lda $fb
    cmp _doc
    bcc mn_mapped
mn_after_gap:
    inc mn_part
    sec
    lda $fb
    sbc _doc
    sta $fb
    lda $fc
    sbc _doc+1
    sta $fc
    clc
    lda $fb
    adc _doc+2
    sta $fb
    lda $fc
    adc _doc+3
    sta $fc
mn_mapped:
    clc
    lda $fc
    adc #$72
    sta $fc
    rts

mn_forward_setup:
    jsr mn_map
    lda mn_part
    beq mn_forward_prefix
    lda _doc+4
    ldx _doc+5
    jmp mn_forward_bound
mn_forward_prefix:
    lda _doc
    ldx _doc+1
mn_forward_bound:
    sec
    sbc _doc+6
    sta $fd
    txa
    sbc _doc+7
    sta $fe
    rts

mn_backward_setup:
    jsr mn_map
    lda _doc+6
    sta $fd
    lda _doc+7
    sta $fe
    lda mn_part
    beq mn_backward_ready
    sec
    lda $fd
    sbc _doc
    sta $fd
    lda $fe
    sbc _doc+1
    sta $fe
mn_backward_ready:
    rts

mn_forward:
    lda $fd
    ora $fe
    bne mn_forward_chunk
    lda mn_part
    bne mn_forward_done
    inc mn_part
    lda _doc+2
    sta $fb
    clc
    lda _doc+3
    adc #$72
    sta $fc
    lda _doc+4
    ldx _doc+5
    jsr mn_forward_bound
    jmp mn_forward
mn_forward_done:
    rts
mn_forward_chunk:
    jsr mn_chunk_size
    ldy #0
    lda mn_kind
    beq mn_forward_word
    cmp #1
    beq mn_forward_separator
    cmp #2
    beq mn_forward_paragraph
    jmp mn_forward_goto
mn_forward_word:
    lda ($fb),y
    jsr mn_is_word
    bcc mn_forward_stop
    iny
    cpy mn_span
    bne mn_forward_word
    beq mn_forward_full
mn_forward_separator:
    lda ($fb),y
    jsr mn_is_word
    bcs mn_forward_stop
    iny
    cpy mn_span
    bne mn_forward_separator
    beq mn_forward_full
mn_forward_paragraph:
    lda ($fb),y
    cmp #13
    beq mn_forward_stop
    iny
    cpy mn_span
    bne mn_forward_paragraph
    beq mn_forward_full
mn_forward_goto:
    lda ($fb),y
    cmp #13
    bne mn_forward_goto_next
    jsr mn_decrement_paragraph
    bne mn_forward_goto_next
    iny
    bne mn_forward_stop
    ; A CR at index255 is included, so zero here means 256, not no progress.
    ldx #1
    tya
    jmp mn_forward_commit
mn_forward_goto_next:
    iny
    cpy mn_span
    bne mn_forward_goto
mn_forward_full:
    jsr mn_full_amount
    jsr mn_forward_commit
    jmp mn_forward
mn_forward_stop:
    tya
    ldx #0
mn_forward_commit:
    sta mn_amount
    stx mn_amount+1
    clc
    adc _doc+6
    sta _doc+6
    txa
    adc _doc+7
    sta _doc+7
    clc
    lda $fb
    adc mn_amount
    sta $fb
    lda $fc
    adc mn_amount+1
    sta $fc
    jmp mn_consume

mn_backward:
    lda $fd
    ora $fe
    bne mn_backward_chunk
    lda mn_part
    beq mn_backward_done
    dec mn_part
    lda _doc
    sta $fb
    sta $fd
    lda _doc+1
    sta $fe
    clc
    adc #$72
    sta $fc
    jmp mn_backward
mn_backward_done:
    rts
mn_backward_chunk:
    jsr mn_chunk_size
    jsr mn_full_amount
    sta mn_amount
    stx mn_amount+1
    sec
    lda $fb
    sbc mn_amount
    sta $fb
    lda $fc
    sbc mn_amount+1
    sta $fc
    ldy mn_span
    dey
    lda mn_kind
    beq mn_backward_word
    cmp #1
    beq mn_backward_separator
    jmp mn_backward_paragraph
mn_backward_word:
    lda ($fb),y
    jsr mn_is_word
    bcc mn_backward_stop
    dey
    cpy #$ff
    bne mn_backward_word
    beq mn_backward_full
mn_backward_separator:
    lda ($fb),y
    jsr mn_is_word
    bcs mn_backward_stop
    dey
    cpy #$ff
    bne mn_backward_separator
    beq mn_backward_full
mn_backward_paragraph:
    lda ($fb),y
    cmp #13
    beq mn_backward_stop
    dey
    cpy #$ff
    bne mn_backward_paragraph
mn_backward_full:
    jsr mn_backward_commit
    jmp mn_backward
mn_backward_stop:
    ; Pointer is the chunk base. Restore the exclusive cursor to base+Y+1,
    ; then consume only bytes after the first mismatching byte.
    tya
    sec
    adc $fb
    sta $fb
    lda $fc
    adc #0
    sta $fc
    tya
    eor #$ff
    clc
    adc mn_span
    sta mn_amount
    lda #0
    sta mn_amount+1
mn_backward_commit:
    sec
    lda _doc+6
    sbc mn_amount
    sta _doc+6
    lda _doc+7
    sbc mn_amount+1
    sta _doc+7
mn_consume:
    sec
    lda $fd
    sbc mn_amount
    sta $fd
    lda $fe
    sbc mn_amount+1
    sta $fe
    rts

mn_chunk_size:
    lda #0
    ldx $fe
    bne mn_chunk_full
    lda $fd
mn_chunk_full:
    sta mn_span
    rts
mn_full_amount:
    ldx #0
    lda mn_span
    bne mn_amount_ready
    inx
mn_amount_ready:
    rts
mn_decrement_paragraph:
    lda mn_paragraph
    bne mn_paragraph_low
    dec mn_paragraph+1
mn_paragraph_low:
    dec mn_paragraph
    lda mn_paragraph
    ora mn_paragraph+1
    rts

mn_part: .byte 0
mn_kind: .byte 0
mn_span: .byte 0
mn_amount: .word 0
mn_paragraph: .word 0
