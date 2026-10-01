#!/usr/bin/env node
// dispatch-measure — rendered horizontal overflow, and optionally one computed style, per viewport width.
// Shipped with the dispatch skill; `/dispatch setup` copies it to <repo>/.claude/dispatch/.
// No dependencies of its own: it uses the repo's Playwright — Node from <repo>/node_modules, else
// Python from $DISPATCH_PYTHON or the repo's virtualenv. Never a global install, never the system python.
// Importing this file runs nothing; only `node dispatch-measure.mjs ...` does (see scripts/measure.test.mjs).
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, realpathSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, extname, join, resolve, sep } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

export const USAGE = `Usage (from the repo root):
  node .claude/dispatch/dispatch-measure.mjs <url> <width>... [--select <css selector> --prop <computed property>]
                                                         [--shot <dir>] [--compare <reference image> --shot <dir>] [--a11y]
  node .claude/dispatch/dispatch-measure.mjs --probe     which renderer would be used; exit 0, or 3 with the fix

Examples:
  node .claude/dispatch/dispatch-measure.mjs http://localhost:5173/catalog 320 375 768 1280
  node .claude/dispatch/dispatch-measure.mjs http://localhost:5173/catalog 375 900 --select .grid --prop grid-template-columns
  node .claude/dispatch/dispatch-measure.mjs http://localhost:5173/ 375 --select :root --prop --brand
  node .claude/dispatch/dispatch-measure.mjs http://localhost:5173/catalog 375 1280 --shot .claude/dispatch/shots
  node .claude/dispatch/dispatch-measure.mjs http://localhost:5173/catalog 1440 --compare .claude/dispatch/refs/007/desktop.png

Output — a renderer line, then one line per width, nothing else:
  renderer: node playwright
  375px  overflow: no  .grid { grid-template-columns: 343px }
  320px  overflow: yes, 48px (scrollWidth 368 > clientWidth 320)
Quote the renderer line as the tool you rendered with.
--select/--prop read the first match only; the line says "(first of N)" when there are more.
--prop takes any computed property, custom properties (--brand) included.
For a column count, count the values grid-template-columns prints.

Basic accessibility (a cross-cutting check — not a full audit):
  --a11y              per width: missing lang, img without alt, form controls / buttons / links without an
                      accessible name, skipped heading levels, duplicate ids, text below WCAG AA contrast
                      against its nearest solid background. The line ends "a11y: none found (basic checks)"
                      or "a11y: N — <kind> <count> (<first element>), ...". A repo with axe/pa11y/lighthouse
                      should use that instead; this needs nothing installed.

Screenshots and reference comparison (for work built from an image reference):
  --shot <dir>        full-page PNG per width, <dir>/<page>-<width>.png; the line ends "shot: <path>"
  --compare <image>   exactly one width. The reference (PNG/JPEG/WebP) is scaled to that width (a 2x mock
                      becomes 1x), compared pixel by pixel with the render over their common height, and a
                      composite  reference | render | diff (red = differs)  is written to
                      <dir>/<page>-<width>-compare.png (<dir> = --shot, default .claude/dispatch/shots).
                      The line ends "compare: <N>% differ (<w>x<h>; reference <rw>x<rh>) -> <composite>".
                      Open the composite and read it; the percentage is a trend, not a verdict.

It starts nothing: the dev server must already be running.
Checks run in this order; the first that fails sets the exit code, with one line on stderr:
  1. arguments   -> exit 1  "<the problem> — see --help"; also Node older than 18
  2. dev server  -> exit 2  "dev server not reachable at <url>" (also on HTTP >= 400, a page that fails to
                           load or does not finish in time), or "<url> redirected to <final url>" — measure
                           the final URL, or give the page the session it needs; a redirect is never measured
  3. renderer    -> exit 3  "playwright not installed ..." or "chromium for playwright is not installed ...",
                           each with the fix for its ecosystem
Renderer lookup: $DISPATCH_PYTHON if set (exit 3 if it cannot import playwright); else Node "playwright"
from <current directory>/node_modules only; else Python "playwright" from .venv or venv. A virtualenv
outside the repo (poetry's default) needs DISPATCH_PYTHON.
Exit 0 means measured, not passed: read the lines.
Browsers: if .claude/dispatch/browsers/ exists next to this script and PLAYWRIGHT_BROWSERS_PATH
is unset, it is used (setup installs chromium there so nothing lands outside the repo).`;

