# Sample Playback

Open `sample-playback.web64proj` in Web64 IDE, enable emulator audio, and press **Run**. The screen briefly blanks for stable timing while a spoken “Welcome to Web64” plays once; the centered title then appears. Press **Run** again to replay it.

The project contains `main.asm` and a 16,640-byte, noise-shaped 4-bit `assets/welcome.bin` in its virtual filesystem. One sample per byte changes SID master volume (`$d418`). Ordinary and page-wrap paths both take 123 PAL CPU cycles per sample (about 8.01 kHz). A single SID pulse voice with TEST and GATE set supplies a fixed DC bias, providing software digi boost for quieter 8580-style playback without hardware modifications. During playback, the program disables VIC display DMA for steady timing and banks out BASIC ROM so the entire sample remains readable in RAM, while SID I/O stays visible. The sample ends at a neutral level rather than abruptly dropping the volume; then the centered title returns. SID's voice filter is not in this master-volume playback path, so VCF settings do not smooth the sample steps.

The phrase was synthesized locally with the Microsoft Zira Desktop voice as “Welcome to Web sixty four,” then low-pass resampled and quantized for this example.

No external build tools or asset files are needed: the `.web64proj` is authoritative and self-contained.

Verified in Web64 IDE 2.4.5: native build completed without diagnostics and Run completed. Listening confirmed recognizable speech; with the one-voice software boost, reSID Realtime is still quieter than FastSID but the difference is acceptable. Real 6581/8580 hardware has not yet been auditioned. The native export was inspected, but a fresh-workspace reopen remains unverified because the connected workspace has unsaved changes and no permitted save handle.
