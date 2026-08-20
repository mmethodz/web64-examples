# World + Motion and Sprites Actor Camera

Use left/right to compose the Web64 Game Runtime Motion, World, and Sprite modules while preserving their independent runtime closure.

The camera follows the actor at pixel resolution with the v5 buffered renderer and remains stable when it reaches either map edge. The displayed VIC page is immutable and the player sprite remains independent of World rendering.

This example is self-contained: the .web64proj stores the editable native asset wrappers (.w64chr, .w64blk, .w64map, .w64spr), their generated include/build artifacts, and the C source that installs the charset and sprite bytes into VIC-visible memory before running.

## Controls

- Joystick port 2: move/scroll according to the example.
- Release the joystick to see Motion braking and deceleration.
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
