; Margin64 byte codecs and streaming boundary.
; C owns file policy, channel selection, DOS errors and transactional adoption.
; _fastcall byte argument arrives in A; bool return A with X=0.
; These raw KERNAL transfers update file_io_failed, not the SDK's family latch.
; Both old and new error domains are consumed before any byte is published.
.include "web64/disk.inc"

asm_file_stream_get:
    lda _file_io_failed
    ora _file_io_eof
    bne mf_get_none
    jsr $ffcf
    bcs mf_get_fail
    pha
    jsr $ffb7
    sta mf_read_status
    and #$bf
    bne mf_get_pull_fail
    pla
    sta _file_io_value
    lda mf_read_status
    and #$40
    sta _file_io_eof
    ldx #0
    lda #1
    rts
mf_get_pull_fail:
    pla
mf_get_fail:
    lda #1
    sta _file_io_failed
mf_get_none:
    lda #0
    tax
    rts
mf_read_status: .byte 0

_file_stream_put:
    pha
    lda _file_io_failed
    bne mf_put_skip
    pla
    jsr $ffd2
    bcs mf_put_fail
    jsr $ffb7
    beq mf_put_done
mf_put_fail:
    lda #1
    sta _file_io_failed
mf_put_done:
    rts
mf_put_skip:
    pla
    rts

; CRC16-CCITT-FALSE: initial $ffff, polynomial $1021, no final XOR.
_file_crc_byte:
    eor _file_crc+1
    sta _file_crc+1
    ldx #8
mf_crc_bit:
    asl _file_crc
    rol _file_crc+1
    bcc mf_crc_next
    lda _file_crc
    eor #$21
    sta _file_crc
    lda _file_crc+1
    eor #$10
    sta _file_crc+1
mf_crc_next:
    dex
    bne mf_crc_bit
    rts

_file_plain_byte:
    cmp #4
    bcc mf_byte_no
_file_native_byte:
    cmp #32
    bcs mf_byte_printable
    tax
    lda mf_tokens,x
    ldx #0
    cmp #0
    rts
mf_byte_printable:
    cmp #128
    bcc mf_byte_yes
    cmp #160
    bcs mf_byte_yes
mf_byte_no:
    lda #0
    tax
    rts
mf_byte_yes:
    ldx #0
    lda #1
    rts
mf_tokens:
    .byte 0,1,1,1,0,0,0,0,0,1,1,0,1,1,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; Ordinary stack ABI: two pointers at ($02),Y. Always terminates at <=16.
; Source/destination are bounded project-owned filename buffers, not DOS code.
_file_copy_name:
    ldy #0
    lda ($02),y
    sta $fd
    iny
    lda ($02),y
    sta $fe
    iny
    lda ($02),y
    sta $fb
    iny
    lda ($02),y
    sta $fc
    ldy #0
mf_name_copy:
    lda ($fb),y
    beq mf_name_terminate
    sta ($fd),y
    iny
    cpy #16
    bcc mf_name_copy
    lda #0
mf_name_terminate:
    sta ($fd),y
    rts

; One pointer in A/X. Length is bounded even if no terminator is present.
_file_name_length:
    sta $fb
    stx $fc
    ldy #0
mf_name_length:
    lda ($fb),y
    beq mf_name_length_done
    iny
    cpy #16
    bcc mf_name_length
mf_name_length_done:
    tya
    ldx #0
    rts

; Refuse empty names, PETSCII controls and DOS command/wildcard syntax.
_file_name_valid:
    sta $fb
    stx $fc
    ldy #0
    lda ($fb),y
    beq mf_name_no
mf_name_check:
    cmp #32
    bcc mf_name_no
    cmp #128
    bcc mf_name_printable
    cmp #160
    bcc mf_name_no
mf_name_printable:
    cmp #58
    beq mf_name_no
    cmp #44
    beq mf_name_no
    cmp #61
    beq mf_name_no
    cmp #42
    beq mf_name_no
    cmp #63
    beq mf_name_no
    cmp #34
    beq mf_name_no
    iny
    cpy #16
    bcs mf_name_yes
    lda ($fb),y
    bne mf_name_check
mf_name_yes:
    ldx #0
    lda #1
    rts
mf_name_no:
    lda #0
    tax
    rts

_file_hex_digit:
    cmp #10
    bcc mf_hex_decimal
    clc
    adc #55
    rts
