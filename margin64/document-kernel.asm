; Foreground document primitives. Public _fastcall passes one word in A/X.
; $fb-$fe are call-clobbered scratch; software SP/FP $02-$05 are untouched.
; Cursor navigation does not move the gap. Only an edit requests relocation.
; Active bytes are $7200-$aff9 with BASIC hidden ($01=$36).

_doc_get:
    sta $fb
    stx $fc
    cpx _doc+5
    bcc md_get_in_range
    bne md_get_missing
    cmp _doc+4
    bcs md_get_missing
md_get_in_range:
    cpx _doc+1
    bcc md_get_physical
    bne md_get_after_gap
    cmp _doc
    bcc md_get_physical
md_get_after_gap:
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
md_get_physical:
    clc
    lda $fc
    adc #$72
    sta $fc
    ldy #0
    lda ($fb),y
    ldx #0
    rts
md_get_missing:
    lda #0
    tax
    rts

_doc_move_gap:
    cpx _doc+5
    bcc md_move_valid
    bne md_move_clamp
    cmp _doc+4
    bcc md_move_valid
    beq md_move_valid
md_move_clamp:
    lda _doc+4
    ldx _doc+5
md_move_valid:
    sta md_position
    stx md_position+1
    cpx _doc+1
    bcc md_move_left
    bne md_move_right
    cmp _doc
    bcc md_move_left
    bne md_move_right
    rts

md_move_left:
    sec
    lda _doc
    sbc md_position
    sta _margin_move_count
    lda _doc+1
    sbc md_position+1
    sta _margin_move_count+1
    sec
    lda _doc+2
    sbc _margin_move_count
    sta _doc+2
    sta _margin_move_to
    lda _doc+3
    sbc _margin_move_count+1
    sta _doc+3
    clc
    adc #$72
    sta _margin_move_to+1
    lda md_position
    sta _margin_move_from
    lda md_position+1
    clc
    adc #$72
    sta _margin_move_from+1
    jmp md_move_commit

md_move_right:
    sec
    lda md_position
    sbc _doc
    sta _margin_move_count
    lda md_position+1
    sbc _doc+1
    sta _margin_move_count+1
    lda _doc
    sta _margin_move_to
    lda _doc+1
    clc
    adc #$72
    sta _margin_move_to+1
    lda _doc+2
    sta _margin_move_from
    lda _doc+3
    clc
    adc #$72
    sta _margin_move_from+1
    clc
    lda _doc+2
    adc _margin_move_count
    sta _doc+2
    lda _doc+3
    adc _margin_move_count+1
    sta _doc+3
md_move_commit:
    lda md_position
    sta _doc
    lda md_position+1
    sta _doc+1
    jmp _margin_move_bytes

md_position: .word 0

; Exchange max(removed,inserted) bytes without retaining two versions.
; The previous payload is read before either destination is written. Active
; document source starts at end and destination at gap, so forward exchange
; also works when the gap is empty. The absolute indexed store is patched
; only by this foreground routine; neither IRQ nor NMI calls document code.
_margin_exchange_bytes:
    lda #0
    sta $fb
    lda #$63
    sta $fc
    lda _doc+2
    sta $fd
    lda _doc+3
    clc
    adc #$72
    sta $fe
    lda _doc
    sta md_exchange_store+1
    lda _doc+1
    clc
    adc #$72
    sta md_exchange_store+2
    lda _margin_edit+2
    sta md_remove_left
    lda _margin_edit+3
    sta md_remove_left+1
    lda _margin_edit+6
    sta md_insert_left
    lda _margin_edit+7
    sta md_insert_left+1
    ldy #0
md_exchange_loop:
    lda md_remove_left
    ora md_remove_left+1
    ora md_insert_left
    ora md_insert_left+1
    beq md_exchange_done
    lda ($fb),y
    tax
    lda md_remove_left
    ora md_remove_left+1
    beq md_exchange_insert
    lda ($fd),y
    sta ($fb),y
    lda md_remove_left
    bne md_exchange_remove_low
    dec md_remove_left+1
md_exchange_remove_low:
    dec md_remove_left
