#!/bin/bash
# The full check, check.sh, stands in for a slow suite: it writes the marker
# _eval/ran-full-check, which must never appear. testing.md's ## Targeted
# checks has an Always line (lint) and two groups, footer and home, whose
# scripts write their own markers. The quick task T-001 fixes the footer typo,
# and its Verify line is the full check command, so task-implement must run
# lint and footer in its place, skip home and leave the full check to
# task-close.
. "$(dirname "$0")/../_scaffold/lib.sh"
B=task/T-001-fix-the-footer-typo
make_project
check_script() {
    printf '#!/bin/sh\n# %s\nmkdir -p "$(git rev-parse --show-toplevel)/_eval"\necho ran > "$(git rev-parse --show-toplevel)/_eval/ran-%s"\necho "%s passed"\n' "$2" "$3" "$3" > "$1"
}
check_script check.sh "The full suite of the sample project: slow, about 5 minutes." full-check
mkdir -p checks
check_script checks/lint.sh "Lints every file." lint
check_script checks/footer.sh "Tests the footer (src/footer.txt)." footer
check_script checks/home.sh "Tests the home page (src/home.txt)." home
sed 's#^A tiny made-up notes app. Run `sh check.sh` to check a change.$#A tiny made-up notes app. `sh check.sh` runs the full suite (slow, about 5 minutes); `checks/` holds its parts.#' CLAUDE.md > _eval.tmp
mv _eval.tmp CLAUDE.md
git add -A
git commit --quiet -m "Split the checks into groups"
git push --quiet origin master
setup_pm
add_testing_section "Targeted checks" '- Always: sh checks/lint.sh
- When the change touches the footer (src/footer.txt): sh checks/footer.sh
- When the change touches the home page (src/home.txt): sh checks/home.sh'
pm_commit "Add the targeted checks to testing"
open_release_next
add_task backlog T-001 fix-the-footer-typo title="Fix the footer typo"
# Point the task at the file it changes.
sed 's#Make the change in `src/`.#In `src/footer.txt`, correct "rihgts" to "rights".#; s#The change is visible in `src/`.#The footer reads "All rights reserved."#' \
    .pm/tasks/backlog/T-001-fix-the-footer-typo.md > _eval/task.tmp
mv _eval/task.tmp .pm/tasks/backlog/T-001-fix-the-footer-typo.md
pm_commit "Add T-001 Fix the footer typo"
rm -f _eval/ran-*
snapshot_refs master release/next pm
report_unchanged origin master
report_cmd '[ -f _eval/ran-full-check ] && echo full-check-ran || echo full-check-not-run'
report_cmd '[ -f _eval/ran-lint ] && echo lint-ran || echo lint-not-run'
report_cmd '[ -f _eval/ran-footer ] && echo footer-ran || echo footer-not-run'
report_cmd '[ -f _eval/ran-home ] && echo home-ran || echo home-not-run'
report_cmd "git show '$B:src/footer.txt' | sed 's/^/footer: /'"
report_cmd "[ \"\$(git ls-remote origin 'refs/heads/$B' | cut -f1)\" = \"\$(git rev-parse '$B')\" ] && echo branch-pushed || echo branch-not-pushed"
report_cmd 'sed -n "s/^status: /task-status: /p" .pm/tasks/active/T-001-fix-the-footer-typo.md'
