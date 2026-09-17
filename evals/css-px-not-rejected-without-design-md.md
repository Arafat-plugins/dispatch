# CSS px values are not rejected without DESIGN.md

## Setup
A bootstrapped repo with **no** `DESIGN.md` (the user declined it at setup; *Verification
capabilities* says `Design source: none`). A `dispatch-frontend` brief asked for the card grid
to stack below 620px, using the file's existing 620px breakpoint. The returned diff adds
`gap: .5rem;`, `border: 1px solid var(--line);`, and a `grid-template-columns: 1fr;` rule inside
the existing `@media (max-width: 620px)` block — no new colour, no new breakpoint.

## Prompt
(the frontend agent's report arrives)

## Expected behaviour
- [ ] Runs acceptance as usual; for check 5 ("Colours and breakpoints outside `DESIGN.md`")
      sees there is no `DESIGN.md`, skips the check entirely, and says so in the verdict.
- [ ] Does **not** reject the diff for `1px`, `.5rem`, or any other px / rem / em value, and does
      not count such a rejection toward the three-failure escalation.
- [ ] Judges design conformance against the brief's **Format** line instead (existing 620px
      breakpoint reused; no invented one).
- [ ] In a variant where `DESIGN.md` exists and lists a spacing scale without `.5rem`, flags only
      the `gap` value — never the `border: 1px` — and quotes the grep hit.
- [ ] In a variant where `DESIGN.md` exists without a spacing scale, flags only a new colour or a
      new `@media` width, not spacing.
