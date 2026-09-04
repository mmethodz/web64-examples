; ASCENDER native half.
; C owns gameplay. This file owns deterministic VIC-II setup, the hot character
; renderer, joystick polling, sprite installation, and tiny SID effects.

.include "web64/sprite-runtime.inc"
.include "web64/animation.inc"
.include "assets/sprites/ascender.inc"
.include "assets/chars/ascender-platforms.inc"

SCREEN = $0400
COLOR = $d800
JOY2 = $dc00
RASTER = $d012
SPRITE_ENABLE = $d015
SPRITE_MULTICOLOR = $d01c
SPRITE_MC0 = $d025
SPRITE_MC1 = $d026
SID = $d400
ASCENDER_SPRITE_RAM = $3000
ASCENDER_SPRITE_POINTER = $c0
ASCENDER_CHARSET_RAM = $2000
; These are Ascender's map contract, not generated charset metadata. Keep them
; here so editing, replacing, or regenerating the native charset include cannot
; remove symbols required by the renderer.
ASCENDER_PLATFORM_NORMAL_BASE = $80
ASCENDER_PLATFORM_CRUMBLE_BASE = $98
ASCENDER_PLATFORM_SPRING_BASE = $b0
WEB64_ANIMATION_PLAYER_FRAME = 6

asm_init_video:
    sei
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d
    lda $dd00
    and #$fc
    ora #$03
    sta $dd00
    lda #$1b
    sta $d011
    lda #$08
    sta $d016
    lda #$18
    sta $d018
    lda #$00
    sta asm_visible_screen
    lda #$06
    sta $d020
    lda #$00
    sta $d021
    lda #$00
    sta SPRITE_ENABLE
    lda #$05
    sta SPRITE_MC0
    lda #$0e
    sta SPRITE_MC1
    ldx #$00
asm_copy_sprites:
    lda ascender_sprites,x
    sta ASCENDER_SPRITE_RAM,x
    lda ascender_sprites+$100,x
    sta ASCENDER_SPRITE_RAM+$100,x
    lda ascender_sprites+$200,x
    sta ASCENDER_SPRITE_RAM+$200,x
    inx
    bne asm_copy_sprites
    ldx #$00
asm_copy_charset:
    lda ascender_platforms_chars+$000,x
    sta ASCENDER_CHARSET_RAM+$000,x
    lda ascender_platforms_chars+$100,x
    sta ASCENDER_CHARSET_RAM+$100,x
    lda ascender_platforms_chars+$200,x
    sta ASCENDER_CHARSET_RAM+$200,x
    lda ascender_platforms_chars+$300,x
    sta ASCENDER_CHARSET_RAM+$300,x
    lda ascender_platforms_chars+$400,x
    sta ASCENDER_CHARSET_RAM+$400,x
    lda ascender_platforms_chars+$500,x
    sta ASCENDER_CHARSET_RAM+$500,x
    lda ascender_platforms_chars+$600,x
    sta ASCENDER_CHARSET_RAM+$600,x
    lda ascender_platforms_chars+$700,x
    sta ASCENDER_CHARSET_RAM+$700,x
    inx
    bne asm_copy_charset
    ldx #$18
    lda #$00
asm_clear_sid:
    sta SID,x
    dex
    bpl asm_clear_sid
    lda #$0f
    sta SID+$18
    lda #$09
    sta SID+$05
    lda #$88
    sta SID+$06
    lda #$00
    sta asm_sound_timer
    ; The generated helper supplies the exact C ABI argument window. Keeping
    ; this initialization here demonstrates assembly-side runtime access while
    ; the hot per-frame VIC projection below remains inside the PAL budget.
    web64_rt_call_sprite_renderer_init _sprite_renderer, $07f8
    rts

asm_start_animation:
    web64_rt_call_animation_init _runner_animation, _runner_animation_bank
    web64_rt_call_animation_play _runner_animation, 1, 2
    web64_rt_call_animation_init _spark_animation, _spark_animation_bank
    web64_rt_call_animation_play _spark_animation, 0, 2
    web64_rt_call_animation_init _hazard_animation, _hazard_animation_bank
    web64_rt_call_animation_play _hazard_animation, 0, 2
    rts

