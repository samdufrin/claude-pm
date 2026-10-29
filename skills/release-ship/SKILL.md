---
name: release-ship
description: "Use only when the user asks to ship the open release or a hotfix: test-merges release/next (or the hotfix branch) into the default branch with the full check, commits Release <version>, tags v<version> locally, marks the release doc shipping and gives the push command. Never pushes the default branch or tags."
argument-hint: "[hotfix-T-043] [major|minor|patch]"
---

# Ship a release

Merges the open release (`release/next`) or a finished hotfix into the default branch, tags it, and records it in `.pm/releases/`. The user then pushes and deploys, and runs /pm:release-deployed.

Arguments (`$ARGUMENTS`), in any order, both optional:
- `hotfix-T-043` (or just `T-043`): ship that hotfix (`releases/hotfix-T-043.md`) instead of the open release.
- `major`, `minor` or `patch`: the version bump. Without it, the skill proposes one and asks.

Rules for the whole run:
- First read `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` in full. It is the source of truth for the layout, release docs, versions, git flow, test merges, workflow files, commit messages and asking.
- `${CLAUDE_PLUGIN_ROOT}` is not set inside Bash. Write it out as the literal path this skill shows, and pass every path to scripts as an argument, quoted.
- `<root>` is the project root (`git rev-parse --show-toplevel`), `<pm>` the path `pm-dir.sh` prints, `<default>` the default branch (conventions.md, Git flow). Run git with `git -C "<root>" …` or `git -C "<pm>" …`; never `cd` into `<pm>`.
- **Never push the default branch or any tag.** Never force-push, never move or recreate a tag, never resolve a merge conflict yourself, never stash or discard the user's changes (the one reset this skill runs, in step 6, restores a tree it verified clean itself).
- Edit `.pm/` files with the Edit or Write tool, never with `sed` or other commands that put text into a pattern.
- When a step says **stop**, end the run with a short report: what you found, what this run changed (before step 6: nothing), and the fix. If you switched branches, switch back to `<start>` first.

## 1. Locate and sync

1. `<root>`: `git rev-parse --show-toplevel`. `<pm>`: `sh "${CLAUDE_PLUGIN_ROOT}/scripts/pm-dir.sh" "<root>"`; if it exits 1, **stop**: "pm is not set up in this clone: run /pm:docs-init."
2. `sh "${CLAUDE_PLUGIN_ROOT}/scripts/pm-sync.sh" "<pm>"`. Exit 1, 2: **stop** and show its output (conventions.md, Exit codes). Note if it says `pm` has no upstream.
3. Whether there's an origin: `git -C "<root>" remote get-url origin`. `<default>`: as conventions.md says.

## 2. Check the workflow sections

Read `<pm>/workflows/testing.md` and `<pm>/workflows/release.md`. These must be defined: `## Full check` and `## Environment` in `testing.md` (the test merge starts the environment and runs the check); `## Deploy` and `## Rollback` in `release.md`. So must `## Conditional checks`, `## Security-sensitive paths` and `## Quick checks` in `testing.md` when they're present. A section is **undefined** when its heading is missing, it has no text under it, or it still contains a `<!-- fill in: … -->` comment; `None.` is defined. If any is undefined, **stop** and name each one by file and section (e.g. "`## Rollback` in `.pm/workflows/release.md` isn't filled in"). Nothing has changed.

## 3. Pick the release

1. Parse the arguments: a word like `hotfix-T-043` or `T-043` names a hotfix (`<id>` is `T-043`); `major`, `minor` or `patch` is `<bump>`. Ignore anything else.
2. The doc is `<pm>/releases/hotfix-<id>.md` for a hotfix, otherwise `<pm>/releases/next.md`. Read it.
   - It doesn't exist: **stop**. For a hotfix: there's no release doc for it; it's created when the hotfix is closed (`/pm:task-close <id>`). For a normal release: if a `releases/*.md` has `status: shipping`, a release is already shipping: push and deploy it, then run `/pm:release-deployed <version>`, which opens the next release; otherwise say `releases/next.md` is missing.
   - `status: deployed`: **stop**: deployed release docs are read-only.
   - `status: shipping`: **stop**: it's already shipped; push and deploy it, then run `/pm:release-deployed <version>`.
   - It must be `status: open`, with `kind: hotfix` for a hotfix and `kind: release` otherwise; else **stop** and say what's wrong.
