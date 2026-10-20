# Orchestration

Detail for Phase 1's orchestration check. Applies when a backend or contract change has web or mobile work waiting to consume it. One orchestration session coordinates the project; each ticket gets its own ticket session that runs the normal workflow.

What makes these projects hard isn't the number of tickets, it's the order. A client can't ship against a contract that doesn't exist yet, and the user's local environment can show one branch at a time. The orchestration session exists to hold that order, and the release behind it, so the user doesn't have to.

---

## The one rule: the orchestration session delegates everything

It writes no code, owns no branch, and opens no PR. Not even a one-line fix. If it notices something that needs changing, it goes to the ticket session that owns that area, or becomes a new ticket. Two sessions touching the same work makes it impossible to tell who did what.

Ticket sessions follow Phase 0 as usual: one ticket, one worktree, one branch, one PR. They never touch another ticket's worktree, and neither does the orchestration session.

Ticket sessions don't coordinate with each other directly. Everything that crosses tickets goes through the orchestration session (see "Change notices" below).

## The user talks only to the orchestration session

The point of orchestrating is that the user has one place to work. So:

- **Never tell the user to type anything into a ticket session.** Not a command, not an approval, not a pasted brief. The orchestration session delivers everything itself with the app's session tools: `send_message` to send, `list_events` to read a session's recent work, `list_sessions` / `get_session` to find sessions and their branch and PR.
- **Never tell the user to say a specific phrase.** Ask a plain question and act on the answer, however it's worded.
- **Ticket sessions report upward, not to the user.** Every brief tells the ticket session to send questions, change notices, and "done" to the orchestration session (`send_message` to `"parent"` when the orchestration session started it, otherwise its session id from the brief).
- **Approvals are relayed word for word.** When a ticket session needs the user's sign-off (opening a PR, a Jira write), the orchestration session puts the question to the user and sends back the user's answer quoted exactly, with what it approves. It never approves on the user's behalf, and never paraphrases a "yes."

Two things still happen outside the orchestration session, and the user should hear about them up front rather than mid-project: permission prompts that a ticket session's mode requires the user to click in that session, and looking at the local environment during verification.

---

## Step 1 — Kickoff for the project

One announcement for the whole project, using the Kickoff section of `SKILL.md`, but describing the project rather than one ticket. Ticket sessions skip their own kickoff. Later updates go in the same thread.

## Step 2 — Break the work into tickets

Draft one ticket per PR-sized piece, split by repo and by behavior: typically a backend ticket for the contract, a web ticket, and a mobile ticket. Use Step 2 of `references/ticket-reconciliation.md` for the drafting rules.

**Decide the feature flag at the same time.** Most backend-plus-client work ships behind one TestTrack flag. Settle whether there is one, which ticket creates it (normally the backend ticket, using the `create-feature-flag` skill), and that the client tickets reuse it rather than adding their own. If there's a flag, draft a cleanup ticket to retire it after launch, in the same batch, so it isn't forgotten.

**Ask about an epic; don't assume one.** *"Want these grouped under an epic?"* Default to no. Link the tickets to each other either way.

Show the full set and create them on one confirmation.

## Step 3 — Route each ticket on its own

