; Measured screen kernels. Ordinary web64-stack-v1 C calls put exact-width
; arguments at ($02),Y; these leaves read that window without moving SP/FP.
; No compiler-private parameter labels and no fixed resident code addresses.
; $fb/$fc is call-scoped text scratch. IRQ/keyboard service remains enabled.

; Fixed screen-code status text, A/X = pointer. Truncate before the final NUL;
; the document name and other live PETSCII are rendered by their own path.
_ui_message:
    sta $fb
    stx $fc
    ldy #0
ui_message_copy:
    lda ($fb),y
    beq ui_message_end
    sta _status_message,y
    iny
    cpy #39
    bne ui_message_copy
    lda #0
ui_message_end:
    sta _status_message,y
    jmp _ui_status

_status_message: .fill 40,0

; Foreground ownership: ui_status runs after layout/painting has consumed the
; shared LINE_TEXT buffer. Menus invalidate layout before returning. No extra
; allocation, IRQ work or change to the public ui_write/number byte contract.
asm_status_begin:
    lda #1
    sta ui_status_composing
    ldx #39
    lda #160
ui_status_clear:
    sta $6e00,x
    dex
    bpl ui_status_clear
    rts
asm_status_commit:
    ldx #39
ui_status_copy:
    lda $6e00,x
    cmp $07c0,x
    beq ui_status_color
    sta $07c0,x
ui_status_color:
    lda $dbc0,x
    and #15
    cmp _theme_accent
    beq ui_status_next
    lda _theme_accent
    sta $dbc0,x
ui_status_next:
    dex
    bpl ui_status_copy
    lda #0
    sta ui_status_composing
    rts
ui_status_composing: .byte 0

; Cheaper foreground mailbox entry for fixed labels. No parameter frame is
; needed; the ordinary ui_write C entry below remains ABI-compatible.
_asm_ui_write:
asm_ui_write:
    lda #0
    sta ui_native
    lda ui_column
    sta ui_left
    lda _ui_draw_text
    sta $fb
    lda _ui_draw_text+1
    sta $fc
    jsr ui_row_address
    jmp ui_text_next

_ui_write:
    lda #0
    beq ui_text_mode
_ui_petscii:
    lda #1
ui_text_mode:
    sta ui_native
    jsr ui_read_position
    ldy #2
    lda ($02),y
    sta $fb
    iny
    lda ($02),y
    sta $fc
    jsr ui_row_address
ui_text_next:
    lda ui_row
    cmp #25
    bcs ui_done
    ldy #0
    lda ($fb),y
    beq ui_done
    inc $fb
    bne ui_text_byte
    inc $fc
ui_text_byte:
    ldx ui_native
    bne ui_native_byte
    cmp #255
    beq ui_text_newline
ui_text_ready:
    jsr ui_put_character
    jmp ui_text_next
; Data labels are PETSCII, not ASCII and not terminal commands. Screen codes
; are chosen for the same lower/upper ROM font as the document viewport.
ui_native_byte:
    jsr _ui_petscii_code
    jmp ui_text_ready
_ui_petscii_code:
    ldx #0
    cmp #32
    bcc ui_native_control
    cmp #64
    bcc ui_native_ready
    cmp #96
    bcc ui_native_sub64
    cmp #128
    bcc ui_native_sub32
    cmp #160
    bcc ui_native_control
    cmp #192
    bcc ui_native_sub64
    cmp #255
    beq ui_native_pi
    and #127
    rts
ui_native_sub32:
    sec
    sbc #32
    rts
ui_native_sub64:
    sec
    sbc #64
    rts
ui_native_pi:
    lda #94
    rts
ui_native_control:
    lda #63
ui_native_ready:
    rts
ui_text_newline:
    inc ui_row
    lda ui_left
    sta ui_column
    jsr ui_row_address
    jmp ui_text_next
ui_done:
    rts

ui_read_position:
    ldy #0
    lda ($02),y
    sta ui_row
    iny
    lda ($02),y
    sta ui_column
    sta ui_left
    rts
ui_row_address:
    ldx ui_row
    cpx #25
    bcs ui_done
    lda mv_screen_lo,x
    sta ui_screen_store+1
    sta ui_color_store+1
    lda mv_screen_hi,x
    sta ui_screen_store+2
    clc
    adc #$d4
    sta ui_color_store+2
    rts
ui_put_character:
    ldy ui_column
    cpy #40
    bcs ui_done
    ldx ui_status_composing
    beq ui_screen_store
    ldx ui_row
    cpx #24
    bne ui_screen_store
    ora #128
    sta $6e00,y
    inc ui_column
    rts
ui_screen_store:
    sta $0400,y
    lda _theme_foreground
ui_color_store:
    sta $d800,y
    inc ui_column
    rts

_ui_number:
    jsr ui_read_position
    lda ui_row
    cmp #25
    bcs ui_done
    ldy #2
    lda ($02),y
    sta ui_value
    iny
    lda ($02),y
    sta ui_value+1
    iny
    lda ($02),y
    beq ui_done
    cmp #6
    bcs ui_done
    sta ui_digits
    jsr ui_row_address
    lda #0
    sta ui_place
ui_decimal_place:
    ldx ui_place
    lda #48
    sta ui_digit
ui_decimal_subtract:
    lda ui_value
    sec
    sbc ui_decimal_lo,x
    sta ui_remainder
    lda ui_value+1
    sbc ui_decimal_hi,x
    bcc ui_decimal_digit
    sta ui_value+1
    lda ui_remainder
    sta ui_value
    inc ui_digit
    jmp ui_decimal_subtract
ui_decimal_digit:
    lda #5
    sec
    sbc ui_place
    cmp ui_digits
    bcc ui_decimal_emit
    bne ui_decimal_next
ui_decimal_emit:
    lda ui_digit
    jsr ui_put_character
ui_decimal_next:
    inc ui_place
    lda ui_place
    cmp #5
    bne ui_decimal_place
    rts

ui_decimal_lo: .byte <10000,<1000,<100,<10,<1
ui_decimal_hi: .byte >10000,>1000,>100,>10,>1
ui_row: .byte 0
ui_column: .byte 0
ui_left: .byte 0
ui_value: .word 0
ui_remainder: .byte 0
ui_digit: .byte 0
ui_digits: .byte 0
ui_place: .byte 0
ui_native: .byte 0
_ui_draw_row = ui_row
_ui_draw_column = ui_column
_ui_draw_text: .word 0