3. `tasks` must list at least one task; if it's empty, **stop**: there's nothing to ship. Each listed task must have its file in `<pm>/tasks/done/` (`<id>-*.md`) with `status: done`; if one doesn't, **stop** and name it.
4. `<branch>` is the doc's `branch:` (`release/next`, or `hotfix/T-043-…`). For a hotfix, it must match the task's `branch:`.

## 4. Check the code checkout and bring branches up to date

1. Save the current branch as `<start>`: `git -C "<root>" symbolic-ref --quiet --short HEAD`. If that fails (detached HEAD), **stop** and ask the user to check out a branch.
2. `git -C "<root>" status --porcelain --untracked-files=all` must show no changes to tracked files (only `??` lines are allowed). Otherwise **stop**, list the changes, and ask the user to commit or stash them. Save the `??` lines as `<untracked-before>`.
3. With an origin: `git -C "<root>" fetch origin`. Then bring each of these up to date from origin, in this order: `<default>`; `<branch>`; and, for a hotfix whose `<pm>/releases/next.md` exists with `status: open`, `release/next` too. For each branch `<b>`:
   - It exists only on origin: `git -C "<root>" branch --track <b> origin/<b>`.
   - It exists only locally: fine (for `<default>`, that would be odd: **stop** and report it).
   - Both exist: if `git -C "<root>" merge-base --is-ancestor <b> origin/<b>` succeeds and they differ, it's behind: `git -C "<root>" switch <b>` then `git -C "<root>" merge --ff-only origin/<b>`. If `origin/<b>` is an ancestor of `<b>`, it's ahead or equal: fine. If neither is an ancestor of the other, they've diverged: **stop** and report it (never pull, rebase or reset).
   - It exists nowhere: **stop** and name it.
   Without an origin, each branch must exist locally.

## 5. Version and preflight

1. The current version `<latest>`: the highest tag `v<major>.<minor>.<patch>` reachable from `<default>`:
   ```sh
   git -C "<root>" tag --merged <default> --list 'v*' --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1
   ```
   With none, the current version is `0.0.0` (say so in the report).
2. **An earlier run that stopped halfway.** If `<latest>` exists, its commit (`git -C "<root>" rev-parse "<latest>^{commit}"`) has the subject `Release <latest version>`, and its second parent (`git -C "<root>" rev-parse "<latest>^2"`) is the tip of `<branch>` (`git -C "<root>" rev-parse <branch>`), then an earlier run merged and tagged this release but didn't record it (the doc is still `open`). Don't merge or tag again and don't ask: `<version>` is `<latest>` without the `v`, `<merge>` is `git -C "<root>" rev-parse --short "<latest>^{commit}"`, and `<shipped>` is its commit time in UTC, `TZ=UTC git -C "<root>" log -1 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format=%cd "<latest>^{commit}"`. Ignore any `<bump>` (say so). Go to step 7, and say in the report that this run finished an earlier one.
3. The proposed bump: for a hotfix, **patch**; otherwise **minor** if any of the release's tasks has `type: feature`, else **patch**. Never propose major.
4. If `<bump>` was given, use it. Otherwise ask one question with `AskUserQuestion`: "Ship this as which version?", listing the release's tasks with their types as the reason. Options: the proposed version, marked "(Recommended)" with the reason (e.g. "T-042 is a feature"); the other of minor or patch; and major. If `AskUserQuestion` isn't available (a headless `claude -p` run), ask the same question with the same numbered options in plain text as the last thing in your message and end your turn; carry on from here when the answer arrives.
5. `<version>`: the current version with `<bump>` applied (major: `X+1.0.0`; minor: `X.Y+1.0`; patch: `X.Y.Z+1`).
6. The tag must be new: if `git -C "<root>" rev-parse --verify --quiet refs/tags/v<version>` succeeds, or (with an origin) `git -C "<root>" ls-remote --tags origin v<version>` prints anything, **stop**: tag `v<version>` already exists and is never moved. Also **stop** if `<pm>/releases/<version>.md` exists.
7. A normal release needs the default branch already in `release/next`: if `git -C "<root>" merge-base --is-ancestor <default> release/next` fails, **stop**. The default branch has commits `release/next` lacks (usually a hotfix whose merge into `release/next` was skipped or conflicted). The fix: `git switch release/next`, `git merge --no-ff <default>`, resolve any conflict, run the full check, `git push origin release/next`, then rerun /pm:release-ship.
8. There must be something to merge: if `git -C "<root>" merge-base --is-ancestor <branch> <default>` succeeds, `<branch>` is already in the default branch: **stop** and report it.

