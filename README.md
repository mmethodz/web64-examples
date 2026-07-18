# Web64 Examples

A standalone suite of Web64 IDE example projects. Each folder contains one self-contained .web64proj file and a README.

The suite covers assembly-only projects, Web64 C projects, mixed C/ASM projects, asset/include workflows, input, raster timing, sprites, screen memory, compiler conformance, and diagnostic scenarios.

Open a .web64proj in the Web64 IDE to inspect, build, and run it.

## Web64 C v1 Coverage

- `c-compiler-conformance` prints PASS/FAIL for parser-backed arithmetic, shifts, bitwise operators, casts, nested calls, `_fastcall` runtime calls, and `printf` argument materialization.
- `c-fixed-subpixel-scroll`, `c-fixed-sine-lerp`, `c-fixed-motion`, `c-fixed-mandelbrot`, and `c-fixed-mandelbrot-bitmap` cover `web64/fixed.h` 8.8 constants/conversions, wrapping fixed addition/subtraction, fixed multiply, `web64_sin8`, `web64_fix8_lerp`, `Web64Motion2D` runtime dependency closure, and runtime-calculated character-mode and multicolor bitmap fixed-point Mandelbrot renderers.
- `c-screen-colors`, `c-screen-memory`, `c-joystick-registers`, `c-sprite-joy`, `sprite-joy-sid-bumps-c`, and `c-asset-header` cover SDK headers, C64 register aliases, sprite helpers, joystick helpers, SID/register workflows, and generated asset metadata.
- `hybrid-c-calls-asm`, `hybrid-asm-uses-c-data`, and `hybrid-asset-copy` cover mixed C/ASM symbols and runtime dependency selection boundaries.
- `diagnostic-unsupported-c` covers stable unsupported-syntax diagnostics.
- `tutorials/README.md` links tutorial prose to runnable projects and intentionally documents only shipped behavior.
