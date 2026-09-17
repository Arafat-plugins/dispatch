# Changelog

## 1.5.0 — 2026-09-17

"Capabilities". 1.4.0 assumed tooling it never provisioned: a frontend agent that could not see,
no design source, no path for adding a dependency, and database guards that were described but
never set up. No renames; the footer line, the existing commands, the four agent names,
`effort: medium`, model-by-weight and the 2-concurrent cap are unchanged.

**Setup — capabilities are provisioned, not assumed**
- New mode `/dispatch setup` (new `references/setup.md`); bootstrap runs it as Step 2c. Each
  step is detect → propose → install → record; nothing installs without saying what and a yes,
  never globally, never outside the repo; a missing capability is recorded and said, never
  skipped quietly.
- Runtime and dev server detected and recorded. Browser: a configured MCP (playwright,
  puppeteer, chrome, claude-in-chrome, Claude_Browser) gets its exact tool names appended to the
  installed `dispatch-frontend`'s `tools:` line; else Playwright as a dev dependency with chromium
  kept in `.claude/dispatch/browsers/`; else `Rendering: none` and every width is *Not verified*.
- `AGENTS.md` gains a *Verification capabilities* section; the state file gains
  `capabilities_measured` (bootstrap.md).

**One measuring script**
- New `skills/dispatch/scripts/dispatch-measure.mjs`, copied to `.claude/dispatch/`:
  `<url> <width>... [--select <css> --prop <property>]` → one line per width, overflow and the
  computed value. Starts nothing; exit 2 `dev server not reachable at <url>`, exit 3 no renderer.
  Uses the repo's Node Playwright, else Python Playwright.
- The inline Playwright snippet is gone from acceptance.md; acceptance, responsive.md and the
  frontend template call the script.

**Design guidance**
- Setup step d generates `DESIGN.md` for UI projects — Tokens, Breakpoints, Components,
  References, Never — from the theme config, CSS custom properties and `@media` queries, plus at
  most three one-at-a-time questions; shown before writing. An optional frontend-design skill is
  offered only if the registry actually lists one, installed into the repo.
- `dispatch-frontend` reads `AGENTS.md`, then `DESIGN.md`, then the briefed files; what
  `DESIGN.md` defines cannot be overridden by a brief. prompt-spec.md cites `DESIGN.md`
  components in **Format**; responsive.md skips what it answers; acceptance.md gains a fifth
  check — a colour, spacing value or breakpoint not in `DESIGN.md` is a finding.

**Dependencies**
- New mode `/dispatch deps <add|remove|update> <package>` (new `references/dependencies.md`):
  ask first; a `sonnet` brief limited to manifest + lockfile, install clean, tests green, audit
  quoted in ≤ 10 lines; acceptance rejects any source file; then `/dispatch verify` asking only
  about provenance, advisories, pinning and lockfile integrity.
- failures.md routes "a dependency is needed" here; when-not-to-dispatch.md allows a one-line
  bump of a package already present; the implementer names package, constraint and reason when
  it stops.

**Database guards**
- Setup step e detects a read-only credential by key name only, or prints the engine's SQL to
  create one (Postgres, MySQL/MariaDB, MongoDB; SQLite uses `-readonly`) — the user runs it.
- "Prefer a read-only user" is now a hard rule: the db-tester refuses to proceed when the only
  credential it can find is the application's read-write user, and confirms its grants after
  connecting (db-check.md, dispatch-db-tester.md "Start here").

**Surfaces and status**
- bootstrap.md generates a *Surfaces* table (route → entry → view → styles) for Laravel,
  Next.js/Nuxt/SvelteKit, WordPress and plain PHP, capped at ~60 rows; LOCATE skips the grep
  when it names the files.
- `status` reports each capability ✅ / ⚠️ / ❌ with the one command that fixes it.

**Repo**
- `scripts/validate.sh`: measure script exists and passes `node --check` (skipped only without
  node); no inline `chromium.launch` in references or agents; setup.md and dependencies.md exist
  and are linked; links between references resolve; DESIGN.md wiring; the db refusal rule;
  the Surfaces recipes; version at least 1.5.0; the footer is the last line of every brief
  template and is paraphrased nowhere in the repo; SKILL.md stays under 250 lines.
- `README.md`: `setup` and `deps` in usage, the provisioned files, "Capabilities are
  provisioned, not assumed".
