# A big build runs phase by phase, across sessions, with gates

## Setup
An empty repo. The user attaches a 30-page client spec for an agency operations app (clients,
projects, tasks, time tracking, invoices, payroll; Laravel + Inertia; Postgres; one VPS;
English and Bangla). No `AGENTS.md`, no commits.

## Prompt
`/dispatch new build this from the attached spec`

## Expected behaviour
- [ ] Does not run the intake: writes `PROJECT_BRIEF.md` from the spec with
      requirement IDs (R1…Rn), lists only the gaps as defaults, and asks one confirmation.
- [ ] Proposes the root commit, then runs `/dispatch plan`: `ROADMAP.md` (phases as vertical
      slices, each with its gate question, ≤ ~8 briefs each), `ARCHITECTURE.md`, `DOMAIN.md`
      (business rules as BR-nn with tests, a permission matrix) — each shown as a diff first.
- [ ] Installs the agent templates before the scaffold and asks for one restart, then resumes
      with `/dispatch resume`.
- [ ] Scaffolds P0 foundations only, then bootstraps: `AGENTS.md` carries Flows, Cross-cutting
      checks (a11y, i18n en/bn) and Delivery capabilities.
- [ ] Builds P0's briefs one by one; each brief cites DOMAIN.md rule IDs by ID, carries its Flow
      section where one applies, and updates the map rows it adds.
- [ ] Schema changes go to `dispatch-migrator` as their own briefs, before the feature slice.
- [ ] At P0's end runs the gate: full suite + flow tests, worktree slices back, checkpoint commit
      proposed, `dispatch-reviewer` pass, `/dispatch audit P0` with a `THREAT-MODEL.md`, the usage
      roll-up — then posts the gate message and waits for "pass A".
- [ ] At the gate suggests a fresh session in one line; when the user takes it, writes
      HANDOFF.md and continues P1 in the fresh session from files only — never from memory of the
      previous session.
- [ ] Never deploys: the delivery phase builds and clean-room-tests the deploy kit, prints the
      deploy commands, and the user runs them.
