---
runs: 1
max_turns: 80
timeout_seconds: 900
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---
The hotfix T-001 is built and I am happy with it. Close it: use the pm plugin's task-close skill with the argument `T-001`.

Then run `sh evals-report.sh`.
