/*
 * Web64 IDE Example
 * Name: Ghost Chase C
 * Description: Fixed-point player movement, two inertial enemies, animated sprites, coins, lives, and SID playback.
 */

#include <stdint.h>
#include <stdbool.h>
#include <c64.h>
#include "game.h"

#define PLAYER_POINTER 0xc0
#define COIN_POINTER 0xc4
#define ENEMY_POINTER 0xd0
#define VIC_SPRITE1_X 0xd002
#define VIC_SPRITE1_Y 0xd003
#define VIC_SPRITE2_X 0xd004
#define VIC_SPRITE2_Y 0xd005
#define VIC_SPRITE3_X 0xd006
#define VIC_SPRITE3_Y 0xd007
#define VIC_SPRITE_ENABLE 0xd015
#define VIC_SPRITE1_COLOR 0xd028

#define PLAYER_START_X 5120
#define PLAYER_START_Y 4288
#define ENEMY1_START_X 768
#define ENEMY1_START_Y 1856
#define ENEMY2_START_X 9440
#define ENEMY2_START_Y 6720
#define PLAYFIELD_MIN_X 768
#define PLAYFIELD_MAX_X 9440
#define PLAYFIELD_MIN_Y 1856
#define PLAYFIELD_MAX_Y 6720
#define PLAYER_WRAP_X 10240

#define PLAYER_X_ACCEL 6
#define PLAYER_Y_ACCEL 5
#define PLAYER_DECEL 4
#define PLAYER_X_MAX 128
#define PLAYER_Y_MAX 96
#define ENEMY_X_ACCEL 4
#define ENEMY_Y_ACCEL 3
#define ENEMY_X_DECEL 3
#define ENEMY_Y_DECEL 2
#define ENEMY_X_MAX 77
#define ENEMY_Y_MAX 58
#define ENEMY_X_SLOW_RANGE 256
#define ENEMY_Y_SLOW_RANGE 224
#define TARGET_SAMPLE_FRAMES 25
#define HIT_FLASH_FRAMES 50

int16_t player_x = PLAYER_START_X;
int16_t player_y = PLAYER_START_Y;
int16_t player_dx = 0;
int16_t player_dy = 0;
int16_t enemy1_x = ENEMY1_START_X;
int16_t enemy1_y = ENEMY1_START_Y;
int16_t enemy1_dx = 0;
int16_t enemy1_dy = 0;
int16_t enemy2_x = ENEMY2_START_X;
int16_t enemy2_y = ENEMY2_START_Y;
int16_t enemy2_dx = 0;
int16_t enemy2_dy = 0;
int16_t enemy1_target_x = PLAYER_START_X;
int16_t enemy1_target_y = PLAYER_START_Y;
int16_t coin_target_x = 5888;
int16_t coin_target_y = 3072;

uint16_t player_screen_x = 160;
uint16_t enemy1_screen_x = 24;
uint16_t enemy2_screen_x = 295;
uint8_t player_screen_y = 134;
uint8_t enemy1_screen_y = 58;
uint8_t enemy2_screen_y = 210;
uint8_t joy_now = JOY_RELEASED_MASK;
uint8_t player_frame = 0;
uint8_t player_anim_delay = 0;
uint8_t enemy_frame = 0;
uint8_t enemy_anim_delay = 0;
uint8_t enemy_target_delay = 0;
uint16_t coin_x = 184;
uint8_t coin_y = 96;
uint8_t coin_frame = 0;
uint8_t coin_delay = 0;
uint8_t coin_forward = 1;
uint8_t hit_flash_frames = 0;
uint8_t rng = 73;
uint8_t score = 0;
uint8_t lives = 3;
uint8_t frame_counter = 0;
uint8_t game_over_state = 0;

// --- ZERO-PARAMETER COLLISION SYSTEM ---
uint16_t col_x1;
uint16_t col_x2;
uint8_t col_y1;
uint8_t col_y2;

void read_joy(void) {
    joy_now = *(uint8_t*)JOYPORT_2;
}

