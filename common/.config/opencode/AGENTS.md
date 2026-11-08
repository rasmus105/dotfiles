# Agent instructions

## Coding

- NEVER use non-ascii symbols in code (e.g. —, →, etc.)

- Keep single-use logic inline unless extracting it creates a clear abstraction
  or isolates a substantial, self-contained operation. Do not create tiny
  helpers merely to shorten a function; optimize for reading the flow without
  jumping between definitions. Prefer an existing standard-library function
  over writing a helper.

- Keep logic inside the abstraction responsible for it, with the narrowest
  practical visibility. Expose only what callers need, keeping implementation
  details internal.

- Import modules and namespaces under their own names. Resolve collisions by
  improving local names rather than adding suffixes such as _module; reconsider
  whether a name conflates distinct concepts.

- Do not add tests that merely restate implementation details, enum mappings,
  constants, or trivial switch arms. A test must exercise meaningful behavior,
  an invariant, a regression, an edge case, or an integration boundary. If the
  test has no independent oracle and can repeat the implementation's mistake,
  omit it.

- Branches should be named in format `rasmus105/<name>`, unless otherwise
  specified. Worktrees should always go into `wt/<name>`, as `wt` is
  configured to be ignored globally by git (e.g. `rasmus105/plotting` ->
  `wt/plotting`)

## Documentation

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
- Keep section-header comments true: place each new declaration under the
  section that describes it (e.g. no private helpers under a "Public API"
  header).
- Our planning does not belong as documentation in repos.

## Workflow

- Close temporary tabs and panes in Rex you create when finished.
- NEVER name Rex tabs or sessions unless explicitly asked.
- Before committing uncommitted work you did not write, review it against these
  rules as if you had written it.
- Git commit messages are a single brief subject line (e.g.
  `debug: accept '?' inside AT set arguments`). Do not add a body or
  description.
- On the Mac mini, use Rex host `macbook` to access the MacBook server;
  run `rex -S macbook ...` and inspect its sessions before using a terminal.
  If `rex` is not on PATH, use `/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex`.

## Communication

- Respect the reader's time. Write for their task and existing knowledge,
  including only what helps them understand the result or make a decision.
  State each point once; omit what they can readily infer.

- Use labels, units, tables, and visual cues to convey information concisely.
  Show context where it matters, such as marking rainy periods directly on a
  plot. Omit unnecessary elements, and keep qualifications close to what they
  affect.

- Choose the form that conveys the information most clearly and concisely.
  Use prose for explanation and reasoning; use labels, lists, tables, or visuals
  when they make facts, comparisons, or patterns easier to grasp. Avoid prose
  that merely narrates what is already apparent.
