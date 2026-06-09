---
name: pm-code-change
description: Workflow for non-engineers driving code changes in a shared codebase. Routes the task into Fast, Standard, or Full Path based on complexity. Use when starting a coding task, asking "should I build this or loop in an engineer?", preparing to open a PR, or responding to PR review comments.
---

# PM Code Change Skill

A workflow for product managers (or junior engineers) driving code changes with AI assistance. Walks the user and the AI through the full process to avoid confusion, wasted time, and common mistakes.

## When this skill applies

- User is not an engineer (or is junior).
- User is the driver of a code change. AI is the executor and advisor.
- The change touches a real codebase, not a sandbox.
- AI's job: assess complexity, surface signals, write code, draft responses. Gates exist where they protect against predictable mistakes (Phase 9 PR creation, Phase 10 posting, Phase 13 skill edits) — those require explicit user sign-off.

## How to invoke

Run the full workflow end-to-end by saying "run the PM code change workflow."

Or invoke individual phases on demand:

- "do the routing" → Phase 1
- "sharpen the prompt" → Phase 2
- "do the intake" → Phase 3
- "do the pre-flight" → Phase 4
- "score complexity" → Phase 5
- "make the plan" → Phase 6
- "review before PR" → Phase 8 (passes per path)
- "just persona review" → Phase 8, Pass 3 only
- "fresh eyes" → Phase 8, Pass 4 only
- "respond to comments" → Phase 10
- "post-mortem" → Phase 13

## Output format

Each phase notes a default format, but the AI should pick the format from `references/output-format-catalog.md` that best matches the content's shape. HTML for spatial/comparative/long-form content. Markdown for linear or ephemeral content. XML for AI-to-AI handoffs.

## Session start: sync with the remote

At the beginning of any session that invokes this skill, sync with the remote so the user is running the latest version:

```bash
cd ~/.claude/skills/pm-code-change && \
  git diff --quiet && git diff --cached --quiet && \
  git pull --ff-only --quiet 2>/dev/null || true
```

