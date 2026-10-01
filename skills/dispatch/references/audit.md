# Audit — system-level security at phase gates

`/dispatch audit <phase|module>`. `verify` judges one task's diff, and by design anything already
in the code at BASE is out of scope. That is right for a change and wrong for a system. An ERP
needs someone to ask, at each gate, whether the **whole** module still enforces who may see and
do what, whether tenants stay apart, and whether the audit trail can be forged. That is this
mode. It uses the same read-only critic, pointed at a module instead of a diff.

## When it runs

- **At every gate** (planning.md), over the phase's modules. A gate message names its result.
- **On request**, for one module (`/dispatch audit Billing`) or the whole app before a launch.
- **Not per task.** Per-task safety is `verify`.

## `THREAT-MODEL.md` — written once, kept short

At the repo root, **≤ 120 lines**, written at the first audit and shown as a diff. The user
confirms it:

```markdown
# Threat model
## Assets
client records (confidential per BR-04) · invoices & payments · payroll · audit log · credentials
## Actors
anonymous · member · manager · accountant · admin · another tenant's user · a leaked API token
## Trust boundaries
browser ↔ app · app ↔ payment webhook (signed) · app ↔ queue workers · app ↔ DB (roles: app, migrator, ro)
## Top risks (each → where it is checked)
T1 cross-tenant read via list/search/export — ClientPrivacyTest, audit Billing & Clients
T2 privilege escalation via role edit — DOMAIN.md Permissions, UserRolePolicyTest
T3 webhook replay / forged payment — F1 flow test, signature check in PaymentWebhook
T4 audit log tampering — append-only grants (migrations.md, privileges)
```

## The audit brief — to `dispatch-security-critic`

```
## Task
Audit brief (audit.md): judge whether <module or phase> enforces the threat model and the
permission matrix, across all of its code — not a diff.

## Inputs
Paths in scope: <the module's directories from AGENTS.md → Modules / Layout>
Threat model: THREAT-MODEL.md → T1, T2, T3 (the risks touching these paths)
Permission matrix: DOMAIN.md → Permissions rows <module>.*
Entry points: <the Surfaces rows and API routes for these paths — from AGENTS.md>

## Evaluate specifically for
- every entry point: authentication, then the Permissions row for its action — list, search,
  export, API and queued jobs, not only the page
- tenant scoping on every query that reads tenant tables
- the risks named above, each traced from its entry point to the data
- dependency advisories: <the audit command from AGENTS.md → Commands, output quoted ≤ 10 lines>

## Steps
1. Read AGENTS.md, THREAT-MODEL.md and the DOMAIN.md rows above.
2. For each entry point listed under Inputs, in order: authentication, then its Permissions row.
3. Check tenant scoping on every query in the paths that reads tenant tables.
4. Trace each named risk from its entry point to the data.
5. Run the dependency audit command and quote ≤ 10 lines.
6. Run `git status --porcelain` and confirm it is unchanged.

## Out of scope
Code outside the paths above. Style, performance, architecture opinions.

## Done means
- [ ] every entry point listed with its auth + permission verdict (a table, one row each)
- [ ] every named risk has a verdict — a finding, or "none" with the line that guards it
- [ ] each finding: file:line, the concrete attack, severity, confidence
- [ ] `git status --porcelain` unchanged — you wrote nothing

## Budget
L — about 80 tool calls. At the budget, stop and report what is covered and what is not.

## Report
At most 60 lines — the entry-point table may take 20 of them.

[ follow the numbered steps above in order; do not plan, add, skip or reorder steps; if a step cannot be done as written, stop and report ]
```

Run it on an **idle tree**, with the before/after `git status` check (acceptance.md, *After the
critic*). It runs on Opus 5.5, as always.

## After the audit

- Report the findings grouped by severity, each with its attack, **in the gate message**.
- A **high** finding blocks the gate. It becomes a brief in the current phase before the user is
  asked to pass.
- Medium and low findings are the user's call: fix now, or record as
  `accepted risk — <reason> — <date>` under the risk in `THREAT-MODEL.md`.
- Never auto-fix. Every fix goes through the cycle, like any change.
- An entry point with no permission check and no row in the matrix is a finding **and** a gap in
  `DOMAIN.md`. Brief both.
