# Database checks

Read-only inspection dispatched to `dispatch-db-tester`. The default posture is **read-only**;
a write requires the user to ask for it in that turn, in words.

## Before dispatching

`AGENTS.md` should name the connection. If it does not, find it once and add it there — every
future dispatch then gets it for free:

```bash
grep -rniE "(DB_NAME|DATABASE_URL|DB_HOST|DB_USER)" \
  --include="*.env*" --include="*.php" --include="*.json" --include="*.yml" . | head
```

**Never put credentials in the brief.** Name the config file the agent should read them from.
A password pasted into a prompt is a password in a transcript.

## The brief

```
## Task
<the question being answered — not "check the database">

## Connection
Read credentials from <config file>. Do not print them in your output.

## Posture
READ ONLY. You may run SELECT, SHOW, DESCRIBE, EXPLAIN.
Do NOT run INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE, or CREATE.
Do NOT modify schema or data under any circumstances.

## Checks
<the specific questions>

## Report
A table of check → result → judgement. Include the query you ran for each.
Say "cannot determine" where you cannot; do not guess.

## Out of scope
Do NOT survey the whole schema. Only what the checks above need.
Do NOT dump table contents; report counts and samples of at most 5 rows.
Do NOT print credentials, tokens, or personal data — mask them.

[ task list broken down into phases, each phase as a vertical slice, numbered ]
```

## Checks worth asking for

**Schema integrity** — do the tables the code expects exist, with the expected columns and
types? Is anything the code writes to missing an index it is filtered by?

**Referential integrity** — orphaned rows whose parent is gone; foreign keys declared in code
but not in schema.

**Data sanity** — nulls in columns the code assumes non-null; duplicates in what should be
unique; timestamps in the future; counts that disagree between a table and its projection.

**Migration drift** — does the live schema match what the migration files describe? This is the
one that quietly breaks deploys, and it is invisible from reading code alone.

**Index health** — the columns the hot queries filter and sort by, versus the indexes that exist.
Pair with `EXPLAIN` on the actual query, not a guess at it.

## Reporting

The result is evidence, not a verdict on the code. Report the query, the result, and what it
implies. If a check suggests a bug, that is a new task — plan it, brief it, dispatch it. Do not
let the db agent fix what it found.
