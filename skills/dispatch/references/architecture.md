# Architecture and domain — the non-UI source of truth

`DESIGN.md` stops a UI brief from re-describing colours and spacing. Nothing did the same for
the rules that are expensive to get wrong in a business app: module boundaries, layering, the
data model, API conventions, business rules, and who may do what. Each brief had to restate
them, or they drifted over fifty dispatches. Three compact documents fix that. Briefs **cite**
them by section and ID, and agents read only the cited parts.

| File | Holds | Size |
| --- | --- | --- |
| `ARCHITECTURE.md` | modules and boundaries, layering, the data model (entities and relations, not columns), API conventions, cross-cutting rules, what never happens | ≤ 150 lines |
| `DOMAIN.md` | glossary, business rules `BR-nn`, the permission matrix, state machines (pointing at Flows) | ≤ 200 lines; split by module past that |
| `docs/adr/NNNN-<title>.md` | one decision each: context, decision, consequences | ≤ 30 lines each |

## Where they come from

- **A new project**: `/dispatch plan` writes them from `PROJECT_BRIEF.md` and the stack choice
  ([planning.md](planning.md)), shown as diffs and confirmed.
- **An existing repo**: bootstrap *proposes* them when the repo has business logic and no such
  documents. Survey routes, services, policies, migrations and enums for names and paths, not
  bodies. Show them as diffs, and write them on a yes. A repo that already has an architecture
  doc, a `docs/` domain page or ADRs keeps them: `AGENTS.md` points at them, and nothing is
  duplicated.
- Record where they live in `AGENTS.md` → *Where things are* (`Architecture:`, `Domain:`,
  `ADRs:`).

## `ARCHITECTURE.md` — shape

```markdown
# Architecture
## Modules
| Module | Owns | May call | Never calls |
| Billing | invoices, payments | Clients (read), Ledger | HR |
## Layers
controller → service → repository; controllers never touch the ORM directly; jobs call services
## Data model
Client 1—n Project n—n User (membership) · Project 1—n Invoice 1—n InvoiceLine · …
## API conventions
errors: RFC 7807 · pagination: cursor · auth: session (web), Sanctum token (api) · 404 for record-level denial
## Cross-cutting
audit log on every write to Billing/HR · tenancy: team_id on every tenant table · i18n: en, bn
## Never
raw SQL outside repositories · business rules in controllers or views · cross-module writes
```

## `DOMAIN.md` — shape

```markdown
# Domain
## Glossary
Engagement — a client's paid project; not a "job" (that word means a queued task here)
## Business rules
BR-01 An invoice total = Σ lines + tax, rounded half-up to 2 dp, per invoice not per line. Test: InvoiceTotalTest
BR-02 An invoice is paid at most once; a refund is a new document. Test: F1 flow test
BR-04 A client is visible only to its project members — list, search, reports and exports. Test: ClientPrivacyTest
## Permissions
| Action | Admin | Manager | Accountant | Member |
| client.view | ✅ | ✅ own | ❌ | ✅ member |
| invoice.void | ✅ | ❌ | ✅ | ❌ |
## State machines
invoice: issued → paid | void (void only before paid) — see AGENTS.md → Flows F1
```

**Every rule is one line, with an ID and a test.** A rule with no test says `Test: none — gap`.

## Reading them — by section, never whole

The main session and the agents read these the way `status` reads the polish index: headings
first, then only the cited part.

```bash
grep -nE '^(## |BR-[0-9]+)' DOMAIN.md                     # the outline: sections and rule IDs
grep -E '^BR-0(1|4) ' DOMAIN.md                            # the rules a brief cites
awk '/^## Permissions/{on=1;print;next} /^## /{on=0} on' DOMAIN.md
```

## In briefs

- **Knowledge** names the parts to read: "Read `DOMAIN.md` BR-01, BR-02 and the Permissions
  rows `invoice.*`; `ARCHITECTURE.md` → Layers and Billing's row." The agent reads those parts
  and nothing else.
- **Format** cites the conventions: "layering per ARCHITECTURE.md → Layers; errors per API
  conventions".
- **Done means** carries the rules as checks: "BR-01 holds: `InvoiceTotalTest` covers rounding
  per invoice".
- **A brief that changes a rule** lists `DOMAIN.md` (or `ARCHITECTURE.md`) under Inputs and adds
  an ADR. A rule never changes as a side effect.

## The agents' rule

The implementer, the migrator and the test-writer treat a cited rule the way the frontend agent
treats `DESIGN.md`. **A brief cannot override it; only a briefed change to the document can.**
If the brief contradicts a cited rule, or the change would break an uncited rule the agent
happens to see, the agent stops and reports. It does not pick one side.

## At acceptance and review

- **Acceptance**: a hunk that breaks a cited rule, a layer boundary or a permission row is a
  rejection that quotes the rule ID ([acceptance.md](acceptance.md)).
- **Drift** that no single diff shows, such as a rule enforced in 4 of 5 places or a module
  starting to call a neighbour it should not, is found by `dispatch-reviewer` at each gate
  ([planning.md](planning.md#gates--the-user-signs-off-phase-by-phase)). Its findings become
  briefs. It never fixes anything.
- **Security**: the permission matrix is what `/dispatch audit` checks the code against
  ([audit.md](audit.md)).
