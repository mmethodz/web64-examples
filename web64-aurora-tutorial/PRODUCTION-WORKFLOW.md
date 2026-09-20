# Reusable Web64 tutorial production workflow

## Production gates
1. Choose one coherent native project, not an unrelated montage. Build a reference demo through the public IDE. Save a .web64proj early. Treat its virtual filesystem as authoritative.
2. Rehearse every visible action in the deployed IDE. Record exact labels and actual compiler/runtime behavior. Do not write narration that promises unverified behavior.
3. Before the final take, reopen the saved project in a fresh browser workspace, edit, save, reopen, build and run. Independently compile the saved VFS and verify animation and text behavior. Stop the final take if either gate fails.
4. Record clean chapter takes using the same verified workflow. Never include failed rehearsal actions as successful operations.
5. Inspect the final encoded video, subtitle timing and audio, then repeat native project build/run.

## Privacy and browser setup
Use a dedicated browser window with only the tutorial tab. Use the official Web64 IDE URL. The ChatGPT extension provides browser control; native Windows browser inspection failed URL validation in this environment. Native JavaScript prompts may need a human handoff because dialog handling stalled the extension. File imports require the extension permission described at https://developers.openai.com/codex/app/chrome-extension#upload-files . Do not change browser security settings automatically.

Record only the named window with Windows Graphics Capture. Never capture the whole desktop. Set secondary_window=False. The first framing check was 1920 by 1032 pixels. Crop the top 144 pixels BEFORE writing footage to exclude tabs, address bar and the debugging banner. Recheck this exact crop if window geometry or banners change. Do not include native file dialogs, desktop notifications, unrelated apps or profile information.

## Tools
Python 3.14; local packages in ../tools/python. Windows-Capture 2.0.1 uses Windows Graphics Capture. imageio-ffmpeg 0.6.0 supplies FFmpeg 7.1. Kokoro-ONNX 0.4.7 + Kokoro-82M v1.0 generates local English narration; voice af_heart. Pillow draws title cards. Keep package versions, model sources and licenses with production notes.

## Capture
Run capture.py CHAPTER --seconds DURATION --crop-top 144. It targets only Web64 IDE - Google Chrome, includes the cursor, receives updated window frames and writes a constant 30 fps stream. Static frames are naturally held; active frames retain real-time pacing. Encoding: H.264 libx264, veryfast, CRF 18, yuv420p, faststart. A geometry change aborts recording. Logs and raw chapter MP4s live under raw/. Inspect qa/capture-framing.png before approving the crop.

The older FFmpeg gdigrab window path produced black footage with this accelerated Chrome window; use Windows Graphics Capture instead.

## Teaching and pacing
Explain the purpose before each change. Introduce one concept at a time. Give viewers time to read code and build results. Imported teaching source and assets must be openly identified as supplied files; do not pretend they were typed live. Type small illustrative edits at a comfortable rate, allow a pause before and after, and show their consequences in the running result. Show source and generated bindings distinctly. Use native project/asset/build/emulator terminology. Cut compilation waits and mistakes normally; never accelerate editing into an AI speed-coding sequence.

## Narration and captions
Write chapter narration only after rehearsal. Generate paragraph WAV files locally, preserve the exact script and voice/speed settings, and listen to representative pronunciation samples. Say Web sixty four, C sixty four, character set and sixty-five-oh-two naturally. Use measured generated audio lengths to construct the edit timeline; leave short breathing gaps. Target roughly fourteen minutes. Retain a full WAV and timed SRT subtitles. Normalize spoken audio with a two-pass loudness process and check true peak.

## Intro and outro
Start on black with the genuine Web64 logo. Use the original synthesized three-note chime, not an unlicensed stock effect. Keep the intro brief and fade into real editor footage. End on black with Web64 IDE and Copyright © 2026 Siteledger Solutions Oy. No music bed is necessary. See AUDIO-SOURCES.md.

## Edit and render
Build a 1920 by 1080, 30 fps timeline. Keep the recorded 1920 by 888 page at native scale in a restrained matte with space for a chapter label and captions. Apply small, deliberate zooms only where needed for code readability. Use real captured frames only for IDE interaction; do not recreate the IDE. Keep an edit decision list with source clip, in/out time, chapter duration and narration file. Render H.264 high profile, yuv420p, AAC stereo, faststart; also preserve lossless narration and source footage.

## Delivery and revision
Deliver the inspected MP4, .web64proj, PRG, supplied teaching assets/source references, narration WAV, SRT, script, timeline and production guide. Keep maintainer tools, browser profile data and QA logs separate from the distributable native example. Do not redistribute browser profiles or unrelated local data. A later topic, such as sprite multiplexing, reuses the production pipeline but must repeat the full native lifecycle and rehearsal gates for its own project.

## Recorded production and verification

The final take was captured on 20 September 2026 from the official remote IDE in a dedicated Chrome window. The native project was created with New → C project, saved early, populated through native import and Code editing, saved, reopened in a fresh workspace, built and run. The final message edit was typed at approximately 170 ms per character. Supplied teaching source was introduced explicitly as supplied material.

