# World Vertical Scroller

Use up/down on joystick port 2 to scroll the camera. Left/right moves only the sprite marker.

The v5 renderer never shifts the displayed screen. It prepares neighboring screen pages offscreen across the eight fine-scroll frames and selects a complete page in the lower border. The same boundary presents the exact native per-cell map colors in Color RAM from top to bottom ahead of the visible raster. Intermediate frames do not rewrite Color RAM, and clamping never repeats the terminal row.

This example is self-contained: the .web64proj stores the editable native asset wrappers (.w64chr, .w64blk, .w64map, .w64spr), their generated include/build artifacts, and the C source that installs the charset and sprite bytes into VIC-visible memory before running.

## Controls

- Joystick port 2: move/scroll according to the example.
- Left/right: move the hires sprite marker without changing the camera.
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