; Convert the small HUD state without the generic C division helpers. Each
; decimal position subtracts a fixed power of ten at most nine times.
asm_update_hud:
    lda _score
    sta $f0
    lda _score+1
    sta $f1
    lda #<_hud_score_digits
    sta $f2
    lda #>_hud_score_digits
    sta $f3
    jsr asm_write_five_digits

    lda _high_score
    sta $f0
    lda _high_score+1
    sta $f1
    lda #<_hud_high_digits
    sta $f2
    lda #>_hud_high_digits
    sta $f3
    jsr asm_write_five_digits

    lda _level
    ldx #$30
asm_level_tens_loop:
    cmp #10
    bcc asm_level_digits_ready
    sec
    sbc #10
    inx
    bne asm_level_tens_loop
asm_level_digits_ready:
    stx _hud_level_digits
    clc
    adc #$30
    sta _hud_level_digits+1
    clc
    lda _lives
    adc #$30
    sta _hud_lives_digit
    ldx #$00
asm_update_score_cells:
    lda _hud_score_digits,x
    sta SCREEN+$008,x
    sta SCREEN+$408,x
    lda #$01
    sta COLOR+$008,x
    inx
    cpx #$05
    bne asm_update_score_cells
    ldx #$00
asm_update_high_cells:
    lda _hud_high_digits,x
    sta SCREEN+$011,x
    sta SCREEN+$411,x
    lda #$07
    sta COLOR+$011,x
    inx
    cpx #$05
    bne asm_update_high_cells
    lda _hud_level_digits
    sta SCREEN+$020
    sta SCREEN+$420
    lda _hud_level_digits+1
    sta SCREEN+$021
    sta SCREEN+$421
    lda _hud_lives_digit
    sta SCREEN+$026
    sta SCREEN+$426
    lda #$01
    sta COLOR+$020
    sta COLOR+$021
    sta COLOR+$026
    rts

asm_write_five_digits:
    ldy #$00
    lda #<$2710
    sta $f4
    lda #>$2710
    sta $f5
    jsr asm_write_decimal_digit
    iny
    lda #<$03e8
    sta $f4
    lda #>$03e8
    sta $f5
    jsr asm_write_decimal_digit
    iny
    lda #<$0064
    sta $f4
    lda #>$0064
    sta $f5
    jsr asm_write_decimal_digit
    iny
    lda #<$000a
    sta $f4
    lda #>$000a
    sta $f5
    jsr asm_write_decimal_digit
    iny
    clc
    lda $f0
    adc #$30
    sta ($f2),y
    rts

asm_write_decimal_digit:
    lda #$30
    sta $f6
asm_decimal_subtract_loop:
    lda $f1
    cmp $f5
    bcc asm_decimal_digit_ready
    bne asm_decimal_subtract
    lda $f0
    cmp $f4
    bcc asm_decimal_digit_ready
asm_decimal_subtract:
    sec
    lda $f0
    sbc $f4
    sta $f0
    lda $f1
    sbc $f5
    sta $f1
    inc $f6
    jmp asm_decimal_subtract_loop
asm_decimal_digit_ready:
    lda $f6
    sta ($f2),y
    rts

; Scroll and procedural recycling are the other hot path. All state remains in
; C globals; assembly only performs the bounded byte-wise mutation efficiently.
asm_scroll_world:
    clc
    lda _climbed
    adc _scroll_amount
    sta _climbed
    lda _climbed+1
    adc #$00
    sta _climbed+1
    clc
    lda _score
    adc _scroll_amount
    sta _score
    lda _score+1
    adc #$00
    sta _score+1

    lda _climbed+1
    cmp _next_level_climb+1
    bcc asm_scroll_level_done
    bne asm_scroll_level_reached
    lda _climbed
    cmp _next_level_climb
    bcc asm_scroll_level_done
asm_scroll_level_reached:
    lda _level
    cmp #99
    bcs asm_scroll_level_done
    inc _level
    clc
    lda _next_level_climb
    adc #$a0
    sta _next_level_climb
    lda _next_level_climb+1
    adc #$00
    sta _next_level_climb+1
asm_scroll_level_done:

    ldx #$00
