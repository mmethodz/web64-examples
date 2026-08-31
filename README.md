# Web64 Examples

A standalone suite of Web64 IDE example projects. Each folder contains one self-contained .web64proj file and a README.

The suite covers assembly-only projects, Web64 C projects, mixed C/ASM projects, asset/include workflows, input, raster timing, sprites, screen memory, compiler conformance, and diagnostic scenarios.

Open a .web64proj in the Web64 IDE to inspect, build, and run it.

## Complete game

- `trike-mania/trike-mania.web64proj` is a complete four-racer C64 championship: title screen, four portrait-driven teddy personalities and stat profiles, three distinct multicolor circuits, ordered checkpoints and laps, boosts, jumps, hazards, AI competitors, results, championship scoring, and replay. The project keeps its 33-frame `.w64spr` bank, `.w64chr` charset, three themed `.w64blk` sets, and three material-backed `.w64map` tracks editable in Web64. Its verification evidence covers all 12 teddy/track combinations, full three-lap races, joystick input, runtime closure, Color RAM rendering, and a measured SID-reserved PAL frame budget.

## Web64 Game Runtime: World module

- `WORLD_RUNTIME_EXAMPLES.md` links the native `.w64*` World-module examples: static map, horizontal/vertical/bidirectional scrollers, a Q12.4 subpixel Motion scroller, multicolor scroller, platformer, and World + Motion + Sprites actor/camera composition. World belongs to Web64 Game Runtime alongside Motion, Collision, Animation, Sprites, and Actors, while retaining independent runtime closure. These projects include their editable assets and generated build artifacts, copy charset/sprite data into VIC-visible memory at startup, and are joystick-driven on port 2.

## Bitmap drawing examples

- `bitmap-drawing/bitmap-drawing.web64proj` demonstrates bitmap setup, logical-index lines and shapes, explicit palette ownership, and bounded replace-only flood fill.
- `bitmap-wireframe-3d/bitmap-wireframe-3d.web64proj` renders a perspective wireframe cube with twelve optimized bitmap lines. Web64's Matrix generator supplies cyclic Q8.8 X/Y rotation matrices, WASD controls pitch and yaw, and XOR redraw removes the previous orientation without clearing the full bitmap.

## Web64 v2 workstream examples

- `actor-batch-arena/actor-batch-arena.web64proj` is the standalone open actor-batch demonstration: 32 caller-owned SoA actors, 21 visible actors, sine-driven Q12.4 movement, independent base/overlay animation, public culling and actor-pair buffers, descriptor-backed atomic sprite pairs, repeated six-slot PAL mux reuse, two reserved direct HUD slots, and a deterministic priority drop. Its application-owned IRQ wrapper documents the acknowledgement and chaining boundary; `WEB64_EXAMPLE_VERIFY` exercises 120 frames without hiding any phase buffer or asset placement.
- `trajectory-patterns/trajectory-patterns.web64proj` demonstrates eight independent trajectory states sharing one immutable compact waypoint pattern authored as `assets/trajectories/shared-loop.w64traj`. The editable asset deterministically generates the raw `.traj` consumed through `assets/generated.h`; its anchor and editor context never enter the C64 program. The example covers all four X/Y mirroring combinations, looping, ping-pong, phase staggering, exact prime-duration interpolation, direct C-owned VIC-II rendering, and native assembly inspection through `web64/trajectory.inc` while linking only the trajectory runtime module.
- `trajectory-patterns-asm/trajectory-patterns-asm.web64proj` is the cycle-critical native companion. Its independent `square-loop.w64traj` generates a `.traj`/`.inc` pair, and the assembly consumes only those placement-neutral outputs. C enters assembly once; one `_web64_trajectory_step_batch_fast` call advances eight caller-owned lockstep states, and open assembly projects the changed Q12.4 axis directly into all eight VIC-II sprites. The complete measured hot interval stays at or below 3,783 cycles / 19.246% PAL under both C ABIs, including event writes and VIC projection, while exact-linking only the scalar and batch trajectory modules.
- `trajectory-actors/trajectory-actors.web64proj` is the comprehensive C composition example: eight actors each use a distinct editable `.w64traj`, while all eight share a four-frame animated Web64 sprite asset. Every trajectory carries an authoring-only animation preview reference; C explicitly owns runtime placement, animation binding, sprite-RAM installation, stepping, and rendering.
- `trajectory-actors-asm/trajectory-actors-asm.web64proj` renders the same eight assets and animation entirely from open native assembly after its one-shot C entry. It consumes generated `.traj`/`.inc` and sprite symbols, uses scalar stepping for heterogeneous paths, and projects full public Q12.4 coordinates—including VIC-II high-X bits—without introducing an engine-owned actor model.

## Web64 C v1 Coverage

- `c-compiler-conformance` prints PASS/FAIL for parser-backed arithmetic, shifts, bitwise operators, casts, nested calls, `_fastcall` runtime calls, and `printf` argument materialization.
- `c-fixed-subpixel-scroll`, `c-fixed-sine-lerp`, `c-fixed-motion`, `c-fixed-mandelbrot`, and `c-fixed-mandelbrot-bitmap` cover `web64/fixed.h` 8.8 constants/conversions, wrapping fixed addition/subtraction, fixed multiply, `web64_sin8`, `web64_fix8_lerp`, `Web64Motion2D` runtime dependency closure, and runtime-calculated character-mode and multicolor bitmap fixed-point Mandelbrot renderers.
- `c-screen-colors`, `c-screen-memory`, `c-joystick-registers`, `c-sprite-joy`, `sprite-joy-sid-bumps-c`, and `c-asset-header` cover SDK headers, C64 register aliases, sprite helpers, joystick helpers, SID/register workflows, and generated asset metadata.
- `hybrid-c-calls-asm`, `hybrid-asm-uses-c-data`, and `hybrid-asset-copy` cover mixed C/ASM symbols and runtime dependency selection boundaries.
- `diagnostic-unsupported-c` retains its historical path but now serves as a runnable `switch`-statement regression project.
- `tutorials/README.md` links tutorial prose to runnable projects and intentionally documents only shipped behavior.
