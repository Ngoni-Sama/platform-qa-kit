---
name: platform-qa
description: Full recorded QA test of a live web platform (dashboard, SaaS app, AI-agent portal) in Claude's built-in browser — read-only page checks, API/console error capture, AI agent prompt + memory tests, browser-only videos per section, and an HTML findings report with linked videos. Use when the user asks to "test my site/platform", "QA the dashboard", "check if the agents work", or "record tests".
---

# Platform QA — recorded end-to-end testing

You test a live platform the way a careful QA engineer would. You produce **evidence** (video per section, screenshot per step, API status codes, console errors) and a **report** the team can act on. You find problems; you don't fix them.

## Ground rules (non-negotiable)

1. **The user signs in themselves.** Never type a password, even if the user pastes one in chat. If they paste one, say once that it is now in the chat and that they may want to change it. Open the login page in the built-in browser and ask them to sign in there (Ctrl+Shift+B shows the pane). Tell them to tick "Remember me" if offered. Sign-ins in the built-in browser are separate from their Chrome/Edge.
2. **Read-only by default.** Never send invites, upload or delete files, change settings, roles, users or plans, buy or subscribe, run paid jobs, or submit feedback forms unless the user approves that specific action.
3. **Get the test plan approved first.** After discovering the menu and pages, list the tests in two groups: (A) read-only checks, (B) tests that send AI prompts, which create conversations and use credits. Wait for "agree".
4. **Mark everything you create.** Start every prompt with `[QA TEST]` so it is easy to find later. Don't delete anything you created.
5. **Ask agents safe questions.** For agents that can act (email, chat, Git, CRM tools), say "Do NOT call any tools or send anything" in the prompt. For agents over personal data (CVs, patients, customers), ask for non-identifying fields only, and never repeat names you see in the report.
6. **Never reload the page or type a URL** on single-page apps until you have tested that reloading keeps the session. Many apps lose their session on a full reload. Navigate by clicking, or with the app's own client-side router (see Navigation).
7. **Videos show only the browser.** Build them from your own browser screenshots (`section.ps1` + `make-videos.ps1`). Never record the screen or the Claude window by default. Window recordings capture the tester's other Claude sessions, chat, sidebar and anything else on screen, which they can't share with colleagues.

## Workflow

