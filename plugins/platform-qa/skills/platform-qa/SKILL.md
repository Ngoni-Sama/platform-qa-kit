---
name: platform-qa
description: Recorded end-to-end QA of a live web platform (dashboard, SaaS app, admin portal, AI-agent product) — read-only page checks, API and console error capture, AI agent answer + memory tests, browser-only videos per section, and a polished HTML walkthrough report with suggested fixes. Works with Claude's built-in browser (Claude Code desktop) or Claude in Chrome (Cowork, the Chrome extension, Claude Code --chrome). Use when asked to "test my site/platform", "QA the dashboard", "check if the agents work", "record tests" or "make a test report".
---

# Platform QA — recorded end-to-end testing

You test a live platform like a careful QA engineer and hand back **evidence** (a browser-only video per section, API status codes, console errors) and a **report** the team can act on: a step-by-step walkthrough with findings and concrete suggested fixes. You find problems; you don't fix the platform.

Before running, read **references/pitfalls.md** (problems real runs hit, and the fix for each). When writing the report read **references/report-guide.md**; before sharing or publishing anything read **references/publishing.md**.

## Ground rules (non-negotiable)

1. **The user signs in themselves.** Never type a password, even if the user pastes one in chat. If they do, say once that it's now in the chat and they may want to change it. Open the login page and ask them to sign in; tell them to use email + password (SSO buttons often pick the wrong personal account) and tick "Remember me".
2. **Read-only by default.** Never send invites or messages, upload or delete, change settings, roles, users or plans, buy or subscribe, run paid jobs or submit forms unless the user approves that specific action.
3. **Plan first.** After discovery, list the tests in two groups: (A) read-only checks, (B) tests that send prompts to AI agents (they create conversations and use credits). Wait for approval.
4. **Mark what you create.** Start every prompt with `[QA TEST]`. Don't delete anything you created.
5. **Safe agent prompts.** Agents that can act (email, chat, Git, CRM): add "Do NOT call any tools or send anything". Agents over personal data (CVs, patients, customers): ask for non-identifying fields only; never repeat personal names in the report.
6. **Videos show only the browser.** Build them from browser screenshots or the browser's own GIF recorder. Never record the screen, the desktop or the Claude window — that captures the user's other sessions, chat and apps.
7. **Don't reload or type URLs** on single-page apps until you've tested that a reload keeps the session (do that test last). Navigate by clicking or with the app's client-side router.
8. **Ask before anything outward-facing:** pushing to a repo, deploying, publishing, which git identity to commit as. Check a repo is private before pushing data that shows people (see publishing.md).

## Step 0 — Detect the environment

