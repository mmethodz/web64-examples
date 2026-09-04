#include <stdint.h>
#include <web64/game.h>
#include <web64/motion.h>
#include <web64/collision.h>
#include <web64/animation.h>
#include <web64/sprite-runtime.h>

#define PLATFORM_COUNT 10
#define PLAYFIELD_WIDTH 320
#define PLAYFIELD_HEIGHT 160
#define PLAYER_WIDTH 18
#define PLAYER_HEIGHT 20
#define PLAYER_MAX_X 4832
#define PLAYER_START_X (144 << 4)
#define PLAYER_START_Y (134 << 4)
#define SCROLL_LINE 896
#define STATE_TITLE 0
#define STATE_PLAYING 1
#define STATE_GAME_OVER 2
#define PLATFORM_NORMAL 0
#define PLATFORM_CRUMBLE 1
#define PLATFORM_SPRING 2
#define JOY_LEFT_MASK 4
#define JOY_RIGHT_MASK 8
#define JOY_FIRE_MASK 16

void asm_init_video(void);
void asm_prepare_game_screen(void);
void asm_start_animation(void);
void asm_update_hud(void);
void asm_scroll_world(void);
void asm_draw_title(void);
void asm_animate_title(void);
void asm_draw_playfield(void);
void asm_present_frame(void);
void asm_draw_game_over(void);
void asm_hide_sprites(void);
void asm_wait_frame(void);
void asm_audio_tick(void);
void asm_sfx_bounce(void);
void asm_sfx_collect(void);
void asm_sfx_crash(void);
uint8_t asm_read_joystick(void);

Web64Body2D player;
Web64SpriteRenderer sprite_renderer;
Web64AnimationStep runner_run_steps[4] = {
    {0, 3, 0, 255},
    {1, 3, 0, 255},
    {2, 3, 0, 255},
    {3, 3, 0, 255}
};
Web64AnimationStep runner_rise_steps[2] = {
    {4, 5, 0, 255},
    {5, 5, 0, 255}
};
Web64AnimationStep runner_fall_steps[2] = {
    {6, 5, 0, 255},
    {7, 5, 0, 255}
};
Web64AnimationStep spark_animation_steps[2] = {
    {8, 1, 0, 255},
    {9, 1, 0, 255}
};
Web64AnimationStep hazard_animation_steps[2] = {
    {10, 1, 0, 255},
    {11, 1, 0, 255}
};
Web64AnimationSequence runner_animation_sequences[3];
Web64AnimationBank runner_animation_bank;
Web64AnimationPlayer runner_animation;
Web64AnimationSequence spark_animation_sequence;
Web64AnimationBank spark_animation_bank;
Web64AnimationPlayer spark_animation;
Web64AnimationSequence hazard_animation_sequence;
Web64AnimationBank hazard_animation_bank;
Web64AnimationPlayer hazard_animation;
Web64Aabb player_box;
Web64Aabb object_box;

uint8_t platform_x[PLATFORM_COUNT];
uint8_t platform_y[PLATFORM_COUNT];
uint8_t platform_width[PLATFORM_COUNT];
uint8_t platform_kind[PLATFORM_COUNT];
/* A platform pays its landing bonus once; recycling rearms its slot. */
uint8_t platform_scored[PLATFORM_COUNT];

uint8_t hud_score_digits[5];
uint8_t hud_high_digits[5];
uint8_t hud_level_digits[2];
uint8_t hud_lives_digit;

uint16_t score;
uint16_t high_score;
uint16_t climbed;
uint16_t next_level_climb;
uint16_t random_state;
uint8_t level;
uint8_t lives;
uint8_t game_state;
uint8_t previous_joy;
uint8_t boost_ready;
uint8_t frame_counter;
uint8_t runner_animation_state;
uint8_t runner_animation_frame_mask;
uint8_t spark_animation_frame_mask;
uint8_t hazard_animation_frame_mask;
uint8_t scroll_amount;
uint8_t spark_x;
uint8_t spark_y;
uint8_t spark_active;
uint16_t enemy_x;
uint8_t enemy_y;
int8_t enemy_dx;
uint8_t invulnerable;

#ifdef WEB64_EXAMPLE_VERIFY
uint8_t verification_complete;
uint8_t verification_landings;
uint8_t verification_crossings;
uint8_t verification_aabb_hits;
uint8_t verification_scroll;
uint8_t verification_runtime_motion;
uint8_t verification_runtime_collision;
uint8_t verification_scored_landings;
uint8_t verification_repeat_landings;
#endif

static void update_hud(void) {
    asm_update_hud();
}

