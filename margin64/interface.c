#include "margin64.h"
#pragma charset("screencode_mixed")

uint8_t editor_width = 40;
uint8_t print_width = 60, print_lines = 66, print_margin = 5, print_spacing = 1;
uint8_t search_case, search_whole_word;
extern char status_message[40];
static char input_number[6];
static uint8_t menu_active;
static const char *panel_title;

/* Fixed labels are encoded by the compiler for the lower/uppercase ROM font.
 * ui_write copies screen bytes; explicit \377 is our multiline separator
 * (screen code 10 is lowercase j, so a newline byte would be ambiguous).
 * Live PETSCII filenames/input use ui_petscii instead. */

/* The foreground UI is nonreentrant. Fixed screen labels use the native
 * mailbox instead of building a three-argument software frame for each label.
 * Arguments are evaluated once; other translation units retain ui_write(). */
#define ui_write(row,column,text) do { ui_draw_row = (row); ui_draw_column = (column); ui_draw_text = (text); asm_ui_write(); } while (0)
#define panel(title) do { panel_title = (title); panel_begin(); } while (0)

void asm_status_begin(void);
void asm_status_commit(void);

void ui_status(void) {
    /* Viewport construction has finished with LINE_TEXT. Compose into its
     * existing 40-byte scratch, then commit only changed screen/color cells.
     * This avoids exposing a cleared or half-inverted status row while typing. */
    asm_status_begin();
    if (status_message[0]) ui_write(24, 0, status_message);
    else {
        if (document_name[0]) ui_petscii(24, 0, document_name);
        else ui_write(24, 0, "UNTITLED");
        if (doc.modified) LINE_TEXT[17] = 170;
        ui_write(24, 19, doc.overwrite ? "OVR" : "INS");
        if (DOCUMENT_CAPACITY - doc.length < 256) ui_write(24, 23, "LOW MEM");
        else if (doc.selecting) ui_write(24, 23, "MARK");
        else ui_number(24, 23, doc.length, 5);
    }
    /* Always visible, even during other status messages. No Undo popups or
     * transition messages: the model owns the two-watermark eligibility latch. */
    LINE_TEXT[31] = 160;
    ui_write(24, 32, doc_undo_state() == UNDO_READY ? "UNDO ON " : "UNDO OFF");
    asm_status_commit();
}

uint8_t wait_key(void) {
    static uint8_t value;
    do { value = asm_key(); } while (!value);
    return value;
}

uint8_t choice_key(void) {
    static uint8_t value;
    value = wait_key();
    if (value >= 193 && value <= 218) value -= 128;
    return value;
}

static void panel_begin(void) {
    asm_cursor_hide();
    asm_clear_screen();
    ui_write(1, 2, "MARGIN64");
    ui_write(3, 2, panel_title);
    ui_write(23, 2, "RUN/STOP: BACK");
    menu_active = 1;
    ui_status();
}

void panel_end(void) {
    menu_active = 0;
    view_redraw();
}

void ui_panel(const char *title) { panel(title); }

uint8_t ui_confirm(const char *message) {
    static uint8_t key;
    panel("PLEASE CONFIRM");
    ui_write(7, 1, message);
    ui_write(10, 3, "Y  YES        N  KEEP CURRENT");
    do { key = choice_key(); } while (key != 89 && key != 78 && key != 3 && key != 27);
    panel_end();
    return key == 89;
}

uint8_t ui_prompt(const char *label, char *buffer, uint8_t limit) {
    static uint8_t length, key, index;
    length = 0;
    while (length < limit && buffer[length]) length++;
    panel(label);
    ui_write(12, 2, "RETURN: ACCEPT   RUN/STOP: CANCEL");
    for (;;) {
        for (index = 0; index < 36; index++) SCREEN[322 + index] = 32;
        buffer[length] = 0;
        ui_petscii(8, 2, buffer);
        SCREEN[322 + length] = 160;
        key = wait_key();
        if (key == 13) { buffer[length] = 0; panel_end(); return 1; }
        if (key == 3 || key == 27) { panel_end(); return 0; }
        if (key == 20) { if (length) length--; }
        else if ((key >= 32 && key < 128) || key >= 160) {
            if (length < limit) buffer[length++] = key;
        }
    }
}

static void edit_error(void) {
    switch (doc.error) {
        case EDIT_FULL: ui_message("DOCUMENT FULL - EDIT UNCHANGED"); break;
        case EDIT_CLIPBOARD_FULL: ui_message("MARK EXCEEDS 512-BYTE CLIPBOARD"); break;
        case EDIT_NO_SELECTION: ui_message("F5: MARK TEXT BEFORE COPY/CUT"); break;
        case EDIT_RANGE: ui_message("INVALID EDIT RANGE - UNCHANGED"); break;
    }
}

