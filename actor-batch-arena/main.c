#include <stdint.h>
#include <web64/actor-batch.h>

#define ACTOR_COUNT 32
#define HOT_ACTOR_COUNT 18
#define VISIBLE_ACTORS 18
#define POINTER_TABLE 0x07f8
#define BASE_POINTER 0xc0
#define OVERLAY_POINTER 0xc4
#define MUX_OWNED_SLOTS 0xfc
#define MUX_CAPACITY 24
#define VERIFY_FRAMES 120
#define ANIMATION_BATCH_COUNT 1

void example_install_irq(void);
void example_init_pair_binding(void);
void example_prepare_video(void);
void example_show_video(void);
void example_prepare_frame_inputs(void);

WEB64_ACTOR_POOL(pool, ACTOR_COUNT);
WEB64_ACTOR_ANIMATION_STORAGE(animation, ACTOR_COUNT);
WEB64_ACTOR_VISIBLE_STORAGE(visible, ACTOR_COUNT);
WEB64_ACTOR_PAIR_STORAGE(pairing, ACTOR_COUNT, 64);
WEB64_ACTOR_BOUNDS_STORAGE(bounds, ACTOR_COUNT);
WEB64_ACTOR_SPRITE_SET_STORAGE(sprites, ACTOR_COUNT);
WEB64_ACTOR_COMMAND_STORAGE(commands, ACTOR_COUNT);
WEB64_SPRITE_MUX_STORAGE(mux, MUX_CAPACITY);

Web64ActorBatchView view;
Web64ActorBatchView animation_view;
Web64ActorViewport viewport;
Web64ActorBatchStatus actor_status;
Web64ActorMuxPipeline pipeline;
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
uint8_t verification_begin_busy;
uint8_t expected_accepted_entries;
uint8_t expected_dropped_entries;
uint8_t expected_accepted_layers;
uint8_t expected_dropped_layers;
uint16_t previous_actor_x;
volatile uint8_t benchmark_phase;
uint8_t animation_active_ids[ANIMATION_BATCH_COUNT];
uint8_t animation_active_count;

uint16_t home_x[32] = {
    42, 50, 132, 204, 32, 112, 204, 52,
    132, 207, 32, 112, 202, 52, 142, 207,
    32, 112, 202, 72, 192, 24, 44, 64,
    84, 104, 124, 144, 164, 184, 194, 204
};

uint8_t actor_y[32] = {
    20, 20, 20, 70, 100, 120, 140, 160,
    180, 180, 180, 180, 180, 180, 180, 180,
    180, 180, 200, 200, 200, 231, 231, 231,
    231, 231, 231, 231, 231, 231, 231, 231
};

/* Stable global X order. All actors share one wave offset, so this remains
   coherent while the caller-owned pair workspace stays directly inspectable. */
uint8_t initial_x_order[32] = {
    21, 4, 10, 16, 0, 22, 1, 7,
    13, 23, 19, 24, 25, 5, 11, 17,
    26, 2, 8, 14, 27, 28, 29, 20,
    30, 12, 18, 3, 6, 31, 9, 15
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
    animation_steps[0].duration = 1;
    animation_steps[0].event = 1;
    animation_steps[1].frame = 1;
    animation_steps[1].overlay_frame = 2;
    animation_steps[1].duration = 1;
    animation_steps[1].event = 0;
    animation_steps[2].frame = 2;
    animation_steps[2].overlay_frame = 1;
    animation_steps[2].duration = 1;
    animation_steps[2].event = 2;
    animation_steps[3].frame = 3;
    animation_steps[3].overlay_frame = 0;
    animation_steps[3].duration = 1;
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
    animation_active_count = ANIMATION_BATCH_COUNT;
    animation_view.active_ids = animation_active_ids;
    animation_view.active_count = &animation_active_count;
    animation_view.capacity = ACTOR_COUNT;
    for (i = 0; i < ACTOR_COUNT; i++) {
        animation_bank[i] = WEB64_ADDRESS(&arena_animation_bank);
        animation_queued[i] = 0xff;
        animation_direction[i] = 1;
        animation_ticks[i] = 0;
        animation_overlay_frame[i] = 3;
    }
}