const HERE = dirname(fileURLToPath(import.meta.url));
const VALUE_FLAGS = new Set(['--select', '--prop', '--shot', '--compare']);
const DEFAULT_SHOTS = '.claude/dispatch/shots';
const DIFF_THRESHOLD = 0.04; // per-pixel colour distance, 0..1, above which a pixel "differs" (catches #eef3f5 vs #fff)
const COMPOSITE_MAX_W = 2400;
const FLAGS = new Set([...VALUE_FLAGS, '--probe', '--a11y', '--help', '-h']);
const VENV_PYTHONS = ['.venv/bin/python', 'venv/bin/python', '.venv/Scripts/python.exe', 'venv/Scripts/python.exe'];
const LOAD_MS = 30000;
const IDLE_MS = 5000;
const BROWSERS = 'PLAYWRIGHT_BROWSERS_PATH="$PWD/.claude/dispatch/browsers"';

function die(code, msg) {
  console.error(msg);
  process.exit(code);
}

export function parseArgs(argv) {
  const o = { url: null, widths: [], select: null, prop: null, shot: null, compare: null, a11y: false, probe: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '-h' || a === '--help') return { help: true };
    if (a === '--probe') {
      o.probe = true;
    } else if (a === '--a11y') {
      o.a11y = true;
    } else if (VALUE_FLAGS.has(a)) {
      const v = argv[++i];
      // Only one of our own flags counts as "no value": `--prop --brand` reads a custom property.
      if (v === undefined || v === '' || FLAGS.has(v)) return { error: `${a} needs a value` };
      o[a.slice(2)] = v;
    } else if (a.startsWith('-') && a !== '-') {
      return { error: `unknown option ${a}` };
    } else if (o.url === null) {
      o.url = a;
    } else if (/^[1-9]\d{0,4}$/.test(a)) {
      o.widths.push(Number(a));
    } else {
      return { error: `not a width in px: ${a}` };
    }
  }
  if (o.probe) {
    return o.url === null && !o.select && !o.prop && !o.shot && !o.compare && !o.a11y ? { probe: true } : { error: '--probe takes no other arguments' };
  }
  if (o.url === null) return { error: 'missing <url>' };
  try {
    if (!/^https?:$/.test(new URL(o.url).protocol)) throw new Error();
  } catch {
    return { error: `not an http(s) URL: ${o.url}` };
  }
  if (o.widths.length === 0) return { error: 'give at least one width' };
  if (!o.select !== !o.prop) return { error: '--select and --prop go together' };
  if (o.compare) {
    if (o.widths.length !== 1) return { error: '--compare takes exactly one width — the width the reference was drawn at' };
    if (!/\.(png|jpe?g|webp)$/i.test(o.compare)) return { error: `--compare needs a .png, .jpg or .webp image: ${o.compare}` };
    if (!o.shot) o.shot = DEFAULT_SHOTS;
  }
  // getPropertyValue wants kebab-case; accept gridTemplateColumns too. Custom properties are
  // case-sensitive and passed through untouched.
  if (o.prop && !o.prop.startsWith('--')) o.prop = o.prop.replace(/[A-Z]/g, (m) => '-' + m.toLowerCase());
  return o;
}

export function runtimeError(g = globalThis, version = process.version) {
  return typeof g.fetch === 'function' ? null : `needs Node 18+ (this is ${version}) — see --help`;
}

