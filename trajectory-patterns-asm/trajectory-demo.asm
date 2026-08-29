.include "web64/trajectory.inc"

; This is an open mixed C/assembly example. The only C work is entering this
; routine once. Every per-frame operation below is native assembly.

TRAJECTORY_ACTORS = 8
SPRITE_POINTER_TABLE = $07f8
SPRITE_DATA = $3000
SPRITE_POINTER = $c0
VIC_SPRITE_X_MSB = $d010
VIC_SPRITE_ENABLE = $d015
VIC_SPRITE_Y_EXPAND = $d017
VIC_SPRITE_PRIORITY = $d01b
VIC_SPRITE_MULTICOLOR = $d01c
VIC_SPRITE_X_EXPAND = $d01d
VIC_BORDER = $d020
VIC_BACKGROUND = $d021
VIC_RASTER = $d012

asm_trajectory_demo:
_asm_trajectory_demo:
    sei
    jsr trajectory_clear_screen
    jsr trajectory_install_sprite
    jsr trajectory_init_states

    ; Prepare the stable five-byte window once; the frame loop then pays only JSR.
    web64_rt_prepare_trajectory_step_batch_fast trajectory_states, TRAJECTORY_ACTORS, trajectory_events

    jsr trajectory_project_positions
    lda #0
    sta trajectory_frame_counter
    sta trajectory_frame_counter+1

trajectory_frame_loop:
trajectory_wait_raster:
    lda VIC_RASTER
    cmp #250
    bne trajectory_wait_raster
trajectory_wait_leave:
    lda VIC_RASTER
    cmp #250
    beq trajectory_wait_leave

; The purple border interval is the complete hot workload: one public fast
; batch call plus direct projection of the one VIC axis changed this frame.
    lda #4
    sta VIC_BORDER
trajectory_hot_start:
    ; This pattern is axis-aligned and the batch is lockstep. Inspecting the
    ; public pre-step segment index identifies the changed axis without a mirror.
    lda trajectory_states+WEB64_TRAJECTORY_STATE_CONTROL
    and #1
    bne trajectory_hot_y
trajectory_hot_x:
    jsr _web64_trajectory_step_batch_fast
    lda trajectory_states+0+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$30
    sta $d000
    lda trajectory_states+19+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$50
    sta $d002
    lda trajectory_states+38+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$80
    sta $d004
    lda trajectory_states+57+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$a0
    sta $d006
    lda trajectory_states+76+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$30
    sta $d008
    lda trajectory_states+95+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$50
    sta $d00a
    lda trajectory_states+114+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$80
    sta $d00c
    lda trajectory_states+133+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$a0
    sta $d00e

    jmp trajectory_hot_projected
trajectory_hot_y:
    jsr _web64_trajectory_step_batch_fast
    lda trajectory_states+0+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$40
    sta $d001
    lda trajectory_states+19+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$40
    sta $d003
    lda trajectory_states+38+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$50
    sta $d005
    lda trajectory_states+57+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$50
    sta $d007
    lda trajectory_states+76+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$90
    sta $d009
    lda trajectory_states+95+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$90
    sta $d00b
    lda trajectory_states+114+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$a0
    sta $d00d
    lda trajectory_states+133+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$a0
    sta $d00f

trajectory_hot_projected:
    lda #0
    sta VIC_BORDER
trajectory_hot_end:
    inc trajectory_frame_counter
    bne trajectory_frame_counted
    inc trajectory_frame_counter+1
trajectory_frame_counted:
    jmp trajectory_frame_loop

trajectory_init_states:
    ; The shared pattern argument is invariant across all eight initializations.
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_pattern, trajectory_pattern
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_state, (trajectory_states+0)
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_x, $0310
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_y, $0410
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_options, $1000
    jsr _web64_trajectory_init_fast
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_init_ok_0
    jmp trajectory_init_failed
trajectory_init_ok_0:
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_state, (trajectory_states+19)
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_x, $05e0
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_y, $0410
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_options, $1400
    jsr _web64_trajectory_init_fast
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_init_ok_1
    jmp trajectory_init_failed
trajectory_init_ok_1:
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_state, (trajectory_states+38)
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_x, $0810
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_y, $05e0
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_options, $1800
    jsr _web64_trajectory_init_fast
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_init_ok_2
    jmp trajectory_init_failed
trajectory_init_ok_2:
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_state, (trajectory_states+57)
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_x, $0ae0
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_y, $05e0
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_options, $1c00
    jsr _web64_trajectory_init_fast
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_init_ok_3
    jmp trajectory_init_failed
trajectory_init_ok_3:
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_state, (trajectory_states+76)
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_x, $0310
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_y, $0910
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_options, $1000
    jsr _web64_trajectory_init_fast
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_init_ok_4
    jmp trajectory_init_failed
trajectory_init_ok_4:
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_state, (trajectory_states+95)
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_x, $05e0
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_y, $0910
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_options, $1400
    jsr _web64_trajectory_init_fast
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_init_ok_5
    jmp trajectory_init_failed
trajectory_init_ok_5:
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_state, (trajectory_states+114)
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_x, $0810
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_y, $0ae0
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_options, $1800
    jsr _web64_trajectory_init_fast
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_init_ok_6
    jmp trajectory_init_failed
