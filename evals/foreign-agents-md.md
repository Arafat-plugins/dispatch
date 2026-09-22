# Foreign AGENTS.md

## Setup
The repo has an `AGENTS.md` written for Codex: 40 lines of setup instructions and coding
style, no Layout table, no Commands, no known-failing baseline, and no
`<!-- dispatch:map v1 -->` marker. No `.claude/agents/` directory.

## Prompt
`/dispatch status`, then `/dispatch bootstrap`

## Expected behaviour
- [ ] `status` reports the map as **foreign** (present, no marker), not as bootstrapped; `Next:` is `/dispatch bootstrap`.
- [ ] Bootstrap does not overwrite. It writes a proposal that keeps every existing line and appends a region between `<!-- dispatch:map v1 -->` and `<!-- /dispatch:map -->`.
- [ ] Shows `diff -u AGENTS.md <proposal>` to the user **before** writing.
- [ ] Inside the region, references the Codex sections that already cover something ("Conventions: see above") rather than duplicating them.
- [ ] Runs the test/lint commands with a timeout before writing the Known-failing baseline; the section is dated and commit-stamped, or says `not measured — <reason>`. Never a bare "none".
- [ ] State file has `"version": "1.6.0"`, `commit`, and `baseline_measured`.
- [ ] Ends by telling the user what to commit and that newly installed agents may need a session restart.
