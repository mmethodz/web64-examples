#include "margin64.h"
#include <string.h>

#define TEXT ((uint8_t *)DOCUMENT_BASE)
#define UNDO_BYTES ((uint8_t *)UNDO_BASE)
#define CLIPBOARD ((uint8_t *)CLIPBOARD_BASE)

/* One recent edit, never a rolling history. The fixed payload holds at most
 * 512 bytes. Undo exchanges old/new bytes in that same buffer; Redo only
 * reverses that exchange and needs no second copy or extra transaction type. */
typedef struct {
    uint16_t position, removed, inserted, cursor, anchor;
    uint8_t selecting, state; /* UndoState, including the hysteresis latch */
} RecentEdit;
typedef struct {
    uint16_t position, removed;
    const uint8_t *inserted;
    uint16_t count;
} EditRequest;
typedef struct {
    uint8_t *destination;
    uint16_t position, count;
} CopyRequest;

Document doc;
uint16_t document_dirty_from, document_dirty_to, clipboard_length;
uint8_t *margin_move_from, *margin_move_to;
uint16_t margin_move_count;
EditRequest margin_edit;
CopyRequest margin_copy;
static RecentEdit recent;
void margin_copy_bytes(void);
void margin_exchange_bytes(void);
void margin_apply_edit(void);
void margin_finish_edit(void);

/* Public overlap-safe libc is cheaper than a second application copy loop. */
void margin_move_bytes(void) {
    memmove(margin_move_to, margin_move_from, margin_move_count);
}

void doc_clear_selection(void) {
    doc.anchor = doc.cursor;
    doc.selecting = 0;
    if (doc.dirty != 2) doc.dirty = 1;
}
uint16_t doc_selection_start(void) {
    if (doc.selecting && doc.anchor < doc.cursor) return doc.anchor;
    return doc.cursor;
}
uint16_t doc_selection_end(void) {
    if (doc.selecting && doc.anchor > doc.cursor) return doc.anchor;
    return doc.cursor;
}
void doc_select_all(void) {
    doc.anchor = 0;
    doc.cursor = doc.length;
    doc.selecting = 1;
    if (doc.dirty != 2) doc.dirty = 1;
}
void doc_adopt(uint16_t length) {
    if (length > DOCUMENT_CAPACITY) { doc.error = EDIT_FULL; return; }
    doc.gap = length;
    doc.end = DOCUMENT_CAPACITY;
    doc.length = length;
    doc.cursor = 0;
    doc.anchor = 0;
    doc.top = 0;
    doc.selecting = 0;
    doc.modified = 0;
    doc.overwrite = 0;
    doc.error = EDIT_OK;
    doc.dirty = 2;
    document_dirty_from = 0;
    document_dirty_to = length;
    recent.state = length > UNDO_DISABLE_ABOVE ? UNDO_DISABLED : UNDO_EMPTY;
}
void doc_new(void) { doc_adopt(0); }

/* Every refusal precedes changes to text, gap, selection or the recent edit. */
static uint8_t admit_edit(void) {
    if (margin_edit.position > doc.length ||
        margin_edit.removed > doc.length - margin_edit.position) {
        doc.error = EDIT_RANGE; return 0;
    }
    if (margin_edit.count > DOCUMENT_CAPACITY - (doc.length - margin_edit.removed)) {
        doc.error = EDIT_FULL; return 0;
    }
    if (margin_edit.count && !margin_edit.inserted) {
        doc.error = EDIT_RANGE; return 0;
    }
    return 1;
}
/* Undo is opportunistic, never edit admission. A disabled session must cross
 * the lower watermark before a later edit may create a fresh record. The
 * latch uses the existing state byte, not a second buffer or metadata log. */
static void remember_edit(void) {
    uint16_t next_length;
    next_length = doc.length - margin_edit.removed + margin_edit.count;
    recent.cursor = doc.cursor;
    recent.anchor = doc.anchor;
    recent.selecting = doc.selecting;
    if (next_length > UNDO_DISABLE_ABOVE) {
        recent.state = UNDO_DISABLED;
        return;
    }
    if (recent.state == UNDO_DISABLED) {
        if (next_length <= UNDO_REENABLE_AT) recent.state = UNDO_EMPTY;
        return;
    }
    if (margin_edit.removed > UNDO_CAPACITY || margin_edit.count > UNDO_CAPACITY) {
        recent.state = UNDO_EMPTY;
        return;
    }
    recent.position = margin_edit.position;
    recent.removed = margin_edit.removed;
    recent.inserted = margin_edit.count;
    margin_copy.destination = UNDO_BYTES;
    margin_copy.position = margin_edit.position;
    margin_copy.count = margin_edit.removed;
    margin_copy_bytes();
    recent.state = UNDO_READY;
}

