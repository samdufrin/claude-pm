---
type: regex
pattern: '^[0-9a-f]+ .*Set up pm$'
flags: m
target: {source: file, path: eval-report.txt}
match: count:1
---
