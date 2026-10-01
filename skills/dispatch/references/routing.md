# Routing — picking the agent

## Discover before you assume

Agents are per-repo. Never hardcode a name; look:

```bash
find .claude/agents -maxdepth 1 -name '*.md' -exec head -4 {} + 2>/dev/null
```

The `description` line in each agent's frontmatter says what it is for. Match the task to a
description. If the repo has purpose-built agents, **prefer them** — they carry conventions a
generic agent does not.

If the repo has none, `/dispatch bootstrap` installs the generic set below.

## Routing table

| The task is about | Agent | Why |
| --- | --- | --- |
| Server logic, APIs, data access, business rules — a whole flow step, all layers | `dispatch-implementer` | Edits code, writes and runs tests |
| Layout, CSS, responsive, anything judged by looking | `dispatch-frontend` | Needs to render and measure |
| Writing a schema change, backfill, seed or grant | `dispatch-migrator` | Dev database only; migrate → rollback → migrate ([migrations.md](migrations.md)) |
| Tests only — closing a `Test: none — gap`, test-first for a slice, E2E user flows | `dispatch-test-writer` | Writes tests, never app code |
| Inspecting data, schema, integrity, query plans | `dispatch-db-tester` | Read-only DB inspection |
| "Is this change safe?" — per task, only when the diff touches a security surface (speed.md); `/dispatch audit` per phase | `dispatch-security-critic` | Critic only, never edits |
| "Does the phase still fit the architecture and domain rules?" — per gate | `dispatch-reviewer` | Findings only: layering, rule and permission drift, queries |
| Reviewing a diff before commit | repo's own review agent, else `dispatch-security-critic` | |

**Roles without a template of their own** go to `dispatch-implementer`, with a first line in
the brief's Task naming the role and the reference that governs it:

| The task is about | Brief it as | Governed by |
| --- | --- | --- |
| CI pipeline, deploy kit, backups, runbooks, cutover | `Delivery brief (delivery.md): …` | [delivery.md](delivery.md) |
| Documentation — README, runbook text, API docs | `Docs brief: …` — Inputs are the doc files only | prompt-spec.md; Verbatim for user text |
| Performance — a measured slow page or query | `Performance brief: …` — Current wrong behaviour is a number (ms, queries) | the before/after number in Done means |
| Data import / ETL from another system | `Migration brief (migrations.md): …`, kind *data* — to `dispatch-migrator` | [migrations.md](migrations.md) |
| i18n — strings, locales, RTL | `i18n brief: …` — the locale files plus the views that use them | AGENTS.md → Cross-cutting checks |
| Accessibility fixes | to `dispatch-frontend`, with the `--a11y` lines in Done means | AGENTS.md → Cross-cutting checks |

**Polish is not a routing target.** There is no agent for it and no row above: it goes to a
second Claude session, never to a sub-agent of this one ([polish.md](polish.md)).

**No scout.** "Which file does X?" is not a dispatch. Locating files and lines is part of
planning, and planning is the main session's: `grep -rn`, `git grep -n`, then a ≤ 60-line read
around the hit (prompt-spec.md). The verify chain's "scout stage" is also you, reusing the diff
you already read at acceptance (verifier.md).

## When the agent name is not recognised

Templates copied into `.claude/agents/` during this session are usually not loaded until the
session restarts or `/agents` reloads them. If the runtime rejects `dispatch-implementer` (or
any of the templates), do not wait and do not skip the dispatch:

1. Use a general-purpose sub-agent.
2. Paste the template's body — everything below its frontmatter — at the top of the brief,
   under a `## Role` heading. Path: `.claude/agents/<name>.md` (installed) or
   `<SKILL_DIR>/agents/<name>.md` (the path bootstrap.md, Step 0, recorded in your plan).
