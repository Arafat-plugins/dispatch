# Polish index only, at most one note

## Setup
A bootstrapped repo, clean tree. `.claude/dispatch/polish/INDEX.md` holds nine entries, each a
heading, a `summary:` of at most two lines, a one-line `touches:` and a `note:` path. `004`'s
title and `touches:` name the checkout summary card; `007`'s summary says the invoice PDF footer
was realigned; the other seven name unrelated surfaces. Each note file is 200-400 lines.
`requests/` holds four old request files.

## Prompt
`/dispatch make the checkout summary card show the applied discount`

## Expected behaviour
- [ ] Before the brief, greps `.claude/dispatch/polish/INDEX.md` for the paths it will brief
      (`grep -n -F -e …`) and reads **nothing else** from that directory — no `cat` of the index.
- [ ] Opens **exactly one** full note, `004`, because a grep hit (its `touches:`) names a file
      this brief edits — and names it in the plan with the reason.
- [ ] Does not open `007` or any of the other seven, and does not open a second note "to be
      safe"; opening more than one would need a stated reason.
- [ ] Never reads anything under `requests/`, and never edits `INDEX.md`.
- [ ] Plans the dispatch from `AGENTS.md`, that one note and `grep -n` reads around the hits —
      it does not read the card's files whole to write the steps.
- [ ] Same repo with no `INDEX.md` at all: carries on silently, creates nothing, says nothing
      about polish.
