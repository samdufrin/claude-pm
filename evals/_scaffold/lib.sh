# Shared helpers for eval case scaffolds.
#
# A case's scaffold script (evals/<case>/scaffold.sh, named in its case.yaml as
# context.scaffold_script) runs with the empty workspace as its working
# directory, no arguments and a minimal environment (PATH, a temporary HOME,
# TMPDIR). It sources this file and calls the functions below, all of which
# act on the working directory:
#
#   . "$(dirname "$0")/../_scaffold/lib.sh"
#   make_project
#   setup_pm
#   open_release_next
#   add_task active T-001 fix-footer title="Fix the footer" status=built
#   pm_commit "Add T-001 Fix the footer"
#   snapshot_refs
#   report_unchanged origin master
#
# Layout it builds, all inside the workspace (the agent can only write there):
#   ./                  the project: a made-up "Sample notes" app on master
#   ./_eval/origin.git  its bare origin
#   ./_eval/<name>      second clones (second_clone)
#   ./.pm               the pm worktree (setup_pm)
#   ./evals-report.sh   the report script the prompt runs (make_project)
# _eval/, evals-report.sh and eval-report.txt are in .git/info/exclude, so
# the checkout stays clean.
#
# Every function exits the scaffold on failure (set -eu).

set -eu

# Every function below writes into the working directory and builds a git
# repo there. The eval runner starts each scaffold in a new, empty workspace,
# so refuse anything else: run by hand from the plugin repo or a real project,
# these helpers would rewrite that repo's files and history.
if [ -n "$(ls -A .)" ]; then
    echo "lib.sh: refusing to run in $(pwd): it isn't empty. Scaffolds build a scratch git repo in the current directory, so run them only in a new, empty workspace (the eval runner does this)." >&2
    exit 1
fi

PM_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
PM_TEMPLATES=$PM_ROOT/templates
PM_SCAFFOLD=$PM_ROOT/evals/_scaffold
PROJECT=$(pwd)
ORIGIN=$PROJECT/_eval/origin.git
DEFAULT_BRANCH=master

# Quiet, deterministic git for the scaffold itself.
export GIT_AUTHOR_NAME="Eval User" GIT_AUTHOR_EMAIL="eval-user@example.com"
export GIT_COMMITTER_NAME="Eval User" GIT_COMMITTER_EMAIL="eval-user@example.com"

# git_local <repo>: sets the identity and safe defaults in one repo's config,
# so the agent's own commits there use them too.
git_local() {
    git -C "$1" config user.name "Eval User"
    git -C "$1" config user.email "eval-user@example.com"
    git -C "$1" config commit.gpgsign false
    git -C "$1" config tag.gpgsign false
}

# fill_template <template> <dest> [name=value ...]: copies a template,
# replacing each {{name}} with its value (literally; values may hold any
# character but a newline).
fill_template() {
    src=$1
    dst=$2
    shift 2
    mkdir -p "$(dirname "$dst")"
    PAIRS=$(printf '%s\n' "$@") awk '
        BEGIN {
            n = split(ENVIRON["PAIRS"], list, "\n")
            for (i = 1; i <= n; i++) {
                eq = index(list[i], "=")
                if (eq == 0) continue
                keys[i] = "{{" substr(list[i], 1, eq - 1) "}}"
                vals[i] = substr(list[i], eq + 1)
            }
        }
        {
            line = $0
            for (i = 1; i <= n; i++) {
                if (!(i in keys)) continue
                out = ""
                while ((at = index(line, keys[i])) > 0) {
                    out = out substr(line, 1, at - 1) vals[i]
                    line = substr(line, at + length(keys[i]))
                }
                line = out line
            }
            print line
        }
    ' "$src" > "$dst"
}

# set_fields <file> [key=value ...]: sets frontmatter keys (the first
# "key: ..." line inside the leading --- block). Keys must already exist: an
# unknown key stops the scaffold with an error.
set_fields() {
    file=$1
    shift
    for pair in "$@"; do
        key=${pair%%=*}
        value=${pair#*=}
        KEY=$key VALUE=$value awk '
            BEGIN { key = ENVIRON["KEY"]; value = ENVIRON["VALUE"] }
            NR == 1 && $0 == "---" { infm = 1; print; next }
            infm && $0 == "---" { infm = 0 }
            infm && !done && index($0, key ":") == 1 { print key ": " value; done = 1; next }
            { print }
            END { exit done ? 0 : 3 }
        ' "$file" > "$file.tmp" || {
            rm -f "$file.tmp"
            echo "set_fields: no frontmatter key '$key' in $file" >&2
            exit 1
        }
        mv "$file.tmp" "$file"
    done
}

