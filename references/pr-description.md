# Writing the PR description

Detail for Phase 9, and for Track 1's step 6. The Book (`the-book rules github/prs`) sets the standard: explain why, follow the repo's template, describe verification CI cannot show. This file is how to meet that standard within the template, adapted from Dan Egan's `authoring_pull_requests.md` in `bestdan/agent-guidance`.

A PR description exists to save the reviewer time. The diff already says what changed. The description says why, and what a careful reader cannot infer.

**One test settles every sentence: does it change what the reviewer does next?** If not, cut it.

## Every track, including Track 1

- **The opening paragraph is mandatory.** One to three sentences: the problem this solves or the capability it adds, and the approach. A ticket link is not a substitute — the reviewer should not have to open Jira to learn why the PR exists. This applies to a two-line copy change too; there it is one sentence.
- **Fill the repo's template in this spirit.** In retail, the template's `Description` prompt asks "What is the new functionality?" — answer it with the why and the approach, not a list of changes. A template section that does not apply is filled `N/A`, not deleted.
- **Fits on one screen.** A change that seems to need more is usually a PR that should be split, or detail that belongs somewhere else (table below).

## Include, when it applies

- **Context an outsider lacks.** Assume the reviewer does not know this area or the product background.
- **The non-obvious.** A trade-off, a workaround, an unusual pattern, a decision a reviewer would reasonably question. Naming it turns a confused review into a focused one.
- **Verification CI cannot show.** What was checked by hand, in which environment, with which persona or flag state. "Saw the new label on the summary page as a joint-account persona, with the flag on and off."
- **What to scrutinize**, when the change has real blast radius. One line, plus the rollback path if the change is hard to reverse.
- **Links**: the ticket, the design, the prior discussion, the PR this depends on.

## Never include

- "Tests pass," "verified locally," "lint is clean" — CI reports that.
- Counts of lines, files, or classes changed.
- A bullet per changed file. That is the Files tab.
- A walkthrough of the whole diff. The reviewer is about to read it.
- Work that is not in this diff, described as if it were: intended, dropped, or follow-up work.

## Where detail belongs

| Content                         | Home                                  |
| ------------------------------- | ------------------------------------- |
| Why this line, not that line    | Inline diff comment                   |
| Why this design, at length      | ADR or design doc, linked             |
| Product or ticket background    | The ticket, linked                    |
| Work not in this diff           | A follow-up ticket (`/capture-issue`) |
| Walkthrough of the whole change | Nowhere — trust the diff              |

## The body must match the diff

Every claim about what the change does must be visible in the diff. Re-read the body against the final diff before showing the draft to the user, and again after any push that changes what the PR does — a body written for the first commit may no longer describe the change. When a later commit outgrows the body, draft the update in the same breath as the push, without being asked.

## Before showing the draft

1. **Compare the changed files against what the ticket asked for.** A file nobody asked for is scope creep or a leftover from earlier work. Stop and ask the user, rather than shipping it under this PR's story.
2. **Read the body once as the reviewer.** Cut every sentence that does not change what the reviewer does next.