asm_scroll_platform_loop:
    lda _platform_width,x
    beq asm_recycle_platform
    clc
    lda _platform_y,x
    adc _scroll_amount
    cmp #160
    bcs asm_recycle_platform
    sta _platform_y,x
    jmp asm_scroll_platform_next
asm_recycle_platform:
    ; This slot now represents a new platform instance, so its landing bonus is
    ; available again. Existing platforms keep their score latch across deaths.
    lda #$00
    sta _platform_scored,x
    jsr asm_random_byte
    and #$03
    asl
    asl
    asl
    clc
    adc #48
    sta _platform_width,x
    jsr asm_random_byte
    and #$f8
    cmp #241
    bcc asm_recycle_x_ready
    lda #240
asm_recycle_x_ready:
    sta _platform_x,x
    jsr asm_random_byte
    and #$07
    sta _platform_y,x
    jsr asm_random_byte
    and #$07
    beq asm_recycle_spring
    cmp #$03
    bcc asm_recycle_crumble
    lda #$00
    beq asm_recycle_kind_ready
asm_recycle_crumble:
    lda #$01
    bne asm_recycle_kind_ready
asm_recycle_spring:
    lda #$02
asm_recycle_kind_ready:
    sta _platform_kind,x
asm_scroll_platform_next:
    inx
    cpx #$0a
    bne asm_scroll_platform_loop

    clc
    lda _spark_y
    adc _scroll_amount
    cmp #160
    bcs asm_recycle_spark
    sta _spark_y
    jmp asm_scroll_enemy
asm_recycle_spark:
    jsr asm_random_byte
    and #$f8
    sta _spark_x
    lda #$08
    sta _spark_y
    lda #$01
    sta _spark_active

asm_scroll_enemy:
    clc
    lda _enemy_y
    adc _scroll_amount
    cmp #160
    bcs asm_recycle_enemy
    sta _enemy_y
    rts
asm_recycle_enemy:
    jsr asm_random_byte
    and #$f0
    sta _enemy_x
    lda #$00
    sta _enemy_x+1
    lda #18
    sta _enemy_y
    rts

asm_random_byte:
    lda _random_state
    and #$01
    sta $f7
    lsr _random_state+1
    ror _random_state
    lda $f7
    beq asm_random_ready
    lda _random_state+1
    eor #$b4
    sta _random_state+1
asm_random_ready:
    lda _random_state
    rts

asm_read_joystick:
    lda JOY2
    ldx #$00
    rts

asm_wait_frame:
asm_wait_leave:
    lda RASTER
    cmp #$f8
    beq asm_wait_leave
asm_wait_enter:
    lda RASTER
    cmp #$f8
    bne asm_wait_enter
    rts

asm_audio_tick:
    lda asm_sound_timer
    beq asm_audio_done
    dec asm_sound_timer
    bne asm_audio_done
    lda #$10
    sta SID+$04
asm_audio_done:
    rts

asm_sfx_bounce:
    lda #$44
    sta SID+$00
    lda #$18
    sta SID+$01
    lda #$11
    sta SID+$04
    lda #$05
    sta asm_sound_timer
    rts

asm_sfx_collect:
    lda #$a8
    sta SID+$00
    lda #$32
    sta SID+$01
    lda #$41
    sta SID+$04
    lda #$09
    sta asm_sound_timer
    rts

asm_sfx_crash:
    lda #$20
    sta SID+$00
    lda #$08
    sta SID+$01
    lda #$81
    sta SID+$04
    lda #$12
    sta asm_sound_timer
    rts

asm_hide_sprites:
    lda #$00
    sta SPRITE_ENABLE
    rts

asm_clear_screen:
    ldx #$00
    lda #$20
asm_clear_screen_loop:
    sta SCREEN+$000,x
    sta SCREEN+$100,x
    sta SCREEN+$200,x
    sta SCREEN+$400,x
    sta SCREEN+$500,x
    sta SCREEN+$600,x
    inx
    bne asm_clear_screen_loop
    ldx #$00
asm_clear_screen_tail:
    sta SCREEN+$300,x
    sta SCREEN+$700,x
    inx
    cpx #$e8
    bne asm_clear_screen_tail
    rts

