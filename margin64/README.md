# Margin64 0.1

A keyboard-driven C64 word-processor example, written in Web64-C and 6502
assembly. It is a readable, editable Web64 project and a practical application
stress test, not a commercial word-processor release.

## Open, build and run

Requires **Web64 2.4.1 or later**, including the compiler and I/O corrections
from this campaign. Use the updated IDE while that release awaits deployment.

1. Open `margin64.web64proj` in Web64 IDE. This saved project is the source of
   truth: it contains the complete virtual sources, compiler settings, build
   targets and disk layout. The adjacent sources are reference exports.
2. In **Disk/Media**, choose **Build Dependencies**, then **Run Disk**. Run Disk
   also builds missing or changed dependencies automatically. Its shortcut is
   **Ctrl+F5**; ordinary F5 runs the active PRG instead.
3. Click the emulator display and type. F1 opens the application menu. For
   numeric-keypad typing, choose **Keyboard off** under Emulator Options so the
   keypad is not assigned to joystick input.

The supplied `dist/margin64.d64` is the application disk. To rebuild it, use
**Download** on the disk in Disk/Media. No external compiler, Node scripts,
source repository or custom project-file editing is required.

Save your project after editing virtual sources or build settings. Reopening
that saved `.web64proj` is the reproducible development workflow.

## Editing

| Key | Action |
| --- | --- |
| F1 / F2 | Menu / help |
| F3 / F4 | Find / find next |
| F5 / F6 | Start or finish a logical selection / paste |
| F7 / F8 | Undo / save |
| Cursor keys | Move through wrapped text |
| RETURN / DEL | New paragraph / backspace |
| RUN/STOP | Cancel a dialog or clear selection |

The Edit menu includes copy, cut, redo, select all/word/paragraph, deletion and
insert/overwrite mode. The Document menu provides start/end, page movement,
word movement, paragraph navigation and statistics. The Format menu offers
bold, underline, emphasis, tabs, hard lines, page breaks and 20–40-column wrap.
Changing display wrapping does not insert line breaks into document content.

Selection uses a logical anchor and endpoint, so it can cross wrapped lines
and paragraphs. The clipboard holds **512 bytes**. An oversized copy/cut is
refused without deleting text. Undo retains **one eligible edit**, with a
512-byte payload; large edits proceed without whole-operation Undo. The status
bar always shows actual Undo availability. Replace All can undo only its last
eligible replacement, not the entire command.

Search terms and replacement text are limited to 32 bytes. Find supports next,
previous, wraparound, exact/ignored case and whole-word matching. Replace All
checks required capacity before changing text. Searches examine stored logical
bytes; an inline formatting token can interrupt an otherwise visible word.

## Documents and data disks

All New/Open/Save/Save As, directory, validation and recovery code is resident.
Saving does **not** load an application module.

- **One drive:** after startup, swap drive 8 to your data disk while the program
  is idle. Save/Open/Directory work without the application disk. Printing or
  search may request the application disk again; cancel leaves editing and
  saving available.
- **Two drives:** keep the application disk in drive 8 and choose data device 9
  in **File → Data device**. Enable/mount drive 9 in the emulator. The application
  module device remains 8, independently of the selected data device.

Web64 Disk/Media can download an empty D64 and mount imported data disks. After
saving documents, **Capture Drive 8/9** downloads the mounted disk with its C64
file changes. Downloading a newly mastered application disk is not a substitute
for capturing the data disk. Keep backups outside the browser.

Native documents are SEQ files with a 32-byte `M64D` version-1 header, bounded
payload length, CRC-16 and compact wrap/print settings. Text is PETSCII with
small inline style, tab, line, paragraph and page tokens. PETSCII SEQ import and
export provide plain-text interchange; this is not a UTF-8 editor.

Open validates a separate full candidate before replacing the active document.
A failed or oversized load preserves the current document. Save writes and
reads back a new temporary file before promotion; an existing document becomes
a separately named backup. DOS rename is not power-failure-atomic. If promotion
fails, the recovery screen identifies files to retain. Temporary/backup files
are deliberately not silently deleted; manage them after confirming a good copy.

Use normal **true-drive emulation** for this version. A separate KERNAL-trap
check rejected a completed read during channel cleanup, safely preserving the
old document. That accelerated disk mode is not a supported I/O claim here.

## Printing

