# Integration — merging parallel slices, checkpoint commits, keeping the map current

Three things a long build needs that single dispatches never did:

1. **Parallel work has to come back.** A worktree slice was accepted in its own tree, and
   nothing said how its changes reach yours.
2. **Accepted work has to be checkpointed.** The skill never commits on its own, which is right,
   but the result was a tree that stayed dirty for a whole phase. BASE became a snapshot tree
   every time, and one bad dispatch could tangle several accepted ones.
3. **The map has to keep up.** `AGENTS.md` was refreshed only by re-running bootstrap, so by
   phase 3 the Surfaces table and Flows map described phase 1.

## 1. Bringing a worktree slice back

After a worktree slice is accepted (acceptance.md, *Worktree isolation*), with its START and
AFTER from your plan:

```bash
git -C <worktree-path> diff --binary <START> <AFTER> | git apply -    # into your tree; index untouched
git status --porcelain                                                 # the slice's files, now here
git worktree remove --force <worktree-path>
git branch -D <the worktree's branch>                                  # the Agent tool names it
```

- **`git apply` refused** (a hunk does not fit) → the slices were not disjoint. Stop, tell the
  user which files overlap, and re-brief the later slice on top of the earlier one. Never
  resolve a conflict by hand. That is reading the territory.
- **Integration acceptance**: after every apply, run the targeted and flow tests of **both**
  slices in your tree. A slice that passed alone and fails together is a rejection of the
  *later* slice, with the failure quoted.
- The end-of-task run (full suite, verify) and every gate run only **after every slice is back**,
  with AFTER taken from your own tree.

## 2. Checkpoint commits — proposed, run on a yes

After the end-of-task run passes (speed.md) — and always at a gate (planning.md) — **propose**
one commit for the task:

```bash
git status --porcelain                                  # what will be committed
for p in <the task's paths, from its briefs' Inputs> .claude/dispatch/ledger.md .claude/dispatch/briefs ROADMAP.md AGENTS.md; do
  if [ -e "$p" ]; then git add -A -- "$p"; fi           # one absent path must not abort the rest (bootstrap.md, Step 6)
done
git commit -m "<type>(<scope>): <task> [dispatch <first NNN>–<last NNN>]"
```

Show the paths and the message, and run it **only on the user's yes**. `AGENTS.md` may hold a
standing answer. The user writes it; the skill never adds it:

```markdown
## Checkpoints
Commit after each accepted task: yes      # the user's standing yes; absent or "ask" → ask each time
```

With a standing yes, commit after the end-of-task run passes and say so in one line. Either way:

- **Never push**, never amend or rebase, and never commit a task that failed its full suite or
  has an unaccepted dispatch.
- Stage **paths, not `-A` alone**. The user's own uncommitted work stays out. If a path mixes
  the user's edits with the task's, say so and ask.
- The ledger line is appended **before** the commit, so the commit carries it and leaves the
  tree clean. The next task's BASE is then a clean `git rev-parse HEAD`, not a snapshot. The
  ledger itself is never edited afterwards: the commit is found by its message,
  `git log --oneline --grep 'dispatch 012'`.

## 3. Keeping `AGENTS.md` current — map upkeep in the brief

**A dispatch that changes the map updates the map, in the same brief.** When the task adds or
removes a route or page (Surfaces), a top-level directory (Layout), a flow or flow step (Flows),
a command (Commands), or a module (Modules / module maps below), then:

- the brief lists `AGENTS.md` (or the module's map) under **Inputs**, with a line under Target:
  "add the Surfaces row for `/invoices/:id` → InvoiceController@show → Invoices/Show.vue";
- **Done means** carries it: `- [ ] AGENTS.md row added/changed as stated; nothing else in it
  edited`;
- acceptance checks the map hunk like any other. A new route with no map row is a rejection.

Only the region between the dispatch markers is edited this way. Anything outside them belongs
to the user.

## 4. Module maps — when one map is not enough

When the root `AGENTS.md` would pass its ~200-line cap — in practice around 60 surfaces, 8 flows,
or 6 modules, whichever comes first — it becomes an **index**. It
keeps what every brief needs (What this project is, Conventions, Do NOT, Commands, Known-failing
baseline, Verification capabilities) and one row per module:

```markdown
## Modules
| Module | Path | Map | Flows |
| --- | --- | --- | --- |
| Billing | app/Modules/Billing | app/Modules/Billing/AGENTS.md | F1, F4 |
| HR | app/Modules/HR | app/Modules/HR/AGENTS.md | F5–F7 |
```

Each module map uses the same markers and sections (Layout, Surfaces, Flows) for its own paths,
**≤ 120 lines**. A brief's Knowledge line then reads "root `AGENTS.md`, then
`app/Modules/Billing/AGENTS.md`". Bootstrap proposes the split when the thresholds are reached,
shows the diffs, and writes on a yes. This does not need a monorepo.

`status` counts drift per map, and a re-run of bootstrap rewrites only the marked regions.