md_exchange_insert:
    lda md_insert_left
    ora md_insert_left+1
    beq md_exchange_next
    txa
md_exchange_store:
    sta $ffff,y
    lda md_insert_left
    bne md_exchange_insert_low
    dec md_insert_left+1
md_exchange_insert_low:
    dec md_insert_left
md_exchange_next:
    iny
    bne md_exchange_loop
    inc $fc
    inc $fe
    inc md_exchange_store+2
    jmp md_exchange_loop
md_exchange_done:
    rts

md_remove_left: .word 0
md_insert_left: .word 0

; EditRequest: position+0, removed+2, inserted pointer+4, count+6.
; C has already checked bounds, available document bytes and inverse space.
; This kernel cannot reject an edit after history admission.
_margin_apply_edit:
    lda _margin_edit
    ldx _margin_edit+1
    jsr _doc_move_gap
    lda _margin_edit+6
    ora _margin_edit+7
    beq _margin_finish_edit
    lda _margin_edit+4
    sta _margin_move_from
    lda _margin_edit+5
    sta _margin_move_from+1
    lda _doc
    sta _margin_move_to
    lda _doc+1
    clc
    adc #$72
    sta _margin_move_to+1
    lda _margin_edit+6
    sta _margin_move_count
    lda _margin_edit+7
    sta _margin_move_count+1
    jsr _margin_move_bytes

; Complete either an ordinary physical edit or an inverse-payload exchange.
; Cursor/selection normally collapse after the insertion; Undo then restores
; its recorded logical endpoints. Viewport top follows edits before it.
_margin_finish_edit:
    clc
    lda _doc+2
    adc _margin_edit+2
    sta _doc+2
    lda _doc+3
    adc _margin_edit+3
    sta _doc+3
    clc
    lda _doc
    adc _margin_edit+6
    sta _doc
    lda _doc+1
    adc _margin_edit+7
    sta _doc+1
    sec
    lda _doc+4
    sbc _margin_edit+2
    sta _doc+4
    lda _doc+5
    sbc _margin_edit+3
    sta _doc+5
    clc
    lda _doc+4
    adc _margin_edit+6
    sta _doc+4
    lda _doc+5
    adc _margin_edit+7
    sta _doc+5
    clc
    lda _margin_edit
    adc _margin_edit+6
    sta _doc+6
    sta _doc+8
    lda _margin_edit+1
    adc _margin_edit+7
    sta _doc+7
    sta _doc+9
    lda #0
    sta _doc+12
    sta _doc+15
    lda #1
    sta _doc+13
    lda _doc+16
    cmp #2
    bne md_dirty_fresh
    lda _margin_edit+1
    cmp _document_dirty_from+1
    bcc md_dirty_begin
    bne md_dirty_extend
    lda _margin_edit
    cmp _document_dirty_from
    bcs md_dirty_extend
md_dirty_begin:
    lda _margin_edit
    sta _document_dirty_from
    lda _margin_edit+1
    sta _document_dirty_from+1
md_dirty_extend:
    ; The previous exclusive endpoint is in pre-edit coordinates. If it is
    ; past the removed span, shift it by the admitted delta; otherwise the
    ; new insertion end covers/clamps it. This is max(transformed-old,new).
    clc
    lda _margin_edit
    adc _margin_edit+2
    sta $fb
    lda _margin_edit+1
    adc _margin_edit+3
    sta $fc
    lda _document_dirty_to+1
    cmp $fc
    bcc md_dirty_new_end
    bne md_dirty_shift_end
    lda _document_dirty_to
    cmp $fb
    bcc md_dirty_new_end
md_dirty_shift_end:
    sec
    lda _document_dirty_to
    sbc _margin_edit+2
    sta _document_dirty_to
    lda _document_dirty_to+1
    sbc _margin_edit+3
    sta _document_dirty_to+1
    clc
    lda _document_dirty_to
    adc _margin_edit+6
    sta _document_dirty_to
    lda _document_dirty_to+1
    adc _margin_edit+7
    sta _document_dirty_to+1
    jmp md_dirty_mark
md_dirty_fresh:
    lda _margin_edit
    sta _document_dirty_from
    lda _margin_edit+1
    sta _document_dirty_from+1
