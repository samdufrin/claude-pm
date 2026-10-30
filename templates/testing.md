# Testing

<!--
How to check a change in this project. The pm skills read the sections below and stop when one they need is undefined: its heading is missing, it's empty, or it still holds a fill-in comment. Write `None.` when there's genuinely nothing to put in a section.

Optional sections. Add one only when it applies; a section that's present but not filled in blocks like a required one:
- `## Targeted checks`: for a full check too slow to run while building. The full check then runs only when a task is closed or a release shipped; while a task is built, pm runs only the groups a change needs. Group your tests (Playwright tags, pytest markers, directories) and list them one per line as `- Always: <command>` (fast checks every change needs, e.g. `- Always: npm run lint && npm run typecheck`) or `- When <condition>: <command>`, saying what the group covers, e.g. `- When the change touches billing (src/billing/, the invoice pages): npx playwright test --grep @billing`.
- `## Conditional checks`: checks that run only for some changes, one per line as `- When <condition>: <command>`, e.g. `- When the diff touches web/: npm run test:browser`. They run after the full check whenever the changed files meet the condition.
- `## Security-sensitive paths`: one path prefix per line as `- <path prefix>`, e.g. `- src/auth/`. A quick task whose diff touches one gets a security audit.
- `## Quick checks`: fast commands for checking a single step while building (one test file, a linter). They never replace the full or targeted check.
-->

## Full check
<!-- fill in: the command block that runs every check (tests, type checks, linters, static analysis) and exits 0 only when all of them pass, e.g.
```sh
make check
```
-->

## Environment
<!-- fill in: the commands that start whatever the checks need (services, containers, a database), in a command block, or `None.` if the checks need nothing running. -->
