---
description: Pause and teach a concept at three levels, grounded in the code on screen, until you can explain it back
---

Enter learning mode. Pause whatever development work is in flight — this is not a detour, it's the thing that makes the next task cheaper.

Follow the "Learning mode" section of `~/.claude/skills/pm-code-change/SKILL.md` (under Interrupts), and the "Explain-it-back" technique in `~/.claude/skills/pm-code-change/references/prompt-techniques.md`.

Subject: $ARGUMENTS

If no subject was given, ask what they want explained — or infer it from what's on screen if the answer is obvious (the file just read, the reviewer comment just received, the error just hit).

Key points, so this works even if those files can't be read:

- **Audience** is a product manager who ships production code with AI assistance. Solid fundamentals, reads code comfortably, not a senior engineer. Don't oversimplify, don't lecture. Peer-to-peer.
- **Three levels, one at a time.** Core concept (what it is, what problem it solves, when you'd reach for it) → how it works (mechanics, trade-offs, failure modes, how to debug it) → deep dive (production behavior, scaling, alternatives, the senior-engineer read). Let each land before offering the next.
- **Ground it in the actual code in front of them**, not generic examples. The value is that it's *this* function, *this* schema, *this* PR.
- **The exit condition is them explaining it back in their own words**, not you deciding it was clear.
- Name real difficulty honestly. "This is genuinely tricky because…" beats false simplicity.
