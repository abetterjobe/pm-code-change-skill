# Pre-PR review: Passes 2–5

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

- Run the `code-review` skill at `--effort high`. **Never pass `--comment`** — that posts findings directly to the PR, which violates Phase 10's posting protocol. Findings go to Pass 5 synthesis only.
- Spawn a general-purpose sub-agent with the diff and the original task description only, prompted: *"Review this diff for correctness bugs and code quality issues. You have no context on prior discussion. Be specific and quote line numbers."*

The value of fresh-eyes review is bias removal — the original-context reviewer (mid-task) has invested in the current approach; the fresh-eyes reviewer hasn't.

**Verify each finding; don't accept them on authority.** The fresh-eyes reviewer has *less* context than you — it hasn't read the ticket, the prior discussion, or the surrounding conventions. Some of its findings will describe problems that are already handled elsewhere, or that misread the architecture. For each one, check the actual code and classify it: confirmed, or invalid with a stated reason. Carry both lists into Pass 5 — the invalid ones are worth keeping, because the same misreading often resurfaces in human review and you'll already have the answer.

---

## UI pass — Track 3, when any UI changed

Don't hand-roll this. The `audit-react-frontend` skill already audits React work in `@betterment/retail` against team conventions — story coverage, Playwright coverage, routing and navigation, shared layouts, Samba/Panda styling verified through the Samba MCP, and React 19 readiness. It produces a numbered findings report and only applies fixes on request.

Run it, then carry its findings into Pass 5 alongside the others. If the change touches Playwright specs, `audit-playwright-tests` covers those separately.

This pass was referenced by Phase 8's track table for a long time without ever being defined — an instruction to run a pass that didn't exist. It's defined here now by pointing at the tool that already does the work.

---

## Pass 5 — Synthesize and decide

Collect findings from passes 1–4 into one list. For each finding, classify it:

- **Fix now** — issue is real and in scope. Address before opening PR.
- **Document as a known trade-off** — issue is real but out of scope. Add to PR description so reviewers see it was considered, **and invoke `/capture-issue` to file it.** A real issue written into a PR description and nowhere else dies when the PR merges. The description tells reviewers it was considered; the ticket is what makes it survive.
- **Reject with reasoning** — issue is wrong. Note why in case the same comment surfaces in human review.

**Default output format:** see `references/output-format-catalog.md`. For most PRs with >3 findings, render as `./.pm-review-<short-sha>.html` using the annotated-diff pattern: columns for source pass, file:line (linked), severity, classification, reasoning. The "documented trade-offs" rows copy cleanly into the PR description. Short reviews (≤3 minor findings) can stay as a markdown list.

Only proceed to Phase 9 when every Pass 1 item is ✅. For Track 2 / Track 3, every Pass 2 ❌ must also be fixed.
