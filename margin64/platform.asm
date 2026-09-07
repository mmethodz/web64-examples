; Margin64: hardware access and bounded viewport kernels.
; Normal KERNAL IRQ/keyboard/IEC operation remains available with $01=$36.
; Only short banked accesses and the post-validation commit hide ROM/I/O.
; $fb-$fe are call-scoped scratch, never the compiler's software SP/FP.

asm_platform_init:
    lda #$36
    sta $01
    lda $00
    ora #7
    sta $00
    lda $dd00
    and #$fc
    ora #3
    sta $dd00
    lda #$1b
    sta $d011
    lda #8
    sta $d016
    lda #$16
    sta $d018
    lda #0
    sta $d015
    sta $d020
    sta $d021
    lda #$80
    sta $0291 ; lock lower/uppercase ROM; Shift+CBM must not switch the font
    sta $028a ; KERNAL repeats text; asm_key suppresses held function commands
    lda #$ff
    sta $cc   ; BLNSW: editor owns the caret; keep KERNAL IRQ/GETIN, not its cursor
    lda #0
    sta $c6
    sta mv_cursor_visible
    sta mv_command_key
    jsr $ff90 ; SETMSG: application owns the screen, including IEC errors
    ; Safe RAM vectors are outside both document payloads. SEI alone would
    ; not protect banked candidate access from RESTORE/CIA2 NMI.
    lda #<mv_banked_nmi
    sta $fffa
    sta $fffe
    lda #>mv_banked_nmi
    sta $fffb
    sta $ffff
    lda #<asm_platform_init
    sta $fffc
    lda #>asm_platform_init
    sta $fffd
    cli
    rts

mv_banked_nmi:
    pha
    lda $01
    pha
    lda #$36
    sta $01
    lda $dd0d
    pla
    sta $01
    pla
    rti

asm_key:
    ; Drain already queued function-key repeats before rearming. This applies
    ; inside modal menus as well as the editor: a held F1 must not close its
    ; menu, and an F8 queued during IEC Save must not start another Save.
    lda $c5
    cmp #64
    bne mv_key_get
    lda $c6
    bne mv_key_get
    sta mv_command_key
mv_key_get:
    lda $028d
    sta _key_modifiers
    jsr $ffe4
    cmp #133
    bcc mv_key_return
    cmp #141
    bcs mv_key_return
    cmp mv_command_key
    beq mv_key_repeat
    sta mv_command_key
mv_key_return:
    ldx #0
    rts
mv_key_repeat:
    lda #0
    beq mv_key_return
mv_command_key: .byte 0
asm_jiffy:
    lda $a2
    ldx #0
    rts

asm_bank_read:
    lda _bank_address
    sta $fb
    lda _bank_address+1
    sta $fc
    php
    sei
    lda $01
    pha
    lda #$30
    sta $01
    ldy #0
    lda ($fb),y
    sta _bank_value
    pla
    sta $01
    plp
    rts
asm_bank_write:
    lda _bank_address
    sta $fb
    lda _bank_address+1
    sta $fc
    php
    sei
    lda $01
    pha
    lda #$30
    sta $01
    ldy #0
    lda _bank_value
    sta ($fb),y
    pla
    sta $01
    plp
    rts

asm_commit_candidate:
    ; Caller has checked version, size, character repertoire and checksum.
    ; No disk access/fallible operation occurs after this commit point.
    lda #0
    sta $fb
    sta $fd
    lda #$b0
    sta $fc
    lda #$72
    sta $fe
    ldx _bank_length+1
    ldy #0
    php
    sei
    lda $01
    pha
    lda #$30
    sta $01
    cpx #0
    beq mv_commit_tail
mv_commit_page:
    lda ($fb),y
    sta ($fd),y
    iny
    bne mv_commit_page
    inc $fc
    inc $fe
    dex
    bne mv_commit_page
mv_commit_tail:
    cpy _bank_length
    beq mv_commit_done
    lda ($fb),y
    sta ($fd),y
    iny
    bne mv_commit_tail
mv_commit_done:
    pla
    sta $01
    plp
    rts

asm_clear_screen:
    jsr asm_cursor_hide
    ldx #0
