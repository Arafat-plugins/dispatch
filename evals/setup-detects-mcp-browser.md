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
      command and URL (`npm run dev` → `http://localhost:5173`, or the URL the server printed if
      the user pasted it) without starting the server.
- [ ] Recognises a UI project from the stylesheets / `.vue` files and runs step b.
- [ ] Finds the playwright MCP from the session's own tool list first, then confirms it in
      `claude mcp list`, and does **not** propose `npm i -D playwright` — an MCP browser is the
      first choice. A claude-in-chrome or Claude_Browser tool in the session list alone would be
      recorded `(main session only)` and not added to the agent.
- [ ] Before writing anything, asks once: append the tool names **exactly as listed** to the
      `tools:` line of the installed `.claude/agents/dispatch-frontend.md`, and copy the script.
      On the yes, appends them — never deletes the `tools:` line, never edits
      `skills/dispatch/agents/dispatch-frontend.md`, never invents a tool name.
- [ ] Copies `dispatch-measure.mjs` into `.claude/dispatch/`, not into the project's `scripts/`;
      an existing, different copy is shown as a diff before it is replaced.
- [ ] Shows the `AGENTS.md` diff before writing, and the new section reads
      `Rendering: MCP playwright — frontend agent tools: <the line as installed>`.
- [ ] Sets `"capabilities_measured"` in `.claude/.dispatch-state.json`.
- [ ] Lists the files to commit (including the changed agent file) and does not commit.
- [ ] Mentions that the edited agent file may need a restart (or `/agents`) to load.
