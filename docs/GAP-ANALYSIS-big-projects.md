# dispatch v1.7.0 — gap analysis for big builds

**Question:** how far is `dispatch` from being able to carry a *large* build — an ERP, a
multi-module web app, a SaaS with its own data model — from idea to production?
**Reviewed:** v1.7.0 (this branch): `SKILL.md`, all 14 references, 4 agent templates, the
measure script, `validate.sh`, 21 evals, README and CHANGELOG. About 2,900 lines of instructions.
**Lens:** skill design (triggering, progressive disclosure, testability) and large-project
delivery (planning, continuity, contracts, integration, release).
**Real-world evidence:** the GoodTechies HQ build (an agency operating system: 13 phases, finance,
payroll, leave, chat, reports, 2,776 tests) ran on dispatch v1.5.1. It worked, but only because a
1,000+-line master prompt supplied the project layer the skill does not have (details below).

> **Status — 1.9.0 (2026-09-27): every gap below has a fix in the skill.** This report is kept
> as written for 1.7.0; the table records where each gap was closed. Readiness figures in §1 and
> §3 are the 1.7.0 baseline — the fixes are untested on a real build until the next one runs.
>
> | Gap | Status | Where |
> | --- | --- | --- |
> | G1 plan layer | closed | `/dispatch plan`, `references/planning.md` — requirement IDs, `ROADMAP.md`, gates |
> | G2 cross-session memory | closed (1.8.0) | ledger, briefs on disk — `references/context.md` |
> | G3 context growth | closed (1.8.0) | rotation, `HANDOFF.md`, `/dispatch resume` |
> | G4 architecture/domain | closed | `references/architecture.md` — `ARCHITECTURE.md`, `DOMAIN.md` (BR-nn, permissions), ADRs |
> | G5 tests in the contract | closed (1.8.0 + 1.9.0) | fail-at-BASE tests, targeted/full shards, `dispatch-test-writer` |
> | G6 migrations | closed | `/dispatch migrate`, `references/migrations.md`, `dispatch-migrator` |
> | G7 merging parallel work | closed | `references/integration.md` §1 — apply-back + integration acceptance |
> | G8 checkpoints | closed | `references/integration.md` §2 — proposed commit, optional standing yes |
> | G9 map scaling | closed | module maps + map upkeep in every brief — `integration.md` §3–4 |
> | G10 intake / spec ingest | closed (1.8.0 + 1.9.0) | spec replaces intake; requirement IDs traced to phases |
> | G11 roles | closed | 3 new templates (migrator, test-writer, reviewer) + routing rows for delivery, docs, perf, ETL, i18n, a11y |
> | G12 review beyond security | closed | `dispatch-reviewer`, once per gate |
> | G13 system-level security | closed | `/dispatch audit`, `THREAT-MODEL.md` — `references/audit.md` |
> | G14 delivery | closed | `references/delivery.md` — clean-room checked artefacts; the user deploys |
> | G15 non-web platforms | narrowed | per-platform recipes in `setup.md` (Flutter goldens, Maestro/Detox, Electron, golden output); no new tooling |
> | G16 a11y / i18n / perf | closed | Cross-cutting checks in `AGENTS.md`; `dispatch-measure.mjs --a11y` (basic checks, not a full audit) |
> | G17 cost visibility | closed | ledger minutes + per-phase roll-up at gates against an optional budget |
> | G18 triggers | closed | description names build / new app / ERP / plan; `evals/triggers.json` |
> | G19 skill reading cost | closed (1.8.0) | `references/cycle-card.md` |
> | G20 evals | narrowed | `evals/evals.json` generated in skill-creator format + a multi-session big-build eval; `validate.sh` still checks many exact phrases |
> | G21 restart timing | closed | `new-project.md` installs templates before the scaffold, one restart |

---

## 1. Verdict

`dispatch` is a strong **per-change** protocol. It has almost no **per-project** layer.

| Kind of work | Readiness | Why |
| --- | --- | --- |
| A fix or small change in an existing repo | **~90 %** | Map, brief, baseline, diff-based acceptance, critic, and failure handling are all mature. |
| A feature in an existing app (1–10 dispatches) | **~80 %** | Works well. Tests, migrations and merging parallel work are left to the user. |
| A new big app or ERP, end to end (100+ dispatches, many sessions) | **~45 %** | No roadmap, no progress ledger, no way to resume, no architecture or domain source of truth, no migration or test contract, no path from code to deployment. |