static void seed_platforms(void) {
    uint8_t platform_index;
    platform_x[0] = 112;
    platform_y[0] = 154;
    platform_width[0] = 72;
    platform_kind[0] = PLATFORM_NORMAL;
    platform_x[1] = 80;
    platform_y[1] = 126;
    platform_width[1] = 80;
    platform_kind[1] = PLATFORM_NORMAL;
    platform_x[2] = 136;
    platform_y[2] = 100;
    platform_width[2] = 72;
    platform_kind[2] = PLATFORM_CRUMBLE;
    platform_x[3] = 96;
    platform_y[3] = 74;
    platform_width[3] = 72;
    platform_kind[3] = PLATFORM_NORMAL;
    platform_x[4] = 152;
    platform_y[4] = 48;
    platform_width[4] = 64;
    platform_kind[4] = PLATFORM_SPRING;
    platform_x[5] = 48;
    platform_y[5] = 20;
    platform_width[5] = 72;
    platform_kind[5] = PLATFORM_NORMAL;
    platform_x[6] = 216;
    platform_y[6] = 8;
    platform_width[6] = 56;
    platform_kind[6] = PLATFORM_NORMAL;
    platform_x[7] = 8;
    platform_y[7] = 4;
    platform_width[7] = 64;
    platform_kind[7] = PLATFORM_CRUMBLE;
    platform_x[8] = 168;
    platform_y[8] = 2;
    platform_width[8] = 64;
    platform_kind[8] = PLATFORM_NORMAL;
    platform_x[9] = 248;
    platform_y[9] = 0;
    platform_width[9] = 56;
    platform_kind[9] = PLATFORM_NORMAL;
    for (platform_index = 0; platform_index < PLATFORM_COUNT; platform_index = platform_index + 1) {
        platform_scored[platform_index] = 0;
    }
}

static void reset_player(void) {
    player.x = PLAYER_START_X;
    player.y = PLAYER_START_Y;
    player.vx = 0;
    player.vy = -80;
    boost_ready = 1;
    invulnerable = 75;
    /* Keep the roaming hazard outside the first jump corridor after every
       spawn. It starts across the arena and above the first landing choices. */
    enemy_x = 280;
    enemy_dx = -1;
    enemy_y = 24;
}

static void start_game(void) {
    score = 0;
    climbed = 0;
    next_level_climb = 160;
    level = 1;
    lives = 3;
    frame_counter = 0;
    random_state = 0x5a37;
    spark_x = 190;
    spark_y = 88;
    spark_active = 1;
    runner_animation_state = 1;
    runner_animation_frame_mask = 0;
    spark_animation_frame_mask = 0;
    hazard_animation_frame_mask = 0;
    seed_platforms();
    reset_player();
    runner_animation_sequences[0].steps = WEB64_ADDRESS(runner_run_steps);
    runner_animation_sequences[0].count = 4;
    runner_animation_sequences[0].flags = WEB64_ANIMATION_LOOP;
    runner_animation_sequences[1].steps = WEB64_ADDRESS(runner_rise_steps);
    runner_animation_sequences[1].count = 2;
    runner_animation_sequences[1].flags = WEB64_ANIMATION_LOOP;
    runner_animation_sequences[2].steps = WEB64_ADDRESS(runner_fall_steps);
    runner_animation_sequences[2].count = 2;
    runner_animation_sequences[2].flags = WEB64_ANIMATION_LOOP;
    runner_animation_bank.sequences = WEB64_ADDRESS(runner_animation_sequences);
    runner_animation_bank.count = 3;
    spark_animation_sequence.steps = WEB64_ADDRESS(spark_animation_steps);
    spark_animation_sequence.count = 2;
    spark_animation_sequence.flags = WEB64_ANIMATION_LOOP;
    spark_animation_bank.sequences = WEB64_ADDRESS(&spark_animation_sequence);
    spark_animation_bank.count = 1;
    hazard_animation_sequence.steps = WEB64_ADDRESS(hazard_animation_steps);
    hazard_animation_sequence.count = 2;
    hazard_animation_sequence.flags = WEB64_ANIMATION_LOOP;
    hazard_animation_bank.sequences = WEB64_ADDRESS(&hazard_animation_sequence);
    hazard_animation_bank.count = 1;
    asm_start_animation();
    asm_prepare_game_screen();
    update_hud();
    game_state = STATE_PLAYING;
}

static void update_player_box(void) {
    player_box.x = player.x >> 4;
    player_box.y = player.y >> 4;
    player_box.width = PLAYER_WIDTH;
    player_box.height = PLAYER_HEIGHT;
    player_box.category = 1;
    player_box.mask = 0xff;
}

