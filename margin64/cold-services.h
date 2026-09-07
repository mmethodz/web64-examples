#ifndef MARGIN64_COLD_SERVICES_H
#define MARGIN64_COLD_SERVICES_H
#include "margin64.h"

/* Private Margin64 service revision 1. Each target resolves its own labels.
 * No generated resident address is copied into a module or project file.
 * The resident installs JMPs at $6200 and typed pointers at $62a0.
 * A module never calls standalone _start (which would reset the C stack).
 * Cold code must never Open a document or overwrite its own candidate area.
 */
#define COLD_COMMAND (*(uint8_t *)0x62c2)
/* Capture these target pointers into named C pointers on module entry.
 * 0 Document; 1 editor width; 2..5 print width/lines/margin/spacing;
 * 6..7 search case/whole-word; 8 viewport width. */
#define COLD_CONTEXT ((uint16_t *)0x62a0)
#define FIND_TEXT ((char *)0x7000)
#define REPLACE_TEXT ((char *)0x7021)
#define FIND_LIMIT 32

void ui_panel(const char *title);
uint8_t wait_key(void);
uint8_t choice_key(void);
void panel_end(void);

#endif