Nothing has changed so far.

## 6. Test merge into the default branch

1. `git -C "<root>" switch <default>`.
2. `git -C "<root>" merge --no-ff --no-commit <branch>`.
3. **Conflict** (the merge exits non-zero): list the conflicting files with `git -C "<root>" diff --name-only --diff-filter=U`, **undo the merge** (below), switch back to `<start>`, and **stop**. Report the conflicting files, that nothing was committed, tagged or renamed and the release doc is still `open`, and the fix: on `<branch>`, run `git merge --no-ff <default>`, resolve the conflict, run the full check, push it (`git push origin <branch>`), then rerun /pm:release-ship with the same arguments.
4. **Checks**, on the merged result, from `<root>`:
   - Start the environment as `testing.md`'s `## Environment` says (nothing if it says `None.`).
   - Run every command in `## Full check`. It passes when it exits 0.
   - Then each line of `## Conditional checks` (if present), `- When <condition>: <command>`: list the changed files with `git -C "<root>" diff --name-only <default>...<branch>` and run the command if they meet the condition. When unsure, run it. Note each conditional check run or skipped, and why.
   - Then the tree must be as the merge left it: `git -C "<root>" diff --name-only` (changes since the merge staged everything) must print nothing, and `git -C "<root>" status --porcelain --untracked-files=all` must show no `??` line that isn't in `<untracked-before>`. Files changed or created by the checks count as a failing check; name them.
5. **A check fails:** note the failing command (or the files the checks changed) and the end of its output, **undo the merge**, switch back to `<start>`, and **stop**. Report the failing check and its output, that nothing was committed, tagged or renamed and the release doc is still `open`, and the fix: on `<branch>`, run `git merge --no-ff <default>` (resolving any conflict), fix the failure, run the full check, push it (`git push origin <branch>`), then rerun /pm:release-ship with the same arguments. Untracked files the checks created are left in place; list them so the user can remove them.
6. **Undo the merge:** `git -C "<root>" merge --abort`. If that fails (e.g. a check rewrote a merged file), run `git -C "<root>" reset --hard HEAD`: step 4.2 verified there were no changes to tracked files before the merge, so this only removes the merge. Say in the report which of the two ran. Then `git -C "<root>" status --porcelain --untracked-files=no` must print nothing.
7. **Everything passes:**
   ```sh
   git -C "<root>" commit -m "Release <version>"
   git -C "<root>" tag -a v<version> -m "Release <version>"
   ```
   Record `<merge>` (`git -C "<root>" rev-parse --short HEAD`) and `<shipped>` (`date -u +%Y-%m-%dT%H:%M:%SZ`). Don't push either.

From here on the release is shipped locally: don't stop before the release doc is recorded (step 8). Problems below are noted and reported.

## 7. Hotfix only: carry the fix into release/next, delete the branch