void show_game_over(void) {
    uint16_t r1 = 0x0400 + (12 * 40) + 15;
    uint16_t c1 = 0xd800 + (12 * 40) + 15;
    uint16_t r2 = 0x0400 + (14 * 40) + 12;
    uint16_t c2 = 0xd800 + (14 * 40) + 12;

    // "GAME OVER"
    *(uint8_t*)(r1 + 0) = 68; *(uint8_t*)(c1 + 0) = 1; // G
    *(uint8_t*)(r1 + 1) = 65; *(uint8_t*)(c1 + 1) = 1; // A
    *(uint8_t*)(r1 + 2) = 70; *(uint8_t*)(c1 + 2) = 1; // M
    *(uint8_t*)(r1 + 3) = 66; *(uint8_t*)(c1 + 3) = 1; // E
    *(uint8_t*)(r1 + 4) = 64; *(uint8_t*)(c1 + 4) = 1; // [space]
    *(uint8_t*)(r1 + 5) = 71; *(uint8_t*)(c1 + 5) = 1; // O
    *(uint8_t*)(r1 + 6) = 75; *(uint8_t*)(c1 + 6) = 1; // V
    *(uint8_t*)(r1 + 7) = 66; *(uint8_t*)(c1 + 7) = 1; // E
    *(uint8_t*)(r1 + 8) = 72; *(uint8_t*)(c1 + 8) = 1; // R

    // "FIRE TO RESTART"
    *(uint8_t*)(r2 + 0) = 67;  *(uint8_t*)(c2 + 0) = 10; // F
    *(uint8_t*)(r2 + 1) = 69;  *(uint8_t*)(c2 + 1) = 10; // I
    *(uint8_t*)(r2 + 2) = 72;  *(uint8_t*)(c2 + 2) = 10; // R
    *(uint8_t*)(r2 + 3) = 66;  *(uint8_t*)(c2 + 3) = 10; // E
    *(uint8_t*)(r2 + 4) = 64;  *(uint8_t*)(c2 + 4) = 10; // [space]
    *(uint8_t*)(r2 + 5) = 74;  *(uint8_t*)(c2 + 5) = 10; // T
    *(uint8_t*)(r2 + 6) = 71;  *(uint8_t*)(c2 + 6) = 10; // O
    *(uint8_t*)(r2 + 7) = 64;  *(uint8_t*)(c2 + 7) = 10; // [space]
    *(uint8_t*)(r2 + 8) = 72;  *(uint8_t*)(c2 + 8) = 10; // R
    *(uint8_t*)(r2 + 9) = 66;  *(uint8_t*)(c2 + 9) = 10; // E
    *(uint8_t*)(r2 + 10) = 73; *(uint8_t*)(c2 + 10) = 10;// S
    *(uint8_t*)(r2 + 11) = 74; *(uint8_t*)(c2 + 11) = 10;// T
    *(uint8_t*)(r2 + 12) = 65; *(uint8_t*)(c2 + 12) = 10;// A
    *(uint8_t*)(r2 + 13) = 72; *(uint8_t*)(c2 + 13) = 10;// R
    *(uint8_t*)(r2 + 14) = 74; *(uint8_t*)(c2 + 14) = 10;// T

    *(uint8_t*)VIC_SPRITE_ENABLE = 0;
}

void hide_game_over(void) {
    uint16_t r1 = 0x0400 + (12 * 40) + 15;
    uint16_t r2 = 0x0400 + (14 * 40) + 12;
    uint8_t i;
    
    for (i = 0; i < 9; i++) {
        *(uint8_t*)(r1 + i) = 0;
    }
    for (i = 0; i < 15; i++) {
        *(uint8_t*)(r2 + i) = 0;
    }
}

void trigger_game_over(void) {
    game_over_state = 1;
    show_game_over();
}

