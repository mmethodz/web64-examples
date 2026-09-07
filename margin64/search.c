#include "cold-services.h"
#pragma charset("screencode_mixed")

/* Disk-loaded search tool. Persistent terms belong to the resident workspace,
 * never the module image or the failure-preserving Open candidate. Search is
 * over logical document bytes; style tokens are not silently removed. */
static uint8_t find_length, replace_length;
static uint16_t found_position;
static Document *state;
static uint8_t *case_setting, *whole_setting;

static uint8_t term_length(const char *text) {
    static uint8_t count;
    count = 0;
    while (count < FIND_LIMIT && text[count]) count++;
    return count;
}

static uint8_t word_byte(uint8_t value) {
    return (value >= 48 && value <= 57) || (value >= 65 && value <= 90) ||
        (value >= 193 && value <= 218);
}

static uint8_t folded(uint8_t value) {
    if (!*case_setting && value >= 193 && value <= 218) value -= 128;
    return value;
}

/* 'previous' is the byte immediately before this position in the searched
 * text. Replace All retains that ORIGINAL byte before replacing a match, so
 * an inserted/deleted word boundary cannot change its preflight match set. */
static uint8_t matches(uint16_t position, uint8_t previous) {
    static uint8_t index;
    if (!find_length || position > state->length || find_length > state->length - position) return 0;
    if (*whole_setting && word_byte(previous)) return 0;
    for (index = 0; index < find_length; index++) {
        if (folded(doc_get(position + index)) != folded(FIND_TEXT[index])) return 0;
    }
    if (*whole_setting && position + find_length < state->length &&
        word_byte(doc_get(position + find_length))) return 0;
    return 1;
}

static uint8_t matches_at(uint16_t position) {
    if (position) return matches(position, doc_get(position - 1));
    return matches(position, 0);
}

static void mark_found(void) {
    state->anchor = found_position;
    state->cursor = found_position + find_length;
    state->selecting = 1;
    if (state->dirty != 2) state->dirty = 1;
    view_reset_column();
}

static uint8_t selected_match(void) {
    found_position = doc_selection_start();
    return state->selecting && doc_selection_end() - found_position == find_length && matches_at(found_position);
}

static uint8_t find_next(uint8_t backward) {
    static uint16_t start, position;
    find_length = term_length(FIND_TEXT);
    if (!find_length) { ui_message("ENTER FIND TEXT FIRST"); return 0; }
    start = state->cursor;
    if (selected_match()) {
        if (backward) start = found_position;
        else start = found_position + find_length;
    }
    if (backward) {
        position = start;
        while (position) {
            position--;
            if (matches_at(position)) { found_position = position; mark_found(); return 1; }
        }
        position = state->length;
        while (position > start) {
            position--;
            if (matches_at(position)) { found_position = position; mark_found(); return 1; }
        }
    } else {
        position = start;
        while (position < state->length) {
            if (matches_at(position)) { found_position = position; mark_found(); return 1; }
            position++;
        }
        position = 0;
        while (position < start) {
            if (matches_at(position)) { found_position = position; mark_found(); return 1; }
            position++;
        }
    }
    ui_message("TEXT NOT FOUND");
    return 0;
}

static void find_dialog(void) {
    if (ui_prompt("FIND TEXT (32 BYTES MAX)", FIND_TEXT, FIND_LIMIT)) {
        /* A new search starts at the caret, not the old selection's anchor. */
        state->selecting = 0;
        if (state->dirty != 2) state->dirty = 1;
        find_next(0);
    }
}

static uint8_t replacement_terms(void) {
    find_length = term_length(FIND_TEXT);
    if (!find_length) {
        if (!ui_prompt("FIND TEXT (32 BYTES MAX)", FIND_TEXT, FIND_LIMIT)) return 0;
        find_length = term_length(FIND_TEXT);
    }
    if (!find_length) { ui_message("EMPTY FIND TEXT - UNCHANGED"); return 0; }
    if (!ui_prompt("REPLACE WITH (EMPTY DELETES)", REPLACE_TEXT, FIND_LIMIT)) return 0;
    replace_length = term_length(REPLACE_TEXT);
    return 1;
}

