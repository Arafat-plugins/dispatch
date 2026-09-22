# Polish — the second session

After an accepted change there is usually light polish left: spacing that is almost right, a
message that reads wrong, an edge case nobody briefed. Doing the build **and** the polish in one
session fills that session's context with detail it does not need, and a session full of detail
it does not need hallucinates.

So polish happens in a **second, separate Claude session**, in the same repo. The main session
learns what happened there from **one index line per run** — a title, a summary of at most two
lines, and the paths or surfaces it touched.

## Which session are you?

Both sessions load the same `SKILL.md`, so decide this before anything else — it changes which
rules bind you.

- **The invocation was `/dispatch polish [<NNN>|<what>]`** → you are the **polish session**. Go
  to "The polish session" below. That section, and this file, are your rules.
- **Anything else** — `/dispatch <task>`, `deps`, `verify`, `db`, `bootstrap`, `setup`, `new`,
  `status`, or no argument → you are the **main session**. The reading rule and the handoff
  below are yours; you do not polish.

**In the polish session, this file replaces four of `SKILL.md`'s non-negotiables** — the ones
scoped "main session" there:

| `SKILL.md` non-negotiable | In the polish session |
| --- | --- |
| read `INDEX.md` and nothing else from that directory | you read and write that whole directory, `requests/` included — it is your workspace |
| never polish here, never dispatch polish | polishing **is** the job; you still dispatch nothing |
| never more than 2 sub-agents at once | you run none at all |
| never let a sub-agent decide *what* and *whether it worked* | no sub-agents; the user decides both, with you |

**Every other non-negotiable still binds you**: never commit, never push, never auto-fix a
finding, never edit `AGENTS.md`, and the baseline-and-diff discipline below. The 8-question
ceiling does not apply here either — see "Working with the user".

## Layout

Bootstrap creates both directories and seeds the index (bootstrap.md, Step 3):

| Path | Who writes it | Who reads it |
| --- | --- | --- |
| `.claude/dispatch/polish/INDEX.md` | the polish session | the main session, every dispatch |
| `.claude/dispatch/polish/<NNN>-<slug>.md` | the polish session | the main session, at most one, on a reason |
| `.claude/dispatch/polish/requests/<NNN>-<slug>.md` | the main session | the polish session, the named one |

**`INDEX.md` is the ledger.** One entry per polish run, and each entry is exactly four things:
a heading line, a `summary:` of **at most two lines**, a one-line `touches:`, and the note's
path. Nothing else belongs in this file — no rationale, no code, no prose beyond those lines.
It is the only polish file the main session ever reads, and it stays cheap because of that.

**`touches:` is what the reading rule matches on**, so it is bounded, not a file list: **at most
five** comma-separated items on **one line**, each either a repo path or a surface name
(`checkout.css, cart summary card`). More than five → name the surface instead of its files, and
if it still will not fit, end with `+N more` and the full set stays in the note's `files:`
frontmatter. A `touches:` line that needs to wrap is the same signal as a three-line summary:
the polish was two polishes.

**The note** is the full explanation. It is written once, by the polish session, and read by a
human or by a main session that has a specific reason to open it.

**The request** is the handoff brief. The main session writes it and never reads it back.

## The main session's reading rule

This is the point of the feature. It is a non-negotiable, not a preference.

- **Before planning any dispatch** — `<task>`, `deps`, `verify`, `db` — read
  `.claude/dispatch/polish/INDEX.md` and **nothing else** from that directory. Titles,
  two-line summaries and `touches:` lines are all you are allowed to hold.

  ```bash
  cat .claude/dispatch/polish/INDEX.md 2>/dev/null
  ```

- **A long index is read through a window, not whole.** The index grows by four lines per
  polish, so past ~40 entries `cat` is no longer cheap. This prints everything above the first
  entry plus the **40 most recent** entries, in one pass, and is safe on a short index too:

  ```bash
  awk '/^### /{n++} {L[NR]=$0; k[NR]=n} END{for(i=1;i<=NR;i++) if(k[i]==0 || k[i]>n-40) print L[i]}' \
    .claude/dispatch/polish/INDEX.md 2>/dev/null
  ```

  The older entries are still reachable without reading the file: `grep '^### ' INDEX.md` lists
  every heading and nothing else, and a heading gives you the number. Only go back for one when
  a heading names what this brief touches.

