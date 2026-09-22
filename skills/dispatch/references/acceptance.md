# Acceptance — the main session's own check

Step 5 of the cycle. **Not delegated.** A sub-agent reporting its own success is not evidence;
it is the same model that just did the work, marking its own homework.

## Before the dispatch: a baseline to diff from

`git diff` with no argument shows *everything* uncommitted — the user's half-done work, the
previous dispatch, and this one, mixed. You need a BASE that isolates this dispatch.

**Print it, record it, paste it.** Every command here prints a sha. Write it into your plan
(`BASE: 3f2a9c1…`) and paste the literal into each later command wherever this file says
`<BASE>`. Do not rely on assigning it to a shell variable: the assignment prints nothing, so
you never see the value, and in runtimes whose shell does not persist between tool calls (Cowork, some SDK hosts)
the variable is gone by step 5 — `git diff ""` then fails with exit 128. To survive a context
reset too, you may also store it: `git rev-parse HEAD > "$(git rev-parse --path-format=absolute --git-path dispatch-base)"`.

**Preferred — clean tree.** Ask the user to commit or stash first; then:

```bash
test -z "$(git status --porcelain)" && git rev-parse HEAD      # prints BASE
```

**Record BASE_HEAD at the same time** — one cheap command, checked at step 5:

```bash
git rev-parse HEAD                                             # prints BASE_HEAD — the commit BASE sits on
```

On a clean tree BASE_HEAD is the same sha as BASE; after the snapshot command below it is not,
because that BASE is a *tree*. **A tree sha does not fail there** — `git log <tree>..HEAD`
resolves the tree-ish and exits **0** having printed the repo's **entire history**, which reads
as "the sub-agent committed all of these". So write both into your plan, keep them apart, and
use the `^{commit}` form in "What the diff cannot see", which rejects a tree outright.

**The ignored-file baseline**, the second thing step 5 needs. Take it once BASE is printed, into
a file named after BASE so two dispatches in flight cannot overwrite each other's:

```bash
git -c core.quotePath=false ls-files --others --ignored --exclude-standard \
  > "$(git rev-parse --path-format=absolute --git-path dispatch-ignored-<BASE>)"
```

Paste the literal BASE sha for `<BASE>`. `--git-path` keeps the file inside the git directory —
never a stray path in the tree, and a linked worktree gets its own copy. **In a worktree**, put
`git -C <worktree-path>` on both `git` calls in that line.

**Dirty tree the user wants to keep — the snapshot command.** Records the working tree,
untracked files included, as a tree object. It builds a throwaway index seeded from `HEAD`
(so tracked files that `.gitignore` now matches are not dropped), so the real index is never
touched, nothing is staged and no hook runs. `--git-path` finds the git directory in a linked
worktree too, where `.git` is a file:

```bash
( export GIT_INDEX_FILE="$(git rev-parse --path-format=absolute --git-path dispatch-snap-index)"; git read-tree HEAD && git add -A >/dev/null && git write-tree; rm -f "$GIT_INDEX_FILE" )
```

It prints the tree sha: that is BASE. `git diff <BASE> <AFTER>` then shows only what changed
after it. A later dispatch takes a fresh one. Git older than 2.31 has no `--path-format`: run
the command from the repo root without that flag.

**Read the printed sha, not the exit status.** In a repo with no commit `git read-tree HEAD`
fails, the `&&` chain stops, and the subshell still ends on `rm -f` — so the command exits **0**
having printed no sha at all (only `fatal: Not a valid object name HEAD` on stderr). **No sha
printed is the failure**; an exit 0 here is not a snapshot. Make the root commit first, as
**[new-project.md](new-project.md)** does, then re-run.

**Worktree isolation** — for parallel dispatches, or any dispatch whose blast radius you are
unsure of. In Claude Code, pass `isolation: "worktree"` to the Agent tool: the sub-agent works
on its own branch in its own worktree and reports the path. Elsewhere, create one yourself
(`git worktree add <path> -b dispatch/<task> <START>`) and name the path in the brief. Record
`START` first — `git rev-parse HEAD` in your tree; the worktree holds committed state only, so
commit or leave out what the brief needs from your dirty tree. Review there, merge only after
acceptance:

