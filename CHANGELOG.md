# Changelog

## 2.0.0 — 2026-10-01

**Only the main session plans; sub-agents follow direct steps.** And the round trips that made a
five-minute task take an hour are removed or narrowed. Unchanged: Opus 5.5 at `effort: high` for
every sub-agent, the 2-concurrent cap, BASE/AFTER acceptance owned by the main session,
Verbatim text, Playwright measuring and `--compare` on both sides, and nothing committed without
a yes or pushed.

**Breaking — the brief is a list of numbered direct steps**
- New `## Steps` section in every brief (prompt-spec.md, cycle card, and the deps, migration,
  db, critic and audit briefs): `In <file>, in <function/selector> (around line N), change X to
  Y`, one change per step, the last step the check commands. Written by the main session.
- New footer, replacing the phase-planning one (SKILL.md → The mandatory footer); it ends every
  brief, verbatim.
- All seven agent templates: "The planning is already done — by the main session, not you."
  No phase lists, no extra steps, no change no step names; stop at a step that cannot be done as
  written. Worker reports are ≤ 20 lines, per step.
- The main session may read ≈ 60 lines around a `grep -n` hit to write a precise step (it still
  never reads whole files). A stop at a step is a wrong step, fixed and re-dispatched — not a
  failure (failures.md, case 3).
- Acceptance checks each step: a change no step asked for is a rejection; a rejection carries the
  corrected step written out.

**Narrowed or removed for speed** (speed.md rewritten)
- **Scout sub-agent: removed.** Locating is planning; the main session greps.
- **Questions: one defaults-first message, ceiling 3 per task** (was one at a time, ceiling 8).
  Small UI fixes with obvious responsive behaviour ask nothing. New-project intake: purpose,
  MVP scope, then one defaults-first confirmation.
- **Full suite: size L only**, or on the user's ask (was once per task, S included).
- **Security critic: only when the diff touches a security surface** — auth, permissions,
  payments, secrets, input handling, queries, uploads, data writes (was every task except pure
  CSS/docs). `/dispatch verify` still always runs.
- **Test-first and flow tests: only when a step asks** (was every logic brief); the flow check
  at acceptance runs only the flow the brief carried.
- **Brief files on disk: size M and L only**; S keeps just its ledger line.
- **Session rotation: only after a compaction or when unsure**; at ~10 dispatches or a phase end
  it is suggested in one line, not forced.
- **Polish index: `grep` hits for the briefed paths** before a brief, instead of reading the
  index every dispatch.
- **Direct edits by the main session: up to ~10 lines in one file** you already hold (was 5).
- **Budgets: ~15 / 40 / 80 tool calls** for S / M / L (was 25 / 60 / 120).

**Packaging**
- `main` now carries the full tree (1.9.0 lived only as a changed-files zip in `docs/`, missing
  three files its `SKILL.md` links to). Upload to claude.ai with a zip whose top folder is
  `dispatch/` holding `SKILL.md` — see README → Install.

## 1.9.0 — 2026-09-27

The big-build layer: every gap in `docs/GAP-ANALYSIS-big-projects.md` now has a fix (status
table at the top of that file). Unchanged: the footer, Opus 5.5 at `effort: high` for every
sub-agent, the 2-concurrent cap, acceptance being the main session's, and nothing deployed or
pushed by the skill.

**Plan, phases, gates — `/dispatch plan`, new `references/planning.md`** (G1, G17)
- Requirement IDs in `PROJECT_BRIEF.md`; `ROADMAP.md` (≤ 250 lines) with vertical-slice phases,
  dependencies, planned briefs, exit criteria and a gate question; read by table + current block.
- Gates: full suite + flows, worktree slices back, checkpoint commit proposed, reviewer pass,
  `/dispatch audit`, usage roll-up from the ledger (against an optional budget), then the gate
  message and an explicit "pass"; the session rotates at every gate.

**Architecture and domain — new `references/architecture.md`** (G4)
- `ARCHITECTURE.md` (modules, layers, data model, API conventions, cross-cutting, never),
  `DOMAIN.md` (glossary, `BR-nn` rules each with a test, permission matrix, state machines),
  `docs/adr/`. Briefs cite by section and ID; agents read only cited parts and stop on a
  contradiction; acceptance rejects a hunk that breaks a cited rule.

**Migrations — `/dispatch migrate`, new `references/migrations.md`, new `dispatch-migrator`** (G6)
- Kinds (additive, constraining, destructive, data, privileges) with their own Done means;
  migrate → rollback → migrate on the dev database, quoted; applied migrations never edited;
  destructive steps only on the user's yes; production never touched.

**New roles** (G11, G12): `dispatch-test-writer` (tests only, fail-first, E2E with the repo's
runner), `dispatch-reviewer` (once per gate: layering, rule/permission drift, queries — findings
only); routing rows for delivery, docs, performance, ETL, i18n and a11y briefs. Seven templates,
all `model: claude-opus-5-5`, `effort: high`.

**Integration — new `references/integration.md`** (G7, G8, G9)
- Worktree slices come back with `git diff --binary | git apply` plus an integration test run.
- Checkpoint commits are proposed after each task and at gates, run on the user's yes — or a
  standing yes the user writes in `AGENTS.md` → Checkpoints. Never a push. The non-negotiable now
  reads "never commit without the user's yes".
- Map upkeep: a brief that adds a route, flow step, command or module updates its `AGENTS.md` row;
  acceptance rejects a missing row. Past ~60 surfaces / 8 flows / 6 modules, module maps.

**Audit — `/dispatch audit`, new `references/audit.md`** (G13): `THREAT-MODEL.md` (≤ 120 lines)
and a module-wide critic brief — entry-point table (auth + permission per route, export, job),
tenant scoping, named risks, dependency advisories. A high finding blocks the gate.

**Delivery — new `references/delivery.md`** (G14): *Delivery capabilities* in `AGENTS.md`; CI,
env config, deploy kit, backup/restore, runbooks and cutover as briefs whose Done means is a
clean-room container run; deploy commands are printed for the user, never run.

