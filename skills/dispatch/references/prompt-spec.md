# The Spec — how a dispatch brief is assembled

A brief is a set of **direct instructions**, not a request. The main session has already done
the planning: it decided what changes, found the spot, and wrote each change down as a numbered
step. The sub-agent has no memory of the conversation and no say in the plan. It reads the
steps, executes them in order, runs the check, and reports. Everything it needs is in the brief
or it does not exist.

## Who does what

| Main session (you) | Sub-agent |
| --- | --- |
| sizes the task, settles questions with the user | — |
| locates files and lines (`grep -n`, a ≤ 60-line read around each hit) | reads the files the steps name |
| writes every step: file, place, exact change | executes the steps, in order, as written |
| writes Done means and the check commands | runs the check commands, quotes the output |
| judges the diff — accept or reject | reports per step; never judges its own work |

If you cannot write a step precisely — you do not know which function, which selector, which
value — you have not finished planning. Run another `grep -n`, read the lines around the hit, or
ask the user. Do not hand the uncertainty to the sub-agent as "figure out where".

## Template

```
## Task
<one sentence: the observable change you want>

## User's words
<the user's request, quoted exactly as they wrote it — every message that defines this task.
Where your steps and these words differ, these words win — stop and report.>

## Inputs
Files you may edit:
  - <exact/path/one>
  - <exact/path/two>
Page URL(s):
  <UI briefs only: the dev-server URL from AGENTS.md → Verification capabilities + the path of
  each page to measure, e.g. http://localhost:5173/catalog; not UI → delete this line>
Reference image(s):
  <only when the user gave an image: repo path → the width to compare at, and
  Fidelity: exact | close — see visual-reference.md; otherwise delete this line>

## Steps
1. In `<path>`, in `<function / selector / block>` (around line <N>), change <exact current
   thing> to <exact new thing>.
2. In `<path>`, after `<anchor line>`, add <exact thing>.
3. <…one change per step; every step names its file>
N. Run: `<lint on changed files>` and `<targeted test / measure command>`. Quote the output.

## Verbatim — use exactly
<every piece of text the user supplied for the product — labels, headings, messages, emails,
error strings, names — each in its own fenced block, copied byte for byte from their message.
None → delete this section.>

## Flow
<only when a step touches a step of a flow in AGENTS.md → Flows: the In / Out contract and
invariants, copied from the map — see flows.md; otherwise delete this section>

## Out of scope — do NOT
- do NOT touch <files/areas>
- do NOT refactor, rename or reformat anything a step does not name
- do NOT survey the repository; read AGENTS.md, then only the files named above
- do NOT commit, push, or change git state
- do NOT add dependencies

## Done means
- [ ] <checkable condition>
- [ ] <checkable condition>
- [ ] <Verbatim present: each string appears exactly, where named>
- [ ] the check commands in the last step ran, output quoted

## Budget
<S: ~15 tool calls · M: ~40 · L: ~80 (speed.md). At the budget, stop and report which steps are
done and which are left — do not keep going.>

## Report
At most 20 lines. Per step: `done` or `not done — <why>`. Then the check output, quoted short.

[ follow the numbered steps above in order; do not plan, add, skip or reorder steps; if a step cannot be done as written, stop and report ]
```

Add **Audience** (what consumes the code, the contract to keep) and **Format** (the file's
conventions, `DESIGN.md` components by name) sections only when the steps alone do not make them
obvious — a public class-name contract, a layer rule, an escaping rule.

## The six rules

**1. Steps are direct and complete.** Each step names one file and one change, concretely:
"in `assets/css/catalog.css`, in `.grid` inside `@media (max-width: 620px)`, set
`grid-template-columns: 1fr`". Not "make the grid responsive". The agent adds no step of its own;
a change that no step names is scope creep at acceptance.

**2. Inputs are paths, not descriptions.** If you cannot name the file, you have not finished
locating — run the grep yourself. There is no scout.

**3. Read just enough to write the step.** `grep -n` finds the line; read about 60 lines around
it (`Read` with offset/limit, or `sed -n '<from>,<to>p'`) to get the selector, the function
name, the current value. Never read the whole file to plan — that is the cost this skill avoids.
A step that needs more than that is a sign the task is size M or L; split it.

**4. Out of scope is where briefs earn their keep.** Name the adjacent things the agent will be
tempted by.

**5. "Done means" is the acceptance test, written before the work.** If you cannot write a
checkable list, the task is not ready to dispatch.

