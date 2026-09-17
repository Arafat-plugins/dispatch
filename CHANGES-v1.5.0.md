# dispatch v1.5.0 — "Capabilities"

Release notes for the upgrade from v1.4.0. Branch: `feat/v1.5.0-capabilities`. Date: 2026-09-17.

## Why

v1.4.0 was a sound delegation protocol that **assumed tooling it never provisioned**:

1. The frontend agent could not see. "Verified at 375px" meant *read the rules*, and the main
   session retyped a Playwright one-liner by hand, if Playwright happened to be installed.
2. The frontend agent had no design source, so every UI brief re-explained taste.
3. A needed dependency stopped the task with no way forward.
4. The database guards were described but never set up. Nothing checked that a read-only user
   existed.

Also: `AGENTS.md` had no generated surface map, and `status` could call a repo "bootstrapped"
even when it could not verify a single rendered width.

## What changed

| Area | Change | Files |
| --- | --- | --- |
| Setup | New `/dispatch setup` mode, run by bootstrap as Step 2c: detect → propose → install → record for dev server, browser, design source, DB guards. Installs only on a yes, only into the repo | `references/setup.md` (new), `references/bootstrap.md`, `SKILL.md` |
| Measuring | One script, `dispatch-measure.mjs` (copied to `.claude/dispatch/`), replaces the inline snippet. Exit 2 means the dev server is unreachable; exit 3 means there is no renderer | `scripts/dispatch-measure.mjs` (new), `references/acceptance.md`, `references/responsive.md`, `agents/dispatch-frontend.md` |
| Design | `DESIGN.md` generated for UI projects; frontend agent reads it first and cannot be overridden by a brief; acceptance flags values outside it | `references/setup.md`, `agents/dispatch-frontend.md`, `references/prompt-spec.md`, `references/responsive.md`, `references/acceptance.md` |
| Dependencies | New `/dispatch deps` mode: sonnet brief on manifest + lockfile only, audit quoted, narrow critic pass; stop-case and trivial-bump routing | `references/dependencies.md` (new), `references/failures.md`, `references/when-not-to-dispatch.md`, `references/verifier.md`, `agents/dispatch-implementer.md` |
| Database | Read-only user detected or its SQL printed (never run); db-tester refuses the app's read-write credential and confirms its grants | `references/setup.md`, `references/db-check.md`, `agents/dispatch-db-tester.md` |
| Surfaces | Generated route → entry → view → styles table; LOCATE skips the grep when it names the files | `references/bootstrap.md`, `SKILL.md` |
| Status | Each capability reported ✅ / ⚠️ / ❌ with its one fix | `references/status.md` |
| Repo | Version 1.5.0; validate.sh extended (checks 13–22, footer and example checks tightened); 4 evals; example map; README; CHANGELOG | `scripts/validate.sh`, `evals/*`, `skills/dispatch/examples/*`, `README.md`, `CHANGELOG.md` |

Unchanged: the footer line, the six existing commands, the four agent names, `effort: medium`,
model-by-weight, the 2-concurrent cap, and the "read-only by instruction, checked by the main
session" wording.

Check before committing:

```bash
bash scripts/validate.sh                                   # PASS
node --check skills/dispatch/scripts/dispatch-measure.mjs
node skills/dispatch/scripts/dispatch-measure.mjs http://127.0.0.1:9/ 375; echo $?   # dev server not reachable … / 2
```

## What to commit

All of these, on `feat/v1.5.0-capabilities`:

```
modified:  README.md
modified:  CHANGELOG.md
modified:  scripts/validate.sh
modified:  evals/README.md
modified:  skills/dispatch/SKILL.md
modified:  skills/dispatch/agents/dispatch-db-tester.md
modified:  skills/dispatch/agents/dispatch-frontend.md
modified:  skills/dispatch/agents/dispatch-implementer.md
modified:  skills/dispatch/examples/AGENTS.example.md
modified:  skills/dispatch/examples/README.md
modified:  skills/dispatch/references/{acceptance,bootstrap,db-check,failures,prompt-spec,responsive,status,verifier,when-not-to-dispatch}.md
new:       CHANGES-v1.5.0.md
new:       skills/dispatch/references/setup.md
new:       skills/dispatch/references/dependencies.md
new:       skills/dispatch/scripts/dispatch-measure.mjs
new:       evals/setup-detects-mcp-browser.md
new:       evals/setup-no-browser-reports-not-verified.md
new:       evals/deps-brief-lockfile-only.md
new:       evals/db-tester-refuses-rw-credentials.md
```

Nothing else. `LICENSE` and `.gitignore` are untouched, and this repo has no `DESIGN.md` of its
own: `DESIGN.md` is a file the skill writes into a *user's* repo.

Suggested commit message:

```
dispatch v1.5.0 — capabilities: setup, measure script, DESIGN.md, deps, read-only DB guard

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012SFYn7oQXnSBbzDKnGsRAH
```

## PR note

The cloud session cannot push, so no branch was pushed and no PR was opened from it. The branch
is ready locally, and the description is below. Upload the changed files to the
`feat/v1.5.0-capabilities` branch through the GitHub web UI, open the PR against `main`, and
merge it once `bash scripts/validate.sh` passes.

**Title:** `dispatch v1.5.0 — Capabilities are provisioned, not assumed`

**Description:**

```markdown
v1.4.0 told agents to verify at 375px and to connect read-only, but never checked that either
was possible. v1.5.0 provisions and records the tooling.

- `/dispatch setup` (bootstrap Step 2c): dev server, browser (MCP tools on the frontend agent,
  or repo-local Playwright), `DESIGN.md`, and a read-only DB user. It detects what exists, asks
  before installing anything, and records the result. Anything still missing is written down and
  reported to the user.
- `dispatch-measure.mjs`: one script for overflow and computed style per width, replacing the
  inline Playwright snippet. It starts nothing and exits 2 when the dev server is down.
- `DESIGN.md` is the frontend agent's design source. A brief cannot override it, and acceptance
  flags values that are not in it.
- `/dispatch deps`: a dependency change is its own sonnet dispatch on the manifest and lockfile
  only, followed by a critic pass limited to provenance, advisories, pinning and lockfile.
- The db-tester refuses the application's read-write credential. Setup prints the engine's
  read-only-user SQL for the user to run.
- A generated Surfaces table in AGENTS.md, and `status` reports each capability as ✅ / ⚠️ / ❌.

No renames. The footer, commands, agent names, `effort: medium`, model-by-weight and the
2-concurrent cap are unchanged. `bash scripts/validate.sh` → PASS.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_012SFYn7oQXnSBbzDKnGsRAH
```
