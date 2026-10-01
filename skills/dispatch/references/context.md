# Context — keeping the main session small over a long build

The main session is the one place that must stay accurate: it writes every brief and judges
every diff. Over a long build it filled up anyway, and a full session is where hallucination
starts. It stated shas it never printed, called files done that were rejected, and "remembered"
briefs differently from how they were written. It happened for six reasons:

1. **The skill's own reading.** Before the first dispatch, `SKILL.md`, routing, prompt-spec,
   acceptance and verifier add up to about 1,100 lines, and they were re-opened every cycle.
2. **Every diff stayed.** Each acceptance adds up to ~300 lines. Fifty dispatches means fifty
   diffs, all still in context.
3. **The plan lived only in the conversation.** BASE, AFTER, the brief text and the attempt
   count had no home on disk. When the runtime compacted the conversation, the summary kept
   "BASE was recorded" and dropped the sha.
4. **Reports piled up**: 40 lines per sub-agent, every run (now 20, per step).
5. **No end.** One session was expected to carry a whole build.
6. **Claims from memory.** "Tests pass", "that file was accepted", "the brief said X", said
   without a command behind them this cycle.

## The fact rule

**Every statement about the repo or the work must come from something produced in this cycle**:
a command's output, the diff, the brief file, the ledger, or a sub-agent report (and the report
counts only as a claim). That covers every path, sha, test result, "accepted", "done", and "the
brief said". Anything else is `unknown — checking` followed by the command that checks it. This
applies to what you tell the user and to what you put in a brief.

After the conversation has been compacted or summarised, **treat every sha, path and verdict
in the summary as unknown**. Re-read them from the ledger and the brief files before using any.

## Briefs live on disk — size M and L

For a size M or L task, write each brief to a file before dispatching it, then dispatch with its
content. A size S brief lives in the Agent prompt only; its ledger line is its record:

```
.claude/dispatch/briefs/<NNN>-<slug>.md
```

Write it — and any reference image — **before** you record BASE, and append the ledger line only
**after** AFTER is recorded, so the dispatch's own diff never contains your bookkeeping
([acceptance.md](acceptance.md#your-bookkeeping-is-not-the-agents-diff)). A rejection edits that
file (append *What failed* / *What correct looks like*, or rewrite it on the second failure) and
takes a new BASE before the re-dispatch. Acceptance reads its **Done means** from the file, not from memory. A new
session resumes from it. `<NNN>` comes from the counter below, shared with the ledger and the
reference images.

## The ledger

`.claude/dispatch/ledger.md` is **one line per dispatch outcome**, appended when you accept,
reject, escalate, or skip verify. Never edit or reorder it:

```
NNN | date | slug | agent | size | BASE | AFTER | verdict | attempt | tests | verify | minutes
007 | 2026-09-28 | pricing-hero | dispatch-frontend | M | 3f2a9c1 | 8e1d004 | accepted | 2 | targeted ✓ | batched | 18
```

**Read only its tail** (`tail -n 20 .claude/dispatch/ledger.md`), never the whole file. It
replaces keeping the task's history in your head. **The next free number**, for the ledger, the
briefs and the refs:

```bash
{ ls .claude/dispatch/briefs 2>/dev/null; awk -F' [|] ' '/^[0-9]{3} /{print $1}' .claude/dispatch/ledger.md 2>/dev/null; } \
  | grep -oE '^[0-9]{3}' | sort -n | tail -1 | awk '{printf "%03d\n", $1+1} END{if(NR==0) print "001"}'
```

Commit `ledger.md` and `briefs/`. They are small, and they are how a teammate's session, or
yours tomorrow, knows what happened.

## Read less, per cycle

- **The cycle card**: for a routine dispatch read [cycle-card.md](cycle-card.md) instead of
  routing, prompt-spec, acceptance and verifier. Open a full reference only when the card sends
  you to it: a failure, an oversize diff, a first UI or flow brief, a deps change, a cold
  verify.
- **The diff, not the noise**: exclude lockfiles, generated output and snapshots from what you
  read ([acceptance.md](acceptance.md#what-you-read)). Read `--stat` first, then per file.
- **Reports**: take the per-step verdicts and the "not verified" lines, and do not repeat the rest
  to the user.
- **Polish**: `grep` hits in the index only ([polish.md](polish.md)).

## Rotate the session — only when needed

Rotation costs the user a new session, so it is not automatic. **Rotate** when either holds:

- the conversation has been **compacted or summarised** by the runtime
- you are unsure of a BASE, a brief, or what was accepted, and the ledger does not settle it

**Suggest** it in one line, and carry on unless the user says yes, after about **10 accepted
dispatches** in this session or at the end of a phase of a planned build.

To rotate, first write any size-S brief still in flight to `.claude/dispatch/briefs/<NNN>-<slug>.md`
(it otherwise lives only in the conversation), then write `.claude/dispatch/HANDOFF.md`, **30
lines at most**, overwriting the previous one:

```markdown
# Handoff — <date>
Task: <one line> (size <S|M|L>)   Brief: .claude/dispatch/briefs/<NNN>-<slug>.md
State: <accepted up to NNN; NNN in flight / rejected once / not yet dispatched>
BASE: <sha>   AFTER: <sha or —>   BASE_HEAD: <sha>
Verify: <done for NNN–NNN / pending over <BASE>..<AFTER>>
Full suite this task: <not run / ✓ / ✗ <which>>
Next: <the one next action>
Open with the user: <question, or none>
```

Then print this block for the user:

```
My context is getting long, and that is where mistakes start. State is saved in
.claude/dispatch/HANDOFF.md and the ledger. Start a fresh session in this repo
(`claude --model claude-opus-5-5`) and run:

    /dispatch resume
```

Stop there. Do not start the next dispatch in the old session. (When you only suggested a
rotation and the user did not take it, carry on.)

## `/dispatch resume`

A fresh main session reads **only** these files, in this order: `AGENTS.md` (and `CLAUDE.md`),
`.claude/dispatch/HANDOFF.md`, `tail -n 20 .claude/dispatch/ledger.md`, the brief file that
`HANDOFF.md` names, `ROADMAP.md`'s header, table and current phase block when a roadmap exists
([planning.md](planning.md#roadmapmd)); polish is read later, as `grep` hits for each brief. Then it runs `git status
--porcelain` and `git rev-parse HEAD`, and checks that `HEAD` matches `BASE_HEAD`. If it does
not, someone committed in between: say so and take a new BASE. Say in at most five lines where
things stand and what comes next, then continue the cycle from `Next:`.

No `HANDOFF.md` → resume from the ledger's last line and say so. No ledger either → there is
nothing to resume; run `status`.

`.claude/dispatch/HANDOFF.md` is a working file, overwritten at each rotation. Bootstrap (Step 3)
proposes it for `.gitignore`.
