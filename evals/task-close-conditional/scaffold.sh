#!/bin/bash
# testing.md has a conditional check, "- When the diff touches ui/: sh
# check-ui.sh", and check-ui.sh writes the marker _eval/ui-check-ran. The
# built quick task T-001's branch changes ui/x.txt, so closing it must run
# that check on the test merge.
. "$(dirname "$0")/../_scaffold/lib.sh"
B=task/T-001-update-the-ui-text
make_project
printf '#!/bin/sh\n# The UI check of the sample project: records that it ran.\nmkdir -p _eval\necho ui-check-ran > _eval/ui-check-ran\necho "ui check passed"\n' > check-ui.sh
mkdir -p ui
printf 'Old UI text.\n' > ui/x.txt
git add check-ui.sh ui/x.txt
git commit --quiet -m "Add the UI and its check"
git push --quiet origin master
setup_pm
add_testing_section "Conditional checks" "- When the diff touches ui/: sh check-ui.sh"
pm_commit "Add the UI check to testing"
open_release_next
work_branch "$B" release/next
commit_on "$B" ui/x.txt 'New UI text.' 'Update the UI text'
add_task active T-001 update-the-ui-text title="Update the UI text" branch="$B"
# The task's text points at ui/x.txt, the file its branch changes.
sed 's#`src/`#`ui/x.txt`#g' .pm/tasks/active/T-001-update-the-ui-text.md > _eval/task.tmp
mv _eval/task.tmp .pm/tasks/active/T-001-update-the-ui-text.md
pm_commit "Finish T-001"
rm -f _eval/ui-check-ran
snapshot_refs master release/next pm "$B"
report_cmd 'git log -1 --format="next-head: %s" release/next'
report_cmd '[ "$(git rev-parse release/next^1)" = "$(cat _eval/before/local-release-next)" ] && [ "$(git rev-parse release/next^2)" = "$(cat _eval/before/local-task-T-001-update-the-ui-text)" ] && echo merge-parents-ok || echo merge-parents-wrong'
report_cmd '[ "$(git ls-remote origin refs/heads/release/next | cut -f1)" = "$(git rev-parse release/next)" ] && echo origin-next-at-local || echo origin-next-differs'
report_cmd '[ -f _eval/ui-check-ran ] && echo ui-check-ran || echo ui-check-did-not-run'
report_cmd 'git -C .pm log -1 --format="pm-head: %s"'
