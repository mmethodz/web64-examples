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

; Make startup intentional immediately. C initialization and the first open
; schedule can take longer than one frame, so never expose the BASIC screen or
; half-initialized sprite state while those caller-owned buffers are prepared.
_example_prepare_video:
    lda $d011
    and #$ef
    sta $d011
    lda #0
    sta $d015
    sta $d020
    sta $d021
    lda #$20
    ldx #0
example_clear_screen:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne example_clear_screen
    rts

_example_show_video:
    lda $d011
    ora #$10
    sta $d011
    rts

; Open application adapter: integrate the caller-owned Q12.4 X positions and
; update the visible cohort's left edge from a 32-sample sine table, then
; select one actor for this frame's full scalar-compatible animation
; transition. The precomputed pair phase does not consume right edges here.
; No runtime-private state is used.
_example_prepare_frame_inputs:
    inc _wave_phase
    lda _wave_phase
    and #31
    sta _wave_phase
    tax
    lda example_wave,x
    sec
    sbc #24
    sta example_wave_offset
    lda example_velocity_lo,x
    sta example_velocity_value_lo
    lda example_velocity_hi,x
    sta example_velocity_value_hi

    lda _frame_counter
    and #31
    sta _animation_active_ids

    ldx #0
    ldy #0
example_motion_loop:
    cpx #36
    bcs example_motion_direct
    lda _home_x,x
    clc
    adc example_wave_offset
    sta _bounds_left,y
example_motion_direct:
    lda _pool_x,x
    clc
    adc example_velocity_value_lo
    sta _pool_x,x
    lda _pool_x+1,x
    adc example_velocity_value_hi
    sta _pool_x+1,x
example_motion_next:
    iny
    inx
    inx
    cpx #64
    bne example_motion_loop
    rts

example_wave:
    .byte 24,29,33,37,41,44,46,47,48,47,46,44,41,37,33,29
    .byte 24,19,15,11,7,4,2,1,0,1,2,4,7,11,15,19
example_velocity_lo:
    .byte $50,$50,$40,$40,$40,$30,$20,$10,$10,$f0,$f0,$e0,$d0,$c0,$c0,$c0
    .byte $b0,$b0,$c0,$c0,$c0,$d0,$e0,$f0,$f0,$10,$10,$20,$30,$40,$40,$40
example_velocity_hi:
    .byte 0,0,0,0,0,0,0,0,0,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,0,0,0,0,0,0,0
example_wave_offset: .byte 0
example_velocity_value_lo: .byte 0
example_velocity_value_hi: .byte 0

; Application-owned IRQ wrapper. The mux never installs, acknowledges, or
; terminates an interrupt for the application.

_example_install_irq:
    sei
    tsx
    stx example_install_entry_sp
    ; This standalone game uses the mux raster boundary as its sole tick.
    ; Disable and drain both CIA interrupt sources before CLI so a pending
    ; KERNAL jiffy IRQ from the long, interrupt-disabled startup cannot race
    ; the application vector handoff.
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d
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
    tsx
    stx example_install_exit_sp
    rts

example_irq:
    inc example_irq_entered
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

example_install_entry_sp: .byte 0
example_install_exit_sp: .byte 0
example_irq_entered: .byte 0
