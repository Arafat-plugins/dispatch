# dispatch

A Claude Code / agent skill that keeps the **main session's context clean** by delegating
implementation work to sub-agents — with a written spec, exact file paths, and an acceptance
check the main session performs itself.

```bash
npx skills add Arafat-plugins/dispatch
```

## The problem

Two things go wrong when you hand work to sub-agents:

1. **The sub-agent surveys the whole codebase** before doing anything, because nobody told it
   where to look. Slow, expensive, and it still guesses.
2. **The main session reads everything anyway** — to write the brief, to check the result — so
   the context you were trying to protect fills up regardless.

## The approach

The main session holds the **map, not the territory**.

- It reads `AGENTS.md` — a compact repo map, a few KB — and nothing else about the codebase.
- It locates files by path (one `grep`), and never opens them.
- It writes an explicit spec: the task, inputs (with the page URL for UI work), audience,
  format, out-of-scope, and a checkable "done means" list.
- The sub-agent does the reading and the editing.
- The main session reads the **diff** and judges it against the spec it wrote.

Rejected work is re-dispatched, never hand-fixed — hand-fixing is how the file contents end up
in your context anyway. (One narrow exception, and a short list of edits too small to dispatch
at all, in `references/when-not-to-dispatch.md`.)

## Usage

```
/dispatch bootstrap          # once per repo — writes AGENTS.md, installs agent templates, runs setup
/dispatch setup              # provision + record verification: dev server, browser, DESIGN.md, read-only DB user
/dispatch new <idea>         # heavy new project — one-question-at-a-time intake, then build
/dispatch <task>             # plan → locate → brief → work → accept
/dispatch deps <add|remove|update> <package>   # a dependency change as its own dispatch
/dispatch verify             # security critic pass over the current diff
/dispatch db <check>         # read-only database inspection
/dispatch status             # what's set up, what's missing
```

**Run `bootstrap` first.** It surveys the repo once and writes `AGENTS.md` — the map every later
dispatch depends on. Without it, sub-agents go back to surveying and the skill does nothing for
you. An `AGENTS.md` written for another tool is left intact; bootstrap appends a marked
dispatch section (`<!-- dispatch:map v1 -->`) and shows you the diff first.

**Then commit what bootstrap wrote** — `AGENTS.md`, `.claude/agents/dispatch-*.md`,
`.claude/.dispatch-state.json`, `.claude/dispatch/dispatch-measure.mjs`, and `DESIGN.md` plus
any dev dependency setup added — before the first dispatch, so they do not land in every
acceptance diff. Agents installed mid-session may need a restart (or `/agents`) to load;
until then the skill falls back to a general-purpose sub-agent carrying the template body.

**Each dispatch starts from a baseline.** Clean tree, or a snapshot of the dirty one — a printed
sha the main session records in its plan — so the diff you judge is the sub-agent's alone,
created files included, without touching your git index. Parallel dispatches get their own
worktrees.

## What bootstrap installs

Generic agent templates in `.claude/agents/`, skipped if a file of that name already exists:

| Agent | Model | Effort | Role |
| --- | --- | --- | --- |
| `dispatch-implementer` | opus | medium | Server logic, APIs, data access — core-level implementation |
| `dispatch-frontend` | opus | medium | CSS, layout, responsive — design work |
| `dispatch-db-tester` | sonnet | medium | Database inspection — read-only by instruction, plus engine-level guards |
| `dispatch-security-critic` | sonnet (haiku per call for trivial diffs) | medium | Critic only — never edits |

Plus what bootstrap's capabilities step (`/dispatch setup`) provisions — each install proposed
first and run only on your yes, always into the repo, never globally:

