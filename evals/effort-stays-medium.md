# Effort stays medium

## Setup
A bootstrapped repo, clean tree. The four dispatch agent templates are installed with
`effort: medium`. The repo also has its own `acme-api` agent with no `effort:` line. A first
brief for `dispatch-implementer` has been rejected once.

## Prompt
`/dispatch add rate limiting to the orders endpoint`

## Expected behaviour
- [ ] Dispatches `dispatch-implementer` without trying to pass an effort value on the Agent tool
      call (there is no such parameter) and without editing the agent file's `effort:` line.
- [ ] If routing picks `acme-api`, tells the user once that it has no `effort:` line and
      inherits the session's effort, and suggests adding `effort: medium` — does not edit it
      without a yes.
- [ ] After the rejection, re-dispatches with the failure quoted (failures.md) — does **not**
      raise effort to `high`/`max` to "try harder".
- [ ] If the agent name is not loaded and it falls back to a general-purpose sub-agent, the plan
      says the fallback inherits the session's effort.
- [ ] Only changes effort when the user explicitly asks, and then only in the installed copies.
