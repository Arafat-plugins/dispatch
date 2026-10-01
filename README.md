# dispatch

A Claude Code / agent skill that keeps the **main session's context clean** by delegating
implementation work to sub-agents. **Only the main session plans**: it writes every brief as
numbered direct steps with exact file paths, the sub-agent executes them, and the main session
checks the diff itself.

## Install

**Claude Code / any agent runtime:**

```bash
npx skills add Arafat-plugins/dispatch
```

**claude.ai / Claude desktop (Settings → Capabilities → Skills → Upload):** upload a zip whose
top folder is `dispatch/`, with `SKILL.md` directly inside it. GitHub's "Download ZIP" does
**not** work as is — it nests the skill two folders deep (`dispatch-main/skills/dispatch/`).
Build the right zip from a clone:

```bash
cd skills && zip -r ../dispatch.zip dispatch && cd ..
unzip -l dispatch.zip | head      # first entries: dispatch/  dispatch/SKILL.md ...
```

Or take `dispatch.zip` from a GitHub release — `.github/workflows/release-zip.yml` builds it
the same way and attaches it to every published release.

## The problem

Two things go wrong when you hand work to sub-agents:

1. **The sub-agent surveys the whole codebase** before doing anything, because nobody told it
   where to look. Slow, expensive, and it still guesses.
2. **The main session reads everything anyway** — to write the brief, to check the result — so
   the context you were trying to protect fills up regardless.

## The approach

The main session holds the **map, not the territory**.

- It reads `AGENTS.md` — a compact repo map, a few KB — and nothing else about the codebase.
- It locates files and lines itself (`grep -n`, then ≈ 60 lines around the hit) — enough to
  write an exact step, never the whole file.
- It writes the brief as **numbered direct steps** — "in `<file>`, in `<selector>` (around line
  N), change X to Y" — plus inputs (with the page URL for UI work), out-of-scope, and a
  checkable "done means" list.
- The sub-agent executes the steps in order. It never plans, never adds a step, and stops at
  a step it cannot do as written.
- The main session reads the **diff** and judges it against the spec it wrote.

Rejected work is re-dispatched, never hand-fixed — hand-fixing is how the file contents end up
in your context anyway. (One narrow exception, and a short list of edits too small to dispatch
at all, in `references/when-not-to-dispatch.md`.)

## Usage

```
/dispatch bootstrap          # once per repo — writes AGENTS.md, installs agent templates, runs setup
/dispatch setup              # provision + record verification: dev server, browser, DESIGN.md, read-only DB user
/dispatch new <idea>         # heavy new project — defaults-first intake (or your spec), then plan and build
/dispatch plan               # roadmap, phases and gates + ARCHITECTURE.md / DOMAIN.md for a large build
/dispatch <task>             # plan → locate → brief → work → accept
/dispatch deps <add|remove|update> <package>   # a dependency change as its own dispatch
/dispatch migrate <change>   # a schema/data change as its own dispatch: migrate → rollback → migrate
/dispatch verify             # security critic pass over the current diff
/dispatch audit <phase|module>  # system-level security at a gate, against THREAT-MODEL.md
/dispatch polish [<NNN>]     # run this in a SECOND session — it works the rough edges with you
/dispatch db <check>         # read-only database inspection
/dispatch status             # what's set up, what's missing
/dispatch resume             # a fresh session picks up where a rotated one stopped
```

**Run `bootstrap` first.** It surveys the repo once and writes `AGENTS.md` — the map every later
dispatch depends on. Without it, sub-agents go back to surveying and the skill does nothing for
you. An `AGENTS.md` written for another tool is left intact; bootstrap appends a marked
dispatch section (`<!-- dispatch:map v1 -->`) and shows you the diff first.

**Then commit what bootstrap wrote** — `AGENTS.md`, `.claude/agents/dispatch-*.md`,
`.claude/.dispatch-state.json`, `.claude/dispatch/dispatch-measure.mjs`,
`.claude/dispatch/polish/INDEX.md`, and `DESIGN.md` plus
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
| `dispatch-implementer` | Opus 5.5 (`claude-opus-5-5`) | high | Server logic, APIs, data access — core-level implementation |
| `dispatch-frontend` | Opus 5.5 (`claude-opus-5-5`) | high | CSS, layout, responsive — design work |
| `dispatch-db-tester` | Opus 5.5 (`claude-opus-5-5`) | high | Database inspection — read-only by instruction, plus engine-level guards |
| `dispatch-security-critic` | Opus 5.5 (always, whatever the diff size) | high | Critic only — never edits; also runs `/dispatch audit` |
| `dispatch-migrator` | Opus 5.5 (`claude-opus-5-5`) | high | Schema, data and privilege changes — dev database only, migrate → rollback → migrate |
| `dispatch-test-writer` | Opus 5.5 (`claude-opus-5-5`) | high | Tests only — flow tests, test-first, E2E with the repo's runner; never app code |
| `dispatch-reviewer` | Opus 5.5 (`claude-opus-5-5`) | high | Once per gate: layering, rule and permission drift, queries — findings only |

