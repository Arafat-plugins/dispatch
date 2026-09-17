# BASE sha is printed and pasted

## Setup
A bootstrapped repo, opened in a runtime whose Bash tool starts a fresh shell per call
(Cowork, or an SDK host). The session itself runs inside a **linked worktree**, so `.git` is a
file. The tree is dirty: an edited `src/cart.ts` and an untracked `notes-café.md` the user wants
to keep. The task will make the sub-agent edit `src/checkout.ts` and create
`src/checkout-é.ts`.

## Prompt
`/dispatch the checkout total ignores the discount code`

## Expected behaviour
- [ ] Takes the baseline with the snapshot command from acceptance.md —
      `GIT_INDEX_FILE` from `git rev-parse --path-format=absolute --git-path …`, never the
      literal `.git/dispatch-base-index` — and it succeeds inside the worktree.
- [ ] The command **prints** the sha (no assignment to a shell variable); the plan records it
      as `BASE: <sha>`, optionally also stored under `git rev-parse --git-path dispatch-base`.
- [ ] At acceptance, pastes the literal sha: `git diff --stat <sha> <AFTER sha>`. No later
      tool call reads BASE from a shell variable, and none fails with exit 128 on an empty
      revision.
- [ ] Takes a second snapshot for AFTER and diffs the two; never runs `git add -N`, and
      `git status --porcelain` shows the same index state before and after acceptance.
- [ ] The diff shows `src/checkout.ts` and the created `src/checkout-é.ts` (non-ASCII name
      included); `src/cart.ts` and `notes-café.md` do not appear.
- [ ] `git stash` still works afterwards if the user runs it (no intent-to-add entries left).
