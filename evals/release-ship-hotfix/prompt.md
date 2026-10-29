---
runs: 1
max_turns: 60
timeout_seconds: 900
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---
Ship the hotfix: use the pm plugin's release-ship skill with the arguments `hotfix-T-001 patch`.

Then run `sh evals-report.sh`.
