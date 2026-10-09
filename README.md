# Platform QA kit for Claude

Get Claude to test your web platform end to end: every page, every AI agent, recorded on video, with a findings report at the end. Claude only looks around. It won't change, send or delete anything unless you approve that specific action.

## What you need
- **The Claude desktop app** (Windows), using the **Code** tab. It has a built-in browser that Claude drives.
- **FFmpeg 8 or newer**, for the video recordings. In PowerShell:
  ```
  winget install Gyan.FFmpeg
  ```
  Then open a new terminal and check that window capture is available:
  ```
  ffmpeg -hide_banner -h filter=gfxcapture
  ```
  If it prints "Unknown filter", your FFmpeg is too old. Download the latest "full" build from https://www.gyan.dev/ffmpeg/builds/ and unzip it to `C:\Tools\ffmpeg`.

## Install (one time)
Copy the `platform-qa` folder into your Claude skills folder:
```
%USERPROFILE%\.claude\skills\platform-qa\
```
You should end up with `%USERPROFILE%\.claude\skills\platform-qa\SKILL.md`.

## Run a test
1. In the Claude desktop app's Code tab, start a new session and type:
   ```
   /platform-qa https://your-platform.example.com
   ```
   You can also just say "test and record my platform at …".
2. Claude opens your site in its built-in browser. **You sign in yourself** there (Ctrl+Shift+B shows the browser). Never give Claude your password, because it won't type it anyway. Tick "Remember me" if the site has it.
3. Claude lists every test it plans to run and waits for your OK. Tests that send prompts to AI agents use some credits and leave conversations marked `[QA TEST]`.
4. While it runs, you can use other apps on top of Claude. **Don't minimize the Claude window**, or the video goes blank. Claude can rebuild blank sections from screenshots, but live video is better.

## What you get
`Videos\qa-<site>\` contains:
- one MP4 per section (dashboard, account pages, each agent, and so on)
- `report.html`: findings ranked Broken / High / Medium / Low, an agent results table, what passed, links to every video, and exactly what the test created

## Good to know
- Sign-ins in Claude's browser are separate from your Chrome or Edge.
- Claude won't reload pages until it has tested that reloading keeps you signed in. Some apps sign you out on reload.
- Agents that can act (email, chat, Git) are told not to use any tools. Agents over personal data are asked for non-identifying fields only. Recordings can still show what's on screen, so check them before sharing outside your team.
- **Mac:** the testing and report work the same, but `rec.ps1` is Windows-only. Record the Claude window yourself with Cmd+Shift+5 → "Record Selected Window", or tell Claude to skip video and rely on screenshots.
