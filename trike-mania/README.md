# Trike Mania

Trike Mania is a complete four-racer Commodore 64 championship created for Web64 IDE. Teddy bears race tricycles around three editable multicolor circuits, with distinct driver statistics, AI rivals, honey boosts, ramps, oil hazards, barriers, three-lap races, results, championship points, and replay.

## Controls

- Joystick port 2
- Left/right: steer
- Up or fire: pedal
- Down: brake
- Fire: confirm menus

## Championship

1. Teddy Park - broad garden bends, a honey boost, a dithered bridge ramp, mud, hay bales, flowers, and a duck pond
2. Picnic Panic - a technical crossing route with jam boosts, basket ramps, spilled jelly, picnic tables, lemonade, and sandwich landmarks
3. Toybox Turbo - the sharp final circuit with rocket boosts, launch ramps, spinning tops, block walls, trains, and construction chicanes

Choose Bramble the Trailblazer, Coco the Tactician, Patches the Steady Ace, or Tumbles the Daredevil. Each has an individual portrait, face, accessory, race color, and meaningfully different speed, acceleration, steering, and grip. All four teddies compete in every race.

## Editable native assets

- `assets/chars/trike-mania.w64chr`: custom HUD font and multicolor track charset
- `assets/blocks/*.w64blk`: three separate editable 2x2 themed block vocabularies with curved road edges and dithered ramps
- `assets/maps/*.w64map`: three editable track maps with material planes
- `assets/sprites/teddy-trikes.w64spr`: 33 multicolor frames: 16 pedal, eight jump, four spin, one shadow, and four teddy portraits, plus nine named animation sequences

All circuits are static 40x20-character worlds below the five-row HUD, so the renderer uses per-cell Color RAM without any scrolling tax. Each map has its own visual layout, block vocabulary, material plane, special-surface placement, start grid, and 16 ordered checkpoints.

## Runtime composition

The game explicitly composes Web64 Motion, Collision, Animation, Direct Sprite, Actor, and World modules. The static circuit and its Color RAM are rendered only when a race begins. Ordinary race frames update four subpixel racers, ordered checkpoints, AI, material interactions, animation frames, HUD deltas, and eight hardware sprites.

The project uses Web64-native c64lib VIC-II names for hardware-facing setup. A baseline first proved the generic C composition too expensive in this compiler configuration: update 79,491 cycles, full HUD 247,399 cycles, and sprite rendering 15,638 cycles. Only then were those fixed four-racer frame operations fused in `src/race-hot.asm`; track/world construction, actor storage, animation data, collision setup, and all game flow remain in C and the Game Runtime. Racer contact pairs are distributed deterministically across frames so collision behavior remains complete without paying for all six AABB pairs in one frame.

## CPU and SID budget

PAL provides 19,656 CPU cycles per frame. Verification reserves 2,200 cycles for an ordinary SID player call and 3,200 cycles on the worst frame. The measured worst game frame is 8,607 cycles; with the worst SID reserve it uses 11,807 cycles and leaves 7,849 cycles free. See `PERFORMANCE.md` for reproducible evidence.

Every planned music or sound trigger is marked with a `TODO MUSIC` or `TODO SFX` comment in `main.c`. The per-frame placeholder is `sid_player_todo()`.

## Build targets

- **Trike Mania**: playable release game, starting at `$2d00`
- **Trike Mania Verification**: deterministic twelve-case exercise target covering every teddy on every track, boost/jump/oil behavior, four natural checkpoint-validated finishes per race, results, and cycle markers
- **Visual Evidence** targets: deterministic title, selection, and three-track screenshots used by the repository acceptance route

The memory plan keeps the software C stack at `$0800-$09ff`, reserves `$1000-$1fff` for the future SID, stores the charset at `$2000-$23ff`, stores 33 sprite frames at `$2400-$2c3f`, and places code at `$2d00+`. Startup selects processor-port value `$35`, exposing RAM beneath BASIC/KERNAL ROM while keeping C64 I/O visible. The generator rejects any target that would reach the C64 I/O window at `$d000`.
