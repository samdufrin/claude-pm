#!/bin/bash
# pm set up at v1.0.0 with an open release holding one done feature task,
# T-001 Add dark mode, already merged into release/next and pushed.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm
open_release_next

work_branch task/T-001-add-dark-mode release/next
commit_on task/T-001-add-dark-mode src/theme.txt "Dark mode: on" "Add a dark theme"
sha=$(git rev-parse --short task/T-001-add-dark-mode)
git switch --quiet release/next
git merge --quiet --no-ff -m "Merge T-001 Add dark mode" task/T-001-add-dark-mode
git push --quiet origin release/next
git switch --quiet master
git branch --quiet -d task/T-001-add-dark-mode
git push --quiet origin --delete task/T-001-add-dark-mode
add_task done T-001 add-dark-mode title="Add dark mode" type=feature \
    branch=task/T-001-add-dark-mode "commits=[$sha]" \
    merge="$(git rev-parse --short release/next)" closed="$(date +%F)"
set_fields .pm/releases/next.md "tasks=[T-001]"
add_release_task_line next "T-001 Add dark mode (feature)"
pm_commit "Close T-001"

snapshot_refs master release/next pm
report_unchanged origin master
report_unchanged origin release/next
report_cmd 'git log -1 --format="master-head: %s" master'
report_cmd '[ "$(git rev-list --parents -n 1 master | wc -w)" = 3 ] && echo master-head-is-merge || echo master-head-not-merge'
report_cmd '[ "$(git rev-parse master^1)" = "$(cat _eval/before/local-master)" ] && [ "$(git rev-parse master^2)" = "$(cat _eval/before/local-release-next)" ] && echo merged-next-into-master || echo not-merged-next-into-master'
report_cmd '[ "$(git rev-parse "v1.1.0^{commit}" 2>/dev/null)" = "$(git rev-parse master)" ] && echo tag-at-master || echo tag-not-at-master'
report_cmd '[ "$(git cat-file -t v1.1.0 2>/dev/null)" = tag ] && echo tag-annotated || echo tag-not-annotated'
report_cmd 'git ls-remote --exit-code --tags origin v1.1.0 >/dev/null && echo tag-on-origin || echo tag-not-on-origin'
report_cmd 'm=$(sed -n "s/^merge: //p" .pm/releases/1.1.0.md); [ -n "$m" ] && [ "$(git rev-parse -q --verify "$m^{commit}")" = "$(git rev-parse master)" ] && echo doc-merge-is-release || echo doc-merge-wrong'
report_cmd '[ -e .pm/releases/next.md ] && echo next-doc-present || echo next-doc-gone'
report_cmd 'git -C .pm log -1 --format="pm-head: %s"'
report_cmd 'git -C .pm rev-list --count "$(cat _eval/before/local-pm)..pm" | sed "s/^/new-pm-commits: /"'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git rev-parse pm)" ] && echo pm-pushed || echo pm-not-pushed'
report_cmd '[ -z "$(git -C .pm status --porcelain)" ] && echo pm-clean || echo pm-dirty'
