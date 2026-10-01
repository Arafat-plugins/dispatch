# dispatch — five field issues, their causes, and the 1.8.0 fixes

Reported from real use of dispatch 1.5–1.7 on large builds, 2026-09-27. Each issue below gives
**what you saw**, **why the skill caused it** (with the file responsible in 1.7.0), **what 1.8.0
changes**, the **eval** that checks it, and **what it still cannot fix**.

| # | What you saw | Main cause | Fix in 1.8.0 | New file |
| --- | --- | --- | --- | --- |
| 1 | A task takes 2–3 hours | Too many round trips per task, each justified on its own | Size every task S/M/L; defaults-first questions; targeted tests per dispatch; one critic per task; tool-call budgets | `references/speed.md` |
| 2 | Work from an image reference is never quite exact | The sub-agent never saw the image, and nothing compared the result to it | Image saved in the repo and named in the brief; the agent writes a reference spec; `--compare` makes a reference / render / diff composite | `references/visual-reference.md`, `dispatch-measure.mjs --compare` |
| 3 | Backend workflows break badly | Flows were split by layer across dispatches; no contract between steps; no flow tests | A flow map in `AGENTS.md`; a **Flow** section in briefs; one vertical slice per step; flow tests that fail at BASE; a flow check at acceptance | `references/flows.md` |
| 4 | The main session fills up, then hallucinates | Every reference and diff stayed in context; the plan lived only in the conversation; the session never ended | The fact rule; briefs on disk; a ledger; a cycle card; rotation with `HANDOFF.md`; `/dispatch resume` | `references/context.md`, `references/cycle-card.md` |
| 5 | Text I wrote gets reworded | The main session paraphrased the request; nothing carried product text verbatim; nothing checked it | *User's words* and *Verbatim* brief sections; an agent rule; `git grep -F` at acceptance, where a rewording is a rejection | changes to `prompt-spec.md`, `acceptance.md` and both worker agents |

---

## 1. A task takes 2–3 hours

**What you saw.** Assigning a task, even a small one, took two to three hours before it came
back accepted.

**Why.** No single step was slow. The skill added round trips, each sensible alone:

| Round trip | Source in 1.7.0 |
| --- | --- |
| Up to 8 questions, one per message, each waiting on you | `responsive.md`, `new-project.md` ("one question at a time", "never batch") |
| A scout sub-agent just to find files | `SKILL.md` LOCATE |
| The worker ran the **full** test suite (bootstrap allows 10 minutes) | `dispatch-implementer.md` "Run what AGENTS.md lists for lint and test" |
| Acceptance ran the full suite again | `acceptance.md` "The check" |
| The security critic ran after **every** dispatch, CSS included | `SKILL.md` step 6 |
| Backend work split by layer into 2–4 dispatches, run in sequence | `routing.md` "One job per dispatch" |
| Up to 3 attempts, each repeating all of the above | `failures.md` |

Every sub-agent is Opus 5.5 at `effort: high` (1.7.0), so each extra run costs real minutes.

**What 1.8.0 changes.**
- **Size first** (`speed.md`). S, M or L goes in the plan and sets the questions, scout, tests,
  critic and budget. An S task gets no scout, one dispatch, targeted tests and a budget of about
  25 tool calls.
- **Defaults-first questions** (`responsive.md`, `new-project.md`). The main session proposes a
  default for every open point and asks once: *go, or correct any line.* That counts as one
  question. It asks one at a time only where no default fits. Batching stays forbidden.
- **Tests: targeted per dispatch, full once per task.** `AGENTS.md` now has *Test (targeted)*
  and *Test (full)* rows (`bootstrap.md`). The implementer runs targeted tests (its template
  says so), and the full suite runs once after the last dispatch.
- **Verify once per task** (`verifier.md`). One critic run over the whole task's diff. It is
  skipped, and said, when only stylesheets, images or docs changed. Templates, config and copy in
  code still get it. It is still Opus 5.5 whenever it runs.
- **One slice, one dispatch** (`routing.md`, `flows.md`). A backend flow step, all layers, goes
  to one implementer run instead of one per layer.
- **Budgets** (`prompt-spec.md`). Every brief caps tool calls (~25 / 60 / 120). An agent at its
  budget stops and reports, and `failures.md` case 3 treats that as a question, not a failure.
- **Timing in the ledger** (`context.md`). Each task ends with
  `N dispatches, N rejections, critic N×, full suite N× — N min`, so slow tasks show which round
  trip is to blame.

**Eval:** `evals/small-task-fast-lane.md`, `evals/design-responsive-defaults-first.md`.

**Still cannot fix.** A slow test suite or dev server is the repo's own cost. Opus 5.5 at
`effort: high` is your setting; lowering `effort:` for S tasks is a lever only you can pull.

---

## 2. Work from an image reference is never quite exact

**What you saw.** You gave an image and asked for the design to match it. The result came back
close but never exact.

**Why.**
1. **The sub-agent never saw the image.** A brief is text. A pasted image stays in the main
   session, and the frontend agent built from the main session's *description*. Every unnamed
   spacing, weight and colour was guessed.
