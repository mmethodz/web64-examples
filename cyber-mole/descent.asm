; Deep Descent cold bank transitions; no disk access from active game frames.
load_region:
    ldx district
    lda region_for_district,x
    cmp loaded_region
    bne region_change
    rts
region_change:
    sta wanted_region
load_visual_retry:
    lda wanted_region
    clc
    adc #48
    sta visual_name+4
    jsr disk_enter
    cm_load visual_name, 5, 8, $2000, $3c00
    sta disk_status
    jsr disk_leave
    lda disk_status
    and #$bf
    bne visual_failed
    jsr cm_last_end
    cmp #0
    bne visual_failed
    txa
    ldx wanted_region
    cmp visual_end_hi,x
    bne visual_failed
    lda $2d00
    cmp #67
    bne visual_failed
    lda $2d01
    cmp #89
    bne visual_failed
    lda $2d02
    cmp #86
    bne visual_failed
    lda $2d03
    cmp #1
    bne visual_failed
    lda $2d04
    cmp wanted_region
    bne visual_failed
    sta loaded_region
    lda $2d05
    sta $d022
    sta $d025
    lda $2d06
    sta $d023
    lda wanted_region
    beq region_ready
    lda lives
    cmp #5
    bcs region_no_battery
    inc lives
region_no_battery:
    lda wanted_region
    jsr play_scene
    jsr load_region_music
    rts
visual_failed:
    jsr show_disk_error
    jmp load_visual_retry
region_ready:
    rts
wanted_region: .byte 0

load_region_music:
    lda wanted_region
    beq region_music_done
    clc
    adc #48
    sta tune_name+4
load_tune_retry:
    jsr disk_enter
    cm_load tune_name, 5, 8, $9000, $a600
    sta disk_status
    jsr disk_leave
    lda disk_status
    and #$bf
    bne tune_failed
    jsr cm_last_end
    sta tune_end_lo
    stx tune_end_hi
    ldx wanted_region
    lda tune_end_lo
    cmp music_end_lo,x
    bne tune_failed
    lda tune_end_hi
    cmp music_end_hi,x
    bne tune_failed
    jsr select_music
    bcs tune_failed
    lda #1
    sta music_ready
    lda #0
    jsr cyber_music_init_address
region_music_done:
    rts
tune_failed:
    jsr show_disk_error
    jmp load_tune_retry

; Expanded rooms retain all four native map planes, one 256-byte page each.
load_room_retry:
    lda level
    clc
    adc #35
    sta room_name+4
    jsr disk_enter
    jsr cm_load_cached_room
    sta disk_status
    jsr disk_leave
    lda disk_status
    and #$bf
    bne room_failed
    jsr cm_last_end
    cmp #0
    bne room_failed
    cpx #$c4
    bne room_failed
    lda BANK+200
    cmp #67
    bne room_failed
    lda BANK+201
    cmp #89
    bne room_failed
    lda BANK+202
    cmp #66
    bne room_failed
    lda BANK+203
    cmp #2
    bne room_failed
    lda BANK+204
    cmp district
    bne room_failed
    lda BANK+205
    cmp level
    bne room_failed
    lda BANK+210
    cmp #5
    bcs room_failed
    ldx #0
validate_room_cells:
    lda BANK,x
    cmp #48
    bcs room_failed
    lda $c300,x
    cmp #28
    bcs room_failed
    inx
    cpx #200
    bne validate_room_cells
    lda district
    sta loaded_district
    jmp bank_loaded
room_failed:
    lda #255
    sta cm_cached_district
    jsr show_disk_error
    jmp load_room_retry

grid_art = $b500
grid_colors = $b600
grid_original = $b700
grid_video = $b800
; The original six-room mechanical pages stay byte-identical at $c000.
; Native presentation planes have their own replaceable district bank.
load_corporate_skin:
    lda district
    clc
    adc #49
    sta skin_name+4
    jsr disk_enter
    cm_load skin_name, 5, 8, $1000, $2000
    sta disk_status
    jsr disk_leave
    lda disk_status
    and #$bf
    bne skin_failed
    jsr cm_last_end
    cmp #0
    bne skin_failed
    cpx #$20
    bne skin_failed
    ldx #3
