---
runs: 1
max_turns: 150
timeout_seconds: 1800
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill, Agent]
---
Build T-001: use the pm plugin's task-implement skill with the argument `T-001`.

Then run `sh evals-report.sh`.
