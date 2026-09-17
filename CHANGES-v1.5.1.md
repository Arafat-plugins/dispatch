# dispatch v1.5.1 — "Review fixes"

Release notes for the fix release after v1.5.0 (2d73111). Branch: `fix/v1.5.1-review`.
Date: 2026-09-17.

## Why

An independent reviewer read every file of v1.5.0, cross-checked the files against each other,
ran the shell/git/DB snippets and tested `dispatch-measure.mjs` against a real page.
`validate.sh` passed on v1.5.0, yet the review found 16 cross-file contradictions, 15 snippet
errors, 9 script bugs, 7 unsafe or unactionable steps and 5 design flaws. Each is a small fix
to one file. Every *(verify)* claim was re-run here before it was fixed. "Reproduced" below
means it failed in this session. Where the failure could not be run here, the fix went in
anyway because it makes the instruction portable, and the line says so.

Unchanged: the footer line, the eight commands, the four agent names, `effort: medium`,
model-by-weight, the 2-concurrent cap, the "read-only by instruction, checked by the main
session" wording, and the frontmatter subset.

## What changed — one line per review item

**A. Cross-file contradictions**
- A1 SKILL.md's "every brief carries" list now includes **Task** and **Done means**.
- A2 `dispatch-implementer` accepts a brief whose Task line says `Dependency brief (dependencies.md):`. It may then edit the manifest and lockfile only, and dependencies.md's Task line uses that phrase.
- A3 failures.md lists created files with `git diff --name-only --diff-filter=A <BASE> <AFTER>` and notes both `??` and ` A` (see B4).
- A4 routing.md: `haiku` for the critic is chosen per call. The "set it in the installed copy" advice is gone because the per-call `model` always overrides it.
- A5 prompt-spec.md's worked example cites the "Surfaces" table, not "Styles by surface".
- A6 status.md's sample and evals/foreign-agents-md.md say 1.5.1. validate.sh checks both files.
- A7 evals/design-asks-responsive-one-question.md points to "SKILL.md → Designing or changing UI".
- A8 The UI-project test is defined once, in setup.md. status.md says to run the same test.
- A9 The script now really uses only the repo's Playwright (C1, C2), so the "repo's Playwright" claim in README/CHANGELOG/setup holds.
- A10 setup.md step e: "a user that `AGENTS.md` already names as read-only". The reference to a nonexistent per-engine table is gone.
- A11 The Rendering record template lists `MCP name (main session only)` and `n/a (no UI)`.
- A12 dependencies.md no longer says `status` reports vulnerable versions. `status` runs no audit.
- A13 validate.sh prints `ok` only for a check that passed. Its header says it runs everything and exits at the end.
- A14 validate.sh finds every fenced block starting `## Task`/`## Role` in SKILL.md and references/, and requires the footer as its last line. Mutation-tested.
- A15 validate.sh checks `model: opus` / `effort: medium` in the extracted frontmatter only. Mutation-tested.
- A16 README and db-check.md: the read-only DB user is the **only** real guard. `--safe-updates`, session `READ ONLY` and `PGOPTIONS` are called seatbelts.

**B. Shell / git / DB snippets**
- B1 BASE and SKILL_DIR are printed, recorded in the plan and pasted into later commands. The optional `--git-path dispatch-base` file is documented. Reproduced: a later call ran `git diff ""` and got exit 128.
- B2 bootstrap Step 0 takes a directory only from a line that printed. The empty search no longer gives `SKILL_DIR=.`. Reproduced.
- B3 The index path comes from `git rev-parse --path-format=absolute --git-path`. Reproduced: the old path failed in a linked worktree. A relative `--git-path` also failed from a subdirectory, found while testing.
- B4 `git add -N` is replaced by a second snapshot (AFTER) and `git diff <BASE> <AFTER>`. The throwaway index is seeded from `HEAD`, otherwise tracked-but-ignored files showed as deleted. Reproduced: the `"caf\303\251.css"` name failed, and `git stash` failed with intent-to-add entries.
- B5 Reverts use `git restore --source=<BASE> --worktree` (fallback for git < 2.23 included). Reproduced: `git checkout <BASE> --` staged the files.
- B6 Worktree review diffs START against an AFTER snapshot and lists the branch's commits. Reproduced: `git diff HEAD` missed an untracked file and a commit.
- B7 DB seatbelts go on every invocation: `PGOPTIONS='-c default_transaction_read_only=on'` and `mysql --init-command='SET SESSION TRANSACTION READ ONLY'`. Reproduced on Postgres 16: a one-off `SET SESSION` did not reach the next `psql -c`. MySQL is not installed here; the fix follows the same logic.
- B8 The Postgres grant check uses `has_table_privilege` and role membership, and also checks `rolcreaterole/rolcreatedb/rolbypassrls`. Reproduced: a role that inherits INSERT passed the old check.
- B9 `ls name.*` globs became `find -maxdepth 1 -name` in setup.md, bootstrap.md, status.md and routing.md, including the `.env*` grep. Not reproduced here (no zsh); fixed for portability.
- B10 The `--exclude-dir` flags are written inline, not as an unquoted `$X`. Not reproduced here (no zsh); fixed for portability.
- B11 bootstrap Step 2b uses `command -v timeout || command -v gtimeout`, else the tool call's own limit. Not reproduced here (`timeout` exists); fixed for portability.
- B12 The Vite/Next default URL is `http://localhost:<port>`, and setup records the URL the dev server prints. The `::1` binding was not reproduced here; fixed for portability.
- B13 `go version`, not `go --version`. Reproduced: "flag provided but not defined".
- B14 when-not-to-dispatch.md: Read only the lines (`offset`/`limit`), then Edit. A `sed -n` fallback is given for other runtimes.
- B15 setup.md detects browsers from the session's own tool list first. Chrome and connector browsers are recorded as `(main session only)` by default. Reproduced: `claude mcp list` reported "No MCP servers configured" while this session held claude-in-chrome tools.

