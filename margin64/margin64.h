#ifndef MARGIN64_H
#define MARGIN64_H

#include <stdint.h>

/* Stock C64 budget: code/data $0800-$61ff; bounded workspaces $6200-$71ff;
 * active document $7200-$aff9; transactional candidate $b000-$fff9.
 * Six top bytes are reserved for safe RAM vectors when ROM is hidden.
 * The normal project settings place the 1024-byte C stack at $6a00.
 * No malloc, REU or browser-side document engine is involved. */
#define DOCUMENT_BASE 0x7200
#define CANDIDATE_BASE 0xb000
#define DOCUMENT_CAPACITY 15866
#define UNDO_BASE 0x6300
#define UNDO_CAPACITY 512
/* Hysteresis: passing the upper limit disables Undo until the document has
 * shrunk to the lower limit. Only a subsequent eligible edit is remembered. */
#define UNDO_DISABLE_ABOVE 16384
#define UNDO_REENABLE_AT 14336
#define CLIPBOARD_BASE 0x6700
#define CLIPBOARD_CAPACITY 512
#define IO_BUFFER ((uint8_t *)0x6900)
#define LINE_TEXT ((uint8_t *)0x6e00)
#define LINE_STYLE ((uint8_t *)0x6e40)
#define LINE_POSITION ((uint16_t *)0x6e80)
#define ROW_START ((uint16_t *)0x6f00)
#define ROW_STYLE ((uint8_t *)0x6f40)
#define ROW_END ((uint16_t *)0x6f60)
#define ROW_X ((uint8_t *)0x6fa0)
#define SCREEN ((uint8_t *)0x0400)
#define COLOR ((uint8_t *)0xd800)

/* Canonical printable PETSCII plus compact internal tokens. UI literals use
 * compile-time charset encoding, never the document's stored representation. */
#define TOKEN_BOLD 1
#define TOKEN_UNDERLINE 2
#define TOKEN_EMPHASIS 3
#define TOKEN_TAB 9
#define TOKEN_LINE 10
#define TOKEN_PAGE 12
#define TOKEN_PARAGRAPH 13

enum EditorError {
    EDIT_OK, EDIT_FULL, EDIT_CLIPBOARD_FULL,
    EDIT_NOTHING_TO_UNDO, EDIT_NOTHING_TO_REDO, EDIT_NO_SELECTION, EDIT_RANGE
};
enum UndoState { UNDO_EMPTY, UNDO_READY, UNDO_REDO, UNDO_DISABLED };

/* ABI: packed bytes, offsets below are also used by the measured ASM renderer.
 * Use tests to keep the C layout and assembly offsets in agreement. */
typedef struct {
    uint16_t gap;       /* 0: logical/physical gap start */
    uint16_t end;       /* 2: physical gap end */
    uint16_t length;    /* 4: logical payload length */
    uint16_t cursor;    /* 6: active endpoint, 0..length */
    uint16_t anchor;    /* 8: selection anchor */
    uint16_t top;       /* 10: viewport logical start */
    uint8_t selecting; /* 12: selection/mark mode */
    uint8_t modified;  /* 13: unsaved changes */
    uint8_t overwrite; /* 14: 0 insert, 1 overwrite */
    uint8_t error;     /* 15: EditorError */
    uint8_t dirty;     /* 16: 0 clean, 1 mark/cursor, 2 document mutation */
} Document;

extern Document doc;
/* Earliest admitted text change while dirty==2. Viewport consumption clears
 * dirty; cursor/mark-only refreshes must not downgrade an unconsumed2. */
extern uint16_t document_dirty_from;
/* Exclusive affected endpoint in current document coordinates. Pending ranges
 * follow subsequent edits; cached suffix reuse must pass this endpoint. */
extern uint16_t document_dirty_to;
extern uint16_t clipboard_length;
void doc_new(void);
_fastcall uint8_t doc_get(uint16_t position);
_fastcall void doc_move_gap(uint16_t position);
/* One admitted command, all-or-nothing; refusals leave content/Undo intact.
 * A valid edit never waits for Undo space or confirmation. Large edits and
 * disabled Undo clear the old record. Input must not alias document/Undo
 * storage. NULL+zero inserts none. */