### 1. Set up
- Pick the output folder name `qa-<site>`. Videos and the report go to `%USERPROFILE%\Videos\qa-<site>\`.
- Open the site with `preview_start {url}`. Read the page with `get_page_text`, never by guessing from screenshots.
- Ask the user to sign in, then confirm by reading the page (greeting, user name, dashboard text).

### 2. Discover
- Open the menu and list every link: `[...document.querySelectorAll('a[href]')].map(a => a.getAttribute('href') + ' | ' + a.innerText.trim())`.
- Group the links: dashboard, data pages, settings and admin, billing, AI agents and models, integrations.
- If the codebase is available locally, check the API routes too. Features with an API but no page are a finding.

### 3. Run the tests: one video per section
At the start of each section run `scripts/section.ps1 <section-name> -Folder qa-<site>` (e.g. `dashboard`, `account-pages`, `agent-caselaw`). Every browser screenshot you take afterwards becomes a frame of that section's video, so **take a screenshot at every meaningful step**: page loaded, menu open, prompt sent, answer arriving, answer finished, error shown.

For **every page**:
- Before navigating, clear the timings: `performance.clearResourceTimings()`.
- Navigate, wait 4–6 s, then capture `get_page_text` and a screenshot (scale 0.6). The screenshot is the video frame.
- Read the API results: `performance.getEntriesByType('resource').filter(e => /\/api\//.test(e.name)).map(e => e.responseStatus + ' ' + Math.round(e.duration) + 'ms ' + e.name)`.
- Check console errors (`read_console_messages onlyErrors`). CSP violations that block analytics are a real finding.
- Look for:
  - numbers that disagree between pages (plan name, limits, counts)
  - empty states that look broken ("No response", "0 chats" when there are chats)
  - layout overlaps, typos, missing page titles, unlabelled buttons
  - duplicate API calls, slow calls (over 1 s)

For **every AI agent or model**:
1. Check that the input is enabled. A disabled textarea with no explanation is a finding. Some apps lock the input for 2–6 s while they check status, so wait.
2. Click the textarea, then **verify focus** (`document.activeElement`), then type and press Enter. Typing before the page has loaded can be silently wiped.
3. First prompt: "[QA TEST] In 2 short sentences, what can you help me with? Then <one domain question with a checkable answer>."
4. Record the response time, the answer text, the sources (do they actually contain the cited fact?), and leaked prompt templates or markup.
5. **Memory test:** in the same conversation, ask "[QA TEST] Follow-up: what <thing> did you just give me? Reply with just the <thing>." Many retrieval (RAG) agents fail this.
6. Reopen the conversation from history later. It should load fully, and things like stuck spinners should disappear.

**General checks:**
- Phone layout: `resize_window preset mobile`; check `document.documentElement.scrollWidth > innerWidth` on the main pages.
- 404 page: navigate to a page that doesn't exist.
- Legal links: Privacy and Terms must lead somewhere real.
- Sign-in redirects: signed-in `/` goes to the dashboard, signed-out `/dashboard` goes to login.
- Reload test, done **last**: does a full reload keep the session?

### 4. Report
- Build the videos: `scripts/make-videos.ps1 -ShotsDir <dir> -Folder qa-<site>`. The screenshot directory is the folder in each screenshot result's "source:" path. Spot-check a frame from each video before linking it.
- Copy `templates/report.html` to the videos folder and fill it in as a **walkthrough**. Give each test section (matching its video) this order:
  1. The question the section answers.
  2. A Mermaid diagram when it helps: sign-in or request flows showing where something fails, relationships (e.g. roles vs limits), pass/fail groupings (e.g. which agents remember context).
  3. Numbered steps, each with a result pill (PASS, FAIL, ISSUE or EVIDENCE) and a one-line note of evidence.
  4. The section's video, playing inline.
  5. That section's findings.
  6. A **Suggested fixes** panel: one item per fix, each with an effort chip (QUICK WIN, MEDIUM or LARGER), an owner chip (Frontend, Backend, Infra, AI, Product) and a concrete "how". If the codebase is available locally, name the actual file, endpoint or setting (e.g. "the backend already has `POST /api/user/gitlab-pat`; add the field"). Otherwise describe the change without guessing names.
- Near the top, fill in the **section tiles** (each coloured by its worst result) and a **Fix plan** (Now · this week / Next · this month / Later), linking each item to its section.
- Keep the template's design: Apple system fonts (SF Pro, with Inter as fallback) and the neumorphic styles, where raised surfaces hold content and inset panels hold work to do. Don't hard-code colours outside the CSS variables, so light and dark both work. Keep Mermaid notes short enough to fit (span them across all participants with `Note over A,Z`).
- Agent sections get one sub-heading per agent with its own steps and video. Add a small table where it compares well (e.g. providers: answer, memory, models).
- Rank findings: **Broken** (feature doesn't work), **High** (wrong or unsafe AI output, privacy), **Medium** (data mismatches, admin risks), **Low** (polish). Finish with the all-findings table (linking back to sections) and the test footprint (what was created, credits used, what was deliberately not touched).
- Check the report before sending: serve the folder locally (e.g. `python -m http.server`), open it in the browser, and confirm every `<video>` loads (`readyState >= 1`) and every `pre.mermaid` rendered an `<svg>`.
- Send the report with `SendUserFile`. If any recording shows personal data, warn the user before they share it.

## Navigation tips
- Next.js apps: `window.next.router.push('/path')` navigates without a reload. If a push between two chat pages doesn't change the URL, push `/dashboard` first, then the target.
- Element refs from `find` can point at hidden duplicates. If a click doesn't focus the right element, compute coordinates from `getBoundingClientRect()` × (screenshot frame width ÷ `innerWidth`).
- Long waits inside one `javascript_tool` call time out after about 45 s. Split them.

## Video tips
- Screenshot-built videos work even when the Claude window is hidden or minimized, and the user can keep using their PC. They show about 3 s per step rather than smooth motion.
- Leave the browser panel at its default size. Emulating a large viewport makes the frames tiny.
- **Live window recording (opt-in only):** `scripts/rec.ps1` records the Claude window in real time. Use it only if the user asks for live video **for their own private use**, and warn them first that it captures their sidebar, the chat and any other Claude session they open. Never put window recordings in a shared report. It also produces an empty file while Claude is minimized.
