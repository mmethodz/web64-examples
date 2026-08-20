# Web64 Examples

A standalone suite of Web64 IDE example projects. Each folder contains one self-contained .web64proj file and a README.

The suite covers assembly-only projects, Web64 C projects, mixed C/ASM projects, asset/include workflows, input, raster timing, sprites, screen memory, compiler conformance, and diagnostic scenarios.

Open a .web64proj in the Web64 IDE to inspect, build, and run it.

## Web64 Game Runtime: World module

- `WORLD_RUNTIME_EXAMPLES.md` links the native `.w64*` World-module examples: static map, horizontal/vertical/bidirectional scrollers, a Q12.4 subpixel Motion scroller, multicolor scroller, platformer, and World + Motion + Sprites actor/camera composition. World belongs to Web64 Game Runtime alongside Motion, Collision, Animation, Sprites, and Actors, while retaining independent runtime closure. These projects include their editable assets and generated build artifacts, copy charset/sprite data into VIC-visible memory at startup, and are joystick-driven on port 2.

## Web64 C v1 Coverage

- `c-compiler-conformance` prints PASS/FAIL for parser-backed arithmetic, shifts, bitwise operators, casts, nested calls, `_fastcall` runtime calls, and `printf` argument materialization.
- `c-fixed-subpixel-scroll`, `c-fixed-sine-lerp`, `c-fixed-motion`, `c-fixed-mandelbrot`, and `c-fixed-mandelbrot-bitmap` cover `web64/fixed.h` 8.8 constants/conversions, wrapping fixed addition/subtraction, fixed multiply, `web64_sin8`, `web64_fix8_lerp`, `Web64Motion2D` runtime dependency closure, and runtime-calculated character-mode and multicolor bitmap fixed-point Mandelbrot renderers.
- `c-screen-colors`, `c-screen-memory`, `c-joystick-registers`, `c-sprite-joy`, `sprite-joy-sid-bumps-c`, and `c-asset-header` cover SDK headers, C64 register aliases, sprite helpers, joystick helpers, SID/register workflows, and generated asset metadata.
- `hybrid-c-calls-asm`, `hybrid-asm-uses-c-data`, and `hybrid-asset-copy` cover mixed C/ASM symbols and runtime dependency selection boundaries.
- `diagnostic-unsupported-c` retains its historical path but now serves as a runnable `switch`-statement regression project.
- `tutorials/README.md` links tutorial prose to runnable projects and intentionally documents only shipped behavior.