mv_clear:
    lda #32
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $06e8,x
    lda _theme_foreground
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $dae8,x
    inx
    bne mv_clear
    lda _theme_background
    sta $d021
    rts

; Return the next raw logical byte in A. This bounded scan traverses a gap
; exactly once without shifting the document or building a permanent line index.
mv_get_byte:
    lda mv_pos+1
    cmp _doc+1
    bne mv_read
    lda mv_pos
    cmp _doc
    bne mv_read
    lda _doc+2
    sta $fb
    lda _doc+3
    clc
    adc #$72
    sta $fc
mv_read:
    ldy #0
    lda ($fb),y
    inc $fb
    bne mv_read_no_carry
    inc $fc
mv_read_no_carry:
    inc mv_pos
    bne mv_read_done
    inc mv_pos+1
mv_read_done:
    rts

asm_layout_line:
    lda #0
    sta mv_scan
    jmp mv_layout_begin
asm_scan_line:
    lda #1
    sta mv_scan
mv_layout_begin:
    lda _view_start
    sta mv_pos
    lda _view_start+1
    sta mv_pos+1
    ; Map logical start to a physical gap-buffer address once per row.
    lda _view_start+1
    cmp _doc+1
    bcc mv_start_before_gap
    bne mv_start_after_gap
    lda _view_start
    cmp _doc
    bcc mv_start_before_gap
mv_start_after_gap:
    lda _view_start
    sec
    sbc _doc
    sta $fb
    lda _view_start+1
    sbc _doc+1
    sta $fc
    lda $fb
    clc
    adc _doc+2
    sta $fb
    lda $fc
    adc _doc+3
    clc
    adc #$72
    sta $fc
    jmp mv_start_ready
mv_start_before_gap:
    lda _view_start
    sta $fb
    lda _view_start+1
    clc
    adc #$72
    sta $fc
mv_start_ready:
    lda _view_style
    sta mv_style
    lda #0
    sta mv_col
    sta mv_break_count
    sta _view_flags
    lda mv_scan
    beq mv_line_loop
    jmp mv_scan_loop
mv_line_loop:
    lda mv_pos+1
    cmp _doc+5
    bne mv_not_end
    lda mv_pos
    cmp _doc+4
    bne mv_not_end
    jmp mv_line_done
mv_not_end:
    lda mv_col
    cmp _view_width
    bcc mv_line_has_room
    jmp mv_line_wrap
mv_line_has_room:
    lda mv_pos
    sta mv_char_pos
    lda mv_pos+1
    sta mv_char_pos+1
    jsr mv_get_byte
    cmp #1
    beq mv_bold
    cmp #2
    beq mv_underline
    cmp #3
    beq mv_emphasis
    cmp #13
    bne mv_not_paragraph
    jmp mv_line_delimiter
mv_not_paragraph:
    cmp #10
    bne mv_not_hard_line
    jmp mv_line_delimiter
mv_not_hard_line:
    cmp #12
    bne mv_not_page
    jmp mv_line_delimiter
mv_not_page:
    cmp #9
    beq mv_tab
    sta mv_char
    jsr mv_put_char
    lda mv_char
    cmp #32
    bne mv_line_loop
    lda mv_col
    sta mv_break_count
    lda mv_pos
    sta mv_break_pos
    lda mv_pos+1
    sta mv_break_pos+1
    lda mv_style
    sta mv_break_style
    jmp mv_line_loop
mv_bold:
    lda mv_style
    eor #1
    sta mv_style
    jmp mv_line_loop
mv_underline:
    lda mv_style
    eor #2
    sta mv_style
    jmp mv_line_loop
mv_emphasis:
    lda mv_style
    eor #4
    sta mv_style
    jmp mv_line_loop
mv_tab:
    lda #32
    sta mv_char
    jsr mv_put_char
    lda mv_col
    cmp _view_width
    bcs mv_tab_break
    and #7
    bne mv_tab
mv_tab_break:
    lda mv_col
    sta mv_break_count
    lda mv_pos
    sta mv_break_pos
    lda mv_pos+1
    sta mv_break_pos+1
    lda mv_style
    sta mv_break_style
    jmp mv_line_loop