```bash
git -C <worktree-path> status --porcelain
(cd <worktree-path> && <the snapshot command>)            # prints AFTER for the worktree
git -C <worktree-path> diff --stat <START> <AFTER>        # edits, created files and any commits
git -C <worktree-path> log --oneline <START>..HEAD        # commits it made — briefs forbid them
```

Take the ignored-file baseline in the worktree too, before the dispatch, and check it after —
the `git -C <worktree-path>` form both commands give above. A worktree has its own git
directory, so `--git-path` keeps that baseline separate from the shared tree's on its own.

`git diff HEAD` in the worktree is not enough: it misses untracked files and anything the
agent committed on its branch.

Two parallel sub-agents without worktrees share one working tree and one diff; you cannot
attribute a hunk to either. **Parallel without isolation is only for disjoint file sets, and
even then each brief names its files so you can partition the diff by path.**

## What you read

```bash
git status --porcelain                                  # M = edited, ?? = created, D = deleted
<the snapshot command>                                  # prints AFTER — record it next to BASE
git diff --stat <BASE> <AFTER>                          # shape: which files, how big
git diff <BASE> <AFTER>                                 # the actual change
```

**Created files are invisible to `git diff <BASE>`**, which compares against the working tree
only for tracked paths. A second snapshot records them, so `git diff <BASE> <AFTER>` shows them
as `new file` hunks — with no index change, so `git stash` and the user's staging are
unaffected, and with any file name (`git ls-files` quotes non-ASCII names such as
`"caf\303\251.css"`, which a `while read` loop cannot pass back to git). List them with
`git -c core.quotePath=false diff --name-only --diff-filter=A <BASE> <AFTER>`.

**Large diff — read in pieces, never whole.** If `--stat` reports more than ~300 changed lines
or more than ~6 files:

```bash
git diff --stat <BASE> <AFTER>                          # first: the shape
git diff <BASE> <AFTER> -- <path>                       # then: one file at a time, briefed files first
```

An oversize diff is itself a finding — the brief was too broad, or the agent went exploring.
Say so in the verdict; do not read 2,000 lines to find out whether the task got done.

## What the diff cannot see

`git diff <BASE> <AFTER>` compares two trees. Two things happen outside those trees, and both
are checked with one command each, on the shared (non-worktree) tree as well as in a worktree.

**Commits.** A sub-agent that runs `git commit` moves `HEAD`. Its content still shows in
`git diff <BASE> <AFTER>` — the snapshot reads `HEAD` first — but the repo's history changed
under you, and `git restore --source=<BASE>` (failures.md) will not put it back:

```bash
git log --oneline <BASE_HEAD>^{commit}..HEAD            # must print nothing
git diff --stat <BASE_HEAD>^{commit} HEAD               # if it did commit: the shape of what it committed
```

**Sub-agents do not commit** — every brief says so. A line from that `git log` is not a
bookkeeping detail: the commit is part of the change you are judging, so read it with the rest
of the diff, and **report it to the user by sha and subject** in the verdict, whether you accept
or reject the work. `<BASE_HEAD>` is the commit sha recorded next to BASE. **`^{commit}` is the
guard**, not decoration: paste BASE (a tree) there by mistake and git stops with
`expected commit type, but the object dereferences to tree type` and exit 128 — without it, the
same mistake prints every commit in the repo and exits 0.

**Ignored paths.** `dist/`, `node_modules/`, a `.env`, a dumped key: `.gitignore` hides them
from `git status` and from the diff, so an agent can write them and pass acceptance in silence.
Compare against the baseline taken before the dispatch:

```bash
git -c core.quotePath=false ls-files --others --ignored --exclude-standard \
  | diff "$(git rev-parse --path-format=absolute --git-path dispatch-ignored-<BASE>)" - \
  | awk '/^>/{sub(/^> ?/,""); print; n++} END{exit n?1:0}'
```

