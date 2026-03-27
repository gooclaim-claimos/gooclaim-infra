---
description: Create a new Architecture Decision Record in docs/10-adr/. Usage: /new-adr <title> e.g. /new-adr use temporal for rw2
---

# /new-adr — Create a New Architecture Decision Record

When this skill is invoked, create a new ADR file in `docs/10-adr/`.

## How to invoke

```
/new-adr use temporal for rw2
/new-adr "haystack for knowledge layer"
```

---

## Steps

1. Check existing ADRs in `docs/10-adr/` to get the next number
2. Create file: `docs/10-adr/{NNN}-{kebab-case-title}.md`
3. Fill in the template below based on the topic provided

---

## ADR Template

```markdown
# ADR-{NNN}: {Title}

**Date:** {YYYY-MM}
**Status:** Accepted
**Deciders:** Team

---

## Context

[What is the problem or situation that requires a decision?
What are the constraints? What will break or be hard if we don't decide?]

## Decision

[What was decided — one clear sentence.]

## Reasons

- [Reason 1]
- [Reason 2]
- [Reason 3]

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| [Alt 1] | [Reason] |
| [Alt 2] | [Reason] |

## Consequences

- [What changes as a result of this decision]
- [Any known trade-offs]
- [Any follow-up actions needed]
```

---

## Rules

- Never fabricate technical details — if unsure, leave a `[TODO: fill in]` placeholder
- Always check existing ADRs to avoid duplicates
- Keep "Decision" section to one sentence — the detail goes in "Reasons"
- "Rejected Alternatives" is mandatory — helps future engineers understand why not X
