# Aurora tutorial narration

## What we are building

Welcome to Web sixty four. In this tutorial, we will make Aurora: a colourful character plasma with a custom character set and a scrolling message. Everything belongs to one native Web sixty four project, so the source, graphics, and build settings travel together.

We will use C for setup and text, and a small sixty-five-oh-two assembly loop for the animated field. You do not need to type hundreds of lines while watching. The accompanying source and character set are supplied teaching files. We will import them, examine the important parts, make a small edit, and run the result in the integrated Commodore sixty four emulator.

## Create and save the project

Begin in the Code tab. The file tree is our view of the project. Open New and choose C project. Web sixty four creates a C starter with a main function and its own build target. The template note explains the starting structure; main dot C is the program entry source.

Save the project early, using the project save control at the top. I am calling this Plasma Tutorial. The web sixty four proj file is the complete working project. Saving only a C source file would not preserve the character set and target settings that we are about to add.

There are two useful distinctions here. A source file is something we edit. A build target describes what the IDE produces from those files. The final P R G is the executable result. Keep the native project as your editable master, and export the P R G when you want to distribute or run the built program elsewhere.

## Import and inspect the custom charset

Now import the supplied Aurora dot C H R file using Import, Add files. This is a raw character set: two thousand and forty-eight bytes, or two hundred and fifty-six characters with eight bytes per character. Once imported, it becomes a native editable graphics asset in the project.

Open the Char Editor. Each thumbnail represents an eight by eight pixel character. The large grid edits one character, while the properties describe its index and video mode. Our set contains a small uppercase font and sixteen ordered-dither patterns. The font gives the demonstration its own lettering. The patterns turn a simple character grid into a textured display.

This project uses text hires mode. Each character pixel is either background or foreground; the foreground colour can still vary from screen cell to screen cell. We do not need bitmap mode for this effect. Select a letter, then a dither pattern, and compare the large pixel grid with the repeated tile preview.

For your own version, edit the graphic here. Web sixty four updates the generated bindings for you. Do not maintain a second handwritten copy of the generated include. Save the project again so that the editable asset and its source references stay together.

## Give code and graphics their own memory

Before adding the full program, set up the build target. Name the target Aurora and the output Aurora dot P R G. Set Origin to hexadecimal four thousand. The dollar sign is the assembler notation for a hexadecimal address.

Our memory layout is deliberately simple. Screen memory starts at hexadecimal zero four hundred. Colour R A M is at D eight hundred. The custom character set will be copied to three eight hundred. The program begins at four thousand, immediately after that two-kilobyte character area.

These addresses have different jobs. The program's load address does not choose where the video chip finds its characters. We will configure the VIC-two memory register separately in the source. Keeping those two decisions clear prevents a common error: loading graphics successfully but telling the video chip to display some other memory.

The root source stays main dot C, and the target remains a P R G program. This example needs no disk mastering step: its code and character data fit in a single executable.

## Build a plasma from two waves

Import plasma dot I N C using Add files. Then open main dot C and paste the supplied C source. These teaching files are included with the tutorial. The C program handles setup and text. Its plasma frame function includes the assembly kernel, which we can inspect as a separate file.

The effect begins with a table of two hundred and fifty-six sine samples. The values range from zero to thirty-one. We are using a lookup table instead of calculating trigonometry on the Commodore sixty four for every cell. Advancing a byte-sized phase naturally wraps around the table.

First, the code calculates forty horizontal samples and caches them. Those same samples can be reused for every row. For each of the eighteen plasma rows, it adds a vertical sample. Shifting the sum right by one gives an index from zero to thirty-one.

That index selects two things: a colour from the palette table, and a dither character from the glyph table. Colour R A M receives the colour. Screen memory receives the character number. The VIC-two combines them with the character set to draw the image.

Notice the separate horizontal and vertical increments: five and nine. They control how tightly the waves repeat across the display. The phase changes over time, so those waves flow through each other.

The store addresses advance by forty bytes at the end of each row. This kernel patches its own absolute store operands, so it belongs in writable memory. We disable interrupts in this small standalone demo; a larger program would need an explicit interrupt and memory-ownership design.

## Add a readable scrolling message