static void edit_menu(void) {
    static uint8_t key;
    panel("EDIT\377\377U UNDO           R REDO\377\377C COPY           X CUT\377\377V PASTE          A SELECT ALL\377\377W SELECT WORD    P SELECT PARAGRAPH\377\377D DELETE WORD    K DELETE PARAGRAPH\377\377I INSERT/OVERWRITE");
    key = choice_key();
    panel_end();
    switch (key) {
        case 85: doc_undo(); break;
        case 82: doc_redo(); break;
        case 67: doc_copy(); break;
        case 88: doc_cut(); break;
        case 86: doc_paste(); break;
        case 65: doc_select_all(); break;
        case 87: select_word(); break;
        case 80: select_paragraph(); break;
        case 68: doc.anchor = doc.cursor; move_word(1); doc.selecting = 1; doc_delete(); break;
        case 75: select_paragraph(); doc_delete(); break;
        case 73: doc.overwrite = !doc.overwrite; break;
    }
}

static void file_menu(void) {
    static uint8_t key;
    panel("FILE\377\377N NEW            O OPEN\377\377S SAVE           A SAVE AS\377\377D DIRECTORY      V DATA DEVICE\377\377I IMPORT PETSCII X EXPORT PETSCII\377\377\377\377DATA DEVICE\377\3778: SWAP IN DATA DISK WHEN IDLE.\3779: KEEP APPLICATION DISK IN DRIVE 8.");
    ui_number(15, 15, disk_device, 2);
    key = choice_key();
    panel_end();
    switch (key) {
        case 78:
            if (!doc.modified || ui_confirm("DISCARD UNSAVED CHANGES?")) {
                doc_new(); document_name[0] = 0; asm_clear_screen(); view_invalidate();
            }
            break;
        case 79: file_open_dialog(0); break;
        case 83: file_save_dialog(0, 0); break;
        case 65: file_save_dialog(1, 0); break;
        case 68: file_directory(); break;
        case 73: file_open_dialog(1); break;
        case 88: file_save_dialog(1, 1); break;
        case 86: disk_device++; if (disk_device > 11) disk_device = 8; break;
    }
}

static void search_menu(void) {
    static uint8_t key;
    panel("SEARCH\377\377F FIND           N FIND NEXT\377\377B FIND PREVIOUS  R REPLACE ONE\377\377A REPLACE ALL");
    ui_write(12, 2, search_case ? "C CASE: EXACT" : "C CASE: IGNORE");
    ui_write(14, 2, search_whole_word ? "W WORDS: WHOLE" : "W WORDS: ANY");
    key = choice_key();
    panel_end();
    switch (key) {
        case 70: search_dialog(); break;
        case 78: search_next(0); break;
        case 66: search_next(1); break;
        case 82: search_replace(); break;
        case 65: search_replace_all(); break;
        case 67: search_case = !search_case; break;
        case 87: search_whole_word = !search_whole_word; break;
    }
}

void format_options(void) {
    static uint8_t key;
    static uint8_t token;
    panel("FORMAT\377\377B BOLD           U UNDERLINE\377\377E EMPHASIS       T TAB\377\377L HARD LINE      P PAGE BREAK\377\377\377W WRAP WIDTH     CURRENT:\377\377\377\377\377STYLE TOKENS TOGGLE UNTIL NEXT TOKEN.");
    ui_number(12, 27, editor_width, 2);
    key = choice_key();
    panel_end();
    switch (key) {
        case 66: case 85: case 69:
            token = TOKEN_BOLD;
            if (key == 85) token = TOKEN_UNDERLINE;
            if (key == 69) token = TOKEN_EMPHASIS;
            doc_format(token);
            break;
        case 84: doc_type(TOKEN_TAB); break;
        case 76: doc_type(TOKEN_LINE); break;
        case 80: doc_type(TOKEN_PAGE); break;
        case 87:
            editor_width -= 5;
            if (editor_width < 20) editor_width = 40;
            view_width = editor_width;
            doc.top = 0;
            view_invalidate();
            break;
    }
}

static uint16_t decimal_number(const char *text) {
    static uint16_t result;
    result = 0;
    while (*text >= 48 && *text <= 57) {
        if (result > 6000) return 65535;
        result = result * 10 + *text++ - 48;
    }
    return result;
}

