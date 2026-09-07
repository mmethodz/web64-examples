; CYBER-MOLE / resident PAL engine. Web64 native assembler, no external toolchain.
; Single-cell changes only; no full-screen redraw in a game frame.
.include "web64/animation.inc"
.include "web64/disk.inc"
.include "assets/chars/title.inc"
.include "assets/sprites/bit.inc"
.include "assets/sprites/death.inc"
.include "assets/sprites/reactions.inc"
reactions_sprites = $3800
bit_sprites = sprite_data
death_sprites = death_sprite_data
_cyber_init = cyber_init
_cyber_title = cyber_title
_cyber_new_game = cyber_new_game
_cyber_load_level = cyber_load_level
_cyber_play_level = cyber_play_level
_cyber_scores = cyber_scores
_cyber_ending = cyber_ending

SCREEN = $0400
COLOR = $d800
CHARSET = $2000
SPRITES = $3000
BANK = $c000
SCORES = $cf00
game_chars = $2000
circuit_frames = $2800
tile_colors = $2c00
tile_data = $2c40
PTR = $e0
CPTR = $e2
SRC = $e4
TEMP = $e6
TEMP2 = $e7

cyber_init:
    sei
    cld
    jsr cm_install_fastloader
    lda #0
    sta $d020
    sta $d021
    sta $d015
    sta music_ready
    sta current_music
    sta frame_counter
    sta frame_counter+1
    sta high_loaded
    sta help_visible
    sta death_timer
    lda #255
    sta loaded_district
    sta loaded_region
    sta cm_cached_district
    lda #$35
    sta $01
    jsr silence_irqs
    lda $dd00
    and #$fc
    ora #3
    sta $dd00
    lda #$1b
    sta $d011
    lda #$18
    sta $d016
    lda #$18
    sta $d018
    lda #11
    sta $d022
    sta $d025
    lda #14
    sta $d023
    lda #1
    sta $d026
    lda #0
    sta $d017
    sta $d01b
    sta $d01d
    lda #255
    sta $d01c
    jsr install_base_sprites
    web64_rt_call_animation_init bit_anim, animation_bank
    web64_rt_call_animation_init guard_anim, animation_bank
    web64_rt_call_animation_init packet_anim, animation_bank
    web64_rt_call_animation_init spark_anim, animation_bank
    web64_rt_call_animation_init death_anim, death_bank
    web64_rt_call_animation_init reaction_anim, reaction_bank
    web64_rt_call_animation_play bit_anim, 2, 2
    web64_rt_call_animation_play guard_anim, 3, 2
    web64_rt_call_animation_play packet_anim, 4, 2
    web64_rt_call_animation_play spark_anim, 5, 2
    rts

install_base_sprites:
    ldx #0
init_sprite_copy:
    lda sprite_data,x
    sta SPRITES,x
    lda sprite_data+$100,x
    sta SPRITES+$100,x
    lda sprite_data+$200,x
    sta SPRITES+$200,x
    lda sprite_data+$300,x
    sta SPRITES+$300,x
    lda sprite_data+$400,x
    sta SPRITES+$400,x
    lda sprite_data+$500,x
    sta SPRITES+$500,x
    lda death_sprite_data,x
    sta SPRITES+$600,x
    lda death_sprite_data+$100,x
    sta SPRITES+$700,x
    inx
    bne init_sprite_copy
    rts

silence_irqs:
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d
    lda #0
    sta $d01a
    lda #15
    sta $d019
    rts

; Application presentation/cache policy over the native Web64 loader ABI.
.include "loader.asm"
.include "room-cache.asm"

save_score_file:
    web64_rt_call_loader_shutdown
    lda #0
    sta cm_loader_ready
    lda #$36
    sta $01
    web64_rt_call_disk_save score_save_name, 9, 8, SCORES, $cf40
    sta cm_save_result
    web64_rt_call_loader_reinitialize_after_save
    cmp #0
    bne cm_save_detached
    lda #1
    sta cm_loader_ready
cm_save_detached:
    lda #$35
    sta $01
    lda cm_save_result
    rts
cm_save_result: .byte 0

; One update per actual PAL raster, including CIA/VIC contention in VICE.
cyber_wait_frame:
    bit $d011
    bmi cyber_wait_frame
    lda $d012
    cmp #248
    bne cyber_wait_frame
    inc frame_counter
    bne frame_wait_done
    inc frame_counter+1
frame_wait_done:
    rts

read_joystick:
    lda #$ff
    sta $dc02
    sta $dc00
    lda $dc00
    eor #$ff
    and #31
    sta joy
    rts

tick_animation:
    web64_rt_call_animation_tick bit_anim
    web64_rt_call_animation_tick guard_anim
    web64_rt_call_animation_tick packet_anim
    web64_rt_call_animation_tick spark_anim
    rts
tick_music:
    lda music_ready
    beq music_done
    jsr cyber_music_play_address
    lda game_mode
    cmp #1
    bne music_done
    lda seconds
    cmp #21
    bcs music_done
    lda frame_counter
    and #3
    bne music_done
    ; 5 SID ticks per 4 PAL frames: the intact soundtrack accelerates by 25%.
    jsr cyber_music_play_address
music_done:
    rts

install_game_charset:
    ; Installed by the native GLYP region target at the next cold load.
    rts
install_title_charset:
    lda #title_multicolor_1
    sta $d022
    sta $d025
    lda #title_multicolor_2
    sta $d023
    lda #<title_chars
    sta SRC
    lda #>title_chars
    sta SRC+1