# insert_claude_block <file>: inserts the CLAUDE.md block after the file's
# first paragraph (the first run of non-blank lines that aren't headings,
# ending at the next blank line), or at the end if it has none.
insert_claude_block() {
    BLOCK=$(cat "$PM_TEMPLATES/claude-md-block.md") awk '
        function block() { print ENVIRON["BLOCK"]; done = 1 }
        !done && inpara && $0 == "" { print; block(); print; inpara = 0; next }
        !done && $0 != "" && $0 !~ /^#/ { inpara = 1 }
        { print }
        END { if (!done) { if (NR) print ""; block() } }
    ' "$1" > "$1.tmp"
    mv "$1.tmp" "$1"
}

# exclude <pattern>: adds a line to the project's .git/info/exclude.
exclude() {
    mkdir -p "$PROJECT/.git/info"
    printf '%s\n' "$1" >> "$PROJECT/.git/info/exclude"
}

# make_project: a git repo on master with two commits, a passing check.sh, a
# CLAUDE.md and README, pushed to a bare origin whose HEAD is master. Also
# installs evals-report.sh. Optional: make_project --no-origin (no remote).
make_project() {
    git init --quiet -b "$DEFAULT_BRANCH" "$PROJECT"
    git_local "$PROJECT"
    exclude "/_eval/"
    exclude "/evals-report.sh"
    exclude "/eval-report.txt"
    cp "$PM_SCAFFOLD/evals-report.sh" "$PROJECT/evals-report.sh"

    cat > "$PROJECT/README.md" <<'MD'
# Sample notes

A tiny made-up notes app used to test the pm plugin.
MD
    cat > "$PROJECT/CLAUDE.md" <<'MD'
# Sample notes

A tiny made-up notes app. Run `sh check.sh` to check a change.

## Conventions
- Keep files small.
MD
    printf '#!/bin/sh\n# The full check of the sample project: always passes.\necho "all checks passed"\n' > "$PROJECT/check.sh"
    git -C "$PROJECT" add -A
    git -C "$PROJECT" commit --quiet -m "Initial commit"

    mkdir -p "$PROJECT/src"
    printf 'Welcome to Sample notes.\n' > "$PROJECT/src/home.txt"
    printf 'Copyright Sample notes. All rihgts reserved.\n' > "$PROJECT/src/footer.txt"
    git -C "$PROJECT" add -A
    git -C "$PROJECT" commit --quiet -m "Add the home page and footer"

    if [ "${1:-}" != --no-origin ]; then
        git init --quiet --bare -b "$DEFAULT_BRANCH" "$ORIGIN"
        git -C "$PROJECT" remote add origin "$ORIGIN"
        git -C "$PROJECT" push --quiet -u origin "$DEFAULT_BRANCH"
        git -C "$PROJECT" remote set-head origin "$DEFAULT_BRANCH"
    fi
}

has_origin() {
    git -C "$PROJECT" remote get-url origin >/dev/null 2>&1
}

