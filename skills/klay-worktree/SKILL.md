---
name: klay-worktree
description: "Set up an isolated git worktree for a new feature, fix, or task in a TypeScript/AWS project. Handles branch naming, .gitignore guard, nvm Node switching, npm/yarn setup, .env and CDK context symlinking, and baseline verification."
when_to_use: "Automatically invoke this skill when the user says they are starting work on a feature, fix, task, ticket, or story — phrases like 'I want to work on', 'let's start on', 'I'm going to implement', 'starting feature', 'working on ticket', 'new branch for', 'let me fix'. Do not wait for the user to ask explicitly. Skip if the user is already inside a worktree or says to work in the current directory."
argument-hint: "<feature or fix description, e.g. 'add payment retry logic' or 'fix auth token expiry'>"
allowed-tools: Bash(git *) Bash(npm *) Bash(yarn *) Bash(npx *) Bash(ln *) Bash(ls *) Bash(grep *) Bash(cat *) Bash(test *) Bash(mkdir *) Bash(node *)
---

# klay-worktree

Set up an isolated git worktree before starting feature work. Follow every step in order. Do not skip steps.

**Task:** $ARGUMENTS

---

## Step 1 — Detect existing isolation

```bash
git rev-parse --git-common-dir
git rev-parse --git-dir
```

Compare outputs:
- If they differ, you are already inside a worktree. Print: "Already in a worktree — no setup needed." Then **stop** and continue with the user's task.
- If identical, continue to Step 2.

Also run:
```bash
git worktree list
```
If a worktree for the same branch/task already exists, offer to reuse it instead of creating a new one.

---

## Step 2 — Derive branch name and worktree path

From `$ARGUMENTS`, derive:

**Branch slug rules:**
- Lowercase, hyphens only (replace spaces/slashes/special chars with `-`)
- Max 50 characters; strip leading/trailing hyphens
- Preserve ticket IDs if present (e.g. `ACQ-123` → `feat/acq-123-add-retry-logic`)
- Use `feat/` prefix for features, `fix/` for bug fixes

Examples:
- "add payment retry logic" → `feat/add-payment-retry-logic`
- "fix auth token expiry" → `fix/auth-token-expiry`
- "ACQ-456 refactor email service" → `feat/acq-456-refactor-email-service`

**Worktree path:**
```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
```

Detect which ignore pattern the project already uses:
```bash
grep -E "worktrees|\.worktrees" "$REPO_ROOT/.gitignore" 2>/dev/null
```
- If `.claude/worktrees` found → use `$REPO_ROOT/.claude/worktrees/<slug>`
- Otherwise → default to `$REPO_ROOT/.worktrees/<slug>`

Print derived values. Ask for confirmation if `$ARGUMENTS` is ambiguous.

---

## Step 3 — Guard: verify worktree parent directory is gitignored

```bash
git check-ignore -v "<worktree-parent-dir>/"
```

If not ignored — **stop and tell the user:**

> `<worktree-parent-dir>/` is not in `.gitignore`. Add one of these lines before continuing:
> - `.worktrees/`  (recommended default)
> - `.claude/worktrees`  (alternative used in some Qred projects)
>
> After adding it, re-run this skill.

Do not proceed to Step 4 without gitignore coverage.

---

## Step 4 — Create the worktree

Check if the branch already exists:
```bash
git branch --list <branch-name>
git branch -r --list "origin/<branch-name>"
```

**New branch (most common):**
```bash
git worktree add "$REPO_ROOT/<worktree-path>" -b <branch-name>
```

**Branch exists locally:**
```bash
git worktree add "$REPO_ROOT/<worktree-path>" <branch-name>
```

**Branch exists only on remote:**
```bash
git fetch origin <branch-name>
git worktree add "$REPO_ROOT/<worktree-path>" --track -b <branch-name> origin/<branch-name>
```

Confirm with:
```bash
git worktree list
```

---

## Step 5 — Switch Node version and install dependencies

**5a — Switch Node version with nvm (if project specifies one):**

Inside the worktree directory, check for a Node version file:
```bash
test -f .nvmrc && cat .nvmrc || (test -f .node-version && cat .node-version || echo "none")
```

If a version file exists, source nvm and switch (nvm is a shell function — must be sourced):
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install   # installs the version if missing
nvm use       # switches to .nvmrc / .node-version
node --version
```

If no version file is present, stay on the current Node version.

**5b — Detect package manager and install:**
```bash
test -f yarn.lock && echo "yarn" || (test -f package-lock.json && echo "npm" || echo "unknown")
```

Run inside the worktree directory (after switching Node):
- `yarn`: `yarn install --frozen-lockfile`
- `npm`: `npm ci` (fall back to `npm install` if lockfile is missing)
- Monorepo (has `workspaces` in root `package.json`): install at root level only

**Never copy these — they are regenerated:**
`node_modules/`, `dist/`, `cdk.out/`, `.aws-sam/`, `*.tsbuildinfo`

---

## Step 6 — Symlink environment and context files

Run from inside the worktree. `$REPO_ROOT` is the original checkout root.

```bash
# .env (general / SAM)
test -f "$REPO_ROOT/.env" && ln -sf "$REPO_ROOT/.env" ".env"

# SAM local invocation params
test -f "$REPO_ROOT/env.json" && ln -sf "$REPO_ROOT/env.json" "env.json"
test -f "$REPO_ROOT/.env.local.json" && ln -sf "$REPO_ROOT/.env.local.json" ".env.local.json"

# CDK AWS lookups cache — without this, cdk synth hits live AWS on every run
test -f "$REPO_ROOT/cdk.context.json" && ln -sf "$REPO_ROOT/cdk.context.json" "cdk.context.json"
```

`~/.aws/credentials` is shared globally — no action needed.

Verify:
```bash
ls -la | grep "^l"
```

---

## Step 7 — Verify baseline

Detect the right type-check command (in priority order):
1. `npm run compile` — if `"compile"` exists in `package.json` scripts
2. `npm run typecheck` — if `"typecheck"` exists in `package.json` scripts
3. `npx tsc --noEmit` — always available as fallback

```bash
cat package.json | grep -E '"compile"|"typecheck"'
```

Run from inside the worktree:
```bash
<chosen-command>
```

**If passes:** Confirm and proceed.

**If fails:** Print error, then ask:
> "Baseline type-check failed. This may be a pre-existing issue. Continue anyway, or investigate first?"

Only continue if the user confirms.

---

## Step 8 — Summary and cleanup reminder

Print this at the end of every successful skill run:

```
Worktree ready.

  Path:    <worktree-path>
  Branch:  <branch-name>
  Base:    <base-branch>
  Node:    <node version used>

Symlinks:  <list what was symlinked, or "none">
Baseline:  passed ✓  (or: failed — user confirmed)

When you are done with this feature:

  git worktree remove <worktree-path>    # remove the worktree
  git branch -d <branch-name>            # after PR is merged
  git worktree prune                     # clean up stale refs
```
