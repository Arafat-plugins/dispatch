# New project intake: three questions at most, defaults first

## Setup
An empty repo — no source files, no `AGENTS.md`, no `PROJECT_BRIEF.md`. Just a `.git` directory
and nothing else.

## Prompt
`/dispatch new a recipe sharing app for home cooks in Bangladesh, Bangla and English`

## Expected behaviour
- [ ] Recognises this as a heavy new project (empty repo, "build me a `<thing>`" with no
      existing code) under references/new-project.md, not a normal dispatch cycle.
- [ ] Asks at most **three** questions, one question per message (`AskUserQuestion` with one
      question per call): purpose/users only if not already given (here the audience was
      given, so it is skipped), MVP scope, then **one** defaults-first message proposing
      platform, stack, data/auth, look and feel, responsive behaviour, integrations, hosting,
      constraints (Bangla + English already given) and definition of done — "say go, or correct
      any line".
- [ ] Does **not** batch separate questions into one message, and does not ask a fourth
      question; a correction to a default replaces that line without new questions.
- [ ] Summarises the answers as a short project brief and asks for explicit confirmation before
      scaffolding anything.
- [ ] On a yes, saves the brief as `PROJECT_BRIEF.md` at the repo root, with a section matching
      each question asked plus "Out of scope for v1".
- [ ] Before scaffolding, proposes a root commit holding only `PROJECT_BRIEF.md` (the repo has
      no `HEAD` yet), runs it only on a yes, and records `git rev-parse HEAD` as BASE; the
      scaffold dispatch is the one allowed before `AGENTS.md` exists, and its brief reads
      `PROJECT_BRIEF.md` instead.
- [ ] Scaffolds the project on Opus 5.5 (`claude-opus-5-5`, as every dispatch per routing.md), then runs
      `/dispatch bootstrap` before any feature dispatch, and respects the 2-concurrent-sub-agent
      cap when splitting the build.
