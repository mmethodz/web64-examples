#include "margin64.h"

uint16_t view_start, view_next, view_cursor_position, view_line_end;
uint16_t view_selection_start, view_selection_end;
uint8_t view_width = 40;
uint8_t view_style, view_next_style, view_count, view_flags, view_valid;
uint8_t view_row, view_column, view_paint_style;
uint8_t key_modifiers;
uint8_t theme_background = 0, theme_foreground = 15, theme_accent = 3;
uint16_t bank_address, bank_length;
uint8_t bank_value;
uint8_t view_cursor_row, view_cursor_column, view_desired_column, view_desired_valid;
static uint8_t cached_width;
static uint16_t cached_top;
uint16_t view_previous_selection_start, view_previous_selection_end;
uint16_t view_cached_length, view_length_delta;
uint8_t view_allow_reuse;
void asm_scan_line(void);
void asm_find_cursor(void);
void asm_locate_top(void);
void asm_invalidate_seek(void);
void asm_invalidate_changed_seek(void);
uint8_t asm_row_cursor(void);
uint8_t asm_row_selection(void);
uint8_t asm_dirty_row(void);
uint8_t asm_reuse_suffix(void);
uint8_t view_top_style;

void view_invalidate(void) {
    view_valid = 0;
    doc.dirty = 2;
    asm_invalidate_seek();
}

/* A dialog changes the physical screen, not logical wrapping or seek history.
 * Keep an already-invalid layout invalid; otherwise request a full repaint
 * using its cached boundaries. The outer command paints once after dispatch. */
void view_redraw(void) {
    if (view_valid) view_valid = 2;
    if (!doc.dirty) doc.dirty = 1;
}

/* The C policy owns invalidation and the 24-row logical viewport. Native
 * kernels own measured scans, comparisons, painting and cursor navigation.
 * dirty=1 retains layout; dirty=2 admits the model's accumulated interval.
 * A suffix is reusable only after its content, boundary and style converge.
 * No document-sized line index or extra document workspace is allocated. */
void view_refresh(void) {
    static uint8_t rebuild, paint, found, selection_changed;
    asm_cursor_hide();
    if (doc.cursor > doc.length) doc.cursor = doc.length;
    if (doc.top > doc.length) doc.top = 0;
    if (doc.top == 0) view_top_style = 0;
    if (view_width == 0 || view_width > 40) view_width = 40;
    if (cached_width != view_width) asm_invalidate_seek();
    if (doc.dirty == 2) asm_invalidate_changed_seek();
    /* Edits in the first cached row can change the offscreen predecessor's
     * word-wrap lookahead. Repair that boundary too, including equality when
     * a deletion moves top to the surviving insertion point. At document
     * start there is no predecessor and normal dirty-row reuse stays cheap. */
    if (cached_width != view_width || (doc.dirty == 2 && doc.top != 0 && document_dirty_from <= ROW_END[0])) {
        view_valid = 0;
        view_cursor_position = doc.top;
        view_column = 0;
        asm_locate_top();
        view_top_style = view_style;
    }
    if (!view_valid && doc.cursor > doc.top + 960) {
        view_cursor_position = doc.cursor;
        view_column = 12;
        asm_locate_top();
        view_top_style = view_style;
    }
    rebuild = 24;
    view_allow_reuse = 0;
    if (!view_valid || cached_width != view_width || cached_top != doc.top) rebuild = 0;
    else if (doc.dirty == 2) {
        rebuild = asm_dirty_row();
        view_length_delta = doc.length - view_cached_length;
        if (view_previous_selection_start == view_previous_selection_end) view_allow_reuse = 1;
    }
    if (doc.cursor < doc.top) {
        view_cursor_position = doc.cursor;
        view_column = 2;
        asm_locate_top();
        view_top_style = view_style;
        rebuild = 0;
    }
    view_selection_start = doc_selection_start();
    view_selection_end = doc_selection_end();
    if (!doc.selecting) {
        view_selection_start = 0;
        view_selection_end = 0;
    }
    selection_changed = view_previous_selection_start != view_selection_start || view_previous_selection_end != view_selection_end;
refresh_rows:
    found = 0;
    view_start = doc.top;
    view_style = view_top_style;
    for (view_row = 0; view_row < 24; view_row++) {
        if (view_row >= rebuild) {
            if (view_row == rebuild && rebuild) {
                view_start = ROW_START[view_row];
                view_style = ROW_STYLE[view_row];
            }
            ROW_START[view_row] = view_start;
            ROW_STYLE[view_row] = view_style;
        }
        paint = view_valid == 2 || view_row >= rebuild || (selection_changed && asm_row_selection());
        if (paint || (!found && asm_row_cursor())) {
            view_start = ROW_START[view_row];
            view_style = ROW_STYLE[view_row];
            asm_layout_line();
            if (view_allow_reuse && view_row >= rebuild && asm_reuse_suffix()) {
                rebuild = 24;
                view_allow_reuse = 0;
            }
            ROW_END[view_row] = view_next;
            ROW_X[view_row] = view_flags;
            if (!found && asm_row_cursor()) {
                asm_find_cursor();
                view_cursor_row = view_row;
                view_cursor_column = view_column;
                found = 1;
            }
            if (paint) asm_paint_line();
            view_start = view_next;
            view_style = view_next_style;
        }
    }
    if (!found) {
        view_cursor_position = doc.cursor;
        view_column = 12;
        asm_locate_top();
        view_top_style = view_style;
        rebuild = 0;
        view_allow_reuse = 0;
        goto refresh_rows;
    }
    cached_top = doc.top;
    cached_width = view_width;
    view_cached_length = doc.length;
    view_previous_selection_start = view_selection_start;
    view_previous_selection_end = view_selection_end;
    view_valid = 1;
    doc.dirty = 0;
    view_row = view_cursor_row;
    view_column = view_cursor_column;
    asm_cursor_show();
    ui_status();
}

void view_reset_column(void) { view_desired_valid = 0; }
