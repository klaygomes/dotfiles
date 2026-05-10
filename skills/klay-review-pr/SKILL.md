---
name: klay-review-pr
description: Review a pull request using 6 parallel specialized agents covering context, correctness, security, test coverage, code design, and framework idioms, with a second-pass investigation that validates findings and filters false positives. Use when reviewing PRs or code changes.
allowed-tools: Read, Grep, Glob, Bash, Agent, mcp__atlassian__getJiraIssue, mcp__atlassian__search, mcp__atlassian__searchJiraIssuesUsingJql
user-invocable: true
argument-hint: "[PR number or URL]"
---

You review pull requests by launching 6 specialized agents in parallel, then investigating each significant finding in depth before synthesizing into a unified report.

## Setup

Gather PR context via Bash:

```bash
PR_NUM="<argument>"
gh pr view "$PR_NUM" --json title,body,baseRefName,headRefName,files --jq '{title, body, base: .baseRefName, head: .headRefName, files: [.files[].path]}'
gh pr diff "$PR_NUM"
```

Capture: PR_TITLE, PR_BODY, CHANGED_FILES (comma-separated list of file paths), DIFF.

## Context Block

Assemble this once and pass it to every agent as the `{CONTEXT}` replacement:

```
PR: #<number> -- <title>

Description:
<PR body>

Changed files: <comma-separated list>

To see the full diff, run: gh pr diff <number>
```

## Agent Launch

First, read `~/.claude/skills/shared/review-agents.md` to get the 6 agent prompt templates.

Then launch all 6 agents in a **single message** so they execute concurrently. For each agent, take its prompt template from the shared file and replace `{CONTEXT}` with the context block assembled above.

0. **context-builder** (general-purpose agent) -- from shared file
1. **correctness-reviewer** (specialized agent type) -- from shared file
2. **security-reviewer** (specialized agent type) -- from shared file
3. **test-reviewer** (specialized agent type) -- from shared file
4. **code-design** (general-purpose agent) -- from shared file
5. **framework-idioms** (general-purpose agent) -- from shared file

Each agent reads the changed files directly and uses the `gh pr diff` command if it needs the full diff.

## Synthesis

Once all 6 agents complete, apply the synthesis rules from `~/.claude/skills/shared/review-agents.md`:

1. **Context**: take the context-builder agent's output and use it as-is for the Context section at the top of the report
2. **Deduplicate**: merge findings from the 5 review agents where two or more flag the same issue (same file, same line, same root cause)
3. **Global numbering**: issue numbers are unique across all sections, never restart
4. **Confidence bucketing**: Critical (>=90), Important (80-89), Minor (<80)

Use the issue format from the shared file.

## Investigation

After deduplication, investigate each finding with initial confidence >= 80 to validate severity and filter false positives. Minor findings (confidence < 80) skip investigation and pass through as-is.

1. For each finding with confidence >= 80, read the issue-investigator prompt template from `~/.claude/skills/shared/review-agents.md`
2. Launch one investigation agent per finding in a **single message** (parallel). For each agent:
   - Replace `{CONTEXT}` with the PR context block
   - Replace `{FINDING}` with the full finding (category, file:line, problem, suggested fix, and the original agent's reasoning)
   - Use a general-purpose agent (not a specialized type -- the investigator needs to be unbiased across all categories, and specialized agents are tuned to find issues which could bias toward confirmation)
3. After all investigators return:
   - **Dismissed findings**: Remove entirely from the report. They never appear.
   - **All other findings**: Use the investigator's revised confidence and problem description as the final values.
4. Combine investigated findings with uninvestigated Minor findings, bucket by final confidence, and number sequentially.

## Output Format

```markdown
## Review: PR #<number> -- <title>

## Context
<Insert the context-builder agent's output here verbatim>

## Critical Issues (>=90 confidence)
### #1 -- [Short title] `file:line`
**Category:** [Correctness | Security | Race Condition | Type Design | ...]
**Problem:** [What is wrong and why it matters]
**Suggested fix:** [Concrete solution, with code snippet if helpful]

## Important Issues (80-89 confidence)
### #N -- [Short title] `file:line`
**Category:** [Category]
**Problem:** [Explanation]
**Suggested fix:** [Solution]

## Minor Issues (<80 confidence)
[Optional, same format, continuing numbering]

## Type Design Notes
[Only if new types introduced]

## Tidy First Opportunities
[Quick wins worth doing now]

## Strengths
[2-3 things done well]
```

## Principles

- Constructive but direct, no platitudes
- Prioritize: correctness > performance > maintainability > style
- Specific file:line references
- Concrete fix suggestions
- Economic lens: focus on high-impact issues
- When multiple approaches valid, explain tradeoffs
- Filter aggressively: quality over quantity
