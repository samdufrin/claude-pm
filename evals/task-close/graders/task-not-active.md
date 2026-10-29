---
type: regex
pattern: '^\.pm/tasks/active/T-001'
flags: m
target: {source: file, path: eval-report.txt}
match: not_contains
---
