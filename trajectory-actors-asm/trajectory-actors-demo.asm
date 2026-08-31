.include "web64/trajectory.inc"
.include "assets/trajectories/actor-1-box-loop.inc"
.include "assets/trajectories/actor-2-diamond-loop.inc"
.include "assets/trajectories/actor-3-wide-loop.inc"
.include "assets/trajectories/actor-4-triangle-loop.inc"
.include "assets/trajectories/actor-5-kite-loop.inc"
.include "assets/trajectories/actor-6-hourglass-loop.inc"
.include "assets/trajectories/actor-7-vertical-loop.inc"
.include "assets/trajectories/actor-8-hex-loop.inc"
.include "assets/sprites/trajectory-actors.inc"

; Eight heterogeneous, independently editable trajectories deliberately use scalar
; stepping. The native application owns animation and VIC-II composition.
TRAJECTORY_ACTOR_COUNT = 8
TRAJECTORY_ACTOR_SPRITE_RAM = $3000
TRAJECTORY_ACTOR_SPRITE_POINTER = $c0
TRAJECTORY_ACTOR_POINTER_TABLE = $07f8
VIC_SPRITE_X_MSB = $d010
VIC_SPRITE_ENABLE = $d015
VIC_SPRITE_Y_EXPAND = $d017
VIC_SPRITE_PRIORITY = $d01b
VIC_SPRITE_MULTICOLOR = $d01c
VIC_SPRITE_X_EXPAND = $d01d
VIC_SPRITE_MULTICOLOR_1 = $d025
VIC_SPRITE_MULTICOLOR_2 = $d026
VIC_MEMORY = $d018
CIA2_PORT_A = $dd00
CIA2_DATA_DIRECTION_A = $dd02
VIC_BORDER = $d020
VIC_BACKGROUND = $d021
VIC_RASTER = $d012

asm_trajectory_actors_demo:
_asm_trajectory_actors_demo:
    sei
    lda #0
    sta trajectory_actor_error
    jsr trajectory_actor_clear_screen
    jsr trajectory_actor_install_sprites
    jsr trajectory_actor_init_states
    jsr trajectory_actor_write_animation_pointers
    jsr trajectory_actor_project_positions
    lda #0
    sta trajectory_actor_frame_counter
    sta trajectory_actor_frame_counter+1

trajectory_actor_frame_loop:
trajectory_actor_wait_raster:
    lda VIC_RASTER
    cmp #250
    bne trajectory_actor_wait_raster
trajectory_actor_wait_leave:
    lda VIC_RASTER
    cmp #250
    beq trajectory_actor_wait_leave

    lda #4
    sta VIC_BORDER
trajectory_actor_hot_start:
    ; Checked initialization validated each immutable pattern and complete state.
    ; Only this runtime mutates those states, so scalar fast stepping preserves
    ; the checked invariant without repeating validation on every PAL frame.
    web64_trajectory_call_step_fast (trajectory_actor_states+0)
    sta trajectory_actor_events+0
    web64_trajectory_call_step_fast (trajectory_actor_states+19)
    sta trajectory_actor_events+1
    web64_trajectory_call_step_fast (trajectory_actor_states+38)
    sta trajectory_actor_events+2
    web64_trajectory_call_step_fast (trajectory_actor_states+57)
    sta trajectory_actor_events+3
    web64_trajectory_call_step_fast (trajectory_actor_states+76)
    sta trajectory_actor_events+4
    web64_trajectory_call_step_fast (trajectory_actor_states+95)
    sta trajectory_actor_events+5
    web64_trajectory_call_step_fast (trajectory_actor_states+114)
    sta trajectory_actor_events+6
    web64_trajectory_call_step_fast (trajectory_actor_states+133)
    sta trajectory_actor_events+7
    jsr trajectory_actor_tick_animation
    jsr trajectory_actor_project_positions
    inc trajectory_actor_frame_counter
    bne trajectory_actor_frame_counted
    inc trajectory_actor_frame_counter+1
trajectory_actor_frame_counted:
trajectory_actor_hot_end:
    lda #0
    sta VIC_BORDER
    jmp trajectory_actor_frame_loop

trajectory_actor_init_states:
    web64_trajectory_call_init (trajectory_actor_states+0), actor_1_box_loop_pattern, $0300, $0480, actor_1_box_loop_default_options
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_actor_init_ok_0
    sta trajectory_actor_error
    jmp trajectory_actor_failed
trajectory_actor_init_ok_0:
    web64_trajectory_call_init (trajectory_actor_states+19), actor_2_diamond_loop_pattern, $0700, $04c0, actor_2_diamond_loop_default_options
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_actor_init_ok_1
    sta trajectory_actor_error
    jmp trajectory_actor_failed