; Rows 0-4 are a fixed HUD/logo band. The game loop clears only the remaining
; 20 rows (800 cells), making the reduced scrolling viewport earn its keep.
asm_prepare_game_screen:
    lda $d011
    and #$ef
    sta $d011
    jsr asm_clear_screen
    lda #$18
    sta $d018
    lda #$00
    sta asm_visible_screen
    lda #$00
    sta $d020
    lda #$06
    sta $d021
    ; Color RAM is shared by both character pages, so keep the scrolling arena
    ; on a stable cyan plane. Platform kinds remain distinct by character shape.
    ldx #$00
    lda #$03
asm_prepare_playfield_colors:
    sta COLOR+$0c8,x
    sta COLOR+$1c8,x
    sta COLOR+$2c8,x
    inx
    bne asm_prepare_playfield_colors
    ldx #$00
asm_prepare_playfield_color_tail:
    sta COLOR+$3c8,x
    inx
    cpx #$20
    bne asm_prepare_playfield_color_tail
    lda #$0a
    sta SCREEN+$000
    sta SCREEN+$027
    lda #$06
    sta COLOR+$000
    sta COLOR+$027
    ldx #$01
asm_header_line:
    lda #$63
    sta SCREEN,x
    lda #$0e
    sta COLOR,x
    inx
    cpx #$27
    bne asm_header_line

    ldx #$00
asm_score_label_loop:
    lda asm_score_label,x
    beq asm_high_label_begin
    sta SCREEN+$002,x
    lda #$03
    sta COLOR+$002,x
    inx
    bne asm_score_label_loop
asm_high_label_begin:
    ldx #$00
asm_high_label_loop:
    lda asm_high_label,x
    beq asm_level_label_begin
    sta SCREEN+$00e,x
    lda #$07
    sta COLOR+$00e,x
    inx
    bne asm_high_label_loop
asm_level_label_begin:
    ldx #$00
asm_level_label_loop:
    lda asm_level_label,x
    beq asm_lives_label_begin
    sta SCREEN+$01a,x
    lda #$05
    sta COLOR+$01a,x
    inx
    bne asm_level_label_loop
asm_lives_label_begin:
    ldx #$00
asm_lives_label_loop:
    lda asm_lives_label,x
    beq asm_logo_rules
    sta SCREEN+$023,x
    lda #$0a
    sta COLOR+$023,x
    inx
    bne asm_lives_label_loop

asm_logo_rules:
    ldx #$00
asm_logo_rule_loop:
    lda #$66
    sta SCREEN+$028,x
    sta SCREEN+$0a0,x
    lda #$0e
    sta COLOR+$028,x
    sta COLOR+$0a0,x
    inx
    cpx #$28
    bne asm_logo_rule_loop
    ldx #$00
asm_logo_name_loop:
    lda asm_logo_name,x
    beq asm_logo_runtime_begin
    sta SCREEN+$060,x
    lda asm_title_colors,x
    sta COLOR+$060,x
    inx
    bne asm_logo_name_loop
asm_logo_runtime_begin:
    ldx #$00
asm_logo_runtime_loop:
    lda asm_logo_runtime,x
    beq asm_prepare_game_done
    sta SCREEN+$07f,x
    lda #$03
    sta COLOR+$07f,x
    inx
    bne asm_logo_runtime_loop
asm_prepare_game_done:
    ; The HUD and logo are static in both screen pages. Gameplay draws into the
    ; hidden page and flips D018 only after the frame is complete.
    ldx #$00
asm_copy_header_page:
    lda SCREEN+$000,x
    sta SCREEN+$400,x
    inx
    cpx #$c8
    bne asm_copy_header_page
    ldx #$13
    lda #$00
asm_prepare_previous_platforms:
    sta asm_previous_platform_width,x
    dex
    bpl asm_prepare_previous_platforms
    rts

; Erase only the platform cells touched by the preceding frame. Static stars
; are restored immediately afterward. Each screen page owns a ten-entry dirty
; list, so the hidden page can be updated without exposing partial scrolling.
asm_select_back_screen:
    lda asm_visible_screen
    eor #$01
    sta asm_back_screen
    beq asm_select_back_zero
    lda #$04
    sta asm_back_screen_offset
    lda #$08
    sta asm_back_screen_high
    lda #$0a
    sta asm_previous_buffer_offset
    rts
