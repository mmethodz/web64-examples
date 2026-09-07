.include "cold-imports.inc"
; Ordinary native target header. Entry bypasses standalone C stack startup.
cold_image_end:
* = $b000
    jmp _cold_entry
    .byte $4d,$36,$34,$43,1
    .word cold_image_end-$b000
    .byte 2,1,0,0,0,0
