#!/bin/sh
# Usage: sh evals-report.sh ["<extra command>" ...]
# Copied into each eval workspace by make_project (lib.sh). The case prompt
# asks the agent to run it from the project root once the skill has finished,
# so graders can read the repo's git state from eval-report.txt: every
# branch's log, the worktrees, the tags, origin's refs, the files in .pm,
# git status of the project and of .pm, then each command the case's scaffold
# registered in _eval/report-extra (report_cmd in lib.sh, one per line), then
# each command given as an argument; each runs with sh -c under a
# "== <command>" header.
set -u

out=eval-report.txt
: > "$out"

run() {
    printf '== %s\n' "$1" >> "$out"
    sh -c "$1" >> "$out" 2>&1 || printf '(exit %s)\n' "$?" >> "$out"
    printf '\n' >> "$out"
}

run 'git log --all --oneline --decorate'
run 'git worktree list'
run 'git tag'
run 'git ls-remote origin'
run 'find .pm -type f -not -path "*/.git" | sort'
run 'git status'
run 'git -C .pm status --short --branch'
if [ -f _eval/report-extra ]; then
    while IFS= read -r cmd || [ -n "$cmd" ]; do
        [ -n "$cmd" ] && run "$cmd"
    done < _eval/report-extra
fi
for cmd in "$@"; do
    run "$cmd"
done

echo "wrote $out"
