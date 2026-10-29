#!/bin/sh
# Usage: pm-dir.sh [repo-dir]
# Prints the path of the worktree that has the pm branch checked out (normally
# <project root>/.pm). Works from the main checkout and from any linked
# worktree, since they all share one worktree list.
# Exit 0: path printed. Exit 1: not a git repo, or no worktree on pm.
set -eu

repo=${1:-.}

if ! list=$(git -C "$repo" worktree list --porcelain 2>/dev/null); then
    echo "not a git repository: $repo" >&2
    exit 1
fi

path=$(printf '%s\n' "$list" | awk '
    /^worktree / { p = substr($0, 10) }
    $0 == "branch refs/heads/pm" { print p; exit }
')

if [ -z "$path" ]; then
    echo "pm is not set up in this clone: run /pm:docs-init" >&2
    exit 1
fi

printf '%s\n' "$path"
