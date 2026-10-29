#!/bin/bash
# Release 1.1.0 (T-001, a feature) is shipped but master and the tag
# v1.1.0 are not pushed yet: releases/1.1.0.md is shipping and there is no
# releases/next.md.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm
open_release_next

# T-001, closed into release/next.
task=task/T-001-add-dark-mode
work_branch "$task" release/next
commit_on "$task" src/theme.txt "Dark mode: on" "Add a dark theme"
sha=$(git rev-parse --short "$task")
git switch --quiet release/next
git merge --quiet --no-ff -m "Merge T-001 Add dark mode" "$task"
git push --quiet origin release/next
git switch --quiet master
git push --quiet origin --delete "$task"
git branch --quiet -D "$task"
add_task done T-001 add-dark-mode title="Add dark mode" type=feature \
    branch="$task" "commits=[$sha]" \
    merge="$(git rev-parse --short release/next)" closed="$(date +%F)"
set_fields .pm/releases/next.md "tasks=[T-001]"
add_release_task_line next "T-001 Add dark mode (feature)"
pm_commit "Close T-001"

# Ship 1.1.0, as release-ship would.
git merge --quiet --no-ff -m "Release 1.1.0" release/next
git tag -a v1.1.0 -m "Release 1.1.0"
git -C .pm mv releases/next.md releases/1.1.0.md
set_fields .pm/releases/1.1.0.md version=1.1.0 status=shipping \
    shipped="$(date -u +%Y-%m-%dT%H:%M:%SZ)" tag=v1.1.0 merge="$(git rev-parse --short master)"
set_fields .pm/tasks/done/T-001-add-dark-mode.md release=1.1.0
pm_commit "Ship 1.1.0"

snapshot_refs master release/next pm
report_unchanged local master
report_unchanged origin master
report_unchanged local release/next
report_unchanged origin release/next
report_unchanged local pm
report_unchanged origin pm
report_cmd 'git ls-remote --exit-code --tags origin v1.1.0 >/dev/null && echo tag-on-origin || echo tag-not-on-origin'
report_cmd '[ -e .pm/releases/next.md ] && echo next-doc-present || echo next-doc-absent'
