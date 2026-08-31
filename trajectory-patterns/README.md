# Trajectory Patterns

This standalone Web64 project demonstrates the optional Trajectory Pattern Runtime.

- Eight live instances share one immutable 3-byte-per-segment pattern.
- `assets/trajectories/shared-loop.w64traj` is editable in the first-class Trajectory Editor. Its generated `.traj` is exposed to C through `assets/generated.h`; the authoring JSON, anchor, viewport, and preview choices never enter the C64 program.
- The four X/Y mirroring combinations reuse the same pattern bytes.
- Looping and continuously looping ping-pong instances keep independent indices, phases, Q12.4 positions, and interpolation errors.
- Prime and power-of-two durations demonstrate exact centered-DDA endpoints without per-frame movement arrays.
- C owns the frame loop and passes the public positions to the independently linked direct Sprite Runtime. The trajectory runtime does not render, allocate, install an IRQ, or copy assets.
- `state-reader.asm` includes `web64/trajectory.inc` and reads the same public state by its generated offsets.

Open `trajectory-patterns.web64proj` in Web64 IDE and run it. The eight sprites continuously trace mirrored, phase-staggered loops inside the visible screen. Exact linkage adds only `game-trajectory.asm` and the deliberately called `game-sprites.asm` adapter.
