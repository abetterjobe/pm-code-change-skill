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

- **Never send the user to a ticket session.** Not to type a command, give an approval, paste a brief, or click a permission prompt. The orchestration session delivers everything itself with the app's session tools: `send_message` to send, `list_events` to read a session's recent work, `list_sessions` / `get_session` to find sessions and their branch and PR.
- **Never tell the user to say a specific phrase.** Ask a plain question and act on the answer, however it's worded.
- **Ticket sessions report upward, not to the user.** Every brief tells the ticket session to send questions, change notices, and "done" to the orchestration session (`send_message` to `"parent"` when the orchestration session started it, otherwise its session id from the brief), then end its turn. A question asked in the ticket session itself waits for an answer nobody sees.
- **Approvals are relayed word for word.** When a ticket session needs the user's sign-off (opening a PR, a Jira write), the orchestration session puts the question to the user and sends back the user's answer quoted exactly, with what it approves. It never approves on the user's behalf, and never paraphrases a "yes."
- **The ticket is the design approval.** A ticket the user approved in Step 2 approves the design it describes, so a ticket session doesn't stop to ask for it again. Ticket sessions won't take an approval relayed from another session as the user's, so this has to be in the brief itself (Step 5). The ticket session goes ahead, then reports the decisions it made. It asks only about a choice the ticket doesn't settle.

### Permissions go through the orchestration session too

A permission prompt inside a ticket session is the one thing the orchestration session can't answer for the user: none of the session tools responds to another session's prompt. So the work is to keep prompts from appearing there, and to handle the rest from here.

1. **Start ticket sessions in a mode that doesn't prompt for routine work.** A session started with `start_session` inherits the orchestration session's permission mode and can't start higher. Before creating any ticket session, check this session's mode with `get_session("self")`. If it's lower than the project needs (usually `auto`), ask the user to raise it here, once: `set_session_permission_mode` on `"self"` shows the approval card in this session.
2. **Raise a ticket session from here when it needs more.** `set_session_permission_mode` on a session this one started shows its approval card in the orchestration session, not in the ticket session. Use it when a ticket session reports it's blocked on permissions, or when the watch (Step 8) finds one stuck.
3. **If a prompt is still pending in a ticket session after that, it's the one exception.** Whether raising the mode clears a prompt that is already open hasn't been checked. If it doesn't, tell the user which session and what the prompt is for, with a link, in one line. Then record what caused it in the plan, so the next brief can avoid it.

Looking at the local environment during verification also happens outside the orchestration session. Tell the user about it, and about the permission exception, at the start of the project rather than midway.

---

## Step 1 — Kickoff for the project

One announcement for the whole project, using the Kickoff section of `SKILL.md`, but describing the project rather than one ticket. Ticket sessions skip their own kickoff. Later updates go in the same thread.

## Step 2 — Break the work into tickets

Draft one ticket per PR-sized piece, split by repo and by behavior: typically a backend ticket for the contract, a web ticket, and a mobile ticket. Use Step 2 of `references/ticket-reconciliation.md` for the drafting rules.

**Decide the feature flag at the same time.** Work that spans more than one ticket ships behind one TestTrack flag, off by default, unless the user says otherwise. Settle which ticket creates it (normally the backend ticket, using the `create-feature-flag` skill), and that the other tickets reuse its name rather than adding their own. The flag's PR ships alongside the feature PRs: never show it to the user as a blocker or as the next step. Draft a cleanup ticket to retire the flag after launch, in the same batch, so it isn't forgotten.

**Ask about an epic; don't assume one.** *"Want these grouped under an epic?"* Default to no. Link the tickets to each other either way.

Show the full set and create them on one confirmation. That confirmation also starts their ticket sessions (Step 5); don't ask a second time.

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

Each ticket session starts from a self-contained brief. The session should be able to start from the brief alone. Every brief carries:

- The ticket key, repo, track, what it waits on, the flag it uses, and whether screenshots are needed.
- **Scope lock:** this session works on this ticket only. Anything else it notices goes to the orchestration session as a note labeled "optional, not blocking", or to `/capture-issue`. Never presented as required.
- **The approval line:** *"The ticket is the design approval. Proceed, and report the decisions you made. Ask the orchestration session only about choices the ticket doesn't settle."*
- **Reporting:** how to reach the orchestration session, and that every question, approval request, change notice, and "done" goes there with `send_message`, after which the session ends its turn. It never asks the user anything in its own session.
- **Permissions:** if a command needs a permission the session's mode doesn't allow, say so to the orchestration session rather than waiting at the prompt.

**Creating the session.** The orchestration session starts every session itself. The user never forks a session by hand, and never copies or pastes a brief.

- **Ticket sessions in the confirmed plan:** `start_session` with `initiation: "user_asked"` (the user asked for these when they confirmed the tickets), `use_worktree: true`, and the brief as the prompt. Use `context: "fork"` only while this conversation is still short and the orchestration session is itself in a worktree: a fork from a plain checkout shares that folder instead of getting its own worktree. Otherwise use `context: "fresh"` with the brief and a `background` paragraph.
- **New work that comes up mid-project** (a follow-up ticket, a split PR the user hasn't asked for yet): `start_session` with `initiation: "own_initiative"`. It appears as a card in the orchestration session, and the user starts it with one click. Nothing runs until they do.
- **If this app has no `start_session`:** use `spawn_task` with the session's title and the full brief. It shows as a chip the user clicks once.

Record each session's id in the plan as soon as the tool returns it.

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

## Step 7 — Relay questions and approvals

When a ticket session sends a question or an approval request, put it to the user in the orchestration session, in plain words, naming the ticket. Send the answer back word for word with what it approves (see "Approvals are relayed word for word"). The ticket session picks it up as its next turn. The user never opens the ticket session to answer.

Each status leads with one table: every ticket, its state, and what's waiting on the user. Questions from ticket sessions sit below it, one line each. Session-to-session detail stays out of the status unless the user has to act on it.

## Step 8 — Watch for sessions waiting on the user

The app wakes the orchestration session when a ticket session it started ends a turn. It doesn't when a ticket session is stuck partway through a turn, usually at a permission prompt. Set up a recurring check with `CronCreate` once the first ticket session starts (for example `7,22,37,52 8-19 * * 1-5`), with a prompt that:

1. Lists the project's sessions with `list_sessions` (the sidebar group), skipping archived ones.
2. Flags a session as waiting when it is running but idle for 15 minutes or more (likely a prompt partway through a command), or stopped with a last message that asks for something (read the last few events with `list_events`).
3. Skips anything already reported, using a small dedupe file in the scratch location keyed by session and last-activity time.
4. Stays quiet when nothing is new. Otherwise it sends one `PushNotification` naming each waiting ticket and what it needs, and handles what it can from here: relay the question (Step 7) or raise the mode (see "Permissions go through the orchestration session too").

Delete the check with `CronDelete` at close-out.

## Step 9 — Schedule local verification

The user runs one local environment. Don't let ticket sessions compete for it: tell the user which ticket to verify next, in dependency order, and record each one as verified in the plan.

## Step 10 — Run the release plan

Track progress through the ticket sessions' own reports, their recent work (`list_events`), and GitHub and Jira, never through other sessions' files. As each step of the release plan lands, work out what it unblocks and say so: after the backend merges, the web PR needs a rebase onto main and a check that generated types are current; after it deploys, the mobile ticket gets its go-ahead.

When a ticket session files a follow-up with `/capture-issue`, it links the new ticket to its own ticket; pick it up from Jira and add a row.

**Screenshots:** the plan records which tickets need them and why. The ticket session takes them, since only its branch has the code, and attaches them to its PR. Check the PR for them before marking the ticket done.

## Step 11 — Close out

The project is done when every row is merged, or deliberately dropped with the user's say-so. Then:

- Draft a closing update for the kickoff thread.
- Run one post-mortem (Phase 13) for the whole project instead of one per ticket.
- Delete the Step 8 watch.
- List the worktrees and sessions that can be cleaned up, and offer to archive the sessions.

Never transition tickets to Done; that stays the team's call.