mv_line_wrap:
    lda mv_break_count
    beq mv_line_hard_wrap
    sta mv_col
    lda mv_break_pos
    sta mv_pos
    lda mv_break_pos+1
    sta mv_pos+1
    lda mv_break_style
    sta mv_style
mv_line_hard_wrap:
    lda mv_pos
    sec
    sbc #1
    sta _view_line_end
    lda mv_pos+1
    sbc #0
    sta _view_line_end+1
    jmp mv_line_finish
mv_line_delimiter:
    lda mv_char_pos
    sta _view_line_end
    lda mv_char_pos+1
    sta _view_line_end+1
    jmp mv_line_finish
mv_line_done:
    lda mv_pos
    sta _view_line_end
    lda mv_pos+1
    sta _view_line_end+1
    lda mv_col
    cmp _view_width
    bcs mv_line_finish
    lda #1
    sta _view_flags ; EOF insertion point belongs to this non-full row.
mv_line_finish:
    lda mv_pos
    sta _view_next
    lda mv_pos+1
    sta _view_next+1
    lda mv_style
    sta _view_next_style
    lda mv_col
    sta _view_count
    lda mv_scan
    bne mv_line_return
    ; Clear the abandoned tail after wrapping at a previous space. Position
    ; cache maps blank/end cells to the logical insertion point, not screen X.
mv_line_pad:
    lda mv_col
    cmp #40
    bcs mv_line_return
    lda _view_line_end
    sta mv_char_pos
    lda _view_line_end+1
    sta mv_char_pos+1
    lda #32
    sta mv_char
    jsr mv_put_char
    ldx mv_col
    dex
    lda #$80 ; filler is a caret stop, never styled/selected document content.
    sta $6e40,x
    jmp mv_line_pad
mv_line_return:
    rts

mv_put_char:
    lda mv_scan
    bne mv_put_advance
    ldx mv_col
    lda mv_char
    sta $6e00,x
    lda mv_style
    sta $6e40,x
    txa
    asl
    tax
    lda mv_char_pos
    sta $6e80,x
    lda mv_char_pos+1
    sta $6e81,x
mv_put_advance:
    inc mv_col
    rts

; Off-screen seeks only need boundaries and style. Do not construct 40
; character/style/word-position triples for rows which cannot be displayed.
mv_scan_loop:
    lda mv_pos+1
    cmp _doc+5
    bne mv_scan_not_end
    lda mv_pos
    cmp _doc+4
    bne mv_scan_not_end
    jmp mv_line_done
mv_scan_not_end:
    lda mv_col
    cmp _view_width
    bcc mv_scan_read
    jmp mv_line_wrap
mv_scan_read:
    jsr mv_get_byte
    cmp #32
    beq mv_scan_space
    bcc mv_scan_control
mv_scan_glyph:
    inc mv_col
    jmp mv_scan_loop
mv_scan_control:
    cmp #1
    bcc mv_scan_glyph
    cmp #4
    bcc mv_scan_style
    cmp #9
    beq mv_scan_tab
    cmp #13
    beq mv_scan_delimiter
    cmp #10
    beq mv_scan_delimiter
    cmp #12
    beq mv_scan_delimiter
    jmp mv_scan_glyph
mv_scan_delimiter:
    jmp mv_line_hard_wrap
mv_scan_style:
    tax
    lda mv_style
    eor mv_style_bits-1,x
    sta mv_style
    jmp mv_scan_loop
mv_scan_tab:
    lda mv_col
    clc
    adc #8
    and #$f8
    cmp _view_width
    bcc mv_scan_tab_ready
    lda _view_width
mv_scan_tab_ready:
    sta mv_col
    jmp mv_scan_break
mv_scan_space:
    inc mv_col
mv_scan_break:
    lda mv_col
    sta mv_break_count
    lda mv_pos
    sta mv_break_pos
    lda mv_pos+1
    sta mv_break_pos+1
    lda mv_style
    sta mv_break_style
    jmp mv_scan_loop

; The cursor is a logical insertion point. Zero-width style tokens and every
; cell of a tab map to their source position; clipped full rows never use X=40.
asm_find_cursor:
    ldx #0
    ldy #0
mv_find_cursor:
    cpy _view_count
    bcs mv_cursor_column_ready
    lda $6e81,x
    cmp _doc+7
    bcc mv_cursor_column_next
    bne mv_cursor_column_ready
    lda $6e80,x
    cmp _doc+6
    bcs mv_cursor_column_ready
