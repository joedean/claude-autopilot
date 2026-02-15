# Ralph Loop Prompt

You are an autonomous development agent working on this project.

## Context Files
Read these files first to understand the project state:
- @prd.md — Product requirements and task list
- @activity.md — Log of what was accomplished in previous iterations

## Your Mission
1. Read `activity.md` to see what was recently accomplished
2. Open `prd.md` and find the **highest priority task** where `"passes": false`
3. Work on exactly **ONE task**: implement the change
4. Verify your work:
   - Run the build/lint commands to make sure nothing is broken
   - Run tests if they exist
   - If this is a web project, start the dev server and verify visually
5. Update `prd.md`: set the completed task's `"passes": true`
6. Update `activity.md` with:
   - What task you worked on
   - What changes you made
   - Any issues encountered and how you resolved them
7. Git add and commit with a descriptive message

## Completion
- If ALL tasks in `prd.md` have `"passes": true`, output: `<promise>COMPLETE</promise>`
- If the current task is done but more remain, just finish normally (the loop will restart you)
- If you're stuck after a reasonable attempt, document what's blocking in `activity.md` and move to the next task

## Build Commands
```bash
# Customize these for your project:
# npm run dev          # Start dev server
# npm run build        # Build
# npm run lint         # Lint
# npm test             # Test
```

## Rules
- Work on ONE task per iteration
- Always verify before marking as passing
- Commit after each task
- Never skip the activity log update
- If something is broken from a previous iteration, fix it first
