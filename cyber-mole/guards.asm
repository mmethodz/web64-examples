; Sentinel routing. Four flow fields are rebuilt only when a grid is loaded.
; Each hot update follows one arrow per actor; there is no frame-time search.
; Reserved scratch RAM (not resident data): $b000..$b3c7 flow fields,
; $b400..$b4c7 breadth-first queue. Grid topology may open, never close.
sentinel_fields = $b000
sentinel_queue = $b400

reset_guards:
    ldx #3
sentinel_remember_home:
    lda actor_cell,x
    sta sentinel_home-1,x
    dex
    bne sentinel_remember_home
    lda #0
    sta guard_clock
    sta sentinel_goal
    sta sentinel_blocked
    sta sentinel_blocked+1
    sta sentinel_blocked+2
    sta sentinel_field
    lda #1
    sta sentinel_goal+1
    lda #3
    sta sentinel_goal+2
    lda enemy_period
    cmp #18
    bcs sentinel_period_ready
    lda #18
    sta enemy_period
sentinel_period_ready:
    ldy spawn_cell
    jsr sentinel_column
    sec
    sbc #2
    bcs sentinel_left_ready
    lda #0
sentinel_left_ready:
    sta sentinel_safe_left
    jsr sentinel_column
    clc
    adc #3
    sta sentinel_safe_right
    lda cell_y,y
    sec
    sbc #32
    sta sentinel_safe_top
    clc
    adc #65
    sta sentinel_safe_bottom
sentinel_build_field:
    lda #0
    sta PTR
    sta sentinel_head
    sta sentinel_tail
    lda sentinel_field
    clc
    adc #$b0
    sta PTR+1
    ldy #0
    lda #0
sentinel_clear_field:
    sta (PTR),y
    iny
    cpy #200
    bne sentinel_clear_field
    ldx sentinel_field
    ldy sentinel_waypoints,x
    ldx #200
sentinel_find_seed:
    lda grid,y
    jsr sentinel_solid
    bcc sentinel_seed_ready
    dex
    beq sentinel_field_done
    iny
    cpy #200
    bne sentinel_find_seed
    ldy #0
    jmp sentinel_find_seed
sentinel_seed_ready:
    lda #5
    sta (PTR),y
    tya
    sta sentinel_queue
    inc sentinel_tail
sentinel_queue_next:
    ldx sentinel_head
    lda sentinel_queue,x
    sta sentinel_origin
    lda #0
    sta sentinel_direction
sentinel_flood_neighbor:
    ldy sentinel_origin
    ldx sentinel_direction
    jsr sentinel_neighbor
    bcs sentinel_flood_next
    lda (PTR),y
    bne sentinel_flood_next
    txa
    eor #2
    clc
    adc #1
    sta (PTR),y
    ldx sentinel_tail
    tya
    sta sentinel_queue,x
    inc sentinel_tail
sentinel_flood_next:
    inc sentinel_direction
    lda sentinel_direction
    cmp #4
    bne sentinel_flood_neighbor
    inc sentinel_head
    lda sentinel_head
    cmp sentinel_tail
    bne sentinel_queue_next
sentinel_field_done:
    inc sentinel_field
    lda sentinel_field
    cmp #4
    beq sentinel_fields_ready
    jmp sentinel_build_field
sentinel_fields_ready:
    rts

; A life recovery cannot leave a guard parked in Bit's protected spawn zone.
; Only the guards in that zone are returned to their original map starts.
recover_guards:
    lda #0
    sta guard_clock
    ldx #3
sentinel_recover_loop:
    ldy actor_cell,x
    lda cell_y,y
    cmp sentinel_safe_top
    bcc sentinel_recover_next
    cmp sentinel_safe_bottom
    bcs sentinel_recover_next
    jsr sentinel_column
    cmp sentinel_safe_left
    bcc sentinel_recover_next
    cmp sentinel_safe_right
    bcs sentinel_recover_next
    ldy sentinel_home-1,x
    tya
    sta actor_cell,x
    lda cell_x,y
    sta actor_x,x
    lda cell_x_hi,y
    sta actor_x_hi,x
    lda cell_y,y
    sta actor_y,x
    lda #0
    sta sentinel_blocked-1,x
sentinel_recover_next:
    dex
    bne sentinel_recover_loop
    rts

update_guards:
    lda shield
    cmp #75
    bcc sentinel_awake
    rts
sentinel_awake:
    inc guard_clock
    lda guard_clock
    cmp enemy_period
    bcs sentinel_move_due
    rts
sentinel_move_due:
    lda #0
    sta guard_clock
    ldx #1
sentinel_actor_loop:
    stx guard_slot
    cpx #3
    bne sentinel_regular_actor
    lda rival_active
    bne sentinel_actor_next
sentinel_regular_actor:
    lda actor_active,x
    beq sentinel_actor_next
    lda actor_cell,x
    sta sentinel_origin
    jsr sentinel_chase
    bcc sentinel_check_step
    ldx guard_slot
    lda sentinel_goal-1,x
    clc
    adc #$b0
    sta PTR+1
    lda #0
    sta PTR
    ldy sentinel_origin
    lda (PTR),y
    cmp #5
    beq sentinel_advance
    cmp #1
    bcc sentinel_advance
    sec
    sbc #1
    tax
    jsr sentinel_neighbor
    bcs sentinel_advance
