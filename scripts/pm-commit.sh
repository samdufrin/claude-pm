#!/bin/sh
# Usage: pm-commit.sh <pm-dir> <message>
# Stages everything in the pm worktree, commits it with <message>, then, when
# pm has an upstream, rebases onto it and pushes. A rejected push (someone
# pushed pm in between) is retried with another rebase, 3 pushes in all.
# Never forces. With no upstream it only commits.
# Exit 0: committed (or nothing to commit) and pushed, or no upstream.
# Exit 1: not a pm worktree, or git failed for another reason.
# Exit 2: a rebase conflicted; it was aborted, the commit stays local, and the
#         conflicting files are listed after a "conflict:" line.
# Exit 3: all 3 pushes were rejected because origin's pm kept moving; the
#         commit stays local. (A push declined for another reason is exit 1.)
set -eu

if [ $# -ne 2 ]; then
    echo "usage: pm-commit.sh <pm-dir> <message>" >&2
    exit 1
fi
dir=$1
message=$2
here=$(dirname "$0")

branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null) || branch=
if [ "$branch" != pm ]; then
    echo "not a pm worktree: $dir" >&2
    exit 1
fi

git -C "$dir" add -A
if git -C "$dir" diff --cached --quiet; then
    echo "nothing to commit"
else
    git -C "$dir" commit --quiet -m "$message"
    echo "committed: $(git -C "$dir" log -1 --format='%h %s')"
fi

if ! git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    echo "not pushed: no upstream"
    exit 0
fi

remote=$(git -C "$dir" config branch.pm.remote)
target=$(git -C "$dir" config branch.pm.merge)

attempt=1
while :; do
    status=0
    out=$(sh "$here/pm-sync.sh" "$dir" 2>&1) || status=$?
    if [ "$status" -ne 0 ]; then
        printf '%s\n' "$out"
        exit "$status"
    fi

    if [ "$(git -C "$dir" rev-list --count '@{upstream}..HEAD')" -eq 0 ]; then
        echo "nothing to push"
        exit 0
    fi

    if out=$(git -C "$dir" push --quiet "$remote" "HEAD:$target" 2>&1); then
        echo "pushed to $remote"
        exit 0
    fi

    # Retry only when someone else moved pm first: a non-fast-forward
    # ("! [rejected] ... (fetch first)" or "(non-fast-forward)"), or the
    # remote's ref changing between git's check and its update ("incorrect
    # old value provided", "cannot lock ref"). Anything else, such as a
    # server hook declining the push, is a plain failure.
    if ! printf '%s\n' "$out" | grep -qE '! \[rejected\]|\(fetch first\)|\(non-fast-forward\)|incorrect old value provided|cannot lock ref'; then
        printf '%s\n' "$out" >&2
        echo "push failed" >&2
        exit 1
    fi

    if [ "$attempt" -ge 3 ]; then
        printf '%s\n' "$out" >&2
        echo "push rejected 3 times; the commit stays local" >&2
        exit 3
    fi
    attempt=$((attempt + 1))
done
