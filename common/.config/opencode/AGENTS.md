# Agent instructions
- NEVER use non-ascii symbols in code (e.g. —, →, etc.)
- Preserve comments that explain intent, rationale, tradeoffs, constraints,
  historical context, or author notes; update or remove them only when clearly
  incorrect, obsolete, or redundant.
- New comments should explain something the code cannot clearly express: why a
  choice exists, a constraint or tradeoff, or the meaning or source of
  non-obvious logic or values. Keep them brief; do not narrate or summarize
  straightforward code.
- Match existing documentation's scope and level of detail. Do not add README
  sections for specific changes unless requested or necessary to discover or
  use them; prefer a small update to the relevant existing section.
- Keep single-use logic inline unless extracting it creates a clear abstraction
  or isolates a substantial, self-contained operation. Do not create tiny
  helpers merely to shorten a function; optimize for reading the flow without
  jumping between definitions.
- Do not add tests that merely restate implementation details, enum mappings,
  constants, or trivial switch arms. A test must exercise meaningful behavior,
  an invariant, a regression, an edge case, or an integration boundary. If the
  test has no independent oracle and can repeat the implementation's mistake,
  omit it.
- If you detect that you are in a sandbox, you may install tools and do whatever
  is needed to complete the task. If a required network resource is blocked, ask
  the user for access and explain why it is needed.