// Runs in the page. Kept self-contained: its source is also handed to Python Playwright.
export function measure([sel, prop]) {
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

export function line(w, r, o) {
  let s = `${w}px  ` + (r.sw > r.cw
    ? `overflow: yes, ${r.sw - r.cw}px (scrollWidth ${r.sw} > clientWidth ${r.cw})`
    : 'overflow: no');
  if (o.select) {
    if (r.error) s += `  ${o.select}: ${r.error}`;
    else if (!r.matches) s += `  ${o.select}: no match`;
    else s += `  ${o.select} { ${o.prop}: ${r.value === '' ? '(empty)' : r.value} }` + (r.matches > 1 ? ` (first of ${r.matches})` : '');
  }
  if (r.a11y) s += '  ' + a11yText(r.a11y);
  if (r.shot) s += `  shot: ${r.shot}`;
  if (r.cmp) {
    const c = r.cmp;
    s += `  compare: ${c.pct.toFixed(1)}% differ (${c.w}x${c.h}; reference ${c.rw}x${c.rh}) -> ${c.file}`;
  }
  return s;
}

export function a11yText(a) {
  const kinds = Object.entries(a).filter(([, v]) => v.n > 0);
  if (!kinds.length) return 'a11y: none found (basic checks)';
  const total = kinds.reduce((s, [, v]) => s + v.n, 0);
  return `a11y: ${total} — ` + kinds.map(([k, v]) => `${k} ${v.n} (${v.first})`).join(', ');
}

// WCAG 2.x contrast ratio of two [r,g,b] colours. Pure, for the unit test; a11yScan carries an
// identical inline copy, because eval inside the page fails on any site whose CSP lacks 'unsafe-eval'.
export function contrastRatio(a, b) {
  const lum = (c) => {
    const [r, g, bl] = c.map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; });
    return 0.2126 * r + 0.7152 * g + 0.0722 * bl;
  };
  const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

// Runs in the page. Fully self-contained: no eval, so a strict Content-Security-Policy cannot break it.
export function a11yScan() {
  const cr = (a, b) => {
    const lum = (c) => {
      const [r, g, bl] = c.map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; });
      return 0.2126 * r + 0.7152 * g + 0.0722 * bl;
    };
    const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x);
    return (hi + 0.05) / (lo + 0.05);
  };
  const out = {};
  const hit = (k, el) => {
    const o = (out[k] = out[k] || { n: 0, first: '' });
    o.n++;
    if (!o.first) o.first = el ? el.tagName.toLowerCase() + (el.id ? '#' + el.id : el.classList[0] ? '.' + el.classList[0] : '') : 'document';
  };
  const visible = (el) => { const s = getComputedStyle(el); return s.display !== 'none' && s.visibility !== 'hidden' && el.getClientRects().length > 0; };
  const named = (el) => {
    if ((el.getAttribute('aria-label') || '').trim() || (el.getAttribute('title') || '').trim()) return true;
    const lb = el.getAttribute('aria-labelledby');
    if (lb && lb.split(/\s+/).some((id) => (document.getElementById(id)?.textContent || '').trim())) return true;
    return false;
  };
  if (!(document.documentElement.getAttribute('lang') || '').trim()) hit('lang', null);
  document.querySelectorAll('img').forEach((el) => { if (!el.hasAttribute('alt') && visible(el)) hit('img-alt', el); });
  document.querySelectorAll('input, select, textarea').forEach((el) => {
    if (['hidden', 'submit', 'button', 'reset', 'image'].includes((el.type || '').toLowerCase()) || !visible(el)) return;
    const lab = (el.id && document.querySelector(`label[for="${CSS.escape(el.id)}"]`)) || el.closest('label');
    if (!(lab && lab.textContent.trim()) && !named(el) && !(el.getAttribute('placeholder') || '').trim()) hit('control-name', el);
  });
  document.querySelectorAll('button, a[href], [role="button"]').forEach((el) => {
    if (!visible(el)) return;
    const text = (el.textContent || '').trim() || [...el.querySelectorAll('img[alt]')].map((i) => i.alt.trim()).join('');
    if (!text && !named(el)) hit(el.tagName === 'A' ? 'link-name' : 'button-name', el);
  });
  let last = 0;
  document.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach((el) => {
    if (!visible(el)) return;
    const lv = Number(el.tagName[1]);
    if (last && lv > last + 1) hit('heading-skip', el);
    last = lv;
  });
  const seen = new Set();
  document.querySelectorAll('[id]').forEach((el) => { if (seen.has(el.id)) hit('duplicate-id', el); seen.add(el.id); });
  const rgb = (s) => { const m = s.match(/rgba?\(([^)]+)\)/); if (!m) return null; const p = m[1].split(/[ ,/]+/).filter(Boolean).map(Number); return { c: p.slice(0, 3), a: p.length > 3 ? p[3] : 1 }; };
  const bgOf = (el) => {
    for (let e = el; e; e = e.parentElement) {
      const s = getComputedStyle(e);
      if (s.backgroundImage && s.backgroundImage !== 'none') return null; // over an image: cannot judge
      const b = rgb(s.backgroundColor);
      if (b && b.a >= 0.99) return b.c;
    }
    return [255, 255, 255];
  };
  const walker = document.createTreeWalker(document.body || document.documentElement, NodeFilter.SHOW_TEXT);
  const done = new Set();
  for (let n = walker.nextNode(); n; n = walker.nextNode()) {
    const el = n.parentElement;
    if (!el || done.has(el) || !n.textContent.trim() || !visible(el)) continue;
    done.add(el);
    const s = getComputedStyle(el);
    const fg = rgb(s.color), bg = bgOf(el);
    if (!fg || !bg || fg.a < 0.99) continue;
    const size = parseFloat(s.fontSize), bold = Number(s.fontWeight) >= 700;
    const need = size >= 24 || (bold && size >= 18.66) ? 3 : 4.5;
    if (cr(fg.c, bg) < need) hit('contrast', el);
  }
  return out;
}

