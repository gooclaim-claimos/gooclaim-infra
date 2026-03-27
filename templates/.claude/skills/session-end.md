---
rules-version: "1.0"
description: Complete the session log in CLAUDE_SESSION.md. Fills what was done, decisions made, files changed, and what's next. Usage: /session-end or /session-end Mayank
---

# /session-end — End of Session Checklist

When this skill is invoked, complete the session log in `CLAUDE_SESSION.md`.

## How to invoke

```
/session-end
/session-end Mayank
```

---

## Steps

1. Read `CLAUDE_SESSION.md` — find the current open session block (the one without "Ended" filled in)
2. Read `git diff HEAD` and `git log --oneline -10` to understand what changed
3. Fill in the session block fields:
   - **Ended:** current time (ask user if unsure)
   - **What was done:** bullet list from git diff + conversation context
   - **Decisions made:** any architectural choices made this session → also add to ADL table
   - **Files changed:** list from git diff
   - **Tests:** did tests pass? what coverage?
   - **What's next:** 2-3 concrete next tasks
   - **Open questions / blockers:** anything unresolved

4. Update **Module Checklist** — change status for any components worked on:
   - `⬜ Not started` → `🟡 In progress` → `✅ Done (sdx)` → `🚀 Deployed (nprd)`

5. Update **Environment Status** table if any deploy happened

6. Add any **Claude Code Patterns Learned** — non-obvious things discovered about this codebase

7. Remind user to commit:
   ```bash
   git add CLAUDE_SESSION.md
   git commit -m "docs: session log $(date +%Y-%m-%d) [name]"
   git push
   ```

---

## Rules

- Never fabricate test results — if tests weren't run, write "not run this session"
- "Decisions made" = only things that affect architecture; not every code choice
- Keep "What's next" actionable — not vague like "continue L1", but specific like "implement RW1 entity extraction"
