#include <stdint.h>
#include <web64/trajectory.h>
#include <web64/sprite-runtime.h>

#define TRAJECTORY_COUNT 8
#define SEGMENT_COUNT 8
#define POINTER_TABLE 0x07f8
#define SPRITE_DATA 0x3000
#define SPRITE_POINTER 0xc0

uint8_t example_color_from_state(void);

Web64TrajectorySegment shared_segments[SEGMENT_COUNT];
Web64TrajectoryPattern shared_pattern;
Web64TrajectoryState state0;
Web64TrajectoryState state1;
Web64TrajectoryState state2;
Web64TrajectoryState state3;
Web64TrajectoryState state4;
Web64TrajectoryState state5;
Web64TrajectoryState state6;
Web64TrajectoryState state7;
Web64SpriteRenderer sprite_renderer;
uint8_t frame_counter;
uint8_t verification_complete;
uint8_t i;

void make_sprite(void) {
    uint8_t row;
    uint8_t *data;
    data = (uint8_t *)SPRITE_DATA;
    for (row = 0; row < 63; row++) data[row] = 0;
    for (row = 3; row < 18; row++) {
        data[row * 3] = 0x18;
        data[row * 3 + 1] = 0x7e;
        data[row * 3 + 2] = 0x18;
    }
    data[63] = 0;
}

void make_pattern(void) {
    shared_segments[0].delta_x = 48;  shared_segments[0].delta_y = 0;   shared_segments[0].duration = 32;
    shared_segments[1].delta_x = 16;  shared_segments[1].delta_y = 24;  shared_segments[1].duration = 17;
    shared_segments[2].delta_x = -16; shared_segments[2].delta_y = 24;  shared_segments[2].duration = 23;
    shared_segments[3].delta_x = -48; shared_segments[3].delta_y = 0;   shared_segments[3].duration = 32;
    shared_segments[4].delta_x = -16; shared_segments[4].delta_y = -24; shared_segments[4].duration = 17;
    shared_segments[5].delta_x = 16;  shared_segments[5].delta_y = -24; shared_segments[5].duration = 23;
    shared_segments[6].delta_x = 0;   shared_segments[6].delta_y = 8;   shared_segments[6].duration = 31;
    shared_segments[7].delta_x = 0;   shared_segments[7].delta_y = -8;  shared_segments[7].duration = 29;
    shared_pattern.segments = shared_segments;
    shared_pattern.count = SEGMENT_COUNT;
}

void make_states(void) {
    web64_trajectory_init(&state0, &shared_pattern, 58 << WEB64_SUBPIXEL_BITS, 62 << WEB64_SUBPIXEL_BITS, WEB64_TRAJECTORY_LOOP);
    web64_trajectory_init(&state1, &shared_pattern, 106 << WEB64_SUBPIXEL_BITS, 62 << WEB64_SUBPIXEL_BITS, WEB64_TRAJECTORY_LOOP | WEB64_TRAJECTORY_NEGATE_X);
    web64_trajectory_init(&state2, &shared_pattern, 154 << WEB64_SUBPIXEL_BITS, 62 << WEB64_SUBPIXEL_BITS, WEB64_TRAJECTORY_LOOP | WEB64_TRAJECTORY_NEGATE_Y);
    web64_trajectory_init(&state3, &shared_pattern, 202 << WEB64_SUBPIXEL_BITS, 62 << WEB64_SUBPIXEL_BITS, WEB64_TRAJECTORY_LOOP | WEB64_TRAJECTORY_NEGATE_X | WEB64_TRAJECTORY_NEGATE_Y);
    web64_trajectory_init(&state4, &shared_pattern, 58 << WEB64_SUBPIXEL_BITS, 152 << WEB64_SUBPIXEL_BITS, WEB64_TRAJECTORY_PING_PONG);
    web64_trajectory_init(&state5, &shared_pattern, 106 << WEB64_SUBPIXEL_BITS, 152 << WEB64_SUBPIXEL_BITS, WEB64_TRAJECTORY_PING_PONG | WEB64_TRAJECTORY_NEGATE_X);
    web64_trajectory_init(&state6, &shared_pattern, 154 << WEB64_SUBPIXEL_BITS, 152 << WEB64_SUBPIXEL_BITS, WEB64_TRAJECTORY_PING_PONG | WEB64_TRAJECTORY_NEGATE_Y);
    web64_trajectory_init(&state7, &shared_pattern, 202 << WEB64_SUBPIXEL_BITS, 152 << WEB64_SUBPIXEL_BITS, WEB64_TRAJECTORY_PING_PONG | WEB64_TRAJECTORY_NEGATE_X | WEB64_TRAJECTORY_NEGATE_Y);
    for (frame_counter = 0; frame_counter < 5; frame_counter++) web64_trajectory_step_fast(&state1);
    for (frame_counter = 0; frame_counter < 10; frame_counter++) web64_trajectory_step_fast(&state2);
    for (frame_counter = 0; frame_counter < 15; frame_counter++) web64_trajectory_step_fast(&state3);
    for (frame_counter = 0; frame_counter < 20; frame_counter++) web64_trajectory_step_fast(&state4);
    for (frame_counter = 0; frame_counter < 25; frame_counter++) web64_trajectory_step_fast(&state5);
    for (frame_counter = 0; frame_counter < 30; frame_counter++) web64_trajectory_step_fast(&state6);
    for (frame_counter = 0; frame_counter < 35; frame_counter++) web64_trajectory_step_fast(&state7);
}

void render_state(Web64TrajectoryState *state, uint8_t slot, uint8_t color) {
    uint16_t x;
    x = state->x >> WEB64_SUBPIXEL_BITS;
    web64_sprite_render(&sprite_renderer, slot, x, state->y >> WEB64_SUBPIXEL_BITS, SPRITE_POINTER, color, WEB64_SPRITE_VISIBLE);
}

void render_states(void) {
    uint8_t base_color;
    base_color = example_color_from_state();
    render_state(&state0, 0, base_color);
    render_state(&state1, 1, base_color + 1);
    render_state(&state2, 2, base_color + 2);
    render_state(&state3, 3, base_color + 3);
    render_state(&state4, 4, base_color + 4);
    render_state(&state5, 5, base_color + 5);
    render_state(&state6, 6, base_color + 6);
    render_state(&state7, 7, base_color + 7);
}

void wait_frame(void) {
#ifdef WEB64_EXAMPLE_VERIFY
    return;
#else
    while (*((uint8_t *)0xd012) != 250) { }
    while (*((uint8_t *)0xd012) == 250) { }
#endif
}

void main(void) {
    make_sprite();
    make_pattern();
    make_states();
    web64_sprite_renderer_init(&sprite_renderer, POINTER_TABLE);
    *((uint8_t *)0xd020) = 0;
    *((uint8_t *)0xd021) = 0;
    frame_counter = 0;
    while (1) {
        wait_frame();
        web64_trajectory_step_fast(&state0);
        web64_trajectory_step_fast(&state1);
        web64_trajectory_step_fast(&state2);
        web64_trajectory_step_fast(&state3);
        web64_trajectory_step_fast(&state4);
        web64_trajectory_step_fast(&state5);
        web64_trajectory_step_fast(&state6);
        web64_trajectory_step_fast(&state7);
        render_states();
        frame_counter++;
#ifdef WEB64_EXAMPLE_VERIFY
        if (frame_counter == 120) {
            verification_complete = 1;
            return;
        }
#endif
    }
}
