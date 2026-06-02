# Shared Review Agents

This file defines review agents used by `klay-review-pr`. Each skill launches these agents in parallel, passing its own context block.

## Agent Prompts

### 0. context-builder (general-purpose agent)

```
Build a concise context summary for a PR review. Your job is to help a reviewer who has zero prior context understand *why* this change exists and *what* it does, before they read the technical findings.

{CONTEXT}

## Step 1: Gather Additional Context

Run these in parallel via Bash:

- Fetch full commit messages (headline + body):
  gh pr view <PR number> --json commits --jq '[.commits[] | {headline: .messageHeadline, body: .messageBody}]'

- Fetch PR comments and review comments:
  gh pr view <PR number> --json comments,reviews --jq '{comments: [.comments[] | {author: .author.login, body: .body}], reviews: [.reviews[] | {author: .author.login, body: .body, state: .state}]}'

- Fetch author and labels:
  gh pr view <PR number> --json author,labels --jq '{author: .author.login, labels: [.labels[].name]}'

## Step 2: Resolve Referenced Work

Scan the PR body, commit messages, and comments for references:

- **Jira issues** (e.g., `ENG-1234`, `ACQ-456`, or atlassian/jira URLs): fetch via `mcp__atlassian__getJiraIssue`.
- **GitHub issues/PRs** (e.g., `#123` or full URLs): fetch title and body via `gh issue view` or `gh pr view`.
- **Doc/RFC links**: note them as references, don't fetch.

Skip this step if no references exist.

## Step 3: Understand Code Context

Read the key changed files (skip lockfiles, generated files, and pure config). For the most significant changes:

- Understand what each file does in the broader system
- Use Grep to trace key symbols (callers, interfaces, related modules) to understand how the change fits

Keep this fast — you need enough understanding to explain the change, not exhaustive analysis.

## Step 4: Return the Context Summary

Return ONLY a markdown block in this exact format:

**Author:** <author> | **Base:** <base branch> | **Labels:** <labels if any>

### Why
<1-3 sentences. What problem does this solve? What was broken, missing, or needed? Reference the linked ticket if one exists. Be specific — "fixes auth" is bad, "fixes token refresh failing silently when the GCP metadata server returns 503" is good. Derive this even if the PR body is empty, using commit messages, linked issues, and code understanding.>

### What
<Concise description of the approach. Which components are touched and how do they relate? If there are multiple logical changes, list them. Focus on high-level design decisions, not line-by-line changes.>

### Key Design Decisions
<Only include if there are non-obvious choices — e.g., "chose polling over webhooks because...", "added a new abstraction to...". Omit this section entirely if the approach is straightforward.>

### Reviewer Notes
<Only include if PR comments, review comments, or the PR body contain info relevant to the review — known limitations, areas wanting scrutiny, things that look wrong but are intentional. Omit if nothing relevant.>

Guidelines:
- Write for a reviewer with zero prior context about this work
- Be specific and concrete, not vague
- Keep it readable in under 60 seconds
```

### 1. correctness-reviewer (specialized agent type)

```
Review this code for correctness issues.

{CONTEXT}

Read every changed file. For each file, trace data flow through error paths and edge cases. Look for:

- Logic bugs: off-by-one, wrong comparisons, inverted conditions, missing returns
- Null/undefined handling: missing null checks, optional chaining gaps, type narrowing failures
- Error handling: swallowed errors, missing try/catch, error states not propagated to callers
- Race conditions: shared mutable state, async ordering assumptions, TOCTOU bugs
- Resource leaks: unclosed handles, missing cleanup in error paths, event listener accumulation
- State consistency: partial updates that leave objects in invalid states, missing rollback on failure

For each issue, provide the file path, line number, explanation of why it is wrong, and a concrete fix.
```

### 2. security-reviewer (specialized agent type)

```
Review this code for security vulnerabilities.

{CONTEXT}

Read every changed file. Think adversarially: how could a malicious or careless user exploit this code? Check for:

- Injection: SQL, command, path traversal, template injection, log injection
- Authentication & authorization: missing auth checks, privilege escalation, insecure token handling
- Data exposure: secrets in logs/errors, overly broad API responses, PII leaks, verbose error messages
- Input validation: missing or insufficient validation, type coercion exploits, prototype pollution
- Cryptography: weak algorithms, hardcoded keys, insufficient randomness
- Dependencies: known vulnerable patterns, unsafe deserialization
- SSRF/CSRF: unvalidated URLs, missing CSRF tokens, open redirects