The GoodTechies HQ master prompt says it directly: *"dispatch decides **how work is delegated**,
this prompt decides **what is built and in which order**."* Everything in that second half is
this report's gap list. It includes a phase table with human gates (Part E), a
`PROGRESS.md` protocol so "a new session can continue from this file alone" (Part G), a
phase-to-brief split (Part J), a migrator database role, tests split into shards, a deploy kit
and a cutover runbook. The skill supplied none of it. The progress file also shows what happens
without a protocol: *"this header and the table below had gone four phases stale."*

---

## 2. What already works — keep it

- **Hold the map, not the territory.** `AGENTS.md`, locating by path only, and reading the diff
  instead of the file. This is the right core idea for large codebases.
- **The brief** (`prompt-spec.md`). It has explicit Inputs, Out of scope and a checkable
  "Done means", and it ends with the phase footer.
- **Acceptance you do yourself.** It diffs a BASE snapshot against an AFTER snapshot, so files
  the sub-agent created are included. It checks commits and ignored files, and handles a large
  diff by reading `--stat` first.
- **Failure handling** (`failures.md`). The first failure gets more detail in the brief, the
  second gets a rewritten brief, and the third stops and goes to the user.
- **The security critic.** It judges risks mapped from what the diff actually touches, and it
  is read-only by instruction and checked with `git status`.
- **Setup provisions the checking tools** (browser, measure script, `DESIGN.md`, read-only DB
  user) and records them. It does not assume they exist.
- **Dependencies get their own dispatch**, and **polish runs in a second session** with an index.
  The polish index (`INDEX.md`) is the right pattern for keeping a large project's state
  compact. It exists for polish only.
- **One model (new in 1.7.0).** Every sub-agent runs on Opus 5.5, including the scout and the
  fallback. The planner no longer has to pick a model per task.

---

## 3. Scorecard across the full lifecycle

Scores run from 0 (absent) to 5 (complete for a large build).

| Stage | What a large build needs | What dispatch has | Score |
| --- | --- | --- | --- |
| Discover | Ingest an existing spec, per-module requirements, acceptance criteria | 10 generic intake questions, at most 8 asked, then `PROJECT_BRIEF.md` | 2 |
| Architect | Module boundaries, data model, API contracts, permission matrix, decision records | nothing (`DESIGN.md` covers UI only) | 0 |
| Plan | Roadmap of vertical-slice phases, dependencies between them, human gates | "Split the build into dispatches as normal" (`new-project.md:82`) | 1 |
| Build: one change | Brief, route, work, accept | full cycle | 5 |
| Build: across sessions | Progress ledger, resume, session rotation | polish index only; BASE and the plan live in the conversation | 1 |
| Test | Tests required per slice, sharded runs, integration and E2E tests | the implementer only *runs* the listed tests (`dispatch-implementer.md:58`) | 2 |
| Data | Migration write path, migrator role, seeds, data import | read-only db-tester only | 1 |
| Integrate | Merge parallel worktrees, integration acceptance | "merge only after acceptance", with no procedure (`acceptance.md:73`) | 1 |
| Review | Security, plus architecture, performance and conventions per phase | security only; the others are excluded by design (`verifier.md:142`) | 3 |
| Release | CI, environments and secrets, deploy, backups, runbooks, cutover | nothing (intake asks "Hosting" and then drops it) | 0 |
| Skill quality | Trigger coverage, automated evals, compact core | 21 evals run by hand; `validate.sh` checks exact phrases | 2 |

---

## 4. The gaps

Each gap lists what is missing, where that shows in the skill, why it hurts on a big build,
and a proposed fix. Priority: **P0** blocks a big build, **P1** makes one slow or risky,
**P2** is polish.

### P0 — blocks a big build

#### G1 · No project plan layer (roadmap, phases, gates)
- **Missing:** everything between `PROJECT_BRIEF.md` and a single dispatch. There are no
  milestones, no dependency order (auth, then tenancy, then master data, then transactions,
  then reports), no human gates, and no "definition of done" for a phase.
- **Evidence:** `new-project.md:82` covers the whole build in one sentence.
  GoodTechies needed Part E (phases and gates A–F) and Part J (splitting a phase into briefs)
  of its master prompt to fill this.
- **Fix:** add `/dispatch plan`, which writes `ROADMAP.md`. It holds phases as vertical slices
  (what the user can click at the end of each), the dependencies between phases, the gates the
  user signs off, and each phase's list of planned briefs. Add a new `references/planning.md`
  with the method for splitting a phase into briefs, a size budget per brief (≤ ~300 changed
  lines, to match `failures.md` case 5), and the rule that a phase ends with a gate question
  to the user.

