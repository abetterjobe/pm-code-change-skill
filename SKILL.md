---
name: pm-code-change
description: Workflow for non-engineers driving code changes in a shared codebase. Routes the task into the Direct, Guided, or Partnered track based on complexity and blast radius. Use when starting a coding task, asking "should I build this or loop in an engineer?", preparing to open a PR, or responding to PR review comments.
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

- "set up the branch" → Phase 0
- "do the routing" → Phase 1
- "sharpen the prompt" → Phase 2
- "do the intake" → Phase 3
- "do the pre-flight" → Phase 4
- "score complexity" → Phase 5
- "make the plan" → Phase 6
- "review before PR" → Phase 8 (passes per track)
- "just persona review" → Phase 8, Pass 3 only
- "fresh eyes" → Phase 8, Pass 4 only
- "respond to comments" → Phase 10
- "post-mortem" → Phase 13
- "reconcile the ticket" → Phase 14

Two interrupts, callable from anywhere and outside the phase order:

- "capture an issue" / "file a follow-up" → file a ticket for something spotted mid-task
- "learning opportunity" / "explain this to me" → pause and teach, instead of escalating

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

Run this once per session, before Phase 0.

---

## Standards: The Book is the source of truth

Betterment's engineering standards live in **The Book** (`the-book` CLI, or https://the-book.betterment.io). This skill does **not** restate them. Where a standard exists in The Book, cite it and follow it — don't maintain a second copy here that can drift.

The Book auto-loads into Claude Code sessions when set up (`the-book ai setup`): path-scoped indexes land in `~/.claude/rules/the-book/` and full rule bodies in `~/.claude/references/the-book/`, refreshed each session. Rules arrive based on the file types being touched, so Ruby work pulls Ruby standards, frontend work pulls JavaScript and frontend-testing standards.

Query it directly when you need something the auto-load didn't surface:

```bash
the-book topics            # what rule groups exist, and their file patterns
the-book rules <id>        # a specific rule body
the-book search "<term>"   # search across all sections
```

**What this means for this skill:** this skill owns *process* — how a non-engineer moves a change from idea to merge without wasting reviewer time. The Book owns *standards* — what good code looks like here. When the two touch, The Book wins and this skill points at it.

If The Book has no guidance on something, say so rather than inventing a standard.

---

## Phase 0: Workspace and branch setup

Run this before anything else, including routing. It is cheap, it is mechanical, and skipping it produces the most expensive class of mistake this skill has seen — not bad code, but *good code in the wrong place*, mixed with someone else's work, or committed alongside files nobody meant to touch.

### New task means new branch

Starting something new means branching off `origin/main` immediately. No questions, no "let me first see what's here." Never build on `main`, and never build on a branch left over from a different task.

```bash
git fetch origin && git checkout -b <descriptive-branch-name> origin/main
```

### Verify the branch before every consequential action

Before any test run, commit, push, or PR, confirm where you actually are:

```bash
git branch --show-current
```

Do not assume an earlier checkout is still in effect. Sessions get long, other work interleaves, and hooks or scripts can move you. Check, don't remember.

### One task per branch

Never mix two independent tasks on one branch or in one PR. If a second task comes up mid-flow, that's a separate branch off `origin/main`. When switching between tasks, state the switch explicitly and show the branch you landed on as proof.

### Worktree isolation is absolute

If the session is running in a git worktree, touch **nothing** outside that worktree. Not `main`, not the shared checkout, not another task's directory. Do not leave the worktree to escape friction — friction inside the worktree gets solved inside the worktree.

Note that some repo-level conveniences are unsafe inside a worktree — a database reset that assumes the shared checkout is one of them. Check before running repo scripts that touch shared state.

### Know what's already dirty

Before starting, see what's already modified so you can tell your changes from pre-existing ones later:

```bash
git status --short
```

Untracked or modified files that predate your work are not yours to commit. Note them now so Phase 8 can tell them apart.

---

## Phase 1: Track routing

Run this after Phase 0. Its job is to prevent the full workflow's overhead in the cheap case. The full workflow exists for changes where skipping a phase costs days; for a copy change, running it costs hours and clutters the repo.

There are three tracks, and they differ in *shape*, not just in how many steps get skipped:

| Track | For | Who drives |
|---|---|---|
| **1 — Direct** | Presentational and configuration changes: copy, labels, styling, animation, config values, analytics events on existing screens | PM alone, start to finish |
| **2 — Guided** | Real behavior changes inside one repo, in an area with existing precedent | PM drives, AI advises, engineer reviews |
| **3 — Partnered** | Contract changes, multi-system work, or genuine placement ambiguity | Engineer scopes the design *before* code |

The distinction that matters most is Track 3: its defining feature is not more review passes, it's that **the PM shouldn't be scoping it solo**. If a task lands in Track 3, the first action is a conversation, not a keystroke.

### The 3 questions

Deliberately user-answerable. The AI handles the technical questions (file count, API contract impact, placement ambiguity, cross-system coordination) in Phase 4 and Phase 5 after routing, and escalates if anything comes back high.

