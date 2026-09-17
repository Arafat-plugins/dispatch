#!/usr/bin/env bash
# Structural checks for the dispatch skill. Bash only, no dependencies.
# Usage: scripts/validate.sh        (from anywhere; exits 1 on the first category with failures)
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/skills/dispatch"
FOOTER='[ task list broken down into phases, each phase as a vertical slice, numbered ]'
fail=0
ok()   { printf 'ok    %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fail=1; }

# 1. SKILL.md frontmatter: only name, description, license, compatibility, metadata at top level
fm=$(awk 'NR==1 && $0!="---"{exit 1} NR>1 && $0=="---"{exit} NR>1{print}' "$SKILL/SKILL.md") \
  || bad "SKILL.md does not start with a frontmatter block"
keys=$(printf '%s\n' "$fm" | grep -E '^[A-Za-z_-]+:' | cut -d: -f1)
for k in $keys; do
  case "$k" in name|description|license|compatibility|metadata) ;; *) bad "SKILL.md frontmatter has disallowed key: $k" ;; esac
done
for k in name description; do
  printf '%s\n' "$keys" | grep -qx "$k" || bad "SKILL.md frontmatter missing required key: $k"
done
ok "SKILL.md frontmatter keys: $(printf '%s' "$keys" | tr '\n' ' ')"

# 2. every references/*.md link in SKILL.md resolves
missing=0
for link in $(grep -oE '\]\(references/[A-Za-z0-9._-]+\.md\)' "$SKILL/SKILL.md" | sed -E 's/^\]\((.*)\)$/\1/' | sort -u); do
  [ -f "$SKILL/$link" ] || { bad "SKILL.md links to missing file: $link"; missing=1; }
done
[ $missing -eq 0 ] && ok "all references/*.md links in SKILL.md resolve"
# and every reference file is linked from SKILL.md (a reference nobody reaches is dead)
for f in "$SKILL"/references/*.md; do
  grep -q "references/$(basename "$f")" "$SKILL/SKILL.md" || bad "reference not linked from SKILL.md: $(basename "$f")"
done

# 3. every agent template has name/description/tools/model, and name matches filename
for f in "$SKILL"/agents/*.md; do
  base=$(basename "$f" .md)
  afm=$(awk 'NR==1 && $0!="---"{exit 1} NR>1 && $0=="---"{exit} NR>1{print}' "$f") || { bad "$base: no frontmatter"; continue; }
  for k in name description tools model; do
    printf '%s\n' "$afm" | grep -qE "^$k: *[^ ]" || bad "$base: frontmatter missing $k"
  done
  n=$(printf '%s\n' "$afm" | sed -nE 's/^name: *//p')
  [ "$n" = "$base" ] || bad "$base: name '$n' does not match filename"
  grep -qF "$FOOTER" "$f" || bad "$base: does not mention the footer line"
done
ok "agent templates: $(ls "$SKILL"/agents/*.md | xargs -n1 basename | sed 's/\.md$//' | tr '\n' ' ')"