skin_header_check:
    lda $1e10,x
    cmp skin_signature,x
    bne skin_failed
    dex
    bpl skin_header_check
    lda $1e14
    cmp district
    bne skin_failed
    sta loaded_district
    jmp bank_loaded
skin_failed:
    jsr show_disk_error
    jmp load_corporate_skin
skin_name: .text "SKIN1"
skin_signature: .byte 67,89,65,1
skin_start_lo: .byte <$1000,<$1258,<$14b0,<$1708,<$1960,<$1bb8
skin_start_hi: .byte >$1000,>$1258,>$14b0,>$1708,>$1960,>$1bb8

prepare_room:
    lda #0
    sta plane_active
    sta registers_required
    sta registers_done
    sta rival_active
    sta finale_room
    sta motor_enabled
    sta core_wake_left
    lda #255
    sta mechanism_old_cell
    lda district
    cmp #5
    bcs prepare_descent
    jmp prepare_corporate
prepare_descent:
    lda #1
    sta plane_active
    lda BANK+210
    sta registers_required
    lda BANK+211
    sta rival_active
    lda BANK+212
    sta finale_room
    ldx #0
prepare_planes:
    lda BANK,x
    sta grid_art,x
    lda $c100,x
    and #15
    sta grid_colors,x
    lda finale_room
    beq prepare_color_done
    lda BANK,x
    cmp #28
    bcc prepare_color_done
    lda #8
    sta grid_colors,x
prepare_color_done:
    lda $c200,x
    sta grid_video,x
    lda $c300,x
    sta grid_original,x
    inx
    cpx #200
    bne prepare_planes
    jmp normalize_actor_floors
prepare_corporate:
    lda #1
    sta plane_active
    ldx local_level
    lda skin_start_lo,x
    sta PTR
    clc
    adc #200
    sta CPTR
    lda skin_start_hi,x
    sta PTR+1
    adc #0
    sta CPTR+1
    lda CPTR
    clc
    adc #200
    sta TEMP
    lda CPTR+1
    adc #0
    sta TEMP2
    ldy #0
prepare_corporate_planes:
    lda (PTR),y
    sta grid_art,y
    lda (CPTR),y
    and #15
    sta grid_colors,y
    lda (TEMP),y
    sta grid_video,y
    lda (SRC),y
    sta grid_original,y
    iny
    cpy #200
    bne prepare_corporate_planes
normalize_actor_floors:
    ldx #0
prepare_actor_cell:
    lda grid_original,x
    cmp #10
    beq prepare_actor_floor
    cmp #11
    beq prepare_actor_floor
    cmp #16
    beq prepare_actor_floor
    cmp #17
    bne prepare_plane_next
prepare_actor_floor:
    lda #0
    sta grid_original,x
    lda grid_art,x
    cmp #10
    beq prepare_clear_actor_art
    cmp #11
    beq prepare_clear_actor_art
    cmp #16
    beq prepare_clear_actor_art
    cmp #17
    bne prepare_plane_next
prepare_clear_actor_art:
    lda #0
    sta grid_art,x
prepare_plane_next:
    inx
    cpx #200
    bne prepare_actor_cell
prepare_room_done:
    rts

; Register latches combine Bit's phase with the two halves of the gravity bus.
; Failed matches leave state untouched; every latch and bonus is single-use.
update_mechanisms:
    lda registers_required
    bne mechanism_enabled
    rts
mechanism_enabled:
    ldx actor_cell
    lda grid,x
    cmp #18
    bcs mechanism_kind
    jmp mechanism_remember
mechanism_kind:
    cmp #22
    bcs mechanism_clutch
    sec
    sbc #18
    cmp registers_done
    bne mechanism_remember
    and #1
    cmp phase
    bne mechanism_remember
    lda registers_done
    lsr
    cmp gravity
    bne mechanism_remember
    lda finale_room
    beq latch_register
    lda #4
    sec
    sbc packets_left
    cmp registers_done
    beq mechanism_remember
    bcc mechanism_remember
latch_register:
    lda #25
    sta grid,x
    jsr draw_cell
    inc registers_done
    lda finale_room
    beq latch_not_core
    ldx registers_done
    lda core_wake_rows-1,x
    sta core_wake_cell
    lda #20
    sta core_wake_left
