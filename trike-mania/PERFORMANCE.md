# Trike Mania frame budget

The generator compiles the release, verification, and visual-evidence targets before publishing this project. The dedicated verification route profiles production-equivalent race frames after initializing all four racers.

Budget contract:

- PAL frame: 19,656 cycles
- Ordinary SID reserve: 2,200 cycles
- Worst-case SID reserve: 3,200 cycles
- Maximum game-logic/render budget on a worst frame: 16,456 cycles
- Static map rendering, title construction, selection construction, and results construction occur outside the race-frame loop
- Baseline generic C update: 79,491 cycles
- Baseline full HUD: 247,399 cycles
- Baseline direct sprite composition: 15,638 cycles
- Fused four-racer update plus distributed contact maximum: 6,801 cycles
- Dirty HUD writer maximum: 591 cycles
- Eight-sprite race renderer maximum: 1,090 cycles
- Complete measured worst game frame: 8,607 cycles
- Worst game frame plus 3,200-cycle SID reserve: 11,807 cycles
- Remaining PAL worst-frame headroom: 7,849 cycles
- Bespoke assembly was accepted only after those baseline measurements demonstrated the breach

Acceptance also completes one natural, ordered-checkpoint circuit with all four active racers for every teddy/track combination. A timeout fallback is present for the playable game but is forbidden by the verification target.

Reproduce with `npm run test:trike-mania` and `npm run test:trike-mania-visual` in the Web64 IDE repository.
