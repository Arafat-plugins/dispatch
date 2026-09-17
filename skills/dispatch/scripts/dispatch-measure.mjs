#!/usr/bin/env node
// dispatch-measure — rendered horizontal overflow, and optionally one computed style, per viewport width.
// Shipped with the dispatch skill; `/dispatch setup` copies it to <repo>/.claude/dispatch/.
// No dependencies of its own: it uses the repo's Playwright (Node first, then Python).
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const USAGE = `Usage (from the repo root):
  node .claude/dispatch/dispatch-measure.mjs <url> <width>... [--select <css selector> --prop <computed property>]

Examples:
  node .claude/dispatch/dispatch-measure.mjs http://127.0.0.1:5173/catalog 320 375 768 1280
  node .claude/dispatch/dispatch-measure.mjs http://127.0.0.1:5173/catalog 375 900 --select .grid --prop grid-template-columns

Output — one line per width, nothing else:
  375px  overflow: no  .grid { grid-template-columns: 343px }
  320px  overflow: yes, 48px (scrollWidth 368 > clientWidth 320)
--select/--prop read the first match only; the line says "(first of N)" when there are more.
For a column count, count the values grid-template-columns prints.

It starts nothing: the dev server must already be running.
Checks run in this order; the first that fails sets the exit code:
  1. arguments   -> exit 1  this usage text
  2. dev server  -> exit 2  "dev server not reachable at <url>" (also on HTTP >= 400, or a page that fails to load)
  3. renderer    -> exit 3  "playwright not installed ..." or "chromium for playwright is not installed ..."
                           Node "playwright" is resolved from this script's directory, then the
                           current directory; else Python "playwright" from $DISPATCH_PYTHON,
                           .venv, venv, python3, python.
Exit 0 means measured, not passed: read the lines.
Browsers: if .claude/dispatch/browsers/ exists next to this script and PLAYWRIGHT_BROWSERS_PATH
is unset, it is used (setup installs chromium there so nothing lands outside the repo).`;

const HERE = dirname(fileURLToPath(import.meta.url));

function die(code, msg) {
  console.error(msg);
  process.exit(code);
}

function parseArgs(argv) {
  const o = { url: null, widths: [], select: null, prop: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '-h' || a === '--help') return { help: true };
    if (a === '--select' || a === '--prop') {
      const v = argv[++i];
      if (v === undefined || v === '' || v.startsWith('--')) return { error: `${a} needs a value` };
      o[a.slice(2)] = v;
    } else if (a.startsWith('--')) {
      return { error: `unknown option ${a}` };
    } else if (o.url === null) {
      o.url = a;
    } else if (/^[1-9]\d{0,4}$/.test(a)) {
      o.widths.push(Number(a));
    } else {
      return { error: `not a width in px: ${a}` };
    }
  }
  if (o.url === null) return { error: 'missing <url>' };
  try {
    if (!/^https?:$/.test(new URL(o.url).protocol)) throw new Error();
  } catch {
    return { error: `not an http(s) URL: ${o.url}` };
  }
  if (o.widths.length === 0) return { error: 'give at least one width' };
  if (!o.select !== !o.prop) return { error: '--select and --prop go together' };
  // getPropertyValue wants kebab-case; accept gridTemplateColumns too.
  if (o.prop) o.prop = o.prop.replace(/[A-Z]/g, (m) => '-' + m.toLowerCase());
  return o;
}

// Runs in the page. Kept self-contained: its source is also handed to Python Playwright.
function measure([sel, prop]) {
  const d = document.documentElement;
  const r = { sw: d.scrollWidth, cw: d.clientWidth };
  if (sel) {
    try {
      const els = document.querySelectorAll(sel);
      r.matches = els.length;
      if (els.length) r.value = getComputedStyle(els[0]).getPropertyValue(prop).trim();
    } catch (e) {
      r.error = 'invalid selector';
    }
  }
  return r;
}

function line(w, r, o) {
  let s = `${w}px  ` + (r.sw > r.cw
    ? `overflow: yes, ${r.sw - r.cw}px (scrollWidth ${r.sw} > clientWidth ${r.cw})`
    : 'overflow: no');
  if (o.select) {
    if (r.error) s += `  ${o.select}: ${r.error}`;
    else if (!r.matches) s += `  ${o.select}: no match`;
    else s += `  ${o.select} { ${o.prop}: ${r.value === '' ? '(empty)' : r.value} }` + (r.matches > 1 ? ` (first of ${r.matches})` : '');
  }
  return s;
}

async function loadNodePlaywright() {
  const pick = (m) => (m && m.chromium ? m : m && m.default && m.default.chromium ? m.default : null);
  try {
    return pick(await import('playwright'));
  } catch {}
  try {
    const p = createRequire(join(process.cwd(), 'noop.js')).resolve('playwright');
    return pick(await import(pathToFileURL(p).href));
  } catch {}
  return null;
}

