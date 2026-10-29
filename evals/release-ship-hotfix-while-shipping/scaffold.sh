#!/bin/bash
# Release 1.1.0 (T-001, a feature) is shipped but not yet pushed or deployed:
# master has the Release 1.1.0 merge and the local tag v1.1.0,
# releases/1.1.0.md is shipping and there's no releases/next.md. A hotfix
# T-002, branched off master after that, is closed: releases/hotfix-T-002.md
# is open.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm
open_release_next

# T-001, closed into release/next.
work_branch task/T-001-add-dark-mode release/next
commit_on task/T-001-add-dark-mode src/theme.txt "Dark mode: on" "Add a dark theme"
sha=$(git rev-parse --short task/T-001-add-dark-mode)
git switch --quiet release/next
git merge --quiet --no-ff -m "Merge T-001 Add dark mode" task/T-001-add-dark-mode
git push --quiet origin release/next
git switch --quiet master
git push --quiet origin --delete task/T-001-add-dark-mode
git branch --quiet -D task/T-001-add-dark-mode
add_task done T-001 add-dark-mode title="Add dark mode" type=feature \
    branch=task/T-001-add-dark-mode "commits=[$sha]" \
    merge="$(git rev-parse --short release/next)" closed="$(date +%F)"
set_fields .pm/releases/next.md "tasks=[T-001]"
add_release_task_line next "T-001 Add dark mode (feature)"
pm_commit "Close T-001"

# Ship 1.1.0 locally, as release-ship would.
git merge --quiet --no-ff -m "Release 1.1.0" release/next
git tag -a v1.1.0 -m "Release 1.1.0"
git -C .pm mv releases/next.md releases/1.1.0.md
set_fields .pm/releases/1.1.0.md version=1.1.0 status=shipping \
    shipped="$(date -u +%Y-%m-%dT%H:%M:%SZ)" tag=v1.1.0 merge="$(git rev-parse --short master)"
set_fields .pm/tasks/done/T-001-add-dark-mode.md release=1.1.0
pm_commit "Ship 1.1.0"

# Hotfix T-002, closed.
hotfix=hotfix/T-002-fix-the-footer-typo
work_branch "$hotfix" master
commit_on "$hotfix" src/footer.txt "Copyright Sample notes. All rights reserved." "Fix the footer typo"
add_task done T-002 fix-the-footer-typo title="Fix the footer typo" type=hotfix priority=high \
    branch="$hotfix" "commits=[$(git rev-parse --short "$hotfix")]" closed="$(date +%F)"
add_release hotfix-T-002 kind=hotfix branch="$hotfix" "tasks=[T-002]"
add_release_task_line hotfix-T-002 "T-002 Fix the footer typo (hotfix)"
pm_commit "Close T-002"

snapshot_refs master release/next pm "$hotfix"
report_unchanged origin master
report_unchanged local release/next
report_unchanged origin release/next
report_cmd 'git log -1 --format="master-head: %s" master'
report_cmd '[ "$(git rev-parse master^1)" = "$(cat _eval/before/local-master)" ] && [ "$(git rev-parse master^2)" = "$(cat _eval/before/local-hotfix-T-002-fix-the-footer-typo)" ] && echo merged-hotfix-into-master || echo not-merged-hotfix-into-master'
report_cmd '[ "$(git rev-parse "v1.1.1^{commit}" 2>/dev/null)" = "$(git rev-parse master)" ] && echo tag-at-master || echo tag-not-at-master'
report_cmd 'git ls-remote --exit-code --tags origin v1.1.1 >/dev/null && echo tag-on-origin || echo tag-not-on-origin'
report_cmd 'git log --all --format=%s | grep -c "^Merge 1\.1\.1 into release/next" | sed "s/^/merge-into-next-commits: /"'
report_cmd 'git rev-parse -q --verify refs/heads/hotfix/T-002-fix-the-footer-typo >/dev/null && echo hotfix-branch-local || echo hotfix-branch-gone-locally'
report_cmd '[ "$(git ls-remote origin refs/heads/hotfix/T-002-fix-the-footer-typo | cut -f1)" = "$(cat _eval/before/origin-hotfix-T-002-fix-the-footer-typo)" ] && echo hotfix-branch-on-origin || echo hotfix-branch-not-on-origin'
report_cmd 'm=$(sed -n "s/^merge: //p" .pm/tasks/done/T-002-fix-the-footer-typo.md); [ -n "$m" ] && [ "$(git rev-parse -q --verify "$m^{commit}")" = "$(git rev-parse master)" ] && echo task-merge-is-release || echo task-merge-wrong'
report_cmd '[ -e .pm/releases/next.md ] && echo next-doc-present || echo next-doc-absent'
report_cmd '[ -e .pm/releases/hotfix-T-002.md ] && echo hotfix-doc-present || echo hotfix-doc-gone'
report_cmd 'git -C .pm log -1 --format="pm-head: %s"'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git rev-parse pm)" ] && echo pm-pushed || echo pm-not-pushed'
