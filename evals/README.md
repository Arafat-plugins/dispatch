# Evals

Scenario files for the behaviours the skill must produce. Each has three sections — `## Setup`
(the repo state), `## Prompt` (what the user says), `## Expected behaviour` (what the main
session must do, as checkable lines). Run them by hand in Claude Code with the skill
installed, or through a harness:

- **`evals/evals.json`** is generated from these files by `node scripts/build-evals.mjs` in the
  skill-creator format (`prompt`, `setup`, `expectations` — one per checklist line), so the
  skill-creator eval loop can run each scenario with and without the skill and grade the
  transcript line by line. `validate.sh` fails when it is out of date.
- **`evals/triggers.json`** holds 20 should-trigger / should-not-trigger queries for the
  description, for skill-creator's description optimisation loop.

| File | Gap it guards |
| --- | --- |
| `new-file-acceptance.md` | created files are reviewed, not just `git diff` |
| `dirty-tree-before-dispatch.md` | baseline isolates the sub-agent's diff |
| `foreign-agents-md.md` | an `AGENTS.md` from another tool is not "bootstrapped" |
| `credential-grep.md` | locating DB config never prints values |
| `third-failure-escalation.md` | the loop stops after the rewritten brief fails |
| `typo-fix-uses-opus-5-5.md` | even light work is dispatched on Opus 5.5 — no cheaper model, set explicitly on the call |
| `brief-is-direct-steps.md` | the main session locates and plans; the brief is numbered direct steps; a fallback and a repo's own agent still get Opus 5.5 on the call |
| `agent-stops-at-wrong-step.md` | a sub-agent stops at a step it cannot do as written; the main session fixes the step — not a failure |
| `critic-only-on-security-surface.md` | the critic runs only when the diff touches a security surface; copy and markup skip it |
| `third-parallel-agent-asks-user.md` | a third concurrent sub-agent needs the user's yes first |
| `design-responsive-defaults-first.md` | responsive scope is settled with one defaults-first confirmation, never a batch of questions |
| `verbatim-text-kept-exact.md` | the user's request and product text reach the agent unedited and land byte for byte |
| `image-reference-compared.md` | an image to match is saved in the repo, briefed, and compared with `--compare` by agent and acceptance |
| `backend-flow-step-one-slice.md` | a flow step is one brief through every layer, with its contract, written as steps, and its flow test run once |
| `session-rotates-and-resumes.md` | rotation is suggested at ~10 dispatches, forced only after a compaction; `/dispatch resume` continues from files only |
| `small-task-fast-lane.md` | a small task: no questions, no scout, ≤ 6 steps, no full suite, no critic |
| `big-build-multi-session.md` | a spec-driven build: plan, roadmap and gates, migrator, reviewer, audit, rotation, and no deploys by the skill |
| `new-project-intake-one-question.md` | a heavy new project is scoped in at most three questions, defaults first, before anything is built |
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
| `polish-index-only-one-note.md` | before a brief only `grep` hits in `INDEX.md` for the briefed paths are read, and at most one full note, with the reason named |
