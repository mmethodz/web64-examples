; PRISM / eight independently timed VIC colour writes within each 63-cycle line.
; Runs in the lower border: no badline and no sprite DMA can steal these cycles.
; A double IRQ removes the foreground instruction's 0..6 cycle entry uncertainty.
; The final D012 comparison compensates the remaining 1-cycle NOP ambiguity.
; Saved registers are operands, not stack pushes; TXS discards only the nested IRQ.
prism_arm:
    sta prism_restore_a+1
    stx prism_restore_x+1
    sty prism_restore_y+1
    lda #<prism_stable
    sta $fffe
    lda #>prism_stable
    sta $ffff
    lda #1
    sta $d012
    sta $d019
    tsx
    cli
    .fill 16,$ea
prism_wait_nested:
    jmp prism_wait_nested

prism_stable:
    txs
    ldx #8
prism_align:
    dex
    bne prism_align
    bit $ea
    lda $d012
    cmp $d012
    beq prism_phase
prism_phase:
    lda #1
    sta $d019
    ; Each unrolled line: 8 * (LDA # = 2 + STA abs = 4) + 15 = 63 cycles.
    ; The write boundaries are 6 cycles / 48 VIC pixels apart.
prism_line0:
    lda #6
    sta $d020
    lda #14
    sta $d020
    lda #3
    sta $d020
    lda #1
    sta $d020
    lda #3
    sta $d020
    lda #14
    sta $d020
    lda #6
    sta $d020
    lda #0
    sta $d020
    bit $ea
    .fill 6,$ea
prism_line1:
    lda #6
    sta $d020
    lda #14
    sta $d020
    lda #3
    sta $d020
    lda #1
    sta $d020
    lda #3
    sta $d020
    lda #14
    sta $d020
    lda #6
    sta $d020
    lda #0
    sta $d020
    bit $ea
    .fill 6,$ea
prism_line2:
    lda #6
    sta $d020
    lda #14
    sta $d020
    lda #3
    sta $d020
    lda #1
    sta $d020
    lda #3
    sta $d020
    lda #14
    sta $d020
    lda #6
    sta $d020
    lda #0
    sta $d020
    bit $ea
    .fill 6,$ea
prism_line3:
    lda #6
    sta $d020
    lda #14
    sta $d020
    lda #3
    sta $d020
    lda #1
    sta $d020
    lda #3
    sta $d020
    lda #14
    sta $d020
    lda #6
    sta $d020
    lda #0
    sta $d020
    bit $ea
    .fill 6,$ea
prism_line4:
    lda #6
    sta $d020
    lda #14
    sta $d020
    lda #3
    sta $d020
    lda #1
    sta $d020
    lda #3
    sta $d020
    lda #14
    sta $d020
    lda #6
    sta $d020
    lda #0
    sta $d020
    bit $ea
    .fill 6,$ea
prism_end:
    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff
    lda #$1b
    sta $d011
    lda #48
    sta $d012
prism_restore_a:
    lda #0
prism_restore_x:
    ldx #0
prism_restore_y:
    ldy #0
    rti