The Print command loads the real `M64-PRINT` module and sends formatted PETSCII
to IEC printer device 4, secondary address 7. Use a compatible C64 printer or a
separately configured VICE printer backend. Web64 currently has no printer
configuration/capture UI; the browser's practical interchange route is PETSCII
SEQ export and data-disk capture. The module owns wrapping,
left margin, line spacing and page length. RUN/STOP cancels between lines.

This version has a **plain-text printer profile**: inline display styles are
flattened, not sent as arbitrary printer control bytes. Page breaks are emitted
as carriage-return rows, not unsupported form-feed commands. Printer failures
are reported without altering document content. There is no new browser print
dialog or managed page-capture UI; emulator output-driver configuration and
physical printer support remain separate concerns. Closing a channel does not
guarantee that an emulator graphics printer flushes a partial page.

## Memory and capacity

The original resident-size target was **18,432 bytes**. It was not achieved;
the user accepted the target miss to close this educational example. The final
resident, including its real module loader and BASIC boot line, is **23,007
bytes** — **4,575 bytes above that original target**. This is not an address-space
overlap: the workspaces were moved above the actual resident.

| Region | Purpose |
| --- | --- |
| `$0801–$61df` | Resident image; BASIC `SYS 2064`, generated C startup at `$0810` |
| `$6200–$62ff` | Private module services, typed context and loader state |
| `$6300–$64ff` | 512-byte recent-edit payload |
| `$6500–$66ff` | Reserved spare workspace |
| `$6700–$68ff` | 512-byte clipboard |
| `$6900–$69ff` | Resident file/header/DOS workspace |
| `$6a00–$6dff` | 1,024-byte C software stack |
| `$6e00–$6fff` | Viewport caches and rendering scratch |
| `$7000–$71ff` | Search terms and print scratch |
| `$7200–$aff9` | Active document: **15,866 bytes**, including formatting tokens |
| `$b000–$fff9` | Separate load candidate; cold modules temporarily use `$b000–$cfff` |
| `$fffa–$ffff` | Safe RAM vectors while ROM is hidden |

The document model and workspace arrangement remain fixed: no malloc, paging,
REU requirement or browser-side document engine. The loader invalidates cold
code before Open writes candidate memory. A module cannot load another module
or Open a document while executing from that region.

The 15,866-byte figure is the physical document limit, not a promise that all
operations are instant. Large reflows, searches and ordinary disk I/O can take
noticeable time: the focused near-capacity no-match search test measured about
23 seconds of PAL CPU time. Search is synchronous in this version. This closure
uses bounded sanity checks, not a new comprehensive
commercial-product or hardware-compatibility campaign. See `VERIFICATION.md`
for the measured working-size sample and the exact checks completed.

A 14 KiB document was opened, edited, saved, captured and reopened byte-for-byte
in the final true-drive check. Its immediate post-load typing assertion remains
unconfirmed and is explicitly recorded in `VERIFICATION.md` for manual review.

## Project structure

C owns the document model, commands, menus, viewport policy and safe file
transactions. Assembly handles measured document moves/scans, screen updates,
keyboard/banking, byte-stream codecs and bounded module loading. The code uses
the Web64 stack ABI, native assembler, charset pragmas and SDK disk/KERNAL APIs.

The three normal build targets are:

- **Margin64:** `main.c` plus the resident C/ASM units, origin `$0810`, producing
  `margin64.prg`. `boot.asm` contributes its normal BASIC SYS line at `$0801`.
- **Print:** `print.c` and `print-header.asm`, origin `$b010`, producing `print.prg`.
- **Search:** `search.c` and `search-header.asm`, origin `$b010`, producing `search.prg`.

Disk/Media places `MARGIN64` as runnable and `M64-PRINT`/`M64-SEARCH` as **Raw
data PRGs**, preserving their `$b000` module headers. The disk references the
actual target outputs, so Build Dependencies discovers the required builds.
Web64 also adds its standard `@W64-DISK-1` disk-identity marker when mastering.

The module headers and service table are ordinary project source. Each target
resolves its own labels; there are no hand-patched generated addresses. Module
origin, length, entry range, version, expected identity, complete EOF and I/O
status are checked. Modules are trusted application code, not signed plugins.

Remaining opportunities for size or speed improvements are future work. This
version deliberately does not add autosave, spell checking, multiple resident
documents, unlimited history or a new printing platform.
