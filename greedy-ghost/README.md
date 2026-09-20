# Greedy Ghost

Open `greedy-ghost.web64proj` in [Web64 IDE](https://web64.nofs.ai/ide/) and press **F5 / Start PRG**. Enable emulator audio for music and effects. Fire on joystick port 2 starts the game; directions steer the inertial player. Collect coins while avoiding the two enemies; fire restarts after game over.

C owns game state, fixed-point movement and the Motion helper calls. `asset_copy.asm` contains hardware-facing video, sprite, SID, raster and scene routines. The charset, block/map and sprite assets remain editable in their corresponding IDE editors.

Music is authored in `assets/music/title.w64sid` through **SID Tracker**. It contains music/effect subtunes; the `.sid` output is the playable binary, not a substitute for editable tracker source. Keep generated asset bindings synchronized through native editor saves.

The Main target compiles `main.c` with `asset_copy.asm`, uses origin `$6000` and produces `ghost.prg`. All development inputs are in the `.web64proj`; save it through Web64 after editing. No separate assembler, music converter or Web64 source checkout is required.
