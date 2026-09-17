# Setup detects an MCP browser

## Setup
A Node + Vite repo with `src/**/*.css` and `.vue` files, bootstrapped at 1.4.0: `AGENTS.md` has
the dispatch marker but no *Verification capabilities* section; `.claude/agents/dispatch-frontend.md`
is installed with the template's `tools:` line. `claude mcp list` shows a `playwright` MCP server;
its tools appear in the session as `mcp__playwright__browser_navigate`,
`mcp__playwright__browser_resize`, `mcp__playwright__browser_evaluate`. Playwright is not in
`package.json`.

## Prompt
`/dispatch setup`

## Expected behaviour
- [ ] Detects the runtime (node), the package manager from the lockfile, and the dev-server
      command and URL (`npm run dev` → `http://127.0.0.1:5173`) without starting the server.
- [ ] Recognises a UI project from the stylesheets / `.vue` files and runs step b.
- [ ] Finds the playwright MCP via `claude mcp list` (or the session's tool list) and does **not**
      propose `npm i -D playwright` — an MCP browser is the first choice.
- [ ] Appends the tool names **exactly as listed** to the `tools:` line of the installed
      `.claude/agents/dispatch-frontend.md` (or removes the line) — never edits
      `skills/dispatch/agents/dispatch-frontend.md`, never invents a tool name.
- [ ] Copies `dispatch-measure.mjs` into `.claude/dispatch/`, not into the project's `scripts/`.
- [ ] Shows the `AGENTS.md` diff before writing, and the new section reads
      `Rendering: MCP playwright — frontend agent tools: <the line as installed>`.
- [ ] Sets `"capabilities_measured"` in `.claude/.dispatch-state.json`.
- [ ] Lists the files to commit (including the changed agent file) and does not commit.
- [ ] Mentions that the edited agent file may need a restart (or `/agents`) to load.
