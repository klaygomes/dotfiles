---
name: klay-task
description: "Manage Taskwarrior tasks using natural language — add, list, complete, postpone, annotate, start."
when_to_use: >-
  Auto-invoke when the user says: "add a task", "remind me to", "I need to do", "create a task for",
  "what are my tasks", "what's due", "show my tasks", "what do I have today / this week",
  "mark done", "complete task", "done with X", "postpone task", "push X to next week",
  "start task", "I'm working on X", "add note to task".
argument-hint: "<natural language task operation, e.g. 'add fix login bug due tomorrow project:backend' or 'show tasks for project frontend'>"
allowed-tools: Bash(task *)
---

**Task:** $ARGUMENTS

---

## Step 1 — Parse intent

Identify one of: `list`, `add`, `done`, `postpone`, `start`, `stop`, `annotate`, `delete`.

If `$ARGUMENTS` is empty or vague ("show", "list", "tasks"), treat as `list`.

---

## Step 2 — Execute

### list — default view

```bash
task next
```

Scoped variants:
- by project: `task project:X next`
- by tag: `task +tagname next`
- full list: `task list`
- overdue: `task +OVERDUE list`
- due today: `task +TODAY list`
- due this week: `task +WEEK list`

---

### add — create a new task

Extract description, then optional fields:

| Field | Natural language cue | Task syntax |
|-------|---------------------|-------------|
| due | "due X", "by X", "on X", "for X" | `due:<date>` |
| project | "for project X", "in project X" | `project:X` |
| tag | "#X", "tagged X", "+X" | `+X` |
| priority | "urgent / high / low / medium" → H/M/L | `priority:H` |
| scheduled | auto-set when due is present | `scheduled:due-4d` |

**Always include `scheduled:due-4d` when a `due:` is provided.** This keeps the task hidden from `task next` until it enters the 4-day window before it's due.

```bash
task add "<description>" [due:<date>] [scheduled:due-4d] [project:X] [+tag] [priority:H]
```

#### Date expressions (pass through directly — taskwarrior understands these)

| Natural language | Syntax |
|-----------------|--------|
| "tomorrow" | `due:tomorrow` |
| "friday" / "next friday" | `due:fri` |
| "in 3 days" | `due:today+3d` |
| "next week" | `due:sow` |
| "end of week" | `due:eow` |
| "end of month" | `due:eom` |
| "end of year" | `due:eoy` |
| "June 15" / "2026-06-15" | `due:2026-06-15` |

---

### done — complete a task

If the user gives an ID:
```bash
task <id> done
```

If the user names a task without an ID:
1. Run `task list` to find candidates
2. Confirm: "Task 4 — 'fix login bug'? (done / no)"
3. Only execute after confirmation

---

### postpone — shift due date forward

```bash
task <id> modify due:due+<N>d
```

For an absolute date:
```bash
task <id> modify due:<date>
```

Also update scheduled to stay in sync with the new due date:
```bash
task <id> modify scheduled:due-4d
```

Both `modify` calls can be combined:
```bash
task <id> modify due:due+3d scheduled:due-4d
```

---

### start / stop

```bash
task <id> start
task <id> stop
```

---

### annotate

```bash
task <id> annotate "<note text>"
```

---

### delete

Ask for confirmation before deleting. Then:
```bash
task <id> delete
```

---

## Step 3 — Confirm output

After every mutating command, print a compact one-line summary:

```
✓ Added     "review PR for ACQ-123" · project:acquisition · due: fri · visible: tue
✓ Done      task 4 — "fix login bug"
✓ Postponed task 4 · due → fri · visible: tue
✓ Started   task 2 — "write tests for auth"
✓ Annotated task 3 — note added
```

For `list` commands, let `task` output render directly without wrapping.
