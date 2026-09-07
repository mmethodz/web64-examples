# Native SID Tracker to multi-load disk

The editable source is `.w64sid`. Tracker **Save** regenerates a standard PSID
`.sid` file and its `.inc` declarations; it does not replace the source. The
PSID header is 124 bytes, whereas a raw PRG has a two-byte load address. Thus
the SID file is 122 bytes larger. Renaming it to `.prg` is not a conversion.

Cyber-Mole uses the ordinary IDE workflow all the way to the disk. No script,
project-JSON edit, hand-made asset metadata or external converter is required.

## Edit and run the supplied project

1. Edit a song in SID Tracker and press **Save**.
2. In **Disk/Media**, use **Build Dependencies**, then **Run Disk** (or export
   the rebuilt disk). **Download File** exports an individual mastered PRG.
   This also rebuilds the main target, whose size and entry-point tables
   consume the updated music includes.
3. Boot `CYBER-MOLE` from the rebuilt image. Mounting the old disk or pressing
   the emulator's play/resume button does not rebuild disk files.

Do not export or rename music PRGs by hand. There are no music PRG source files
in the project tree. They are **Build Targets** outputs.

## Create the same wiring inside the IDE

1. Create/save `assets/music/substrate.w64sid` in SID Tracker. On **Info**, set
   Driver address and Music data address to `$9000`, clock PAL. Keep the normal
   generated include settings. Save produces `substrate.sid` and `substrate.inc`
   with the normal filename-derived `substrate_sid` symbols.
2. In **Code**, create `banks/music-substrate.asm` containing:

   ```asm
   .include "assets/music/substrate.inc"
   .incbin substrate_sid, "assets/music/substrate.sid", substrate_sid_c64_data_offset, substrate_sid_c64_data_size
   ```

3. In **Build Targets**, create a **Packed data (Exomizer)** target, choose that assembly root/input,
   select Web64 Native Assembler, disable C, set origin `$9000`, and output name
   `music-substrate.prg`. Set **Staging address** to `$b000`, **Block size** to
   `0` (whole song), and **Maximum staged bytes** to `2048`. The installed song
   must end at or before `$a600`, where the SDK packed validator begins.
4. In **Disk/Media**, create a D64 and add that **target output** as a PRG logical
   file named `PULSE`. Select **PRG mode > Raw data** for this data placement.
   Only the `CYBER-MOLE` boot file uses **Runnable (SYS)**. Place the logical
   file on the disk with **Place File**.
5. Repeat for `archive`, `works`, and `core`, placed as `TUNE1`, `TUNE2`, `TUNE3`.
   The resident `music.inc` uses their generated size and entry-point symbols.

The assembler's native `.incbin` offset/length operands select the C64 payload
without copying the PSID header. Native assembly supplies the decoded origin;
the Packed data target creates a checked W64X container with its own staging
address. Disk/Media places those packed bytes unchanged into the image. The
game's checked decoder restores the original SID bytes before playback. Other native
graphics/map banks use the same Code -> Build Targets -> Disk/Media workflow;
their bank layouts are ordinary assembly source, not private project fields.

## Game-side music contract

Keep each driver loaded at `$9000`; payloads must fit before the SDK validator
at `$a600`; the packed container must fit the loader's 2048-byte staging capacity. The original music
is subtune 0, repair 1, shutdown 2; deep songs also use register effect 3 and ending
music 4. Preserve these roles when editing the game soundtrack.

Sizes and init/play addresses are read from native generated includes. The
resident selects entry points only after a successful exact-length load; two
absolute-JMP call gates add three cycles per SID call, with no per-frame lookup.
Wrong-address, oversized, missing or truncated banks never enable playback.
Changing a source's filename requires updating normal source references, just
as renaming any included charset or assembly file does.

Use Web64 2.4.0 or later for the hardware-loader SDK and Packed data targets.
Save the complete project to retain editor metadata and build/disk settings.
Older IDE versions must not re-master this project.
