# C sprite and joystick

Open **`web64-c-sprite-joy.web64proj`** in [Web64 IDE](https://web64.nofs.ai/ide/) and press **F5 / Start PRG**. Use joystick port 2 to move; fire changes the player sprite from yellow to red. Configure keyboard joystick emulation in Emulator Options if no controller is available.

C owns joystick polling, movement, sprite positioning and frame selection. The project also contains assembly support and an editable sprite bank at `assets/sprites/c-joy.spr`. Inspect the configured translation units in Build Targets rather than importing the reference note as another source file.

The target produces `web64-c-sprite-joy.prg` at `$c000`. This deliberately retains its original `web64-static-v0` ABI; it is not a reason to select that ABI for every new C project. The current IDE can build the saved project directly. Edit virtual sources/assets and use **Save Web64 project** to preserve changes.
