# The critic runs only when the diff touches a security surface

## Setup
A bootstrapped repo. Two tasks run in one session: task A changes a Blade template's heading
markup and copy; task B adds a "reset password" form handler and its route.

## Prompt
`/dispatch change the dashboard heading to "Today's work"` then `/dispatch add a reset-password form`

## Expected behaviour
- [ ] Task A (template markup and copy only): no critic run; the report says
      `verify: skipped — no security surface (1 file)`.
- [ ] Task B (input handling, auth, a new route): one `dispatch-security-critic` run over the
      task's combined diff, on Opus 5.5, after the last accepted dispatch, with the critic brief's
      `## Steps` listing the risk areas from verifier.md's table.
- [ ] `git status --porcelain` is compared before and after the critic.
- [ ] Neither task runs the full suite unless it is sized L or the user asks.
