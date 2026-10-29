#!/bin/bash
# An open release holding one done feature task, T-001 Add dark mode, merged
# into release/next. master then got a commit (pushed) that release/next
# lacks, so the release must refuse to ship until master is merged into it.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm
open_release_next

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

commit_on master src/home.txt "Welcome to Sample notes, your notes app." "Reword the home page"

snapshot_refs master release/next pm
report_unchanged local master
report_unchanged origin master
report_unchanged local release/next
report_unchanged origin release/next
report_unchanged local pm
report_unchanged origin pm
report_cmd 'git log --all --format=%s | grep -c "^Release " | sed "s/^/release-commits: /"'
report_cmd 'echo "tags: $(git tag | tr "\n" " ")"'
report_cmd '[ -f "$(git rev-parse --git-path MERGE_HEAD)" ] && echo merge-in-progress || echo no-merge-in-progress'
