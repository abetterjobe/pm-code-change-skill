---
description: Check the Jira ticket is accurate, assigned to you, active, in the current sprint, and linked to the PR
---

Reconcile the ticket for the current work so it accurately reflects reality.

**Read `~/.claude/skills/pm-code-change/references/ticket-reconciliation.md` and follow it.** That file has the full procedure and the Jira specifics that are easy to get wrong.

Ticket or branch, if given: $ARGUMENTS

If nothing was given, find the ticket from the current branch name or the open PR.

Two rules that matter most, so they hold even if that file can't be read:

- **Never transition a ticket to Done.** This moves tickets into flight, never out. Closing is the team's call against their own definition of done, and it's often board automation's job.
- **Never hardcode status names** — they differ per board. Resolve the target status by Jira's `statusCategory` (`indeterminate` for in-flight), preferring `In Review` → `Code Review` → `In Progress` among the options that actually exist. Some boards have no review status at all.

And don't trust the remote-issue-links API to tell you whether a PR is linked — it returns empty for tickets that plainly have PRs. Verify through the ticket key in the branch name and PR title instead.

Batch every proposed change behind one confirmation, then re-read the ticket to verify each write actually landed.