**C. dispatch-measure.mjs**
- C1 Node Playwright is used only from `<repo>/node_modules`. `status`/`setup` probe with the script's own `--probe`. Reproduced: a `NODE_PATH` global rendered while `import('playwright')` said missing.
- C2 A set `DISPATCH_PYTHON` must work, otherwise exit 3. The bare `python3`/`python` fallback is gone. Reproduced: an invalid value fell through to system python.
- C3 The chromium fix for Python is `"<py>" -m playwright install chromium`. Reproduced.
- C4 `--prop --brand` works. Only the script's own flags count as a missing value, and custom property names keep their case. Reproduced, then tested end to end.
- C5 A redirect exits 2 and names the final URL. A 3xx is refused before rendering, and a changed `page.url()` is refused after. Reproduced: a /login redirect exited 0.
- C6 A Python `ETIMEDOUT` exits 2 ("did not finish"). Unit-tested with a real spawn timeout.
- C7 Argument errors print one line ending "see --help". Reproduced: 26 lines before.
- C8 No `fetch` exits 1 with "needs Node 18+". Reproduced with `--no-experimental-fetch`, which gave exit 2 before.
- C9 The first output line is `renderer: node playwright` or `renderer: python <path>`. acceptance.md and the frontend template report it.

**D. Unactionable or unsafe steps**
- D1 Every UI brief has a **Page URL(s)** line under Inputs (template and worked example). Acceptance and the frontend agent measure that URL, and `$URL` is gone.
- D2 MySQL credentials go through `--defaults-extra-file=<(printf …)`, which writes no file. Env files are loaded without echoing and in the same call as the query. Checked: a non-shell `.env` loses the value and leaks part of it in the error message, so the doc sends such files to the `grep` form.
- D3 The dirty-tree path no longer touches the index at all (B4).
- D4 setup.md asks once before steps b and c write anything, and shows the diff before replacing an existing script copy.
- D5 The "delete the `tools:` line" option is removed from setup.md, bootstrap.md, the frontend template and the eval. Browser tools are added by name only, on a yes.
- D6 status.md flags agent files the runtime has not loaded. Without an agent list to compare, it flags files newer than `.dispatch-state.json`. The "newer than the session" test is gone.
- D7 README DB-guard wording is covered by A16.

**E. Design flaws**
- E1 Acceptance check 5 covers colours and breakpoints. Spacing is checked only when DESIGN.md lists a scale, and then only margin/padding/gap. Without DESIGN.md the check is waived. The frontend template's "Never" line matches. The grep patterns were tested against `border: 1px` / `gap: .5rem`.
- E2 The critic and the db-tester run only when no other agent is editing the same working tree (routing.md, verifier.md, acceptance.md).
- E3 new-project.md makes a root commit holding `PROJECT_BRIEF.md`, proposed and run on a yes, before the scaffold. SKILL.md exempts the scaffold dispatch from "no map". Reproduced: `git rev-parse HEAD` fails in an empty repo.
- E4 bootstrap Step 0 prefers the path the runtime reports. Otherwise it takes the candidate whose `metadata.version` is 1.5.1, and validate.sh checks that literal. Tested with a 1.4.0 plugin-cache copy next to a 1.5.1 copy.
- E5 status.md's Rendering ❌ fix comes from `--probe`: `npx …` for Node, `"<py>" -m …` for Python, `/dispatch setup` when the package is missing. The Python search is the script's own.

**F. Release housekeeping**
- Version 1.5.1 in SKILL.md, bootstrap.md (state JSON and Step 0), status.md, evals/foreign-agents-md.md and CHANGELOG.md. README changed only where a claim changed: DB guards, script resolution, brief fields, baseline, haiku.
- validate.sh new checks:
  - Task/Done means in briefs
  - `Page URL(s):` in the template and the example
  - no `git add -N`, no shell-variable BASE, worktree-safe index path, `git restore`
  - no `ls` globs, `$X` flag lists or `go --version`
  - the deps-brief exception
  - PGOPTIONS / `--init-command` / `has_table_privilege`
  - every eval listed in evals/README.md
  - `node --test scripts/measure.test.mjs`
  - minimum version 1.5.1

  17 mutations were tried against it and each one fails the run.