async function renderNode(pw, o) {
  let browser;
  try {
    browser = await pw.chromium.launch();
  } catch (e) {
    die(3, 'chromium for playwright is not installed (or cannot start here) — run: ' +
      'PLAYWRIGHT_BROWSERS_PATH="$PWD/.claude/dispatch/browsers" npx playwright install chromium');
  }
  const out = [];
  let loadError = null;
  try {
    const page = await browser.newPage();
    for (const w of o.widths) {
      await page.setViewportSize({ width: w, height: 900 });
      try {
        await page.goto(o.url, { waitUntil: 'load', timeout: 30000 });
      } catch (e) {
        loadError = String(e.message || e).split('\n')[0];
        break;
      }
      await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {});
      out.push([w, await page.evaluate(measure, [o.select, o.prop])]);
    }
  } finally {
    await browser.close();
  }
  if (loadError) die(2, `dev server not reachable at ${o.url} — page did not load: ${loadError}`);
  return out;
}

const PY = `
import json, sys
from playwright.sync_api import sync_playwright
url, sel, prop, fn = sys.argv[1:5]
widths = [int(w) for w in sys.argv[5:]]
with sync_playwright() as p:
    try:
        b = p.chromium.launch()
    except Exception:
        print("NOCHROMIUM")
        sys.exit(3)
    pg = b.new_page()
    for w in widths:
        pg.set_viewport_size({"width": w, "height": 900})
        try:
            pg.goto(url, wait_until="load", timeout=30000)
        except Exception as e:
            print("NOLOAD " + (str(e).splitlines() or [""])[0])
            b.close()
            sys.exit(2)
        try:
            pg.wait_for_load_state("networkidle", timeout=5000)
        except Exception:
            pass
        print(json.dumps([w, pg.evaluate(fn, [sel or None, prop or None])]))
    b.close()
`;

function findPython() {
  const c = [process.env.DISPATCH_PYTHON, '.venv/bin/python', 'venv/bin/python',
    '.venv/Scripts/python.exe', 'venv/Scripts/python.exe', 'python3', 'python'];
  for (const py of c) {
    if (!py) continue;
    if (py.includes('/') && !existsSync(py)) continue;
    const r = spawnSync(py, ['-c', 'import playwright'], { stdio: 'ignore' });
    if (r.status === 0) return py;
  }
  return null;
}

function renderPython(py, o) {
  const r = spawnSync(py, ['-c', PY, o.url, o.select || '', o.prop || '', measure.toString(), ...o.widths.map(String)],
    { encoding: 'utf8', timeout: 60000 * o.widths.length });
  const lines = (r.stdout || '').split('\n').filter(Boolean);
  if (lines.includes('NOCHROMIUM')) {
    die(3, 'chromium for playwright is not installed (or cannot start here) — run: ' +
      `PLAYWRIGHT_BROWSERS_PATH="$PWD/.claude/dispatch/browsers" ${py.includes('/') ? dirname(py) + '/' : ''}playwright install chromium`);
  }
  const noload = lines.find((l) => l.startsWith('NOLOAD'));
  if (noload) die(2, `dev server not reachable at ${o.url} — page did not load: ${noload.slice(7)}`);
  if (r.status !== 0) die(3, `python playwright failed (${py}): ${(r.stderr || '').trim().split('\n').pop()}`);
  return lines.map((l) => JSON.parse(l));
}

const o = parseArgs(process.argv.slice(2));
if (o.help) {
  console.log(USAGE);
  process.exit(0);
}
if (o.error) die(1, `dispatch-measure: ${o.error}\n\n${USAGE}`);

// 2. dev server — any response below 400 counts as up (redirects included); this script never starts one.
let status = 0;
try {
  status = (await fetch(o.url, { redirect: 'manual', signal: AbortSignal.timeout(5000) })).status;
} catch {
  die(2, `dev server not reachable at ${o.url}`);
}
if (status >= 400) die(2, `dev server not reachable at ${o.url} — it answered HTTP ${status}; measuring an error page proves nothing`);

// 3. renderer
if (!process.env.PLAYWRIGHT_BROWSERS_PATH && existsSync(join(HERE, 'browsers'))) {
  process.env.PLAYWRIGHT_BROWSERS_PATH = join(HERE, 'browsers');
}
const pw = await loadNodePlaywright();
let results;
if (pw) {
  results = await renderNode(pw, o);
} else {
  const py = findPython();
  if (!py) {
    die(3, 'playwright not installed — neither Node "playwright" nor Python "playwright" is available to this repo. ' +
      'Run /dispatch setup (it proposes a dev-only, repo-local install), or report every width as Not verified.');
  }
  results = renderPython(py, o);
}
for (const [w, r] of results) console.log(line(w, r, o));
