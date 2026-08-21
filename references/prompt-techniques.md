# Prompt techniques reference

A toolbox for any phase that prompts an AI (Phase 2 for shaping the task; Phase 8 Pass 4 for spawning a fresh-eyes sub-agent; anywhere else that drafts a prompt). Apply selectively based on what the prompt needs.

- **Role assignment** — assign an expert identity to calibrate depth.
  *"Act as a staff engineer reviewing a GraphQL schema change. You care about API contract stability and domain placement."*

- **Few-shot examples** — 2–5 worked examples for format consistency.
  *Use when the desired output shape is hard to describe but easy to demonstrate (e.g., reviewer-persona comment style).*

- **XML structural tags** — `<task>`, `<context>`, `<constraints>`, `<output-format>` wrap sections so the model parses reliably.
  *Especially useful when the prompt has multiple distinct sections and the model tends to blur them.*

- **Grounding anchors** — explicit anti-hallucination rules.
  *"If you don't know whether a precedent exists, say 'unknown' — do not guess. Cite file:line for every claim about existing code."*

- **Chain-of-thought** — force step-by-step reasoning before the answer.
  *"Think step by step. Show your reasoning before the final classification."*
  *Caveat: skip for reasoning models that already do this internally.*

- **Attack, then steelman** — stress-test a plan before committing to it. Distinct from asking for a critique: a critique returns polite suggestions, an attack returns the assumption that breaks it.
  *"Here is the plan: [plan]. Your job is to destroy it. Find every assumption I'm making that could be wrong, and name the single biggest problem. Generic risks don't count — be specific to this plan. Then steelman it: build the strongest case for doing it anyway. Then tell me what you actually think."*
  Used by Phase 6, where changing the approach is still cheap. Phase 8 Pass 2 is adversarial about the code; this is the equivalent for the plan. The steelman half matters — attack-only produces reflexive negativity, which is as useless as reflexive agreement.

- **Style cloning** — get drafts that sound like the user instead of like an assistant. Without samples, any "write this in my voice" instruction produces a polished corporate register that reviewers read as automated.
  *"Here are 3–5 things I've actually written: [samples]. Analyze the patterns — sentence length, rhythm, how I open and close, vocabulary I favor, what I never do. Then match that pattern in anything you draft for me."*
  Used by Phase 10. Analyze the patterns rather than describing the style — a description produces an imitation of a description. The best samples are the user's own PR comments and Slack messages on similar threads, not polished writing.

- **Explain-it-back** (Feynman) — a completion test for any explanation, not just a way to phrase one. An explanation that reuses the vocabulary of the thing being explained leaves the user with a definition and no comprehension.
  *"Explain [topic] using analogies and everyday examples. After each one, check whether I actually followed it. Keep going until I can explain it back to you in my own words."*
  Used by learning mode. The exit condition is the user's own restatement — not the explainer's judgment that it was clear.
