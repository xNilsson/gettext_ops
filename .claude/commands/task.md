# Start Working on Task

Read the task file `docs/tasks/$1.md` where $1 is the task ID (e.g., 001, 002, etc).

After reading the task file:

1. Use the TodoWrite tool to create a todo list based on the task's deliverables and acceptance criteria
2. Mark the first relevant todo as in_progress
3. Update the task file's status to "in_progress" if it's currently "not-started"
4. Add a progress log entry with today's date noting that work has started
5. Begin working on the task following the deliverables and implementation notes

If the task depends on other tasks that are not completed:
- Check the status of those tasks first by reading their files
- If dependencies are not complete, warn about this but proceed if user confirms

Remember to:
- Follow the implementation notes and API design in the task
- Write tests as you implement features
- Update the task's Progress Log section with notes as you work
- Use @doc and @spec for all public functions
- Run tests frequently with `mix test`
