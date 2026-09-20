# Bumps

Open `bumps.web64proj` in [Web64 IDE](https://web64.nofs.ai/ide/) and press **F5 / Start PRG**. This self-running assembly plasma demonstrates an explicitly expanded screen-rendering loop and a custom density charset.

The target starts at `init`, uses origin `$c000` and produces `bumps.prg`. Its editable character asset is `assets/chars/bumps.chr`; assembly copies the charset into display RAM and consumes its generated include. Change the asset in Char Editor, not the generated `.inc`, or inspect the phase and row calculations in `bumps.asm`.

Sources and asset metadata live in the `.web64proj`. Builds use unsaved virtual edits; **Save Web64 project** preserves them without requiring external tools.