mv_cursor_column_next:
    inx
    inx
    iny
    cpy #39
    bcc mv_find_cursor
mv_cursor_column_ready:
    sty _view_column
    rts

; Cold seek policy: retain 24 preceding native line boundaries, without a
; document-sized index or any off-screen line-buffer/Color RAM writes.
asm_invalidate_seek:
    ldx #0
    beq mv_invalidate_seek
asm_invalidate_changed_seek:
    lda _document_dirty_from+1
    lsr
    lsr
    tax
mv_invalidate_seek:
    lda #$ff
mv_invalidate_seek_loop:
    cpx #20
    bcs mv_invalidate_seek_done
    sta mv_checkpoint_hi,x
    inx
    bne mv_invalidate_seek_loop
mv_invalidate_seek_done:
    rts

asm_locate_top:
    lda #0
    sta _view_start
    sta _view_start+1
    sta _view_style
    sta mv_seek_index
    sta mv_seek_count_value
    ; One coarse native boundary per KiB costs 60 bytes, not a line index.
    ; Start two KiB earlier for cursor context, falling back to the beginning
    ; if an unusually token-heavy paragraph supplied too few preceding rows.
    lda _view_cursor_position+1
    lsr
    lsr
    sec
    sbc #2
    bcc mv_seek_choose_live
    tax
mv_seek_checkpoint:
    lda mv_checkpoint_hi,x
    cmp #$ff
    bne mv_seek_checkpoint_found
    dex
    bpl mv_seek_checkpoint
    jmp mv_seek_choose_live
mv_seek_checkpoint_found:
    sta _view_start+1
    lda mv_checkpoint_lo,x
    sta _view_start
    lda mv_checkpoint_style,x
    sta _view_style
mv_seek_choose_live:
    lda _view_valid
    beq mv_seek_begin
    lda _view_column
    cmp #24
    bcs mv_seek_begin
    asl
    tax
    lda _view_cursor_position+1
    cmp $6f01,x
    bcc mv_seek_begin
    bne mv_seek_live_context_ready
    lda _view_cursor_position
    cmp $6f00,x
    bcc mv_seek_begin
mv_seek_live_context_ready:
    lda _doc+11
    cmp _view_start+1
    bcc mv_seek_begin
    bne mv_seek_check_live_target
    lda _doc+10
    cmp _view_start
    bcc mv_seek_begin
mv_seek_check_live_target:
    lda _view_cursor_position+1
    cmp _doc+11
    bcc mv_seek_begin
    bne mv_seek_cached
    lda _view_cursor_position
    cmp _doc+10
    bcc mv_seek_begin
    bne mv_seek_cached
    lda _view_column
    bne mv_seek_begin
mv_seek_cached:
    lda _doc+10
    sta _view_start
    lda _doc+11
    sta _view_start+1
    lda _view_top_style
    sta _view_style
mv_seek_begin:
    lda _view_start
    ora _view_start+1
    sta mv_seek_origin
mv_seek_loop:
    lda _view_start+1
    cmp _view_cursor_position+1
    bcc mv_seek_scan
    bne mv_seek_exit_early
    lda _view_start
    cmp _view_cursor_position
    bcc mv_seek_scan
mv_seek_exit_early:
    jmp mv_seek_finish
mv_seek_scan:
    jsr asm_scan_line
    lda _view_next+1
    cmp _view_cursor_position+1
    bcc mv_seek_accept
    bne mv_seek_exit_early
    lda _view_next
    cmp _view_cursor_position
    bcc mv_seek_accept
    bne mv_seek_exit_early
    ; Partial EOF is an insertion point in the row just scanned, not the
    ; beginning of another row. Full-width/delimited EOF may still advance.
    lda _view_flags
    bne mv_seek_exit_early
mv_seek_accept:
    lda _view_next
    cmp _view_start
    bne mv_seek_record
    lda _view_next+1
    cmp _view_start+1
    beq mv_seek_finish
