# C Compiler Conformance

Browser-run Web64 C conformance example for the Web64 C v1 scalar-expression and ABI surface.

Open `c-compiler-conformance.web64proj` in Web64 IDE and start `_main`. The program prints `WEB64 C V1` followed by `PASS` when arithmetic, shifts, bitwise operators, casts, nested calls, `_fastcall` runtime calls, and `printf` argument materialization produce the expected values. A failing check prints `FAIL` and the failing code.

This example is source-backed and limited to implemented Web64 C behavior. It does not claim native cc65 object or linker compatibility.