| What | Where | Why |
| --- | --- | --- |
| Measure script | `.claude/dispatch/dispatch-measure.mjs` | One command for overflow and computed styles per width — used by acceptance and the frontend agent alike |
| `DESIGN.md` (UI projects) | repo root | Tokens, breakpoints, components, references, and what the project never does — generated from your theme and CSS, shown before writing |
| Browser | a browser MCP's tools on `dispatch-frontend`'s `tools:` line, or Playwright as a dev dependency with chromium in `.claude/dispatch/browsers/` (gitignored) | So "verified at 375px" is rendered, not read |
| Read-only DB user | printed as SQL for your engine — you run it | The db-tester refuses to run on the application's read-write credential |
| *Verification capabilities* | a section in `AGENTS.md` | What this repo can check with; `status` reports each line |

The main session overrides the model per dispatch, on the Agent tool call — `sonnet` for light
work even on the two `opus`-default agents (a copy fix, a renamed field), `opus` for anything
the brief calls design or core-level (routing.md, "Model selection").

If your repo already has purpose-built agents, routing prefers them. They know your conventions;
these templates do not.

**On "read-only".** The critic and db-tester have no `Edit`/`Write`, but they have `Bash`, and
Bash can write. Their read-only posture is enforced by instruction, checked by the main
session (`git status --porcelain` before and after must match), and — for databases — backed
by one real guard: **a read-only DB user** (`sqlite3 -readonly` for SQLite), which the server
enforces whatever the agent types. Everything else is a seatbelt, put on every command because
each `psql -c` / `mysql -e` is a new session: `PGOPTIONS='-c default_transaction_read_only=on'`,
`mysql --init-command='SET SESSION TRANSACTION READ ONLY'`, and `mysql --safe-updates` (which
only stops `UPDATE`/`DELETE` without a key — `INSERT`, `DROP`, `ALTER` still run). A login that
can write can also switch a seatbelt off. So the db-tester refuses to proceed when the only
credential it can find is the application's read-write one. Credentials are never on a command
line and never grepped into the transcript.

The frontend agent's default tool list has no browser. Setup adds a browser MCP's tools to its
`tools:` line when one is configured and you say yes (a connected Chrome stays with the main
session); otherwise both the agent and the main session run
`.claude/dispatch/dispatch-measure.mjs` on a repo-local Playwright — and report rendering as
*Not verified* when neither is available.

## Design notes

Three ideas do the work:

**The Spec.** A brief is an engineering recipe: explicit inputs, the intended consumer, a format
guide, and — the part most people skip — an explicit list of what to leave alone. An
unconstrained agent refactors, renames, and adds dependencies, and every one of those is a diff
you now have to review.

**The Verifier.** A second model acts *exclusively* as a critic, evaluating against a spec
written from the actual diff. It edits nothing — by instruction, and the main session checks.
A generic security checklist produces generic findings; the scout stage — the main session
reusing the diff it already read at acceptance — exists so the critic is asked about risks the
change can actually carry.

**The Knowledge Base.** `AGENTS.md` is written for sub-agents, not humans. Its two most valuable
sections are the ones people skip: *what not to bother reading*, and the *known-failing
baseline* — so no future agent re-debugs a test that was already red on a clean checkout.

Every dispatch prompt ends, verbatim, with:

```
[ task list broken down into phases, each phase as a vertical slice, numbered ]
```

Last position, so it is the final instruction read. It is an instruction, not a placeholder:
the sub-agent plans numbered phases before editing and reports per phase; the main session
checks the phases at acceptance. The brief decides *what*; phases are only *how*, within scope.

**Capabilities are provisioned, not assumed.** A protocol that says "verify at 375px" or
"connect read-only" is only as honest as the tooling behind it. Setup detects what the repo can
check with — dev server, browser, design source, read-only database user — proposes what is
missing, installs only on a yes and only into the repo, and writes the result into `AGENTS.md`.
What stays missing is recorded as *none* and reported, so a *Not verified* at acceptance is
expected rather than a surprise; `status` shows each capability with the one command that fixes
it (references/setup.md).

