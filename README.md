# pm

A Claude Code plugin for markdown project management. A project's tasks, releases, workflows and architecture docs live as markdown files on an orphan git branch, `pm`, checked out at `.pm/` in the project root. Any agent or teammate can pick up work from those files alone. There's no tracker, no wiki and no pull requests.

`.pm/` is gitignored on code branches, so it reads the same whichever branch you're on. The skills commit and push the `pm` branch themselves.

## Install

```sh
claude plugin marketplace add samdufrin/claude-pm
claude plugin install pm@samduf
```

That installs it for you, in every project. To share it with a project's team, use project scope: `/pm:docs-init` commits a `.claude/settings.json` that names the `samduf` marketplace and enables `pm@samduf`. Claude Code doesn't install it from that alone, so each person runs this once in their clone:

```sh
claude plugin install pm@samduf --scope project
```

The plugin has no version number: every commit pushed to this repo is the new version. The project settings turn on auto-update for the marketplace, so changes arrive on their own. For a user-scope install, turn on auto-update for `samduf` in `/plugin`, or run `claude plugin marketplace update samduf`.

**Trust.** An update reaches every installer automatically, and the skills run git and the project's check commands on your machine. So this repo is pushed to only with two-factor authentication, and `master` is a protected branch. A project that would rather pin a version can set `ref` (a branch or tag of this repo) on the marketplace's source in its `.claude/settings.json`, and turn `autoUpdate` off:

```json
"extraKnownMarketplaces": {
  "samduf": {
    "source": { "source": "github", "repo": "samdufrin/claude-pm", "ref": "<tag or branch>" },
    "autoUpdate": false
  }
}
```

A marketplace source takes `ref` but not `sha`, so to pin an exact commit, pin a tag or branch you trust not to move.

## Commands

| Command | What it does |
|---|---|
| `/pm:docs-init [baseline-version]` | Sets pm up in a project, or attaches `.pm/` in a fresh clone of a project that already uses it. |
| `/pm:status` | Shows where things stand: the open release, tasks in progress and their next step, the top of the backlog, loose ends. Read-only. |
| `/pm:task-create [--quick \| --hotfix] <description>` | Interviews you, then writes a task to the backlog. `--quick` writes a short task with no interview, for very small changes. `--hotfix` writes the same short task for an urgent fix to released code. |
| `/pm:task-harden <id> [--defer-decisions]` | Finds and settles, in up to five passes, whatever an implementer would have to guess. `--defer-decisions` takes Claude's recommendation instead of asking. |
| `/pm:task-implement <id>` | Asks everything up front, then builds the task unattended on its own branch, step by step, with review, checks, a security audit and a manual acceptance checklist. |
| `/pm:task-close <id>` | Your acceptance. Merges the task into `release/next` after the full check, records its outcome and adds it to the open release. A hotfix isn't merged here; it gets its own release doc. |
| `/pm:release-ship [hotfix-T-043] [major\|minor\|patch]` | Merges the open release (or a hotfix) into the default branch after the full check, tags it locally and gives you the push command. |
| `/pm:release-deployed [version] [deploy-time]` | After you push and deploy: marks the release deployed and opens the next one. |

A task goes create → harden → implement → close, each in its own session. The task file is the only thing passed between them. `<id>` is `T-042`, or just `42`.

## The `.pm/` layout

```
.pm/
  README.md            the index: start here
  architecture/        how the system is built
  workflows/
    testing.md         how to check a change
    release.md         how a release reaches users
  tasks/
    backlog/           proposal, ready
    active/            in-progress, built, blocked
    done/              done
  releases/            next.md (the open release), hotfix-T-043.md, 1.1.0.md…
```

A task is one file, such as `tasks/backlog/T-042-shopping-list.md`. Its ID never changes. The folder it's in shows its status, and the skills move it.

Every project fills in its two workflow files. The skills hold the process; these hold the project's facts.

- `testing.md` needs `## Full check` (the command that runs every check) and `## Environment` (how to start what the checks need, or `None.`). Optional: `## Conditional checks`, `## Security-sensitive paths`, `## Quick checks`.
- `release.md` needs `## Deploy`, `## After deploy` and `## Rollback`.

A section is undefined while its heading is missing, it's empty or it still holds a `fill in` comment. A skill that needs an undefined section stops and names it, before changing anything.

## Git flow

- `task/T-042-shopping-list` comes off `release/next` and merges back into it at `/pm:task-close`.
- `release/next` always exists. `/pm:release-ship` merges it into the default branch and tags it `vX.Y.Z`.
- `hotfix/T-043-…` comes off the default branch and ships on its own as a patch release.
- Every merge is `--no-ff`. Nothing is squashed or fast-forwarded, so the commits a task records stay reachable.

The skills push `pm` and the work branches (`task/*`, `hotfix/*`, `release/next`), so a task started on one machine can be resumed on another. They never push the default branch or tags: pushing those may deploy, so you do it. The report ends with the exact command, for example `git push origin main v1.1.0`. Nothing is ever force-pushed.

## Setup

**New project.** On the default branch, with a clean checkout, run `/pm:docs-init`, optionally with the version the current state should be tagged as (`/pm:docs-init 1.0.0`). It creates the `pm` branch and `.pm/`, commits `Set up pm` on the default branch (the `.gitignore` line, a short block in `CLAUDE.md` and `.claude/settings.json`), tags the baseline, opens `release/next`, and pushes `pm` and `release/next`. Then fill in the two workflow files, and push the default branch and the tag yourself.

**Fresh clone.** Run `claude plugin install pm@samduf --scope project`, then `/pm:docs-init`. It finds the `pm` branch on origin and attaches it at `.pm/` without committing anything.

## Requirements

- git 2.42 or later (for `git worktree add --orphan`).
- A POSIX `sh`. The scripts are plain `sh`.
- `/pm:docs-init` merges `.claude/settings.json` with `python3` or `jq` when either is installed, and otherwise edits it directly.

## Developing the plugin

Every push to this repo reaches every user, so try a change locally first:

```sh
claude --plugin-dir /path/to/claude-pm
```

Run `/reload-plugins` in that session after editing a skill. Before pushing, check the manifests:

```sh
claude plugin validate .
```

The eval suite in `evals/` runs the skills against scripted repos and grades the results:

```sh
claude plugin eval . --scaffold --trust-plugin --ablation none -j 4 --allow-tools Bash Read Write Edit Glob Grep Skill
```

It needs a machine where Claude Code can sandbox Bash.

This is a personal tool, shared as is. Issues and pull requests aren't accepted. Fork it if you want it to work differently.

## License

MIT. See `LICENSE`.
