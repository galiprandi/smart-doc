# Modules Documentation

This repository organizes code into modules/packages. Each major module should have its own documentation file under docs/modules/<module>.md describing purpose, public APIs/contracts, dependencies, and risks.

Current state
- TBD: Detect modules from code layout and create corresponding docs.
- Add new module docs here as modules are identified.

Documentation guidance
- For each module, include:
  - Purpose and responsibilities
  - Public APIs, contracts, and interfaces
  - Key entities/types and important functions/classes
  - In/Out dependencies within the repo (who uses it; what it uses)
  - Risks and TODOs

Adding a module doc
- Create docs/modules/<module>.md with content modeled after this structure.
- Link to code paths using relative paths, e.g. ./../../src/module/file.ts
- Include a short “TBD” note if details are not yet known.