mf_hex_decimal:
    clc
    adc #48
    rts

; Only replace the two-digit suffix in a project-owned M64-TEMP/BACK name.
_file_number_name:
    ldy #0
    lda ($02),y
    sta $fb
    iny
    lda ($02),y
    sta $fc
    iny
    lda ($02),y
    pha
    lsr
    lsr
    lsr
    lsr
    jsr _file_hex_digit
    ldy #9
    sta ($fb),y
    pla
    and #15
    jsr _file_hex_digit
    iny
    sta ($fb),y
    rts

; Source traversal is logical, including an interior gap. Native output keeps
; every token; plain PETSCII omits styles 1..3 and maps hard lines to CR.
_file_next_output:
    sta mf_output_plain
mf_output_next:
    lda _file_output_position+1
    cmp _doc+5
    bcc mf_output_byte
    bne mf_output_end
    lda _file_output_position
    cmp _doc+4
    bcs mf_output_end
mf_output_byte:
    lda _file_output_position
    ldx _file_output_position+1
    jsr _doc_get
    sta _file_io_value
    inc _file_output_position
    bne mf_output_filter
    inc _file_output_position+1
mf_output_filter:
    ldx mf_output_plain
    beq mf_output_ready
    cmp #1
    bcc mf_output_ready
    cmp #4
    bcc mf_output_next
    cmp #10
    bne mf_output_ready
    lda #13
    sta _file_io_value
mf_output_ready:
    ldx #0
    lda #1
    rts
mf_output_end:
    lda #0
    tax
    rts
mf_output_plain: .byte 0

; Exact M64D v1 header codec. Header/stream bytes are native file bytes, never
; screen codes. Length and CRC are checked by the bounded reader below.
mf_header = $6900
mf_capacity = $3dfa
_file_valid_header:
    ldx #7
mf_header_prefix:
    lda mf_header,x
    cmp mf_header_magic,x
    bne mf_header_bad
    dex
    bpl mf_header_prefix
    ldx #4
mf_header_settings:
    lda mf_header+12,x
    cmp mf_header_min,x
    bcc mf_header_bad
    cmp mf_header_limit,x
    bcs mf_header_bad
    dex
    bpl mf_header_settings
    ldx #17
mf_header_reserved:
    lda mf_header,x
    bne mf_header_bad
    inx
    cpx #32
    bcc mf_header_reserved
    ldx #0
    lda #1
    rts
mf_header_bad:
    lda #0
    tax
    rts
mf_header_magic: .byte $4d,$36,$34,$44,1,32,0,0
mf_header_min: .byte 20,40,20,0,1
mf_header_limit: .byte 41,81,100,16,3

_file_make_header:
    lda #0
    sta _file_output_position
    sta _file_output_position+1
    ldx #31
mf_header_zero:
    sta mf_header,x
    dex
    bpl mf_header_zero
    lda #$ff
    sta _file_crc
    sta _file_crc+1
mf_header_checksum:
    lda #0
    jsr _file_next_output
    beq mf_header_fill
    lda _file_io_value
    jsr _file_crc_byte
    jmp mf_header_checksum
mf_header_fill:
    ldx #7
mf_header_fill_magic:
    lda mf_header_magic,x
    sta mf_header,x
    dex
    bpl mf_header_fill_magic
    lda _doc+4
    sta mf_header+8
    lda _doc+5
    sta mf_header+9
    lda _file_crc
    sta mf_header+10
    lda _file_crc+1
    sta mf_header+11
    lda _editor_width
    sta mf_header+12
    lda _print_width
    sta mf_header+13
    lda _print_lines
    sta mf_header+14
    lda _print_margin
    sta mf_header+15
    lda _print_spacing
    sta mf_header+16
    rts

; _fastcall: plain in A, verify in X. Verification reads the logical active
; source; import writes only the candidate through the banking-aware helper.
; No commit occurs here, and the RAM vectors at $fffa..$ffff remain untouched.
_file_read_document:
    sta mf_document_plain
    stx mf_document_verify
    lda #<mf_capacity
    sta mf_document_expected
    lda #>mf_capacity
    sta mf_document_expected+1
    lda mf_document_plain
    beq mf_document_native_header
    jmp mf_document_start
mf_document_native_header:
    lda #0
    sta mf_header_index