Each line printed is a path created since BASE. **Exit 0 with no output is the pass**; exit 1
means at least one ignored path was written. The `awk` is what makes the status match the
verdict — ending the pipeline on `grep '^>'` instead inverts it, exit 1 on the clean case and 0
when files leaked, so a runtime that surfaces non-zero flags every good acceptance. **In a
worktree**, put `git -C <worktree-path>` on both `git` calls.

Judge each one:

- **Build output** under a path `AGENTS.md` names as generated, from a build the brief asked
  for (`dist/app.js`, a cache, a compiled asset) — expected. Note it in the verdict, one line,
  and do not commit it.
- **A new dotfile, an `.env`, a key, a dump, a credential file, or anything the brief did not
  ask for** — **rejection**, and tell the user the path before anything else. An agent writing
  where nothing is watching is the finding, whatever the file contains; do not open it to
  decide.

**`git clean -nxd` is not a substitute.** It prints a different set, wrong in both directions: a
wholly-untracked directory collapses to one entry (`Would remove dist/` — `dist/new.js` never
appears), and it lists untracked files that are *not* ignored, which the baseline diff excludes.
Use it to eyeball a tree, never in place of the command above.

## The check

Take the **"Done means"** list from the brief you wrote and go through it line by line. For each:
confirmed by the diff, contradicted by the diff, or not visible in the diff. The third case is
not a pass — it means you need a command that shows it:

```bash
<the repo's lint command>
<the repo's test command>
```

`AGENTS.md` names those. Run them; do not assume.

**Then the phases.** The footer told the sub-agent to plan numbered phases and report per
phase. Check that the report has them and that each maps onto a "Done means" line or a briefed
file. A report with no phase list means the footer was ignored: judge the diff anyway, but say
so in the verdict, and if it happens twice with the same agent, check the installed agent file
still carries the template's Report section.

## Beyond the checklist

Five things a checklist does not catch, worth a look every time:

1. **Files outside the brief.** Anything edited *or created* that the brief did not name is
   scope creep. `git status --porcelain` is the complete list; compare it to Inputs. Reject it,
   even if the change looks reasonable — an agent that edits unbriefed files once will do it
   again on a task where it matters.
2. **Deletions.** `git diff --stat` shows the ratio. Large deletions the brief did not ask for
   are the single most common way a sub-agent quietly breaks something.
3. **Placeholders.** `TODO`, `FIXME`, stubbed returns, commented-out code left behind:
   ```bash
   git diff <BASE> <AFTER> | grep -nE '^\+.*(TODO|FIXME|XXX|HACK|placeholder)'
   ```
4. **Self-reported verification.** "Verified at 375px" in the report is a claim. Rendering
   claims from a sub-agent without browser tools are reading, not measuring — see below.
5. **Colours and breakpoints outside `DESIGN.md`.** A UI diff that introduces a colour or a
   breakpoint `DESIGN.md` does not define is a finding — reject it, even when it looks right.
   Check the added lines only:
   ```bash
   git diff <BASE> <AFTER> | grep -nE '^\+.*(#[0-9a-fA-F]{3,8}\b|rgba?\(|hsla?\(|hwb\(|oklch\(|@media)'
   ```
   Each hit is either a `DESIGN.md` token (by name, or a value it lists) or a finding.
   **Spacing** is checked only when `DESIGN.md` → Tokens lists a spacing scale, and then only
   the spacing properties — a `border: 1px`, a `line-height`, a `width` are routine CSS, never
   findings on their own:
   ```bash
   git diff <BASE> <AFTER> | grep -nE '^\+.*\b(margin|padding|gap|row-gap|column-gap|inset)[a-z-]*\s*:[^;]*[0-9.]+(px|rem|em)\b'
   ```
   No `DESIGN.md` in the repo → **skip this check entirely** and say so in the verdict; the
   brief's **Format** is the design rule then, and a px or rem value is not a reason to reject.

## Verifying frontend work yourself

The frontend agent's default tool list has no browser. Unless its report names the tool it
rendered with, treat "verified" as **verified by reading the rules**, and report it as
**Not verified** for rendering. For any design/UI task, check the widths the brief's Target
behaviour named — at minimum mobile ~375px, tablet ~768px, desktop ~1280px+, or the project's
own breakpoints; see **[responsive.md](responsive.md)**. Report per width: measured, or
**Not verified**.