copy_charset:
    lda #<CHARSET
    sta PTR
    lda #>CHARSET
    sta PTR+1
    ldx #8
    ldy #0
charset_page:
    lda (SRC),y
    sta (PTR),y
    iny
    bne charset_page
    inc SRC+1
    inc PTR+1
    dex
    bne charset_page
    rts

clear_screen:
    lda #0
    sta $d015
    ldx #0
clear_screen_loop:
    lda #32
    sta SCREEN,x
    sta SCREEN+$100,x
    sta SCREEN+$200,x
    sta SCREEN+$2e8,x
    lda #3
    sta COLOR,x
    sta COLOR+$100,x
    sta COLOR+$200,x
    sta COLOR+$2e8,x
    inx
    bne clear_screen_loop
    rts

; Text SRC, destination PTR. Screen codes, zero terminated. Cold screens only.
write_text:
    ldy #0
write_text_loop:
    lda (SRC),y
    beq write_text_done
    sta (PTR),y
    iny
    bne write_text_loop
write_text_done:
    rts

show_loading:
    jsr clear_screen
    lda #<loading_text
    sta SRC
    lda #>loading_text
    sta SRC+1
    lda #<(SCREEN+488)
    sta PTR
    lda #>(SCREEN+488)
    sta PTR+1
    jmp write_text

show_disk_error:
    lda #<retry_text
    sta SRC
    lda #>retry_text
    sta SRC+1
    lda #<(SCREEN+601)
    sta PTR
    lda #>(SCREEN+601)
    sta PTR+1
    jsr write_text
    jsr wait_release
wait_retry_fire:
    jsr cyber_wait_frame
    jsr loader_present
    jsr read_joystick
    lda joy
    and #16
    beq wait_retry_fire
    jmp wait_release
wait_release:
    jsr cyber_wait_frame
    jsr read_joystick
    lda joy
    and #16
    bne wait_release
    rts

wait_neutral:
    jsr instructions_frame
    jsr read_joystick
    lda joy
    bne wait_neutral
    rts

cyber_title:
    lda #0
    sta game_mode
    sta help_visible
    jsr install_base_sprites
    jsr install_title_charset
    jsr clear_screen
    lda current_music
    beq title_check_music
    lda #0
    sta music_ready
title_check_music:
    lda music_ready
    bne title_music_ready
load_music_retry:
    jsr show_loading
    jsr disk_enter
    cm_load music_name, 5, 8, $9000, $a600
    sta disk_status
    jsr disk_leave
    lda disk_status
    and #$bf
    bne music_load_failed
    ; A missing/truncated disk file must not execute stale RAM.
    jsr cm_last_end
    cpx #>cyber_music_payload_end
    bne music_load_failed
    cmp #<cyber_music_payload_end
    bne music_load_failed
    ldx #0
    jsr select_music
    bcs music_load_failed
    lda #1
    sta music_ready
    lda #0
    jsr cyber_music_init_address
    jmp title_music_ready
music_load_failed:
    jsr show_disk_error
    jmp load_music_retry
title_music_ready:
    lda high_loaded
    bne title_scores_loaded
    jsr load_scores
title_scores_loaded:
    ldx #0
title_copy:
    lda title_map,x
    sta SCREEN,x
    lda title_map+$100,x
    sta SCREEN+$100,x
    lda title_map+$200,x
    sta SCREEN+$200,x
    lda title_map+$2e8,x
    sta SCREEN+$2e8,x
    lda title_colors,x
    sta COLOR,x
    lda title_colors+$100,x
    sta COLOR+$100,x
    lda title_colors+$200,x
    sta COLOR+$200,x
    lda title_colors+$2e8,x
    sta COLOR+$2e8,x
    inx
    bne title_copy
    ; Hero-sized Bit and two animated packets below the dithered bitmap logo.
    lda #7
    sta $d015
    lda #1
    sta $d01d
    sta $d017
    lda #0
    sta $d010
    lda #160
    sta $d000
    lda #100
    sta $d002
    lda #244
    sta $d004
    lda #3
    sta $d027
    sta $d028
    lda #7
    sta $d029
    jsr wait_release
title_loop:
    jsr cyber_wait_frame
    jsr tick_animation
    jsr tick_music
    lda bit_anim+6
    clc
    adc #$c0
    sta $07f8
    lda packet_anim+6
    clc
    adc #$c0
    sta $07f9
    eor #1
    sta $07fa
    lda frame_counter
    lsr
    lsr
    and #7
    tax
    lda title_bob,x
    clc
    adc #147
    sta $d001
    lda title_bob+4,x
    clc
    adc #157
    sta $d003
    lda title_bob+2,x
    clc
    adc #157
    sta $d005
    ; Stepped metallic sheen and running rail lights, without redrawing logo.
    lda frame_counter
    and #3
    bne title_no_shine
    lda frame_counter
    lsr
    lsr
    and #31
    tax
    lda #11
    sta COLOR+83,x
    sta COLOR+963,x
    lda #3
    sta COLOR+84,x
    sta COLOR+964,x
    lda frame_counter
    lsr
    lsr
    lsr
    and #7
    tax
    lda title_prompt_colors,x
    ldx #12
title_prompt_glow:
    sta COLOR+893,x
    dex
    bpl title_prompt_glow
title_no_shine:
    jsr read_joystick
    lda joy
    and #16
    bne title_start_game
    lda joy
    and #1
    bne title_open_help
    jmp title_loop
title_open_help:
    jsr instructions_page
    jmp title_scores_loaded
