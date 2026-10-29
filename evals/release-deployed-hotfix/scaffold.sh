#!/bin/bash
# Hotfix T-001 shipped as 1.0.1 (merged into master and into release/next,
# which is pushed), and the user has pushed master and v1.0.1. Its branch is
# still on origin and, in this clone, locally too (as on a teammate's machine
# that pulled it). releases/1.0.1.md is shipping and releases/next.md is open.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm
open_release_next

hotfix=hotfix/T-001-fix-the-footer-typo
work_branch "$hotfix" master
commit_on "$hotfix" src/footer.txt "Copyright Sample notes. All rights reserved." "Fix the footer typo"
add_task done T-001 fix-the-footer-typo title="Fix the footer typo" type=hotfix priority=high \
    branch="$hotfix" "commits=[$(git rev-parse --short "$hotfix")]" closed="$(date +%F)"
add_release hotfix-T-001 kind=hotfix branch="$hotfix" "tasks=[T-001]"
add_release_task_line hotfix-T-001 "T-001 Fix the footer typo (hotfix)"
pm_commit "Close T-001"

# Ship 1.0.1, as release-ship would.
git merge --quiet --no-ff -m "Release 1.0.1" "$hotfix"
git tag -a v1.0.1 -m "Release 1.0.1"
merge=$(git rev-parse --short master)
git switch --quiet release/next
git merge --quiet --no-ff -m "Merge 1.0.1 into release/next" master
git push --quiet origin release/next
git switch --quiet master
git -C .pm mv releases/hotfix-T-001.md releases/1.0.1.md
set_fields .pm/releases/1.0.1.md version=1.0.1 status=shipping \
    shipped="$(date -u +%Y-%m-%dT%H:%M:%SZ)" tag=v1.0.1 merge="$merge"
set_fields .pm/tasks/done/T-001-fix-the-footer-typo.md release=1.0.1 merge="$merge"
pm_commit "Ship 1.0.1"
git push --quiet origin master v1.0.1

snapshot_refs master release/next pm
report_unchanged local master
report_unchanged origin master
report_unchanged local release/next
report_unchanged origin release/next
report_cmd 'git -C .pm log --reverse --format="pm-new: %s" "$(cat _eval/before/local-pm)..pm"'
report_cmd 'git -C .pm rev-list --count "$(cat _eval/before/local-pm)..pm" | sed "s/^/new-pm-commits: /"'
report_cmd 'git -C .pm diff --quiet "$(cat _eval/before/local-pm)" pm -- releases/next.md && echo next-doc-unchanged || echo next-doc-changed'
report_cmd 'git ls-remote --exit-code --heads origin hotfix/T-001-fix-the-footer-typo >/dev/null && echo hotfix-branch-on-origin || echo hotfix-branch-gone-from-origin'
report_cmd 'git rev-parse -q --verify refs/heads/hotfix/T-001-fix-the-footer-typo >/dev/null && echo hotfix-branch-local || echo hotfix-branch-gone-locally'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git rev-parse pm)" ] && echo pm-pushed || echo pm-not-pushed'
report_cmd '[ -z "$(git -C .pm status --porcelain)" ] && echo pm-clean || echo pm-dirty'