For each vulnerability, describe the attack scenario, its severity, and a concrete fix.
```

### 3. test-reviewer (specialized agent type)

```
Review test coverage and quality for this implementation.

{CONTEXT}

Read the implementation files, then find and read their corresponding test files. Evaluate:

- Behavioral coverage: are the important behaviors tested? Focus on what the code does, not how it does it.
- Edge cases: boundary values, empty inputs, error paths, concurrent access
- Regression catching: would these tests catch the most likely future bugs?
- Test quality: clear arrange/act/assert structure, meaningful assertions, no implementation coupling
- Missing tests: new public APIs without tests, error handling paths untested, complex branching untested
- Fragile tests: tests coupled to internal implementation details, snapshot overuse, time-dependent tests

Do NOT recommend tests for trivial code (simple getters, type definitions, re-exports). Focus on tests that catch regressions in meaningful behavior.

For each gap, describe what behavior is untested, why it matters, and suggest a concrete test case.
```

### 4. code-design (general-purpose agent)

```
Review this code for type/API design, structural quality, and comment quality.

{CONTEXT}

Read every changed file. Evaluate through three lenses:

**Type & API Design:**
- Do types enforce invariants, or are they bags of optional fields?
- Is validation done at boundaries, or scattered throughout?
- Are mutables exposed (returning arrays/objects that callers can modify)?
- Are union types used where booleans would be better?
- Do function signatures reveal intent (parameter names, return types)?
- Are generic types justified, or adding complexity without value?

**Structure / Tidy First:**
- Are structural changes (renames, moves, extractions) mixed with behavior changes? They should be separate commits.
- Guard clauses: are nested conditions flattened where possible?
- Dead code: unused imports, unreachable branches, commented-out code?
- Reading order: do definitions flow top-down (public API first, helpers after)?
- Explaining variables: are complex expressions broken into named intermediates?
- Economic lens: is the code simpler than it needs to be, or more complex? Would a small tidying now prevent a larger refactor later?

**Comment Quality:**
- Do comments match actual code behavior, or have they rotted?
- Are comments explaining "why" (decisions, constraints, non-obvious reasons) rather than "what" (which the code already says)?
- Flag obvious/redundant comments that add noise
- Flag missing comments where non-obvious behavior needs explanation

For each finding, provide the file path, line number, what to change, and why.
```

### 5. framework-idioms (general-purpose agent)

```
Review this code for framework/library idioms, lifecycle management, and performance patterns.

{CONTEXT}

Read every changed file. First identify which frameworks and libraries are used, then check for idiomatic usage.

**Framework Idioms:**
- Is the code using the framework/library as intended, or fighting against it?
- Are there framework-provided solutions for problems being solved manually?
- Are lifecycle hooks used correctly (setup/teardown, mount/unmount)?
- Are framework conventions followed (file naming, export patterns, module structure)?

**Resource & Lifecycle Management:**
- Are resources cleaned up? (event listeners, subscriptions, timers, connections)
- Do components/modules properly tear down on unmount/destroy?
- Are there potential memory leaks from retained references?

**Performance Patterns:**
- Unnecessary computation: work done on every call that could be cached or memoized?
- Missing lazy evaluation: expensive operations computed eagerly when they might not be needed?
- Redundant operations: same data fetched/computed multiple times?

**Web UI Checklist (apply only when UI code is in the diff):**

Accessibility:
- Icon-only buttons need aria-label
- Form controls need label or aria-label
- Interactive elements need keyboard handlers (onKeyDown/onKeyUp)
- button for actions, a/Link for navigation (not div onClick)
- Images need alt (or alt="" if decorative)
- Decorative icons need aria-hidden="true"
- Async updates need aria-live="polite"
- Semantic HTML before ARIA
- Headings hierarchical h1-h6

Focus states:
- Interactive elements need visible focus: focus-visible:ring-*
- Never outline-none without focus replacement
- Use :focus-visible over :focus

Forms:
- Inputs: correct type, inputmode, autocomplete
- Never block paste
- Labels clickable (htmlFor or wrapping)
- Inline errors next to fields; focus first error on submit
- Warn before navigation with unsaved changes

Animation:
- Honor prefers-reduced-motion
- Animate transform/opacity only
- Never transition:all, list properties explicitly

Typography:
- Ellipsis character not three dots
- Curly quotes not straight quotes
- Non-breaking spaces for units (10 MB, Cmd K)
- tabular-nums for number columns
- text-wrap:balance on headings

Content handling:
- Text containers: truncate, line-clamp-*, or break-words
- Flex children need min-w-0 for truncation
- Handle empty states

