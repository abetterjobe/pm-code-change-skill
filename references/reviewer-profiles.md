# Reviewer profiles

A growing record of what specific reviewers care about. Used by Phase 8 Pass 3 (reviewer persona simulation). Grown via Phase 13.

The profiles below are placeholder templates showing format and depth. As real PRs surface real reviewers and their patterns, replace the generic names with actual names + GitHub handles. Phase 13 proposes these updates and the user approves them.

> **Auto reviewer 1 (template)** — type system, especially nullability. Prefers nullable when the underlying data is sometimes absent; pushes back on non-null assertions without justification. Will ask "when would this ever be null?" — have an answer ready.
>
> **Auto reviewer 2 (template)** — domain model placement and convention-matching. Will flag fields placed on the wrong owner. Cares about precedent — if a similar feature exists, this one should follow it. Watches for conventions like "exclude the current user from collaborator lists."
>
> **Auto reviewer 3 (template)** — business logic placement and defensive code. Will flag resolver/business logic inlined in schema type definitions. Will flag redundant guards where the invariant is upstream-enforced. Strongly dislikes AI-signed PR responses.

*Each new reviewer who leaves substantive comments gets a profile entry. Format: bolded name + handle, then 2–4 sentences capturing their recurring concerns and any pattern phrases they use.*
