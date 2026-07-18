# C Fixed Mandelbrot Bitmap

Web64 C fixed-point Mandelbrot renderer using C64 multicolor bitmap mode.

Open `c-fixed-mandelbrot-bitmap.web64proj` in Web64 IDE and run it. The program first executes deterministic fixed-point oracle checks, switches the VIC-II into multicolor bitmap mode, prepares the shared bitmap color cells, then calculates a 160 x 200 Mandelbrot image into bitmap memory at `$2000`.

The fractal is calculated by Web64-C code at runtime using the public `web64/fixed.h` API. It is not pre-rendered data or a JavaScript-generated asset.

## Fixed-Point Format

This example uses signed 8.8 fixed point (`web64_fix8_8`) for complex-plane coordinates and iteration arithmetic, matching the character-mode Mandelbrot example. Mandelbrot iteration requires multiplication for `real * real`, `imag * imag`, and `real * imag`, so the example uses the currently implemented public 8.8 multiply helper.

Public fixed-point API used:

- `web64_fix8_8`
- `web64_fix8_add_wrap`
- `web64_fix8_sub_wrap`
- `web64_fix8_mul`

## Renderer

- Display strategy: C64 multicolor bitmap mode with bitmap bytes at `$2000`, screen color cells at `$0400`, and color RAM at `$d800`.
- Resolution: 160 x 200 multicolor pixels.
- Viewport: real approximately -2.15 to +0.96, imaginary approximately +1.20 to -1.14, framing the Mandelbrot cardioid and primary bulb.
- Iteration limit: 24.
- Escape test: `real_sq + imag_sq > 4.0`.
- Pixel ramp: bounded points use the black background; escaped points select one of three fixed multicolor entries by iteration depth.
- Palette: every 8 x 8 bitmap cell uses the same screen high nibble, screen low nibble, and color-RAM entry so color-band boundaries come from bitmap pixels instead of cell-local palette changes.
- Controls: none; it renders once and waits.

The render is a one-shot calculation and is expected to be slow on an emulated C64. Use warp if you want the full image quickly. No real-time rendering claim is made.

## Correctness Oracle

Before rendering, the C program checks the same fixed-point Mandelbrot cases as the character-mode example. If any oracle fails, the program returns to text mode, prints `FIXED ORACLE FAIL`, and does not render the bitmap fractal.

## Runtime Closure

Expected runtime modules for the current project are:

- `web64-runtime/startup.asm`
- `web64-runtime/fixed-mul.asm`

Current limitations:

- Uses 8.8 precision because public 16.16 multiplication/division are intentionally not implemented yet.
- Multicolor bitmap mode still has four colors per cell; this example keeps those cell colors stable to avoid blocky 8 x 8 palette transitions.
- Writes the 8000-byte bitmap through 250-byte address bands so byte-indexed Web64-C address expressions stay simple and visible.
