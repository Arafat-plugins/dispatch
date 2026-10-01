# Responsive — clarifying and verifying UI work

Any task that designs or changes UI — a new page, a new component, a layout change, a visual
redesign — **always includes responsive behaviour**, in scope and in "Done means". Skipping it
produces work that looks right once, on the one screen it was checked at.

## Before briefing: defaults first, in one message

Before you write the steps, settle how it should look on smaller screens. **Propose, do not
interview.** Most answers have a sensible default: the project's own breakpoints, a nav pattern
`DESIGN.md` names, the collapse the file already uses, or the common pattern for that component
([speed.md](speed.md#questions--one-defaults-first-message-at-most)).

Write a default for every open point below, with a short reason for each, and post them as
**one** message: "Here is how I'll build it unless you change a line … say *go*, or correct any
line." A *go* settles all of them; a correction replaces that line and asks nothing new. Put
any other open point of the task (copy, scope) into the **same** message.

Skip any point that `AGENTS.md` or `DESIGN.md` already answers, or that the user already stated.
A small UI fix whose responsive behaviour is obvious from the file (an existing breakpoint, a
padding change) needs **no message at all**: write the defaults into the brief and say them in
the plan.

The points to cover. Most tasks need 1–3 of them, not all 5:

1. **Mobile navigation**: hamburger menu, bottom tab bar, or a horizontal row that scrolls.
2. **Column collapse**: this N-column layout on mobile stacks to 1 column, 2 columns, or a
   horizontally scrolling row.
3. **What hides or moves**: on mobile, `<element>` collapses into a drawer, moves below the main
   content, or stays visible and narrower.
4. **Images and tables**: this table on mobile scrolls horizontally, stacks rows into cards, or
   hides secondary columns.
5. **Pixel-exact widths**: whether any width must match a mock exactly. If one must, the mock is
   a reference image ([visual-reference.md](visual-reference.md)), or whether "no overflow,
   roughly right" is enough.

## The question ceiling — at most 3, across every path

**Never more than 3 questions in one task**, counting every question you ask the user from the
moment the task starts: the new-project intake ([new-project.md](new-project.md)), setup's design
points ([setup.md](setup.md), step d) and the points above. A defaults-first message counts as
one. Ask a separate question only when a point has **no** sensible default (brand colours,
which of two flows the user means) — one question per message, never batched. In Claude Code use
`AskUserQuestion` with a single question per call; elsewhere plain text.

**On reaching 3, stop asking** and proceed on your stated defaults, saying them in the plan and
the report so the user can correct them after seeing the result.

**The ceiling bounds an intake, and `/dispatch polish` is not one.** The polish session
([polish.md](polish.md)) works with the user in the loop, on what is in front of them — so **the
ceiling does not apply there**, and nothing in it is loosened for the main session by that.

## Turning answers into targets

Each answer becomes **steps** (the exact rule per breakpoint, in the file's existing media
queries) and a **Done means** line per width, in `prompt-spec.md`'s format — checkable, not
adjectived. Write the per-width target in your plan first:

```
Per width:
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
