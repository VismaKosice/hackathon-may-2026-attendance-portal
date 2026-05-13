# Solo or Small-Team — Quickstart

**Audience:** Solo participant or 2–3 person team at the hackathon.
**Read time:** 5 minutes.
**Then:** open [`../product-spec.md`](../product-spec.md) §13 + pick your vertical slice.

---

## You will not finish everything

The brief targets a 5–7 person team. With 1–3 people, you cannot ship the full Basic surface in the build window — and the rubric rewards **completed depth over started breadth**.

Pick a vertical slice. Ship it end-to-end. Demo something that works.

## Judging principle

> **The spec is the contract.** Anything `product-spec.md` does not specify is your discretion — judges do not penalise undefined choices. Ship what works; do not hedge.

The Gherkin in [`../acceptance/`](../acceptance/) is the rubric. Every scenario you make pass scores. A scenario that's 90% wired and fails scores zero.

## Stack picks — choose in the first 15 minutes

Solo budgets are even tighter. Prefer:

- **Monolithic stack** — one repo, one process, one framework. No microservices.
- **Familiarity over fashion** — use what you know. Hackathon is not the place to learn Rust.
- **Batteries-included frameworks** — NestJS / Django / Rails / Spring Boot / ASP.NET Core. Auth, ORM, validation, error handling out of the box.
- **SQLite for Basic.** Postgres if you genuinely need it. The spec does not require either.
- **Server-rendered or thin SPA.** A full SPA + separate API doubles your scope. Inertia / Hotwire / Livewire / Razor Pages collapse it back.

No starter code, but the OpenAPI at [`../dev-extras/integration/api-reference.yaml`](../dev-extras/integration/api-reference.yaml) and the mock server at [`../dev-extras/integration/mock-server/`](../dev-extras/integration/mock-server/) are your reference for shapes.

## Vertical slice — recommended cuts

Ship one slice end-to-end before starting the next. The slices are ranked by judge-visibility per unit of effort:

### Slice A — Employee day (highest ROI)

1. Mock-login (pick from a dropdown).
2. Calendar grid showing the current week.
3. Mark workdays + request vacation.
4. See approval status.
5. Hard rule H1 (cannot exceed quota) enforced.

This passes a meaningful subset of `acceptance/employee.feature`. ~5–6 hours for a single competent dev with AI.

### Slice B — Manager approval (add on top of A)

1. Login as manager.
2. See team's pending requests.
3. Approve / reject.
4. Self-approval guard (button disabled when manager == requester).

This passes the core of `acceptance/manager.feature`. ~2–3 hours added.

### Slice C — HR document validation (only if A + B are solid)

1. Employee uploads document.
2. HR validates / rejects with reason.
3. Status visible to employee.

~2 hours added.

### Slices to skip for solo

- XLSX export (spec §11.1) — high effort, low judge-visibility.
- Year-rollover (spec §6.3) — high effort, off the demo path.
- Real OIDC (Bonus, spec §14) — pure time sink for solo.
- Admin team config (spec §17 admin) — low judge-visibility vs effort.
- The full §9 rule catalogue — pick 3–4 rules that map to your slice. Skip the rest with a comment.

## Day shape — solo, 8h build window (example)

Adjust to your event's actual schedule.

| Hour | Track | Output |
|---|---|---|
| h0–h0.5 | Setup | Stack chosen, repo init, CI hooked, `TEAM.md` committed. |
| h0.5–h2 | Skeleton | Mock-login + calendar grid + first endpoint. Hello-world deployed locally. |
| h2–h4 | Slice A | Employee day end-to-end. One acceptance scenario passing. |
| h4–h5 | Slice A polish | Rest of `acceptance/employee.feature` Basic scenarios. |
| h5–h6.5 | Slice B | Manager approval flow. Self-approval guard. |
| h6.5–h7 | Slice C (optional) | HR document validation if A + B are solid. |
| h7–h8 | Demo prep | One smooth flow rehearsed. Screenshot of any acceptance pass. `TEAM.md` final. |

## AI tooling — your only multiplier

Solo without AI cannot finish even Slice A. With AI:

- **Scaffold ruthlessly.** Generate controllers + views + migrations from the spec in batches.
- **Use the mock server.** Don't build your own seed data — point your FE at `dev-extras/integration/mock-server/` while your BE catches up.
- **Read the OpenAPI** — let the AI generate types / clients / fixtures from it.
- **Skip tests you cannot land.** A scenario green on the rubric beats a unit test that proves nothing.

Prompt for slice planning:

```
You are helping me solo a single-day hackathon. Stack: [your stack].
Spec: [paste product-spec.md §13 + §17].
Goal: ship a vertical slice covering employee marks workdays + requests
vacation + sees approval status, with at most 5 hours of work.

Plan: ordered task list with explicit cuts. For each task, indicate
"include" or "skip" and why. Be ruthless — assume I will not finish
anything past hour 7.
```

## What "good" looks like

- One vertical slice works end-to-end at demo time.
- Some `acceptance/` scenarios pass; you can name which.
- `TEAM.md` is committed at the repo root before the build window ends.
- Demo runs without hitting an unimplemented path.
- You can articulate what was cut and why. Judges credit honest scope choices.

## Common failure modes (avoid)

- **Trying to build the full Basic surface.** You won't finish. Cut to one slice.
- **SPA + separate API.** Doubles your scope. Use a framework that collapses it.
- **Learning a new stack at the event.** Hackathon-day is not stack-evaluation day.
- **Real OIDC.** Mock login is fine for Basic. Bonus is unreachable for solo anyway.
- **Skipping `TEAM.md`.** Without it, your repo is not scored. See [`../README.md`](../README.md) for required schema.
- **No demo rehearsal.** Spend the last 30 minutes walking the flow once. Surfaces broken transitions.

## Links

- [`../product-spec.md`](../product-spec.md) §13 — must-have feature list.
- [`../product-spec.md`](../product-spec.md) §17 — UX / screens.
- [`../acceptance/`](../acceptance/) — Gherkin = judging contract.
- [`../dev-extras/integration/api-reference.yaml`](../dev-extras/integration/api-reference.yaml) — OpenAPI 3.1 contract.
- [`../dev-extras/integration/mock-server/`](../dev-extras/integration/mock-server/) — runnable mock API.
- [`../dev-extras/role-quickstarts/backend-dev.md`](../dev-extras/role-quickstarts/backend-dev.md) + [`../dev-extras/role-quickstarts/frontend-dev.md`](../dev-extras/role-quickstarts/frontend-dev.md) — deeper per-role guides if you split work.
- [`../README.md`](../README.md) — overall judging rubric + ground rules + `TEAM.md` schema.
