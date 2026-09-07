; Margin64 closure draft. Resident native loader, never code at $b000.
; Root supplies _cold_services_start/_cold_services_end (1..159 bytes),
; installs its typed pointer context at $62a0, and owns all UI/retry policy.
; Requires resident asm_file_stream_get, _file_dos_status and their existing
; _file_io_failed/_file_io_eof/_file_io_value/_file_dos_code globals.
; Logical files 2 and 15 must be idle. Data-device selection is never changed.
;
; PRG header: $b000 JMP entry; +3 "M64C"; +7 format1; +8 total image length;
; +10 module2 PRINT/3 SEARCH; +11 serviceABI1; +12..15 zero.
; Length includes the16-byte header, excludes the two PRG address bytes.
; Images are trusted application code; shape/transport checks are not signing.

_cold_valid = $62c0
_cold_application_device = $62c1
_cold_command = $62c2
_cold_busy = $62c3
_cold_requested = $62c4
_cold_error = $62c5
cl_pointer = $62c6
cl_end = $62c8
cl_index = $62ca
cl_open_mask = $62cb
cl_initialized = $62cc
cl_header = $62e0

; Error:0 success;1 state/module/bank/service-table;2 transport;
;3 DOS;4 PRG origin;5 header/revision/entry;6 length;7 truncated;8 tail.
asm_cold_init:
_asm_cold_init:
    lda #0
    sta _cold_valid
    sta _cold_busy
    sta _cold_command
    sta cl_initialized
    sta _cold_error
    lda #8
    sta _cold_application_device
    lda #>(_cold_services_end-_cold_services_start)
    bne cl_init_bad
    lda #<(_cold_services_end-_cold_services_start)
    beq cl_init_bad
    cmp #160
    bcs cl_init_bad
    ldy #0
cl_init_copy:
    lda _cold_services_start,y
    sta $6200,y
    iny
    cpy #<(_cold_services_end-_cold_services_start)
    bne cl_init_copy
    inc cl_initialized
    rts
cl_init_bad:
    lda #1
    sta _cold_error
    rts

; A bool result: an executing module must return before candidate reuse.
asm_cold_invalidate:
_asm_cold_invalidate:
    lda _cold_busy
    bne cl_state_bad
    lda #0
    sta _cold_valid
    lda #1
    ldx #0
    rts
cl_state_bad:
    lda #1
    sta _cold_error
cl_no:
    lda #0
    tax
    rts

; No arguments: cold_entry(void) reads _cold_command and uses the live stack.
; Never enter a separately generated _start, which would reset that stack.
asm_cold_invoke:
_asm_cold_invoke:
    lda _cold_busy
    bne cl_state_bad
    lda _cold_valid
    cmp #2
    bcc cl_state_bad
    cmp #4
    bcs cl_state_bad
    lda $01
    and #7
    cmp #6
    bne cl_state_bad
    inc _cold_busy
    jsr $b000
    lda #0
    sta _cold_busy
    rts

; _fastcall module ID in A. Return A=1 only after exact EOF, DOS and cleanup.
asm_cold_load:
_asm_cold_load:
    cmp #2
    bcc cl_state_bad
    cmp #4
    bcs cl_state_bad
    sta _cold_requested
    lda cl_initialized
    beq cl_state_bad
    lda _cold_busy
    bne cl_state_bad
    lda $01
    and #7
    cmp #6
    bne cl_state_bad
    lda _cold_application_device
    cmp #8
    bcc cl_state_bad
    cmp #12
    bcs cl_state_bad
    lda #0
    sta _cold_error
    lda _cold_requested
    cmp _cold_valid
    beq cl_yes
    jsr asm_cold_invalidate
    lda #0
    sta _file_io_failed
    sta _file_io_eof
    sta _file_dos_code
    sta cl_open_mask
    jsr cl_open
    bcs cl_finish
    jsr cl_read_image
    bcs cl_finish
    jsr cl_close_data
    lda _file_io_failed
    bne cl_finish
    jsr _file_dos_status
    cmp #0
    beq cl_finish
    lda #3
    sta _cold_error
cl_finish:
    jsr cl_cleanup
    lda _file_io_failed
    beq cl_check_result
    lda _cold_error
    bne cl_check_result
    lda #2
    sta _cold_error
cl_check_result:
    lda _cold_error
    beq cl_publish
    jmp cl_no
cl_publish:
    lda _cold_requested
    sta _cold_valid
cl_yes:
    lda #1
    ldx #0
    rts

; Real KERNAL OPEN/CHKIN, selected once for the whole bounded PRG stream.
; The existing DOS kernel consumes its carry/READST immediately; the selected
; channel15 belongs to application_device, not the application's disk_device.
cl_open:
    lda #0
    tax
    tay
    jsr $ffbd
    lda #15
    ldx _cold_application_device
    ldy #15
    jsr $ffba
    lda #1
    sta cl_open_mask
    jsr $ffc0
    bcs cl_open_io
    jsr $ffb7
    bne cl_open_io
    jsr _file_dos_status
    lda _file_io_failed
    bne cl_open_io
    lda #0
    sta _file_dos_code
    ldx _cold_requested
    dex
    dex
    lda cl_name_low,x
    sta $fb
    lda cl_name_high,x
    tay
    lda cl_name_length,x
    ldx $fb
    jsr $ffbd
    lda #2
    ldx _cold_application_device
    ldy #2
    jsr $ffba
    lda #3
    sta cl_open_mask
    jsr $ffc0
    bcs cl_open_io
    jsr $ffb7
    bne cl_open_io
    jsr _file_dos_status
    cmp #0
    bne cl_open_dos
    lda _file_io_failed
    bne cl_open_io
    ldx #2
    jsr $ffc6
    bcs cl_open_io
    jsr $ffb7
    bne cl_open_io
    lda #0
    sta _file_io_eof
    clc
    rts