void update_player_x_velocity(void) {
    if ((joy_now & JOY_LEFT) == 0) {
        player_dx = player_dx - PLAYER_X_ACCEL;
        if (player_dx < -PLAYER_X_MAX) {
            player_dx = -PLAYER_X_MAX;
        }
        return;
    }
    if ((joy_now & JOY_RIGHT) == 0) {
        player_dx = player_dx + PLAYER_X_ACCEL;
        if (player_dx > PLAYER_X_MAX) {
            player_dx = PLAYER_X_MAX;
        }
        return;
    }
    if (player_dx > 0) {
        if (player_dx <= PLAYER_DECEL) {
            player_dx = 0;
        } else {
            player_dx = player_dx - PLAYER_DECEL;
        }
        return;
    }
    if (player_dx < 0) {
        if (player_dx >= -PLAYER_DECEL) {
            player_dx = 0;
        } else {
            player_dx = player_dx + PLAYER_DECEL;
        }
    }
}

void update_player_y_velocity(void) {
    if ((joy_now & JOY_UP) == 0) {
        player_dy = player_dy - PLAYER_Y_ACCEL;
        if (player_dy < -PLAYER_Y_MAX) {
            player_dy = -PLAYER_Y_MAX;
        }
        return;
    }
    if ((joy_now & JOY_DOWN) == 0) {
        player_dy = player_dy + PLAYER_Y_ACCEL;
        if (player_dy > PLAYER_Y_MAX) {
            player_dy = PLAYER_Y_MAX;
        }
        return;
    }
    if (player_dy > 0) {
        if (player_dy <= PLAYER_DECEL) {
            player_dy = 0;
        } else {
            player_dy = player_dy - PLAYER_DECEL;
        }
        return;
    }
    if (player_dy < 0) {
        if (player_dy >= -PLAYER_DECEL) {
            player_dy = 0;
        } else {
            player_dy = player_dy + PLAYER_DECEL;
        }
    }
}

void update_enemy1_x_velocity(void) {
    if (enemy1_target_x > enemy1_x + ENEMY_X_SLOW_RANGE) {
        if (enemy1_dx < 0) {
            enemy1_dx = enemy1_dx + ENEMY_X_DECEL;
        } else {
            enemy1_dx = enemy1_dx + ENEMY_X_ACCEL;
        }
        if (enemy1_dx > ENEMY_X_MAX) {
            enemy1_dx = ENEMY_X_MAX;
        }
        return;
    }
    if (enemy1_x > enemy1_target_x + ENEMY_X_SLOW_RANGE) {
        if (enemy1_dx > 0) {
            enemy1_dx = enemy1_dx - ENEMY_X_DECEL;
        } else {
            enemy1_dx = enemy1_dx - ENEMY_X_ACCEL;
        }
        if (enemy1_dx < -ENEMY_X_MAX) {
            enemy1_dx = -ENEMY_X_MAX;
        }
        return;
    }
    if (enemy1_dx > 0) {
        if (enemy1_dx <= ENEMY_X_DECEL) {
            enemy1_dx = 0;
        } else {
            enemy1_dx = enemy1_dx - ENEMY_X_DECEL;
        }
        return;
    }
    if (enemy1_dx < 0) {
        if (enemy1_dx >= -ENEMY_X_DECEL) {
            enemy1_dx = 0;
        } else {
            enemy1_dx = enemy1_dx + ENEMY_X_DECEL;
        }
    }
}

void update_enemy1_y_velocity(void) {
    if (enemy1_target_y > enemy1_y + ENEMY_Y_SLOW_RANGE) {
        if (enemy1_dy < 0) {
            enemy1_dy = enemy1_dy + ENEMY_Y_DECEL;
        } else {
            enemy1_dy = enemy1_dy + ENEMY_Y_ACCEL;
        }
        if (enemy1_dy > ENEMY_Y_MAX) {
            enemy1_dy = ENEMY_Y_MAX;
        }
        return;
    }
    if (enemy1_y > enemy1_target_y + ENEMY_Y_SLOW_RANGE) {
        if (enemy1_dy > 0) {
            enemy1_dy = enemy1_dy - ENEMY_Y_DECEL;
        } else {
            enemy1_dy = enemy1_dy - ENEMY_Y_ACCEL;
        }
        if (enemy1_dy < -ENEMY_Y_MAX) {
            enemy1_dy = -ENEMY_Y_MAX;
        }
        return;
    }
    if (enemy1_dy > 0) {
        if (enemy1_dy <= ENEMY_Y_DECEL) {
            enemy1_dy = 0;
        } else {
            enemy1_dy = enemy1_dy - ENEMY_Y_DECEL;
        }
        return;
    }
    if (enemy1_dy < 0) {
        if (enemy1_dy >= -ENEMY_Y_DECEL) {
            enemy1_dy = 0;
        } else {
            enemy1_dy = enemy1_dy + ENEMY_Y_DECEL;
        }
    }
}

