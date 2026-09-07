; Game-owned district cache. W64X validation and transactional decoding belong
; to Web64; this file only selects a room and retains the opaque packed bytes.
cm_load_cached_room:
    lda cm_cached_district
    cmp district
    bne cm_cache_cold
    jmp cm_restore_room
cm_cache_cold:
    lda district
    clc
    adc #44
    sta cm_cache_name+4
    cm_load cm_cache_name, 5, 8, $b900, $bf00
    and #$bf
    bne cm_cache_return
    lda district
    sta cm_cached_district
    jmp cm_room_success
cm_cache_return:
    rts

cm_cache_install:
    lda cm_length+1
    cmp #6
    bcc cm_cache_length_ok
    bne cm_cache_bad
    lda cm_length
    bne cm_cache_bad
cm_cache_length_ok:
    lda #0
    sta SRC
    sta cm_room_request
    lda #$b0
    sta SRC+1
    sta cm_room_request+1
    lda cm_length
    sta cm_room_request+2
    lda cm_length+1
    sta cm_room_request+3
    jsr cm_decode_room
    cmp #0
    bne cm_cache_bad
    lda #0
    sta SRC
    sta PTR
    lda #$b0
    sta SRC+1
    lda #$b9
    sta PTR+1
    jsr cm_copy_received
    lda cm_length
    sta cm_cached_length
    lda cm_length+1
    sta cm_cached_length+1
    jmp cm_success
cm_cache_bad:
    lda #255
    sta cm_cached_district
    jmp cm_error

cm_restore_room:
    lda #0
    sta SRC
    sta cm_room_request
    lda #$b9
    sta SRC+1
    sta cm_room_request+1
    lda cm_cached_length
    sta cm_room_request+2
    lda cm_cached_length+1
    sta cm_room_request+3
    jsr cm_decode_room
    cmp #0
    bne cm_cache_bad
cm_room_success:
    lda #0
    sta cm_end
    lda #$c4
    sta cm_end+1
    jmp cm_success

cm_decode_room:
    ; Six independent 1 KiB room records restored at $c000 are game policy,
    ; not a constraint imposed on other users of the loader runtime.
    ldy #5
    lda (SRC),y
    cmp #6
    bne cm_room_shape_bad
    lda local_level
    cmp #6
    bcs cm_room_shape_bad
    sta cm_room_request+12
    asl
    sta TEMP
    asl
    asl
    clc
    adc TEMP
    adc #8
    tay
    lda (SRC),y
    bne cm_room_shape_bad
    iny
    lda (SRC),y
    cmp #$c0
    bne cm_room_shape_bad
    iny
    lda (SRC),y
    bne cm_room_shape_bad
    iny
    lda (SRC),y
    cmp #4
    bne cm_room_shape_bad
    web64_rt_call_loader_unpack cm_room_request
    rts
cm_room_shape_bad:
    lda #2
    rts
cm_cache_name: .text "CACH1"
cm_cached_district: .byte 255
cm_cached_length: .word 0
cm_room_request: .word $b900,0,$c000,1024,$e000,1024
    .byte 0
