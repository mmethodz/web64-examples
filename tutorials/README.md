# Web64 C Tutorials

Each tutorial entry links prose to a runnable `.web64proj` project. The projects are browser-local Web64 IDE projects; they do not require native cc65, host filesystem paths, or external build tools.

## Lessons

| Lesson | Runnable project | Proves |
| --- | --- | --- |
| C compiler conformance | `../c-compiler-conformance/c-compiler-conformance.web64proj` | Parser-backed scalar expressions, casts, nested calls, `_fastcall` runtime calls, and `printf` argument materialization. |
| Fixed subpixel scroll | `../c-fixed-subpixel-scroll/c-fixed-subpixel-scroll.web64proj` | `web64/fixed.h` 8.8 constants, ratio conversion, wrapping add, integer conversion, and no-helper runtime closure. |
| Fixed sine lerp | `../c-fixed-sine-lerp/c-fixed-sine-lerp.web64proj` | `web64_sin8`, `web64_fix8_mul`, `web64_fix8_lerp`, and fixed multiply/trig runtime selection. |
| Fixed motion | `../c-fixed-motion/c-fixed-motion.web64proj` | `Web64Motion2D`, address-of aggregate helper calls, and fixed-vector runtime selection. |
| Screen colors | `../c-screen-colors/c-screen-colors.web64proj` | Direct C64 register writes from C. |
| Screen memory | `../c-screen-memory/c-screen-memory.web64proj` | C writes to C64 screen memory. |
| Joystick registers | `../c-joystick-registers/c-joystick-registers.web64proj` | C64 register aliases and joystick helpers. |
| Sprite joystick | `../c-sprite-joy/c-sprite-joy.web64proj` | Sprite helper declarations and C64 sprite registers. |
| Sprite joy SID bumps C | `../sprite-joy-sid-bumps-c/sprite-joy-sid-bumps-c.web64proj` | C-first sprite, joystick acceleration, SID, 16-bit X wrap, and charset asset copy. |
| Asset header | `../c-asset-header/c-asset-header.web64proj` | Generated `assets/generated.h` metadata. |
| Mixed C calls ASM | `../hybrid-c-calls-asm/hybrid-c-calls-asm.web64proj` | C symbols and direct `asm_` label calls. |
| ASM uses C data | `../hybrid-asm-uses-c-data/hybrid-asm-uses-c-data.web64proj` | Mixed C/ASM symbol visibility. |
| Diagnostic unsupported C | `../diagnostic-unsupported-c/diagnostic-unsupported-c.web64proj` | Stable diagnostics for unsupported syntax. |

The tutorial suite intentionally documents only shipped behavior. Planned compiler features should remain in the compatibility matrix until source changes and executable tests prove them.
