/* Margin64 cold print module. Plain PETSCII profile, device 4 / secondary 7.
 * Formatting toggles are zero-width; their visual styles are not printer
 * escape codes. Tabs use eight-column stops inside the left margin. CR is
 * the only emitted control: page tokens pad to the next configured page,
 * since an MPS-803 does not implement a generic form-feed command.
 * The document, cursor, selection, gap and Undo remain entirely read-only.
 */
#pragma charset("screencode_mixed")
#include "cold-services.h"
#include <web64/disk.h>
#include <cbm.h>

#define PRINT_INPUT ((char *)0x7080)
#define PRINT_LINE ((uint8_t *)0x7100)

static Document *print_state;
static uint8_t *width_setting;
static uint8_t *lines_setting;
static uint8_t *margin_setting;
static uint8_t *spacing_setting;
static uint16_t print_position, print_length, break_position;
static uint8_t body_width, page_lines, left_margin, line_spacing;
static uint8_t line_count, break_count, page_row, print_failed, print_cancelled;

static void send_byte(uint8_t value) {
    if (print_failed || print_cancelled) return;
    cbm_k_chrout(value);
    if (cbm_k_last_error() || cbm_k_readst()) print_failed = 1;
}

/* Keyboard service runs only with the default channels restored. Polling is
 * bounded by one physical line, including the blank rows in a page break. */
static void line_boundary(void) {
    uint8_t key;
    cbm_k_clrchn();
    if (cbm_k_last_error() || cbm_k_readst()) print_failed = 1;
    if (print_failed) return;
    key = asm_key();
    if (key == 3 || key == 27) { print_cancelled = 1; return; }
    if (cbm_k_chkout(4) || cbm_k_last_error()) print_failed = 1;
}

static void send_row(void) {
    send_byte(13);
    page_row++;
    if (page_row == page_lines) page_row = 0;
    line_boundary();
}

/* Returns 0 at EOF, 1 at a soft wrap, 2 at a hard line/paragraph and 3 at
 * an explicit page boundary. The last whitespace checkpoint lets a whole
 * word move to the next line without an allocation or document mutation. */
static uint8_t next_line(void) {
    uint8_t value, tab_end;
    line_count = 0;
    break_count = 0;
    break_position = print_position;
    while (print_position < print_length) {
        value = doc_get(print_position);
        if (value >= TOKEN_BOLD && value <= TOKEN_EMPHASIS) {
            print_position++;
        } else if (value == TOKEN_LINE || value == TOKEN_PARAGRAPH || value == TOKEN_PAGE) {
            print_position++;
            if (value == TOKEN_PAGE) return 3;
            return 2;
        } else if (value == 32 || value == TOKEN_TAB) {
            print_position++;
            if (line_count == body_width) return 1;
            tab_end = line_count + 1;
            if (value == TOKEN_TAB) tab_end = (line_count | 7) + 1;
            if (tab_end > body_width) tab_end = body_width;
            while (line_count < tab_end) PRINT_LINE[line_count++] = 32;
            break_count = line_count;
            break_position = print_position;
        } else if ((value >= 32 && value <= 127) || value >= 160) {
            if (line_count == body_width) {
                if (break_count) {
                    line_count = break_count;
                    print_position = break_position;
                    while (line_count && PRINT_LINE[line_count - 1] == 32) line_count--;
                }
                return 1;
            }
            PRINT_LINE[line_count++] = value;
            print_position++;
        } else {
            /* Invalid/internal controls must never become printer commands. */
            print_position++;
        }
    }
    return 0;
}