Bootstrap also creates `.claude/dispatch/polish/` and `.claude/dispatch/polish/requests/` with a
seeded empty `INDEX.md` — the polish session's ledger, and the only polish file the main session
ever reads (below).

Plus what bootstrap's capabilities step (`/dispatch setup`) provisions — each install proposed
first and run only on your yes, always into the repo, never globally:

| What | Where | Why |
| --- | --- | --- |
| Measure script | `.claude/dispatch/dispatch-measure.mjs` | One command for overflow and computed styles per width — used by acceptance and the frontend agent alike |
| `DESIGN.md` (UI projects) | repo root | Tokens, breakpoints, components, references, and what the project never does — generated from your theme and CSS, shown before writing |
| Browser | a browser MCP's tools on `dispatch-frontend`'s `tools:` line, or Playwright as a dev dependency with chromium in `.claude/dispatch/browsers/` (gitignored) | So "verified at 375px" is rendered, not read |
| Read-only DB user | printed as SQL for your engine — you run it | The db-tester refuses to run on the application's read-write credential |
| *Verification capabilities* | a section in `AGENTS.md` | What this repo can check with; `status` reports each line |

Every sub-agent runs on **Opus 5.5** — the templates pin `model: claude-opus-5-5` by full ID,
and the main session also sets the model on every Agent tool call, so any general-purpose
fallback runs on Opus 5.5 too instead of the runtime's small default. There is no light/heavy split and no downgrade to `sonnet`, `haiku` or `fable`; the
security critic in particular runs on Opus 5.5 however small the diff. Bootstrap offers to pin
the repo's sessions as well, in `.claude/settings.json` (routing.md, "Model selection").

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