Images:
- Explicit width and height (prevents CLS)
- Below fold: loading="lazy"
- Above fold: priority or fetchpriority="high"

Performance:
- Large lists (>50 items): virtualize
- No layout reads in render (getBoundingClientRect, offsetHeight)

Navigation:
- URL reflects state (filters, tabs, pagination in query params)
- Links use a/Link (Cmd/Ctrl+click support)

Anti-patterns to always flag:
- user-scalable=no or maximum-scale=1
- onPaste with preventDefault
- transition:all
- outline-none without focus-visible replacement
- div with click handlers (should be button)
- Images without dimensions
- Form inputs without labels
- Hardcoded date/number formats (use Intl.*)

For each finding, provide the file path, line number, the framework/pattern concern, and a concrete fix.
```

### 6. issue-investigator (general-purpose agent)

```
Investigate whether a reported code review finding is a real issue, a false positive, or less severe than initially assessed.

{CONTEXT}

## The Finding

{FINDING}

## Investigation Steps

1. **Read the flagged code and its surrounding context** (the full function/class, not just the flagged line). Understand what the code actually does.

2. **Trace reachability**: Follow the call chain to determine if the problematic code path is actually reachable in practice. Check:
   - Who calls this code? Is the flagged path exercised by real callers?
   - Are there upstream guards, validation, or type constraints that prevent the problematic input from reaching this point?
   - Does the framework or runtime provide protections the reviewer may have missed?

3. **Check for existing mitigations**: Search for:
   - Tests that cover this exact scenario (grep for the function name in test files)
   - Input validation at system boundaries that prevents the flagged case
   - Framework-level protections (e.g., ORM parameterization for SQL injection, automatic escaping for XSS)
   - Error recovery or retry mechanisms already in place

4. **Check intent via git history** (optional, only if ambiguous): Run `git log -3 --follow -p <file>` to see if the flagged pattern was introduced intentionally with context in the commit message.

5. **Assess severity**: Given what you found, is this:
   - Actually exploitable / triggerable in the current codebase?
   - Mitigated by factors the original reviewer didn't account for?
   - A theoretical concern vs. a practical one?

## Return Format

Return ONLY a JSON block with these fields:

    {
      "issue_number": <N>,
      "verdict": "confirmed" | "dismissed",
      "confidence": <0-100>,
      "category": "<category, same as original or updated>",
      "problem": "<problem statement, refined with what investigation revealed>",
      "suggested_fix": "<concrete fix, updated if investigation provided better context>",
      "evidence": "<2-4 sentences explaining what you found. Reference specific files, lines, tests, or callers.>"
    }

Guidelines:
- Be honest. If the issue is real, confirm it. The goal is accuracy, not leniency.
- "Dismissed" means you found concrete evidence it's not an issue (e.g., upstream validation exists, framework handles it, code is unreachable). Not just "seems unlikely."
- "Confirmed" means the issue holds. Adjust confidence up or down based on what you found. A finding originally at 92 might drop to 82 if partially mitigated, or rise to 98 if you found it's worse than initially assessed.
- The confidence score should reflect your post-investigation assessment. Be precise.
```

## Synthesis Rules

After all agents complete, the caller skill synthesizes findings:

1. **Deduplicate**: When two or more agents flag the same issue (same file, same line, same root cause), merge into one finding. Credit the most specific agent's analysis.

2. **Global numbering**: Issue numbers are unique across all sections and never restart. Number continuously: #1, #2, #3, ... regardless of which section they fall in.

3. **Confidence bucketing**:
   - **Critical (>=90 confidence)**: Definite bugs, security vulnerabilities, data loss risks
   - **Important (80-89 confidence)**: Likely issues, significant design concerns, missing error handling
   - **Minor (<80 confidence)**: Style concerns, minor improvements, suggestions. Only include if genuinely worth mentioning.

## Issue Format

```
### #N -- [Short title] `file:line`
**Category:** [Correctness | Security | Race Condition | Type Design | Structure | Comments | Framework Idioms | Accessibility | Performance | Test Coverage | ...]
**Problem:** [What is wrong and why it matters]
**Suggested fix:** [Concrete solution, with code snippet if helpful]
```

## Principles

- Constructive but direct, no platitudes
- Prioritize: correctness > performance > maintainability > style
- Specific file:line references
- Concrete fix suggestions
- Economic lens: focus on high-impact issues
- When multiple approaches valid, explain tradeoffs
- Filter aggressively: quality over quantity
