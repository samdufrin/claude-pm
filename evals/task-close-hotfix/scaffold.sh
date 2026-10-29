#!/bin/bash
# A built quick hotfix T-001 whose branch hotfix/T-001-fix-footer (off
# master, pushed) has one commit, with release/next open and no hotfix
# release doc yet. task-close merges nothing, records the commit, keeps the
# branch and creates releases/hotfix-T-001.md.
. "$(dirname "$0")/../_scaffold/lib.sh"
B=hotfix/T-001-fix-footer
F=.pm/tasks/done/T-001-fix-footer.md
make_project
setup_pm
open_release_next
work_branch "$B" master
commit_on "$B" src/footer.txt 'Copyright Sample notes. All rights reserved.' 'Fix the footer typo'
add_task active T-001 fix-footer title="Fix the footer" type=hotfix priority=high branch="$B"
pm_commit "Finish T-001"
mkdir -p _eval/before
git log --reverse --format=%H "master..$B" | tr '\n' ' ' > _eval/before/task-commits
snapshot_refs master release/next pm "$B"
for b in master release/next "$B"; do
    report_unchanged local "$b"
    report_unchanged origin "$b"
done
cp "$(dirname "$0")/../task-close/recorded.sh" _eval/recorded.sh
report_cmd 'echo "merges: $(git rev-list --all --merges --count)"'
report_cmd "sh _eval/recorded.sh $F null"
report_cmd 'git -C .pm log -1 --format="pm-head: %s"'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git -C .pm rev-parse HEAD)" ] && echo pm-pushed || echo pm-not-pushed'