title_start_game:
    jsr wait_release
    lda #0
    sta $d017
    sta $d01d
    sta $d015
    rts

; A native character map and its Color RAM plane; no disk load or music reset.
instructions_page:
    jsr clear_screen
    lda #1
    sta help_visible
    ldx #0
instructions_copy:
    lda instructions_map,x
    sta SCREEN,x
    lda instructions_map+$100,x
    sta SCREEN+$100,x
    lda instructions_map+$200,x
    sta SCREEN+$200,x
    lda instructions_map+$2e8,x
    sta SCREEN+$2e8,x
    lda instructions_colors,x
    sta COLOR,x
    lda instructions_colors+$100,x
    sta COLOR+$100,x
    lda instructions_colors+$200,x
    sta COLOR+$200,x
    lda instructions_colors+$2e8,x
    sta COLOR+$2e8,x
    inx
    bne instructions_copy
    lda #7
    sta $d015
    sta $d01d
    lda #0
    sta $d017
    jsr wait_neutral
instructions_loop:
    jsr instructions_frame
    jsr read_joystick
    lda joy
    and #16
    beq instructions_loop
    jsr wait_neutral
    lda #0
    sta help_visible
    rts
instructions_frame:
    jsr cyber_wait_frame
    jsr tick_animation
    jsr tick_music
    lda bit_anim+6
    clc
    adc #$c0
    sta $07f8
    lda packet_anim+6
    clc
    adc #$c0
    sta $07f9
    eor #1
    sta $07fa
    lda frame_counter
    lsr
    lsr
    and #7
    tax
    lda title_bob,x
    clc
    adc #211
    sta $d001
    lda title_bob+4,x
    clc
    adc #211
    sta $d003
    lda title_bob+2,x
    clc
    adc #211
    sta $d005
    rts

cyber_new_game:
    lda #1
    sta _run_active
    lda #5
    sta lives
    lda #0
    sta level
    sta local_level
    sta district
    sta score
    sta score+1
    sta score+2
    sta won_game
    sta death_timer
    lda #255
    sta loaded_district
    sta loaded_region
    jsr install_game_charset
    rts

cyber_load_level:
    lda #0
    sta game_mode
    jsr show_loading
    jsr load_region
    lda district
    cmp #5
    bcc load_legacy_bank
    jmp load_room_retry
load_legacy_bank:
    cmp loaded_district
    bne load_bank_retry
    jmp bank_loaded
load_bank_retry:
    lda district
    clc
    adc #49
    sta bank_name+4
    jsr disk_enter
    cm_load bank_name, 5, 8, BANK, $c600
    sta disk_status
    jsr disk_leave
    lda disk_status
    and #$bf
    bne bank_failed
    jsr cm_last_end
    cmp #0
    bne bank_failed
    cpx #$c6
    bne bank_failed
    lda BANK+200
    cmp #67
    bne bank_failed
    lda BANK+201
    cmp #89
    bne bank_failed
    lda BANK+202
    cmp #66
    bne bank_failed
    lda BANK+203
    cmp #1
    bne bank_failed
    lda BANK+204
    cmp district
    bne bank_failed
    jmp load_corporate_skin
bank_failed:
    jsr show_disk_error
    jmp load_bank_retry
bank_loaded:
    jsr finish_arrival_scene
    lda score
    sta entry_score
    lda score+1
    sta entry_score+1
    lda score+2
    sta entry_score+2
restart_level:
    jsr clear_screen
    ldx district
    lda district_light,x
    sta $d023
    lda district
    cmp #5
    bcc restart_legacy_palette
    ; Authored mechanisms begin on a deterministic clock, independent of the
    ; drive latency or the length of the preceding scene. Act One is unchanged.
    lda #0
    sta frame_counter
    sta frame_counter+1
    lda $2d05
    sta $d022
    sta $d025
    lda $2d06
    sta $d023
restart_legacy_palette:
    lda #0
    sta SRC
    lda local_level
    clc
    adc #$c0
    sta SRC+1
    lda district
    cmp #5
    bcc restart_page_ready
    lda #$c0
    sta SRC+1
restart_page_ready:
    ldy #206
    lda (SRC),y
    sta seconds
    iny
    lda (SRC),y
    sta enemy_period
    iny
    lda (SRC),y
    sta gravity
    iny
    lda (SRC),y
    sta phase
    jsr prepare_room
    ldx #0
copy_grid:
    txa
    tay
    lda (SRC),y
    ldy district
    cpy #5
    bcc copy_grid_legacy
    lda $c300,x
copy_grid_legacy:
    sta grid,x
    inx
    cpx #200
    bne copy_grid
    lda #0
    sta packets_left
    sta enemy_count
    sta move_timer
    sta seconds_tick
    sta retry_requested
    sta level_done
    sta spark_timer
    sta death_timer
    lda #1
    sta fire_latched
    sta fire_used
    lda #0
    ldx #7
clear_actors:
    sta actor_active,x
    sta actor_kind,x
    dex
    bpl clear_actors
    ldx #0
scan_grid:
    stx scan_cell
    lda grid,x
    cmp #16
    bne scan_not_player
    stx actor_cell
    stx spawn_cell
    lda #1
    sta actor_active
    lda #0
    sta grid,x
    jmp scan_next
scan_not_player:
    cmp #17
    bne scan_not_guard
    ldy enemy_count
    iny
    cpy #4
    bcs scan_next
    txa
    sta actor_cell,y
    lda #1
    sta actor_active,y
    sta actor_kind,y
    lda #0
    sta grid,x
    inc enemy_count
    jmp scan_next
