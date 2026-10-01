# Flows — backend work that holds end to end

A **flow** is a business workflow that crosses files, handlers and states: order → invoice →
payment → receipt; leave request → approval → balance; signup → verify → first login. Each
dispatch can pass its own "Done means" while the flow as a whole is broken. The skill caused
that in five ways:

1. **One job per dispatch splits a flow across briefs.** The model, the handler and the view of
   one step went to different dispatches, sometimes to different agents. Each got a slice, and
   nobody got the handoff between slices.
2. **No brief carried the contract between steps**: what the previous step hands over (shape,
   state, IDs) and what the next step expects. Each agent inferred it from the one file it was
   given.
3. **Tests were optional.** The implementer *ran* the listed tests. Nothing asked it to *write*
   one that drives the flow through the changed step.
4. **Acceptance read the diff, not the behaviour.** A diff can look right and still break the
   step after it.
5. **Nothing re-ran earlier flows.** A new step that changed a shared status or column broke a
   flow accepted three dispatches ago, and nobody saw it until the user did.

## The flow map — in `AGENTS.md`

Bootstrap writes a **Flows** section inside the dispatch markers (bootstrap.md, Step 2). The
new-project path writes it from `PROJECT_BRIEF.md`, and every brief that adds a step keeps it
current. One block per flow, **8 lines at most**:

```markdown
## Flows
### F1 order-to-cash
Trigger: POST /orders (OrderController@store)
Steps: order.created → InvoiceService::issue (invoice.issued) → PaymentWebhook (invoice.paid) → ReceiptMailer
States: orders.status draft→placed→paid · invoices.status issued→paid|void
Invariants: invoice.total = Σ lines + tax; an invoice is paid once; void only before paid
Test: php artisan test --filter=OrderToCashFlowTest
```

With more than ~8 flows, keep one line each here (`F7 payroll-run — docs/flows/payroll-run.md —
test: …`) and put the blocks in `docs/flows/`. The map stays a map.

**No test yet for a flow** → write `Test: none — first brief touching F1 adds it`. That is a
gap to close, not a line to leave.

## The brief — a `Flow` section

Any brief whose Inputs touch a step of a mapped flow fills the template's **Flow** section,
copied from the map and never paraphrased:

```
## Flow
F1 order-to-cash — this brief changes step 2 (InvoiceService::issue).
In:  order.status = placed; order.lines[] with qty, unit_price, tax_rate (from step 1)
Out: invoice.status = issued; invoice.total set; event InvoiceIssued(invoice_id) (step 3 listens)
Invariants: invoice.total = Σ lines + tax; an order has at most one non-void invoice
Do NOT change what step 1 hands over or what step 3 listens for.
```

When the flow has a test in the map, the **last step** runs it and **Done means** says it passes:

```
- [ ] `OrderToCashFlowTest` passes (command and result quoted)
```

Adding or extending a flow test is a **step you write**, with the assertion spelled out ("in
`tests/Feature/OrderToCashFlowTest.php`, add a test that issues the invoice for a placed order
and asserts `invoice.total = Σ lines + tax`"). Ask for test-first (the new assertion shown red
before the change, then green) only when the brief fixes a bug the test reproduces — not by
default.

## Slice by flow step, not by layer

A backend feature is **one vertical slice through every layer of one step** — migration, model,
service, handler, request validation, the view wiring that uses it, and its flow test — briefed
to **one** `dispatch-implementer`. Do not split "the model" and "the controller" into separate
dispatches. That split is how the handoff gets lost, and it doubles the round trips
([speed.md](speed.md)).

`dispatch-frontend` still takes work that is judged by looking (layout, visual design,
responsive). Markup that only wires existing components to the new data stays with the
implementer's slice.

**Two steps of one flow are never dispatched in parallel.** They share a contract. Run them in
sequence and accept the first before briefing the second.

## Acceptance — the flow check

After "The check" in [acceptance.md](acceptance.md):

```bash
<the Test: command from AGENTS.md → Flows for the flow the brief carried>
```

- **A red flow test is a rejection**, even when every other "Done means" line holds. Quote the
  failing assertion.
- **Test-first, when the steps asked for it.** You cannot run BASE yourself; the evidence is the
  agent's quoted run — the new assertion failing before its change, then passing. No quote →
  reject, naming the assertion.
- **A new state, event or column that another flow reads** without that flow's test in the
  run → run it now.

**End of a size-L task:** run every flow test in the map once, together with the full suite
([speed.md](speed.md#tests--targeted-once-each-side)). Report it as one line
per flow: `F1 order-to-cash ✓`. S and M tasks run only the flow they touched.

## Verify — ask about the transitions

For a diff that changes a flow step, the critic brief ([verifier.md](verifier.md)) adds these to
*Evaluate specifically for*:

- skipping a step (paying an invoice that was never issued, approving your own request)
- replay and double submit (idempotency of the handler and the webhook)
- state changes without the permission check the previous step did
- a race between two steps writing the same row

## Data after a flow change

When the step writes data, a db-tester check ([db-check.md](db-check.md)) can confirm the
invariants on the development database: rows that break an invariant, orphans, and statuses
outside the allowed set. It stays read-only. A violation found there is a finding for a new
brief, never something to fix in place.
