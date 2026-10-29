#!/bin/bash
# A project whose .gitignore ignores the whole /.claude folder, with a local
# file there that must stay ignored after the rule is rewritten.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
printf 'node_modules/\n/.claude\n*.log\n' > .gitignore
git add .gitignore
git commit --quiet -m "Ignore local files"
git push --quiet origin master
mkdir -p .claude
printf '{\n  "permissions": {"allow": ["Bash(ls:*)"]}\n}\n' > .claude/settings.local.json
snapshot_refs master
report_unchanged origin master
report_cmd 'git log -1 --format="head-subject: %s" master'
report_cmd 'git show --stat --format=%s master'
report_cmd 'git ls-tree -r --name-only master | grep -qxF .claude/settings.json && echo settings-committed || echo settings-not-committed'
report_cmd 'git ls-tree -r --name-only master | grep -q "^\.claude/settings\.local\.json$" && echo local-committed || echo local-not-committed'
report_cmd 'git check-ignore -q .claude/settings.local.json && echo local-still-ignored || echo local-not-ignored'
report_cmd 'git check-ignore -q .claude/settings.json && echo settings-ignored || echo settings-not-ignored'
report_cmd 'git show master:.gitignore | sed "s/^/gitignore: /"'