scan_not_guard:
    cmp #10
    beq scan_packet
    cmp #11
    bne scan_not_packet
scan_packet:
    and #1
    sta TEMP
    lda packets_left
    clc
    adc #4
    tay
    cpy #8
    bcs scan_next
    txa
    sta actor_cell,y
    lda TEMP
    sta actor_phase,y
    lda #2
    sta actor_kind,y
    lda #1
    sta actor_active,y
    lda #0
    sta grid,x
    inc packets_left
    jmp scan_next
scan_not_packet:
    cmp #5
    bne scan_next
    stx exit_cell
scan_next:
    ldx scan_cell
    inx
    cpx #200
    beq scan_grid_done
    jmp scan_grid
scan_grid_done:
    jsr reset_guards
    ldx #0
position_actors:
    ldy actor_cell,x
    lda cell_x,y
    sta actor_x,x
    lda cell_x_hi,y
    sta actor_x_hi,x
    lda cell_y,y
    sta actor_y,x
    inx
    cpx #8
    bne position_actors
    ldx #0
draw_whole_grid:
    stx scan_cell
    jsr draw_cell
    ldx scan_cell
    inx
    cpx #200
    bne draw_whole_grid
    jsr draw_hud_labels
    jsr update_hud
    jsr draw_descent_help
    lda #125
    sta shield
    lda #1
    sta game_mode
    rts

cyber_play_level:
game_loop:
    jsr cyber_wait_frame
cyber_frame:
    lda death_timer
    beq game_alive_frame
    jsr death_frame
    jmp game_frame_end
game_alive_frame:
    jsr tick_animation
    jsr interpolate_actors
    jsr render_actors
    jsr animate_circuit
    jsr tick_music
    jsr read_joystick
    jsr handle_player
    lda level_done
    ora retry_requested
    bne game_frame_end
    lda game_mode
    cmp #1
    bne game_frame_end
    jsr update_mechanisms
    jsr update_core_lights
    jsr update_packets
    jsr update_guards
    jsr update_rival
    jsr check_contacts
    lda death_timer
    bne game_frame_end
    lda _run_active
    beq game_frame_end
    jsr update_clock
    jsr update_hud
game_frame_end:
    lda retry_requested
    beq game_no_retry
    jsr rollback_score
    jsr restart_level
game_no_retry:
    lda _run_active
    beq game_return
    lda level_done
    beq game_loop
    ; Reward remaining seconds exactly once, then hand bank sequencing to C.
    ldx seconds
award_time:
    lda #$10
    jsr score_add
    dex
    bne award_time
    inc level
    inc local_level
    lda local_level
    cmp #6
    bne game_check_win
    lda #0
    sta local_level
    inc district
game_check_win:
    lda level
    cmp #campaign_length
    bne game_return
    lda #1
    sta won_game
    lda #0
    sta _run_active
game_return:
    rts

handle_player:
    lda shield
    beq player_no_shield
    dec shield
player_no_shield:
    lda move_timer
    beq player_input
    dec move_timer
player_input:
    jsr check_core_action
    lda level_done
    bne player_done
    lda joy
    and #16
    beq fire_released
    lda #1
    sta fire_latched
    lda fire_used
    bne player_done
    lda joy
    and #1
    beq fire_not_up
    lda gravity
    eor #1
    sta gravity
    lda #1
    sta fire_used
    rts
fire_not_up:
    lda joy
    and #2
    beq player_done
    lda #1
    sta fire_used
    jmp retry_life
fire_released:
    lda fire_latched
    beq move_player
    lda fire_used
    bne fire_reset
    lda phase
    eor #1
    sta phase
fire_reset:
    lda #0
    sta fire_latched
    sta fire_used
move_player:
    lda move_timer
    bne player_done
    lda joy
    and #15
    bne player_has_move
    web64_rt_call_animation_play bit_anim, 2, 1
player_done:
    rts
player_has_move:
    ldx #0
    lsr
    bcs choose_direction
    inx
    lsr
    bcs choose_direction
    inx
    lsr
    bcs choose_direction
    inx
choose_direction:
    stx move_dir
    lda actor_cell
    clc
    adc direction_delta,x
    sta target_cell
    tax
    lda grid,x
    cmp #2
    beq player_done
    cmp #3
    beq player_done
    cmp #27
    bne player_drive_open
    lda motor_enabled
    beq player_done
    lda #27
player_drive_open:
    cmp #5
    beq move_exit
    cmp #6
    bne move_not_exit
move_exit:
    lda packets_left
    bne player_done
    lda registers_done
    cmp registers_required
    bcc player_done
    lda finale_room
    beq move_normal_exit
    lda target_cell
    sta actor_cell
    lda #8
    sta move_timer
    rts
move_normal_exit:
    lda #1
    sta level_done
    rts
move_not_exit:
    cmp #8
    beq move_gate
    cmp #9
    bne move_packet_check
move_gate:
    and #1
    cmp phase
    bne player_done
move_packet_check:
    ldx #4
player_packet_loop:
    lda actor_active,x
    beq player_packet_next
    lda actor_cell,x
    cmp target_cell
    bne player_packet_next
    lda actor_phase,x
    cmp phase
    beq player_patch_packet
    ; Wrong-color blocks may be pushed sideways onto an empty grid cell.
    lda move_dir
    cmp #2
    bcs push_horizontal
    rts
push_horizontal:
    tay
    lda target_cell
    clc
    adc direction_delta,y
    tay
    lda grid,y
    beq push_floor_open
    rts
push_floor_open:
    sty push_cell
    stx pushed_actor
    ldy #4
