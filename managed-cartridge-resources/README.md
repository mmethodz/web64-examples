# Managed Cartridge Resources

Open `managed-cartridge-resources.web64proj` in Web64 IDE. In **Disk/Media → Cartridge Layouts**, choose Standard 8K, Standard 16K, Magic Desk, or EasyFlash, then select **Run Cartridge** (`Ctrl+Alt+F5`). The CRT cold-boots through VICE's real cartridge path. A successful run displays `WEB64 ASM` in white on black, with a blue border.

The project has one resident mixed C/ASM Build Target and four native cartridge layouts. `main.c` initializes the VIC for cartridge cold boot, calls the managed resource API in `<web64/cartridge.h>`, and reads the four-byte palette into `$5000`. `palette-probe.asm` includes `web64/cartridge.inc` and the build-generated `cartridge/generated.inc`, then reads the same logical resource into `$5004` through `web64_rt_call_cart_resource_read`. The visible `ASM` suffix appears only after both paths succeed. Resource IDs are build-local handles; the application does not encode banks or ROM windows.

The palette is an editable project binary at `assets/palette.bin`. Build Cartridge creates the resource directory at `$4000` and reserves `$5000–$50FF` as a writable destination. The resident program loads at `$2000`. To explore larger multi-extent resources, import a binary into the project, add it under **Managed resources** in each layout, and use `web64_cart_resource_copy` for a transfer exceeding 256 bytes. Fixed Standard 8K/16K layouts have much less ROM capacity than Magic Desk and EasyFlash.

Use **Run Cartridge**, not F5/Start PRG: the resident target depends on real cartridge mapping and a generated directory. Cartridge data is immutable; this example does not save changes into the CRT. Its C and ASM sources, resource, target, layouts, and memory declarations are all stored in the `.web64proj`; rebuilding requires no host script.

See the Web64 IDE's **Cartridge Runtime** reference for the C structs, assembly macros, status codes, IRQ/scratch rules, and memory safety contract.