mf_document_header:
    jsr asm_file_stream_get
    bne mf_document_header_byte
    lda _file_io_failed
    beq mf_document_bad_header
    jmp mf_document_no
mf_document_bad_header:
    jmp mf_document_corrupt
mf_document_header_byte:
    ldx mf_header_index
    lda _file_io_value
    sta mf_header,x
    inc mf_header_index
    cpx #31
    bcc mf_document_header
    jsr _file_valid_header
    beq mf_document_bad_header
    lda mf_header+8
    sta mf_document_expected
    lda mf_header+9
    sta mf_document_expected+1
    cmp #>mf_capacity
    bcc mf_document_header_size_ok
    bne mf_document_too_big_header
    lda mf_document_expected
    cmp #<mf_capacity+1
    bcc mf_document_header_size_ok
mf_document_too_big_header:
    jmp mf_document_capacity
mf_document_header_size_ok:
    lda mf_document_verify
    beq mf_document_start
    lda mf_document_expected
    cmp _doc+4
    bne mf_document_bad_header
    lda mf_document_expected+1
    cmp _doc+5
    bne mf_document_bad_header
    lda mf_header+12
    cmp _editor_width
    bne mf_document_bad_header
    lda mf_header+13
    cmp _print_width
    bne mf_document_bad_header
    lda mf_header+14
    cmp _print_lines
    bne mf_document_bad_header
    lda mf_header+15
    cmp _print_margin
    bne mf_document_bad_header
    lda mf_header+16
    cmp _print_spacing
    bne mf_document_bad_header
mf_document_start:
    lda #0
    sta _file_io_count
    sta _file_io_count+1
    sta _file_output_position
    sta _file_output_position+1
    lda #$ff
    sta _file_crc
    sta _file_crc+1
mf_document_next:
    jsr asm_file_stream_get
    bne mf_document_got_byte
    jmp mf_document_end
mf_document_got_byte:
    lda _file_io_value
    sta mf_document_actual
    ldx mf_document_plain
    beq mf_document_native
    jsr _file_plain_byte
    bne mf_document_size
    lda mf_document_verify
    beq mf_document_next
    jmp mf_document_corrupt
mf_document_native:
    jsr _file_native_byte
    beq mf_document_corrupt
mf_document_size:
    lda _file_io_count+1
    cmp mf_document_expected+1
    bcc mf_document_value
    bne mf_document_over
    lda _file_io_count
    cmp mf_document_expected
    bcc mf_document_value
mf_document_over:
    lda _file_io_count+1
    cmp #>mf_capacity
    bcc mf_document_corrupt
    lda _file_io_count
    cmp #<mf_capacity
    bcs mf_document_capacity
    jmp mf_document_corrupt
mf_document_value:
    lda mf_document_verify
    beq mf_document_candidate
    lda mf_document_plain
    jsr _file_next_output
    beq mf_document_corrupt
    lda _file_io_value
    cmp mf_document_actual
    bne mf_document_corrupt
    beq mf_document_crc
mf_document_candidate:
    lda _file_io_count
    sta _bank_address
    lda _file_io_count+1
    clc
    adc #$b0
    sta _bank_address+1
    lda mf_document_actual
    sta _bank_value
    jsr asm_bank_write
mf_document_crc:
    lda mf_document_actual
    jsr _file_crc_byte
    inc _file_io_count
    bne mf_document_continue
    inc _file_io_count+1
mf_document_continue:
    jmp mf_document_next
mf_document_corrupt:
    lda #2
    bne mf_document_fail
mf_document_capacity:
    lda #3
mf_document_fail:
    sta _file_io_failed
mf_document_no:
    lda #0
    tax
    rts
mf_document_end:
    lda _file_io_failed
    bne mf_document_no
    lda mf_document_plain
    bne mf_document_verify_end
    lda _file_io_count
    cmp mf_document_expected
    bne mf_document_corrupt
    lda _file_io_count+1
    cmp mf_document_expected+1
    bne mf_document_corrupt
    lda _file_crc
    cmp mf_header+10
    bne mf_document_corrupt
    lda _file_crc+1
    cmp mf_header+11
    bne mf_document_corrupt
mf_document_verify_end:
    lda mf_document_verify
    beq mf_document_yes
    lda mf_document_plain
    jsr _file_next_output
    bne mf_document_corrupt
mf_document_yes:
    ldx #0
    lda #1
    rts