Next, find scroll text. The message is an ordinary C string, written in uppercase because our supplied font defines those character positions. Screen codes and character shapes are separate: the screen holds an index, and the character set supplies the pixels at that index.

Every third animation update, we move the bottom text row one character to the left. Then we put the next message character into the rightmost cell. When the string reaches its zero terminator, the message position returns to the beginning.

This is character scrolling, so it moves eight pixels at a time. It is intentionally simple and easy to adapt. A pixel-smooth scroller would also coordinate fine scrolling and a raster split; that is a separate lesson.

Change a few words in the message to make the demo yours. Keep the new text inside the quotation marks. The counter controls reading speed independently of the plasma phase. A larger threshold makes the text advance less frequently. After an edit, save and build before judging the new result in the emulator.

## Load the native asset through the SDK

The key asset handoff is in main. We include the Web sixty four assets header and the generated assets header. The generated header gives us Aurora asset, a descriptor for the character set stored in the project.

Web sixty four asset copy charset takes two arguments: the destination character R A M address, and a pointer to that descriptor. It validates the character data description and copies the asset. We check its status before enabling the display. A red border is our simple failure signal.

The runtime helper copies bytes; the program still chooses the VIC bank and memory layout. Here, the memory setup value selects screen memory at zero four hundred and characters at three eight hundred. We clear the screen and colour memory, draw the captions, and then turn the display on.

The SDK also provides assembly include helpers for its runtime calling convention. C callers use the typed declaration directly. If you later move this setup into assembly, use the matching preparation or call macro from the assets include rather than guessing how arguments are passed.

## Build, inspect and run

Before the final build, review Settings. This project uses the Web sixty four C compiler and its stack A B I. We select the speed profile, enable the relevant optimisation switches, and request runtime dependencies so the linker can keep the helpers the program needs.

The demo draws directly to screen memory, so standard input and output are set to None. The emulator display is set to one times: one-to-one scaling, not Fit. That keeps the pixel grid consistent throughout this tutorial.

Return to Build Targets and choose Build Target. Read the actual result: the output name, load address, and diagnostics. A successful build tells us that the compiler and linker accepted the project. It does not by itself prove that our graphics or animation are correct.

Start the P R G to test that next. The IDE loads and starts the compiled program in its integrated emulator. Look for all three parts: the Aurora title in our custom font, the changing plasma field, and the message advancing along the bottom. If an edit appears to do nothing, confirm that you built and started the intended target.

## Test the result and preserve it

Let the demonstration run for a moment. The two waves keep changing their relationship, so the field moves through different bands and curves. The ordered-dither characters add a second layer of variation without changing video mode or uploading a new bitmap every frame.

Watch the text as well as the colours. It should remain readable, advance at a regular pace, and eventually wrap to the beginning of the message. The fixed captions should stay still. Those are different responsibilities in the program, and checking each one is more useful than simply seeing something appear on screen.

The frame loop waits for a raster position before starting its next update. That gives the program a repeatable reference to the video signal. It is not a promise that every possible modification will fit inside one video frame. If you add work, measure again and test on the video standard you intend to support.

Now save the native project. A useful final check is to reopen that saved file in a fresh workspace and run the build again. This catches missing assets and settings that only existed in the previous session. The accompanying project has also been compiled and run in an independent VICE verification, including checks that the character bytes match and both animations change over time.

Keep the project file when sharing an editable example. The source handout and raw character file are helpful references, but the native project contains the linked assets, source, and build settings together. That is the file another Web sixty four user should open to continue the work.

## Make it your own

We have taken a C starter through asset import, memory planning, source integration, build, and execution. The finished result combines a custom font, sixteen dither patterns, two animated waves, and a character scroller.

For a first variation, change the text and the palette. For a second, adjust the horizontal and vertical wave increments. Change one thing at a time, build, and watch what it does. Keeping a working saved project makes it easy to compare versions and return to a known result.

The most reusable idea is the separation of responsibilities. The native asset editor owns the graphics. Generated bindings describe them. Runtime helpers perform the documented asset transfer. Your program chooses the memory layout and the effect. Build Targets describes the executable output, and the emulator lets you test that output immediately.

The supplied project, teaching files, and notes are included with this tutorial. Open the project, explore the code, and use it as a starting point for your own Commodore sixty four experiments. Thank you for watching.