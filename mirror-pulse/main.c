#include <stdint.h>
#include <peekpoke.h>
#include <web64/bitmap.h>
#include "courses.h"

#define BITMAP_MEMORY ((uint8_t *)0x2000)
#define SCREEN_MEMORY ((uint8_t *)0x0400)
#define CURRENT_KEY 0x00c5
#define VIC_CONTROL_1 0xd011
#define VIC_RASTER 0xd012
#define VIC_CONTROL_2 0xd016
#define JOYPORT_2 0xdc00
#define JOY_UP 0x01
#define JOY_DOWN 0x02
#define JOY_LEFT 0x04
#define JOY_RIGHT 0x08
#define JOY_FIRE 0x10
#define JOY_RELEASED_MASK 0x1f
#define JOY_UP_P(value) (!((value) & JOY_UP))
#define JOY_DOWN_P(value) (!((value) & JOY_DOWN))
#define JOY_LEFT_P(value) (!((value) & JOY_LEFT))
#define JOY_RIGHT_P(value) (!((value) & JOY_RIGHT))
#define JOY_FIRE_P(value) (!((value) & JOY_FIRE))
#define KEY_NONE 64
#define KEY_RETURN 1
#define KEY_W 9
#define KEY_A 10
#define KEY_S 13
#define KEY_E 14
#define KEY_R 17
#define KEY_D 18
#define KEY_X 23
#define KEY_Q 62
#define KEY_SPACE 60
#define KEY_H 29

#define PIXEL_BACKGROUND 0
#define PIXEL_COURSE 1
#define PIXEL_LASER 2
#define PIXEL_ACCENT 3

#define DIRECTION_RIGHT 0
#define DIRECTION_DOWN 1
#define DIRECTION_LEFT 2
#define DIRECTION_UP 3
#define MIRROR_SLASH 0
#define MIRROR_BACKSLASH 1

#define PICKUP_SCORE 0
#define PICKUP_PULSE 1
#define PICKUP_TIME 2
#define SCORE_NODE_VALUE 250
#define TIME_CELL_SECONDS 30
#define PULSE_CELL_VALUE 3
#define COURSE_CLEAR_VALUE 1000
#define FINAL_PULSE_VALUE 50
#define HIGHSCORE_COUNT 5

#define HUD_DIRTY_SCORE 0x01
#define HUD_DIRTY_TIME 0x02
#define HUD_DIRTY_PULSES 0x04
#define HUD_DIRTY_SELECTION 0x08
#define HUD_DIRTY_ALL 0x0f

#define ACTION_NONE 0
#define ACTION_UP 1
#define ACTION_DOWN 2
#define ACTION_LEFT 3
#define ACTION_RIGHT 4
#define ACTION_PREVIOUS 5
#define ACTION_NEXT 6
#define ACTION_ROTATE 7
#define ACTION_PULSE 8
#define ACTION_RESET 9

#define COURSE_WON 1
#define COURSE_NO_PULSES 2
#define COURSE_TIME_UP 3

static const int8_t direction_x[4] = { 1, 0, -1, 0 };
static const int8_t direction_y[4] = { 0, 1, 0, -1 };
static const uint8_t slash_reflection[4] = { DIRECTION_UP, DIRECTION_LEFT, DIRECTION_DOWN, DIRECTION_RIGHT };
static const uint8_t backslash_reflection[4] = { DIRECTION_DOWN, DIRECTION_RIGHT, DIRECTION_UP, DIRECTION_LEFT };
static const int8_t emitter_tip_x[4] = { 6, 0, -6, 0 };
static const int8_t emitter_tip_y[4] = { 0, 6, 0, -6 };
static const int8_t emitter_wing_1_x[4] = { 3, -3, -3, -3 };
static const int8_t emitter_wing_1_y[4] = { -3, 3, -3, -3 };
static const int8_t emitter_wing_2_x[4] = { 3, 3, -3, 3 };
static const int8_t emitter_wing_2_y[4] = { 3, 3, 3, -3 };
static const uint16_t decimal_powers[5] = { 10000, 1000, 100, 10, 1 };

/* Five-column, seven-row bitmap font: space, 0-9, A-Z, -, :, /, +, ., ?. */
static const uint8_t font5x7[43][5] = {
    { 0x00, 0x00, 0x00, 0x00, 0x00 },
    { 0x3e, 0x51, 0x49, 0x45, 0x3e },
    { 0x00, 0x42, 0x7f, 0x40, 0x00 },
    { 0x42, 0x61, 0x51, 0x49, 0x46 },
    { 0x21, 0x41, 0x45, 0x4b, 0x31 },
    { 0x18, 0x14, 0x12, 0x7f, 0x10 },
    { 0x27, 0x45, 0x45, 0x45, 0x39 },
    { 0x3c, 0x4a, 0x49, 0x49, 0x30 },
    { 0x01, 0x71, 0x09, 0x05, 0x03 },
    { 0x36, 0x49, 0x49, 0x49, 0x36 },
    { 0x06, 0x49, 0x49, 0x29, 0x1e },
    { 0x7e, 0x11, 0x11, 0x11, 0x7e },
    { 0x7f, 0x49, 0x49, 0x49, 0x36 },
    { 0x3e, 0x41, 0x41, 0x41, 0x22 },
    { 0x7f, 0x41, 0x41, 0x22, 0x1c },
    { 0x7f, 0x49, 0x49, 0x49, 0x41 },
    { 0x7f, 0x09, 0x09, 0x09, 0x01 },
    { 0x3e, 0x41, 0x49, 0x49, 0x7a },
    { 0x7f, 0x08, 0x08, 0x08, 0x7f },
    { 0x00, 0x41, 0x7f, 0x41, 0x00 },
    { 0x20, 0x40, 0x41, 0x3f, 0x01 },
    { 0x7f, 0x08, 0x14, 0x22, 0x41 },
    { 0x7f, 0x40, 0x40, 0x40, 0x40 },
    { 0x7f, 0x02, 0x0c, 0x02, 0x7f },
    { 0x7f, 0x04, 0x08, 0x10, 0x7f },
    { 0x3e, 0x41, 0x41, 0x41, 0x3e },
    { 0x7f, 0x09, 0x09, 0x09, 0x06 },
    { 0x3e, 0x41, 0x51, 0x21, 0x5e },
    { 0x7f, 0x09, 0x19, 0x29, 0x46 },
    { 0x46, 0x49, 0x49, 0x49, 0x31 },
    { 0x01, 0x01, 0x7f, 0x01, 0x01 },
    { 0x3f, 0x40, 0x40, 0x40, 0x3f },
    { 0x1f, 0x20, 0x40, 0x20, 0x1f },
    { 0x3f, 0x40, 0x38, 0x40, 0x3f },
    { 0x63, 0x14, 0x08, 0x14, 0x63 },
    { 0x07, 0x08, 0x70, 0x08, 0x07 },
    { 0x61, 0x51, 0x49, 0x45, 0x43 },
    { 0x08, 0x08, 0x08, 0x08, 0x08 },
    { 0x00, 0x36, 0x36, 0x00, 0x00 },
    { 0x20, 0x10, 0x08, 0x04, 0x02 },
    { 0x08, 0x08, 0x3e, 0x08, 0x08 },
    { 0x00, 0x60, 0x60, 0x00, 0x00 },
    { 0x02, 0x01, 0x51, 0x09, 0x06 }
};