static uint8_t overlaps_object(uint16_t x, uint8_t y, uint8_t width, uint8_t height) {
    object_box.x = x;
    object_box.y = y;
    object_box.width = width;
    object_box.height = height;
    object_box.category = 2;
    object_box.mask = 0xff;
#ifdef WEB64_EXAMPLE_VERIFY
    verification_runtime_collision = 1;
#endif
    return web64_collision_aabb(&player_box, &object_box);
}

static void scroll_world(uint8_t pixels) {
    if (pixels == 0) {
        return;
    }
#ifdef WEB64_EXAMPLE_VERIFY
    verification_scroll = 1;
#endif
    scroll_amount = pixels;
    asm_scroll_world();
}

static void move_enemy(void) {
    int16_t enemy_next;
    uint8_t speed;
    speed = 1;
    if (level >= 4) {
        speed = 2;
    }
    if (enemy_dx < 0) {
        enemy_next = (int16_t)enemy_x - speed;
    } else {
        enemy_next = (int16_t)enemy_x + speed;
    }
    if (enemy_next < 4) {
        enemy_next = 4;
        enemy_dx = 1;
    }
    if (enemy_next > 300) {
        enemy_next = 300;
        enemy_dx = -1;
    }
    enemy_x = (uint16_t)enemy_next;
}

static uint8_t find_landing(uint16_t old_y) {
    uint8_t landing_index;
    uint16_t old_bottom;
    uint16_t new_bottom;
    old_bottom = (old_y >> 4) + PLAYER_HEIGHT;
    new_bottom = (player.y >> 4) + PLAYER_HEIGHT;
    update_player_box();
    for (landing_index = 0; landing_index < PLATFORM_COUNT; landing_index = landing_index + 1) {
        if (platform_width[landing_index] != 0) {
            if ((old_bottom <= platform_y[landing_index]) && (new_bottom >= platform_y[landing_index])) {
#ifdef WEB64_EXAMPLE_VERIFY
                verification_crossings = verification_crossings + 1;
#endif
                if (overlaps_object(platform_x[landing_index], platform_y[landing_index], platform_width[landing_index], 6) != 0) {
#ifdef WEB64_EXAMPLE_VERIFY
                    verification_aabb_hits = verification_aabb_hits + 1;
#endif
                    player.y = ((uint16_t)(platform_y[landing_index] - PLAYER_HEIGHT)) << 4;
                    if (platform_kind[landing_index] == PLATFORM_SPRING) {
                        player.vy = -96;
                    } else {
                        player.vy = -80;
                    }
                    if (platform_scored[landing_index] == 0) {
                        platform_scored[landing_index] = 1;
                        if (platform_kind[landing_index] == PLATFORM_SPRING) {
                            score = score + 30;
                        } else {
                            score = score + 10;
                        }
#ifdef WEB64_EXAMPLE_VERIFY
                        verification_scored_landings = verification_scored_landings + 1;
#endif
                    } else {
#ifdef WEB64_EXAMPLE_VERIFY
                        verification_repeat_landings = verification_repeat_landings + 1;
#endif
                    }
                    if (platform_kind[landing_index] == PLATFORM_CRUMBLE) {
                        platform_width[landing_index] = 0;
                    }
                    boost_ready = 1;
                    asm_sfx_bounce();
#ifdef WEB64_EXAMPLE_VERIFY
                    verification_landings = verification_landings + 1;
#endif
                    return 1;
                }
            }
        }
    }
    return 0;
}

static void collect_spark(void) {
    if (spark_active == 0) {
        return;
    }
    if (overlaps_object(spark_x, spark_y, 12, 12) != 0) {
        spark_active = 0;
        score = score + 250;
        asm_sfx_collect();
    }
}

static uint8_t hit_enemy(void) {
    if (invulnerable != 0) {
        return 0;
    }
    return overlaps_object(enemy_x, enemy_y, 16, 16);
}

static void select_runner_animation(int8_t intent) {
    uint8_t sequence;
    if (intent != 0) {
        sequence = 0;
    } else if (player.vy < 0) {
        sequence = 1;
    } else {
        sequence = 2;
    }
    if (sequence != runner_animation_state) {
        runner_animation_state = sequence;
        web64_animation_play(&runner_animation, sequence, WEB64_ANIMATION_PLAY_IF_CHANGED);
    }
}

static void lose_life(void) {
    asm_sfx_crash();
    if (lives > 1) {
        lives = lives - 1;
        platform_x[0] = 112;
        platform_y[0] = 154;
        platform_width[0] = 72;
        platform_kind[0] = PLATFORM_NORMAL;
        platform_scored[0] = 1;
        reset_player();
        return;
    }
    lives = 0;
    if (score > high_score) {
        high_score = score;
    }
    update_hud();
    game_state = STATE_GAME_OVER;
}

