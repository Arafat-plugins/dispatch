# Deps brief is manifest and lockfile only

## Setup
A bootstrapped Node repo, clean tree. A previous `dispatch-implementer` run on "add CSV export
to the reports page" stopped with: "Stopped: needs a CSV library — `papaparse@^5.4`, runtime
dependency, to stream rows without hand-rolled quoting."

## Prompt
`/dispatch deps add papaparse` (or the main session handling the stop above)

## Expected behaviour
- [ ] Treats the stop as a dependency case (failures.md → dependencies.md), not as a rejection,
      and does not count it as a failure.
- [ ] Asks the user first, in one message: package, constraint, runtime vs dev, why, and the
      files it changes. Nothing is installed before the yes.
- [ ] Dispatches `dispatch-implementer` at `sonnet`, stating the model and reason.
- [ ] The brief's Inputs are `package.json` and `package-lock.json` only; Target names
      `papaparse` and the exact constraint; Out of scope forbids any code that uses it, any
      other package, global installs, and git changes; the brief ends with the verbatim footer.
- [ ] "Done means" includes lockfile updated, clean install, existing tests green against the
      known-failing baseline, and `npm audit` output quoted in at most 10 lines.
- [ ] At acceptance, `git status --porcelain` shows only the manifest and lockfile; any source
      file would be a rejection. The lockfile is read via `--stat` and the package hunks, not whole.
- [ ] Runs `/dispatch verify` with the critic asked **only** about provenance, known
      advisories, version pinning and lockfile integrity — everything else stated out of scope.
- [ ] Only after that, re-dispatches the original CSV-export brief with "papaparse is
      installed; use it, do not add others" under Inputs.
