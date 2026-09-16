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
for f in SKILL.md references/prompt-spec.md references/verifier.md references/db-check.md; do
  grep -qF "$FOOTER" "$SKILL/$f" || bad "$f: verbatim footer line missing"
done
# no near-miss paraphrases anywhere in the skill
if grep -rnE '\[ *task list' "$SKILL" | grep -vF "$FOOTER" | grep -q .; then
  bad "a paraphrased footer exists:"; grep -rnE '\[ *task list' "$SKILL" | grep -vF "$FOOTER"
fi
ok "verbatim footer present in SKILL.md, prompt-spec.md, verifier.md, db-check.md; no paraphrases"

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

[ $fail -eq 0 ] && { echo "PASS"; exit 0; } || { echo "FAILED"; exit 1; }
