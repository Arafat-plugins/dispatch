# Typo fix uses sonnet

## Setup
A bootstrapped repo (marker present, agents installed, tree clean). The user points at a typo
in a user-facing string: `"Sucessfully saved"` should read `"Successfully saved"`, in
`templates/toast.html`, one line.

## Prompt
`/dispatch fix the typo in the save toast — "Sucessfully" should be "Successfully"`

## Expected behaviour
- [ ] Recognises this as light work (text/copy) under the model-by-weight rule, not design or
      core-level implementation.
- [ ] If dispatched at all (the edit may also qualify for when-not-to-dispatch.md and be done
      directly), the Agent tool call sets `model: sonnet` explicitly — never left at the
      `dispatch-implementer` template's frontmatter default of `opus` without the override, and
      never `opus`.
- [ ] States the model choice and a one-line reason in the plan ("light copy edit → sonnet").
- [ ] Does not spend `opus` (or `fable`, where offered) on this task.
- [ ] Acceptance still runs normally: baseline, diff, Done means checked.
