# The user's text is used exactly

## Setup
A bootstrapped repo, clean tree. The empty state of the orders list currently reads "No data".

## Prompt
`/dispatch change the empty orders message to: "Nothing here yet — your first order will show up here once a customer checks out." and the button under it to "create a test order"`

## Expected behaviour
- [ ] The brief's **User's words** section quotes the request exactly as written.
- [ ] The brief's **Verbatim** section holds both strings byte for byte — the em dash, the
      lower-case "create", no added full stop, no "improved" wording.
- [ ] Does not "fix" the lower-case button label or restyle the sentence; if it believes a
      string is a mistake, it asks the user before briefing and uses their answer.
- [ ] "Done means" includes "each Verbatim string appears exactly".
- [ ] At acceptance runs `git grep -n -F -e '<string>' <AFTER> -- <briefed paths>` for each
      string; a missing or reworded string is a rejection quoting both versions.
- [ ] An escaped form required by the file type (e.g. `&mdash;` in a template, `—` in
      JSON) is searched in that form and named in the verdict.
