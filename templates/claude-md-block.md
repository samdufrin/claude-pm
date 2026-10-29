<!-- pm:start -->
## Project docs
Tasks, releases, workflows and architecture live in `.pm/`, a worktree of the orphan `pm` branch (gitignored here, the same on every branch). Start with `.pm/README.md`, or run `/pm:status`. Changes go through the `pm` plugin: `/pm:task-create`, `/pm:task-implement`, `/pm:task-close`, `/pm:release-ship`, `/pm:release-deployed`.
On a fresh clone: `claude plugin install pm@samduf --scope project`, then `/pm:docs-init` to attach `.pm/`.
<!-- pm:end -->