static void print_job(void) {
    uint8_t reason, index;
    body_width = width_setting[0];
    page_lines = lines_setting[0];
    left_margin = margin_setting[0];
    line_spacing = spacing_setting[0];
    if (body_width < 40 || body_width > 80 || page_lines < 20 || page_lines > 99 ||
        left_margin > 15 || line_spacing < 1 || line_spacing > 2) {
        ui_message("Invalid print settings");
        return;
    }
    body_width -= left_margin;
    print_length = print_state->length;
    print_position = 0;
    page_row = 0;
    print_failed = 0;
    print_cancelled = 0;
    ui_panel("Printing to device 4");
    ui_write(5, 2, "Plain PETSCII - secondary address 7");
    ui_write(7, 2, "RUN/STOP cancels between lines");
    if (web64_file_open("", 0, 4, 4, 7) || web64_disk_last_error()) print_failed = 1;
    if (!print_failed) {
        if (cbm_k_chkout(4) || cbm_k_last_error()) print_failed = 1;
    }
    while (!print_failed && !print_cancelled) {
        reason = next_line();
        if (line_count || reason == 1 || reason == 2) {
            if (line_count) {
                for (index = 0; index < left_margin; index++) send_byte(32);
                for (index = 0; index < line_count; index++) send_byte(PRINT_LINE[index]);
            }
            send_row();
            /* Never insert a double-spacing blank on a fresh page. */
            if (line_spacing == 2 && page_row && !print_failed && !print_cancelled) send_row();
        }
        if (reason == 3) {
            while (page_row && !print_failed && !print_cancelled) send_row();
        }
        if (reason == 0) break;
    }
    /* CLOSE/CLRCHN do not have a reliable raw carry contract. Use the SDK's
     * retained independent error latch and READST, including late errors. */
    cbm_k_clrchn();
    if (cbm_k_last_error() || cbm_k_readst()) print_failed = 1;
    if (web64_file_close(4) || web64_disk_last_error() || cbm_k_readst()) print_failed = 1;
    cbm_k_clrchn();
    if (print_failed) ui_message("Printer error - output may be partial");
    else if (print_cancelled) ui_message("Print cancelled - output is partial");
    else ui_message("Print job sent to device 4");
}

static void edit_setting(uint8_t key) {
    uint8_t *setting;
    uint8_t value, index, lower, upper;
    setting = width_setting;
    lower = 40;
    upper = 80;
    if (key == 50) { setting = lines_setting; lower = 20; upper = 99; }
    if (key == 51) { setting = margin_setting; lower = 0; upper = 15; }
    if (key == 52) { setting = spacing_setting; lower = 1; upper = 2; }
    PRINT_INPUT[0] = 0;
    if (!ui_prompt("Enter print setting", PRINT_INPUT, 2)) return;
    value = 0;
    index = 0;
    while (PRINT_INPUT[index]) {
        if (PRINT_INPUT[index] < 48 || PRINT_INPUT[index] > 57) {
            ui_message("Enter a number in the shown range");
            return;
        }
        value = value * 10 + PRINT_INPUT[index] - 48;
        index++;
    }
    if (index == 0 || value < lower || value > upper) {
        ui_message("Enter a number in the shown range");
        return;
    }
    setting[0] = value;
}

void cold_entry(void) {
    uint8_t key;
    if (COLD_COMMAND != 4) return;
    print_state = (Document *)COLD_CONTEXT[0];
    width_setting = (uint8_t *)COLD_CONTEXT[2];
    lines_setting = (uint8_t *)COLD_CONTEXT[3];
    margin_setting = (uint8_t *)COLD_CONTEXT[4];
    spacing_setting = (uint8_t *)COLD_CONTEXT[5];
    for (;;) {
        ui_panel("Print document");
        ui_write(4, 2, "1 Width incl. margin (40-80)");
        ui_number(4, 33, width_setting[0], 2);
        ui_write(6, 2, "2 Rows per page      (20-99)");
        ui_number(6, 33, lines_setting[0], 2);
        ui_write(8, 2, "3 Left margin         (0-15)");
        ui_number(8, 33, margin_setting[0], 2);
        ui_write(10, 2, "4 Line spacing         (1-2)");
        ui_number(10, 33, spacing_setting[0], 1);
        ui_write(13, 2, "P Print    B Back    RUN/STOP Back");
        ui_write(16, 2, "Plain PETSCII / device 4 / sec. 7");
        ui_write(18, 2, "Inline styles print as plain text.");
        key = choice_key();
        if (key == 3 || key == 27 || key == 66) break;
        if (key >= 49 && key <= 52) edit_setting(key);
        if (key == 80) print_job();
    }
    panel_end();
}