push_check_occupied:
    lda actor_active,y
    beq push_check_next
    lda actor_cell,y
    cmp push_cell
    bne push_check_next
    rts
push_check_next:
    iny
    cpy #8
    bne push_check_occupied
    ldx pushed_actor
    lda push_cell
    sta actor_cell,x
    jmp player_packet_next
player_patch_packet:
    jsr patch_packet
player_packet_next:
    inx
    cpx #8
    bne player_packet_loop
    lda target_cell
    sta actor_cell
    tax
    lda grid,x
    cmp #1
    bne player_not_digging
    lda #0
    sta grid,x
    jsr draw_cell
    lda #8
    sta drill_flash
player_not_digging:
    lda #8
    sta move_timer
    lda move_dir
    cmp #2
    beq face_left
    web64_rt_call_animation_play bit_anim, 0, 1
    rts
face_left:
    web64_rt_call_animation_play bit_anim, 1, 1
    rts

patch_packet:
    lda finale_room
    beq patch_packet_ready
    lda #4
    sec
    sbc packets_left
    cmp registers_done
    beq patch_packet_ready
    rts
patch_packet_ready:
    lda #0
    sta actor_active,x
    dec packets_left
    ; 100 points, decimal-safe saturation. X remains the packet slot.
    lda #0
    jsr score_add
    sed
    clc
    lda score+1
    adc #1
    sta score+1
    lda score+2
    adc #0
    sta score+2
    bcc patch_score_ok
    lda #$99
    sta score
    sta score+1
    sta score+2
patch_score_ok:
    cld
    stx spark_slot
    lda #12
    sta spark_timer
    ; Native non-looping SFX subtune borrows voice 3 and restores the music.
    txa
    pha
    lda #1
    jsr cyber_music_init_address
    pla
    tax
    lda packets_left
    bne patch_done
    lda registers_done
    cmp registers_required
    bne patch_done
    ldy exit_cell
    lda #6
    sta grid,y
    txa
    pha
    tya
    tax
    jsr draw_cell
    pla
    tax
patch_done:
    rts

; A is a packed BCD amount <=99, X/Y preserved. Saturation prevents rollover.
score_add:
    sed
    clc
    adc score
    sta score
    lda score+1
    adc #0
    sta score+1
    lda score+2
    adc #0
    sta score+2
    bcc score_no_carry
    lda #$99
    sta score
    sta score+1
    sta score+2
score_no_carry:
    cld
    rts

update_packets:
    lda frame_counter
    and #15
    bne packets_done
    ldx #4
packet_loop:
    stx packet_slot
    lda actor_active,x
    beq packet_next
    jsr conveyor_target
    bcc packet_target_ready
    ldy gravity
    lda actor_cell,x
    clc
    adc gravity_delta,y
packet_target_ready:
    sta packet_target
    cmp #200
    bcs packet_next
    tay
    lda grid,y
    cmp #27
    bne packet_not_drive_lock
    lda motor_enabled
    bne packet_target_open
    beq packet_next
packet_not_drive_lock:
    cmp #23
    beq packet_target_open
    cmp #24
    beq packet_target_open
    cmp #0
    bne packet_next
packet_target_open:
    ldy #4
packet_occupied:
    lda actor_active,y
    beq packet_occupied_next
    lda actor_cell,y
    cmp packet_target
    beq packet_next
packet_occupied_next:
    iny
    cpy #8
    bne packet_occupied
    lda packet_target
    sta actor_cell,x
packet_next:
    ldx packet_slot
    inx
    cpx #8
    bne packet_loop
packets_done:
    rts

.include "guards.asm"

check_contacts:
    lda death_timer
    bne contact_done
    ldx #4
contact_packets:
    lda actor_active,x
    beq contact_packet_next
    lda actor_cell,x
    cmp actor_cell
    bne contact_packet_next
    lda actor_phase,x
    cmp phase
    bne contact_hazard
    jsr patch_packet
contact_packet_next:
    inx
    cpx #8
    bne contact_packets
    ldx #1
contact_guards:
    lda actor_active,x
    beq contact_guard_next
    lda actor_cell,x
    cmp actor_cell
    beq contact_hazard
contact_guard_next:
    inx
    cpx #4
    bne contact_guards
    rts
contact_hazard:
    lda shield
    bne contact_done
    lda #0
    jmp begin_death
contact_done:
    rts
retry_life:
    lda #1
    jmp begin_death

; Nonblocking native shutdown. The last life gets the complete sequence too.
begin_death:
    ldx death_timer
    bne death_already_started
    ldx lives
    beq death_already_started
    ; A hit on the expiry tick is also a timeout: restart after this one
    ; shutdown, rather than immediately charging another life on respawn.
    cmp #0
    bne death_reason_ready
    ldx seconds
    cpx #1
    bne death_reason_ready
    ldx seconds_tick
    cpx #49
    bcc death_reason_ready
    lda #1
death_reason_ready:
    sta death_reason
    dec lives
    lda #death_duration
    sta death_timer
    lda #2
    sta game_mode
    lda #0
    sta move_timer
    sta spark_timer
    web64_rt_call_animation_play death_anim, 0, 2
    lda #2
    jsr cyber_music_init_address
    jsr update_hud
death_already_started:
    rts

death_frame:
    ; Freeze physical actors and timer, but retain circuit/sprite/music motion.
    jsr tick_animation
    jsr render_actors
    jsr animate_circuit
    jsr tick_music
    web64_rt_call_animation_tick death_anim
    dec death_timer
    bne death_frame_done
    lda lives
    beq end_game
    lda death_reason
    beq death_respawn
    lda #1
    sta retry_requested
    rts
