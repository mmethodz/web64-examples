# C plasma effect

Open `c-plasma.web64proj` in [Web64 IDE](https://web64.nofs.ai/ide/) and press **F5 / Start PRG**. `main.c` renders a character-mode plasma using a 512-entry byte sine table and an editable shading charset.

The table includes Web64 generator metadata identifying its sine preset, sample count and byte output. To experiment, use the IDE's table generator and preserve the value range expected by the charset. `assets/generated.h` supplies bindings for `assets/chars/charset.chr`; the program copies those character bytes to `$2000` before selecting them with the VIC memory register.

The Main target includes `main.c` and the assembly shell, starts at `$4000` and produces `c-plasma.prg`. Edit the virtual C source or use Char Editor, run again, then save the project to retain changes. No native C toolchain is required.