latch_not_core:
    lda #$50
    jsr score_add
    lda #3
    jsr cyber_music_init_address
    jsr unlock_descent_exit
    jsr draw_descent_help
    jmp mechanism_remember
mechanism_clutch:
    cmp #22
    beq clutch_contact
    cmp #26
    bne mechanism_remember
clutch_contact:
    cpx mechanism_old_cell
    beq mechanism_remember
    lda motor_enabled
    eor #1
    sta motor_enabled
    beq clutch_off
    lda #26
    bne clutch_draw
clutch_off:
    lda #22
clutch_draw:
    sta grid,x
    jsr draw_cell
mechanism_remember:
    lda actor_cell
    sta mechanism_old_cell
mechanism_done:
    rts
unlock_descent_exit:
    lda packets_left
    bne descent_exit_done
    lda registers_done
    cmp registers_required
    bne descent_exit_done
    ldx exit_cell
    lda #6
    sta grid,x
    jsr draw_cell
descent_exit_done:
    rts

; A packet on a live belt moves laterally. Gravity reverses the drive train.
; Carry clear returns A=target; carry set requests ordinary gravity instead.
conveyor_target:
    lda motor_enabled
    beq conveyor_none
    ldy actor_cell,x
    lda grid,y
    cmp #27
    beq conveyor_right
    cmp #23
    beq conveyor_left
    cmp #24
    bne conveyor_none
conveyor_right:
    lda #1
    bne conveyor_direction
conveyor_left:
    lda #255
conveyor_direction:
    ldy gravity
    beq conveyor_offset
    eor #$ff
    clc
    adc #1
conveyor_offset:
    clc
    adc actor_cell,x
    cmp #200
    bcs conveyor_none
    sta conveyor_cell
    tay
    lda cell_y,y
    ldy actor_cell,x
    cmp cell_y,y
    bne conveyor_none
    lda conveyor_cell
    clc
    rts
conveyor_none:
    sec
    rts
conveyor_cell: .byte 0

; Two cells per PAL frame: restored register rows wake progressively without
; paying for an entire decorative machine repaint on the latch frame.
update_core_lights:
    lda core_wake_left
    beq core_lights_done
    lda #2
    sta core_wake_budget
core_light_cell:
    ldx core_wake_cell
    lda grid_art,x
    cmp #28
    bcc core_light_next
    lda $c100,x
    sta grid_colors,x
    jsr draw_cell
core_light_next:
    inc core_wake_cell
    dec core_wake_left
    beq core_lights_done
    dec core_wake_budget
    bne core_light_cell
core_lights_done:
    rts
core_wake_rows: .byte 60,80,100,120
core_wake_cell: .byte 0
core_wake_left: .byte 0
core_wake_budget: .byte 0

; Eetu's preservation policy: pursue unpatched data and backfill empty floor.
; Soil is drillable and never closes hard topology or erases registers/packets.
update_rival:
    lda rival_active
    bne rival_enabled
    rts
rival_enabled:
    lda shield
    beq rival_unshielded
    rts
rival_unshielded:
    lda frame_counter
    and #31
    bne rival_done
    ldx #4
rival_find_packet:
    lda actor_active,x
    bne rival_has_job
    inx
    cpx #8
    bne rival_find_packet
    rts
rival_has_job:
    ldy actor_cell,x
    sty rival_target
    ldy actor_cell+3
    sty rival_old_cell
    jsr sentinel_column
    sta rival_column
    ldy rival_target
    jsr sentinel_column
    cmp rival_column
    beq rival_vertical
    ldx #1
    bcs rival_try_step
    ldx #3
    bne rival_try_step
rival_vertical:
    lda cell_y,y
    ldy rival_old_cell
    cmp cell_y,y
    beq rival_done
    ldx #2
    bcs rival_try_step
    ldx #0
rival_try_step:
    ldy rival_old_cell
    jsr sentinel_neighbor
    bcs rival_done
    sty rival_target
    ldx #0
rival_occupancy:
    lda actor_active,x
    beq rival_occupancy_next
    lda actor_cell,x
    cmp rival_target
    beq rival_done
rival_occupancy_next:
    inx
    cpx #8
    bne rival_occupancy
    lda rival_target
    sta actor_cell+3
    ldx rival_old_cell
    cpx spawn_cell
    beq rival_done
    lda grid,x
    bne rival_done
    lda #1
    sta grid,x
    jsr draw_cell