void update_enemy2_x_velocity(void) {
    if (coin_target_x > enemy2_x + ENEMY_X_SLOW_RANGE) {
        if (enemy2_dx < 0) {
            enemy2_dx = enemy2_dx + ENEMY_X_DECEL;
        } else {
            enemy2_dx = enemy2_dx + ENEMY_X_ACCEL;
        }
        if (enemy2_dx > ENEMY_X_MAX) {
            enemy2_dx = ENEMY_X_MAX;
        }
        return;
    }
    if (enemy2_x > coin_target_x + ENEMY_X_SLOW_RANGE) {
        if (enemy2_dx > 0) {
            enemy2_dx = enemy2_dx - ENEMY_X_DECEL;
        } else {
            enemy2_dx = enemy2_dx - ENEMY_X_ACCEL;
        }
        if (enemy2_dx < -ENEMY_X_MAX) {
            enemy2_dx = -ENEMY_X_MAX;
        }
        return;
    }
    if (enemy2_dx > 0) {
        if (enemy2_dx <= ENEMY_X_DECEL) {
            enemy2_dx = 0;
        } else {
            enemy2_dx = enemy2_dx - ENEMY_X_DECEL;
        }
        return;
    }
    if (enemy2_dx < 0) {
        if (enemy2_dx >= -ENEMY_X_DECEL) {
            enemy2_dx = 0;
        } else {
            enemy2_dx = enemy2_dx + ENEMY_X_DECEL;
        }
    }
}

void update_enemy2_y_velocity(void) {
    if (coin_target_y > enemy2_y + ENEMY_Y_SLOW_RANGE) {
        if (enemy2_dy < 0) {
            enemy2_dy = enemy2_dy + ENEMY_Y_DECEL;
        } else {
            enemy2_dy = enemy2_dy + ENEMY_Y_ACCEL;
        }
        if (enemy2_dy > ENEMY_Y_MAX) {
            enemy2_dy = ENEMY_Y_MAX;
        }
        return;
    }
    if (enemy2_y > coin_target_y + ENEMY_Y_SLOW_RANGE) {
        if (enemy2_dy > 0) {
            enemy2_dy = enemy2_dy - ENEMY_Y_DECEL;
        } else {
            enemy2_dy = enemy2_dy - ENEMY_Y_ACCEL;
        }
        if (enemy2_dy < -ENEMY_Y_MAX) {
            enemy2_dy = -ENEMY_Y_MAX;
        }
        return;
    }
    if (enemy2_dy > 0) {
        if (enemy2_dy <= ENEMY_Y_DECEL) {
            enemy2_dy = 0;
        } else {
            enemy2_dy = enemy2_dy - ENEMY_Y_DECEL;
        }
        return;
    }
    if (enemy2_dy < 0) {
        if (enemy2_dy >= -ENEMY_Y_DECEL) {
            enemy2_dy = 0;
        } else {
            enemy2_dy = enemy2_dy + ENEMY_Y_DECEL;
        }
    }
}

void sample_enemy_targets(void) {
    enemy_target_delay = enemy_target_delay + 1;
    if (enemy_target_delay < TARGET_SAMPLE_FRAMES) {
        return;
    }
    enemy_target_delay = 0;
    enemy1_target_x = player_x;
    enemy1_target_y = player_y;
}

void update_enemy_velocities(void) {
    update_enemy1_x_velocity();
    update_enemy1_y_velocity();
    update_enemy2_x_velocity();
    update_enemy2_y_velocity();
}

void apply_player_motion(void) {
    player_x = player_x + player_dx;
    if (player_x < 0) {
        player_x = player_x + PLAYER_WRAP_X;
    }
    if (player_x >= PLAYER_WRAP_X) {
        player_x = player_x - PLAYER_WRAP_X;
    }

    player_y = player_y + player_dy;
    if (player_y < PLAYFIELD_MIN_Y) {
        player_y = PLAYFIELD_MIN_Y;
        player_dy = 0;
    }
    if (player_y > PLAYFIELD_MAX_Y) {
        player_y = PLAYFIELD_MAX_Y;
        player_dy = 0;
    }
}

