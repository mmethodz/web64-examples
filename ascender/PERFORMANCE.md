# Ascender PAL budget

The playable `main` target waits for one PAL raster boundary per update and is designed for a 19,656-cycle 50 Hz frame.

## Measured steady-state result

The Web64 headless 6502 machine ran the compiled `main` PRG from frame 40 through frame 220 with joystick 2 neutral after starting the game. Cycle deltas were sampled at consecutive raster-wait entries, so startup and title-screen work are excluded.

| Measure | Cycles |
| --- | ---: |
| Average | 14,018 |
| Worst frame | 18,671 |
| PAL ceiling | 19,656 |
| Worst-case headroom | 985 |

The window includes active vertical scrolling, procedural platform recycling, eight-phase custom platform characters, HUD digit refreshes, landings, Web64 motion/collision calls, three runtime animation players, hidden-page drawing, and the final page flip. The runner animation ticks every frame; the spark and hazard players are interleaved on light frame phases so the eight-frame HUD phase retains headroom. No sampled frame exceeded the ceiling. The complete present routine takes at most 23 cycles and alternated cleanly between `$18` and `$28` on every sampled frame.

The same trace audited 230 presented playfields against a canonical reconstruction from the live platform arrays. It found zero mismatched cells and zero writes to the currently visible playfield. The copied `$2000` charset also matched the native `.w64chr` payload byte for byte. Together, those checks cover stale dirty spans, wrong-page writes, bad vertical-phase tiles, and incomplete buffer flips—the paths that cause exposed scroll artifacts.

## Deterministic gameplay target

The separate `verify` target runs 640 update/render iterations without raster waits. Its final symbols must report:

- `verification_complete == 1`
- `verification_landings > 0`
- `verification_aabb_hits > 0`
- `verification_scroll == 1`
- `verification_runtime_motion == 1`
- `verification_runtime_collision == 1`
- `verification_scored_landings > 0`
- `verification_repeat_landings > 0`
- `runner_animation_frame_mask == $ff`
- `spark_animation_frame_mask == 3`
- `hazard_animation_frame_mask == 3`

The current deterministic route accepts 11 landings: six first landings award points and five repeat landings rebound without awarding points. The animation masks prove that all four run frames, both rise frames, both fall frames, and both frames of each secondary animation were selected by the Web64 animation runtime.

The verification also invokes the respawn path directly: the player returns to `(144, 134)`, the hazard is placed at `(280, 24)` moving inward from the far side, and collision damage is suppressed for 75 frames.