# 4. the verbatim footer is the last line of every brief template (fenced blocks ending in it)
BRIEFS="SKILL.md references/prompt-spec.md references/verifier.md references/db-check.md references/dependencies.md"
for f in $BRIEFS; do
  grep -qF "$FOOTER" "$SKILL/$f" || bad "$f: verbatim footer line missing"
  # inside every fenced block that contains the footer, it is the last non-empty line, unindented
  awk -v F="$FOOTER" '
    /^ *```/ { if (inb) { if (has && last != F) b = 1; if (last == F) n++; inb = 0 } else { inb = 1; has = 0; last = "" }; next }
    inb { if ($0 != "") last = $0; if (index($0, F)) has = 1 }
    END { exit (b || n == 0) }' "$SKILL/$f" \
    || bad "$f: a fenced brief does not end with the verbatim footer line"
done
# no near-miss paraphrases anywhere in the repo (this script excluded: it holds the patterns)
PARA='\[ *task list|task list broken down|each phase as a vertical'
if grep -rnE "$PARA" "$ROOT" --exclude-dir=.git | grep -v '^[^:]*scripts/validate\.sh:' | grep -vF "$FOOTER" | grep -q .; then
  bad "a paraphrased footer exists:"
  grep -rnE "$PARA" "$ROOT" --exclude-dir=.git | grep -v '^[^:]*scripts/validate\.sh:' | grep -vF "$FOOTER"
fi
ok "verbatim footer ends the briefs in $(echo $BRIEFS | tr ' ' ',' | sed 's|references/||g'); no paraphrases in the repo"

# 5. version consistency: SKILL.md metadata == bootstrap state JSON == top CHANGELOG entry
v_skill=$(sed -nE 's/^  version: *//p' "$SKILL/SKILL.md" | head -1)
v_boot=$(grep -oE '"version": *"[0-9.]+"' "$SKILL/references/bootstrap.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
v_log=$(grep -oE '^## [0-9]+\.[0-9]+\.[0-9]+' "$ROOT/CHANGELOG.md" | head -1 | cut -c4-)
if [ -n "$v_skill" ] && [ "$v_skill" = "$v_boot" ] && [ "$v_skill" = "$v_log" ]; then
  ok "version $v_skill consistent across SKILL.md, bootstrap.md, CHANGELOG.md"
else
  bad "version mismatch: SKILL.md=$v_skill bootstrap.md=$v_boot CHANGELOG.md=$v_log"
fi

# 6. example AGENTS.md carries the dispatch markers
ex="$SKILL/examples/AGENTS.example.md"
{ grep -q '<!-- dispatch:map v1 -->' "$ex" && grep -q '<!-- /dispatch:map -->' "$ex"; } \
  && ok "example AGENTS.md has dispatch markers" || bad "example AGENTS.md missing dispatch markers"
{ grep -q '^## Verification capabilities' "$ex" && grep -q '^### Surfaces' "$ex"; } \
  && ok "example AGENTS.md has Verification capabilities and Surfaces" \
  || bad "example AGENTS.md missing '## Verification capabilities' or '### Surfaces'"

# 7. evals: each scenario has the three required headings
n_evals=0
for f in "$ROOT"/evals/*.md; do
  [ "$(basename "$f")" = "README.md" ] && continue
  n_evals=$((n_evals + 1))
  for h in '## Setup' '## Prompt' '## Expected behaviour'; do
    grep -q "^$h" "$f" || bad "$(basename "$f"): missing '$h'"
  done
done
[ "$n_evals" -ge 5 ] && ok "evals: $n_evals scenarios with Setup / Prompt / Expected behaviour" || bad "evals: expected at least 5 scenarios, found $n_evals"

# 8. implementer and frontend templates default to model: opus (they cover core/design work)
for a in dispatch-implementer dispatch-frontend; do
  grep -qE '^model: *opus$' "$SKILL/agents/$a.md" || bad "$a: expected 'model: opus' in frontmatter"
done
ok "dispatch-implementer and dispatch-frontend default to model: opus"

# 9. SKILL.md states the 2-concurrent-sub-agent cap
grep -qF 'more than 2 sub-agents' "$SKILL/SKILL.md" || bad "SKILL.md does not mention the 2 sub-agent concurrency cap"
ok "SKILL.md mentions the 2-concurrent sub-agent cap"

# 10. responsive.md exists and is linked from SKILL.md
if [ -f "$SKILL/references/responsive.md" ]; then
  grep -q 'references/responsive.md' "$SKILL/SKILL.md" && ok "responsive.md exists and is linked from SKILL.md" \
    || bad "responsive.md exists but is not linked from SKILL.md"
else
  bad "skills/dispatch/references/responsive.md is missing"
fi

# 11. new-project.md exists, is linked from SKILL.md, and mentions "one question"
if [ -f "$SKILL/references/new-project.md" ]; then
  linked=0; grep -q 'references/new-project.md' "$SKILL/SKILL.md" && linked=1
  phrase=0; grep -qi 'one question' "$SKILL/references/new-project.md" && phrase=1
  if [ $linked -eq 1 ] && [ $phrase -eq 1 ]; then
    ok "new-project.md exists, is linked from SKILL.md, and mentions 'one question'"
  else
    [ $linked -eq 1 ] || bad "new-project.md exists but is not linked from SKILL.md"
    [ $phrase -eq 1 ] || bad "new-project.md does not mention 'one question'"
  fi
else
  bad "skills/dispatch/references/new-project.md is missing"
fi

# 12. every agent template runs at effort: medium
for f in "$SKILL"/agents/*.md; do
  grep -qE '^effort: *medium$' "$f" || bad "$(basename "$f" .md): expected 'effort: medium' in frontmatter"
done
ok "agent templates set effort: medium"

# 13. the measure script ships with the skill and parses (node --check; skipped only without node)
MEASURE="$SKILL/scripts/dispatch-measure.mjs"
if [ -f "$MEASURE" ]; then
  ok "skills/dispatch/scripts/dispatch-measure.mjs exists"
  if command -v node >/dev/null 2>&1; then
    if node --check "$MEASURE" 2>/dev/null; then ok "dispatch-measure.mjs passes node --check"
    else bad "dispatch-measure.mjs fails node --check"; fi
  else
    ok "dispatch-measure.mjs node --check (node not installed, skipped)"
  fi
  grep -qF 'die(2, `dev server not reachable at ${o.url}`)' "$MEASURE" \
    && ok "dispatch-measure.mjs exits 2 with 'dev server not reachable at <url>'" \
    || bad "dispatch-measure.mjs does not exit 2 with 'dev server not reachable at <url>'"
else
  bad "skills/dispatch/scripts/dispatch-measure.mjs is missing"
fi

# 14. one measuring script, not retyped snippets: references and the frontend template call it
if grep -rn 'chromium.launch' "$SKILL/references" "$SKILL/agents" | grep -q .; then
  bad "an inline Playwright snippet (chromium.launch) is back in references/ or agents/:"
  grep -rn 'chromium.launch' "$SKILL/references" "$SKILL/agents"
else
  ok "no inline Playwright snippet in references/ or agents/"
fi
for f in references/acceptance.md references/responsive.md agents/dispatch-frontend.md; do
  grep -qF 'dispatch-measure.mjs' "$SKILL/$f" || bad "$f does not reference dispatch-measure.mjs"
done
ok "acceptance.md, responsive.md, dispatch-frontend.md reference dispatch-measure.mjs"

# 15. setup.md exists and is linked from SKILL.md; bootstrap runs it; status reads what it records
if [ -f "$SKILL/references/setup.md" ]; then
  grep -q 'references/setup.md' "$SKILL/SKILL.md" && ok "setup.md exists and is linked from SKILL.md" \
    || bad "setup.md exists but is not linked from SKILL.md"
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
ok "setup.md defines Verification capabilities; bootstrap Step 2c runs it; status.md reads it"

# 16. relative links between reference files resolve (anchors ignored; reference names are
#     lowercase — an uppercase target like AGENTS.md is a file in the user's repo, not ours)
dead=0
for f in "$SKILL"/references/*.md; do
  for link in $(grep -oE '\]\([a-z0-9._-]+\.md(#[^)]*)?\)' "$f" | sed -E 's/^\]\(([^)#]*).*$/\1/' | sort -u); do
    [ -f "$SKILL/references/$link" ] || { bad "$(basename "$f") links to missing reference: $link"; dead=1; }
  done
done
[ $dead -eq 0 ] && ok "links between reference files resolve"

# 17. design guidance is wired: the frontend agent reads DESIGN.md; setup generates it; acceptance checks it
grep -qF 'DESIGN.md' "$SKILL/agents/dispatch-frontend.md" || bad "dispatch-frontend.md does not mention DESIGN.md"
grep -qF 'then `DESIGN.md` if it exists' "$SKILL/agents/dispatch-frontend.md" \
  || bad "dispatch-frontend.md 'Start here' does not read DESIGN.md"
for f in references/setup.md references/prompt-spec.md references/responsive.md references/acceptance.md; do
  grep -qF 'DESIGN.md' "$SKILL/$f" || bad "$f does not mention DESIGN.md"
done
ok "DESIGN.md wired into dispatch-frontend.md, setup.md, prompt-spec.md, responsive.md, acceptance.md"

# 18. dependencies.md exists, is linked from SKILL.md, carries the footer, and the stop-cases route to it
if [ -f "$SKILL/references/dependencies.md" ]; then
  grep -q 'references/dependencies.md' "$SKILL/SKILL.md" && ok "dependencies.md exists and is linked from SKILL.md" \
    || bad "dependencies.md exists but is not linked from SKILL.md"
  grep -qF "$FOOTER" "$SKILL/references/dependencies.md" || bad "dependencies.md: verbatim footer line missing"
  grep -qF '`sonnet`' "$SKILL/references/dependencies.md" || bad "dependencies.md does not pin the deps brief to sonnet"
else
  bad "skills/dispatch/references/dependencies.md is missing"
fi
for f in references/failures.md references/when-not-to-dispatch.md; do
  grep -qF 'dependencies.md' "$SKILL/$f" || bad "$f does not route dependency changes to dependencies.md"
done
grep -qF '/dispatch deps' "$SKILL/SKILL.md" || bad "SKILL.md mode table has no /dispatch deps row"
ok "failures.md and when-not-to-dispatch.md route dependencies to dependencies.md; SKILL.md has /dispatch deps"

# 19. database guards are a hard rule: refuse the application's read-write credential
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
ok "db-check.md and dispatch-db-tester.md refuse read-write credentials; setup.md step e provisions a read-only user"

# 20. the Surfaces table: bootstrap generates it, LOCATE uses it
grep -qF '### Surfaces' "$SKILL/references/bootstrap.md" && grep -qF 'route:list --json' "$SKILL/references/bootstrap.md" \
  || bad "bootstrap.md lacks the Surfaces table or its framework recipes"
grep -qF 'Surfaces table' "$SKILL/SKILL.md" || bad "SKILL.md LOCATE step does not use the Surfaces table"
ok "bootstrap.md generates a Surfaces table; SKILL.md LOCATE skips the grep when it names the files"

# 21. version: this release's checks assume at least 1.5.0 (consistency itself is check 5)
MIN_VERSION=1.5.0
if [ -n "$v_skill" ] && [ "$(printf '%s\n%s\n' "$MIN_VERSION" "$v_skill" | sort -V | head -1)" = "$MIN_VERSION" ]; then
  ok "version $v_skill is at least $MIN_VERSION"
else
  bad "version '$v_skill' is older than $MIN_VERSION, which the capability checks above assume"
fi

# 22. SKILL.md stays lean and lists the new modes; details live in references
lines=$(wc -l < "$SKILL/SKILL.md")
[ "$lines" -le 250 ] && ok "SKILL.md is $lines lines (limit 250)" || bad "SKILL.md is $lines lines — move detail into references (limit 250)"
for m in '/dispatch setup' '/dispatch deps' '/dispatch bootstrap' '/dispatch new' '/dispatch verify' '/dispatch db' '/dispatch status'; do
  grep -qF "| \`$m" "$SKILL/SKILL.md" || bad "SKILL.md mode table has no row for $m"
done
ok "SKILL.md mode table lists bootstrap, setup, new, deps, verify, db, status"

[ $fail -eq 0 ] && { echo "PASS"; exit 0; } || { echo "FAILED"; exit 1; }
