#!/bin/sh
# Usage: pm-sync.sh <pm-dir>
# Brings the pm branch up to date with its upstream (git pull --rebase).
# Uncommitted changes in the worktree are refused (exit 1), upstream or not:
# they are left over from an interrupted run, and a skill must not build on
# or commit them without knowing what they are.
# Exit 0: up to date, or nothing to sync with (no upstream; a note says so).
# Exit 1: not a pm worktree, uncommitted changes, or git failed (e.g. network).
# Exit 2: the rebase conflicted; it was aborted, and the conflicting files are
#         listed one per line after a "conflict:" line.
set -eu

if [ $# -ne 1 ]; then
    echo "usage: pm-sync.sh <pm-dir>" >&2
    exit 1
fi
dir=$1

branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null) || branch=
if [ "$branch" != pm ]; then
    echo "not a pm worktree: $dir" >&2
    exit 1
fi

dirty=$(git -C "$dir" status --porcelain)
if [ -n "$dirty" ]; then
    echo "uncommitted changes in $dir; commit or discard them first:" >&2
    printf '%s\n' "$dirty" >&2
    exit 1
fi

if ! git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    echo "not synced: pm has no upstream"
    exit 0
fi

rebasing() {
    [ -d "$(git -C "$dir" rev-parse --path-format=absolute --git-path rebase-merge)" ] ||
        [ -d "$(git -C "$dir" rev-parse --path-format=absolute --git-path rebase-apply)" ]
}

if out=$(git -C "$dir" pull --rebase --quiet 2>&1); then
    echo "synced"
    exit 0
fi

if rebasing; then
    files=$(git -C "$dir" diff --name-only --diff-filter=U)
    git -C "$dir" rebase --abort
    echo "conflict:"
    printf '%s\n' "$files"
    exit 2
fi

printf '%s\n' "$out" >&2
echo "sync failed" >&2
exit 1
