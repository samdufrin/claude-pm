---
runs: 1
max_turns: 60
timeout_seconds: 900
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---
Ship the open release: use the pm plugin's release-ship skill with the argument `minor`.

Then run `sh evals-report.sh`.
