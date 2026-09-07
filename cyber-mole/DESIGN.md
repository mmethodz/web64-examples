# Cyber-Mole engineering contract

## Editing contract

Open the complete project in Web64 2.4.0 or later. All source, native assets, Build Targets and disk placements are editable there. The accompanying source and asset exports mirror the embedded files, but bare graphics bytes do not contain every editor setting: save the complete project to preserve metadata.

The original thirty rooms remain mechanically authoritative. Presentation-only edits should retain materials, starts, objectives, bank headers, timing and scoring. The eighteen deeper rooms add registers, powered machinery, Eetu and the final core. No local build tools or authoring intermediates are needed; room headers and animation tables are ordinary assembly source in the project.

## Memory ownership

| Range | Owner |
| --- | --- |
| $0400-$07ff | VIC screen and sprite pointers |
| $0800-$0e15 | caller-placed Web64 hardware transport, detection and drive upload image |
| $0f00-$0f12 | Web64 loader lifecycle/status state |
| $1000-$1fff | Act One presentation bank (CPU-readable; VIC still sees character ROM here) |
| $2000-$27ff | installed native charset (title or gameplay) |
| $2800-$2bff | four phases of eight animated character families |
| $2c00-$2fff | native block colors/indices, region palette and animation family header |
| $3000-$35ff | installed Bit, sentinel, packet and repair sprite frames |
| $3600-$37ff | eight native death animation frames |
| $3800-$3bff | sixteen native Bit acting frames in the deep regions |
| $3c00-$3fff | caller-placed Web64 bounded P39/M255 decoder |
| $4000-$8fff | resident code, static state and source graphics |
| $9000-$a5ff | replaceable Web64 SID player/song/effects; selected generated init/play addresses |
| $a600-$afff | caller-placed Web64 packed validator and CRC tables |
| $b000-$b4c7 | four sentinel route fields and cold breadth-first queue |
| $b500-$b8c7 | active art, Color RAM, normalized original material and video planes (page aligned) |
| $b900-$beff | one packed six-room deep district cache, maximum 1536 bytes |
| $bf00-$bfff | serial sector buffer |
| $c000-$c5ff | Act One's six mechanical pages, or one expanded room's four planes |
| $c600-$cdff | native arrival/ending screen and Color RAM |
| $ce00-$ceff | unallocated |
| $cf00-$cf7f | versioned high-score file staging |
| $d000-$dfff | VIC/SID/CIA I/O and Color RAM |
| $e000-$fbff | disjoint decoded transaction workspace under ROM |
| $fc00-$fdff | 512-byte Web64-C software stack, RAM visible with $01=$35 |
| $fe00-$fff9 | caller-placed Web64 raw receive kernel (bounded by the vectors) |
| $fffa-$ffff | private application NMI/IRQ vectors |

The C entry point owns high-level sequencing. Assembly owns game frames, map deltas, sprite projection, BCD scoring and joystick interaction. Web64 provides animation, native score SAVE and the generic hardware-loader implementation through its assembly convenience macros. Decoder ZP $60-$68 and transport ZP $74-$79 are registered SDK ownership; game ZP is $e0-$e7. The stack ABI's $02-$18 range is untouched. Packed reception reuses $b000-$b7ff only while routing/active planes are inactive; the game rebuilds those planes before play. Decoder scratch at $e000 is never live destination data. Normal C/game execution uses $01=$35; only ASM KERNAL boundaries temporarily expose ROM. The game's $e0-$e7 KERNAL-scratch warning remains visible: code reconstructs this scratch after ROM calls, and its IRQ does not use it. Boot images may extend above $9000 but must end before the SDK image at $a600; permanent code remains below $9000. No scrolling or sprite multiplexer is needed.

## Sentinel AI and life states

Three sentinels use different roaming goals and can move in all four directions. Four small flow fields are computed once per grid around hard walls, then each AI decision takes a single bounded step. A clear row/column sightline within three cells overrides roaming with pursuit. Dynamic guard occupancy and spawn exclusion are checked at the step, so the actors do not follow an immutable trajectory. Sentinels can hover over undug soil but do not alter the map. Movement is no faster than one tile per eighteen PAL frames, slower than Bit's eight-frame tile movement.