**Cross-cutting and platforms** (G15, G16): *Cross-cutting checks* in `AGENTS.md` (a11y, i18n,
performance, audit log) copied into Done means with their commands; `dispatch-measure.mjs --a11y`
— lang, alt text, accessible names, heading skips, duplicate ids, WCAG AA contrast, no
dependencies; setup recipes for Flutter, React Native/Expo, Electron and CLI/API.

**Skill quality** (G18, G20, G21): the description now triggers on building a new app, website,
ERP or large feature set; `evals/triggers.json` (20 queries); `scripts/build-evals.mjs` generates
`evals/evals.json` in the skill-creator format (checked by `validate.sh`); new
`big-build-multi-session.md` eval; `/dispatch new` installs the templates before the scaffold and
asks for one restart.

**Validation**: check 33 (structure: files, modes, 7 agents, map sections, description length and
triggers, evals.json in sync, trigger set); `measure.test.mjs` 20 tests.

**Fixed before release** (an independent read-only review found 16): end-of-task and gate order
now bring worktree slices back *before* the full suite and verify; resume and PLAN read the
roadmap's current phase; the new-project path commits plan + templates as a second commit (no
amend), writes a handoff before the restart, picks templates from the planned stack, and takes
the scaffold's BASE right before it; migrations allow the framework's schema dump and
`ARCHITECTURE.md`, give Prisma a reset-based rollback, and the migrator matches the recorded dev
connection exactly instead of guessing from a name; setup records a `Migrations:` line;
checkpoint staging skips absent paths and never edits the ledger; the Commands table gains a
*Dependency audit* row; `--a11y` no longer uses `eval` in the page (works under a strict CSP —
tested); `build-evals.mjs` handles nested and multiple code spans in prompts.

## 1.8.0 — 2026-09-27

Five problems reported from real use: slow tasks, image references never matched exactly,
backend workflows breaking end to end, the main session filling up and hallucinating, and
the user's own wording being rewritten. Root causes and the reasoning behind each fix:
`docs/FIELD-ISSUES-v1.8.0.md`. Unchanged: the footer line, the four agent names, Opus 5.5 at
`effort: high`, the 2-concurrent cap, acceptance being the main session's.

**Speed — new `references/speed.md`**
- Every task is sized **S / M / L** in the plan; the size sets questions, scout, tests, critic
  and a tool-call **Budget** (~25 / 60 / 120) that every brief now carries.
- Questions go **defaults first**: one "go, or correct any line" message counts as one question;
  one-at-a-time only where no default fits (`responsive.md`, `new-project.md`). Batching is still
  forbidden. An existing spec replaces the intake.
- Tests: **targeted per dispatch** (new *Test (targeted)* / *Test (full)* rows in `AGENTS.md`),
  the full suite **once per task**.
- Verify runs **once per task** over the combined diff, and is skipped (and said) when only
  stylesheets, images or docs changed (`verifier.md`, `SKILL.md` step 6).
- An agent at its budget stops and reports — handled as a question, not a failure (`failures.md`).

**Image references — new `references/visual-reference.md`**
- The image lives in the repo (`.claude/dispatch/refs/<NNN>-<slug>/<width>.png`) and on a new
  **Reference image(s)** brief line with `Fidelity: exact | close`; one conflict question when the
  mock breaks `DESIGN.md`.
- `dispatch-frontend.md`: open the image, write a reference spec table (phase 1), compare up to
  3 passes, report `% differ` per pass and every red region left.
- `dispatch-measure.mjs`: **`--shot <dir>`** (full-page PNG per width) and **`--compare <image>`**
  (reference scaled to the width, pixel diff, composite *reference | render | diff*). No new
  dependencies — the comparison runs in a blank browser page, Node and Python renderers both.
  Setup gitignores `.claude/dispatch/shots/`.
- Acceptance opens the composite; structure red rejects, content red is noted.

**Backend flows — new `references/flows.md`**
- `AGENTS.md` gets a **Flows** map (trigger, steps, states, invariants, test).
- Briefs get a **Flow** section (In/Out contract, invariants); a flow step is **one vertical
  slice** to one implementer (`routing.md` redefines "one job"); two steps of one flow never run
  in parallel.
- Flow tests are required and must fail at BASE; acceptance runs every touched flow's test plus
  earlier ones — red is a rejection; the critic's risk table gains a flow-transition row.

**Context — new `references/context.md`, `references/cycle-card.md`, mode `/dispatch resume`**
- **The fact rule** (in `SKILL.md`): statements about the repo come from this cycle's output;
  after a compaction every sha in the summary is unknown.
- Briefs are written to `.claude/dispatch/briefs/<NNN>-<slug>.md`; `.claude/dispatch/ledger.md`
  gets one line per outcome (bootstrap creates it, Step 6 commits it).
- The **cycle card** replaces reading four references on a routine dispatch; acceptance excludes
  lockfiles and generated output from what it reads.
- **Rotation** after ~8 accepted dispatches, a phase, or a compaction: `HANDOFF.md` (≤ 30 lines,
  gitignored) plus a resume block; `/dispatch resume` continues from files only. `status` check 12
  and recommendation 2 report a pending handoff.

**The user's words — `prompt-spec.md` rule 5**
- New brief sections **User's words** (the request, unedited) and **Verbatim — use exactly**
  (product text, byte for byte); both worker agents treat Verbatim as final.
- Acceptance `git grep -F`s every Verbatim line in AFTER; a rewording is a rejection. New
  non-negotiable in `SKILL.md`.

**Evals and validation**
- New: `verbatim-text-kept-exact.md`, `image-reference-compared.md`,
  `backend-flow-step-one-slice.md`, `session-rotates-and-resumes.md`, `small-task-fast-lane.md`.
  `design-asks-responsive-one-question.md` → `design-responsive-defaults-first.md`.
- `validate.sh` check 32 guards every half of the five fixes; `measure.test.mjs` +4 tests
  (18 total).