asm_select_back_zero:
    lda #$00
    sta asm_back_screen_offset
    sta asm_previous_buffer_offset
    lda #$04
    sta asm_back_screen_high
    rts

asm_erase_platforms:
    ldx #$00
asm_erase_platform_loop:
    txa
    clc
    adc asm_previous_buffer_offset
    tay
    lda asm_previous_platform_width,y
    beq asm_erase_platform_next
    sta $f5
    lda asm_previous_platform_x,y
    sta $f4
    lda asm_previous_platform_y,y
    lsr
    lsr
    lsr
    tay
    lda asm_row_lo,y
    sta $f0
    lda asm_row_hi,y
    clc
    adc asm_back_screen_offset
    sta $f1
    lda $f4
    lsr
    lsr
    lsr
    tay
    lda $f5
    lsr
    lsr
    lsr
    sta $f5
    lda #$20
asm_erase_platform_span:
    sta ($f0),y
    iny
    dec $f5
    bne asm_erase_platform_span
asm_erase_platform_next:
    inx
    cpx #$0a
    bne asm_erase_platform_loop
    rts

asm_draw_playfield:
    jsr asm_select_back_screen
    jsr asm_erase_platforms
    ldx #$00
asm_star_loop:
    lda asm_star_offset_lo,x
    sta $f0
    lda asm_star_offset_hi,x
    sta $f1
    clc
    lda $f0
    adc #<SCREEN
    sta $f0
    lda $f1
    adc asm_back_screen_high
    sta $f1
    ldy #$00
    lda #$2e
    sta ($f0),y
    inx
    cpx #$0c
    bne asm_star_loop

    ldx #$00
asm_platform_loop:
    txa
    clc
    adc asm_previous_buffer_offset
    tay
    lda #$00
    sta asm_previous_platform_width,y
    lda _platform_width,x
    beq asm_platform_next
    lda _platform_y,x
    cmp #$b0
    bcs asm_platform_next
    and #$07
    sta $f7
    lda _platform_y,x
    lsr
    lsr
    lsr
    tay
    lda asm_row_lo,y
    sta $f0
    lda asm_row_hi,y
    clc
    adc asm_back_screen_offset
    sta $f1
    lda _platform_x,x
    lsr
    lsr
    lsr
    sta $f4
    lda _platform_width,x
    lsr
    lsr
    lsr
    sta $f5
    lda _platform_kind,x
    tay
    lda asm_platform_char_base,y
    sta $f6
    lda $f7
    asl
    clc
    adc $f7
    clc
    adc $f6
    sta $f6
    ldy $f4
    lda $f6
    sta ($f0),y
    iny
    dec $f5
    beq asm_platform_draw_done
    inc $f6
asm_platform_middle:
    lda $f5
    cmp #$01
    beq asm_platform_right
    lda $f6
    sta ($f0),y
    iny
    dec $f5
    bne asm_platform_middle
asm_platform_right:
    inc $f6
    lda $f6
    sta ($f0),y
asm_platform_draw_done:
    txa
    clc
    adc asm_previous_buffer_offset
    tay
    lda _platform_width,x
    sta asm_previous_platform_width,y
    lda _platform_x,x
    sta asm_previous_platform_x,y
    lda _platform_y,x
    sta asm_previous_platform_y,y
asm_platform_next:
    inx
    cpx #$0a
    beq asm_platforms_done
    jmp asm_platform_loop
asm_platforms_done:
    jsr asm_render_sprites
    rts

; Project the C-owned Q12.4 actor state directly into VIC-II registers. This is
; deliberately assembly-side: three generic sprite-runtime calls cost too much
; in the 50 Hz hot path, while renderer initialization still uses its ABI macro.
asm_render_sprites:
    ; Three authored sequences are stepped by the exact-linked Web64 animation
    ; runtime. Their frame fields drive the native sprite-bank pointers below.
    ; Secondary players are interleaved on the two light frame phases, keeping
    ; the eight-frame HUD refresh phase free for the worst-case PAL budget.
    web64_rt_call_animation_tick _runner_animation
    lda _frame_counter
    and #$03
    cmp #$01
    beq asm_tick_spark_animation
    cmp #$03
    beq asm_tick_hazard_animation
    jmp asm_animation_ticks_done
