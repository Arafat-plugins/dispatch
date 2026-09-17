// Unit tests for skills/dispatch/scripts/dispatch-measure.mjs — no Playwright, no network.
// Run: node --test scripts/measure.test.mjs   (validate.sh runs it when node is present)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import * as m from '../skills/dispatch/scripts/dispatch-measure.mjs';

const SCRIPT = join(dirname(fileURLToPath(import.meta.url)), '..', 'skills', 'dispatch', 'scripts', 'dispatch-measure.mjs');
const U = 'http://localhost:5173/';
const run = (args, opts = {}) => spawnSync(process.execPath, [...(opts.flags || []), SCRIPT, ...args], { encoding: 'utf8', env: { ...process.env, ...(opts.env || {}) } });

test('--prop --brand is accepted: a CSS custom property is a value, not a flag', () => {
  const o = m.parseArgs([U, '375', '--select', ':root', '--prop', '--brand']);
  assert.equal(o.error, undefined);
  assert.equal(o.prop, '--brand');
  assert.equal(m.parseArgs([U, '375', '--select', ':root', '--prop', '--Brand-Ink']).prop, '--Brand-Ink');
});

test('a known flag after --select/--prop is a missing value', () => {
  assert.equal(m.parseArgs([U, '375', '--prop', '--select', '.g']).error, '--prop needs a value');
  assert.equal(m.parseArgs([U, '375', '--select', '--prop', 'x']).error, '--select needs a value');
  assert.equal(m.parseArgs([U, '375', '--select', '.g', '--prop']).error, '--prop needs a value');
  assert.equal(m.parseArgs([U, '375', '--select', '.g', '--prop', '--help']).error, '--prop needs a value');
});

test('argument parsing: widths, urls, pairing, camelCase, probe', () => {
  const o = m.parseArgs([U, '320', '375', '--select', '.grid', '--prop', 'gridTemplateColumns']);
  assert.deepEqual(o.widths, [320, 375]);
  assert.equal(o.prop, 'grid-template-columns');
  assert.equal(m.parseArgs([U]).error, 'give at least one width');
  assert.equal(m.parseArgs(['ftp://x/', '375']).error, 'not an http(s) URL: ftp://x/');
  assert.equal(m.parseArgs([U, 'wide']).error, 'not a width in px: wide');
  assert.equal(m.parseArgs([U, '375', '--select', '.g']).error, '--select and --prop go together');
  assert.equal(m.parseArgs([U, '375', '--frobnicate']).error, 'unknown option --frobnicate');
  assert.equal(m.parseArgs([]).error, 'missing <url>');
  assert.deepEqual(m.parseArgs(['--probe']), { probe: true });
  assert.ok(m.parseArgs(['--probe', U]).error);
  assert.deepEqual(m.parseArgs([U, '375', '-h']), { help: true });
});

test('Node without fetch is exit-1 material, not "dev server not reachable"', () => {
  assert.match(m.runtimeError({}, 'v16.20.0'), /needs Node 18\+ \(this is v16\.20\.0\)/);
  assert.equal(m.runtimeError({ fetch() {} }), null);
});

test('output lines', () => {
  assert.equal(m.line(375, { sw: 375, cw: 375 }, {}), '375px  overflow: no');
  assert.equal(m.line(320, { sw: 368, cw: 320 }, {}), '320px  overflow: yes, 48px (scrollWidth 368 > clientWidth 320)');
  const o = { select: ':root', prop: '--brand' };
  assert.equal(m.line(375, { sw: 1, cw: 1, matches: 1, value: '#0a7f5a' }, o), '375px  overflow: no  :root { --brand: #0a7f5a }');
  assert.equal(m.line(375, { sw: 1, cw: 1, matches: 0 }, o), '375px  overflow: no  :root: no match');
  assert.match(m.line(375, { sw: 1, cw: 1, matches: 3, value: '' }, o), /\{ --brand: \(empty\) \} \(first of 3\)$/);
});

test('redirects are detected by comparing the final URL', () => {
  assert.equal(m.redirectedTo('http://localhost:5173', 'http://localhost:5173/'), null);
  assert.equal(m.redirectedTo('http://localhost:5173/a', 'http://localhost:5173/login'), 'http://localhost:5173/login');
});

test('python: a timeout is exit 2 (slow page), not exit 3', () => {
  const r = spawnSync(process.execPath, ['-e', 'setTimeout(() => {}, 5000)'], { timeout: 100, encoding: 'utf8' });
  assert.equal(r.error && r.error.code, 'ETIMEDOUT');
  const x = m.readPython(r, '/repo/.venv/bin/python', U);
  assert.equal(x.code, 2);
  assert.match(x.msg, /^dev server not reachable at .* did not finish/);
});

