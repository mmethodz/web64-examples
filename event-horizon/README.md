# Event Horizon

A neon inverse-polar tunnel with a live wireframe core, orbiting white stars,
an exact-cycle border prism and an original three-voice SID track, **Tidal Lock**.
For a stock **PAL C64**, written entirely in the Web64 native assembler.

## Open and run

1. Open `event-horizon.web64proj` in [Web64 IDE](https://web64.nofs.ai/ide/).
2. Select the PAL C64 and enable emulator audio.
3. Press **F5 / Start PRG**. **Save PRG** exports a standalone executable.

The supplied `dist/event-horizon.prg` is exported through that same IDE control.
It also has a BASIC `SYS 2064` stub: on a PAL C64, load it at its stored address
and `RUN`. No disk mastering, runtime installation, expansion RAM, cartridge,
Node tools or Web64 source checkout is required.

**Space** freezes/resumes the visual phase; the note sequence keeps playing.
Use emulator reset to leave the demo. It takes over the machine and does not
return to BASIC. NTSC timing is not supported.

## What is actually running

- A 320-by-176-pixel multicolor tunnel updates at the PAL frame rate. Two custom
  charsets interleave half-phase shading, including ordered pixel dithering.
- Twenty-four depth bands animate the polar field. Two specialized drawing
  kernels write a hidden screen and publish it only when complete. Identical
  shader loads within a band are grouped to reuse the accumulator.
- Four joined hires sprites form a double-buffered wireframe surface. A 6510
  integer line renderer draws two intersecting rings: 24 edges per pose,
  distributed in cost-balanced 10/14-edge passes. Complete poses update at
  **25 Hz**; the tunnel and orbiting stars update at **50 Hz**.
- Four more sprites orbit independently with full 9-bit horizontal positions.
  Their shapes animate, and their white color remains distinct from the tunnel.
- Raster interrupts change the shared multicolor palette across the tunnel,
  then switch to a separate hires logo/font at the bottom.
- A double-IRQ stabilizer removes foreground-instruction timing uncertainty.
  Five lower-border scanlines each contain **eight VIC border-color writes**,
  spaced six CPU cycles apart, not eight raster-line waits.
- The original SID player drives bass, pulse arpeggios, kick and noise percussion
  using all three voices. The bass and arpeggio have hardware ADSR envelopes;
  pulse width changes continuously while the visual phase advances.

The tunnel geometry, shading dictionary, orbits and projected edge descriptors
are lookup data. This is **not** general-purpose real-time raytracing or runtime
3D matrix projection. The core's pixels really are rasterized on the 6510;
finished core sprite frames are not stored. Everything displayed is produced
by the native VIC-II, not a browser canvas imitation.

## Developing the example

The saved `.web64proj` and its virtual files are authoritative. Accompanying
source files are readable exports of that same project, not an external build
system. Edit and save the project in the IDE.

| File | Responsibility |
| --- | --- |
| `event-horizon.asm` | Startup, memory ownership and measured main loop |
| `engine.inc` | Phase animation, hardware sprites, keyboard and raster chain |
| `vector-core.inc` | Self-modifying integer line drawing into hidden sprite RAM |
| `core-clear.inc` | Absolute-store clears for the two hidden sprite planes |
| `raster-prism.inc` | PAL double IRQ and 63-cycle scanline schedules |
| `music.inc` | Original three-voice SID sequencer |
| `polar-kernel.inc` | Specialized screen-writing instructions |
| `visual-data.inc` | Editable native ASM charsets, tables, score and edge descriptors |

Graphics are supplied as native assembler data, not `.w64chr`/`.w64spr` editor
documents. Color changes in `engine.inc`/`visual-data.inc`, SID note edits and
phase changes can be developed directly in the IDE. These are specialized
effect tables: changing geometry or shading requires keeping the descriptor,
charset and kernel layouts consistent.

## Hardware and timing contract

The effect owns VIC bank `$4000`, Color RAM, all eight sprites, SID, both CIA
interrupt masks, CIA1 timer B, the keyboard matrix and RAM IRQ/NMI vectors.
It uses documented 6510 instructions with ROMs banked out (`$01 = $35`).
Zero page `$e0–$e7` and `$eb–$ec` belongs to the line renderer; the hardware
stack remains at `$0100–$01ff`. Code and vector buffers are self-modifying RAM.

The measured hot window includes interrupt time and VIC DMA stalls, not just
an ideal instruction sum. A missed-deadline counter checks the actual screen
publication boundary. See `PERFORMANCE.md` for measurements and the memory map.
The remaining cycles are synchronization headroom; extending the effect means
rechecking both the PAL deadline and the stable prism, not simply adding work.