1. Can you describe what changes in one sentence?
2. Is it easily reversible by re-editing the same lines?
3. Is it presentational or configuration only — copy, labels, styling, animation, config values, or an analytics event on an existing screen — with no new business logic?

**Scoring:**

- **3/3 yes → Track 1 (Direct)**
- **1–2 yes → Track 2 (Guided)**
- **0 yes → Track 3 (Partnered)**

When borderline, **lean lighter**. Escalation mid-flow is cheap; downgrading is awkward — and Phase 5 will catch a misroute almost immediately.

### Hard overrides — these force Track 3

Regardless of how the three questions scored, any of the following puts the task in Track 3:

- A database migration
- A change to a GraphQL schema, a REST endpoint, or an event payload
- A new field or method that other apps, services, or Mobile consume
- More than one repository
- Authentication, authorization, or permissions
- Anything that moves customer money, or changes a displayed balance, projection, or performance figure

The last one deserves care in this codebase. Changing the *label* above a dollar figure is Track 1. Changing the *figure* is Track 3, however small the diff looks.

### Track → phase map

Track 1 is written out in full below and does not reference phase numbers — that's deliberate, so the light path reads as its own short workflow rather than a list of exemptions.

| Phase | Track 2 — Guided | Track 3 — Partnered |
|---|---|---|
| 0 Workspace + branch | run | run |
| 1 Routing | run | run |
| 2 Sharpen prompt | optional | run |
| 3 Intake | run | run |
| 4 Pre-flight | run | run + module map |
| 5 Complexity confirm | confirm | run |
| 6 Planning | run | run + engineer alignment before code |
| 7 Build | execution rules apply | execution rules apply |
| 8 Pre-PR review | Passes 1, 2, 3, 5; HTML if >3 findings | all 5 passes + UI pass, HTML |
| 9 Open PR | standard description | full description + HTML tour |
| 10–12 Reviews / CI / merge | run | run |
| 13 Post-mortem | run if substantive comments | run |
| 14 Ticket reconciliation | run | run |

### Track 1 — Direct: the whole workflow

Six steps. Nothing else runs — no complexity scoring, no reviewer personas, no fresh-eyes pass, no post-mortem, no HTML artifacts.

