# UI brief has a Page URL line

## Setup
A bootstrapped Vite repo. *Verification capabilities* records
`Dev server: npm run dev → http://localhost:5173` and `Rendering: local Playwright`. The dev
server is running. The dashboard lives at `/dashboard`; its stat cards overflow at 375px.

## Prompt
`/dispatch make the dashboard stat cards stack on mobile`

## Expected behaviour
- [ ] After the responsive questions, the brief's **Inputs** carries
      `Page URL(s): http://localhost:5173/dashboard` — the recorded base plus the page's path —
      and ends with the verbatim footer.
- [ ] The frontend agent runs `node .claude/dispatch/dispatch-measure.mjs http://localhost:5173/dashboard 375 768 1280`
      (the URL taken from that line, not guessed) and quotes the `renderer:` line as the tool it
      rendered with.
- [ ] At acceptance the main session measures the same URL from the brief — never an undefined
      `$URL`, never the bare base URL.
- [ ] If the script exits 2 with `redirected to http://localhost:5173/login`, every width is
      reported *Not verified* with that reason; the login page is not measured and not accepted
      as the dashboard.
- [ ] A UI brief drafted without a Page URL(s) line is completed before dispatch; a frontend
      agent given one without it stops and asks instead of guessing a path.