- **Open exactly one full note**, and only when a title, a summary or a `touches:` item names a
  file, a surface or a behaviour the current brief touches, or the user points you at it. Name
  in the plan which note you opened and why (`opened 007 — touches: checkout.css, which this
  brief edits`). The note's own path is on its `note:` line; for an entry that has been folded
  (below), find it by number:

  ```bash
  find .claude/dispatch/polish -maxdepth 1 -name '007-*.md'
  ```
- **Never open a note "to be safe."** Never open more than one without saying why in the plan.
  **Never read `requests/`** — those are your own outgoing briefs; reading them back is the
  context you sent away coming home.
- **No `INDEX.md`** — polish has never run here. Carry on silently; do not create it, do not
  mention it.
- **Never edit the index.** The polish session owns it, including its hygiene.

A summary and a `touches:` that are still not enough to decide with are not a reason to open the
note — they are a reason to ask the user.

## Index hygiene

Owned by the polish session, done when it appends. **No note file is ever deleted, and no number
is ever reused or renumbered** — hygiene compacts the *index*, never the notes.

- A note **fully superseded** by a later one keeps its entry and its heading gains
  `— superseded by <NNN>`.
- **Past 40 entries**, fold the superseded entries into one heading
  (`### 004, 009, 011-013 — superseded, see 021`). Folding **drops those entries' `summary:`,
  `touches:` and `note:` lines** — that is the point of it, and it is the only thing hygiene
  removes. Every number stays on the heading, and the notes stay on disk; the main session
  reaches one by number with the `find` above.
- **Non-superseded entries are never folded**, so the index still grows. That is what the main
  session's 40-entry window is for: the polish session keeps appending, and the reader bounds
  what it holds. Do not compact live entries to make the file shorter — a summary the main
  session cannot decide from costs it a whole note.

## The next free number — both sessions

Zero-padded, 3 digits, derived from what is already on disk. The main session needs it to name a
request; the polish session needs it to name a note. One command, one counter:

```bash
n=$( { find .claude/dispatch/polish -maxdepth 2 -name '[0-9][0-9][0-9]-*.md' -exec basename {} \; ; echo 000-; } \
     | cut -c1-3 | sort -n | tail -1 )
printf '%03d\n' "$((10#$n + 1))"       # 10# so 008 is eight, not an invalid octal
```

It scans notes and requests together, so a number is never reused by either. The polish session
called as `/dispatch polish <NNN>` on an existing request skips this: the note takes that same
number.

## Handing off — the main session never polishes

When an accepted change still needs polish, or the user asks for polish, you do **not** do it,
and you do **not** dispatch a sub-agent for it. A sub-agent shares your plan and reports back
into your context — that is an *isolated* context, and the point here is a *separate* one.

**Polish, or the ≤5-line direct edit?** Both are small; they are not the same job, and line
count does not separate them. The question is whether there is one right answer you already
hold:

| The ask | Side | Why |
| --- | --- | --- |
| "the empty state says `recieve`" | **direct edit** ([when-not-to-dispatch.md](when-not-to-dispatch.md)) | one right answer, no judgement, nothing to look at |
| a wrong constant, a stale version string, a mislabelled field | **direct edit** | same — the correct value is stated or obvious |
| "the empty state copy reads badly" | **polish** | no stated target; the right wording is found by writing one and showing it |
| "the spacing is almost right", "this reads wrong", "it feels cramped" | **polish** | taste, judged by looking, settled with the user in the loop |

So: **a correction is a direct edit; a judgement call is polish**, however few lines it comes to.
If the user has to see it to say yes, it is polish. If you would have to iterate with them on
the wording or the value, it is polish — handing that to yourself is how the main session fills
with the detail this whole file exists to keep out.

**Once it is polish, hand it off in three steps:**

