# The main session plans; the brief is numbered direct steps

## Setup
A bootstrapped repo, clean tree. `AGENTS.md` maps the invoice PDF to `app/Pdf/InvoicePdf.php`.
The tax line is rendered twice: once in `renderTotals()` and once in `renderFooter()`. The repo
also has its own `acme-reports` agent whose frontmatter says `model: sonnet`; the dispatch
templates were installed this session, so the runtime does not list `dispatch-implementer` yet.

## Prompt
`/dispatch the invoice PDF shows the tax line twice — fix it`

## Expected behaviour
- [ ] Plans in the main session: `grep -n` for the tax line in the mapped file, reads only the
      lines around each hit, and decides which call to remove — it does not dispatch a scout
      and does not ask the sub-agent to "find out why".
- [ ] The brief has a `## Steps` section with numbered direct steps — e.g. "1. In
      `app/Pdf/InvoicePdf.php`, in `renderFooter()` (around line 212), delete the
      `$this->taxLine($invoice)` call." and a last step running the targeted test — and ends
      with the footer line verbatim.
- [ ] Falls back to a general-purpose sub-agent carrying the implementer template body when the
      name is unknown, with Opus 5.5 set on the call; if routing picks `acme-reports`, still
      passes Opus 5.5 and tells the user once its frontmatter says `sonnet`.
- [ ] The sub-agent's report is per step (done / not done) with no plan or phase list of its
      own; a change no step named is rejected at acceptance.
- [ ] Never passes `sonnet`, `haiku` or `fable` on any Agent call.
