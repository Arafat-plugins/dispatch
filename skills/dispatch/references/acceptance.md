# Acceptance — the main session's own check

Step 5 of the cycle. **Not delegated.** A sub-agent reporting its own success is not evidence;
it is the same model that just did the work, marking its own homework.

## What you read

```bash
git diff --stat     # shape: which files, how big
git diff            # the actual change
```

The diff, not the files. If the diff is enormous, that is itself a finding — the brief was too
broad, or the agent went exploring. Say so.

## The check

Take the **"Done means"** list from the brief you wrote and go through it line by line. For each:
confirmed by the diff, contradicted by the diff, or not visible in the diff. The third case is
not a pass — it means you need a command that shows it:

```bash
<the repo's lint command>
<the repo's test command>
```

`AGENTS.md` names those. Run them; do not assume.

## Beyond the checklist

Three things a checklist does not catch, worth a look every time:

1. **Files outside the brief.** Anything edited that the brief did not name is scope creep.
   Reject it, even if the change looks reasonable — an agent that edits unbriefed files once
   will do it again on a task where it matters.
2. **Deletions.** `git diff --stat` shows the ratio. Large deletions the brief did not ask for
   are the single most common way a sub-agent quietly breaks something.
3. **Placeholders.** `TODO`, `FIXME`, stubbed returns, commented-out code left behind:
   ```bash
   git diff | grep -nE '^\+.*(TODO|FIXME|XXX|HACK|placeholder)'
   ```

## The verdict

**Accept** — say plainly what landed, then move to verify.

**Reject** — re-dispatch. The rejection brief carries:
- the original brief, unchanged
- what specifically failed, quoted from the diff
- what "correct" looks like for that item

**Do not fix it yourself.** Hand-fixing pulls the file contents into your context, which is the
exact cost this whole skill exists to avoid. It also hides the failure — the next dispatch on
this repo repeats it.

Two rejections on one brief: stop re-dispatching. The brief is the problem. Rewrite the spec
from **[prompt-spec.md](prompt-spec.md)**, with the failures as new "Out of scope" lines.

## Report to the user

Short, and honest about what you actually verified:

```
Accepted: <one line on what changed>
Verified: <the checks that ran, and their result>
Not verified: <anything you could not check, and why>
```

Never report "done" for something you did not check. "Not verified" is a legitimate line and
the user needs to see it.