md_dirty_new_end:
    clc
    lda _margin_edit
    adc _margin_edit+6
    sta _document_dirty_to
    lda _margin_edit+1
    adc _margin_edit+7
    sta _document_dirty_to+1
md_dirty_mark:
    lda #2
    sta _doc+16
    lda _doc+11
    cmp _margin_edit+1
    bcc md_finish_done
    bne md_finish_top
    lda _doc+10
    cmp _margin_edit
    bcc md_finish_done
    beq md_finish_done
md_finish_top:
    clc
    lda _margin_edit
    adc _margin_edit+2
    sta $fb
    lda _margin_edit+1
    adc _margin_edit+3
    sta $fc
    lda _doc+11
    cmp $fc
    bcc md_finish_clamp
    bne md_finish_shift
    lda _doc+10
    cmp $fb
    bcc md_finish_clamp
md_finish_shift:
    sec
    lda _doc+10
    sbc _margin_edit+2
    sta _doc+10
    lda _doc+11
    sbc _margin_edit+3
    sta _doc+11
    clc
    lda _doc+10
    adc _margin_edit+6
    sta _doc+10
    lda _doc+11
    adc _margin_edit+7
    sta _doc+11
    rts
md_finish_clamp:
    lda _margin_edit
    sta _doc+10
    lda _margin_edit+1
    sta _doc+11
md_finish_done:
    rts

; CopyRequest: destination+0, logical position+2, count+4. The caller checks
; the logical range and destination capacity. At most two physical spans are
; copied through the public libc bridge. The request is consumed as scratch.
_margin_copy_bytes:
    lda _margin_copy+4
    ora _margin_copy+5
    bne md_copy_nonempty
    rts
md_copy_nonempty:
    lda _margin_copy
    sta _margin_move_to
    lda _margin_copy+1
    sta _margin_move_to+1
    lda _margin_copy+3
    cmp _doc+1
    bcc md_copy_before
    beq md_copy_same_page
    jmp md_copy_after
md_copy_same_page:
    lda _margin_copy+2
    cmp _doc
    bcs md_copy_after
md_copy_before:
    sec
    lda _doc
    sbc _margin_copy+2
    sta _margin_move_count
    lda _doc+1
    sbc _margin_copy+3
    sta _margin_move_count+1
    cmp _margin_copy+5
    bcc md_copy_first
    bne md_copy_limit
    lda _margin_move_count
    cmp _margin_copy+4
    bcc md_copy_first
md_copy_limit:
    lda _margin_copy+4
    sta _margin_move_count
    lda _margin_copy+5
    sta _margin_move_count+1
md_copy_first:
    lda _margin_copy+2
    sta _margin_move_from
    lda _margin_copy+3
    clc
    adc #$72
    sta _margin_move_from+1
    jsr _margin_move_bytes
    clc
    lda _margin_move_to
    adc _margin_move_count
    sta _margin_move_to
    lda _margin_move_to+1
    adc _margin_move_count+1
    sta _margin_move_to+1
    clc
    lda _margin_copy+2
    adc _margin_move_count
    sta _margin_copy+2
    lda _margin_copy+3
    adc _margin_move_count+1
    sta _margin_copy+3
    sec
    lda _margin_copy+4
    sbc _margin_move_count
    sta _margin_copy+4
    lda _margin_copy+5
    sbc _margin_move_count+1
    sta _margin_copy+5
md_copy_after:
    lda _margin_copy+4
    ora _margin_copy+5
    beq md_copy_done
    sec
    lda _margin_copy+2
    sbc _doc
    sta _margin_move_from
    lda _margin_copy+3
    sbc _doc+1
    sta _margin_move_from+1
    clc
    lda _margin_move_from
    adc _doc+2
    sta _margin_move_from
    lda _margin_move_from+1
    adc _doc+3
    clc
    adc #$72
    sta _margin_move_from+1
    lda _margin_copy+4
    sta _margin_move_count
    lda _margin_copy+5
    sta _margin_move_count+1
    jmp _margin_move_bytes
md_copy_done:
    rts
