---
runs: 1
max_turns: 40
timeout_seconds: 600
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---
Use the pm plugin's task-create skill with arguments `--hotfix Footer: fix the typo`.

Then run `sh evals-report.sh`.
