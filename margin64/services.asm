; The loader copies this dense template to the reserved $6200 service page.
; Targets use normal stack-v1 calls, except declared A/X fastcall services.
_cold_services_start:
    jmp _doc_get
    jmp _doc_replace
    jmp _ui_prompt
    jmp _ui_confirm
    jmp _ui_message
    jmp asm_key
    jmp _ui_write
    jmp _ui_number
    jmp _view_redraw
    jmp _view_refresh
    jmp _view_reset_column
    jmp _ui_panel
    jmp _wait_key
    jmp _choice_key
    jmp _panel_end
    jmp _doc_format
    jmp _doc_type
    jmp _doc_selection_start
    jmp _doc_selection_end
    jmp _view_invalidate
    jmp _view_page
    jmp _move_word
    jmp _goto_paragraph
    jmp asm_clear_screen
    jmp _ui_petscii
    jmp asm_cursor_hide
_cold_services_end:

asm_context_init:
_asm_context_init:
    ldx #17
cold_context_copy:
    lda cold_context,x
    sta $62a0,x
    dex
    bpl cold_context_copy
    lda #0
    sta $7000
    sta $7021
    rts
cold_context:
    .word _doc, _editor_width, _print_width, _print_lines
    .word _print_margin, _print_spacing, _search_case, _search_whole_word, _view_width