#### G2 · No memory across sessions (ledger and resume)
- **Missing:** a durable record of what was dispatched, accepted and verified, and what comes
  next. BASE, AFTER, the plan and the attempt counts live only in the conversation.
  `acceptance.md` offers saving BASE to `.git/dispatch-base` as an option, and that is the only
  thing that survives.
- **Evidence:** polish has `INDEX.md`, but dispatch itself has nothing equivalent. GoodTechies
  invented `PROGRESS.md`, which then went four phases stale.
- **Fix:** add `.claude/dispatch/ledger/INDEX.md`, built like the polish index: one entry per
  accepted dispatch with the title, a two-line summary, `touches:`, BASE and AFTER, the verify
  result and the number of attempts. It is written at the end of step 6, **in the same step**,
  so it cannot go stale. Add `/dispatch resume`, which reads `ROADMAP.md` plus the last N
  ledger entries and proposes the next brief. `status` would then report the current phase and
  what comes next.

#### G3 · The main session's context grows without limit on long builds
- **Missing:** a rule for when to end the main session and start a fresh one. Every acceptance
  reads a diff of up to about 300 lines. Over 100+ dispatches the main session fills with diffs,
  which is exactly the problem the skill exists to prevent, only slower.
- **Fix:** set a rotation rule. At every phase boundary, or after about 15 accepted dispatches,
  the main session updates the ledger and `ROADMAP.md`, prints a resume command, and stops.
  The next session starts with `/dispatch resume`. This is the polish-session idea applied to
  the build itself.

#### G4 · No architecture or domain source of truth
- **Missing:** a counterpart to `DESIGN.md` for everything that is not UI: module boundaries
  and layering, the data model (entities and relations), API contracts, the roles-and-permissions
  matrix, business rules (tax, payroll, stock valuation), a domain glossary, and decision records.
- **Why it matters:** in an ERP the expensive mistakes are wrong business rules and wrong
  authorisation, not CSS. Right now each brief has to restate them, or they drift from one
  dispatch to the next.
- **Fix:** add `ARCHITECTURE.md`, `DOMAIN.md` and `docs/adr/`, generated at `/dispatch plan` and
  confirmed by the user. Briefs cite them by section, the way UI briefs cite `DESIGN.md`
  components. The implementer stops when a brief contradicts them, just as the frontend agent
  does with `DESIGN.md`. Acceptance treats a diff that breaks a documented rule or permission as
  a finding.

#### G5 · Tests are not part of the contract
- **Missing:** a requirement to write tests. The implementer runs the existing lint and test
  commands, compares against the baseline, and reports. No brief template asks for a test that
  fails before the change and passes after it. There is no guidance on integration or
  end-to-end tests of user flows; the measure script checks widths, not behaviour.
- **Also:** bootstrap gives the whole suite a 600 s timeout (`bootstrap.md:201`). GoodTechies'
  2,776 tests had to be run "in the nine parts `AGENTS.md` lists — one process times out".
  The skill has no concept of test shards.
- **Fix:** in `prompt-spec.md`, add a **Tests** section required for business logic: which
  test to add, what it asserts, and that it fails at BASE. In `AGENTS.md` → Commands, add
  sharded test commands with a timeout per shard. In acceptance, run the new test against BASE
  (it must fail) and AFTER (it must pass). Optionally add a `dispatch-test-writer` role for
  writing tests before the code.

#### G6 · Schema migrations have no write path
- **Missing:** the db-tester is read-only, and it should be. But nothing covers *writing*
  migrations: a brief template, reversible up/down migrations, a separate migrator database
  role, seed and fixture data, data migrations on existing rows, or importing data from a
  legacy system (ERP cutover).
- **Evidence:** GoodTechies needed a `pgsql_migrator` connection, a `roles.sql` file, a test
  that audit logs are append-only, and a ClickUp importer. All of it was specified outside the
  skill.
- **Fix:** add `references/migrations.md` and a `/dispatch migrate` brief type. Inputs are the
  migration files only. Done means requires `migrate` then `rollback` then `migrate` to pass on
  the development database, plus a db-tester check of the result. It runs under a migrator role
  recorded in *Verification capabilities*. The critic is asked about locking, data loss and
  privilege grants.

### P1 — makes a big build slow or risky

#### G7 · Parallel work cannot be merged back
- `acceptance.md:73` says "merge only after acceptance", but briefs forbid commits. The
  worktree therefore holds uncommitted changes, and no procedure says how they reach the main
  tree (a patch, a commit then a merge, or a cherry-pick), how conflicts are handled, or how the
  combined result is accepted.