mv_seek_record:
    ldx mv_seek_index
    lda _view_style
    sta mv_seek_styles,x
    txa
    asl
    tay
    lda _view_start
    sta mv_seek_previous,y
    lda _view_start+1
    sta mv_seek_previous+1,y
    inc mv_seek_index
    lda mv_seek_index
    cmp #24
    bcc mv_seek_count
    lda #0
    sta mv_seek_index
mv_seek_count:
    lda mv_seek_count_value
    cmp #24
    bcs mv_seek_advance
    inc mv_seek_count_value
mv_seek_advance:
    lda _view_next
    sta _view_start
    lda _view_next+1
    sta _view_start+1
    lda _view_next_style
    sta _view_style
    lda _view_start+1
    lsr
    lsr
    tax
    lda mv_checkpoint_hi,x
    cmp #$ff
    bne mv_seek_remembered
    lda _view_start+1
    sta mv_checkpoint_hi,x
    lda _view_start
    sta mv_checkpoint_lo,x
    lda _view_style
    sta mv_checkpoint_style,x
mv_seek_remembered:
    jmp mv_seek_loop
mv_seek_finish:
    lda _view_column
    cmp mv_seek_count_value
    bcc mv_seek_context_ready
    beq mv_seek_context_ready
    lda mv_seek_origin
    beq mv_seek_context_clamp
    lda #0
    sta _view_start
    sta _view_start+1
    sta _view_style
    sta mv_seek_count_value
    sta mv_seek_index
    sta mv_seek_origin
    jmp mv_seek_loop
mv_seek_context_clamp:
    lda mv_seek_count_value
mv_seek_context_ready:
    tax
    beq mv_seek_publish
mv_seek_back:
    lda mv_seek_index
    bne mv_seek_back_ready
    lda #24
    sta mv_seek_index
mv_seek_back_ready:
    dec mv_seek_index
    dex
    bne mv_seek_back
    ldx mv_seek_index
    lda mv_seek_styles,x
    sta _view_style
    txa
    asl
    tax
    lda mv_seek_previous,x
    sta _view_start
    lda mv_seek_previous+1,x
    sta _view_start+1
mv_seek_publish:
    lda _view_start
    sta _doc+10
    lda _view_start+1
    sta _doc+11
    rts

asm_row_cursor:
    lda _view_row
    asl
    tax
    lda _doc+7
    cmp $6f01,x
    bcc mv_row_false
    bne mv_row_cursor_end
    lda _doc+6
    cmp $6f00,x
    bcc mv_row_false
mv_row_cursor_end:
    lda _doc+7
    cmp $6f61,x
    bcc mv_row_true
    bne mv_row_false
    lda _doc+6
    cmp $6f60,x
    bcc mv_row_true
    bne mv_row_false
    lda _doc+7
    cmp _doc+5
    bne mv_row_false
    lda _doc+6
    cmp _doc+4
    bne mv_row_false
    ldx _view_row
    lda $6fa0,x
    rts
mv_row_false:
    lda #0
    rts
mv_row_true:
    lda #1
    rts

asm_dirty_row:
    ldx #0
mv_dirty_row_loop:
    lda $6f61,x
    cmp _document_dirty_from+1
    bcc mv_dirty_row_next
    bne mv_dirty_row_found
    lda $6f60,x
    cmp _document_dirty_from
    bcc mv_dirty_row_next
    bne mv_dirty_row_found
    txa
    lsr
    tay
    lda $6fa0,y
    bne mv_dirty_row_found
mv_dirty_row_next:
    inx
    inx
    cpx #48
    bcc mv_dirty_row_loop
mv_dirty_row_found:
    txa
    lsr
    ; A wrapped line scans into the following word before choosing its last
    ; break. An edit in that lookahead can change the predecessor's boundary,
    ; including appending after a formerly full-width EOF. Rebuild one row
    ; earlier; no extra cache or whole-document line index is needed.
    beq mv_dirty_row_return
    sec
    sbc #1
mv_dirty_row_return:
    rts

; After the entire admitted dirty interval, a matching shifted boundary and
; style prove the unchanged suffix has the same visual rows. Translate only
; cached logical positions; never skip a later sparse formatting bookend.
asm_reuse_suffix:
    lda _view_row
    cmp #23
    bcs mv_suffix_no
    lda _view_next+1
    cmp _document_dirty_to+1
    bcc mv_suffix_no
    bne mv_suffix_after_dirty
    lda _view_next
    cmp _document_dirty_to
    bcc mv_suffix_no
