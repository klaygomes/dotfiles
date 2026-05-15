---
name: klay-plan-reviewer
description: Open the current plan in an interactive browser UI for annotation and review. Returns JSON with action, annotations, and optionally modified plan content.
when_to_use: "Use when the user says 'review my plan', 'open plan reviewer', 'open in browser', or asks to annotate or review the current plan."
argument-hint: "<optional plan file path>"
allowed-tools: Bash(ls *) Bash(find *) Bash(*plan-reviewer*) Write
---

# Plan Reviewer

Opens the current Claude plan in a browser-based CodeMirror 6 editor where the user can read, annotate, and optionally edit the plan, then submit a review action.

## Steps

### 1. Find the plan file

If `$ARGUMENTS` is a file path, use it. Otherwise find the most recently modified plan:

```bash
ls -t ~/.claude/plans/*.md | head -1
```

### 2. Open the plan reviewer

Run the tool and wait (it blocks until the user submits in the browser):

```bash
"${HOME}/bin/plan-reviewer" <path>
```

Capture the JSON printed to stdout.

### 3. Act on the response

Parse the JSON response:

```typescript
{
  action: "approve" | "request_changes" | "comment";
  annotations: Array<{
    text: string;
    range: { from: { line, col }, to: { line, col } };
    comment: string;
  }>;
  modifiedPlan: string;
  summary?: string;
}
```

**`approve`** — Inform the user their plan was approved. Proceed with implementation.

**`request_changes`** — Address each annotation. For each one, locate the referenced text using `range.from.line` and apply the `comment` feedback to the plan. Then update the plan file.

**`comment`** — Read annotations and summary, respond to or acknowledge each point.

### 4. Handle edited plan content

If `modifiedPlan` differs from the original file content, write it back using the Write tool:

```
Write the modifiedPlan content to <path>
```
