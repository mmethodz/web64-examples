# Hybrid platform jumper

Open `platform.web64proj` in [Web64 IDE](https://web64.nofs.ai/ide/) and press **F5 / Start PRG**. Use joystick port 2: left/right moves and fire jumps.

This single-screen example combines C movement with assembly asset placement. Its `charset.chr`, `blocks.blk`, `map.map` and `sprites.spr` are editable project assets. The map is the displayed multicolor level, not an unrelated data container. Keep the map, block and charset references together when editing through their IDE editors.

The **Platform Jumper** target compiles `main.c` and `platform-assets.asm`, uses origin `$8000`, and produces `platform-jumper.prg`. The `.web64proj` holds those sources and build settings; no separate compiler or asset conversion scripts are needed. For the independently linked current World/Motion/Collision composition, also see [World Runtime Platformer](../world-runtime-platformer/README.md).