**The Spec.** A brief is a list of direct instructions the main session wrote after doing the
planning: explicit inputs, numbered steps, and — the part most people skip — an explicit list
of what to leave alone. An
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
[ follow the numbered steps above in order; do not plan, add, skip or reorder steps; if a step cannot be done as written, stop and report ]
```

Last position, so it is the final instruction read. It tells the sub-agent the planning is
done: it executes your steps in order, reports per step, and stops at a step it cannot do as
written instead of improvising. Acceptance checks the diff step by step; a change no step asked
for is a rejection.

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
stops the loop and escalates to you with a summary. Worker reports are capped at 20 lines, per step, and large
diffs are read `--stat` first, then per file — an oversize diff is itself a finding.

**One model: Opus 5.5.** The main session sets `claude-opus-5-5` (or the `opus` alias, where the
tool takes aliases only) on every dispatch — implementer, frontend, db-tester, reviewer and critic
alike. The security critic is **always Opus 5.5**, however small the diff. Only the user changes
the model (routing.md).

**Effort is high.** Every sub-agent template sets `effort: high` in its frontmatter — the
Agent tool cannot set effort per call. Only the user changes it (routing.md).

**At most 2 sub-agents at once.** Every kind counts toward the cap. A plan that needs more asks
the user first, with the job, the reason, and the cost (routing.md).

**Responsive is not optional.** Any task that designs or changes UI always includes responsive
behaviour in scope, settled in one defaults-first message before briefing (or none, when the
file already answers it), and checked at mobile/tablet/desktop with Playwright at acceptance
(references/responsive.md).

**Polish runs in a second session.** After a change is accepted there is usually light polish
left, and doing the build and the polish in one session fills that session with detail it does
not need. So the main session writes a request under
`.claude/dispatch/polish/requests/<NNN>-<slug>.md`, prints the command, and you open a second
terminal in the same repo and run `/dispatch polish <NNN>` on Opus 5.5 at high effort. That session
is a worker, not a dispatcher: it reads and edits files with you directly, takes the same
baseline, shows you the diff, and when you say it is done writes one note plus **one index
entry** — a title, a summary of at most two lines, and a `touches:` line of at most five paths
or surfaces. Before a brief the main session only `grep`s `.claude/dispatch/polish/INDEX.md` for the
paths it will edit, and opens a single full note only when a hit names one of them. A correction with one right answer — a typo, a wrong constant — stays a
direct edit; a judgement call you have to see to approve is polish (references/polish.md).

**Sized for speed.** Every task is sized S / M / L first, and the size sets the ceremony: at
most one defaults-first "go or correct" message (ceiling 3 questions per task); no scout; no
planning pass inside the sub-agent; targeted tests run once on each side; the full suite only
for size L; the security critic only when the diff touches a security surface; a tool-call
budget (~15 / 40 / 80) in every brief. A small task should take minutes, not an hour
(references/speed.md).

**Image references are compared, not described.** A mock or screenshot goes into the repo
(`.claude/dispatch/refs/`), the brief names it, the frontend agent opens it, writes a reference
spec, and runs `dispatch-measure.mjs --compare` — a reference | render | diff composite — for up
to three passes; acceptance opens the same composite (references/visual-reference.md).

**Backend flows hold end to end.** `AGENTS.md` maps each business flow (trigger, steps, states,
invariants, test). A brief touching a step carries its In/Out contract and is one brief through
every layer; a flow test is written where a step says so, and acceptance runs that flow's test
(references/flows.md).

**The main session stays small.** A one-page cycle card replaces re-reading the references;
M and L briefs live in files; a ledger records every outcome; statements must come from this
cycle's output; after a compaction the session writes `HANDOFF.md` and you continue in a fresh
one with `/dispatch resume` — at ~10 dispatches or a phase end that is only suggested
(references/context.md).

**Your words stay yours.** Briefs quote the request unedited (*User's words*) and carry every
piece of product text you supplied byte for byte (*Verbatim*); acceptance `git grep`s each
string, and a rewording is a rejection (references/prompt-spec.md).

**Large builds get a project layer.** `/dispatch plan` numbers the requirements, writes
`ROADMAP.md` (vertical-slice phases, each ending at a gate the user passes), `ARCHITECTURE.md`
and `DOMAIN.md` (business rules `BR-nn` with tests, a permission matrix) — briefs cite them by
ID, agents stop on a contradiction. Each gate runs the full suite, brings worktree slices back,
proposes a checkpoint commit, runs the reviewer and `/dispatch audit`, and rolls up usage from
the ledger. Schema changes are their own `migrate` briefs; delivery artefacts (CI, deploy kit,
backups, runbooks, cutover) are briefs checked in a clean-room container — the user runs real
deploys. Past ~60 surfaces the map splits into module maps, and every brief that adds a route or
flow updates its row (references/planning.md, architecture.md, migrations.md, integration.md,
audit.md, delivery.md).

**New heavy projects get an intake first.** Building from scratch, an empty repo, or a new large
subsystem is scoped in at most three questions — purpose, MVP scope, then one defaults-first
confirmation — before anything is scaffolded; the answers are confirmed and saved as `PROJECT_BRIEF.md`, then bootstrap runs
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
    cycle-card.md             a routine dispatch on one page — read instead of the full references
    planning.md               /dispatch plan: requirement IDs, ROADMAP.md, gates, usage roll-up
    architecture.md           ARCHITECTURE.md, DOMAIN.md (BR-nn, permissions), ADRs — cited by ID
    migrations.md             /dispatch migrate: kinds, the migrator brief, acceptance, never production
    integration.md            worktree slices back, checkpoint commits, map upkeep, module maps
    audit.md                  /dispatch audit: THREAT-MODEL.md, the module-wide critic brief
    delivery.md               CI, env config, deploy kit, backups, runbooks, cutover — clean-room checked
    speed.md                  sizing S/M/L, one defaults-first message, targeted tests, critic on security surfaces
    context.md                the fact rule, briefs on disk, the ledger, session rotation, /dispatch resume
    flows.md                  business flows: the map, the Flow section, flow tests, flow acceptance
    visual-reference.md       building from an image: refs in the repo, reference spec, --compare loop
    prompt-spec.md            how a brief is assembled as numbered direct steps, with a worked example
    routing.md                picking the agent; fallbacks when a name is not loaded
    acceptance.md             the main session's own check — baseline, new files, large diffs, widths
    failures.md               rejections, errors, questions, out-of-scope stops, escalation
    when-not-to-dispatch.md   the trivial-edit and hand-fix exceptions
    responsive.md             responsive defaults-first message, the 3-question ceiling, acceptance widths
    new-project.md            heavy new project intake, three questions at most, PROJECT_BRIEF.md
    verifier.md               the security critic chain
    polish.md                 the second session: grep-hit reading of the index, the handoff, the note
    bootstrap.md              building AGENTS.md, the Surfaces table, measuring the baseline, what to commit
    setup.md                  verification capabilities — dev server, browser, DESIGN.md, read-only DB user
    dependencies.md           the deps brief, its acceptance, and the narrow critic pass
    status.md                 what /dispatch status checks and recommends
    db-check.md               database inspection briefs, per-engine guards
  agents/                     templates installed by bootstrap
  scripts/dispatch-measure.mjs  overflow, computed style, screenshots, reference comparison, basic a11y per width
  examples/                   a real generated AGENTS.md
scripts/validate.sh           structural checks for this repo
scripts/measure.test.mjs      unit tests for the measure script (node --test; no browser, no network)
scripts/build-evals.mjs       evals/*.md → evals/evals.json (skill-creator format); --check in validate.sh
evals/                        scenario files + evals.json (generated) + triggers.json (description evals)
docs/GAP-ANALYSIS-big-projects.md  what the skill still lacks for large builds (ERP, multi-module apps), with a roadmap
docs/FIELD-ISSUES-v1.8.0.md   five problems seen in real use, their root causes, and what 1.8.0 changed
CHANGELOG.md
.github/workflows/release-zip.yml  builds the uploadable dispatch.zip on every release
```

## License

MIT