- Review fixes before release: bookkeeping under `.claude/dispatch/` is kept out of the agent's
  diff (brief before BASE, ledger after AFTER, one `git diff --stat -- .claude/dispatch` check);
  worktree slices are applied back (`git diff --binary | git apply`) before the end-of-task run;
  "fails at BASE" is evidenced by the agent's quoted test-first run; the Python renderer gets the
  reference by path (a >128 KB argument hit E2BIG).

## 1.7.0 — 2026-09-27

One policy change: **every sub-agent runs on Opus 5.5** (`claude-opus-5-5`). The model-by-weight
split of 1.6.0 (`sonnet` for light work, `opus` for design/core/critic) is gone. No renames; the
footer line, the four agent names, the 2-concurrent cap and `effort: high` are unchanged.

**Opus 5.5 everywhere**
- All four agent templates pin `model: claude-opus-5-5` — a full model ID, not the `opus` alias,
  so an installed copy keeps pointing at Opus 5.5 when the alias later moves. `dispatch-db-tester`
  moves up from `sonnet`.
- The main session still sets the model on **every** Agent tool call — `claude-opus-5-5`, or
  `opus` where the parameter accepts aliases only. That per-call value is what reaches the agents
  with no frontmatter of ours: the built-in `Explore` scout (which otherwise runs on the runtime's
  small, fast default — the one place Haiku-class models were still doing dispatch work), a
  general-purpose fallback carrying a template body, and a repo's own agents.
- `routing.md` → *Model selection* rewritten around one rule; the light/heavy table is removed.
  The plan line is now simply `model: Opus 5.5 (claude-opus-5-5)`. Changing the model is the
  user's decision, like effort — never switched down to save cost or sideways to rescue a brief.
- Deps briefs (`dependencies.md`) move from `sonnet` to Opus 5.5; the scaffold dispatch
  (`new-project.md`) and the critic (`verifier.md`) name Opus 5.5 explicitly.
- The main and polish sessions are told to run on Opus 5.5 too (`claude --model claude-opus-5-5`);
  the polish handoff block says so.
- **Optional session pin.** Bootstrap Step 3 now proposes, on a yes, `"model": "claude-opus-5-5"`
  and `env.CLAUDE_CODE_SUBAGENT_MODEL: "claude-opus-5-5"` in `.claude/settings.json` (merged, diff
  shown first), and Step 6 stages that file when it exists.
- **`status` check 11 — model pin.** Lists every installed agent's `model:` line and the settings
  pin; an agent on another model or an alias, or no pin, is reported with its fix, and a new
  recommendation rule (6) points at bootstrap Step 3.

**Evals and validation**
- `typo-fix-uses-sonnet.md` → `typo-fix-uses-opus-5-5.md`: even a one-word copy fix is
  dispatched on Opus 5.5, set explicitly on the call.
- New `scout-pins-opus-5-5.md`: the `Explore` scout, a general-purpose fallback and a repo agent
  whose frontmatter says `sonnet` all get Opus 5.5 on the call.
- `deps-brief-lockfile-only.md`, `new-project-intake-one-question.md`,
  `polish-is-handed-off-not-dispatched.md` updated to Opus 5.5.
- `validate.sh`: check 8 requires `model: claude-opus-5-5` in every template; checks 18 and 30
  follow the new wording; new **check 31** fails if any instruction outside the changelogs routes
  work to `sonnet`, `haiku` or `fable` (or pins an alias) in a line that does not forbid it, and
  checks the scout, fallback, status and settings-pin wiring.

**Cost note.** Light work (copy, renames, scouting, DB checks) now costs Opus 5.5 rates. The
levers left are fewer dispatches (when-not-to-dispatch.md) and the user's own `effort:` choice.

**Also:** `docs/GAP-ANALYSIS-big-projects.md` — a review of what the skill still lacks for
building large apps (ERP, multi-module web apps) end to end, with a prioritised roadmap.

## 1.6.0 — 2026-09-22

One new feature — polish moves to a second session — plus two policy changes and the fixes an
independent review of 1.5.1 found. No renames. The footer line, the four agent names, the
2-concurrent cap and the "read-only by instruction, checked by the main session" wording are
unchanged; `effort:` and the critic's model are not.

**The polish session** — new `references/polish.md`, new `/dispatch polish [<NNN>|<what>]` mode
- On a big project, build **and** polish in one session fills that session's context with detail
  it does not need, and that is where hallucination starts. Polish now runs in a **second,
  separate Claude session** in the same repo, started at high effort on opus. The main session
  learns what happened there from titles and two-line summaries only.
