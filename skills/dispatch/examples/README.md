# Examples

## `AGENTS.storecraft.md`

A real `AGENTS.md` produced by `/dispatch bootstrap` on a large WordPress commerce plugin
(~27 stylesheets, 30 Gutenberg blocks, 168 smoke tests, two coexisting PHP generations).

Worth reading for the three sections that carry the most weight in practice:

- **Do NOT** — names the committed build output, the vendored dirs, and the edition boundary
  that breaks things when ignored. These are the rules an agent cannot infer from the file it
  is editing.
- **Known-failing baseline** — 11 of 168 smoke tests already fail on a clean checkout. Without
  this list, every agent re-investigates them.
- **What not to bother reading** — a direct instruction not to spend context, with a reason per
  entry.

Note it is ~150 lines for a repo of that size. If your map approaches the cost of the territory,
it has stopped being a map.
