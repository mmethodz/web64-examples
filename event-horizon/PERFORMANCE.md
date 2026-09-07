# Event Horizon — PAL timing and memory

## Measured release behavior

The saved project was reopened in a fresh Web64 IDE workspace, saved again,
compiled, exported with **Save PRG** and launched using **Start PRG**. Virtual
sources and build settings survived the round trip. The compiler reported no
errors or warnings. The standalone PRG includes its BASIC SYS stub.

The same saved project was executed in Web64's real VICE **x64sc** core, with
native VIC-II rendering, sprite DMA, badlines and SID emulation:

- **3,330 completed main-loop updates; zero missed screen-publication deadlines.**
- Highest measured work window: **19,421 cycles**, versus **19,656 cycles per PAL
  frame** (about **98.8%**). This is elapsed CIA1 timer-B time, including IRQs and
  VIC DMA stalls encountered inside the window. It is not an instruction-only
  estimate or a claim that every cycle executes useful foreground instructions.
- The timer starts after the frame hand-off and stops after the screen kernel.
  A small amount of entry, measurement and publication code lies outside it.
  The independent missed-frame counter validates the actual deadline.
- Tunnel/phase shading, stars and SID sequencing run once per PAL frame. The
  24-edge wireframe is drawn in two balanced passes and published at **25 Hz**.
- The stabilized prism scanline was byte-identical across **1,043 sampled
  native frames** under changing foreground, sprite and SID workloads.
- Space freeze/resume passed; complete sprite-plane pixels matched an
  independent line-rasterization reference. The score continued while frozen.
- A complete original SID score loop produced non-silent PCM with **zero native
  audio overruns**. This is an audio-output check, not a subjective listening
  certification or an assertion about every browser/audio device.

Early live-vector versions exceeded a frame. Cost-balanced line scheduling,
grouped shader loads, endpoint immediates, carry reuse after a known borrow,
and unrolled absolute-address buffer clears made the final combination fit.
The small remainder is intentional deadline headroom, not an invitation to add
work without remeasurement. Normal reset and keyboard interactions were tested;
this is not a proof covering every possible hardware modification or IRQ source.

No physical C64 measurement or NTSC compatibility claim is made.

## Raster ownership

Palette IRQs precede each tunnel row's badline. The final row handler switches
to hires footer text, publishes the completed screen and wakes the foreground.
The foreground uses the lower border, top border and visible field to prepare
the following frame; it is not confined to vertical blank.

At raster 256, the first prism IRQ preserves A/X/Y in immediate operands and
arms a second IRQ. The second handler discards only its nested hardware stack
frame. A final raster comparison compensates the one-cycle residual entry phase.

Each prism line consists of:

    8 × (LDA immediate: 2 + STA absolute: 4) + BIT zero page: 3 + 6 × NOP: 2
    = 63 cycles

Thus its eight color changes occur six CPU cycles / 48 VIC pixel clocks apart.
Five such lines run consecutively in a lower-border region without badlines or
sprite DMA. Moving that code into the active sprite area would invalidate the
schedule. The chain restores the ordinary palette IRQ for the next frame.

## Resident memory map

| Address | Ownership |
| --- | --- |
| `$0001` | CPU port: ROMs off, I/O visible |
| `$00e0–$00e7`, `$00eb–$00ec` | Private vector-renderer scratch |
| `$0100–$01ff` | Hardware call/IRQ stack |
| `$0801–$080c` | BASIC SYS header |
| `$0810–$39e0` | Code, state, SID sequencer and specialized drawing kernels |
| `$4000–$47ff` | Multicolor shading charset, phase 0 |
| `$4800–$4fff` | Multicolor shading charset, half-phase |
| `$5000–$50ff`, `$5100–$51ff` | Double-buffered four-sprite core planes |
| `$5200–$5309` | Core row/column/mask and pose-pointer lookup tables |
| `$7000–$73ff`, `$7400–$77ff` | Two screen pages, including sprite pointers |
| `$7800–$7fff` | Hires footer charset; last 256 bytes also hold star animation |
| `$8000–$86ff` | Shader, depth ripple, orbit and pulse-width tables |
| `$8700–$8aff` | Initial Color RAM map |
| `$8b00–$8d49` | Footer screen, palettes and original SID note/frequency tables |
| `$9000–$adff` | 64 sets of projected edge descriptors, not sprite bitmaps |
| `$d000–$dfff` | VIC-II, SID, Color RAM and CIA I/O |
| `$fffa–$ffff` | RAM interrupt vectors with KERNAL banked out |

The load span is **42,495 bytes**, `$0801–$adff`; the PRG file is **42,497 bytes**
including its two-byte load address. Gaps in that span are normal PRG padding,
not additional workspaces or separately loaded modules.

All code/data below the VIC assets is checked to finish before `$4000`.
The active core's sprite pointers are updated before its DMA interval; drawing
and clearing target only the other plane. Screen buffers likewise publish only
after the hidden screen is complete. Neither buffer strategy depends on host
render speed.

Maintainer automation and captured evidence remain outside this distributable
example. Building and using it requires only its native Web64 project.
