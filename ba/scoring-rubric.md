# BA Lane — Scoring Rubric

**Audience:** Judges evaluating the BA lane; BAs running a self-evaluation pass.
**Purpose:** How the BA's end-of-day bundle is scored.
**Total:** 100 Basic + up to 30 Bonus (gated by Basic ≥ 90%) = up to 130 points.
**Date:** 2026-05-12

> The BA lane is a **parallel, individual scoring axis**, judged independently of build teams. BAs are ranked **per-individual** on a dedicated BA tab; **BA scores never contribute to any team's total score**. The BA does not staff a team and does not gate dev flow. Output is an end-of-day **analysis bundle** — story set + dependency analysis + traceability matrix + team-shape recommendations + Bonus ROI ranking.

> **The spec is the contract.** Bundles are judged on how well they slice and analyse `product-spec.md` — not on what the BA invents around it. Inventing requirements is penalised under the "Polish" axis, not rewarded.

---

## Basic scoring axes (100 pts)

| Axis | Max | What is being scored |
|---|---|---|
| Story quality | 25 | Per-story shape, INVEST adherence, 2h sizing, well-formed G/W/T |
| Coverage | 20 | Fraction of spec §13 + §9 catalogue sliced into stories with G/W/T |
| Dependency analysis | 15 | Map quality, critical path identified, parallelisation logic |
| Traceability matrix | 15 | Spec → story → Gherkin → rule → notification → audit |
| Bonus ROI ranking | 10 | Top 5 axes with explicit, defensible reasoning |
| Team-shape recommendations | 10 | 2 / 4 / 7-person plans with cuts named |
| Polish | 5 | Readability, organisation, AI-assisted workflow shown |

Subtotal = **100 pts**.

## Bonus tier (up to 30 pts, gated)

Mirrors the team rubric: BA Bonus is counted **only when the BA Basic score is ≥ 90 pts**. Below that gate, Bonus contributions earn zero. Above the gate, full stories (with G/W/T) for spec §14 Bonus axes earn points up to the cap.

| Signal | Pts per axis | Notes |
|---|---|---|
| Bonus axis with ≥ 2 well-shaped G/W/T stories | ~5 | Quality over quantity — one excellent story beats two shallow ones. |
| Proposed-new G/W/T scenarios for Bonus edge cases (dedup, idempotency, template registry, hash-chain integrity, etc.) | ~1-2 each | Same standard as Basic proposed-new (genuine gap-finding only). |
| Dependency analysis of Bonus axes (which Bonus reuses Basic infra, which conflicts) | ~3-5 | Shipped as an addendum to the Basic dependency map. |

Cap = **30 pts**. Total BA-lane ceiling = 100 + 30 = **130 pts**.

Coverage requirement at the gate: Basic ≥ 90 pts AND all 14 §13 items present AND all H1-H10 + S1-S6 rules covered by ≥ 1 G/W/T. If any of those fail, Bonus is zero regardless of how many Bonus stories are authored.

---

## Axis 1 — Story quality (25 pts)

How well-shaped are the individual stories?

| Band | Description | Pts |
|---|---|---|
| High | Every story fits one screen. Every story carries **at least one Given/When/Then scenario** in its body, well-formed (Given = state, When = single action, Then = observable outcome). Most stories cover happy path + ≥ 1 rule trip + ≥ 1 edge. Mapping to `acceptance/` is accurate; proposed-new scenarios are clearly marked. Sizing is plausible at 2h. INVEST principles (Independent, Negotiable, Valuable, Estimable, Small, Testable) visibly applied. Demo cue per story. | 20-25 |
| Medium | Most stories follow the template. G/W/T present but shallow (happy path only on ≥ 50%, no rule trips covered). A handful oversized or under-shaped. Demo cue missing on ~20%. | 12-19 |
| Low | Stories are paragraphs, not slices. G/W/T missing or malformed (Given used as action, Then used as hope). Sizing not credible. Demo cues missing on > 50%. | 5-11 |
| Floor | Stories are spec excerpts copy-pasted. No G/W/T. No template applied. | 0-4 |

Common evidence:
- A judge reading any single story understands what to build and how to demo it in < 60 seconds.
- The 2h sizing claim is checkable — the story is small enough that a senior + AI pair would plausibly finish it.
- G/W/T scenarios tie to concrete fixture users (Anna, Tomáš, Janka, …) where possible — concrete beats abstract.
- Bonus stories carry an explicit "recommend only after Basic ≥ 90%" annotation.

**Penalties under this axis (subtract from band):**
- G/W/T that contradicts the matching `acceptance/` scenario without flagging the conflict: −2 pts per occurrence.
- "Should" / "could" / "might" in `Then` clauses: −1 pt per occurrence.

## Axis 2 — Coverage (20 pts)

Does the bundle cover the Basic surface — both as stories and as G/W/T scenarios?