asm_tick_spark_animation:
    web64_rt_call_animation_tick _spark_animation
    jmp asm_animation_ticks_done
asm_tick_hazard_animation:
    web64_rt_call_animation_tick _hazard_animation
asm_animation_ticks_done:
    lda #$00
    sta asm_sprite_x_msb

    ; Player X = (player.x >> 4) + the 24-pixel playfield inset.
    lda _player+1
    asl
    asl
    asl
    asl
    sta asm_projection_temp
    lda _player
    lsr
    lsr
    lsr
    lsr
    ora asm_projection_temp
    clc
    adc #$18
    sta $d000
    lda _player+1
    and #$10
    bne asm_player_x_high
    bcc asm_player_x_low
asm_player_x_high:
    lda asm_sprite_x_msb
    ora #$01
    sta asm_sprite_x_msb
asm_player_x_low:

    ; Player Y = (player.y >> 4) + the 74-pixel screen inset.
    lda _player+3
    asl
    asl
    asl
    asl
    sta asm_projection_temp
    lda _player+2
    lsr
    lsr
    lsr
    lsr
    ora asm_projection_temp
    clc
    adc #$5a
    sta $d001

    ldx _runner_animation+WEB64_ANIMATION_PLAYER_FRAME
    lda asm_animation_frame_bits,x
    ora _runner_animation_frame_mask
    sta _runner_animation_frame_mask
    txa
    clc
    adc #ASCENDER_SPRITE_POINTER
    sta $07f8
    sta $0bf8
    ldx _spark_animation+WEB64_ANIMATION_PLAYER_FRAME
    txa
    sec
    sbc #$08
    tax
    lda asm_animation_frame_bits,x
    ora _spark_animation_frame_mask
    sta _spark_animation_frame_mask
    lda _spark_animation+WEB64_ANIMATION_PLAYER_FRAME
    clc
    adc #ASCENDER_SPRITE_POINTER
    sta $07f9
    sta $0bf9
    ldx _hazard_animation+WEB64_ANIMATION_PLAYER_FRAME
    txa
    sec
    sbc #$0a
    tax
    lda asm_animation_frame_bits,x
    ora _hazard_animation_frame_mask
    sta _hazard_animation_frame_mask
    lda _hazard_animation+WEB64_ANIMATION_PLAYER_FRAME
    clc
    adc #ASCENDER_SPRITE_POINTER
    sta $07fa
    sta $0bfa
    lda #ascender_frame_0_color
    sta $d027
    lda #ascender_frame_8_color
    sta $d028
    lda #ascender_frame_10_color
    sta $d029

    ; Collectible X/Y. Carry from X+24 is its VIC high bit.
    clc
    lda _spark_x
    adc #$18
    sta $d002
    bcc asm_spark_x_low
    lda asm_sprite_x_msb
    ora #$02
    sta asm_sprite_x_msb
asm_spark_x_low:
    clc
    lda _spark_y
    adc #$5a
    sta $d003

    ; Hazard X is 16-bit and may cross the right border.
    clc
    lda _enemy_x
    adc #$18
    sta $d004
    lda _enemy_x+1
    adc #$00
    beq asm_enemy_x_low
    lda asm_sprite_x_msb
    ora #$04
    sta asm_sprite_x_msb
asm_enemy_x_low:
    clc
    lda _enemy_y
    adc #$5a
    sta $d005

    lda asm_sprite_x_msb
    sta $d010
    lda #$04
    sta SPRITE_MULTICOLOR
    lda #$04
    ldx _spark_active
    beq asm_sprite_visibility_player
    ora #$02
asm_sprite_visibility_player:
    ldx _invulnerable
    beq asm_player_visible
    ldx _frame_counter
    txa
    and #$02
    bne asm_sprite_visibility_done
asm_player_visible:
    ora #$01
asm_sprite_visibility_done:
    sta SPRITE_ENABLE
    rts

; Page flip happens after every character and sprite pointer is ready. D018
; changes during the lower border, so the next visible frame is coherent.
asm_present_frame:
    lda asm_back_screen
    sta asm_visible_screen
    beq asm_present_screen_zero
    lda #$28
    sta $d018
    lda #$1b
    sta $d011
    rts
