# The Verifier — security critic chain

A second model acting **exclusively as a critic**, evaluating the work against a spec written
from the actual change. It never edits. Its only output is findings.

Run after acceptance. Different question: acceptance asks *"does it do the job?"*, this asks
*"is it safe?"*

## Two stages, and why

```
accepted work
  │
  1. SCOUT   read-only: reads the diff, reports what actually changed
  │          → you write a security spec targeted at THAT change
  │
  2. CRITIC  dispatch-security-critic (haiku, read-only):
  │          evaluates the diff against your spec
  │
  → findings to the user; the user decides what to fix
```

The scout stage exists because a generic security checklist produces generic findings. A diff
that only touches CSS should not be asked about SQL injection — it wastes the review and buries
the one finding that matters. Write the spec from what changed.

If the repo already has a review agent (`ls .claude/agents/`), run it **first** and give the
critic its output as context. The two stack: the repo's agent knows the codebase's own rules,
the critic knows what to be suspicious of.

## Stage 1 — scout

```bash
git diff --stat
git diff
```

Reduce to: which files, which surfaces, and — the part that matters — **what kind of risk this
change can carry**. Map from what you see:

| The diff touches | Ask the critic about |
| --- | --- |
| Anything reading request input | Validation, sanitisation, type confusion |
| Output into HTML/JS/SQL/shell | Escaping at the point of output, context-correct |
| A query built with string concatenation | Parameterisation |
| An endpoint, route, or handler | Authentication, authorisation, rate limits |
| File paths from input | Traversal, symlinks, upload type checks |
| Auth, sessions, tokens, crypto | Timing, storage, expiry, algorithm choice |
| Dependencies or lockfiles | Provenance, known advisories, version pinning |
| Only styles / markup / copy | Content injection only — **say the rest is out of scope** |

Naming what is out of scope is as valuable as naming what is in.

## Stage 2 — the critic brief

```
## Role
You are a security critic. You evaluate; you do not edit. You have no write tools and you
must not request them. Your output is findings, or the sentence "No findings."

## The change
<scout summary: files, surfaces, what it does>

## Evaluate specifically for
<the mapped risks from the table — only the ones that apply>

## Out of scope
<everything the diff cannot affect — say it explicitly>
Do NOT report style, naming, formatting, performance, or architecture opinions.
Do NOT report on code the diff did not touch.

## For each finding, give exactly
- file:line
- what an attacker does, concretely — the input and the effect
- severity: high / medium / low
- confidence: certain / likely / speculative

If a concern is speculative, mark it speculative. Do not pad the list.
If there is nothing, say "No findings." That is a valid and expected result.

## Knowledge
Read AGENTS.md at the repo root first, then only the changed files.

[ task list broken down into phases, each phase as a vertical slice, numbered ]
```

## Handling findings

Report them to the user grouped by severity, each with the concrete attack. Then stop.

- **Never auto-fix.** A fix is a new change and goes through the full cycle — plan, brief,
  dispatch, accept.
- **Never auto-commit or push.**
- **Do not launder confidence.** A finding the critic marked speculative stays speculative when
  you report it. Passing along a maybe as a certainty is worse than not reviewing at all.
- **"No findings" is reportable as-is.** Do not go hunting for something to say.