3. State the tool restriction in words inside the brief ("you have no browser; you are
   read-only; do not write files") — a general-purpose agent has every tool.
4. Set the model to Opus 5.5 on the call ([Model selection](#model-selection)) — the
   fallback has no frontmatter to supply it. It inherits the session's effort, which cannot be
   set to `high` per call; note that in the plan (see [Effort](#effort)).
5. Tell the user a restart makes the named agents available.

## Rules

**One job per dispatch — and a job is a vertical slice.** "Fix the CSS and also add the REST
field" is two briefs to two agents: a single agent given two unrelated jobs produces a diff you
cannot accept or reject cleanly. But one step of a backend flow — migration, model, service,
handler, validation, the wiring that shows it, and its flow test — is **one** job for **one**
`dispatch-implementer`, not four dispatches by layer; splitting by layer is how the handoff
between them gets lost ([flows.md](flows.md#slice-by-flow-step-not-by-layer)).

**Read-only work goes to a read-only agent** (critic, reviewer, db-tester). Do not give edit
tools to a question. Finding *where* something is, you do yourself.

**Never dispatch the same brief twice hoping for a different result.** An attempt that came back
and was rejected gets a brief that changed — the original plus what failed and the corrected
step on the first rejection, rewritten steps on the second. A third failure stops the
loop (failures.md).

The one narrow exception: the run errored or timed out and **nothing changed** — the tree is
identical to BASE. No attempt was made, so there is no result to differ from; re-dispatch the
identical brief once (failures.md, case 2). A second error there is treated as a rejection and
the brief is rewritten.

**Sequence, do not parallelise, when work touches the same files.** Two agents editing one file
produce a diff neither of them intended. Parallel dispatch is fine only for genuinely disjoint
file sets — say so explicitly in each brief, and give each sub-agent its own worktree
(`isolation: "worktree"` on the Agent tool in Claude Code) so the diffs stay separable
(acceptance.md). Without isolation, two parallel diffs are one diff. Parallel also means the
[concurrency cap](#concurrency-cap) below: at most 2 at once, whatever the file split.

## Concurrency cap

**At most 2 sub-agents running at once, counting every kind** — workers, the critic, the
reviewer, the db-tester. Track how many are in flight; a third one queues behind them, it does not run
alongside them.

A plan that fans out beyond 2 at once (several disjoint surfaces of one big project, say) is
not a default — ask the user before dispatching the third:

```
This needs 3 sub-agents in parallel: <job A>, <job B>, <job C> — disjoint files, listed above.
Capped at 2, job C waits ~<estimate> for one to finish. Run 3 concurrent instead, or keep the
queue?
```

Proceed past 2 only on an explicit yes, and only for that plan — the cap applies again on the
next dispatch.

**Read-only agents need an idle tree.** The critic, the reviewer and the db-tester are checked by comparing
`git status --porcelain` before and after they run (acceptance.md, "After the critic"). A worker
editing the same working tree meanwhile changes that output, and the check can no longer tell
whose change it was. So the second slot may hold one of them only while **no other agent is
editing the same tree** — a worker in its own worktree does not count; queue the critic behind
a worker that shares your tree.

## Model selection

**One model for every sub-agent: Opus 5.5** (`claude-opus-5-5`). Implementer, frontend,
db-tester, security critic, reviewer, a general-purpose fallback — light copy fix or new
subsystem, one-line diff or thousand-line scaffold. There is no light/heavy split any more and
no downgrade path: never `sonnet`, never `haiku`, never `fable`, for any role, for any size.

**Set it on the Agent tool call, every dispatch** — the per-call `model` parameter overrides the
agent file's frontmatter, and an agent with no `model:` line (a general-purpose fallback, a
repo's own agent) otherwise runs on whatever default the runtime gives it, which can be a small,
fast model. Pass:

| The `model` parameter accepts | Pass |
| --- | --- |
| a full model ID | `claude-opus-5-5` |
| aliases only (an enum such as `sonnet` / `opus` / `haiku` / `fable`) | `opus` — it resolves to Opus 5.5; `status` check 11 confirms the pin |

State it in the plan, one line: `model: Opus 5.5 (claude-opus-5-5)`. No reason line is needed —
there is no choice to justify.

**Template defaults.** All seven templates ship `model: claude-opus-5-5` in frontmatter — a full
ID, not the `opus` alias, so an installed copy keeps pointing at Opus 5.5 even after the alias
moves to a newer model. The per-call parameter is still set every time: it is what covers the
agents that have no frontmatter of yours. `dispatch-security-critic` in particular is **never**
dispatched on another model — not for a one-file diff, not for a copy change, not because it is
read-only; size is not a reason to think less hard about safety.

**Repo's own agents.** A purpose-built agent whose `model:` line names something else still runs
on Opus 5.5 — the per-call parameter wins. Tell the user once that its frontmatter disagrees and
suggest `model: claude-opus-5-5`; do not edit it without a yes.

**Pinning the rest of the runtime (optional, on the user's yes).** Bootstrap Step 3 offers two
lines in `.claude/settings.json`, so sessions and sub-agents the skill does not dispatch land on
Opus 5.5 too:

```json
{
  "model": "claude-opus-5-5",
  "env": { "CLAUDE_CODE_SUBAGENT_MODEL": "claude-opus-5-5" }
}
```

`model` is the session default for this repo — main and polish sessions alike; the env var is
the fallback for any sub-agent that has neither a per-call nor a frontmatter model. Neither
replaces setting the per-call parameter.

**Changing the model** is the user's decision, like effort — per repo, in the installed copies
and the settings file. Never switch it yourself: not down to save cost, not to "a different
model" to rescue a failing brief (a failing brief is rewritten, failures.md).

The **main session** should run on Opus 5.5 too (`claude --model claude-opus-5-5`, or `/model`).
The skill cannot switch it mid-task; if the session is on another model, say so once at the
start of the first dispatch and carry on.

## Effort

**Every sub-agent runs at `effort: high`.** Model picks *how capable*; effort picks *how long
it thinks*. High is the setting for a briefed job on Opus 5.5, whatever its size.

- **Where it is set:** the `effort:` line in each agent file's frontmatter. All seven templates
  ship with `effort: high`. The Agent tool has **no per-call effort parameter**, so there is
  nothing to set on the dispatch itself — only check the installed file still says `high`.
- **Repo's own agents:** if a purpose-built agent has no `effort:` line it inherits the
  session's effort. Tell the user once, and suggest adding `effort: high` to it.
- **Fallback sub-agent** (a general-purpose agent carrying a template body — see above): it
  inherits the session's effort and nothing in the call can change that. Say so in the plan.
- **Changing it** — `low`, `medium`, `xhigh`, `max` — is the user's decision, per repo, in the
  installed copies. Never change it yourself to rescue a failing brief; a failing brief is
  rewritten (failures.md), not thought about harder.
