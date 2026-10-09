# Report guide

Start from `templates/report.html`. Keep its design: Apple system fonts (SF Pro on Apple devices, Inter as the fallback) and a neumorphic UI — **raised** surfaces hold content, **inset** panels hold work to do. Use only the CSS variables for colour so light and dark modes both work.

## Structure (top to bottom)
1. **Header:** platform, URL, date and time window, account and plan, "read-only plus `[QA TEST]` prompts", and that videos are browser-only slides (~3 s per step).
2. **Stats row:** broken / AI-quality / data mismatches / UX-polish counts, plus one headline ratio (e.g. "6 / 11 agents remember context").
3. **Section tiles:** one clickable tile per section, class `pass` / `warn` / `fail` by its worst result, with a 2–5 word status.
4. **Contents** list.
5. **Fix plan:** three inset columns — *Now · this week*, *Next · this month*, *Later* — each item linking to its section.
6. **One `<h2>` section per video section**, in this order:
   1. Goal: the question the section answers.
   2. Optional Mermaid diagram — only when it explains something: a request flow showing where it fails, a sign-in flow, how settings interact (roles vs limits), a pass/fail grouping.
   3. Numbered steps, each with a pill: `PASS`, `FAIL`, `ISSUE` or `EVIDENCE`, and a one-line note with the evidence (numbers, status codes, timings).
   4. The section's video: `<video controls preload="none" playsinline poster="videos/posters/NN-x.jpg" src="videos/NN-x.mp4">` (or `<img>` for a GIF).
   5. Findings (`.f crit|high|med|low|fix`).
   6. **Suggested fixes** panel: one item per fix with an effort chip (`quick` QUICK WIN, `mid` MEDIUM, `big` LARGER), an owner chip (Frontend, Backend, Infra, AI, Product, Legal) and a concrete "how". Name real files/endpoints/settings only if you saw them in the code.
   - Agent sections: one `<h3>` per agent with its own steps and video; providers/models can share a comparison table (answer, time, memory, models offered).
7. **All findings, ranked** table (Broken → High → Medium → Low) linking back to sections.
8. **Test footprint:** what was created (conversations, messages), credits used, what was deliberately not touched, and which videos show personal data.

## Severity
- **Broken** — a feature doesn't work or a legal/compliance gap (missing privacy policy).
- **High** — wrong, unsafe or privacy-leaking AI output; data exposure.
- **Medium** — data mismatches, risky admin actions, confusing settings.
- **Low** — polish, performance, accessibility, typos.
- **Corrected** (`fix`) — an earlier finding that turned out wrong; keep it visible and say why.

## Verify before sending
Serve the folder (`python -m http.server 8765` in the report folder) and open it in the browser:
- every `<video>` loads metadata (`readyState >= 1`, `duration > 0`) and every poster loads;
- every `pre.mermaid` contains an `<svg>` and no note text overflows its box;
- no horizontal scroll at 375 px; check light and dark (`resize_window colorScheme`).
Then send the file to the user and stop the server.
