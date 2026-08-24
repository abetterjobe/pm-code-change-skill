---
description: Investigate a code area before writing anything — precedent, docs, conceptual owner, reviewers
---

Run pre-flight investigation on a code area. No code gets written in this step — the job is to understand what's there and surface anything unexpected.

Follow Phase 4 of `~/.claude/skills/pm-code-change/SKILL.md`.

Area or task: $ARGUMENTS

The four steps:

1. **Search for similar features.** Existing patterns set precedent — if a similar feature exists, it almost certainly defines the convention to follow. For UI changes, check adjacent pages in the same flow first; they're the highest-probability source of an applicable pattern. State what you found explicitly: *"X pattern exists at [file]; I'll use that rather than writing something new."*
2. **Read the process docs in the area.** README, CONTRIBUTING, AGENTS.md, ADR/SDR directories, runbooks. The Book's rules auto-load by file type, but repo- and directory-specific docs don't — read those yourself.
3. **Identify the conceptual owner.** Ask "who owns this data or behavior?" before "where is it easiest to add this?" The correct location is usually not the most convenient one.
4. **Identify likely reviewers and codeowners.** Check `CODEOWNERS` or recent commit authors in the touched files.

Also determine whether this needs a **design review** — The Book requires one for a new pattern, a novel application of an existing pattern, or a new way of interacting with another app, and a lightweight ADR when a pattern changes. Discovering that requirement after the code is written is one of the most expensive misses available.

Assume no requirements or scope beyond what was explicitly described. If anything turns up unexpected — existing precedent, a design-review requirement, an unclear owner — stop and flag it rather than proceeding.
