#include <stdint.h>
#include <assets/generated.h>
#include <web64/assets.h>
#include <web64/animation.h>
#include <web64/trajectory.h>
#include <web64/sprite-runtime.h>

#define ACTOR_COUNT 8
#define SPRITE_RAM ((uint8_t *)0x3000)
#define SPRITE_POINTER 0xc0
#define POINTER_TABLE 0x07f8
#define VERIFY_FRAMES 600

Web64TrajectoryState trajectory_state_0;
Web64TrajectoryState trajectory_state_1;
Web64TrajectoryState trajectory_state_2;
Web64TrajectoryState trajectory_state_3;
Web64TrajectoryState trajectory_state_4;
Web64TrajectoryState trajectory_state_5;
Web64TrajectoryState trajectory_state_6;
Web64TrajectoryState trajectory_state_7;
Web64AnimationPlayer animation_player;
Web64AnimationStep animation_steps[4] = {{0,4,0,255},{1,4,0,255},{2,4,0,255},{3,4,0,255}};
Web64AnimationSequence animation_sequence;
Web64AnimationBank animation_bank;
Web64SpriteRenderer sprite_renderer;
uint16_t previous_x[ACTOR_COUNT];
uint16_t previous_y[ACTOR_COUNT];
uint8_t animation_frame_masks[ACTOR_COUNT];
uint8_t movement_mask;
uint16_t frame_counter;
uint16_t verification_frames;
uint8_t verification_complete;
uint8_t initialization_failed;

void initialize_trajectories(void) {
    if (web64_trajectory_init(&trajectory_state_0, &actor_1_box_loop_asset, 48 << WEB64_SUBPIXEL_BITS, 72 << WEB64_SUBPIXEL_BITS, actor_1_box_loop_default_options) != WEB64_TRAJECTORY_OK) initialization_failed = 1;
    if (web64_trajectory_init(&trajectory_state_1, &actor_2_diamond_loop_asset, 112 << WEB64_SUBPIXEL_BITS, 76 << WEB64_SUBPIXEL_BITS, actor_2_diamond_loop_default_options) != WEB64_TRAJECTORY_OK) initialization_failed = 1;
    if (web64_trajectory_init(&trajectory_state_2, &actor_3_wide_loop_asset, 160 << WEB64_SUBPIXEL_BITS, 68 << WEB64_SUBPIXEL_BITS, actor_3_wide_loop_default_options) != WEB64_TRAJECTORY_OK) initialization_failed = 1;
    if (web64_trajectory_init(&trajectory_state_3, &actor_4_triangle_loop_asset, 232 << WEB64_SUBPIXEL_BITS, 78 << WEB64_SUBPIXEL_BITS, actor_4_triangle_loop_default_options) != WEB64_TRAJECTORY_OK) initialization_failed = 1;
    if (web64_trajectory_init(&trajectory_state_4, &actor_5_kite_loop_asset, 48 << WEB64_SUBPIXEL_BITS, 156 << WEB64_SUBPIXEL_BITS, actor_5_kite_loop_default_options) != WEB64_TRAJECTORY_OK) initialization_failed = 1;
    if (web64_trajectory_init(&trajectory_state_5, &actor_6_hourglass_loop_asset, 104 << WEB64_SUBPIXEL_BITS, 148 << WEB64_SUBPIXEL_BITS, actor_6_hourglass_loop_default_options) != WEB64_TRAJECTORY_OK) initialization_failed = 1;
    if (web64_trajectory_init(&trajectory_state_6, &actor_7_vertical_loop_asset, 168 << WEB64_SUBPIXEL_BITS, 156 << WEB64_SUBPIXEL_BITS, actor_7_vertical_loop_default_options) != WEB64_TRAJECTORY_OK) initialization_failed = 1;
    if (web64_trajectory_init(&trajectory_state_7, &actor_8_hex_loop_asset, 224 << WEB64_SUBPIXEL_BITS, 148 << WEB64_SUBPIXEL_BITS, actor_8_hex_loop_default_options) != WEB64_TRAJECTORY_OK) initialization_failed = 1;
    previous_x[0] = trajectory_state_0.x;
    previous_y[0] = trajectory_state_0.y;
    previous_x[1] = trajectory_state_1.x;
    previous_y[1] = trajectory_state_1.y;
    previous_x[2] = trajectory_state_2.x;
    previous_y[2] = trajectory_state_2.y;
    previous_x[3] = trajectory_state_3.x;
    previous_y[3] = trajectory_state_3.y;
    previous_x[4] = trajectory_state_4.x;
    previous_y[4] = trajectory_state_4.y;
    previous_x[5] = trajectory_state_5.x;
    previous_y[5] = trajectory_state_5.y;
    previous_x[6] = trajectory_state_6.x;
    previous_y[6] = trajectory_state_6.y;
    previous_x[7] = trajectory_state_7.x;
    previous_y[7] = trajectory_state_7.y;
}