**Which page:** the brief's **Page URL(s)** line under Inputs (prompt-spec.md) — every UI
brief carries one; `<page url>` below is each of those, pasted. A UI brief without it was not
ready to dispatch: add it before the re-dispatch. `AGENTS.md` → *Verification capabilities*
says what this repo can render with (**[setup.md](setup.md)**). Use what it records:

- **Rendering: local Playwright** — run the repo's copy of the measure script, the same one the
  frontend agent runs. Never retype a Playwright snippet; one script means one result format.

  ```bash
  node .claude/dispatch/dispatch-measure.mjs <page url> 320 375 768 1280
  node .claude/dispatch/dispatch-measure.mjs <page url> 375 900 --select .grid --prop grid-template-columns
  ```

  A `renderer:` line (the tool you report), then one line per width — `overflow: no`, or
  `overflow: yes, <px>` — plus the computed value when `--select`/`--prop` are given (count the
  `grid-template-columns` values for a column count; `--prop --brand` reads a `DESIGN.md`
  token). Nothing else enters your context. Exit 0 means *measured*, not *passed*: read the
  lines.
- **Rendering: MCP `<name>`** — if that browser is in your own tool list, resize to each width,
  load `<page url>`, check the address it ended on is that URL (a redirect is Not verified), and evaluate `document.documentElement.scrollWidth - document.documentElement.clientWidth`
  plus the computed values "Done means" names. Same one-line-per-width report.
- **Rendering: none**, or no section → every width is `Not verified: rendering (no browser
  available)`. That is an honest result; a green tick without a measurement is not.

The script starts nothing. **Exit 2** (`dev server not reachable at <url>`): start the server
with the command *Verification capabilities* records — in the background, stopped when you are
done — or ask the user to, then re-run. Exit 2 with `redirected to <final url>` means the page
sent you elsewhere (often a login): nothing was measured — use the final URL if that is the
briefed page, else report the widths *Not verified* and say why. **Exit 3** (Playwright or its
chromium missing): report per width `Not verified`, and pass on the fix the line names, or
`/dispatch setup`. **Exit 1**: the arguments; the one line says which. Portable fallback: the
script is plain Node 18+; any runtime with a shell runs it the same way.

## The verdict

**Accept** — say plainly what landed, then move to verify. Polish left over after an accepted
change is not another dispatch and not yours: write the request and hand it to the second
session — **[polish.md](polish.md)**.

**Reject** — re-dispatch. The rejection brief carries:
- the original brief, unchanged
- what specifically failed, quoted from the diff
- what "correct" looks like for that item

**Do not fix it yourself.** Hand-fixing pulls the file contents into your context, which is the
exact cost this whole skill exists to avoid. It also hides the failure — the next dispatch on
this repo repeats it. The single exception — a one-token fix entirely visible in the diff you
already read — is defined in **[when-not-to-dispatch.md](when-not-to-dispatch.md)**.

Two rejections on one brief: stop re-dispatching. The brief is the problem. Rewrite the spec
from **[prompt-spec.md](prompt-spec.md)**, with the failures as new "Out of scope" lines.

**Three failures — the rewritten brief failed too — stop.** Escalate per
**[failures.md](failures.md)**. Do not dispatch a fourth time without the user's direction.

## After the critic

The security critic and the db-tester are read-only **by instruction** — they hold `Bash`.
Confirm they behaved:

```bash
git status --porcelain > /tmp/dispatch-before    # before dispatching the critic
git status --porcelain | diff /tmp/dispatch-before -   # after: no output = nothing changed
```

Any difference is a finding about the agent, reported to the user before the critic's own
findings. That only holds if nothing else edited this tree in between: run a read-only agent
while no other agent is editing the same working tree (routing.md, "Concurrency cap").

## Report to the user

Short, and honest about what you actually verified:

```
Accepted: <one line on what changed>
Verified: <the checks that ran, and their result>
Not verified: <anything you could not check, and why — rendering claims go here>
```

Never report "done" for something you did not check. "Not verified" is a legitimate line and
the user needs to see it.