Web64Bitmap bitmap;
Web64BitmapPalette palette;

uint8_t course_index;
uint8_t selected_mirror;
uint8_t mirror_x[MAX_MIRRORS];
uint8_t mirror_y[MAX_MIRRORS];
uint8_t mirror_angle[MAX_MIRRORS];
uint8_t pickup_collected[MAX_PICKUPS];
uint8_t pulse_pickup_hit[MAX_PICKUPS];
uint8_t beam_x0[MAX_BEAM_SEGMENTS];
uint8_t beam_y0[MAX_BEAM_SEGMENTS];
uint8_t beam_x1[MAX_BEAM_SEGMENTS];
uint8_t beam_y1[MAX_BEAM_SEGMENTS];
uint8_t beam_segment_count;
uint8_t pulse_goal_reached;
uint8_t pulse_pickup_count;
uint8_t pulses_left;
uint8_t pulses_fired;
uint16_t score;
uint16_t time_left;
uint8_t second_frame;
uint8_t input_last;
uint8_t input_repeat;
uint8_t entry_initials[3];
uint8_t hud_dirty;

#ifdef WEB64_RENDER_VERIFY
uint8_t verification_render_phase;
#endif

uint16_t high_scores[HIGHSCORE_COUNT] = { 12000, 9000, 6500, 4000, 2000 };
uint8_t high_name_0[HIGHSCORE_COUNT] = { 'R', 'L', 'I', 'B', 'D' };
uint8_t high_name_1[HIGHSCORE_COUNT] = { 'A', 'U', 'O', 'E', 'O' };
uint8_t high_name_2[HIGHSCORE_COUNT] = { 'Y', 'X', 'N', 'A', 'T' };

uint8_t verification_status;
uint8_t verification_complete;
uint8_t verification_courses_solved;
uint8_t verification_pickups_collected;
uint8_t verification_segments_traced;
uint8_t verification_move_changed;
uint8_t verification_rotation_changed;

static void wait_frame(void) {
#if defined(WEB64_EXAMPLE_VERIFY) || defined(WEB64_RENDER_VERIFY)
    return;
#else
    while (PEEK(VIC_RASTER) != 250) { }
    while (PEEK(VIC_RASTER) == 250) { }
#endif
}

static uint8_t glyph_index(uint8_t gi_value) {
    if (gi_value == ' ') return 0;
    if (gi_value >= '0' && gi_value <= '9') return 1 + gi_value - '0';
    if (gi_value >= 'A' && gi_value <= 'Z') return 11 + gi_value - 'A';
    if (gi_value == '-') return 37;
    if (gi_value == ':') return 38;
    if (gi_value == '/') return 39;
    if (gi_value == '+') return 40;
    if (gi_value == '.') return 41;
    return 42;
}

static void draw_char(uint8_t dc_x, uint8_t dc_y, uint8_t dc_value, uint8_t dc_pixel) {
    uint8_t dc_column;
    uint8_t dc_row;
    uint8_t dc_bits;
    uint8_t dc_glyph;
    dc_glyph = glyph_index(dc_value);
    dc_column = 0;
    while (dc_column < 5) {
        dc_bits = font5x7[dc_glyph][dc_column];
        dc_row = 0;
        while (dc_row < 7) {
            if ((dc_bits & ((uint8_t)1 << dc_row)) != 0) {
                web64_bitmap_plot_fast(&bitmap, dc_x + dc_column, dc_y + dc_row, dc_pixel, WEB64_BITMAP_OP_REPLACE);
            }
            dc_row++;
        }
        dc_column++;
    }
}

static void draw_text(uint8_t dt_x, uint8_t dt_y, const char *dt_text, uint8_t dt_pixel) {
    while (*dt_text != 0) {
        draw_char(dt_x, dt_y, (uint8_t)*dt_text, dt_pixel);
        dt_x = dt_x + 6;
        dt_text++;
    }
}

static void draw_number(uint8_t dn_x, uint8_t dn_y, uint16_t dn_value, uint8_t dn_digits, uint8_t dn_pixel) {
    uint8_t dn_index;
    uint8_t dn_digit;
    uint16_t dn_power;
    dn_index = 5 - dn_digits;
    while (dn_index < 5) {
        dn_power = decimal_powers[dn_index];
        dn_digit = (uint8_t)(dn_value / dn_power);
        dn_value = dn_value - (uint16_t)dn_digit * dn_power;
        draw_char(dn_x, dn_y, '0' + dn_digit, dn_pixel);
        dn_x = dn_x + 6;
        dn_index++;
    }
}

static void draw_box(uint8_t db_x, uint8_t db_y, uint8_t db_width, uint8_t db_height, uint8_t db_pixel, uint8_t db_operation) {
    uint8_t db_right;
    uint8_t db_bottom;
    db_right = db_x + db_width - 1;
    db_bottom = db_y + db_height - 1;
    web64_bitmap_hline_fast(&bitmap, db_x, db_y, db_width, db_pixel, db_operation);
    web64_bitmap_hline_fast(&bitmap, db_x, db_bottom, db_width, db_pixel, db_operation);
    web64_bitmap_vline_fast(&bitmap, db_x, db_y + 1, db_height - 2, db_pixel, db_operation);
    web64_bitmap_vline_fast(&bitmap, db_right, db_y + 1, db_height - 2, db_pixel, db_operation);
}

static void fill_box(uint8_t fb_x, uint8_t fb_y, uint8_t fb_width, uint8_t fb_height, uint8_t fb_pixel) {
    uint8_t fb_row;
    fb_row = 0;
    while (fb_row < fb_height) {
        web64_bitmap_hline_fast(&bitmap, fb_x, fb_y + fb_row, fb_width, fb_pixel, WEB64_BITMAP_OP_REPLACE);
        fb_row++;
    }
}

static void draw_course_name(uint8_t dcn_x, uint8_t dcn_y) {
    if (course_index == 0) draw_text(dcn_x, dcn_y, "FIRST LIGHT", PIXEL_COURSE);
    else if (course_index == 1) draw_text(dcn_x, dcn_y, "CROSS CURRENT", PIXEL_COURSE);
    else if (course_index == 2) draw_text(dcn_x, dcn_y, "SKY HOOK", PIXEL_COURSE);
    else if (course_index == 3) draw_text(dcn_x, dcn_y, "BACK DRAFT", PIXEL_COURSE);
    else if (course_index == 4) draw_text(dcn_x, dcn_y, "FIVE FOLD", PIXEL_COURSE);
    else draw_text(dcn_x, dcn_y, "FINAL CIRCUIT", PIXEL_COURSE);
}

