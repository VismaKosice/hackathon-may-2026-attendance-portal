# Slicing Guidance — The Analyst Playbook

**Audience:** Business Analyst at the hackathon, producing the analysis bundle.
**Purpose:** How to slice spec §13 into a complete, dependency-aware story set; how to build the supporting analysis artefacts.
**Companion docs:** [`story-template.md`](story-template.md) for per-story shape, [`scoring-rubric.md`](scoring-rubric.md) for how the bundle is judged.
**Date:** 2026-05-12

> **You are not on a build team.** Dev teams build from [`../product-spec.md`](../product-spec.md), [`../acceptance/`](../acceptance/), and [`../dev-extras/integration/api-reference.yaml`](../dev-extras/integration/api-reference.yaml). They do not wait on your stories. This document is about producing your **own deliverable** at depth — a parallel artefact judged on its own merit. See [`../role-quickstarts/business-analyst.md`](../role-quickstarts/business-analyst.md) first.

> **The spec is the contract.** Anything `product-spec.md` does not define is the team's discretion. Do not invent requirements. Document what's there; flag gaps without filling them with your preferences.

---

## The 2-hour rule

A senior engineer with strong AI tooling delivers a vertical slice in ~2 hours. Use that as your sizing target. The 2-hour rule is a **slicing heuristic**, not a delivery promise — your stories do not need to be perfectly accurate for any specific team's velocity, but they should be reviewable as plausibly 2h.

Smaller than 2h → ceremony eats the budget. Larger than 2h → flies blind between commits. Reviewers see "could a competent pair do this in 2h?" and your story passes or fails on that question.

## Acceptance criteria — every story carries Given/When/Then

Each story you author includes **at least one Given/When/Then scenario** in its body. Two-to-five scenarios is typical for a 2h slice: happy path + 1-2 rule trips + 1-2 edges.

**Why you author your own** — the `acceptance/*.feature` files in the brief repo are the **judging contract** (pre-authored, shipped to teams, used as the TDD spec and rubric). They are not editable by BAs. Your G/W/T are **analysis output**: how you (the BA) think the story behaves end-to-end. The two can sit side-by-side without conflict; when they disagree, `acceptance/` wins by definition.

**Three uses for BA-authored G/W/T:**

1. **Mirror-and-elaborate.** Re-write the existing `acceptance/` scenario in your own words, often with additional `And` clauses covering notification + audit fan-out. Cite the canonical scenario in `Mapping → Existing Gherkin`. This shows you read and understood the contract.
2. **Edge cases.** Identify combinations the upfront Gherkin missed (rule combos, transition edges, slot conflicts across absence types). Mark the scenario `(proposed)`. These are the highest-value contributions in the bundle.
3. **Bonus axes.** Where `acceptance/` covers Bonus surfaces only at a high level (e.g. the `@bonus @email-channel` block), elaborate G/W/T per concrete behaviour (dedup, idempotency, template registry).

**Authoring discipline:**

- Given = state, not action. "Anna has 3 vacation days remaining" — not "Anna logs in".
- When = a single user action. One verb.
- Then = an observable outcome. UI state, persisted state, notification record, audit entry.
- `And` / `But` for additional clauses inside a step.
- Tie to seeded fixture users (Anna, Tomáš, Janka, Peter, Mária) where you can — concrete beats abstract.
- One scenario per outcome shape (Approve and Reject = two scenarios, not one with branches).
- No "should" / "could" / "might". Then is a fact.

See [`story-template.md`](story-template.md) for the full template + three worked examples (Basic vertical, Basic rule-only, Bonus gated).

## Coverage pass — the Basic 14

Spec §13 lists 14 items. Each gets sliced into 1-4 stories. Starting point:

| # | Spec §13 item | Suggested stories | Notes for the analyst |
|---|---|---|---|
| 1 | Admin creates teams, assigns managers, invites users | 2-3 | Org-tree CRUD + cycle check (admin endpoint) + role assignment are independent slices. |
| 2 | Mock login | 1 | Single story; OIDC is Bonus §14 (separate). |
| 3 | Worktime entry (project, BT toggle, overtime auto-detect, live validation) | 3 | Submit happy path / overtime auto-flag / BT toggle. Worktime soft rules (S2, S3, S4, S6) cluster into one rule story. |
| 4 | Vacation full loop (submit → approve → notify → balance refresh → calendar update) | 3-4 | Submit / approve / withdraw / quota-rule (H5 + S5). |
| 5 | Sickday with all hard rules (H2 full-day, H3 ≤3/yr, H4 consecutive, working-day) | 2-3 | Happy path + rule cluster (H2+H3+H4 share story). Notification fan-out as a separate slice or piggy-back. |
| 6 | Paragraph + document upload, HR validate, reject path | 3 | Submit + upload / HR approve / HR reject + reason. H8 surfaces here. |
| 7 | Manager team calendar (grid, colour, click-through, badges, month switch) | 2 | Render + interactions are separable. |
| 8 | Manager approvals queue (live, approve/reject, skip-level approve) | 2-3 | Queue render + decision flow + skip-level filter (DEC-003). |
| 9 | HR monthly XLSX export (two-sheet, SK + EN, frozen header, catalogue) | 2 | Generator + locale switch. SK alone if cut. |
| 10 | HR documents queue (preview, approve/reject + reason) | 2 | Overlaps #6 — can be one combined slice. |
| 11 | Year-rollover dry-run + apply (3 worked examples) | 2 | Engine + UI separable. |
| 12 | Audit log screen (filterable, before/after snapshot) | 1-2 | Writer is part of every state-change story; the screen is its own slice. |
| 13 | My notifications inbox | 1 | Reader; writer is part of every state-change story. |
| 14 | Balances screen (allocated/used/reserved/carried/lost + chart) | 2 | Computed-view read + chart. |