2. **Nothing compared the result to the image.** `dispatch-measure.mjs` measured overflow and
   one computed property, nothing visual.
3. **`DESIGN.md` silently won.** The frontend agent snaps to tokens. Mock values that were not
   tokens drifted toward the design system, and nobody had decided that they should.

**What 1.8.0 changes.**
- **The image becomes a file**: `.claude/dispatch/refs/<NNN>-<slug>/<width>.png`, named in the
  brief's new **Reference image(s)** line with the width to compare at and
  `Fidelity: exact | close`. A pasted image the main session cannot write to disk: it asks you
  once to save it at that path (`visual-reference.md` §1).
- **One conflict question** when the mock uses values `DESIGN.md` lacks: match the mock and add
  them as tokens, or keep the tokens (§2).
- **The agent opens the image** (`dispatch-frontend.md` → *Reference images*). Phase 1 is a
  reference spec table measured from the image's pixels, and it builds from that table.
- **A real comparison.** `dispatch-measure.mjs` gains `--shot <dir>` (a full-page PNG per
  width) and `--compare <image>`. The reference is scaled to the width (a 2x mock works),
  compared pixel by pixel, and written out as a **reference | render | diff** composite with
  red where they differ, plus a `% differ` figure. The agent does up to 3 compare passes and
  reports the trend (`38% → 12% → 4%`).
- **Acceptance opens the same composite.** Structural red (a missing block, a different order or
  size) is rejected with the region quoted. Content red (real data, real photos) is accepted and
  said. The percentage is a trend, never the pass mark.

Tested in this release: an identical page compares at **0.1%** (text scaling only), a page with
a changed colour and padding at **42%**, with both the Node and Python Playwright renderers.

**Eval:** `evals/image-reference-compared.md`.

**Still cannot fix.** Without a renderer (`Rendering: none`) the comparison cannot run, and every
width is reported *Not verified*. Missing fonts or assets always show as red, which is why a
person judges the composite.

---

## 3. Backend workflows break badly

**What you saw** (you chose *flows break end to end*). Each piece passed on its own, but the
joined workflow (order → invoice → payment, request → approval → balance) failed.

**Why.**
1. **Flows were split by layer.** "One job per dispatch" (`routing.md`) led to the model, the
   service and the handler going to separate dispatches. The handoff between them belonged to
   nobody.
2. **No contract between steps.** No brief said what the previous step hands over or what the
   next step expects, so each agent inferred it from the one file it had.
3. **Tests were optional.** The implementer *ran* the listed tests. Nothing asked it to *write*
   a test driving the flow through its step.
4. **Acceptance judged the diff, not the behaviour.**
5. **No regression net.** A new step that changed a shared status broke a flow accepted three
   dispatches earlier, unseen.

**What 1.8.0 changes.**
- **Flow map** in `AGENTS.md` → **Flows**, at most 8 lines per flow: trigger, steps, states,
  invariants, test command (`flows.md`, `bootstrap.md`).
- **The brief's Flow section**, copied from the map: the step changed, the In/Out contract, the
  invariants, and "do NOT change what the previous step hands over or what the next step listens
  for".
- **One vertical slice per step** (`routing.md`). Migration, model, service, handler, validation,
  wiring and test go to **one** implementer. Two steps of one flow are never dispatched in
  parallel.
- **Flow tests are required.** Done means asks for a test that drives the flow through the step
  end to end, with a new assertion that **fails at BASE and passes at AFTER**. The implementer
  writes the test first (`dispatch-implementer.md` → *Flows*).
- **The flow check at acceptance** (`acceptance.md`). It runs every touched flow's test plus the
  flows accepted earlier in the task. A red flow test is a rejection. All flow tests and the full
  suite run once at the end of the task.
- **The critic asks about transitions** (`verifier.md`): step skipping, replay and double
  submit, a transition without a permission check, races.

**Eval:** `evals/backend-flow-step-one-slice.md`.

**Still cannot fix.** A flow missing from the map gets no protection, so bootstrap writes one
block per workflow a user would name, and a flow without a test is marked as a gap. Business
rules that are wrong in the spec stay wrong. That is the architecture and domain gap (G4) in
`docs/GAP-ANALYSIS-big-projects.md`.

---

## 4. The main session fills up, then hallucinates

**What you saw.** Over a long build the main session's context became huge. It then stated
things that were not true: shas, what was accepted, what a brief said.

**Why.**
1. The skill's own reading was about 1,100 lines of references before the first dispatch, often
   re-opened.
2. Every acceptance diff (up to ~300 lines) stayed in context.
3. BASE, AFTER, the brief and the attempt count lived only in the conversation. Auto-compaction
   kept "BASE was recorded" and dropped the sha, so the model filled the gap.
4. Every sub-agent report (up to 40 lines) stayed.
5. Nothing ended the session. One session was expected to carry a whole build.
6. Nothing forbade claims made from memory.

