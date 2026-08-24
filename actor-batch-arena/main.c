#include <stdint.h>
#include <web64/actor-batch.h>

#define ACTOR_COUNT 32
#define VISIBLE_ACTORS 21
#define POINTER_TABLE 0x07f8
#define BASE_POINTER 0xc0
#define OVERLAY_POINTER 0xc4
#define MUX_OWNED_SLOTS 0xfc
#define MUX_CAPACITY 24
#define VERIFY_FRAMES 120

void example_install_irq(void);
void example_init_pair_binding(void);

WEB64_ACTOR_POOL(pool, ACTOR_COUNT);
WEB64_ACTOR_ANIMATION_STORAGE(animation, ACTOR_COUNT);
WEB64_ACTOR_VISIBLE_STORAGE(visible, ACTOR_COUNT);
WEB64_ACTOR_PAIR_STORAGE(pairing, ACTOR_COUNT, 64);
WEB64_ACTOR_SPRITE_SET_STORAGE(sprites, ACTOR_COUNT);
WEB64_ACTOR_COMMAND_STORAGE(commands, ACTOR_COUNT);
WEB64_SPRITE_MUX_STORAGE(mux, MUX_CAPACITY);

Web64ActorBatchView view;
Web64ActorViewport viewport;
Web64ActorBatchStatus actor_status;
Web64SpriteRenderer hud_renderer;
Web64AnimationStep animation_steps[4];
Web64AnimationSequence arena_sequence;
Web64AnimationBank arena_animation_bank;
Web64SpriteOverlayBinding pair_binding;

volatile uint8_t frame_tick;
volatile uint8_t irq_count;
volatile uint8_t irq_entry_line;
volatile uint8_t irq_exit_line;
uint8_t observed_tick;
uint8_t wave_phase;
uint8_t i;
uint8_t frame_counter;
uint8_t verification_complete;
uint8_t verification_stable_drop;
uint8_t verification_motion_changes;
uint8_t verification_pair_frames;
uint8_t verification_independent_frames;
uint8_t expected_accepted_entries;
uint8_t expected_dropped_entries;
uint8_t expected_accepted_layers;
uint8_t expected_dropped_layers;
uint16_t previous_actor_x;

/* Unsigned, 24-centered, 32-sample sine wave. */
uint8_t sprite_wave[32] = {
    24, 29, 33, 37, 41, 44, 46, 47,
    48, 47, 46, 44, 41, 37, 33, 29,
    24, 19, 15, 11, 7, 4, 2, 1,
    0, 1, 2, 4, 7, 11, 15, 19
};

uint8_t home_x[32] = {
    42, 50, 132, 212, 32, 112, 212, 52,
    132, 222, 32, 112, 202, 52, 142, 232,
    32, 112, 202, 72, 192, 24, 52, 80,
    108, 136, 164, 192, 220, 248, 276, 304
};

uint8_t actor_y[32] = {
    20, 20, 20, 20, 55, 55, 55, 84,
    84, 84, 113, 113, 113, 142, 142, 142,
    171, 171, 171, 200, 200, 250, 250, 250,
    250, 250, 250, 250, 250, 250, 250, 250
};

void example_make_sprite_data(void) {
    uint8_t frame;
    uint8_t byte;
    uint16_t offset;
    volatile uint8_t *base_data;
    volatile uint8_t *overlay_data;
    base_data = (uint8_t *)0x3000;
    overlay_data = (uint8_t *)0x3100;
    for (frame = 0; frame < 4; frame++) {
        offset = ((uint16_t)frame) << 6;
        for (byte = 0; byte < 63; byte++) {
            base_data[offset + byte] = ((byte + frame) & 1) ? 0x55 : 0x14;
            overlay_data[offset + byte] = ((byte + frame) & 3) ? 0x42 : 0x7e;
        }
        base_data[offset + 63] = 0;
        overlay_data[offset + 63] = 0;
    }
}