# setup_pm [--full-check-undefined] [--no-baseline-push]: what /pm:docs-init
# leaves behind on a project with commits: the "Set up pm" commit on master
# (.gitignore, CLAUDE.md block, .claude/settings.json), tag v1.0.0 on it, and
# a .pm worktree on an orphan pm branch with README, both workflow files
# (every required section defined with trivial commands), the folders and a
# deployed baseline releases/1.0.0.md, committed and pushed (-u origin pm).
# By default master and v1.0.0 are pushed too, as the user would have done;
# --no-baseline-push leaves them local. --full-check-undefined leaves
# testing.md's ## Full check as a fill-in comment.
setup_pm() {
    full_check_undefined=false
    push_baseline=true
    for arg in "$@"; do
        case $arg in
        --full-check-undefined) full_check_undefined=true ;;
        --no-baseline-push) push_baseline=false ;;
        *) echo "setup_pm: unknown option $arg" >&2; exit 1 ;;
        esac
    done

    printf '.pm/\n' >> "$PROJECT/.gitignore"
    insert_claude_block "$PROJECT/CLAUDE.md"
    mkdir -p "$PROJECT/.claude"
    cat > "$PROJECT/.claude/settings.json" <<'JSON'
{
  "extraKnownMarketplaces": {
    "samduf": {
      "source": {"source": "github", "repo": "samdufrin/claude-pm"},
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "pm@samduf": true
  }
}
JSON
    git -C "$PROJECT" add -A
    git -C "$PROJECT" commit --quiet -m "Set up pm"
    git -C "$PROJECT" tag -a v1.0.0 -m "Release 1.0.0"
    if has_origin && [ "$push_baseline" = true ]; then
        git -C "$PROJECT" push --quiet origin "$DEFAULT_BRANCH" v1.0.0
    fi

    exclude ".pm/"
    git -C "$PROJECT" worktree add --quiet --orphan -b pm "$PROJECT/.pm"
    git_local "$PROJECT/.pm"
    pm=$PROJECT/.pm
    for d in architecture tasks/backlog tasks/active tasks/done; do
        mkdir -p "$pm/$d"
        : > "$pm/$d/.gitkeep"
    done
    fill_template "$PM_TEMPLATES/readme.md" "$pm/README.md" project="Sample notes"
    write_testing_md "$full_check_undefined"
    write_release_md
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    fill_template "$PM_TEMPLATES/baseline-release.md" "$pm/releases/1.0.0.md" \
        version=1.0.0 default_branch="$DEFAULT_BRANCH" now="$now" \
        merge="$(git -C "$PROJECT" rev-parse --short HEAD)"
    git -C "$pm" add -A
    git -C "$pm" commit --quiet -m "Set up pm docs"
    if has_origin; then
        git -C "$pm" push --quiet -u origin pm
    fi
}

# fill_sections <file> ["Heading=text" ...]: in a workflow file made from a
# template, replaces the fill-in comment under each named "## Heading" with
# its text (\n in the text becomes a new line). Sections not named keep
# their comment.
fill_sections() {
    file=$1
    shift
    PAIRS=$(printf '%s\n' "$@") awk '
        BEGIN {
            n = split(ENVIRON["PAIRS"], list, "\n")
            for (i = 1; i <= n; i++) {
                eq = index(list[i], "=")
                if (eq > 0) text[substr(list[i], 1, eq - 1)] = substr(list[i], eq + 1)
            }
        }
        /^## / { section = substr($0, 4) }
        skipping { if (index($0, "-->")) skipping = 0; next }
        index($0, "<!-- fill in:") == 1 && (section in text) {
            gsub(/\\n/, "\n", text[section])
            print text[section]
            if (!index($0, "-->")) skipping = 1
            next
        }
        { print }
    ' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
}

# write_testing_md [true|false]: .pm/workflows/testing.md from the template,
# with ## Full check `sh check.sh` (given true, left as its fill-in comment)
# and ## Environment None.
write_testing_md() {
    f=$PROJECT/.pm/workflows/testing.md
    mkdir -p "$(dirname "$f")"
    cp "$PM_TEMPLATES/testing.md" "$f"
    if [ "${1:-false}" = true ]; then
        fill_sections "$f" "Environment=None."
    else
        fill_sections "$f" 'Full check=```sh\nsh check.sh\n```' "Environment=None."
    fi
}

# add_testing_section <heading> <body>: appends "## <heading>" and its body to
# testing.md (e.g. add_testing_section "Conditional checks"
# "- When the diff touches ui/: sh check-ui.sh"). Commit it yourself.
add_testing_section() {
    printf '\n## %s\n%s\n' "$1" "$2" >> "$PROJECT/.pm/workflows/testing.md"
}

