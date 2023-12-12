# Info

Helper scripts and tools for starting up a dev environment.

- Manages tmux sessions, creating them if they don't exist, and setting up several windows in each.
    - Changes dir to a certain directory for a project/dev env
    - Creates multiple windows with certain files
    - Fills caches, loads functions, sets up nvim config as needed
    - Starts background process manager for starting any servers or services
    - Sets up dashboards/etc
## Help
- Should create a helper window that provides information for each dev environment tmux session that's started

# todo
- workflow for managing multiple git repos at once


# todo now
- set up initial tmux sessions
- create script for setting up tmux sessions
- figure out how to send a command to a different session/terminal/pane/window

```
# working on ideas
tmux new -s ideas

# copying over config files (?) and installing dependencies
# bootstrapping the environment
tmux new -s bootstrap

# setting up cli tools and aliases
tmux new -s cli-tools

# dev bootstrap
tmux new -s dev-boot

# todo
tmux new -s todo
```

```
tmux new -s ideas

tmux new -s bootstrap

tmux new -s cli-tools

tmux new -s dev-boot

tmux new -s todo
```
