# Cyber-Mole performance and support

These measurements describe the supplied game and disk. They are not promises for arbitrary edits or different hardware. Editing and building require only Web64 IDE; no local verification tools are part of this example.

## PAL frame budgets

| Workload | Measured peak CPU cycles |
| --- | ---: |
| Continuous 48-room gameplay, including completion scoring | 11,813 |
| Original 30 remastered rooms, normal/urgent review workload | 8,813 |
| Death lifecycle | 6,390 |
| Three-sentinel update in isolation | 1,411 |
| Final machine's two-cell wake-up | 433 |
| Loading/scene presenter across the supplied songs | 2,428 |

A PAL frame contains 19,656 CPU cycles before VIC-II contention. These sampled workloads remain below a 13,000-cycle instruction-work budget. Cold route construction occurs outside active gameplay. Real-VICE presentation checks separately account for VIC contention: the original thirty rooms maintain normal and urgent cadence with all eight sprite slots animated. The title and final chamber also receive independent cadence checks.

## Loading

Unwarped PAL VICE, true 1541-II emulation, Speed 100, actual IEC data transfers:

| Transition | Seconds |
| --- | ---: |
| First gameplay entry | 9.22 |
| Cached original room | 0.38 |
| Cached deep room | 0.56 |
| Next corporate district | 4.72 |
| Arrival in the archive | 14.22 |

Fast-transfer presenter updates were one PAL frame apart in these samples. KERNAL SAVE and some initialization/error paths can mask interrupts and are not included in a universal fluid-loading guarantee. The hardware loader is synchronous; title input is kept independent by not prefetching there.

The resident occupies 20,399 bytes. The boot PRG is 25,946 bytes including relocation/SDK images. Resident code must stay below the SID bank at $9000; only 81 bytes remain at that boundary, so review placement carefully before adding code. Data banks load on demand; the whole campaign is not held in RAM. See `DESIGN.md` and `LOADER.md`.

## What was verified

The linked 6502 game completes all 48 rooms under joystick-driven control. The original thirty solutions retain identical materials, level metadata, and 8,440 frame-state comparisons after their presentation remaster. CPU tests exercise actual game, score, decoder and cache code; their serial boundary is simulated and is not used as hardware-timing evidence.

Separate true-drive VICE checks cover disk loading, six naturally completed rooms, title/instructions, normal and urgent animation, death, the final machine and ending, high-score round trips, and loading failures/retries. The full 48-room completion authority is the linked-CPU run, not a claimed continuous 48-room VICE playthrough.

The example's public-only packaging changes no game instructions, native asset data, target outputs or disk bytes.

## After an edit

Use Web64's debugger and emulator at normal PAL speed. Check room readability, animation cadence, bank sizes, loading and recovery after rebuilding the disk. A music or graphics edit can increase both compressed size and decode cost. Keep staging limits, decoded scratch, C stack, live banks and SDK placement disjoint. Build diagnostics are useful safeguards, not a replacement for observing the edited game.

The game targets PAL. Independent NTSC tests of the reusable loader do not certify NTSC gameplay. Physical C64/1541-II, alternative drives/ROMs and every full/write-protected disk case still require separate testing.
