# Complete Current Task

Mark the current task as complete and move it to the archived folder.

Steps:

1. Identify which task is currently in-progress by reading task files in `docs/tasks/`
2. If multiple tasks are in-progress, ask which one to complete
3. If no task is in-progress, ask the user which task to complete
4. Verify all acceptance criteria are met:
   - Read the task file
   - Check if deliverables are complete
   - Confirm tests are passing
   - Ask user if all acceptance criteria are met
5. Update the task file:
   - Change Status to "completed"
   - Add final progress log entry with completion date
   - Note what was accomplished
6. Move the task file to `docs/archived/[ID]-[name].md`
7. Clear the todo list with TodoWrite (empty array)
8. Provide a summary of what was completed

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