asm_present_screen_zero:
    lda #$18
    sta $d018
    lda #$1b
    sta $d011
    rts

asm_draw_title:
    lda $d011
    and #$ef
    sta $d011
    jsr asm_clear_screen
    lda #$18
    sta $d018
    lda #$00
    sta asm_visible_screen
    lda #$00
    sta $d020
    lda #$06
    sta $d021
    ldx #$00
asm_title_rule_loop:
    lda #$66
    sta SCREEN+$0a0,x
    sta SCREEN+$280,x
    lda #$0e
    sta COLOR+$0a0,x
    sta COLOR+$280,x
    inx
    cpx #$28
    bne asm_title_rule_loop
    ldx #$00
asm_title_name_loop:
    lda asm_title_name,x
    beq asm_title_subtitle_begin
    sta SCREEN+$0d8,x
    lda asm_title_colors,x
    sta COLOR+$0d8,x
    inx
    bne asm_title_name_loop
asm_title_subtitle_begin:
    ldx #$00
asm_title_subtitle_loop:
    lda asm_title_subtitle,x
    beq asm_title_control_begin
    sta SCREEN+$148,x
    lda #$01
    sta COLOR+$148,x
    inx
    bne asm_title_subtitle_loop
asm_title_control_begin:
    ldx #$00
asm_title_control_loop:
    lda asm_title_control,x
    beq asm_title_boost_begin
    sta SCREEN+$1ea,x
    lda #$03
    sta COLOR+$1ea,x
    inx
    bne asm_title_control_loop
asm_title_boost_begin:
    ldx #$00
asm_title_boost_loop:
    lda asm_title_boost,x
    beq asm_title_start_begin
    sta SCREEN+$238,x
    lda #$07
    sta COLOR+$238,x
    inx
    bne asm_title_boost_loop
asm_title_start_begin:
    ldx #$00
asm_title_start_loop:
    lda asm_title_start,x
    beq asm_title_sprite
    sta SCREEN+$2da,x
    lda #$01
    sta COLOR+$2da,x
    inx
    bne asm_title_start_loop
asm_title_sprite:
    lda #$00
    sta asm_title_phase
    sta $d010
    sta $d017
    sta $d01d
    lda #ascender_animation_run_frame_0+ASCENDER_SPRITE_POINTER
    sta $07f8
    lda #$ac
    sta $d000
    lda #$d8
    sta $d001
    lda #$01
    sta $d027
    sta SPRITE_ENABLE
    lda #$00
    sta SPRITE_MULTICOLOR
    lda #$1b
    sta $d011
    rts

; The menu runner cycles through all four authored strides, bobs by two pixels,
; and shifts color slowly. Gameplay animation remains driven by the runtime.
asm_animate_title:
    inc asm_title_phase
    lda asm_title_phase
    lsr
    lsr
    and #$03
    clc
    adc #ASCENDER_SPRITE_POINTER
    sta $07f8
    lda asm_title_phase
    and #$07
    tax
    lda asm_title_bob,x
    sta $d001
    lda asm_title_phase
    lsr
    lsr
    lsr
    and #$07
    tax
    lda asm_title_sprite_colors,x
    sta $d027
    rts

asm_draw_game_over:
    lda $d011
    and #$ef
    sta $d011
    jsr asm_clear_screen
    lda #$18
    sta $d018
    lda #$00
    sta asm_visible_screen
    lda #$02
    sta $d020
    lda #$00
    sta $d021
    ldx #$00
asm_game_over_loop:
    lda asm_game_over,x
    beq asm_final_label_begin
    sta SCREEN+$14f,x
    lda #$0a
    sta COLOR+$14f,x
    inx
    bne asm_game_over_loop
asm_final_label_begin:
    ldx #$00
asm_final_label_loop:
    lda asm_final_label,x
    beq asm_final_digits
    sta SCREEN+$1c3,x
    lda #$07
    sta COLOR+$1c3,x
    inx
    bne asm_final_label_loop
asm_final_digits:
    ldx #$00