// <page>-<width>.png — the page part from the URL path, filesystem-safe.
export function shotName(url, w, suffix = '') {
  const path = new URL(url).pathname.replace(/\/+$/, '').replace(/\.(html?|php)$/i, '');
  const page = (path.split('/').filter(Boolean).join('-') || 'home').replace(/[^A-Za-z0-9._-]+/g, '_').slice(0, 60);
  return `${page}-${w}${suffix}.png`;
}

export function dataUrl(file, read = readFileSync) {
  const ext = extname(file).toLowerCase();
  const type = ext === '.png' ? 'image/png' : ext === '.webp' ? 'image/webp' : 'image/jpeg';
  return `data:${type};base64,${read(file).toString('base64')}`;
}

// Pixel comparison of two same-sized RGBA buffers. Pure, so the unit test runs it; its source is
// also evaluated inside the browser page that draws the composite. Returns the count of differing
// pixels and an RGBA diff image: a faded copy of the render, red wherever the two differ.
export function pixelDiff(a, b, w, h, threshold) {
  const out = new Uint8ClampedArray(w * h * 4);
  const max = Math.sqrt(3 * 255 * 255);
  let diff = 0;
  for (let i = 0; i < w * h * 4; i += 4) {
    const dr = a[i] - b[i], dg = a[i + 1] - b[i + 1], db = a[i + 2] - b[i + 2];
    if (Math.sqrt(dr * dr + dg * dg + db * db) / max > threshold) {
      diff++;
      out[i] = 255; out[i + 1] = 0; out[i + 2] = 0; out[i + 3] = 255;
    } else {
      const g = 255 - (255 - (b[i] * 0.3 + b[i + 1] * 0.59 + b[i + 2] * 0.11)) * 0.25;
      out[i] = g; out[i + 1] = g; out[i + 2] = g; out[i + 3] = 255;
    }
  }
  return { diff, total: w * h, out };
}

// Runs in a blank page (no site CSP). Self-contained: its source is also handed to Python Playwright.
export async function compareInPage([refUrl, shotUrl, width, diffSrc, threshold, maxW]) {
  const pd = (0, eval)('(' + diffSrc + ')');
  const load = (src) => new Promise((ok, no) => { const i = new Image(); i.onload = () => ok(i); i.onerror = () => no(new Error('cannot decode image')); i.src = src; });
  const [ref, shot] = await Promise.all([load(refUrl), load(shotUrl)]);
  const rh = Math.round(ref.naturalHeight * width / ref.naturalWidth);
  const w = Math.min(width, shot.naturalWidth), h = Math.min(rh, shot.naturalHeight);
  const pixels = (img, dw, dh) => {
    const c = document.createElement('canvas'); c.width = w; c.height = h;
    const x = c.getContext('2d'); x.fillStyle = '#fff'; x.fillRect(0, 0, w, h); x.drawImage(img, 0, 0, dw, dh);
    return { c, data: x.getImageData(0, 0, w, h).data };
  };
  const A = pixels(ref, width, rh), B = pixels(shot, shot.naturalWidth, shot.naturalHeight);
  const r = pd(A.data, B.data, w, h, threshold);
  const D = document.createElement('canvas'); D.width = w; D.height = h;
  D.getContext('2d').putImageData(new ImageData(r.out, w, h), 0, 0);
  const gap = 16, head = 28, scale = Math.min(1, maxW / (3 * w + 2 * gap));
  const C = document.createElement('canvas');
  C.width = Math.round((3 * w + 2 * gap) * scale); C.height = Math.round((h + head) * scale);
  const x = C.getContext('2d'); x.scale(scale, scale);
  x.fillStyle = '#fff'; x.fillRect(0, 0, 3 * w + 2 * gap, h + head);
  x.fillStyle = '#111'; x.font = '16px sans-serif';
  [['reference', A.c], ['render', B.c], ['diff (red = differs)', D]].forEach(([label, cv], k) => {
    x.fillText(label, k * (w + gap) + 4, 19); x.drawImage(cv, k * (w + gap), head);
  });
  return { pct: 100 * r.diff / r.total, w, h, rw: ref.naturalWidth, rh: ref.naturalHeight, png: C.toDataURL('image/png') };
}

