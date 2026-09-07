.include "assets/chars/works.inc"
.incbin works_chars, "assets/chars/works.w64chr"
.incbin visual_animation, "assets/chars/works-animation.w64chr", 0, 1024
    .byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
    .byte $0f,$0f,$0b,$0f,$0b,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
    .byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
    .fill 16,0
.incbin visual_blocks, "assets/blocks/works.w64blk"
    .fill 0,0
    .byte 67,89,86,1,2,works_multicolor_1,works_multicolor_2
    .byte $00,$03,$06,$16,$17,$18,$19,$1a
    .fill 753,0
.incbin visual_sprites, "assets/sprites/works.w64spr"
.incbin visual_death, "assets/sprites/death.w64spr"
.incbin reaction_pixels, "assets/sprites/reactions.w64spr"