trajectory_actor_init_ok_1:
    web64_trajectory_call_init (trajectory_actor_states+38), actor_3_wide_loop_pattern, $0a00, $0440, actor_3_wide_loop_default_options
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_actor_init_ok_2
    sta trajectory_actor_error
    jmp trajectory_actor_failed
trajectory_actor_init_ok_2:
    web64_trajectory_call_init (trajectory_actor_states+57), actor_4_triangle_loop_pattern, $0e80, $04e0, actor_4_triangle_loop_default_options
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_actor_init_ok_3
    sta trajectory_actor_error
    jmp trajectory_actor_failed
trajectory_actor_init_ok_3:
    web64_trajectory_call_init (trajectory_actor_states+76), actor_5_kite_loop_pattern, $0300, $09c0, actor_5_kite_loop_default_options
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_actor_init_ok_4
    sta trajectory_actor_error
    jmp trajectory_actor_failed
trajectory_actor_init_ok_4:
    web64_trajectory_call_init (trajectory_actor_states+95), actor_6_hourglass_loop_pattern, $0680, $0940, actor_6_hourglass_loop_default_options
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_actor_init_ok_5
    sta trajectory_actor_error
    jmp trajectory_actor_failed
trajectory_actor_init_ok_5:
    web64_trajectory_call_init (trajectory_actor_states+114), actor_7_vertical_loop_pattern, $0a80, $09c0, actor_7_vertical_loop_default_options
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_actor_init_ok_6
    sta trajectory_actor_error
    jmp trajectory_actor_failed
trajectory_actor_init_ok_6:
    web64_trajectory_call_init (trajectory_actor_states+133), actor_8_hex_loop_pattern, $0e00, $0940, actor_8_hex_loop_default_options
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_actor_init_ok_7
    sta trajectory_actor_error
    jmp trajectory_actor_failed
trajectory_actor_init_ok_7:
    rts

trajectory_actor_failed:
    lda #2
    sta VIC_BORDER
    sta VIC_BACKGROUND
trajectory_actor_failed_loop:
    jmp trajectory_actor_failed_loop

trajectory_actor_write_animation_pointers:
    ldx #0
trajectory_actor_write_animation_pointer_loop:
    ldy trajectory_actor_animation_step,x
    lda trajectory_actor_animation_frames,y
    clc
    adc #TRAJECTORY_ACTOR_SPRITE_POINTER
    sta TRAJECTORY_ACTOR_POINTER_TABLE,x
    inx
    cpx #TRAJECTORY_ACTOR_COUNT
    bne trajectory_actor_write_animation_pointer_loop
    rts

trajectory_actor_tick_animation:
    ldx #0
trajectory_actor_animation_loop:
    lda trajectory_actor_animation_step,x
    tay
    lda trajectory_actor_animation_tick,x
    clc
    adc #1
    cmp trajectory_actor_animation_durations,y
    bcc trajectory_actor_animation_keep_step
    lda #0
    sta trajectory_actor_animation_tick,x
    iny
    cpy #trajectory_actors_animation_orbit_pulse_count
    bcc trajectory_actor_animation_step_ready
    ldy #0
trajectory_actor_animation_step_ready:
    tya
    sta trajectory_actor_animation_step,x
    jmp trajectory_actor_animation_write_pointer
trajectory_actor_animation_keep_step:
    sta trajectory_actor_animation_tick,x
trajectory_actor_animation_write_pointer:
    lda trajectory_actor_animation_frames,y
    clc
    adc #TRAJECTORY_ACTOR_SPRITE_POINTER
    sta TRAJECTORY_ACTOR_POINTER_TABLE,x
    inx
    cpx #TRAJECTORY_ACTOR_COUNT
    bne trajectory_actor_animation_loop
    rts

trajectory_actor_project_positions:
    lda #0
    sta trajectory_actor_x_msb
    ; Actor 1: convert the complete public 16-bit Q12.4 position.
    lda trajectory_actor_states+0+WEB64_TRAJECTORY_STATE_X+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+0+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d000
    lda trajectory_actor_states+0+WEB64_TRAJECTORY_STATE_X+1
    and #$10
    beq trajectory_actor_x_low_0
    lda trajectory_actor_x_msb
    ora #$01
    sta trajectory_actor_x_msb
trajectory_actor_x_low_0:
    lda trajectory_actor_states+0+WEB64_TRAJECTORY_STATE_Y+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+0+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d001
    ; Actor 2: convert the complete public 16-bit Q12.4 position.
    lda trajectory_actor_states+19+WEB64_TRAJECTORY_STATE_X+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+19+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d002
    lda trajectory_actor_states+19+WEB64_TRAJECTORY_STATE_X+1
    and #$10
    beq trajectory_actor_x_low_1
    lda trajectory_actor_x_msb
    ora #$02
    sta trajectory_actor_x_msb
