#include <stdint.h>
#include <web64/animation.h>
#include <web64/disk.h>

/* Cold orchestration only. Animation and disk runtime primitives are called
   from engine.asm through Web64's generated, exact-width argument macros. */
extern uint8_t run_active;
void cyber_init(void);
void cyber_title(void);
void cyber_new_game(void);
void cyber_load_level(void);
void cyber_play_level(void);
void cyber_scores(void);
void cyber_ending(void);

void main(void) {
    cyber_init();
    for (;;) {
        cyber_title();
        cyber_new_game();
        while (run_active != 0) {
            cyber_load_level();
            if (run_active != 0) cyber_play_level();
        }
        cyber_ending();
        cyber_scores();
    }
}