- **Fix:** add an integration step. Export the accepted worktree diff as a patch from the two
  snapshots, apply it to the main tree, re-run the tests, run an **integration acceptance**
  over the combined diff, then remove the worktree.

#### G8 · No checkpoints (the skill never commits)
- Never committing on its own is the right default, but a long build needs a checkpoint after
  every accepted slice. Otherwise the tree stays dirty, BASE turns into a snapshot tree, and one
  bad dispatch can tangle several accepted ones.
- **Fix:** after accept and verify, draft a commit command and message (Conventional Commits,
  with the ledger entry number) and run it only on the user's yes. The ledger records the
  commit sha. A repo can opt in to "commit on accept" through a line in `AGENTS.md`.

#### G9 · The map does not scale to many modules
- `AGENTS.md` is limited to about 200 lines (`bootstrap.md:92`) and Surfaces to about 60 rows
  (`bootstrap.md:187`). An ERP with 15 modules and 300+ routes turns into rows like
  `/admin/* (42 routes)`. Per-package maps exist only for monorepos, and only for packages the
  user names. The map is refreshed only by re-running bootstrap.
- **Fix:** add module maps (`<module>/AGENTS.md`), with the root file as an index, even outside
  monorepos. Make **map maintenance part of acceptance**: a dispatch that adds a route, module or
  directory adds its row in the same brief, and acceptance checks it.

#### G10 · The intake is too small for an ERP and cannot read an existing spec
- A ceiling of 8 questions across the whole task, with 10 generic questions, suits "build me an
  app", not "build our accounting, HR and inventory". There is no path for a client spec that
  already exists. GoodTechies had to say *"Do not run `/dispatch new` intake."*
- **Fix:** add `/dispatch new --from <spec.md|pdf>`, which extracts `PROJECT_BRIEF.md` from the
  spec and asks only about gaps. Add a short per-module intake with its own question ceiling.
  Add IDs for requirements and acceptance criteria that `ROADMAP.md` phases and brief
  "Done means" lines refer back to, so each criterion can be traced to the work that meets it.

#### G11 · Only four roles
- Routing covers implement, frontend, database checks, and security review. There is no
  guidance for tests, migrations, documentation, CI/CD and infrastructure, performance work,
  data import/ETL, or i18n.
- **Fix:** add routing rows for each of these, even when the agent is `dispatch-implementer`
  with a role preamble. Ship `dispatch-test-writer` and `dispatch-migrator` templates, all on
  Opus 5.5 at `effort: high`.

#### G12 · No review beyond security
- The critic is told not to report architecture or performance (`verifier.md:142`), which is
  correct for a critic. But nobody else checks for N+1 queries, layering violations, missing
  indexes, drift from the permission matrix, or convention drift across 100 dispatches.
- **Fix:** add an optional `dispatch-reviewer` that runs **once per phase**, not per dispatch,
  against `ARCHITECTURE.md` and `DOMAIN.md`. It is read-only and reports findings only, like
  the critic.

#### G13 · Security review stops at each diff
- `verify` judges one diff, and "history before BASE is out of scope" (`verifier.md:43`). An
  ERP also needs a threat model and a check of the whole system at phase gates: the
  authorisation matrix end to end, tenant isolation, audit-log integrity, and advisories across
  all dependencies.
- **Fix:** add `/dispatch audit <phase|module>`, which checks the system against
  `THREAT-MODEL.md` and the permission matrix in `DOMAIN.md`, runs the same read-only critic
  over a module instead of a diff, and is required at every gate.

#### G14 · No path from code to production
- The intake asks where the app will be hosted, and nothing uses the answer again. The skill
  covers no CI pipeline, environment configuration and secrets, staging, deploy, backups and
  restore tests, runbooks, cutover, or a parallel run with the old system.
- **Fix:** add `references/delivery.md` with delivery dispatch types (CI, deploy kit, backup,
  runbook). Their Done means require a check in a clean container, which is what GoodTechies
  did by hand ("the deploy kit passed in a fresh Ubuntu 24.04 container"). Record a *Delivery
  capabilities* section in `AGENTS.md`.

### P2 — quality and polish

#### G15 · Checks are web-only
Setup, responsive rules and the measure script assume a dev server and a browser. The intake
offers mobile, desktop and CLI, but Flutter, React Native, Electron and CLI projects can never
report *Verified*. **Fix:** add a capability recipe per platform (emulator or simulator
screenshots, a CLI golden-output test), or say plainly that these platforms can only be
reported *Not verified*.

