# Bitmap Drawing

This standalone Web64 project demonstrates the checked and fast Bitmap Drawing Runtime in multicolor bitmap mode.

- `web64_bitmap_init` validates and activates caller-selected bitmap and screen memory, clears the bitmap, and installs one palette uniformly.
- Lines, rectangles, ellipses, circles, and dots operate on logical pixel indices rather than raw packed bitmap bits.
- The bounded flood fill uses caller-owned span storage and replace-only v1 semantics. It never changes screen or Color RAM palette assignments.
- Fast calls are used only with in-range coordinates and palette-valid indices.

Open `bitmap-drawing.web64proj` in Web64 IDE and run it. The finished bitmap remains on screen after `main` returns.
