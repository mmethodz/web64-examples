# Egg Hunt

Open `egghunt.web64proj` in [Web64 IDE](https://web64.nofs.ai/ide/) and press **F5 / Start PRG**. Use joystick port 2: left/right walks and up/down climbs when aligned with a ladder. Collect the eggs in the level.

`main.c` owns the logical player state and Q12.4 movement. `src/render.asm` handles hardware-facing rendering and map access; `include/game.h` defines the material meanings. The map's material plane distinguishes platforms, ladders and eggs, while its Color RAM plane supplies visible colors. A visual edit and a material edit therefore have different gameplay consequences.

Edit the linked charset, blocks, map and sprite assets in their native editors under `assets/`. Do not modify generated material/color binary planes independently. The saved Main target uses `web64-stack-v1`, origin `$6000`, and output `egghunt.prg`.

The `.web64proj` contains the authoritative sources and assets. Save through the IDE to retain edits; compiling does not require a prior save or an external build toolchain.
