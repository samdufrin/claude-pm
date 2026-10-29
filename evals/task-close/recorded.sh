# Copied to _eval/recorded.sh by the task-close scaffolds.
# Usage: sh _eval/recorded.sh <task file> <merge-ref|null>
# Checks the task's commits list against _eval/before/task-commits (full SHAs
# of the branch's commits, saved by the scaffold) and its merge field.
f=$1
s=$(sed -n 's/^commits: \[\(.*\)\]$/\1/p' "$f" | tr -d ,)
full=
for c in $s; do full="$full$(git rev-parse -q --verify "$c^{commit}") "; done
if [ -n "$s" ] && [ "$full" = "$(cat _eval/before/task-commits)" ]; then echo commits-match; else echo "commits-mismatch: $s"; fi
m=$(sed -n 's/^merge: //p' "$f")
if [ "$2" = null ]; then
    want=null
    got=$m
else
    want=$(git rev-parse "$2")
    got=$(git rev-parse -q --verify "$m^{commit}")
fi
if [ -n "$m" ] && [ "$got" = "$want" ]; then echo merge-recorded; else echo "merge-not-recorded: $m"; fi