#### G16 · Accessibility, i18n and performance are never part of Done means
Responsive checks are required for every UI brief. Accessibility (WCAG), i18n (the intake even
suggests "Bangla + English") and performance budgets are never turned into checks. **Fix:** add
a *Cross-cutting checks* list in `AGENTS.md`, set at intake, that every relevant brief copies
into Done means, the same way it copies breakpoints today.

#### G17 · No visibility into cost and usage (sharper after 1.7.0)
With every sub-agent on Opus 5.5, a copy fix costs the same model rate as a new subsystem, and
a 100-dispatch build adds up. **Fix:** record dispatches and attempts per phase in the ledger,
ask about a budget at intake if the user wants one, and report a count per phase at each gate.
The model stays fixed; the remaining levers are fewer dispatches and the user's own `effort:`
setting.

#### G18 · The description does not trigger on "build me an app"
The description triggers on delegation words ("dispatch", "delegate", "sub-agents"). A user
who says "build me an ERP" or "start a new web app" will not load the skill, so
`/dispatch new` never runs. **Fix:** add build and new-project trigger phrases to the
description, and add trigger evals using the `skill-creator` description-optimisation loop.

#### G19 · The skill's own instructions are costly to read
Before its first cycle the main session reads `SKILL.md`, `routing.md`, `prompt-spec.md`,
`acceptance.md` and `verifier.md`, about 1,100 lines. That is the skill spending the very
context budget it protects. **Fix:** write a cycle card of about 60 lines for repeat dispatches
(the exact commands and the brief skeleton), and open the long references only on an exception
(failure, oversize diff, cold verify).

#### G20 · The evals are run by hand, and the validator checks exact wording
There are 21 scenario files with no harness and no pass rate. `validate.sh` greps for exact
sentences, so every wording change needs a matching validator edit (this 1.7.0 update had to
rewrite 4 checks and add a fifth for one policy change). There is no eval longer than one dispatch. **Fix:** run
the scenarios with the `skill-creator` eval loop, using sub-agents that score each scenario's
expected-behaviour checklist. Add one **multi-session big-build eval**: plan, 3 phases, a
session rotation, a resume, and a gate. Move validator checks from sentences to structure
(headings, frontmatter keys, links).

#### G21 · New agents need a restart
Templates installed during a session are not selectable until the session restarts, so the
fallback path is common on a new project's first day. That is acceptable, but `/dispatch new`
could install the templates *before* the scaffold dispatch and ask for the restart once, at the
point where it costs least.

---

## 5. Proposed roadmap

| Release | Theme | Gaps | Main additions |
| --- | --- | --- | --- |
| **1.8.0** | Project layer | G1, G2, G3, G10 | `/dispatch plan` → `ROADMAP.md` with gates; `ledger/INDEX.md`; `/dispatch resume`; session rotation; `/dispatch new --from <spec>` |
| **1.9.0** | Contracts | G4, G5, G6, G16 | `ARCHITECTURE.md`, `DOMAIN.md`, ADRs; Tests section in briefs with the fail-at-BASE rule; test shards; `migrations.md` and `dispatch-migrator`; cross-cutting checks |
| **2.0.0** | Scale and delivery | G7, G8, G9, G11–G14 | worktree integration; checkpoint commits; module maps and map upkeep during acceptance; new roles; per-phase reviewer; `/dispatch audit`; `delivery.md` |
| **2.1.0** | Skill quality | G15, G17–G21 | platform recipes; usage per phase; trigger phrases; cycle card; automated evals and a big-build eval |

**Rough effect on big-build readiness:** about 45 % today, about 65 % after 1.8, about 80 %
after 1.9, and about 90 % after 2.0. Releases 1.8 and 1.9 together would replace most of the
GoodTechies master prompt's Parts 0, E, G and J with skill behaviour, so the next large build
would not need one.

---

## 6. Guardrails for closing these gaps

- **Keep "hold the map, not the territory".** Every new file (`ROADMAP.md`, ledger, `DOMAIN.md`)
  must be compact and read through an index, the way the polish index works. None should be a
  document the main session reads in full each cycle.
- **Keep acceptance in the main session.** A per-phase reviewer or audit adds findings. It never
  accepts work.
- **Keep the user in charge of irreversible steps.** Commits, migrations against real data,
  deploys and gates run only on the user's yes.
- **Keep one model.** New roles ship with `model: claude-opus-5-5` and `effort: high`, like the
  rest (1.7.0).
