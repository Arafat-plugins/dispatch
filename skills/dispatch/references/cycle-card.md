# Cycle card — a routine dispatch on one page

Read this card instead of routing.md, prompt-spec.md, acceptance.md and verifier.md for a
**routine** dispatch. Open a full reference only where a line below sends you to it.
"Routine" means the repo is bootstrapped and nothing below has failed.

## 0. Plan — yours

- `tail -n 5 .claude/dispatch/ledger.md`; `grep -n -F '<each path you will brief>'
  .claude/dispatch/polish/INDEX.md` — nothing else from either directory.
- **Size it**: S / M / L, written into the plan ([speed.md](speed.md)).
- Ambiguous in a way that changes the work → **one** defaults-first message. Clear → no question.
- The user's messages that define the task: copy them, **unedited**, for *User's words* and
  *Verbatim*.
- **Model**: `model: Opus 5.5 (claude-opus-5-5)` on every Agent call.

## 1. Locate — yours, paths and lines

Surfaces table → Flows map → `grep -rn` → `git grep -n`. Read about 60 lines around each hit,
enough to write the step exactly. No scout.

## 2. Brief — numbered direct steps

Size M or L: write it to `.claude/dispatch/briefs/<NNN>-<slug>.md` first, **before** step 3's
BASE. Size S: the brief lives in the Agent prompt only.

```
## Task
<one sentence>

## User's words
<quoted exactly>

## Inputs
Files you may edit: <paths>
Page URL(s): <UI only>
Reference image(s): <image given only — visual-reference.md>

## Steps
1. In `<path>`, in `<function / selector>` (around line <N>), change <X> to <Y>.
2. <…one change per step, each naming its file>
N. Run: `<lint on changed files>` ; `<targeted tests / measure command>`. Quote the output.

## Verbatim — use exactly
<user-supplied product text, byte for byte — or delete>

## Flow
<a mapped flow step only — flows.md — or delete>

## Out of scope — do NOT
- do NOT touch <…>; do NOT survey the repo; do NOT commit; do NOT add dependencies

## Done means
- [ ] <checkable> · [ ] <Verbatim strings present> · [ ] check output quoted

## Budget
<S ~15 | M ~40 | L ~80> tool calls; at the budget, stop and report.

## Report
At most 20 lines, per step: done / not done; check output quoted.

[ follow the numbered steps above in order; do not plan, add, skip or reorder steps; if a step cannot be done as written, stop and report ]
```

First UI brief, first flow brief, first image brief, or a deps change → open responsive.md,
flows.md, visual-reference.md or dependencies.md for that one.

## 3. Baseline — print it, record it

```bash
git status --porcelain
git rev-parse HEAD                        # clean → BASE (and BASE_HEAD)
```

Dirty tree → the snapshot command in SKILL.md prints BASE. Write `BASE:` and `BASE_HEAD:` into
the plan as literals.

## 4. Dispatch

Agent from `AGENTS.md`'s role list, the model set on the call, at most 2 running at once.
Then wait; do not read along.

## 5. Accept — yours

```bash
git status --porcelain
<snapshot command>                                           # AFTER
git diff --stat <BASE> <AFTER>
git diff <BASE> <AFTER> -- . ':(exclude)*.lock' ':(exclude)package-lock.json'
git log --oneline <BASE_HEAD>^{commit}..HEAD                 # must be empty
git grep -n -F -e '<each Verbatim line>' <AFTER> -- <briefed paths>
<lint on changed files> ; <targeted tests>                   # once
```

Go through the steps and Done means line by line. A change no step asked for, unbriefed files,
large deletions, TODOs, a missing Verbatim string, or a red test → **reject** with the failing
step quoted and the corrected step written out. UI → the measure script at each width, plus
`--compare` for a reference image and open the composite. Over ~300 lines, commits, ignored
files, or anything odd → acceptance.md.

Append the ledger line.

## 6. End of task

- **Full suite**: size L only, or when the user asks. Otherwise `full suite: not run (S/M)`.
- **Verify**: only when the diff touches a security surface
  ([speed.md](speed.md#verify--only-on-a-security-surface)), once over first BASE → last AFTER;
  verifier.md. Otherwise `verify: skipped — no security surface`.
- Report `Accepted / Verified / Not verified`, plus the timing line.
- **Rotate?** Only if the conversation was compacted, or you are unsure of a BASE or verdict →
  `HANDOFF.md` and the resume block ([context.md](context.md#rotate-the-session--only-when-needed)).
