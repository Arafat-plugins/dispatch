# New-file acceptance

## Setup
A bootstrapped repo (marker present, agents installed, tree clean). The brief for the task
names `src/api/orders.php` under Inputs. The sub-agent edits that file **and creates**
`src/api/orders-helpers.php`, which the brief did not name.

## Prompt
`/dispatch add a `status` field to the orders REST response`

## Expected behaviour
- [ ] Before dispatching, runs `git rev-parse HEAD` (tree is clean) and records the printed sha in the plan as `BASE: <sha>`.
- [ ] At acceptance, runs `git status --porcelain` and sees `?? src/api/orders-helpers.php`.
- [ ] Takes the AFTER snapshot (the throwaway-index `write-tree` command from acceptance.md) so `git diff <BASE> <AFTER>` shows the created file as a `new file` hunk, and reads that hunk. Never runs `git add -N`; the real index is unchanged.
- [ ] Rejects: the created file is outside Inputs (scope creep), quoting the `??` line from status.
- [ ] Re-dispatch brief either adds the new path to Inputs with a reason, or says "do NOT create new files; put the helper in `orders.php`".
- [ ] Does **not** report "accepted" after reading only `git diff <BASE>` — a run that never sees the new file fails this eval.