- `evals/`: scenarios for an MCP browser found by setup, no browser → *Not verified*, a deps
  brief limited to the lockfile, and the db-tester refusing read-write credentials.
- `examples/AGENTS.example.md`: a filled *Verification capabilities* section and a *Surfaces*
  table.

## 1.4.0 — 2026-09-16

**Sub-agent effort is medium**
- All four agent templates carry `effort: medium` in their frontmatter. Model sets how capable
  a sub-agent is; effort sets how long it thinks — a briefed job does not need more.
- The Agent tool has no per-call effort, so the frontmatter is the only place it is set.
  routing.md gains an *Effort* section: repo-owned agents without an `effort:` line inherit the
  session (suggest adding it), the general-purpose fallback inherits the session (noted in the
  plan), and only the user raises or lowers it — never the main session to rescue a failing
  brief (SKILL.md, routing.md, bootstrap.md, README).
- `scripts/validate.sh`: every agent template has `effort: medium`.
- `evals/`: scenario for effort staying medium.

## 1.3.0 — 2026-09-15

One gap: a new heavy project gets built from guesses instead of from the user's own answers. No
renames; the footer line, the commands, and the four agent names are unchanged.

**New heavy project intake**
- A heavy new project — built from scratch, an empty/near-empty repo, or a new large subsystem
  (multiple modules, many files, its own data model) — is gathered from the user *before* a
  brief is written. A light new thing (one script, one small file) skips intake or needs at
  most 1-2 questions.
- One question per message, `AskUserQuestion` with 2-4 concrete options, "you decide" allowed,
  never batched — same rule as responsive.md. Skips anything the user already said, stops as
  soon as planning is possible. Suggested order (new `references/new-project.md`): purpose and
  users, platform, stack, MVP scope, data/auth, look and feel (continues into responsive.md for
  UI), integrations, hosting, constraints, definition of done.
- Answers are confirmed back as a short brief and saved as `PROJECT_BRIEF.md` at the repo root
  before anything is scaffolded — the source for planning and every later dispatch brief.
- New mode `/dispatch new <idea>` runs the intake; a plain `/dispatch <task>` that matches the
  heavy-new-project signals runs it automatically (SKILL.md, "Starting something new?").
- Scaffolding runs at `opus` (routing.md, heavy/core work), then `/dispatch bootstrap` — which
  now checks for `PROJECT_BRIEF.md` on an empty repo and reads "What this project is" from it
  (bootstrap.md).

**Repo**
- `scripts/validate.sh`: `new-project.md` exists, is linked from SKILL.md, and mentions "one
  question".
- `README.md`: `/dispatch new` in usage, the intake rule in design notes, new-project.md in the
  layout tree.
- `evals/`: scenario for one-question-at-a-time new-project intake.

## 1.2.0 — 2026-09-15

Three protocol gaps: which model a dispatch runs at, how many sub-agents run at once, and
responsive scope on design work. No renames; the footer line, the commands, and the four agent
names are unchanged.

