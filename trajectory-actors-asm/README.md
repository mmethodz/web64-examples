# Trajectory Actors — Native Assembly

This is the comprehensive native-assembly companion to [the C example](../trajectory-actors/trajectory-actors.web64proj).

- Eight independent `.w64traj` assets are editable in the Trajectory Editor. Each generates its own raw three-byte-segment `.traj` payload and assembly `.inc` file.
- C enters `asm_trajectory_actors_demo()` exactly once. Assembly owns the PAL loop, eight caller-owned 19-byte trajectory states, scalar stepping of the heterogeneous patterns, animation cadence, and direct VIC-II writes.
- The generated four-frame `trajectory-actors.w64spr` asset is embedded once and copied to `$3000`. Its generated include provides animation frame/duration and palette constants.
- Animation is deliberately application-owned: a small native ticker advances the authored frame sequence with per-actor phase offsets. No trajectory-to-animation binding, actor runtime, game object, or engine-owned behavior is implied.
- Projection reads the full public Q12.4 coordinates, including VIC-II high-X bits in `$d010`; it does not rely on fixed 16-pixel bands.
- CIA2 direction, VIC-bank/screen-base selection, sprite pointers, colors, coordinates, and enable/multicolor registers are explicit application-owned writes.
- `.w64traj` and sprite authoring sources never execute on the C64. Assembly can use the generated `.traj` triplets with Web64's runtime, as here, or parse them with completely custom code.

Open `trajectory-actors-asm.web64proj` in Web64 IDE and run it. The verifier rebuilds both public C ABIs, validates all generated families and exact runtime closure, executes 600 PAL frames, proves public-state/VIC agreement (including high X), observes all four animation frames for every actor, checks copied sprite RAM byte-for-byte, and reports a separate generous ceiling for this intentionally comprehensive scalar demo. It does not reuse or weaken the optimized batch example's performance gate.