**Dependencies have a path.** Briefs still forbid adding packages. A needed one becomes its own
`deps` dispatch — manifest and lockfile only, audit quoted, then a critic asked only about
provenance, advisories, pinning and lockfile integrity — before the code that uses it
(references/dependencies.md).

**When it stops.** Two rejections mean the brief is wrong and gets rewritten; a third failure
stops the loop and escalates to you with a summary. Reports are capped at 40 lines, and large
diffs are read `--stat` first, then per file — an oversize diff is itself a finding.

**Model by task weight.** The main session sets the model explicitly on every dispatch —
`sonnet` for light work, `opus` for design or core-level implementation — and says why
(routing.md).

**Effort is medium.** Every sub-agent template sets `effort: medium` in its frontmatter — the
Agent tool cannot set effort per call. Only the user changes it (routing.md).

**At most 2 sub-agents at once.** Every kind counts toward the cap. A plan that needs more asks
the user first, with the job, the reason, and the cost (routing.md).

**Responsive is not optional.** Any task that designs or changes UI always includes responsive
behaviour in scope, clarified one question at a time before briefing, and checked at
mobile/tablet/desktop at acceptance (references/responsive.md).

**New heavy projects get an intake first.** Building from scratch, an empty repo, or a new large
subsystem is gathered from the user one question at a time — never batched — before anything is
scaffolded; the answers are confirmed and saved as `PROJECT_BRIEF.md`, then bootstrap runs
(`/dispatch new <idea>`, references/new-project.md).

## Compatibility

Needs an agent runtime that can spawn sub-agents and run shell commands. Built for Claude Code;
the protocol itself is portable. Git is required for the acceptance and verify steps.

Frontmatter is restricted to the Agent Skills spec subset (`name`, `description`, `license`,
`compatibility`, `metadata`), so the skill packages cleanly for non-Claude-Code runtimes too.
Where a step names something Claude Code-specific (the `Explore` agent, `isolation: "worktree"`)
the reference gives the portable fallback next to it. Database checks cover MySQL/MariaDB,
PostgreSQL, SQLite and MongoDB. The measure script needs Node 18+; it renders with the repo's
own Playwright only — Node from `<repo>/node_modules`, else Python from `$DISPATCH_PYTHON` or
the repo's `.venv`/`venv` — never a global install or the system interpreter, and it prints
which one it used (`renderer: …`). `--probe` shows the same lookup without a page.

`scripts/validate.sh` (bash; uses node when present) checks the skill's own structure and runs
`node --test scripts/measure.test.mjs`; `evals/` holds scenario files describing the behaviour
each fix is meant to produce.

## Layout

```
skills/dispatch/
  SKILL.md                    the dispatch protocol
  references/
    prompt-spec.md            how a brief is assembled, with a worked example
    routing.md                picking the agent; fallbacks when a name is not loaded
    acceptance.md             the main session's own check — baseline, new files, large diffs, widths
    failures.md               rejections, errors, questions, out-of-scope stops, escalation
    when-not-to-dispatch.md   the trivial-edit and hand-fix exceptions
    responsive.md             responsive clarification questions and acceptance widths
    new-project.md            heavy new project intake, one question at a time, PROJECT_BRIEF.md
    verifier.md               the security critic chain
    bootstrap.md              building AGENTS.md, the Surfaces table, measuring the baseline, what to commit
    setup.md                  verification capabilities — dev server, browser, DESIGN.md, read-only DB user
    dependencies.md           the deps brief, its acceptance, and the narrow critic pass
    status.md                 what /dispatch status checks and recommends
    db-check.md               database inspection briefs, per-engine guards
  agents/                     templates installed by bootstrap
  scripts/dispatch-measure.mjs  overflow + computed style per width; setup copies it to .claude/dispatch/
  examples/                   a real generated AGENTS.md
scripts/validate.sh           structural checks for this repo
scripts/measure.test.mjs      unit tests for the measure script (node --test; no browser, no network)
evals/                        scenario files: setup, prompt, expected behaviour
CHANGELOG.md
```

## License

MIT
