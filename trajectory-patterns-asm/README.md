# Trajectory Patterns — Optimized Assembly

This is the native hot-loop companion to the C-oriented `trajectory-patterns` example.

- C enters `asm_trajectory_demo()` once and performs no per-frame work.
- Eight contiguous caller-owned `Web64TrajectoryState` records share one immutable four-segment pattern.
- One `_web64_trajectory_step_batch_fast` call advances eight lockstep states while the option bits provide all four X/Y mirroring combinations.
- The assembly reads the published Q12.4 state layout and writes owned VIC-II sprite coordinates directly. Each lane is intentionally constrained to a compile-time 16x16 band, allowing the projection to combine the public low byte with a constant high nibble. Because the shared pattern is axis-aligned and lockstep, the public pre-step segment index also identifies the only coordinate that changes that frame. The verifier proves both specializations; a game whose actors cross bands or whose pattern mixes axes must use a generic 16-bit projection. No private semantic mirror is introduced.
- The purple border interval measures the complete hot workload: one exact-window batch call, trajectory execution, public event writes, changed-axis Q12.4 projection, and all eight changed sprite coordinates. It is intentionally much smaller than the C example's repeated C call/marshalling interval.
- The assembly uses the generated `web64/trajectory.inc` helpers for immediate arguments, one-time batch-window preparation, packed segment/pattern emission, and caller-owned state/event storage. These are source macros only: their emitted instructions and data are byte-identical to the handwritten ABI sequence, and the stable batch window is still prepared outside the frame loop.
- All sprites remain in motion on a closed path. Sprite payload placement at `$3000`, pointer-table placement at `$07f8`, and hardware ownership are explicit in `trajectory-demo.asm`.

The example includes only the family-owned `web64/trajectory.inc`, which provides the standard `web64_rt_prepare_*`/`web64_rt_call_*` helpers plus the trajectory layouts and constants. The optional `web64/runtime.inc` remains a whole-registry ABI catalog. Exact linkage adds only `game-trajectory.asm` and `game-trajectory-batch.asm`.

Open `trajectory-patterns-asm.web64proj` in Web64 IDE and run it. The verifier executes 600 PAL frames under both Web64 C ABIs, checks exact closure and public-state/VIC agreement, rejects a complete hot interval above the 20% PAL acceptance target, and retains 25% as the absolute rejection ceiling. Unlike the runtime-only benchmark, this visual gate also includes the example's explicit VIC projection work.
