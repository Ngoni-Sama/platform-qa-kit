# Sharing and publishing the report

Only do this when the user asks, and confirm each outward-facing step.

## Before anything leaves the machine
- Reports and videos usually show **real people's data** (staff emails, customer or candidate names). Tell the user which videos do; suggest private sharing.
- **Check a repo is private before pushing** that data: `GET https://api.github.com/repos/<owner>/<repo>` without auth returns **404** for a private repo, 200 for a public one. Check again after the push. If the user created it public, stop and ask them to switch it to private first.

## Git identity
- **Ask which identity to commit as** when the repo's owner isn't obvious. Work and personal accounts often differ; the global git identity may be a work email the user doesn't want on personal repos.
- For a personal GitHub account, a repo-local no-reply identity is safest: `git config user.name <login>` and `git config user.email <id>+<login>@users.noreply.github.com` (the id comes from `GET https://api.github.com/users/<login>`).
- Rewriting authors on already-pushed commits needs a force-push — ask first. A force-push doesn't delete files already uploaded to GitHub's Git LFS storage; only deleting the repo does.

## Repo layout
- `index.html`, `report.html`, `videos/*.mp4`, `videos/posters/*.jpg`, a `README.md` (top issues, how to view, confidentiality note).
- **Commit videos as normal files, not Git LFS** (see pitfalls.md).

## Hosting
- **Vercel (Hobby/free):** deployments are **public** to anyone with the link; password protection is a paid feature. A private repo only deploys when the **commit author is the Vercel account owner** — otherwise "Deployment Blocked … did not have contributing access". Fix the commit identity, not the plan. Make sure the folder's `index.html` (from the template) is committed, or the site root is a 404. Add a `vercel.json` `X-Robots-Tag: noindex` header plus `robots.txt` `Disallow: /`.
- **Private web hosting:** Cloudflare Pages + Cloudflare Access (free tier) can restrict the site to the company's email domain.
- **Simplest private option:** the private GitHub repo itself — collaborators clone it and open `report.html`.
