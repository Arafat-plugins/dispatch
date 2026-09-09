# Routing — picking the agent

## Discover before you assume

Agents are per-repo. Never hardcode a name; look:

```bash
ls .claude/agents/*.md 2>/dev/null && head -4 .claude/agents/*.md
```

The `description` line in each agent's frontmatter says what it is for. Match the task to a
description. If the repo has purpose-built agents, **prefer them** — they carry conventions a
generic agent does not.

If the repo has none, `/dispatch bootstrap` installs the generic set below.

## Routing table

| The task is about | Agent | Why |
| --- | --- | --- |
| Server logic, APIs, data access, business rules | `dispatch-implementer` | Edits code, runs tests |
| Layout, CSS, responsive, anything judged by looking | `dispatch-frontend` | Needs to render and measure |
| "Which file does X?", "where is Y defined?" | `Explore` (or any read-only agent) | Returns paths, edits nothing |
| Schema, queries, migrations, data integrity | `dispatch-db-tester` | Read-only DB inspection |
| "Is this change safe?" | `dispatch-security-critic` | Critic only, never edits |
| Reviewing a diff before commit | repo's own review agent, else `dispatch-security-critic` | |

## Rules

**One job per dispatch.** "Fix the CSS and also add the REST field" is two briefs to two agents.
A single agent given two jobs produces a diff you cannot accept or reject cleanly — half of it
is right.

**Read-only work goes to a read-only agent.** If you need to know *where* something is, dispatch
a scout that returns paths. Do not give edit tools to a question.

**Never dispatch the same brief twice hoping for a different result.** A second failure means
the brief is wrong. Rewrite the spec, then dispatch.

**Sequence, do not parallelise, when work touches the same files.** Two agents editing one file
produce a diff neither of them intended. Parallel dispatch is fine only for genuinely disjoint
file sets — and say so explicitly in each brief.

## Model selection

Set in each agent's own frontmatter, once:

- workers → `model: sonnet`
- the security critic → `model: haiku`

Nothing switches mid-task. The main session stays whatever the user is running.
