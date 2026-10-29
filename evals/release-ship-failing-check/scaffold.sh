#!/bin/bash
# An open release holding one done feature task, T-001 Add dark mode, merged
# into release/next. Its branch also broke check.sh (the full check,
# `sh check.sh`), which now exits 1, so the release's test merge fails.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm
open_release_next

task=task/T-001-add-dark-mode
work_branch "$task" release/next
commit_on "$task" src/theme.txt "Dark mode: on" "Add a dark theme"
commit_on "$task" check.sh '#!/bin/sh
echo "theme check failed: src/theme.txt has no light mode" >&2
exit 1' "Check the theme file"
commits="$(git log --reverse --format=%h release/next.."$task" | paste -sd, - | sed 's/,/, /g')"
git switch --quiet release/next
git merge --quiet --no-ff -m "Merge T-001 Add dark mode" "$task"
git push --quiet origin release/next
git switch --quiet master
git push --quiet origin --delete "$task"
git branch --quiet -D "$task"
add_task done T-001 add-dark-mode title="Add dark mode" type=feature \
    branch="$task" "commits=[$commits]" \
    merge="$(git rev-parse --short release/next)" closed="$(date +%F)"
set_fields .pm/releases/next.md "tasks=[T-001]"
add_release_task_line next "T-001 Add dark mode (feature)"
pm_commit "Close T-001"

snapshot_refs master release/next pm
report_unchanged local master
report_unchanged origin master
report_unchanged local release/next
report_unchanged local pm
report_unchanged origin pm
report_cmd 'git log --all --format=%s | grep -c "^Release " | sed "s/^/release-commits: /"'
report_cmd 'echo "tags: $(git tag | tr "\n" " ")"'
report_cmd '[ -f "$(git rev-parse --git-path MERGE_HEAD)" ] && echo merge-in-progress || echo no-merge-in-progress'
report_cmd '[ -e .pm/releases/1.1.0.md ] && echo version-doc-present || echo version-doc-absent'
