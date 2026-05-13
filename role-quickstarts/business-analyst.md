# Business Analyst — Quickstart

**Audience:** Business Analyst at the hackathon.
**Read time:** 5 minutes.
**Then:** open [`../ba/slicing-guidance.md`](../ba/slicing-guidance.md) and start producing.

---

## You are a parallel lane

You are **not** staffed onto a build team. You do not facilitate stand-ups, cut scope, or run the clock. You produce your own deliverable across the day; it is judged independently against [`../ba/scoring-rubric.md`](../ba/scoring-rubric.md).

Dev teams build from [`../product-spec.md`](../product-spec.md), [`../acceptance/`](../acceptance/), and [`../dev-extras/integration/api-reference.yaml`](../dev-extras/integration/api-reference.yaml). They do not wait on you.

You may sit near a team and answer questions if asked. **Do not push help.** Teams that want a BA in the loop will ask; teams that don't, won't.

## Judging principle

> **The spec is the contract.** Anything `product-spec.md` does not define is the team's discretion — judges do not score teams on undefined behaviour, only on what the spec specifies. Your analysis lives inside the spec; do not invent new requirements.

This means: when a question comes up that the spec does not answer, the team picks. You can document the choice as a clarification in your stories, but the team is not penalised for choosing differently than you would.

## What you deliver

A single artefact bundle, due at the end of the day, sized to fit in one folder or one document:

1. **Story set** — ~30 stories covering spec §13 + §9 rule catalogue, using [`../ba/story-template.md`](../ba/story-template.md). 2-hour-target slices. **Every story carries at least one Given/When/Then scenario** in its body — most stories have 2-5 (happy path + rule trips + edges). The `acceptance/*.feature` files are the judging contract authored upfront; your G/W/T are *analysis output* — they may mirror existing scenarios, elaborate with notification + audit fan-out, or propose new scenarios that surface gaps in `acceptance/`.
2. **Dependency map** — visual or tabular, showing which stories block which. Critical path identified.
3. **Bonus axis ROI ranking** — top 5 Bonus axes from spec §14, with reasoning, sequenced for a team that already has Basic ≥ 90%.
4. **Traceability matrix** — one row per story, columns: spec section, Gherkin scenario, hard/soft rules hit, notifications, audit. Catches gaps before judges do.
5. **Team-shape recommendations** — same backlog, different parallelisation plans for 2-person / 4-person / 7-person teams. Shows how cuts cascade.

Anything in [`../ba/scoring-rubric.md`](ba/scoring-rubric.md) earns points. Anything else is decoration.

## BA Bonus tier — extra points for Bonus-axis stories

Mirroring the team rubric, the BA lane has a **Bonus tier worth up to 30 pts, gated by BA Basic ≥ 90%**. You earn Bonus points by authoring full stories (with G/W/T) for spec §14 Bonus axes — not just ranking them.

Suggested approach:
- Complete Basic coverage first; self-evaluate against [`../ba/scoring-rubric.md`](../ba/scoring-rubric.md) to verify the gate.
- Once the gate is clear, pick from the top of your own Bonus ROI ranking (Basic deliverable #3).
- Each Bonus axis with ≥ 2 well-shaped stories earns ~5 pts; cap is 30. Quality over quantity — a Bonus axis with one excellent story beats two shallow ones.
- Proposed-new G/W/T for Bonus edge cases counts here too.

## What you do NOT deliver

- Coordination of any build team.
- Demo scripts (teams own their own).
- Implementation guidance (the FE / BE / testing refinements own that).
- A revised spec. You are not editing `product-spec.md` or the Gherkin.

## Suggested day shape

These are tracks, not a schedule. Move between them as productive.

| Track | What you produce |
|---|---|
| **Coverage pass** | Slice spec §13 (14 items) into ~25-30 stories. Use the template. Author Given/When/Then per story. |
| **Rule pass** | Cross-check spec §9 (H1-H10 + S1-S6). Every rule needs at least one G/W/T scenario (positive + negative where applicable). Identify combos `acceptance/` missed → propose new G/W/T. |
| **Dependency pass** | Build the dependency map; identify critical path; flag stories that block many. |
| **Bonus ROI pass** | Rank spec §14 axes by effort × judge-visibility × code-reuse-with-Basic. Top 5 with reasoning. |
| **Traceability pass** | Build the matrix. Use it to find gaps in your own coverage pass. |
| **Team-shape pass** | For each of 2 / 4 / 7-person teams, write the parallelisation plan with explicit cuts. |
| **Polish pass** | Format the bundle. Cross-link consistently. Self-evaluate against the rubric. |

Sequence is up to you. Most BAs will iterate — coverage → rule → coverage → dependency → coverage. That's fine.

## AI tooling — your specific use

The BA's high-leverage AI use is **drafting stories from spec text** + **building the traceability matrix**.

Prompt template:

```
You are helping me slice a hackathon backlog. Each story should be ~2h
for a senior + AI dev. Use this template: [paste story-template.md]

Spec item:
[paste product-spec.md §13 item #N + any referenced rules from §9]

Linked Gherkin scenarios from acceptance/<file>.feature:
[paste the relevant scenarios]

Draft 2-3 stories that cover this item. For each, fill the template fields
and propose a Demo cue line.
```

Then **edit ruthlessly**. The AI will over-produce. Cut anything that isn't testable, demo-able, or sliced to 2h. Show your prompts in the bundle — *judges credit AI-assisted workflow that is visibly directed, not blindly accepted*.

## What "good" looks like

- A bundle a real BA could hand to a real engineering team on day 1 of a sprint.
- Stories that map cleanly to Gherkin scenarios; no orphans.
- A dependency map that says *"start here, parallelise here, this blocks everything"* at a glance.
- A Bonus ROI ranking with reasoning — not just a list.
- A team-shape table that shows you understand the actual budget arithmetic.
- The bundle is a `ba/` folder in your fork (or equivalent), reviewable end-to-end in under 10 minutes by a judge.

## Common failure modes (avoid)

- **Producing a spec rewrite.** You are not rewriting `product-spec.md`. You are slicing it. If your story body is longer than the spec section it comes from, you're writing prose, not stories.
- **Inventing requirements.** Anything not in the spec is the team's call. Document what's there; do not extrapolate.
- **Hovering over a build team.** If a team wants help, they will ask. Otherwise, work on your own bundle. Time spent watching dev/QA pairs is time not producing.
- **Coordinating a team without being asked.** Teams have their own scope-cutter / clock-watcher — typically the strongest dev or whoever volunteers. That is not your role.
- **Skipping the traceability matrix.** It is the highest-leverage artefact in the bundle — it catches your own gaps before judges do.
- **No self-evaluation.** Run the rubric against your own bundle before the deadline. Most BAs will gain ~10 points from one pass.

## Links

- [`../ba/slicing-guidance.md`](../ba/slicing-guidance.md) — the analyst playbook (slice patterns, full §13 mapping, dependency framework, Bonus ROI framework).
- [`../ba/story-template.md`](../ba/story-template.md) — per-story shape.
- [`../ba/scoring-rubric.md`](../ba/scoring-rubric.md) — how the bundle is judged.
- [`../product-spec.md`](../product-spec.md) — the contract you slice.
- [`../acceptance/`](../acceptance/) — Gherkin scenarios you reference.
- [`../README.md`](../README.md) — overall judging rubric.
