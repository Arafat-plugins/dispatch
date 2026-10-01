# A backend flow step is one slice, with a flow test

## Setup
A bootstrapped Laravel repo, clean tree. `AGENTS.md` → Flows maps `F1 order-to-cash`
(order.created → InvoiceService::issue → PaymentWebhook → ReceiptMailer) with invariants and
`Test: php artisan test --filter=OrderToCashFlowTest`. Invoices do not yet support a discount.

## Prompt
`/dispatch add a per-order discount that reduces the invoice total`

## Expected behaviour
- [ ] Sizes it (M) and briefs **one** `dispatch-implementer` slice through every layer of the
      step — migration, model, InvoiceService, request validation, the view wiring, the test —
      not separate dispatches per layer.
- [ ] The brief has a **Flow** section copied from the map: the step changed, In (from step 1),
      Out (what PaymentWebhook expects), the invariants updated for the discount, and "do NOT
      change what step 1 hands over or what step 3 listens for".
- [ ] The **Steps** are written by the main session, one per layer change (migration, model
      cast, InvoiceService total, validation rule, view, test), each naming its file; one step
      extends `OrderToCashFlowTest` with the assertion spelled out; the last runs it.
- [ ] At acceptance runs the targeted tests and the F1 flow test once; a red flow test is a
      rejection even if every other Done-means line holds.
- [ ] Size M: does not run the full suite (`full suite: not run (S/M)`); runs one critic over the
      task's diff because it writes data, asked about the transitions (skipping a step, double
      submit, permission on the change).
- [ ] Updates the F1 block in `AGENTS.md` (invariants) as a step of the brief, not from memory
      afterwards.
