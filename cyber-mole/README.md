# CYBER-MOLE

A PAL C64 arcade puzzle game for Web64 2.4.0 or later. You are Bit, a plasma-drill maintenance robot descending through **48 grids**: corporate servers, a disconnected archive, the brass machinery of the 1897 Works, and the original maintenance core.

## Open, build, and play

1. Open [Web64 IDE](https://web64.nofs.ai/ide/) and open `cyber-mole.web64proj`. The project contains all source, native assets, editor metadata, Build Targets, and disk placements.
2. In **Disk/Media**, choose the **Cyber-Mole disk** set and press **Build Dependencies**.
3. Press **Run Disk** to master, mount in drive 8, and boot the current project. The emulator's play/resume button does not rebuild anything. Running only the resident PRG requires its matching data disk to be mounted separately.
4. Export the rebuilt D64 when you want to keep or transfer it. **Download File** exports an individual mastered PRG.

No command line, Node installation, external assembler/compressor, or Web64 source checkout is required. The supplied `dist/cyber-mole.d64` is also ready to play without building. On a C64, load `CYBER-MOLE` from device 8 and `RUN`.

The resident target may report **"game uses KERNAL-managed zero page while KERNAL visibility is enabled."** This is a conservative warning about its declared `$e0–$e7` scratch, not a build error. Normal execution banks KERNAL out; the game reconstructs scratch after its explicit ROM disk boundaries, and its IRQ does not use those bytes. Keep this ownership rule when editing. Do not remove the reservation just to silence the warning. See `LOADER.md`.

Use PAL and normal speed. True-drive VICE with a 1541-II has been verified; physical C64/1541-II testing remains separate. An old exported disk does not change when you edit the project.

## Controls and objectives

Use joystick port 2.

- Move in four directions to drill through data soil.
- Tap and release Fire to switch between cyan and amber.
- Hold Fire and press Up to reverse packet gravity.
- Hold Fire and press Down to retry the room. This costs a life and restores its entry score.
- Match your color to a packet to patch it. Wrong-color packets are dangerous; push them sideways or change color.
- Patch every packet, then enter the exit node.

On the title, **Up opens instructions** and Fire returns. A fresh Fire press starts play. Three reactive sentinels navigate machinery and pursue nearby Bit. Collisions play an electrical shutdown before a protected reboot; repaired packets stay repaired. Retries cannot farm points. Music accelerates during the final twenty seconds.

Below Grid 30, restore numbered registers in order. I and II need downward gravity; III and IV need upward gravity. Odd registers need cyan, even registers amber. Step onto a clutch to switch the drive shaft: powered belts transport packets and drive locks open; reversing gravity reverses belts. Eetu, an older maintenance mole, seeks unpatched data and backfills abandoned floor without erasing objectives. Arrival in a new region restores one life, up to five.

In the Master Clock chamber, patch a packet, acknowledge the next register, then repeat. With all four systems restored, enter the central console and press Fire.

## Edit entirely in Web64

- **Char / Block / Map Editors:** edit native artwork and the four map planes. Structure and Color RAM control presentation; material IDs control gameplay. Preserve material, starts, objectives and bank headers for a presentation-only change. All original thirty solutions remain valid in this version.
- **Sprite Editor:** edit gameplay, death and acting frames while retaining the documented sequence groups.
- **SID Tracker:** edit a `.w64sid` song and press Save. Its generated `.sid` and `.inc` files feed normal assembly bank targets. Never rename a SID file to PRG. See `MUSIC.md`.
- **Code / Build Targets:** ordinary `banks/*.asm` sources define native asset placement. The resident program is a PRG; data banks are Packed data targets. Only the boot disk entry is **Runnable (SYS)**; bank entries are **Raw data**.

After editing, save the project and repeat **Build Dependencies → Run Disk**. Native generated includes and map-plane binaries are outputs: edit their parent assets instead. The complete `.web64proj` retains colors, links, animation metadata and build settings. Loose asset binaries are accompanying exports, not a substitute for that metadata; open the project instead of reconstructing it from bare bytes.

## Files and technical notes

- `cyber-mole.web64proj`: complete editable project.
- `main.c`, `*.asm`, `*.inc`, `banks/`, `assets/`: accompanying source and native asset exports.
- `dist/`: playable disk and individual built PRGs.
- `DESIGN.md`: memory, material, animation and bank contracts for editing.
- `LOADER.md`: Web64 loader integration, recovery and hardware limits.
- `MUSIC.md`: native Tracker-to-disk workflow.
- `PERFORMANCE.md`: measured budgets and their limits.
- `CHANGELOG.md` and the two license notices: history and third-party attribution.

All eight gameplay sprite slots animate. Custom characters animate circuitry and machinery; the dithered title logo uses an editable charset and Color RAM map. During fast reads, the game-owned IRQ continues music and the loading presentation. Foreground input pauses during the synchronous transfer; title prefetch is intentionally disabled. See `LOADER.md`.

Five high scores with editable initials are kept in RAM and saved to a writable game disk. Retain/export the **modified mounted disk** to keep scores across browser sessions; re-mastering from the project restores its supplied initial scores.

Original game, artwork, levels, and music created for this example. No imported commercial C64 graphics or tunes.
