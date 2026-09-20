# Aurora — Web64 IDE tutorial

A C64 character plasma, custom font, dither graphics and character scroller. The native project is the editable master. The teaching files are the starting material imported or pasted in the video.

## Watch and run

- `Web64-Aurora-Tutorial.mp4`: 14-minute English tutorial, 1080p/30 fps, captions in the bottom margin.
- `Plasma-Tutorial.web64proj`: complete native project with the edited “MAKE SOMETHING NEW!” message.
- `aurora.prg`: executable compiled from the saved native project.
- `teaching-files/`: original charset, C source and assembly include.
- `narration.wav`, `captions.srt`, `NARRATION.md`: separate audio, captions and script.
- `PRODUCTION-WORKFLOW.md`, `AUDIO-SOURCES.md`: revision instructions and audio provenance.

Open https://web64.nofs.ai/ide/ in a dedicated browser window. Use **Open Web64 project** to open the native project. Select **main.c** in Code, open **Build Targets**, select **Aurora**, and choose **Build Target**. Confirm Ready and no diagnostics. Choose **Start PRG** and view Code and the integrated emulator at **1x**. Expect a fixed Aurora title, moving coloured patterns and scrolling text that wraps.

## Follow from the teaching files

1. Code → New → C project. Save a native project early.
2. Import → Add files → `aurora.chr`. Char Editor opens and native bindings are generated. Keep the `.chr` extension.
3. Build Targets: label Aurora; output `aurora.prg`; origin `$4000`; root `main.c`; PRG program; Web64-C target enabled.
4. Import `plasma.inc`. Open main.c and paste the supplied C source. Its plasma_frame function includes that virtual assembly file.
5. Settings: Web64 C90 + extensions; Stack ABI v1; Web64 browser native; Freestanding. Select Speed and enable Peephole, Simplify and Runtime deps. Set C stdout and stdin to None. Select emulator 1x and disable Scanlines for the video's presentation.
6. Select main.c before building. Build Target, inspect the report, and Start PRG.
7. Change a short uppercase message phrase, save, build and run. The video changes MAKE IT YOUR OWN! to MAKE SOMETHING NEW!.
8. Save, reopen in a fresh workspace and build/run again. Share the native project for editing.

This deployment normalizes Output file and Origin while editing. Paste complete values into those fields. New C project resets emulator scaling; restore 1x. After examining read-only SDK includes, return to main.c before building.

## Memory and graphics

| Purpose | Address |
|---|---|
| 40 × 25 character screen | `$0400` |
| Colour RAM | `$D800` |
| 2 KB custom charset | `$3800` |
| PRG load/start | `$4000` |

The charset has 256 eight-byte glyphs. Uppercase letters occupy ASCII indexes because this program writes C string bytes directly as character indexes. Dither glyphs occupy indexes 128–143. The plasma covers 40 columns and 18 rows starting at screen row 3. The scroller uses row 23 and moves one character every third animation update.

The field combines cached horizontal sine samples with a vertical sample for each row. The resulting 0–31 index selects both a palette entry and a glyph. The kernel uses writable, self-modified store operands; interrupts are disabled in this standalone demonstration. The scroller moves by characters, rather than using a pixel-smooth raster split.

## Runtime handoff

```c
#include <web64/assets.h>
#include "assets/generated.h"

if (web64_asset_copy_charset((uint8_t *)0x3800, &aurora_asset)
    != WEB64_ASSET_COPY_OK) {
    for (;;) { VIC->border_color = 2; }
}
```

The descriptor belongs to the native asset. Edit the charset in Char Editor; do not maintain a second hand-written generated header. The helper validates and copies character bytes. The program separately selects VIC bank 0 and sets `VIC->memory_setup = 0x1e` for screen `$0400` and charset `$3800`.

Assembly callers can inspect `web64/assets.inc` in Web64 SDK → ASM includes. Matching macros are `web64_rt_prepare_asset_copy_charset destination, asset` and `web64_rt_call_asset_copy_charset destination, asset`. The sidebar displays their arguments. Preparation loads the runtime argument window; the call macro also invokes the runtime entry.

## Reference and production archive

The IDE manual is at https://web64.nofs.ai/docs/web64-ide-user-manual.html . The separate production archive retains raw captured takes, edit decisions, narration segments, rendering scripts and verification evidence. The native example does not require repository tooling.
