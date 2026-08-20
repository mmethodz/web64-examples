# Web64 Game Runtime World-module examples

These examples exercise the independently linked World modules within Web64 Game Runtime, using first-class native .w64 assets and joystick-driven demos. Import the .web64proj file from any folder into Web64 IDE and press Run. Browser gamepad polling is enabled for joystick port 2, and the numeric keypad remains available at the same time.

- [World Static Map](./world-static-map/README.md) — Move the sprite with joystick port 2. Press fire to mutate a visible map cell. This example renders the native per-cell Color RAM plane.
- [World Horizontal Scroller](./world-horizontal-scroller/README.md) — Use left/right on joystick port 2 to scroll the camera. Up/down moves only the sprite marker.
- [World Subpixel Motion Scroller](./world-subpixel-scroller/README.md) — Use left/right to drive a Q12.4 Motion camera through acceleration, braking, reversal, and a deterministic stop before World renders it.
- [World Vertical Scroller](./world-vertical-scroller/README.md) — Use up/down on joystick port 2 to scroll the camera. Left/right moves only the sprite marker.
- [World Bidirectional Scroller](./world-bidirectional-scroller/README.md) — Use all joystick directions to scroll the camera over a wider and taller native map.
- [World Multicolor Scroller](./world-multicolor-scroller/README.md) — A multicolor character-mode scroller. Use all joystick directions on port 2.
- [Game Runtime World Platformer](./world-runtime-platformer/README.md) — Move with left/right and jump with fire or up. The camera follows the player over a multicolor map.
- [World + Motion and Sprites Actor Camera](./world-runtime-actor-camera/README.md) — Use left/right to exercise Game Runtime Motion together with World camera/streaming and native Sprites.

The moving examples use the v5 buffered World renderer. The VIC always displays an immutable screen page while neighboring pages are prepared offscreen over the fine-scroll transition; the time-critical page selection completes in the lower border. The VIC's 38-column/24-row edge masks prevent unbacked cells from becoming visible during fine scrolling. Camera clamping stops cleanly at map edges without replaying terminal rows or columns, and stopping or reversing midway through a cell preserves the exact fine phase. At each completed character boundary, the renderer presents the exact per-cell native map colors in Color RAM from top to bottom ahead of the visible raster. Intermediate and idle frames perform no screen or Color RAM writes. The static example also renders the exact native per-cell Color RAM plane.

The platformer is a playable integration example: Game Runtime Motion supplies acceleration, braking and gravity; Collision reads the native material plane; Sprite Runtime renders a hires player over a multicolor character map; and World follows the actor without owning the game loop.