cl_open_dos:
    lda #3
    sta _cold_error
    sec
    rts
cl_open_io:
    lda #1
    sta _file_io_failed
    lda #2
    sta _cold_error
    sec
    rts

cl_required:
    jsr asm_file_stream_get
    bne cl_required_yes
    lda #7
    sta _cold_error
    lda _file_io_failed
    beq cl_required_no
    lda #2
    sta _cold_error
cl_required_no:
    sec
    rts
cl_required_yes:
    lda _file_io_value
    clc
    rts

cl_read_image:
    jsr cl_required
    bcc cl_read_origin
    rts
cl_read_origin:
    cmp #0
    bne cl_origin_bad
    jsr cl_required
    bcs cl_read_no
    cmp #$b0
    bne cl_origin_bad
    lda #0
    sta cl_index
cl_header_next:
    jsr cl_required
    bcs cl_read_no
    ldx cl_index
    sta cl_header,x
    inc cl_index
    cpx #15
    bne cl_header_next
    jsr cl_validate
    bcs cl_read_no
    ldx #15
cl_header_copy:
    lda cl_header,x
    sta $b000,x
    dex
    bpl cl_header_copy
    lda #$10
    sta cl_pointer
    lda #$b0
    sta cl_pointer+1
cl_body_next:
    jsr cl_required
    bcs cl_read_no
    pha
    lda cl_pointer
    sta $fb
    lda cl_pointer+1
    sta $fc
    pla
    ldy #0
    sta ($fb),y
    inc cl_pointer
    bne cl_body_end
    inc cl_pointer+1
cl_body_end:
    lda cl_pointer+1
    cmp cl_end+1
    bne cl_body_next
    lda cl_pointer
    cmp cl_end
    bne cl_body_next
    jsr asm_file_stream_get
    bne cl_tail_bad
    lda _file_io_failed
    beq cl_read_eof
    jmp cl_open_io
cl_read_eof:
    lda _file_io_eof
    beq cl_tail_bad
    clc
    rts
cl_origin_bad:
    lda #4
    sta _cold_error
cl_read_no:
    sec
    rts
cl_tail_bad:
    lda #8
    sta _cold_error
    sec
    rts

cl_validate:
    lda #5
    sta _cold_error
    lda cl_header
    cmp #$4c
    beq cl_validate_magic
    sec
    rts
cl_validate_magic:
    ldx #4
cl_magic:
    lda cl_header+3,x
    cmp cl_signature,x
    bne cl_validate_no
    dex
    bpl cl_magic
    lda cl_header+10
    cmp _cold_requested
    bne cl_validate_no
    lda cl_header+11
    cmp #1
    bne cl_validate_no
    ldx #3
cl_reserved:
    lda cl_header+12,x
    bne cl_validate_no
    dex
    bpl cl_reserved
    lda #6
    sta _cold_error
    lda cl_header+9
    cmp #$20
    bcc cl_size_low
    bne cl_validate_no
    lda cl_header+8
    bne cl_validate_no
cl_size_low:
    lda cl_header+9
    bne cl_size_ok
    lda cl_header+8
    cmp #17
    bcc cl_validate_no
cl_size_ok:
    clc
    lda cl_header+9
    adc #$b0
    sta cl_end+1
    lda cl_header+8
    sta cl_end
    lda #5
    sta _cold_error
    lda cl_header+2
    cmp #$b0
    bcc cl_validate_no
    bne cl_entry_upper
    lda cl_header+1
    cmp #$10
    bcc cl_validate_no
cl_entry_upper:
    lda cl_header+2
    cmp cl_end+1
    bcc cl_validate_yes
    bne cl_validate_no
    lda cl_header+1
    cmp cl_end
    bcs cl_validate_no
cl_validate_yes:
    lda #0
    sta _cold_error
    clc
    rts
cl_validate_no:
    sec
    rts

cl_close_data:
    lda cl_open_mask
    and #2
    beq cl_close_done
    lda #2
    clc
    jsr $ffc3
    jsr cl_close_status
    lda cl_open_mask
    and #1
    sta cl_open_mask
cl_close_done:
    rts
cl_cleanup:
    jsr $ffcc
    jsr cl_close_data
    lda cl_open_mask
    beq cl_cleanup_done
    lda #15
    clc
    jsr $ffc3
    jsr cl_close_status
cl_cleanup_done:
    lda #0
    sta cl_open_mask
    jmp $ffcc
cl_close_status:
    bcs cl_close_failed
    jsr $ffb7
    and #$bf
    beq cl_close_done
cl_close_failed:
    lda #1
    sta _file_io_failed
    rts

cl_signature: .byte $4d,$36,$34,$43,1
cl_name_length: .byte 13,14
cl_name_low: .byte <cl_print_name,<cl_search_name
cl_name_high: .byte >cl_print_name,>cl_search_name
cl_print_name: .byte $4d,$36,$34,$2d,$50,$52,$49,$4e,$54,$2c,$50,$2c,$52
cl_search_name: .byte $4d,$36,$34,$2d,$53,$45,$41,$52,$43,$48,$2c,$50,$2c,$52
cl_loader_end:
