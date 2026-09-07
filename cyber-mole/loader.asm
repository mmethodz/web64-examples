; Application policy only. Web64 owns transport, lifecycle and W64X decoding.
; Inactive route RAM $b000-$b7ff receives packed input. Disjoint $e000-$fbff
; scratch holds decoded bytes until the SDK's checked transactional commit.
.include "web64/loader.inc"
.macro cm_load name, length, device, destination, end
    lda #<destination
    sta cm_destination
    lda #>destination
    sta cm_destination+1
    lda #<end
    sta cm_limit
    lda #>end
    sta cm_limit+1
    web64_rt_prepare_loader_read name, length, $b000, 2048
    jsr cm_load_stream
.endmacro

disk_enter:
    sei
    lda #$36
    sta $01
    ; The game owns screen codes and mixed-mode Color RAM, not the ROM editor.
    ; BASIC/previous I/O can leave SAVE's console messages enabled at $9d.
    lda $9d
    sta disk_message_mode
    lda #0
    jsr $ff90
    jsr silence_irqs
    lda $0314
    sta disk_irq_vector
    lda $0315
    sta disk_irq_vector+1
    lda #<disk_irq
    sta $0314
    lda #>disk_irq
    sta $0315
    lda #248
    sta $d012
    lda #$1b
    sta $d011
    lda #1
    sta $d019
    sta $d01a
    sta loader_active
    lda scene_visible
    bne disk_present_ready
    jsr loader_bit
disk_present_ready:
    lda #<cm_nmi
    sta $fffa
    lda #>cm_nmi
    sta $fffb
    lda #<cm_irq_ram
    sta $fffe
    lda #>cm_irq_ram
    sta $ffff
    lda #$35
    sta $01
    cli
    rts
disk_leave:
    sei
    lda #$36
    sta $01
    jsr silence_irqs
    lda disk_irq_vector
    sta $0314
    lda disk_irq_vector+1
    sta $0315
    lda #0
    sta loader_active
    lda disk_message_mode
    jsr $ff90
    lda #$ff
    sta $dc02
    sta $dc00
    lda #$35
    sta $01
    rts

; The KERNAL IRQ entry saves A/X/Y. Native Animation owns $fb..$fe; the
; generated SID event player uses absolute RAM, not zero page. No KERNAL,
; renderer or file routine is called from here. See LOADER.md for ownership.
disk_irq:
    jsr disk_irq_body
    jmp $ea81
cm_irq_ram:
    pha
    txa
    pha
    tya
    pha
    jsr disk_irq_body
    pla
    tay
    pla
    tax
    pla
    rti
disk_irq_body:
    lda #1
    sta $d019
    lda $fb
    pha
    lda $fc
    pha
    lda $fd
    pha
    lda $fe
    pha
    cld
    jsr loader_present
    pla
    sta $fe
    pla
    sta $fd
    pla
    sta $fc
    pla
    sta $fb
    rts

loader_present:
    inc loader_ticks
    bne loader_tick_ready
    inc loader_ticks+1
loader_tick_ready:
    jsr tick_music
    lda scene_visible
    beq loader_bit
    jmp scene_present
loader_bit:
    web64_rt_call_animation_tick bit_anim
    lda bit_anim+6
    clc
    adc #$c0
    sta $07f8
    lda #1
    sta $d015
    lda #0
    sta $d010
    sta $d017
    sta $d01d
    lda #172
    sta $d000
    lda #208
    sta $d001
    lda #3
    sta $d027
    rts

cm_load_stream:
    lda cm_loader_ready
    bne cm_loader_prepared
    ; Retry also handles an initially absent or power-cycled drive. No hidden
    ; KERNAL fallback and no game callback inside the serial protocol.
    web64_rt_call_loader_init 8,$bf00,loader_ticks
    cmp #0
    bne cm_error
    lda #1
    sta cm_loader_ready
cm_loader_prepared:
    jsr _web64_loader_read
    cmp #0
    bne cm_error
    web64_rt_call_loader_last_size
    sta cm_length
    stx cm_length+1
    lda cm_destination+1
    cmp #$cf
    beq cm_raw_scores
    web64_rt_call_loader_last_origin
    cmp #0
    bne cm_error
    cpx #$b0
    bne cm_error
    lda cm_destination+1
    cmp #$b9
    bne cm_single_bank
    jmp cm_cache_install
cm_single_bank:
    ; These application banks are single restore-at-origin records. The SDK
    ; validates all format, bounds, CRC, stream and decoded-data invariants.
    lda $b005
    cmp #1
    bne cm_error
    lda $b008
    cmp cm_destination
    bne cm_error
    lda $b009
    cmp cm_destination+1
    bne cm_error
    jsr cm_unpack_staged
    cmp #0
    bne cm_error
    clc
    lda cm_destination
    adc $b00a
    sta cm_end
    lda cm_destination+1
    adc $b00b
    sta cm_end+1
cm_success:
    lda #64
    sta cm_status
    rts
cm_error:
    lda #0
    sta cm_loader_ready
    lda #2
    sta cm_status
    rts
cm_raw_scores:
    ; Score-file shape/checksum is application semantics, not loader format.
    lda cm_length
    cmp #64
    bne cm_error
    lda cm_length+1
    bne cm_error
    web64_rt_call_loader_last_origin
    cmp #0
    bne cm_error
    cpx #$cf
    bne cm_error
    lda #0
    sta SRC
    sta PTR
    lda #$b0
    sta SRC+1
    lda #$cf
    sta PTR+1
    jsr cm_copy_received
    jmp cm_success
cm_unpack_staged:
    lda cm_length
    sta cm_unpack_request+2
    lda cm_length+1
    sta cm_unpack_request+3
    lda cm_destination
    sta cm_unpack_request+4
    lda cm_destination+1
    sta cm_unpack_request+5
    sec
    lda cm_limit
    sbc cm_destination
    sta cm_unpack_request+6
    lda cm_limit+1
    sbc cm_destination+1
    sta cm_unpack_request+7
    web64_rt_call_loader_unpack cm_unpack_request
    rts
cm_copy_received:
    ldy #0
    ldx cm_length+1
    beq cm_copy_tail
cm_copy_page:
    lda (SRC),y
    sta (PTR),y
    iny
    bne cm_copy_page
    inc SRC+1
    inc PTR+1
    dex
    bne cm_copy_page
cm_copy_tail:
    ldx cm_length
    beq cm_copy_done
cm_copy_received_loop:
    lda (SRC),y
    sta (PTR),y
    iny
    dex
    bne cm_copy_received_loop
cm_copy_done:
    clc
    lda PTR
    adc cm_length
    sta cm_end
    lda PTR+1
    adc #0
    sta cm_end+1
    rts
cm_last_end:
    lda cm_end
    ldx cm_end+1
    rts
cm_nmi:
    rti


disk_irq_vector: .word 0
disk_message_mode: .byte 0
loader_ticks: .word 0
loader_active: .byte 0
cm_destination: .word 0
cm_limit: .word 0
cm_end: .word 0
cm_loader_ready: .byte 0
cm_status: .byte 0
cm_length: .word 0
cm_unpack_request: .word $b000,0,0,0,$e000,7168
    .byte 255