function writePng(file, b64) {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, Buffer.from(b64.replace(/^data:image\/png;base64,/, ''), 'base64'));
}

// A redirect means another page was measured. Returns the final URL when it differs, else null.
export function redirectedTo(requested, final) {
  if (!final) return null;
  return new URL(requested).href === final ? null : final;
}

// Node Playwright from <root>/node_modules only. createRequire alone would also follow NODE_PATH
// and global folders — a machine-wide install the probes in status.md/setup.md would call missing.
export function repoPlaywrightPath(root = process.cwd()) {
  const dir = join(root, 'node_modules', 'playwright');
  if (!existsSync(join(dir, 'package.json'))) return null;
  try {
    const p = createRequire(join(root, 'package.json')).resolve('playwright', { paths: [root] });
    return p.startsWith(realpathSync(dir) + sep) ? p : null; // symlinked (pnpm) is fine; anything else is not
  } catch {
    return null;
  }
}

async function loadNodePlaywright(root) {
  const p = repoPlaywrightPath(root);
  if (!p) return null;
  try {
    const m = await import(pathToFileURL(p).href);
    return m && m.chromium ? m : m && m.default && m.default.chromium ? m.default : null;
  } catch {
    return null;
  }
}

function pyCanImport(py) {
  return spawnSync(py, ['-c', 'import playwright'], { stdio: 'ignore', timeout: 30000 }).status === 0;
}

// Which Python to use. `has`/`canImport` are injectable for the unit test.
export function findPython(env = process.env, root = process.cwd(), has = existsSync, canImport = pyCanImport) {
  if (env.DISPATCH_PYTHON) {
    const py = env.DISPATCH_PYTHON;
    return canImport(py)
      ? { py }
      : { error: `DISPATCH_PYTHON=${py} cannot run "import playwright" — fix the path, or unset it to search .venv and venv` };
  }
  for (const rel of VENV_PYTHONS) {
    const py = join(root, rel);
    if (has(py) && canImport(py)) return { py };
  }
  return { py: null };
}

export function chromiumFix(kind, py) {
  return 'chromium for playwright is not installed (or cannot start here) — run: ' +
    (kind === 'node' ? `${BROWSERS} npx playwright install chromium` : `${BROWSERS} "${py}" -m playwright install chromium`);
}

export function missingMessage(root = process.cwd(), has = existsSync) {
  const node = has(join(root, 'package.json'));
  const python = ['pyproject.toml', 'requirements.txt', 'setup.py', 'Pipfile'].some((f) => has(join(root, f)));
  const what = node && !python ? 'a dev-only `playwright` in package.json'
    : python && !node ? '`playwright` in the project virtualenv (dev group)'
    : 'a dev-only, repo-local playwright';
  return 'playwright not installed — no Node "playwright" in ./node_modules and no Python "playwright" in ' +
    `$DISPATCH_PYTHON, .venv or venv. Fix: /dispatch setup (it proposes ${what}, chromium in ` +
    '.claude/dispatch/browsers/). Until then report every width as Not verified.';
}

export async function findRenderer({ env = process.env, root = process.cwd(), loadNode = loadNodePlaywright, pickPython = findPython } = {}) {
  if (env.DISPATCH_PYTHON) {
    const p = pickPython(env, root);
    return p.error ? { error: p.error } : { kind: 'python', py: p.py, label: `python ${p.py}` };
  }
  const pw = await loadNode(root);
  if (pw) return { kind: 'node', pw, label: 'node playwright' };
  const p = pickPython(env, root);
  if (p.py) return { kind: 'python', py: p.py, label: `python ${p.py}` };
  return { error: missingMessage(root) };
}