death_respawn:
    lda spawn_cell
    sta actor_cell
    tay
    lda cell_x,y
    sta actor_x
    lda cell_x_hi,y
    sta actor_x_hi
    lda cell_y,y
    sta actor_y
    lda #125
    sta shield
    lda #0
    sta move_timer
    lda #1
    sta game_mode
    sta fire_latched
    sta fire_used
    web64_rt_call_animation_play bit_anim, 2, 2
    jsr recover_guards
    jsr update_hud
death_frame_done:
    rts
end_game:
    lda #0
    sta _run_active
    sta game_mode
    rts
rollback_score:
    lda entry_score
    sta score
    lda entry_score+1
    sta score+1
    lda entry_score+2
    sta score+2
    rts

update_clock:
    ; Leave the fresh spawn/recovery frame untimed.
    lda shield
    cmp #125
    beq clock_done
    inc seconds_tick
    lda seconds_tick
    cmp #50
    bcc clock_done
    lda #0
    sta seconds_tick
    dec seconds
    bne clock_done
    jmp retry_life
clock_done:
    rts

; Move sprites continuously, even though puzzle decisions occur on cell edges.
interpolate_actors:
    ldx #0
interpolate_loop:
    ldy actor_cell,x
    lda cell_x_hi,y
    cmp actor_x_hi,x
    bcc interpolate_left
    bne interpolate_right
    lda cell_x,y
    cmp actor_x,x
    bcc interpolate_left
    beq interpolate_y
interpolate_right:
    clc
    lda actor_x,x
    adc actor_speed,x
    sta actor_x,x
    lda actor_x_hi,x
    adc #0
    sta actor_x_hi,x
    jmp interpolate_y
interpolate_left:
    sec
    lda actor_x,x
    sbc actor_speed,x
    sta actor_x,x
    lda actor_x_hi,x
    sbc #0
    sta actor_x_hi,x
interpolate_y:
    lda cell_y,y
    cmp actor_y,x
    bcc interpolate_up
    beq interpolate_next
    clc
    lda actor_y,x
    adc actor_speed,x
    sta actor_y,x
    jmp interpolate_next
interpolate_up:
    sec
    lda actor_y,x
    sbc actor_speed,x
    sta actor_y,x
interpolate_next:
    inx
    cpx #8
    bne interpolate_loop
    rts

render_actors:
    lda #0
    sta sprite_mask
    sta sprite_high
    ldx #0
render_actor_loop:
    stx render_slot
    txa
    asl
    tay
    lda actor_x,x
    sta $d000,y
    lda actor_y,x
    sta $d001,y
    lda actor_x_hi,x
    beq render_low
    lda sprite_high
    ora sprite_bits,x
    sta sprite_high
render_low:
    lda actor_active,x
    beq render_inactive
    lda sprite_mask
    ora sprite_bits,x
    sta sprite_mask
render_inactive:
    cpx #0
    bne render_not_bit
    lda death_timer
    beq render_living_bit
    lda death_anim+6
    clc
    adc #24
    sta render_frame
    lda frame_counter
    and #3
    tay
    lda death_colors,y
    sta $d027
    jmp render_pointer
render_living_bit:
    lda bit_anim+6
    sta render_frame
    ldy phase
    lda phase_colors,y
    ldy shield
    beq render_bit_color
    ldy frame_counter
    tya
    and #4
    beq render_phase_color
    lda #1
    bne render_bit_color
render_phase_color:
    ldy phase
    lda phase_colors,y
render_bit_color:
    sta $d027
    jmp render_pointer
render_not_bit:
    cpx #4
    bcs render_packet
    cpx #3
    bne render_sentinel
    lda rival_active
    beq render_sentinel
    lda bit_anim+6
    and #3
    ora #4
    sta render_frame
    lda #7
    sta $d02a
    jmp render_pointer
render_sentinel:
    lda guard_anim+6
    sec
    sbc #12
    clc
    adc render_slot
    and #3
    clc
    adc #12
    sta render_frame
    lda frame_counter
    lsr
    lsr
    clc
    adc render_slot
    and #7
    tay
    lda guard_colors,y
    sta $d027,x
    jmp render_pointer
render_packet:
    lda packet_anim+6
    sec
    sbc #16
    clc
    adc render_slot
    and #3
    clc
    adc #16
    sta render_frame
    ldy actor_phase,x
    lda phase_colors,y
    sta $d027,x
    lda spark_timer
    beq render_pointer
    cpx spark_slot
    bne render_pointer
    lda sprite_mask
    ora sprite_bits,x
    sta sprite_mask
    lda spark_anim+6
    sta render_frame
    lda #1
    sta $d027,x
render_pointer:
    lda render_frame
    clc
    adc #$c0
    sta $07f8,x
    ldx render_slot
    inx
    cpx #8
    beq render_all_done
    jmp render_actor_loop
render_all_done:
    lda sprite_high
    sta $d010
    lda sprite_mask
    sta $d015
    lda spark_timer
    beq render_done
    dec spark_timer
render_done:
    rts

; 32-byte glyph delta per frame, cycling eight device families and four phases.
animate_circuit:
    lda frame_counter
    and #31
    sta TEMP
    and #7
    tax
    lda animated_tiles,x
    ldy plane_active
    beq circuit_tile_ready
    lda $2d07,x
