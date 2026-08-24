; Open native descriptors: C, KickAssembler, or any other routine may inspect
; or replace these while sprite payload placement remains application-owned.
_base_asset:
    .word $3000
    .word $0100
    .word 4
    .byte 64, 63, 24, 21, 2, 5, 6, 14, 0
_overlay_asset:
    .word $3100
    .word $0100
    .word 4
    .byte 64, 63, 24, 21, 1, 1, 6, 14, 0
_pair_asset:
    .word _base_asset
    .word _overlay_asset
    .word 4
    .byte 5, 1, 6, 14, 0

_example_init_pair_binding:
    lda #<_pair_asset
    sta _pair_binding
    lda #>_pair_asset
    sta _pair_binding+1
    lda #$c0
    sta _pair_binding+2
    lda #$c4
    sta _pair_binding+3
    rts

; Application-owned IRQ wrapper. The mux never installs, acknowledges, or
; terminates an interrupt for the application.

_example_install_irq:
    sei
    lda $0314
    sta example_irq_chain+1
    lda $0315
    sta example_irq_chain+2
    lda #<example_irq
    sta $0314
    lda #>example_irq
    sta $0315
    lda $d01a
    ora #1
    sta $d01a
    cli
    rts

example_irq:
    ; The KERNAL dispatcher has already saved A/X/Y before entering $0314.
    lda $d019
    and #1
    beq example_irq_chain
    lda #1
    sta $d019
    inc _irq_count
    lda $d012
    sta _irq_entry_line
    lda __web64_mux_irq_frame_boundary
    beq example_irq_service
    inc _frame_tick
example_irq_service:
    jsr _web64_sprite_mux_irq_service_fast
    lda $d012
    sta _irq_exit_line
    jmp $ea81
example_irq_chain:
    jmp $ffff
