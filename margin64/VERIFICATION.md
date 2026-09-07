# Margin64 0.1 — verification and limitations

This is a bounded example-closure record, dated 2026-09-07. It does not claim a
new comprehensive product, hardware-compatibility or performance campaign.

## Native project and disk

The authoritative `margin64.web64proj` was saved by Web64 IDE's Save Project
action. A fresh IDE workspace reopened it and saved it again; all virtual
sources, compiler settings, target inputs and disk layout survived unchanged.
The reopened IDE built all three targets without diagnostics and downloaded
`dist/margin64.d64` through Disk/Media. Run Disk uses the ordinary named BASIC
LOAD/RUN path and reached the visible Margin64 editor in the browser, using
Warp to shorten disk waiting. There are no substitute function stubs in the
application.

| Native target | Resident/module bytes | Loaded addresses |
| --- | ---: | --- |
| Margin64 | 23,007 | `$0801–$61df` |
| Print | 3,932 | `$b000–$bf5b` |
| Search | 4,646 | `$b000–$c225` |

Sizes exclude each PRG's two-byte load address. Main includes the BASIC boot
line and resident cold-module support. The old 18,432-byte resident target is
missed by **4,575 bytes**. The earlier approximately 3.3 KiB estimate preceded
the completed module support; this final figure is not presented as meeting the
old target. There is no overlap with services/workspaces starting at `$6200` or
the 1,024-byte C software stack at `$6a00`.

The disk contains the boot application, the two real cold modules and Web64's
automatically generated disk-identity marker. Save, Open, directory, prompts and
recovery remain resident. No module is
required merely to save onto a different disk or device 9.

## Application checks

The full saved-project binary, byte-identical to the boot file extracted from
the IDE-generated D64, was exercised in VICE. Checks include:

- Normal disk boot and keyboard-matrix typing.
- Statistics loaded from the application disk and returned through the real
  resident service table.
- Print loaded from that disk, opened its settings menu and returned via Back.
  Both module calls preserved document and Undo bytes.
- Switching the data device to 9 while leaving the application disk in drive 8.
- Opening a 14,336-byte native document, with exact payload comparison.
- Inserting near its beginning, further typing, deletion and Undo, with exact
  document comparisons and visible wrapped output.
- Saving the edited 14,338-byte document, checking the complete captured native
  file and retaining the original as a separate backup.
- Reopening the saved document and comparing every logical byte successfully.

The final immediate post-load keystroke assertion **did not pass**. The probe
sent a four-frame key pulse while Open appeared still to be returning; the
document stayed unchanged and reported DOCUMENT OPENED, with no I/O error.
This does not establish whether input was simply premature or needs a fix.
Continued typing after that reload remains a manual-inspection follow-up.
The entire replay is therefore not reported as an all-green test suite.

Full read/write checks use **true-drive emulation**. A KERNAL-trap read check
failed during cleanup after receiving the correct payload; the old document
was preserved. That accelerated mode is a known limitation, not a successful
load/save compatibility claim.

The independently compiled modules also passed focused native-6502 checks:
30 printer cases, 22 search commands across 38 native calls, and 91 bounded
loader invocations. Those tests include controlled I/O failure boundaries;
they are not physical-printer or drive-timing measurements.

## Capacity and responsiveness

**15,866 bytes** is the hard active-document limit, including formatting tokens.
A full independent load candidate and fixed save/error workspace remain
reserved. Undo and clipboard are each capped at 512 bytes; there is no unlimited
history. One eligible edit can be undone. Large edits and Replace All do not
gain an artificial whole-command history guarantee.

A **14 KiB document** is the exercised working-size sample, not an exhaustive
maximum-capacity certification. The existing full-capacity component tests do
not substitute for a complete near-limit application workflow in this layout.

In the final warp-off editing sample, the first near-start insertion was
observed after 16 PAL frames (about 322 ms host time), with settled rendering by
19 frames. The following insertion was observed by the four-frame key-release
point (about 76 ms), settled by six frames. These include input-pulse and host
observation overhead; they are not best-case 6502 cycle timings.

Search is synchronous. One near-capacity no-match test took 22,769,632 CPU
cycles, approximately 23 seconds of PAL CPU time. Long scans and reflow can
therefore pause input; this version does not promise instant operations at the
physical limit. Disk speed depends on true-drive emulation and host speed.

## Output and remaining limits

Printing emits plain PETSCII to device 4/secondary 7; inline styles are flattened.
The module has layout and error tests, but Web64 has no printer setup/capture
UI. A compatible physical printer or separately configured VICE backend is
needed. PETSCII SEQ export plus Capture Drive is the browser interchange route.

No new autosave, spell checker, multi-document mode or browser-side document
engine was added for closure. Search terms are 32 bytes and formatting tokens
can interrupt a match. DOS file promotion is verified but not power-failure
atomic. Keep captured data disks and backups outside the browser.

Maintainer profiling scripts, test fixtures and screenshots are deliberately
outside this example. Users need only the native project, these accompanying
sources/guides and the disk artifact; no private build machinery is required.
