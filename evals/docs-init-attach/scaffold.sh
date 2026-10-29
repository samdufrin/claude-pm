#!/bin/bash
# A fresh clone of an origin that already uses pm. The project that set pm up
# is built in _eval/upstream and pushed to _eval/origin.git; the workspace is
# then a plain clone of that origin, with no .pm worktree yet.
. "$(dirname "$0")/../_scaffold/lib.sh"
WS=$PROJECT
mkdir -p "$WS/_eval/upstream"
PROJECT=$WS/_eval/upstream
ORIGIN=$WS/_eval/origin.git
make_project
setup_pm
open_release_next
add_task backlog T-001 fix-footer title="Fix the footer"
pm_commit "Add T-001 Fix the footer"

# Clone it into the workspace (which already holds _eval, so clone beside it
# and move the repository in).
PROJECT=$WS
cd "$WS"
git clone --quiet "$ORIGIN" "$WS/_eval/clone"
mv "$WS/_eval/clone/.git" "$WS/.git"
rm -rf "$WS/_eval/clone"
git reset --quiet --hard
git_local "$WS"
exclude "/_eval/"
exclude "/evals-report.sh"
exclude "/eval-report.txt"
cp "$PM_SCAFFOLD/evals-report.sh" "$WS/evals-report.sh"

snapshot_refs master release/next pm
git for-each-ref --format='%(objectname) %(refname)' | grep -v ' refs/heads/pm$' > _eval/before/other-refs
git -C "$WS/_eval/upstream" rev-parse pm > _eval/before/upstream-pm
report_unchanged local master
report_unchanged origin master
report_unchanged local release/next
report_unchanged origin release/next
report_unchanged origin pm
report_cmd 'git for-each-ref --format="%(objectname) %(refname)" | grep -v " refs/heads/pm$" | cmp -s - _eval/before/other-refs && echo other-refs-unchanged || echo other-refs-changed'
report_cmd '[ "$(git rev-parse pm)" = "$(cat _eval/before/upstream-pm)" ] && echo pm-at-origin || echo pm-not-at-origin'
report_cmd 'grep -qxF .pm/ .git/info/exclude && echo exclude-has-pm || echo exclude-lacks-pm'
report_cmd 'git worktree list --porcelain | grep -c "^worktree " | sed "s/^/worktrees: /"'
