#!/bin/bash
# A built quick task T-001 whose branch changes the footer line that a later
# commit on release/next also changes, differently. task-close must abort the
# test merge, leave everything as it was and name src/footer.txt.
. "$(dirname "$0")/../_scaffold/lib.sh"
B=task/T-001-fix-footer
make_project
setup_pm
open_release_next
work_branch "$B" release/next
commit_on "$B" src/footer.txt 'Copyright Sample notes. All rights reserved.' 'Fix the footer typo'
commit_on release/next src/footer.txt 'Copyright 2026 Sample notes. All rihgts reserved.' 'Add the year to the footer'
add_task active T-001 fix-footer title="Fix the footer" branch="$B"
pm_commit "Finish T-001"
snapshot_refs master release/next pm "$B"
for b in release/next pm "$B"; do
    report_unchanged local "$b"
    report_unchanged origin "$b"
done
report_cmd 'git rev-parse -q --verify MERGE_HEAD >/dev/null && echo merge-in-progress || echo no-merge-in-progress'
