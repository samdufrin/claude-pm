#!/bin/bash
# A built quick task T-001 with a pushed branch, but testing.md's
# ## Full check is still its fill-in comment. task-close must stop before
# changing anything and name the section.
. "$(dirname "$0")/../_scaffold/lib.sh"
B=task/T-001-fix-footer
make_project
setup_pm --full-check-undefined
open_release_next
work_branch "$B" release/next
commit_on "$B" src/footer.txt 'Copyright Sample notes. All rights reserved.' 'Fix the footer typo'
add_task active T-001 fix-footer title="Fix the footer" branch="$B"
pm_commit "Finish T-001"
snapshot_refs master release/next pm "$B"
for b in release/next pm "$B"; do
    report_unchanged local "$b"
    report_unchanged origin "$b"
done
report_cmd '[ "$(git rev-list --all --merges --count)" = 0 ] && echo no-merge-commits || echo merge-commits-found'
report_cmd '[ -z "$(git -C .pm status --porcelain)" ] && echo pm-clean || echo pm-dirty'
