# Responsive — clarifying and verifying UI work

Any task that designs or changes UI — a new page, a new component, a layout change, a visual
redesign — **always includes responsive behaviour**, in scope and in "Done means". Skipping it
produces work that looks right once, on the one screen it was checked at.

## Before briefing: ask, one question at a time

Before you write the brief, ask the user how it should look on smaller screens. In Claude Code,
use `AskUserQuestion` with **a single question per call**, 2-4 concrete options. Where that tool
does not exist — the `compatibility:` line promises this skill works anywhere — ask in plain
text, one question per message, same discipline. Wait for the answer, then ask the next.
**Never batch questions into one message** — a user answers the part they understand and skims
past the rest.

Skip a question that `AGENTS.md` or `DESIGN.md` already answers (an existing breakpoint table,
a stated nav pattern, a component whose responsive behaviour `DESIGN.md` → Components defines)
or that the user already stated unprompted.

Typical order — stop as soon as you have enough to write measurable targets; most tasks need
2-3 questions, not all 5:

1. **Mobile navigation** — "Nav on mobile: hamburger menu / bottom tab bar / stays horizontal
   and scrolls?"
2. **Column collapse** — "This N-column layout on mobile: stack to 1 column / 2 columns / a
   horizontally scrolling row?"
3. **What hides or moves** — "On mobile, `<element>`: collapse into a drawer / move below the
   main content / stay visible, narrower?"
4. **Images and tables** — "This table on mobile: horizontal scroll / stack rows into cards /
   hide secondary columns?"
5. **Pixel-exact widths** — "Any width here that must match a mock exactly, or is 'no overflow,
   roughly right' good enough?"

## The question ceiling — at most 8, across every path

**One question at a time, and never more than 8 questions in one flow**, counting every question
you ask the user from the moment the task starts: the new-project intake
([new-project.md](new-project.md), up to 10 suggested), setup's design questions
([setup.md](setup.md), step d, up to 3) and the 5 above. Asked end to end that is roughly twenty
messages before a single file is written, and the user stops answering long before then.

The ceiling is a hard stop, not a budget to spend. Count out loud in your plan
(`questions asked: 4/8`), skip everything `PROJECT_BRIEF.md`, `AGENTS.md`, `DESIGN.md` or the
user's own words already answer, and **stop as soon as you can write measurable targets** —
most tasks need 2-3.

**On reaching 8, stop asking and post one message**: the remaining unknowns, the default you
propose for each, and what each default commits you to. Then proceed on a single confirmation:

```
Enough to start. Still open, with what I will assume unless you say otherwise:
- <unknown>: <default>, because <one clause>
- <unknown>: <default>, because <one clause>
Say "go" and I will brief it this way, or correct any line.
```

That message is not a ninth question — it is one confirmation covering all of them. A "go" is
the answer; a correction replaces the default and still does not restart the questioning.

**The ceiling bounds an intake, and `/dispatch polish` is not one.** It counts the questions
asked *before* work starts, to a user waiting for it to start. The polish session
([polish.md](polish.md)) works with the user in the loop, on what is in front of them, and each
question follows a change they just saw — so **the ceiling does not apply there**, and nothing
in it is loosened for the main session by that. Every other path — the intake, setup's design
questions, the five above, and anything else the main session asks — counts toward the 8.

## Turning answers into targets

Each answer becomes a **Target behaviour** line in the brief, in `prompt-spec.md`'s format —
stated per width, checkable, not adjectived:

```
Target behaviour:
  <=375px: nav collapses to a hamburger menu; filters move into a drawer opened by a button.
  768px: 3-column grid becomes 2 columns; table keeps all columns, horizontal scroll allowed.
  >=1280px: unchanged from the current desktop layout.
```

"Responsive" or "works on mobile" is not a target — a width paired with an observable behaviour
is what acceptance can check against.

## Acceptance widths

Unless the project's own `DESIGN.md` or `AGENTS.md` states its breakpoints, check at minimum:

- **mobile** ~375px
- **tablet** ~768px
- **desktop** ~1280px+

Use the project's breakpoints instead of these defaults whenever `DESIGN.md` or `AGENTS.md`
names them.

**The main session checks these itself at acceptance** — with the repo's measure script,
`node .claude/dispatch/dispatch-measure.mjs <url> <width>...`, or the MCP browser that
`AGENTS.md` → *Verification capabilities* records, against every width the brief named
([acceptance.md](acceptance.md#verifying-frontend-work-yourself)). No renderer available →
report **Not verified** for each width, per width; that is a legitimate acceptance line, not
something to smooth over.

Write "Done means" widths so the script can check them as given: `no overflow at 320, 375, 768,
1280` and `.grid grid-template-columns has 1 value at 375, 3 at 1280` — a selector and a
computed property (a custom property such as `--brand` works too), not "looks right".

The frontend template (`dispatch-frontend.md`) verifies **every** width in "Done means", not
only the one reported broken, with the same script, and reports per width: `rendered with
<tool>` or `read, not rendered`.