**Model by task weight**
- The main session sets the Agent tool's `model` explicitly on every dispatch — `sonnet` for
  light work (copy, docs, config, renames, mechanical edits, scouting, DB checks, the security
  critic), `opus` for design work or core-level implementation — and states the choice and a
  one-line reason in its plan (SKILL.md, routing.md's new "Model selection" table).
- `dispatch-implementer` and `dispatch-frontend` templates default to `model: opus`; the main
  session overrides down to `sonnet` for light tasks. `dispatch-db-tester` and
  `dispatch-security-critic` stay `model: sonnet`.

**At most 2 sub-agents at once**
- A hard cap of 2 concurrent sub-agents, counting every kind — workers, scouts, critic,
  db-tester. A plan needing more asks the user first, naming the job, the reason, and the cost;
  proceeds past 2 only on an explicit yes, for that plan (SKILL.md non-negotiables, routing.md's
  new "Concurrency cap" section with a worked ask message).

**Responsive is always in scope for design work**
- Any task that designs or changes UI always includes responsive behaviour in scope and in
  "Done means" — at minimum mobile ~375px, tablet ~768px, desktop ~1280px+, or the project's own
  breakpoints from `AGENTS.md`.
- Before briefing, the main session asks the user how it should look on smaller screens, one
  question per message, never batched, using `AskUserQuestion` — new `references/responsive.md`
  gives the question list, example options, and how answers become measurable "Target
  behaviour" per width (prompt-spec.md).
- Acceptance checks every named width itself, reusing the existing Playwright/overflow snippet,
  and reports "Not verified" per width it cannot render; the frontend template verifies every
  width in "Done means" and reports per width (acceptance.md, dispatch-frontend.md).

**Repo**
- `scripts/validate.sh`: implementer/frontend templates are `model: opus`; SKILL.md mentions
  the 2-concurrent cap; `responsive.md` exists and is linked from SKILL.md.
- `evals/`: scenarios for model-by-weight on trivial edits, the third-parallel-agent ask, and
  one-question-at-a-time responsive clarification.

## 1.1.0 — 2026-09-15

Closes the acceptance, safety, and portability gaps found in 1.0.0. No renames; the footer
line, the commands, and the four agent names are unchanged.

**Acceptance**
- Created files are reviewed: `git status --porcelain` + intent-to-add before `git diff` (acceptance.md, SKILL.md).
- Every dispatch starts from a recorded baseline — clean tree or a `write-tree` snapshot — and diffs against it; worktree isolation for parallel or risky dispatches (acceptance.md, routing.md).
- Large diffs are read `--stat` first, then per file; oversize is a finding. Sub-agent reports capped at 40 lines in every template and brief.
- The footer is explained as an instruction the sub-agent acts on: phases before editing, per-phase report, checked at acceptance; phases are *how*, the brief is *what*; read-only slices defined (SKILL.md, prompt-spec.md, agent templates).
- Loop termination: third failure stops and escalates; handling for errors, timeouts, questions, out-of-scope stops (new failures.md).
- When not to dispatch, and the narrow hand-fix exception (new when-not-to-dispatch.md).
- Frontend "verified" without rendering is reported as Not verified; the main session measures overflow itself with a headless Playwright one-liner when available.

**Safety**
- README no longer claims "no write tools". Critic and db-tester are read-only *by instruction*; the main session diffs `git status` before and after (README, verifier.md, templates).
- Real DB guards: read-only user, `SET SESSION TRANSACTION READ ONLY`, `sqlite3 -readonly`, `mysql --safe-updates`, Mongo read-only method list (db-check.md, dispatch-db-tester).
- Credential grep is `-l` only, never prints matching lines; credentials go via `--defaults-extra-file`, `PGPASSFILE`, env — never `-p<password>` on the command line.
- Security critic default model is `sonnet`; `haiku` noted as the cheap option for trivial diffs.

**Bootstrap and status**
- `<!-- dispatch:map v1 -->` / `<!-- /dispatch:map -->` markers; a foreign `AGENTS.md` gets a dispatch region appended after a shown diff, never overwritten.
- Bootstrap runs lint/test with a time budget and records a dated, commit-stamped baseline, or `not measured — <reason>`. Never an unmeasured "none".
- `/dispatch status` defined: map, agents, state version, layout drift, baseline age, CLAUDE.md link, tree cleanliness, one recommendation (new status.md).
- Skill-dir lookup with a `find` fallback; note on agents not hot-loaded mid-session and the general-purpose fallback.
- What to commit after bootstrap (`AGENTS.md`, `.claude/agents/dispatch-*.md`, state file — recommended) and why it must land before the first dispatch.
- State file gains `commit` and `baseline_measured`; version 1.1.0.

**Portability**
- db-check and db-tester cover MySQL/MariaDB, PostgreSQL, SQLite, MongoDB.
- `Explore` scout given a portable fallback; verify-chain scout clarified as the main session reusing the acceptance diff.
- Monorepo note: root `AGENTS.md` as index, per-package maps on request.
- Frontend template documents adding MCP browser tools to the installed copy's `tools:` line.

**Repo**
- `scripts/validate.sh`: frontmatter keys, reference links, agent frontmatter, verbatim footer in every brief template, version consistency.
- `evals/`: scenarios for new-file acceptance, dirty tree, foreign AGENTS.md, credential grep, third-failure escalation.

## 1.0.0 — 2026-09-09

- Initial release: the dispatch protocol (plan → locate → brief → work → accept → verify), bootstrap for `AGENTS.md`, four agent templates, database checks, worked example.
