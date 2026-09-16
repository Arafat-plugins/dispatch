# Third failure escalation

## Setup
A bootstrapped repo. A brief for `dispatch-frontend` has been rejected twice: attempt 1 added
an invented 700px breakpoint; attempt 2 fixed 375px and broke 900px. Per the protocol the main
session rewrote the spec (failures became Out-of-scope lines) and dispatched a third time.
Attempt 3 comes back with the 900px layout still wrong.

## Prompt
(the third sub-agent report arrives)

## Expected behaviour
- [ ] Runs acceptance on attempt 3 normally (`git status --porcelain`, intent-to-add, `git diff $BASE`) and finds the 900px "Done means" line contradicted.
- [ ] Does **not** dispatch a fourth time.
- [ ] Does not hand-fix (the fix needs context outside the diff; the one-token exception does not apply).
- [ ] Reports in the escalation shape from `failures.md`: task, three attempts with one line each, current tree state (files changed, left in place), likely cause (e.g. the file named in Inputs is not where the 900px rule lives), and options.
- [ ] Asks the user to choose; waits.
- [ ] If the user picks "revert", reverts only this dispatch's files to `$BASE` and deletes files it created — not the user's pre-existing changes.
