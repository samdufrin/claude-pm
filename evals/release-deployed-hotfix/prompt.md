---
runs: 1
max_turns: 60
timeout_seconds: 900
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---
Record the deploy: use the pm plugin's release-deployed skill with the argument `1.0.1`.

Then run `sh evals-report.sh`.