- Layout, created by bootstrap Step 3: `.claude/dispatch/polish/INDEX.md` (the ledger — one
  heading, a `summary:` of at most two lines, a one-line `touches:` of at most five paths or
  surfaces, the note path, and nothing else), `.claude/dispatch/polish/<NNN>-<slug>.md` (the full
  note, frontmatter `id`/`title`/`summary`/`date`/`touches`/`files`/`request`),
  `.claude/dispatch/polish/requests/<NNN>-<slug>.md` (the main session's handoff brief).
- **`touches:` is what the reading rule matches on** — the index line has to carry the thing the
  decision is made from, or the decision cannot be made from the index alone. It is bounded: five
  items, one line, `+N more` past that, with the full set staying in the note's `files:`.
- **The main session's reading rule, a non-negotiable:** before planning any dispatch it reads
  `INDEX.md` and nothing else from that directory; it opens exactly one full note, and only when
  a title, summary or `touches:` names a file, surface or behaviour the current brief touches,
  naming which and why in the plan; it never opens one "to be safe", never reads `requests/`,
  never edits the index. No `INDEX.md` → polish has never run here, carry on silently. Past ~40
  entries it reads a **bounded window** — everything above the first entry plus the 40 most
  recent, one `awk` — and reaches older ones through `grep '^### '` and a `find` by number.
- **The main session never polishes and never dispatches polish** — a sub-agent is an isolated
  context, and the point here is a separate one. It writes the request and prints the exact block
  telling the user to open a second terminal in the repo and run `/dispatch polish <NNN>`. The
  boundary against the ≤5-line direct edit is decidable and stated in both files: a **correction**
  with one right answer (a typo, a wrong constant, a version string) is still a direct edit; a
  **judgement call** settled by looking — "the copy reads badly", "the spacing is almost right" —
  is polish, however few lines it comes to.
- **Both sessions load the same `SKILL.md`**, so it now opens with a mode-recognition step, and
  the four non-negotiables the polish session cannot obey — index-only reading, never polish here,
  the 2-sub-agent cap, sub-agents never judging themselves — are marked **(main session)** and
  listed in `polish.md` as the ones its own rules replace. Everything else still binds both.
- The **8-question ceiling** bounds an intake, so it does not apply to the polish session, which
  works with the user in the loop; the ceiling is unchanged for the main session
  (`responsive.md`, `polish.md`).
- The polish session is a worker, not a dispatcher: it reads `AGENTS.md`, `CLAUDE.md` and the
  request, then works with the user directly, reading and editing files itself. Same acceptance
  discipline — the baseline snapshot from `acceptance.md` before anything is touched, the diff
  shown at the end. It never edits `AGENTS.md` and never commits.
- On "done" it writes the note, then appends the index entry, in that order, at the next free
  `NNN` (zero-padded 3 digits, derived from the filenames already on disk — notes and requests
  share the counter). That numbering command sits in one section both sessions are pointed at,
  since the main session needs it to number a request. The two-line summary is hard: a summary
  that needs three lines means the polish was two polishes, split into two notes.
- Index hygiene is the polish session's, and it compacts the **index**, never the notes: no note
  file is deleted and no number is reused or renumbered. A fully superseded entry keeps its
  heading, marked `superseded by <NNN>`; past 40 entries the superseded ones fold into a single
  heading, which is the one thing that drops their `summary:`, `touches:` and `note:` lines — the
  notes stay on disk and are found by number. Non-superseded entries are never folded; the main
  session's bounded window is what keeps a long index cheap to read.
- Wired into `SKILL.md` (mode row, mode recognition, a section, the scoped non-negotiables),
  `bootstrap.md` (the directories, the seeded index, Step 6's staging list, `polish_index` in the
  state file), `acceptance.md` (after an accepted change, polish goes to the polish session),
  `status.md` (check 10 reports whether polish is set up and how many entries the index holds,
  reading no note and nothing under `requests/`), `routing.md` (polish is not a routing target),
  `when-not-to-dispatch.md` (correction vs judgement call), `responsive.md` (the ceiling) and
  `README.md`.

**Sub-agent effort is high**
- All four agent templates carry `effort: high` in their frontmatter, replacing `medium`. The
  Agent tool still has **no per-call effort parameter**, so the frontmatter remains the only
  place it is set — check the installed file, there is nothing to pass on the dispatch.
- Repo-owned agents without an `effort:` line still inherit the session's effort; the suggestion
  to the user is now `effort: high`. The general-purpose fallback still inherits the session and
  is still noted in the plan. Only the user changes it, in the installed copies (SKILL.md,
  routing.md, bootstrap.md, README).
- `scripts/validate.sh` check 12 asserts `effort: high`; `evals/effort-stays-medium.md` renamed
  to `evals/effort-stays-high.md`.

**The security critic runs on opus, always**
- `dispatch-security-critic` ships `model: opus`, not `sonnet`, and the template says why: a
  security judgement that misses something is worse than a slow one, so this role is never
  downgraded — not for a one-file diff, not because it is read-only. The `haiku`-for-trivial-diffs
  downgrade is gone.
- Model-by-weight is otherwise unchanged — `sonnet` for simple text-level work, `opus` for design
  and core-level implementation — with security review named as always-`opus` regardless of diff
  size (routing.md, SKILL.md, verifier.md, README).
- `dispatch-db-tester` stays `model: sonnet`. `scripts/validate.sh` check 8 now asserts all four
  models and the critic's "never downgraded" line.

**Review fixes carried in this release**
- `.env` was **executed**, not parsed: `set -a; . ./.env` runs the file as shell, so a value like
  `p4ss;echo "LEAKED: $DB_RO_PASSWORD"` prints the password on stdout. Replaced by a whitelist
  text parser that prints nothing (db-check.md).
- Bootstrap's Step 6 `git add` staged **nothing** when any listed path was absent (exit 128 on
  the first missing pathspec, and `CLAUDE.md` is optional). Now each path is staged only if it
  exists, with `find` for the agents glob (bootstrap.md).
- `/dispatch verify` with no cycle in flight had no BASE or AFTER. verifier.md now derives them —
  dirty tree against `HEAD`, or a revision the user names — and states what a cold verify cannot
  check: attribution, intent, and anything committed before BASE.
- Acceptance was blind to sub-agent **commits** and to **ignored paths**: a new "What the diff
  cannot see" section records `BASE_HEAD` and an ignored-file baseline up front and checks both
  (acceptance.md). Three details in that section are stated the way git actually behaves:
  - The commit check is `git log --oneline <BASE_HEAD>^{commit}..HEAD`. A tree sha there does
    **not** fail — git resolves the tree-ish and exits 0 having printed the repo's *entire*
    history, which reads as "the sub-agent committed all of these". `^{commit}` is the guard: the
    same mistake then stops with `expected commit type` and exit 128.
  - The ignored-path check ends in an `awk` so its **exit status matches the verdict** — 0 and no
    output is the pass, 1 means something was written where nothing was watching. Ending on
    `grep '^>'` inverts it, and a runtime that surfaces non-zero flags every clean acceptance.
  - `git clean -nxd` is **not** the same set and no longer claimed to be: it collapses a wholly
    untracked directory to one entry (`dist/`, never `dist/new.js`) and it also lists untracked
    files that are not ignored.
- The ignored-file baseline was a single hard-coded `/tmp/dispatch-ignored-base`, which two
  dispatches in flight overwrite for each other. It is now
  `git rev-parse --path-format=absolute --git-path dispatch-ignored-<BASE>` — unique per dispatch,
  inside the git directory, and a linked worktree gets its own. The worktree section gives the
  `git -C <worktree-path>` form for both commands, which it previously promised and omitted
  (acceptance.md).
