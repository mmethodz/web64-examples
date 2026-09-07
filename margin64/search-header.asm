.include "cold-imports.inc"
; Service revision 1, module 3. All lengths resolve within this target.
cold_image_end:
* = $b000
    jmp _cold_entry
    .byte $4d,$36,$34,$43,1
    .word cold_image_end-$b000
    .byte 3,1,0,0,0,0
