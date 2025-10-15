# List All Tasks

Read all task files in `docs/tasks/` directory and display them in a table format with the following information:

- **ID** - The task number (001, 002, etc.)
- **Name** - The task name
- **Status** - Current status (not-started, in-progress, completed, skipped)
- **Dependencies** - What tasks it depends on
- **Can Parallelize** - Whether it can be done in parallel with other tasks

Also provide a summary:
- Total tasks
- Completed tasks
- In-progress tasks
- Available tasks (dependencies met)

Highlight which tasks are available to work on next (i.e., their dependencies are completed or they have no dependencies).

Format the output as a markdown table for easy reading.

Example output:

```
## gettext_ops Tasks

| ID  | Name                  | Status      | Depends On | Parallel |
|-----|-----------------------|-------------|------------|----------|
| 001 | Setup Project         | completed   | none       | No       |
| 002 | Core Parsing          | completed   | 001        | No       |
| 003 | Config System         | completed   | 001        | Yes      |
| 004 | Output Formatting     | in-progress | 002        | No       |
| 005 | Search Commands       | not-started | 002,003,004| Yes      |
| ... | ...                   | ...         | ...        | ...      |

### Summary
- Total: 10 tasks
- Completed: 3
- In Progress: 1
- Not Started: 6

### Available to Start
- Task 005: Search Commands (dependencies met)
- Task 006: List Untranslated (dependencies met)
```

After showing the table, suggest which task to work on next if asked.
