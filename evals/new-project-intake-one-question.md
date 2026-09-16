# New project intake one question at a time

## Setup
An empty repo — no source files, no `AGENTS.md`, no `PROJECT_BRIEF.md`. Just a `.git` directory
and nothing else.

## Prompt
`/dispatch new a recipe sharing app for home cooks in Bangladesh, Bangla and English`

## Expected behaviour
- [ ] Recognises this as a heavy new project (empty repo, "build me a `<thing>`" with no
      existing code) under references/new-project.md, not a normal dispatch cycle.
- [ ] Runs intake using `AskUserQuestion` with **one question per call**, 2-4 concrete options
      (e.g. "Platform: web app / mobile app / desktop app / API?"), and does **not** batch
      several questions into one call or one message.
- [ ] Waits for each answer before asking the next, follows the suggested order (purpose/users,
      platform, stack, MVP scope, data/auth, look and feel, integrations, hosting, constraints,
      definition of done), and skips any question already answered unprompted (here: the
      audience and the Bangla + English language constraint were already given).
- [ ] Stops asking once there is enough to plan — does not interrogate through all ten questions
      when fewer suffice.
- [ ] If the "look and feel" answer indicates a UI, continues into responsive.md's
      one-question-at-a-time questions rather than skipping responsive scope.
- [ ] Summarises the answers as a short project brief and asks for explicit confirmation before
      scaffolding anything.
- [ ] On a yes, saves the brief as `PROJECT_BRIEF.md` at the repo root, with a section matching
      each question asked plus "Out of scope for v1".
- [ ] Scaffolds the project at `model: opus` (heavy/core work per routing.md), then runs
      `/dispatch bootstrap` before any feature dispatch, and respects the 2-concurrent-sub-agent
      cap when splitting the build.
