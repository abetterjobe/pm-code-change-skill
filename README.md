# PM Code Change Skill

A Claude Code skill for non-engineers (product managers) driving code changes in shared codebases with human reviewers.

## What it does

Routes a coding task into one of three tracks, then runs only the workflow that matches:

| Track | For | Who drives |
|---|---|---|
| **1 — Direct** | Copy, labels, styling, animation, config, analytics events | PM alone — a self-contained 6-step workflow |
| **2 — Guided** | Real behavior changes in one repo | PM drives, AI advises, engineer reviews |
| **3 — Partnered** | Contract changes, multi-system work, placement ambiguity | Engineer scopes the design *before* code |

A copy change stays genuinely cheap. A complex PR gets the full treatment (multi-pass review, reviewer-perspective rehearsal, fresh-eyes review assistance, post-mortem upgrade loop). Certain changes — migrations, schema changes, anything touching customer money or a displayed figure — force Track 3 regardless of how small the diff looks.

The skill is built around guardrails for non-engineer authorship:

- AI never opens PRs without explicit user confirmation
- AI never posts comments to GitHub — the user is the only voice on every PR
- AI never edits the skill's own instructions without sign-off
- For complex code, the workflow explicitly routes to engineer involvement before any code is written

**Standards come from The Book**, not from this skill. Betterment's engineering standards (https://the-book.betterment.io) auto-load into Claude Code by file type. This skill owns *process* — how a non-engineer gets a change from idea to merge without wasting reviewer time — and cites The Book for *standards* rather than keeping a copy that drifts.

Every track ends with ticket reconciliation: the Jira ticket is described accurately, assigned to you, in an active state, in the current sprint, and linked to the PR — or created and filled out if it doesn't exist yet.

See [`SKILL.md`](./SKILL.md) for the full workflow (Phase 0 through Phase 14).

## Install

```bash
git clone https://github.com/abetterjobe/pm-code-change-skill ~/.claude/skills/pm-code-change
```

That's it. The skill auto-loads in any Claude Code session that triggers it — starting a coding task, asking "should I build this or loop in an engineer?", preparing to open a PR, or responding to PR review comments.

## Use

In any Claude Code session, just start describing what you want to do:

> *"I want to update the 'Add a beneficiary' button text to 'Add beneficiary' across the app."*

The skill runs the gate (3 user-answerable questions plus a hard-override check), routes the task to a track, and proceeds through only the workflow that matches.

Or invoke individual phases on demand:

- *"set up the branch"* → Phase 0 (workspace + branch hygiene)
- *"do the routing"* → Phase 1 (track selection)
- *"sharpen the prompt"* → Phase 2 (structured task brief)
- *"do the pre-flight"* → Phase 4 (investigate the code area)
- *"review before PR"* → Phase 8 (multi-pass review)
- *"post-mortem"* → Phase 13 (improve the skill)
- *"reconcile the ticket"* → Phase 14 (Jira accuracy, assignment, sprint, PR linkage)

Plus two interrupts, callable from anywhere:

- *"capture an issue"* → file a follow-up ticket for something spotted mid-task, without derailing the current work
- *"explain this to me"* → pause development and teach the concept at three levels, instead of escalating past it

See `SKILL.md` for the full invocation map.

## What's in the box

```
pm-code-change/
├── SKILL.md                              # Phase 0-14 workflow + track routing
├── README.md                             # This file
└── references/
    ├── reviewer-profiles.md              # Templates for Phase 8 Pass 3
    ├── prompt-techniques.md              # Toolkit used by Phase 2 + Pass 4
    └── output-format-catalog.md          # When to use HTML / markdown / XML
```

## Update

```bash
cd ~/.claude/skills/pm-code-change
git pull
```

Next Claude Code session picks up the new version.

## Contribute back

When you use the skill and find a gap — a misroute, a missing reviewer concern, a phase that should have caught something — Phase 13 generates a proposed diff. Send it back via:

- A GitHub issue or PR on this repo
- (Slack channel TBD — coming once a few users have tried the skill)

The skill is designed to compound: every shared post-mortem helps the next user avoid the same mistake.

## Origin

Developed by Andy Jobe with workflow concepts borrowed from:

- Zevi Arnovitz's *"How a Meta PM ships products without ever writing code"* and [AI Development Workflow](https://shorthaired-billboard-f9a.notion.site/Zevi-s-AI-Development-Workflow-2c86baffbc90810fa63bd0ee8ecffce9) (multi-pass review, post-mortem upgrade loop, peer-review verification, status-tracked plan files, issue capture, learning mode)
- [nidhinjs/prompt-master](https://github.com/nidhinjs/prompt-master) (9 intent dimensions, prompt techniques)
- [thariqs.github.io/html-effectiveness](https://thariqs.github.io/html-effectiveness/) (output format catalog)

## License

TBD.
