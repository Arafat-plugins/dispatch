# Setup without a browser reports Not verified

## Setup
A bootstrapped Laravel + Inertia repo (`artisan`, `resources/js/Pages/*.vue`,
`resources/css/app.css`). No browser MCP is configured; Playwright is in neither `package.json`
nor any virtualenv. When setup proposes `npm i -D playwright`, the user answers "no".

## Prompt
`/dispatch setup`, then later `/dispatch status`, then
`/dispatch make the dashboard stat cards stack on mobile`

## Expected behaviour
- [ ] Setup proposes the install with specifics — `npm i -D playwright`, chromium into
      `.claude/dispatch/browsers/` via `PLAYWRIGHT_BROWSERS_PATH`, dev-only, lockfile and
      `.gitignore` changes — as **one** question, and installs nothing on "no".
- [ ] Never proposes a global install (`npm -g`, `npx playwright install` into the home cache
      without `PLAYWRIGHT_BROWSERS_PATH`, `install-deps`, `sudo`).
- [ ] Records `Rendering: none — every width is reported Not verified` in *Verification
      capabilities* and **says so to the user** — it does not fall through silently.
- [ ] `status` shows Rendering as ⚠️ with the sentence "UI briefs will be accepted as *Not
      verified* for every width until this is set up." and `/dispatch setup` as the fix.
- [ ] The UI task still dispatches (after the responsive questions); the brief's "Done means"
      lists widths.
- [ ] At acceptance the main session does not retype a Playwright snippet and does not claim a
      measurement: the report has `Not verified: rendering (no browser available)` for each
      width.
- [ ] If the frontend agent's report says "verified at 375px" without naming a tool, it is
      treated as read, not rendered.
