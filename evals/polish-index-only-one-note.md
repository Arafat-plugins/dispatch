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
- [ ] Before planning, reads `.claude/dispatch/polish/INDEX.md` and **nothing else** from that
      directory — one `cat`, titles, two-line summaries and `touches:` lines only.
- [ ] Opens **exactly one** full note, `004`, because its title and `touches:` name the surface
      this brief touches — and names it in the plan with the reason.
- [ ] Does not open `007` or any of the other seven, and does not open a second note "to be
      safe"; opening more than one would need a stated reason.
- [ ] Never reads anything under `requests/`, and never edits `INDEX.md`.
- [ ] Plans the dispatch from `AGENTS.md` plus that one note — it does not read the card's own
      files to write the brief.
- [ ] Same repo with no `INDEX.md` at all: carries on silently, creates nothing, says nothing
      about polish.
