# Game Runtime World Platformer

Move with left/right and jump with fire or up. The camera follows the player over a multicolor map. The example composes the independently linked Game Runtime World, Motion, Collision, and Sprite modules.

The example starts grounded on a material-map floor with several reachable platforms. Game Runtime Motion supplies acceleration, braking, gravity and the jump impulse; Collision supplies platform probes; the v5 buffered World renderer follows the player without touching the active VIC page; and Sprite Runtime keeps the player hires over the multicolor character map.

This example is self-contained: the .web64proj stores the editable native asset wrappers (.w64chr, .w64blk, .w64map, .w64spr), their generated include/build artifacts, and the C source that installs the charset and sprite bytes into VIC-visible memory before running.

## Controls

- Joystick port 2 left/right: accelerate and brake.
- Fire or up: jump while grounded.
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