1. **Restate the ask in one line, and name the files.** One search for the string or component being changed. If a precedent exists for how this kind of change is done nearby, follow it. If the search turns up something unexpected — the string lives in five places, or the component is shared more widely than expected — stop and escalate to Track 2.
2. **Confirm you're on a fresh branch off `origin/main`** (Phase 0).
3. **Make the change.** The execution rules in Phase 7 still apply. A small change doesn't get to violate a standard.
4. **Verify.** Run the targeted checks for the files touched, and see the change working locally (Phase 9's local verification applies to every track, including this one).
5. **Check the commit's file list before pushing** — see Phase 8, Pass 1. This is where Track 1 changes most often go wrong: the diff is two lines, and three unrelated files ride along with it.
6. **Open the PR** with a one-line description, after explicit user confirmation (Phase 9's creation protocol).
7. **Reconcile the ticket** (Phase 14). This runs on every track — a two-line copy change still needs its ticket assigned, in the right state, in the sprint, and linked to the PR.

If a Track 1 change draws substantive review comments, that's a signal Phase 1 misrouted — worth a post-mortem even though Track 1 normally skips it.

### Escalation triggers

Move up a track mid-flow if any fire:

- File count exceeds 3 (Track 1 → 2)
- A reviewer disagrees with the approach (Track 2 → 3)
- Scope creep emerges (any track → next up)
- An in-flight signal from Phase 7 triggers (any track → next up)
- A pre-flight finding reveals an unfamiliar area, a design-review requirement, or a placement ambiguity (Track 1 → 2, Track 2 → 3)
- Any hard override surfaces that wasn't visible at routing time (any track → 3)

State the escalation explicitly: *"I'm escalating from Track 1 to Track 2 because [trigger]."* Then resume from the appropriate phase.

---

## Phase 2: Sharpen the prompt

Before Phase 3, sharpen the ask itself. The cost of a fuzzy initial ask compounds through every later phase.

**When to run this phase:**
- The initial ask is more than one sentence and isn't already a structured ticket.
- Phase 1 routed this to Track 2 or Track 3.
- The user is starting a new feature, not a follow-up to an existing one.
- The user explicitly says "sharpen the prompt."

**When to skip:**
- The ask is a one-liner with obvious scope.
- The user is mid-task continuing prior work.
- Track 1.

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

For Track 2 / Track 3 tasks, save the Brief to `./.pm-brief.html` so the user can review it before Phase 3 starts.

---

## Phase 3: Task intake

Establish what's actually being asked.

**If Phase 2 ran:** the Brief already covers ambiguity. Phase 3 confirms the Brief and produces a one-sentence statement of intent. Skip clarifying questions unless something in the Brief is still unclear.

**If Phase 2 was skipped:** do the full intake from scratch.

1. **Restate the ask in one sentence.** If you can't, ask the user to clarify before proceeding.
2. **Ask any questions you have** (skip if Phase 2 already covered them). Don't assume. If anything is ambiguous — the desired behavior, affected users, which entity/account/account-type, what "done" looks like, whether existing similar features should be matched — surface it now. **Assume no requirement or scope beyond what was explicitly described.** Inferred scope is the most common source of a diff the user didn't ask for.
3. **Identify the user-facing outcome.** What changes for the end user when this ships?
4. **Find the smallest possible change that achieves it.** Default to the minimal viable change. Larger scope = more risk.
5. **Locate the ticket (if any).** Read it fully. Acceptance criteria often reveal scope-creep risk.
6. **State your one-sentence understanding back to the user, with any open questions.** Confirm before proceeding.

---

## Phase 4: Pre-flight

Before writing code, investigate the area.

**By track:**
- **Track 1:** one search for the changed string/component and a quick check for adjacent precedent. If anything unexpected turns up, escalate.
- **Track 2 / 3:** run all 4 steps below.

1. **Search the codebase for similar features.** Existing patterns set precedent. If a similar feature exists, it almost certainly defines the convention to follow. **For UI/UX changes, check adjacent pages in the same flow first** — they're the highest-probability source of an applicable pattern. If you find one, state it explicitly: *"X pattern exists at [file]; I'll use that instead of writing new CSS/components."*
2. **Read process docs in the area.** README, CONTRIBUTING, AGENTS.md, ADR/SDR/RFC directories, runbooks. Discovering process requirements mid-PR causes rework. The Book's path-scoped rules load automatically, but repo- and directory-specific docs do not — read those yourself.
3. **Identify the conceptual owner of the change.** Ask "who owns this data/behavior?" before "where is it easiest to add this?" The conceptually correct location is usually not the most convenient. The Book's guidance on domain ownership is the reference here — see `the-book ways application-design`.
4. **Identify likely reviewers and codeowners.** Check `CODEOWNERS` files or recent commit authors. Knowing who reviews helps frame the change — and seeds Phase 8 Pass 3.

**Does this need a design review?** The Book requires a design review when introducing a new pattern, a novel application of an existing pattern, or a new way of interacting with another app — and a lightweight ADR when a pattern changes (`the-book ways writing-software`). If pre-flight suggests any of those, surface it now. Discovering a design-review requirement after the code is written is one of the most expensive misses available.

If any of these turn up something unexpected (existing precedent, a design-review requirement, an unclear owner), pause and flag it.

---

## Phase 5: Complexity assessment

**By track:**
- **Track 1:** skip. The three routing questions plus the hard-override list already did this job. If the change felt like it needed scoring, it wasn't Track 1.
- **Track 2:** full scoring; confirm Phase 1's classification and refine.
- **Track 3:** full scoring with detailed reasoning per axis.

Score the task on four axes. Each axis is graded **low** or **high** complexity.

**Axis 1 — Change type**
- low: copy, labels, styling, animation, flag toggles, analytics events on existing screens
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

Count the number of axes scored high. That total maps to a track — a framework for deciding whether the PM can proceed solo, should read docs first, or should align with an engineer before any code is written.

- **0 highs → Track 1 or 2.** PM can drive. Proceed.
- **1 high → Track 2.** PM can drive, but read the relevant area docs before starting.
- **2+ highs → Track 3.** Pause before writing code. Either loop in an engineer to scope the design, or at minimum spend time defining the solution more rigorously with an engineer's input. State this to the user: *"This looks like Track 3 because [specific axes that scored high]. Want to pull in an engineer first, or proceed?"*

If this scoring contradicts Phase 1's initial routing, the more cautious track wins — and state the escalation explicitly.

### High-complexity disguises (tasks that look low but aren't)

- "Just add a field to…" — adding a field to a public API is a contract change.
- "Just show this data on the screen" — if the data isn't on the client, it's an API change.
- "It should already be there, just expose it" — if it's not exposed, find out why first.
- "It's the same as [other feature]" — similar features often diverge in subtle ways.
- "Just change the number" — a displayed figure is a contract with the customer, not a label.

---

## Phase 6: Planning + decision point

Before building, write down the approach.

**Track 2 and Track 3 write the plan to a file, not just to chat.** A plan that lives only in conversation dies with the session — and long tasks outlive their sessions. Save it to `./.pm-plan.md` with per-step status and an overall progress figure at the top:

```markdown
# <Feature> implementation plan

**Overall progress:** `0%`

## TL;DR
What we're building and why, in two sentences.

## Decisions made
- <choice> — <why>

## Tasks
- [ ] 🟥 **Step 1: <name>**
  - [ ] 🟥 <subtask>
- [ ] 🟥 **Step 2: <name>**
```

Status markers: 🟥 to do, 🟨 in progress, 🟩 done. Phase 7 updates the file as each step lands — the file is the source of truth for where the work stands, not the chat history.

Two things this buys. **Recovery:** when context gets long or a session ends, the next session starts from the plan file alone and doesn't need the transcript. **Scope control:** a written step list makes added scope visible, because new work has to be added to the file to be tracked.

Keep the plan minimal. No steps that weren't discussed, no speculative structure, no complexity beyond what was clarified. Track 1 skips this entirely — a six-step change doesn't need a tracking document.

1. **State the approach in 2–3 bullets.** What you'll change, where, and why.
2. **List unknowns and produce questions for any that need engineer input.** Unknowns fall into two buckets:
   - Things the AI can investigate by reading code or docs — investigate first.
   - Things that require human judgment (design choices, conventions, process) — draft a concrete question for the user to take to an engineer.

   For each engineer-bound question:
   - Specific enough to answer in 1–2 sentences
   - Phrased so the user can read it aloud or copy/paste
   - Focused on what you need to know to proceed confidently

   Categories to draw from: **placement, contract shape, process (design review / ADR), coordination, conventions, risk.**

3. **Decide based on the track:**
   - **Track 2** — the AI reads the relevant area docs itself, then proceeds.
   - **Track 3** — share approach, unknowns, and engineer questions with the user. **Alignment with an engineer happens before code, not after.** If engineer questions exist, state explicitly: *"Once you have answers, share them and I can resume."*

---

## Phase 7: Building

**By track:** the same rules apply across all tracks — Track 1 doesn't get to skip the execution rules just because the change is small. Anti-patterns are still anti-patterns at any size.

Apply these rules continuously, not just at the start.

**Track 2 / Track 3: update `./.pm-plan.md` as each step lands** — flip the status marker and refresh the progress figure. Do it as you go, not in a batch at the end; the file's value is that it's accurate at any moment the session might be interrupted.

### Execution rules

Betterment's code standards come from The Book and load automatically by file type — follow them. The rules below are the ones this skill adds on top, because they address failure modes specific to AI-assisted work by a non-engineer.

1. **Place things where they belong.** Identify the conceptual owner before the convenient call site. The Book's domain-ownership guidance is the reference (`the-book ways application-design`); the failure mode this rule guards against is reaching for whatever type is already in context.
2. **Read the docs before writing code.** Even when the task seems obvious. The Book auto-loads standards, but repo READMEs, ADRs, runbooks, and contributing guides do not — and process requirements discovered mid-PR cause rework.
3. **Don't quietly expand scope after the user has confirmed a next step.** When the user says testing is done and asks for a PR, open the PR. Don't detour into unrequested tests, refactors, or polish first. If you believe something else is needed, say so in a sentence and let them decide.

For code-shape standards — logic belonging in domain models rather than controllers or schema definitions, and not building speculative protective machinery — The Book states both, with reasoning:

- *"We build skinny controllers and rich domain models"* — `the-book ways writing-software`
- *"We practice malleable design rather than future-proofing"*, because every joint that doesn't prove necessary *"leaves scar tissue"* — same source

Cite those rather than restating them. They apply to nil guards, backward-compat shims, migration helpers, and speculative flags: if the scenario being protected against can't be confirmed against current production state, don't write the code.

### In-flight signals to flag

When any of these appear, surface them immediately:

- Reviewers disagree on the same design point.
- A reviewer references a pattern in code you haven't read.
- Scope grew since starting (file count up, new types/interfaces appearing). Surface explicitly: *"This started as X files; it's now Y. The growth comes from [reason]. Is this necessary, or scope creep we should split?"*
- User is editing process docs (ADR/SDR/RFC) they don't fully understand.
- User would have to defend a choice in a comment they couldn't defend without quoting you.
- A change you thought was internal turns out to affect a public API contract.
- Iteration count on the same design decision is exceeding 3–5 attempts. Stop, restate the actual user need, and search again for existing patterns before continuing. Sustained iteration without convergence is a sign the wrong approach is being refined.
- The diff is approaching ~250 lines. That's already chunky by Betterment standards — see Phase 9 on splitting.

### Anti-patterns to avoid

Specific failure modes from prior work. Catch these proactively:

- Signing PR responses as AI ("this is Claude") — engineers see an automated agent making design decisions.
- Adding backward-compat shims without first verifying with `git show origin/main:<file> | grep <symbol>` that the thing being made compatible-with actually exists.
- Inlining resolver / business logic in schema type definitions.
- Placing fields on the most reachable type rather than the conceptually correct one.
- Mixing "empty list" and "null" semantics — pick one and be consistent.
- Adding `if <invariant>` checks where the invariant is guaranteed by upstream filtering.
- Deferring decisions to follow-up PRs when the fix is in scope and small.
- Pulling adjacent unrelated issues into the current PR ("while I'm here"). File a follow-up ticket. The PR's job is the original ask, not surrounding cleanup.

---

## Phase 8: Pre-PR review (multi-pass)

This is the highest-leverage phase. Most engineer-time-wasted on past PRs has been predictable comments that a robust self-review would have caught. The goal here is to surface those comments before a human sees them.

**By track:**
- **Track 1:** Pass 1 only. Markdown output, in-chat. Skip everything else.
- **Track 2:** Passes 1, 2, 3 (1–2 personas), and 5. Skip Pass 4 unless the change is substantial (≥5 files, new public API surface, or new business-logic class). HTML output only if >3 findings.
- **Track 3:** All 5 passes + UI pass (if any UI changed). HTML output mandatory.

Run the included passes in order. Don't skip to Phase 9 until the track's final pass is complete.

### Pass 1 — Mechanical checklist

The minimum gate, and the only gate on Track 1. Everything here is checkable without judgment, which is exactly why it gets skipped and exactly why it bites.

1. Tests written and passing for new behavior.
2. Schema/generated files regenerated (not hand-edited).
3. No commented-out code, no debug prints, no TODO markers added in this diff.
4. Diff is minimal — anything not serving the original task is cut.
5. Did scope expand beyond the original ask? If yes, surface to the user — ask whether to split before continuing.
6. **Run the formatter, not just the linter.** CI lint jobs commonly run both, and a formatter-only failure turns CI red after a clean-looking local run. Check what the repo's lint job actually invokes and run all of it. Where the repo provides a combined pre-flight script for changed files, prefer it.
7. **Read the commit's file list before pushing.** Not the diff — the file list:

   ```bash
   git show --stat --oneline HEAD
   ```

   Every file in it must be one you meant to touch. This is the single most repeated mechanical failure in this skill's history: generated or reset artifacts — a dumped database structure file being the classic — sit staged in the working tree and get swept into an unrelated commit, breaking CI far beyond the PR's own scope. Cross-reference against the pre-existing dirty files noted in Phase 0. If something you didn't author is in the list, unstage it before pushing.

### Pass 2 — Adversarial self-review against the rules

Walk the diff line-by-line against Phase 7's execution rules and anti-patterns, and against the Book rules that loaded for the file types you touched. For each, ask "did I violate this?" — out loud, with a yes/no. Not "did I try to follow this?" — *did the resulting code follow it?*

- Is anything inlined that should live in a domain model? (Book: skinny controllers, rich domain models)
- Did I add protective code for a risk I never confirmed? (Book: malleable design over future-proofing)
- Is anything placed on the most reachable type instead of the conceptual owner? (Rule 1)
- Are there `if <invariant>` checks where the invariant is guaranteed upstream? (Anti-pattern)
- Did I mix "empty list" and "null" semantics? (Anti-pattern)
- Did I defer small in-scope fixes to follow-ups when they belonged here? (Anti-pattern)
- Did I add code comments? (Book: we don't write them outside public library APIs and genuinely gnarly code)

Report each as ✅ clean / ⚠️ borderline / ❌ violation. Fix every ❌ before Pass 3.

Where an internal tool already reviews a diff against The Book, prefer it over hand-rolling this check — it reads from the live rule set and won't drift.

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

**Verify each finding; don't accept them on authority.** The fresh-eyes reviewer has *less* context than you — it hasn't read the ticket, the prior discussion, or the surrounding conventions. Some of its findings will describe problems that are already handled elsewhere, or that misread the architecture. For each one, check the actual code and classify it: confirmed, or invalid with a stated reason. Carry both lists into Pass 5 — the invalid ones are worth keeping, because the same misreading often resurfaces in human review and you'll already have the answer.

### Pass 5 — Synthesize and decide

Collect findings from passes 1–4 into one list. For each finding, classify it:

- **Fix now** — issue is real and in scope. Address before opening PR.
- **Document as a known trade-off** — issue is real but out of scope. Add to PR description so reviewers see it was considered.
- **Reject with reasoning** — issue is wrong. Note why in case the same comment surfaces in human review.

**Default output format:** see `references/output-format-catalog.md`. For most PRs with >3 findings, render as `./.pm-review-<short-sha>.html` using the annotated-diff pattern: columns for source pass, file:line (linked), severity, classification, reasoning. The "documented trade-offs" rows copy cleanly into the PR description. Short reviews (≤3 minor findings) can stay as a markdown list.

Only proceed to Phase 9 when every Pass 1 item is ✅. For Track 2 / Track 3, every Pass 2 ❌ must also be fixed.

---

## Phase 9: Opening the PR

### Prerequisite: local verification

**Applies to every track, including Track 1.** Before assembling the PR draft, confirm the user has seen the change working in their local environment. The AI must not propose opening a PR until the user has confirmed local verification.

This gate is only useful if the AI can actually help the user clear it. Know the repo's local startup path cold — the PM is often running the environment only in these sessions, so vague instructions strand them.

General shape, adapted to whatever the repo actually uses:

1. **Reset the local database before running.** Never assume the local DB matches the branch's schema. *(Not safe inside a worktree — see Phase 0.)*
2. **Start the environment from the directory the tooling expects**, not the repo root, if the repo's dev tooling is per-application.
3. **Know the interactive-tool gotchas** — which processes take over the terminal, how to actually stop them, and what a healthy startup looks like versus a hung one.
4. **When the environment is in an unexpected state, give clean stop-and-start instructions.** Never suggest skipping past it or working around it. A confusing half-running environment produces false verification, which is worse than none.

Note that reset-style scripts frequently leave generated artifacts staged — Phase 8 Pass 1 item 7 exists because of exactly this interaction.

If local verification is blocked by environment issues, the user makes the call — but the default is: **no local verification, no PR.**

### Size check: prefer several small PRs

Before opening, ask whether this should be more than one PR. Split by behavior increment — each PR should be a coherent, reviewable step.

- Prefer independent PRs. Stack them only when genuinely interdependent.
- ~250 lines is already chunky by Betterment standards. Treat that as a prompt to reconsider, not a hard limit.
- A large PR from a non-engineer author costs reviewers disproportionately more, because they can't assume the author caught the mechanical issues.

If splitting makes sense, propose the split before opening anything.

### Creation protocol

The AI **creates the PR**, but only after explicit user confirmation. This is distinct from Phase 10's prohibition on posting comments — Phase 9 is a single bounded action with sign-off; Phase 10 is ongoing engagement with reviewers.

Workflow:

1. AI assembles the draft per the checklist below (title, description, reviewers, tour file if Track 3).
2. AI shows the full draft to the user — title, description (rendered), reviewer list, and the exact `gh pr create` invocation it intends to run.
3. User reviews, edits whatever needs editing, and confirms by saying "open it" or equivalent.
4. AI runs `gh pr create` with the confirmed content.
5. AI reports the PR URL back to the user.

If the user doesn't confirm — or edits the draft — loop back to step 2 before running `gh pr create`. The AI never opens a PR without explicit user confirmation.

### By track

- **Track 1:** title + one-line description. Skip the tour, skip the trade-offs list (nothing was traded off).
- **Track 2:** full description with what/why/how-to-test. PR tour optional.
- **Track 3:** full description + HTML PR tour saved to `./.pm-pr-tour-<pr-number>.html`. Link the tour from the PR description.

### Draft checklist

Betterment's PR authoring standards live in The Book (`the-book rules github/prs`, and the authoring/reviewing standards referenced from `the-book ways writing-software`) — follow those for title conventions, description content, and reviewability. Follow the repository's own PR template where one exists. The items below are the ones this workflow adds:

1. **Title and description reflect the final change** — not the original intent if the work evolved. **If the diff changed after the initial draft (force-push, amend, file removal), re-check the description against the current diff and update any stale references.**
2. **Put the ticket key in the branch name and the PR title, and link the ticket in the description.** That's what drives the tracker's automatic linking. Phase 14 verifies the linkage properly — don't hand-check it here.
3. **Add reviewers** based on CODEOWNERS or area expertise.
4. **Include the Pass 5 "documented trade-offs" list** so reviewers see what was considered and consciously deferred.

If title/description drifts from reality during review, update them. Don't let them lie.

---

## Phase 10: Responding to reviews

### Posting protocol — the AI never posts

**The AI never posts comments to GitHub unprompted.** The AI drafts; the user reviews, edits, and either posts themselves or directs the AI to post. No `gh pr comment`, no `gh api .../comments`, no batch auto-replies driven by the AI's own judgment. The user is always the author of the content.

**Consent, not prohibition.** When the user explicitly directs you to post a draft they've reviewed, execute the post — the rule is no posting without explicit consent, not no posting ever. Do not quote this section back to refuse a clear request.

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
- **Keep drafts high-level.** The user fields the follow-up questions, so a draft that commits to technical detail they can't defend creates a trap. Pitch at the altitude they can speak to.
- If the user can't defend the draft in their own words, that's the signal to recommend involving an engineer — not to rewrite the draft.
- When two reviewers disagree, don't pick a side. Draft a message that surfaces the conflict to both and asks them to align. Tag them by name. User posts.
- For each comment, take an action: fix in code, draft an acknowledgment, draft a push-back with reasoning, or escalate to an engineer. Don't leave comments hanging — but the user always posts.

---

## Phase 11: CI failures

Default action: investigate before retrying. A retry that "works" doesn't mean the failure was flaky.

- **Tests failing consistently and touching your changes** → investigate. Likely a regression you caused.
- **Linter or formatter errors on your files** → fix. If the formatter is what failed, Phase 8 Pass 1 item 6 was skipped.
- **Failures in files you didn't mean to touch** → check the commit's file list (Pass 1 item 7). An unintended file riding along is a more common cause than a real regression.
- **Schema drift / generated-file diffs** → regenerate via the codebase's documented command. Don't hand-edit.
- **Flaky tests on a path unrelated to your changes** → flag to the user. Identify the owner. Recommend retry or escalation; don't try to fix.
- **Pre-existing failures in main** → identify, mention, do not block on them.

When flagging a flaky failure, include: test file path, owning team (from CODEOWNERS), and whether it was failing before this PR.

The Book's position is that we don't merge with failing suites (`the-book ways testing-software`) — a red build is not a thing to route around.

---

## Phase 12: Merge readiness

Before recommending merge, confirm:

1. All blocking comments resolved.
2. All required reviewers approved.
3. All CI checks green (or known-flaky failures explicitly flagged).
4. Title and description still accurately describe the final state.
5. Linked ticket title still accurate, and the ticket ↔ PR links still resolve both ways.
6. No `(blocking)` comments unresolved.
7. No scope creep that hasn't been discussed with reviewers.
8. The branch still contains only this task's work.

If anything is off, surface to the user before they merge.

---

## Phase 13: Post-mortem upgrade loop

After PR is merged (or after a review cycle that surfaced significant comments), spend 10 minutes upgrading this skill. The skill should compound: every PR makes the next one cheaper.

**By track:**
- **Track 1:** skip — unless something surprised you. A Track 1 PR drawing significant review comments is itself a signal Phase 1 misrouted, and that's worth a post-mortem.
- **Track 2:** run if any substantive comments came up.
- **Track 3:** mandatory.

**Process:**

1. **For each comment that surprised you**, ask: *"What in this skill made me miss this?"* Identify the gap — a missing rule, a missing anti-pattern, a missing reviewer concern, a phase that should have caught it.
2. **Check whether The Book already covers it.** If it does, the fix is a citation, not a new rule — and if this skill was restating something The Book now says better, delete the restatement. This skill should shrink whenever The Book grows.
3. **For each reviewer who left substantive comments**, propose updates to `references/reviewer-profiles.md`. Add specific concerns they raised.
4. **For each anti-pattern that appeared in your diff**, propose adding it to Phase 7's anti-pattern list if not already there.
5. **For each "I should have known to read X" moment**, propose noting X for Phase 4's pre-flight in this area.
6. **If the track was wrong**, propose a routing fix — a new hard override, or a change to the three questions. Misroutes are the most valuable post-mortem finding, because they compound across every future task.
7. **Show the user the proposed diff and the commit message that will be used. Get explicit confirmation.** On approval:
   - Apply the edit to `SKILL.md` and/or `references/*.md`
   - `git add` the changed files
   - `git commit` with a message describing what was learned and why the change was made (format: *"Phase 13: <one-line summary>"* with a body explaining the trigger)
   - `git push` to the remote so the next session picks it up

   Don't apply, commit, or push without explicit confirmation — the AI never edits or publishes the skill silently. The user's single approval covers all three actions (edit, commit, push) since they're conceptually one action: "make this skill update durable."

   If `git push` fails (auth expired, conflict, offline), surface the error to the user. Don't auto-resolve.

**Default output format:** see `references/output-format-catalog.md`. For PRs with >3 substantive review comments, render as `./.pm-postmortem-<pr-number>.html` using the timeline pattern: each comment in chronological order, annotated with the phase that should have caught it, why it didn't, and the proposed skill change. Include the proposed diff at the bottom so the upgrade is one paste away. Short post-mortems (1–3 comments) can stay as a markdown list.

---

## Phase 14: Ticket reconciliation

The last step on every track, including Track 1. Its job is to leave the ticket in a state that accurately reflects reality: described correctly, owned by the user, in an active state, in the current sprint, and connected to the PR.

Run it after the PR is open. It's idempotent — safe to re-run any time the work or the ticket moves.

### Step 1 — Find the ticket

Look in this order:

1. A ticket the user named explicitly in the conversation.
2. A ticket key in the current branch name — keys look like `[A-Z][A-Z0-9]+-\d+` (e.g. a branch `ix-2174-custom-portfolio-label` implies `IX-2174`).
3. A ticket key in the PR title or description.

If two sources disagree, stop and ask which is right. Never guess between two candidate tickets.

### Step 2 — If no ticket exists, create one

Creating a ticket is an outward-facing action in a shared tracker, so **draft it, show the user, and create only on explicit confirmation.**

Draft with:

- **Project** — infer from sibling tickets in the same area or from the branch prefix. If it can't be inferred confidently, ask; don't default to a random project.
- **Issue type** — `Bug` when fixing incorrect existing behavior, `Task`/`Story` when adding something. Check the project's available types rather than assuming.
- **Summary** — one line, describing the user-facing outcome, not the implementation.
- **Description** — match the shape the project already uses. Where a bug-report convention exists (an Observed / Expected structure is common), follow it. Include what the user sees, what they should see, and the affected surface.
- **Assignee** — the current user (`atlassianUserInfo` → `account_id`).

Then continue through the checks below as if the ticket had existed.

### Step 3 — Reconcile the four attributes

Check each, collect the drift, and present it as one batch before writing anything.

**a. Description is accurate.** Compare it against what actually shipped. Work often diverges from the original report — a bug turns out to have a different cause, or the fix covers more or less than described. If it drifted, propose replacement text and show what changes. Never overwrite a description silently; the reporter's original account of the problem has value.

**b. Assigned to the user.** Compare `assignee.accountId` against the current user's account id. If someone else is assigned, don't reassign — surface it, because it may be deliberate.

**c. Status is active — In Progress or in review.** Do **not** hardcode status names; they differ per board. Read the real options with `getTransitionsForJiraIssue` and pick by `statusCategory`:

- Target a transition whose destination `statusCategory.key` is `indeterminate` (Jira's "In Progress" category).
- Among those, prefer by name in this order: `In Review` → `Code Review` → `In Progress`. Some boards have no review status at all — the Investing Enablement board, for example, offers only `In Progress` and `On Hold/Blocked` in that category. Never select a blocked/hold status as the target.
- **Never transition a ticket to Done.** Closing a ticket is the team's call, made against their own definition of done, and often driven by board automation. This phase moves tickets *into* flight, never out.

If the ticket is already `Done` while work is still in flight, that's drift worth reporting — but flag it and let the user decide rather than reopening it.

**d. In the current active sprint.** Verify with JQL rather than the Agile API — no board id needed:

```
key = <TICKET> AND sprint in openSprints()
```

A result means it's in an open sprint. An empty result means it isn't. If it isn't, adding it requires writing the board's sprint field, which may be outside the available API scopes — attempt it, and if it fails, say so plainly and hand the user the one-click fix rather than reporting success.

### Step 4 — Verify PR linkage the way a human sees it

**The remote-issue-links API is not a reliable signal here.** It returns an empty list for tickets that demonstrably have linked PRs, because the GitHub integration surfaces them in the ticket's development panel rather than as remote links. An empty result is not evidence of a missing link, and chasing it produces phantom work.

Verify the mechanism that actually drives linking instead:

1. The ticket key appears in the branch name — `git branch --show-current`.
2. The ticket key appears in the PR title — `gh pr view --json title,body`.
3. The PR description links the ticket.

If all three hold, the linkage is in place. If the key is missing from the PR title, fix the title. If it's missing from the branch name on an already-open PR, don't rename the branch — add the key to the title and description instead, and note it for next time.

### Step 5 — Report, confirm, then write

Present the findings as a short table: attribute, current state, desired state, proposed action. Batch every mutation behind a single confirmation so the user approves once, not five times.

On approval, apply the changes and re-read the ticket to confirm each one landed. Report what actually changed — if a write failed (permissions, missing scope, a transition the workflow doesn't allow from the current status), say which one and why. Don't report success for a write you didn't verify.

---

## Interrupts

Two commands that aren't workflow steps. They don't belong to a phase and they don't run in order — you reach for them mid-flow, from anywhere, and then return to whatever you were doing. Both exist because the linear workflow has no good answer for the situation they address.

### Capture an issue — "file this for later"

*Invoke with: "capture an issue" or "file a follow-up."*

Phase 7's anti-patterns forbid pulling adjacent problems into the current PR and say to file a follow-up ticket instead. This is how that ticket gets filed, without derailing the work in progress.

The point is speed. The user is mid-task and wants this out of their head in under two minutes.

1. **Ask at most 2–3 targeted questions in a single message.** What's the issue, current versus desired behavior, and type/priority if not obvious from the description. One round trip, not a back-and-forth. Skip anything already clear.
2. **Search only when it helps.** Grep for the relevant files to attach context — three at most, the most relevant only. Don't research best practices for a straightforward bug.
3. **Draft the ticket** using Phase 14 Step 2's creation rules — project inference, issue type, the project's own description convention, assignee.
4. **Create it on confirmation**, report the key, and return to the interrupted work.

Default to normal priority and medium effort; ask only if genuinely unclear. Bullet points, not paragraphs.

### Learning mode — "explain this to me"

*Invoke with: "learning opportunity", "explain this to me", or "teach me this."*

Pause development entirely. This is not a detour from the work — it's the thing that makes the next task cheaper, and it's the missing half of Phase 10's rule about not defending what you don't understand. When the user hits something they can't follow, the workflow's only current answer is "escalate to an engineer." This is the other option: understand it.

**Audience.** A product manager who ships production code with AI assistance. Solid fundamentals, reads code comfortably, not a senior engineer. Don't oversimplify and don't lecture. Peer-to-peer.

**Structure — three levels, and let each one land before moving on.** Don't dump all three at once; the user says when to go deeper.

1. **Core concept** — what this is, the problem it solves, when you'd reach for it, how it fits the wider system.
2. **How it works** — the mechanics underneath, the trade-offs and why this approach was chosen, the failure modes to watch for, how to debug it when it breaks.
3. **Deep dive** — implementation details that affect production behavior, scaling and performance implications, the alternatives and when they'd win, the senior-engineer read on it.

**Ground every level in the code actually in front of the user.** Generic explanations are available anywhere; the value here is that it's *this* function, *this* schema, *this* PR. Favor concepts that compound over academic completeness, and name genuine difficulty honestly — "this is tricky because…" beats false simplicity.

Learning mode is also the right response when the user is about to accept a reviewer's comment they don't understand. Understanding the comment is a better outcome than applying it on faith.

---

## References

Detailed reference material lives under `references/`. Read on demand:

- **`references/reviewer-profiles.md`** — what specific reviewers care about. Used by Phase 8 Pass 3. Grows via Phase 13.
- **`references/prompt-techniques.md`** — toolkit for prompting AIs (role assignment, few-shot, XML tags, grounding anchors, chain-of-thought). Used by Phase 2 and Phase 8 Pass 4.
- **`references/output-format-catalog.md`** — when to use HTML vs markdown vs XML; pattern library; file naming convention. Consulted by every phase that produces output.

Betterment's engineering standards are **not** duplicated here — they come from The Book (`the-book`, or https://the-book.betterment.io). See "Standards: The Book is the source of truth" above.
