---
name: dispatch
description: Delegate implementation work to sub-agents while the main session keeps a clean context. The main session plans, hands each sub-agent an explicit written spec plus the exact files to touch, then judges the returned diff itself. Run `/dispatch bootstrap` once per repo to generate the AGENTS.md map that sub-agents read instead of surveying the codebase. Use when a task needs real file edits, when the main session is filling up with file contents it does not need, when sub-agents keep re-reading the whole project before doing anything, or when the user asks to dispatch, delegate, orchestrate, or route work to sub-agents.
license: MIT
compatibility: Any agent runtime that can spawn sub-agents and run shell commands. Built for Claude Code; the protocol works anywhere sub-agents and git are available. Git is required for the acceptance and verify steps.
metadata:
  version: 1.0.0
  author: Arafat-plugins
---

# Dispatch

You are the **owner** of this task, not a relay. You hold the plan and the working
knowledge of the repo. You do not burn your context doing the work.

## The one rule

**Hold the map, not the territory.**

- Read `AGENTS.md` (and `CLAUDE.md` if present). Compact, stable, a few KB. That is your
  knowledge of this repo.
- **Do not open the files you are about to dispatch.** Locating a file is cheap — one `grep`,
  one line of output. Reading 900 lines of a stylesheet is not. The sub-agent reads it.
- On acceptance, read the **diff**, never the whole file. The diff is what you are judging.

Every rule below serves this one. If you catch yourself reading a file's contents to decide
what to put in a brief, stop — that is the sub-agent's job.

## Your three roles, in order

1. **Planner** — decide what the change actually is. Ask the user if the ask is ambiguous.
2. **Dispatcher** — hand a specific job to a specific agent with specific references.
   Never "go figure out the codebase."
3. **Acceptance checker** — read what came back and judge whether it does the job.
   **This is yours. Do not delegate it.**

## Modes

Pick by what follows the command. With no argument, run `status`.

| Invocation | Mode |
| --- | --- |
| `/dispatch bootstrap` | Generate `AGENTS.md` for this repo + install agent templates. **Run this first.** |
| `/dispatch <task>` | The full cycle: plan → locate → brief → work → accept |
| `/dispatch verify` | Security critic chain over the current diff |
| `/dispatch db <check>` | Database inspection via the db-tester agent |
| `/dispatch status` | What is set up, what is missing, what to run next |

## First: is this repo bootstrapped?

```bash
ls AGENTS.md .claude/agents/ 2>/dev/null
```

If `AGENTS.md` does not exist, say so and offer `bootstrap` before anything else. A dispatch
without a map is exactly the situation this skill exists to prevent — the sub-agent will start
surveying. Do not proceed to a task dispatch with no map unless the user tells you to.

Read **[references/bootstrap.md](references/bootstrap.md)** when running bootstrap.

## The dispatch cycle

### 1. PLAN
Decide what the change is, from `AGENTS.md` + `CLAUDE.md` only. If the request is ambiguous in a
way that changes the work, ask now — not after a sub-agent has written the wrong thing.

### 2. LOCATE
Resolve exact paths. Paths only, no contents:

```bash
grep -rl "<symbol or selector>" --include="*.<ext>" . | head
```

If `AGENTS.md` already names the owning file for this surface, use it and skip the grep.
If you cannot narrow to a small set of files, dispatch a **read-only scout** to find them and
return paths — not a worker who both searches and edits.

### 3. BRIEF
Assemble the spec. Read **[references/prompt-spec.md](references/prompt-spec.md)** for the
template and the worked example. Every brief carries, at minimum:

- **Inputs** — exact file paths, the current wrong behaviour
- **Audience** — what consumes this code and what contract it must keep
- **Format** — the conventions of the file being edited
- **Out of scope** — explicit "do NOT touch X, do NOT refactor Y, do NOT survey the repo"
- **Knowledge** — "read `AGENTS.md` first, then only the files named above"
- **Footer** — the phase line, verbatim, always (see below)

Pick the agent with **[references/routing.md](references/routing.md)**.

### 4. WORK
The sub-agent implements and reports back. You wait. You do not read along.

### 5. ACCEPT
Yours alone. Read **[references/acceptance.md](references/acceptance.md)**.

```bash
git diff --stat
git diff
```

Judge the diff against the spec *you wrote in step 3*. That is why the spec must be explicit
up front — a vague brief cannot be checked.

- **Accept** → say what landed, move to verify.
- **Reject** → re-dispatch with what was wrong and why. **Do not hand-fix it yourself** — that
  is how your context fills with the file contents you were avoiding. Two rejections on the same
  brief means the brief is wrong, not the agent. Rewrite the spec.

### 6. VERIFY
Read **[references/verifier.md](references/verifier.md)**. Separate question from step 5:
step 5 asks *"does it do the job?"*, verify asks *"is it safe?"*

## The mandatory footer

Every dispatch prompt ends with this line, character for character, as the last line:

```
[ task list broken down into phases, each phase as a vertical slice, numbered ]
```

No exceptions, no paraphrase, no reordering. It goes last so it is the final instruction the
sub-agent reads. A vertical slice means each phase is independently checkable end to end — not
"phase 1: write the CSS, phase 2: test the CSS", but "phase 1: mobile layout correct and
verified, phase 2: tablet layout correct and verified".

## Non-negotiables

- Never dispatch a job whose brief you could not check the result of.
- Never let a sub-agent both decide *what* to do and *whether it worked*. Those are your calls.
- The security critic **only criticises** — it never edits.
- Findings are advisory. Never auto-fix, never auto-commit, never push.
- If you skip acceptance because the change "looks fine", you have not used this skill.
