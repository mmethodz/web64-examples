# Web64 Examples Agent Instructions

These instructions apply to every example and application in this repository.

## Web64-native project authority

Never defer `.web64proj` creation to release packaging for a Web64-native example or application. Create it early, keep it authoritative, and periodically prove the full browser-native lifecycle during development.

- The saved project and its virtual filesystem are the source of truth for source code, native assets, build targets, memory/compiler settings and disk mastering. Loose exports are accompanying references, not a second development authority.
- Create and maintain the project through the IDE's own authoring workflow. Sources merely being importable, a hand-tailored project JSON, or an external harness build is not proof of a valid Web64-native project.
- During development, periodically reopen the saved project in a fresh browser workspace, edit, save, reopen, build and run through normal IDE controls; verify disk creation/Run Disk when applicable. Record unfinished or failing stages honestly instead of deferring this lifecycle until release or substituting test stubs.
- Maintainer tests may inspect and compile the saved project's VFS or use explicitly isolated test fixtures. They must not silently fall back to adjacent loose source files when the authoritative project is absent.
- Keep repository-only tooling and test evidence out of the distributable example. Users need only the native project, accompanying assets/documentation and release artifacts, not Web64's implementation repository or Node tooling.
