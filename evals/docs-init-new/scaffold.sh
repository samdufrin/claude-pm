#!/bin/bash
# A project with commits, pushed to a bare origin, and no pm yet. It already
# has a .gitignore and a committed .claude/settings.json with another key,
# both of which the setup must keep.
. "$(dirname "$0")/../_scaffold/lib.sh"
make_project
printf 'node_modules/\n*.log\n' > .gitignore
mkdir -p .claude
printf '{\n  "env": {"A": "1"}\n}\n' > .claude/settings.json
git add .gitignore .claude/settings.json
git commit --quiet -m "Add project settings"
git push --quiet origin master
snapshot_refs master
report_unchanged origin master
report_cmd 'git log -1 --format="head-subject: %s" master'
report_cmd '[ "$(git rev-parse master~1)" = "$(cat _eval/before/origin-master)" ] && echo setup-on-original-head || echo setup-not-on-original-head'
report_cmd 'echo "setup-files: $(git diff --name-only master~1 master | LC_ALL=C sort | tr "\n" " ")"'
report_cmd 'git show master:.gitignore | grep -qxF .pm/ && echo gitignore-has-pm || echo gitignore-lacks-pm'
report_cmd 'git show master:.gitignore | sed "s/^/gitignore: /"'
report_cmd 'git show master:CLAUDE.md | grep -c -xF "<!-- pm:start -->" | sed "s/^/claude-md-blocks: /"'
report_cmd 'git show master:CLAUDE.md | grep -qxF "A tiny made-up notes app. Run \`sh check.sh\` to check a change." && echo claude-md-kept || echo claude-md-lost'
report_cmd 'git show master:.claude/settings.json | python3 -c "import json,sys; d=json.load(sys.stdin); ok=d[\"enabledPlugins\"][\"pm@samduf\"] is True and d[\"extraKnownMarketplaces\"][\"samduf\"][\"source\"][\"repo\"]==\"samdufrin/claude-pm\"; print(\"settings-enable-pm\" if ok else \"settings-wrong\"); print(\"settings-keeps-env\" if d.get(\"env\")=={\"A\":\"1\"} else \"settings-lost-env\")" 2>/dev/null || echo settings-invalid'
report_cmd '[ "$(git rev-parse "v1.0.0^{commit}")" = "$(git rev-parse master)" ] && echo tag-at-setup || echo tag-not-at-setup'
report_cmd '[ "$(git cat-file -t v1.0.0)" = tag ] && echo tag-annotated || echo tag-lightweight'
report_cmd '[ "$(git rev-parse release/next)" = "$(git rev-parse master)" ] && echo next-at-setup || echo next-not-at-setup'
report_cmd '[ "$(git ls-remote origin refs/heads/release/next | cut -f1)" = "$(git rev-parse release/next)" ] && echo next-pushed || echo next-not-pushed'
report_cmd '[ "$(git ls-remote origin refs/heads/pm | cut -f1)" = "$(git rev-parse pm)" ] && echo pm-pushed || echo pm-not-pushed'
report_cmd 'git ls-remote --exit-code --tags origin v1.0.0 >/dev/null && echo tag-on-origin || echo tag-not-on-origin'
report_cmd 'grep -qxF .pm/ .git/info/exclude && echo exclude-has-pm || echo exclude-lacks-pm'
report_cmd 'git -C .pm log --format="pm-commit: %s"'
report_cmd '[ -z "$(git -C .pm rev-parse -q --verify pm~1)" ] && echo pm-single-commit || echo pm-several-commits'
report_cmd 'git merge-base master pm >/dev/null 2>&1 && echo pm-shares-history || echo pm-unrelated'
report_cmd 'grep -rl "{{" .pm --exclude-dir=.git >/dev/null && echo placeholders-left || echo no-placeholders'
