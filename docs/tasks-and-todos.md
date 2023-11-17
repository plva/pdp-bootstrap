# Managing todos
- Todos are managed by adding a `todo:` to code, or if its longer, a `todo_start` with a `todo_end` tag
- You can also add todos in a `todo.md` markdown file
- Still need to decide whether they can be added in any file whatsoever, maintaining an exception-list of files/directories/patterns for todo files
	- Or if we specify file formats and allow-lists of directories that will be searched for todos
	- Alternatively, ask the user every time that they git commit whether to add the todo
- In the IssueService, every git commit should have a hook that checks to see whether a todo has been added or removed
	- If it's been added, amend the todo to give it an id (e.g. change `todo:` to `todo.12345:`) so it can be tracked in IssueService database
	- If it's been removed, close it out from the database (asking user whether it should be closed, deleted, etc--can default to a specific action)
	- todos can be nested in `todo_{start,end}` tags
		- in CodeGeneratorService, create a tool that auto-creates start/end tags in comments for relevant file types

