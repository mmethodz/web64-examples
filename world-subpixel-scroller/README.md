# World Subpixel Motion Scroller

Use left/right on joystick port 2 to drive the camera through the Game Runtime Motion module. Motion retains the authoritative Q12.4 position; `world.h` maps it to integer, coarse-cell, and fine-scroll state; the buffered World renderer follows that target without feeding rounded screen coordinates back into physics.

The default profile demonstrates 0.125 px/frame acceleration, gradual braking, clean reversal, and a PAL-safe maximum of 1 px/frame. Releasing the joystick settles deterministically without completing a partial character transition or oscillating around the target.

The v5 renderer keeps the active VIC screen immutable, uses the 38-column edge mask during horizontal fine scrolling, prepares neighbor pages offscreen, and refreshes the exact native per-cell Color RAM plane only when a complete page is selected. The project is self-contained: its `.web64proj` includes the editable `.w64chr`, `.w64blk`, `.w64map`, and `.w64spr` assets plus generated build artifacts.

## Controls

- Left/right: accelerate and reverse the Q12.4 World camera.
- Release left/right: brake smoothly to a deterministic stop.
- Up/down: move the hires marker independently of the camera.
- Browser gamepad polling and the numeric keypad joystick both target port 2.

## Important source constants

- `CAMERA_ACCELERATION = 2` means 2/16 or 0.125 px/frame².
- `CAMERA_BRAKING = 3` means 3/16 or 0.1875 px/frame².
- `CAMERA_MAXIMUM = 16` means 1 px/frame.