void initialize_animation(void) {
    animation_sequence.steps = WEB64_ADDRESS(animation_steps);
    animation_sequence.count = 4;
    animation_sequence.flags = WEB64_ANIMATION_LOOP;
    animation_bank.sequences = WEB64_ADDRESS(&animation_sequence);
    animation_bank.count = 1;
    web64_animation_init(&animation_player, WEB64_ADDRESS(&animation_bank));
    web64_animation_play(&animation_player, 0, WEB64_ANIMATION_PLAY_RESTART);
}

void install_sprite_asset(void) {
    if (web64_asset_copy_sprite(SPRITE_RAM, &trajectory_actors_asset) != WEB64_ASSET_COPY_OK) initialization_failed = 2;
    *((uint8_t *)0xdd02) = *((uint8_t *)0xdd02) | 3;
    *((uint8_t *)0xdd00) = (*((uint8_t *)0xdd00) & 0xfc) | 3;
    *((uint8_t *)0xd018) = 0x15;
    *((uint8_t *)0xd020) = 0;
    *((uint8_t *)0xd021) = 0;
    *((uint8_t *)0xd025) = trajectory_actors_asset.multicolor_1;
    *((uint8_t *)0xd026) = trajectory_actors_asset.multicolor_2;
    web64_sprite_renderer_init(&sprite_renderer, POINTER_TABLE);
}

