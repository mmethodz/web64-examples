# World Multicolor Scroller

A multicolor character-mode scroller. Use all joystick directions on port 2.

The example uses the exact multicolor values from the native map Color RAM plane and the v5 five-page buffered renderer. The displayed screen remains immutable; Color RAM is presented once at each completed character boundary, from top to bottom ahead of the visible raster, and is untouched on intermediate frames.

This example is self-contained: the .web64proj stores the editable native asset wrappers (.w64chr, .w64blk, .w64map, .w64spr), their generated include/build artifacts, and the C source that installs the charset and sprite bytes into VIC-visible memory before running.

## Controls

- Joystick port 2: move/scroll according to the example.
- The supplied player marker is deliberately hires; character and sprite multicolor modes are independent VIC-II settings.
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