void example_init_buffers(void) {
    /* The cycle-critical runtime cohort is the canonical 24-actor workload.
       Eight offscreen background actors remain in the same open SoA arrays and
       are integrated by the application assembly adapter. */
    pool_active_count = HOT_ACTOR_COUNT;
    for (i = 0; i < ACTOR_COUNT; i++) {
        pool_active_ids[i] = i;
        pool_active[i] = 1;
        pool_x[i] = ((uint16_t)home_x[i]) << WEB64_SUBPIXEL_BITS;
        pool_y[i] = ((uint16_t)actor_y[i]) << WEB64_SUBPIXEL_BITS;
        pool_vx[i] = 0;
        pool_vy[i] = 0;
        pool_width[i] = 20;
        pool_height[i] = 20;
        pool_category[i] = 1;
        pool_mask[i] = 1;
        pairing_sorted_ids[i] = initial_x_order[i];
        bounds_left[i] = home_x[i];
        bounds_right[i] = home_x[i] + pool_width[i];
        bounds_top[i] = actor_y[i];
        bounds_bottom[i] = actor_y[i] + pool_height[i];
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
    viewport.width = 232;
    viewport.height = 190;
    visible.entries = visible_entries;
    visible.capacity = ACTOR_COUNT;
    pairing_workspace.sorted_ids = pairing_sorted_ids;
    pairing_workspace.count = 0;
    pairing_workspace.capacity = ACTOR_COUNT;
    pairing_workspace.initialized = 0;
    pairing_pairs.pairs = pairing_pair_entries;
    pairing_pairs.capacity = 64;
    bounds.left = bounds_left;
    bounds.right = bounds_right;
    bounds.top = bounds_top;
    bounds.bottom = bounds_bottom;
    bounds.capacity = ACTOR_COUNT;
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
    pipeline.view = &view;
    pipeline.animation = &animation;
    pipeline.viewport = &viewport;
    pipeline.visible = &visible;
    pipeline.bounds = &bounds;
    pipeline.pair_workspace = &pairing_workspace;
    pipeline.pairs = &pairing_pairs;
    pipeline.sprites = &sprites;
    pipeline.commands = &commands;
    pipeline.mux = &mux;
    pipeline.status = &actor_status;
    pipeline.flags = WEB64_ACTOR_MUX_PIPELINE_BOUNDS_STABLE |
        WEB64_ACTOR_MUX_PIPELINE_DENSE_ACTIVE_IDS |
        WEB64_ACTOR_MUX_PIPELINE_ANIMATION_PRETICKED |
        WEB64_ACTOR_MUX_PIPELINE_PAIRS_PRECOMPUTED |
        WEB64_ACTOR_MUX_PIPELINE_STABLE_TOPOLOGY |
        WEB64_ACTOR_MUX_PIPELINE_STABLE_ORDER_IDENTITY |
        WEB64_ACTOR_MUX_PIPELINE_DENSE_MOTION_PREINTEGRATED;
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
    if (web64_sprite_mux_begin_frame(&mux) != WEB64_SPRITE_MUX_OK) {
        verification_begin_busy++;
        return 0;
    }
#ifdef WEB64_EXAMPLE_BENCHMARK
    benchmark_phase = 1;
#endif
    /* The application-owned adapter integrates the open Q12.4 positions,
       updates visible left edges from a sine table, and selects the actor
       whose public animation state will be prepared for the next frame. */
    example_prepare_frame_inputs();
#ifdef WEB64_EXAMPLE_BENCHMARK
    benchmark_phase = 2;
#endif
    if (web64_actor_batch_run_mux_fast(&pipeline) != WEB64_ACTOR_BATCH_OK) return 0;
#ifdef WEB64_EXAMPLE_BENCHMARK
    benchmark_phase = 3;
#endif
    web64_sprite_mux_commit(&mux);
#ifdef WEB64_EXAMPLE_BENCHMARK
    benchmark_phase = 4;
#endif
    /* The committed schedule owns resolved frame pointers. Advancing one
       caller-owned animation player here prepares independent base/overlay
       indices for the next frame without extending the raster-300 deadline. */
    web64_actor_batch_animation_tick_fast(&animation_view, &animation, 0);
#ifdef WEB64_EXAMPLE_BENCHMARK
    benchmark_phase = 5;
#endif
#ifdef WEB64_EXAMPLE_VERIFY
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
#endif
    frame_counter++;
#ifdef WEB64_EXAMPLE_BENCHMARK
    benchmark_phase = 6;
#endif
    return 1;
}

void main(void) {
    uint8_t service_count;
    example_prepare_video();
    example_make_sprite_data();
    example_init_pair_binding();
    example_init_buffers();
    /* Binding initializes command frames; animation state takes final ownership. */
    example_init_animation();
    /* All actors share one X-wave offset, so their relative AABBs do not
       change. Run the open pair phase once and let the fused display phase
       preserve that caller-owned result on every PAL frame. */
    web64_actor_batch_pairs_x(
        &view, &pairing_workspace, &pairing_pairs, &actor_status
    );
    web64_sprite_renderer_init(&hud_renderer, POINTER_TABLE);
    *((uint8_t *)0xd025) = 6;
    *((uint8_t *)0xd026) = 14;
    web64_sprite_render_asset_pair(
        &hud_renderer, &pair_binding, 1, 0, 40, 54,
        0, 3, WEB64_SPRITE_VISIBLE
    );
    if (web64_sprite_mux_init(
        &mux, mux_buffer_a, mux_buffer_b, MUX_CAPACITY,
        POINTER_TABLE, MUX_OWNED_SLOTS, 6, 14, WEB64_SPRITE_MUX_VIDEO_PAL
    ) != WEB64_SPRITE_MUX_OK) return;
    if (web64_sprite_mux_activate(&mux) != WEB64_SPRITE_MUX_OK) return;
    previous_actor_x = pool_x[0];
    if (!example_build_frame()) return;
    example_show_video();
#ifdef WEB64_EXAMPLE_BENCHMARK
    benchmark_phase = 8;
    web64_sprite_mux_irq_service();
    benchmark_phase = 9;
    for (service_count = 1; service_count < 16; service_count++) {
        web64_sprite_mux_irq_service();
    }
    /* Warm the second caller-owned schedule buffer once. Steady frames reuse
       the validated topology of both buffers without copying a hidden list. */
    example_build_frame();
    for (service_count = 0; service_count < 16; service_count++) {
        web64_sprite_mux_irq_service();
    }
    benchmark_phase = 0;
    example_build_frame();
    benchmark_phase = 7;
    return;
#else
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
    /* Activation arms line 300 before the application enables VIC raster IRQs.
       Clear a stale raster request so the first dispatch is the armed compare. */
    *((uint8_t *)0xd019) = 1;
    example_install_irq();
    observed_tick = frame_tick;
    while (1) {
        while (observed_tick == frame_tick) { }
        observed_tick = frame_tick;
        example_build_frame();
    }
#endif
#endif
}
