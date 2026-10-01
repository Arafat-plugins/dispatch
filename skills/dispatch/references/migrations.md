# Migrations — changing the schema deliberately

`/dispatch migrate <change>`. The db-tester is read-only, and it stays that way. Until 1.9.0,
though, nothing covered **writing** schema changes. Migrations were buried in feature briefs
and reviewed like any other code, and they carried the risks feature code does not: locks,
data loss, irreversible steps, and privilege grants that default privileges quietly widen.

## When it applies

- A new table, column, index, constraint, enum value or view.
- A **data migration**: backfill, rename-and-copy, split or merge of existing rows.
- A **seed or fixture** change that tests or demos rely on.
- An **import** from a legacy system (a cutover), which is also [delivery.md](delivery.md)'s.

A feature that needs a schema change is **two dispatches in sequence**: the migration first
(this file), accepted and applied to the dev database, then the feature slice that uses it
(flows.md). The one exception is an additive column that only the slice itself reads. It may
ride inside the slice when the brief says so, and it still gets the Done means below.

## Before dispatching

1. **Capabilities.** `AGENTS.md` → *Verification capabilities* → `Migrations:` names the
   command (`php artisan migrate`, `alembic upgrade head`, `rails db:migrate`,
   `npx prisma migrate dev`), the **development** database it runs against — host, name and user,
   exactly — and the migrator connection if the project uses one (setup.md, steps e and f).
   Production is never a target. Nothing here connects to it.
   **Prisma has no down migrations**: its "rollback" step is `npx prisma migrate reset --force`
   on the dev database followed by `npx prisma migrate dev` — the reset proves the whole history
   replays; write that pair into the brief in place of rollback → migrate.
2. **Classify the change**. The answer goes into the brief:

| Kind | Examples | Extra in Done means |
| --- | --- | --- |
| Additive | new table, nullable column, new index | `migrate → rollback → migrate` clean |
| Constraining | NOT NULL, unique, FK on existing data | a db-tester check first: rows that would violate it = 0 |
| Destructive | drop or rename a column or table, type narrowing | **the user's explicit yes before the brief**; expand → migrate data → contract across separate briefs; a backup note |
| Data | backfill, copy, split | idempotent (safe to run twice); row counts before and after quoted; runs in batches for large tables |
| Privileges | grants, roles, RLS policies | the critic asks about privilege scope; default privileges named |

## The brief — to `dispatch-migrator`

```
## Task
Migration brief (migrations.md): <one sentence — the schema change>

## Inputs
Files you may create or edit:
  - <database/migrations/2026_10_03_000000_add_discount_to_invoices.php>   (new)
  - <the model's casts/fillable, if the framework needs it to read the column>
  - <the schema dump the framework rewrites: db/schema.rb, structure.sql, prisma/schema.prisma>
  - ARCHITECTURE.md   (only when an entity or relation changes — Data model line)
Kind: additive | constraining | destructive | data | privileges
Target: <table.column type null default; index; constraint — exact>
Dev database: <from Verification capabilities — the migrator connection if there is one>

## Steps
1. Print the connection `<migrate>` will use (host, port, database, user — never the password)
   and compare it with the Dev database line above. Any difference → stop.
2. Create `<new migration path>` with: <up: the exact change>; <down: the exact reverse>.
3. <the model cast / fillable line, if the framework needs it — or delete this step>
4. Run `<migrate>`, then `<rollback one step>`, then `<migrate>`. Quote each exit code and last lines.
5. Run `<schema dump / \d table>` and quote ≤ 15 lines.

## Out of scope — do NOT
- do NOT write feature code that uses the column (that is the next brief)
- do NOT edit an already-applied migration — add a new one
- do NOT run migrations against anything but the dev database named above
- do NOT commit, push, or change git state

## Knowledge
Read AGENTS.md first; ARCHITECTURE.md → Data model; DOMAIN.md <rule IDs this touches>.

## Done means
- [ ] `<migrate>` → `<rollback one step>` → `<migrate>` on the dev database, all exit 0, output quoted
- [ ] the down migration restores the previous schema exactly (or the brief says why it cannot)
- [ ] <kind-specific line from the table above>
- [ ] schema dump / `\d <table>` after, quoted ≤ 15 lines
- [ ] you report per step: done / not done, output quoted

## Budget
M — about 40 tool calls. At the budget, stop and report.

## Report
At most 20 lines, per step.

[ follow the numbered steps above in order; do not plan, add, skip or reorder steps; if a step cannot be done as written, stop and report ]
```

## Acceptance

- The diff touches only what Inputs named: the migration files, the named model lines, the
  framework's schema dump, and `ARCHITECTURE.md` → Data model when listed. **An edited, already
  applied migration is a rejection**: history is append-only.
- Read the quoted `migrate → rollback → migrate` output. "Not verified" here means the
  migration is not accepted. A schema change nobody ran is a guess.
- A **db-tester check** ([db-check.md](db-check.md)) confirms the result read-only: the column,
  index or constraint exists, and for data migrations the counts and invariants hold.
- **Verify, narrowly** ([verifier.md](verifier.md)): locks on large tables, data loss paths, a
  down migration that drops data, privilege grants wider than the brief. That is all the critic
  is asked about.
- Update `ARCHITECTURE.md` → Data model in the same brief when an entity or relation changed.

## Never

- Run a migration against production or a shared database, even read-only "just to check".
  Deploys run migrations ([delivery.md](delivery.md)), and the user runs deploys.
- Squash, reorder or delete applied migrations.
- A destructive step without the user's yes in this conversation.