- New `scripts/measure.test.mjs`: 14 tests, no Playwright, no network. The script runs nothing when imported.
- New evals: `base-sha-is-printed.md`, `critic-waits-for-idle-tree.md`, `css-px-not-rejected-without-design-md.md`, `ui-brief-has-page-url.md`. Nine existing scenarios were updated.

## Checked before committing

```bash
bash scripts/validate.sh                          # PASS (27 checks)
node --test scripts/measure.test.mjs              # 14 pass
grep -rn 'git add -N' skills/ README.md           # nothing
```

End to end against a local `python3 -m http.server`-style page, with widths 320/375/768/1280:
- Node route: repo `node_modules`. Python route: `.venv`, and `DISPATCH_PYTHON`.
- `--select .grid --prop grid-template-columns` and `--select :root --prop --brand` → `#0a7f5a`.
- Exit 1: arguments, and no `fetch`.
- Exit 2: server down, HTTP 500, a 302 to /login, and a client-side redirect.
- Exit 3: no repo Playwright (with a global one on `NODE_PATH`), missing chromium on both routes, and a bad `DISPATCH_PYTHON`.

## What to commit

All of these, on `fix/v1.5.1-review`:

```
modified:  CHANGELOG.md
modified:  README.md
modified:  scripts/validate.sh
modified:  skills/dispatch/SKILL.md
modified:  skills/dispatch/agents/{dispatch-db-tester,dispatch-frontend,dispatch-implementer,dispatch-security-critic}.md
modified:  skills/dispatch/references/{acceptance,bootstrap,db-check,dependencies,failures,new-project,prompt-spec,responsive,routing,setup,status,verifier,when-not-to-dispatch}.md
modified:  skills/dispatch/scripts/dispatch-measure.mjs
modified:  evals/README.md
modified:  evals/{credential-grep,db-tester-refuses-rw-credentials,deps-brief-lockfile-only,design-asks-responsive-one-question,dirty-tree-before-dispatch,foreign-agents-md,new-file-acceptance,new-project-intake-one-question,setup-detects-mcp-browser,third-failure-escalation}.md
new:       CHANGES-v1.5.1.md
new:       scripts/measure.test.mjs
new:       evals/base-sha-is-printed.md
new:       evals/critic-waits-for-idle-tree.md
new:       evals/css-px-not-rejected-without-design-md.md
new:       evals/ui-brief-has-page-url.md
```

Nothing else. `LICENSE`, `.gitignore`, `CHANGES-v1.5.0.md` and `skills/dispatch/examples/` are
untouched, and there is no `DESIGN.md` in this repo.

Suggested commit message:

```
dispatch v1.5.1 — review fixes: printed BASE snapshots, repo-only measure script, DB seatbelts per call

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012SFYn7oQXnSBbzDKnGsRAH
```

## PR note

The cloud session cannot push, so no branch was pushed and no PR was opened. The
branch is ready locally, and the description is below. To publish it:

1. Upload the changed and new files to a `fix/v1.5.1-review` branch through the GitHub web UI.
2. Open the PR against `main`.
3. Merge once `bash scripts/validate.sh` passes.

**Title:** `dispatch v1.5.1 — Review fixes`

**Description:**

```markdown
Fixes from an independent review of v1.5.0. validate.sh passed on v1.5.0; now it also checks
for everything below. Each claim was reproduced before it was fixed where this environment
allowed. The zsh, macOS and MySQL items are portability fixes.

- Baseline: BASE is a printed sha that the session records and pastes. The snapshot works in
  linked worktrees and subdirectories. Acceptance diffs two snapshots instead of using
  `git add -N`, so non-ASCII names, `git stash` and the user's index are all safe. Reverts use
  `git restore --worktree`.
- dispatch-measure.mjs uses only the repo's Playwright and has a `--probe` flag, which status
  and setup use. Other changes:
  - `--prop --brand` reads custom properties.
  - A redirect exits 2 and names the final URL.
  - A timeout is exit 2; Node < 18 is exit 1.
  - Errors are one line, and the output starts with `renderer: …`.
  - 14 unit tests.
- DB: the read-only user is the only real guard. PGOPTIONS / `--init-command` seatbelts go on
  every call. The Postgres grant check sees inherited roles. MySQL options go through process
  substitution.
- Briefs: Task, Done means and a Page URL(s) line for UI work. The implementer accepts
  dependency briefs. The critic waits for an idle tree. A new project makes a root commit
  before the scaffold. DESIGN.md checks colours and breakpoints, and spacing only when
  DESIGN.md lists a scale.
- Setup and status: browsers are detected from the session's tool list first. Setup asks
  before copying or editing `tools:` and never deletes that line. There is one UI-project
  test. Bootstrap Step 0 is version-checked.

No renames. The footer, commands, agent names, `effort: medium`, model-by-weight and the
2-concurrent cap are unchanged. `bash scripts/validate.sh` → PASS.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_012SFYn7oQXnSBbzDKnGsRAH
```