1. If `<pm>/releases/next.md` doesn't exist or its status isn't `open`, skip the merge: a normal release is shipping, and the next /pm:release-deployed recreates `release/next` from the default branch, which has the fix. Note it for the report. Also skip it if `release/next` already contains the release commit (`git -C "<root>" merge-base --is-ancestor <merge> release/next`, after a halfway run), but still push `release/next` if origin's copy differs.
2. Otherwise:
   ```sh
   git -C "<root>" switch release/next
   git -C "<root>" merge --no-ff <default> -m "Merge <version> into release/next"
   ```
   - On a conflict: list the files (`git -C "<root>" diff --name-only --diff-filter=U`), run `git -C "<root>" merge --abort`, and note it. The hotfix stays shipped. The report gives the fix: on `release/next`, `git merge --no-ff <default>`, resolve, push; until then /pm:release-ship refuses the next normal release.
   - Otherwise, with an origin, `git -C "<root>" push origin release/next` (`push -u` if it has no upstream). If the push is rejected, note the branch and git's message for the report (never force, pull or rebase).
3. `git -C "<root>" switch <default>`. If `<branch>` exists locally, delete it there only, now that `<default>` (checked out, and containing it) is HEAD: `git -C "<root>" branch -d <branch>`. Don't delete it on origin: /pm:release-deployed does that once the tag is pushed.
4. Switch back to `<start>` unless it was `<branch>` (then stay on `<default>` and say so in the report).

For a normal release, switch back to `<start>`.

## 8. Record the release in .pm/

1. `git -C "<pm>" mv releases/<doc file> releases/<version>.md` (`next.md` or `hotfix-<id>.md`).
2. In `releases/<version>.md`, set the frontmatter: `version: <version>`, `status: shipping`, `shipped: <shipped>`, `tag: v<version>`, `merge: <merge>`. Change the heading to `# Release <version>`. Replace the text under `## Rollback` with the `## Rollback` text of `workflows/release.md`, plus anything specific to this release (e.g. a production step that needs undoing). Keep everything else.
3. In each of its task files in `tasks/done/`, set `release: <version>`. For a hotfix, also set the task's `merge: <merge>` (the short SHA of the `Release <version>` merge commit on the default branch).
4. `sh "${CLAUDE_PLUGIN_ROOT}/scripts/pm-commit.sh" "<pm>" "Ship <version>"`. If it doesn't exit 0, put its output and the matching recovery in the report:
   - **Exit 1** (git failed, or the push was declined): check `git -C "<pm>" log -1 --format=%s` and `git -C "<pm>" status --porcelain`. If the last commit is `Ship <version>`, it's committed but not pushed: once the cause is fixed, `git -C "<pm>" pull --rebase && git -C "<pm>" push`. If not, the changes are still uncommitted in `.pm/`: once the cause is fixed, `git -C "<pm>" add -A && git -C "<pm>" commit -m 'Ship <version>' && git -C "<pm>" push`.
   - **Exit 2** (rebase conflict; the commit is local): `git -C "<pm>" pull --rebase`, resolve the files it lists, `git -C "<pm>" add <files>`, `git -C "<pm>" rebase --continue`, then `git -C "<pm>" push`.
   - **Exit 3** (origin's `pm` kept moving; the commit is local): `git -C "<pm>" pull --rebase && git -C "<pm>" push`.
   The code side is done either way; don't rerun /pm:release-ship for this.

## 9. Report

Keep it short:
- **Shipped:** `<version>` (the bump and why), the `Release <version>` merge commit `<merge>` on `<default>`, the tag `v<version>`, the tasks in it, and each conditional check run or skipped, and why. If this run finished a halfway one (step 5.2), say so.
- **Hotfix:** whether `<default>` was merged into `release/next` and pushed, or skipped because a release is shipping (the next /pm:release-deployed recreates `release/next` with the fix), or conflicted (with the fix); that the hotfix branch was deleted locally and stays on origin until /pm:release-deployed.
- **`.pm/`:** `releases/<version>.md` (status `shipping`), committed as `Ship <version>`; pushed, or not, with the recovery from step 8.4.
- **Production steps** from the release doc, if any.
- **Next:** the steps under `## Deploy` in `workflows/release.md`, then the exact push command for the default branch and the tag: `git push origin <default> v<version>`. Nothing was pushed to `<default>` or any tag. If other `v*` tags reachable from `<default>` aren't on origin yet (`git ls-remote --tags origin`), add them to the command.
- End with: "After the deploy, run /pm:release-deployed <version>."