uint8_t doc_replace(uint16_t position, uint16_t removed,
                    const uint8_t *inserted, uint16_t count) {
    margin_edit.position = position;
    margin_edit.removed = removed;
    margin_edit.inserted = inserted;
    margin_edit.count = count;
    if (!admit_edit()) return 0;
    if (!removed && !count) { doc.error = EDIT_OK; return 1; }
    remember_edit();
    margin_apply_edit();
    return 1;
}

uint8_t doc_type(uint8_t argument) {
    static uint8_t value, next;
    static uint16_t start, removed;
    value = argument;
    start = doc_selection_start();
    removed = doc_selection_end() - start;
    if (!removed && doc.overwrite && doc.cursor < doc.length) {
        next = doc_get(doc.cursor);
        if (next != TOKEN_PARAGRAPH && next != TOKEN_LINE && next != TOKEN_PAGE) removed = 1;
    }
    /* Typing replaces the single recent edit; there is no coalescing timer,
     * rolling log or additional metadata on the normal input path. */
    return doc_replace(start, removed, &value, 1);
}
static uint8_t erase(uint8_t backward) {
    static uint16_t start, end;
    start = doc_selection_start();
    end = doc_selection_end();
    if (end == start) {
        if (backward) {
            if (!start) { doc.error = EDIT_OK; return 1; }
            start--;
        } else {
            if (end == doc.length) { doc.error = EDIT_OK; return 1; }
            end++;
        }
    }
    return doc_replace(start, end - start, 0, 0);
}
uint8_t doc_backspace(void) { return erase(1); }
uint8_t doc_delete(void) { return erase(0); }

uint8_t doc_copy(void) {
    static uint16_t start, count;
    start = doc_selection_start();
    count = doc_selection_end() - start;
    if (!count) { doc.error = EDIT_NO_SELECTION; return 0; }
    if (count > CLIPBOARD_CAPACITY) { doc.error = EDIT_CLIPBOARD_FULL; return 0; }
    margin_copy.destination = CLIPBOARD;
    margin_copy.position = start;
    margin_copy.count = count;
    margin_copy_bytes();
    clipboard_length = count;
    doc.error = EDIT_OK;
    return 1;
}
uint8_t doc_cut(void) {
    static uint16_t start, count;
    start = doc_selection_start();
    count = doc_selection_end() - start;
    if (!doc_copy()) return 0;
    return doc_replace(start, count, 0, 0);
}
uint8_t doc_paste(void) {
    static uint16_t start;
    start = doc_selection_start();
    if (!clipboard_length) { doc.error = EDIT_NO_SELECTION; return 0; }
    return doc_replace(start, doc_selection_end() - start, CLIPBOARD, clipboard_length);
}

static uint8_t exchange_recent(uint8_t redo) {
    if (recent.state != (redo ? UNDO_REDO : UNDO_READY)) {
        doc.error = redo ? EDIT_NOTHING_TO_REDO : EDIT_NOTHING_TO_UNDO;
        return 0;
    }
    margin_edit.position = recent.position;
    margin_edit.removed = redo ? recent.removed : recent.inserted;
    margin_edit.count = redo ? recent.inserted : recent.removed;
    doc_move_gap(recent.position);
    margin_exchange_bytes();
    margin_finish_edit();
    if (!redo) {
        doc.cursor = recent.cursor;
        doc.anchor = recent.anchor;
        doc.selecting = recent.selecting;
    }
    recent.state = redo ? UNDO_READY : UNDO_REDO;
    return 1;
}
uint8_t doc_undo(void) { return exchange_recent(0); }
uint8_t doc_redo(void) { return exchange_recent(1); }
uint8_t doc_undo_state(void) { return recent.state; }

/* A small marked range fits the SAME contiguous recent-edit record. Larger
 * formatting continues without Undo. No special transaction type, selection
 * snapshot or metadata grows with document length. */
uint8_t doc_format(uint8_t token) {
    static uint16_t start, end;
    start = doc_selection_start();
    end = doc_selection_end();
    if (token < TOKEN_BOLD || token > TOKEN_EMPHASIS || end > doc.length) {
        doc.error = EDIT_RANGE; return 0;
    }
    if (start == end) return doc_replace(start, 0, &token, 1);
    if (doc.length > DOCUMENT_CAPACITY - 2) { doc.error = EDIT_FULL; return 0; }
    margin_edit.position = start;
    margin_edit.removed = end - start;
    margin_edit.count = margin_edit.removed + 2;
    remember_edit();
    margin_edit.position = end;
    margin_edit.removed = 0;
    margin_edit.inserted = &token;
    margin_edit.count = 1;
    margin_apply_edit();
    margin_edit.position = start;
    margin_apply_edit();
    doc.cursor = recent.cursor + 1;
    doc.anchor = recent.anchor + 1;
    doc.selecting = recent.selecting;
    return 1;
}
