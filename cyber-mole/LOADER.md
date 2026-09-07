# Web64 hardware-loader integration

Cyber-Mole consumes the Web64 2.4.0 hardware-loader runtime through
`web64/loader.inc` and caller-placed read-only SDK images. It no longer owns
private copies of transport, drive startup, CRC or decompression code.
The implementation retains Covert Bitops 2.29's one-bit/long-filename protocol
and the bounded Exomizer P39/M255 contract. Upstream notices remain in
`FASTLOADER-LICENSE.md` and `PACKED-DATA-LICENSE.md`; the SDK includes carry them
too. No emulator-side file shortcut is shipped.

## Authoring and disk mastering

Native editable graphics, maps and SID Tracker sources feed ordinary assembly
data roots and IDE Packed data targets. Disk/Media places their exact Raw data
PRG outputs on one D64; only CYBER-MOLE receives a Runnable/SYS wrapper. Native
Build Dependencies / Run Disk rebuilds modified source and included assets.
No external compressor, assembler, private JSON or prepacked source is needed.

Packed targets use staging origin $b000 and maximum size 2048 bytes. CACH1-3
contain six independent 1024-byte records, all restored at $c000, with a tighter
1536-byte maximum. They derive from the same native room planes as the editable
individual-room targets. SCORES remains a raw 64-byte payload at $cf00.

## Application policy versus runtime

`loader.asm` adapts SDK statuses to the existing game retry flow and checks the
expected application bank origin/shape. `room-cache.asm` owns district identity,
the six-room cache and room selection. Region order, music installation,
cutscenes, score UI and title policy remain application responsibilities.
The SDK knows none of these concepts.

The game calls synchronous staged read, checks its PRG origin, then calls the
SDK unpacker with explicit destination and scratch capacities. All selected
records decode into disjoint scratch and pass decoded CRC before the first
live write. Even a damaged stream with a recomputed container checksum leaves
the live bank byte-identical. Missing, short and oversized files also stay on
the retry screen. A cache is made resident only after successful validation of
the first selected room; subsequent selections are independently checked.

## Owned memory

| Range | Purpose |
| --- | --- |
| $0800-$0e15 | SDK transport, startup and drive upload image |
| $0f00-$0f12 | SDK status/lifecycle state |
| $3c00-$3fff | SDK bounded decoder envelope |
| $9000-$a5ff | Replaceable SID bank; original song ends at $a3ed |
| $a600-$afff | SDK validation and CRC tables |
| $b000-$b7ff | Incoming packed staging, reusing inactive route/plane RAM |
| $b900-$beff | Application-owned deep district cache |
| $bf00-$bfff | Caller-provided 256-byte serial sector page |
| $e000-$fbff | Decoded transaction scratch, never active presentation |
| $fc00-$fdff | Existing 512-byte C software stack, relocated |
| $fe00-$fff9 | SDK raw receive kernel envelope |
| $fffa-$ffff | Application NMI/IRQ vectors |

Normal execution uses $01=$35, including C stack access. ASM-only KERNAL
boundaries temporarily map $36 and restore $35 before C resumes. Boot images
are copied before SID banks reclaim their source storage. Native placement
checks guard every logical SDK range, boot image and C stack. Build-time checks
also enforce the resident/SID boundary and packed/cache capacities.

Decoder $60-$68 and persistent transport $74-$79 zero page are registered SDK
ownership; $fb-$fe is non-reentrant call scratch. The game uses $e0-$e7 and
reconstructs that scratch after ROM calls. Its KERNAL-risk warning remains
visible rather than disabling memory governance. The IRQ never uses that
game scratch and saves/restores A/X/Y plus $fb-$fe. The C ABI's $02-$18 pseudo-
registers are unchanged.

## IRQ, music and lifecycle

A caller-owned raster IRQ at line 248 increments `loader_ticks` and advances
the unchanged native SID player and bounded Bit/scene presenter. RAM and
KERNAL-compatible entries cover both mappings; a RAM NMI handler handles
RESTORE while ROM is out. Foreground loading never re-enters the music or
animation runtime. No gameplay timer advances during loading.

The transport's four settling NOPs and serial-bit loop are unchanged. Fast
waits and decode/commit allow the IRQ to run. The SDK touches CIA2's IEC lines
while preserving VIC-bank bits; the application does not compete for the bus.
The caller's persistent tick word provides the dead-peer watchdog. Its observed
disabled-drive recovery is about 13 seconds; this is not a universal hard
deadline for arbitrary KERNAL/ROM faults or unsupported hardware.

Score SAVE calls SDK shutdown first, retains the KERNAL SAVE result separately,
then explicitly reinstalls drive code. Reads through stale state return
NOT_INITIALIZED. Reinstall failure leaves loading unavailable until a fresh
retry. SAVE is not a fast saver: its ROM handshakes and some reinstall paths
can mask interrupts. Console messages are suppressed/restored and complete
hires score-status rows replace old text. Scores remain in RAM on failure;
browser users must retain/export the writable disk for cross-session storage.

Title prefetch stays disabled. IRQ-friendly is not mainline-cooperative: a
synchronous disk read would suspend title joystick/manual navigation. No fake
poll API or speculative title load is introduced.

## Verification and support

The independent Web64 SDK suite proves native C/ASM linkage, memory ownership,
raw/packed failures, scratch transactions, save/reinstall and generic IRQ/SID
continuity on PAL and NTSC true-drive VICE. The game adds all 48 joystick-driven
solutions, the immutable original 30-room/8440-state comparison, native asset
editing, endgame/1897 path, scores, title and region/cache integration checks.

Loading measurements use unwarped PAL x64sc with true 1541-II emulation and
actual IEC transfers. The initial boot-file transfer is excluded. Separate
checks cover the runnable boot wrapper, presentation, score persistence,
drive-error recovery and real VIC cadence. See `PERFORMANCE.md` for measured
timings, sizes and the distinction between gameplay and transport evidence.

The game is PAL; independent NTSC SDK proof does not certify NTSC gameplay.
Physical C64/1541-II, alternative ROMs/devices and every full/write-protected
disk failure still require their own hardware tests. The supplied image is
a snapshot: export a new D64 in Disk/Media after editing the project.