mv_suffix_after_dirty:
    ldx _view_row
    lda _view_flags
    cmp $6fa0,x
    bne mv_suffix_no
    lda _view_next_style
    cmp $6f41,x
    bne mv_suffix_no
    txa
    asl
    tax
    clc
    lda $6f60,x
    adc _view_length_delta
    sta mv_range_from
    lda $6f61,x
    adc _view_length_delta+1
    cmp _view_next+1
    bne mv_suffix_no
    lda mv_range_from
    cmp _view_next
    bne mv_suffix_no
mv_suffix_shift:
    inx
    inx
    cpx #48
    bcs mv_suffix_yes
    clc
    lda $6f00,x
    adc _view_length_delta
    sta $6f00,x
    lda $6f01,x
    adc _view_length_delta+1
    sta $6f01,x
    clc
    lda $6f60,x
    adc _view_length_delta
    sta $6f60,x
    lda $6f61,x
    adc _view_length_delta+1
    sta $6f61,x
    jmp mv_suffix_shift
mv_suffix_yes:
    lda #1
    rts
mv_suffix_no:
    lda #0
    rts

asm_row_selection:
    lda _view_selection_start
    sta mv_range_from
    lda _view_selection_start+1
    sta mv_range_from+1
    lda _view_selection_end
    sta mv_range_to
    lda _view_selection_end+1
    sta mv_range_to+1
    jsr mv_row_range
    bne mv_range_return
    lda _view_previous_selection_start
    sta mv_range_from
    lda _view_previous_selection_start+1
    sta mv_range_from+1
    lda _view_previous_selection_end
    sta mv_range_to
    lda _view_previous_selection_end+1
    sta mv_range_to+1
mv_row_range:
    lda mv_range_from
    cmp mv_range_to
    bne mv_range_nonempty
    lda mv_range_from+1
    cmp mv_range_to+1
    beq mv_range_false
mv_range_nonempty:
    lda _view_row
    asl
    tax
    lda $6f01,x
    cmp mv_range_to+1
    bcc mv_range_lower
    bne mv_range_false
    lda $6f00,x
    cmp mv_range_to
    bcs mv_range_false
mv_range_lower:
    lda mv_range_from+1
    cmp $6f61,x
    bcc mv_range_true
    bne mv_range_false
    lda mv_range_from
    cmp $6f60,x
    bcs mv_range_false
mv_range_true:
    lda #1
    rts
mv_range_false:
    lda #0
mv_range_return:
    rts

; Navigation stays in the same native logical-line path as layout. Public
; one-byte _fastcall entries receive direction/end in A; no private C ABI.
_view_vertical:
    sta mv_direction
    jsr mv_keep_column
    lda mv_direction
    bpl mv_vertical_down
    lda _view_cursor_row
    bne mv_vertical_up_row
    lda _doc+10
    ora _doc+11
    beq mv_navigation_done
    lda _doc+10
    sec
    sbc #1
    sta _view_cursor_position
    lda _doc+11
    sbc #0
    sta _view_cursor_position+1
    lda #0
    sta _view_column
    jsr asm_locate_top
    lda _view_style
    sta _view_top_style
    lda #0
    sta _view_valid
    jmp mv_move_to_line
mv_vertical_up_row:
    tax
    dex
    jmp mv_vertical_row
mv_vertical_down:
    lda _doc+6
    cmp _doc+4
    bne mv_vertical_has_next
    lda _doc+7
    cmp _doc+5
    beq mv_navigation_done
mv_vertical_has_next:
    ldx _view_cursor_row
    lda $6fa0,x
    bne mv_navigation_done
    cpx #23
    bne mv_vertical_down_row
    jsr mv_load_row
    jsr asm_scan_line
    jsr mv_next_line
    lda $6f02
    sta _doc+10
    lda $6f03
    sta _doc+11
    lda $6f41
    sta _view_top_style
    lda #0
    sta _view_valid
    jmp mv_move_to_line
mv_vertical_down_row:
    inx
mv_vertical_row:
    jsr mv_load_row
    jmp mv_move_to_line
mv_navigation_done:
    rts

