# pm conventions

The operating rules every pm skill follows. Read this whole file before acting. The task body format is in `task-format.md`, next to this file.

Throughout:
- `<pm>` is the path `pm-dir.sh` prints (normally `<project root>/.pm`).
- `<default>` is the project's default branch (see Git flow).
- Scripts are run as `sh ${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh <args>`. They get every path as an argument and print plain results.
- `T-042` stands for any task ID and `1.1.0` for any version.

## Templates and placeholders

Skills create files from `${CLAUDE_PLUGIN_ROOT}/templates/`, replacing every `{{name}}` placeholder. No `{{…}}` may be left in a written file.

| Template | Becomes | Placeholders |
|---|---|---|
| `readme.md` | `<pm>/README.md` | `{{project}}`: the project's name (from its README or folder name) |
| `testing.md` | `<pm>/workflows/testing.md` | none; replace each `<!-- fill in: … -->` comment whose answer the project's `CLAUDE.md` or `README` gives, and leave the rest |
| `release-workflow.md` | `<pm>/workflows/release.md` | none; as for `testing.md` |
| `task.md` | `<pm>/tasks/backlog/T-042-<slug>.md` (full task) | `{{id}}`, `{{title}}`, `{{type}}`, `{{priority}}`, `{{owner}}`, `{{date}}` (frontmatter); body placeholders (`{{goal}}`, `{{summary}}`, `{{decision_rows}}`, `{{open_questions}}`, `{{design_heading}}`, `{{design}}`, `{{tests}}`, `{{build_steps}}`, `{{acceptance}}`, `{{code_docs}}`, `{{pm_docs}}`, `{{out_of_scope}}`) are written per `task-format.md`; add more design sections (`## 5. …`) and renumber the ones after them as the task needs |
| `quick-task.md` | `<pm>/tasks/backlog/T-042-<slug>.md` (quick task) | `{{id}}`, `{{title}}`, `{{type}}`, `{{priority}}`, `{{owner}}`, `{{date}}`, `{{goal}}`, `{{summary}}`, `{{step_name}}`, `{{step}}`, `{{verify}}`, `{{acceptance}}`; add Build order steps if the change needs more than one |
| `release.md` | `<pm>/releases/next.md` or `<pm>/releases/hotfix-T-042.md` | `{{kind}}` (`release` or `hotfix`), `{{branch}}` (`release/next` or the hotfix branch), `{{opened}}` (UTC timestamp), `{{name}}` (`next` or `hotfix-T-042`) |
| `baseline-release.md` | `<pm>/releases/<version>.md` | `{{version}}` (no `v`), `{{default_branch}}`, `{{now}}` (UTC timestamp), `{{merge}}` (the default branch's HEAD, short SHA) |
| `claude-md-block.md` | inserted into the project's `CLAUDE.md` | none; see The CLAUDE.md block |

`{{owner}}` is `git config user.name`; `{{date}}` is the local date (see Timestamps). The slug is the title in lowercase, words joined by `-`, only `a-z`, `0-9` and `-`, at most 40 characters, cut at a word boundary.

## The `.pm/` layout

`.pm/` is a git worktree of the orphan branch `pm`, checked out at `<project root>/.pm/`. The `pm` branch holds nothing else. The folder is ignored on code branches (`.pm/` in `.gitignore`, and in `.git/info/exclude` so older branches ignore it too), so it reads the same from every branch.

```
.pm/
  README.md          the index: what's here, setup on a fresh clone, "run /pm:status first", and a "read when" line for every architecture and workflow doc
  architecture/      how the system is built (optional files, one per area)
  workflows/
    testing.md       how to check a change (see Workflow files)
    release.md       how a release is deployed and rolled back
  tasks/
    backlog/         proposal and ready tasks
    active/          in-progress, built and blocked tasks
    done/            done tasks
  releases/          one file per release
```

- Empty folders hold a `.gitkeep`.
- Every doc in `architecture/` and `workflows/` has a line under `README.md`'s `## Read when`: `- [path](path): read when …`. A skill that creates such a doc adds its line in the same commit.
- There is no decisions folder: a task records how a decision was made; workflow and architecture docs record the rules in force now.
- `.pm/` docs (other than task files) describe only accepted, merged work. They are edited at `/pm:task-close`, never while a task is being built.

## Task files

One file per task: `tasks/<folder>/T-042-<slug>.md`. The ID never changes; the folder shows the status.

### Frontmatter

```yaml
---
id: T-042
title: Shopping list
type: feature            # feature | fix | hotfix | chore
priority: normal         # high | normal | low
owner: Jane Doe          # git config user.name of whoever created or took it
status: proposal         # proposal | ready | in-progress | built | blocked | done
quick: false             # true for a quick task (and every hotfix)
created: 2026-10-28      # local date
branch: null             # set by task-implement: task/T-042-shopping-list or hotfix/T-042-…
release: null            # set by release-ship: 1.1.0
commits: []              # set by task-close: short SHAs on the branch, oldest first
merge: null              # set by task-close (release-ship for a hotfix): merge commit short SHA
closed: null             # set by task-close: local date
---
```

- Keys appear in this order. Unset values are `null` (or `[]` for `commits`). Lists are inline: `commits: [a1b2c3d, e4f5a6b]`.
- `type`: `feature` for new behaviour, `fix` for a bug fix, `chore` for anything else (refactors, dependencies, docs), `hotfix` for an urgent fix shipped on its own from the default branch. A hotfix is always quick, with `priority: high`.

### Status and folder

Status and folder always agree. Move a file with `git mv` (in `<pm>`) in the same commit that changes its `status`.

| status | folder | meaning |
|---|---|---|
| `proposal` | `backlog/` | written, with decisions or questions still to settle |
| `ready` | `backlog/` | nothing left to guess; can be built |
| `in-progress` | `active/` | being built on its branch |
| `built` | `active/` | every step done and verified; waiting for `/pm:task-close` |
| `blocked` | `active/` | a step is blocked or a critical or high security finding is unfixed |
| `done` | `done/` | merged into `release/next` (a hotfix: ready to ship) and accepted by the user |

A task is done when it's merged into `release/next`, or for a hotfix, when it's ready to ship. Running `/pm:task-close` is the user's acceptance; there's no separate review.

### Backlog order

By `priority` (`high`, then `normal`, then `low`); within a level, the lower ID first.

### Body

See `task-format.md`.

## Release docs

One file per release in `releases/`:
- `next.md`: the open normal release, created with `release/next`. Tasks are added as they close; it gets a version only at ship time.
- `hotfix-T-042.md`: a hotfix waiting to ship, created by `/pm:task-close` for the hotfix.
- `<version>.md` (no `v` prefix, e.g. `1.1.0.md`): a shipped release. `/pm:release-ship` renames `next.md` or `hotfix-T-042.md` to this with `git mv`.

```yaml
---
version: null            # set at ship: 1.1.0
kind: release            # release | hotfix | baseline
status: open             # open | shipping | deployed
branch: release/next     # or hotfix/T-043-…
opened: 2026-10-28T18:04:00Z   # UTC
shipped: null            # merge time, UTC
deployed: null           # UTC
tag: null                # v1.1.0
merge: null              # merge commit on the default branch, short SHA
tasks: []                # [T-042, T-045], appended by task-close
---
# Release <version, "next" or "hotfix-T-043">

## Tasks
<one line each: T-042 Shopping list (feature); "None yet." while empty>

## Production steps
<collected from each task's Outcome, one bullet per step naming its task; "None." while empty>

## Rollback
<at ship: the `## Rollback` text of workflows/release.md plus anything specific to this release>

## Notes
```

- **Status:** `open` (collecting tasks), `shipping` (merged and tagged locally, waiting for the user to push and deploy), `deployed`.
- At most one normal release is open at a time: `releases/next.md`. Between `/pm:release-ship` and `/pm:release-deployed` there is none, so a normal task can't be closed in that window. A hotfix can be open alongside it.
- A `baseline` doc (written by `/pm:docs-init` for a project that already had commits) is `status: deployed` from the start, with the baseline tag, the default branch's HEAD as `merge`, no tasks, and the note "The project's state when pm was adopted."
- **Deployed docs are read-only.** Before editing any release doc, check its `status`; if it's `deployed`, refuse and say so. Nothing else enforces this.

### Versions

Semantic versioning, tagged `v<version>` on the default branch (`git tag -a v1.1.0 -m "Release 1.1.0"`). The current version is the latest `v*` tag reachable from the default branch. At ship, propose the bump: **minor** if any task in the release has `type: feature`, otherwise **patch**; a hotfix is always patch. Never propose major; the user may choose it. Never move or recreate an existing tag: if the tag for the version already exists, stop and report it.

## Timestamps

- Release times (`opened`, `shipped`, `deployed`) are ISO 8601 in UTC to the second: `2026-10-28T18:04:00Z`, from `date -u +%Y-%m-%dT%H:%M:%SZ`. A time given in any other form (an argument like "yesterday 5pm" or one with an offset) is converted to that form.
- Task dates (`created`, `closed`, and the date in `## Outcome`'s `**Closed:**` line) are plain dates in the machine's local time zone, from `date +%F`, so they match the day the work happened.

## Locating `.pm/`

Run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/pm-dir.sh` from anywhere in the project (or pass the project path). It reads `git worktree list --porcelain` and prints the path of the worktree on `refs/heads/pm`, which works from the main checkout and from any linked worktree. If it exits 1, stop with: "pm is not set up in this clone: run /pm:docs-init." (`/pm:docs-init` itself is the exception: that's how it decides what to do.)

All `.pm/` git commands use `git -C <pm> …`. Never `cd` into `<pm>` and forget to come back, and never run code-branch commands there.

## Syncing `.pm/`

- **Before reading anything you'll act on**, run `pm-sync.sh <pm>`: it runs `git pull --rebase` when `pm` has an upstream. A read-only skill (`/pm:status`) runs `git -C <pm> fetch` instead and reports how far behind it is.
- **After each logical change** (a new task, a status move, a step marked done, a release update), run `pm-commit.sh <pm> "<message>"`. It stages everything in `<pm>`, commits, rebases onto the upstream and pushes. If the push is rejected because someone pushed `pm` in between, it rebases and pushes again, 3 pushes in all. It never forces.
- One commit per logical change, with one message from the list below. Don't batch unrelated changes into one commit, and don't leave changes in `<pm>` uncommitted when a skill ends.

### Exit codes

| Code | `pm-sync.sh` | `pm-commit.sh` | What the skill does |
|---|---|---|---|
| 0 | synced, or no upstream (prints `not synced: pm has no upstream`) | committed and pushed, nothing to commit, or no upstream (prints `not pushed: no upstream`) | carry on; with no upstream, say once in the report that `.pm/` changes weren't pushed |
| 1 | not a pm worktree, uncommitted changes in `<pm>` (refused with or without an upstream: they're left over from an interrupted run and must not be built on or committed blindly), or git failed (network, permissions) | not a pm worktree, git failed, or the push was declined for a reason other than someone pushing first (e.g. a server hook) | stop and show the script's message |
| 2 | the rebase conflicted; it was aborted and the conflicting files are listed after `conflict:` | same, with the commit still local | stop and report the conflicting files (task IDs have their own handling, below) |
| 3 | n/a | all 3 pushes were rejected because origin's `pm` kept moving; the commit stays local | stop and say to rerun the skill |

With no `origin` remote, or no upstream on `pm`, the scripts commit without pushing. `pm-commit.sh` never sets an upstream: only `/pm:docs-init` does, with `git -C <pm> push -u origin pm`.

## Commit messages

One short imperative subject line: no body, no trailer, no co-author line, no ticket prefix. `.pm/` commits use exactly these forms:

| When | Message |
|---|---|
| a task is created | `Add T-042 Shopping list` |
| a task is renumbered after a collision | `Renumber T-042 to T-043` |
| a hardening pass settles something | `Harden T-042: <what it settled>` |
| a task is started | `Start T-042` |
| a build step is done | `Finish step 3 of T-042` |
| a task is built | `Finish T-042` |
| a task is blocked | `Block T-042` |
| a task is closed | `Close T-042` |
| a release is shipped | `Ship 1.1.0` |
| a release is deployed | `Deploy 1.1.0` |
| a new release is opened | `Open the next release` |
| `.pm/` is created | `Set up pm docs` |

Code commits:
- a build step: a one-line imperative description of what the step does (`Add the shopping list page`);
- the task's code-doc edits: `Update docs for T-042`;
- merging a task: `Merge T-042 <title>`;
- shipping: `Release 1.1.0`;
- a hotfix into `release/next`: `Merge 1.0.1 into release/next`;
- the project setup on the default branch: `Set up pm`.

## Task IDs

- An ID is `T-<n>` with `n` zero-padded to at least 3 digits: `T-001`, `T-042`, `T-1203`. The file is `T-042-<slug>.md`.
- `next-task-id.sh <pm>` prints the next free ID: the highest number in `tasks/*/T-*.md` plus 1 (`T-001` when there are none).
- `/pm:task-create` runs it right after syncing, writes the file, and commits and pushes it at once with `pm-commit.sh`, so the ID is claimed as soon as possible. Then it checks for a collision:
  - **Different slug** (after the commit, `tasks/` holds another `T-042-*.md` that the rebase brought in): the other file reached origin first and keeps the ID. Run `next-task-id.sh` again, `git -C <pm> mv` your file to the new ID, change `id:` and the `# T-…` heading, and commit `Renumber T-042 to T-043`. Check again, until there's no collision. Nobody can have referred to the new ID yet.
  - **Same filename** (`pm-commit.sh` exits 2 with a conflict on that one file, its rebase already aborted): undo your commit with `git -C <pm> reset HEAD~1` (a mixed reset, so the file is left untracked and nothing stays staged), move your file out of `<pm>` (to a temporary path) so the tree is clean, run `pm-sync.sh`, get a new ID, write the file back under it with the new `id:` and heading, and commit again. A conflict on any other file is a normal exit 2: stop and report.
- The report names the final ID, and says it was renumbered if it was.

## Git flow

### The default branch

Read it from `git symbolic-ref --short refs/remotes/origin/HEAD` (minus the `origin/` prefix). If that fails, use `master` if it exists locally, then `main`.

### Branches

| Branch | Comes off | Merges into | Created by |
|---|---|---|---|
| `release/next` | the default branch | the default branch, at ship | `/pm:docs-init`, then `/pm:release-deployed` |
| `task/T-042-<slug>` | `release/next` | `release/next`, at close | `/pm:task-implement` |
| `hotfix/T-042-<slug>` | the default branch | the default branch, at ship (then the default branch into `release/next`) | `/pm:task-implement` |

- `release/next` always exists, except between `/pm:release-ship` and `/pm:release-deployed`.
- Every merge of one branch into another uses `git merge --no-ff`. Never squash, never fast-forward such a merge, never rebase a code branch, so the commits a task records stay reachable. (Bringing a local branch up to its own copy on origin is the one fast-forward: see Starting from origin.)

### Test merges

Merging a task at close and merging a release or hotfix at ship are test merges:
1. Check out the target branch and run `git merge --no-ff --no-commit <branch>`.
2. If it conflicts, list the conflicting files (`git diff --name-only --diff-filter=U`), run `git merge --abort`, and stop.
3. Otherwise run the full check and the conditional checks that apply (see Workflow files) on the merged result, with the environment started as `## Environment` says.
4. If any check fails, run `git merge --abort` and stop.
5. Only if both succeed, commit (`git commit -m "<message>"`), and for a release, tag.

On a stop, nothing is committed, tagged, renamed or moved: the task stays in `active/`, the release doc stays `open`. The report gives the conflicting files or the failing check, and the fix: on the branch being merged, `git merge --no-ff <target branch>`, resolve any conflict, push it, and rerun the skill. Skills never resolve merge conflicts themselves.

A normal release is shipped only when the default branch is already in `release/next` (`git merge-base --is-ancestor <default> release/next`); if not, stop with that same fix (merge the default branch into `release/next`).

### Hotfixes

`/pm:task-close` closes a hotfix without merging it and creates its release doc. `/pm:release-ship hotfix-T-043` test-merges the hotfix branch into the default branch and tags it, then merges the default branch into `release/next` (`git merge --no-ff <default> -m "Merge <version> into release/next"`) and pushes `release/next`. It skips that second merge when `releases/next.md` doesn't exist or isn't `open` (a release is shipping; the next `/pm:release-deployed` recreates `release/next` from the default branch, which has the fix). If the second merge conflicts, it aborts it and reports, leaving the hotfix shipped, with the fix: on `release/next`, `git merge --no-ff <default>`, resolve, and push. The hotfix branch is then deleted locally but kept on origin until `/pm:release-deployed` sees the tag there.

### Pushing

- When there's an `origin`, push each work branch (`task/*`, `hotfix/*`, `release/next`) right after committing or merging on it: `git push -u origin <branch>` the first time, `git push origin <branch>` after that. This lets work started on one machine resume on another.
- Never `--force`, in any form, on any branch.
- A rejected code push (someone else pushed that branch first) stops the skill: name the branch and show git's message. Local commits stay. Never pull or rebase a code branch to get past it.
- Deleting a merged task branch: `git branch -d <branch>`, plus `git push origin --delete <branch>` when it exists on origin.
- **Never push the default branch or tags.** Pushing the default branch can deploy, and a tag pushed before its branch points at an undeployed commit. Where they need pushing, the report ends with the exact command, e.g. `git push origin main v1.1.0`.
- With no `origin`, everything works locally; the report says once that nothing was pushed.

### Starting from origin

Before acting on a work branch (`release/next`, a task or hotfix branch, the default branch at ship), run `git fetch origin`. If the branch exists only on origin, check it out with tracking (`git switch --track origin/<branch>`). If the local branch is behind origin, fast-forward it (`git merge --ff-only origin/<branch>`). If the two have diverged, stop and report it.

### Clean checkout

Before switching branches, run `git status --porcelain` in the code checkout (ignore `.pm/`, which is excluded anyway). If there are uncommitted changes, stop and ask the user to commit or stash them. Also stop on a detached HEAD. Never stash, reset or discard the user's changes.

## Workflow files

Skills hold the process; each project's `workflows/testing.md` and `workflows/release.md` hold its facts. Never guess a command, and never skip a step because its section is undefined.

### Sections

| File | Required | Optional |
|---|---|---|
| `workflows/testing.md` | `## Full check`, `## Environment` | `## Conditional checks`, `## Security-sensitive paths`, `## Quick checks` |
| `workflows/release.md` | `## Deploy`, `## After deploy`, `## Rollback` | none |

- `## Full check`: a command block, run in full every time a skill runs the full check. It passes when it exits 0.
- `## Environment`: the commands that start what the checks need, or `None.`
- `## Deploy`: what the user does to deploy a shipped release (starting with pushing the default branch and the tag).
- `## After deploy`: checks and commands once the deploy has finished; shown to the user as a checklist.
- `## Rollback`: how to go back to the previous release.
- `## Quick checks`: fast commands for checking one step while building; never a substitute for the full check.

### Defined and undefined

A section is **undefined** when its heading is missing, it's empty, or it still contains a `<!-- fill in: … -->` comment. A section that says `None.` is defined. An optional section that's absent means none; one that's present but undefined blocks like a required one.

After syncing and before changing anything, a skill checks every section it uses. If one is undefined, it stops and names each undefined file and section (e.g. "`## Full check` in `.pm/workflows/testing.md` isn't filled in"). The task, release doc and branches stay as they were.

| Skill | Sections it needs |
|---|---|
| `/pm:task-implement` | `testing.md`: `## Full check`, `## Environment` |
| `/pm:task-close` | `testing.md`: `## Full check` (not for a hotfix, which merges nothing) |
| `/pm:release-ship` | `testing.md`: `## Full check`; `release.md`: `## Deploy`, `## Rollback` |
| `/pm:release-deployed` | `release.md`: `## After deploy` |

The same skills also check the optional sections of those files when they're present. `/pm:docs-init`, `/pm:status`, `/pm:task-create` and `/pm:task-harden` don't block; `/pm:status` lists undefined sections under loose ends.

### Conditional checks

`## Conditional checks` is a list of lines:

```markdown
- When <condition>: <command>
```

e.g. `- When the diff touches web/ or tests/browser/: npm run test:browser`. Wherever a skill runs the full check (the baseline and the last step of `/pm:task-implement`, and the test merges of `/pm:task-close` and `/pm:release-ship`), it runs `## Full check` every time, then each conditional check whose condition the diff meets. The diff is the files the change touches compared with its base: on the task branch, `git diff --name-only <base>...HEAD`; during a test merge (where HEAD is the target), `git diff --name-only <target>...<branch being merged>`. `<base>` is `release/next` for a task and the default branch for a hotfix or a release. When unsure whether a condition applies, run the check. The report names each conditional check run or skipped, and why.

### Security-sensitive paths

`## Security-sensitive paths` is a list of path prefixes:

```markdown
- src/auth/
- config/permissions.yml
```

A changed file (`git diff --name-only <base>...HEAD`) matches if its path starts with one of them. A quick task whose diff touches a matching path gets a security audit of the whole diff; with no such section, quick tasks get none. The report says whether the audit ran and which paths triggered it.

## The CLAUDE.md block

`/pm:docs-init` inserts `templates/claude-md-block.md` into the project's `CLAUDE.md`, markers included, after the file's first paragraph: the first block of text lines that aren't headings, ending at the next blank line (so a block goes below a title and its opening sentence, never between them). If the file has no such paragraph, append the block at the end; if there's no `CLAUDE.md`, the block is the whole new file. Between `<!-- pm:start -->` and `<!-- pm:end -->` it belongs to pm: if the markers are already there, replace what's between them instead of inserting a second block. Leave everything else in `CLAUDE.md` alone.

## Asking the user

- Every question uses `AskUserQuestion`, with at most 4 questions per call, the recommended option first marked "(Recommended)" with a one-line reason.
- When `AskUserQuestion` isn't available (a headless `claude -p` run), ask the same question, with the same options numbered and the recommendation marked, in plain text as the last thing in your message, and end your turn. Carry on from that point when the answer arrives.
- Never ask what the task file, the `.pm/` docs or the code already answer.

## Reports

Every skill ends with a short report: what changed (files, branches, commits), anything not pushed and why, anything that needs the user, and the next command to run. When the default branch or a tag needs pushing, the report ends with the exact push command.
