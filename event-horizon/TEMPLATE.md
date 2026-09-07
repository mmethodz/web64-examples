# Native assembler project

Event Horizon began with the IDE's **New > Assembly project** template.
Its main target is a normal PRG at `$0801`, with root `event-horizon.asm`
and entry symbol `start`. Supporting `.inc` files are explicit assembler
includes, not separate translation units. The complete program is resident;
there are no external runtime or disk-file dependencies.

Use `README.md` for operation and `PERFORMANCE.md` before editing timing code.
