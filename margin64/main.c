#include "margin64.h"
#pragma charset("screencode_mixed")

/* C orchestrates commands. The document is native C; ASM is confined to the
 * measured scan/paint kernels and the C64 hardware/banking boundary. */
static uint8_t last_blink;

void main(void) {
    uint8_t key, now;
    asm_platform_init();
    cold_init();
    doc_new();
    asm_clear_screen();
    ui_message("MARGIN64 / F1 MENU / F2 HELP");
    view_refresh();
    for (;;) {
        key = asm_key();
        if (key != 0) {
            /* asm_key also debounces command repeats inside modal dialogs. */
            command_key(key);
            if (doc.dirty) view_refresh();
        }
        now = asm_jiffy() & 32;
        if (now != last_blink) {
            last_blink = now;
            if (now) asm_cursor_show();
            else asm_cursor_hide();
        }
    }
}