**Starting story count: 29-34.** Adjust upward for thorough analysis bundles or to cover more rules per slice.

## Rule pass — the H1-H10 + S1-S6 catalogue

Spec §9 names 16 rules. Every rule belongs to at least one story.

Use this table when refining the coverage pass — gaps here are coverage gaps.

| Rule | Spec section | Trigger | Best home story |
|---|---|---|---|
| H1 — overlap | §9.1 | Worktime ↔ worktime, worktime ↔ approved absence, absence-slot ↔ absence-slot | Worktime submit |
| H2 — sickday full-day only | §9.1 | Half-day sickday attempted | Sickday rule cluster |
| H3 — sickday ≤ 3/yr | §9.1 | 4th sickday in calendar year | Sickday rule cluster |
| H4 — no consecutive sickdays | §9.1 | Adjacent calendar-day sickdays | Sickday rule cluster |
| H5 — quota exceeded | §9.1 | Vacation / Paragraph / OCR / Special beyond remaining | Vacation submit (recur on each absence type) |
| H6 — worktime forbidden on approved-absence day | §9.1 | Worktime attempted on absence day | Worktime submit |
| H7 — overtime forbidden during absence | §9.1 | Overtime flag on absence day; PN over weekend | Worktime overtime story |
| H8 — documents required to finalise | §9.1 | Approve transition without HR-validated doc on Paragraph/OCR/Special | Manager approve / HR validate |
| H9 — full-day absence vs worktime same day | §9.1 | Full-day absence then worktime | Worktime submit (overlaps H6) |
| H10 — slot collision | §9.1 | Two absences on the same morning/afternoon slot | Vacation submit (recur on each absence type) |
| S1 — 30-min gap | §9.2 | Half-day absence + same-day worktime starting < 30 min later | Worktime soft-warning cluster |
| S2 — working-window soft warn | §9.2 | Worktime outside 08:00-16:30 default | Worktime soft-warning cluster |
| S3 — night-time | §9.2 | Worktime between 22:00 and 06:00 | Worktime soft-warning cluster |
| S4 — single entry > 8h | §9.2 | One worktime entry exceeding 8h | Worktime soft-warning cluster |
| S5 — quota approaching | §9.2 | Submission leaves ≤ 2 remaining | Vacation submit |
| S6 — public holiday | §9.2 | Worktime on Slovak holiday | Worktime soft-warning cluster |

If a rule has no home story, it has no test, no UI surface, and no demo moment. That is a coverage gap; flag it in the bundle.

## Dependency pass — the map

A handful of stories block many others. Sequence those first.

```
┌──────────────────────────────────────────────────────────────────┐
│  Foundation (cannot demo anything without these)                 │
├──────────────────────────────────────────────────────────────────┤
│  S-01  Mock login                                                │
│  S-02  Seed fixture wired (users + teams + direct_manager_id)    │
│  S-03  App shell + role-aware routing                            │
└──────────────────────────────────────────────────────────────────┘
                                ↓
┌──────────────────────────────────────────────────────────────────┐
│  Vertical slice #1 — Vacation end-to-end                         │
├──────────────────────────────────────────────────────────────────┤
│  S-04  Submit vacation (form + H5 + S5)                          │
│  S-05  Manager approves vacation (queue + transition + audit)    │
│  S-06  Employee sees decision (notification + balance)           │
└──────────────────────────────────────────────────────────────────┘
                                ↓
┌──────────────────────────────────────────────────────────────────┐
│  Parallel tracks open                                            │
├──────────────────────────────────────────────────────────────────┤
│  Track A  Sickday + PN                                           │
│  Track B  Paragraph + document upload + HR validate              │
│  Track C  Manager calendar + queue + skip-level                  │
│  Track D  Worktime + overtime + soft warnings                    │
└──────────────────────────────────────────────────────────────────┘
                                ↓
┌──────────────────────────────────────────────────────────────────┐
│  Aggregating screens + jobs                                      │
├──────────────────────────────────────────────────────────────────┤
│  S-19  HR monthly XLSX export                                    │
│  S-20  Year-rollover dry-run + apply                             │
│  S-21  Balances screen                                           │
│  S-22  My notifications inbox                                    │
│  S-23  Audit log screen                                          │
└──────────────────────────────────────────────────────────────────┘
```

