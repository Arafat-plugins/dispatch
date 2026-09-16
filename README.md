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
- It writes an explicit spec: inputs, audience, format, out-of-scope, and a checkable
  "done means" list.
- The sub-agent does the reading and the editing.
- The main session reads the **diff** and judges it against the spec it wrote.

Rejected work is re-dispatched, never hand-fixed — hand-fixing is how the file contents end up
in your context anyway. (One narrow exception, and a short list of edits too small to dispatch
at all, in `references/when-not-to-dispatch.md`.)

## Usage

```
/dispatch bootstrap          # once per repo — writes AGENTS.md, installs agent templates
/dispatch new <idea>         # heavy new project — one-question-at-a-time intake, then build
/dispatch <task>             # plan → locate → brief → work → accept
/dispatch verify             # security critic pass over the current diff
/dispatch db <check>         # read-only database inspection
/dispatch status             # what's set up, what's missing
```

**Run `bootstrap` first.** It surveys the repo once and writes `AGENTS.md` — the map every later
dispatch depends on. Without it, sub-agents go back to surveying and the skill does nothing for
you. An `AGENTS.md` written for another tool is left intact; bootstrap appends a marked
dispatch section (`<!-- dispatch:map v1 -->`) and shows you the diff first.

**Then commit what bootstrap wrote** — `AGENTS.md`, `.claude/agents/dispatch-*.md`,
`.claude/.dispatch-state.json` — before the first dispatch, so they do not land in every
acceptance diff. Agents installed mid-session may need a restart (or `/agents`) to load;
until then the skill falls back to a general-purpose sub-agent carrying the template body.

**Each dispatch starts from a baseline.** Clean tree, or a snapshot of the dirty one, so the
diff you judge is the sub-agent's alone — created files included. Parallel dispatches get
their own worktrees.

## What bootstrap installs

Generic agent templates in `.claude/agents/`, skipped if a file of that name already exists:

| Agent | Model | Role |
| --- | --- | --- |
| `dispatch-implementer` | opus | Server logic, APIs, data access — core-level implementation |
| `dispatch-frontend` | opus | CSS, layout, responsive — design work |
| `dispatch-db-tester` | sonnet | Database inspection — read-only by instruction, plus engine-level guards |
| `dispatch-security-critic` | sonnet (haiku for trivial diffs) | Critic only — never edits |

The main session overrides the model per dispatch, on the Agent tool call — `sonnet` for light
work even on the two `opus`-default agents (a copy fix, a renamed field), `opus` for anything
the brief calls design or core-level (routing.md, "Model selection").

If your repo already has purpose-built agents, routing prefers them. They know your conventions;
these templates do not.

**On "read-only".** The critic and db-tester have no `Edit`/`Write`, but they have `Bash`, and
Bash can write. Their read-only posture is enforced by instruction, checked by the main
session (`git status --porcelain` before and after must match), and — for databases — backed
by real guards: a read-only DB user, `SET SESSION TRANSACTION READ ONLY`, `sqlite3 -readonly`,
`mysql --safe-updates`. Credentials are never on a command line and never grepped into the
transcript.

The frontend agent's default tool list has no browser. Add your MCP browser tools to its
`tools:` line after install, or the main session measures overflow itself with a headless
Playwright one-liner — and reports rendering as *Not verified* when neither is available.

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

**When it stops.** Two rejections mean the brief is wrong and gets rewritten; a third failure
stops the loop and escalates to you with a summary. Reports are capped at 40 lines, and large
diffs are read `--stat` first, then per file — an oversize diff is itself a finding.

**Model by task weight.** The main session sets the model explicitly on every dispatch —
`sonnet` for light work, `opus` for design or core-level implementation — and says why
(routing.md).

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
PostgreSQL, SQLite and MongoDB.

`scripts/validate.sh` (bash, no dependencies) checks the skill's own structure; `evals/` holds
scenario files describing the behaviour each fix is meant to produce.

## Layout

```
skills/dispatch/
  SKILL.md                    the dispatch protocol
  references/
    prompt-spec.md            how a brief is assembled, with a worked example
    routing.md                picking the agent; fallbacks when a name is not loaded
    acceptance.md             the main session's own check — baseline, new files, large diffs
    failures.md               rejections, errors, questions, out-of-scope stops, escalation
    when-not-to-dispatch.md   the trivial-edit and hand-fix exceptions
    responsive.md             responsive clarification questions and acceptance widths
    new-project.md            heavy new project intake, one question at a time, PROJECT_BRIEF.md
    verifier.md               the security critic chain
    bootstrap.md              building AGENTS.md, measuring the baseline, what to commit
    status.md                 what /dispatch status checks and recommends
    db-check.md               database inspection briefs, per-engine guards
  agents/                     templates installed by bootstrap
  examples/                   a real generated AGENTS.md
scripts/validate.sh           structural checks for this repo
evals/                        scenario files: setup, prompt, expected behaviour
CHANGELOG.md
```

## License

MIT