void example_init_animation(void) {
    animation_steps[0].frame = 0;
    animation_steps[0].overlay_frame = 3;
    animation_steps[0].duration = 2;
    animation_steps[0].event = 1;
    animation_steps[1].frame = 1;
    animation_steps[1].overlay_frame = 1;
    animation_steps[1].duration = 2;
    animation_steps[1].event = 0;
    animation_steps[2].frame = 2;
    animation_steps[2].overlay_frame = 0;
    animation_steps[2].duration = 2;
    animation_steps[2].event = 2;
    animation_steps[3].frame = 3;
    animation_steps[3].overlay_frame = 2;
    animation_steps[3].duration = 2;
    animation_steps[3].event = 0;
    arena_sequence.steps = WEB64_ADDRESS(animation_steps);
    arena_sequence.count = 4;
    arena_sequence.flags = WEB64_ANIMATION_LOOP;
    arena_animation_bank.sequences = WEB64_ADDRESS(&arena_sequence);
    arena_animation_bank.count = 1;
    animation.bank = animation_bank;
    animation.sequence = animation_sequence;
    animation.queued = animation_queued;
    animation.step = animation_step;
    animation.ticks = animation_ticks;
    animation.frame = animation_frame;
    animation.overlay_frame = animation_overlay_frame;
    animation.events = animation_events;
    animation.status = animation_status;
    animation.direction = animation_direction;
    for (i = 0; i < ACTOR_COUNT; i++) {
        animation_bank[i] = WEB64_ADDRESS(&arena_animation_bank);
        animation_queued[i] = 0xff;
        animation_direction[i] = 1;
        animation_ticks[i] = 1;
        animation_overlay_frame[i] = 3;
    }
}

void example_init_buffers(void) {
    pool_active_count = ACTOR_COUNT;
    for (i = 0; i < ACTOR_COUNT; i++) {
        pool_active_ids[i] = i;
        pool_active[i] = 1;
        pool_x[i] = WEB64_POS_FROM_PX(home_x[i]);
        pool_y[i] = WEB64_POS_FROM_PX(actor_y[i]);
        pool_vx[i] = 0;
        pool_vy[i] = 0;
        pool_width[i] = 20;
        pool_height[i] = 20;
        pool_category[i] = 1;
        pool_mask[i] = 1;
        pairing_sorted_ids[i] = i;
    }
    view.active_ids = pool_active_ids;
    view.active = pool_active;
    view.active_count = &pool_active_count;
    view.capacity = ACTOR_COUNT;
    view.x = pool_x;
    view.y = pool_y;
    view.vx = pool_vx;
    view.vy = pool_vy;
    view.width = pool_width;
    view.height = pool_height;
    view.category = pool_category;
    view.mask = pool_mask;
    viewport.world_x = 0;
    viewport.world_y = 0;
    viewport.vic_origin_x = 24;
    viewport.vic_origin_y = 30;
    viewport.width = 320;
    viewport.height = 230;
    visible.entries = visible_entries;
    visible.capacity = ACTOR_COUNT;
    pairing_workspace.sorted_ids = pairing_sorted_ids;
    pairing_workspace.count = ACTOR_COUNT;
    pairing_workspace.capacity = ACTOR_COUNT;
    pairing_workspace.initialized = 1;
    pairing_pairs.pairs = pairing_pair_entries;
    pairing_pairs.capacity = 64;
    sprites.kind = sprites_kind;
    sprites.asset = sprites_asset;
    sprites.base_pointer = sprites_base_pointer;
    sprites.overlay_pointer = sprites_overlay_pointer;
    sprites.frame_count = sprites_frame_count;
    sprites.base_color = sprites_base_color;
    sprites.overlay_color = sprites_overlay_color;
    sprites.multicolor_1 = sprites_multicolor_1;
    sprites.multicolor_2 = sprites_multicolor_2;
    sprites.flags = sprites_flags;
    sprites.priority = sprites_priority;
    sprites.base_frame = animation_frame;
    sprites.overlay_frame = animation_overlay_frame;
    sprites.capacity = ACTOR_COUNT;
    commands.commands = commands_commands;
    commands.capacity = ACTOR_COUNT;
    for (i = 0; i < 4; i++) {
        web64_actor_sprite_bind_asset_pair(
            &sprites, i, &pair_binding, WEB64_SPRITE_VISIBLE, 255 - i
        );
    }
    for (i = 4; i < ACTOR_COUNT; i++) {
        web64_actor_sprite_bind_raw(
            &sprites, i, BASE_POINTER, 4, 5,
            WEB64_SPRITE_VISIBLE | WEB64_SPRITE_MULTICOLOR, 255 - i
        );
        sprites_multicolor_1[i] = 6;
        sprites_multicolor_2[i] = 14;
    }
}

