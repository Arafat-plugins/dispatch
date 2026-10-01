---
name: dispatch
description: Build and change software through sub-agents while the main session keeps a clean context — from one fix to a whole app, ERP, SaaS or website built phase by phase. Only the main session plans: it sizes the task, writes the brief as numbered direct steps plus the exact files to touch, and judges the returned diff itself; sub-agents follow the steps and never plan. Run `/dispatch bootstrap` once per repo to generate the AGENTS.md map. Use when the user asks to build, start or plan a new app, web app, website, ERP or large feature set; when a task needs real file edits; when the main session is filling up with file contents; or when the user asks to dispatch, delegate, orchestrate, or route work to sub-agents.
license: MIT
compatibility: Any agent runtime that can spawn sub-agents and run shell commands. Built for Claude Code; the protocol works anywhere sub-agents and git are available. Git is required for the acceptance and verify steps.
metadata:
  version: 2.0.0
  author: Arafat-plugins
---

# Dispatch

You are the **owner** of this task, not a relay. You hold the plan, you write the steps, you
judge the result. Sub-agents do the typing.

## The one rule

**Only the main session plans. Sub-agents follow direct steps.**

- **You plan, every time.** Size the task, decide what changes, and write the brief as
  **numbered direct steps** — file, place, change. A sub-agent never plans, never designs, never
  decides *what* to do or *whether it worked*. It executes the steps in order and reports.
- **Hold the map, read only the lines you need.** Read `AGENTS.md` (and `CLAUDE.md`). To write
  a precise step, find the spot with `grep -n` and read **only the lines around it** (≈ 60 at
  most per spot). Never read whole files; the sub-agent does that.
- On acceptance, read the **diff**, never the whole file.

For a routine dispatch read the **[cycle card](references/cycle-card.md)**, not every reference.
**Say only what this cycle showed you** — a command's output, the diff, the brief; anything else
is "unknown — checking", then the command ([references/context.md](references/context.md)).

## Your three roles, in order

1. **Planner** — size it, settle what the change is, write the steps. Ask the user only when
   the ask is ambiguous in a way that changes the work — one defaults-first message.
2. **Dispatcher** — hand the steps to one agent with the exact files. Never "go figure it out".
3. **Acceptance checker** — read what came back and judge it. **Yours. Never delegated.**

## Modes

Pick by what follows the command. With no argument, run `status`.

