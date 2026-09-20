/* AURORA - Web64 tutorial. Native project is the source of truth. */
#include <stdint.h>
#include <string.h>
#include <c64.h>
#include <web64/assets.h>
#include "assets/generated.h"

#define SCREEN ((volatile uint8_t *)0x0400)
#define COLOR  ((volatile uint8_t *)0xd800)
#define CHAR_RAM ((uint8_t *)0x3800)
#define SCROLL_ROW 23

static const char message[] =
    "    AURORA - A CHARACTER PLASMA IN WEB64. "
    "TWO WAVES BECOME COLOUR AND TEXTURE. "
    "CUSTOM CHARSET - NATIVE ASSETS - C AND 6502. "
    "EDIT. BUILD. RUN. MAKE IT YOUR OWN!    ";
static uint8_t scroll_clock;
static uint16_t message_pos;

/* C handles the presentation. ASCII indexes match our custom font. */
void caption(uint16_t offset, const char *text, uint8_t colour) {
    while (*text) {
        SCREEN[offset] = *text++;
        COLOR[offset++] = colour;
    }
}

void scroll_text(void) {
    uint8_t x;
    if (++scroll_clock < 3) return;
    scroll_clock = 0;
    for (x = 0; x < 39; ++x)
        SCREEN[SCROLL_ROW * 40 + x] = SCREEN[SCROLL_ROW * 40 + x + 1];
    SCREEN[SCROLL_ROW * 40 + 39] = message[message_pos++];
    if (!message[message_pos]) message_pos = 0;
}

/* A small 6502 kernel keeps the 720-cell inner loop economical.
   It precomputes the horizontal wave once, then adds a row wave.
   Self-modified absolute stores advance across the screen rows.
   Interrupts are disabled: this routine owns its patch locations. */
void plasma_frame(void) {
    asm(".include \"plasma.inc\"");
}

void main(void) {
    asm("sei");
    VIC->border_color = 0;
    VIC->background_color0 = 0;
    VIC->control1 = 0x0b; /* Blank while preparing the display. */
    CIA2->pra = (CIA2->pra & 0xfc) | 3;
    if (web64_asset_copy_charset(CHAR_RAM, &aurora_asset) != WEB64_ASSET_COPY_OK)
        for (;;) { VIC->border_color = 2; }
    memset((void *)SCREEN, 32, 1000);
    memset((void *)COLOR, 3, 1000);
    VIC->memory_setup = 0x1e; /* Screen $0400; charset $3800; VIC bank 0. */
    VIC->control2 = 0x08;
    caption(12, "A U R O R A", 1);
    caption(44, "WEB64  /  CHARACTER PLASMA", 14);
    caption(22 * 40 + 3, "2 WAVES + 16 TEXTURES + C64 COLOUR", 7);
    VIC->control1 = 0x1b;
    for (;;) {
        while (VIC->raster == 250) {}
        while (VIC->raster != 250) {}
        plasma_frame();
        scroll_text();
    }
}