_view_page:
    sta mv_direction
    jsr mv_keep_column
    ldx _view_cursor_row
    jsr mv_load_row
    lda mv_direction
    bpl mv_page_forward
    lda _view_start
    ora _view_start+1
    beq mv_page_resolve
    lda _view_start
    sec
    sbc #1
    sta _view_cursor_position
    lda _view_start+1
    sbc #0
    sta _view_cursor_position+1
    lda #19
    sta _view_column
    jsr asm_locate_top
    lda _view_style
    sta _view_top_style
    jmp mv_page_resolve
mv_page_forward:
    lda #20
    sta mv_page_count
mv_page_scan:
    jsr asm_scan_line
    lda _view_flags
    bne mv_page_resolve
    lda _view_next
    cmp _view_start
    bne mv_page_advance
    lda _view_next+1
    cmp _view_start+1
    beq mv_page_resolve
mv_page_advance:
    jsr mv_next_line
    dec mv_page_count
    bne mv_page_scan
mv_page_resolve:
    lda _view_start
    sta mv_page_target
    sta _view_cursor_position
    lda _view_start+1
    sta mv_page_target+1
    sta _view_cursor_position+1
    lda _view_style
    sta mv_page_style
    lda _view_cursor_row
    sta _view_column
    jsr asm_locate_top
    lda #0
    sta _view_valid
    lda _view_style
    sta _view_top_style
    lda mv_page_target
    sta _view_start
    lda mv_page_target+1
    sta _view_start+1
    lda mv_page_style
    sta _view_style
    jmp mv_move_to_line

_view_home:
    pha
    lda #0
    sta _view_desired_valid
    ldx _view_cursor_row
    jsr mv_load_row
    pla
    beq mv_home_start
    jsr asm_layout_line
    lda _view_line_end
    sta _doc+6
    lda _view_line_end+1
    sta _doc+7
    jmp mv_navigation_dirty
mv_home_start:
    lda _view_start
    sta _doc+6
    lda _view_start+1
    sta _doc+7
    jmp mv_navigation_dirty

mv_keep_column:
    lda _view_desired_valid
    bne mv_keep_column_done
    lda _view_cursor_column
    sta _view_desired_column
    lda #1
    sta _view_desired_valid
mv_keep_column_done:
    rts
mv_load_row:
    lda $6f40,x
    sta _view_style
    txa
    asl
    tax
    lda $6f00,x
    sta _view_start
    lda $6f01,x
    sta _view_start+1
    rts
mv_next_line:
    lda _view_next
    sta _view_start
    lda _view_next+1
    sta _view_start+1
    lda _view_next_style
    sta _view_style
    rts
mv_move_to_line:
    jsr asm_layout_line
    lda _view_desired_column
    asl
    tax
    lda $6e80,x
    sta _doc+6
    lda $6e81,x
    sta _doc+7
mv_navigation_dirty:
    lda _doc+16
    bne mv_keep_column_done
    lda #1
    sta _doc+16
    rts

asm_paint_line:
    ldx _view_row
    lda mv_screen_lo,x
    sta $fb
    sta $fd
    lda mv_screen_hi,x
    sta $fc
    clc
    adc #$d4
    sta $fe
    ldy #0
mv_paint:
    lda $6e00,y
    ; PETSCII -> lower/uppercase ROM screen code, independent of C UI ASCII.
    cmp #$80
    bcc mv_paint_low
    cmp #$a0
    bcc mv_paint_invalid
    cmp #$c0
    bcc mv_paint_high_graphic
    cmp #$ff
    bne mv_paint_high_letter
    lda #$5e
    jmp mv_paint_style
mv_paint_high_letter:
    and #$7f
    jmp mv_paint_style
mv_paint_high_graphic:
    sec
    sbc #$40
    jmp mv_paint_style
mv_paint_low:
    cmp #32
    bcc mv_paint_invalid
    cmp #$40
    bcc mv_paint_style
    cmp #$60
    bcs mv_paint_lower_graphic
    sec
    sbc #$40
    jmp mv_paint_style
mv_paint_lower_graphic:
    sec
    sbc #$20
    jmp mv_paint_style
mv_paint_invalid:
    lda #63