This pulls maintainer updates only if the local copy has no uncommitted changes. If local has changes, the pull skips silently and the session uses the local version (Phase 13's commit/push flow handles propagating those changes back to the remote when ready).

Run this once per session, before Phase 1.

---

## Phase 1: Path routing

Run this first. Its job is to prevent the full workflow's overhead in the cheap case. The full workflow exists for Full Path PRs where skipping a phase costs days; for a copy change, running it costs hours and clutters the repo.

### The 3 questions

These are deliberately user-answerable. The AI handles the technical questions (file count, API contract impact, placement ambiguity, cross-system coordination) in Phase 4 (pre-flight) and Phase 5 (complexity assessment) after routing, and escalates the path if anything technical comes back high.

Answer each:

1. Can you describe what changes in one sentence?
2. Is it easily reversible by re-editing the same lines?
3. Is it labels/copy/config only — no new business logic?

**Scoring:**

- **3/3 yes → Fast Path** (Tier 1)
- **1–2 yes → Standard Path** (Tier 2)
- **0 yes → Full Path** (Tier 3)

When borderline, **lean lighter**. Escalation mid-flow is cheap; downgrading is awkward — and Phase 5 will catch a misroute almost immediately.

### Path → phase map

| Phase | Fast | Standard | Full |
|---|---|---|---|
| 2 Sharpen prompt | skip | optional | run |
| 3 Intake | one-line restate | run | run |
| 4 Pre-flight | quick precedent search | run | run + module map |
| 5 Complexity confirm | quick spot-check (all 4 axes must score low; else escalate) | confirm | run |
| 6 Planning | skip | run | run + side-by-side if alternatives |
| 7 Build | execution rules apply | execution rules apply | execution rules apply |
| 8 Pre-PR review | Pass 1 only, markdown | 1+2+3+5, HTML if >3 findings | all 5 passes + UI pass, HTML |
| 9 Open PR | one-line description | standard description | full description + HTML tour |
| 10–12 Reviews / CI / merge | run | run | run |
| 13 Post-mortem | only if surprised | run if substantive comments | run |

### Escalation triggers

Move up a path mid-flow if any fire:

- File count exceeds 3 (Fast → Standard)
- A reviewer disagrees with the approach (Standard → Full)
- Scope creep emerges (any path → next up)
- An in-flight signal from Phase 7 triggers (any path → next up)
- A pre-flight finding reveals an unfamiliar area, an SDR requirement, or a placement ambiguity (Fast → Standard, Standard → Full)

State the escalation explicitly: *"I'm escalating from Fast Path to Standard Path because [trigger]."* Then resume from the appropriate phase.

### Worked example — Fast Path

> *"Change the modal header from 'Add a beneficiary' to 'Add beneficiary' across the app."*

Routing: 3/3 yes → Fast Path.

What runs:
- One-line restate.
- Quick grep for the old string. Note the file(s).
- Make the change.
- Phase 8 Pass 1: tests pass, no other files touched, scope still tiny.
- Open PR with a one-line description (after user confirmation).

What does **not** run: Phase 2, Phase 6, Phase 8 Pass 2/3/4/5, Phase 9 PR tour, Phase 13 post-mortem, any HTML output.

Phase 5 still runs as a quick spot-check (all 4 axes must score low). If any axis comes back high, the routing was wrong — escalate.

---

## Phase 2: Sharpen the prompt

Before Phase 3, sharpen the ask itself. The cost of a fuzzy initial ask compounds through every later phase.

**When to run this phase:**
- The initial ask is more than one sentence and isn't already a structured ticket.
- Phase 1 routed this to Standard or Full Path.
- The user is starting a new feature, not a follow-up to an existing one.
- The user explicitly says "sharpen the prompt."

**When to skip:**
- The ask is a one-liner with obvious scope.
- The user is mid-task continuing prior work.

**Process:**

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

**Default output format:** XML (consumed by the AI in Phase 3). See `references/output-format-catalog.md` for when to additionally render the Brief as HTML for the user.

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

For Standard / Full Path tasks, save the Brief to `./.pm-brief.html` so the user can review it before Phase 3 starts.

---

## Phase 3: Task intake

Establish what's actually being asked.

**If Phase 2 ran:** the Brief already covers ambiguity. Phase 3 confirms the Brief and produces a one-sentence statement of intent. Skip clarifying questions unless something in the Brief is still unclear.

**If Phase 2 was skipped (Fast Path):** do the full intake from scratch.

1. **Restate the ask in one sentence.** If you can't, ask the user to clarify before proceeding.
2. **Ask any questions you have** (skip if Phase 2 already covered them). Don't assume. If anything is ambiguous — the desired behavior, affected users, which entity/account/account-type, what "done" looks like, whether existing similar features should be matched — surface it now.
3. **Identify the user-facing outcome.** What changes for the end user when this ships?
4. **Find the smallest possible change that achieves it.** Default to the minimal viable change. Larger scope = more risk.
5. **Locate the ticket (if any).** Read it fully. Acceptance criteria often reveal scope-creep risk.
6. **State your one-sentence understanding back to the user, with any open questions.** Confirm before proceeding.

---

## Phase 4: Pre-flight

Before writing code, investigate the area.

**By path:**
- **Fast Path:** one grep for the changed string/file and a quick check for adjacent precedent. Skip the full investigation. If anything unexpected turns up, escalate.
- **Standard / Full Path:** run all 4 steps below.

1. **Search the codebase for similar features.** Existing patterns set precedent. If a similar feature exists, it almost certainly defines the convention to follow. **For UI/UX changes, check adjacent pages in the same flow first** — they're the highest-probability source of an applicable pattern. If you find one, state it explicitly: *"X pattern exists at [file]; I'll use that instead of writing new CSS/components."*
2. **Read process docs in the area.** README, CONTRIBUTING, AGENTS.md, ADR/SDR/RFC directories, runbooks. Discovering process requirements mid-PR causes rework.
3. **Identify the conceptual owner of the change.** Ask "who owns this data/behavior?" before "where is it easiest to add this?" The conceptually correct location is usually not the most convenient.
4. **Identify likely reviewers and codeowners.** Check `CODEOWNERS` files or recent commit authors. Knowing who reviews helps frame the change — and seeds Phase 8 Pass 3.

If any of these turn up something unexpected (existing precedent, an SDR process, an unclear owner), pause and flag it.

---

## Phase 5: Complexity assessment

**By path:**
- **Fast Path:** quick spot-check. Score all 4 axes; every one must come back **low**. If any axis scores high, the routing was wrong — escalate to Standard or Full based on the count of highs. State the escalation explicitly.
- **Standard Path:** full scoring; confirm Phase 1's classification and refine.
- **Full Path:** full scoring with detailed reasoning per axis.

Score the task on four axes. Each axis is graded **low** or **high** complexity.

**Axis 1 — Change type**
- low: copy, labels, flag toggles, analytics events on existing screens
- high: behavior changes (new logic, conditions, UI flows) OR adding/changing fields or methods that other systems depend on

**Axis 2 — API contract impact**
- low: code with no external consumers (private methods, internal classes, implementation changes within a single service)
- high: GraphQL schema, REST endpoint, event schema, DB migration that other repos/services consume

**Axis 3 — Placement ambiguity**
- low: "where does this belong" answers itself in one sentence (e.g., "it's a field on the User model")
- high: multiple types/models could conceptually own it and you have to weigh trade-offs

**Axis 4 — System coordination**
- low: single repo, one logical area
- high: multiple repos/services, or coordination across teams (backend + frontend + mobile + docs)

### Scoring

Count the number of axes scored high. That total maps to a path — a framework for deciding whether the PM can proceed solo, should read docs first, or should align with an engineer before any code is written.

- **0 highs → Fast Path.** PM can drive. Proceed.
- **1 high → Standard Path.** PM can drive, but read the relevant area docs (README, CONTRIBUTING, ADR) before starting.
- **2+ highs → Full Path.** Pause before writing code. Either loop in an engineer to scope the design, or at minimum spend time defining the solution more rigorously with an engineer's input. State this to the user: *"This looks like a Full Path task because [specific axes that scored high]. Want to pull in an engineer first, or proceed?"*

If this scoring contradicts Phase 1's initial routing, the more cautious path wins — and state the escalation explicitly.

### High-complexity disguises (tasks that look low but aren't)

- "Just add a field to…" — adding a field to a public API is a contract change.
- "Just show this data on the screen" — if the data isn't on the client, it's an API change.
- "It should already be there, just expose it" — if it's not exposed, find out why first.
- "It's the same as [other feature]" — similar features often diverge in subtle ways.

---

## Phase 6: Planning + decision point

Before building, write down the approach.

1. **State the approach in 2–3 bullets.** What you'll change, where, and why.
2. **List unknowns and produce questions for any that need engineer input.** Unknowns fall into two buckets:
   - Things the AI can investigate by reading code or docs — investigate first.
   - Things that require human judgment (design choices, conventions, process) — draft a concrete question for the user to take to an engineer.

   For each engineer-bound question:
   - Specific enough to answer in 1–2 sentences
   - Phrased so the user can read it aloud or copy/paste
   - Focused on what you need to know to proceed confidently

   Categories to draw from: **placement, contract shape, process (SDR/ADR/RFC), coordination, conventions, risk.**

3. **Decide based on the path:**
   - **Fast Path** — proceed.
   - **Standard Path** — the AI reads the relevant area docs itself, then proceeds.
   - **Full Path** — share approach, unknowns, and engineer questions with the user. They decide. If engineer questions exist, state explicitly: *"Once you have answers, share them and I can resume."*

---

## Phase 7: Building

**By path:** same rules apply across all paths — Fast Path doesn't get to skip the execution rules just because the change is small. Anti-patterns are still anti-patterns at any size.

Apply these rules continuously, not just at the start.

### Execution rules

1. **Place things where they belong.** Conceptual owner before convenient call site.
2. **Read the docs before writing code.** Even when the task seems obvious.
3. **Keep logic in the layer that owns it.** Don't inline business logic into schema types, serializers, config files, or interfaces. If a method does real work, it belongs in a dedicated class.
4. **Don't add protective code without verifying the risk is real.** Before adding backward-compat shims, nil guards, migration helpers, feature flags — verify the scenario being protected against can actually happen in current production state. If the risk can't be confirmed, don't add the code.
5. **Hold the line on minimum viable change.** Restate the smallest possible change at each major decision point in the build. If the working diff has grown beyond the original scope, surface it explicitly: *"This started as X files; it's now Y. The growth comes from [reason]. Is this necessary, or scope creep we should split?"*

### In-flight signals to flag

When any of these appear, surface them immediately:

- Reviewers disagree on the same design point.
- A reviewer references a pattern in code you haven't read.
- Scope grew since starting (file count up, new types/interfaces appearing).
- User is editing process docs (SDR/ADR/RFC) they don't fully understand.
- User would have to defend a choice in a comment they couldn't defend without quoting you.
- A change you thought was internal turns out to affect a public API contract.
- Iteration count on the same design decision is exceeding 3–5 attempts. Stop, restate the actual user need, and search again for existing patterns before continuing. Sustained iteration without convergence is a sign the wrong approach is being refined.

### Anti-patterns to avoid

Specific failure modes from prior work. Catch these proactively:

- Signing PR responses as AI ("this is Claude") — engineers see an automated agent making design decisions.
- Adding backward-compat shims without first verifying with `git show origin/main:<file> | grep <symbol>` that the thing being made compatible-with actually exists.
- Inlining resolver / business logic in schema type definitions.
- Placing fields on the most reachable type rather than the conceptually correct one.
- Mixing "empty list" and "null" semantics — pick one and be consistent.
- Adding `if <invariant>` checks where the invariant is guaranteed by upstream filtering.
- Deferring decisions to follow-up PRs when the fix is in scope and small.
- Writing new CSS, components, or utilities for a UX pattern that exists elsewhere in the codebase. Grep for the existing pattern first, even if it means a less elegant implementation.
- Pulling adjacent unrelated issues into the current PR ("while I'm here"). File a follow-up ticket. The PR's job is the original ask, not surrounding cleanup.

---

## Phase 8: Pre-PR review (multi-pass)

This is the highest-leverage phase. Most engineer-time-wasted on past PRs has been predictable comments that a robust self-review would have caught. The goal here is to surface those comments before a human sees them.

**By path:**
- **Fast Path:** Pass 1 only. Markdown output, in-chat. Skip everything else.
- **Standard Path:** Passes 1, 2, 3 (1–2 personas), and 5. Skip Pass 4 unless the change is substantial (≥5 files, new public API surface, or new business-logic class). HTML output only if >3 findings.
- **Full Path:** All 5 passes + UI pass (if any UI changed). HTML output mandatory.

Run the included passes in order. Don't skip to Phase 9 until the path's final pass is complete.

### Pass 1 — Mechanical checklist

The minimum gate.

1. Tests written and passing for new behavior.
2. Schema/generated files regenerated (not hand-edited).
3. No commented-out code, no debug prints, no TODO markers added in this diff.
4. Diff is minimal — anything not serving the original task is cut.
5. Did scope expand beyond the original ask? If yes, surface to the user — ask whether to split before continuing.

### Pass 2 — Adversarial self-review against the skill's own rules

Walk the diff line-by-line against Phase 7's execution rules and anti-patterns. For each rule, ask "did I violate this?" — out loud, with a yes/no. Not "did I try to follow this?" — *did the resulting code follow it?*

- Is anything inlined that should be its own class? (Rule 3)
- Did I add protective code without verifying the risk is real? (Rule 4)
- Is anything placed on the most reachable type instead of the conceptual owner? (Anti-pattern)
- Are there `if <invariant>` checks where the invariant is guaranteed upstream? (Anti-pattern)
- Did I mix "empty list" and "null" semantics? (Anti-pattern)
- Did I defer small in-scope fixes to follow-ups when they belonged here? (Anti-pattern)

Report each as ✅ clean / ⚠️ borderline / ❌ violation. Fix every ❌ before Pass 3.

### Pass 3 — Reviewer persona simulation

For each likely reviewer (from `CODEOWNERS`, recent commit authors in the touched files, or `references/reviewer-profiles.md`), take on their known concerns and review the diff *as them*. Be specific — quote what they'd say.

Output format per reviewer:

> **As [Name]:** "[Specific comment they'd make, in their voice]. [What they'd want changed.]"

If a persona has nothing to say, state that explicitly — don't skip silently.

If a reviewer's profile isn't documented yet, infer from their last 5–10 comments on this area of the codebase. Useful commands:

- `gh api repos/<org>/<repo>/pulls/comments --paginate -q '.[] | select(.user.login=="<handle>") | .body' | head -50`
- `gh search prs --owner <org> --reviewed-by <handle> --limit 10`

After running Pass 3, surface any new findings about a reviewer's recurring concerns — Phase 13 will propose adding them to `references/reviewer-profiles.md`.

### Pass 4 — Fresh-eyes second opinion

Invoke an independent reviewer with no context from this session. Two options:

- Run the `code-review` skill at `--effort high`. **Never pass `--comment`** — that posts findings directly to the PR, which violates Phase 10's posting protocol. Findings go to Pass 5 synthesis only.
- Spawn a general-purpose sub-agent with the diff and the original task description only, prompted: *"Review this diff for correctness bugs and code quality issues. You have no context on prior discussion. Be specific and quote line numbers."*

The value of fresh-eyes review is bias removal — the original-context reviewer (mid-task) has invested in the current approach; the fresh-eyes reviewer hasn't.

### Pass 5 — Synthesize and decide

Collect findings from passes 1–4 into one list. For each finding, classify it:

- **Fix now** — issue is real and in scope. Address before opening PR.
- **Document as a known trade-off** — issue is real but out of scope. Add to PR description so reviewers see it was considered.
- **Reject with reasoning** — issue is wrong. Note why in case the same comment surfaces in human review.

**Default output format:** see `references/output-format-catalog.md`. For most PRs with >3 findings, render as `./.pm-review-<short-sha>.html` using the annotated-diff pattern: columns for source pass, file:line (linked), severity, classification, reasoning. The "documented trade-offs" rows copy cleanly into the PR description. Short reviews (≤3 minor findings) can stay as a markdown list.

Only proceed to Phase 9 when every Pass 1 item is ✅. For Standard / Full Path, every Pass 2 ❌ must also be fixed.

---

## Phase 9: Opening the PR

### Prerequisite: local verification

Before assembling the PR draft, confirm the user has seen the change working in their local environment. The AI must not propose opening a PR until the user has confirmed local verification.

If local verification is blocked by environment issues, the user makes the call — but the default is: **no local verification, no PR.** Do not propose pushing or opening a PR before this gate clears.

### Creation protocol

The AI **creates the PR**, but only after explicit user confirmation. This is distinct from Phase 10's prohibition on posting comments — Phase 9 is a single bounded action with sign-off; Phase 10 is ongoing engagement with reviewers.

Workflow:

1. AI assembles the draft per the checklist below (title, description, reviewers, tour file if Full Path).
2. AI shows the full draft to the user — title, description (rendered), reviewer list, and the exact `gh pr create` invocation it intends to run.
3. User reviews, edits whatever needs editing, and confirms by saying "open it" or equivalent.
4. AI runs `gh pr create` with the confirmed content.
5. AI reports the PR URL back to the user.

If the user doesn't confirm — or edits the draft — loop back to step 2 before running `gh pr create`. The AI never opens a PR without explicit user confirmation.

### By path

- **Fast Path:** title + one-line description. Skip the tour, skip the trade-offs list (nothing was traded off).
- **Standard Path:** full description with what/why/how-to-test. PR tour optional.
- **Full Path:** full description + HTML PR tour saved to `./.pm-pr-tour-<pr-number>.html`. Link the tour from the PR description.

### Draft checklist

1. **Title and description accurately reflect the final change** — not the original intent if the work evolved. **If the diff changed after the initial draft (force-push, amend, file removal), re-check the description against the current diff and update any stale references.**
2. **Description sections:** what changed, why (link ticket/intent), how to test, mobile/coordination impact.
3. **Link the ticket** at the top of the description.
4. **Update the ticket title** if the work diverged from the original ticket title.
5. **Add reviewers** based on CODEOWNERS or area expertise.
6. **Include the Pass 5 "documented trade-offs" list** in the PR description so reviewers see what was considered and consciously deferred.

If title/description drifts from reality during review, update them. Don't let them lie.

---

## Phase 10: Responding to reviews

### Posting protocol — the AI never posts

**The AI never posts comments to GitHub unprompted.** The AI drafts; the user reviews, edits, and either posts themselves or directs the AI to post. No `gh pr comment`, no `gh api .../comments`, no batch auto-replies driven by the AI's own judgment. The user is always the author of the content.

**Consent, not prohibition.** The rule is *no posting without explicit consent* — not "no posting ever." When the user reviews a draft and directs the AI to post it ("post this," "go ahead and reply"), the AI executes the post. The user has reviewed the content and consented. The prohibition is on the AI deciding *whether* to post, not on the mechanical action of submitting content the user has approved. **Do not refuse a clear request by quoting this section back at the user.**

This applies to:
- Inline code comments
- Replies in existing comment threads
- New top-level PR conversations
- PR description edits that include a response to a reviewer

The AI may freely edit code in response to a comment (that's Phase 7 work continuing), but the *acknowledgment* — even "fixed in latest commit" — comes from the user.

Any draft that includes a `gh pr comment` invocation is itself the violation — stop drafting and revert to text-only.

### Who responds to what

**User can respond to (AI drafts):**
- Logistics (timing, tickets, titles, linking)
- Intent (why we're building this)
- Concrete fixes (typo, rename, missing test, adding a case to a test)
- Acknowledging a fix has been made

**Engineer should respond to (don't draft — escalate):**
- "Have you considered X?" referencing existing code
- Type system, schema, or API contract questions
- Reviewer disagreements
- Blocking comments
- Domain model placement
- Anything labeled `(blocking)`

### Drafting protocol

- **Never sign drafts as AI or attribute them to AI.** The user is the author.
- If the user can't defend the draft in their own words, that's the signal to recommend involving an engineer — not to rewrite the draft.
- When two reviewers disagree, don't pick a side. Draft a message that surfaces the conflict to both and asks them to align. Tag them by name. User posts.
- For each comment, take an action: fix in code, draft an acknowledgment, draft a push-back with reasoning, or escalate to an engineer. Don't leave comments hanging — but the user always posts.

---

## Phase 11: CI failures

Default action: investigate before retrying. A retry that "works" doesn't mean the failure was flaky.

- **Tests failing consistently and touching your changes** → investigate. Likely a regression you caused.
- **Linter errors on your files** → fix.
- **Schema drift / generated-file diffs** → regenerate via the codebase's documented command. Don't hand-edit.
- **Flaky tests on a path unrelated to your changes** → flag to the user. Identify the owner. Recommend retry or escalation; don't try to fix.
- **Pre-existing failures in main** → identify, mention, do not block on them.

When flagging a flaky failure, include: test file path, owning team (from CODEOWNERS), and whether it was failing before this PR.

---

## Phase 12: Merge readiness

Before recommending merge, confirm:

1. All blocking comments resolved.
2. All required reviewers approved.
3. All CI checks green (or known-flaky failures explicitly flagged).
4. Title and description still accurately describe the final state.
5. Linked ticket title still accurate.
6. No `(blocking)` comments unresolved.
7. No scope creep that hasn't been discussed with reviewers.

If anything is off, surface to the user before they merge.

---

## Phase 13: Post-mortem upgrade loop

After PR is merged (or after a review cycle that surfaced significant comments), spend 10 minutes upgrading this skill. The skill should compound: every PR makes the next one cheaper.

**By path:**
- **Fast Path:** skip — unless something surprised you (a Fast Path PR drawing significant review comments is itself a signal Phase 1 misrouted; that's worth a post-mortem).
- **Standard Path:** run if any substantive comments came up.
- **Full Path:** mandatory.

**Process:**

1. **For each comment that surprised you**, ask: *"What in this skill made me miss this?"* Identify the gap — a missing rule, a missing anti-pattern, a missing reviewer concern, a phase that should have caught it.
2. **For each reviewer who left substantive comments**, propose updates to `references/reviewer-profiles.md`. Add specific concerns they raised.
3. **For each anti-pattern that appeared in your diff**, propose adding it to Phase 7's anti-pattern list if not already there.
4. **For each "I should have known to read X" moment**, propose noting X for Phase 4's pre-flight in this area.
5. **Show the user the proposed diff and the commit message that will be used. Get explicit confirmation.** On approval:
   - Apply the edit to `SKILL.md` and/or `references/*.md`
   - `git add` the changed files
   - `git commit` with a message describing what was learned and why the change was made (format: *"Phase 13: <one-line summary>"* with a body explaining the trigger)
   - `git push` to the remote so the next session picks it up

   Don't apply, commit, or push without explicit confirmation — the AI never edits or publishes the skill silently. The user's single approval covers all three actions (edit, commit, push) since they're conceptually one action: "make this skill update durable."

   If `git push` fails (auth expired, conflict, offline), surface the error to the user. Don't auto-resolve.

**Default output format:** see `references/output-format-catalog.md`. For PRs with >3 substantive review comments, render as `./.pm-postmortem-<pr-number>.html` using the timeline pattern: each comment in chronological order, annotated with the phase that should have caught it, why it didn't, and the proposed skill change. Include the proposed diff at the bottom so the upgrade is one paste away. Short post-mortems (1–3 comments) can stay as a markdown list.

---

## References

Detailed reference material lives under `references/`. Read on demand:

- **`references/reviewer-profiles.md`** — what specific reviewers care about. Used by Phase 8 Pass 3. Grows via Phase 13.
- **`references/prompt-techniques.md`** — toolkit for prompting AIs (role assignment, few-shot, XML tags, grounding anchors, chain-of-thought). Used by Phase 2 and Phase 8 Pass 4.
- **`references/output-format-catalog.md`** — when to use HTML vs markdown vs XML; pattern library; file naming convention. Consulted by every phase that produces output.