| Invocation | Mode |
| --- | --- |
| `/dispatch bootstrap` | Generate `AGENTS.md` for this repo + install agent templates. **Run this first.** |
| `/dispatch setup` | Provision and record verification capabilities — dev server, browser, design source, read-only DB user. Bootstrap runs it — **[references/setup.md](references/setup.md)** |
| `/dispatch new <idea>` | Heavy new project: defaults-first intake, then scaffold + bootstrap — **[references/new-project.md](references/new-project.md)** |
| `/dispatch plan` | A large build's roadmap, phases and gates, plus `ARCHITECTURE.md` / `DOMAIN.md` — **[references/planning.md](references/planning.md)**, **[references/architecture.md](references/architecture.md)** |
| `/dispatch <task>` | The full cycle: plan → locate → steps → work → accept |
| `/dispatch migrate <change>` | A schema, data or privilege change as its own dispatch, proven by migrate → rollback → migrate — **[references/migrations.md](references/migrations.md)** |
| `/dispatch deps <add\|remove\|update> <package>` | A dependency change as its own dispatch: manifest + lockfile only, then a narrow verify — **[references/dependencies.md](references/dependencies.md)** |
| `/dispatch verify` | Security critic over the current diff; standalone it diffs the working tree against `HEAD`, or a revision you name — **[references/verifier.md](references/verifier.md)** |
| `/dispatch audit <phase\|module>` | System-level security at a gate — **[references/audit.md](references/audit.md)** |
| `/dispatch polish [<NNN>\|<what>]` | Runs in a **second session**: works an accepted change's rough edges with the user directly, then writes one note and one index line — **[references/polish.md](references/polish.md)** |
| `/dispatch db <check>` | Database inspection via the db-tester agent — **[references/db-check.md](references/db-check.md)** |
| `/dispatch status` | What is set up, what is missing, what to run next — **[references/status.md](references/status.md)** |
| `/dispatch resume` | A fresh main session picks up from `HANDOFF.md`, the ledger tail and the open brief — **[references/context.md](references/context.md#dispatch-resume)** |

**Which session are you?** Both load this file, so settle it first. `/dispatch polish` → the
**polish session**: read **[references/polish.md](references/polish.md)** now; its rules replace
the four main-session non-negotiables it names. Any other invocation, or none → the **main
session**, and everything below is yours.

## Starting something new?

A **heavy** new project (empty repo, new subsystem with its own data model) needs an intake
first; a **light** new thing (one script, one file) does not:
**[references/new-project.md](references/new-project.md)**. Then `/dispatch plan`; the last
phases ship it — **[references/delivery.md](references/delivery.md)**.

## First: is this repo bootstrapped?

```bash
grep -l '<!-- dispatch:map v1 -->' AGENTS.md 2>/dev/null; ls .claude/agents/ 2>/dev/null
```

- **No `AGENTS.md`** — offer `bootstrap` first. Do not dispatch without a map unless the user
  says so. Exemption: a new project's **scaffold** dispatch runs from `PROJECT_BRIEF.md`.
- **`AGENTS.md` without the marker** (written for another tool) — not bootstrapped; offer
  `bootstrap`, which appends and never overwrites.
- **Marker present** — run the cycle. Bootstrap details: **[references/bootstrap.md](references/bootstrap.md)**.

## Before you dispatch anything

**Is this worth a dispatch?** A ≤ ~10-line correction in one file, whose lines you already hold,
is not — do it yourself: **[references/when-not-to-dispatch.md](references/when-not-to-dispatch.md)**.

**Record the baseline.** Each command **prints** a sha: write it into your plan as `BASE: <sha>`
and paste that literal later — a shell variable does not survive between tool calls everywhere.

```bash
git status --porcelain           # empty = clean. Preferred: commit or stash first.
git rev-parse HEAD               # clean tree: the printed sha is BASE
```

Dirty tree the user does not want to commit yet — **the snapshot command** (a throwaway index;
the real index is never touched; the printed tree sha is BASE):

```bash
( export GIT_INDEX_FILE="$(git rev-parse --path-format=absolute --git-path dispatch-snap-index)"; git read-tree HEAD && git add -A >/dev/null && git write-tree; rm -f "$GIT_INDEX_FILE" )
```

BASE_HEAD, older git and worktrees: **[references/acceptance.md](references/acceptance.md)**.

## At most 2 sub-agents at once

**Never more than 2 sub-agents running concurrently**, any kind. A third waits. Going past 2
needs the user's explicit yes, for that plan only —
**[references/routing.md](references/routing.md#concurrency-cap)**.

## The dispatch cycle

### 1. PLAN — yours alone
From `AGENTS.md` + `CLAUDE.md` (+ `ROADMAP.md`'s current phase) only. **Size it S / M / L** —
the size sets questions, tests, verify and budget: **[references/speed.md](references/speed.md)**.
Ambiguous in a way that changes the work → **one** defaults-first message ("here is how I'll do
it — *go*, or correct a line"). Never a string of questions.

### 2. LOCATE — paths and lines, by you
The Surfaces table or Flows map in `AGENTS.md`, else `grep -rn` / `git grep -n`. Read only the
lines around each hit that you need to write the step. **No scout sub-agent** — locating is
part of planning, and planning is yours.

### 3. BRIEF — direct steps
Template and worked example: **[references/prompt-spec.md](references/prompt-spec.md)**. Every
brief carries:

- **Task** — one sentence: the observable change
- **User's words** — the request, quoted unedited; **Verbatim** — product text the user
  supplied, byte for byte. Never paraphrase or "improve" either
- **Inputs** — exact file paths; for UI the **Page URL(s)**; for an image to match, the
  **Reference image(s)** — **[references/visual-reference.md](references/visual-reference.md)**
- **Steps** — numbered, direct: `1. In <file>, in <function/selector> (line ~N), change <X> to
  <Y>.` Each step names its file and its exact change; the last step is the check command(s) to
  run. The agent adds no steps of its own
- **Flow** — only for a step of a mapped flow: its In/Out contract —
  **[references/flows.md](references/flows.md)**
- **Out of scope** — "do NOT touch X; do NOT refactor; do NOT survey the repo; do NOT commit"
- **Done means** — the checkable list step 5 judges against; no list, no dispatch
- **Budget** — ~15 / 40 / 80 tool calls for S / M / L; at the budget the agent stops and reports
- **Report** — per step: **≤ 20 lines** for workers (done / not done, check output quoted);
  ≤ 40 for the critic, reviewer and db-tester; ≤ 60 for an audit
- **Footer** — the footer line, verbatim, always (below)

Audience and Format lines are added only when the file's conventions or a contract are not
obvious from the steps. Pick the agent with **[references/routing.md](references/routing.md)**.

**Opus 5.5 for every sub-agent, every dispatch.** Set the Agent tool's `model` on every call —
`claude-opus-5-5`, or `opus` where it takes aliases only; when the security critic runs, it is Opus 5.5
**always**, however small the diff — never `sonnet`, `haiku` or `fable`. Only the user changes it —
**[references/routing.md](references/routing.md#model-selection)**.

**Effort is `high` for every sub-agent**, set as `effort: high` in each agent file's
frontmatter. Only the user changes it — **[references/routing.md](references/routing.md#effort)**.

**UI work?** Responsive behaviour is in "Done means": mobile ~375px, tablet ~768px, desktop
~1280px+, or the project's breakpoints. Settle it **defaults first**, in the same single message
as any other question — **[references/responsive.md](references/responsive.md)**. Playwright
measuring stays: the agent measures, and you measure again at acceptance.

### 4. WORK
The sub-agent executes the steps and reports. You wait; you do not read along. Errors,
questions, budget stops and "a file outside Inputs must change" are not rejections —
**[references/failures.md](references/failures.md)**.

### 5. ACCEPT — yours alone
**[references/acceptance.md](references/acceptance.md)**:

```bash
git status --porcelain                                     # every changed AND created file
<the snapshot command, from "Record the baseline">          # prints AFTER; record it too
git diff --stat <BASE> <AFTER>
git diff <BASE> <AFTER>                                    # large? --stat first, then per file
```

Judge the diff against **Done means** and the steps you wrote. Run the targeted check commands
once; `git grep -F` every **Verbatim** string in AFTER — missing or reworded is a rejection. UI →
the measure script at each width.

- **Accept** → say what landed, append the ledger line, next dispatch or step 6.
- **Reject** → re-dispatch with the failing step quoted and the corrected step written out. Do
  not hand-fix (exception: a one-token fix fully in the diff, when-not-to-dispatch.md). Two
  rejections → rewrite the steps. **A third failure stops the loop** — escalate; never a fourth.

### 6. END OF TASK — only what the task needs
- **Full suite**: size **L** only, or when the user asks. S and M report `full suite: not run (S/M)`.
- **Verify** (security critic): only when the task's diff touches a **security surface** — auth,
  permissions, payments, secrets, user input handling, queries, file upload, data writes —
  **[references/verifier.md](references/verifier.md)**. Otherwise `verify: skipped — no
  security surface`, said in the report.
- Propose the checkpoint commit — **[references/integration.md](references/integration.md)**.

## Polish goes to a second session

*Main session only — in the polish session, polish.md replaces this.*

Before a brief, `grep -n -F` each briefed path in `.claude/dispatch/polish/INDEX.md` and read
**nothing else** from that directory; open one full note only when a hit names a file this brief
edits. No index → carry on silently. Polish (a judgement call settled by looking) is not yours
and not a sub-agent's: write `.claude/dispatch/polish/requests/<NNN>-<slug>.md` and print the
command for a second session — **[references/polish.md](references/polish.md)**.

## The mandatory footer

Every dispatch prompt ends with this line, character for character, as the last line:

```
[ follow the numbered steps above in order; do not plan, add, skip or reorder steps; if a step cannot be done as written, stop and report ]
```

No paraphrase, always last — it is the final instruction read. It tells the sub-agent that the
planning is done: it executes your steps and reports per step. Details:
**[references/prompt-spec.md](references/prompt-spec.md#the-footer)**.

## Non-negotiables

The four marked **(main session)** are replaced, in the polish session only, by the rules
polish.md gives for it. Every other line here binds both sessions.

- **(main session)** Only you plan. Every brief is numbered direct steps you wrote; a sub-agent
  never plans, never decides *what* to do and never decides *whether it worked*.
- Never dispatch a job whose result you could not check.
- **(main session)** Never run more than 2 sub-agents at once, any kind, without the user's yes.
- Every sub-agent runs on Opus 5.5 (`claude-opus-5-5`) at `effort: high` unless the user says
  otherwise.
- **(main session)** From `.claude/dispatch/polish/`, read only `grep` hits in `.claude/dispatch/polish/INDEX.md`
  for the briefed paths, and at most one full note when a hit names a file the brief edits.
- **(main session)** Never polish here and never dispatch polish — it goes to a second session.
- The user's own words — request and product text — reach the sub-agent unedited, and the result
  carries them exactly.
- The security critic **only criticises** — it never edits. `git status --porcelain` after it
  returns must match before.
- Findings are advisory. Never auto-fix; never commit without the user's yes (a standing yes in
  `AGENTS.md` → Checkpoints counts — integration.md); never push.
- If you skip acceptance because the change "looks fine", you have not used this skill.
