; Ordinary Code workspace source. All metadata comes from SID Tracker Save.
; The four sources use the tracker's default, filename-derived symbol names.
.include "assets/music/substrate.inc"
.include "assets/music/archive.inc"
.include "assets/music/works.inc"
.include "assets/music/core.inc"
substrate_sid = substrate_sid_load_address
archive_sid = archive_sid_load_address
works_sid = works_sid_load_address
core_sid = core_sid_load_address
cyber_music_payload_end = substrate_sid_payload_end

; X = installed bank. Called cold, after exact-length validation and before
; enabling playback. Changing the generated driver layout needs no manual fix.
select_music:
    cpx #4
    bcs music_layout_invalid
    lda music_load_lo,x
    bne music_layout_invalid
    lda music_load_hi,x
    cmp #$90
    bne music_layout_invalid
    lda music_end_hi,x
    cmp #$b0
    bcc music_layout_valid
    bne music_layout_invalid
    lda music_end_lo,x
    bne music_layout_invalid
music_layout_valid:
    lda music_init_lo,x
    sta cyber_music_init_address+1
    lda music_init_hi,x
    sta cyber_music_init_address+2
    lda music_play_lo,x
    sta cyber_music_play_address+1
    lda music_play_hi,x
    sta cyber_music_play_address+2
    stx current_music
    clc
    rts
music_layout_invalid:
    sec
    rts

; A stays the subtune index for init. One absolute JMP (3 cycles) per call.
cyber_music_init_address:
    jmp substrate_sid_init_address
cyber_music_play_address:
    jmp substrate_sid_play_address

; Symbolic lengths are essential: a Tracker edit may grow or shrink a song.
music_end_lo:
    .byte <substrate_sid_payload_end,<archive_sid_payload_end,<works_sid_payload_end,<core_sid_payload_end
music_end_hi:
    .byte >substrate_sid_payload_end,>archive_sid_payload_end,>works_sid_payload_end,>core_sid_payload_end
music_load_lo:
    .byte <substrate_sid_load_address,<archive_sid_load_address,<works_sid_load_address,<core_sid_load_address
music_load_hi:
    .byte >substrate_sid_load_address,>archive_sid_load_address,>works_sid_load_address,>core_sid_load_address
music_init_lo:
    .byte <substrate_sid_init_address,<archive_sid_init_address,<works_sid_init_address,<core_sid_init_address
music_init_hi:
    .byte >substrate_sid_init_address,>archive_sid_init_address,>works_sid_init_address,>core_sid_init_address
music_play_lo:
    .byte <substrate_sid_play_address,<archive_sid_play_address,<works_sid_play_address,<core_sid_play_address
music_play_hi:
    .byte >substrate_sid_play_address,>archive_sid_play_address,>works_sid_play_address,>core_sid_play_address
