.include "assets/chars/archive.inc"
.incbin archive_chars, "assets/chars/archive.w64chr"
.incbin visual_animation, "assets/chars/archive-animation.w64chr", 0, 1024
    .byte $0e,$0b,$09,$09,$0e,$0b,$09,$09,$0e,$0b,$09,$09,$0e,$0b,$09,$09
    .byte $0e,$0b,$0b,$0f,$0b,$0f,$09,$09,$0e,$0b,$09,$09,$0e,$0b,$09,$09
    .byte $0e,$0b,$09,$09,$0e,$0b,$09,$09,$0e,$0b,$09,$09,$0e,$0b,$09,$09
    .fill 16,0
.incbin visual_blocks, "assets/blocks/archive.w64blk"
    .fill 0,0
    .byte 67,89,86,1,1,archive_multicolor_1,archive_multicolor_2
    .byte $00,$03,$06,$12,$13,$14,$15,$19
    .fill 753,0
.incbin visual_sprites, "assets/sprites/archive.w64spr"
.incbin visual_death, "assets/sprites/death.w64spr"
.incbin reaction_pixels, "assets/sprites/reactions.w64spr"
