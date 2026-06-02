---
name: klay-manage-git-worktrees
description: Manage git worktrees to work on multiple branches simultaneously in separate directories. Use when the user wants to work on multiple branches at once, run parallel agents on different branches, set up a worktree, or mentions git worktree.
---

# Git Worktree Management

Use git worktrees to check out multiple branches of the same repo in separate directories. Each worktree gets its own working tree while sharing git history, making it ideal for running multiple windows/agents on different branches.

## Creating a Worktree

### 1. Determine the setup

- **Worktree directory**: `.worktrees/` inside the repo root (e.g., `<repo-root>/.worktrees/<branch-name>`)
- **Naming convention**: use the branch name as the directory name (e.g., `.worktrees/fix-auth`)
- **Base branch**: `main` (default) — create the new branch from here unless the user specifies otherwise

### 2. Ensure the directory is gitignored

Before creating any worktree, verify `.worktrees/` is in `.gitignore`:

```bash
git check-ignore -q .worktrees 2>/dev/null || echo ".worktrees/" >> .gitignore
```

### 3. Create the worktree

For a **new branch** (most common):

```bash
git worktree add .worktrees/<branch-name> -b <branch-name> <default-base>
```

For an **existing branch**:

```bash
git worktree add .worktrees/<branch-name> <branch-name>
```

## Rebasing a Branch in a Worktree

Use a temporary worktree to rebase a branch onto main (or another base branch) without disrupting the main workspace. This is useful when you want to keep the main workspace clean or avoid conflicts with running dev servers.

### When the branch is already checked out in the main workspace

Git does not allow the same branch to be checked out in two worktrees simultaneously. If the main workspace is on the branch you want to rebase, **detach HEAD first** to free the branch:

```bash
git checkout --detach
```

### Steps

```bash
# 1. Create a temporary worktree for the branch
git worktree add .worktrees/rebase-<branch-name> <branch-name>

# 2. Full-fetch inside the worktree to update all remote refs
cd .worktrees/rebase-<branch-name>
git fetch origin

# 3. Rebase onto <default-base> (e.g., origin/main or origin/master)
git rebase origin/<default-base> 

# 4. Resolve conflicts if any (see "Resolving Conflicts" below)

# 5. Force-push the rebased branch (use --force-with-lease for safety)
git push --force-with-lease origin <branch-name>

# 6. Return to <default-base> workspace, remove the worktree, and re-checkout
cd <repo-root>
git worktree remove .worktrees/rebase-<branch-name>
git checkout <branch-name>

# 7. Sync local branch with the pushed rebase (local still has pre-rebase commits)
git fetch origin <branch-name>
git reset --hard origin/<branch-name>

# 8. Verify the rebase landed on latest <default-base>
git merge-base HEAD origin/<default-base>  # should equal origin/<default-base> HEAD
```

**Important:** Use `git fetch origin` (full fetch) in step 2, not `git fetch origin main`. A branch-specific fetch only updates `FETCH_HEAD` and may not update the `origin/main` tracking ref, causing the rebase to land on a stale base.

The `git checkout` in step 6 will warn about "leaving commits behind" — these are the pre-rebase commits on the detached HEAD, which are safe to discard since the rebased versions have been pushed.

### Resolving Conflicts

If the rebase stops with conflicts:

1. Check which files conflict: `git status`
2. Resolve each file — prefer preserving both sides when safe
3. Stage resolved files: `git add <file>`
4. Continue the rebase: `git rebase --continue`
5. Repeat until all commits are applied

Do **not** install dependencies or run builds in this worktree — it is only needed for the git operations. The worktree is deleted immediately after.

## Listing Worktrees

```bash
git worktree list
```

## Removing a Worktree

When the user is done with a worktree:

```bash
git worktree remove .worktrees/<branch-name>
```

If the worktree has uncommitted changes, warn the user before using `--force`.

## Pruning Stale Worktrees

If a worktree directory was manually deleted:

```bash
git worktree prune
```

## Important Notes

- Never create a worktree for a branch that is already checked out elsewhere — git will reject it.
- Each worktree needs its own dependency install — `node_modules`, `vendor`, etc. are not shared.
- Commits made in any worktree are immediately visible in all others (shared `.git`).
- The main repo's `.git` directory is the source of truth; worktrees contain a `.git` file (not directory) that points back to it.
- All worktrees live inside `.worktrees/` to keep them colocated with the repo and visible in Source Control panel.
