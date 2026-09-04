# Ascender

`ascender.web64proj` is a playable C64-style clone of the one-more-jump platform-climber formula. The stick runner bounces automatically; steer onto the next ledge, climb as the arena scrolls, collect sparks, dodge the roaming hazard, and use one air boost per landing. Each platform pays its landing bonus only once until that platform slot is recycled, so idling on one ledge cannot farm score.

## Controls

- Joystick port 2 left/right: steer
- Fire: start, restart, or spend the current jump's air boost
- Browser gamepads and Web64's numeric-keypad joystick mapping both work

## Hybrid/runtime split

- `main.c` owns the state machine, platform definitions, per-platform score latches, score/lives/level progression, and gameplay decisions.
- Web64 Game Runtime supplies Q12.4 motion integration/clamping, AABB collision tests, three animation players, and sprite-renderer initialization.
- `assets/sprites/ascender.w64spr` is the native editable 12-frame Web64 sprite bank. It contains four-frame `Run`, two-frame `Rise`, `Fall`, `Spark Pulse`, and `Hazard Spin` animations. The runner changes sequence with movement, while the collectible and hazard animate independently.
- `assets/chars/ascender-platforms.w64chr` is the native editable 256-character Web64 charset. Normal, crumble, and spring platforms each have left/middle/right tiles in eight vertical phases, so scrolling advances at pixel granularity instead of exposing character-row seams.
- `ascender-engine.asm` uses the generated runtime include macros, projects runtime state into VIC-II sprites, updates the extended HUD, scrolls/recycles the world, renders per-page dirty platform spans, flips screen pages, polls joystick 2, and plays SID effects.

The top five character rows form a fixed HUD/logo band with `ASCENDER` centered on both character-screen pages. The smaller 20-row climbing window leaves more room for status data. Gameplay is drawn into the hidden `$0400`/`$0800` page and exposed by alternating `$D018` between `$18` and `$28` at raster 248. Each page keeps its own dirty-platform history, the custom charset remains at `$2000`, and the shared Color RAM stays stable. Full-screen transitions remain blank until the new page is ready. The title runner cycles through four strides below all instructional text with a small bob and color pulse. Every respawn moves the hazard to the far side while granting 75 frames of recovery time.

The generated `assets/chars/ascender-platforms.inc` file is disposable and may be rewritten after any Char Editor structural edit. Ascender's application-owned platform ranges therefore live near the top of `ascender-engine.asm`: normal starts at `$80`, crumble at `$98`, and spring at `$b0`. Editing or copying glyph pixels is safe; if those 72 platform glyphs are moved to different slots, update the three assembly constants as well.

## PAL performance

The normal target is raster-paced at 50 Hz. A headless 6502 cycle trace over 180 steady-state frames measured 14,018 cycles average and 18,671 cycles worst case, including active scrolling, recycling, HUD refresh, collision, landing, double-buffer rendering, and runtime animation. That leaves 985 cycles below the 19,656-cycle PAL frame budget. See `PERFORMANCE.md` for the verification contract and page-integrity audit.

The `verify` build target compiles the same game with `WEB64_EXAMPLE_VERIFY=1`, runs 640 deterministic frames without raster waits, and exposes symbols that prove motion, collision, landing, scrolling, paid and blocked repeat landings, all eight runner frames, both secondary animation frames, and clean completion.
