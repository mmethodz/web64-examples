# World Bidirectional Scroller

Use all joystick directions to scroll the camera over a wider and taller native map.

The v5 renderer maintains a current page plus four prepared cardinal neighbors. The displayed page is never shifted or rebuilt. Each completed character boundary presents the exact native per-cell map colors in Color RAM; intermediate frames leave Color RAM untouched, and every clamped edge stops without repeating its terminal strip.

This example is self-contained: the .web64proj stores the editable native asset wrappers (.w64chr, .w64blk, .w64map, .w64spr), their generated include/build artifacts, and the C source that installs the charset and sprite bytes into VIC-visible memory before running.

## Controls

- Joystick port 2: move/scroll according to the example.
- The direction remains locked until the current eight-pixel character transition is complete.
- Browser gamepad polling is enabled; the numeric keypad joystick also remains available.

## Included files

- assets/blocks/world.inc
- assets/blocks/world.w64blk
- assets/chars/world.inc
- assets/chars/world.w64chr
- assets/maps/world.color.bin
- assets/maps/world.inc
- assets/maps/world.material.bin
- assets/maps/world.w64map
- assets/sprites/player.inc
- assets/sprites/player.w64spr
- TEMPLATE.md