void step_actors(void) {
    web64_trajectory_step_fast(&trajectory_state_0);
    web64_trajectory_step_fast(&trajectory_state_1);
    web64_trajectory_step_fast(&trajectory_state_2);
    web64_trajectory_step_fast(&trajectory_state_3);
    web64_trajectory_step_fast(&trajectory_state_4);
    web64_trajectory_step_fast(&trajectory_state_5);
    web64_trajectory_step_fast(&trajectory_state_6);
    web64_trajectory_step_fast(&trajectory_state_7);
    web64_animation_tick(&animation_player);
    if (trajectory_state_0.x != previous_x[0] || trajectory_state_0.y != previous_y[0]) movement_mask = movement_mask | 1;
    previous_x[0] = trajectory_state_0.x;
    previous_y[0] = trajectory_state_0.y;
    animation_frame_masks[0] = animation_frame_masks[0] | (1 << ((animation_player.frame + 0) & 3));
    if (trajectory_state_1.x != previous_x[1] || trajectory_state_1.y != previous_y[1]) movement_mask = movement_mask | 2;
    previous_x[1] = trajectory_state_1.x;
    previous_y[1] = trajectory_state_1.y;
    animation_frame_masks[1] = animation_frame_masks[1] | (1 << ((animation_player.frame + 1) & 3));
    if (trajectory_state_2.x != previous_x[2] || trajectory_state_2.y != previous_y[2]) movement_mask = movement_mask | 4;
    previous_x[2] = trajectory_state_2.x;
    previous_y[2] = trajectory_state_2.y;
    animation_frame_masks[2] = animation_frame_masks[2] | (1 << ((animation_player.frame + 2) & 3));
    if (trajectory_state_3.x != previous_x[3] || trajectory_state_3.y != previous_y[3]) movement_mask = movement_mask | 8;
    previous_x[3] = trajectory_state_3.x;
    previous_y[3] = trajectory_state_3.y;
    animation_frame_masks[3] = animation_frame_masks[3] | (1 << ((animation_player.frame + 3) & 3));
    if (trajectory_state_4.x != previous_x[4] || trajectory_state_4.y != previous_y[4]) movement_mask = movement_mask | 16;
    previous_x[4] = trajectory_state_4.x;
    previous_y[4] = trajectory_state_4.y;
    animation_frame_masks[4] = animation_frame_masks[4] | (1 << ((animation_player.frame + 0) & 3));
    if (trajectory_state_5.x != previous_x[5] || trajectory_state_5.y != previous_y[5]) movement_mask = movement_mask | 32;
    previous_x[5] = trajectory_state_5.x;
    previous_y[5] = trajectory_state_5.y;
    animation_frame_masks[5] = animation_frame_masks[5] | (1 << ((animation_player.frame + 1) & 3));
    if (trajectory_state_6.x != previous_x[6] || trajectory_state_6.y != previous_y[6]) movement_mask = movement_mask | 64;
    previous_x[6] = trajectory_state_6.x;
    previous_y[6] = trajectory_state_6.y;
    animation_frame_masks[6] = animation_frame_masks[6] | (1 << ((animation_player.frame + 2) & 3));
    if (trajectory_state_7.x != previous_x[7] || trajectory_state_7.y != previous_y[7]) movement_mask = movement_mask | 128;
    previous_x[7] = trajectory_state_7.x;
    previous_y[7] = trajectory_state_7.y;
    animation_frame_masks[7] = animation_frame_masks[7] | (1 << ((animation_player.frame + 3) & 3));
}

void render_actor(Web64TrajectoryState *state, uint8_t slot, uint8_t color, uint8_t frame) {
    uint16_t x;
    x = state->x >> WEB64_SUBPIXEL_BITS;
    web64_sprite_render(&sprite_renderer, slot, x, state->y >> WEB64_SUBPIXEL_BITS, frame, color, WEB64_SPRITE_VISIBLE | WEB64_SPRITE_MULTICOLOR);
}

void render_actors(void) {
    render_actor(&trajectory_state_0, 0, 2, SPRITE_POINTER + ((animation_player.frame + 0) & 3));
    render_actor(&trajectory_state_1, 1, 3, SPRITE_POINTER + ((animation_player.frame + 1) & 3));
    render_actor(&trajectory_state_2, 2, 5, SPRITE_POINTER + ((animation_player.frame + 2) & 3));
    render_actor(&trajectory_state_3, 3, 7, SPRITE_POINTER + ((animation_player.frame + 3) & 3));
    render_actor(&trajectory_state_4, 4, 8, SPRITE_POINTER + ((animation_player.frame + 0) & 3));
    render_actor(&trajectory_state_5, 5, 10, SPRITE_POINTER + ((animation_player.frame + 1) & 3));
    render_actor(&trajectory_state_6, 6, 13, SPRITE_POINTER + ((animation_player.frame + 2) & 3));
    render_actor(&trajectory_state_7, 7, 14, SPRITE_POINTER + ((animation_player.frame + 3) & 3));
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
    install_sprite_asset();
    initialize_animation();
    initialize_trajectories();
    if (initialization_failed != 0) {
        *((uint8_t *)0xd020) = 2;
        return;
    }
    render_actors();
    while (1) {
        wait_frame();
        step_actors();
        render_actors();
        frame_counter++;
#ifdef WEB64_EXAMPLE_VERIFY
        verification_frames++;
        if (verification_frames == VERIFY_FRAMES) {
            verification_complete = 1;
            return;
        }
#endif
    }
}