- The Playwright probe and the run could disagree — the probe ran the skill's copy, which cannot
  see `.claude/dispatch/browsers/`. Both now run the installed copy from the repo root, with the
  same `DISPATCH_PYTHON` (setup.md, status.md).
- That probe was printed with a `<…>` placeholder **inside** a fenced block of otherwise literal
  commands, where `<` is a redirect and the apostrophe opens a quote — pasting it gave
  `unexpected EOF while looking for matching '`. Every line in those blocks is now literally
  runnable and the `DISPATCH_PYTHON=` prefix is explained in prose outside the fence (setup.md,
  status.md).
- `setup.md` claimed "steps b and c copy files out of the skill's own directory" — only c does —
  while step b told you to run c first, so the documented a→b→c order could not be followed. The
  claim is corrected and the order is stated once: a, b, c, d, e, f, with one detour inside b,
  because b's Playwright probe runs the copy c installs.
- The re-dispatch rule contradicted itself: routing.md forbade re-dispatching a brief, failures.md
  told you to. Now one rule — a rejected attempt always gets a changed brief; only an errored run
  that changed nothing is re-dispatched unchanged, once (routing.md, failures.md).
- The critic and db-tester fenced briefs were missing `## Task` and `## Done means` (verifier.md,
  db-check.md).
- `scripts/validate.sh` gaps: check 23 now walks every fenced brief for those two sections, and
  check 24 catches `--intent-to-add` as well as `-N`.
- More `scripts/validate.sh`: check 28's bootstrap assertion was hollow — it grepped for a string
  that appears five times in the file, so deleting the whole "The polish directory." block still
  passed. It now asserts the `mkdir -p`, the index seed, and the `[ -f … ] ||` guard that stops a
  re-run overwriting the ledger. New check 29 covers the session scoping (mode recognition in
  `SKILL.md` and `polish.md`, the `(main session)` markers, the ceiling exemption, and the old
  self-negating mode row as a banned string). New check 30 guards this release's two headline
  policies **outside** the agent frontmatter that checks 8 and 12 already cover: `effort: high`
  and security-critic-always-`opus`, asserted in `SKILL.md`, `routing.md`, `bootstrap.md` and
  `README.md`, plus a repo-wide ban on any other `effort:` value stated as policy.
- Check 22's `SKILL.md` line limit goes from 250 to 270. The file sat at exactly 250, so any
  addition failed; 270 is 250 plus the session-routing this release has to put in `SKILL.md`
  itself — a session must route before it knows which reference to open — and nothing else. The
  check's own comment records that reasoning.
- A question ceiling: at most **8 questions across every path** — intake, responsive and setup
  step d counted together — then one message proposing a default per remaining unknown, answered
  by a single "go" (responsive.md, new-project.md, setup.md).
- `AskUserQuestion` is Claude Code-only; both one-question-at-a-time flows now give the plain-text
  fallback the `compatibility:` line promises (responsive.md, new-project.md).
- A stale `Styles by surface` table in the example `AGENTS.md`, which bootstrap has not generated
  since 1.5.0 (examples/AGENTS.example.md).
- Four smaller ones: Step 0 printed the same skill directory twice (`./x` and `x`); a MySQL
  password containing `"` or `\` was cut short in the option file; setup.md step d's
  design-package grep matched `"build"` and `"prebuild"` while missing `"@radix-ui/…"`; and
  setup.md run alone had no `<SKILL_DIR>` resolved before steps b and c copy from it.

## 1.5.1 — 2026-09-17

"Review fixes". An independent review of 1.5.0 found cross-file contradictions, shell/git/DB
snippets that fail outside the author's shell, bugs in the measure script, a few unsafe steps
and five design flaws; `validate.sh` passed on all of them. Each claim was re-checked before
fixing (scratch repos, a linked worktree, non-ASCII names, a local Postgres 16, the script
against a local page on both renderers). No renames; the footer line, the commands, the four
agent names, `effort: medium`, model-by-weight, the 2-concurrent cap and the "read-only by
instruction, checked by the main session" wording are unchanged.

**Baseline and acceptance (git)**
- BASE is **printed and pasted**, not kept in `BASE=$(…)`: the assignment shows nothing, and in
  runtimes with a fresh shell per tool call the variable is gone by step 5 (`git diff ""`, exit
  128 — reproduced). The session writes `BASE: <sha>` into its plan; SKILL_DIR the same way
  (SKILL.md, acceptance.md, bootstrap.md, setup.md, routing.md).
- The snapshot command takes its index path from `git rev-parse --path-format=absolute
  --git-path`, so it works in a linked worktree (`.git` is a file — reproduced) and from a
  subdirectory, and seeds the throwaway index from `HEAD` so tracked-but-ignored files are not
  reported as deleted (found while testing).
- `git add -N` is gone. Acceptance takes a second snapshot (AFTER) and reads
  `git diff <BASE> <AFTER>`: created files included, any file name (the old loop failed on
  `"caf\303\251.css"` — reproduced), the real index untouched, `git stash` unaffected (it failed
  with intent-to-add entries — reproduced) (SKILL.md, acceptance.md, verifier.md, critic template).
- Reverting a dispatch uses `git restore --source=<BASE> --worktree` (`git checkout <BASE> --`
  also staged the files — reproduced); created files are listed with
  `git diff --name-only --diff-filter=A` (failures.md).
- Worktree review diffs the recorded START sha against an AFTER snapshot and lists the agent's
  commits; `git diff HEAD` missed both (reproduced). Portable fallback: `git worktree add`.
- A new project gets a root commit holding `PROJECT_BRIEF.md` (proposed, run on a yes) before
  the scaffold dispatch, which is the one dispatch exempt from "no map, no dispatch"
  (new-project.md, SKILL.md).

**dispatch-measure.mjs**
- Node Playwright only from `<repo>/node_modules`; a global or `NODE_PATH` install was used
  while the status probe said "missing" (reproduced). `status` and `setup` now probe with the
  script itself: `--probe` (same lookup, plus a chromium start).
- `DISPATCH_PYTHON` wins when set and exits 3 if it cannot import playwright (it fell through
  silently — reproduced); no bare `python3`/`python` fallback; chromium fix printed as
  `"<py>" -m playwright install chromium` (reproduced the bare `playwright install`).
- `--prop --brand` reads a custom property (was "needs a value" — reproduced); custom property
  names keep their case.
- A redirect exits 2 with the final URL: a 3xx before rendering, and a changed `page.url()` after
  (a redirect to /login measured with exit 0 — reproduced, server and client-side).
- A Python timeout exits 2 ("did not finish"), not 3 (unit-tested with a real spawn timeout).
- Argument errors print one line ending "see --help" (printed 26 lines — reproduced). No `fetch`
  → exit 1 "needs Node 18+" (was exit 2 "not reachable" — reproduced with
  `--no-experimental-fetch`).
- Output starts with `renderer: node playwright` / `renderer: python <path>`, the tool the
  frontend agent reports.
- Importing the script runs nothing; new `scripts/measure.test.mjs` (`node --test`, no
  Playwright, no network).

**Shell portability and database guards**
- `ls name.*` globs replaced by `find -name` (zsh aborts on an unmatched glob), the `$X`
  `--exclude-dir` list written inline (zsh does not word-split), `timeout` → `timeout` or
  `gtimeout`, else the tool call's own limit (setup.md, bootstrap.md, status.md, routing.md).
  **Not reproduced here (no zsh, and `timeout` exists); fixed for portability.**
- Bootstrap Step 0 lists every skill copy with its version and takes the one matching this
  release; an empty search no longer yields `SKILL_DIR=.` (reproduced), and an older plugin-cache
  copy is not installed.
- Vite/Next default URL is `http://localhost:<port>`, and setup records the URL the server
  prints. `127.0.0.1` vs `::1` not reproduced here; fixed for portability.