`game_mode` is 0 for cold screens, 1 for play, 2 for death and 3 for a staged scene. A hit or timeout debits one life and starts a native, once-playing death animation (48 frames by default, derived from its native duration symbols). The last life still receives every frame. During shutdown, physical actors, input and the countdown freeze while all visible sprites, circuits and SID playback keep animating. Collision recovery retains score/packets; timeout/manual retry restores the entry grid/score. A collision on the timer's expiry tick takes the timeout/retry path for the same single life, avoiding another death immediately on reboot. Respawn shields last 125 frames, freeze sentinels initially, exclude a five-by-five arrival zone and relocate any sentinel already inside that zone back to its map start. Held fire cannot spend another life on recovery.

## Level and disk contract

Each grid is a 20 by 10 native block map. **Material IDs**, not structure/block IDs or generated labels, govern gameplay. Act One `GRID1..5` retain their exact original six 256-byte mechanical pages (200 material bytes + 56 header/name bytes). `SKIN1..5` at $1000 hold six 600-byte triplets: structure, Color RAM, video-matrix. At offset 3600 a CYA/version/district/six-room signature precedes padding to 4096 bytes. Both banks load only on district changes; retries reuse them.

Expanded `ROOMA..ROOMR` describe four 256-byte pages at $c000: structure/header, Color RAM, video-matrix, material. `CACH1..3` group six such native sources into independent 1024-byte packed blocks, all restored at $c000. Only one room is expanded at a time; its packed district remains at $b900. Individual room targets remain available for inspection/editing. `GLYP0..3` replace native visual banks, `TUNE1..3` replace the original `PULSE` SID bank, and `SCNE1..4` contain native scenes. Data targets emit W64X containers through the IDE, placed as Raw data without executable wrappers. Only `CYBER-MOLE` is boot-wrapped. No disk operations run in an active gameplay frame. Failure remains on a retry screen; incomplete transfers cannot overwrite the active presentation. See `LOADER.md` for IRQ/serial ownership.

Each material map contains one Bit start (16), one closed exit (5), and four packet starts (10 cyan / 11 amber). Act One has three sentinels (17); deeper teaching rooms begin with fewer. Steel (2) and racks (3) are impassable; soil (1) is drilled on entry; cyan/amber gates (8/9) require the matching phase. Preserve the solid perimeter and gameplay-critical objects when editing an authoritative puzzle. Open circuits (0), vents (4), coils (7), live-wire graphics (12), relays (13), coolant (14) and warnings (15) are traversable. Coils are signposting; fire + up controls gravity anywhere.

Deep registers use material 18..21 in order, requiring phase `(ordinal & 1)` and gravity `(ordinal >> 1)`; a successful latch becomes 25 and scores once. Clutches 22/26 toggle the motor on entry, 23/24 convey packets when powered (reversed by gravity), and 27 is a powered drive lock. Eetu shares actor slot 3, seeks active packets and backfills abandoned plain floor without modifying objectives or Bit's spawn. In the final chamber, each packet must be acknowledged by the next register before another repair; a bounded color reveal wakes the machine before the console accepts Fire. Region entry replenishes one life (cap five). Expanded room clocks reset on entry/retry so loading or scene length cannot change opening physics; Act One timing is unchanged.

## Editing graphics

`grid.w64chr` holds the font and initial tile graphics. Every block is four characters in row-major order; block ID n initially refers to characters `64 + 4*n` through `67 + 4*n`. The renderer reads the native blockset rather than assuming that character arrangement for static drawing.

`grid-animation.w64chr` makes the live circuit phases editable in the Char Editor. Its first 128 characters contain four phases of eight tile families, four consecutive characters per tile. The family order is open circuit, rack, open exit, coil, cyan gate, amber gate, live wire, relay. Phase p / family f starts at character `p*32 + f*4`. The remaining 128 characters are spare. Runtime animation installs these phases into the corresponding original tile glyph slots; retain those slots for animated blocks.

The title is a native **character** map linked to `title.w64chr`, with a native Color RAM plane (`title.color.bin`). Edits to map colors therefore survive editor save/regeneration. Sprite pixels and the six four-frame animation sequences remain native sprite-bank data. Assembly consumes the native binary graphics and generated animation include symbols directly, so in-IDE pixel and sequence-duration edits reach the game without re-authoring. Keep the six four-frame looping sequences and their contiguous frame groups; packet/guard phases are staggered within those groups. Repair sparks loop only during their twelve-frame display window.

