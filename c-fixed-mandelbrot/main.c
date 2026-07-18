/*
 * Web64 IDE Example
 * Name: C Fixed Mandelbrot
 * Description: Renders a 160x200 Mandelbrot set in C64 multicolor bitmap mode using web64/fixed.h 8.8 helpers.
 */

#include <stdint.h>
#include <web64/fixed.h>

#define MANDEL_WIDTH_BYTES 40
#define MANDEL_CELL_ROWS 25
#define MANDEL_MAX_ITERATIONS 24
#define MANDEL_ESCAPE_RADIUS2 1024
#define MANDEL_MIN_REAL -550
#define MANDEL_MAX_IMAG 307
#define MANDEL_REAL_STEP 5
#define MANDEL_IMAG_STEP 3
#define MANDEL_CELL_REAL_STEP 20
#define MANDEL_CELL_IMAG_STEP 24

uint8_t oracle_failures;
uint8_t screen_band;
uint8_t screen_offset;
uint8_t cell_row;
uint8_t y_pixel;
uint8_t char_col;
uint8_t pair_index;
uint8_t iter_count;
uint8_t pixel_pair;
uint8_t bitmap_byte;
uint8_t color_hi;
uint8_t color_lo;
uint8_t color_ram;
uint8_t screen_row_offset;
int bitmap_addr;
int current_cell_addr;
int row_base;
web64_fix8_8 c_real;
web64_fix8_8 cell_real_start;
web64_fix8_8 row_imag;
web64_fix8_8 pixel_imag;
web64_fix8_8 z_real;
web64_fix8_8 z_imag;
web64_fix8_8 real_sq;
web64_fix8_8 imag_sq;
web64_fix8_8 mag_sq;
web64_fix8_8 two_real_imag;
web64_fix8_8 next_real;
web64_fix8_8 next_imag;

uint8_t mandelbrot_iterate(web64_fix8_8 point_real, web64_fix8_8 point_imag, uint8_t max_iterations) {
    uint8_t iteration;

    z_real = 0;
    z_imag = 0;
    iteration = 0;

    while (iteration < max_iterations) {
        real_sq = web64_fix8_mul(z_real, z_real);
        imag_sq = web64_fix8_mul(z_imag, z_imag);
        mag_sq = web64_fix8_add_wrap(real_sq, imag_sq);
        if (mag_sq > MANDEL_ESCAPE_RADIUS2) {
            return iteration;
        }

        two_real_imag = web64_fix8_mul(z_real, z_imag);
        next_real = web64_fix8_add_wrap(web64_fix8_sub_wrap(real_sq, imag_sq), point_real);
        next_imag = web64_fix8_add_wrap(web64_fix8_add_wrap(two_real_imag, two_real_imag), point_imag);
        z_real = next_real;
        z_imag = next_imag;
        iteration = iteration + 1;
    }

    return max_iterations;
}

uint8_t mandelbrot_pixel_pair(uint8_t iteration) {
    if (iteration == MANDEL_MAX_ITERATIONS) return 0;
    if (iteration < 3) return 1;
    if (iteration < 7) return 2;
    if (iteration < 13) return 3;
    if (iteration < 19) return 2;
    return 1;
}

void bitmap_put(uint8_t value) {
    *(uint8_t*)bitmap_addr = value;
}

void cell_color_put(void) {
    color_hi = 2;
    color_lo = 8;
    color_ram = 7;
    if (screen_band == 0) { *(uint8_t*)(0x0400 + screen_offset) = (color_hi << 4) | color_lo; *(uint8_t*)(0xd800 + screen_offset) = color_ram; return; }
    if (screen_band == 1) { *(uint8_t*)(0x04c8 + screen_offset) = (color_hi << 4) | color_lo; *(uint8_t*)(0xd8c8 + screen_offset) = color_ram; return; }
    if (screen_band == 2) { *(uint8_t*)(0x0590 + screen_offset) = (color_hi << 4) | color_lo; *(uint8_t*)(0xd990 + screen_offset) = color_ram; return; }
    if (screen_band == 3) { *(uint8_t*)(0x0658 + screen_offset) = (color_hi << 4) | color_lo; *(uint8_t*)(0xda58 + screen_offset) = color_ram; return; }
    *(uint8_t*)(0x0720 + screen_offset) = (color_hi << 4) | color_lo;
    *(uint8_t*)(0xdb20 + screen_offset) = color_ram;
}