mv_paint_style:
    sta mv_char
    lda _theme_foreground
    sta mv_color
    lda $6e40,y
    and #1
    beq mv_not_bold
    lda #1
    sta mv_color
mv_not_bold:
    lda $6e40,y
    and #2
    beq mv_not_underline
    lda #14
    sta mv_color
mv_not_underline:
    lda $6e40,y
    and #4
    beq mv_not_emphasis
    lda mv_char
    ora #$80
    sta mv_char
mv_not_emphasis:
    lda $6e40,y
    bmi mv_no_selection
    lda _doc+12
    beq mv_no_selection
    tya
    asl
    tax
    lda $6e81,x
    cmp _view_selection_start+1
    bcc mv_no_selection
    bne mv_selected_lower
    lda $6e80,x
    cmp _view_selection_start
    bcc mv_no_selection
mv_selected_lower:
    lda $6e81,x
    cmp _view_selection_end+1
    bcc mv_selected
    bne mv_no_selection
    lda $6e80,x
    cmp _view_selection_end
    bcs mv_no_selection
mv_selected:
    lda mv_char
    ora #$80
    sta mv_char
    lda _theme_accent
    sta mv_color
mv_no_selection:
    lda mv_char
    cmp ($fb),y
    beq mv_paint_color
    sta ($fb),y
mv_paint_color:
    lda ($fd),y
    and #$0f
    cmp mv_color
    beq mv_paint_next
    lda mv_color
    sta ($fd),y
mv_paint_next:
    iny
    cpy #40
    beq mv_paint_done
    jmp mv_paint
mv_paint_done:
    rts

asm_cursor_hide:
    lda mv_cursor_visible
    beq mv_cursor_hidden
    lda mv_cursor_address
    sta $fb
    lda mv_cursor_address+1
    sta $fc
    ldy #0
    lda ($fb),y
    eor #$80
    sta ($fb),y
    lda #0
    sta mv_cursor_visible
mv_cursor_hidden:
    rts
asm_cursor_show:
    lda mv_cursor_visible
    bne mv_cursor_hidden
    lda _view_row
    cmp #24
    bcs mv_cursor_hidden
    tax
    lda mv_screen_lo,x
    clc
    adc _view_column
    sta $fb
    sta mv_cursor_address
    lda mv_screen_hi,x
    adc #0
    sta $fc
    sta mv_cursor_address+1
    ldy #0
    lda ($fb),y
    eor #$80
    sta ($fb),y
    lda #1
    sta mv_cursor_visible
    rts

mv_screen_lo:
    .byte <$0400,<$0428,<$0450,<$0478,<$04a0,<$04c8,<$04f0,<$0518
    .byte <$0540,<$0568,<$0590,<$05b8,<$05e0,<$0608,<$0630,<$0658
    .byte <$0680,<$06a8,<$06d0,<$06f8,<$0720,<$0748,<$0770,<$0798,<$07c0
mv_screen_hi:
    .byte >$0400,>$0428,>$0450,>$0478,>$04a0,>$04c8,>$04f0,>$0518
    .byte >$0540,>$0568,>$0590,>$05b8,>$05e0,>$0608,>$0630,>$0658
    .byte >$0680,>$06a8,>$06d0,>$06f8,>$0720,>$0748,>$0770,>$0798,>$07c0
mv_pos: .word 0
mv_char_pos: .word 0
mv_break_pos: .word 0
mv_break_count: .byte 0
mv_break_style: .byte 0
mv_col: .byte 0
mv_style: .byte 0
mv_char: .byte 0
mv_color: .byte 0
mv_scan: .byte 0
mv_style_bits: .byte 1,2,4
mv_seek_index: .byte 0
mv_seek_count_value: .byte 0
mv_seek_origin: .byte 0
mv_seek_previous: .fill 48, 0
mv_seek_styles: .fill 24, 0
mv_checkpoint_hi: .fill 20, $ff
mv_checkpoint_lo: .fill 20, 0
mv_checkpoint_style: .fill 20, 0
mv_range_from: .word 0
mv_range_to: .word 0
mv_direction: .byte 0
mv_page_count: .byte 0
mv_page_target: .word 0
mv_page_style: .byte 0
mv_cursor_visible: .byte 0
mv_cursor_address: .word 0
