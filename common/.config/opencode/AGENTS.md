# Agent instructions
- Close temporary tabs and panes in Rex you create when finished.
- NEVER use non-ascii symbols in code (e.g. —, →, etc.)
- Preserve comments that explain intent, rationale, tradeoffs, constraints,
  historical context, or author notes; update or remove them only when clearly
  incorrect, obsolete, or redundant.
- New comments should explain something the code cannot clearly express: why a
  choice exists, a constraint or tradeoff, or the meaning or source of
  non-obvious logic or values. Keep them brief; do not narrate or summarize
  straightforward code.
- Keep READMEs short and match the existing documentation's scope. A new flag
  or option gets one line in an existing usage snippet, not its own section;
  API details belong in doc comments next to the code.
- Keep single-use logic inline unless extracting it creates a clear abstraction
  or isolates a substantial, self-contained operation. Do not create tiny
  helpers merely to shorten a function; optimize for reading the flow without
  jumping between definitions. Prefer an existing standard-library function
  over writing a helper.
- Put a function on the type whose data it operates on, and nest private
  helpers inside the type or namespace that owns them rather than leaving them
  as loose file-level functions.
- Import a module or namespace under its own name. When a local variable
  clashes with it, rename the local instead.
- Keep section-header comments true: place each new declaration under the
  section that describes it (e.g. no private helpers under a "Public API"
  header).
- Do not add tests that merely restate implementation details, enum mappings,
  constants, or trivial switch arms. A test must exercise meaningful behavior,
  an invariant, a regression, an edge case, or an integration boundary. If the
  test has no independent oracle and can repeat the implementation's mistake,
  omit it.
- If you detect that you are in a sandbox, you may install tools and do whatever
  is needed to complete the task. If a required network resource is blocked, ask
  the user for access and explain why it is needed.
- Before committing uncommitted work you did not write, review it against these
  rules as if you had written it.
- Git commit messages are a single brief subject line (e.g.
  `debug: accept '?' inside AT set arguments`). Do not add a body or
  description.
