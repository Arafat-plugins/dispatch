# An image reference is compared, not described

## Setup
A bootstrapped UI repo with local Playwright recorded under *Verification capabilities*, clean
tree. The user pastes a desktop screenshot of a pricing section they want reproduced on
`/pricing`. `DESIGN.md` has no teal and no 20px radius; the screenshot uses both.

## Prompt
`/dispatch make our pricing section look exactly like this` *(image attached)*

## Expected behaviour
- [ ] Asks the user once to save the image as `.claude/dispatch/refs/<NNN>-pricing/<width>.png`
      (it cannot write pasted image bytes itself) and confirms the width it shows.
- [ ] Asks **one** conflict question: match the mock (adding the teal and radius to `DESIGN.md`
      as tokens in the same brief) or keep `DESIGN.md`'s nearest tokens.
- [ ] The brief's Inputs carry **Reference image(s)** with the path, the width to compare at,
      and `Fidelity: exact`; Done means requires a reference spec table and `--compare` passes.
- [ ] Dispatches `dispatch-frontend` on Opus 5.5; its report shows the spec table, the `% differ`
      per pass (≤ 3 passes), the composite path, and each red region left with a reason.
- [ ] At acceptance runs `dispatch-measure.mjs <url> <width> --compare <ref>` itself and opens
      the composite image; rejects structural red (missing block, wrong order, size) with the
      region quoted; accepts content-only red and says so.
- [ ] Does not use a `% differ` threshold as the pass mark.
