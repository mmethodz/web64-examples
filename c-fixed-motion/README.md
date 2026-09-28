# C Fixed Motion

Steer a UFO with joystick port 2. The Web64-C program stores its position, velocity, and acceleration in a `Web64Motion2D` and advances all three with `web64_motion2d_integrate()` once per video frame.

Open `c-fixed-motion.web64proj` in Web64 IDE and press **F5** to build and run. Move the joystick to accelerate, release it to coast and gradually stop, or hold **Fire** to brake immediately. The border and on-screen mode label distinguish thrust, coast, and brake. The lower readout shows X/Y position and velocity as signed 8.8 hexadecimal values (for example, `$0100` is +1 pixel; `$ff00` is -1 pixel).

The UFO is an editable native sprite asset at `assets/sprites/ufo.w64spr` inside the project. The assembly source only includes the generated asset bytes; C uses `memcpy()` to transfer them to sprite RAM at `$3000`. `CURSOFF()` hides the BASIC cursor before the screen is cleared. No loose source files or external build chain are needed.

The generated Build Output should include the fixed-vector runtime module, but not the fixed multiply, division, or trigonometry modules.
