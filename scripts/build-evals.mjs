#!/usr/bin/env node
// Builds evals/evals.json (the skill-creator eval format) from the scenario files in evals/*.md,
// so the same scenarios can be run by a harness instead of only by hand.
//   node scripts/build-evals.mjs           write evals/evals.json
//   node scripts/build-evals.mjs --check   exit 1 if evals/evals.json is missing or out of date
// Each scenario's "## Prompt" becomes `prompt`, "## Setup" becomes `setup` (the repo state the
// runner must prepare), and every "- [ ]" line under "## Expected behaviour" becomes one entry of
// `expectations` — what a grader checks the transcript against.
import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const DIR = join(ROOT, 'evals');
const OUT = join(DIR, 'evals.json');

export function section(md, name) {
  const lines = md.split('\n');
  const i = lines.findIndex((l) => l.trim() === `## ${name}`);
  if (i < 0) return '';
  const out = [];
  for (const l of lines.slice(i + 1)) {
    if (/^## /.test(l)) break;
    out.push(l);
  }
  return out.join('\n').trim();
}

export function expectations(block) {
  const items = [];
  for (const l of block.split('\n')) {
    const m = l.match(/^- \[[ x]\] (.*)$/);
    if (m) items.push(m[1].trim());
    else if (items.length && /^\s+\S/.test(l)) items[items.length - 1] += ' ' + l.trim();
  }
  return items;
}

// The user's words. A prompt written as one code span may nest backticks inside it
// ("`/dispatch add a `status` field`"), so a section that starts with "`/" and ends with "`"
// loses only those two; otherwise ("`a`, then `b`") every code-span fence is removed.
export function promptText(s) {
  const one = s.trim();
  if (/^`\//.test(one) && one.endsWith('`') && !/`\s*,?\s*(then|and)\b/.test(one)) return one.slice(1, -1);
  return one.replace(/`([^`]*)`/g, '$1').replace(/\s*\n\s*/g, ' ');
}

export function build(dir = DIR) {
  const files = readdirSync(dir).filter((f) => f.endsWith('.md') && f !== 'README.md').sort();
  const evals = files.map((f, i) => {
    const md = readFileSync(join(dir, f), 'utf8');
    const title = (md.match(/^# (.*)$/m) || [, f])[1].trim();
    return {
      id: i + 1,
      name: f.replace(/\.md$/, ''),
      prompt: promptText(section(md, 'Prompt')),
      setup: section(md, 'Setup'),
      expected_output: title,
      files: [],
      expectations: expectations(section(md, 'Expected behaviour')),
    };
  });
  return JSON.stringify({ skill_name: 'dispatch', evals }, null, 2) + '\n';
}

const invoked = process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1];
if (invoked) {
  const json = build();
  if (process.argv.includes('--check')) {
    if (!existsSync(OUT) || readFileSync(OUT, 'utf8') !== json) {
      console.error('evals/evals.json is out of date — run: node scripts/build-evals.mjs');
      process.exit(1);
    }
    console.log(`evals/evals.json up to date (${JSON.parse(json).evals.length} evals)`);
  } else {
    writeFileSync(OUT, json);
    console.log(`wrote evals/evals.json (${JSON.parse(json).evals.length} evals)`);
  }
}
