# Task brief

Detail for Phase 2. Only runs on Track 2 and Track 3 — Track 1 skips it.

## Process

1. **Restate the ask in one sentence.**
2. **Score the 9 dimensions** as ✅ clear / ⚠️ implicit / ❌ missing:
   - **Task** — what action, on what
   - **Input** — what data/state is given
   - **Output** — what changes / what artifact is produced
   - **Constraints** — what cannot change; what must be matched
   - **Context** — surrounding system, related features, ticket
   - **Audience** — who sees the result (end user, internal, engineers)
   - **Memory** — relevant prior decisions, past PRs, conventions
   - **Success criteria** — how we know we're done
   - **Examples** — similar features that set precedent
3. **Pick the 3 most critical ❌ or ⚠️ dimensions and ask one question each.** Max 3. The forcing function matters — open-ended Q&A wastes the user's time.
4. **Produce a Task Brief** with all 9 dimensions filled in (best inference for any unanswered, marked as such).
5. **Hand off to Phase 3**, which now operates against the Brief instead of the raw ask.

## Output

XML, consumed by the AI in Phase 3. See `output-format-catalog.md` for when to additionally render the Brief as HTML for the user.

```
<task-brief>
  <task>...</task>
  <input>...</input>
  <output>...</output>
  <constraints>...</constraints>
  <context>...</context>
  <audience>...</audience>
  <memory>...</memory>
  <success-criteria>...</success-criteria>
  <examples>...</examples>
</task-brief>
```

Save the Brief to `./.pm-brief.html` so the user can review it before Phase 3 starts.

## A note on the question cap

Three questions, maximum. This is a deliberate departure from the unbounded "keep asking until you have no more questions" approach — that works for someone whose whole job is the build, but it spends a product manager's time badly. The cap forces prioritization: ask the three that would most change the output, infer the rest, and mark the inferences so they can be corrected cheaply.

Assume no requirements or scope beyond what was explicitly described. Inferred scope is the most common source of a diff the user didn't ask for.
