# Assembly plasma

Open `asm-plasma.web64proj` in [Web64 IDE](https://web64.nofs.ai/ide/) and press **F5 / Start PRG**. This self-running character-mode effect combines a sine lookup table with a custom shading charset; it is not a bitmap-mode renderer.

`main.asm` owns initialization, raster synchronization and screen updates. The charset at `assets/shadechars.chr` is an editable project asset, copied to VIC-visible RAM at `$2000`; screen RAM remains at `$0400`. Edit the shading characters in Char Editor or change phase increments in the virtual assembly source, then run again. Keep the asset path and generated symbols consistent.

The saved target produces `asm-plasma.prg` from `$c000`. Save the `.web64proj` to retain edits; no external assembler or local build chain is needed.