1. Write `.claude/dispatch/polish/requests/<NNN>-<slug>.md` with the next free `NNN` — the
   command is in **[The next free number](#the-next-free-number--both-sessions)**, just above:

   ```markdown
   # Polish request <NNN> — <title>

   ## What was just built
   <one paragraph: the change that landed, and how it was accepted>

   ## Files involved
   - `<path>` — <what it does in this change>

   ## What polish means here
   - <the specific rough edge, observable>
   - <the next one>

   ## What must not change
   - <contract, behaviour, or file that is settled and stays settled>
   ```

2. Print this block to the user, verbatim:

   ```
   Polish goes to a second session, not to me — a separate context, so mine stays on the build.

   Open a new terminal in this repo, start Claude Code at high effort on opus, and run:

       /dispatch polish <NNN>

   Request written to .claude/dispatch/polish/requests/<NNN>-<slug>.md. When that session is
   done it writes a note and one index line; I read the index, not the note.
   ```

3. Carry on with your own work. You will see the result as one index line, next dispatch.

## The polish session — `/dispatch polish [<NNN>|<what>]`

**You are a worker, not a dispatcher.** This mode inverts the skill: you read files, you edit
files, you talk to the user directly. You dispatch nothing.

**Start here:**

1. Read `AGENTS.md`, and `CLAUDE.md` if present.
2. Read the request: `.claude/dispatch/polish/requests/<NNN>-<slug>.md` for the `<NNN>` you were
   given. Called with a description instead of a number, or with nothing, there may be no
   request — say so and take the job from the user.
3. Work with the user. They supply further references and prompts as you go; ask when the ask is
   ambiguous, one question at a time.

**Working with the user — the 8-question ceiling does not apply here.** That ceiling
([responsive.md](responsive.md#the-question-ceiling--at-most-8-across-every-path)) bounds an
*intake*: questions asked before any work, to a user waiting for it to start. This session is
the opposite — the user is in the loop, looking at the thing, and each question follows an edit
they just saw. Keep asking as long as the work does, **one question per message**, never
batched. The discipline that stays: ask only what the files, the request and the user's own
words have not already answered, and never ask a question you could settle by making the change
and showing it.

**Baseline before you touch anything.** Same acceptance discipline as every dispatch: take the
snapshot from **[acceptance.md](acceptance.md)** ("Before the dispatch: a baseline to diff
from"), record the printed sha in your plan, and at the end show the user
`git diff <BASE> <AFTER>` using the commands that file gives. Do not restate them here.

**You never edit `AGENTS.md`** — that is bootstrap's file. **You never commit.**

## Writing the note

When the user says the polish is done, write the note **first**, then append the index entry.
That order matters: an index line pointing at a file that does not exist is worse than a note
nobody has indexed yet.

**The number.** If you were called as `/dispatch polish <NNN>` and a request with that number
exists, the note takes that same number. Otherwise take the next free one —
**[The next free number](#the-next-free-number--both-sessions)**.

**The note** — `.claude/dispatch/polish/<NNN>-<slug>.md`:

```markdown
---
id: <NNN>
title: <the same title the index line carries>
summary: |
  <line 1 — what changed, in the user's terms>
  <line 2 — optional; the consequence or the caveat>
date: <ISO date>
touches: <the same ≤5 items, one line, the index entry carries character for character>
files:
  - <path touched — the full list, however long; the index never carries this>
request: .claude/dispatch/polish/requests/<NNN>-<slug>.md    # omit the key if there was none
---

## What was wrong
<the observable problem, as the user described it or as you found it>

## What changed, and why
### `<path>`
<per file: the change, and the reason it is that change and not another>

## Left alone deliberately
<what you saw, decided not to touch, and why>

## Do not undo
<anything the next person would "fix" back, and what breaks when they do>
```

**The index entry** — appended to `.claude/dispatch/polish/INDEX.md`, nothing else added:

```markdown
### <NNN> — <title>
summary: <line 1 — what changed, in the user's terms>
         <line 2 — optional; the consequence or the caveat>
touches: <≤5 paths or surfaces, comma-separated, one line — `+N more` if it would not fit>
note: .claude/dispatch/polish/<NNN>-<slug>.md
```

The `summary:` and `touches:` here are the same lines as the note's frontmatter, character for
character. Copy them; do not rewrite them shorter. `touches:` is what the main session decides
on, so name what it would recognise — the paths and surfaces, not the reason.

## The two-line summary rule

Hard. **If the summary does not fit in two lines, the polish was two polishes** — split it into
two notes, two numbers, two index entries. Do not compress, do not use semicolons to smuggle a
third clause in. A summary that needs three lines is a main session opening the note, which is
the cost this whole file exists to avoid.

## Never

**The main session:**

- polish inside the main session, or as a sub-agent of it — the point is a separate context, not
  an isolated one
- read more than `INDEX.md` from the polish directory without a named reason
- read `requests/`, or edit the index

**The polish session:** dispatch a sub-agent, edit `AGENTS.md`, or commit.