rival_done:
    rts

check_core_action:
    lda finale_room
    beq core_action_done
    lda actor_cell
    cmp exit_cell
    bne core_action_done
    lda packets_left
    bne core_action_done
    lda core_wake_left
    bne core_action_done
    lda registers_done
    cmp registers_required
    bne core_action_done
    lda joy
    and #16
    beq core_action_done
    lda #1
    sta level_done
    sta fire_used
core_action_done:
    rts

draw_descent_help:
    lda registers_required
    beq descent_help_done
    lda #<descent_help
    sta SRC
    lda #>descent_help
    sta SRC+1
    lda registers_done
    cmp registers_required
    bcc descent_help_draw
    lda #<hud_help
    sta SRC
    lda #>hud_help
    sta SRC+1
    lda finale_room
    beq descent_help_draw
    lda #<core_help
    sta SRC
    lda #>core_help
    sta SRC+1
descent_help_draw:
    ldx #39
    lda #32
descent_help_clear:
    sta SCREEN+960,x
    dex
    bpl descent_help_clear
    lda #<(SCREEN+960)
    sta PTR
    lda #>(SCREEN+960)
    sta PTR+1
    jsr write_text
    lda registers_done
    cmp registers_required
    bcs descent_help_done
    clc
    adc #49
    sta SCREEN+964
    lda registers_done
    and #1
    beq register_cyan
    ldx #3
register_amber:
    lda amber_word,x
    sta SCREEN+966,x
    dex
    bpl register_amber
register_cyan:
    lda registers_done
    cmp #2
    bcc descent_help_done
    ldx #3
register_up:
    lda up_word,x
    sta SCREEN+971,x
    dex
    bpl register_up
descent_help_done:
    rts

; Scene implementation below is cold; native room/score memory stays separate.
play_scene:
    sta scene_id
    clc
    adc #48
    sta scene_name+4
load_scene_retry:
    jsr disk_enter
    cm_load scene_name, 5, 8, $c600, $ce00
    sta disk_status
    jsr disk_leave
    lda disk_status
    and #$bf
    bne scene_failed
    jsr cm_last_end
    cmp #0
    bne scene_failed
    cpx #$ce
    bne scene_failed
    lda $cdd0
    cmp #67
    bne scene_failed
    lda $cdd1
    cmp #89
    bne scene_failed
    lda $cdd2
    cmp #83
    bne scene_failed
    lda $cdd3
    cmp #2
    bne scene_failed
    lda $cdd4
    cmp scene_id
    bne scene_failed
    jmp scene_loaded
scene_failed:
    jsr show_disk_error
    jmp load_scene_retry
scene_loaded:
    jsr clear_screen
    lda #3
    sta game_mode
    lda #0
    sta scene_tick
    sta scene_tick+1
    sta scene_fire_armed
    web64_rt_call_animation_play reaction_anim, 0, 2
    ldx #0
scene_copy:
    lda $c600,x
    sta SCREEN,x
    lda $c700,x
    sta SCREEN+$100,x
    lda $c800,x
    sta SCREEN+$200,x
    lda $c8e8,x
    sta SCREEN+$2e8,x
    lda $c9e8,x
    sta COLOR,x
    lda $cae8,x
    sta COLOR+$100,x
    lda $cbe8,x
    sta COLOR+$200,x
    lda $ccd0,x
    sta COLOR+$2e8,x
    inx
    bne scene_copy
    lda #1
    sta scene_visible
    sta $d015
    sta $d01d
    lda #0
    sta $d010
    sta $d017
    lda #166
    sta $d000
    lda #216
    sta $d001
    lda #3
    sta $d027
    lda scene_id
    cmp #4
    beq ending_scene_setup
    ; The caller now loads music and the room with this native scene active.
    rts
ending_scene_setup:
    lda #0
    sta $d418
    sta music_ready
    ldx #0
ending_dark:
    sta COLOR,x
    sta COLOR+$100,x
    sta COLOR+$200,x
    sta COLOR+$2e8,x
    inx
    bne ending_dark
    jmp scene_loop
finish_arrival_scene:
    lda scene_visible
    bne scene_loop
    rts
