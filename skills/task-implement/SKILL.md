---
name: task-implement
description: Use only when the user asks to implement, build or resume a pm task by its ID. Step 3 of the pm task process. Build a task from its task file in .pm/ (written by /pm:task-create, ideally hardened by /pm:task-harden). Confirms every open question, default and run setting up front (a quick task asks nothing), then runs unattended to the end, with no further questions: works through the task's build order step by step on its own branch, dispatching an implementer subagent and an independent reviewer for each step, verifies, commits and pushes every step, then runs a security audit, automated user testing and the docs, and ends with a report and a manual acceptance checklist.
argument-hint: "<id>"
---

# Implement a task

Step 3 of 4 in the task process: `/pm:task-create` → `/pm:task-harden` → **`/pm:task-implement`** → `/pm:task-close`. The task file follows the format in `${CLAUDE_PLUGIN_ROOT}/reference/task-format.md`: a frontmatter `status` (`proposal`, `ready`, `in-progress`, `built`, `blocked`); sections **Decisions** (cells starting `**Confirmed:**` or `**Default, not confirmed:**`, IDs `D1`, `D2`…), **Open questions** (numbered, or `None.`), design sections, **Tests**, **Build order** (steps with a `**Verify:**`), **Acceptance**, **Docs** and **Out of scope**. Keep it in that format when you write to it: `/pm:task-close` and `/pm:status` read the frontmatter and the Build order's **Done.** marks.

Build what a task describes, one build step at a time. You are the **orchestrator**: you read the task file, brief subagents, check their work and talk to the user. Subagents write the code. Keep your own context for decisions and verification, not for file dumps.

The task file is the source of truth. Subagents build what it says, not what they think is better. Where the task is wrong or silent, the answer is written back into the task file, so the task and the code never disagree.

Never report something as passing that you didn't see pass. If a check fails, say so with its output.

## Unattended run

The user usually starts this skill and leaves (for example at the end of the day), expecting the build finished when they return. So the run has two phases:

1. **Kickoff (steps 1–4):** gather everything that needs the user's say, ask it all in one sitting, and write the answers into the task file.
2. **Build (steps 5–11):** runs to the end with **no further questions and no pauses**. Never call `AskUserQuestion`, never end a turn waiting for a reply, and never stop to report progress mid-run. Progress lines are fine, but keep working after them. When background agents are running, wait for their notifications and carry on. The only things you leave for the user are in the final report.

During the build, anything that would have been a question is settled by the **decision rule**: choose the option that best fits the task's intent, its confirmed decisions and `CLAUDE.md`; between equals, take the most conservative one (smallest change, least new surface, no data-model or permission loosening, easiest to reverse). Record it in the task's **Decisions** as a new `D` cell starting `**Default, not confirmed:**`, ending "(chosen during the unattended build: <why>)", edit every section it touches, and list it in the report for the user to confirm. A quick task with no **Decisions** gets a `## Decisions` section after its Summary for these, in the same cell format. If no option is safe without the user (it would be destructive, irreversible, touch production, need a secret or account the run doesn't have, or reverse a `**Confirmed:**` decision), don't guess: mark the step **blocked** (step 6f), skip the steps that depend on it, and carry on with the rest.

## Kickoff

Every question in the kickoff uses `AskUserQuestion`. When it isn't available (a headless `claude -p` run), ask the same questions, with the same options numbered and the recommendation marked, in plain text as the last thing in your message, and end your turn; carry on from that point when the answers arrive.

### 1. Find and read the task
First read `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md` (the operating rules: layout, git flow, pushing, sync, commit messages, workflow files) and `${CLAUDE_PLUGIN_ROOT}/reference/task-format.md`. Locate `.pm/` with `sh ${CLAUDE_PLUGIN_ROOT}/scripts/pm-dir.sh`; if it exits 1, stop with "pm is not set up in this clone: run /pm:docs-init." Run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/pm-sync.sh <pm>` and handle its exit code as `conventions.md` says (stop and report on 1 or 2).

Then check the workflow sections this skill uses, before changing anything: in `<pm>/workflows/testing.md`, `## Full check` and `## Environment`, plus `## Conditional checks`, `## Security-sensitive paths` and `## Quick checks` when they're present. A section is undefined when its heading is missing, it's empty, or it still contains a `<!-- fill in: … -->` comment (`None.` is defined; an absent optional section means none). If any is undefined, stop and name each undefined file and section (e.g. "`## Full check` in `.pm/workflows/testing.md` isn't filled in"), leaving the task and branches as they were. Never guess a command.

Use the ID in `$ARGUMENTS` (`T-042`, or `42` for `T-042`) and find `<pm>/tasks/backlog/T-042-*.md` (status `proposal` or `ready`) or `<pm>/tasks/active/T-042-*.md` (a resumed run). If it's in `tasks/done/`, say it's done and stop: done tasks aren't built or edited again. If there isn't an ID, look for tasks in `backlog/` with `status: ready`: use it if there's exactly one, and ask with `AskUserQuestion` if there are several. If the chosen task is already `built` (for example after `/pm:task-close`'s **Some failed** answer), don't rebuild it: see **Revising a built task** below.

