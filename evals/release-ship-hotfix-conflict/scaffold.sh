#!/bin/bash
# Release 1.0.0 is deployed. A closed hotfix T-001 rewrites the footer line
# in src/footer.txt, and a later commit on master (pushed) rewrites the same
# line differently, so merging the hotfix into master conflicts.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm

hotfix=hotfix/T-001-fix-the-footer-typo
work_branch "$hotfix" master
commit_on "$hotfix" src/footer.txt "Copyright Sample notes. All rights reserved." "Fix the footer typo"
commit_on master src/footer.txt "Sample notes, all rihgts reserved, 2026." "Update the footer year"
open_release_next
add_task done T-001 fix-the-footer-typo title="Fix the footer typo" type=hotfix priority=high \
    branch="$hotfix" "commits=[$(git rev-parse --short "$hotfix")]" closed="$(date +%F)"
add_release hotfix-T-001 kind=hotfix branch="$hotfix" "tasks=[T-001]"
add_release_task_line hotfix-T-001 "T-001 Fix the footer typo (hotfix)"
pm_commit "Close T-001"

snapshot_refs master release/next pm "$hotfix"
report_unchanged local master
report_unchanged origin master
report_unchanged local release/next
report_unchanged local "$hotfix"
report_unchanged local pm
report_unchanged origin pm
report_cmd 'git log --all --format=%s | grep -c "^Release " | sed "s/^/release-commits: /"'
report_cmd 'echo "tags: $(git tag | tr "\n" " ")"'
report_cmd '[ -f "$(git rev-parse --git-path MERGE_HEAD)" ] && echo merge-in-progress || echo no-merge-in-progress'
report_cmd '[ -e .pm/releases/1.0.1.md ] && echo version-doc-present || echo version-doc-absent'