async function renderNode(pw, o) {
  let browser;
  try {
    browser = await pw.chromium.launch();
  } catch (e) {
    die(3, chromiumFix('node'));
  }
  const out = [];
  let loadError = null;
  try {
    if (o.probe) return out;
    const page = await browser.newPage();
    for (const w of o.widths) {
      await page.setViewportSize({ width: w, height: 900 });
      try {
        await page.goto(o.url, { waitUntil: 'load', timeout: LOAD_MS });
      } catch (e) {
        loadError = String(e.message || e).split('\n')[0];
        break;
      }
      await page.waitForLoadState('networkidle', { timeout: IDLE_MS }).catch(() => {});
      const r = await page.evaluate(measure, [o.select, o.prop]);
      if (o.a11y) r.a11y = await page.evaluate(a11yScan);
      if (o.shot) {
        const png = await page.screenshot({ fullPage: true });
        r.shot = join(o.shot, shotName(o.url, w));
        writePng(r.shot, png.toString('base64'));
        if (o.compare) {
          const cmpPage = await browser.newPage();
          const c = await cmpPage.evaluate(compareInPage, [o.refUrl, 'data:image/png;base64,' + png.toString('base64'), w, pixelDiff.toString(), DIFF_THRESHOLD, COMPOSITE_MAX_W]);
          await cmpPage.close();
          c.file = join(o.shot, shotName(o.url, w, '-compare'));
          writePng(c.file, c.png);
          delete c.png;
          r.cmp = c;
        }
      }
      out.push([w, r, page.url()]);
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
import base64, os
url, sel, prop, fn, extra = sys.argv[1:6]
extra = json.loads(extra)
widths = [int(w) for w in sys.argv[6:]]
def write_png(path, b64):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "wb") as f:
        f.write(base64.b64decode(b64.split(",", 1)[-1]))
with sync_playwright() as p:
    try:
        b = p.chromium.launch()
    except Exception:
        print("NOCHROMIUM")
        sys.exit(3)
    if not url:
        b.close()
        print("PROBEOK")
        sys.exit(0)
    pg = b.new_page()
    for w in widths:
        pg.set_viewport_size({"width": w, "height": 900})
        try:
            pg.goto(url, wait_until="load", timeout=${LOAD_MS})
        except Exception as e:
            print("NOLOAD " + (str(e).splitlines() or [""])[0])
            b.close()
            sys.exit(2)
        try:
            pg.wait_for_load_state("networkidle", timeout=${IDLE_MS})
        except Exception:
            pass
        r = pg.evaluate(fn, [sel or None, prop or None])
        if extra.get("a11yfn"):
            r["a11y"] = pg.evaluate(extra["a11yfn"])
        if extra.get("shot"):
            png = pg.screenshot(full_page=True)
            r["shot"] = os.path.join(extra["shot"], extra["names"][str(w)])
            write_png(r["shot"], base64.b64encode(png).decode())
            if extra.get("refpath"):
                cp = b.new_page()
                with open(extra["refpath"], "rb") as f:
                    ref = "data:" + extra["refmime"] + ";base64," + base64.b64encode(f.read()).decode()
                c = cp.evaluate(extra["cmpfn"], [ref, "data:image/png;base64," + base64.b64encode(png).decode(), w, extra["difffn"], extra["threshold"], extra["maxw"]])
                cp.close()
                c["file"] = os.path.join(extra["shot"], extra["cmpname"])
                write_png(c["file"], c.pop("png"))
                r["cmp"] = c
        print(json.dumps([w, r, pg.url]))
    b.close()
`;

export function pythonTimeoutMs(widths) {
  return 30000 + (LOAD_MS + IDLE_MS + 10000) * Math.max(1, widths);
}

// Turns a spawnSync result into { results } or { code, msg }. Pure: the unit test feeds it.
export function readPython(r, py, url) {
  if (r.error && r.error.code === 'ETIMEDOUT') {
    return { code: 2, msg: `dev server not reachable at ${url} — the page did not finish within the time limit (slow or hung page, or chromium hung); nothing was measured` };
  }
  if (r.error) return { code: 3, msg: `python playwright could not start (${py}): ${r.error.message}` };
  const lines = (r.stdout || '').split('\n').filter(Boolean);
  if (lines.includes('NOCHROMIUM')) return { code: 3, msg: chromiumFix('python', py) };
  const noload = lines.find((l) => l.startsWith('NOLOAD'));
  if (noload) return { code: 2, msg: `dev server not reachable at ${url} — page did not load: ${noload.slice(7)}` };
  if (r.status !== 0) return { code: 3, msg: `python playwright failed (${py}): ${(r.stderr || '').trim().split('\n').pop()}` };
  return { results: lines.filter((l) => l !== 'PROBEOK').map((l) => JSON.parse(l)) };
}

function renderPython(py, o) {
  const extra = !o.shot ? {} : {
    shot: o.shot,
    names: Object.fromEntries(o.widths.map((w) => [String(w), shotName(o.url, w)])),
    ...(o.compare ? {
      // the path, not the bytes: one argv entry is capped at 128 KB on Linux (E2BIG), and a mock is bigger
      refpath: resolve(o.compare), refmime: dataUrl(o.compare, () => Buffer.alloc(0)).slice(5, -8), cmpname: shotName(o.url, o.widths[0], '-compare'), cmpfn: compareInPage.toString(),
      difffn: pixelDiff.toString(), threshold: DIFF_THRESHOLD, maxw: COMPOSITE_MAX_W,
    } : {}),
  };
  if (o.a11y) Object.assign(extra, { a11yfn: a11yScan.toString() });
  const args = ['-c', PY, o.probe ? '' : o.url, o.select || '', o.prop || '', measure.toString(), JSON.stringify(extra), ...o.widths.map(String)];
  const r = spawnSync(py, args, { encoding: 'utf8', timeout: pythonTimeoutMs(o.widths.length) });
  const x = readPython(r, py, o.url);
  if (x.code) die(x.code, x.msg);
  return x.results;
}

async function main(argv) {
  const o = parseArgs(argv);
  if (o.help) {
    console.log(USAGE);
    process.exit(0);
  }
  if (o.error) die(1, `dispatch-measure: ${o.error} — see --help`);
  const rt = runtimeError();
  if (rt) die(1, `dispatch-measure: ${rt}`);
  if (o.probe) o.widths = [];
  if (o.compare) {
    if (!existsSync(o.compare)) die(1, `dispatch-measure: reference image not found: ${o.compare} — see --help`);
    o.refUrl = dataUrl(o.compare);
  }

  // 2. dev server — this script never starts one. A 3xx is a different page: refuse it here, and
  //    compare the final URL after rendering for client-side redirects.
  if (!o.probe) {
    let res;
    try {
      res = await fetch(o.url, { redirect: 'manual', signal: AbortSignal.timeout(5000) });
    } catch {
      die(2, `dev server not reachable at ${o.url}`);
    }
    if (res.status >= 400) die(2, `dev server not reachable at ${o.url} — it answered HTTP ${res.status}; measuring an error page proves nothing`);
    if (res.status >= 300) {
      const to = res.headers.get('location');
      die(2, `${o.url} redirected to ${to ? new URL(to, o.url).href : '(no Location)'} (HTTP ${res.status}) — measure the final URL, or give the page the session it needs`);
    }
  }

  // 3. renderer
  if (!process.env.PLAYWRIGHT_BROWSERS_PATH && existsSync(join(HERE, 'browsers'))) {
    process.env.PLAYWRIGHT_BROWSERS_PATH = join(HERE, 'browsers');
  }
  const rd = await findRenderer();
  if (rd.error) die(3, rd.error);
  const results = rd.kind === 'node' ? await renderNode(rd.pw, o) : renderPython(rd.py, o);
  for (const [, , final] of results) {
    const to = redirectedTo(o.url, final);
    if (to) die(2, `${o.url} redirected to ${to} — measure the final URL, or give the page the session it needs`);
  }
  console.log(`renderer: ${rd.label}`);
  for (const [w, r] of results) console.log(line(w, r, o));
}

const invoked = (() => {
  try {
    return realpathSync(resolve(process.argv[1] || '')) === realpathSync(fileURLToPath(import.meta.url));
  } catch {
    return false;
  }
})();
if (invoked) await main(process.argv.slice(2));