Run Phase 1 per ticket. The backend ticket is Track 3, so an engineer scopes the contract before any code (for GraphQL, retail's `speckit-gql-scaffold` skill covers the design record). A client ticket can still be Track 1 or 2 on its own merits.

## Step 4 — Write the project plan

Save `.pm-project.md` in the orchestration session's scratch location. It is the orchestration session's file; ticket sessions never write to it. Two parts.

**Tickets**, one row each:

| Ticket | Repo | Track | Waits on | Session / branch | PR | Reviewed | Screenshots | Status |
|---|---|---|---|---|---|---|---|---|

*Reviewed* tracks whether the ticket session ran `/bookworm:code-review` before pushing and `/bookworm:pr-review` on the PR. A ticket isn't done until both ran and their findings were addressed.

**Release plan**: the order things merge and ship, and what each step waits on. For example:

1. Backend PR merges; schema regenerated.
2. Backend change deployed. (Check how each repo actually releases; don't assume.)
3. Web PR rebased onto main, generated types confirmed current, merges.
4. Mobile PR merges and goes out with the next app release; check whether the minimum supported app version matters.
5. Flag rollout: who turns it on, for whom, when.
6. Flag retired (the cleanup ticket).

Keep both parts current. A new orchestration session should be able to resume from this file alone.

## Step 5 — Create, name, and brief the ticket sessions

Each ticket session starts from a self-contained brief: ticket key, repo, track, what it waits on, the flag it uses, whether screenshots are needed, how to reach the orchestration session, and the rules above about reporting upward. The session should be able to start from the brief alone.

**Creating the session.** Use `start_session` if this app has it; the user does nothing. Otherwise use `spawn_task` with the session's title and the full brief as its prompt: it appears as a chip in the orchestration session, the user clicks it once, and it opens as a new session in its own worktree. Then find it with `list_sessions` and record its session id in the plan.

**Naming.** Follow the user's convention:

| What | Format | Example |
|---|---|---|
| Sidebar group | The project's name | `CP Decimal Precision` |
| Orchestration session | `<project> orchestrator` | `CP decimal orchestrator` |
| Ticket session | `(N) <project> <area>` | `(3) CP decimal Graph` |

- **N** is the PR's number in the project: PR 1, PR 2, and so on. A platform can have more than one PR, so the number is what tells two Mobile sessions apart. Use the same number in the plan.
- **Area** is `Graph` for a GraphQL change, `BE` or the owning team's name (`Portfolios`) for backend work, and `Web` or `Mobile` for clients.
- **Project** is short and in sentence case after the first word: `CP decimal`, not `CP Decimal Precision`.

Set titles with `set_session_title` (the app asks the user first if they named a session themselves), and file the project's sessions under one sidebar group with the sidebar tools.

Default order: backend first; web next (same repo as the backend in retail, so it can stack on the backend PR and be reviewed in parallel); mobile last (a separate repo can't stack, so it waits until the backend change is deployed).

## Step 6 — Change notices

When a ticket session changes something another ticket depends on, it reports it. It doesn't fix the other ticket.

**What counts:** a field added, renamed, or removed; a type or nullability change; a changed argument; different behavior a client relies on; the flag's name or rollout; a new dependency; a slipped timeline.

**How it travels:** the ticket session sends a short change notice (what changed, why, which PR) to the orchestration session with `send_message`. It goes through the orchestration session, never sideways to another ticket, and never through the user.

**What the orchestration session does with it:** decide which tickets are affected, update their rows and briefs, and send each affected ticket session a change request it can act on from that message alone. Then tell the user, in the next status, what changed and which sessions it went to. A client built against the old contract is the most expensive miss this shape of project has.

## Step 7 — Schedule local verification

The user runs one local environment. Don't let ticket sessions compete for it: tell the user which ticket to verify next, in dependency order, and record each one as verified in the plan.

## Step 8 — Run the release plan

Track progress through the ticket sessions' own reports, their recent work (`list_events`), and GitHub and Jira, never through other sessions' files. As each step of the release plan lands, work out what it unblocks and say so: after the backend merges, the web PR needs a rebase onto main and a check that generated types are current; after it deploys, the mobile ticket gets its go-ahead.

When a ticket session files a follow-up with `/capture-issue`, it links the new ticket to its own ticket; pick it up from Jira and add a row.

**Screenshots:** the plan records which tickets need them and why. The ticket session takes them, since only its branch has the code, and attaches them to its PR. Check the PR for them before marking the ticket done.

## Step 9 — Close out

The project is done when every row is merged, or deliberately dropped with the user's say-so. Then:

- Draft a closing update for the kickoff thread.
- Run one post-mortem (Phase 13) for the whole project instead of one per ticket.
- List the worktrees and sessions that can be cleaned up, and offer to archive the sessions.

Never transition tickets to Done; that stays the team's call.
