# Mirror Pulse

Mirror Pulse is a complete six-course C64 puzzle game built around Web64's optimized multicolor bitmap line routine and a finite pulse bank. Arrange and rotate mirrors before spending a shot: the game never exposes a free live beam preview.

## Objective

Guide each discrete laser pulse from the emitter to the receiver. A shot snapshots the current mirror layout, spends one pulse, and reveals the reflected route one segment at a time. Mirror editing is locked until the pulse has finished.

Beam-hit powerups latch when collected and cannot be farmed:

- Diamond: **250 points**.
- Plus box: **3 additional pulses**.
- Hourglass: **30 additional seconds**.

Each course grants new pulses on entry and has a stage-specific three-to-five-minute clock. Reaching the receiver awards 1,000 points plus ten points for every remaining second. Completing all six courses also converts every unused pulse into 50 points. Running out of time or pulses ends the campaign.

## Controls

Keyboard:

- `W` / `A` / `S` / `D`: move the selected mirror on the course grid.
- `Q` / `E`: select the previous or next mirror.
- `R`: rotate the selected mirror between `/` and `\`.
- `Space` or `Return`: fire one pulse.
- `X`: restore the course's initial mirror layout without restoring time, pulses, or collected powerups.
- `H`: open the high-score table from the title screen.

Joystick or mapped gamepad on port 2:

- Direction: move the selected mirror.
- Fire: rotate it.
- Fire + left/right: select the previous/next mirror.
- Fire + up: fire one pulse.
- Fire + down: restore the initial layout without a refund.

The Web64 keyboard-joystick mapping and a browser gamepad feed the same port-2 controls, so the complete campaign and three-initial high-score entry are operable without a physical joystick.

## Implementation notes

- The game uses a 160×200 multicolor bitmap at `$2000`, with palette screen memory at `$0400` and program origin `$4000`.
- The PRG crosses the `$A000–$BFFF` BASIC ROM window, so its Web64 C startup selects processor port `$36`: RAM is visible there while KERNAL ROM, I/O, keyboard scanning, and joystick access remain available.
- The course background is retained: walls, emitter, receiver, and fixed HUD labels are drawn once. Mirrors, selection frames, powerups, and laser segments are reversible XOR overlays, so moving or rotating a mirror touches only its old and new bounds.
- HUD values use independent dirty fields. An unchanged refresh performs no bitmap writes; a clock tick redraws only the three-digit time field and never rewrites Screen RAM or Color RAM.
- Axis-aligned boxes and fills use the specialized fast horizontal/vertical line paths, while mirror diagonals and reflected beam segments use `web64_bitmap_line_fast()`. A tiny bitmap font keeps the HUD and menus in the same surface without corrupting bitmap palette RAM.
- Ray traversal is integer-only and restricted to four cardinal directions. `/` and `\` mirrors apply deterministic direction lookup tables; a bounded 16-segment limit stops reflection loops.
- Long reflected routes are rendered one segment per PAL frame rather than stacking multiple expensive lines into one frame.
- Course solutions are emitted only when `WEB64_EXAMPLE_VERIFY` is defined. They are absent from the normal game build.
- The five-entry high-score table and initials are retained for replay within the running program. This example deliberately performs no disk writes, so scores reset when the program is reloaded.

Open `mirror-pulse.web64proj` in Web64 IDE and run the `Mirror Pulse` target.
