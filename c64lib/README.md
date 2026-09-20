# c64lib compatibility examples

These native Web64 projects deliberately demonstrate the SDK's c64lib compatibility surface. Open a `.web64proj` in the public [Web64 IDE](https://web64.nofs.ai/ide/); all sources and build settings are inside it. No separate c64lib checkout, Kick Assembler installation or host build chain is required.

| Project | Purpose |
| --- | --- |
| `c64lib-common-asm.web64proj` | Assembly memory configuration, VIC bank selection and screen fill. |
| `c64lib-common-c.web64proj` | C screen fill and VIC register setup. |
| `c64lib-mixed.web64proj` | C/ASM calls and explicit CIA interrupt ownership. |
| `c64lib-text-c.web64proj` | Screen-code string encoding, positioned text and hexadecimal output. |
| `c64lib-tile2-scroll.web64proj` | Compatibility Tile2 configuration and bidirectional character-cell scrolling. |
| `c64lib-64spec.web64proj` | Assembly assertions through a native test target. |
| `c64lib-magic-desk.web64proj` | Compatibility Magic Desk bootstrap and CRT target generation. |

For ordinary PRG examples, use **Start PRG / F5**. Select explicit test or cartridge targets in **Build Targets** and inspect **Build Output**. The Magic Desk example is not evidence of a complete cartridge mastering, disk-to-cartridge conversion or verified hardware cartridge workflow; its successful build establishes output generation only.

For new editable game worlds, prefer the native `.w64chr` → `.w64blk` → `.w64map` relationships demonstrated by the [World examples](../WORLD_RUNTIME_EXAMPLES.md). The Tile2 example intentionally keeps its small tables in assembly to teach that compatibility API, not to replace native Map Editor authoring.

Keep the declared C ABI and assembly calling conventions together when modifying mixed projects. Save through **Save Web64 project** to retain changes; unsaved virtual sources can already be built and run.
