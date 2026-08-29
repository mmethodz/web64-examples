#include <stdint.h>
#include <peekpoke.h>
#include <web64/bitmap.h>
#include "rotation-matrices.h"

#define BITMAP_MEMORY ((uint8_t *)0x2000)
#define SCREEN_MEMORY ((uint8_t *)0x0400)
#define CURRENT_KEY 0x00c5
#define VIC_RASTER 0xd012
#define KEY_NONE 64
#define KEY_W 9
#define KEY_A 10
#define KEY_S 13
#define KEY_D 18
#define VERTEX_COUNT 8
#define EDGE_COUNT 12
#define ANGLE_MASK (ROTATION_X_STEPS - 1)

static const int8_t cube_vertices[VERTEX_COUNT][3] = {
    { -24, -24, -24 }, { 24, -24, -24 },
    { 24, 24, -24 }, { -24, 24, -24 },
    { -24, -24, 24 }, { 24, -24, 24 },
    { 24, 24, 24 }, { -24, 24, 24 }
};

static const uint8_t cube_edges[EDGE_COUNT][2] = {
    { 0, 1 }, { 1, 2 }, { 2, 3 }, { 3, 0 },
    { 4, 5 }, { 5, 6 }, { 6, 7 }, { 7, 4 },
    { 0, 4 }, { 1, 5 }, { 2, 6 }, { 3, 7 }
};

Web64Bitmap bitmap;
Web64BitmapPalette palette;
int16_t rotated_x[VERTEX_COUNT];
int16_t rotated_y[VERTEX_COUNT];
int16_t rotated_z[VERTEX_COUNT];
uint16_t screen_x[VERTEX_COUNT];
uint8_t screen_y[VERTEX_COUNT];
uint8_t angle_x;
uint8_t angle_y;
uint8_t verification_status;
uint8_t verification_complete;
uint8_t verification_frames;
uint16_t verification_initial_x;
uint8_t verification_initial_y;
uint16_t verification_final_x;
uint8_t verification_final_y;

int16_t matrix_pair(int16_t a, int16_t u, int16_t b, int16_t v) {
    int16_t result;
    result = a * u;
    result = result + b * v;
    return result >> 8;
}

void project_object(void) {
    uint8_t vertex;
    int16_t x;
    int16_t y;
    int16_t z;
    int16_t pitch_y;
    int16_t pitch_z;
    int16_t view_x;
    int16_t view_z;
    int16_t depth_scale;
    int16_t projected;

    for (vertex = 0; vertex < VERTEX_COUNT; vertex++) {
        x = cube_vertices[vertex][0];
        y = cube_vertices[vertex][1];
        z = cube_vertices[vertex][2];

        pitch_y = matrix_pair(rotation_x[angle_x][1][1], y, rotation_x[angle_x][1][2], z);
        pitch_z = matrix_pair(rotation_x[angle_x][2][1], y, rotation_x[angle_x][2][2], z);
        view_x = matrix_pair(rotation_y[angle_y][0][0], x, rotation_y[angle_y][0][2], pitch_z);
        view_z = matrix_pair(rotation_y[angle_y][2][0], x, rotation_y[angle_y][2][2], pitch_z);

        rotated_x[vertex] = view_x;
        rotated_y[vertex] = pitch_y;
        rotated_z[vertex] = view_z;

        depth_scale = 96 + view_z;
        projected = view_x * depth_scale;
        screen_x[vertex] = 160 + (projected >> 6);
        projected = pitch_y * depth_scale;
        screen_y[vertex] = 100 - (projected >> 6);
    }
}

void draw_object(void) {
    uint8_t edge;
    uint8_t first;
    uint8_t second;
    for (edge = 0; edge < EDGE_COUNT; edge++) {
        first = cube_edges[edge][0];
        second = cube_edges[edge][1];
        web64_bitmap_line_fast(
            &bitmap,
            screen_x[first], screen_y[first],
            screen_x[second], screen_y[second],
            1, WEB64_BITMAP_OP_XOR
        );
    }
}

void wait_frame(void) {
#ifdef WEB64_EXAMPLE_VERIFY
    return;
#else
    while (PEEK(VIC_RASTER) != 250) { }
    while (PEEK(VIC_RASTER) == 250) { }
#endif
}

uint8_t read_rotation_key(void) {
#ifdef WEB64_EXAMPLE_VERIFY
    if (verification_frames < 4) return KEY_D;
    if (verification_frames < 8) return KEY_S;
    if (verification_frames < 10) return KEY_A;
    if (verification_frames == 10) return KEY_W;
    return KEY_NONE;
#else
    return PEEK(CURRENT_KEY);
#endif
}

void main(void) {
    uint8_t key;
    uint8_t next_x;
    uint8_t next_y;

    palette.color0 = 0;
    palette.color1 = 3;
    palette.color2 = 0;
    palette.color3 = 0;
    verification_status = web64_bitmap_init(
        &bitmap, BITMAP_MEMORY, SCREEN_MEMORY, WEB64_BITMAP_MODE_HIRES, &palette
    );
    if (verification_status != WEB64_BITMAP_OK) return;

    angle_x = 0;
    angle_y = 0;
    verification_frames = 0;
    project_object();
    verification_initial_x = screen_x[0];
    verification_initial_y = screen_y[0];
    draw_object();

    while (1) {
        wait_frame();
        key = read_rotation_key();
        next_x = angle_x;
        next_y = angle_y;
        if (key == KEY_W) next_x = (angle_x - 1) & ANGLE_MASK;
        if (key == KEY_S) next_x = (angle_x + 1) & ANGLE_MASK;
        if (key == KEY_A) next_y = (angle_y - 1) & ANGLE_MASK;
        if (key == KEY_D) next_y = (angle_y + 1) & ANGLE_MASK;

        if (next_x != angle_x || next_y != angle_y) {
            draw_object();
            angle_x = next_x;
            angle_y = next_y;
            project_object();
            draw_object();
        }

#ifdef WEB64_EXAMPLE_VERIFY
        verification_frames++;
        if (verification_frames == 12) {
            verification_final_x = screen_x[0];
            verification_final_y = screen_y[0];
            verification_complete = 1;
            return;
        }
#endif
    }
}
