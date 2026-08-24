# Actor Batch Arena

An unreleased Web64 v2 Game Runtime example built around the open actor-batch pipeline.

The project keeps 32 actors in caller-owned SoA storage and exposes every intermediate stage to C and assembly. Twenty-one actors enter the viewport, four use native two-layer overlay commands, and the PAL mux owns only VIC slots 2–7 while a direct HUD pair remains fixed in slots 0–1. A 32-sample sine table drives horizontal targets; the batch motion kernel integrates the resulting Q12.4 velocities. Base and overlay frame indices advance independently.

Each application-owned frame performs motion, animation tick, culling, coherent X-sweep pair generation, command building, mux submission, and commit explicitly. Four pairs deliberately share one vertical band, creating repeatable priority pressure against six owned slots. Pairs are submitted as one logical command and can never separate. The IRQ wrapper acknowledges the VIC source, advances the game tick only at the mux frame boundary, calls the fast service inside the KERNAL register envelope, and owns chaining/RTI.

`WEB64_EXAMPLE_VERIFY` runs 120 synthetic PAL frames and publishes `verification_complete`, `frame_counter`, `verification_pair_frames`, `verification_independent_frames`, `verification_motion_changes`, and `verification_stable_drop` for automated inspection. Normal builds install the application IRQ and run continuously.

This is a standalone `web64-examples` project, not an IDE template and not a v2 release by itself.