trajectory_actor_x_low_1:
    lda trajectory_actor_states+19+WEB64_TRAJECTORY_STATE_Y+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+19+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d003
    ; Actor 3: convert the complete public 16-bit Q12.4 position.
    lda trajectory_actor_states+38+WEB64_TRAJECTORY_STATE_X+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+38+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d004
    lda trajectory_actor_states+38+WEB64_TRAJECTORY_STATE_X+1
    and #$10
    beq trajectory_actor_x_low_2
    lda trajectory_actor_x_msb
    ora #$04
    sta trajectory_actor_x_msb
trajectory_actor_x_low_2:
    lda trajectory_actor_states+38+WEB64_TRAJECTORY_STATE_Y+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+38+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d005
    ; Actor 4: convert the complete public 16-bit Q12.4 position.
    lda trajectory_actor_states+57+WEB64_TRAJECTORY_STATE_X+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+57+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d006
    lda trajectory_actor_states+57+WEB64_TRAJECTORY_STATE_X+1
    and #$10
    beq trajectory_actor_x_low_3
    lda trajectory_actor_x_msb
    ora #$08
    sta trajectory_actor_x_msb
trajectory_actor_x_low_3:
    lda trajectory_actor_states+57+WEB64_TRAJECTORY_STATE_Y+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+57+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d007
    ; Actor 5: convert the complete public 16-bit Q12.4 position.
    lda trajectory_actor_states+76+WEB64_TRAJECTORY_STATE_X+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+76+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d008
    lda trajectory_actor_states+76+WEB64_TRAJECTORY_STATE_X+1
    and #$10
    beq trajectory_actor_x_low_4
    lda trajectory_actor_x_msb
    ora #$10
    sta trajectory_actor_x_msb
trajectory_actor_x_low_4:
    lda trajectory_actor_states+76+WEB64_TRAJECTORY_STATE_Y+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+76+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d009
    ; Actor 6: convert the complete public 16-bit Q12.4 position.
    lda trajectory_actor_states+95+WEB64_TRAJECTORY_STATE_X+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+95+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d00a
    lda trajectory_actor_states+95+WEB64_TRAJECTORY_STATE_X+1
    and #$10
    beq trajectory_actor_x_low_5
    lda trajectory_actor_x_msb
    ora #$20
    sta trajectory_actor_x_msb
trajectory_actor_x_low_5:
    lda trajectory_actor_states+95+WEB64_TRAJECTORY_STATE_Y+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+95+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d00b
    ; Actor 7: convert the complete public 16-bit Q12.4 position.
    lda trajectory_actor_states+114+WEB64_TRAJECTORY_STATE_X+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+114+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d00c
    lda trajectory_actor_states+114+WEB64_TRAJECTORY_STATE_X+1
    and #$10
    beq trajectory_actor_x_low_6
    lda trajectory_actor_x_msb
    ora #$40
    sta trajectory_actor_x_msb
trajectory_actor_x_low_6:
    lda trajectory_actor_states+114+WEB64_TRAJECTORY_STATE_Y+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+114+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d00d
    ; Actor 8: convert the complete public 16-bit Q12.4 position.
    lda trajectory_actor_states+133+WEB64_TRAJECTORY_STATE_X+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+133+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d00e
    lda trajectory_actor_states+133+WEB64_TRAJECTORY_STATE_X+1
    and #$10
    beq trajectory_actor_x_low_7
    lda trajectory_actor_x_msb
    ora #$80
    sta trajectory_actor_x_msb
trajectory_actor_x_low_7:
    lda trajectory_actor_states+133+WEB64_TRAJECTORY_STATE_Y+1
    asl
    asl
    asl
    asl
    sta trajectory_actor_projection_temp
    lda trajectory_actor_states+133+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora trajectory_actor_projection_temp
    sta $d00f
    lda trajectory_actor_x_msb
    sta VIC_SPRITE_X_MSB
    rts

trajectory_actor_clear_screen:
    lda #0
    sta VIC_BORDER
    sta VIC_BACKGROUND
    tax
    lda #$20
trajectory_actor_clear_screen_loop:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne trajectory_actor_clear_screen_loop
    rts

trajectory_actor_install_sprites:
    ; $3000 with VIC pointers $c0-$c3 is in VIC bank 0. Screen $0400 owns
    ; its pointer table at $07f8. Select every part of that relationship
    ; explicitly rather than inheriting a KERNAL or loader default.
    lda CIA2_DATA_DIRECTION_A
    ora #$03
    sta CIA2_DATA_DIRECTION_A
    lda CIA2_PORT_A
    and #$fc
    ora #$03
    sta CIA2_PORT_A
    lda #$14
    sta VIC_MEMORY
    ldx #0
