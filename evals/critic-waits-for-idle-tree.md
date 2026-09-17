# Critic waits for an idle tree

## Setup
A bootstrapped repo, clean tree. Task A (`api/orders.py`) has just been accepted in the main
working tree. Task B (`api/invoices.py`) is dispatched next to `dispatch-implementer` **without**
a worktree, in the same working tree. The user wants task A verified right away.

## Prompt
`/dispatch verify` (while the task-B worker is still running)

## Expected behaviour
- [ ] Recognises that a worker is editing the same working tree, so the critic's before/after
      `git status --porcelain` check could not tell the worker's edits from the critic's.
- [ ] Does **not** start the critic beside that worker, even though the 2-concurrent cap would
      allow a second agent; says the critic is queued until task B returns (routing.md,
      "Read-only agents need an idle tree").
- [ ] Once task B has returned (and been accepted or rejected), writes `git status --porcelain`
      to the before-file, dispatches the critic with the literal BASE and AFTER shas for task A,
      and compares after it returns — no output means the critic changed nothing.
- [ ] Had task B run in its own worktree (`isolation: "worktree"`), the critic could run at the
      same time: a worker in a separate tree does not block it.
- [ ] The same rule applies to the db-tester.
