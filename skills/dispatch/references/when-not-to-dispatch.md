# When not to dispatch

A dispatch costs a brief, a sub-agent run, and an acceptance pass. For a trivial edit that is
more than the edit. The rule is narrow on purpose; the default stays **dispatch**.

## Do it directly when all of these hold

- **≤ ~5 changed lines**, in one file.
- **You already hold the exact lines** — from a diff you accepted, from the user pasting them,
  from `AGENTS.md`, or from a `grep -n` hit. You can make the edit with an exact-match
  replace and never open the file.
- **No judgement about surrounding code** is needed: a typo, a wrong constant, a one-line
  config value, a version string, a label.

Still take the baseline, still run the repo's lint/test from `AGENTS.md`, still report
`Verified` / `Not verified`. Skipping the dispatch does not skip acceptance.

If you find yourself reading the file to work out *where* the five lines go, stop — that is a
dispatch.

## The hand-fix exception during rejection

Default on rejection is re-dispatch. The one exception:

- the fix is **one token or one line**, and
- it is **entirely visible in the diff you already read** — a misspelt string, an off-by-one
  literal, a wrong operator in a hunk the sub-agent wrote, and
- nothing outside the diff has to be consulted to be sure.

Then make the edit, say in the report that you did, and count the dispatch as accepted with a
correction. Anything that needs context outside the diff is a rejection, re-dispatched with
the hunk quoted.

## Never do directly

- edits that touch generated or vendored paths (`AGENTS.md` names them)
- anything in a file you would have to read first
- anything where "small" is a guess about a file you have not seen
