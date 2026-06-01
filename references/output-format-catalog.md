# Output format catalog

For each output the skill produces, pick the format that matches the content's shape.

## Decision rules

| Content shape | Format |
|---|---|
| Spatial (diff, dependency graph, side-by-side) | HTML |
| Many items with severity/classification | HTML |
| Long-form, multi-section, will be re-visited | HTML |
| Will be shared with engineers or saved | HTML |
| Linear, glanced once, in-chat | Markdown |
| AI-to-AI handoff (one phase feeding another) | XML |
| Short prose answer | Plain text |

## HTML patterns and when they apply

| Pattern | When to use | Where in this skill |
|---|---|---|
| Annotated diff (margin notes, severity tags, file:line jump-links) | Many findings of varying severity to act on | Phase 8, Pass 5 |
| Side-by-side comparison | Two or more approaches to evaluate | Phase 6 when alternatives exist; Phase 4 when comparing precedent features |
| Timeline | Sequential events mapped to a frame | Phase 13 post-mortem |
| Module map (boxes and arrows) | Showing relationships in an unfamiliar area | Phase 4 when the area is new to the user |
| Collapsible sections | Long output with sections of varying interest | Any phase producing >1 screen of content |
| Color-coded status | Classifications with priority/severity | Pass 2 violations, Pass 5 fix-now/documented/rejected, Phase 12 merge checklist |
| Reviewer-persona cards | Pass 3 output with one card per reviewer | Phase 8, Pass 3 when ≥3 reviewers |
| File-by-file tour | PR walkthrough with reasoning per file | Phase 9 Full Path PR tour |

## File naming convention

Save to the project root with prefix `.pm-` and phase suffix:

- `.pm-brief.html` — Phase 2 task brief
- `.pm-plan.html` — Phase 6 plan (when alternatives exist)
- `.pm-review-<short-sha>.html` — Phase 8 review
- `.pm-pr-tour-<pr-number>.html` — Phase 9 PR tour
- `.pm-postmortem-<pr-number>.html` — Phase 13 post-mortem

Gitignore `.pm-*.html` if not already.

## When in doubt

Default to markdown for ephemeral in-chat outputs. Default to HTML for any output the user will open in a browser, share with engineers, or come back to later.

The principle: **diffs, dependency graphs, and severity-tagged lists are spatial information; markdown flattens them.** Reach for HTML when the content has structure that markdown can't carry.