circuit_tile_ready:
    sta TEMP2
    asl
    asl
    asl
    asl
    asl
    sta PTR
    lda TEMP2
    lsr
    lsr
    lsr
    clc
    adc #$22
    sta PTR+1
    lda TEMP
    lsr
    lsr
    lsr
    clc
    adc #>circuit_frames
    sta SRC+1
    lda TEMP
    asl
    asl
    asl
    asl
    asl
    clc
    adc #<circuit_frames
    sta SRC
    bcc animate_source_ready
    inc SRC+1
animate_source_ready:
    ldy #31
animate_copy:
    lda (SRC),y
    sta (PTR),y
    dey
    bpl animate_copy
    rts

; X = map cell. Four native characters and Color RAM bytes; X clobbered.
draw_cell:
    lda screen_lo,x
    sta PTR
    sta CPTR
    lda screen_hi,x
    sta PTR+1
    clc
    adc #$d4
    sta CPTR+1
    lda plane_active
    beq draw_semantic_tile
    lda grid,x
    cmp grid_original,x
    bne draw_semantic_tile
    lda grid_colors,x
    sta TEMP
    lda grid_art,x
    tax
    jmp draw_tile_chars
draw_semantic_tile:
    lda grid,x
    tax
    lda tile_colors,x
    sta TEMP
draw_tile_chars:
    txa
    asl
    asl
    tax
    ldy #0
    lda tile_data,x
    sta (PTR),y
    lda tile_data+1,x
    iny
    sta (PTR),y
    lda tile_data+2,x
    ldy #40
    sta (PTR),y
    lda tile_data+3,x
    iny
    sta (PTR),y
    lda TEMP
    sta (CPTR),y
    dey
    sta (CPTR),y
    ldy #1
    sta (CPTR),y
    dey
    sta (CPTR),y
    rts

draw_hud_labels:
    lda #<hud_text
    sta SRC
    lda #>hud_text
    sta SRC+1
    lda #<SCREEN
    sta PTR
    lda #>SCREEN
    sta PTR+1
    jsr write_text
    lda #<hud_info
    sta SRC
    lda #>hud_info
    sta SRC+1
    lda #<(SCREEN+80)
    sta PTR
    lda #>(SCREEN+80)
    sta PTR+1
    jsr write_text
    lda #<hud_help
    sta SRC
    lda #>hud_help
    sta SRC+1
    lda #<(SCREEN+960)
    sta PTR
    lda #>(SCREEN+960)
    sta PTR+1
    jsr write_text
    ldx #39
hud_rail:
    lda #45
    sta SCREEN+120,x
    lda #6
    sta COLOR+120,x
    lda #3
    sta COLOR+80,x
    dex
    bpl hud_rail
    ; Loaded page's screen-code name, centered in a fixed twenty-cell well.
    lda #0
    sta SRC
    lda local_level
    clc
    adc #$c0
    sta SRC+1
    lda district
    cmp #5
    bcc hud_page_ready
    lda #$c0
    sta SRC+1
hud_page_ready:
    ldy #216
    ldx #0
hud_name:
    lda (SRC),y
    sta SCREEN+50,x
    iny
    inx
    cpx #20
    bne hud_name
    rts

update_hud:
    ldy phase
    lda phase_colors,y
    sta COLOR+84
    sta COLOR+85
    sta COLOR+86
    sta COLOR+87
    lda #3
    ldy seconds
    cpy #21
    bcs hud_timer_color
    lda frame_counter
    and #8
    beq hud_timer_red
    lda #7
    bne hud_timer_color
hud_timer_red:
    lda #2
hud_timer_color:
    sta COLOR+117
    sta COLOR+118
    sta COLOR+119
    lda score+2
    ldx #19
    jsr hud_bcd
    lda score+1
    ldx #21
    jsr hud_bcd
    lda score
    ldx #23
    jsr hud_bcd
    lda level
    clc
    adc #1
    ldx #34
    jsr hud_decimal
    lda packets_left
    ora #48
    sta SCREEN+109
    lda lives
    ora #48
    sta SCREEN+79
    lda #12
    sta SCREEN+77
    lda #58
    sta SCREEN+78
    lda seconds
    ldx #49
    cmp #100
    bcc timer_under_100
    sbc #100
    bcs timer_hundred_ready
timer_under_100:
    ldx #48
timer_hundred_ready:
    stx SCREEN+117
    ldx #118
    jsr hud_decimal
    ldx #3
    lda phase
    beq phase_cyan_hud
phase_amber_hud:
    lda amber_word,x
    sta SCREEN+84,x
    dex
    bpl phase_amber_hud
    jmp gravity_hud
phase_cyan_hud:
    lda cyan_word,x
    sta SCREEN+84,x
    dex
    bpl phase_cyan_hud
gravity_hud:
    ldx #3
    lda gravity
    beq gravity_down_hud
gravity_up_hud:
    lda up_word,x
    sta SCREEN+98,x
    dex
    bpl gravity_up_hud
    rts
gravity_down_hud:
    lda down_word,x
    sta SCREEN+98,x
    dex
    bpl gravity_down_hud
    rts
hud_bcd:
    pha
    lsr
    lsr
    lsr
    lsr
    ora #48
    sta SCREEN,x
    pla
    and #15
    ora #48
    sta SCREEN+1,x
    rts
hud_decimal:
    ldy #48
decimal_tens:
    cmp #10
    bcc decimal_ones
    sec
    sbc #10
    iny
    bne decimal_tens
decimal_ones:
    ora #48
    sta SCREEN+1,x
    tya
    sta SCREEN,x
    rts

