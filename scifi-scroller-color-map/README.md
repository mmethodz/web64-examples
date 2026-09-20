# Sci-Fi Color Map Scroller

Open `scifi-scroller-color-map.web64proj` in [Web64 IDE](https://web64.nofs.ai/ide/) and press **F5 / Start PRG**. The assembly demo automatically scrolls in both directions across an 80×25 multicolor map below a fixed four-row HUD.

Inspect `main.asm` for the explicitly scheduled fine-scroll and streaming work. The editable charset is `assets/chars/scifi2.chr`; `assets/scifimap2.map` owns the map and its generated `.screen.bin` and `.color.bin` planes. Edit the map in Map Editor rather than modifying those derived planes independently.

The Main target uses `start` at `$8000` and produces `main.prg`. This is an application-owned scroller; the [World examples](../WORLD_RUNTIME_EXAMPLES.md) demonstrate the reusable native runtime alternative. Save the `.web64proj` after editing; building and running require only the public IDE.
