# C Compiler Conformance

Browser-run Web64 C conformance example for the Web64 C v1 scalar-expression and ABI surface.

Open `c-compiler-conformance.web64proj` in Web64 IDE and use **F5 / Start PRG** with the saved automatic entry configuration. Do not bypass the C startup by manually jumping to `_main`. The program prints `WEB64 C V1` followed by `PASS` when arithmetic, shifts, bitwise operators, casts, nested calls, `_fastcall` runtime calls, and `printf` argument materialization produce the expected values. A failing check prints `FAIL` and the failing code.

The historical `V1` label describes this regression suite, not a requirement to find an old IDE. The project intentionally retains `web64-static-v0`; its purpose is to exercise that supported calling convention against the current compiler. New projects need not copy its ABI choice.

This example is source-backed and limited to implemented Web64 C behavior. It does not claim native cc65 object or linker compatibility.