uint8_t example_build_frame(void) {
    int16_t target_x;
    if (web64_sprite_mux_begin_frame(&mux) != WEB64_SPRITE_MUX_OK) return 0;
    wave_phase = (wave_phase + 1) & 31;
    for (i = 0; i < ACTOR_COUNT; i++) {
        target_x = home_x[i] + sprite_wave[(wave_phase + i) & 31] - 24;
        pool_vx[i] = WEB64_POS_FROM_PX(target_x) - pool_x[i];
    }
    web64_actor_batch_integrate_xy_fast(&view, &actor_status);
    web64_actor_batch_animation_tick_fast(&view, &animation, &actor_status);
    web64_actor_batch_cull_fast(&view, &viewport, &visible, &actor_status);
    web64_actor_batch_pairs_x_fast(
        &view, &pairing_workspace, &pairing_pairs, &actor_status
    );
    web64_actor_batch_build_commands_fast(
        &view, &visible, &sprites, &commands, &actor_status
    );
    web64_actor_commands_submit_mux_fast(&mux, &commands, &actor_status);
    web64_sprite_mux_commit(&mux);
    if (pool_x[0] != previous_actor_x) verification_motion_changes++;
    previous_actor_x = pool_x[0];
    if (pairing_pairs.count) verification_pair_frames++;
    if (animation_frame[0] != animation_overlay_frame[0]) {
        verification_independent_frames++;
    }
    if (!frame_counter) {
        expected_accepted_entries = mux.status.accepted_entries;
        expected_dropped_entries = mux.status.dropped_entries;
        expected_accepted_layers = mux.status.accepted_layers;
        expected_dropped_layers = mux.status.dropped_layers;
        verification_stable_drop = 1;
    } else if (
        expected_accepted_entries != mux.status.accepted_entries ||
        expected_dropped_entries != mux.status.dropped_entries ||
        expected_accepted_layers != mux.status.accepted_layers ||
        expected_dropped_layers != mux.status.dropped_layers
    ) {
        verification_stable_drop = 0;
    }
    frame_counter++;
    return 1;
}

void main(void) {
    uint8_t service_count;
    example_make_sprite_data();
    example_init_pair_binding();
    example_init_buffers();
    /* Binding initializes command frames; animation state takes final ownership. */
    example_init_animation();
    web64_sprite_renderer_init(&hud_renderer, POINTER_TABLE);
    *((uint8_t *)0xd025) = 6;
    *((uint8_t *)0xd026) = 14;
    web64_sprite_render_asset_pair(
        &hud_renderer, &pair_binding, 1, 0, 24, 24,
        0, 3, WEB64_SPRITE_VISIBLE
    );
    web64_sprite_mux_init(
        &mux, mux_buffer_a, mux_buffer_b, MUX_CAPACITY,
        POINTER_TABLE, MUX_OWNED_SLOTS, 6, 14, WEB64_SPRITE_MUX_VIDEO_PAL
    );
    web64_sprite_mux_irq_service_fast();
    web64_sprite_mux_activate(&mux);
    previous_actor_x = pool_x[0];
    example_build_frame();
#ifdef WEB64_EXAMPLE_VERIFY
    while (frame_counter < VERIFY_FRAMES) {
        for (service_count = 0; service_count < 16; service_count++) {
            web64_sprite_mux_irq_service();
        }
        example_build_frame();
    }
    verification_complete = 1;
    if (!verification_stable_drop) verification_complete = 0;
    if (verification_motion_changes <= 100) verification_complete = 0;
    if (verification_pair_frames != VERIFY_FRAMES) verification_complete = 0;
    if (verification_independent_frames != VERIFY_FRAMES) verification_complete = 0;
    if (visible.count != VISIBLE_ACTORS) verification_complete = 0;
    if (!expected_dropped_entries) verification_complete = 0;
    if (expected_dropped_layers < 2) verification_complete = 0;
    return;
#else
    example_install_irq();
    observed_tick = frame_tick;
    while (1) {
        while (observed_tick == frame_tick) { }
        observed_tick = frame_tick;
        example_build_frame();
    }
#endif
}
