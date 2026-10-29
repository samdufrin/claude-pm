#!/bin/bash
# A project with pm set up and work in flight: release 1.3.2 deployed, an open
# release holding a done feature task (so it would ship as 1.4.0), an active
# task halfway through its build order on a pushed branch, and four backlog
# tasks whose priority/ID order differs from their ID order. A teammate then
# pushes one more commit to origin's pm, so the workspace's .pm/ is 1 commit
# behind. Nothing may change: no file, no commit, no push, no pull.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm

# A later release, 1.3.2, already deployed.
commit_on master src/about.txt "About Sample notes." "Add the about page"
git tag -a v1.3.2 -m "Release 1.3.2"
git push --quiet origin v1.3.2
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
add_release 1.3.2 version=1.3.2 status=deployed shipped="$now" deployed="$now" tag=v1.3.2
pm_commit "Deploy 1.3.2"

open_release_next

# The open release holds one done feature task.
add_task done T-006 add-tags-to-notes title="Add tags to notes" type=feature closed="$(date +%F)"
set_fields .pm/releases/next.md "tasks=[T-006]"
add_release_task_line next "T-006 Add tags to notes (feature)"

# The backlog: expected order T-003 (high), T-001, T-004 (normal), T-002 (low).
add_task backlog T-001 show-word-counts title="Show word counts" type=feature
add_task backlog T-002 add-a-dark-theme title="Add a dark theme" type=feature priority=low status=proposal
add_task backlog T-003 export-notes-as-text title="Export notes as text" type=feature priority=high
add_task backlog T-004 sort-notes-by-date title="Sort notes by date" type=feature status=proposal

# An active task: step 1 done, step 2 next.
work_branch task/T-005-add-the-search-box release/next
commit_on task/T-005-add-the-search-box src/search.txt "Search box" "Add the search box"
add_task active T-005 add-the-search-box title="Add the search box" type=feature \
    status=in-progress branch=task/T-005-add-the-search-box
f=.pm/tasks/active/T-005-add-the-search-box.md
awk '{ print } /^1\. \*\*/ { print "2. **Wire up the search index.** Index every note in `src/search.txt`. **Verify:** `sh check.sh` passes." }' "$f" > "$f.tmp"
mv "$f.tmp" "$f"
pm_commit "Add the sample tasks"

# A teammate pushes to pm; the workspace doesn't fetch it.
other=$(second_clone teammate)
git -C "$other" switch --quiet pm
printf '\nTeammate note.\n' >> "$other/README.md"
git -C "$other" commit --quiet -am "Note from a teammate"
git -C "$other" push --quiet origin pm

snapshot_refs master release/next pm
report_unchanged local pm
report_unchanged origin pm
report_unchanged local master
report_unchanged local release/next
report_cmd '[ -z "$(git status --porcelain)" ] && [ -z "$(git -C .pm status --porcelain)" ] && echo no-files-changed || echo files-changed'
