# Trajectory Actors (C)

This project is a complete C-side example of Web64's first-class trajectory and sprite authoring assets. Run **trajectory-actors.web64proj** to see eight phase-staggered animated VIC-II sprites follow eight different paths.

## What is editable

- Each file under **assets/trajectories/** with the **.w64traj** extension is a distinct editable Trajectory Editor asset. Every actor therefore has its own local path, timing, authoring anchor, and runtime-default preview.
- Each authoritative **.w64traj** deterministically generates a raw **.traj** and a companion **.inc**. The C program consumes the generated descriptors through **assets/generated.h**.
- **assets/sprites/trajectory-actors.w64spr** is an editable four-frame multicolor sprite asset. Its **orbit-pulse** animation metadata records the authored 4/4/4/4 PAL timing.

## Runtime ownership and purity

The **.traj** payloads remain only compact three-byte **dx, dy, duration** segments. Authoring anchors, appearance references, viewport state, and animation metadata never enter those runtime bytes. The program supplies every actor's starting position, owns eight public **Web64TrajectoryState** records, performs checked initialization once, and uses the fast trajectory step thereafter.

Appearance preview is not runtime binding. The **.w64traj** files reference the sprite animation so the Trajectory Editor can preview it, while this application deliberately constructs its own **Web64AnimationStep**, sequence, bank, and shared player. Per-actor phase offsets remain application-owned and avoid seven redundant per-frame animation ticks. The program copies the generated sprite descriptor to **$3000**, explicitly selects its CIA2/VIC bank and **$0400** screen pointer table, applies the authored multicolor palette, and renders the actors directly with **web64_sprite_render**.

Web64 exact-links only the trajectory, animation, direct-sprite, and typed asset-copy modules actually called here. There is no actor framework, scene, map, camera, IRQ, hidden allocation, or engine-owned gameplay state.

The companion **../trajectory-actors-asm/trajectory-actors-asm.web64proj** demonstrates the same eight editable trajectory families and animated sprite asset from assembly, including direct use of the generated **.traj/.inc** products.
