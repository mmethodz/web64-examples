; A normal BASIC SYS line makes this low-memory resident directly bootable.
; The main C target starts its generated startup at $0810 (decimal 2064).
; Kept in source, so Disk/Media does not need a relocating loader over our code.
margin64_boot_resume:
* = $0801
    .word $080b
    .word 10
    .byte $9e,$32,$30,$36,$34,0
    .word 0
* = margin64_boot_resume
