# Ticket reconciliation

Detail for Phase 14. Runs in full on Track 2 and Track 3, after the PR is open; Track 1 runs only two of these checks, inside its own workflow. Idempotent — safe to re-run any time the work or the ticket moves.

Goal: leave the ticket in a state that accurately reflects reality — described correctly, owned by the user, in an active state, in the current sprint, and connected to the PR.

Written against Jira via the Atlassian MCP tools. Get `cloudId` from `getAccessibleAtlassianResources`, and the current user's account id from `atlassianUserInfo`.

---

## Step 1 — Find the ticket

Look in this order:

1. A ticket the user named explicitly in the conversation.
2. A ticket key in the current branch name — keys look like `[A-Z][A-Z0-9]+-\d+` (e.g. a branch `ix-2174-custom-portfolio-label` implies `IX-2174`).
3. A ticket key in the PR title or description.

If two sources disagree, stop and ask which is right. Never guess between two candidate tickets.

---

## Step 2 — If no ticket exists, create one

Creating a ticket is an outward-facing action in a shared tracker, so **draft it, show the user, and create only on explicit confirmation.**

Draft with:

- **Project** — infer from sibling tickets in the same area or from the branch prefix. If it can't be inferred confidently, ask; don't default to a random project.
- **Issue type** — `Bug` when fixing incorrect existing behavior, `Task`/`Story` when adding something. Check the project's available types rather than assuming.
- **Summary** — one line, describing the user-facing outcome, not the implementation.
- **Description** — match the shape the project already uses. Where a bug-report convention exists (an Observed / Expected structure is common), follow it. Include what the user sees, what they should see, and the affected surface.
- **Assignee** — the current user (`atlassianUserInfo` → `account_id`).

Then continue through the checks below as if the ticket had existed.

---

## Step 3 — Reconcile the four attributes

Check each, collect the drift, and present it as one batch before writing anything.

**a. Description is accurate.** Compare it against what actually shipped. Work often diverges from the original report — a bug turns out to have a different cause, or the fix covers more or less than described. If it drifted, propose replacement text and show what changes. Never overwrite a description silently; the reporter's original account of the problem has value.

**b. Assigned to the user.** Compare `assignee.accountId` against the current user's account id. If someone else is assigned, don't reassign — surface it, because it may be deliberate.

**c. Status is active — In Progress or in review.** Do **not** hardcode status names; they differ per board. Read the real options with `getTransitionsForJiraIssue` and pick by `statusCategory`:

- Target a transition whose destination `statusCategory.key` is `indeterminate` (Jira's "In Progress" category).
- Among those, prefer by name in this order: `In Review` → `Code Review` → `In Progress`. Some boards have no review status at all — the Investing Enablement (`IX`) board, for example, offers only `In Progress` and `On Hold/Blocked` in that category. Never select a blocked/hold status as the target.
- **Never transition a ticket to Done.** Closing a ticket is the team's call, made against their own definition of done, and often driven by board automation. This phase moves tickets *into* flight, never out.

If the ticket is already `Done` while work is still in flight, that's drift worth reporting — but flag it and let the user decide rather than reopening it.

**d. In the current active sprint.** Verify with JQL rather than the Agile API — no board id needed:

```
key = <TICKET> AND sprint in openSprints()
```

A result means it's in an open sprint. An empty result means it isn't. If it isn't, adding it requires writing the board's sprint field, which may be outside the available API scopes — attempt it, and if it fails, say so plainly and hand the user the one-click fix rather than reporting success.

---

## Step 4 — Verify PR linkage the way a human sees it

**The remote-issue-links API is not a reliable signal here.** It returns an empty list for tickets that demonstrably have linked PRs, because the GitHub integration surfaces them in the ticket's development panel rather than as remote links. An empty result is not evidence of a missing link, and chasing it produces phantom work.

Verify the mechanism that actually drives linking instead:

1. The ticket key appears in the branch name — `git branch --show-current`.
2. The ticket key appears in the PR title — `gh pr view --json title,body`.
3. The PR description links the ticket.

If all three hold, the linkage is in place. If the key is missing from the PR title, fix the title. If it's missing from the branch name on an already-open PR, don't rename the branch — add the key to the title and description instead, and note it for next time.

---

## Step 5 — Report, confirm, then write

Present the findings as a short table: attribute, current state, desired state, proposed action. Batch every mutation behind a single confirmation so the user approves once, not five times.

On approval, apply the changes and re-read the ticket to confirm each one landed. Report what actually changed — if a write failed (permissions, missing scope, a transition the workflow doesn't allow from the current status), say which one and why. Don't report success for a write you didn't verify.
