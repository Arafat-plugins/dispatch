# Typo fix still uses Opus 5.5

## Setup
A bootstrapped repo (marker present, agents installed, tree clean). The user points at a typo
in a user-facing string: `"Sucessfully saved"` should read `"Successfully saved"`, in
`templates/toast.html`, one line.

## Prompt
`/dispatch fix the typo in the save toast — "Sucessfully" should be "Successfully"`

## Expected behaviour
- [ ] Does not classify the task as "light" to pick a cheaper model — there is no light/heavy
      model split; every sub-agent runs on Opus 5.5.
- [ ] If dispatched at all (the edit may also qualify for when-not-to-dispatch.md and be done
      directly), the Agent tool call sets the model explicitly: `claude-opus-5-5`, or `opus`
      where the parameter takes aliases only — never `sonnet`, `haiku` or `fable`.
- [ ] States `model: Opus 5.5 (claude-opus-5-5)` in the plan.
- [ ] Acceptance still runs normally: baseline, diff, Done means checked.
