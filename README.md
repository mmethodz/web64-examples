# Web64 Examples

A standalone suite of Web64 IDE example projects. The `.web64proj` files contain their virtual sources, assets and build settings; accompanying files are references and release outputs. Some collections contain several projects.

The suite covers assembly-only projects, Web64 C projects, mixed C/ASM projects, asset/include workflows, input, raster timing, sprites, screen memory, compiler conformance, and diagnostic scenarios.

Open a `.web64proj` in the [Web64 IDE](https://web64.nofs.ai/ide/) to inspect, build, and run it. No local compiler, assembler, Node installation or Web64 implementation repository is required.

## Start, change, run

1. Download a project's `.web64proj` and use **Open Web64 project**. The IDE's **New from template... → Examples** collection also offers curated examples from this repository.
2. For an ordinary PRG example, press **F5** or **Start PRG**. Click the emulator when keyboard/game input is needed; each example's README describes its controls.
3. Change the virtual source or a native asset in its editor, then run again. Builds use the current virtual filesystem, including unsaved edits.
4. Use **Save Web64 project** to retain those changes. Editing an adjacent loose source export does not update the project automatically.

For multi-target projects, select the intended target in **Build Targets** and inspect **Build Output**. For disk applications, use **Disk/Media → Build Dependencies → Run Disk**; **Run Disk** builds missing or stale dependencies. Use the configured disk layout rather than manually combining PRGs. Supplied release binaries are convenient snapshots, not the editable project authority.

## Native assets and compatibility examples

Native character, sprite, block, map, trajectory and tracker assets belong in their corresponding IDE editors. Generated includes, asset headers and binary planes are derived outputs: edit their owning asset, then consume the generated bindings from C or assembly. Map structure, material, video-matrix and Color RAM planes describe the displayed world and its behavior; they are not interchangeable arbitrary level-data buffers.

The current IDE supplies the SDK. A saved project's ABI, memory placement, PAL timing and interrupt ownership remain part of that example's design; do not change them just to match a newer default. The [c64lib collection](c64lib/README.md) intentionally teaches compatibility interfaces. For new native scrolling worlds, start with the [World examples](WORLD_RUNTIME_EXAMPLES.md).

## Audio example

- `sample-playback/sample-playback.web64proj` plays a spoken “Welcome to Web64” sample through cycle-counted SID volume updates and displays a centered title afterward. Enable emulator audio before pressing Run; see its README for the playback format.

## Cycle-timed demo

- `cycle-lab/cycle-lab.web64proj` is a small assembly-only companion for Web64's Cycle / Raster Profiler. Open and run the native project, explicitly select the profiling runtime, and compare a raster IRQ's paint routine with a busy waiting loop. The README covers exact frame accounting, source navigation and bounded capture files. It requires an IDE build with the Profiler workspace; no external tools are needed.

- `event-horizon/event-horizon.web64proj` is an assembly-only PAL C64 demo: a dithered inverse-polar tunnel, live double-buffered wireframe sprites, orbiting white stars, original three-voice SID music and an exact-cycle border prism. The tunnel and stars update at 50 Hz; the 6510 draws complete wireframe poses at 25 Hz. Its measured work window reaches 19,421 PAL cycles, with zero missed deadlines across 3,330 verified updates. Open the native project and press F5, or run `event-horizon/dist/event-horizon.prg`. All code and visual tables remain editable in the IDE; no external build machinery is required.

## Productivity application

- `margin64/margin64.web64proj` is a keyboard-driven C64 word-processor example for Web64 2.4.1 or later. Its C/ASM virtual sources, resident safe document I/O, two-drive support, capped Undo/clipboard, and real disk-loaded search/print targets are editable in the IDE. Use Disk/Media > Build Dependencies > Run Disk, or the supplied `margin64/dist/margin64.d64`. The accompanying README and verification record report the 15,866-byte physical document limit, exercised 14 KiB working sample, accepted resident-size miss and remaining limitations. No external build machinery is required.

## Complete game

- `cyber-mole/cyber-mole.web64proj` is a 48-room, single-screen PAL arcade puzzle. Bit drills, patches colored packets, reverses gravity and evades reactive sentinel AI. A presentation-only remaster preserves all thirty original solutions; Deep Descent continues through the Disconnected Archive, 1897 Works and Original Core. Native sprites, all character/block/map planes, the dithered title logo and regional SID music remain editable. Web64's hardware-loader runtime transfers raw and packed banks while the game-owned IRQ animates Bit or a cutscene. The directory contains only the complete Web64 project and accompanying source, native assets, guides and outputs: open it in Web64 2.4.0 or later, then use Disk/Media > Build Dependencies > Run Disk. No Node installation or Web64 source checkout is required. `cyber-mole/dist/cyber-mole.d64` is the supplied one-disk release with writable initials/high scores.
- `ascender/ascender.web64proj` is a compact assembly + C hybrid endless platform climber. The automatically bouncing stick runner can steer and spend one mid-air boost per landing while procedural normal, crumble, and spring ledges scroll through a reduced 20-row arena beneath a centered extended HUD/logo band. Each platform awards its landing bonus only once until recycled. A native 12-frame `.w64spr` bank drives five Web64 runtime animations, while an eight-phase native `.w64chr` platform set provides pixel-granular vertical movement. Motion and collision remain runtime-owned; cycle-critical scrolling, double-buffered dirty-span rendering, sprite projection, HUD conversion, and SID effects run in assembly. Exact page audits and a measured 18,671-cycle worst frame keep the example artifact-free inside its 50 Hz PAL budget.
- `trike-mania/trike-mania.web64proj` is a complete four-racer C64 championship: title screen, four portrait-driven teddy personalities and stat profiles, three distinct multicolor circuits, ordered checkpoints and laps, boosts, jumps, hazards, AI competitors, results, championship scoring, and replay. The project keeps its 33-frame `.w64spr` bank, `.w64chr` charset, three themed `.w64blk` sets, and three material-backed `.w64map` tracks editable in Web64. Its verification evidence covers all 12 teddy/track combinations, full three-lap races, joystick input, runtime closure, Color RAM rendering, and a measured SID-reserved PAL frame budget.
- `mirror-pulse/mirror-pulse.web64proj` is a complete six-course multicolor-bitmap laser puzzle. Move, select, and rotate mirrors before committing one of a finite number of beam pulses; collect single-use score, pulse, and extra-time pickups along valid reflected paths; race stage-dependent PAL timers for time bonuses; and place on a session high-score table. It supports keyboard and port-2 joystick controls, uses the optimized bitmap line runtime for the course and animated pulse trace, and includes deterministic host plus assembled-6502 verification.

## Web64 Game Runtime: World module

- `WORLD_RUNTIME_EXAMPLES.md` links the native `.w64*` World-module examples: static map, horizontal/vertical/bidirectional scrollers, a Q12.4 subpixel Motion scroller, multicolor scroller, platformer, and World + Motion + Sprites actor/camera composition. World belongs to Web64 Game Runtime alongside Motion, Collision, Animation, Sprites, and Actors, while retaining independent runtime closure. These projects include their editable assets and generated build artifacts, copy charset/sprite data into VIC-visible memory at startup, and are joystick-driven on port 2.

## Bitmap drawing examples

- `bitmap-drawing/bitmap-drawing.web64proj` demonstrates bitmap setup, logical-index lines and shapes, explicit palette ownership, and bounded replace-only flood fill.
- `bitmap-wireframe-3d/bitmap-wireframe-3d.web64proj` renders a perspective wireframe cube with twelve optimized bitmap lines. Web64's Matrix generator supplies cyclic Q8.8 X/Y rotation matrices, WASD controls pitch and yaw, and XOR redraw removes the previous orientation without clearing the full bitmap.

## Web64 v2 workstream examples

- `actor-batch-arena/actor-batch-arena.web64proj` is the standalone open actor-batch demonstration: 32 caller-owned SoA actors, an 18-actor visible cohort, sine-driven Q12.4 movement, independent base/overlay animation, public culling and actor-pair buffers, descriptor-backed atomic sprite pairs, repeated six-slot PAL mux reuse, two reserved direct HUD slots, and a deterministic priority drop. Its application-owned IRQ wrapper documents the acknowledgement and chaining boundary; `WEB64_EXAMPLE_VERIFY` exercises 120 frames without hiding any phase buffer or asset placement.
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