**What 1.8.0 changes** (`context.md`, `cycle-card.md`).
- **The fact rule**, stated in `SKILL.md`. Every statement about the repo must come from this
  cycle's command output, diff, brief file or ledger. Anything else is *unknown — checking*, then
  the command. After a compaction, every sha in the summary counts as unknown.
- **Briefs on disk**: `.claude/dispatch/briefs/<NNN>-<slug>.md`. Rejections edit the file, and
  acceptance reads Done means from it, not from memory.
- **The ledger**: `.claude/dispatch/ledger.md`, one line per outcome with BASE, AFTER, verdict,
  attempt, tests, verify and minutes. Only its tail is read.
- **The cycle card**: one page for a routine dispatch instead of four references. Full
  references open only on an exception.
- **Less diff**: acceptance leaves lockfiles, generated files and snapshots out of what it reads.
- **Rotation**: after about 8 accepted dispatches, a finished size-L task or phase, or any
  compaction, the session writes `HANDOFF.md` (at most 30 lines), prints a resume block and
  stops. The fresh session runs **`/dispatch resume`**, reads only the handoff, the ledger tail,
  the open brief and the indexes, and checks `HEAD` against the recorded BASE_HEAD.
- `status` reports a pending handoff first.

**Eval:** `evals/session-rotates-and-resumes.md`.

**Still cannot fix.** The skill cannot measure its own context size. The rotation triggers are
proxies (dispatch count, phase end, compaction). Rotate earlier by saying so; the handoff works
at any point.

---

## 5. Text I wrote gets reworded

**What you saw** (you chose *ignores my wording*). Text you supplied (labels, headings,
messages, copy) came back rewritten or "improved" instead of used as written.

**Why.**
1. **The main session paraphrased.** The brief's Task line is the main session's summary. The
   sub-agent never saw your words, only the summary, and the main session's own reading slipped
   in.
2. **No verbatim channel.** The brief template had no place for text that must not change, so
   product copy sat inside prose where it looked like a suggestion.
3. **Agents "improve".** Nothing told the implementer or frontend agent that supplied text is
   final, so both fixed grammar, casing and length.
4. **Nothing checked it.** Acceptance compared the diff with Done means, and no line there
   said "this exact string".

**What 1.8.0 changes.**
- **User's words** (`prompt-spec.md`): the request is quoted unedited at the top of every brief.
  Where your words and the main session's Task line differ, your words win.
- **Verbatim — use exactly**: every piece of product text you supplied, each in its own fenced
  block, byte for byte. If the main session thinks there is a mistake, it asks you before the
  brief and never corrects it silently (rule 5).
- **Both worker agents** (`dispatch-implementer.md`, `dispatch-frontend.md` → *Verbatim text*)
  treat it as final: no rewording, no case, punctuation or typo fixes, no translation, no
  shortening. If it does not fit, the agent stops and reports. Text read off an image is used
  only when it is in Verbatim.
- **Mechanical acceptance** (`acceptance.md` → *Verbatim text*):
  `git grep -n -F -e '<line>' <AFTER> -- <paths>` for every line. A missing or reworded string is
  a rejection that quotes both versions. Escaped forms (`&mdash;`, `\'`) are searched as escaped,
  and the verdict says so.
- A **non-negotiable** in `SKILL.md`: your words reach the sub-agent unedited, and the result
  carries them exactly.

**Eval:** `evals/verbatim-text-kept-exact.md`.

**Still cannot fix.** Text you did not write, such as placeholder copy the agent had to invent,
has no Verbatim to hold it to. If wording matters there, give the text or ask for a list of
invented strings in the report.

---

## How the release was checked

- `bash scripts/validate.sh` passes. The new **check 32** fails if any half of these five fixes
  is removed later: the reference, the agent rule, the brief section or the acceptance check.
- `node --test scripts/measure.test.mjs`: 18 tests pass, 4 of them new (for `--shot`,
  `--compare`, `shotName`, `pixelDiff` and output lines).
- `--shot` and `--compare` were run end to end against a live page with the Node and Python
  Playwright renderers: an identical page gives 0.1%, a changed one 42%, and the composite was
  inspected.
- An independent read-only review (a separate Opus 5.5 agent) checked the release for
  contradictions and broken commands. Nine of its findings were fixed before the commit:
  - The per-slice critic wording was made consistent with once per task.
  - Stale "one-question-at-a-time" labels were removed.
  - The cycle card's brief was missing *Audience* and *Format*.
  - The worked example had no *User's words*.
  - Bookkeeping under `.claude/dispatch/` was showing up in acceptance diffs. Fixed with
    brief-before-BASE, ledger-after-AFTER and a one-line check.
  - Merging worktree slices back before the end-of-task verify was not described.
  - It was unclear how acceptance can see "fails at BASE". It now uses the agent's quoted
    test-first run.
  - Test-first now applies to every logic brief, not only flow briefs.
  - The Python renderer received the reference image as one argument, which fails above
    128 KB (E2BIG). It now receives the path. Re-tested with a 0.9 MB reference on both
    renderers.
- Six scenario evals were added or rewritten. As before, they are run by hand or with a
  skill-eval harness.