scene_loop:
    jsr cyber_wait_frame
    jsr tick_music
    jsr scene_present
    jmp scene_input
scene_present:
    web64_rt_call_animation_tick reaction_anim
    lda reaction_anim+6
    clc
    adc #$e0
    sta $07f8
    inc scene_tick
    bne scene_tick_ready
    inc scene_tick+1
scene_tick_ready:
    lda scene_tick+1
    bne scene_not_resolve
    lda scene_tick
    cmp #64
    bne scene_not_recoil
    web64_rt_call_animation_play reaction_anim, 1, 2
scene_not_recoil:
    lda scene_tick
    cmp #128
    bne scene_not_resolve
    web64_rt_call_animation_play reaction_anim, 2, 2
scene_not_resolve:
    jmp scene_lights
scene_input:
    jsr read_joystick
    lda joy
    and #16
    bne scene_fire
    lda #1
    sta scene_fire_armed
    bne scene_time_check
scene_fire:
    lda scene_fire_armed
    beq scene_time_check
    lda scene_id
    cmp #4
    bne scene_skip_check
    lda scene_tick+1
    cmp #2
    bcc scene_time_check
scene_skip_check:
    lda scene_tick+1
    bne scene_done
    lda scene_tick
    cmp #50
    bcs scene_done
scene_time_check:
    lda scene_id
    cmp #4
    beq ending_time_check
    lda scene_tick+1
    bne scene_done
    lda scene_tick
    cmp #200
    bcs scene_done
    jmp scene_loop
ending_time_check:
    lda scene_tick+1
    cmp #3
    bcs scene_done
    jmp scene_loop
scene_done:
    lda #0
    sta game_mode
    sta $d015
    sta $d01d
    sta ending_active
    sta scene_visible
    rts
scene_lights:
    lda scene_id
    cmp #4
    beq ending_lights
    lda scene_tick
    and #31
    tax
    ; Use a bounded palette index and one native machine column per frame.
    txa
    and #7
    tay
    lda pulse_colors,y
    sta COLOR+204,x
    sta COLOR+364,x
    sta COLOR+524,x
    rts
ending_lights:
    ; Power propagates down the native color plane, one character row every
    ; eight frames. The complete machine appears before Bit celebrates.
    lda scene_tick+1
    bne scene_celebrate
    lda scene_tick
    and #7
    bne scene_lights_done
    lda scene_tick
    lsr
    lsr
    lsr
    cmp #25
    bcs scene_lights_done
    tax
    lda ending_row_lo,x
    sta ending_color_read+1
    sta ending_color_write+1
    lda ending_row_hi,x
    sta ending_color_write+2
    ; The plane is not page aligned: self-modified absolute loads avoid ZP
    ; and keep the scene presenter safe inside the loader IRQ.
    txa
    pha
    lda ending_source_lo,x
    sta ending_color_read+1
    lda ending_source_hi,x
    sta ending_color_read+2
    ldx #39
ending_color_row:
ending_color_read:
    lda $c9e8,x
ending_color_write:
    sta $d800,x
    dex
    bpl ending_color_row
    pla
    cmp #16
    bne scene_lights_done
    lda #1
    sta music_ready
    lda #4
    jsr cyber_music_init_address
    rts
scene_celebrate:
    lda scene_tick+1
    cmp #1
    bne scene_lights_done
    web64_rt_call_animation_play reaction_anim, 3, 1
scene_lights_done:
    rts
cyber_ending:
    lda won_game
    beq ending_return
    lda #1
    sta ending_active
    lda #4
    jsr play_scene
ending_return:
    rts

tune_name: .text "TUNE1"
room_name: .text "ROOMA"
scene_name: .text "SCNE1"
tune_end_lo: .byte 0
tune_end_hi: .byte 0
current_music: .byte 0
plane_active: .byte 0
registers_required: .byte 0
registers_done: .byte 0
motor_enabled: .byte 0
mechanism_old_cell: .byte 255
rival_active: .byte 0
rival_old_cell: .byte 0
rival_target: .byte 0
rival_column: .byte 0
finale_room: .byte 0
scene_id: .byte 0
scene_tick: .word 0
scene_fire_armed: .byte 0
ending_active: .byte 0
scene_visible: .byte 0
