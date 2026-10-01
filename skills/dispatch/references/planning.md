# Planning — the roadmap, phases and gates of a large build

`/dispatch plan`. A single dispatch knows what to build. Nothing up to 1.8.0 said **what to
build next, in what order, and when to stop and show the user**. Large builds filled that gap
with a hand-written master prompt, and its progress file went four phases stale. This file is
that layer, kept compact enough for the main session to read a slice of it per cycle.

## When it runs

- **After the new-project intake** ([new-project.md](new-project.md)): `PROJECT_BRIEF.md` is
  confirmed, and the root commit exists. Plan before the scaffold dispatch, so the scaffold
  builds the first phase's foundations and nothing else.
- **On an existing repo, for a size-L body of work**, meaning several features, a new module
  or a rebuild. Run it before the first brief.
- **Not** for a single task. A size S or M task is a dispatch ([speed.md](speed.md)).

It writes three things, each shown as a diff and confirmed by the user before it lands:
`ROADMAP.md`, plus `ARCHITECTURE.md` and `DOMAIN.md` ([architecture.md](architecture.md)).

## Requirements get IDs first

Number what `PROJECT_BRIEF.md` (or the user's spec) asks for as `R1`, `R2`, …, one line each,
in a **Requirements** section of `PROJECT_BRIEF.md`. Every phase, brief and gate refers to
these IDs, so "is R14 done?" can be answered with a `grep` instead of from memory.

## `ROADMAP.md`

At the repo root, **250 lines at most**. The top is an overview table. Below it is one block
per phase. The main session reads the table and the current phase's block, never the whole
file:

```markdown
# Roadmap — <project>
Source: PROJECT_BRIEF.md (R1–R42) · Architecture: ARCHITECTURE.md · Domain: DOMAIN.md

| Phase | Vertical slice — what the user can click at the end | Depends on | Gate | Status |
| --- | --- | --- | --- | --- |
| P0 | Login + roles + audit log + app shell, deployed to staging | — | A | ✅ gate passed 2026-10-02 |
| P1 | Clients & projects, with the privacy rule | P0 | B | 🔄 3/5 briefs accepted |
| P2 | Invoices → payments (F1 order-to-cash) | P1 | C | ⬜ |

## P1 — Clients & projects
Requirements: R3, R4, R7, R9
Flows: F2 client-onboarding (new)
Briefs (planned → ledger NNN once dispatched):
- [x] 012 client CRUD + policy — M — implementer
- [x] 013 client list UI — M — frontend
- [ ] project CRUD + membership — M — implementer
- [ ] privacy rule BR-04 across list/search — M — implementer
Exit: R3 R4 R7 R9 demonstrable; F2 flow test green; full suite green; audit P1 clean or accepted
Gate B asks: "Is a client visible only to its project members — including search and reports?"
```

**Reading it without reading all of it:**

```bash
sed -n '1,/^## P/p' ROADMAP.md | sed '$d'                             # the header and table
awk '/^## P1 /{on=1;print;next} /^## P/{on=0} on' ROADMAP.md            # one phase block
```

**Order phases by dependency, and make each one a vertical slice.** A usual order is:
foundation (auth, roles, tenancy, audit, shell, CI) → master data → transactions and flows →
reports → admin tools → delivery and cutover ([delivery.md](delivery.md)). Every phase ends with
something the user can **click and judge**, never "all models" or "the API layer". A phase has
at most ~8 planned briefs. Split anything bigger.

The main session keeps `ROADMAP.md` current **in the same step as the ledger line**: tick the
brief and update the Status cell. It is never updated from memory afterwards.

## Gates — the user signs off, phase by phase

When a phase's last brief is accepted, do not start the next phase. Run the gate:

1. **Bring back every worktree slice** ([integration.md](integration.md#1-bringing-a-worktree-slice-back)).
2. **The full suite and every flow test** (speed.md, flows.md). Record the counts as numbers,
   then propose the checkpoint commit ([integration.md](integration.md#2-checkpoint-commits--proposed-run-on-a-yes)).
3. **The reviewer pass**: `dispatch-reviewer` over the phase's combined diff, against
   `ARCHITECTURE.md` and `DOMAIN.md` (routing.md), with the brief below. It reports findings
   only.
4. **The audit**: `/dispatch audit P<n>` ([audit.md](audit.md)).
5. **The usage roll-up** from the ledger. See below.
6. **The gate message.** Post it, then wait for an explicit answer (below the reviewer brief).

The reviewer brief — you pick the areas the phase could have broken, one step each:

```
## Task
Review brief (planning.md): find layering, rule, permission, query, convention and test drift
across phase P<n>'s combined diff. Findings only.

## Inputs
Diff: git diff <phase's first BASE> <phase's last AFTER>   (literal shas from the ledger)
Rules: ARCHITECTURE.md → <sections>; DOMAIN.md → <BR-nn ids, Permissions rows>

## Steps
1. Read AGENTS.md, the ARCHITECTURE.md sections and DOMAIN.md rows above, then `git diff --stat`.
2. Layering: <the boundaries to check>.
3. Rule drift: <BR-nn> in every path that reads or writes it (list, search, export, API, job).
4. Permission drift: <the Permissions rows> against every new route and action.
5. Queries: N+1 and unbounded queries in <the changed list/report paths>.
6. Tests: every BR-nn or flow changed in the phase has a test.
7. Run `git status --porcelain` and confirm it is unchanged.

## Out of scope
Security (that is the audit), style, naming, code outside the diff.

## Done means
- [ ] every step has findings or "none", each finding with file:line and what breaks
- [ ] `git status --porcelain` unchanged — you wrote nothing

## Budget
About 60 tool calls. At the budget, stop and report which steps are covered.

## Report
At most 40 lines, one section per step.

[ follow the numbered steps above in order; do not plan, add, skip or reorder steps; if a step cannot be done as written, stop and report ]
```

The gate message:

```
Gate B — P1 Clients & projects
You can now: <3–6 things to click, with the URL of each>
Requirements covered: R3 R4 R7 R9 (all planned)   Not covered: none
Tests: 412/412 · flows F1 ✓ F2 ✓ · audit: 1 medium (accepted? see below) · review: 2 low
Usage: 7 dispatches, 2 rejections, critic 1×, ~3 h 10 min (budget: none set)
Open questions: <the gate question from ROADMAP, plus anything the phase raised>
Reply "pass B" to start P2, or name what to change first.
```

Only an explicit pass starts the next phase. Changes the user asks for become briefs inside
the **same** phase, and the gate runs again. Record the pass date in the Status cell, then
**suggest a fresh session** in one line ([context.md](context.md)) — a gate is the natural
handoff point — and carry on if the user does not take it.

## Usage roll-up

Every dispatch runs on Opus 5.5 at `effort: high`, so the ledger is the only measure of spend.
At each gate, count the phase's ledger lines:

```bash
awk -F' [|] ' -v from=<first NNN> -v to=<last NNN> '$1>=from && $1<=to {n++; if($8~/reject/) r++; m+=$12} END{printf "%d dispatches, %d rejections, ~%d min\n", n, r, m}' .claude/dispatch/ledger.md
```

If `PROJECT_BRIEF.md` → Constraints names a budget (hours, dispatches or a date), compare the
count with it in the gate message. A phase running more than 50 % over its share gets one line
saying so, with the round trip that caused it (speed.md). The skill never cuts effort or model
to save cost. That is the user's call.

## Changing the plan

Scope changes are the user's decision. Propose each one as a diff to `ROADMAP.md`
(and `PROJECT_BRIEF.md` if a requirement changes), and apply it on a yes. Add a phase, split one,
or move a brief. Never renumber done phases or requirement IDs. A dropped requirement is marked
`R12 — dropped <date>: <reason>`, not deleted.

## What the main session reads per cycle

The roadmap header and table plus the **current** phase block, `tail -n 20` of the ledger, and
`grep` hits in the polish index for the paths a brief will edit. Not the whole roadmap, and not the other phases' blocks. `/dispatch resume`
reads the same ([context.md](context.md#dispatch-resume)).
