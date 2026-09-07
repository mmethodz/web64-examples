.include "assets/chars/core.inc"
.incbin core_chars, "assets/chars/core.w64chr"
.incbin visual_animation, "assets/chars/core-animation.w64chr", 0, 1024
    .byte $0e,$0b,$09,$09,$0e,$0b,$09,$09,$0e,$0b,$09,$09,$0e,$0b,$09,$09
    .byte $0e,$0b,$0b,$0f,$0b,$0f,$09,$09,$0e,$0b,$09,$09,$0e,$0b,$09,$09
    .byte $0e,$0b,$09,$09,$0e,$0b,$09,$09,$0e,$0b,$09,$09,$0e,$0b,$09,$09
    .fill 16,0
.incbin visual_blocks, "assets/blocks/core.w64blk"
    .fill 0,0
    .byte 67,89,86,1,3,core_multicolor_1,core_multicolor_2
    .byte $00,$03,$06,$12,$13,$17,$18,$1b
    .fill 753,0
.incbin visual_sprites, "assets/sprites/core.w64spr"
.incbin visual_death, "assets/sprites/death.w64spr"
.incbin reaction_pixels, "assets/sprites/reactions.w64spr"
