#!/bin/bash
# A project with pm set up and no tasks. A teammate's clone then pushes
# tasks/backlog/T-001-other.md to origin's pm, and the workspace doesn't fetch
# it: the skill must sync before picking an ID, so its task becomes T-002 and
# the teammate's file is left as it is.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm
open_release_next

other=$(second_clone teammate)
git -C "$other" switch --quiet pm
fill_template "$PM_TEMPLATES/quick-task.md" "$other/tasks/backlog/T-001-other.md" \
    id=T-001 title="Other change" type=chore priority=normal owner="Other User" \
    date="$(date +%F)" goal="Another change." summary="- Another change." \
    step_name="Make the other change" step="Change \`src/home.txt\`." \
    verify="\`sh check.sh\` passes." acceptance="1. The other change is in \`src/home.txt\`."
git -C "$other" add -A
git -C "$other" commit --quiet -m "Add T-001 Other change"
git -C "$other" push --quiet origin pm
git -C "$other" rev-parse HEAD:tasks/backlog/T-001-other.md > _eval/other-blob

snapshot_refs master release/next pm
report_unchanged local master
report_unchanged local release/next
report_cmd 'git -C .pm log --format="pm-commit: %s"'
report_cmd 'git -C .pm rev-list --count "$(cat _eval/before/origin-pm)..pm" | sed "s/^/new-pm-commits: /"'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git rev-parse pm)" ] && echo pm-pushed || echo pm-not-pushed'
report_cmd '[ -z "$(git -C .pm status --porcelain)" ] && echo pm-clean || echo pm-dirty'
report_cmd '[ "$(git rev-parse pm:tasks/backlog/T-001-other.md)" = "$(cat _eval/other-blob)" ] && echo other-unchanged || echo other-changed'
report_cmd 'ls .pm/tasks/*/T-*.md | wc -l | sed "s/^ */task-files: /"'
report_cmd 'cat .pm/tasks/backlog/T-002-*.md'
