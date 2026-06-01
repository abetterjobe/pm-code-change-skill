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