trajectory_actor_copy_sprite_loop:
    lda trajectory_actors_sprites,x
    sta TRAJECTORY_ACTOR_SPRITE_RAM,x
    inx
    bne trajectory_actor_copy_sprite_loop
    ldx #TRAJECTORY_ACTOR_COUNT-1
trajectory_actor_sprite_setup_loop:
    lda trajectory_actor_colors,x
    sta $d027,x
    dex
    bpl trajectory_actor_sprite_setup_loop
    lda #$ff
    sta VIC_SPRITE_ENABLE
    sta VIC_SPRITE_MULTICOLOR
    lda #0
    sta VIC_SPRITE_X_MSB
    sta VIC_SPRITE_Y_EXPAND
    sta VIC_SPRITE_PRIORITY
    sta VIC_SPRITE_X_EXPAND
    lda #trajectory_actors_multicolor_1
    sta VIC_SPRITE_MULTICOLOR_1
    lda #trajectory_actors_multicolor_2
    sta VIC_SPRITE_MULTICOLOR_2
    rts

trajectory_actor_colors:
    .byte $02, $03, $05, $07, $08, $0a, $0d, $0e
trajectory_actor_animation_frames:
    .byte trajectory_actors_animation_orbit_pulse_frame_0, trajectory_actors_animation_orbit_pulse_frame_1, trajectory_actors_animation_orbit_pulse_frame_2, trajectory_actors_animation_orbit_pulse_frame_3
trajectory_actor_animation_durations:
    .byte trajectory_actors_animation_orbit_pulse_duration_0, trajectory_actors_animation_orbit_pulse_duration_1, trajectory_actors_animation_orbit_pulse_duration_2, trajectory_actors_animation_orbit_pulse_duration_3
trajectory_actor_animation_step:
    .byte 0, 1, 2, 3, 0, 1, 2, 3
trajectory_actor_animation_tick:
    .fill TRAJECTORY_ACTOR_COUNT, 0

; Actor 1 Box Loop: source-only .w64traj -> raw triplets + descriptor.
    .incbin actor_1_box_loop_segments, "assets/trajectories/actor-1-box-loop.traj"
actor_1_box_loop_pattern:
    actor_1_box_loop_emit_pattern

; Actor 2 Diamond Loop: source-only .w64traj -> raw triplets + descriptor.
    .incbin actor_2_diamond_loop_segments, "assets/trajectories/actor-2-diamond-loop.traj"
actor_2_diamond_loop_pattern:
    actor_2_diamond_loop_emit_pattern

; Actor 3 Wide Loop: source-only .w64traj -> raw triplets + descriptor.
    .incbin actor_3_wide_loop_segments, "assets/trajectories/actor-3-wide-loop.traj"
actor_3_wide_loop_pattern:
    actor_3_wide_loop_emit_pattern

; Actor 4 Triangle Loop: source-only .w64traj -> raw triplets + descriptor.
    .incbin actor_4_triangle_loop_segments, "assets/trajectories/actor-4-triangle-loop.traj"
actor_4_triangle_loop_pattern:
    actor_4_triangle_loop_emit_pattern

; Actor 5 Kite Loop: source-only .w64traj -> raw triplets + descriptor.
    .incbin actor_5_kite_loop_segments, "assets/trajectories/actor-5-kite-loop.traj"
actor_5_kite_loop_pattern:
    actor_5_kite_loop_emit_pattern

; Actor 6 Hourglass Loop: source-only .w64traj -> raw triplets + descriptor.
    .incbin actor_6_hourglass_loop_segments, "assets/trajectories/actor-6-hourglass-loop.traj"
actor_6_hourglass_loop_pattern:
    actor_6_hourglass_loop_emit_pattern

; Actor 7 Vertical Loop: source-only .w64traj -> raw triplets + descriptor.
    .incbin actor_7_vertical_loop_segments, "assets/trajectories/actor-7-vertical-loop.traj"
actor_7_vertical_loop_pattern:
    actor_7_vertical_loop_emit_pattern

; Actor 8 Hex Loop: source-only .w64traj -> raw triplets + descriptor.
    .incbin actor_8_hex_loop_segments, "assets/trajectories/actor-8-hex-loop.traj"
actor_8_hex_loop_pattern:
    actor_8_hex_loop_emit_pattern

; The generated sprite bank is embedded once. The include above supplies its
; frame, duration, palette, and size constants without duplicating this payload.
    .incbin trajectory_actors_sprites, "assets/sprites/trajectory-actors.w64spr"

trajectory_actor_states:
    web64_trajectory_reserve_states TRAJECTORY_ACTOR_COUNT
trajectory_actor_events:
    web64_trajectory_reserve_events TRAJECTORY_ACTOR_COUNT
trajectory_actor_frame_counter:
    .word 0
trajectory_actor_error:
    .byte 0
trajectory_actor_x_msb:
    .byte 0
trajectory_actor_projection_temp:
    .byte 0