sentinel_check_step:
    sty sentinel_target
    lda shield
    beq sentinel_occupied
    lda cell_y,y
    cmp sentinel_safe_top
    bcc sentinel_occupied
    cmp sentinel_safe_bottom
    bcs sentinel_occupied
    jsr sentinel_column
    cmp sentinel_safe_left
    bcc sentinel_occupied
    cmp sentinel_safe_right
    bcc sentinel_actor_next
sentinel_occupied:
    ldx #1
sentinel_occupied_loop:
    lda actor_active,x
    beq sentinel_occupied_next
    lda actor_cell,x
    cmp sentinel_target
    beq sentinel_wait
sentinel_occupied_next:
    inx
    cpx #4
    bne sentinel_occupied_loop
    ldx guard_slot
    lda sentinel_target
    sta actor_cell,x
    lda #0
    sta sentinel_blocked-1,x
sentinel_actor_next:
    ldx guard_slot
    inx
    cpx #4
    beq sentinel_idle
    jmp sentinel_actor_loop
sentinel_idle:
    rts
sentinel_wait:
    ldx guard_slot
    inc sentinel_blocked-1,x
    lda sentinel_blocked-1,x
    cmp #2
    bcc sentinel_actor_next
sentinel_advance:
    ldx guard_slot
    lda #0
    sta sentinel_blocked-1,x
    lda sentinel_goal-1,x
    clc
    adc #1
    and #3
    sta sentinel_goal-1,x
    jmp sentinel_actor_next

; Chase only an aligned player within three cells, with a clear whole ray.
; The guard still advances one cell, giving the player time to dodge sideways.
sentinel_chase:
    ldy actor_cell
    ldx sentinel_origin
    lda cell_y,y
    cmp cell_y,x
    bne sentinel_chase_vertical
    tya
    sec
    sbc sentinel_origin
    beq sentinel_no_chase
    bcc sentinel_chase_left
    cmp #4
    bcs sentinel_no_chase
    ldx #1
    bne sentinel_chase_ray
sentinel_chase_left:
    cmp #253
    bcc sentinel_no_chase
    ldx #3
    bne sentinel_chase_ray
sentinel_chase_vertical:
    lda cell_x,y
    cmp cell_x,x
    bne sentinel_no_chase
    lda cell_x_hi,y
    cmp cell_x_hi,x
    bne sentinel_no_chase
    tya
    sec
    sbc sentinel_origin
    bcc sentinel_chase_up
    cmp #61
    bcs sentinel_no_chase
    ldx #2
    bne sentinel_chase_ray
sentinel_chase_up:
    cmp #196
    bcc sentinel_no_chase
    ldx #0
sentinel_chase_ray:
    ldy sentinel_origin
    jsr sentinel_neighbor
    bcs sentinel_no_chase
    sty sentinel_target
sentinel_chase_continue:
    cpy actor_cell
    beq sentinel_chase_ready
    jsr sentinel_neighbor
    bcc sentinel_chase_continue
sentinel_no_chase:
    sec
    rts
sentinel_chase_ready:
    ldy sentinel_target
    clc
    rts

; X direction 0=up,1=right,2=down,3=left; Y source. Return Y neighbor,
; carry clear if in bounds and not steel/rack/closed exit. X is preserved.
sentinel_neighbor:
    cpx #1
    beq sentinel_right_edge
    cpx #3
    bne sentinel_neighbor_add
    lda cell_x,y
    cmp #20
    bne sentinel_neighbor_add
    lda cell_x_hi,y
    beq sentinel_blocked_step
    bne sentinel_neighbor_add
sentinel_right_edge:
    lda cell_x,y
    cmp #68
    bne sentinel_neighbor_add
    lda cell_x_hi,y
    bne sentinel_blocked_step
sentinel_neighbor_add:
    tya
    clc
    adc sentinel_delta,x
    cmp #200
    bcs sentinel_blocked_step
    tay
    lda grid,y
sentinel_solid:
    cmp #2
    beq sentinel_blocked_step
    cmp #3
    beq sentinel_blocked_step
    cmp #5
    beq sentinel_blocked_step
    clc
    rts
sentinel_blocked_step:
    sec
    rts

; Convert the existing generated 9-bit pixel X lookup to its tile column.
; No additional resident 200-byte coordinate table is required.
sentinel_column:
    lda cell_x_hi,y
    asl
    asl
    asl
    asl
    sta sentinel_temp
    lda cell_x,y
    lsr
    lsr
    lsr
    lsr
    ora sentinel_temp
    sec
    sbc #1
    rts

sentinel_waypoints: .byte 44,55,155,144
sentinel_delta: .byte 236,1,20,255
sentinel_goal: .byte 0,1,3
sentinel_blocked: .byte 0,0,0
sentinel_home: .byte 0,0,0
sentinel_field: .byte 0
sentinel_head: .byte 0
sentinel_tail: .byte 0
sentinel_direction: .byte 0
sentinel_origin: .byte 0
sentinel_target: .byte 0
sentinel_temp: .byte 0
sentinel_safe_left: .byte 0
sentinel_safe_right: .byte 0
sentinel_safe_top: .byte 0
sentinel_safe_bottom: .byte 0