static void refresh_hud(void) {
    if ((hud_dirty & HUD_DIRTY_SCORE) != 0) {
        fill_box(7, 10, 29, 7, PIXEL_BACKGROUND);
        draw_number(7, 10, score, 5, PIXEL_ACCENT);
    }
    if ((hud_dirty & HUD_DIRTY_TIME) != 0) {
        fill_box(46, 10, 17, 7, PIXEL_BACKGROUND);
        draw_number(46, 10, time_left, 3, PIXEL_ACCENT);
    }
    if ((hud_dirty & HUD_DIRTY_PULSES) != 0) {
        fill_box(73, 10, 11, 7, PIXEL_BACKGROUND);
        draw_number(73, 10, pulses_left, 2, PIXEL_LASER);
    }
    if ((hud_dirty & HUD_DIRTY_SELECTION) != 0) {
        fill_box(97, 10, 5, 7, PIXEL_BACKGROUND);
        draw_number(97, 10, selected_mirror + 1, 1, PIXEL_ACCENT);
    }
    hud_dirty = 0;
}

static void draw_hud(void) {
    draw_text(1, 1, "C", PIXEL_ACCENT);
    draw_number(7, 1, course_index + 1, 1, PIXEL_ACCENT);
    draw_course_name(17, 1);
    draw_text(1, 10, "S", PIXEL_ACCENT);
    draw_text(40, 10, "T", PIXEL_ACCENT);
    draw_text(67, 10, "P", PIXEL_ACCENT);
    draw_text(91, 10, "M", PIXEL_ACCENT);
    draw_text(103, 10, "/", PIXEL_COURSE);
    draw_number(109, 10, course_mirror_count[course_index], 1, PIXEL_COURSE);
    web64_bitmap_line_fast(&bitmap, 0, 19, 159, 19, PIXEL_COURSE, WEB64_BITMAP_OP_REPLACE);
    hud_dirty = HUD_DIRTY_ALL;
    refresh_hud();
}

static void draw_emitter(void) {
    uint8_t de_x;
    uint8_t de_y;
    uint8_t de_direction;
    uint8_t de_tip_x;
    uint8_t de_tip_y;
    de_x = course_emitter_x[course_index];
    de_y = course_emitter_y[course_index];
    de_direction = course_emitter_direction[course_index];
    de_tip_x = de_x + emitter_tip_x[de_direction];
    de_tip_y = de_y + emitter_tip_y[de_direction];
    draw_box(de_x - 3, de_y - 3, 7, 7, PIXEL_ACCENT, WEB64_BITMAP_OP_REPLACE);
    web64_bitmap_line_fast(&bitmap, de_x, de_y, de_tip_x, de_tip_y, PIXEL_ACCENT, WEB64_BITMAP_OP_REPLACE);
    web64_bitmap_line_fast(&bitmap, de_tip_x, de_tip_y, de_x + emitter_wing_1_x[de_direction], de_y + emitter_wing_1_y[de_direction], PIXEL_ACCENT, WEB64_BITMAP_OP_REPLACE);
    web64_bitmap_line_fast(&bitmap, de_tip_x, de_tip_y, de_x + emitter_wing_2_x[de_direction], de_y + emitter_wing_2_y[de_direction], PIXEL_ACCENT, WEB64_BITMAP_OP_REPLACE);
}

static void draw_target(void) {
    uint8_t dta_x;
    uint8_t dta_y;
    dta_x = course_target_x[course_index];
    dta_y = course_target_y[course_index];
    draw_box(dta_x - 5, dta_y - 5, 11, 11, PIXEL_LASER, WEB64_BITMAP_OP_REPLACE);
    web64_bitmap_line_fast(&bitmap, dta_x - 3, dta_y, dta_x + 3, dta_y, PIXEL_LASER, WEB64_BITMAP_OP_REPLACE);
    web64_bitmap_line_fast(&bitmap, dta_x, dta_y - 3, dta_x, dta_y + 3, PIXEL_LASER, WEB64_BITMAP_OP_REPLACE);
}

