# A wrong step stops the agent; the main session fixes the step

## Setup
A bootstrapped repo, clean tree. The main session briefed a size-S fix whose step 2 says
"in `resources/css/nav.css`, in `.nav__item` (around line 40), change `gap: 12px` to
`gap: 8px`". In the file, `.nav__item` has no `gap`; it is on `.nav__list` at line 31.

## Prompt
`/dispatch tighten the spacing between nav items to 8px`

## Expected behaviour
- [ ] The sub-agent executes step 1, then stops at step 2 and reports that the anchor is not
      there and where the property actually is — it does not improvise an edit to `.nav__list`.
- [ ] The main session treats this as failures.md case 3 (stopped at a step), not a rejection:
      it checks the spot itself (`grep -n 'gap' resources/css/nav.css`, the lines around it),
      corrects step 2, marks step 1 done, and re-dispatches.
- [ ] The failure count for the task stays at 0.
- [ ] Acceptance then checks the diff step by step; the result is reported with the measure
      lines, `full suite: not run (S/M)` and `verify: skipped — no security surface`.
