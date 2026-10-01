# Delivery — from accepted code to a running system

The intake asks where the app will run, and up to 1.8.0 nothing used the answer. CI, environment
configuration, deploy scripts, backups, runbooks and the cutover from an old system were built by
hand, outside the skill, or not at all. This file makes them briefs like any other. The
rule that matters most here: **agents build and test delivery artefacts; the user runs them
against real servers.**

## Delivery capabilities — recorded once

Bootstrap (or `/dispatch plan`) adds this block to `AGENTS.md`, inside the markers, from
`PROJECT_BRIEF.md` → Hosting and what the repo already has:

```markdown
## Delivery capabilities
Target: single VPS, Ubuntu 24.04, nginx + php-fpm + Postgres 16 (from PROJECT_BRIEF.md)
CI: GitHub Actions — .github/workflows/ci.yml (lint, test shards, build) | none
Clean-room check: docker available → `docker run --rm -v "$PWD":/app ubuntu:24.04 …` | none
Environments: local · staging (user-run) · production (user-run)
Secrets: .env (gitignored) · .env.example documents every key · never values in the repo
Deploy: deploy/deploy.sh — run by the user · backups: deploy/backup.sh + restore test
```

## Delivery briefs

Briefed to `dispatch-implementer`. The Task line opens with `Delivery brief (delivery.md):`
(routing.md). One artefact per brief:

| Artefact | Inputs | Done means includes |
| --- | --- | --- |
| **CI pipeline** | `.github/workflows/*.yml` (or the host's equivalent) | lint + test shards + build run green locally with the same commands; the workflow runs them, cached; no secret values in the file |
| **Environment config** | `.env.example`, config files | every key the code reads is in `.env.example` with a comment; the app fails fast and clearly on a missing key |
| **Deploy kit** | `deploy/` scripts, server config templates | runs to completion in the clean-room container from a fresh checkout; idempotent (runs twice); migrations run as the migrator role; rollback step documented |
| **Backup & restore** | `deploy/backup.sh`, `deploy/restore.sh` | a backup made in the clean room restores into an empty database, and a row count matches |
| **Runbook** | `docs/runbooks/<name>.md` | every command in it was run in the clean room and its output quoted; no step says "just" |
| **Cutover / import** | the importer (migrations.md, kind *data*) + `docs/runbooks/cutover.md` | a dry run on a sample export; counts in = counts out; idempotent; a parallel-run window and rollback written down |

**The clean-room check** is the delivery equivalent of rendering at a width. A deploy script
that has only been read is `Not verified: no clean-room run`, and the report says so. GoodTechies
HQ's deploy kit "passed in a fresh Ubuntu 24.04 container". That is the bar.

## What the skill never does

- Connect to, deploy to, or migrate a staging or production server. The brief's Out of scope
  says so every time. Deploy commands are **printed for the user**, with what each one changes.
- Put a secret value in any file, command line or report.
- Push, tag or publish a release.

## At a gate

The gate that ends the last phase (planning.md) checks delivery too: CI green on the checkpoint
commit, the deploy kit's clean-room run quoted, a restore test quoted, and the runbooks listed.
The user runs the real deploy and says so. Record it in `ROADMAP.md` → Status
(`deployed to staging by the user, 2026-11-02`).
