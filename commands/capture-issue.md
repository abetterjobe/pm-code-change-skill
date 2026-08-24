---
description: File a follow-up ticket for something spotted mid-task, without derailing the current work
---

Capture an issue the user just thought of, fast, so they can get back to what they were doing. Budget: under two minutes.

Follow the "Capture an issue" section of `~/.claude/skills/pm-code-change/SKILL.md` (under Interrupts) and Step 2 of `~/.claude/skills/pm-code-change/references/ticket-reconciliation.md` for the drafting rules.

What they spotted: $ARGUMENTS

Key points:

- **Ask at most 2–3 targeted questions in a single message.** What the issue is, current versus desired behavior, and type/priority if not obvious. One round trip, not a conversation. Skip anything already clear from what they told you.
- **Search only when it helps.** Grep for the relevant files to attach context — three at most. Don't research best practices for a straightforward bug.
- **Draft, show, create on confirmation.** Creating a ticket writes to a shared tracker, so it needs an explicit yes.
- Default to normal priority and medium effort. Ask only if genuinely unclear.
- Bullet points, not paragraphs.
- Report the ticket key and stop. Don't start working on it — the whole point is that it's for later.

This exists because pulling adjacent problems into the current PR is an anti-pattern, and "file a follow-up ticket" needs a mechanism or it doesn't happen.