# write_release_md: .pm/workflows/release.md from the template with every
# section defined.
write_release_md() {
    f=$PROJECT/.pm/workflows/release.md
    mkdir -p "$(dirname "$f")"
    cp "$PM_TEMPLATES/release-workflow.md" "$f"
    fill_sections "$f" \
        'Deploy=Push the default branch and the tag: `git push origin master v<version>`. Pushing deploys nothing in this sample project.' \
        'After deploy=- [ ] Run `sh check.sh` on the deployed copy.' \
        'Rollback=Redeploy the previous tag.'
}

# pm_commit <message>: commits everything in .pm and pushes it if pm has an
# upstream.
pm_commit() {
    git -C "$PROJECT/.pm" add -A
    git -C "$PROJECT/.pm" commit --quiet -m "$1"
    if git -C "$PROJECT/.pm" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
        git -C "$PROJECT/.pm" push --quiet
    fi
}

# open_release_next: creates release/next from master (pushed -u when there's
# an origin) and writes .pm/releases/next.md (open), committed as "Open the
# next release".
open_release_next() {
    git -C "$PROJECT" branch release/next "$DEFAULT_BRANCH"
    if has_origin; then
        git -C "$PROJECT" push --quiet -u origin release/next
    fi
    add_release next kind=release branch=release/next
    pm_commit "Open the next release"
}

# add_release <stem> [key=value ...]: writes .pm/releases/<stem>.md from the
# release template (open, opened now), then sets any frontmatter keys, e.g.
# add_release 1.1.0 version=1.1.0 status=shipping tag=v1.1.0 "tasks=[T-001]".
# kind defaults to release and branch to release/next. Doesn't commit.
add_release() {
    stem=$1
    shift
    kind=release
    branch=release/next
    for pair in "$@"; do
        case $pair in
        kind=*) kind=${pair#kind=} ;;
        branch=*) branch=${pair#branch=} ;;
        esac
    done
    fill_template "$PM_TEMPLATES/release.md" "$PROJECT/.pm/releases/$stem.md" \
        kind="$kind" branch="$branch" name="$stem" \
        opened="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    set_fields "$PROJECT/.pm/releases/$stem.md" "$@"
}

# add_release_task_line <stem> <line>: replaces "None yet." under ## Tasks of
# releases/<stem>.md with <line>, or appends <line> after the existing ones.
add_release_task_line() {
    f=$PROJECT/.pm/releases/$1.md
    awk -v line="$2" '
        $0 == "## Tasks" { print; intasks = 1; next }
        intasks && $0 == "None yet." { print line; intasks = 0; added = 1; next }
        intasks && $0 == "" { if (!added) print line; intasks = 0; added = 1 }
        { print }
    ' "$f" > "$f.tmp"
    mv "$f.tmp" "$f"
}

# add_task <folder> <id> <slug> [key=value ...]: writes
# .pm/tasks/<folder>/<id>-<slug>.md in the quick format, then sets any
# frontmatter keys. Defaults: title from the slug, type fix, priority normal,
# status by folder (backlog: ready, active: built, done: done), one build
# step, marked Done. outside the backlog. Doesn't commit.
add_task() {
    folder=$1
    id=$2
    slug=$3
    shift 3
    title=$(printf '%s' "$slug" | tr '-' ' ' | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }')
    for pair in "$@"; do
        case $pair in title=*) title=${pair#title=} ;; esac
    done
    case $folder in
    backlog) status=ready ;;
    active) status=built ;;
    done) status=done ;;
    *) echo "add_task: unknown folder $folder" >&2; exit 1 ;;
    esac
    f=$PROJECT/.pm/tasks/$folder/$id-$slug.md
    fill_template "$PM_TEMPLATES/quick-task.md" "$f" \
        id="$id" title="$title" type=fix priority=normal owner="Eval User" \
        date="$(date +%F)" goal="$title." \
        summary="- $title in the sample project." \
        step_name="$title" step="Make the change in \`src/\`." \
        verify="\`sh check.sh\` passes." \
        acceptance="1. The change is visible in \`src/\`."
    set_fields "$f" status="$status" "$@"
    if [ "$folder" != backlog ]; then
        sed 's/^\(1\. \*\*.*\*\*Verify:\*\* .*\)$/\1 **Done.**/' "$f" > "$f.tmp"
        mv "$f.tmp" "$f"
    fi
}

