---
name: klay-investigate
description: Automatically activated when user asks how something works, wants to understand unfamiliar code, needs to explore a new codebase, or asks questions like "where is X implemented?", "how does Y work?", or "explain the Z component"
allowed-tools: Read, Grep, Glob, Task
---

# Investigating Codebases

Systematically explore unfamiliar code. Start broad, follow breadcrumbs, provide evidence with `file:line` references.

## Phase 1: Reconnaissance

1. Identify project type: check `package.json`, `Cargo.toml`, `setup.py`, `go.mod`, top-level README.
2. Map directories: `src/`, `lib/`, `app/`, tests, config, scripts. Note framework patterns.
3. Discover entry points: `main.js`, `index.ts`, `__init__.py`, `server.js`, `app.py`, `main.go`, CLI handlers, build targets.

Use Glob for structure, Read for entry files. Do not dive deep yet.

## Phase 2: Targeted Investigation

1. Search by name: `Grep "functionName"`, `Grep "class Name"`.
2. Search by concept: `Grep "auth" --include="*.ts"`.
3. Search by pattern: `Grep "export.*function"`, `Grep "import.*from"`.
4. Find by file: `Glob "**/*auth*"`, `Glob "**/*.{test,spec}.{js,ts}"`.

Read key files starting at entry points. Follow imports, function calls, data flow. Track key files and relationships.

Use Task for complex multi-step traces.

## Phase 3: Deep Dive

1. Trace call chains, data transformations, error handling, edge cases.
2. Note algorithms, data structures, performance and security choices.
3. Extract conventions: naming, file organization, import/export, testing, docs.

Verify across related files. Build a mental model before explaining.

## Common Layouts

**Web app:** `index.html` / `main.js` → `routes/`, `api/`, `controllers/` → `components/`, `pages/` → `services/`, `utils/` → `store/`, `state/` → `config/`, `.env`

**API server:** `server.js` / `app.py` → `routes/`, `handlers/` → `middleware/` → `services/`, `domain/` → `models/`, `repositories/` → `config/`

**CLI:** `cli.js` / `__main__.py` → `commands/`, `cli/` → `lib/`, `core/` → `utils/` → arg parsing, config

**Library:** `index.js` / `__init__.py` / `lib.rs` → public exports → `src/`, `lib/` → `types/`, `*.d.ts` → `README`, `docs/`, `examples/`

## Rules

- Always give `path:line` references, never bare claims.
- Explain what code does and how pieces fit, not just location.
- Start simple, go deep only if needed. Match user's familiarity level.
- Be systematic: check multiple locations, cross-reference findings.

## Output Template

```markdown
## [Component] Investigation

### Location
- Primary: `path/to/file.ts:42-67`
- Related: `path/to/other.ts:15`

### Overview
[What this does]

### How It Works
1. [Step with file reference]
2. [Step with file reference]

### Key Files
- `file1.ts`: [Role]
- `file2.ts`: [Role]

### Execution Flow
[Flow with file references]

### Notable Patterns
- [Convention or detail]

### Related Components
- [Component]: [How it relates]
```