static void document_menu(void) {
    static uint8_t key;
    panel("DOCUMENT\377\377H DOCUMENT START E DOCUMENT END\377\377U PAGE UP        D PAGE DOWN\377\377L WORD LEFT      R WORD RIGHT\377\377G GO TO PARAGRAPH S STATISTICS");
    key = choice_key();
    panel_end();
    switch (key) {
        case 72: doc.cursor = 0; break;
        case 69: doc.cursor = doc.length; break;
        case 85: view_page(-1); break;
        case 68: view_page(1); break;
        case 76: move_word(-1); break;
        case 82: move_word(1); break;
        case 71:
            input_number[0] = 0;
            if (ui_prompt("GO TO PARAGRAPH (1..)", input_number, 5)) {
                goto_paragraph(decimal_number(input_number));
            }
            break;
        case 83: document_statistics(); break;
    }
}

void ui_menu(void) {
    static uint8_t key;
    panel("ROOM FOR YOUR WORDS.\377\377\377  F  FILE          E  EDIT\377\377\377  S  SEARCH        O  FORMAT\377\377\377  D  DOCUMENT      P  PRINT\377\377\377  H  HELP          T  THEME\377\377\377\377  SELECT A LETTER");
    key = choice_key();
    panel_end();
    switch (key) {
        case 70: file_menu(); break;
        case 69: edit_menu(); break;
        case 83: search_menu(); break;
        case 79: format_options(); break;
        case 68: document_menu(); break;
        case 80: print_document(); break;
        case 72: ui_help(); break;
        case 84:
            if (theme_background == 0) { theme_background = 6; theme_foreground = 1; }
            else if (theme_background == 6) { theme_background = 11; theme_foreground = 15; }
            else { theme_background = 0; theme_foreground = 15; }
            asm_clear_screen();
            view_invalidate();
            break;
    }
    if (!doc.dirty) doc.dirty = 1;
    edit_error();
}

void ui_help(void) {
    static uint8_t key;
    panel("QUICK GUIDE\377\377TYPE TO WRITE. RETURN: NEW PARAGRAPH.\377\377CURSORS MOVE. DEL: BACKSPACE.\377\377F1 MENU     F2 HELP     F3 FIND\377\377F4 NEXT     F5 MARK     F6 PASTE\377\377F7 UNDO     F8 SAVE\377\377F5 SETS ANCHOR. MOVE TO EXTEND MARK.\377\377F1 E: COPY/CUT/REDO/SELECT/DELETE.\377\377F1 O: STYLES, TABS, WRAP, BREAKS.\377\377RETURN: DISK & SAFETY HELP");
    key = wait_key();
    if (key == 13) {
        panel("DISK & DOCUMENT SAFETY\377\377F1 F: OPEN, SAVE AS, DIRECTORY.\377\377KEEP A BACKUP ON ANOTHER DISK.\377\377SAVE WRITES AND VERIFIES A NEW FILE\377BEFORE REPLACING THE OLD VERSION.\377\377FAILED OPEN KEEPS YOUR DOCUMENT.\377\377CLIPBOARD 512. UNDO: 1 EDIT/512 BYTES.\377DOCUMENT LIMIT: 15866 BYTES.\377LARGE EDITS CONTINUE WITHOUT UNDO.\377\377PETSCII IMPORT/EXPORT USE SEQ FILES.\377\377ANY KEY: RETURN TO YOUR DOCUMENT.");
        wait_key();
    }
    panel_end();
}

void command_key(uint8_t key) {
    status_message[0] = 0;
    doc.error = EDIT_OK;
    if (key >= 32 && (key < 128 || key >= 160)) {
        view_reset_column();
        doc_type(key);
        edit_error();
        return;
    }
    switch (key) {
        case 13: doc_type(TOKEN_PARAGRAPH); break;
        case 9: doc_type(TOKEN_TAB); break;
        case 20: doc_backspace(); break;
        case 148: doc.overwrite = !doc.overwrite; break;
        case 29: if (doc.cursor < doc.length) doc.cursor++; view_reset_column(); break;
        case 157: if (doc.cursor) doc.cursor--; view_reset_column(); break;
        case 17: view_vertical(1); break;
        case 145: view_vertical(-1); break;
        case 19: view_home(0); break;
        case 147: doc.cursor = 0; view_reset_column(); break;
        case 3: case 27: doc_clear_selection(); break;
        case 133: ui_menu(); break;
        case 137: ui_help(); break;
        case 134: search_dialog(); break;
        case 138: search_next(0); break;
        case 135:
            if (doc.selecting) doc_clear_selection();
            else { doc.anchor = doc.cursor; doc.selecting = 1; }
            break;
        case 139: doc_paste(); break;
        case 136: doc_undo(); break;
        case 140: file_save_dialog(0, 0); break;
    }
    if (!doc.dirty) doc.dirty = 1;
    edit_error();
}
