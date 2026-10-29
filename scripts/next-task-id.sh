#!/bin/sh
# Usage: next-task-id.sh <pm-dir>
# Prints the next task ID: the highest number among tasks/*/T-*.md plus 1,
# zero-padded to at least 3 digits (T-001 when there are no tasks).
set -eu

if [ $# -ne 1 ]; then
    echo "usage: next-task-id.sh <pm-dir>" >&2
    exit 1
fi
dir=$1

if [ ! -d "$dir/tasks" ]; then
    echo "no tasks folder in $dir" >&2
    exit 1
fi

max=0
for f in "$dir"/tasks/*/T-*.md; do
    [ -e "$f" ] || continue
    num=$(basename "$f" | sed -n 's/^T-\([0-9][0-9]*\)[-.].*$/\1/p')
    [ -n "$num" ] || continue
    n=$(printf '%s\n' "$num" | sed 's/^0*\(.\)/\1/')
    if [ "$n" -gt "$max" ]; then
        max=$n
    fi
done

printf 'T-%03d\n' $((max + 1))
