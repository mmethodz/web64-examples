#ifndef MIRROR_PULSE_COURSES_H
#define MIRROR_PULSE_COURSES_H

#define COURSE_COUNT 6
#define MAX_MIRRORS 5
#define MAX_PICKUPS 5
#define MAX_WALLS 3
#define MAX_BEAM_SEGMENTS 16
#define STARTING_PULSES 4

static const uint16_t course_time[COURSE_COUNT] = { 180, 210, 240, 270, 300, 300 };
static const uint8_t course_pulse_grant[COURSE_COUNT] = { 3, 3, 4, 4, 5, 5 };
static const uint8_t course_emitter_x[COURSE_COUNT] = { 10, 10, 30, 150, 10, 80 };
static const uint8_t course_emitter_y[COURSE_COUNT] = { 70, 170, 25, 180, 100, 190 };
static const uint8_t course_emitter_direction[COURSE_COUNT] = { 0, 0, 1, 2, 0, 3 };
static const uint8_t course_target_x[COURSE_COUNT] = { 20, 140, 60, 40, 130, 150 };
static const uint8_t course_target_y[COURSE_COUNT] = { 40, 150, 40, 160, 150, 40 };
static const uint8_t course_mirror_count[COURSE_COUNT] = { 2, 4, 3, 4, 5, 5 };
static const uint8_t course_pickup_count[COURSE_COUNT] = { 3, 4, 4, 4, 5, 5 };
static const uint8_t course_wall_count[COURSE_COUNT] = { 0, 1, 1, 2, 2, 3 };

static const uint8_t course_mirror_x[COURSE_COUNT][MAX_MIRRORS] = {
    { 100, 130, 0, 0, 0 },
    { 140, 100, 30, 120, 0 },
    { 20, 80, 140, 0, 0 },
    { 40, 80, 100, 50, 0 },
    { 150, 100, 20, 70, 120 },
    { 20, 60, 100, 150, 70 }
};
static const uint8_t course_mirror_y[COURSE_COUNT][MAX_MIRRORS] = {
    { 120, 160, 0, 0, 0 },
    { 40, 180, 120, 100, 0 },
    { 150, 170, 110, 0, 0 },
    { 40, 60, 180, 140, 0 },
    { 180, 170, 130, 40, 110 },
    { 60, 80, 140, 100, 180 }
};
static const uint8_t course_mirror_angle[COURSE_COUNT][MAX_MIRRORS] = {
    { 1, 0, 0, 0, 0 },
    { 1, 0, 1, 0, 0 },
    { 0, 1, 0, 0, 0 },
    { 0, 1, 0, 1, 0 },
    { 0, 0, 0, 1, 0 },
    { 1, 0, 1, 0, 1 }
};
static const uint8_t course_pickup_x[COURSE_COUNT][MAX_PICKUPS] = {
    { 30, 60, 40, 0, 0 },
    { 30, 50, 20, 80, 0 },
    { 30, 75, 105, 85, 0 },
    { 135, 120, 150, 90, 0 },
    { 25, 40, 20, 80, 130 },
    { 80, 110, 140, 30, 90 }
};
static const uint8_t course_pickup_y[COURSE_COUNT][MAX_PICKUPS] = {
    { 70, 55, 40, 0, 0 },
    { 170, 120, 120, 150, 0 },
    { 50, 70, 70, 40, 0 },
    { 180, 145, 140, 160, 0 },
    { 100, 140, 90, 50, 100 },
    { 175, 160, 170, 100, 40 }
};
static const uint8_t course_pickup_type[COURSE_COUNT][MAX_PICKUPS] = {
    { 0, 1, 2, 0, 0 },
    { 0, 2, 1, 0, 0 },
    { 2, 0, 1, 0, 0 },
    { 0, 2, 1, 0, 0 },
    { 0, 2, 1, 0, 2 },
    { 2, 0, 1, 2, 0 }
};
static const uint8_t course_wall_x[COURSE_COUNT][MAX_WALLS] = {
    { 0, 0, 0 },
    { 80, 0, 0 },
    { 60, 0, 0 },
    { 60, 80, 0 },
    { 60, 70, 0 },
    { 50, 90, 40 }
};
static const uint8_t course_wall_y[COURSE_COUNT][MAX_WALLS] = {
    { 0, 0, 0 },
    { 80, 0, 0 },
    { 100, 0, 0 },
    { 80, 135, 0 },
    { 90, 120, 0 },
    { 60, 110, 130 }
};
static const uint8_t course_wall_width[COURSE_COUNT][MAX_WALLS] = {
    { 0, 0, 0 },
    { 10, 0, 0 },
    { 60, 0, 0 },
    { 10, 40, 0 },
    { 60, 10, 0 },
    { 70, 50, 20 }
};
static const uint8_t course_wall_height[COURSE_COUNT][MAX_WALLS] = {
    { 0, 0, 0 },
    { 50, 0, 0 },
    { 10, 0, 0 },
    { 50, 8, 0 },
    { 10, 40, 0 },
    { 10, 10, 20 }
};

#ifdef WEB64_EXAMPLE_VERIFY
static const uint8_t solution_mirror_x[COURSE_COUNT][MAX_MIRRORS] = {
    { 60, 60, 0, 0, 0 },
    { 50, 50, 20, 20, 0 },
    { 30, 110, 110, 0, 0 },
    { 120, 120, 150, 150, 0 },
    { 40, 40, 20, 20, 130 },
    { 80, 140, 140, 30, 30 }
};
static const uint8_t solution_mirror_y[COURSE_COUNT][MAX_MIRRORS] = {
    { 70, 40, 0, 0, 0 },
    { 170, 90, 90, 150, 0 },
    { 70, 70, 40, 0, 0 },
    { 180, 120, 120, 160, 0 },
    { 100, 170, 170, 50, 50 },
    { 160, 160, 180, 180, 40 }
};
static const uint8_t solution_mirror_angle[COURSE_COUNT][MAX_MIRRORS] = {
    { 0, 1, 0, 0, 0 },
    { 0, 1, 0, 1, 0 },
    { 1, 0, 1, 0, 0 },
    { 1, 0, 1, 0, 0 },
    { 1, 0, 1, 0, 1 },
    { 0, 1, 0, 1, 0 }
};
#endif

#endif