static void replace_one(void) {
    if (!replacement_terms()) return;
    if (!selected_match() && !find_next(0)) return;
    mark_found();
    if (doc_replace(found_position, find_length, (const uint8_t *)REPLACE_TEXT, replace_length))
        ui_message("ONE MATCH REPLACED");
    else ui_message("REPLACEMENT REFUSED - UNCHANGED");
}

static void replace_all(void) {
    static uint16_t position, matches_found, projected;
    static uint8_t previous, last_original, growth;
    if (!replacement_terms()) return;
    position = 0;
    previous = 0;
    matches_found = 0;
    projected = state->length;
    growth = 0;
    if (replace_length > find_length) growth = replace_length - find_length;
    /* No mutation before every original non-overlapping match fits. Checking
     * each addition avoids overflowing a 16-bit count*replacement product. */
    while (position < state->length) {
        if (matches(position, previous)) {
            matches_found++;
            if (growth) {
                if (projected > DOCUMENT_CAPACITY - growth) {
                    ui_message("REPLACE ALL FULL - TEXT UNCHANGED"); return;
                }
                projected += growth;
            }
            previous = doc_get(position + find_length - 1);
            position += find_length;
        } else {
            previous = doc_get(position);
            position++;
        }
    }
    if (!matches_found) { ui_message("TEXT NOT FOUND"); return; }
    position = 0;
    previous = 0;
    while (position < state->length) {
        if (matches(position, previous)) {
            last_original = doc_get(position + find_length - 1);
            if (!doc_replace(position, find_length, (const uint8_t *)REPLACE_TEXT, replace_length)) {
                ui_message("REPLACE STOPPED - KEEP CURRENT TEXT"); return;
            }
            previous = last_original;
            position += replace_length;
        } else {
            previous = doc_get(position);
            position++;
        }
    }
    /* This is deliberately NOT a whole-command Undo transaction. The normal
     * bounded model retains only its last eligible replacement. */
    ui_message("REPLACED ALL - UNDO: LAST EDIT ONLY");
}

static void statistics(void) {
    static uint16_t position, words, paragraphs;
    static uint8_t value, inside;
    words = 0; paragraphs = 0; inside = 0;
    if (state->length) paragraphs = 1;
    for (position = 0; position < state->length; position++) {
        value = doc_get(position);
        if (value == TOKEN_PARAGRAPH) paragraphs++;
        if (value < TOKEN_BOLD || value > TOKEN_EMPHASIS) {
            if (word_byte(value)) { if (!inside) words++; inside = 1; }
            else inside = 0;
        }
    }
    ui_panel("DOCUMENT STATISTICS");
    ui_write(6, 2, "DOCUMENT BYTES"); ui_number(6, 24, state->length, 5);
    ui_write(9, 2, "WORDS"); ui_number(9, 24, words, 5);
    ui_write(12, 2, "PARAGRAPHS"); ui_number(12, 24, paragraphs, 5);
    ui_write(17, 2, "ANY KEY: RETURN TO YOUR DOCUMENT");
    wait_key(); panel_end();
}

void cold_entry(void) {
    static uint8_t command;
    state = (Document *)COLD_CONTEXT[0];
    case_setting = (uint8_t *)COLD_CONTEXT[6];
    whole_setting = (uint8_t *)COLD_CONTEXT[7];
    command = COLD_COMMAND;
    COLD_COMMAND = 0;
    switch (command) {
        case 6: find_dialog(); break;
        case 7: find_next(0); break;
        case 8: find_next(1); break;
        case 9: replace_one(); break;
        case 10: replace_all(); break;
        case 11: statistics(); break;
    }
}
