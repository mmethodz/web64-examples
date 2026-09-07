#include "margin64.h"
#pragma charset("screencode_mixed")

void asm_cold_init(void);
void asm_context_init(void);
_fastcall uint8_t asm_cold_load(uint8_t module);
uint8_t asm_cold_invalidate(void);
void asm_cold_invoke(void);

void cold_init(void) {
    asm_cold_init();
    asm_context_init();
}

/* All disk-swap, failure and cancel paths are resident. The selected data
 * device is never changed. Cancel leaves typing and Save fully available.
 * A failed Open invalidates cached modules before touching candidate RAM.
 */
void cold_request(uint8_t command) {
    static uint8_t module;
    *(uint8_t *)0x62c2 = command;
    module = 3;
    if (command == 4) module = 2;
    if (*(uint8_t *)0x62c0 != module) {
        asm_cursor_hide();
        ui_message("LOADING TOOLS FROM DRIVE 8");
        ui_status();
        while (!asm_cold_load(module)) {
            if (!ui_confirm("INSERT APP DISK IN 8 - RETRY?")) {
                ui_message("LOAD CANCELLED - TEXT UNCHANGED");
                return;
            }
        }
    }
    asm_cold_invoke();
    view_redraw();
}

/* Existing menu/function-key commands enter real disk targets. */
void print_document(void) { cold_request(4); }
void search_dialog(void) { cold_request(6); }
void search_next(uint8_t backward) { cold_request(backward ? 8 : 7); }
void search_replace(void) { cold_request(9); }
void search_replace_all(void) { cold_request(10); }
void document_statistics(void) { cold_request(11); }