void apply_enemy_motion(void) {
    enemy1_x = enemy1_x + enemy1_dx;
    if (enemy1_x < PLAYFIELD_MIN_X) {
        enemy1_x = PLAYFIELD_MIN_X;
        enemy1_dx = 0;
    }
    if (enemy1_x > PLAYFIELD_MAX_X) {
        enemy1_x = PLAYFIELD_MAX_X;
        enemy1_dx = 0;
    }
    enemy1_y = enemy1_y + enemy1_dy;
    if (enemy1_y < PLAYFIELD_MIN_Y) {
        enemy1_y = PLAYFIELD_MIN_Y;
        enemy1_dy = 0;
    }
    if (enemy1_y > PLAYFIELD_MAX_Y) {
        enemy1_y = PLAYFIELD_MAX_Y;
        enemy1_dy = 0;
    }

    enemy2_x = enemy2_x + enemy2_dx;
    if (enemy2_x < PLAYFIELD_MIN_X) {
        enemy2_x = PLAYFIELD_MIN_X;
        enemy2_dx = 0;
    }
    if (enemy2_x > PLAYFIELD_MAX_X) {
        enemy2_x = PLAYFIELD_MAX_X;
        enemy2_dx = 0;
    }
    enemy2_y = enemy2_y + enemy2_dy;
    if (enemy2_y < PLAYFIELD_MIN_Y) {
        enemy2_y = PLAYFIELD_MIN_Y;
        enemy2_dy = 0;
    }
    if (enemy2_y > PLAYFIELD_MAX_Y) {
        enemy2_y = PLAYFIELD_MAX_Y;
        enemy2_dy = 0;
    }
}

void animate_player(void) {
    if ((player_dx == 0) && (player_dy == 0)) {
        player_frame = 0;
        player_anim_delay = 0;
        *(uint8_t*)VIC_SPRITE_POINTER_BASE = PLAYER_POINTER;
        return;
    }
    player_anim_delay = player_anim_delay + 1;
    if (player_anim_delay < 5) {
        return;
    }
    player_anim_delay = 0;
    player_frame = player_frame + 1;
    if (player_frame >= 4) {
        player_frame = 0;
    }
    *(uint8_t*)VIC_SPRITE_POINTER_BASE = PLAYER_POINTER + player_frame;
}

void animate_enemies(void) {
    enemy_anim_delay = enemy_anim_delay + 1;
    if (enemy_anim_delay < 5) {
        return;
    }
    enemy_anim_delay = 0;
    enemy_frame = enemy_frame + 1;
    if (enemy_frame >= 4) {
        enemy_frame = 0;
    }
    *(uint8_t*)(VIC_SPRITE_POINTER_BASE + 2) = ENEMY_POINTER + enemy_frame;
    *(uint8_t*)(VIC_SPRITE_POINTER_BASE + 3) = ENEMY_POINTER + enemy_frame;
}

void animate_coin(void) {
    coin_delay = coin_delay + 1;
    if (coin_delay < 2) {
        return;
    }
    coin_delay = 0;
    
    // Perfect ping-pong logic that never stalls
    if (coin_forward != 0) {
        coin_frame = coin_frame + 1;
        if (coin_frame == 7) { 
            coin_forward = 0;
        }
    } else {
        coin_frame = coin_frame - 1;
        if (coin_frame == 0) {
            coin_forward = 1;
        }
    }
    
    *(uint8_t*)(VIC_SPRITE_POINTER_BASE + 1) = COIN_POINTER + coin_frame;
}

