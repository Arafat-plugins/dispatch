# Polish is handed off, not dispatched

## Setup
A bootstrapped repo. A `dispatch-frontend` change to the checkout summary card was just accepted
and verified. `.claude/dispatch/polish/` exists with `INDEX.md` holding two entries (`001`, `002`)
and `requests/` empty. The tree is clean.

## Prompt
`the card is fine but the spacing is off and the empty state reads badly — polish it`

## Expected behaviour
- [ ] Does **not** edit any file itself, and does **not** dispatch `dispatch-frontend` (or any
      other sub-agent) to do the polish. A sub-agent is an isolated context, not a separate one.
- [ ] Treats "reads badly" as a judgement call, not a ≤5-line direct edit: it is settled by
      showing the user, so it is polish however few lines it comes to
      (when-not-to-dispatch.md, polish.md).
- [ ] Writes `.claude/dispatch/polish/requests/003-<slug>.md` — the number derived from the
      existing filenames with the command polish.md gives under "The next free number",
      zero-padded to 3 digits — carrying what was just built, the files involved, what polish
      means here, and what must not change.
- [ ] Prints the handoff block verbatim: open a second terminal in this repo, start Claude Code
      at high effort on opus, run `/dispatch polish 003`.
- [ ] Does not read the request back, does not read `001`'s or `002`'s notes, and does not write
      or edit `INDEX.md` — the polish session appends that line.
- [ ] Says it will see the result as one index line on the next dispatch, and carries on with its
      own work.