| Band | Description | Pts |
|---|---|---|
| High | All 14 spec §13 items sliced. All 10 hard rules (H1-H10) covered by at least one G/W/T scenario in some story (positive + negative case where applicable). All 6 soft rules (S1-S6) covered by at least one G/W/T. State transitions for each absence type covered (submit / approve / reject / withdraw / cancel). ≥ 3 "proposed new" scenarios surface real gaps in `acceptance/`. | 17-20 |
| Medium | 12+ of 14 §13 items sliced. 8+ of 10 hard rules covered by G/W/T. 4+ of 6 soft rules. Few or no proposed-new scenarios. | 11-16 |
| Low | 8-11 of 14 §13 items sliced. < 8 hard rules covered. Most soft rules missing from G/W/T. | 4-10 |
| Floor | < 8 §13 items sliced. | 0-3 |

A coverage matrix in the bundle (which story covers which spec section + which G/W/T covers which rule) is the natural evidence. Gaps you identify and flag honestly do **not** lose points — gaps you hide do. "Proposed new" scenarios that surface a genuine `acceptance/` gap earn points at this axis *and* under Story quality.

## Axis 3 — Dependency analysis (15 pts)

Can a build team look at your bundle and know where to start, what to parallelise, and what blocks what?

| Band | Description | Pts |
|---|---|---|
| High | Explicit dependency map (table or graph). Critical path called out. Foundation stories sequenced first. Parallel-track recommendations grounded in actual blocker analysis. | 12-15 |
| Medium | Per-story `Depends on` / `Blocks` fields populated. Map exists but is partial. Critical path implicit. | 7-11 |
| Low | Some stories reference dependencies; many do not. No map. | 2-6 |
| Floor | Dependencies absent across the bundle. | 0-1 |

Bonus credit (within the band): cycle detection in your own bundle (story X depends on Y depends on X = error), flagged + resolved.

## Axis 4 — Traceability matrix (15 pts)

The catch-net artefact. Spec coverage + Gherkin coverage + rule coverage + notification coverage + audit coverage in one table.

| Band | Description | Pts |
|---|---|---|
| High | Matrix is complete (every story has a row). Every row has spec section + Gherkin reference + rule list + notification list + audit list. Empty cells are explicitly "none", not blank. Bundle's own gaps are visible from the matrix. | 12-15 |
| Medium | Matrix exists. Most rows populated. Some cells blank ambiguously. | 7-11 |
| Low | Matrix is partial or only covers some stories. | 2-6 |
| Floor | No matrix. | 0-1 |

The strongest signal: a judge using the matrix to find a coverage gap that the BA also flagged in a separate "open questions" section. That shows the matrix worked as a catch-net.

## Axis 5 — Bonus ROI ranking (10 pts)

Top 5 Bonus axes from spec §14, with reasoning.

| Band | Description | Pts |
|---|---|---|
| High | 5 axes ranked. Each carries a one-paragraph rationale tied to effort × visibility × reuse × risk. The ranking is defensible — a judge can argue with it but cannot call it arbitrary. Explicitly de-prioritised axes named with reasoning. | 8-10 |
| Medium | 3-5 axes ranked with thin reasoning. Order is plausible but reasoning is shallow. | 4-7 |
| Low | A list of Bonus axes with no ranking or reasoning. | 1-3 |
| Floor | Missing. | 0 |

Hint: a ranking that puts "real auth" first loses points — single-day delivery makes it a time pit; the BA should know that.

## Axis 6 — Team-shape recommendations (10 pts)

How does the same backlog behave for a 2-person team versus a 7-person team?

| Band | Description | Pts |
|---|---|---|
| High | Three plans (2 / 4 / 7-person) with explicit cuts, foundation stories, parallel tracks, and aggregating screens identified for each. Cuts named at the item level (not story halves). | 8-10 |
| Medium | Two plans, or three with vague cuts. | 4-7 |
| Low | One plan, or generic guidance. | 1-3 |
| Floor | Missing. | 0 |

Hint: a 2-person plan that still attempts all 14 Basic items loses points — that is not credible inside a single-day window.

## Axis 7 — Polish (5 pts)

The bundle as a deliverable: readability, organisation, AI-assisted workflow shown.

| Band | Description | Pts |
|---|---|---|
| High | Folder structure makes the bundle reviewable in < 10 min. Cross-links work. AI prompts shown in an appendix or alongside generated stories. Self-evaluation against this rubric included. | 4-5 |
| Medium | Bundle is readable. Some cross-links broken. AI workflow implied but not shown. | 2-3 |
| Low | Disorganised. Files unlabelled. No self-evaluation. | 0-1 |

**Inventing requirements not in the spec** is penalised here, not rewarded. Judges deduct 1-2 pts for visible invention.

---

## Self-evaluation

Run the rubric against your own bundle before the deadline. Score each axis honestly. The pass usually identifies 1-2 gaps that are cheap to close at the end of the day (typically: a missed soft rule, an unlinked Gherkin scenario, a story with a missing Demo cue, the traceability matrix's "none" cells written as blank).

A bundle that includes the BA's own self-evaluation table earns full Polish points.

---

## Out of scope for this rubric

- Whether any actual build team used the bundle. (BAs are not on teams; usage is not evaluated.)
- Whether the BA "helped" a team during the day. (Help is optional and informal; not scored.)
- Quality of the spec itself. (The spec is the contract — BAs slice it; they do not rewrite it.)
- Decisions the spec leaves open. (Team's discretion; not judged.)
