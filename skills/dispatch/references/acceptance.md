# Acceptance — the main session's own check

Step 5 of the cycle. **Not delegated.** A sub-agent reporting its own success is not evidence;
it is the same model that just did the work, marking its own homework.

## Before the dispatch: a baseline to diff from

`git diff` with no argument shows *everything* uncommitted — the user's half-done work, the
previous dispatch, and this one, mixed. You need a `$BASE` that isolates this dispatch.

**Preferred — clean tree.** Ask the user to commit or stash first; then:

```bash
test -z "$(git status --porcelain)" && BASE=$(git rev-parse HEAD)
```

**Dirty tree the user wants to keep.** Snapshot the working tree, untracked files included, as
a tree object. Uses a throwaway index, so nothing is staged and no hook runs:

```bash
BASE=$(export GIT_INDEX_FILE=.git/dispatch-base-index; git add -A >/dev/null && git write-tree; rm -f "$GIT_INDEX_FILE")
```

`git diff $BASE` then shows only what changed after the snapshot. Record `$BASE` in your
plan; a later dispatch takes a fresh one.

**Worktree isolation** — for parallel dispatches, or any dispatch whose blast radius you are
unsure of. In Claude Code, pass `isolation: "worktree"` to the Agent tool: the sub-agent works
on its own branch in its own worktree and reports the path. Review there, merge only after
acceptance:

```bash
git -C <worktree-path> status --porcelain
git -C <worktree-path> diff HEAD                      # its branch started at your HEAD
```

Two parallel sub-agents without worktrees share one working tree and one diff; you cannot
attribute a hunk to either. **Parallel without isolation is only for disjoint file sets, and
even then each brief names its files so you can partition the diff by path.**

## What you read

```bash
git status --porcelain                                  # M = edited, ?? = created, D = deleted
git ls-files --others --exclude-standard | while read -r f; do git add -N -- "$f"; done
git diff --stat "$BASE"                                 # shape: which files, how big
git diff "$BASE"                                        # the actual change
```

**Created files are invisible to `git diff` until intent-to-add.** The second line marks them
so they appear as `new file` hunks. When you are done reviewing, `git reset -- <those files>`
if the user wants them back to untracked (an intent-to-add entry blocks `git stash`).

**Large diff — read in pieces, never whole.** If `--stat` reports more than ~300 changed lines
or more than ~6 files:

```bash
git diff --stat "$BASE"                                 # first: the shape
git diff "$BASE" -- <path>                              # then: one file at a time, briefed files first
```

An oversize diff is itself a finding — the brief was too broad, or the agent went exploring.
Say so in the verdict; do not read 2,000 lines to find out whether the task got done.

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

Four things a checklist does not catch, worth a look every time:

1. **Files outside the brief.** Anything edited *or created* that the brief did not name is
   scope creep. `git status --porcelain` is the complete list; compare it to Inputs. Reject it,
   even if the change looks reasonable — an agent that edits unbriefed files once will do it
   again on a task where it matters.
2. **Deletions.** `git diff --stat` shows the ratio. Large deletions the brief did not ask for
   are the single most common way a sub-agent quietly breaks something.
3. **Placeholders.** `TODO`, `FIXME`, stubbed returns, commented-out code left behind:
   ```bash
   git diff "$BASE" | grep -nE '^\+.*(TODO|FIXME|XXX|HACK|placeholder)'
   ```
4. **Self-reported verification.** "Verified at 375px" in the report is a claim. Rendering
   claims from a sub-agent without browser tools are reading, not measuring — see below.

## Verifying frontend work yourself

The frontend agent's default tool list has no browser. Unless its report names the tool it
rendered with, treat "verified" as **verified by reading the rules**, and report it as
**Not verified** for rendering. For any design/UI task, check the widths the brief's Target
behaviour named — at minimum mobile ~375px, tablet ~768px, desktop ~1280px+, or the project's
own breakpoints; see **[responsive.md](responsive.md)**. Report per width: measured, or
**Not verified**. Measure it yourself when the repo has Playwright installed
(`node -e 'require("playwright")'` exits 0) and a running dev URL:

```bash
node -e '
const { chromium } = require("playwright");
const [url, ...widths] = process.argv.slice(1);
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  for (const w of widths.map(Number)) {
    await p.setViewportSize({ width: w, height: 900 });
    await p.goto(url, { waitUntil: "networkidle" });
    const r = await p.evaluate(() => ({ sw: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth }));
    console.log(w, r.sw > r.cw ? "OVERFLOW by " + (r.sw - r.cw) + "px" : "ok");
  }
  await b.close();
})();' "$URL" 320 375 620 900 1024 1440
```

One line per width, nothing else enters your context. Extend the `evaluate` for column counts
(`getComputedStyle(el).gridTemplateColumns.split(" ").length`) when "Done means" names them.
No Playwright, no dev server → the line in the report is `Not verified: rendering (no browser
available)`. That is an honest result; a green tick without a measurement is not.

## The verdict

**Accept** — say plainly what landed, then move to verify.

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
findings.

## Report to the user

Short, and honest about what you actually verified:

```
Accepted: <one line on what changed>
Verified: <the checks that ran, and their result>
Not verified: <anything you could not check, and why — rendering claims go here>
```

Never report "done" for something you did not check. "Not verified" is a legitimate line and
the user needs to see it.