- `go version`, not `go --version` (reproduced).
- The read-only DB user is called the **only** real guard; `--safe-updates`, session
  `READ ONLY` and `PGOPTIONS` are seatbelts, put on **every** invocation — a one-off
  `SET SESSION … READ ONLY` did not reach the next `psql -c`, and a read-write login switched
  `default_transaction_read_only` off (both reproduced on Postgres 16; MySQL not available,
  fixed by the same reasoning) (db-check.md, db-tester, README).
- The Postgres grant check uses `has_table_privilege` plus role membership; the
  `grantee = current_user` filter missed an inherited INSERT (reproduced).
- MySQL credentials reach `--defaults-extra-file` through process substitution (the db-tester
  has no Write tool); env files are loaded without echoing, in the same call as the query.

**Briefs, acceptance and design rules**
- SKILL.md's "every brief carries" adds **Task** and **Done means**; UI briefs carry a
  **Page URL(s)** line, which acceptance and the frontend agent measure (`$URL` was undefined).
- The implementer takes a brief whose Task line says `Dependency brief (dependencies.md):` —
  manifest and lockfile only; before, a deps brief hit its own "do not add a dependency".
- `haiku` for the critic is a per-call choice; the installed-copy advice is gone (the per-call
  `model` always overrides it).
- prompt-spec.md cites the "Surfaces" table bootstrap generates.
- Acceptance's DESIGN.md check covers colours and breakpoints; spacing only when DESIGN.md lists
  a scale, and only margin/padding/gap; no DESIGN.md → the check is waived. `border: 1px` is not
  a finding.
- The critic and the db-tester run only when no other agent is editing the same working tree
  (routing.md, verifier.md, acceptance.md).
- The Claude Code Edit tool needs a Read first: when-not-to-dispatch.md says to read only those
  lines (`offset`/`limit`), with a portable fallback.

**Setup and status**
- Browser detection starts from the session's own tool list; `claude mcp list` shows configured
  servers only (it listed none while this session held claude-in-chrome tools — reproduced).
  Chrome and connector browsers are `(main session only)` by default.
- Setup asks once before steps b and c write anything, shows the diff for an existing script
  copy, and never deletes the frontend agent's `tools:` line (that would hand it every MCP tool).
- The UI-project test lives in setup.md only; status.md runs the same test. The Rendering record
  lists `(main session only)` and `n/a (no UI)`. "A user AGENTS.md already names as read-only"
  replaces a reference to a table that does not exist.
- status reports an agent file the runtime has not loaded ("restart or /agents"), else one newer
  than the state file; the "newer than the session" test is gone. Rendering ❌ prints the fix for
  the right ecosystem, from `--probe`.
- dependencies.md no longer claims `status` reports vulnerable versions.

**Repo**
- `scripts/validate.sh`: prints `ok` only when a check passed and says so in its header; the
  footer check now finds every fenced `## Task` / `## Role` brief; `model:`/`effort:` checked in
  the frontmatter only; version consistency adds bootstrap Step 0, status.md and
  evals/foreign-agents-md.md; new checks for Task/Done means, Page URL, no `git add -N` or
  shell-variable BASE, worktree-safe index path, no `ls` globs, the deps-brief exception,
  PGOPTIONS/`--init-command`, `has_table_privilege`, every eval listed in the README, and
  `node --test scripts/measure.test.mjs`. Minimum version 1.5.1.
- `evals/`: base sha printed, critic waits for an idle tree, px not rejected without DESIGN.md,
  UI brief has a page URL; existing scenarios updated (`git add -N`, `$BASE`, "Rule C",
  version 1.1.0, the DB seatbelts, the MCP detection order).
- `README.md`: DB guards, script resolution, brief fields.

## 1.5.0 — 2026-09-17

"Capabilities". 1.4.0 assumed tooling it never provisioned: a frontend agent that could not see,
no design source, no path for adding a dependency, and database guards that were described but
never set up. No renames; the footer line, the existing commands, the four agent names,
`effort: medium`, model-by-weight and the 2-concurrent cap are unchanged.

**Setup — capabilities are provisioned, not assumed**
- New mode `/dispatch setup` (new `references/setup.md`); bootstrap runs it as Step 2c. Each
  step is detect → propose → install → record; nothing installs without saying what and a yes,
  never globally, never outside the repo; a missing capability is recorded and said, never
  skipped quietly.