uint8_t build_multicolor_pixel_byte(void) {
    pair_index = 0;
    bitmap_byte = 0;
    while (pair_index < 4) {
        iter_count = mandelbrot_iterate(c_real, pixel_imag, MANDEL_MAX_ITERATIONS);
        pixel_pair = mandelbrot_pixel_pair(iter_count);
        if (pair_index == 0) bitmap_byte = pixel_pair << 6;
        if (pair_index == 1) bitmap_byte = bitmap_byte | (pixel_pair << 4);
        if (pair_index == 2) bitmap_byte = bitmap_byte | (pixel_pair << 2);
        if (pair_index == 3) bitmap_byte = bitmap_byte | pixel_pair;
        c_real = web64_fix8_add_wrap(c_real, MANDEL_REAL_STEP);
        pair_index = pair_index + 1;
    }
    return bitmap_byte;
}

void render_multicolor_cell_pixels(void) {
    bitmap_addr = current_cell_addr;
    pixel_imag = row_imag;
    y_pixel = 0;
    while (y_pixel < 8) {
        c_real = cell_real_start;
        bitmap_put(build_multicolor_pixel_byte());
        bitmap_addr = bitmap_addr + 1;
        pixel_imag = web64_fix8_sub_wrap(pixel_imag, MANDEL_IMAG_STEP);
        y_pixel = y_pixel + 1;
    }
    cell_color_put();
}

void mandelbrot_render_bitmap(void) {
    row_imag = 307;
    row_base = 0;
    cell_row = 0;
    screen_band = 0;
    screen_row_offset = 0;
    while (cell_row < MANDEL_CELL_ROWS) {
        current_cell_addr = 0x2000 + row_base;
        cell_real_start = -550;
        char_col = 0;
        screen_offset = screen_row_offset;
        while (char_col < MANDEL_WIDTH_BYTES) {
            render_multicolor_cell_pixels();
            screen_offset = screen_offset + 1;
            current_cell_addr = current_cell_addr + 8;
            cell_real_start = web64_fix8_add_wrap(cell_real_start, MANDEL_CELL_REAL_STEP);
            char_col = char_col + 1;
        }
        row_imag = web64_fix8_sub_wrap(row_imag, MANDEL_CELL_IMAG_STEP);
        row_base = row_base + 320;
        screen_row_offset = screen_row_offset + 40;
        if (screen_row_offset == 200) {
            screen_row_offset = 0;
            screen_band = screen_band + 1;
        }
        cell_row = cell_row + 1;
        *(uint8_t*)0xd020 = cell_row;
    }
}

void enable_multicolor_bitmap(void) {
    *(uint8_t*)0xd020 = 0;
    *(uint8_t*)0xd021 = 0;
    *(uint8_t*)0xd018 = 0x18;
    *(uint8_t*)0xd011 = 0x3b;
    *(uint8_t*)0xd016 = 0x18;
}

void expect_bounded(web64_fix8_8 point_real, web64_fix8_8 point_imag) {
    if (mandelbrot_iterate(point_real, point_imag, MANDEL_MAX_ITERATIONS) != MANDEL_MAX_ITERATIONS) {
        oracle_failures = oracle_failures + 1;
    }
}

void expect_escaped(web64_fix8_8 point_real, web64_fix8_8 point_imag) {
    if (mandelbrot_iterate(point_real, point_imag, MANDEL_MAX_ITERATIONS) == MANDEL_MAX_ITERATIONS) {
        oracle_failures = oracle_failures + 1;
    }
}

void run_oracles(void) {
    oracle_failures = 0;
    expect_bounded(0, 0);
    expect_bounded(-256, 0);
    expect_escaped(256, 0);
    expect_bounded(-512, 0);
    expect_escaped(256, 256);
    expect_bounded(-32, 192);
}

void show_oracle_failure(void) {
    *(uint8_t*)0xd020 = 2;
    *(uint8_t*)0xd021 = 0;
    *(uint8_t*)0x0400 = 6;
    *(uint8_t*)0x0401 = 9;
    *(uint8_t*)0x0402 = 24;
    *(uint8_t*)0x0403 = 5;
    *(uint8_t*)0x0404 = 4;
    *(uint8_t*)0x0405 = 32;
    *(uint8_t*)0x0406 = 15;
    *(uint8_t*)0x0407 = 18;
    *(uint8_t*)0x0408 = 1;
    *(uint8_t*)0x0409 = 3;
    *(uint8_t*)0x040a = 12;
    *(uint8_t*)0x040b = 5;
    *(uint8_t*)0x040c = 32;
    *(uint8_t*)0x040d = 6;
    *(uint8_t*)0x040e = 1;
    *(uint8_t*)0x040f = 9;
    *(uint8_t*)0x0410 = 12;
}

void main(void) {
    run_oracles();
    if (oracle_failures != 0) {
        show_oracle_failure();
        while (1) {
        }
    }

    enable_multicolor_bitmap();
    mandelbrot_render_bitmap();
    *(uint8_t*)0xd020 = 5;
    while (1) {
    }
}
