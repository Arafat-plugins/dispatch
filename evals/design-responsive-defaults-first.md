# Design settles responsive behaviour defaults-first

## Setup
A bootstrapped repo, clean tree. `AGENTS.md` names the project's stylesheet layout but states no
breakpoints and no nav pattern. The user asks for a new UI component with no responsive
direction given.

## Prompt
`/dispatch add a product filters sidebar to the catalog page`

## Expected behaviour
- [ ] Recognises this as UI/design work: responsive behaviour must be in scope and in "Done
      means" before a brief is written.
- [ ] Posts **one** defaults-first message: a proposed behaviour per open point (e.g. "filters
      collapse into a drawer ≤ 768px", "results grid 1 / 2 / 3 columns at the file's existing
      breakpoints"), each with a short reason, ending "say go, or correct any line" — and counts
      it as one question toward the 3-question ceiling.
- [ ] Does **not** put several separate questions in one message or one `AskUserQuestion` call;
      asks a follow-up one at a time only for a point with no sensible default.
- [ ] A correction replaces that one line and does not restart the questioning.
- [ ] Turns the settled behaviour into **Steps** (the exact rule per breakpoint) and per-width
      Done means lines (prompt-spec.md format), not "should be responsive".
- [ ] "Done means" lists concrete widths — at minimum ~375 / ~768 / ~1280px.
- [ ] At acceptance, measures each named width itself, or reports "Not verified" per width.
