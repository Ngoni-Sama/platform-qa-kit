# Pitfalls — problems real runs hit, and what to do

## Signing in and sessions
- **Built-in browser sign-ins are separate** from the user's Chrome/Edge. "I'm signed in" usually means in their own browser — check the page, then ask them to sign in inside Claude's browser (Ctrl+Shift+B / ⌘⇧B shows it). With Claude in Chrome you share their real Chrome session instead.
- **SSO buttons pick the wrong account.** A "Microsoft"/"Google" button may sign in with a personal account and dead-end on a raw provider error (e.g. `AADSTS50020`). Ask the user to use email + password, or "Use another account". Report the dead end as a UX finding.
- **Sessions expire.** A session can die within an hour even with "Remember me". Before a second run, confirm the user is still signed in; if a protected page bounces to the landing page, stop and ask them to sign in again.
- **Never read tokens.** Don't fetch auth/token endpoints or replay requests with credentials to "check" a session — infer from page content and status codes. (Auto-mode will rightly block this.)

## Navigating single-page apps
- **A full reload or typed URL can drop the session.** Navigate by clicking, or with the app's router (Next.js: `window.next.router.push('/path')`). Test reload once, at the end.
- **Router pushes between two URLs of the same page** (e.g. `/chat?agent=1` → `/chat?agent=2`) sometimes don't take. Push a neutral page (`/dashboard`) first, and wait until `location.pathname + location.search` matches before continuing.
- **`find` refs can point at hidden duplicates**, so a click lands on the wrong element. Get coordinates from `getBoundingClientRect()` and scale by (screenshot frame width ÷ `innerWidth`), then confirm `document.activeElement` is what you meant.
- **`javascript_tool` calls time out after ~45 s** — split long waits/loops across calls.
- **Isolate API calls per page** with `performance.clearResourceTimings()` before navigating; the resource buffer only holds recent entries.

## Chat inputs and agents
- **Typing before the page settles gets wiped**, and many inputs are `disabled` for 2–6 s while an agent status check runs. Wait for `textarea.disabled === false`, click it, verify focus, type, check `textarea.value`, then Enter.
- **"Disabled with no LIVE badge for 20 s+"** = agent offline. Re-check a minute later and on a new conversation before reporting; agents can go offline mid-run.
- **Live view vs saved conversation:** source cards can appear late. Before claiming "citation not in sources", reopen the saved conversation and check all sources.
- **Intermittent UI glitches** (a stuck "Creating image" card, a spinner): reopen and retry once; report as intermittent if it doesn't recur.
- **Pages may write to the clipboard** on synthetic clicks — tell the user to check their clipboard before pasting.

## Screenshots, panes and playback
- **Screenshots can lag one step** behind navigation in the built-in browser; if a screenshot shows the previous page, take it again.
- **A hidden browser panel still works** for reading and screenshots, but Chrome won't play video in a hidden/background tab ("video-only background media was paused"). To test playback, ask the user to show the panel; otherwise verify by loading metadata and seeking.
- **Emulating a large viewport in a small panel** makes screenshots tiny. Leave the panel at its default size; use `resize_window` only for phone-width checks, then reset to `desktop`.

## Recording
- **Never record the screen, desktop or Claude window.** A window recording captured the user's sidebar, chat and a *different* Claude session — unshareable. Cropping doesn't fix it (the panel can show other sessions too). Use browser screenshots or `gif_creator` only.
- **Screenshot videos are slides** (≈3 s per step). Say so in the report so a still frame isn't mistaken for a freeze.

## Video files and hosting
- **Encode for the web:** faststart (`-movflags +faststart`), a keyframe every second, H.264 yuv420p — `make_videos.py` does this. Without it, players stall and seeking freezes.
- **"The report has no CSS / no videos"** usually means it was opened as a lone file (chat attachment, side-panel preview, email) without `videos/` beside it. Hand over `report-standalone.html` from `make_videos.py embed` instead; it carries its videos inside.
- **Click-to-play:** `preload="none"` + a poster, so 20+ videos don't all download at once.
- **No Git LFS for report videos.** Vercel and similar hosts serve the 130-byte LFS pointer instead of the file unless LFS is switched on in their settings; clones need `git lfs install`. Screenshot videos are small — commit them as normal files.
- **Mixed jpg/png frames** break ffmpeg's concat demuxer; `make_videos.py` normalises every frame first.

## Windows shell (PowerShell 5.1)
- **UTF-8 without BOM is read as ANSI**: scripts containing `→ … –` fail to parse, and `Get-Content -Raw` mangles UTF-8 files you then rewrite. Prefer Python for file edits; in PowerShell read with `[IO.File]::ReadAllText(path, [Text.Encoding]::UTF8)` and save `.ps1` files with a BOM.
- **Commit messages with quotes** in a PowerShell here-string break `git commit -m`. Write the message to a file and use `git commit -F msg.txt`.
- **Native commands writing to stderr** (git progress) show as red "errors" and exit codes like 255 even on success — check the actual result (`git log`, `git status -sb`, `git ls-remote`).

## Report content
- **Ground fixes in code when you can:** grep the backend for the endpoint/controller and quote the real cause (e.g. "the handler defaults the answer to 'No response' and still returns 201"). Say if the local branch might differ from production.
- **Re-check before asserting** a mismatch: several "data mismatches" turn out to be features (per-user limit overrides, users holding several roles) — then the finding becomes "the UI doesn't explain it".
- **Mermaid:** long `LR` flowcharts with 8+ nodes render too small — use section tiles instead. Keep sequence-diagram notes short and span them across all participants (`Note over A,Z:`) so text doesn't overflow.
