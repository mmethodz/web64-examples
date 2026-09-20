# Turbo Highway

Open `turbo-highway.web64proj` in [Web64 IDE](https://web64.nofs.ai/ide/) and press **F5 / Start PRG**. Use joystick port 2: left/right steers, up accelerates, down brakes, and fire gives a short turbo push.

`main.asm` implements raster-timed pseudo-3D driving with paired multicolor sprites. The project keeps two charsets, a road block set/map and the sprite bank editable under `assets/`. Use the corresponding Char, Block, Map and Sprite editors; retain the linked asset paths and generated symbols.

The **Turbo Highway** target starts at `start`, uses origin `$4000` and produces `driver.prg`. These names are intentional: the editable project is not named after the output PRG. The saved `.web64proj` is the source authority; edit and save it through Web64 without an external assembler or custom packing tool.
