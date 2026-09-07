.include "assets/chars/grid.inc"
.incbin grid_chars, "assets/chars/grid.w64chr"
.incbin visual_animation, "assets/chars/grid-animation.w64chr", 0, 1024
    .byte $0b,$0b,$0e,$0b,$0e,$0a,$0d,$0d,$0b,$0f,$0b,$0f,$0a,$0d,$0e,$0f
    .byte $0b,$0a,$0b,$0b,$0b,$0b,$0b,$0b,$0e,$0e,$0e,$0e,$0f,$0e,$0e,$0e
    .byte $0e,$0e,$0e,$0e,$0e,$0e,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
    .fill 16,0
.incbin visual_blocks, "assets/blocks/grid.w64blk"
    .fill 0,0
    .byte 67,89,86,1,0,grid_multicolor_1,grid_multicolor_2
    .byte $00,$03,$06,$07,$08,$09,$0c,$0d
    .fill 753,0
.incbin visual_sprites, "assets/sprites/bit.w64spr"
.incbin visual_death, "assets/sprites/death.w64spr"
