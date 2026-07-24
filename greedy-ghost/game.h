#ifndef GHOST_CHASE_C_GAME_H
#define GHOST_CHASE_C_GAME_H

void setup_video(void);
void copy_charset(void);
void copy_sprites(void);
void clear_screen(void);
void paint_scene(void);
void sid_init(void);
void sprite_init(void);
void wait_frame(void);
void play_sid(void);
void pulse_scene(void);
void asm_draw_score(void);

#endif