Read the **whole** task file, the project's `CLAUDE.md` (and `README` if there's no `CLAUDE.md`), `<pm>/README.md` and `<pm>/workflows/testing.md`. From `testing.md`, note the full check (`## Full check`), the conditional checks (`## Conditional checks`), any quick checks, and how to start the environment (`## Environment`); from `CLAUDE.md`, the commands for single tests, types and linting, and its conventions and non-negotiables. Every brief you write later repeats the ones that apply.

### 2. Collect what the task leaves open
Don't ask anything yet: collect the items for step 4. A status of `ready` means `/pm:task-harden` found nothing left to guess; still run these checks, since the code may have moved on since. Look for anything an implementer would have to guess about:
- entries under **Open questions** (anything but `None.`);
- decisions marked `**Default, not confirmed:**`;
- `TBD`, "or", "we could", "etc." in design sections;
- a **Build order** step without a `**Verify:**`, or missing **Acceptance** or (in a full task) **Docs** sections.

Then **look ahead for questions the build would otherwise hit later**, since there's no asking once it starts. Read each Build order step against the code it touches and spot-check the task's claims (paths, class names, schema, routes, existing tests). Note anything that would make an implementer stop: a wrong claim the code doesn't settle, a step that needs a change outside the task, a missing message text or limit, an external service or key the step needs, a dependency the task implies but doesn't name. Where the code settles the answer, note the fix: it's written into the task file with the kickoff answers in step 4, so nothing changes before step 3's checks pass. Collect the rest.

If the status is `in-progress` or `blocked`, or Build order steps already end in **Done.** from an earlier run, note it: the run resumes at the first step that isn't (step 4 still runs, and the baseline includes the steps already built). Steps marked **Blocked:** by an earlier run go into the kickoff questions.

