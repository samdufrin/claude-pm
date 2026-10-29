#!/bin/bash
# A built quick task T-001 whose branch task/T-001-fix-footer (off
# release/next, pushed) has two commits: the footer fix and its test, both
# in src/ as the task's step says. Closing it merges the branch into
# release/next with --no-ff, pushes release/next, deletes the branch locally
# and on origin, and closes the task into releases/next.md.
. "$(dirname "$0")/../_scaffold/lib.sh"
B=task/T-001-fix-footer
F=.pm/tasks/done/T-001-fix-footer.md
make_project
setup_pm
open_release_next
work_branch "$B" release/next
commit_on "$B" src/footer.txt 'Copyright Sample notes. All rights reserved.' 'Fix the footer typo'
commit_on "$B" src/footer.test.sh '! grep -q rihgts src/footer.txt' 'Add a test for the footer spelling'
add_task active T-001 fix-footer title="Fix the footer" branch="$B"
pm_commit "Finish T-001"
mkdir -p _eval/before
git log --reverse --format=%H "release/next..$B" | tr '\n' ' ' > _eval/before/task-commits
snapshot_refs master release/next pm "$B"
report_unchanged local master
report_unchanged origin master
report_cmd 'git log -1 --format="next-head: %s" release/next'
report_cmd '[ "$(git rev-parse release/next^1)" = "$(cat _eval/before/local-release-next)" ] && [ "$(git rev-parse release/next^2)" = "$(cat _eval/before/local-task-T-001-fix-footer)" ] && [ -z "$(git rev-parse -q --verify release/next^3)" ] && echo merge-parents-ok || echo merge-parents-wrong'
report_cmd 'git show release/next:src/footer.txt | sed "s/^/footer: /"'
report_cmd '[ "$(git ls-remote origin refs/heads/release/next | cut -f1)" = "$(git rev-parse release/next)" ] && echo origin-next-at-local || echo origin-next-differs'
report_cmd 'git rev-parse -q --verify refs/heads/task/T-001-fix-footer >/dev/null && echo task-branch-local-present || echo task-branch-local-gone'
report_cmd 'git ls-remote --exit-code origin refs/heads/task/T-001-fix-footer >/dev/null && echo task-branch-origin-present || echo task-branch-origin-gone'
cp "$(dirname "$0")/recorded.sh" _eval/recorded.sh
report_cmd "sh _eval/recorded.sh $F release/next"
report_cmd 'git -C .pm log -1 --format="pm-head: %s"'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git -C .pm rev-parse HEAD)" ] && echo pm-pushed || echo pm-not-pushed'
report_cmd '[ -z "$(git -C .pm status --porcelain)" ] && echo pm-clean || echo pm-dirty'
report_cmd 'git rev-parse -q --verify MERGE_HEAD >/dev/null && echo merge-in-progress || echo no-merge-in-progress'
