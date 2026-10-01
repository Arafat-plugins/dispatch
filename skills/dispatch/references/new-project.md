# New project — clarifying before you build

**Heavy** new work — a project/app/site/service built from scratch, an empty or near-empty
repo, or a new large subsystem (multiple modules, many files, its own data model) — needs
information gathered before a brief can be written. Skipping this produces a brief built on
guesses, and a first build the user rejects wholesale.

**Light** new things — one script, one small file, a snippet — skip intake, or need at most 1-2
questions. Do not run the order below for "write me a script that renames these files."

## When it applies

Concrete signals, not vibes:

- "Build me a `<thing>`" — an app, site, service, tool — with no existing code to extend
- An empty repo, or one with only scaffolding (README, license, no source)
- A new subsystem the size of its own module set: several files, its own data model, not a
  single addition to something that already exists

None of these hold → this is a normal dispatch. Plan from `AGENTS.md` as usual.

## Intake — three questions at most

Before you write anything, gather enough to plan — in **at most three questions**, one question
per message. In Claude Code, use `AskUserQuestion` with a single question per call and 2-4
concrete options ("you decide" is a legitimate option); elsewhere ask in plain text. Never batch
separate questions into one message.

1. **Purpose and users** — no default; ask it (skip if the user already said).
2. **MVP scope** — no default; ask it (skip if the user already said).
3. **Everything else, defaults first** ([speed.md](speed.md#questions--one-defaults-first-message-at-most))
   — stack, hosting, auth, integrations, design direction: propose a default for each from what
   the user already said and post them as **one** confirmation ("unless you change a line:
   Laravel + Inertia, Postgres, email login, no payments in v1 … say *go*"). A *go* settles all
   of them; a correction replaces that line and asks nothing new.

**A spec already exists** (the user attached or named a requirements document, master prompt or
client spec) → do not run the intake. Write `PROJECT_BRIEF.md` from the document, list only the
gaps it leaves as defaults, and ask for one confirmation.

**The 3-question ceiling counts across paths** — this intake, responsive.md's points and
setup.md step d share it. Responsive and design points go into the same defaults-first message
as item 3, not into questions of their own
([responsive.md](responsive.md#the-question-ceiling--at-most-3-across-every-path)).

Topics 1 and 4 below are intake items 1 and 2, asked on their own when not already answered;
topics 2, 3 and 5–10 go into the defaults-first message. Suggested order:

1. **Purpose and users** — "What is this for, and who uses it?"
2. **Platform** — "Web app / mobile app / desktop app / API / CLI?"
3. **Tech stack** — "Any stack preference, or should I choose one that fits?"
4. **MVP scope** — "What must v1 do? And what should explicitly wait — not in v1?"
5. **Data and auth** — "Does it store data? Do users log in?"
6. **Look and feel** — "Any design direction — a reference site, a vibe, brand colours?" UI
   project → add [responsive.md](responsive.md)'s points to the same defaults-first message.
7. **Integrations** — "Any third-party services — payments, email, external APIs?"
8. **Hosting** — "Where should this run once it's built?"
9. **Constraints** — "Deadline, budget, languages to support (e.g. Bangla + English),
   performance or accessibility requirements?" — the answers become `AGENTS.md` → Cross-cutting
   checks at bootstrap, each with its command, and the budget becomes the gate roll-up's yardstick
   ([planning.md](planning.md#usage-roll-up))
10. **Definition of done** — "How will you judge v1 is done — a demo, a checklist, a launch?"

Each topic above is a starting point, not a script — propose the default that fits what the
user already said, and skip what they already answered.

## Confirm before building

Summarise the answers as a short **project brief** and get an explicit yes before scaffolding
anything. Save it as `PROJECT_BRIEF.md` at the repo root — sections matching the questions
above, plus a final **Out of scope for v1** section. This file is the source for planning and
for every dispatch brief that follows; do not re-derive it from memory later.

## Then: scaffold, bootstrap, build

0. **A root commit first.** An empty repo has no `HEAD`: `git rev-parse HEAD` fails, so there
   is no BASE and acceptance cannot diff the scaffold. Propose the user's first commit, holding
   only the brief, and run it on a yes — this skill never commits on its own:
   ```bash
   git add PROJECT_BRIEF.md && git commit -m "chore: project brief"
   git rev-parse HEAD                                  # the repo now has a HEAD
   ```
   On a no, ask the user to make any first commit; do not dispatch the scaffold without one.
   This commit's sha is not the scaffold's BASE — step 3 takes that.
1. **Plan** — `/dispatch plan` ([planning.md](planning.md)): requirement IDs in
   `PROJECT_BRIEF.md`, then `ROADMAP.md` (phases, gates), `ARCHITECTURE.md` and `DOMAIN.md`
   ([architecture.md](architecture.md)), each shown as a diff and confirmed.
2. **Install the agent templates now, and restart once.** Run bootstrap's Step 0 and Step 3
   alone, choosing templates from `PROJECT_BRIEF.md`'s stack rather than from the (still empty)
   repo — a planned database means `dispatch-migrator`, planned tests mean
   `dispatch-test-writer` — and create the ledger. Then propose **one commit** holding the plan
   files and `.claude/agents/` (a second commit — never an amend), write
   `.claude/dispatch/HANDOFF.md` with `Next: scaffold P0` ([context.md](context.md)), and ask the
   user to restart the session (or run `/agents`). Templates installed mid-session are not
   selectable until then; doing it once, here, means the scaffold and every brief after it use
   the named agents. After the restart, `/dispatch resume` picks up from the handoff.
3. **Scaffold** phase P0's foundations only — on Opus 5.5, as every dispatch
   ([routing.md](routing.md#model-selection)). This dispatch is **exempt from SKILL.md's "no
   map, no dispatch" rule**: there is nothing to map yet. Its brief's Knowledge line reads "Read
   `PROJECT_BRIEF.md`, `ARCHITECTURE.md` and the P0 block of `ROADMAP.md`; there is no
   `AGENTS.md` yet", and its Inputs name the directories and files the scaffold may create.
   Take BASE **now**, right before this dispatch (`git rev-parse HEAD` after step 2's commit),
   so the plan files and templates are not in the scaffold's diff. Acceptance runs as usual.
4. Run **`/dispatch bootstrap`** so `AGENTS.md` exists before any feature dispatch —
   [bootstrap.md](bootstrap.md) reads `PROJECT_BRIEF.md` for "What this project is" when there
   is no code yet to survey, and writes Flows, Cross-cutting checks and Delivery capabilities
   from the plan.
5. **Build phase by phase**, the briefs `ROADMAP.md` lists, respecting the
   [2-concurrent-sub-agent cap](routing.md#concurrency-cap), each phase ending at its gate
   ([planning.md](planning.md#gates--the-user-signs-off-phase-by-phase)). A UI feature still
   settles responsive behaviour per responsive.md if `PROJECT_BRIEF.md`'s "Look and feel" did
   not already cover it.
