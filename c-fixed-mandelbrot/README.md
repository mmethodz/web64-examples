# C Fixed Mandelbrot
Web64 C fixed-point Mandelbrot renderer using the public `web64/fixed.h` API.

Open `c-fixed-mandelbrot.web64proj` in Web64 IDE and run it. The program first executes deterministic fixed-point oracle checks, switches the VIC-II into multicolor bitmap mode, then calculates a 160 x 200 Mandelbrot image into bitmap memory at `$2000`.

The fractal is calculated by Web64-C code at runtime. It is not pre-rendered data or a JavaScript-generated asset.

## Fixed-Point Format

This example uses signed 8.8 fixed point (`web64_fix8_8`) for complex-plane coordinates and iteration arithmetic.

The 16.16 public tier currently exposes constants, conversions, floor/to-int, and wrapping add/sub macros, but no implementation-backed 16.16 multiply or divide helpers. Mandelbrot iteration requires multiplication for `real * real`, `imag * imag`, and `real * imag`, so this example deliberately uses the strongest correct implemented format instead of adding private local multiply code.

Public fixed-point API used:

- `web64_fix8_8`
- `web64_fix8_add_wrap`
- `web64_fix8_sub_wrap`
- `web64_fix8_mul`

## Renderer

- Display strategy: C64 multicolor bitmap mode with bitmap bytes at `$2000`, screen color cells at `$0400`, and color RAM at `$d800`.
- Resolution: 160 x 200 multicolor pixels.
- Viewport: real approximately -2.15 to +0.96, imaginary approximately +1.20 to -1.14.
- Iteration limit: 24.
- Escape test: `real_sq + imag_sq > 4.0`.
- Pixel ramp: bounded points use the black background; escaped points select one of three fixed multicolor entries by iteration depth.
- Controls: none; it renders once and waits.

This removes the old 40 x 25 text-cell renderer that produced visibly blocky 8x8 edges. The example uses one stable bitmap palette across all cells so color-band boundaries are produced by the 160 x 200 bitmap pixels instead of by 8 x 8 cell palette changes.

The render is a one-shot calculation and is expected to be slow on an emulated C64. Use warp if you want the full image quickly. No real-time rendering claim is made.

## Correctness Oracle

Before rendering, the C program checks these fixed-point cases with the same `mandelbrot_iterate` routine used by the renderer:

- `c = 0 + 0i` remains bounded through 24 iterations.
- `c = -1 + 0i` remains bounded through 24 iterations.
- `c = 1 + 0i` escapes before the iteration limit.
- `c = -2 + 0i` is treated as the documented boundary result and remains bounded through 24 iterations under the implemented escape rule.
- `c = 1 + 1i` escapes before the iteration limit.
- `c = -0.125 + 0.75i` remains bounded through 24 iterations.

If any oracle fails, the program prints `FIXED ORACLE FAIL` and does not render the fractal.

## Runtime Closure

Expected runtime modules for the current project are:

- `web64-runtime/startup.asm`
- `web64-runtime/fixed-mul.asm`

Current limitations:

- Uses 8.8 precision because public 16.16 multiplication/division are intentionally not implemented yet.
- Multicolor bitmap mode has four colors per 8 x 8 cell; this example keeps those cell colors stable to avoid blocky 8 x 8 palette transitions.
- Writes the 8000-byte bitmap through 250-byte address bands so byte-indexed Web64-C address expressions stay simple and visible.