**6. The user's words travel unedited.** **User's words** carries the request itself, so the
sub-agent sees what the user asked and not only your steps. **Verbatim** carries every piece of
product text the user wrote, byte for byte — no "improving", no fixing grammar or capitalisation,
no translating, no shortening. If you think their text has a mistake, ask them before the brief;
never correct it silently. Acceptance checks each Verbatim string mechanically
([acceptance.md](acceptance.md#verbatim-text)).

**And one cap: the report is ≤ 20 lines.** You read the diff anyway; a long report is the same
content twice, in the context you are protecting.

## Worked example

Vague ask: *"make this CSS perfect for all devices"*. You grep the grid, read 50 lines around
it, see the inline `--columns` property and the file's existing 900px / 620px breakpoints, and
write:

```
## Task
Make the product card grid lay out correctly from 320px to 1440px.

## User's words
"make this CSS perfect for all devices"

## Inputs
Files you may edit:
  - assets/css/catalog-discovery.css
Page URL(s):
  http://marketkit.local/shop/

## Steps
1. In `assets/css/catalog-discovery.css`, in `.catalog-grid` (around line 42), replace
   `grid-template-columns: repeat(var(--columns), 1fr);` with
   `grid-template-columns: repeat(3, minmax(0, 1fr));`.
2. In the same file, inside the existing `@media (max-width: 900px)` block (around line 118),
   add `.catalog-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }`.
3. In the same file, inside the existing `@media (max-width: 620px)` block (around line 131),
   add `.catalog-grid { grid-template-columns: minmax(0, 1fr); }`.
4. Run: `node .claude/dispatch/dispatch-measure.mjs http://marketkit.local/shop/ 320 375 620 768 900 1024 1440 --select .catalog-grid --prop grid-template-columns`. Quote the output.

## Out of scope — do NOT
- do NOT edit any other stylesheet, PHP, templates or markup
- do NOT rename or add class names; do NOT add breakpoints
- do NOT survey the repository; read AGENTS.md, then only the file named above
- do NOT commit or push

## Done means
- [ ] no horizontal overflow at 320, 375, 620, 900, 1024, 1440
- [ ] .catalog-grid grid-template-columns has 1 value at 375, 2 at 768, 3 at 1024
- [ ] no class name or DOM change
- [ ] the measure output in step 4 is quoted

## Budget
S — about 15 tool calls. At the budget, stop and report which steps are done.

## Report
At most 20 lines. Per step: done / not done. Then the measure lines.

[ follow the numbered steps above in order; do not plan, add, skip or reorder steps; if a step cannot be done as written, stop and report ]
```

Note what happened: the vague ask became exact edits **before** dispatch. That conversion is the
planner's job — yours — and it is most of the value of this skill.

## The footer

The last line is always, verbatim:

```
[ follow the numbered steps above in order; do not plan, add, skip or reorder steps; if a step cannot be done as written, stop and report ]
```

Last position matters — it is the final instruction read. It tells the sub-agent the planning is
already done. **What the sub-agent does with it:** executes step 1, then step 2, and so on;
writes no plan of its own; reports per step. If a step cannot be done as written — the anchor
line is not there, the value differs, the change would break something it can see — it stops at
that step and reports what it found. It does not improvise a different change. That stop is not
a failure; you fix the step and re-dispatch (failures.md, case 3).

For a read-only brief (critic, db-tester, reviewer) the steps are the checks to run, one per
step: the command or the area, then the judgement.

## Large tasks

A task too big to write as ≤ ~12 direct steps is size M or L. Split it into several briefs,
each with its own steps, planned up front by you (speed.md). The sub-agent never receives a task
it has to break down itself.

## Cross-cutting checks

`AGENTS.md` → **Cross-cutting checks** lists checks such as accessibility or i18n. Copy only the
lines that apply to this brief into the last step and Done means, **with their command**.

## Briefs that change the map

A task that adds or removes a route, page, flow step, command or module has a step that adds
the `AGENTS.md` row, written out, and Done means says "AGENTS.md row added as stated; nothing
else in it edited" — **[integration.md](integration.md#3-keeping-agentsmd-current--map-upkeep-in-the-brief)**.
Rules from `ARCHITECTURE.md` / `DOMAIN.md` are cited by section and ID, never re-described —
**[architecture.md](architecture.md#in-briefs)**.

## Backend briefs

A brief that touches a step of a flow in `AGENTS.md` → **Flows** carries the **Flow** section.
One flow step, all layers, is one brief to one agent — **[flows.md](flows.md)**.

## Design and UI briefs

A UI brief carries responsive Done means per width — see **[responsive.md](responsive.md)** —
and the **Page URL(s)** line, which the frontend agent and your own acceptance both measure. When
the repo has a `DESIGN.md`, steps use its tokens and components by name; a change that needs a
new token is a step that edits `DESIGN.md` first. When the user gave an **image to match**, it
goes into the repo and onto the **Reference image(s)** line, and the agent compares its render
against it — **[visual-reference.md](visual-reference.md)**.
