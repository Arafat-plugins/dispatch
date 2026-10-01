# Speed — sizing a task so it finishes in minutes, not hours

A small task that takes an hour through dispatch almost never has one slow step. It has many
round trips, each justified on its own, and every one of them is a separate Opus 5.5 run at
`effort: high`. Up to 1.9.0 a "simple" task still went through:

| Round trip | Where it came from (≤ 1.9.0) |
| --- | --- |
| reading 3–5 references before the first brief | SKILL.md, cycle card, speed, prompt-spec, responsive |
| one-at-a-time questions, up to 8 | responsive.md, new-project.md |
| a scout sub-agent to find files | SKILL.md, LOCATE |
| the sub-agent planning its own phases before the first edit, and reporting per phase | the footer |
| test-first for every logic brief (write the test, show it red, then green) | prompt-spec.md, implementer |
| the full suite once per task, S included | speed.md, SKILL.md step 6 |
| the security critic once per task, unless only CSS/images/docs changed | verifier.md |
| up to 3 attempts, each repeating all of the above | failures.md |

2.0.0 removes the round trips that do not pay for themselves. The model and effort stay the
user's choice; the fix is **fewer runs and less thinking per run**: the main session plans once,
and the sub-agent only executes.

## Size every task first — S, M or L

Put the size in the plan (`size: S`) before LOCATE. It decides the ceremony:

| | **S** — small | **M** — medium | **L** — large |
| --- | --- | --- | --- |
| Looks like | one surface or one step, ≤ 3 files, a known pattern | one feature slice, ≤ ~8 files | a new module, a new flow, cross-cutting |
| Questions before the brief | 0, or one defaults-first message | one defaults-first message | one defaults-first message, then at most 2 more |
| Steps in a brief | ≤ ~6 | ≤ ~12 per brief | ≤ ~12 per brief, several briefs planned up front |
| Dispatches | 1 | 1 per surface or flow step | 1 per slice |
| Brief on disk / ledger | ledger line only | brief file + ledger | brief file + ledger |
| Tests | targeted, in the last step; you re-run them once | same | same |
| Full suite | not run | not run | once, at the end of the task |
| Critic | only on a security surface | only on a security surface | only on a security surface |
| Budget | ~15 tool calls | ~40 | ~80 |

A task that grows past its size while you plan is **re-sized, and the user is told** in one line.
A ≤ ~10-line correction you already hold is not a dispatch at all
([when-not-to-dispatch.md](when-not-to-dispatch.md)).

**What an S task should cost:** one short plan, one or two `grep -n` reads, one brief, one
sub-agent run that executes ≤ 6 steps, one acceptance pass. About 5–10 minutes, plus the repo's
own test and render time.

## Questions — one defaults-first message, at most

Do not ask what you can propose. **Write your default for every open point and ask once**:

```
Before I brief it — here is how I'll build it unless you change a line:
- Mobile nav: hamburger at ≤ 768px (DESIGN.md has no nav pattern)
- 3-column grid → 1 column ≤ 620px, 2 up to 900px (the file's existing breakpoints)
- Table on mobile: horizontal scroll
Say "go", or correct any line.
```

That is **one** question. Ask a separate question only when there is no sensible default, such
as brand colours or which of two flows the user means — at most **3 questions per task, across
every path** ([responsive.md](responsive.md#the-question-ceiling--at-most-3-across-every-path)).
A clear request needs none: brief it.

## Locate yourself — no scout

In order: the Surfaces table, the Flows map, one `grep -rn`, one `git grep -n`. Then read about
60 lines around each hit — enough to write the step exactly. There is no scout sub-agent:
finding the spot is planning, and planning is the main session's job. Grep returns 8+ candidates
and none is obviously the owner → the task is not S; ask the user, or read the `AGENTS.md` row
again.

## No planning in the sub-agent

The footer used to make every sub-agent write its own phase plan before the first edit and
report per phase. That was a second planning pass, by a model with less context than yours,
on every dispatch. Now the brief **is** the plan: numbered steps the agent executes in order
(prompt-spec.md). The agent's thinking goes into making each edit correctly, not into deciding
what to edit.

## Tests — targeted, once each side

- **In the dispatch**, the last step runs lint on the changed files and the targeted tests (and
  the measure script for UI). The agent quotes the output.
- **At acceptance** you run the same targeted commands once. Playwright measuring stays on both
  sides for UI.
- **Test-first** (write the test, show it red at BASE, then green) only when a step asks for it —
  a bug fix with a reproducible failure, or a flow step whose flow test exists. Not by default.
- **Full suite**: size L only, after the last dispatch — or whenever the user asks. S and M say
  `full suite: not run (S/M)` in the report. A red test there that is not in the known-failing
  baseline → find the dispatch with `git diff --stat` per ledger entry and re-dispatch that one
  brief with the failure quoted.

## Verify — only on a security surface

Run the critic once, over the task's combined diff, **only** when it touches a security
surface: authentication, sessions, permissions, payments, secrets or credentials, user input
handling (forms, uploads, parsing), raw queries, data writes or deletes, CORS / headers.
Otherwise write `verify: skipped — no security surface (<N> files)` in the report. The user can
always run `/dispatch verify`. Deps briefs keep their own narrow verify
([dependencies.md](dependencies.md)). The critic is still Opus 5.5 whenever it runs.

## Budgets — stop runaway agents

Every brief carries a **Budget** line: about 15 / 40 / 80 tool calls for S / M / L. An agent at
its budget stops and reports which steps are done. That is not a failure (failures.md, case 3):
re-dispatch the remaining steps as their own brief.

## Parallel where it is safe

Two briefs with disjoint files and **no shared flow** can run at once in separate worktrees,
within the cap of 2 (routing.md). Bring an accepted worktree slice back before the next slice
that needs it ([integration.md](integration.md#1-bringing-a-worktree-slice-back)).

## What to report

End each task with one timing line in the ledger and the report:
`task 007: 1 dispatch, 0 rejections, critic skipped, full suite not run — 8 min`. When tasks
keep landing over 20 minutes, the ledger shows which round trip is to blame.