void position_sprites(void) {
    uint8_t x_msb;
    uint8_t sprite_enable;

    // SAFETY CATCH: If the game is over, immediately abort and enforce sprites off!
    if (game_over_state != 0) {
        *(uint8_t*)VIC_SPRITE_ENABLE = 0;
        return; 
    }

    player_screen_x = (uint16_t)(player_x / 32);
    player_screen_y = (uint8_t)(player_y / 32);
    enemy1_screen_x = (uint16_t)(enemy1_x / 32);
    enemy1_screen_y = (uint8_t)(enemy1_y / 32);
    enemy2_screen_x = (uint16_t)(enemy2_x / 32);
    enemy2_screen_y = (uint8_t)(enemy2_y / 32);

    *(uint8_t*)VIC_SPRITE0_X = (uint8_t)player_screen_x;
    *(uint8_t*)VIC_SPRITE0_Y = player_screen_y;
    *(uint8_t*)VIC_SPRITE1_X = (uint8_t)coin_x;
    *(uint8_t*)VIC_SPRITE1_Y = coin_y;
    *(uint8_t*)VIC_SPRITE2_X = (uint8_t)enemy1_screen_x;
    *(uint8_t*)VIC_SPRITE2_Y = enemy1_screen_y;
    *(uint8_t*)VIC_SPRITE3_X = (uint8_t)enemy2_screen_x;
    *(uint8_t*)VIC_SPRITE3_Y = enemy2_screen_y;

    x_msb = 0;
    if (player_screen_x >= 256) {
        x_msb = x_msb | 0x01;
    }
    if (coin_x >= 256) {
        x_msb = x_msb | 0x02;
    }
    if (enemy1_screen_x >= 256) {
        x_msb = x_msb | 0x04;
    }
    if (enemy2_screen_x >= 256) {
        x_msb = x_msb | 0x08;
    }
    *(uint8_t*)VIC_SPRITE_X_MSB = x_msb;

    sprite_enable = 0x0f;
    if ((hit_flash_frames != 0) && ((hit_flash_frames & 0x04) != 0)) {
        sprite_enable = 0x0e;
    }
    *(uint8_t*)VIC_SPRITE_ENABLE = sprite_enable;
    *(uint8_t*)VIC_SPRITE1_COLOR = VIC_COLOR_YELLOW;

    if ((joy_now & JOY_FIRE) == 0) {
        *(uint8_t*)VIC_SPRITE0_COLOR = VIC_COLOR_RED;
    } else {
        *(uint8_t*)VIC_SPRITE0_COLOR = VIC_COLOR_WHITE;
    }
}

// Check collision using globals to avoid stack misalignment issues
uint8_t check_collision(void) {
    uint16_t dx;
    uint8_t dy;
    
    if (col_x1 >= col_x2) {
        dx = col_x1 - col_x2;
    } else {
        dx = col_x2 - col_x1;
    }
    if (dx >= 12) {
        return 0;
    }
    
    if (col_y1 >= col_y2) {
        dy = col_y1 - col_y2;
    } else {
        dy = col_y2 - col_y1;
    }
    if (dy >= 12) {
        return 0;
    }
    
    return 1;
}

void spawn_coin(void) {
    uint16_t random_x;
    uint8_t random_y;

    // Roll 1: Update RNG using frame entropy
    rng = (rng * 5) + 17 + frame_counter;
    random_x = rng;
    
    // Roll 2: Add 9th bit for X coordinates > 255
    rng = (rng * 5) + 17 + frame_counter;
    if ((rng & 0x01) != 0) {
        random_x = random_x + 256;
    }
    
    // Confine X to valid playfield width (295 - 24 = 271)
    while (random_x > 271) {
        random_x = random_x - 271;
    }
    coin_x = 24 + random_x;

    // Roll 3: Generate Y coordinate
    rng = (rng * 5) + 17 + frame_counter;
    random_y = rng;
    
    // Confine Y to valid playfield height (210 - 58 = 152)
    while (random_y > 152) {
        random_y = random_y - 152;
    }
    coin_y = 58 + random_y;

    // Map screen coordinates back to fixed-point AI targets
    coin_target_x = (int16_t)(coin_x * 32);
    coin_target_y = (int16_t)((uint16_t)coin_y * 32);
    coin_frame = 0;
    coin_delay = 0;
    coin_forward = 1;
    *(uint8_t*)(VIC_SPRITE_POINTER_BASE + 1) = COIN_POINTER;
}