- Runtime and dev server detected and recorded. Browser: a configured MCP (playwright,
  puppeteer, chrome, claude-in-chrome, Claude_Browser) gets its exact tool names appended to the
  installed `dispatch-frontend`'s `tools:` line; else Playwright as a dev dependency with chromium
  kept in `.claude/dispatch/browsers/`; else `Rendering: none` and every width is *Not verified*.
- `AGENTS.md` gains a *Verification capabilities* section; the state file gains
  `capabilities_measured` (bootstrap.md).

**One measuring script**
- New `skills/dispatch/scripts/dispatch-measure.mjs`, copied to `.claude/dispatch/`:
  `<url> <width>... [--select <css> --prop <property>]` → one line per width, overflow and the
  computed value. Starts nothing; exit 2 `dev server not reachable at <url>`, exit 3 no renderer.
  Uses the repo's Node Playwright, else Python Playwright.
- The inline Playwright snippet is gone from acceptance.md; acceptance, responsive.md and the
  frontend template call the script.

**Design guidance**
- Setup step d generates `DESIGN.md` for UI projects — Tokens, Breakpoints, Components,
  References, Never — from the theme config, CSS custom properties and `@media` queries, plus at
  most three one-at-a-time questions; shown before writing. An optional frontend-design skill is
  offered only if the registry actually lists one, installed into the repo.
- `dispatch-frontend` reads `AGENTS.md`, then `DESIGN.md`, then the briefed files; what
  `DESIGN.md` defines cannot be overridden by a brief. prompt-spec.md cites `DESIGN.md`
  components in **Format**; responsive.md skips what it answers; acceptance.md gains a fifth
  check — a colour, spacing value or breakpoint not in `DESIGN.md` is a finding.

**Dependencies**
- New mode `/dispatch deps <add|remove|update> <package>` (new `references/dependencies.md`):
  ask first; a `sonnet` brief limited to manifest + lockfile, install clean, tests green, audit
  quoted in ≤ 10 lines; acceptance rejects any source file; then `/dispatch verify` asking only
  about provenance, advisories, pinning and lockfile integrity.
- failures.md routes "a dependency is needed" here; when-not-to-dispatch.md allows a one-line
  bump of a package already present; the implementer names package, constraint and reason when
  it stops.

**Database guards**
- Setup step e detects a read-only credential by key name only, or prints the engine's SQL to
  create one (Postgres, MySQL/MariaDB, MongoDB; SQLite uses `-readonly`) — the user runs it.
- "Prefer a read-only user" is now a hard rule: the db-tester refuses to proceed when the only
  credential it can find is the application's read-write user, and confirms its grants after
  connecting (db-check.md, dispatch-db-tester.md "Start here").

**Surfaces and status**
- bootstrap.md generates a *Surfaces* table (route → entry → view → styles) for Laravel,
  Next.js/Nuxt/SvelteKit, WordPress and plain PHP, capped at ~60 rows; LOCATE skips the grep
  when it names the files.
- `status` reports each capability ✅ / ⚠️ / ❌ with the one command that fixes it.

**Repo**
- `scripts/validate.sh`: measure script exists and passes `node --check` (skipped only without
  node); no inline `chromium.launch` in references or agents; setup.md and dependencies.md exist
  and are linked; links between references resolve; DESIGN.md wiring; the db refusal rule;
  the Surfaces recipes; version at least 1.5.0; the footer is the last line of every brief
  template and is paraphrased nowhere in the repo; SKILL.md stays under 250 lines.
- `README.md`: `setup` and `deps` in usage, the provisioned files, "Capabilities are
  provisioned, not assumed".
- `evals/`: scenarios for an MCP browser found by setup, no browser → *Not verified*, a deps
  brief limited to the lockfile, and the db-tester refusing read-write credentials.
- `examples/AGENTS.example.md`: a filled *Verification capabilities* section and a *Surfaces*
  table.

## 1.4.0 — 2026-09-16

**Sub-agent effort is medium**
- All four agent templates carry `effort: medium` in their frontmatter. Model sets how capable
  a sub-agent is; effort sets how long it thinks — a briefed job does not need more.
- The Agent tool has no per-call effort, so the frontmatter is the only place it is set.
  routing.md gains an *Effort* section: repo-owned agents without an `effort:` line inherit the
  session (suggest adding it), the general-purpose fallback inherits the session (noted in the
  plan), and only the user raises or lowers it — never the main session to rescue a failing
  brief (SKILL.md, routing.md, bootstrap.md, README).
- `scripts/validate.sh`: every agent template has `effort: medium`.
- `evals/`: scenario for effort staying medium.

## 1.3.0 — 2026-09-15

One gap: a new heavy project gets built from guesses instead of from the user's own answers. No
renames; the footer line, the commands, and the four agent names are unchanged.

**New heavy project intake**
- A heavy new project — built from scratch, an empty/near-empty repo, or a new large subsystem
  (multiple modules, many files, its own data model) — is gathered from the user *before* a
  brief is written. A light new thing (one script, one small file) skips intake or needs at
  most 1-2 questions.
- One question per message, `AskUserQuestion` with 2-4 concrete options, "you decide" allowed,
  never batched — same rule as responsive.md. Skips anything the user already said, stops as
  soon as planning is possible. Suggested order (new `references/new-project.md`): purpose and
  users, platform, stack, MVP scope, data/auth, look and feel (continues into responsive.md for
  UI), integrations, hosting, constraints, definition of done.
- Answers are confirmed back as a short brief and saved as `PROJECT_BRIEF.md` at the repo root
  before anything is scaffolded — the source for planning and every later dispatch brief.
- New mode `/dispatch new <idea>` runs the intake; a plain `/dispatch <task>` that matches the
  heavy-new-project signals runs it automatically (SKILL.md, "Starting something new?").
- Scaffolding runs at `opus` (routing.md, heavy/core work), then `/dispatch bootstrap` — which
  now checks for `PROJECT_BRIEF.md` on an empty repo and reads "What this project is" from it
  (bootstrap.md).