static void update_game(uint8_t joy) {
    int8_t intent;
    uint16_t old_y;
    uint16_t top_gap;
    uint8_t scroll_pixels;
    intent = 0;
    if ((joy & JOY_LEFT_MASK) == 0) {
        intent = -1;
    }
    if ((joy & JOY_RIGHT_MASK) == 0) {
        intent = 1;
    }
    player.vx = web64_motion_axis(player.vx, intent, 4, 5, 32);
#ifdef WEB64_EXAMPLE_VERIFY
    verification_runtime_motion = 1;
#endif
    web64_motion_integrate(&player.x, player.vx);
    web64_motion_clamp(&player.x, &player.vx, 0, PLAYER_MAX_X);
    if (((joy & JOY_FIRE_MASK) == 0) && ((previous_joy & JOY_FIRE_MASK) != 0) && (boost_ready != 0)) {
        if (player.vy > -72) {
            player.vy = player.vy - 28;
        }
        boost_ready = 0;
    }
    old_y = player.y;
    player.vy = web64_motion_axis(player.vy, 1, 3, 3, 80);
    web64_motion_integrate(&player.y, player.vy);
    if ((player.vy < 0) && (player.y < SCROLL_LINE)) {
        top_gap = SCROLL_LINE - player.y;
        scroll_pixels = (uint8_t)((top_gap + 15) >> 4);
        if (scroll_pixels > 5) {
            scroll_pixels = 5;
        }
        player.y = SCROLL_LINE;
        scroll_world(scroll_pixels);
    }
    if (player.vy >= 0) {
        find_landing(old_y);
    }
    select_runner_animation(intent);
    update_player_box();
    move_enemy();
    collect_spark();
    if (hit_enemy() != 0) {
        lose_life();
        return;
    }
    if ((player.y >> 4) > PLAYFIELD_HEIGHT) {
        lose_life();
        return;
    }
    if (invulnerable != 0) {
        invulnerable = invulnerable - 1;
    }
    frame_counter = frame_counter + 1;
    if (score > high_score) {
        high_score = score;
    }
    if ((frame_counter & 7) == 0) {
        update_hud();
    }
}

static void render_game(void) {
    asm_draw_playfield();
}

#ifdef WEB64_EXAMPLE_VERIFY
static uint8_t verification_joy(uint16_t frame) {
    uint8_t joy;
    uint8_t phase;
    joy = 0xff;
    /* Hold the opening ledge long enough to prove that its first landing pays
       and its next landing is rejected by the per-platform score latch. */
    if (frame < 128) {
        return joy;
    }
    phase = (uint8_t)frame & 63;
    if (phase < 16) {
        joy = joy & (uint8_t)~JOY_LEFT_MASK;
    } else if (phase < 32) {
        joy = joy & (uint8_t)~JOY_RIGHT_MASK;
    }
    if ((frame & 127) == 48) {
        joy = joy & (uint8_t)~JOY_FIRE_MASK;
    }
    return joy;
}
#endif

void main(void) {
    uint8_t joy;
    asm_init_video();
    high_score = 0;
    previous_joy = 0xff;
#ifdef WEB64_EXAMPLE_VERIFY
    {
        uint16_t frame;
        verification_complete = 0;
        verification_landings = 0;
        verification_crossings = 0;
        verification_aabb_hits = 0;
        verification_scroll = 0;
        verification_runtime_motion = 0;
        verification_runtime_collision = 0;
        verification_scored_landings = 0;
        verification_repeat_landings = 0;
        start_game();
        for (frame = 0; frame < 640; frame = frame + 1) {
            joy = verification_joy(frame);
            if (game_state == STATE_PLAYING) {
                update_game(joy);
                if (game_state == STATE_PLAYING) {
                    render_game();
                    asm_present_frame();
                }
            }
            if (game_state == STATE_GAME_OVER) {
                start_game();
            }
            previous_joy = joy;
            asm_audio_tick();
        }
        verification_complete = 1;
        return;
    }
#else
    game_state = STATE_TITLE;
    asm_draw_title();
    while (1) {
        joy = asm_read_joystick();
        asm_audio_tick();
        if (game_state == STATE_PLAYING) {
            update_game(joy);
            if (game_state == STATE_PLAYING) {
                render_game();
                asm_wait_frame();
                asm_present_frame();
            } else {
                asm_wait_frame();
                asm_hide_sprites();
                asm_draw_game_over();
            }
        } else {
            asm_wait_frame();
            if (game_state == STATE_TITLE) {
                asm_animate_title();
            }
            if (((joy & JOY_FIRE_MASK) == 0) && ((previous_joy & JOY_FIRE_MASK) != 0)) {
                start_game();
            }
        }
        previous_joy = joy;
    }
#endif
}
