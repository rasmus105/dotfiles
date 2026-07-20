# Agent instructions
- NEVER use non-ascii symbols in code (e.g. —, →, etc.)
- Avoid comments for self-explanatory code. Comments should mainly explain
  intent, tradeoffs, constraints, or non-obvious behavior.
- Do not add tests that merely restate implementation details, enum mappings,
  constants, or trivial switch arms. A test must exercise meaningful behavior,
  an invariant, a regression, an edge case, or an integration boundary. If the
  test has no independent oracle and can repeat the implementation's mistake,
  omit it.
- If you detect that you are in a sandbox, you may install tools and do whatever
  is needed to complete the task. If a required network resource is blocked, ask
  the user for access and explain why it is needed.
