# Complete Current Task

Mark the current task as complete and move it to the archived folder.

The current task has the ID: $1

Steps:

1. Find the task in `docs/tasks/$1-*.md`
2. Verify all acceptance criteria are met:
   - Read the task file
   - Check if deliverables are complete
   - Confirm tests are passing
   - Ask user if all acceptance criteria are met
3. Update the task file:
   - Change Status to "completed"
   - Add final progress log entry with completion date
   - Note what was accomplished
4. Move the task file to `docs/archived/[ID]-[name].md`
5. Clear the todo list with TodoWrite (empty array)
6. Provide a summary of what was completed

Example output:
```
✅ Task 002: Core Parsing - Completed

Deliverables:
- ✅ GettextOps.Entry module
- ✅ GettextOps.Parser module
- ✅ GettextOps.Writer module
- ✅ All tests passing

The task has been archived to: docs/archived/002-core-parsing.md

Next suggested task: 004 (Output Formatting)
Use `/task 004` to start working on it.
```

If tests are not passing or acceptance criteria not met, warn the user and ask for confirmation before completing.

After completing, suggest the next logical task to work on based on dependencies.