; High-score cold flow is implemented below, outside the active-frame budget.
.include "scores.asm"
.include "descent.asm"
.include "music.inc"
.include "generated.inc"

_run_active: .byte 0
frame_counter: .word 0
game_mode: .byte 0
music_ready: .byte 0
disk_status: .byte 0
high_loaded: .byte 0
help_visible: .byte 0
death_timer: .byte 0
death_reason: .byte 0
level: .byte 0
local_level: .byte 0
district: .byte 0
loaded_district: .byte 255
loaded_region: .byte 255
lives: .byte 5
won_game: .byte 0
score: .byte 0,0,0
entry_score: .byte 0,0,0
seconds: .byte 100
seconds_tick: .byte 0
enemy_period: .byte 18
guard_clock: .byte 0
gravity: .byte 0
phase: .byte 0
packets_left: .byte 4
enemy_count: .byte 3
shield: .byte 125
move_timer: .byte 0
move_dir: .byte 0
target_cell: .byte 0
push_cell: .byte 0
pushed_actor: .byte 0
fire_latched: .byte 0
fire_used: .byte 0
joy: .byte 0
scan_cell: .byte 0
spawn_cell: .byte 21
exit_cell: .byte 38
retry_requested: .byte 0
level_done: .byte 0
packet_slot: .byte 0
packet_target: .byte 0
guard_slot: .byte 0
render_slot: .byte 0
render_frame: .byte 0
sprite_mask: .byte 0
sprite_high: .byte 0
spark_slot: .byte 0
spark_timer: .byte 0
drill_flash: .byte 0
actor_cell: .fill 8,0
actor_x: .fill 8,0
actor_x_hi: .fill 8,0
actor_y: .fill 8,0
actor_active: .fill 8,0
actor_kind: .fill 8,0
actor_phase: .fill 8,0
actor_speed: .byte 2,1,1,1,1,1,1,1
direction_delta: .byte 236,20,255,1
gravity_delta: .byte 20,236
sprite_bits: .byte 1,2,4,8,16,32,64,128
phase_colors: .byte 3,7
pulse_colors: .byte 3,3,6,1,7,1,6,3
death_colors: .byte 1,7,3,6
guard_colors: .byte 2,2,10,10,7,10,10,2
district_light: .byte 14,12,4,6,10,6,7,6
animated_tiles: .byte 0,3,6,7,8,9,12,13
title_bob: .byte 0,1,2,3,3,2,1,0,0,1,2,3,3,2,1,0
title_prompt_colors: .byte 1,1,3,3,3,3,1,1
cyan_word: .byte 3,25,1,14
amber_word: .byte 1,13,2,18
up_word: .byte 21,16,32,32
down_word: .byte 4,15,23,14
music_name: .text "PULSE"
bank_name: .text "GRID1"
visual_name: .text "GLYP0"
score_name: .text "SCORES"
score_save_name: .text "@0:SCORES"
bit_anim: .fill 11,0
guard_anim: .fill 11,0
packet_anim: .fill 11,0
spark_anim: .fill 11,0
death_anim: .fill 11,0
reaction_anim: .fill 11,0
grid: .fill 200,0
.incbin title_chars, "assets/chars/title.w64chr"
.incbin sprite_data, "assets/sprites/bit.w64spr"
.incbin death_sprite_data, "assets/sprites/death.w64spr"
.incbin title_map, "assets/maps/title.w64map"
.incbin title_colors, "assets/maps/title.color.bin"
.incbin instructions_map, "assets/maps/instructions.w64map"
.incbin instructions_colors, "assets/maps/instructions.color.bin"
.incbin default_scores, "assets/data/scores.prg", 2, 64

; Boot-only images are copied before SID loading may reclaim their addresses.
cm_permanent_end:
cm_install_fastloader:
    lda #$35
    sta $01
    cm_boot_copy web64_loader_transport_image, WEB64_LOADER_TRANSPORT_ADDRESS, web64_loader_transport_image_size
    cm_boot_copy web64_loader_state_image, WEB64_LOADER_STATE_ADDRESS, web64_loader_state_image_size
    cm_boot_copy web64_loader_packed_image, WEB64_LOADER_PACKED_ADDRESS, web64_loader_packed_image_size
    cm_boot_copy web64_loader_decoder_image, WEB64_LOADER_DECODER_ADDRESS, web64_loader_decoder_image_size
    cm_boot_copy web64_loader_raw_image, WEB64_LOADER_RAW_ADDRESS, web64_loader_raw_image_size
    web64_rt_call_loader_init 8, $bf00, loader_ticks
    cmp #0
    bne cm_boot_done
    lda #1
    sta cm_loader_ready
cm_boot_done:
    rts

.macro cm_boot_copy image, destination, length
    lda #<image
    sta SRC
    lda #>image
    sta SRC+1
    lda #<destination
    sta PTR
    lda #>destination
    sta PTR+1
    lda #<length
    sta cm_length
    lda #>length
    sta cm_length+1
    jsr cm_copy_received
.endmacro
WEB64_LOADER_TRANSPORT_ADDRESS = $0800
WEB64_LOADER_STATE_ADDRESS = $0f00
WEB64_LOADER_PACKED_ADDRESS = $a600
WEB64_LOADER_DECODER_ADDRESS = $3c00
WEB64_LOADER_RAW_ADDRESS = $fe00
.include "web64/loader-transport-runtime.inc"
.include "web64/loader-state-runtime.inc"
.include "web64/loader-packed-runtime.inc"
.include "web64/loader-decoder-runtime.inc"
.include "web64/loader-raw-runtime.inc"
