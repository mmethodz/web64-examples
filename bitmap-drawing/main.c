#include <stdint.h>
#include <web64/bitmap.h>

#define BITMAP_MEMORY ((uint8_t *)0x2000)
#define SCREEN_MEMORY ((uint8_t *)0x0400)
#define FLOOD_SPANS 64

Web64Bitmap bitmap;
Web64BitmapPalette palette;
WEB64_BITMAP_FLOOD_STORAGE(flood_workspace, FLOOD_SPANS);
uint8_t verification_status;
uint8_t verification_complete;

void main(void) {
    palette.color0 = 0;
    palette.color1 = 6;
    palette.color2 = 14;
    palette.color3 = 1;

    verification_status = web64_bitmap_init(
        &bitmap,
        BITMAP_MEMORY,
        SCREEN_MEMORY,
        WEB64_BITMAP_MODE_MULTICOLOR,
        &palette
    );
    if (verification_status != WEB64_BITMAP_OK) return;

    WEB64_BITMAP_FLOOD_WORKSPACE_INIT(flood_workspace, FLOOD_SPANS);
    verification_status = web64_bitmap_rect(
        &bitmap, 8, 8, 64, 48, 1, WEB64_BITMAP_OP_REPLACE
    );
    if (verification_status != WEB64_BITMAP_OK) return;

    verification_status = web64_bitmap_flood_fill(
        &bitmap, 10, 10, 2, &flood_workspace
    );
    if (verification_status != WEB64_BITMAP_OK) return;

    web64_bitmap_line_fast(
        &bitmap, 0, 199, 159, 0, 3, WEB64_BITMAP_OP_REPLACE
    );
    web64_bitmap_line_fast(
        &bitmap, 0, 0, 159, 199, 1, WEB64_BITMAP_OP_REPLACE
    );
    web64_bitmap_ellipse(
        &bitmap, 112, 120, 35, 24, 3, WEB64_BITMAP_OP_REPLACE
    );
    web64_bitmap_circle(&bitmap, 112, 120, 10, 1, WEB64_BITMAP_OP_XOR);
    web64_bitmap_dot_fast(&bitmap, 112, 120, 3, WEB64_BITMAP_OP_REPLACE);
    verification_complete = 1;
}