static void toggle_pickup(uint8_t dp_pickup) {
    uint8_t dp_x;
    uint8_t dp_y;
    uint8_t dp_type;
    dp_x = course_pickup_x[course_index][dp_pickup];
    dp_y = course_pickup_y[course_index][dp_pickup];
    dp_type = course_pickup_type[course_index][dp_pickup];
    if (dp_type == PICKUP_SCORE) {
        web64_bitmap_line_fast(&bitmap, dp_x, dp_y - 4, dp_x + 4, dp_y, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
        web64_bitmap_line_fast(&bitmap, dp_x + 3, dp_y + 1, dp_x, dp_y + 4, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
        web64_bitmap_line_fast(&bitmap, dp_x - 1, dp_y + 3, dp_x - 4, dp_y, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
        web64_bitmap_line_fast(&bitmap, dp_x - 3, dp_y - 1, dp_x - 1, dp_y - 3, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
    } else if (dp_type == PICKUP_PULSE) {
        draw_box(dp_x - 4, dp_y - 4, 9, 9, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
        web64_bitmap_line_fast(&bitmap, dp_x - 2, dp_y, dp_x + 2, dp_y, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
        web64_bitmap_line_fast(&bitmap, dp_x, dp_y - 2, dp_x, dp_y + 2, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
        web64_bitmap_plot_fast(&bitmap, dp_x, dp_y, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
    } else {
        web64_bitmap_line_fast(&bitmap, dp_x - 4, dp_y - 4, dp_x + 4, dp_y - 4, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
        web64_bitmap_line_fast(&bitmap, dp_x - 4, dp_y + 4, dp_x + 4, dp_y + 4, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
        web64_bitmap_line_fast(&bitmap, dp_x + 3, dp_y - 3, dp_x - 3, dp_y + 3, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
        web64_bitmap_line_fast(&bitmap, dp_x - 3, dp_y - 3, dp_x + 3, dp_y + 3, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
        web64_bitmap_plot_fast(&bitmap, dp_x, dp_y, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR);
    }
}

static void toggle_mirror(uint8_t dm_index) {
    uint8_t dm_x;
    uint8_t dm_y;
    uint8_t dm_y0;
    uint8_t dm_y1;
    uint8_t dm_y2;
    dm_x = mirror_x[dm_index];
    dm_y = mirror_y[dm_index];
    if (mirror_angle[dm_index] == MIRROR_SLASH) {
        dm_y0 = dm_y + 5;
        dm_y1 = dm_y - 5;
        dm_y2 = dm_y - 4;
    } else {
        dm_y0 = dm_y - 5;
        dm_y1 = dm_y + 5;
        dm_y2 = dm_y + 4;
    }
    web64_bitmap_line_fast(&bitmap, dm_x - 5, dm_y0, dm_x + 5, dm_y1, PIXEL_COURSE, WEB64_BITMAP_OP_XOR);
    web64_bitmap_line_fast(&bitmap, dm_x - 4, dm_y0, dm_x + 5, dm_y2, PIXEL_COURSE, WEB64_BITMAP_OP_XOR);
}

static void toggle_selection(void) {
    draw_box(
        mirror_x[selected_mirror] - 7, mirror_y[selected_mirror] - 7,
        15, 15, PIXEL_ACCENT, WEB64_BITMAP_OP_XOR
    );
}

static void draw_playfield(void) {
    uint8_t dpf_index;
    web64_bitmap_clear(&bitmap, PIXEL_BACKGROUND);
    draw_box(1, 20, 158, 179, PIXEL_COURSE, WEB64_BITMAP_OP_REPLACE);
    dpf_index = 0;
    while (dpf_index < course_wall_count[course_index]) {
        fill_box(
            course_wall_x[course_index][dpf_index],
            course_wall_y[course_index][dpf_index],
            course_wall_width[course_index][dpf_index],
            course_wall_height[course_index][dpf_index],
            PIXEL_COURSE
        );
        dpf_index++;
    }
    draw_emitter();
    draw_target();
    dpf_index = 0;
    while (dpf_index < course_pickup_count[course_index]) {
        if (pickup_collected[dpf_index] == 0) toggle_pickup(dpf_index);
        dpf_index++;
    }
    dpf_index = 0;
    while (dpf_index < course_mirror_count[course_index]) {
        toggle_mirror(dpf_index);
        dpf_index++;
    }
    toggle_selection();
    draw_hud();
}

static void add_score(uint16_t as_value) {
    if (score > (uint16_t)(65535 - as_value)) score = 65535;
    else score = score + as_value;
    hud_dirty = hud_dirty | HUD_DIRTY_SCORE;
}

static uint8_t point_in_wall(uint8_t piw_x, uint8_t piw_y) {
    uint8_t piw_wall;
    piw_wall = 0;
    while (piw_wall < course_wall_count[course_index]) {
        if (piw_x >= course_wall_x[course_index][piw_wall]
            && piw_x < course_wall_x[course_index][piw_wall] + course_wall_width[course_index][piw_wall]
            && piw_y >= course_wall_y[course_index][piw_wall]
            && piw_y < course_wall_y[course_index][piw_wall] + course_wall_height[course_index][piw_wall]) return 1;
        piw_wall++;
    }
    return 0;
}

static int8_t mirror_at(uint8_t ma_x, uint8_t ma_y) {
    uint8_t ma_mirror;
    ma_mirror = 0;
    while (ma_mirror < course_mirror_count[course_index]) {
        if (mirror_x[ma_mirror] == ma_x && mirror_y[ma_mirror] == ma_y) return (int8_t)ma_mirror;
        ma_mirror++;
    }
    return -1;
}

static uint8_t mirror_position_blocked(uint8_t mpb_x, uint8_t mpb_y) {
    uint8_t mpb_index;
    uint8_t mpb_wx;
    uint8_t mpb_wy;
    uint8_t mpb_ww;
    uint8_t mpb_wh;
    if (mpb_x < 10 || mpb_x > 150 || mpb_y < 30 || mpb_y > 190) return 1;
    if (mpb_x == course_emitter_x[course_index] && mpb_y == course_emitter_y[course_index]) return 1;
    if (mpb_x == course_target_x[course_index] && mpb_y == course_target_y[course_index]) return 1;
    mpb_index = 0;
    while (mpb_index < course_mirror_count[course_index]) {
        if (mpb_index != selected_mirror && mirror_x[mpb_index] == mpb_x && mirror_y[mpb_index] == mpb_y) return 1;
        mpb_index++;
    }
    mpb_index = 0;
    while (mpb_index < course_pickup_count[course_index]) {
        if (pickup_collected[mpb_index] == 0
            && course_pickup_x[course_index][mpb_index] == mpb_x
            && course_pickup_y[course_index][mpb_index] == mpb_y) return 1;
        mpb_index++;
    }
    mpb_index = 0;
    while (mpb_index < course_wall_count[course_index]) {
        mpb_wx = course_wall_x[course_index][mpb_index];
        mpb_wy = course_wall_y[course_index][mpb_index];
        mpb_ww = course_wall_width[course_index][mpb_index];
        mpb_wh = course_wall_height[course_index][mpb_index];
        if ((uint16_t)mpb_x + 6 >= mpb_wx && mpb_x <= mpb_wx + mpb_ww + 5
            && (uint16_t)mpb_y + 6 >= mpb_wy && mpb_y <= mpb_wy + mpb_wh + 5) return 1;
        mpb_index++;
    }
    return 0;
}

static uint8_t move_selected(int8_t ms_dx, int8_t ms_dy) {
    uint8_t ms_next_x;
    uint8_t ms_next_y;
    ms_next_x = mirror_x[selected_mirror] + ms_dx;
    ms_next_y = mirror_y[selected_mirror] + ms_dy;
    if (mirror_position_blocked(ms_next_x, ms_next_y) != 0) return 0;
    toggle_selection();
    toggle_mirror(selected_mirror);
    mirror_x[selected_mirror] = ms_next_x;
    mirror_y[selected_mirror] = ms_next_y;
    toggle_mirror(selected_mirror);
    toggle_selection();
    return 1;
}

static void rotate_selected(void) {
    toggle_mirror(selected_mirror);
    mirror_angle[selected_mirror] = mirror_angle[selected_mirror] ^ 1;
    toggle_mirror(selected_mirror);
}

static void select_mirror(uint8_t sm_index) {
    toggle_selection();
    selected_mirror = sm_index;
    toggle_selection();
    hud_dirty = hud_dirty | HUD_DIRTY_SELECTION;
    refresh_hud();
}

static void reset_layout(void) {
    uint8_t rl_index;
    rl_index = 0;
    while (rl_index < course_mirror_count[course_index]) {
        mirror_x[rl_index] = course_mirror_x[course_index][rl_index];
        mirror_y[rl_index] = course_mirror_y[course_index][rl_index];
        mirror_angle[rl_index] = course_mirror_angle[course_index][rl_index];
        rl_index++;
    }
    selected_mirror = 0;
}

static void reset_layout_visible(void) {
    uint8_t rlv_index;
    toggle_selection();
    rlv_index = 0;
    while (rlv_index < course_mirror_count[course_index]) {
        toggle_mirror(rlv_index);
        rlv_index++;
    }
    reset_layout();
    rlv_index = 0;
    while (rlv_index < course_mirror_count[course_index]) {
        toggle_mirror(rlv_index);
        rlv_index++;
    }
    toggle_selection();
    hud_dirty = hud_dirty | HUD_DIRTY_SELECTION;
    refresh_hud();
}

static void load_course(void) {
    uint8_t lc_index;
    uint16_t lc_pulse_total;
    reset_layout();
    lc_index = 0;
    while (lc_index < MAX_PICKUPS) {
        pickup_collected[lc_index] = 0;
        pulse_pickup_hit[lc_index] = 0;
        lc_index++;
    }
    time_left = course_time[course_index];
    second_frame = 0;
    lc_pulse_total = pulses_left + course_pulse_grant[course_index];
    if (lc_pulse_total > 99) pulses_left = 99;
    else pulses_left = (uint8_t)lc_pulse_total;
    input_last = ACTION_NONE;
    input_repeat = 0;
}

static uint8_t tick_course_clock(void) {
    if (time_left == 0) return 0;
    second_frame++;
    if (second_frame < 50) return 0;
    second_frame = 0;
    time_left--;
    hud_dirty = hud_dirty | HUD_DIRTY_TIME;
    return 1;
}

static void trace_pulse(void) {
    uint8_t tp_segment;
    uint8_t tp_index;
    uint8_t tp_direction;
    uint8_t tp_reflected;
    uint8_t tp_stop;
    int8_t tp_hit_mirror;
    int16_t tp_beam_cursor_x;
    int16_t tp_beam_cursor_y;
    int16_t tp_next_x;
    int16_t tp_next_y;
    uint8_t tp_pickup_x;
    uint8_t tp_pickup_y;
    beam_segment_count = 0;
    pulse_goal_reached = 0;
    pulse_pickup_count = 0;
    tp_index = 0;
    while (tp_index < MAX_PICKUPS) {
        pulse_pickup_hit[tp_index] = 0;
        tp_index++;
    }
    tp_beam_cursor_x = course_emitter_x[course_index];
    tp_beam_cursor_y = course_emitter_y[course_index];
    tp_direction = course_emitter_direction[course_index];
    tp_segment = 0;
    while (tp_segment < MAX_BEAM_SEGMENTS) {
        beam_x0[tp_segment] = (uint8_t)tp_beam_cursor_x;
        beam_y0[tp_segment] = (uint8_t)tp_beam_cursor_y;
        /* Give each reflected joint to the preceding XOR segment so the
           shared endpoint is toggled once rather than cancelling itself. */
        if (tp_segment != 0) {
            beam_x0[tp_segment] = beam_x0[tp_segment] + direction_x[tp_direction];
            beam_y0[tp_segment] = beam_y0[tp_segment] + direction_y[tp_direction];
        }
        tp_reflected = 0;
        tp_stop = 0;
        while (tp_stop == 0) {
            tp_next_x = tp_beam_cursor_x + direction_x[tp_direction];
            tp_next_y = tp_beam_cursor_y + direction_y[tp_direction];
            if (tp_next_x < 2 || tp_next_x > 157 || tp_next_y < 22 || tp_next_y > 197) {
                tp_stop = 1;
            } else {
                tp_beam_cursor_x = tp_next_x;
                tp_beam_cursor_y = tp_next_y;
                tp_index = 0;
                while (tp_index < course_pickup_count[course_index]) {
                    tp_pickup_x = course_pickup_x[course_index][tp_index];
                    tp_pickup_y = course_pickup_y[course_index][tp_index];
                    if (pickup_collected[tp_index] == 0
                        && tp_pickup_x == (uint8_t)tp_beam_cursor_x
                        && tp_pickup_y == (uint8_t)tp_beam_cursor_y) {
                        pulse_pickup_hit[tp_index] = 1;
                    }
                    tp_index++;
                }
                if (course_target_x[course_index] == (uint8_t)tp_beam_cursor_x
                    && course_target_y[course_index] == (uint8_t)tp_beam_cursor_y) {
                    pulse_goal_reached = 1;
                    tp_stop = 1;
                } else if (point_in_wall((uint8_t)tp_beam_cursor_x, (uint8_t)tp_beam_cursor_y) != 0) {
                    tp_stop = 1;
                } else {
                    tp_hit_mirror = mirror_at((uint8_t)tp_beam_cursor_x, (uint8_t)tp_beam_cursor_y);
                    if (tp_hit_mirror >= 0) {
                        if (mirror_angle[(uint8_t)tp_hit_mirror] == MIRROR_SLASH) tp_direction = slash_reflection[tp_direction];
                        else tp_direction = backslash_reflection[tp_direction];
                        tp_reflected = 1;
                        tp_stop = 1;
                    }
                }
            }
        }
        beam_x1[tp_segment] = (uint8_t)tp_beam_cursor_x;
        beam_y1[tp_segment] = (uint8_t)tp_beam_cursor_y;
        beam_segment_count++;
        tp_segment++;
        if (pulse_goal_reached != 0 || tp_reflected == 0) return;
    }
}

static void collect_pulse_pickups(void) {
    uint8_t cpp_index;
    uint8_t cpp_type;
    uint16_t cpp_total;
    cpp_index = 0;
    while (cpp_index < course_pickup_count[course_index]) {
        if (pulse_pickup_hit[cpp_index] != 0 && pickup_collected[cpp_index] == 0) {
            pickup_collected[cpp_index] = 1;
            pulse_pickup_count++;
            cpp_type = course_pickup_type[course_index][cpp_index];
            if (cpp_type == PICKUP_SCORE) add_score(SCORE_NODE_VALUE);
            else if (cpp_type == PICKUP_PULSE) {
                cpp_total = pulses_left + PULSE_CELL_VALUE;
                if (cpp_total > 99) pulses_left = 99;
                else pulses_left = (uint8_t)cpp_total;
                hud_dirty = hud_dirty | HUD_DIRTY_PULSES;
            } else {
                cpp_total = time_left + TIME_CELL_SECONDS;
                if (cpp_total > 999) time_left = 999;
                else time_left = cpp_total;
                hud_dirty = hud_dirty | HUD_DIRTY_TIME;
            }
        }
        cpp_index++;
    }
}

static void animate_pulse(void) {
    uint8_t ap_segment;
    uint8_t ap_hold;
    ap_segment = 0;
    while (ap_segment < beam_segment_count) {
        web64_bitmap_line_fast(
            &bitmap,
            beam_x0[ap_segment], beam_y0[ap_segment],
            beam_x1[ap_segment], beam_y1[ap_segment],
            PIXEL_LASER, WEB64_BITMAP_OP_XOR
        );
        wait_frame();
        if (tick_course_clock() != 0) refresh_hud();
        ap_segment++;
    }
    ap_hold = 0;
    while (ap_hold < 4) {
        wait_frame();
        if (tick_course_clock() != 0) refresh_hud();
        ap_hold++;
    }
    ap_segment = 0;
    while (ap_segment < beam_segment_count) {
        web64_bitmap_line_fast(
            &bitmap,
            beam_x0[ap_segment], beam_y0[ap_segment],
            beam_x1[ap_segment], beam_y1[ap_segment],
            PIXEL_LASER, WEB64_BITMAP_OP_XOR
        );
        ap_segment++;
    }
    ap_segment = 0;
    while (ap_segment < course_pickup_count[course_index]) {
        if (pulse_pickup_hit[ap_segment] != 0) toggle_pickup(ap_segment);
        ap_segment++;
    }
    refresh_hud();
}

static uint8_t fire_pulse(void) {
    if (pulses_left == 0) return 0;
    pulses_left--;
    hud_dirty = hud_dirty | HUD_DIRTY_PULSES;
    pulses_fired++;
    trace_pulse();
    collect_pulse_pickups();
    refresh_hud();
    animate_pulse();
    return 1;
}

#if !defined(WEB64_EXAMPLE_VERIFY) && !defined(WEB64_RENDER_VERIFY)
static uint8_t decode_keyboard(uint8_t dk_key) {
    if (dk_key == KEY_W) return ACTION_UP;
    if (dk_key == KEY_S) return ACTION_DOWN;
    if (dk_key == KEY_A) return ACTION_LEFT;
    if (dk_key == KEY_D) return ACTION_RIGHT;
    if (dk_key == KEY_Q) return ACTION_PREVIOUS;
    if (dk_key == KEY_E) return ACTION_NEXT;
    if (dk_key == KEY_R) return ACTION_ROTATE;
    if (dk_key == KEY_SPACE || dk_key == KEY_RETURN) return ACTION_PULSE;
    if (dk_key == KEY_X) return ACTION_RESET;
    return ACTION_NONE;
}

static uint8_t decode_joystick(uint8_t dj_joy) {
    if (JOY_FIRE_P(dj_joy)) {
        if (JOY_UP_P(dj_joy)) return ACTION_PULSE;
        if (JOY_DOWN_P(dj_joy)) return ACTION_RESET;
        if (JOY_LEFT_P(dj_joy)) return ACTION_PREVIOUS;
        if (JOY_RIGHT_P(dj_joy)) return ACTION_NEXT;
        return ACTION_ROTATE;
    }
    if (JOY_UP_P(dj_joy)) return ACTION_UP;
    if (JOY_DOWN_P(dj_joy)) return ACTION_DOWN;
    if (JOY_LEFT_P(dj_joy)) return ACTION_LEFT;
    if (JOY_RIGHT_P(dj_joy)) return ACTION_RIGHT;
    return ACTION_NONE;
}

static uint8_t poll_game_action(void) {
    uint8_t pga_command;
    uint8_t pga_key;
    uint8_t pga_joy;
    pga_key = PEEK(CURRENT_KEY);
    pga_command = decode_keyboard(pga_key);
    if (pga_command == ACTION_NONE) {
        pga_joy = PEEK(JOYPORT_2);
        pga_command = decode_joystick(pga_joy);
    }
    if (pga_command == ACTION_NONE) {
        input_last = ACTION_NONE;
        input_repeat = 0;
        return ACTION_NONE;
    }
    if (pga_command != input_last) {
        input_last = pga_command;
        input_repeat = 10;
        return pga_command;
    }
    if (pga_command >= ACTION_UP && pga_command <= ACTION_RIGHT) {
        if (input_repeat == 0) {
            input_repeat = 4;
            return pga_command;
        }
        input_repeat--;
    }
    return ACTION_NONE;
}

static void wait_input_release(void) {
#ifdef WEB64_EXAMPLE_VERIFY
    return;
#else
    while (PEEK(CURRENT_KEY) != KEY_NONE || (PEEK(JOYPORT_2) & JOY_RELEASED_MASK) != JOY_RELEASED_MASK) wait_frame();
#endif
}

static uint8_t wait_menu_choice(void) {
    uint8_t wmc_key;
    uint8_t wmc_joy;
    wait_input_release();
    while (1) {
        wait_frame();
        wmc_key = PEEK(CURRENT_KEY);
        wmc_joy = PEEK(JOYPORT_2);
        if (wmc_key == KEY_H || JOY_DOWN_P(wmc_joy)) return 2;
        if (wmc_key == KEY_SPACE || wmc_key == KEY_RETURN || JOY_FIRE_P(wmc_joy)) return 1;
    }
}

static void draw_title(void) {
    web64_bitmap_clear(&bitmap, PIXEL_BACKGROUND);
    draw_box(3, 3, 154, 194, PIXEL_COURSE, WEB64_BITMAP_OP_REPLACE);
    draw_text(43, 14, "MIRROR PULSE", PIXEL_LASER);
    draw_text(28, 27, "ALIGN FIRE REFLECT", PIXEL_ACCENT);
    draw_text(13, 43, "WASD MOVE  Q/E SELECT", PIXEL_COURSE);
    draw_text(13, 55, "R ROTATE  X RESET", PIXEL_COURSE);
    draw_text(13, 67, "SPACE/FIRE PULSE JOY2", PIXEL_COURSE);
    draw_text(8, 94, "DIAMOND SCORE BOX PULSES", PIXEL_ACCENT);
    draw_text(19, 106, "HOURGLASS EXTRA TIME", PIXEL_ACCENT);
    draw_text(8, 164, "FINITE PULSES NO PREVIEW", PIXEL_LASER);
    draw_text(31, 177, "FIRE OR SPACE START", PIXEL_ACCENT);
    draw_text(43, 187, "H FOR HIGH SCORES", PIXEL_COURSE);
}

static void draw_course_intro(void) {
    web64_bitmap_clear(&bitmap, PIXEL_BACKGROUND);
    draw_box(6, 12, 148, 176, PIXEL_COURSE, WEB64_BITMAP_OP_REPLACE);
    draw_text(55, 27, "COURSE", PIXEL_ACCENT);
    draw_number(97, 27, course_index + 1, 1, PIXEL_ACCENT);
    draw_course_name(40, 48);
    draw_text(34, 74, "TIME LIMIT", PIXEL_COURSE);
    draw_number(100, 74, time_left, 3, PIXEL_LASER);
    draw_text(34, 88, "PULSE GRANT", PIXEL_COURSE);
    draw_text(106, 88, "+", PIXEL_LASER);
    draw_number(112, 88, course_pulse_grant[course_index], 1, PIXEL_LASER);
    draw_text(28, 157, "FIRE OR SPACE TO AIM", PIXEL_LASER);
}

static void draw_course_clear(uint16_t dcc_time_bonus) {
    web64_bitmap_clear(&bitmap, PIXEL_BACKGROUND);
    draw_box(8, 15, 144, 170, PIXEL_COURSE, WEB64_BITMAP_OP_REPLACE);
    draw_text(43, 30, "COURSE CLEAR", PIXEL_LASER);
    draw_text(31, 66, "TIME BONUS", PIXEL_COURSE);
    draw_number(97, 66, dcc_time_bonus, 4, PIXEL_ACCENT);
    draw_text(31, 108, "TOTAL", PIXEL_COURSE);
    draw_number(73, 108, score, 5, PIXEL_ACCENT);
    if (course_index + 1 < COURSE_COUNT) draw_text(28, 151, "FIRE FOR NEXT COURSE", PIXEL_LASER);
    else draw_text(37, 151, "FIRE FOR RESULTS", PIXEL_LASER);
}

static void draw_game_over(uint8_t dgo_reason) {
    web64_bitmap_clear(&bitmap, PIXEL_BACKGROUND);
    draw_box(8, 15, 144, 170, PIXEL_COURSE, WEB64_BITMAP_OP_REPLACE);
    draw_text(49, 34, "RUN OVER", PIXEL_LASER);
    if (dgo_reason == COURSE_NO_PULSES) draw_text(31, 63, "PULSE BANK EMPTY", PIXEL_ACCENT);
    else draw_text(43, 63, "TIME EXPIRED", PIXEL_ACCENT);
    draw_text(37, 91, "COURSES CLEARED", PIXEL_COURSE);
    draw_number(127, 91, course_index, 1, PIXEL_COURSE);
    draw_text(43, 108, "FINAL SCORE", PIXEL_COURSE);
    draw_number(55, 123, score, 5, PIXEL_ACCENT);
    draw_text(31, 155, "FIRE FOR HIGH SCORES", PIXEL_LASER);
}

static void draw_campaign_clear(void) {
    web64_bitmap_clear(&bitmap, PIXEL_BACKGROUND);
    draw_box(8, 15, 144, 170, PIXEL_COURSE, WEB64_BITMAP_OP_REPLACE);
    draw_text(28, 30, "ALL COURSES COMPLETE", PIXEL_LASER);
    draw_text(43, 104, "FINAL SCORE", PIXEL_COURSE);
    draw_number(55, 119, score, 5, PIXEL_ACCENT);
    draw_text(31, 155, "FIRE FOR HIGH SCORES", PIXEL_LASER);
}

static void draw_high_score_row(uint8_t dhsr_index, uint8_t dhsr_pixel) {
    uint8_t dhsr_y;
    dhsr_y = 52 + dhsr_index * 22;
    draw_number(32, dhsr_y, dhsr_index + 1, 1, dhsr_pixel);
    draw_char(44, dhsr_y, high_name_0[dhsr_index], dhsr_pixel);
    draw_char(50, dhsr_y, high_name_1[dhsr_index], dhsr_pixel);
    draw_char(56, dhsr_y, high_name_2[dhsr_index], dhsr_pixel);
    draw_number(79, dhsr_y, high_scores[dhsr_index], 5, dhsr_pixel);
}

static void draw_high_scores(int8_t dhs_highlight) {
    uint8_t dhs_index;
    web64_bitmap_clear(&bitmap, PIXEL_BACKGROUND);
    draw_box(16, 10, 128, 180, PIXEL_COURSE, WEB64_BITMAP_OP_REPLACE);
    draw_text(43, 24, "HIGH SCORES", PIXEL_LASER);
    dhs_index = 0;
    while (dhs_index < HIGHSCORE_COUNT) {
        if ((int8_t)dhs_index == dhs_highlight) draw_high_score_row(dhs_index, PIXEL_ACCENT);
        else draw_high_score_row(dhs_index, PIXEL_COURSE);
        dhs_index++;
    }
    draw_text(28, 171, "FIRE OR SPACE RETURN", PIXEL_ACCENT);
}

static int8_t high_score_position(uint16_t hsp_value) {
    uint8_t hsp_index;
    hsp_index = 0;
    while (hsp_index < HIGHSCORE_COUNT) {
        if (hsp_value > high_scores[hsp_index]) return (int8_t)hsp_index;
        hsp_index++;
    }
    return -1;
}
#endif

static void insert_high_score(uint16_t ihs_value, const uint8_t *ihs_name, uint8_t ihs_position) {
    if (ihs_position < 4) {
        high_scores[4] = high_scores[3];
        high_name_0[4] = high_name_0[3];
        high_name_1[4] = high_name_1[3];
        high_name_2[4] = high_name_2[3];
    }
    if (ihs_position < 3) {
        high_scores[3] = high_scores[2];
        high_name_0[3] = high_name_0[2];
        high_name_1[3] = high_name_1[2];
        high_name_2[3] = high_name_2[2];
    }
    if (ihs_position < 2) {
        high_scores[2] = high_scores[1];
        high_name_0[2] = high_name_0[1];
        high_name_1[2] = high_name_1[1];
        high_name_2[2] = high_name_2[1];
    }
    if (ihs_position < 1) {
        high_scores[1] = high_scores[0];
        high_name_0[1] = high_name_0[0];
        high_name_1[1] = high_name_1[0];
        high_name_2[1] = high_name_2[0];
    }
    high_scores[ihs_position] = ihs_value;
    high_name_0[ihs_position] = ihs_name[0];
    high_name_1[ihs_position] = ihs_name[1];
    high_name_2[ihs_position] = ihs_name[2];
}

#if !defined(WEB64_EXAMPLE_VERIFY) && !defined(WEB64_RENDER_VERIFY)
static void enter_high_score(uint8_t ehs_position) {
    uint8_t ehs_cursor;
    uint8_t ehs_changed;
    uint8_t ehs_key;
    uint8_t ehs_previous_key;
    uint8_t ehs_joy;
    uint8_t ehs_previous_joy;
    entry_initials[0] = 'A';
    entry_initials[1] = 'A';
    entry_initials[2] = 'A';
    ehs_cursor = 0;
    ehs_previous_key = KEY_NONE;
    ehs_previous_joy = JOY_RELEASED_MASK;
    insert_high_score(score, entry_initials, ehs_position);
    draw_high_scores((int8_t)ehs_position);
    draw_box(43, 49 + ehs_position * 22, 7, 10, PIXEL_LASER, WEB64_BITMAP_OP_XOR);
    wait_input_release();
    while (1) {
        wait_frame();
        ehs_changed = 0;
        ehs_key = PEEK(CURRENT_KEY);
        ehs_joy = PEEK(JOYPORT_2);
        if (ehs_key != ehs_previous_key && ehs_key != KEY_NONE) {
            if (ehs_key == KEY_A && ehs_cursor > 0) { ehs_cursor--; ehs_changed = 1; }
            else if (ehs_key == KEY_D && ehs_cursor < 2) { ehs_cursor++; ehs_changed = 1; }
            else if (ehs_key == KEY_W) {
                if (entry_initials[ehs_cursor] == 'Z') entry_initials[ehs_cursor] = 'A';
                else entry_initials[ehs_cursor] = entry_initials[ehs_cursor] + 1;
                ehs_changed = 1;
            } else if (ehs_key == KEY_S) {
                if (entry_initials[ehs_cursor] == 'A') entry_initials[ehs_cursor] = 'Z';
                else entry_initials[ehs_cursor] = entry_initials[ehs_cursor] - 1;
                ehs_changed = 1;
            } else if (ehs_key == KEY_SPACE || ehs_key == KEY_RETURN) {
                if (ehs_cursor < 2) { ehs_cursor++; ehs_changed = 1; }
                else return;
            }
        }
        if (ehs_joy != ehs_previous_joy) {
            if (JOY_UP_P(ehs_joy)) {
                if (entry_initials[ehs_cursor] == 'Z') entry_initials[ehs_cursor] = 'A';
                else entry_initials[ehs_cursor] = entry_initials[ehs_cursor] + 1;
                ehs_changed = 1;
            } else if (JOY_DOWN_P(ehs_joy)) {
                if (entry_initials[ehs_cursor] == 'A') entry_initials[ehs_cursor] = 'Z';
                else entry_initials[ehs_cursor] = entry_initials[ehs_cursor] - 1;
                ehs_changed = 1;
            } else if (JOY_LEFT_P(ehs_joy) && ehs_cursor > 0) { ehs_cursor--; ehs_changed = 1; }
            else if (JOY_RIGHT_P(ehs_joy) && ehs_cursor < 2) { ehs_cursor++; ehs_changed = 1; }
            else if (JOY_FIRE_P(ehs_joy)) {
                if (ehs_cursor < 2) { ehs_cursor++; ehs_changed = 1; }
                else return;
            }
        }
        if (ehs_changed != 0) {
            high_name_0[ehs_position] = entry_initials[0];
            high_name_1[ehs_position] = entry_initials[1];
            high_name_2[ehs_position] = entry_initials[2];
            fill_box(31, 49 + ehs_position * 22, 96, 12, PIXEL_BACKGROUND);
            draw_high_score_row(ehs_position, PIXEL_ACCENT);
            draw_box(43 + ehs_cursor * 6, 49 + ehs_position * 22, 7, 10, PIXEL_LASER, WEB64_BITMAP_OP_XOR);
        }
        ehs_previous_key = ehs_key;
        ehs_previous_joy = ehs_joy;
    }
}

static void show_high_scores_and_wait(void) {
    draw_high_scores(-1);
    wait_input_release();
    while (1) {
        wait_frame();
        if (PEEK(CURRENT_KEY) == KEY_SPACE || PEEK(CURRENT_KEY) == KEY_RETURN || JOY_FIRE_P(PEEK(JOYPORT_2))) return;
    }
}

static uint8_t play_course(void) {
    uint8_t pc_action;
    uint8_t pc_selection;
    draw_playfield();
    wait_input_release();
    while (1) {
        wait_frame();
        if (tick_course_clock() != 0) refresh_hud();
        pc_action = poll_game_action();
        if (pc_action == ACTION_UP) move_selected(0, -10);
        else if (pc_action == ACTION_DOWN) move_selected(0, 10);
        else if (pc_action == ACTION_LEFT) move_selected(-10, 0);
        else if (pc_action == ACTION_RIGHT) move_selected(10, 0);
        else if (pc_action == ACTION_PREVIOUS) {
            if (selected_mirror == 0) pc_selection = course_mirror_count[course_index] - 1;
            else pc_selection = selected_mirror - 1;
            select_mirror(pc_selection);
        } else if (pc_action == ACTION_NEXT) {
            pc_selection = selected_mirror + 1;
            if (pc_selection >= course_mirror_count[course_index]) pc_selection = 0;
            select_mirror(pc_selection);
        } else if (pc_action == ACTION_ROTATE) {
            rotate_selected();
        } else if (pc_action == ACTION_RESET) {
            reset_layout_visible();
        } else if (pc_action == ACTION_PULSE) {
            if (fire_pulse() == 0) return COURSE_NO_PULSES;
            input_last = ACTION_NONE;
            if (pulse_goal_reached != 0) return COURSE_WON;
            if (pulses_left == 0) return COURSE_NO_PULSES;
        }
        if (time_left == 0) return COURSE_TIME_UP;
    }
}

static uint8_t run_campaign(void) {
    uint8_t rc_result;
    uint16_t rc_time_bonus;
    uint16_t rc_pulse_bonus;
    score = 0;
    pulses_left = STARTING_PULSES;
    pulses_fired = 0;
    course_index = 0;
    while (course_index < COURSE_COUNT) {
        load_course();
        draw_course_intro();
        wait_menu_choice();
        rc_result = play_course();
        if (rc_result != COURSE_WON) {
            draw_game_over(rc_result);
            wait_menu_choice();
            return rc_result;
        }
        rc_time_bonus = time_left * 10;
        add_score(COURSE_CLEAR_VALUE);
        add_score(rc_time_bonus);
        draw_course_clear(rc_time_bonus);
        wait_menu_choice();
        course_index++;
    }
    rc_pulse_bonus = (uint16_t)pulses_left * FINAL_PULSE_VALUE;
    add_score(rc_pulse_bonus);
    draw_campaign_clear();
    wait_menu_choice();
    return COURSE_WON;
}
#endif

static void initialize_bitmap(void) {
    /* A directly launched PRG cannot assume the KERNAL left display enable,
       25-row mode, or 40-column mode selected. Establish that app-owned
       baseline before the bitmap runtime selects bitmap + multicolor mode. */
    POKE(VIC_CONTROL_1, (PEEK(VIC_CONTROL_1) & 0x80) | 0x1b);
    POKE(VIC_CONTROL_2, 0x08);
    palette.color0 = 0;
    palette.color1 = 3;
    palette.color2 = 7;
    palette.color3 = 1;
    verification_status = web64_bitmap_init(
        &bitmap,
        BITMAP_MEMORY,
        SCREEN_MEMORY,
        WEB64_BITMAP_MODE_MULTICOLOR,
        &palette
    );
}

#ifdef WEB64_EXAMPLE_VERIFY
static void load_solution(void) {
    uint8_t ls_index;
    ls_index = 0;
    while (ls_index < course_mirror_count[course_index]) {
        mirror_x[ls_index] = solution_mirror_x[course_index][ls_index];
        mirror_y[ls_index] = solution_mirror_y[course_index][ls_index];
        mirror_angle[ls_index] = solution_mirror_angle[course_index][ls_index];
        ls_index++;
    }
}

static void verify_game(void) {
    uint8_t vg_initial_x;
    uint8_t vg_initial_angle;
    score = 0;
    pulses_left = STARTING_PULSES;
    pulses_fired = 0;
    verification_courses_solved = 0;
    verification_pickups_collected = 0;
    verification_segments_traced = 0;
    course_index = 0;
    while (course_index < COURSE_COUNT) {
        load_course();
        if (course_index == 0) {
            draw_playfield();
            vg_initial_x = mirror_x[0];
            move_selected(-10, 0);
            if (mirror_x[0] != vg_initial_x) verification_move_changed = 1;
            vg_initial_angle = mirror_angle[0];
            rotate_selected();
            if (mirror_angle[0] != vg_initial_angle) verification_rotation_changed = 1;
        }
        load_solution();
        draw_playfield();
        fire_pulse();
        verification_segments_traced = verification_segments_traced + beam_segment_count;
        verification_pickups_collected = verification_pickups_collected + pulse_pickup_count;
        if (pulse_goal_reached != 0 && pulse_pickup_count == course_pickup_count[course_index]) {
            verification_courses_solved++;
        }
        add_score(COURSE_CLEAR_VALUE);
        add_score(time_left * 10);
        course_index++;
    }
    entry_initials[0] = 'C';
    entry_initials[1] = 'P';
    entry_initials[2] = 'U';
    insert_high_score(30000, entry_initials, 0);
    verification_complete = 1;
}
#endif

#ifdef WEB64_RENDER_VERIFY
static void verify_rendering(void) {
    score = 1234;
    pulses_left = STARTING_PULSES;
    pulses_fired = 0;
    course_index = 0;
    load_course();
    verification_render_phase = 1;
    draw_playfield();
    verification_render_phase = 2;
    move_selected(-10, 0);
    verification_render_phase = 3;
    draw_playfield();
    verification_render_phase = 4;
    rotate_selected();
    verification_render_phase = 5;
    draw_playfield();
    verification_render_phase = 6;
    select_mirror(1);
    verification_render_phase = 7;
    draw_playfield();
    verification_render_phase = 8;
    time_left--;
    hud_dirty = hud_dirty | HUD_DIRTY_TIME;
    refresh_hud();
    verification_render_phase = 9;
    draw_playfield();
    verification_render_phase = 10;
    refresh_hud();
    verification_render_phase = 11;
    select_mirror(0);
    verification_render_phase = 12;
    draw_playfield();
    verification_render_phase = 13;
    move_selected(10, 0);
    move_selected(-10, 0);
    verification_render_phase = 14;
    rotate_selected();
    rotate_selected();
    verification_render_phase = 15;
    fire_pulse();
    verification_render_phase = 16;
    draw_playfield();
    verification_render_phase = 17;
    reset_layout_visible();
    verification_render_phase = 18;
    draw_playfield();
    verification_render_phase = 19;
}
#endif

void main(void) {
    int8_t mn_position;
    uint8_t mn_choice;
    initialize_bitmap();
    if (verification_status != WEB64_BITMAP_OK) return;
#ifdef WEB64_RENDER_VERIFY
    verify_rendering();
    return;
#else
#ifdef WEB64_EXAMPLE_VERIFY
    verify_game();
    return;
#else
    while (1) {
        draw_title();
        mn_choice = wait_menu_choice();
        if (mn_choice == 2) {
            show_high_scores_and_wait();
        } else {
            run_campaign();
            mn_position = high_score_position(score);
            if (mn_position >= 0) enter_high_score((uint8_t)mn_position);
            show_high_scores_and_wait();
        }
    }
#endif
#endif
}
