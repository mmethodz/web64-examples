# Cycle Lab

A small, assembly-only experiment for Web64's Cycle / Raster Profiler.
Open `cycle-lab.web64proj` in the IDE and choose **Run PRG** (F5).
The saved project is authoritative; `main.asm` is an accompanying source export.
No external tools or source repositories are needed to build it.

## Measure a frame

1. Open **Profiler** and choose **Restart with profiling runtime**. This clears
   the emulated machine, not your project or editor. Run the program again.
2. Capture one detailed frame. PAL has 312 lines × 63 clocks = 19,656 clocks.
   CPU progress plus measured bus stalls must equal that total.
3. Select a raster line with the strip or arrow keys. The horizontal strip
   shows instruction/interrupt intervals and their bus-stall subintervals.
4. Inspect a hotspot and follow **Source** or **Generated ASM**. The `idle`
   loop is intentionally the hottest address: waiting is CPU work too!
5. Use the addresses of `paint_row` and `paint_end` in the Symbols pane as an
   exclusive-end PC range. Name it `Paint row` to separate useful work from
   the polling loop. The copy's STA indexed cost is fixed; indexed reads can
   incur a page-cross penalty depending on the source address.

The IRQ runs at line 50. Display badlines steal bus cycles later in the frame.
The border brackets a short paint routine, not the entire frame; its elapsed
time and the whole-frame budget answer different questions.

## Try an edit

Change the copy length or add a bounded task to `paint_row`, save, and run again.
Capture a new frame. A previous capture belongs to its original build: editing
does not silently attach old timings to new source lines. Live Patch can stop
an active capture when it changes guest memory; finish editing and capture again.

Detailed captures have fixed memory limits and can end early. An incomplete
capture is not a full-frame measurement. Aggregate captures do not provide
individual instruction timing or branch-path evidence. Inclusive call costs
overlap; never add them to the CPU/stall partition.

**Export W64P** streams a local capture through the browser file picker
(Chrome/Edge). Importing preserves the measured ledger; source navigation also
requires the matching build. Exports contain timing and fetched instruction
bytes, not the source document. No capture is uploaded to a service.

Return to **Restart with normal runtime** when finished. Normal operation does
not load the profiling Wasm. This experiment targets the stock C64 and has no
disk, asset, or runtime-library dependencies.
