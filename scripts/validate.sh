#!/usr/bin/env bash
# Structural checks for the dispatch skill. Bash only; node is used when present (checks 13, 27).
# Usage: bash scripts/validate.sh   (from anywhere). Runs every check, prints "ok" only for a
# check that fully passed and one "FAIL" line per problem, then exits 1 if anything failed.
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/skills/dispatch"
FOOTER='[ task list broken down into phases, each phase as a vertical slice, numbered ]'
nfail=0
mark=0
bad()   { printf 'FAIL  %s\n' "$1"; nfail=$((nfail + 1)); }
check() { mark=$nfail; }                                   # start of a check
pass()  { [ "$nfail" -eq "$mark" ] && printf 'ok    %s\n' "$1"; return 0; }   # ok only if the check added no FAIL
fm_of() { awk 'NR==1 && $0!="---"{exit 1} NR>1 && $0=="---"{exit} NR>1{print}' "$1"; }

# 1. SKILL.md frontmatter: only name, description, license, compatibility, metadata at top level
check
fm=$(fm_of "$SKILL/SKILL.md") || bad "SKILL.md does not start with a frontmatter block"
keys=$(printf '%s\n' "$fm" | grep -E '^[A-Za-z_-]+:' | cut -d: -f1)
for k in $keys; do
  case "$k" in name|description|license|compatibility|metadata) ;; *) bad "SKILL.md frontmatter has disallowed key: $k" ;; esac
done
for k in name description; do
  printf '%s\n' "$keys" | grep -qx "$k" || bad "SKILL.md frontmatter missing required key: $k"
done
pass "SKILL.md frontmatter keys: $(printf '%s' "$keys" | tr '\n' ' ')"

# 2. every references/*.md link in SKILL.md resolves, and every reference file is linked from SKILL.md
check
for link in $(grep -oE '\]\(references/[A-Za-z0-9._-]+\.md\)' "$SKILL/SKILL.md" | sed -E 's/^\]\((.*)\)$/\1/' | sort -u); do
  [ -f "$SKILL/$link" ] || bad "SKILL.md links to missing file: $link"
done
for f in "$SKILL"/references/*.md; do
  grep -q "references/$(basename "$f")" "$SKILL/SKILL.md" || bad "reference not linked from SKILL.md: $(basename "$f")"
done
pass "all references/*.md links in SKILL.md resolve; every reference is linked"

# 3. every agent template has name/description/tools/model, and name matches filename
check
for f in "$SKILL"/agents/*.md; do
  base=$(basename "$f" .md)
  afm=$(fm_of "$f") || { bad "$base: no frontmatter"; continue; }
  for k in name description tools model; do
    printf '%s\n' "$afm" | grep -qE "^$k: *[^ ]" || bad "$base: frontmatter missing $k"
  done
  n=$(printf '%s\n' "$afm" | sed -nE 's/^name: *//p')
  [ "$n" = "$base" ] || bad "$base: name '$n' does not match filename"
  grep -qF "$FOOTER" "$f" || bad "$base: does not mention the footer line"
done
pass "agent templates: $(ls "$SKILL"/agents/*.md | xargs -n1 basename | sed 's/\.md$//' | tr '\n' ' ')"

# 4. the verbatim footer ends every brief. A brief is a fenced block whose first line is "## Task"
#    or "## Role"; its last non-blank line must be the footer, unindented. Any fenced block that
#    contains the footer must also end with it.
check
BRIEFS="SKILL.md references/prompt-spec.md references/verifier.md references/db-check.md references/dependencies.md"
for f in $BRIEFS; do
  grep -qF "$FOOTER" "$SKILL/$f" || bad "$f: verbatim footer line missing"
