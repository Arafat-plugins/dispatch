# Evals

Scenario files for the behaviours the skill must produce. Each has three sections — `## Setup`
(the repo state), `## Prompt` (what the user says), `## Expected behaviour` (what the main
session must do, as checkable lines). Run them by hand in Claude Code with the skill
installed, or feed them to a skill-eval harness; `scripts/validate.sh` only checks that each
file has the three sections.

| File | Gap it guards |
| --- | --- |
| `new-file-acceptance.md` | created files are reviewed, not just `git diff` |
| `dirty-tree-before-dispatch.md` | baseline isolates the sub-agent's diff |
| `foreign-agents-md.md` | an `AGENTS.md` from another tool is not "bootstrapped" |
| `credential-grep.md` | locating DB config never prints values |
| `third-failure-escalation.md` | the loop stops after the rewritten brief fails |
| `typo-fix-uses-sonnet.md` | light work is dispatched at `sonnet`, not `opus` |
| `third-parallel-agent-asks-user.md` | a third concurrent sub-agent needs the user's yes first |
| `design-asks-responsive-one-question.md` | responsive scope is clarified one question at a time, not batched |
| `new-project-intake-one-question.md` | a heavy new project is scoped one question at a time before anything is built |
| `effort-stays-high.md` | sub-agents run at `effort: high`; the main session never changes it on its own |
| `setup-detects-mcp-browser.md` | setup uses a configured browser MCP and wires its exact tool names into the installed frontend agent |
| `setup-no-browser-reports-not-verified.md` | no browser → recorded and said, never silent; every width is *Not verified* |
| `deps-brief-lockfile-only.md` | a dependency is its own dispatch: manifest + lockfile only, then a narrow critic pass |
| `db-tester-refuses-rw-credentials.md` | the db-tester will not run on the application's read-write credential |
| `critic-waits-for-idle-tree.md` | the critic (and db-tester) never runs beside a worker editing the same tree |
| `css-px-not-rejected-without-design-md.md` | routine px/rem values are not findings; without `DESIGN.md` the design check is waived |
| `ui-brief-has-page-url.md` | every UI brief names the page URL the agent and acceptance measure |
| `base-sha-is-printed.md` | BASE and AFTER are printed and pasted, work in a linked worktree and with non-ASCII names, and never touch the index |
| `polish-is-handed-off-not-dispatched.md` | polish is written up as a request for a second session, never done in the main session or given to a sub-agent |
| `polish-index-only-one-note.md` | only `INDEX.md` is read before planning, and at most one full note, with the reason named |