**Repo**
- `scripts/validate.sh`: `new-project.md` exists, is linked from SKILL.md, and mentions "one
  question".
- `README.md`: `/dispatch new` in usage, the intake rule in design notes, new-project.md in the
  layout tree.
- `evals/`: scenario for one-question-at-a-time new-project intake.

## 1.2.0 — 2026-09-15

Three protocol gaps: which model a dispatch runs at, how many sub-agents run at once, and
responsive scope on design work. No renames; the footer line, the commands, and the four agent
names are unchanged.

**Model by task weight**
- The main session sets the Agent tool's `model` explicitly on every dispatch — `sonnet` for
  light work (copy, docs, config, renames, mechanical edits, scouting, DB checks, the security
  critic), `opus` for design work or core-level implementation — and states the choice and a
  one-line reason in its plan (SKILL.md, routing.md's new "Model selection" table).
- `dispatch-implementer` and `dispatch-frontend` templates default to `model: opus`; the main
  session overrides down to `sonnet` for light tasks. `dispatch-db-tester` and
  `dispatch-security-critic` stay `model: sonnet`.

**At most 2 sub-agents at once**
- A hard cap of 2 concurrent sub-agents, counting every kind — workers, scouts, critic,
  db-tester. A plan needing more asks the user first, naming the job, the reason, and the cost;
  proceeds past 2 only on an explicit yes, for that plan (SKILL.md non-negotiables, routing.md's
  new "Concurrency cap" section with a worked ask message).

**Responsive is always in scope for design work**
- Any task that designs or changes UI always includes responsive behaviour in scope and in
  "Done means" — at minimum mobile ~375px, tablet ~768px, desktop ~1280px+, or the project's own
  breakpoints from `AGENTS.md`.
- Before briefing, the main session asks the user how it should look on smaller screens, one
  question per message, never batched, using `AskUserQuestion` — new `references/responsive.md`
  gives the question list, example options, and how answers become measurable "Target
  behaviour" per width (prompt-spec.md).
- Acceptance checks every named width itself, reusing the existing Playwright/overflow snippet,
  and reports "Not verified" per width it cannot render; the frontend template verifies every
  width in "Done means" and reports per width (acceptance.md, dispatch-frontend.md).

**Repo**
- `scripts/validate.sh`: implementer/frontend templates are `model: opus`; SKILL.md mentions
  the 2-concurrent cap; `responsive.md` exists and is linked from SKILL.md.
- `evals/`: scenarios for model-by-weight on trivial edits, the third-parallel-agent ask, and
  one-question-at-a-time responsive clarification.

## 1.1.0 — 2026-09-15

Closes the acceptance, safety, and portability gaps found in 1.0.0. No renames; the footer
line, the commands, and the four agent names are unchanged.

**Acceptance**
- Created files are reviewed: `git status --porcelain` + intent-to-add before `git diff` (acceptance.md, SKILL.md).
- Every dispatch starts from a recorded baseline — clean tree or a `write-tree` snapshot — and diffs against it; worktree isolation for parallel or risky dispatches (acceptance.md, routing.md).
- Large diffs are read `--stat` first, then per file; oversize is a finding. Sub-agent reports capped at 40 lines in every template and brief.
- The footer is explained as an instruction the sub-agent acts on: phases before editing, per-phase report, checked at acceptance; phases are *how*, the brief is *what*; read-only slices defined (SKILL.md, prompt-spec.md, agent templates).
- Loop termination: third failure stops and escalates; handling for errors, timeouts, questions, out-of-scope stops (new failures.md).
- When not to dispatch, and the narrow hand-fix exception (new when-not-to-dispatch.md).
- Frontend "verified" without rendering is reported as Not verified; the main session measures overflow itself with a headless Playwright one-liner when available.

**Safety**
- README no longer claims "no write tools". Critic and db-tester are read-only *by instruction*; the main session diffs `git status` before and after (README, verifier.md, templates).
- Real DB guards: read-only user, `SET SESSION TRANSACTION READ ONLY`, `sqlite3 -readonly`, `mysql --safe-updates`, Mongo read-only method list (db-check.md, dispatch-db-tester).
- Credential grep is `-l` only, never prints matching lines; credentials go via `--defaults-extra-file`, `PGPASSFILE`, env — never `-p<password>` on the command line.
- Security critic default model is `sonnet`; `haiku` noted as the cheap option for trivial diffs.

**Bootstrap and status**
- `<!-- dispatch:map v1 -->` / `<!-- /dispatch:map -->` markers; a foreign `AGENTS.md` gets a dispatch region appended after a shown diff, never overwritten.
- Bootstrap runs lint/test with a time budget and records a dated, commit-stamped baseline, or `not measured — <reason>`. Never an unmeasured "none".
- `/dispatch status` defined: map, agents, state version, layout drift, baseline age, CLAUDE.md link, tree cleanliness, one recommendation (new status.md).
- Skill-dir lookup with a `find` fallback; note on agents not hot-loaded mid-session and the general-purpose fallback.
- What to commit after bootstrap (`AGENTS.md`, `.claude/agents/dispatch-*.md`, state file — recommended) and why it must land before the first dispatch.
- State file gains `commit` and `baseline_measured`; version 1.1.0.

**Portability**
- db-check and db-tester cover MySQL/MariaDB, PostgreSQL, SQLite, MongoDB.
- `Explore` scout given a portable fallback; verify-chain scout clarified as the main session reusing the acceptance diff.
- Monorepo note: root `AGENTS.md` as index, per-package maps on request.
- Frontend template documents adding MCP browser tools to the installed copy's `tools:` line.

**Repo**
- `scripts/validate.sh`: frontmatter keys, reference links, agent frontmatter, verbatim footer in every brief template, version consistency.
- `evals/`: scenarios for new-file acceptance, dirty tree, foreign AGENTS.md, credential grep, third-failure escalation.

## 1.0.0 — 2026-09-09

- Initial release: the dispatch protocol (plan → locate → brief → work → accept → verify), bootstrap for `AGENTS.md`, four agent templates, database checks, worked example.