mf_header_index: .byte 0
mf_document_plain: .byte 0
mf_document_verify: .byte 0
mf_document_expected: .word 0
mf_document_actual: .byte 0

; DOS 15 is independent of the data stream and of the SDK error latches.
; Consume raw call carry/READST immediately; never interpret a call error as
; a digit. The bounded original DOS text remains available to the resident UI.
mf_dos_text = $6920
mf_dos_command = $6950
_file_dos_status:
    jsr $ffcc
    ldx #15
    jsr $ffc6
    bcs mf_dos_fail
    jsr $ffb7
    bne mf_dos_fail
    lda #0
    sta mf_dos_index
mf_dos_byte:
    jsr $ffcf
    bcs mf_dos_fail
    pha
    jsr $ffb7
    sta mf_dos_read_status
    and #$bf
    bne mf_dos_pull_fail
    pla
    cmp #13
    beq mf_dos_end
    ldx mf_dos_index
    sta mf_dos_text,x
    inc mf_dos_index
    lda mf_dos_index
    cmp #39
    bcs mf_dos_end
    lda mf_dos_read_status
    beq mf_dos_byte
mf_dos_end:
    ldx mf_dos_index
    lda #0
    sta mf_dos_text,x
    jsr $ffcc
    lda mf_dos_index
    cmp #3
    bcc mf_dos_fail
    lda mf_dos_text+2
    cmp #44
    bne mf_dos_fail
    lda mf_dos_text
    sec
    sbc #48
    cmp #10
    bcs mf_dos_fail
    sta mf_dos_index
    asl
    asl
    clc
    adc mf_dos_index
    asl
    sta mf_dos_index
    lda mf_dos_text+1
    sec
    sbc #48
    cmp #10
    bcs mf_dos_fail
    clc
    adc mf_dos_index
    sta _file_dos_code
    ldx #0
    rts
mf_dos_pull_fail:
    pla
mf_dos_fail:
    jsr $ffcc
    lda #1
    sta _file_io_failed
    lda #255
    ldx #0
    rts
mf_dos_index: .byte 0
mf_dos_read_status: .byte 0

; Stack ABI pointer followed by one byte. Literal suffix is ASCII/PETSCII,
; regardless of the caller's compile-time screen-string character mode.
_file_open_command:
    ldy #0
    lda ($02),y
    sta $fb
    iny
    lda ($02),y
    sta $fc
    ldy #0
mf_open_name:
    lda ($fb),y
    beq mf_open_suffix
    sta mf_dos_command,y
    iny
    cpy #16
    bcc mf_open_name
mf_open_suffix:
    lda #44
    sta mf_dos_command,y
    iny
    lda #83
    sta mf_dos_command,y
    iny
    lda #44
    sta mf_dos_command,y
    iny
    tya
    tax
    ldy #2
    lda ($02),y
    beq mf_open_read
    lda #87
    bne mf_open_mode
mf_open_read:
    lda #82
mf_open_mode:
    sta mf_dos_command,x
    inx
    txa
    ldx #0
    rts

; One native DOS rename step, not replacement policy. The C save transaction
; chooses only validated, unused names and decides when promotion is allowed.
_file_rename:
    ldy #0
    lda ($02),y
    sta $fb
    iny
    lda ($02),y
    sta $fc
    iny
    lda ($02),y
    sta $fd
    iny
    lda ($02),y
    sta $fe
    lda #82
    sta mf_dos_command
    lda #48
    sta mf_dos_command+1
    lda #58
    sta mf_dos_command+2
    ldx #3
    ldy #0
mf_rename_new:
    lda ($fb),y
    beq mf_rename_equals
    sta mf_dos_command,x
    inx
    iny
    cpy #16
    bcc mf_rename_new
mf_rename_equals:
    lda #61
    sta mf_dos_command,x
    inx
    ldy #0
mf_rename_old:
    lda ($fd),y
    beq mf_rename_send
    sta mf_dos_command,x
    inx
    iny
    cpy #16
    bcc mf_rename_old
mf_rename_send:
    stx mf_command_length
    jsr $ffcc
    ldx #15
    jsr $ffc9
    bcs mf_rename_fail
    jsr $ffb7
    bne mf_rename_fail
    lda #0
    sta mf_command_index
