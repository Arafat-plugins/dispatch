# dispatch

A Claude Code / agent skill that keeps the **main session's context clean** by delegating
implementation work to sub-agents — with a written spec, exact file paths, and an acceptance
check the main session performs itself.

```bash
npx skills add Arafat-plugins/dispatch
```

## The problem

Two things go wrong when you hand work to sub-agents:

1. **The sub-agent surveys the whole codebase** before doing anything, because nobody told it
   where to look. Slow, expensive, and it still guesses.
2. **The main session reads everything anyway** — to write the brief, to check the result — so
   the context you were trying to protect fills up regardless.

## The approach

The main session holds the **map, not the territory**.

- It reads `AGENTS.md` — a compact repo map, a few KB — and nothing else about the codebase.
- It locates files by path (one `grep`), and never opens them.
- It writes an explicit spec: inputs, audience, format, out-of-scope, and a checkable
  "done means" list.
- The sub-agent does the reading and the editing.
- The main session reads the **diff** and judges it against the spec it wrote.

Rejected work is re-dispatched, never hand-fixed — hand-fixing is how the file contents end up
in your context anyway.

## Usage

```
/dispatch bootstrap          # once per repo — writes AGENTS.md, installs agent templates
/dispatch <task>             # plan → locate → brief → work → accept
/dispatch verify             # security critic pass over the current diff
/dispatch db <check>         # read-only database inspection
/dispatch status             # what's set up, what's missing
```

**Run `bootstrap` first.** It surveys the repo once and writes `AGENTS.md` — the map every later
dispatch depends on. Without it, sub-agents go back to surveying and the skill does nothing for
you.

## What bootstrap installs

Generic agent templates in `.claude/agents/`, skipped if a file of that name already exists:

| Agent | Model | Role |
| --- | --- | --- |
| `dispatch-implementer` | sonnet | Server logic, APIs, data access |
| `dispatch-frontend` | sonnet | CSS, layout, responsive |
| `dispatch-db-tester` | sonnet | Read-only database inspection |
| `dispatch-security-critic` | haiku | Critic only — never edits |

If your repo already has purpose-built agents, routing prefers them. They know your conventions;
these templates do not.

## Design notes

Three ideas do the work:

**The Spec.** A brief is an engineering recipe: explicit inputs, the intended consumer, a format
guide, and — the part most people skip — an explicit list of what to leave alone. An
unconstrained agent refactors, renames, and adds dependencies, and every one of those is a diff
you now have to review.

**The Verifier.** A second model acts *exclusively* as a critic, evaluating against a spec
written from the actual diff. It has no write tools. A generic security checklist produces
generic findings; the scout stage exists so the critic is asked about risks the change can
actually carry.

**The Knowledge Base.** `AGENTS.md` is written for sub-agents, not humans. Its two most valuable
sections are the ones people skip: *what not to bother reading*, and the *known-failing
baseline* — so no future agent re-debugs a test that was already red on a clean checkout.

Every dispatch prompt ends, verbatim, with:

```
[ task list broken down into phases, each phase as a vertical slice, numbered ]
```

Last position, so it is the final instruction read.

## Compatibility

Needs an agent runtime that can spawn sub-agents and run shell commands. Built for Claude Code;
the protocol itself is portable. Git is required for the acceptance and verify steps.

Frontmatter is restricted to the Agent Skills spec subset (`name`, `description`, `license`,
`compatibility`, `metadata`), so the skill packages cleanly for non-Claude-Code runtimes too.

## Layout

```
skills/dispatch/
  SKILL.md              the dispatch protocol
  references/
    prompt-spec.md      how a brief is assembled, with a worked example
    routing.md          picking the agent
    acceptance.md       the main session's own check
    verifier.md         the security critic chain
    bootstrap.md        building AGENTS.md
    db-check.md         database inspection briefs
  agents/               templates installed by bootstrap
  examples/             a real generated AGENTS.md
```

## License

MIT
