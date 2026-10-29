#!/bin/bash
# Release 1.1.0 (T-001, a feature) is shipped, and the user has pushed
# master and the tag v1.1.0 (and deployed): releases/1.1.0.md is shipping,
# there is no releases/next.md, and release/next is still the shipped one.
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
git push --quiet origin master v1.1.0

snapshot_refs master release/next pm
report_unchanged local master
report_unchanged origin master
report_cmd 'git -C .pm log --reverse --format="pm-new: %s" "$(cat _eval/before/local-pm)..pm"'
report_cmd '[ "$(git rev-parse release/next)" = "$(git rev-parse master)" ] && echo next-at-master || echo next-not-at-master'
report_cmd '[ "$(git ls-remote origin refs/heads/release/next | cut -f1)" = "$(git rev-parse release/next)" ] && echo next-pushed || echo next-not-pushed'
report_cmd 'git rev-parse --abbrev-ref "release/next@{upstream}" 2>/dev/null | sed "s/^/next-upstream: /"'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git rev-parse pm)" ] && echo pm-pushed || echo pm-not-pushed'
report_cmd '[ -z "$(git -C .pm status --porcelain)" ] && echo pm-clean || echo pm-dirty'
report_cmd 'grep -l "{{" .pm/releases/*.md >/dev/null 2>&1 && echo placeholders-left || echo no-placeholders'