`death.w64spr` is a separate eight-frame bank, with six PAL frames per phase. `instructions.w64map` shares the title charset and has its own native Color RAM plane. The title redesign replaces the earlier enlarged-font logo and technical captions. SID subtune 0 is the original music, 1 is repair, and 2 is the nonlooping 32-frame shutdown effect. Both effects temporarily borrow voice three.

The title's dithered steel/cyan/gold artwork occupies 288x48 physical pixels. Its Text Multicolor cells use black, dark gray, shared cyan, and one local color. The 191 logo glyphs (including blank), one circuit terminal and the first 64 font codes fit in the existing 2 KB native charset. Edit these pixels in Char Editor and their placement/colors in Map Editor. This is bitmap-style artwork encoded as a character map, not VIC bitmap display mode. No conversion step or private pixel format is required.

The title contains only `UP - INSTRUCTIONS` and `FIRE TO START` beneath three animated actors. Bit alone is expanded in both axes; the manual restores its previous sprite geometry, and returning to the title restores the hero layout. Circuit rails and a restrained two-color hires prompt animate without touching logo cells. All title assets remain resident, leaving title input independent of disk I/O.

All nine charset profiles are Text multicolor / Per block, not Per project. Character colors preserve hires text (0..63) and multicolor art; animation banks are entirely multicolor. Block previews use block colors; map Color RAM is an explicit override. Merely selecting Text multicolor does not force every glyph into multicolor: Color RAM bit 3 is the C64's mixed-mode selector. The supplied project retains the correct metadata so initial previews need no mode toggle.

The corporate remaster adds blocks 18..47 in previously unused glyphs, retaining the original 136-glyph and eighteen-block prefixes. Recessed lanes remain visually open; machinery keeps solid silhouettes; all interactive tiles retain their identity. New live routing/vent cabinets reuse existing animated rack glyphs, costing no extra frame copies. Unchanged cells draw native structure/colors; drilling, latches and other material mutations select canonical semantic artwork. The video plane is preserved but has no bitmap-color interpretation in text mode.

Edit native map planes for room presentation and native material for intentional puzzle changes. Room headers live in `banks/grid-*.asm` and `banks/room-*.asm`: signature/version, district/index, seconds, enemy period, gravity, phase, optional deep mechanics, and a 20-character screen-code name. Deep cache sources contain the same six room records; update the matching `banks/cache-*.asm` header too if intentionally changing room policy. Native INC metadata regenerates through Web64; bank sources `.incbin` the editable binaries directly. `generated.inc` is a supplied game-owned geometry/animation table, not an editor-generated asset include. Edit it as source when changing the documented game layout; never re-author unrelated assets to build.

## Editing music and mastering

The four `.w64sid` sources use ordinary New W64SID include defaults. Tracker
Save owns each generated `.sid`/`.inc` family. Four native assembly targets
slice only `*_c64_data_offset` / `*_c64_data_size` from those containers, then
the native Packed data target losslessly packages their decoded bytes. Raw
data logical outputs become `PULSE` / `TUNE1..3`. No `.prg` music source is
exported separately. `music.inc` derives exact lengths and entry points from
the regenerated includes, then selects cold-installed JMP call gates after
validation. Those cost three cycles per SID call, with no hot table lookup.
The loader rejects wrong addresses, truncated or oversized songs without
enabling playback. See `MUSIC.md` for UI creation, editing and export steps.

## High-score display

The high-score screen owns its screen codes and Color RAM throughout disk I/O.
The disk boundary saves the inherited KERNAL message policy, calls SETMSG with
zero, then restores the policy on exit. ROM SAVE must not print at a stale
editor cursor or introduce multicolor character colors. Every score-status
transition clears its complete row and restores hires cyan before drawing the
new text; score ranking, initials, checksums and persistence remain unchanged.

## Fairness

Packet repairs are removed from active state and score once. Digging does not award repeatable points. Retry and timeout restore the entry score; normal recovery retains repaired packets. Gravity and color changes are edge-triggered. Respawn protection temporarily prevents hazard hits. A closed exit becomes usable only after the last packet is patched. High scores saturate at 999999 instead of wrapping.

## Visual direction

Black substrate, electric cyan circuitry, amber warnings, steel-blue machinery and deliberate negative space. A large custom pixel logo anchors the title; the compact instrument panel leaves 320 by 160 pixels for the grid. Animated Bit, segmented sentinels, pulsing packets and repair sparks share eight physical sprites. The five districts change structural silhouettes, accent palettes and hazards while retaining legible tile semantics.