uint8_t doc_replace(uint16_t position, uint16_t removed,
                    const uint8_t *inserted, uint16_t count);
/* Small formatting uses the same recent-edit buffer when Undo is enabled.
 * Larger marks still format normally; there is no compound history type. */
uint8_t doc_format(uint8_t token);
uint8_t doc_type(uint8_t value);
uint8_t doc_backspace(void);
uint8_t doc_delete(void);
uint8_t doc_copy(void);
uint8_t doc_cut(void);
uint8_t doc_paste(void);
uint8_t doc_undo(void);
uint8_t doc_redo(void);
uint8_t doc_undo_state(void);
void doc_select_all(void);
void doc_clear_selection(void);
uint16_t doc_selection_start(void);
uint16_t doc_selection_end(void);
/* Called ONLY after the resident loader has fully validated a candidate. */
void doc_adopt(uint16_t length);

/* Hardware and viewport use shared explicit arguments for cheap ASM calls.
 * They are ordinary project-owned symbols, not a new runtime ABI. */
extern uint16_t view_start, view_next;
extern uint8_t view_width, view_style, view_next_style, view_count;
extern uint8_t view_row, view_column, view_paint_style;
extern uint16_t view_cursor_position;
extern uint8_t key_modifiers;
extern uint8_t theme_background, theme_foreground, theme_accent;
extern uint16_t bank_address;
extern uint16_t bank_length;
extern uint8_t bank_value;
void asm_platform_init(void);
uint8_t asm_key(void);
uint8_t asm_jiffy(void);
void asm_layout_line(void);
void asm_paint_line(void);
void asm_cursor_hide(void);
void asm_cursor_show(void);
void asm_bank_read(void);
void asm_bank_write(void);
void asm_commit_candidate(void);
void asm_clear_screen(void);

void view_refresh(void);
/* Call after a dialog overwrites document rows or the wrap/theme changes.
 * Normal navigation only sets dirty=1; never downgrade an admitted dirty=2. */
void view_invalidate(void);
void view_redraw(void);
/* Measured native logical-line navigation; one byte in the public A register. */
_fastcall void view_vertical(int8_t direction);
_fastcall void view_page(int8_t direction);
_fastcall void view_home(uint8_t end);
void view_reset_column(void);
/* Native scans preserve document/gap/history and the existing word policy. */
_fastcall void move_word(int8_t direction);
void select_word(void);
void select_paragraph(void);
_fastcall void goto_paragraph(uint16_t paragraph);
void ui_write(uint8_t row, uint8_t column, const char *text);
extern uint8_t ui_draw_row, ui_draw_column;
extern const char *ui_draw_text;
void asm_ui_write(void);
void ui_petscii(uint8_t row, uint8_t column, const char *text);
_fastcall uint8_t ui_petscii_code(uint8_t value);
void ui_number(uint8_t row, uint8_t column, uint16_t value, uint8_t digits);
_fastcall void ui_message(const char *message);
void ui_status(void);
void ui_menu(void);
void cold_init(void);
void cold_request(uint8_t command);
uint8_t asm_cold_invalidate(void);
uint8_t ui_confirm(const char *message);
uint8_t ui_prompt(const char *label, char *buffer, uint8_t limit);
void ui_help(void);
void command_key(uint8_t key);
void search_dialog(void);
void search_next(uint8_t backward);
void search_replace(void);
void search_replace_all(void);
void document_statistics(void);
void format_options(void);
void print_document(void);

extern uint8_t editor_width;
extern uint8_t print_width, print_lines, print_margin, print_spacing;
extern uint8_t search_case, search_whole_word;

extern char document_name[17];
extern uint8_t disk_device;
void file_open_dialog(uint8_t plain);
void file_save_dialog(uint8_t save_as, uint8_t plain);
void file_directory(void);

#endif
