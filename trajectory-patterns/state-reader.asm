.include "web64/trajectory.inc"

; Native assembly reads the same caller-owned state with published offsets.
; No adapter, copied state, or hidden runtime storage is involved.
_example_color_from_state:
    lda _state0+WEB64_TRAJECTORY_STATE_CONTROL
    and #$0f
    clc
    adc #2
    ldx #0
    rts