### 3. Inspect the workspace
Don't ask anything yet, except where this step says so:
- Run `git status --porcelain` and `git branch --show-current` in the code checkout (ignoring `.pm/`). If there are uncommitted changes, or HEAD is detached, stop and ask the user to commit or stash them first; never stash, reset or discard them yourself.
- Run `git fetch origin` (when there's an `origin`) and work out the base: `release/next` for a task, the default branch for a hotfix (`type: hotfix`), as `conventions.md` describes. If the base doesn't exist locally or on origin, stop and say so (for `release/next`: no release is open, so wait for `/pm:release-deployed` to open the next one).
- Work out the task branch: the frontmatter `branch` if set, otherwise `task/T-042-<slug>` (`hotfix/T-042-<slug>` for a hotfix), with the task file's slug. If that branch already exists (locally or on origin) but the task isn't in `active/`, report it with its latest commits and ask with `AskUserQuestion` whether to reuse it or stop; ask this even for a quick task. If the user chooses to stop, stop here.
- Check that the project's environment is up (for example its containers are running) and that the commands respond, with a quick command, not the full check. If it's down, start it the way `## Environment` says. If it can't be started, that goes into step 4 as well (for a quick task, stop and report it).

### 4. Confirm everything up front
**A quick task (`quick: true`) skips this step entirely:** it asks nothing, and every run setting below takes its recommended option. Its plan items (from step 2) are settled by the decision rule and written into the task file, with step 2's fixes, as build-time decisions. Go straight on to step 5.

For a full task, ask every question in one sitting with `AskUserQuestion` (up to four questions per call; make as many calls back to back as needed). Each question: concrete options, the recommended one first with "(Recommended)", and a one-line trade-off each. Start with a few lines saying how many questions are coming and that the build then runs without asking anything.

**Plan items** (from step 2), one question each:
- each open question and each look-ahead item: the options you see;
- each `**Default, not confirmed:**` decision: keep the default as written (usually recommended), or the alternatives;
- if there are many, or they suggest the task isn't ready, include a first question offering to stop and run `/pm:task-harden T-042` instead.

**Run settings**, every time (skip only the ones that don't apply):
1. **Baseline failures**, if the full check already fails before the build: go on and judge later failures against the baseline (Recommended), or fix them first as an extra step 0.
2. **Questions during the build:** decide by the decision rule and record it for review (Recommended), or skip the affected step and its dependents and carry on with the rest.
3. **Medium security findings:** fix them (Recommended), or list them in the report only. Critical and high findings are always fixed.

Write the answers, and step 2's fixes, into the task file the way `/pm:task-harden` would: edit every part of the task the answer touches, starting the Decision cell with `**Confirmed:**` (a new decision takes the next free `D` number; never renumber). Defaults the user keeps become `**Confirmed:**` with "(default accepted at build time)", so the task no longer reads as undecided. Answers to look-ahead items that aren't task decisions (a missing key) go into your run notes. If the user chose to stop, commit the answers (`sh ${CLAUDE_PLUGIN_ROOT}/scripts/pm-commit.sh <pm> 'Harden T-042: <what it settled>'`) and stop here.

Then tell the user in a few lines: the run settings, the work packages (step 5's list), and that permission prompts would also pause the run, so the session should be in a mode that doesn't prompt for the project's commands (for example auto mode). This is the last message that expects anything from them. Go straight on.

## Build

### 5. Prepare and plan the dispatch
- **Start the task.** Check out the task branch, following `conventions.md`'s Git flow:
  - **New:** check out the base (`git switch <base>`, or `git switch --track origin/<base>` if it exists only on origin); if it's behind origin, `git merge --ff-only origin/<base>`; if the two have diverged, stop and report it. Then `git switch -c <branch>` and push it with `git push -u origin <branch>`.
  - **Existing** (a resumed run, a reused branch, or work started on another machine): if it exists only on origin, `git switch --track origin/<branch>`; otherwise check it out, and if it's behind origin, `git merge --ff-only origin/<branch>`; if the two have diverged, stop and report it. The run carries on from the first Build order step without `**Done.**`.
  - In `<pm>`: if the task is in `backlog/`, `git -C <pm> mv` it to `tasks/active/`. Set `status: in-progress`, `owner` to `git config user.name` and `branch` to the branch name. Commit with `sh ${CLAUDE_PLUGIN_ROOT}/scripts/pm-commit.sh <pm> 'Start T-042'` (it also carries the kickoff answers), handling its exit code as `conventions.md` says. On a resumed run with nothing to change, there's nothing to commit.
  - A hotfix's release doc isn't created here: `/pm:task-close` creates it.
- Pushes: every code push in this run is a plain `git push origin <branch>` of the task branch (with `-u` the first time). Never push the default branch, `release/next` or tags, and never `--force`. If a push is rejected (someone else pushed that branch), stop the run, leaving the local commits; never pull or rebase the branch to get past it. Before stopping, keep `.pm/` clean: set the task's `status: blocked` (moving it to `tasks/active/` with `git -C <pm> mv` if it's still in `backlog/`), append ` **Blocked:** pushing <branch> was rejected: <git's message>.` to the step being built (the first step without `**Done.**`), and commit `.pm/` with `sh ${CLAUDE_PLUGIN_ROOT}/scripts/pm-commit.sh <pm> 'Block T-042'`. Report the branch and git's message. With no `origin`, nothing is pushed; say so once in the report.
- Run the full check (`## Full check` in `testing.md`, with the environment started as `## Environment` says) on the new branch to record the **baseline**, then each conditional check whose condition the diff (`git diff --name-only <base>...HEAD`) meets; when unsure whether a condition applies, run the check, and note each conditional check run or skipped, and why. If anything already fails, write down exactly what and follow the step 4 setting (judge later failures against it, or fix it first as step 0 through an agent). Later failures are judged against this baseline.

Turn the task's **Build order** into work packages, one per step, keeping its order. Use the task's own steps; don't regroup or reorder them unless a step is too large for one agent (then split it into sub-steps that each end in something verifiable).

Run packages **one after another** by default: later steps build on earlier ones. Run two packages in parallel only when both are true:
- neither needs the other's output, and
- they touch **disjoint files** (for example a server step and an unrelated client component). Shared files such as route files, type files, `CLAUDE.md`, migrations and test helpers count as overlapping.

Note for each package which earlier packages it depends on, so a blocked step only skips its dependents.

### 6. Build each step
For each package, do the following. Don't start the next package until this one is verified (or blocked).

**a. Brief the implementer.** Dispatch a `general-purpose` subagent (`Agent` tool). It sees nothing of this conversation, so the brief must stand on its own. Include:
- the task file's path, and the exact sections to read (the step itself, the design sections it implements, the decisions it relies on, its tests), plus `CLAUDE.md`;
- the step's text verbatim, and what is **not** part of this step (later steps' work), so it doesn't run ahead;
- what earlier steps already built (files and names), so it reuses them;
- the conventions and non-negotiables from `CLAUDE.md` that apply, by name;
- the commands to run (in the project's environment, e.g. inside its container);
- these working rules:
  - Read the files the task names, and the existing code it says to mimic, before writing anything. Match the surrounding code's style, naming and comment density.
  - Write the step's tests from the task's Tests section first, or alongside the code, and make them prove the rules (permissions, validation, edge cases), not just the happy path.
  - Validate input at the boundary, authorise before acting, scope every client-supplied ID, escape output, keep secrets out of code and logs, and keep multi-statement writes transactional.
  - Don't cite the task, its section numbers or its decision IDs (`D8`, `§4`) in code, comments, tests or docs: the task file lives on the `pm` branch, not with the code. Write the reason itself where one is needed.
  - Don't add dependencies, features, refactors or files the task doesn't call for. Don't weaken, skip or delete an existing test to make it pass. Don't silence a linter or type error with ignores.
  - Don't run destructive commands against anything but the local dev and test databases, never touch production, and don't commit.
  - Never ask the user anything; you can't reach them. **If the task is ambiguous, contradicts the code, or would need a change outside this step, stop and report the question** with the options you see and the one you'd pick. Don't guess.
- the report it must return, and nothing longer:
  ```
  STATUS: done | blocked
  FILES: <each file created or changed, one line each, with what changed>
  TESTS: <tests added or changed, and what each proves>
  CHECKS: <each command run and its result: pass, or the failing output>
  DEVIATIONS: <anything done differently from the task, and why; "none">
  QUESTIONS: <anything blocking or uncertain, with options and the one it would pick; "none">
  ```

**b. Handle a blocked report.** Don't ask the user. Settle the question by the decision rule (or skip the step, per the step 4 setting), write the answer into the task file (a `**Default, not confirmed:**` Decision cell with the next free `D` number, marked as chosen during the unattended build, and every section it touches), then resume the same agent with `SendMessage`, or brief a new one. If no option is safe without the user, go to **f** as blocked.

**c. Verify it yourself.** Don't take the report's word for it:
- `git diff --stat` and read the diff of the changed files: does it do what the step says, and only that?
- Run the step's **Verify** command from the task, plus the relevant tests, the type checker and the linter for the files touched. Compare against the baseline.
- Check that every test the task lists for this step exists and actually asserts the rule it names.

**d. Independent review.** Dispatch a second, fresh `general-purpose` subagent as the reviewer. Give it the task file's path and sections, `CLAUDE.md`, the list of files the step changed, and ask it to read the diff (`git diff -- <files>`, plus the new files) and report findings only, without editing anything:
- **Task conformance:** anything missing, extra or different from the task.
- **Correctness:** bugs, unhandled edge cases the task names, race conditions, wrong ordering, broken states (empty, error, read-only).
- **Conventions:** departures from `CLAUDE.md` and the surrounding code.
- **Security:** missing authorisation, unscoped IDs, unvalidated input, injection, XSS, data leaking into responses or props.
- **Tests:** rules without a test, tests that can't fail, assertions too weak to catch a regression.

Each finding: file and line, the problem, a concrete failure scenario, severity (`blocker`, `should-fix`, `nit`). Ask it to verify each finding against the code before reporting it, and to say "no findings" rather than invent one.

**e. Fix.** Send `blocker` and `should-fix` findings you agree with back to the implementer (`SendMessage`) or to a new fixer agent, then repeat **c**. Skip findings that contradict the task; if a finding shows the task itself is wrong, settle it by the decision rule and record it. At most **two** fix rounds per step; if it still doesn't verify, mark it blocked (**f**).

**f. Record progress.**
- **Verified:** if the step deviated from the task, edit the task's design sections (and Decisions) so they describe what was built. Commit the step's code on the task branch (`git add` its files, then `git commit -m '<message>'`: one short imperative line describing what the step does, per the user's commit style, with no body or trailer) and push it. Then append ` **Done.**` to the step in the task's Build order, so an interrupted run can resume, here or on another machine, and commit `.pm/` with `sh ${CLAUDE_PLUGIN_ROOT}/scripts/pm-commit.sh <pm> 'Finish step 3 of T-042'`, which also carries the task's edits for this step.
- **Blocked:** append ` **Blocked:** <what's failing or undecided, and what was tried>.` to the step in the Build order. Leave its work in place if it's coherent and the checks still pass at the baseline; otherwise revert this step's changes (only this step's files) so later steps build on a clean tree. Skip every step that depends on it, marking each ` **Blocked:** depends on step N.`, and carry on with the independent ones.

Then write one progress line ("Step 3 of 9 done: <what now works>.", or "Step 3 of 9 blocked: <why>.") and go straight on to the next package.

### 7. Full verification
After the last step:
- Every fix made from here on (regressions, security fixes, added browser tests, fixes found driving the app, in steps 7 to 9) is committed on the task branch as its own commit, one short imperative line describing it, and pushed before moving on. Never sweep a fix into `Update docs for T-042`.
- Run the **full check** (`## Full check` in `testing.md`), then each conditional check whose condition the diff (`git diff --name-only <base>...HEAD`) meets; when unsure whether a condition applies, run the check, and note each conditional check run or skipped, and why. Everything must pass, apart from failures already in the baseline. Fix regressions through a fixer agent, then re-run (at most two rounds; report what still fails).
- Read the whole feature diff (`git diff <base>...` or against the baseline) once yourself, looking for leftovers: debug output, commented-out code, TODOs, stray files, unused code.
- Go through the task section by section and check each behaviour, rule, message, limit and test exists, apart from blocked steps. List anything missing and build it (through an agent, verified as in step 6) before going on.

### 8. Security audit
For a quick task, run this step only when the diff touches a security-sensitive path: a changed file (`git diff --name-only <base>...HEAD`) matches when its path starts with one of the `- <path prefix>` lines under `## Security-sensitive paths` in `testing.md`. With no such section, or no matching file, skip it. Note whether the audit ran and which paths triggered it, for the report.

Dispatch a fresh `general-purpose` subagent for a security audit of the **whole feature diff**, not one step. Brief it with the task file, `CLAUDE.md`, the base commit or file list, and this checklist, asking for verified findings only (file, line, exploit scenario, severity `critical`/`high`/`medium`/`low`), no edits:
- **Authorisation:** every new route, endpoint, action and job checks who may do it, on the server; a member can't reach admin-only paths; access rules match the task's permissions exactly; hidden UI isn't the only protection.
- **Object access (IDOR):** every client-supplied ID is resolved within its scope (owner, tenant, period) before use.
- **Input:** validated on the server with limits on length, count and format; mass assignment isn't possible; enum and type values are checked.
- **Injection:** SQL (raw queries bound, no interpolated input), command, path traversal, header injection.
- **Output:** user content escaped; HTML sanitised by the project's sanitiser; no unsafe HTML rendering of unsanitised data; safe link schemes.
- **Data exposure:** responses, page props, logs, error messages and activity entries don't leak data the viewer may not see, or secrets.
- **Session and requests:** CSRF protection on writes, no state change on GET, redirects only to local paths.
- **Files and external services:** upload size and type limits, private storage, signed URLs with short lifetimes, timeouts and failure handling on outbound calls, no secrets in the client bundle.
- **Concurrency and integrity:** races that bypass a rule, writes that aren't transactional, constraints the database should enforce but doesn't.
- **Dependencies:** any newly added package is necessary and maintained; run the project's audit (`composer audit`, `npm audit --omit=dev` or the stack's equivalent) and report new advisories.

If the built-in `security-review` skill is available, run it as well and merge its findings. Fix every `critical` and `high` finding (through a fixer agent, then re-verify with step 7's checks); fix `medium` ones or list them, per the step 4 setting; list `low` ones in the report. Never accept a `critical` or `high` risk on the user's behalf: if one can't be fixed without the user, leave it unfixed, describe it at the top of the report, and set the task's status to `blocked` in step 10.

### 9. Automated user testing
A quick task skips this step: it gets no automated user testing and no manual acceptance checklist.

**a. Automated user flows.** Make sure every main flow in the task's **Acceptance** section and UI sections is covered by end-to-end tests in the project's browser-test setup, if it has one, including permission variants (an admin, a member, a read-only view) and the empty, error and read-only states. Add missing ones through an agent and run them.

**b. Drive the running app.** Start the app the way `## Environment` and `CLAUDE.md` describe (use the `run` skill if available, or a browser tool if one is connected) and walk through each **Acceptance** check as each kind of user the task names, with the demo or seed data. Check what the task says the user sees: wording, states, light and dark themes if the project has both, a narrow window if the task mentions it. Capture screenshots where a tool allows. Fix what's broken (through an agent, re-verified with step 7's checks) before the report. If no tool can drive the app, say so in the report and leave those checks to the manual script.

**c. Write the manual acceptance script.** Don't ask the user to run it now; it goes in the task file and in the report. A short, numbered list: where to go, which account to sign in as (from `CLAUDE.md` or the seeder), what to do, and what they should see, one line per check, covering the task's **Acceptance** checks and anything automated tests can't prove (look and feel, real devices, real external services). Write it into the task file as a `## Manual acceptance` section right after **Acceptance**, one unticked box per check (`- [ ] 1. <where, which account, what to do, what you should see>`), replacing any earlier one. `/pm:task-close` asks the user about it before merging.

### 10. Docs and task status
- Make the edits the task's **Code docs** list names, on the task branch, through an agent or yourself, following the doc's own voice, for what was built (not blocked steps). If the feature also changes something else `CLAUDE.md` describes (routes, tables, actions, conventions, commands, test files), update those passages too, so `CLAUDE.md` stays accurate. Don't add a section about the task, and don't cite it or its IDs: the task file lives on the `pm` branch, not with the code. Don't edit `.pm/` docs other than the task file: the **`.pm/` docs** list is applied by `/pm:task-close` once the work is merged. Commit the edits on the task branch as `Update docs for T-042` and push; if there was nothing to change, skip the commit.
- Run the full check (and the conditional checks that apply, as in step 7) one last time if anything changed.
- If any step is blocked or a `critical`/`high` finding is unfixed, set the task's `status: blocked` and commit `.pm/` with `sh ${CLAUDE_PLUGIN_ROOT}/scripts/pm-commit.sh <pm> 'Block T-042'`. Otherwise set `status: built` and commit `.pm/` with `"Finish T-042"`.

### 11. Report
This is the first thing the user reads when they return. Lead with what needs them, then the rest, briefly:
- **Needs you:** blocked steps (why, what was tried, what's needed), any unfixed `critical`/`high` finding, and the decisions made during the build (`**Default, not confirmed:**` cells chosen by the decision rule, by `D` number with the choice and the reason) for them to confirm or change;
- what was built, step by step, in a line each;
- the checks run at the end and their results (counts, not adjectives), and each conditional check run or skipped, and why;
- security findings: what was fixed, and anything listed at `medium` or `low`; for a quick task, whether the audit ran and which paths triggered it;
- user testing: what was tested automatically and by driving the app;
- the **manual acceptance script** (step 9c);
- deviations from the task, if any;
- the task branch and its pushed commits (`git log --oneline <base>..<branch>`), and anything not pushed and why.

End by saying the user can reply with the numbers of any acceptance checks that failed (with what they saw) or with changes to the build-time decisions. Then:
- **If they report failures or change decisions:** fix through an agent, re-verify (step 7's checks), commit and push the fix on the task branch the same way, update the task file (decisions become `**Confirmed:**`) and commit `.pm/` (`Revise T-042: <what changed>`), and give them just the affected checks to re-run.
- **If they accept the build-time decisions as they are:** turn those cells into `**Confirmed:**` and commit `.pm/` (`Revise T-042: confirm the build-time decisions`).

Then end with the next step:
- a `built` full task: "Run /pm:task-close T-042 once you've checked the manual acceptance list.";
- a `built` quick task: "Run /pm:task-close T-042 when you're happy with it.";
- a `blocked` task: name what blocks it, and say to rerun `/pm:task-implement T-042` once that's resolved.

## Revising a built task

When step 1 finds the task `built`, run step 3's checks, then check out its branch as step 5's **Existing** case says. Ask with `AskUserQuestion` (or in plain text, as the kickoff says) which manual acceptance checks failed and what the user saw, unless `$ARGUMENTS` already says. Then, with no further questions:
- fix each through an agent, re-verify with step 7's checks, and commit and push each fix on the task branch as its own one-line commit;
- record in the task file any decision a fix makes or changes; untick nothing (`/pm:task-close` asks about the checklist again) and keep `status: built`;
- commit `.pm/` with `sh ${CLAUDE_PLUGIN_ROOT}/scripts/pm-commit.sh <pm> 'Revise T-042: <what changed>'`;
- report what was fixed, the checks and their results, and the commits, ending as step 11 does.
