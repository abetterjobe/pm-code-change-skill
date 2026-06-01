# PM Code Change Skill

A Claude Code skill for non-engineers (product managers) driving code changes in shared codebases with human reviewers.

## What it does

Routes a coding task into **Fast**, **Standard**, or **Full Path** based on complexity, then runs only the workflow phases that match. A copy change stays cheap; a complex PR gets the full treatment (multi-pass review, reviewer-perspective rehearsal, fresh-eyes review assistance, post-mortem upgrade loop).

The skill is built around guardrails for non-engineer authorship:

- AI never opens PRs without explicit user confirmation
- AI never posts comments to GitHub — the user is the only voice on every PR
- AI never edits the skill's own instructions without sign-off
- For complex code, the workflow explicitly routes to engineer involvement before any code is written

See [`SKILL.md`](./SKILL.md) for the full 13-phase workflow.

## Install

```bash
git clone https://github.com/abetterjobe/pm-code-change-skill ~/.claude/skills/pm-code-change
```

That's it. The skill auto-loads in any Claude Code session that triggers it — starting a coding task, asking "should I build this or loop in an engineer?", preparing to open a PR, or responding to PR review comments.

## Use

In any Claude Code session, just start describing what you want to do:

> *"I want to update the 'Add a beneficiary' button text to 'Add beneficiary' across the app."*

The skill runs the gate (3 user-answerable questions), routes the task, and proceeds through only the phases that match the chosen path.

Or invoke individual phases on demand:

- *"do the routing"* → Phase 1 (path selection)
- *"sharpen the prompt"* → Phase 2 (structured task brief)
- *"do the pre-flight"* → Phase 4 (investigate the code area)
- *"review before PR"* → Phase 8 (multi-pass review)
- *"post-mortem"* → Phase 13 (improve the skill)

See `SKILL.md` for the full invocation map.

## What's in the box

```
pm-code-change/
├── SKILL.md                              # The 13-phase workflow
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

- Zevi Arnovitz's *"How a Meta PM ships products without ever writing code"* (multi-pass review, post-mortem upgrade loop)
- [nidhinjs/prompt-master](https://github.com/nidhinjs/prompt-master) (9 intent dimensions, prompt techniques)
- [thariqs.github.io/html-effectiveness](https://thariqs.github.io/html-effectiveness/) (output format catalog)

## License

TBD.
