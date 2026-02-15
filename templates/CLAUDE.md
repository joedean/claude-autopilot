# Project CLAUDE.md

## Project Overview
<!-- Customize this for your project -->
This project uses the hybrid Claude Code workflow with three modes:
Ralph (autonomous loops), GitHub interactive (comment-driven), and Agent Teams (parallel coordination).

## Agent Team Roles

When spawning an agent team for this project, use these specialized roles.
Each teammate should focus exclusively on their domain.

### product-owner
Responsible for requirements clarity, user story definition, and acceptance criteria.
Reviews PRD tasks, ensures they are atomic and verifiable, and validates that
implemented features match the intended user experience. Owns prd.md and
ensures task descriptions are clear enough for other agents to execute.

### solution-architect
Designs technical solutions, defines API contracts, data models, and system
architecture. Makes technology choices, defines module boundaries, and ensures
teammates work on non-overlapping file sets. Creates architecture decision
records. Reviews other teammates' work for architectural consistency.

### clean-code-architect
Implements features following clean code principles: SOLID, DRY, separation
of concerns. Owns the core application code. Writes readable, well-structured
code with proper error handling. Refactors when needed. Does NOT write tests
(that's customer-value-qa's job).

### performance-optimizer
Reviews and optimizes code for performance: query optimization, caching
strategies, lazy loading, bundle size, memory usage. Runs benchmarks and
profiling. Reports findings to the team lead with severity ratings.
Implements fixes for critical performance issues.

### security-hardening-architect
Reviews code for security vulnerabilities: injection attacks, auth issues,
data exposure, dependency vulnerabilities. Runs security scanning tools
where available. Implements fixes for critical security issues. Ensures
secrets are not committed, inputs are validated, and outputs are sanitized.

### customer-value-qa
Writes and runs tests: unit tests, integration tests, and end-to-end tests.
Validates that implemented features match acceptance criteria from the
product-owner. Reports test coverage. Verifies the application builds and
runs without errors. Creates test data and fixtures.

## Team Coordination Rules

- **File ownership**: Each teammate should own different files. Two teammates
  editing the same file causes overwrites. The solution-architect defines
  boundaries at team creation.
- **Communication**: Use the inbox messaging system to share findings.
  Always message the team lead when completing a task or encountering blockers.
- **Git discipline**: Each teammate commits their own work with descriptive
  messages prefixed with their role, e.g., `[clean-code] implement user API`.
- **Task claiming**: Self-claim tasks from the shared task list. Don't claim
  tasks outside your role unless explicitly asked by the lead.
- **Quality gates**: customer-value-qa must verify work before tasks are
  marked complete. security-hardening-architect reviews before merge.

## Build & Run Commands
```bash
# Customize these for your project:
# npm install        # Install dependencies
# npm run dev        # Start dev server
# npm run build      # Production build
# npm run lint       # Lint code
# npm test           # Run tests
# npm run test:cov   # Test coverage
```

## Tech Stack
<!-- Define your stack here so all teammates know the conventions -->
<!-- e.g., Next.js 14, TypeScript, Tailwind, PostgreSQL, Prisma -->

## Project Structure
<!-- Define key directories so teammates know where to work -->
<!-- e.g.,
src/
  api/           — Backend API routes (solution-architect, clean-code-architect)
  components/    — React components (clean-code-architect)
  lib/           — Shared utilities (clean-code-architect)
  tests/         — Test files (customer-value-qa)
docs/            — Documentation (product-owner)
-->
