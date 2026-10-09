# Platform QA kit for Claude

Have Claude test a live web platform end to end and hand you a **walkthrough report**: every page and AI agent checked, a short video per section, ranked findings and concrete **suggested fixes**.

- **Read-only.** Claude looks around and won't change, send, buy or delete anything unless you approve that exact action. Test prompts to AI agents are marked `[QA TEST]`.
- **You sign in yourself.** Claude never types your password.
- **Videos show only the browser.** They're built from screenshots (or GIF recordings) of the browser tab, so your other apps, chats and Claude sessions never appear in them.

## What you get
`Videos/qa-<site>/` (or your Cowork folder) containing:
- `report.html`: a clean Apple-font, neumorphic report (light and dark) with section tiles, a Now / Next / Later fix plan, and per section the steps with PASS / FAIL, the click-to-play video, the findings, a **Suggested fixes** panel (effort, owner, how) and diagrams where useful.
- `videos/`: one web-ready MP4 per section plus poster images.

## Install — pick one

### 1. Claude app: chat, Cowork, and Claude Code (signed in)
1. Download **[`dist/platform-qa.zip`](dist/platform-qa.zip)** from this repo.
2. In the Claude app, go to **Settings → Capabilities** and turn on **Code execution and file creation**.
3. Go to **Customize → Skills**, click **+ → Create skill → Upload a skill**, and choose the ZIP.

The skill then shows up in chat and Cowork; type `/` to pick it. Claude Code also loads it automatically when you're signed in with the same Claude account (Claude Code v2.1.273 or newer; check with `/skills`).
On Team or Enterprise, an owner may need to allow user-created skills.

### 2. Claude Code plugin
In Claude Code:
```
/plugin marketplace add Ngoni-Sama/platform-qa-kit
/plugin install platform-qa@platform-qa-kit
```
Update later with `/plugin marketplace update platform-qa-kit`.

### 3. Manual copy (Claude Code)
```
git clone https://github.com/Ngoni-Sama/platform-qa-kit.git
```
Copy `plugins/platform-qa/skills/platform-qa` to `~/.claude/skills/platform-qa` (Windows: `%USERPROFILE%\.claude\skills\platform-qa`).

## Which browser it uses
| Where you run it | Browser Claude drives | Videos |
|---|---|---|
| **Claude desktop app → Code tab** | The built-in browser panel (separate sign-ins; show it with Ctrl+Shift+B / ⌘⇧B) | MP4s from screenshots |
| **Cowork**, **Claude in Chrome**, Claude Code with Chrome | Your real Chrome via the Claude in Chrome extension (uses your Chrome sign-ins; works in a new tab) | GIF recordings, converted to MP4 when Python is available |

If neither browser is available, Claude asks you to enable Claude in Chrome.

## Requirements for videos
- **Python 3** and **ffmpeg**: `winget install Gyan.FFmpeg` (Windows), `brew install ffmpeg` (Mac), `apt install ffmpeg` (Linux), or just `pip install imageio-ffmpeg`.
- Without a shell (for example the Chrome extension on its own), Claude puts screenshots or GIFs straight into the report instead.

## Run a test
1. Type `/platform-qa https://your-platform.example.com`, or just ask: "test and record my platform at …".
2. Sign in when Claude asks, using email and password (SSO buttons often pick the wrong account), and tick **Remember me**.
3. Approve the test plan. Claude lists read-only checks separately from tests that send prompts to AI agents, since those use credits.
4. Let it run. You can keep using your computer.

## Sharing results
Reports usually show real people's data (staff emails, customer names), so keep them private. The skill checks a GitHub repo is private before pushing, asks which git identity to use, and warns that free web hosting such as Vercel is public. See [`references/publishing.md`](plugins/platform-qa/skills/platform-qa/references/publishing.md).

## For maintainers
- Skill source: `plugins/platform-qa/skills/platform-qa/`. Read `SKILL.md` first; `references/pitfalls.md` lists every problem real runs hit and its fix.
- After editing, rebuild the upload ZIP with `python build_zip.py` and commit `dist/platform-qa.zip`.
- Check the manifests with `claude plugin validate .` (repo root) and `claude plugin validate plugins/platform-qa`.
