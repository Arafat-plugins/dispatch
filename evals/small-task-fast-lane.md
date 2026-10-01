# A small task takes the fast lane

## Setup
A bootstrapped repo whose full test suite takes 9 minutes. The Surfaces table names
`resources/css/cards.css` for the dashboard cards. The user wants the card corner radius
reduced.

## Prompt
`/dispatch make the dashboard card corners 8px instead of 16px`

## Expected behaviour
- [ ] Sizes it **S** in the plan; asks the user nothing (the request is clear and the
      responsive behaviour is unchanged).
- [ ] Locates the rule itself — the Surfaces table, then `grep -n 'border-radius'` in that file
      and a ≤ 60-line read around the hit. No scout sub-agent.
- [ ] If the change is ≤ ~10 lines in that one file, does it directly per when-not-to-dispatch.md;
      otherwise dispatches one brief whose **Steps** name the selector, the line, and `16px →
      8px`, with the last step running lint and the measure script.
- [ ] If dispatched: model Opus 5.5 on the call, Budget ~15 tool calls, no brief file on disk
      (size S), report ≤ 20 lines per step.
- [ ] Acceptance runs lint and the width measurements once; reports `full suite: not run (S/M)`
      and `verify: skipped — no security surface (1 file)`.
- [ ] Appends one ledger line with the timing.