# work_branch <branch> <base>: creates <branch> from <base> (pushed -u when
# there's an origin, unless --local is given as a third argument).
work_branch() {
    git -C "$PROJECT" branch "$1" "$2"
    if has_origin && [ "${3:-}" != --local ]; then
        git -C "$PROJECT" push --quiet -u origin "$1"
    fi
}

# commit_on <branch> <path> <content> <message> [--no-push]: switches to
# <branch>, writes <content> (plus a newline) to <path>, commits it, pushes
# the branch if it has an upstream (unless --no-push), and switches back to
# master.
commit_on() {
    git -C "$PROJECT" switch --quiet "$1"
    mkdir -p "$(dirname "$PROJECT/$2")"
    printf '%s\n' "$3" > "$PROJECT/$2"
    git -C "$PROJECT" add -- "$2"
    git -C "$PROJECT" commit --quiet -m "$4"
    if [ "${5:-}" != --no-push ] &&
        git -C "$PROJECT" rev-parse --abbrev-ref "$1@{upstream}" >/dev/null 2>&1; then
        git -C "$PROJECT" push --quiet origin "$1"
    fi
    git -C "$PROJECT" switch --quiet "$DEFAULT_BRANCH"
}

# second_clone <name>: clones origin into _eval/<name> (all branches fetched,
# identity "Other User") and prints its path, for simulating a teammate.
second_clone() {
    dir=$PROJECT/_eval/$1
    git clone --quiet "$ORIGIN" "$dir"
    git -C "$dir" config user.name "Other User"
    git -C "$dir" config user.email "other-user@example.com"
    git -C "$dir" config commit.gpgsign false
    printf '%s\n' "$dir"
}

# report_cmd <command>: registers a case-specific command for evals-report.sh,
# which runs it (sh -c, from the project root) under a "== <command>" header
# after its standard sections. One command per line of _eval/report-extra.
# Use it to print plain yes/no lines graders can match, e.g.
#   report_cmd 'git merge-base --is-ancestor master release/next && echo master-in-next || echo master-not-in-next'
report_cmd() {
    mkdir -p "$PROJECT/_eval"
    printf '%s\n' "$1" >> "$PROJECT/_eval/report-extra"
}

# ref_name <side> <branch>: the snapshot name for a branch, e.g.
# "origin-release-next" for origin release/next.
ref_name() {
    printf '%s-%s\n' "$1" "$(printf '%s' "$2" | tr '/' '-')"
}

# ref_sha <side> <branch>: the branch's current full SHA, locally (side
# "local") or on origin (side "origin"), or "none" if it doesn't exist.
ref_sha() {
    if [ "$1" = local ]; then
        sha=$(git -C "$PROJECT" rev-parse -q --verify "refs/heads/$2" 2>/dev/null) || sha=
    else
        sha=$(git -C "$PROJECT" ls-remote origin "refs/heads/$2" 2>/dev/null | cut -f1)
    fi
    printf '%s\n' "${sha:-none}"
}

# snapshot_refs [branch ...]: records each branch's SHA, locally and on
# origin, in _eval/before/<side>-<branch with / as ->, e.g.
# _eval/before/origin-master. Default branches: master release/next pm. Call
# it at the end of the scaffold, once everything is set up.
snapshot_refs() {
    [ $# -gt 0 ] || set -- "$DEFAULT_BRANCH" release/next pm
    mkdir -p "$PROJECT/_eval/before"
    for branch in "$@"; do
        for side in local origin; do
            ref_sha "$side" "$branch" > "$PROJECT/_eval/before/$(ref_name "$side" "$branch")"
        done
    done
}

# report_unchanged <side> <branch>: registers a report command printing
# "<name>-unchanged" or "<name>-changed" (name as in snapshot_refs, e.g.
# origin-master-unchanged), comparing the branch now with its snapshot.
report_unchanged() {
    name=$(ref_name "$1" "$2")
    if [ "$1" = local ]; then
        now="git rev-parse -q --verify refs/heads/$2 || echo none"
    else
        now="git ls-remote origin refs/heads/$2 | cut -f1 | grep . || echo none"
    fi
    report_cmd "[ \"\$($now)\" = \"\$(cat _eval/before/$name)\" ] && echo $name-unchanged || echo $name-changed"
}
