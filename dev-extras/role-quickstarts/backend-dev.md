# Backend Developer — Quickstart

**Audience:** Backend developer on a hackathon build team.
**Read time:** 5 minutes.
**Then:** open [`../backend/be-technical-refinement.md`](../backend/be-technical-refinement.md) and start producing.

---

## What you are building

A REST API for the Attendance Portal. Owns the rules, the data, the approval state machine, and the export pipeline. See [`../../product-spec.md`](../../product-spec.md) §6, §7, §9, §11.

The OpenAPI 3.1 reference at [`../integration/api-reference.yaml`](../integration/api-reference.yaml) is the contract surface for Basic. Match it where it specifies; anywhere it leaves shapes open, you choose.

## Judging principle

> **The spec is the contract.** Anything `product-spec.md` does not specify is your discretion — judges do not penalise undefined choices. Pin stack, pin libraries, ship.

The Gherkin in [`../../acceptance/`](../../acceptance/) is the rubric. If `acceptance/*.feature` passes, the feature is done. If it does not, it isn't — regardless of how clean your code reads.

## Stack picks — choose in the first 30 minutes

Framework-agnostic. Pick one and commit:

- **Runtime:** Node + NestJS / Fastify / Express • Python + FastAPI / Django / Flask • Go + Gin / Echo / Chi • Java/Kotlin + Spring Boot / Ktor • C# + ASP.NET Core • Rust + Actix / Axum • Ruby + Rails.
- **DB:** Postgres (preferred for transactions + JSON), SQLite is fine for Basic.
- **Migrations:** whatever the stack idiom is. Just commit them.

No starter code. Fixtures (when available) are stack-agnostic JSON/CSV.

## What you deliver

1. **Working API** — all Basic endpoints from `api-reference.yaml`, exercised by the Gherkin in `acceptance/`.
2. **Rule engine** — Hard rules H1–H10 + Soft rules S1–S6 from spec §9. Hard rules block; soft rules warn.
3. **State machine** — absence lifecycle per spec §7. Transitions are explicit, auditable.
4. **Approval routing** — skip-level + self-approval guard per spec §7. Manager cannot approve their own request.
5. **Audit log** — every state-changing action recorded with actor, target, before/after.
6. **XLSX export** — per spec §11.1.
7. **Mock auth for Basic** — real OIDC is Bonus only.

## Day shape — suggested

These are tracks, not a schedule. Parallelise with FE + QA from hour 0.

| Track | What you produce |
|---|---|
| **Skeleton pass (h0–h1)** | Scaffold app, DB connection, healthcheck, mock-login endpoint. CI green on empty test suite. |
| **Domain pass (h1–h3)** | Entities + migrations. State machine wired but not enforced. Audit log table. |
| **Rule pass (h2–h5)** | Hard rules H1–H10 as testable predicates. Soft rules surface warnings. Unit tests per rule. |
| **Endpoint pass (h3–h6)** | Wire endpoints from `api-reference.yaml`. Acceptance scenarios start passing. |
| **Approval pass (h5–h7)** | Approval routing + skip-level + self-approval guard. Manager / admin endpoints. |
| **Export pass (h6–h7)** | XLSX pipeline (spec §11.1). Verify against the example. |
| **Polish pass (h7–end)** | Error envelope, idempotency keys, request validation, fix flaky scenarios. |

## AI tooling — your specific use

High-leverage backend use is **scaffolding repetitive code from the spec** + **generating rule predicates from §9** + **writing migrations from entity sketches**.

Prompt template:

```
You are helping me build an Attendance Portal REST API.

Context:
- Spec section: [paste product-spec.md §<N>]
- OpenAPI: [paste relevant operationId(s) from api-reference.yaml]
- Stack: [Node + NestJS + Postgres + Prisma]

Task:
Generate the [controller / service / migration / rule predicate] for <X>.
Include validation, error envelope, audit log call.
```

Then **review every line**. The AI will pattern-match a generic CRUD when the spec needs domain rules. Show your prompts in `TEAM.md` notes or commit messages — judges credit visibly directed workflow, not blind acceptance.

## What "good" looks like

- All Basic Gherkin scenarios passing.
- Rule engine is a unit-testable module — not buried in controllers.
- State machine is explicit (table or enum), not implicit in `if`-trees.
- API responses match `api-reference.yaml` shapes for Basic operations.
- Audit log covers every state-changing call.
- No secrets in git. `.env.example` committed.

## Common failure modes (avoid)

- **OIDC before the rule engine works.** Mock auth is fine for Basic. Don't burn 60 minutes on Auth0/Keycloak when H1–H10 aren't testable yet.
- **Inventing entities.** The spec + OpenAPI cover the model. Don't add audit-fields-as-domain-fields, soft-delete flags, or "future-proofing" tables.
- **Skipping the audit log.** Multiple Bonus axes depend on it (analytics, replay, compliance). Cheap to add early, painful to retrofit.
- **Rules in controllers.** Hard rules belong in a pure-function module that's unit-testable without HTTP. Controllers call them.
- **Ignoring the OpenAPI.** Drifting shapes break FE + QA + judging. Lock to the spec for Basic operations.
- **Bonus before Basic ≥ 90%.** Eval-runner forfeits your Bonus points. Don't.

## Links

- [`../backend/be-technical-refinement.md`](../backend/be-technical-refinement.md) — full BE refinement (architecture, rules, state machine, auth, schema, exports, NFRs).
- [`../integration/api-reference.yaml`](../integration/api-reference.yaml) — OpenAPI 3.1 contract.
- [`../integration/mock-server/`](../integration/mock-server/) — runnable reference mock (use it to unblock FE if your API isn't ready yet).
- [`../../product-spec.md`](../../product-spec.md) — behaviour spec. Read §6, §7, §9 first.
- [`../../acceptance/`](../../acceptance/) — Gherkin = judging contract.
- [`../../README.md`](../../README.md) — overall judging rubric + ground rules.