mf_command_next:
    ldx mf_command_index
    lda mf_dos_command,x
    jsr _file_stream_put
    inc mf_command_index
    lda mf_command_index
    cmp mf_command_length
    bcc mf_command_next
    lda #13
    jsr _file_stream_put
    jsr $ffcc
    lda _file_io_failed
    bne mf_command_no
    jsr _file_dos_status
    cmp #0
    bne mf_command_no
    lda _file_io_failed
    bne mf_command_no
    ldx #0
    lda #1
    rts
mf_rename_fail:
    jsr $ffcc
    lda #1
    sta _file_io_failed
mf_command_no:
    lda #0
    tax
    rts
mf_command_length: .byte 0
mf_command_index: .byte 0

; Read one BASIC-format directory line after its two-byte load address.
; Ignore inline display controls, truncate display text at31 bytes, and refuse
; a prematurely ended link/count/text record rather than displaying garbage.
_file_directory_line:
    jsr asm_file_stream_get
    beq mf_directory_no
    lda _file_io_value
    sta mf_directory_link
    jsr asm_file_stream_get
    beq mf_directory_fail
    lda _file_io_value
    ora mf_directory_link
    beq mf_directory_no
    jsr asm_file_stream_get
    beq mf_directory_fail
    lda _file_io_value
    sta _file_directory_blocks
    jsr asm_file_stream_get
    beq mf_directory_fail
    lda _file_io_value
    sta _file_directory_blocks+1
    lda #0
    sta mf_directory_index
mf_directory_character:
    jsr asm_file_stream_get
    beq mf_directory_fail
    lda _file_io_value
    beq mf_directory_ready
    cmp #32
    bcc mf_directory_character
    ldx mf_directory_index
    cpx #31
    bcs mf_directory_character
    sta mf_dos_text,x
    inc mf_directory_index
    bne mf_directory_character
mf_directory_ready:
    ldx mf_directory_index
    lda #0
    sta mf_dos_text,x
    ldx #0
    lda #1
    rts
mf_directory_fail:
    lda #1
    sta _file_io_failed
mf_directory_no:
    lda #0
    tax
    rts
mf_directory_link: .byte 0
mf_directory_index: .byte 0

; Use the public native runtime argument window, not private C-frame labels.
; The selected data device is explicit and independent of the application disk.
_file_open_data:
    ldy #2
    lda ($02),y
    sta mf_open_writing
    jsr _file_open_command
    sta _web64_file_open__arg_length
    lda #<mf_dos_command
    sta _web64_file_open__arg_name
    lda #>mf_dos_command
    sta _web64_file_open__arg_name+1
    lda #2
    sta _web64_file_open__arg_logical_file
    sta _web64_file_open__arg_secondary
    lda _disk_device
    sta _web64_file_open__arg_device
    jsr _web64_file_open
    cmp #0
    bne mf_open_fail
    web64_rt_call_disk_last_error
    cpx #0
    bne mf_open_fail
    cmp #0
    bne mf_open_fail
    jsr _file_dos_status
    cmp #0
    bne mf_open_no
    ldx #2
    lda mf_open_writing
    beq mf_open_input
    jsr $ffc9
    jmp mf_open_selected
mf_open_input:
    jsr $ffc6
mf_open_selected:
    bcs mf_open_fail
    jsr $ffb7
    bne mf_open_fail
    lda #0
    sta _file_io_eof
    tax
    lda #1
    rts
mf_open_fail:
    lda #1
    sta _file_io_failed
mf_open_no:
    lda #0
    tax
    rts
mf_open_writing: .byte 0

; Deterministic byte emission only. C still owns close/DOS checking, complete
; reread verification, backup selection and the two separate rename steps.
_file_write_document:
    sta mf_write_plain
    bne mf_write_body
    jsr _file_make_header
    lda #0
    sta mf_header_index
mf_write_header:
    ldx mf_header_index
    lda mf_header,x
    jsr _file_stream_put
    inc mf_header_index
    lda mf_header_index
    cmp #32
    bcc mf_write_header
mf_write_body:
    lda #0
    sta _file_output_position
    sta _file_output_position+1
mf_write_next:
    lda _file_io_failed
    bne mf_write_done
    lda mf_write_plain
    jsr _file_next_output
    beq mf_write_done
    lda _file_io_value
    jsr _file_stream_put
    jmp mf_write_next
mf_write_done:
    rts
mf_write_plain: .byte 0