test('python: chromium fix names the interpreter with -m; other outcomes', () => {
  const py = '/repo/.venv/bin/python';
  const nc = m.readPython({ status: 3, stdout: 'NOCHROMIUM\n', stderr: '' }, py, U);
  assert.equal(nc.code, 3);
  assert.ok(nc.msg.endsWith(`"${py}" -m playwright install chromium`), nc.msg);
  assert.equal(m.readPython({ status: 2, stdout: 'NOLOAD net::ERR\n' }, py, U).code, 2);
  assert.equal(m.readPython({ status: 1, stdout: '', stderr: 'Traceback\nImportError: x' }, py, U).code, 3);
  assert.equal(m.readPython({ status: null, error: Object.assign(new Error('spawn x ENOENT'), { code: 'ENOENT' }) }, py, U).code, 3);
  const ok = m.readPython({ status: 0, stdout: `[375, {"sw": 375, "cw": 375}, "${U}"]\n` }, py, U);
  assert.deepEqual(ok.results, [[375, { sw: 375, cw: 375 }, U]]);
  assert.deepEqual(m.readPython({ status: 0, stdout: 'PROBEOK\n' }, py, U).results, []);
  assert.match(m.chromiumFix('node'), /npx playwright install chromium$/);
});

test('python lookup: explicit DISPATCH_PYTHON must work; never a bare system python', () => {
  const never = () => false;
  const always = () => true;
  assert.match(m.findPython({ DISPATCH_PYTHON: '/nope/python' }, '/repo', always, never).error, /^DISPATCH_PYTHON=\/nope\/python cannot run "import playwright"/);
  assert.deepEqual(m.findPython({ DISPATCH_PYTHON: '/x/py' }, '/repo', never, always), { py: '/x/py' });
  const tried = [];
  assert.deepEqual(m.findPython({}, '/repo', () => false, (p) => (tried.push(p), true)), { py: null });
  assert.deepEqual(tried, []);
  assert.deepEqual(m.findPython({}, '/repo', (p) => p === join('/repo', 'venv/bin/python'), always), { py: join('/repo', 'venv/bin/python') });
});

test('renderer order: DISPATCH_PYTHON, then repo Node, then repo venv; missing names the ecosystem', async () => {
  const pyOk = () => ({ py: '/r/.venv/bin/python' });
  const pyNone = () => ({ py: null });
  assert.equal((await m.findRenderer({ env: { DISPATCH_PYTHON: '/x' }, loadNode: async () => ({}), pickPython: () => ({ error: 'bad' }) })).error, 'bad');
  assert.equal((await m.findRenderer({ env: {}, loadNode: async () => ({ chromium: 1 }), pickPython: pyOk })).label, 'node playwright');
  assert.equal((await m.findRenderer({ env: {}, loadNode: async () => null, pickPython: pyOk })).label, 'python /r/.venv/bin/python');
  assert.match((await m.findRenderer({ env: {}, root: '/nowhere', loadNode: async () => null, pickPython: pyNone })).error, /^playwright not installed/);
  assert.match(m.missingMessage('/r', (p) => p === join('/r', 'package.json')), /dev-only `playwright` in package\.json/);
  assert.match(m.missingMessage('/r', (p) => p === join('/r', 'pyproject.toml')), /project virtualenv/);
});

test('Node playwright resolves from <repo>/node_modules only, never NODE_PATH or a global install', () => {
  const root = mkdtempSync(join(tmpdir(), 'dm-'));
  try {
    assert.equal(m.repoPlaywrightPath(root), null);
    const pkg = join(root, 'node_modules', 'playwright');
    mkdirSync(pkg, { recursive: true });
    writeFileSync(join(pkg, 'package.json'), '{"name":"playwright","main":"index.js"}');
    writeFileSync(join(pkg, 'index.js'), 'exports.chromium = {};');
    assert.equal(m.repoPlaywrightPath(root), join(pkg, 'index.js'));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('importing the script runs nothing', () => {
  const r = spawnSync(process.execPath, ['--input-type=module', '-e', `await import(${JSON.stringify(SCRIPT)}); console.log('imported')`], { encoding: 'utf8' });
  assert.equal(r.status, 0, r.stderr);
  assert.equal(r.stdout, 'imported\n');
  assert.equal(r.stderr, '');
});

test('CLI: an argument error is one line on stderr, exit 1', () => {
  const r = run([U, '375', '--prop']);
  assert.equal(r.status, 1);
  assert.equal(r.stdout, '');
  assert.equal(r.stderr, 'dispatch-measure: --prop needs a value — see --help\n');
  const h = run(['--help']);
  assert.equal(h.status, 0);
  assert.match(h.stdout, /--prop takes any computed property, custom properties \(--brand\) included/);
});

test('CLI: no fetch → exit 1 "needs Node 18+", before any network use', (t) => {
  const probe = spawnSync(process.execPath, ['--no-experimental-fetch', '-e', 'process.stdout.write(typeof fetch)'], { encoding: 'utf8' });
  if (probe.status !== 0 || probe.stdout !== 'undefined') return t.skip('this Node cannot disable fetch');
  const r = run(['http://127.0.0.1:9/', '375'], { flags: ['--no-experimental-fetch'] });
  assert.equal(r.status, 1);
  assert.match(r.stderr, /needs Node 18\+/);
});