**Your bundle includes** an actual dependency map (table or graph) with every story node showing predecessors and successors. The critical path is the longest predecessor chain — typically S-01 → S-04 → S-05 → S-06 → an aggregating screen.

## Slice patterns — the five recurring shapes

Once you see them, the rest of the slicing is mechanical.

### Pattern A — "Submit X" (happy path)

One story per absence type's happy path. ~2h. Form renders, validator runs, entity persists, notifications fan out, audit entry written, linked Gherkin scenario passes.

### Pattern B — "Rule cluster"

One story per group of related rules. ~1-2h. Sickday rules (H2+H3+H4) cluster; worktime soft rules (S1+S2+S3+S4+S6) cluster. Each rule has its Gherkin scenario; the story covers all of them in one inline-error pass.

### Pattern C — "Transition X → Y"

One story per state-machine transition. ~2h. Approve, Reject, Withdraw, Cancel each get their own. Re-validation per spec §9.3 runs on Approve.

### Pattern D — "Aggregating screen"

One story per screen that *reads* what other stories wrote. ~2-3h. Team calendar, approvals queue, documents queue, audit log, my notifications, balances. Parallelisable once writers are in place.

### Pattern E — "Cross-cutting job"

One story per scheduled or one-off job. ~2-3h. Year-rollover dry-run, year-rollover apply, XLSX export pipeline. Heavy logic; single owner.

## Bonus ROI ranking — the framework

Your bundle ranks the top 5 Bonus axes from spec §14 with explicit reasoning. **Once Basic coverage is complete (≥ 90 pts, see [`scoring-rubric.md`](scoring-rubric.md)), authoring full G/W/T stories for the top-ranked axes earns up to 30 additional points.** Ranking alone is Basic; story production is Bonus.

Use these criteria for the ranking:

1. **Effort** — how many 2h slices to ship (lower is better).
2. **Judge visibility** — how visible in a 10-min demo (higher is better).
3. **Reuse-with-Basic** — does the Bonus reuse Basic infrastructure (higher is better)?
4. **Risk** — likelihood of breaking Basic if attempted late (lower is better).

Default top 5 (publish with your own reasoning; teams may disagree):

1. **Mobile-friendly responsive UI** — high reuse, high visibility, low effort if design system was sensible during Basic.
2. **Multi-language UI (EN)** — high reuse (catalogue infra is Basic); judge-visible on the export + a few labels.
3. **Email delivery channel** — moderate effort, high visibility (judges check inbox during demo). Reuses notification records 1:1.
4. **Skip-level *policy* enforcement** — small surface, strong rule-engine signal, low risk.
5. **Audit-log tampering protection (hash chain)** — single 90-min slice, security + code-quality signal, low risk.

**Explicitly de-prioritised** for single-day delivery: real auth (time pit), Tempo import (engine reuse with §11.6 makes it tempting but risky), websocket push (infra cost), PWA (low ROI for an internal app), two-factor (production-grade work in a day).

## Traceability matrix — the bundle's catch-net

For each story, build a row:

| Story ID | Spec section | Gherkin file:scenario | Hard rules | Soft rules | Notifications | Audit event |
|---|---|---|---|---|---|---|

This is the **highest-leverage artefact** in your bundle. It catches:

- Stories that reference no Gherkin (= not demo-able)
- Spec sections covered by no story (= coverage gap)
- Rules covered by no story (= rule gap)
- State changes without notification fan-out (= violation of spec §10)
- State changes without audit entry (= violation of spec §11.5)

Build it as the last pass; iterate the coverage / rule passes until it's clean.

## Team-shape recommendations — the cuts table

For each of 2-person / 4-person / 7-person teams, write the explicit plan in your bundle:

| Team | Foundation | Vertical slice #1 | Parallel tracks | Aggregating | Cuts |
|---|---|---|---|---|---|
| **2** | S-01..S-03 | Vacation only | One track only (sickday OR paragraph) | Balances + notifications only | XLSX export, year-rollover, audit screen, manager calendar, HR documents queue, BT toggle |
| **4** | S-01..S-03 | Vacation | 2 tracks parallel | Most aggregating screens | Cut EN export, cut chart on balances, cut audit screen filters |
| **7** | S-01..S-03 | Vacation | All 4 tracks parallel | All aggregating screens | None on Basic; pursue top 2 Bonus axes |

**Cuts are by whole item, not story halves.** A half-built screen is a demo liability.

## What this guidance is NOT

- A spec rewrite. The spec is the contract.
- A timeline for a build team. Teams own their own clock.
- A test plan. The testing refinements own that.
- A demo script. Teams write their own.
- A facilitation playbook. You are not facilitating.

## Self-evaluation

Before submitting the bundle, run [`scoring-rubric.md`](scoring-rubric.md) against your own work. Most bundles gain ~10 points from a single self-eval pass — gaps surface, and fixing them is cheap right before the deadline.
