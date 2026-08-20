# World Static Map

Move the sprite with joystick port 2. Press fire to mutate a visible map cell.

This static example deliberately uses the per-cell Color RAM mode: the colors visible on screen come from the editable native map color plane.

This example is self-contained: the .web64proj stores the editable native asset wrappers (.w64chr, .w64blk, .w64map, .w64spr), their generated include/build artifacts, and the C source that installs the charset and sprite bytes into VIC-visible memory before running.

## Controls

- Joystick port 2: move the hires player sprite.
- Fire: mutate one visible character, Color RAM, and material cell.
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
