#!/bin/bash
# A project with pm set up, an open release and no tasks yet. The footer in
# src/footer.txt has a typo ("rihgts").
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
setup_pm
open_release_next

snapshot_refs master release/next pm
report_unchanged local master
report_unchanged local release/next
report_cmd 'git -C .pm log -1 --format="pm-head: %s"'
report_cmd 'git -C .pm rev-list --count "$(cat _eval/before/local-pm)..pm" | sed "s/^/new-pm-commits: /"'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git rev-parse pm)" ] && echo pm-pushed || echo pm-not-pushed'
report_cmd '[ -z "$(git -C .pm status --porcelain)" ] && echo pm-clean || echo pm-dirty'
report_cmd 'grep -l "{{" .pm/tasks/*/T-*.md >/dev/null 2>&1 && echo placeholders-left || echo no-placeholders'
report_cmd 'ls .pm/tasks/*/T-*.md | wc -l | sed "s/^ */task-files: /"'
report_cmd 'cat .pm/tasks/backlog/T-001-*.md'