trajectory_init_ok_6:
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_state, (trajectory_states+133)
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_x, $0ae0
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_y, $0ae0
    web64_trajectory_arg_u16 _web64_trajectory_init_fast__arg_options, $1c00
    jsr _web64_trajectory_init_fast
    cmp #WEB64_TRAJECTORY_OK
    beq trajectory_init_ok_7
    jmp trajectory_init_failed
trajectory_init_ok_7:

    rts

trajectory_init_failed:
    lda #2
    sta VIC_BORDER
    sta VIC_BACKGROUND
trajectory_init_failed_loop:
    jmp trajectory_init_failed_loop

trajectory_project_positions:
    ; Every lane stays inside its compile-time 16-pixel X/Y band. The public
    ; state remains full 16-bit Q12.4 and the verifier proves this specialization.
    ; Sprite 0: public Q12.4 low bytes plus proven 16-pixel bands.
    lda trajectory_states+0+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$30
    sta $d000
    lda trajectory_states+0+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$40
    sta $d001
    ; Sprite 1: public Q12.4 low bytes plus proven 16-pixel bands.
    lda trajectory_states+19+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$50
    sta $d002
    lda trajectory_states+19+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$40
    sta $d003
    ; Sprite 2: public Q12.4 low bytes plus proven 16-pixel bands.
    lda trajectory_states+38+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$80
    sta $d004
    lda trajectory_states+38+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$50
    sta $d005
    ; Sprite 3: public Q12.4 low bytes plus proven 16-pixel bands.
    lda trajectory_states+57+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$a0
    sta $d006
    lda trajectory_states+57+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$50
    sta $d007
    ; Sprite 4: public Q12.4 low bytes plus proven 16-pixel bands.
    lda trajectory_states+76+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$30
    sta $d008
    lda trajectory_states+76+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$90
    sta $d009
    ; Sprite 5: public Q12.4 low bytes plus proven 16-pixel bands.
    lda trajectory_states+95+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$50
    sta $d00a
    lda trajectory_states+95+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$90
    sta $d00b
    ; Sprite 6: public Q12.4 low bytes plus proven 16-pixel bands.
    lda trajectory_states+114+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$80
    sta $d00c
    lda trajectory_states+114+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$a0
    sta $d00d
    ; Sprite 7: public Q12.4 low bytes plus proven 16-pixel bands.
    lda trajectory_states+133+WEB64_TRAJECTORY_STATE_X
    lsr
    lsr
    lsr
    lsr
    ora #$a0
    sta $d00e
    lda trajectory_states+133+WEB64_TRAJECTORY_STATE_Y
    lsr
    lsr
    lsr
    lsr
    ora #$a0
    sta $d00f

    rts

trajectory_clear_screen:
    lda #0
    sta VIC_BORDER
    sta VIC_BACKGROUND
    tax
    lda #$20
trajectory_clear_screen_loop:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne trajectory_clear_screen_loop
    rts

trajectory_install_sprite:
    ldx #63
trajectory_copy_sprite_loop:
    lda trajectory_sprite_bytes,x
    sta SPRITE_DATA,x
    dex
    bpl trajectory_copy_sprite_loop
    ldx #7
trajectory_setup_sprite_loop:
    lda #SPRITE_POINTER
    sta SPRITE_POINTER_TABLE,x
    lda trajectory_sprite_colors,x
    sta $d027,x
    dex
    bpl trajectory_setup_sprite_loop
    lda #$ff
    sta VIC_SPRITE_ENABLE
    lda #0
    sta VIC_SPRITE_X_MSB
    sta VIC_SPRITE_Y_EXPAND
    sta VIC_SPRITE_PRIORITY
    sta VIC_SPRITE_MULTICOLOR
    sta VIC_SPRITE_X_EXPAND
    rts

; Four continuously moving segments form one closed 12x12 path. All eight states
; remain lockstep, while the option bits mirror one immutable path four ways.
trajectory_segments:
    web64_trajectory_emit_segment 12, 0, 12
    web64_trajectory_emit_segment 0, 12, 12
    web64_trajectory_emit_segment $f4, 0, 12
    web64_trajectory_emit_segment 0, $f4, 12
trajectory_pattern:
    web64_trajectory_emit_pattern trajectory_segments, 4

trajectory_sprite_colors:
    .byte 3, 5, 6, 7, 10, 13, 14, 1
trajectory_sprite_bytes:
    .byte $00, $18, $00, $00, $3c, $00, $00, $7e, $00, $00, $ff, $00, $01, $ff, $80, $03, $ff, $c0, $07, $ff, $e0, $0f, $ff, $f0, $1f, $ff, $f8, $3f, $ff, $fc, $7f, $ff, $fe, $0f, $ff, $f0, $0f, $ff, $f0, $0f, $ff, $f0, $0f, $ff, $f0, $0f, $ff, $f0, $0f, $ff, $f0, $03, $ff, $c0, $01, $ff, $80, $00, $7e, $00, $00, $3c, $00
    .byte 0

; Public buffers: assembly, C, KickAssembler, or another runtime may inspect or
; transform these directly. No private semantic mirror exists.
; This visible 280-byte pad keeps the entire 152-byte state array within one page
; in both published C ABIs. The verifier checks that invariant, so layout drift
; cannot silently reintroduce indexed page-cross penalties.
    .fill 280, 0
trajectory_states:
    web64_trajectory_reserve_states TRAJECTORY_ACTORS
trajectory_events:
    web64_trajectory_reserve_events TRAJECTORY_ACTORS
trajectory_frame_counter:
    .word 0
