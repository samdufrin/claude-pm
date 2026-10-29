#!/bin/bash
# A project with pm set up, an open release and one finished task, T-007, in
# tasks/done/. A new task must take the next ID, T-008.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm
open_release_next
add_task done T-007 add-the-about-page title="Add the about page" type=feature closed="$(date +%F)"
pm_commit "Close T-007"

snapshot_refs master release/next pm
report_unchanged local master
report_unchanged local release/next
report_cmd 'git -C .pm log -1 --format="pm-head: %s"'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git rev-parse pm)" ] && echo pm-pushed || echo pm-not-pushed'
report_cmd '[ -z "$(git -C .pm status --porcelain)" ] && echo pm-clean || echo pm-dirty'
report_cmd 'ls .pm/tasks/*/T-*.md | wc -l | sed "s/^ */task-files: /"'
report_cmd 'cat .pm/tasks/backlog/T-008-*.md'
