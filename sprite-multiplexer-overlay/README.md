# Sprite multiplexer and overlay pairs

Open `sprite-multiplexer-overlay.web64proj` in [Web64 IDE](https://web64.nofs.ai/ide/) and press **F5 / Start PRG**. This self-running PAL example combines C-owned sprite submissions with an application-owned assembly IRQ wrapper.

The Sprite Editor assets `assets/sprites/pilot_mc.spr` and `pilot_ol.spr` provide multicolor base and hires overlay layers. `pilot.spritepair.json` describes their relationship. The runtime submits each pair atomically, with independent frame indices and explicit priorities; it does not turn the layers into unrelated sprites when capacity is exhausted.

Inspect `main.c` for caller-owned mux storage and submissions, and `irq-wrapper.asm` for raster acknowledgement/service and register ownership. Keep those boundaries intact when experimenting with timing or adding an IRQ client. Edit the owning sprite assets rather than generated bindings.

The saved PRG target starts at `$6000` and uses `web64-stack-v1`. All required source and assets are in the project. Save through the IDE after editing; no external build tooling is needed.
