# Platform QA kit for Claude

Get Claude to test your web platform end to end: every page, every AI agent, with a video per section and a findings report at the end. Claude only looks around. It won't change, send or delete anything unless you approve that specific action.

**Videos show only the browser.** They're built from screenshots of Claude's browser tab, so your other apps, your other Claude sessions and the chat never appear in them. You can keep using your PC, or minimize Claude, while it runs.

## What you need
- **The Claude desktop app** (Windows), using the **Code** tab. It has a built-in browser that Claude drives.
- **FFmpeg**, to turn the screenshots into videos. In PowerShell:
  ```
  winget install Gyan.FFmpeg
  ```
  Open a new terminal afterwards so `ffmpeg` is on your PATH. Or download a build from https://www.gyan.dev/ffmpeg/builds/ and unzip it to `C:\Tools\ffmpeg`.

## Install (one time)
In PowerShell:
```
git clone https://github.com/Ngoni-Sama/platform-qa-kit.git "$env:TEMP\platform-qa-kit"
Copy-Item "$env:TEMP\platform-qa-kit\platform-qa" "$env:USERPROFILE\.claude\skills\platform-qa" -Recurse
```
Or download the repo as a ZIP from GitHub and copy its `platform-qa` folder into `%USERPROFILE%\.claude\skills\`.
You should end up with `%USERPROFILE%\.claude\skills\platform-qa\SKILL.md`. Restart the Claude app (or start a new session) so it picks up the skill.

To update later, run `git -C "$env:TEMP\platform-qa-kit" pull` and copy the folder again (replace the old one).

## Run a test
1. In the Claude desktop app's Code tab, start a new session and type:
   ```
   /platform-qa https://your-platform.example.com
   ```
   You can also just say "test and record my platform at …".
2. Claude opens your site in its built-in browser. **You sign in yourself** there (Ctrl+Shift+B shows the browser). Never give Claude your password, because it won't type it anyway. Tick "Remember me" if the site has it.
3. Claude lists every test it plans to run and waits for your OK. Tests that send prompts to AI agents use some credits and leave conversations marked `[QA TEST]`.
4. Let it run. You can use other apps meanwhile.

## What you get
`Videos\qa-<site>\` contains:
- one MP4 per section (dashboard, account pages, each agent, and so on), showing the browser step by step, about 3 seconds per step
- `report.html`: findings ranked Broken / High / Medium / Low, an agent results table, what passed, links to every video, and exactly what the test created

## Good to know
- Sign-ins in Claude's browser are separate from your Chrome or Edge.
- Claude won't reload pages until it has tested that reloading keeps you signed in. Some apps sign you out on reload.
- Agents that can act (email, chat, Git) are told not to use any tools. Agents over personal data are asked for non-identifying fields only. The videos still show whatever your platform displays, so check them before sharing outside your team.
- **Live video (optional, private use only):** `scripts/rec.ps1` can film the Claude window in real time, but it captures everything in that window: sidebar, chat and other sessions. Claude only uses it if you ask, and never for the shared report.
- **Mac:** testing, screenshot videos and the report work the same if PowerShell (`pwsh`) and FFmpeg are installed. `rec.ps1` is Windows-only.
