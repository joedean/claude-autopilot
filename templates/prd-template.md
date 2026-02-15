# Product Requirements Document

## Project Name
<!-- Replace with your project name -->
My Project

## Overview
<!-- Brief description of what you're building -->

## Tech Stack
<!-- e.g., Next.js, TypeScript, Tailwind, PostgreSQL, etc. -->

## Architecture
<!-- High-level architecture decisions -->

## Tasks

<!-- 
Each task should be:
- Atomic: one logical unit of work  
- Verifiable: clear success criteria
- Ordered: respect dependencies
- Categorized: setup, feature, integration, styling, testing

The Ralph loop picks the first task with "passes": false
-->

```json
[
  {
    "category": "setup",
    "description": "Initialize project with chosen tech stack",
    "steps": [
      "Create project scaffold",
      "Install dependencies",
      "Verify dev server starts"
    ],
    "passes": false
  },
  {
    "category": "feature",
    "description": "Implement core feature #1",
    "steps": [
      "Create data models",
      "Build API endpoints",
      "Add basic UI"
    ],
    "passes": false
  },
  {
    "category": "feature",
    "description": "Implement core feature #2",
    "steps": [
      "Define the feature scope",
      "Implement backend logic",
      "Wire up frontend"
    ],
    "passes": false
  },
  {
    "category": "testing",
    "description": "Add test coverage",
    "steps": [
      "Write unit tests for core logic",
      "Write integration tests for API",
      "Verify all tests pass"
    ],
    "passes": false
  },
  {
    "category": "styling",
    "description": "Polish UI and responsive design",
    "steps": [
      "Apply consistent styling",
      "Ensure mobile responsiveness",
      "Add loading states and error handling"
    ],
    "passes": false
  }
]
```

## Success Criteria
<!-- When is this project "done"? -->
- [ ] All tasks above pass
- [ ] Dev server runs without errors
- [ ] Core user flow works end-to-end
