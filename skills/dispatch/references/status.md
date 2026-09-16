# Status — what is set up, what is stale, what to run next

`/dispatch status`, and the default when `/dispatch` has no argument. Read-only. Runs the
checks below, prints one table, ends with one recommendation. It reads
`.claude/.dispatch-state.json` — this is the only mode that does.

## Checks

Run all of them; do not stop at the first failure.

```bash
# 1. map
test -f AGENTS.md && grep -c '<!-- dispatch:map v1 -->' AGENTS.md
# 2. agents (role coverage, by description — see routing.md)
ls .claude/agents/*.md 2>/dev/null && grep -h '^description:' .claude/agents/*.md | cut -c1-120
# 3. state
cat .claude/.dispatch-state.json 2>/dev/null
# 4. drift since bootstrap (needs "commit" from the state file)
git diff --stat <state.commit> HEAD | tail -1
git diff --name-only --diff-filter=ADR <state.commit> HEAD | cut -d/ -f1-2 | sort -u | head -20
# 5. CLAUDE.md link
test -f CLAUDE.md && grep -c 'AGENTS.md' CLAUDE.md
# 6. working tree
git status --porcelain | wc -l
# 7. skill dir (see bootstrap.md for the search)
```

| Check | Green | Not green — report as |
| --- | --- | --- |
| Map | `AGENTS.md` present **with** marker | absent → "not bootstrapped"; present without marker → "foreign AGENTS.md — bootstrap will append a dispatch section, not overwrite" |
| Agents | each of the four roles (implement, frontend, db, critic) covered by some agent | list the uncovered roles; "installed this session" if the files are newer than the session (restart or `/agents` to load) |
| State file | present, `version` equals this skill's `metadata.version` | absent → bootstrap did not finish, or the file is gitignored on this clone; older version → "re-run bootstrap to upgrade the map" |
| Layout drift | 0 added/deleted/renamed paths under directories the Layout table names | list them; any directory that appears or disappears means the map is wrong for it |
| Baseline age | `baseline_measured` within 30 days, or `not measured` with a reason | "known-failing baseline is N days old — re-measure" (bootstrap Step 2b) |
| CLAUDE.md | absent, or contains a pointer to `AGENTS.md` | "CLAUDE.md does not point sub-agents at AGENTS.md" |
| Working tree | clean | "N uncommitted paths — commit, stash, or snapshot before the first dispatch (acceptance.md)" |

## Output

```
Map:        AGENTS.md, dispatch marker present, bootstrapped 2026-09-01 at 3f2a9c1
Agents:     implementer ✓  frontend ✓  db-tester ✓  critic ✓   (4 in .claude/agents/)
State:      version 1.1.0 (current)
Drift:      12 commits since bootstrap; 0 layout changes
Baseline:   measured 2026-09-01 (14 days) — 11 failing
CLAUDE.md:  linked
Tree:       clean
Next:       /dispatch <task>
```

## Recommendation rules

In priority order — the first that applies is the `Next:` line:

1. No map, or foreign map → `/dispatch bootstrap`
2. State version older than the skill → `/dispatch bootstrap` (re-run upgrades the region between the markers)
3. Layout drift → `/dispatch bootstrap` (re-run; show the AGENTS.md diff first)
4. Baseline older than 30 days or `not measured` → re-measure (bootstrap Step 2b alone)
5. Uncovered agent role → install that template (bootstrap Step 3 alone)
6. Dirty tree → commit or snapshot, then dispatch
7. Otherwise → `/dispatch <task>`

Status never writes anything. It says what to run; the user runs it.
