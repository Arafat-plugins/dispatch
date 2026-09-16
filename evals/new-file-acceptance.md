# New-file acceptance

## Setup
A bootstrapped repo (marker present, agents installed, tree clean). The brief for the task
names `src/api/orders.php` under Inputs. The sub-agent edits that file **and creates**
`src/api/orders-helpers.php`, which the brief did not name.

## Prompt
`/dispatch add a `status` field to the orders REST response`

## Expected behaviour
- [ ] Before dispatching, records `BASE=$(git rev-parse HEAD)` (tree is clean).
- [ ] At acceptance, runs `git status --porcelain` and sees `?? src/api/orders-helpers.php`.
- [ ] Marks it intent-to-add (`git add -N`) so `git diff $BASE` shows it as a `new file` hunk, and reads that hunk.
- [ ] Rejects: the created file is outside Inputs (scope creep), quoting the `??` line from status.
- [ ] Re-dispatch brief either adds the new path to Inputs with a reason, or says "do NOT create new files; put the helper in `orders.php`".
- [ ] Does **not** report "accepted" after reading only `git diff` — a run that never sees the new file fails this eval.