done
for p in "$SKILL/SKILL.md" "$SKILL"/references/*.md; do
  f=${p#"$SKILL/"}
  res=$(awk -v F="$FOOTER" '
    /^ *```/ {
      if (inb) {
        if (has && last != F) bad = bad " footer-not-last@" start
        if (first ~ /^## (Task|Role)([ ]|$)/) { nb++; if (last != F) bad = bad " brief-without-footer@" start }
        if (last == F) nf++
        inb = 0
      } else { inb = 1; has = 0; last = ""; first = ""; start = NR }
      next
    }
    inb { if ($0 != "") { last = $0; if (first == "") first = $0 }; if (index($0, F)) has = 1 }
    END { printf "%d %d%s\n", nb, nf, bad }' "$p")
  set -- $res
  nb=$1; nf=$2; shift 2
  [ $# -eq 0 ] || bad "$f: a fenced brief does not end with the verbatim footer line (block at line:$*)"
  case " $BRIEFS " in
    *" $f "*)
      if [ "$f" = SKILL.md ]; then [ "$nf" -ge 1 ] || bad "SKILL.md: no fenced block ends with the footer"
      else [ "$nb" -ge 1 ] || bad "$f: no fenced brief (a block starting '## Task' or '## Role') found"; fi ;;
  esac
done
# no near-miss paraphrases anywhere in the repo (this script excluded: it holds the patterns)
PARA='\[ *task list|task list broken down|each phase as a vertical'
if grep -rnE "$PARA" "$ROOT" --exclude-dir=.git | grep -v '^[^:]*scripts/validate\.sh:' | grep -vF "$FOOTER" | grep -q .; then
  bad "a paraphrased footer exists:"
  grep -rnE "$PARA" "$ROOT" --exclude-dir=.git | grep -v '^[^:]*scripts/validate\.sh:' | grep -vF "$FOOTER"
fi
pass "every fenced brief ('## Task'/'## Role') ends with the verbatim footer; no paraphrases in the repo"

# 5. version consistency: SKILL.md metadata == bootstrap state JSON == bootstrap Step 0 ==
#    status.md sample == evals/foreign-agents-md.md == top CHANGELOG entry
check
v_skill=$(printf '%s\n' "$fm" | sed -nE 's/^  version: *//p' | head -1)
v_boot=$(grep -oE '"version": *"[0-9.]+"' "$SKILL/references/bootstrap.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
v_step0=$(grep -oE '`metadata\.version` \(`[0-9.]+`\)' "$SKILL/references/bootstrap.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
v_status=$(grep -oE '^State: +version [0-9.]+' "$SKILL/references/status.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
v_eval=$(grep -oE '"version": *"[0-9.]+"' "$ROOT/evals/foreign-agents-md.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
v_log=$(grep -oE '^## [0-9]+\.[0-9]+\.[0-9]+' "$ROOT/CHANGELOG.md" | head -1 | cut -c4-)
[ -n "$v_skill" ] || bad "SKILL.md metadata has no version"
for pair in "bootstrap.md state JSON=$v_boot" "bootstrap.md Step 0=$v_step0" "status.md sample=$v_status" \
            "evals/foreign-agents-md.md=$v_eval" "CHANGELOG.md=$v_log"; do
  [ "${pair#*=}" = "$v_skill" ] || bad "version mismatch: SKILL.md=$v_skill but ${pair%%=*}=${pair#*=}"
done
pass "version $v_skill consistent across SKILL.md, bootstrap.md (state + Step 0), status.md, evals/foreign-agents-md.md, CHANGELOG.md"

# 6. example AGENTS.md carries the dispatch markers
check
ex="$SKILL/examples/AGENTS.example.md"
{ grep -q '<!-- dispatch:map v1 -->' "$ex" && grep -q '<!-- /dispatch:map -->' "$ex"; } || bad "example AGENTS.md missing dispatch markers"
{ grep -q '^## Verification capabilities' "$ex" && grep -q '^### Surfaces' "$ex"; } \
  || bad "example AGENTS.md missing '## Verification capabilities' or '### Surfaces'"
pass "example AGENTS.md has dispatch markers, Verification capabilities and Surfaces"

# 7. evals: each scenario has the three required headings, and README lists every scenario
check
n_evals=0
for f in "$ROOT"/evals/*.md; do
  b=$(basename "$f")
  [ "$b" = "README.md" ] && continue
  n_evals=$((n_evals + 1))
  for h in '## Setup' '## Prompt' '## Expected behaviour'; do
    grep -q "^$h" "$f" || bad "$b: missing '$h'"
  done
  grep -qF "\`$b\`" "$ROOT/evals/README.md" || bad "evals/README.md has no row for $b"
done
[ "$n_evals" -ge 5 ] || bad "evals: expected at least 5 scenarios, found $n_evals"
pass "evals: $n_evals scenarios with Setup / Prompt / Expected behaviour, all listed in evals/README.md"

# 8. agent template models — in the frontmatter itself. The security critic is always opus:
#    a judgement that misses something is worse than a slow one, whatever the diff size.
check
for a in dispatch-implementer dispatch-frontend dispatch-security-critic; do
  fm_of "$SKILL/agents/$a.md" | grep -qE '^model: *opus$' || bad "$a: expected 'model: opus' in frontmatter"
done
fm_of "$SKILL/agents/dispatch-db-tester.md" | grep -qE '^model: *sonnet$' \
  || bad "dispatch-db-tester: expected 'model: sonnet' in frontmatter"
grep -qE 'never downgraded to `sonnet`' "$SKILL/agents/dispatch-security-critic.md" \
  || bad "dispatch-security-critic.md does not say the role is never downgraded to sonnet"
pass "dispatch-implementer, dispatch-frontend and dispatch-security-critic default to model: opus; dispatch-db-tester to sonnet"

# 9. SKILL.md states the 2-concurrent-sub-agent cap
check
grep -qF 'more than 2 sub-agents' "$SKILL/SKILL.md" || bad "SKILL.md does not mention the 2 sub-agent concurrency cap"
pass "SKILL.md mentions the 2-concurrent sub-agent cap"

# 10. responsive.md exists and is linked from SKILL.md
check
if [ -f "$SKILL/references/responsive.md" ]; then
  grep -q 'references/responsive.md' "$SKILL/SKILL.md" || bad "responsive.md exists but is not linked from SKILL.md"
else
  bad "skills/dispatch/references/responsive.md is missing"
fi
pass "responsive.md exists and is linked from SKILL.md"

# 11. new-project.md exists, is linked from SKILL.md, and mentions "one question"
check
if [ -f "$SKILL/references/new-project.md" ]; then
  grep -q 'references/new-project.md' "$SKILL/SKILL.md" || bad "new-project.md exists but is not linked from SKILL.md"
  grep -qi 'one question' "$SKILL/references/new-project.md" || bad "new-project.md does not mention 'one question'"
else
  bad "skills/dispatch/references/new-project.md is missing"
fi
pass "new-project.md exists, is linked from SKILL.md, and mentions 'one question'"

# 12. every agent template runs at effort: high — in the frontmatter itself
check
for f in "$SKILL"/agents/*.md; do
  fm_of "$f" | grep -qE '^effort: *high$' || bad "$(basename "$f" .md): expected 'effort: high' in frontmatter"
done
pass "agent templates set effort: high (frontmatter)"

# 13. the measure script ships with the skill and parses (node --check; skipped only without node)
check
MEASURE="$SKILL/scripts/dispatch-measure.mjs"
how="node --check skipped: node not installed"
if [ -f "$MEASURE" ]; then
  if command -v node >/dev/null 2>&1; then
    how="passes node --check"
    node --check "$MEASURE" 2>/dev/null || bad "dispatch-measure.mjs fails node --check"
  fi
  grep -qF 'die(2, `dev server not reachable at ${o.url}`)' "$MEASURE" \
    || bad "dispatch-measure.mjs does not exit 2 with 'dev server not reachable at <url>'"
else
  bad "skills/dispatch/scripts/dispatch-measure.mjs is missing"
fi
pass "dispatch-measure.mjs exists ($how) and exits 2 with 'dev server not reachable at <url>'"

# 14. one measuring script, not retyped snippets: references and the frontend template call it
check
if grep -rn 'chromium.launch' "$SKILL/references" "$SKILL/agents" | grep -q .; then
  bad "an inline Playwright snippet (chromium.launch) is back in references/ or agents/:"
  grep -rn 'chromium.launch' "$SKILL/references" "$SKILL/agents"
fi
for f in references/acceptance.md references/responsive.md agents/dispatch-frontend.md; do
  grep -qF 'dispatch-measure.mjs' "$SKILL/$f" || bad "$f does not reference dispatch-measure.mjs"
done
pass "no inline Playwright snippet; acceptance.md, responsive.md, dispatch-frontend.md call dispatch-measure.mjs"

# 15. setup.md exists and is linked from SKILL.md; bootstrap runs it; status reads what it records
check
if [ -f "$SKILL/references/setup.md" ]; then
  grep -q 'references/setup.md' "$SKILL/SKILL.md" || bad "setup.md exists but is not linked from SKILL.md"
else
  bad "skills/dispatch/references/setup.md is missing"
fi
grep -qF '## Verification capabilities' "$SKILL/references/setup.md" 2>/dev/null \
  || bad "setup.md does not define the '## Verification capabilities' section"
grep -qF 'Verification capabilities' "$SKILL/references/status.md" \
  || bad "status.md does not read the 'Verification capabilities' section"
{ grep -qF 'Step 2c' "$SKILL/references/bootstrap.md" && grep -qF '"capabilities_measured"' "$SKILL/references/bootstrap.md"; } \
  || bad "bootstrap.md lacks Step 2c or the capabilities_measured state key"
grep -qF '.claude/dispatch/' "$SKILL/references/setup.md" 2>/dev/null \
  || bad "setup.md does not copy the measure script into .claude/dispatch/"
pass "setup.md defines Verification capabilities; bootstrap Step 2c runs it; status.md reads it"

# 16. relative links between reference files resolve (anchors ignored; reference names are
#     lowercase — an uppercase target like AGENTS.md is a file in the user's repo, not ours)
check
for f in "$SKILL"/references/*.md; do
  for link in $(grep -oE '\]\([a-z0-9._-]+\.md(#[^)]*)?\)' "$f" | sed -E 's/^\]\(([^)#]*).*$/\1/' | sort -u); do
    [ -f "$SKILL/references/$link" ] || bad "$(basename "$f") links to missing reference: $link"
  done
done
pass "links between reference files resolve"

# 17. design guidance is wired: the frontend agent reads DESIGN.md; setup generates it; acceptance checks it
check
grep -qF 'DESIGN.md' "$SKILL/agents/dispatch-frontend.md" || bad "dispatch-frontend.md does not mention DESIGN.md"
grep -qF 'then `DESIGN.md` if it exists' "$SKILL/agents/dispatch-frontend.md" \
  || bad "dispatch-frontend.md 'Start here' does not read DESIGN.md"
for f in references/setup.md references/prompt-spec.md references/responsive.md references/acceptance.md; do
  grep -qF 'DESIGN.md' "$SKILL/$f" || bad "$f does not mention DESIGN.md"
done
grep -qF 'skip this check entirely' "$SKILL/references/acceptance.md" \
  || bad "acceptance.md does not waive the DESIGN.md value check when DESIGN.md is absent"
pass "DESIGN.md wired into dispatch-frontend.md, setup.md, prompt-spec.md, responsive.md, acceptance.md (waived without it)"

# 18. dependencies.md exists, is linked from SKILL.md, carries the footer, and the stop-cases route to it
check
if [ -f "$SKILL/references/dependencies.md" ]; then
  grep -q 'references/dependencies.md' "$SKILL/SKILL.md" || bad "dependencies.md exists but is not linked from SKILL.md"
  grep -qF "$FOOTER" "$SKILL/references/dependencies.md" || bad "dependencies.md: verbatim footer line missing"
  grep -qF '`sonnet`' "$SKILL/references/dependencies.md" || bad "dependencies.md does not pin the deps brief to sonnet"
else
  bad "skills/dispatch/references/dependencies.md is missing"
fi
for f in references/failures.md references/when-not-to-dispatch.md; do
  grep -qF 'dependencies.md' "$SKILL/$f" || bad "$f does not route dependency changes to dependencies.md"
done
grep -qF '/dispatch deps' "$SKILL/SKILL.md" || bad "SKILL.md mode table has no /dispatch deps row"
pass "dependencies.md linked with footer and sonnet; failures.md and when-not-to-dispatch.md route to it"

# 19. database guards are a hard rule: refuse the application's read-write credential
check
REFUSAL='refuses to proceed when the only credential it can find is the application'"'"'s'
grep -qF "$REFUSAL" "$SKILL/references/db-check.md" || bad "db-check.md does not contain the refusal rule: '$REFUSAL ...'"
grep -qiF 'refuse to proceed when the only credential you can find is the application' "$SKILL/agents/dispatch-db-tester.md" \
  || bad "dispatch-db-tester.md does not carry the refusal rule"
awk '/^## Start here/{s=1} /^## Absolute constraints/{s=0} s' "$SKILL/agents/dispatch-db-tester.md" | grep -qi 'refuse to proceed' \
  || bad "dispatch-db-tester.md: the refusal is not in its 'Start here' section"
if grep -rniE 'prefer (a )?read-only (db )?user|read-only (db )?user if one exists' "$SKILL" | grep -q .; then
  bad "the old 'prefer a read-only user' wording is still present:"; grep -rniE 'prefer (a )?read-only (db )?user|read-only (db )?user if one exists' "$SKILL"
fi
grep -qF 'Step e' "$SKILL/references/setup.md" || bad "setup.md has no Step e (database guards)"
pass "db-check.md and dispatch-db-tester.md refuse read-write credentials; setup.md step e provisions a read-only user"

# 20. the Surfaces table: bootstrap generates it, LOCATE uses it, briefs call it by that name
check
grep -qF '### Surfaces' "$SKILL/references/bootstrap.md" && grep -qF 'route:list --json' "$SKILL/references/bootstrap.md" \
  || bad "bootstrap.md lacks the Surfaces table or its framework recipes"
grep -qF 'Surfaces table' "$SKILL/SKILL.md" || bad "SKILL.md LOCATE step does not use the Surfaces table"
grep -qF 'Styles by surface' "$SKILL/references/prompt-spec.md" && bad "prompt-spec.md names a 'Styles by surface' table; bootstrap generates 'Surfaces'"
pass "bootstrap.md generates a Surfaces table; SKILL.md LOCATE and prompt-spec.md use that name"

# 21. version: this release's checks assume at least 1.6.0 (consistency itself is check 5)
check
MIN_VERSION=1.6.0
if [ -z "$v_skill" ] || [ "$(printf '%s\n%s\n' "$MIN_VERSION" "$v_skill" | sort -V | head -1)" != "$MIN_VERSION" ]; then
  bad "version '$v_skill' is older than $MIN_VERSION, which the checks below assume"
fi
pass "version $v_skill is at least $MIN_VERSION"

# 22. SKILL.md stays lean and lists every mode; details live in references.
#     The limit was 250 through 1.5.1 and the file sat at exactly 250, so any addition failed.
#     1.6.0 has to say in SKILL.md itself which of the two sessions is reading it and which
#     non-negotiables that session is bound by — routing that cannot live in a reference file,
#     because a session has to route before it knows which reference to open. 270 is 250 plus
#     that routing (the mode-recognition block, the "(main session)" markers, their preamble)
#     and nothing else; everything beyond it is detail, and detail belongs in references/.
check
lines=$(wc -l < "$SKILL/SKILL.md")
[ "$lines" -le 270 ] || bad "SKILL.md is $lines lines — move detail into references (limit 270)"
for m in '/dispatch setup' '/dispatch deps' '/dispatch bootstrap' '/dispatch new' '/dispatch verify' '/dispatch db' '/dispatch status'; do
  grep -qF "| \`$m" "$SKILL/SKILL.md" || bad "SKILL.md mode table has no row for $m"
done
pass "SKILL.md is $lines lines (limit 270); mode table lists bootstrap, setup, new, deps, verify, db, status"

# 23. every brief carries Task and Done means (SKILL.md's list and prompt-spec.md's template),
#     and every UI brief names its page (Page URL)
check
for item in Task Inputs 'Done means' Report Footer; do
  grep -qE "^- \*\*$item\*\*" "$SKILL/SKILL.md" || bad "SKILL.md 'Every brief carries' list has no '- **$item**' line"
done
for h in '## Task' '## Inputs' '## Done means' '## Report'; do
  grep -qx "$h" "$SKILL/references/prompt-spec.md" || bad "prompt-spec.md template has no '$h' section"
done
[ "$(grep -cE '^Page URL\(s\):' "$SKILL/references/prompt-spec.md")" -ge 2 ] \
  || bad "prompt-spec.md: the template and the worked example need a 'Page URL(s):' line under Inputs"
grep -qF 'Page URL' "$SKILL/references/acceptance.md" || bad "acceptance.md does not read the brief's Page URL(s)"
grep -qF 'Page URL' "$SKILL/agents/dispatch-frontend.md" || bad "dispatch-frontend.md does not read the brief's Page URL(s)"
if grep -rn '\$URL\b' "$SKILL/references" "$SKILL/agents" | grep -q .; then
  bad "an undefined \$URL is used:"; grep -rn '\$URL\b' "$SKILL/references" "$SKILL/agents"
fi
# ...and the fenced example briefs themselves, not just the prose: every fenced block that opens
# with "## Task" or "## Role" must carry a "## Task" line and a "## Done means" line.
for p in "$SKILL/SKILL.md" "$SKILL"/references/*.md; do
  miss=$(awk '
    /^ *```/ { if (inb) { if (isb) { if (!t) m = m " no-Task@" start; if (!d) m = m " no-Done-means@" start } inb = 0 }
               else { inb = 1; isb = 0; t = 0; d = 0; first = 1; start = NR } ; next }
    inb { if (first && $0 != "") { first = 0; if ($0 ~ /^## (Task|Role)([ ]|$)/) isb = 1 }
          if ($0 == "## Task") t = 1; if ($0 == "## Done means") d = 1 }
    END { print m }' "$p")
  [ -z "$miss" ] || bad "${p#"$SKILL/"}: a fenced brief is missing a mandatory section (block at line:$miss)"
done
pass "briefs carry Task and Done means, in the prose list and in every fenced brief; UI briefs carry Page URL(s)"

# 24. base handling: printed shas, a snapshot instead of intent-to-add, worktree-safe index path
check
INTENT='git add[^`]*(-N\b|--intent-to-add\b)'
if grep -rnE "$INTENT" "$SKILL" "$ROOT/README.md" | grep -q .; then
  bad "'git add -N' / 'git add --intent-to-add' is still used (acceptance takes a second snapshot instead):"
  grep -rnE "$INTENT" "$SKILL" "$ROOT/README.md"
fi
if grep -rnE 'BASE=\$\(|"\$BASE"|GIT_INDEX_FILE=\.git/' "$SKILL" "$ROOT/evals" | grep -q .; then
  bad "BASE is kept in a shell variable or the index path assumes .git is a directory:"
  grep -rnE 'BASE=\$\(|"\$BASE"|GIT_INDEX_FILE=\.git/' "$SKILL" "$ROOT/evals"
fi
for f in SKILL.md references/acceptance.md; do
  grep -qF 'git rev-parse --path-format=absolute --git-path dispatch-snap-index' "$SKILL/$f" \
    || bad "$f: the snapshot command does not use git rev-parse --path-format=absolute --git-path"
  grep -qF 'git diff <BASE> <AFTER>' "$SKILL/$f" || bad "$f: acceptance does not diff two snapshots (<BASE> <AFTER>)"
done
grep -qF 'git restore --source=<BASE> --worktree' "$SKILL/references/failures.md" \
  || bad "failures.md does not revert with git restore --source=<BASE> --worktree"
pass "BASE/AFTER are printed snapshots; no git add -N; worktree-safe index path; revert leaves the index alone"

# 25. no ls-with-a-glob in the instructions (zsh aborts the whole command on an unmatched glob)
check
if grep -rnE '(^|[`(;&| ])ls +[^|;&`#]*\*' "$SKILL/SKILL.md" "$SKILL/references" "$SKILL/agents" | grep -q .; then
  bad "an 'ls <name>.*' style glob remains — use find -name:"
  grep -rnE '(^|[`(;&| ])ls +[^|;&`#]*\*' "$SKILL/SKILL.md" "$SKILL/references" "$SKILL/agents"
fi
if grep -rnE 'grep [^|]*\$X\b|\bgo --version' "$SKILL/references" | grep -q .; then
  bad "an unquoted \$X flag list or 'go --version' remains:"; grep -rnE 'grep [^|]*\$X\b|\bgo --version' "$SKILL/references"
fi
pass "no ls globs, split-dependent flag lists or 'go --version' in SKILL.md, references/, agents/"

# 26. deps briefs get through the implementer; db guards are on every invocation
check
grep -qF "unless the brief's Task line says it is a dependency brief" "$SKILL/agents/dispatch-implementer.md" \
  || bad "dispatch-implementer.md lacks the dependency-brief exception"
grep -qF 'Dependency brief (dependencies.md):' "$SKILL/references/dependencies.md" \
  || bad "dependencies.md's brief Task line does not say 'Dependency brief (dependencies.md):'"
for f in agents/dispatch-db-tester.md references/db-check.md; do
  grep -qF "PGOPTIONS='-c default_transaction_read_only=on'" "$SKILL/$f" || bad "$f does not put PGOPTIONS on psql"
  grep -qF -e "--init-command='SET SESSION TRANSACTION READ ONLY'" "$SKILL/$f" || bad "$f does not put --init-command on mysql"
done
grep -qF 'SET SESSION CHARACTERISTICS' "$SKILL/agents/dispatch-db-tester.md" \
  && bad "dispatch-db-tester.md still opens a one-off SET SESSION CHARACTERISTICS session"
grep -qF 'WHERE grantee = current_user' "$SKILL/agents/dispatch-db-tester.md" \
  && bad "dispatch-db-tester.md still checks Postgres grants with grantee = current_user (misses inherited roles)"
grep -qF 'has_table_privilege' "$SKILL/agents/dispatch-db-tester.md" || bad "dispatch-db-tester.md does not use has_table_privilege"
pass "implementer takes dependency briefs; db-tester and db-check.md use PGOPTIONS / --init-command on every call"

# 27. dispatch-measure.mjs unit tests (arg parsing incl. --prop --brand, python/timeout handling,
#     repo-only Playwright lookup) — no Playwright, no network; skipped only without node
check
TEST="$ROOT/scripts/measure.test.mjs"
how="not run: node not installed"
if [ ! -f "$TEST" ]; then
  bad "scripts/measure.test.mjs is missing"
else
  grep -qF "'--prop', '--brand'" "$TEST" || bad "measure.test.mjs does not test '--prop --brand'"
  if command -v node >/dev/null 2>&1; then
    out=$(cd "$ROOT" && node --test scripts/measure.test.mjs 2>&1) \
      || { bad "node --test scripts/measure.test.mjs failed:"; printf '%s\n' "$out" | grep -E '^not ok|^# (pass|fail)'; }
    how="$(printf '%s\n' "$out" | sed -nE 's/^# pass ([0-9]+)$/\1/p') passed"
  fi
fi
pass "scripts/measure.test.mjs covers --prop --brand; node --test: $how"

# 28. the polish session: its mode row, its reference file, and the index-only rule in the
#     non-negotiables (the rule the whole feature rests on — it must survive an edit to SKILL.md)
check
grep -qF '| `/dispatch polish' "$SKILL/SKILL.md" || bad "SKILL.md mode table has no /dispatch polish row"
if [ -f "$SKILL/references/polish.md" ]; then
  grep -q 'references/polish.md' "$SKILL/SKILL.md" || bad "polish.md exists but is not linked from SKILL.md"
  for s in '.claude/dispatch/polish/INDEX.md' '.claude/dispatch/polish/requests/' 'at most two lines'; do
    grep -qF "$s" "$SKILL/references/polish.md" || bad "polish.md does not define '$s'"
  done
else
  bad "skills/dispatch/references/polish.md is missing"
fi
awk '/^## Non-negotiables/{s=1; next} s && /^## /{s=0} s' "$SKILL/SKILL.md" \
  | grep -qF '.claude/dispatch/polish/INDEX.md' \
  || bad "SKILL.md non-negotiables do not carry the index-only polish reading rule"
# bootstrap must carry the creation COMMANDS, not just the path: the string
# '.claude/dispatch/polish' appears throughout the file, so grepping for it passes even with
# the whole "The polish directory." block deleted.
grep -qF 'mkdir -p .claude/dispatch/polish/requests' "$SKILL/references/bootstrap.md" \
  || bad "bootstrap.md does not run 'mkdir -p .claude/dispatch/polish/requests'"
grep -qF '> .claude/dispatch/polish/INDEX.md' "$SKILL/references/bootstrap.md" \
  || bad "bootstrap.md does not seed .claude/dispatch/polish/INDEX.md"
grep -qF '[ -f .claude/dispatch/polish/INDEX.md ] ||' "$SKILL/references/bootstrap.md" \
  || bad "bootstrap.md's index seed is unguarded — re-running bootstrap would overwrite the ledger"
pass "polish mode row, references/polish.md linked, index-only rule in the non-negotiables, bootstrap runs mkdir + a guarded index seed"

# 29. the polish session is scoped, not self-negating: SKILL.md says which session is reading
#     it, polish.md says which non-negotiables it replaces, and the ceiling exempts it
check
grep -qF 'Which session are you?' "$SKILL/SKILL.md" \
  || bad "SKILL.md has no mode-recognition step — a polish session cannot tell it is the second session"
awk '/^## Non-negotiables/{s=1; next} s && /^## /{s=0} s' "$SKILL/SKILL.md" \
  | grep -qF '(main session)' \
  || bad "SKILL.md non-negotiables are not scoped to the main session — they forbid the polish session its job"
for s in 'Which session are you?' 'replaces four of' 'ceiling does not apply here'; do
  grep -qF "$s" "$SKILL/references/polish.md" || bad "polish.md does not state '$s'"
done
grep -qF 'ceiling bounds an intake' "$SKILL/references/responsive.md" \
  || bad "responsive.md does not exempt the polish session from the 8-question ceiling"
grep -qF 'The second session, never this one' "$SKILL/SKILL.md" \
  && bad "SKILL.md's polish mode row still reads 'The second session, never this one' — self-negating to the session reading it"
pass "polish/main session recognition in SKILL.md and polish.md; non-negotiables scoped; question ceiling exempts polish"

# 30. the 1.6.0 effort and model policy, in the prose — the agent frontmatter is checks 8 and 12,
#     but nothing there stops the rules the main session reads from drifting back
check
if grep -rnE 'effort: *(low|medium|xhigh|max)\b' "$SKILL" "$ROOT/README.md" "$ROOT/evals" "$ROOT/scripts" | grep -q .; then
  bad "an effort other than high is stated as policy:"
  grep -rnE 'effort: *(low|medium|xhigh|max)\b' "$SKILL" "$ROOT/README.md" "$ROOT/evals" "$ROOT/scripts"
fi
grep -qF 'Effort is `high` for every sub-agent' "$SKILL/SKILL.md" \
  || bad "SKILL.md does not state 'Effort is \`high\` for every sub-agent'"
grep -qF 'Every sub-agent runs at `effort: high`' "$SKILL/references/routing.md" \
  || bad "routing.md does not state 'Every sub-agent runs at \`effort: high\`'"
grep -qF 'Every template carries `effort: high`' "$SKILL/references/bootstrap.md" \
  || bad "bootstrap.md Step 3 does not state 'Every template carries \`effort: high\`'"
grep -qF 'sets `effort: high` in its frontmatter' "$ROOT/README.md" \
  || bad "README.md does not state that every template sets 'effort: high' in its frontmatter"
# ...and the security critic is opus in all four, however small the diff
grep -qF 'security critic **always**, however small the diff' "$SKILL/SKILL.md" \
  || bad "SKILL.md's model paragraph does not pin the security critic to opus for every diff size"
grep -qF '| **Security review — always, whatever the diff size** | `opus` |' "$SKILL/references/routing.md" \
  || bad "routing.md's model table has no always-opus row for security review"
grep -qF '`dispatch-security-critic` is `opus` always' "$SKILL/references/bootstrap.md" \
  || bad "bootstrap.md Step 3 does not say dispatch-security-critic installs as opus always"
grep -qF '| opus (always, whatever the diff size) |' "$ROOT/README.md" \
  || bad "README.md's agent table does not mark dispatch-security-critic opus (always, whatever the diff size)"
pass "effort: high and security-critic-always-opus stated in SKILL.md, routing.md, bootstrap.md and README.md"

[ "$nfail" -eq 0 ] && { echo "PASS"; exit 0; } || { echo "FAILED ($nfail)"; exit 1; }