void collect_coin(void) {
    // Setup coin coordinates in globals
    col_x1 = coin_x;
    col_y1 = coin_y;
    
    // Check Player
    col_x2 = player_screen_x;
    col_y2 = player_screen_y;
    if (check_collision() != 0) {
        score = score + 1;
        if (score >= 100) {
            score = 0;
        }
        spawn_coin();
        asm_draw_score();
        return;
    }
    
    // Check Enemy 1
    col_x2 = enemy1_screen_x;
    col_y2 = enemy1_screen_y;
    if (check_collision() != 0) {
        spawn_coin();
        return;
    }
    
    // Check Enemy 2
    col_x2 = enemy2_screen_x;
    col_y2 = enemy2_screen_y;
    if (check_collision() != 0) {
        spawn_coin();
    }
}

void reset_positions(void) {
    player_x = PLAYER_START_X;
    player_y = PLAYER_START_Y;
    player_dx = 0;
    player_dy = 0;
    enemy1_x = ENEMY1_START_X;
    enemy1_y = ENEMY1_START_Y;
    enemy1_dx = 0;
    enemy1_dy = 0;
    enemy2_x = ENEMY2_START_X;
    enemy2_y = ENEMY2_START_Y;
    enemy2_dx = 0;
    enemy2_dy = 0;
    enemy1_target_x = PLAYER_START_X;
    enemy1_target_y = PLAYER_START_Y;
    enemy_target_delay = 0;
}

void detect_enemy_hit(void) {
    uint8_t hit = 0;
    
    if (hit_flash_frames != 0) {
        return;
    }
    
    // Setup player coordinates in globals
    col_x1 = player_screen_x;
    col_y1 = player_screen_y;
    
    // Check Enemy 1
    col_x2 = enemy1_screen_x;
    col_y2 = enemy1_screen_y;
    hit = check_collision();
    
    // Check Enemy 2
    if (hit == 0) {
        col_x2 = enemy2_screen_x;
        col_y2 = enemy2_screen_y;
        hit = check_collision();
    }
    
    // Abort if no hit
    if (hit == 0) {
        return;
    }
    
    // Execute Death Sequence
    if (lives != 0) {
        lives = lives - 1;
    }
    hit_flash_frames = HIT_FLASH_FRAMES;
    asm_draw_score();
}

void update_hit_flash(void) {
    if (hit_flash_frames == 0) {
        return;
    }
    hit_flash_frames = hit_flash_frames - 1;
    if (hit_flash_frames != 0) {
        return;
    }
    
    if (lives == 0) {
        trigger_game_over();
    } else {
        reset_positions();
        asm_draw_score();
    }
}

void main(void) {
    setup_video();
    copy_charset();
    copy_sprites();
    clear_screen();
    paint_scene();
    sid_init();
    sprite_init();
    reset_positions();
    spawn_coin();
    position_sprites();
    asm_draw_score();

    while (true) {
        wait_frame();
        frame_counter = frame_counter + 1;
        play_sid();
        
        // Handle Game Over Logic State
        if (game_over_state != 0) {
            read_joy();
            if ((joy_now & JOY_FIRE) == 0) {
                hide_game_over();
                lives = 3;
                score = 0;
                game_over_state = 0;
                reset_positions();
                spawn_coin();
                position_sprites(); 
                asm_draw_score();
            }
        } else {
            // Standard Gameplay State
            update_hit_flash();
            
            // Re-check game_over_state in case update_hit_flash() just killed you!
            if (game_over_state == 0) { 
                if (hit_flash_frames == 0) {
                    read_joy();
                    update_player_x_velocity();
                    update_player_y_velocity();
                    sample_enemy_targets();
                    update_enemy_velocities();
                    apply_player_motion();
                    apply_enemy_motion();
                    animate_player();
                    animate_enemies();
                    animate_coin();
                    
                    // SYNC FIX: Update screen coordinates BEFORE collision checks!
                    position_sprites();
                    
                    collect_coin();
                    detect_enemy_hit();
                } else {
                    // Keep sprites flashing when frozen
                    position_sprites();
                }
            }
        }
        
        pulse_scene();
    }
}