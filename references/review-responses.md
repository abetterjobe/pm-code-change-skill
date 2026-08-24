# Responding to review comments

Detail for Phase 10. The posting protocol itself stays in `SKILL.md` — it's a hard gate that has to be present whether or not this file gets read. This covers who answers what, and how to draft it.

## Who responds to what

**User can respond to (AI drafts):**

- Logistics (timing, tickets, titles, linking)
- Intent (why we're building this)
- Concrete fixes (typo, rename, missing test, adding a case to a test)
- Acknowledging a fix has been made

**Engineer should respond to (don't draft — escalate):**

- "Have you considered X?" referencing existing code
- Type system, schema, or API contract questions
- Reviewer disagreements
- Blocking comments
- Domain model placement
- Anything labeled `(blocking)`

## Drafting protocol

- **Never sign drafts as AI or attribute them to AI.** The user is the author.
- **Match the user's actual writing voice, from samples.** "Write it in my voice" without examples produces a polished corporate register — which is exactly what reads as automated, whatever the signature says. Pull 3–5 of the user's own comments from prior PRs or threads on similar topics, analyze the patterns, and match them. See "Style cloning" in `prompt-techniques.md`.
- **Keep drafts high-level.** The user fields the follow-up questions, so a draft that commits to technical detail they can't defend creates a trap. Pitch at the altitude they can speak to.
- If the user can't defend the draft in their own words, that's the signal to recommend involving an engineer — not to rewrite the draft.
- When two reviewers disagree, don't pick a side. Draft a message that surfaces the conflict to both and asks them to align. Tag them by name. User posts.
- For each comment, take an action: fix in code, draft an acknowledgment, draft a push-back with reasoning, or escalate to an engineer. Don't leave comments hanging — but the user always posts.

## When a comment isn't understood

If the user is about to accept a reviewer's comment they don't follow, that's the moment for learning mode (`/explain-this`) rather than a drafted acknowledgment. Understanding the comment is a better outcome than applying it on faith — and it's the difference between being able to answer the follow-up and having to come back for help.
