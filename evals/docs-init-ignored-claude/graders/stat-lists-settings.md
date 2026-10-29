---
type: regex
pattern: '^ \.claude/settings\.json +\| +[0-9]+ \+*$'
flags: m
target: {source: file, path: eval-report.txt}
---
