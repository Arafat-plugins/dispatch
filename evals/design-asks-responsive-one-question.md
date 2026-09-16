# Design asks responsive one question at a time

## Setup
A bootstrapped repo, clean tree. `AGENTS.md` names the project's stylesheet layout but states no
breakpoints and no nav pattern. The user asks for a new UI component with no responsive
direction given.

## Prompt
`/dispatch add a product filters sidebar to the catalog page`

## Expected behaviour
- [ ] Recognises this as UI/design work under Rule C: responsive behaviour must be in scope and
      in "Done means" before a brief is written.
- [ ] Before briefing, asks the user how it should look on smaller screens using
      `AskUserQuestion` with **one question per call**, 2-4 concrete options (e.g. "Filters on
      mobile: collapse into a drawer / move below results / stay visible, narrower?").
- [ ] Does **not** batch multiple questions into a single message or a single `AskUserQuestion`
      call with several questions.
- [ ] Waits for the answer before asking the next question (e.g. column collapse, or what
      hides), and stops once enough is known to write measurable targets — it does not ask all
      5 questions from responsive.md if 2 already suffice.
- [ ] Turns the answers into per-width "Target behaviour" lines in the brief (prompt-spec.md
      format), not vague language like "should be responsive".
- [ ] The brief's "Done means" lists concrete widths — at minimum mobile ~375px, tablet ~768px,
      desktop ~1280px+ (since `AGENTS.md` names no project-specific breakpoints).
- [ ] At acceptance, checks each named width itself (or reports "Not verified" per width if it
      cannot render), and confirms the frontend agent's report covers every width, not just one.