The final project has five files, one native charset, a target named Aurora, main.c as root and $4000 as origin. The independently compiled saved project produces a 6,937-byte PRG. VICE verification checks all 2,048 charset bytes, VIC memory selection, the fixed title, plasma glyph range, changing plasma and text states, and message wrap. Exact hashes and observations are in qa/verification.json. The delivered project must match that verified hash.

The finished timeline is 840 seconds, 25,200 frames, 1920 × 1080 at 30 fps. Inspect qa/video-verification.json for the final encoded file's hash, full decode result and measured loudness. Inspect the sampled final frames and contact sheet, not just the renderer's exit code. A first encode was reviewed and the project chapter's overly tight crop was removed because it hid the Save toolbar.

## Reproducible sequence

Run these commands from the production directory after capturing and reviewing the chapter takes:

```powershell
python narrate.py
python prepare-edit.py
python render.py
python finish-metadata.py
python inspect-video.py
```

For a single capture, use `python capture.py chapter-name --seconds 120 --crop-top 144`. Capture longer than the narration and remove thinking time and long waits with cuts. The script does not control the UI; the browser session must be operated separately through observed native IDE controls. The extension cannot operate Chrome's native project Open/Save pickers in this setup. A human selected those files; those dialogs were excluded from the film. Once a Save handle existed, subsequent saves were performed through the IDE.

`narration.json` is the narration authority. `narrate.py` uses af_heart, speed 0.86, en-us, 24 kHz source audio. Sentences are cached with text hashes, so changed text receives fresh audio. Exact sentence durations and chapter padding produce timeline.json and captions.srt. `prepare-edit.py` refreshes the script and ASS captions, and rejects missing clips or chapter-duration mismatches. The subtitle font is Segoe UI, 28, in the bottom margin. Long sentences are divided into cues; timing within a sentence is proportional to word count.

`edit-decisions.json` is the editable cut list: file, source in-point and duration for each chapter. All final IDE shots use the actual 1920 × 888 capture at native scale, padded at y=96 on a 1080p canvas. Emulator pixels are never enlarged. Chapter headings occupy the upper margin; captions occupy the lower margin. The recap reuses a short charset shot as a recap illustration. No IDE screens were recreated or generated.

`render.py` renders chapters with H.264 CRF 18 and four encoder threads, joins the picture master, normalizes narration toward -16 LUFS/-1.5 dBTP, mixes the original chime at the intro, and produces H.264/AAC stereo with faststart. It caches completed chapter renders: move the affected render/CHAPTER.mp4 aside after changing that chapter's edit decisions. Delete no raw takes. The final audio uses 48 kHz; the original narration remains available at 24 kHz. `finish-metadata.py` adds navigable MP4 chapters and writes CHAPTERS.txt by a lossless remux. Inspect the file after that final remux.

The intro is six seconds, with a short fade in and fade out. The outro is nine seconds with the exact requested copyright. `make-cards.py`, the retained Web64 logo, intro/outro PNGs and `make-chime.py` preserve their editable sources. See AUDIO-SOURCES.md and licenses/ for provenance.

`check-speech.py` independently transcribes the full narration locally with faster-whisper 1.2.1/tiny.en and records segment confidence. This production recovered all tutorial sections with no segment below average log probability -0.6. ASR is an intelligibility and omission check, not a substitute for a human voice-performance review. The original waveform has only two samples at full scale out of 20,160,000; final encoded audio is checked separately for true peak.

Maintainer verification uses `node verify-native.mjs REPOSITORY SAVED.web64proj`. It reads only the saved native VFS and never falls back to teaching files. Keep this tool and QA evidence in the production archive, outside the distributable example. The learner requires only the IDE and native project.

## Reusing this workflow for another topic

Create a new production directory and a new native project. Reuse capture.py, narrate.py, prepare-edit.py, render.py, inspect-video.py, title treatment and audio provenance procedure. Replace the tutorial source, assets, script, chapter lengths and topic-specific verification. Rehearse the actual deployment again: do not assume that sprite, raster, disk or runtime workflows behave like this charset example. Save and reopen the new native project before recording, and repeat its independent executable checks. Preserve the browser privacy boundary and 1x emulator requirement unless the next user asks for another presentation.

## Rehearsal findings for this deployment
- New C project resets emulator scale to Fit and leaves an existing emulator running. Power it off and restore 1x before the next usable shot. Cut that transition.
- Output file and Origin normalize on every edit. Paste a complete valid value; character-by-character entry corrupts the output suffix and rejects partial addresses. Human pacing does not require typing a pasted value one character at a time.
- The function navigation dropdown may locate a call instead of its definition. Use Find with the full function declaration when teaching a definition.
- Importing a .chr file automatically opens Char Editor and generates its .inc. The filename extension is significant.

- Before Build Target, select the project main.c after inspecting read-only SDK files. In this deployment, building while an SDK include was selected produced a stale 24-byte artifact report. Returning to main.c produced a Ready PRG at $4000. Also record that the explicit target artifact (7170 bytes) and live compiler result (6937 bytes) differ; do not claim byte identity between those paths. Both must be verified if distributing both.
