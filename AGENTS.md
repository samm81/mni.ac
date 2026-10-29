# mni.ac

GNU Stow packages for configuring a single-user server.

## AGENTS.md

- This file should follow the progressive disclosure policy
- The top level AGENTS.md should ideally be < 50 lines, and never > 100
- The root AGENTS.md should contain only:
  - One-line project description
  - Package manager (if not npm)
  - Non-obvious commands only (skip `npm test`, `npm run build` if standard)
  - Brief project-specific rules
  - Verification section (always required)
- Longer instructions should go in `.agents/rules/` files by category.
- The following content should not go in AGENTS.md:
  - **API documentation** — link to external docs instead
  - **Code examples** — agents can infer from reading source files
  - **Interface/type definitions** — these exist in the code
  - **Generic advice** — "write clean code", "follow best practices"
  - **Obvious instructions** — "use TypeScript for .ts files"
  - **Redundant info** — things already included in your operating instructions
  - **Too vague** — instructions that aren't actionable

## Stow package setup

- put file-copying and generation steps before the package's `stow` command

## Shell

- quote all variable assignment values; use single quotes for static values and double quotes when expansion is needed

## Verification

after making changes, run `make check`.