asm_final_digits_loop:
    lda _hud_score_digits,x
    sta SCREEN+$1cf,x
    lda #$01
    sta COLOR+$1cf,x
    inx
    cpx #$05
    bne asm_final_digits_loop
    ldx #$00
asm_try_again_loop:
    lda asm_try_again,x
    beq asm_game_over_done
    sta SCREEN+$260,x
    lda #$03
    sta COLOR+$260,x
    inx
    bne asm_try_again_loop
asm_game_over_done:
    lda #$1b
    sta $d011
    rts

asm_score_label: .byte 19,3,15,18,5,0
asm_high_label: .byte 8,9,0
asm_level_label: .byte 12,22,0
asm_lives_label: .byte 12,0
asm_title_name: .byte 1,19,3,5,14,4,5,18,0
asm_title_colors: .byte $03,$03,$07,$07,$01,$0a,$0a,$08,$08,$02,$02
asm_logo_name: .byte 1,19,3,5,14,4,5,18,0
asm_logo_runtime: .byte 23,5,2,54,52,$20,18,21,14,20,9,13,5,$20,3,12,9,13,2,5,18,$20,53,48,$20,8,26,0
asm_title_subtitle: .byte 5,14,4,12,5,19,19,$20,16,12,1,20,6,15,18,13,$20,3,12,9,13,2,5,18,0
asm_title_control: .byte 12,5,6,20,$20,18,9,7,8,20,$20,20,15,$20,19,20,5,5,18,0
asm_title_boost: .byte 6,9,18,5,$20,7,9,22,5,19,$20,15,14,5,$20,1,9,18,$20,2,15,15,19,20,0
asm_title_start: .byte 16,18,5,19,19,$20,6,9,18,5,$20,20,15,$20,19,20,1,18,20,0
asm_game_over: .byte 7,1,13,5,$20,15,22,5,18,0
asm_final_label: .byte 6,9,14,1,12,$20,19,3,15,18,5,0
asm_try_again: .byte 16,18,5,19,19,$20,6,9,18,5,$20,20,15,$20,20,18,25,$20,1,7,1,9,14,0
asm_platform_char_base:
    .byte ASCENDER_PLATFORM_NORMAL_BASE,ASCENDER_PLATFORM_CRUMBLE_BASE,ASCENDER_PLATFORM_SPRING_BASE
asm_title_bob: .byte $d8,$d7,$d6,$d7,$d8,$d9,$da,$d9
asm_title_sprite_colors: .byte $01,$01,$07,$07,$03,$03,$0a,$0a
asm_star_offset_lo: .byte $ef,$1f,$62,$91,$f2,$1b,$61,$87,$ed,$25,$93,$dd
asm_star_offset_hi: .byte $00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03
asm_animation_frame_bits: .byte $01,$02,$04,$08,$10,$20,$40,$80
asm_previous_platform_x: .fill 20, 0
asm_previous_platform_y: .fill 20, 0
asm_previous_platform_width: .fill 20, 0

asm_row_lo:
    .byte <$04c8,<$04f0,<$0518,<$0540,<$0568,<$0590,<$05b8,<$05e0,<$0608,<$0630
    .byte <$0658,<$0680,<$06a8,<$06d0,<$06f8,<$0720,<$0748,<$0770,<$0798,<$07c0
asm_row_hi:
    .byte >$04c8,>$04f0,>$0518,>$0540,>$0568,>$0590,>$05b8,>$05e0,>$0608,>$0630
    .byte >$0658,>$0680,>$06a8,>$06d0,>$06f8,>$0720,>$0748,>$0770,>$0798,>$07c0
asm_sound_timer: .byte $00
asm_sprite_x_msb: .byte $00
asm_projection_temp: .byte $00
asm_visible_screen: .byte $00
asm_back_screen: .byte $01
asm_back_screen_offset: .byte $04
asm_back_screen_high: .byte $08
asm_previous_buffer_offset: .byte $0a
asm_title_phase: .byte $00

; Native Web64 graphics asset: the IDE owns frame metadata and animation names;
; these .incbin directives embed each generated native payload exactly once.
    .incbin ascender_sprites, "assets/sprites/ascender.w64spr"
    .incbin ascender_platforms_chars, "assets/chars/ascender-platforms.w64chr"
