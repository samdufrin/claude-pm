#!/bin/bash
# pm set up at v1.0.0 with an open (empty) release, and a closed hotfix T-001
# whose branch fixes the footer typo: releases/hotfix-T-001.md is open.
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

snapshot_refs master release/next pm "$hotfix"
report_unchanged origin master
report_cmd 'git log -1 --format="master-head: %s" master'
report_cmd '[ "$(git rev-parse master^1)" = "$(cat _eval/before/local-master)" ] && [ "$(git rev-parse master^2)" = "$(cat _eval/before/local-hotfix-T-001-fix-the-footer-typo)" ] && echo merged-hotfix-into-master || echo not-merged-hotfix-into-master'
report_cmd '[ "$(git rev-parse "v1.0.1^{commit}" 2>/dev/null)" = "$(git rev-parse master)" ] && echo tag-at-master || echo tag-not-at-master'
report_cmd '[ "$(git cat-file -t v1.0.1 2>/dev/null)" = tag ] && echo tag-annotated || echo tag-not-annotated'
report_cmd 'git ls-remote --exit-code --tags origin v1.0.1 >/dev/null && echo tag-on-origin || echo tag-not-on-origin'
report_cmd 'git log -1 --format="next-head: %s" release/next'
report_cmd '[ "$(git rev-parse release/next^1)" = "$(cat _eval/before/local-release-next)" ] && [ "$(git rev-parse release/next^2)" = "$(git rev-parse master)" ] && echo merged-master-into-next || echo not-merged-master-into-next'
report_cmd '[ "$(git ls-remote origin refs/heads/release/next | cut -f1)" = "$(git rev-parse release/next)" ] && echo next-pushed || echo next-not-pushed'
report_cmd 'git rev-parse -q --verify refs/heads/hotfix/T-001-fix-the-footer-typo >/dev/null && echo hotfix-branch-local || echo hotfix-branch-gone-locally'
report_cmd '[ "$(git ls-remote origin refs/heads/hotfix/T-001-fix-the-footer-typo | cut -f1)" = "$(cat _eval/before/origin-hotfix-T-001-fix-the-footer-typo)" ] && echo hotfix-branch-on-origin || echo hotfix-branch-not-on-origin'
report_cmd 'm=$(sed -n "s/^merge: //p" .pm/tasks/done/T-001-fix-the-footer-typo.md); [ -n "$m" ] && [ "$(git rev-parse -q --verify "$m^{commit}")" = "$(git rev-parse master)" ] && echo task-merge-is-release || echo task-merge-wrong'
report_cmd 'm=$(sed -n "s/^merge: //p" .pm/releases/1.0.1.md); [ -n "$m" ] && [ "$(git rev-parse -q --verify "$m^{commit}")" = "$(git rev-parse master)" ] && echo doc-merge-is-release || echo doc-merge-wrong'
report_cmd '[ -e .pm/releases/hotfix-T-001.md ] && echo hotfix-doc-present || echo hotfix-doc-gone'
report_cmd 'git -C .pm log -1 --format="pm-head: %s"'
report_cmd 'git -C .pm rev-list --count "$(cat _eval/before/local-pm)..pm" | sed "s/^/new-pm-commits: /"'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git rev-parse pm)" ] && echo pm-pushed || echo pm-not-pushed'
report_cmd '[ -z "$(git -C .pm status --porcelain)" ] && echo pm-clean || echo pm-dirty'
