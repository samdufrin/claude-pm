# Task format

The body of a task file, below its frontmatter (see `conventions.md` for the frontmatter, folders and statuses). Every pm skill that writes or reads a task relies on these headings and markers, so don't vary them. A task is the only thing passed between sessions and machines: an agent with no other context must be able to build it from the file and the codebase alone.

There are two formats: **full** (`quick: false`), written by `/pm:task-create` after an interview, and **quick** (`quick: true`), for very small changes and every hotfix.

## Full format

Adapt the design headings (4..n) to the task, but keep sections 1, 2, 3 and the last five, with these exact headings, because the skills look for them by name: **Summary**, **Decisions**, **Open questions**, **Tests**, **Build order**, **Acceptance**, **Docs**, **Out of scope**. `## Manual acceptance` and `## Outcome` are added later.

```markdown
# T-042: <title>

**Goal:** <one or two sentences>

## 1. Summary
<What gets built, in a handful of bullets. Someone reading only this knows the shape of it.>

## 2. Decisions
| # | Question | Decision |
|---|---|---|
| D1 | ... | **Confirmed:** ... (alternatives considered: ...) |
| D2 | ... | **Default, not confirmed:** ... |

## 3. Open questions
<Anything still unresolved, each with the options and a recommendation. "None." if empty.>

## 4..n. Design
<Context the implementer needs (conventions to follow, files to read and mimic, with paths), then data model, behaviour and flows, permissions, UI and states, edge cases, and integration with existing code. Concrete names: tables, columns, classes, routes, components, messages.>

## n+1. Tests
<What each test proves, grouped by area, naming the test file each goes in.>

## n+2. Build order
1. **<Step name>.** <What to build, naming the files.> Tests: <which Tests entries this step adds>. **Verify:** `<command>` <and what passing looks like>.
2. ...

## n+3. Acceptance
1. <A check the user can do in the running app: who signs in, what they do, what they see.>

## n+4. Docs
**Code docs:** <edits to files on code branches (CLAUDE.md, the code README, any doc outside .pm/), passage by passage, or "None.">

**`.pm/` docs:** <edits to architecture/ and workflows/ docs in .pm/, passage by passage, or "None.">

## n+5. Out of scope
<Things deliberately left out, so the implementer doesn't add them.>
```

There's no `**Status:**` line: the frontmatter `status` holds it.

### Markers

- **Decision cells** start with exactly `**Confirmed:**` or `**Default, not confirmed:**`. IDs are `D1`, `D2`… in order; a later decision takes the next free number, and IDs are never renumbered or reused. Section numbers don't change either. A choice the user left to Claude is `**Confirmed:**` with "(chosen by Claude at the user's request)". A choice made during an unattended build is `**Default, not confirmed:**` ending "(chosen during the unattended build: <why>)" until the user confirms it.
- **Open questions** is a numbered list, or exactly `None.`
- **Build order** steps each have a `**Verify:**`. Once a step is built and verified, ` **Done.**` is appended to it. A step that can't be finished gets ` **Blocked:** <what's failing or undecided, and what was tried>.`, and each step depending on it ` **Blocked:** depends on step N.` The first step without `**Done.**` is the next step.
- **Docs** has both lists, each either a list of edits or `None.`:
  - **Code docs** are made by `/pm:task-implement` on the task branch after the last build step, in one commit `Update docs for T-042`, so they merge with the code. They include any other `CLAUDE.md` passage the change makes wrong.
  - **`.pm/` docs** are made by `/pm:task-close`, once the work is merged, so the shared docs describe only accepted work.

### Manual acceptance

`/pm:task-implement` adds this after Acceptance once the task is built: the manual checks the user should do, each saying where, which account, what to do and what they should see.

```markdown
## Manual acceptance
- [ ] 1. Sign in as a household member, open a recipe and choose Add to shopping list: its ingredients appear on the Shopping list page, grouped by aisle.
- [ ] 2. …
```

`/pm:task-close` ticks every box (`- [x]`) once the user says they all passed. Quick tasks have none.

### Outcome

`/pm:task-close` appends this at the end of the file:

```markdown
## Outcome
**Closed:** 2026-10-30 by Jane Doe. **Merged:** a1b2c3d into release/next.
- What shipped: <bullets>
- Changed from the plan: <bullets, or "Nothing.">
- Docs updated: <code-doc paths (on the task branch) and .pm paths, or "None.">
- Production steps for the release: <commands or migrations to run when the release is deployed, or "None.">
- Commits: <short SHA — subject, one per line>
```

For a hotfix, the `**Merged:**` part reads `**Merged:** not yet (ships as a hotfix).`; `/pm:release-ship` sets the task's `merge` frontmatter when it ships.

## Quick format

For very small, simple changes (a wording change, a small bug fix) and every hotfix. No numbered sections:

```markdown
# T-042: <title>

**Goal:** <one or two sentences>

## Summary
<What changes, in a few bullets or a short paragraph, naming the files.>

## Build order
1. **<Step name>.** <What to change, naming the files.> **Verify:** `<command>` <and what passing looks like>.

## Acceptance
1. <How the user can tell it's done.>
```

- Usually one Build order step; the same `**Done.**` / `**Blocked:**` marks apply.
- `## Decisions` is added (after Summary, same cell format as the full format) only if the build had to decide something.
- No Docs list: `/pm:task-implement` still fixes any `CLAUDE.md` passage the change makes wrong.
- No `## Manual acceptance`.
- `## Outcome` is appended at close, as above.

## Writing rules

- **Self-contained:** define every term, name every file to touch or copy, and state every convention that applies. Don't write "as discussed" or "like we said".
- **Concrete:** exact names, values, messages, limits and orderings. Replace every "etc.", "handle appropriately", "some", "probably" and "TBD" with the actual answer, or move it to Open questions.
- **Honest about certainty:** every choice the user didn't confirm is marked `**Default, not confirmed:**`. Never present an assumption as settled; the hardening and build skills rely on these markers to find what's left.
- **Decisions keep their reasoning:** record the alternatives that were rejected and why, so the implementer doesn't reintroduce them.
- **Consistent with the codebase:** follow its conventions and the `.pm/` workflow and architecture docs (and say which), and flag any place the task deliberately departs from them.
- **About the code, not the task:** the task file lives on the `pm` branch, not with the code, so never ask for code, comments, tests or `CLAUDE.md` to cite it, its sections or its decision IDs. Anything that must outlive it goes in its **Docs** lists.
