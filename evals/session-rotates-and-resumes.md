# The main session rotates when needed, and resumes from files

## Setup
A bootstrapped repo. In this main session 10 dispatches have been accepted (ledger 031–040); an
eleventh task is planned. Later in the session the runtime compacts the conversation.

## Prompt
`/dispatch next: the leave approval screen`

## Expected behaviour
- [ ] Before the eleventh, **suggests** a fresh session in one line and carries on with the task
      when the user does not take it — no forced stop.
- [ ] After the compaction, rotates: writes `.claude/dispatch/HANDOFF.md` (≤ 30 lines — task,
      size, brief file, BASE/BASE_HEAD literals, what is accepted, Next, open questions) and
      prints the resume block; does not dispatch further in the old session.
- [ ] In the fresh session, `/dispatch resume` reads only `AGENTS.md`, `HANDOFF.md`,
      `tail -n 20` of the ledger and the named brief file; runs
      `git status --porcelain` and `git rev-parse HEAD`; reports where things stand in ≤ 5 lines.
- [ ] If `HEAD` differs from the handoff's BASE_HEAD, says so and takes a new BASE.
- [ ] Never states a sha, test result or "accepted" that did not come from a command, the
      ledger or a brief file in this session (the fact rule); says "unknown — checking" first.
- [ ] After the compaction, treats every sha in the summary as unknown and re-reads it from the
      ledger before use.