**Browser tools** (use whichever is present; the tool names after the prefix are the same — `navigate`, `get_page_text`, `read_page`, `find`, `computer`, `javascript_tool`, `read_console_messages`, `read_network_requests`, `resize_window`):
- `mcp__Claude_Browser__*` — the built-in browser in the Claude desktop app's Code tab. Separate sign-ins from the user's Chrome. Screenshots are saved as files (the result shows a `source:` path) → **screenshot videos**.
- `mcp__claude-in-chrome__*` — Claude in Chrome (Cowork, the extension, Claude Code with Chrome). Uses the user's real Chrome and its sign-ins; work in a new tab. Has `gif_creator` → **GIF videos**.
- Neither → ask the user to enable Claude in Chrome (or use the Claude desktop app's Code tab), and stop.

**Shell** (Bash/PowerShell/Python): needed for `scripts/make_videos.py` (Python 3 + ffmpeg, or `pip install imageio-ffmpeg`). No shell → skip video files, put key screenshots or GIFs straight into the report.

**Output folder:** `~/Videos/qa-<site>/` (Windows `%USERPROFILE%\Videos\qa-<site>\`), or the folder the user/Cowork workspace gives. Videos go in `videos/`, the report at the top.

## Step 1 — Set up and sign in
1. Open the site in a new tab. Read pages with `get_page_text`/`read_page`, not by guessing from screenshots.
2. Ask the user to sign in (built-in browser: they may need Ctrl+Shift+B / ⌘⇧B to show the panel). Confirm by reading the page (greeting, account name).
3. Note the account, plan and time — they go in the report header.

## Step 2 — Discover
- List every menu link: `[...document.querySelectorAll('a[href]')].map(a => a.getAttribute('href') + ' | ' + a.innerText.trim())`.
- Group: dashboard, data/content pages, settings & admin, billing, AI agents & models, integrations, legal.
- If the platform's code is available locally, grep its API routes too: features with an API but no page are a finding, and you can name real files in suggested fixes.

## Step 3 — Run the tests, one section at a time
For each section (dashboard, account pages, each agent, …):
- **Start the section's evidence.** Screenshot mode: remember which screenshots belong to it (for the manifest), or run `python scripts/make_videos.py mark --out <folder> <section>`. GIF mode: `gif_creator` start recording.
- **Every page:** `performance.clearResourceTimings()` → navigate → wait 4–6 s → `get_page_text` + screenshot (every screenshot is a video frame — take one at every meaningful step). Then read API results: `performance.getEntriesByType('resource').filter(e => /\/api\//.test(e.name)).map(e => e.responseStatus + ' ' + Math.round(e.duration) + 'ms ' + e.name)`, and console errors.
- **Look for:** numbers that disagree between pages; empty states that hide failures ("No response", "0 items" when there are items); broken links; layout overlaps; typos; missing titles/labels; duplicate or slow (> 1 s) API calls; admin actions that are dangerous (e.g. suspending yourself).

**Every AI agent or model:**
1. Is the input enabled? Many apps lock it for a few seconds while a status check runs — wait. Locked for 20 s+ with no message = agent offline (finding).
2. Click the textarea, **verify focus and the typed value** before Enter (typing before the page settles gets wiped).
3. First prompt: `[QA TEST] In 2 short sentences, what can you help me with? Then <one domain question with a checkable answer>.` Record time to answer, the answer, the sources (do they contain the cited fact?), leaked prompt templates/markup.
4. **Memory test** in the same conversation: `[QA TEST] Follow-up: what <thing> did you just give me? Reply with just the <thing>.` Retrieval (RAG) agents often fail this.
5. Reopen the conversation from history later: it should load fully; re-check anything odd (live views sometimes show fewer sources than the saved conversation).

**General checks:** phone width (`resize_window` mobile; `document.documentElement.scrollWidth > innerWidth`), a 404 page, Privacy/Terms links, sign-in redirects (signed-in `/` → app, signed-out app → login), CSP errors that block analytics, and **last** a full reload to test the session survives.

## Step 4 — Videos
- Screenshot mode: write `manifest.json` (`{"sections":[{"id":"dashboard","shots":["<path>", ...]}, ...]}`) from the screenshot paths you saw, then `python scripts/make_videos.py build --out <folder> --manifest <folder>/manifest.json`. (Marker mode: `build --out <folder> --shots-dir <screenshot folder>`; add a final `mark end` so the last section doesn't swallow later screenshots.)
- GIF mode: export each section's GIF and list it as `{"id":"…","gif":"<path>"}` in the manifest; or embed the GIF directly in the report as `<img>` if there's no shell.
- Output is web-ready (faststart, keyframe every second) with a poster per video. Spot-check one frame per video before linking it.

## Step 5 — Report
Copy `templates/report.html` next to `videos/` and fill it in following **references/report-guide.md**: section tiles + Fix plan at the top, then per section *goal → diagram (optional) → steps with PASS/FAIL/ISSUE → inline click-to-play video → findings → Suggested fixes*, then all findings ranked and the test footprint. Verify it renders (serve the folder, check every video loads and every diagram drew), then send it to the user and say which videos show personal data.

## Step 6 — Share (only when asked)
Follow **references/publishing.md**: check repo visibility first, ask which git identity to use, commit videos as normal files (not Git LFS), add an `index.html`, keep sites `noindex`, and remember free hosting is public.
