---
runs: 1
max_turns: 40
timeout_seconds: 600
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---
Use the pm plugin's task-create skill with arguments `--quick Fix the typo in the footer`.

Then run `sh evals-report.sh`.
