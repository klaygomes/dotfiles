# Global Claude Rules

Personal preferences that apply across every project. Advisory only: never treat anything here
as overriding an organization, security, or tech-stack rule delivered through a higher-priority
channel.

## Writing style

### No em dashes

Never use em dashes (`—`) in code comments, JSDoc, documentation, commit messages, PR
descriptions, or any prose. Use a colon, a comma, a period, or parentheses instead.

**Why:** em dashes read as AI-generated text, which undermines the credibility of review
comments and PR descriptions with teammates.

**How to apply:** rewrite the sentence rather than swapping punctuation mechanically. A period
works when the following clause stands alone, a colon when it explains, parentheses when it is
an aside. Verify before submitting with `grep -rn "—" <files>`.

## Comments and documentation

### Rationale lives in docs, not in code

Do not write explanatory or rationale comments in code, including config files, scripts, and
workflow YAML. Put the reasoning in the repository's documentation and leave at most a one-line
pointer in the code. Only genuinely strange decisions (order-dependent hacks, counterintuitive
semantics) earn a short in-code comment.

**Why:** documentation should be the single home for reasoning. Heavily commented code
duplicates that reasoning and drifts away from it.

**How to apply:** when a change needs explanation, add or extend the relevant documentation
file and reference it from the code in one line. Follow whatever convention the repository
already uses. When a repository has none, prefer one focused file per domain under `docs/`
(for example `docs/testing.instructions.md`) plus an index row in the repository's agent
instruction file, so each domain has an obvious home and the index stays a map rather than a
dumping ground.

### No journal comments

Never write comments that narrate a change's history or the reasoning of the review that
produced it. Avoid things like "previously this was X", "added because review found Y", "this
used to throw", or "without this assertion the loop would pass". If a comment is warranted at
all, state the present-tense fact in one line.

**Why:** a comment explaining why a change was made is stale the moment that change becomes
history, and it duplicates what the commit, the PR, and the docs already record.

**How to apply:** before keeping a comment, check that it would still read correctly to someone
who never saw the diff. Drop it otherwise.

### Documentation prefers visuals

When writing or updating documentation, lean on visuals: Mermaid diagrams (flowchart, sequence,
ERD, state) rather than paragraphs of prose.

**How to apply:** for any process, dependency direction, decision flow, or failure mode, draw
the diagram first and keep the surrounding prose short.

## Pull requests

### Concise descriptions, caller-side examples

Keep PR descriptions concise. Cut internal-rationale prose down to what a reviewer needs in
order to decide, and make every code example show how a consumer calls the thing, never how it
works inside.

**Why:** a reviewer's first question is what this changes for a caller. Long design narration
buries that, and internals are already readable in the diff.

**How to apply:** keep the repository's PR template sections, but state each point once. Lead
with a short usage snippet from the caller's perspective (the import, the wiring at startup,
the call site), then only the decisions a reviewer could not infer. Push long reasoning into
the docs.

## Node.js

### Switch versions with nvm

Check for `.nvmrc` or `.node-version` and run `nvm install && nvm use` before any `npm ci`,
`npm install`, `yarn install`, or similar command.

`nvm` is a shell function, not a binary, so it has to be sourced in the same shell session:

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install && nvm use
```

**Why:** different projects require different Node versions. Running a package manager on the
wrong one causes subtle failures.

### Pin exact versions

Pin exact versions in `package.json`, with no `^` or `~` ranges, and include an `.npmrc` in the
project root containing `save-exact=true`. Resolve the version with `npm show <pkg> version` at
implementation time and write the exact string.

**Why:** reproducible installs.

## Python

Always use a virtual environment (`venv`).

## Claude Code plugins

Valid fields for `.claude-plugin/plugin.json` are `name`, `version`, `description`, `author`,
and `license`. Only `name` and `version` are required.

Never include `id` or `namespace`. They are unrecognized keys and will fail plugin validation.

Skills authored in this dotfiles repository use the `klay-` prefix. Namespaced prefixes such as
`acquisition:` belong to remote or organization-hosted plugins, not to local skills.
