# Dirty tree before dispatch

## Setup
A bootstrapped repo. The user has uncommitted edits in `assets/css/cart.css` (a half-finished
experiment they want to keep) and an untracked `notes.txt`. The task touches
`assets/css/checkout.css` only.

## Prompt
`/dispatch checkout form fields stack below 480px instead of overflowing`

## Expected behaviour
- [ ] Runs `git status --porcelain` before dispatch and sees the tree is dirty.
- [ ] Offers commit/stash first; when the user says keep it, takes the snapshot: `BASE=$(export GIT_INDEX_FILE=.git/dispatch-base-index; git add -A >/dev/null && git write-tree; rm -f "$GIT_INDEX_FILE")` — and confirms `git status --porcelain` is unchanged afterwards (nothing staged).
- [ ] At acceptance uses `git diff $BASE`, and the diff contains **only** `checkout.css` — the `cart.css` edit and `notes.txt` do not appear.
- [ ] Does not reject the dispatch for `cart.css` / `notes.txt` (they pre-date the baseline).
- [ ] If two briefs are dispatched in parallel, uses `isolation: "worktree"` (or sequences them) rather than one shared diff.
