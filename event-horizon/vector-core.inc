; Real-time integer line drawing directly into a hidden four-sprite plane.
; Projection descriptors contain vertices/slopes, NOT completed sprite images.
; Cost-balanced 10/14-segment halves; publish a complete pose every other frame.
; Shared zero-page is caller-owned; only this non-reentrant main-thread code uses it.
vx = $e0
vy = $e1
vmajor = $e2
vminor = $e3
vend = $e4
verror = $e5
vcount = $e6
vmode = $e7
vptr = $eb

core_render:
    lda core_half
    beq core_first_half
    lda #14
    sta vcount
    jmp v_edge
core_first_half:
    lda core_front
    eor #1
    sta core_back
    sta vx_read+2
    sta vx_write+2
    sta vy_read+2
    sta vy_write+2
    cmp #$51
    bne v_clear_first
    lda #0
    jsr clear_core51
    jmp v_cleared
v_clear_first:
    lda #0
    jsr clear_core50
v_cleared:
    lda animation_clock
    lsr
    and #63
    tax
    lda core_pose_lo,x
    sta vptr
    lda core_pose_hi,x
    sta vptr+1
    lda #10
    sta vcount
v_edge:
    ldy #0
    lda (vptr),y
    sta vx
    iny
    lda (vptr),y
    sta vy
    iny
    lda (vptr),y
    sta vmajor
    lsr
    sta verror
    iny
    lda (vptr),y
    sta vminor
    iny
    lda (vptr),y
    sta vmode
    cmp #2
    bcs v_y_major
    ldx vmode
    lda v_y_steps,x
    sta vx_minor_step
    clc
    lda vx
    adc vmajor
    sta vx_endpoint+1
    ldx vx
    ldy vy
    jsr vx_line
    jmp v_next_edge
v_y_major:
    and #1
    tax
    lda v_x_steps,x
    sta vy_minor_step
    clc
    lda vy
    adc vmajor
    sta vy_endpoint+1
    ldx vx
    ldy vy
    jsr vy_line
v_next_edge:
    clc
    lda vptr
    adc #5
    sta vptr
    bcc v_next_page
    inc vptr+1
v_next_page:
    dec vcount
    beq v_half_done
    jmp v_edge
v_half_done:
    lda core_half
    eor #1
    sta core_half
    bne v_done
    lda core_back
    sta core_front
v_done:
    rts

; X-major kernel. Keep X/Y as actual pixel coordinates throughout.
vx_line:
    lda core_rows,y
    clc
    adc core_columns,x
    sta vx_read+1
    sta vx_write+1
vx_read:
    lda $5000
    ora core_masks,x
vx_write:
    sta $5000
vx_endpoint:
    cpx #0
    beq vx_done
    inx
    sec
    lda verror
    sbc vminor
    bpl vx_store_error
    ; Negative subtraction has already cleared carry (error < minor).
    adc vmajor
vx_minor_step:
    iny
vx_store_error:
    sta verror
    jmp vx_line
vx_done:
    rts

vy_line:
    lda core_rows,y
    clc
    adc core_columns,x
    sta vy_read+1
    sta vy_write+1
vy_read:
    lda $5000
    ora core_masks,x
vy_write:
    sta $5000
vy_endpoint:
    cpy #0
    beq vy_done
    iny
    sec
    lda verror
    sbc vminor
    bpl vy_store_error
    ; The borrow supplies the clear carry for this error wrap.
    adc vmajor
vy_minor_step:
    inx
vy_store_error:
    sta verror
    jmp vy_line
vy_done:
    rts
v_y_steps: .byte $c8,$88
v_x_steps: .byte $e8,$ca
.include "core-clear.inc"
