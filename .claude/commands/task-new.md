# Create New Task

Create a new task file based on the template at `docs/template-task.md`.

Steps:

1. Find the next available task number by checking existing tasks in `docs/tasks/`
2. Ask the user for the task name if not provided as $1
3. Create the new task file: `docs/tasks/[ID]-[name-slugified].md`
4. Copy the template from `docs/template-task.md`
5. Fill in the basic information:
   - Replace `[ID]` with the task number
   - Replace `[Name]` with the provided name
   - Set Status to `not-started`
   - Set Created date to today
   - Ask the user about dependencies
   - Ask if it can be parallelized
6. Save the file

Example usage:
```
/task-new Add Plural Forms Support
```

This would create: `docs/tasks/011-add-plural-forms-support.md`

After creating the task, show the path and suggest using `/task [ID]` to start working on it.

If $1 (name) is not provided, ask the user:
- What is the task name?
- What does this task accomplish?
- Are there any dependencies?
- Can it be done in parallel?
