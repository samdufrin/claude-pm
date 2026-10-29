# {{project}}: project docs

This folder, `.pm/`, is a git worktree of the orphan `pm` branch. It holds the project's tasks, releases, workflows and architecture notes, and reads the same from every code branch (it's gitignored there). The `pm` Claude Code plugin keeps it up to date: its skills commit and push the `pm` branch after every change.

**Run `/pm:status` first.** It shows the open release, the tasks in progress with their next step, the top of the backlog and any loose ends.

## What's here
- `workflows/`: how work is done here: how to check a change (`testing.md`) and how to release it (`release.md`). The pm skills read these and stop if a section they need isn't filled in.
- `architecture/`: how the system is built, one doc per area.
- `tasks/`: one file per task, `T-<n>-<slug>.md`. The folder shows its status: `backlog/` (proposed or ready), `active/` (being built, built or blocked), `done/` (merged).
- `releases/`: one file per release. `next.md` is the release being collected now; shipped releases are named by version (`1.1.0.md`); a hotfix waiting to ship is `hotfix-T-<n>.md`.

## Setup on a fresh clone
1. `claude plugin install pm@samduf --scope project` (once per person).
2. In Claude Code, run `/pm:docs-init`: it attaches this folder as `.pm/`.

Without Claude Code: `git fetch origin pm`, `git worktree add .pm pm`, and add `.pm/` to `.git/info/exclude`.

## How work flows
- `/pm:task-create` writes a task into `tasks/backlog/` (`--quick` for very small changes, `--hotfix` for an urgent fix to the released code); `/pm:task-harden` settles what it leaves open.
- `/pm:task-implement` builds it on a branch `task/T-<n>-<slug>` off `release/next` (a hotfix: `hotfix/T-<n>-<slug>` off the default branch).
- `/pm:task-close` merges it into `release/next` and moves the task to `done/`.
- `/pm:release-ship` merges `release/next` (or a hotfix) into the default branch and tags it; you push and deploy; `/pm:release-deployed` records the deploy and opens the next release.

## Read when
- [workflows/testing.md](workflows/testing.md): read when running or changing the project's checks, or starting its environment.
- [workflows/release.md](workflows/release.md): read when shipping, deploying or rolling back a release.
<!-- One line per doc in architecture/ and workflows/: "- [path](path): read when …". The pm skills add a line whenever they create a doc. -->
