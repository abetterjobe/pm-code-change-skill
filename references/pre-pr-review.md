# Pre-PR review: Passes 2–5 and the edge-case sweep

Detail for Phase 8. Pass 1 (the mechanical checklist) lives in `SKILL.md` because it's the universal gate and Track 1's only one — this file covers the passes that only Track 2 and Track 3 run.

Run the included passes in order. Don't proceed to Phase 9 until the track's final pass is complete.

---

## Pass 2 — Adversarial self-review against the rules

Walk the diff line-by-line against Phase 7's execution rules and anti-patterns, and against the Book rules that loaded for the file types you touched. For each, ask "did I violate this?" — out loud, with a yes/no. Not "did I try to follow this?" — *did the resulting code follow it?*

- Is anything inlined that should live in a domain model? (Book: skinny controllers, rich domain models)
- Did I add protective code for a risk I never confirmed? (Book: malleable design over future-proofing)
- Is anything placed on the most reachable type instead of the conceptual owner? (Rule 1)
- Are there `if <invariant>` checks where the invariant is guaranteed upstream? (Anti-pattern)
- Did I mix "empty list" and "null" semantics? (Anti-pattern)
- Did I defer small in-scope fixes to follow-ups when they belonged here? (Anti-pattern)
- Did I add code comments? (Book: we don't write them outside public library APIs and genuinely gnarly code)
- Is the verification adequate for what changed — not just green, but actually covering the new behavior? A passing suite that never exercises the changed branch is the gap worth naming.
- For everything the change loads: what shows while it loads, when it comes back empty, when it errors, and while it reloads with the old data still on screen?
- For everything the change submits: what happens on a double tap, when the user closes the screen mid-request, and when the screen is gone by the time the response arrives?
- For every value the client checks or calculates: does the server already own that rule or number?
- For every figure on screen: does it add up to the figure it's part of, and does it still read right at zero and at a value too small to show?
- Did I assume data is always present, or always has one shape, without checking the type or where it comes from?

Report each as ✅ clean / ⚠️ borderline / ❌ violation. Fix every ❌ before Pass 3.

Where an internal tool already reviews a diff against The Book, prefer it over hand-rolling this check — it reads from the live rule set and won't drift. The `bookworm` plugin in Betterment's plugin marketplace does exactly this, citing rule IDs.

**Size is not risk.** A large diff is not automatically dangerous and a small one is not automatically safe — a bulk deletion behind a dead feature flag can be routine, while a two-line change to an authorization check is not. Phase 7's ~250-line signal is about *reviewer burden*, not danger; don't read it as a risk score. Judge risk by what the change touches, using Phase 1's hard-override list as the guide.

---

## Pass 3 — Reviewer persona simulation

For each likely reviewer (from `CODEOWNERS`, recent commit authors in the touched files, or `references/reviewer-profiles.md`), take on their known concerns and review the diff *as them*. Be specific — quote what they'd say.

Output format per reviewer:

> **As [Name]:** "[Specific comment they'd make, in their voice]. [What they'd want changed.]"

If a persona has nothing to say, state that explicitly — don't skip silently.

If a reviewer's profile isn't documented yet, infer from their last 5–10 comments on this area of the codebase. Useful commands:

- `gh api repos/<org>/<repo>/pulls/comments --paginate -q '.[] | select(.user.login=="<handle>") | .body' | head -50`
- `gh search prs --owner <org> --reviewed-by <handle> --limit 10`

After running Pass 3, surface any new findings about a reviewer's recurring concerns — Phase 13 will propose adding them to `references/reviewer-profiles.md`.

---

## Pass 4 — Fresh-eyes second opinion

Invoke an independent reviewer with no context from this session. Two options:

- Run the `code-review` skill at high effort. **Never pass `--comment`** — that posts findings directly to the PR, which violates Phase 10's posting protocol. Findings go to Pass 5 synthesis only.
- Spawn a general-purpose sub-agent with the diff, the original task description, and the draft PR title and body, prompted: *"Review this diff and its PR title and description. You have no context on prior discussion. For each finding, open with a Conventional Comments label and a blocking decoration — `issue (blocking): …`, `suggestion (non-blocking): …` — anchor it at file:line, state what it costs if left, and mark anything you couldn't verify UNVERIFIED. Blocking means the change shouldn't merge as it stands; it's a claim about the merge, not about how confident you are. Also check that the description explains why, matches the diff, and contains no file-by-file walkthrough or 'tests pass'."*

The value of fresh-eyes review is bias removal — the original-context reviewer (mid-task) has invested in the current approach; the fresh-eyes reviewer hasn't.

**Verify each finding; don't accept them on authority.** The fresh-eyes reviewer has *less* context than you — it hasn't read the ticket, the prior discussion, or the surrounding conventions. Some of its findings will describe problems that are already handled elsewhere, or that misread the architecture. For each one, check the actual code and classify it: confirmed, or invalid with a stated reason. Carry both lists into Pass 5 — the invalid ones are worth keeping, because the same misreading often resurfaces in human review and you'll already have the answer.

---

## Edge-case sweep — Track 2 and Track 3

Pass 2 asks the edge-case questions, but the session that built the change is the one answering them, and it's invested in the approach. On past PRs, edge cases were the most common kind of review comment: states nobody handled, timing problems, client code guessing at server rules, totals that didn't add up. A cold reader found most of them after the PR was open. This pass hands that one question to a fresh agent before the PR opens.

Spawn a general-purpose sub-agent with no session context. Give it the diff, the ticket, and this prompt:

> "Find the states and inputs this change doesn't handle. Work through three lenses and report on each one, writing 'not applicable' where the diff has nothing for it.
>
> 1. **States.** For every piece of data the change loads: what renders while it loads, when it's empty, when it errors, and while it reloads with old data on screen? For every action that submits: what happens on a double tap, when the user dismisses mid-request, when the screen is gone by the time the response arrives, and when the request succeeds but the refresh after it fails?
> 2. **Trace to the source.** For every value the client validates, filters, or calculates, find the server code that owns it: validators, minimums and limits, resolver filters, the type a mutation actually returns. Flag anywhere the client re-implements, guesses at, or contradicts a server rule, and cite the server file and line.
> 3. **Reconcile the numbers.** For every displayed figure: does it add up to the figure it's part of, and match the same figure elsewhere in the app? Check it at zero, at a value too small to round to a visible digit, and when the underlying records differ (different funds in different accounts, a missing second record).
>
> For each finding, give file:line, the concrete input or sequence that breaks it, and what the user sees. Mark anything you couldn't confirm in the code UNVERIFIED."

Verify each finding against the code, the same way as Pass 4. Every confirmed finding ends in one of two places:

- **A fix, with a test or Storybook story that pins the state.** The fix alone leaves the next change free to break it again.
- **A documented trade-off in the PR description, plus `/capture-issue`.**

A confirmed edge case with neither is the comment a reviewer leaves next.

---

## UI pass — Track 3, when any UI changed

Don't hand-roll this. The `audit-react-frontend` skill already audits React work in `@betterment/retail` against team conventions — story coverage, Playwright coverage, routing and navigation, shared layouts, Samba/Panda styling verified through the Samba MCP, and React 19 readiness. It produces a numbered findings report and only applies fixes on request.

Run it, then carry its findings into Pass 5 alongside the others. If the change touches Playwright specs, `audit-playwright-tests` covers those separately.

---

## Pass 5 — Synthesize and decide

Collect findings from passes 1–4 and the edge-case sweep into one list, each carrying its blocking or non-blocking decoration. For each finding, classify it:

- **Fix now** — issue is real and in scope. Address before opening PR.
- **Document as a known trade-off** — issue is real but out of scope. Add to PR description so reviewers see it was considered, **and invoke `/capture-issue` to file it.** A real issue written into a PR description and nowhere else dies when the PR merges. The description tells reviewers it was considered; the ticket is what makes it survive.
- **Reject with reasoning** — issue is wrong. Note why in case the same comment surfaces in human review.

**Default output format:** see `references/output-format-catalog.md`. For most PRs with >3 findings, render as `.pm-review-<short-sha>.html` in the scratch location using the annotated-diff pattern: columns for source pass, file:line (linked), severity, classification, reasoning. The "documented trade-offs" rows copy cleanly into the PR description. Short reviews (≤3 minor findings) can stay as a markdown list.

Only proceed to Phase 9 when every Pass 1 item is ✅. For Track 2 / Track 3, every Pass 2 ❌ must also be fixed.
