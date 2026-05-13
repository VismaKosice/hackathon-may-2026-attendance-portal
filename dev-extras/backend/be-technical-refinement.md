# Attendance Portal — Backend Technical Refinement

**Status:** Hackathon brief — single-day build window, team sizes 2-7, senior engineers with strong AI tooling.
**Scope:** Backend only. Framework-agnostic technical requirements. Teams pick the actual stack (Node + NestJS / Fastify / Express, Python + FastAPI / Django / Flask, Go + Gin / Echo / Chi, Java/Kotlin + Spring Boot / Ktor, C# + ASP.NET Core, Rust + Actix / Axum, Ruby + Rails, …).
**Companion docs (canonical):**
- `hackathon-may-2026-attendance-portal/product-spec.md` — *read first.* Source of truth for product behaviour, hard/soft rules, state machine, quota model, approval routing, year rollover, export contract, audit log.
- `hackathon-may-2026-attendance-portal/dev-extras/frontend/fe-technical-refinement.md` — sibling FE refinement. Same tier model (Basic / Bonus).
- `hackathon-may-2026-attendance-portal/dev-extras/testing/testing-be-technical-refinement.md` — what the test suite must prove about the backend. This refinement defines **what to build**; the testing doc defines **what to prove**.
**Date:** 2026-05-12

> **This document is the source of truth for backend implementation.** It defines, framework-agnostically, what the backend service must deliver. Each section maps to an industry best practice that judges can score independently. Teams pick the stack; the topics below are how the build is evaluated.

---

## Tier mapping — what is Basic vs Bonus on the backend lane

The product spec's tier gate (Basic ≥ 90 % before any Bonus is counted) applies to backend topics too. The table below maps each section of this doc to its tier so teams do not accidentally over-invest before Basic is green.

| Section | Tier | Notes |
|---|---|---|
| §1 Application architecture + layering | **Basic** | Hexagonal / clean / DDD-lite — pick one and apply consistently. |
| §2 API design + contract-first | **Basic** | OpenAPI 3.1 or equivalent typed contract checked in. |
| §3 Domain modelling — entities + value objects + aggregates | **Basic** | Spec §2 entities are the surface. |
| §4 Rule engine (H1-H10 / S1-S6) | **Basic** | Pure functions, framework-free, exhaustive. |
| §5 Quota computed view | **Basic** | Spec §6.5 — load-bearing. No stored counters. |
| §6 State machine + transitions | **Basic** | Spec §7 transitions enforced server-side. |
| §7 Approval routing + skip-level + self-approval | **Basic** | Spec §3 + DEC-003. |
| §8 Authentication + session | **Basic** = mock-login. **Bonus** = OIDC + PKCE + refresh + IdP integration. |
| §9 Authorization + RBAC | **Basic** | Spec §3 capability matrix. Deny-by-default. |
| §10 Persistence + schema design | **Basic** | Normalised; FKs declared; indexes on hot paths. |
| §11 Migrations | **Basic** | Versioned, forward-only, repeatable from zero. |
| §12 Transactions + consistency | **Basic** | Atomic submission + audit + notification write. |
| §13 Concurrency + optimistic locking | **Basic** (ETag on mutables) — **Bonus** (full row-version + distributed locks). |
| §14 Idempotency | **Basic** | `Idempotency-Key` on non-idempotent mutations. |
| §15 Validation strategy | **Basic** | Boundary + domain + database — three layers. |
| §16 Error handling + envelope | **Basic** | One envelope shape; rule-id discriminators. |
| §17 Document storage + file handling | **Basic** | MIME sniffing, size cap, path-safe filenames. |
| §18 XLSX export pipeline | **Basic** | Spec §11.1 contract — bilingual catalogue. |
| §19 Notifications subsystem | **Basic** | Spec §10 fan-out + dedup. |
| §20 Audit log subsystem | **Basic** | Spec §11.5 — every state change writes. |
| §21 Background jobs + scheduling | **Basic** for year rollover (manual + scheduled both fire). **Bonus** for a real queue (BullMQ / Sidekiq / Celery / Hangfire). |
| §22 Configuration + secrets | **Basic** | Env-var driven; no secrets in repo. |
| §23 Logging — structured + redaction | **Basic** | One logger; PII redaction; level discipline. |
| §24 Observability — metrics, tracing, health | **Bonus** for full OTel; **Basic** = `/healthz` + `/readyz` + a request log line per request. |
| §25 Performance — caching, N+1, pagination | **Basic** | No N+1 on list endpoints; cursor pagination. |
| §26 Security hardening | **Basic** | OWASP top 10 awareness; input validation; SQL injection blocked; IDOR blocked. |
| §27 Rate limiting | **Bonus** per spec §14. |
| §28 Dependency injection + composition root | **Basic** | One wiring point; no module-level singletons. |
| §29 Code-quality rules | **Basic** | SOLID, DRY, strict types, immutability, named comments only. |
| §30 Date / time / TZ handling | **Basic** | Europe/Bratislava authoritative; DST-aware. |
| §31 Internationalisation (server-side) | **Basic** | XLSX labels + notification templates SK + EN. |
| §32 Compliance + data retention | **Basic** | Audit retention, self-service export endpoint, deletion request handling. |
| §33 Build + deploy | **Basic** | Repo builds cold with stack-conventional commands; container image builds clean. |
| §34 Local dev setup + DX | **Basic** | One-command bootstrap; deterministic seed. |
| §35 Definition of Done | **Basic** | Process gate. |
| §36 Feature flags | **Bonus** | Stretch axis. |

The **external scoring system** (per repo `README.md`) pulls each team's `main` branch on every cycle and runs lane-specific evaluation against the repo. Teams do not declare an entrypoint; the scorer uses stack-conventional build/test commands inferred from `TEAM.md` and standard manifest files. Backend lane covers: install → migrate → seed → lint → type-check → unit + integration tests → build → security scans → AI passes (architecture, DRY, security on declared high-risk paths, test quality, spec conformance). Sections §26, §33 below cover the backend side of each.

---

## 1. Application architecture — layering and module boundaries

The backend codebase is split into **layers** with one-way dependencies. Higher layers may call lower layers; never the reverse.

```
┌───────────────────────────────────────────────────────────────┐
│ Interface       HTTP handlers, RPC handlers, CLI, schedulers, │
│                  request/response DTOs, OpenAPI binding       │
├───────────────────────────────────────────────────────────────┤
│ Application      use cases, command/query handlers,           │
│                  transaction boundaries, orchestration        │
├───────────────────────────────────────────────────────────────┤
│ Domain           entities, value objects, aggregates,         │
│                  rule engine, pure business logic, ports      │
├───────────────────────────────────────────────────────────────┤
│ Infrastructure   DB adapters, file storage, email/notification │
│                  transport, IdP client, clock, RNG, queue     │
└───────────────────────────────────────────────────────────────┘
```

- **Domain is framework-agnostic.** Pure language code. No framework imports, no SQL, no HTTP, no I/O. Domain code is testable without booting the app. The rule engine (§4) and the quota computed view (§5) live here as pure functions.
- **Infrastructure adapters implement domain ports.** Domain declares interfaces (e.g. `AbsenceRepository`, `Clock`, `NotificationSink`); infrastructure provides the concrete database / clock / queue implementations.
- **Application orchestrates.** A use case loads aggregates via repositories, calls domain functions, writes results back through repositories, and emits side-effects (audit, notifications) inside a transaction (§12).
- **Interface translates.** HTTP handlers parse + validate input into command DTOs, call the use case, map results to response DTOs. No business logic in handlers.
- **Feature folders, not layer folders.** Organise by feature (`absences/`, `worktime/`, `approvals/`, `documents/`, `quotas/`, `users/`, `teams/`, `holidays/`, `reports/`, `auth/`, `admin/`), each with its own `interface/`, `application/`, `domain/`, `infrastructure/` and a public barrel.
- **File-size guideline:** > 300 lines per file or > 40 lines per function is a smell — extract.
- **Cross-feature reaching is a smell.** Shared types move to `shared/domain`; shared infrastructure helpers to `shared/infrastructure`.

## 2. API design and contract

FE and BE must not drift on payload shapes. Drift breaks the export legacy parity (spec §13.9) and the FE/BE coordination during the demo.

- **REST over HTTP** is the recommended default for hackathon scope. GraphQL or RPC are acceptable if the team has fluency; do not learn either on the day.
- **Contract-first.** OpenAPI 3.1 (or TypeSpec compiling to OpenAPI; Protobuf if RPC) checked into `packages/backend/contract/`. BE generates server stubs and FE generates client types from it. Hand-edited handler signatures without spec updates are forbidden.
- **Resource naming.** Plural nouns (`/absences`, `/worktime-entries`, `/users`, `/teams`). Verbs reserved for non-CRUD actions on a resource (`POST /absences/{id}/approve`, `POST /absences/{id}/withdraw`).
- **Versioning.** All routes under `/api/v1/`. Breaking changes bump to `/api/v2`.
- **Status codes** match HTTP semantics — 200 / 201 / 204 on success; 400 (validation), 401 (no auth), 403 (auth but forbidden), 404, 409 (conflict / state machine violation / ETag mismatch), 412 (precondition failed), 422 (semantic validation), 429 (rate-limited), 5xx (server fault). Never 200-with-error-body.
- **Error envelope.** One shape across every error response (§16).
- **Pagination.** Cursor-based on list endpoints — `?cursor=…&limit=…` returns `{ items, next_cursor }`. Offset pagination acceptable for small fixed lists (e.g. teams, holidays). Document the choice in the spec.
- **Filtering + sorting.** Declared in the spec per endpoint; never accept arbitrary client-supplied SQL or NoSQL queries.
- **Timestamps.** ISO 8601 UTC with explicit offset (`2026-05-12T08:00:00+02:00`). Calendar-day fields use `YYYY-MM-DD` with no time component.
- **Money / hours.** Hours as decimal with one digit precision (`4.5`); never a string.
- **IDs.** UUID v7 (sortable) for new resources. Never expose internal DB primary keys if they differ from the public ID.
- **ETag** on every mutable resource (§13).
- **Idempotency-Key** header accepted on every non-idempotent mutation (§14).

## 3. Domain modelling

Spec §2 entities are the surface. Pin them as **aggregates** with clear boundaries; transactions are scoped to one aggregate at a time.

- **Aggregates:** `User`, `Team`, `AbsenceEntry`, `WorktimeEntry`, `OvertimeEntry`, `Document`, `QuotaProfile`, `Holiday`, `AuditEntry`, `Notification`.
- **Value objects** (immutable, equality by value): `DateRange`, `HalfDaySlot` (Morning / Afternoon / FullDay), `Hours`, `Duration`, `ActivityCode`, `RuleId`, `UserId`, `TeamId`.
- **Identity vs equality.** Aggregates are equal by ID; value objects are equal by value.
- **Invariants enforced inside the aggregate.** An `AbsenceEntry` cannot transition `Withdrawn → Approved`; the entity's `approve()` method refuses it. Use cases call entity methods, not setters.
- **No anaemic models.** A bag of fields with a separate service mutating it is a smell. Methods live where the invariants live.
- **No DB framework annotations in domain.** Persistence concerns belong to the adapter; the domain stays pure (§1, §28).
- **Discriminated unions** for state machines: `AbsenceStatus = Draft | Pending | Approved | Rejected | Withdrawn | Cancelled`. Pattern-match exhaustively (lint rule); never a stringly-typed status.
- **Result-type pattern.** Use case methods return `Result<T, DomainError>`; exceptions are reserved for genuinely unrecoverable bugs.

## 4. Rule engine — hard and soft rules

The validation engine is the single most scrutinised piece of backend logic. Spec §9 defines H1-H10 (hard) + S1-S6 (soft).

- **Pure functions.** Each rule is a function `(submission, context) → RuleResult`. No I/O, no clock-reading inside the rule — the clock and the holiday calendar arrive as `context`.
- **One rule per file.** `domain/rules/h1-overlap.ts`, `domain/rules/h4-consecutive-sickday.ts`, … Easy to find, easy to test.
- **Engine composition.** A `ValidationEngine` runs all applicable rules over a submission and returns `{ hardErrors: RuleViolation[], softWarnings: RuleViolation[] }`. **Never throw** on a rule violation — return it.
- **Rule discriminator.** Every violation carries `ruleId` (`H1`..`H10`, `S1`..`S6`) so the FE, tests, and audit log can branch on it.
- **Localised message.** Each rule exposes a message **key** (e.g. `rules.h4.consecutive`) that the interface layer translates to SK / EN; the domain stays language-neutral.
- **Severity.** Hard rules return `severity: "hard"`; soft rules return `severity: "soft"`. Mixed-severity results are valid — the engine returns all of them so the FE can render both.
- **Deterministic order.** Rule evaluation is ordered (H1 first, H2 second, …) so test assertions and audit messages are stable across runs.
- **Re-validated at every transition.** Spec §9.3: a Pending entity is re-validated on `Approve`. The same engine runs at submit time and at approve time; no separate copy of the rules.
- **Override path.** HR overrides go through a separate `forceApprove(reason)` use case that records the override + reason in the audit log; the rule engine still runs but its hard errors are demoted to warnings in the audit entry. **Never silently bypass.**
- **Holiday calendar.** Slovak public holidays for the relevant year are seeded data (§10); the rule engine receives them via context. Year-rollover loads next year's calendar before 1 January of that year.
- **Spec-traceability.** Every rule file has a header comment linking to the spec section that defines it (e.g. `// per product-spec §9.1 H4`).

## 5. Quota computed view (spec §6.5)

This is the single most load-bearing piece of business logic. **Never store a counter that "current balance" reads from.**

- **Source of truth = events.** The current balance is *derived* from the set of `AbsenceEntry` rows in each state. There is no `vacation_balance.remaining` column anyone writes to.
- **Formula:** `remaining = allocated − reserved − used`. `reserved` = Pending working-days; `used` = Approved working-days. Withdrawn / Rejected / Cancelled entries contribute zero.
- **Single SQL view (or function)** computes the balance per (user, quota_kind, year). Implementations using a SQL view, a materialised view refreshed in the same transaction, or an in-memory recompute are all acceptable. **A persisted denormalised counter that handlers update is forbidden.**
- **Why this matters.** State transitions are racy; counters get out of sync. The computed view is correct by construction — if the entry's state changes, the next read returns the right number.
- **Consumption order.** Carry-over → statutory → bonus (spec §6.1). The view encodes this order; tests in `testing-be §7` assert it.
- **Historical reproducibility.** `balance_as_of(date_X)` replays entry states up to date_X and returns the same numbers as a live read at that moment. Useful for the audit log and for the year-rollover dry-run.
- **Realised vs planned.** `used_realised` filters `used` to entries whose dates are ≤ today (per spec §6.5 last bullet). The view exposes both.
- **Performance.** If the recompute cost is non-trivial for a dashboard load, cache it under a key that includes the user's last-changed timestamp; invalidate on every entry write. Do not let caching become a second source of truth.

## 6. State machine + transitions

Spec §7 defines the absence lifecycle: `Draft → Pending → {Approved, Rejected, Withdrawn} → {Cancelled (from Approved)}`. Sickday + PN bypass Pending.

- **State stored on the aggregate.** A discriminated-union type; no string-typed status field.
- **Transitions are methods on the aggregate.** `entry.approve(actor, clock)`, `entry.reject(reason, actor, clock)`, `entry.withdraw(actor, clock)`. Each method:
  - Asserts the current state allows the transition; returns `Result.Err(InvalidTransition)` otherwise.
  - Re-runs the rule engine where spec §9.3 requires it.
  - Writes the new state.
  - Emits a `DomainEvent` carrying the before/after snapshot for audit + notification fan-out (§19, §20).
- **Terminal states.** `Withdrawn`, `Rejected`, `Cancelled` accept no further transitions. A second `approve()` on an already-Approved entry returns `409`.
- **Sickday + PN bypass.** Submission writes directly to Approved. Sickday and PN entries never have a Pending state.
- **Cancellation window.** Spec §7: Cancel on day-before → succeeds; Cancel on event-day → 409 with HR routing. The aggregate's `cancel()` consults the injected clock and gates accordingly.
- **Rejection reason.** Required at the API boundary and on the domain method. Empty / whitespace-only reasons are validation errors.
- **Audit on every transition.** The aggregate emits a `DomainEvent`; the application layer writes the audit entry in the same transaction (§20).

## 7. Approval routing — skip-level + self-approval guard (DEC-003)

Spec §3 + DEC-003 codify the routing tree.

- **Default routing.** `route(submission)` returns the `direct_manager_id` of the submitter.
- **Skip-level filter.** Any ancestor manager can open a queue filter "I can approve via chain" and see descendant requests. The application layer computes the ancestor chain via a recursive query (PostgreSQL `WITH RECURSIVE`, MySQL `WITH RECURSIVE`, neo4j-style traversal, in-memory for small org trees).
- **Self-approval guard.** If `submitter_id == direct_manager_id` (a manager submitting their own request), the routing walks up to the first non-self ancestor. Multi-step walks handled (LeadA1 → DeptHeadA → CEO).
- **Chain exhausted → HR group.** A user with no manager (or whose entire chain is unavailable) routes to every HR-role user. Notification fan-out (§19) handles the multiplexing.
- **Cycle protection.** Admin endpoints that set `direct_manager_id` must validate the tree is still acyclic. Reject the change with `400` and an explicit message ("This would create a cycle: A → B → A").
- **Routing is computed at submit time, not stored on the entity.** Tomorrow's org change should not redirect today's already-submitted request; instead, the audit log records the actor at decision time.

## 8. Authentication + session

> **Tier note (DEC-005).** **Basic = mock-login** — a user-picker endpoint bound to seeded fixture users; no password. The full OIDC path below is the **Bonus** real-auth path.

### Basic — mock-login

- `POST /api/v1/auth/mock-login { user_id }` issues a short-lived session token. The endpoint exists only when `AUTH_MODE=mock` is set; the production build refuses to start with `AUTH_MODE=mock`.
- Session token is a signed opaque value (HS256 JWT or random bytes + server-side session table). 12 h lifetime.
- The token is returned in the response body for the FE to store in `sessionStorage` (FE refinement §8).

### Bonus — OIDC

- **Protocol.** OIDC Authorization Code + PKCE. No implicit, no resource-owner-password.
- **Provider.** Auth0, Keycloak, Microsoft, Google, or a mock issuer for the demo. Pin the issuer URL in env var.
- **Token verification.** Verify the ID token's signature against the IdP's JWKS, validate `iss`, `aud`, `exp`, `nbf`, `nonce`. Cache JWKS with TTL.
- **Token storage.** The FE keeps the access token; the BE is stateless (per request, verify the bearer). Server-side session table optional.
- **Idle + hard expiry.** 30 min idle, 12 h hard expiry (matches FE refinement §8).
- **Refresh.** Server endpoint `/api/v1/auth/refresh` validates the refresh token (if used) and issues a new access token. Refresh tokens stored server-side with rotation; revoke previous on issue.
- **Logout.** Endpoint clears server-side session + revokes refresh token + posts to IdP end-session.

### Common

- **Session middleware.** One middleware injects `currentUser: { id, roles[] }` into the request context. All route handlers consume it; no handler reads the raw token.
- **No password storage** in Basic. Bonus password path uses bcrypt cost ≥ 12; never sha256 / md5 / plaintext.
- **Multi-factor** out of scope for v1; stretch.
- **Session pinning prevention.** Rotate the session token on every privilege change.

## 9. Authorization — RBAC

Spec §3 defines roles (Employee, Manager, HR, Admin) and capabilities. Authorisation is **deny by default**.

- **Role declared per route.** Every handler declares its required role(s) at registration time (decorator, middleware, route metadata). Routes without an explicit declaration are rejected at boot.
- **Capability matrix.** Spec §3 is the test surface; testing-be §13 asserts the matrix. Capabilities live in `domain/authorization/` as pure predicates: `canApprove(actor, target)`, `canReadAbsence(actor, target)`, `canExportMonthly(actor)`.
- **Predicate-based not role-based at fine grain.** "Manager can approve absences" is too coarse — what the predicate actually says is *"actor.roles.includes('manager') AND target.submitter_id is in actor's subordinate chain"*. Predicates compose; flat role checks do not.
- **Skip-level approval** is its own predicate (`canSkipLevelApprove`), tested separately.
- **IDOR prevention.** Every fetch-by-id route validates the actor is permitted to see *that specific* resource. Sequential ID guessing returns `403` (or `404` if leakage of existence is also a concern).
- **HR / Admin override.** Privileged actions go through `forceX(reason)` methods that record the override; the predicate distinguishes regular Approve from HR override.
- **Privilege-elevation prevention** is out of MVP scope per spec §13 note — judges will not assess the Admin-protection surface for Basic. Bonus only.
- **Audit log read restriction.** Employee + Manager → `403` on `/api/v1/audit-log/*` routes.

## 10. Persistence + schema design

- **Pick one storage.** PostgreSQL is the recommended default for relational + JSON flexibility + recursive queries (needed for §7 chain walk). MySQL, SQLite, MariaDB acceptable. NoSQL (Mongo, DynamoDB) acceptable only if the team has fluency — the relational constraints are non-trivial and an RDBMS is easier within a single-day window.
- **Schema is normalised.** Third-normal-form unless an explicit denormalisation is documented with a reason.
- **Required foreign keys.** Every relationship has a real FK with `ON DELETE` policy declared (restrict / cascade). No "soft" relations via untyped strings.
- **Indexes on hot paths.**
  - `absence_entry (user_id, status, start_date)` — dashboard + queue.
  - `absence_entry (status, manager_id_chain[])` — manager queue.
  - `worktime_entry (user_id, date)` — H1 overlap check.
  - `audit_entry (actor_id, created_at desc)` — audit screen.
  - `notification (recipient_id, read, created_at desc)` — inbox.
- **Constraints declared at the DB.** Not-null where the domain says so; check constraints for enums (`status IN ('draft','pending',...)`); range constraints on hours / decimal columns.
- **No `text` columns where `varchar(N)` fits.** Discourages garbage-in.
- **Timestamps on every row.** `created_at`, `updated_at`, `created_by`, `updated_by` are non-negotiable.
- **Soft delete vs hard delete.** Documents, audit entries, completed absences are hard data — never soft-delete to keep regulatory records intact. Soft-delete reserved for users (deactivation) and teams (archival).
- **JSONB for genuinely variable shapes** (audit entry before/after snapshots, notification payloads). Indexed where queried.
- **Schema diagram** committed to the repo (`packages/backend/docs/schema.png` or `.dbml` / `.mermaid`). One file, regenerated from the migrations.

## 11. Migrations

- **Versioned.** Every schema change is a numbered migration file (`0001_init.sql`, `0002_add_quota_profile.sql`). Hand-rolled SQL or tool-managed (Flyway, Liquibase, Alembic, Prisma, Knex, golang-migrate, ActiveRecord, EF Core).
- **Forward-only.** No `down` migration in production paths. Roll forward with a new migration if needed.
- **Repeatable from zero.** A fresh database to fully-migrated must be a single command (`make migrate`, `npm run migrate`, equivalent). The scoring system invokes this before tests.
- **Idempotent.** Running migrations twice is a no-op.
- **No data mutations in schema migrations.** Data backfills are separate, idempotent, restartable.
- **CI gate.** Every PR runs migrations on a fresh DB; failure fails the build.
- **Naming.** `NNNN_verb_noun.sql` — `0007_add_absence_index_user_status_start.sql`. Reviewer-friendly.

## 12. Transactions + consistency

Every state-changing endpoint must either fully commit or fully roll back. **Audit entries and notification records are part of the same transaction as the entity write.**

- **One transaction per use case.** Application layer opens the transaction at the start of `execute()` and commits at the end. Handlers and adapters do not start transactions on their own.
- **Atomic submission.** Submit + audit-write + notification-record-write are in one transaction. If notification fan-out fails, the absence is not written.
- **Outbox pattern for external side-effects.** If the team integrates a real email provider or external queue, write the message to an `outbox` table inside the same transaction; a separate worker drains it. This is **Bonus**; for Basic, in-process notification records are sufficient (FE polls the notification feed).
- **Isolation level.** Read-committed at minimum. Repeatable-read or serializable on the quota recompute path to prevent phantom reads.
- **Locking.** Take a row lock on the `User` aggregate when computing quota + writing an absence to serialise that user's submissions. `SELECT ... FOR UPDATE` is the standard idiom.
- **No long-running transactions.** Background work runs outside request-bound transactions.
- **Connection pooling.** A single pool, sized per CPU count. No leaked connections — verified by a teardown assertion in tests (testing-be §14).

## 13. Concurrency + optimistic locking

Two managers may approve the same request; HR may cancel what the employee has just withdrawn. The BE must handle these without losing data or showing stale truth.

- **ETag header** on every GET of a mutable resource. Value is a strong hash over the resource's mutable fields + `version` column or `updated_at`.
- **`If-Match` header** required on every PUT / PATCH / DELETE. Server compares; mismatch returns `412 Precondition Failed`.
- **`409 Conflict` on state-machine violation** (e.g. double-approve, withdraw after rejection). Distinct from `412`.
- **Version column** on every mutable row, incremented on each write.
- **Lost-update prevention.** Without ETag/`If-Match`, last-write-wins. That's acceptable for self-owned drafts; **forbidden** for approvals, decisions, document validation, quota changes (testing-be §15).
- **Distributed locks** (Redis SETNX / DB advisory lock) only for genuinely cross-process race conditions — the year-rollover apply step is the canonical case. **Bonus** for hackathon scope.
- **Cancel-vs-reject race.** Both transitions arrive simultaneously → both resolve to the same terminal state; the entity stops contributing to `used` exactly once (computed view, §5). Tests in testing-be §15 assert this.

## 14. Idempotency

State-changing requests must be safely retriable.

- **`Idempotency-Key` header** on every non-idempotent mutation (POST / DELETE without an `If-Match`). Server caches the response keyed by `(actor_id, idempotency_key)` for at least 24 h.
- **On replay**, return the cached response without re-executing the use case.
- **Storage.** An `idempotency_record` table or Redis with TTL. Tied to the actor — different users with the same key do not collide.
- **GET / HEAD / OPTIONS** are inherently idempotent — no key needed.
- **PUT / PATCH / DELETE with `If-Match`** are conditionally idempotent — the ETag provides equivalence — no key needed.
- **Year-rollover apply** uses idempotency at the job level: a `rollover_run (year_from, year_to)` row is the natural key; a second invocation is a no-op (testing-be §10).

## 15. Validation strategy

Three layers, in order of cost.

- **Boundary validation** (cheap, fast). Request DTO shape is validated by a schema validator (Zod, Yup, Joi, class-validator, Pydantic, validator.v10, FluentValidation). Types, ranges, lengths, enum membership. Rejected requests return `400` with the validator's report.
- **Domain validation** (the rule engine, §4). Business rules. Returns `Result` not exceptions.
- **Database validation** (last line of defence). NOT NULL, CHECK constraints, FKs. A request that gets past boundary + domain but fails the DB constraint is a programming bug, not a user error — log as `error`, return `500`.
- **No string-typed coercion at the boundary.** Dates parse to date objects; numbers parse to numbers. Stringly-typed handlers leak into the domain.
- **Schema and DTO live next to the contract** (§2). Regenerate from OpenAPI where possible.

## 16. Error handling + envelope

One envelope shape across every error response. Inconsistent shapes break the FE's error UX (FE refinement §14).

```json
{
  "errors": [
    {
      "ruleId": "H4",
      "field": "date",
      "message": "Consecutive sickdays are not allowed. Consider PN.",
      "severity": "hard",
      "i18nKey": "rules.h4.consecutive"
    }
  ],
  "trace_id": "01F8MECHZX3TBDSZ7XR8RGRP4F"
}
```

- **`errors` is an array** even for single errors. The FE renders a summary based on the count.
- **`trace_id`** propagates the request's trace id (§24) so the user can quote it in a support request.
- **No stack traces in responses.** Ever. Logged server-side, never leaked.
- **No internal field names in messages.** "Date is invalid" — not "absence_entry.start_date violates h4_predicate".
- **`i18nKey`** lets the FE render the localised message; `message` is the server's default (SK).
- **Unexpected errors** map to `500` with envelope `{ errors: [{ message: "Internal server error", trace_id }] }`. The real error is logged.
- **Validation errors group by field** where possible. Multiple errors per field is fine.

## 17. Document storage + file handling

Documents back Paragraph / OCR / Special-leave entries (spec §8).

- **Storage backend.** S3-compatible (MinIO local, AWS S3 production), or a filesystem under a configurable root. Stream uploads — never load full files into memory.
- **Server is source of truth for MIME and size.** Sniff magic bytes; do not trust client-provided `Content-Type` or file extension.
- **Accepted MIME types.** `application/pdf`, `image/jpeg`, `image/png`, `image/heic`. Reject `text/plain`, `image/svg+xml` (XSS vector), `application/octet-stream`.
- **Size cap.** 10 MB per file (configurable). Enforced via streaming counter; do not buffer to check size.
- **Path-safe filenames.** Store under a generated UUID; never reuse the user's filename for the storage path. Original filename retained as metadata.
- **No path traversal.** `..`, `/`, `\` rejected.
- **Anti-virus** out of scope for Basic; **Bonus**: integrate ClamAV scan-on-upload.
- **Per-document access control.** Only the submitter, the manager in the chain, HR, and Admin can fetch a document. Pre-signed URLs scoped per request; never permanent public URLs.
- **Audit on every fetch.** Spec §11.5 requires document-fetch logging.
- **Retention.** Documents are kept for the legal retention period (Slovak labour law — minimum 5 years); deletion goes through the §32 deletion flow.

## 18. XLSX export pipeline (spec §11.1)

- **Streaming generation.** A team of 50 over a full month generates ~3000 rows. Stream rows to the workbook writer; do not build the file in memory.
- **Library choice.** `exceljs` (Node), `openpyxl` (Python streaming), `xlsx` (Java/POI), `EPPlus` (.NET), `excelize` (Go). Pin the version.
- **Two sheets** named per locale: SK = `Dochádzka` + `Nadčas`; EN = `Attendance` + `Overtime`.
- **First row + first column frozen.**
- **One row per half-day for the entire calendar month**, including weekends and holidays.
- **Activity-label catalogue** (spec §11.1) — server-side i18n table maps state + half-day-context to label. Tests in testing-be §11 enumerate every catalogue value.
- **Half-day split.** Morning Paragraph + afternoon work on the same date produces two adjacent rows (Doobedu / Poobede in SK; AM / PM in EN).
- **Decimal separator.** `,` for SK locale, `.` for EN locale. Locale-aware cell formatting; never string concatenation.
- **CSV companion** with header `date,half,full_name,activity,time_range,hours`; two rows per employee per calendar day (spec §11.1).
- **Authorisation.** HR + Admin only; Employee + Manager → `403`.
- **Audit.** Every export records actor, timestamp, scope, IP.
- **Filename.** `attendance-{yyyy}-{mm}-{teamSlug-or-all}-{lang}.xlsx` (matches FE refinement §28).
- **No PII in URL.** `team_id`, `year`, `month`, `lang` query params only.
- **Caching.** No HTTP cache headers — sensitive content.
- **Performance.** Test under the testing-be §16 fixture (500 employees × 12 months) and assert the export streams in < 5 s.

## 19. Notifications subsystem

Spec §10 defines the events + recipients matrix.

- **Event-driven.** Each domain event (`AbsenceSubmitted`, `AbsenceApproved`, `AbsenceRejected`, `DocumentValidated`, `RolloverApplied`, ...) emits a notification record per recipient determined by the spec §10 matrix.
- **Recipient resolution** happens inside the application layer, in the same transaction as the entity write. Tests in testing-be §12 assert dedup + side-effects.
- **Dedup.** A recipient appearing in multiple groups for the same event receives exactly one record. Dedup key = `(event_id, recipient_id)`.
- **No double-send** on idempotent re-submission (§14).
- **Notification persisted to a `notification` table.** Fields: `id`, `recipient_id`, `kind`, `payload (jsonb)`, `created_at`, `read_at`, `source_entity_id`, `source_entity_kind`.
- **FE reads the inbox** via polling (FE refinement §7). No push channel required for Basic.
- **Email channel** is **Bonus** per the spec — same event fan-out, plus an `outbox` row (§12) drained by a worker.
- **No PII in the payload beyond what the recipient is permitted to see.** A manager's notification about an employee's PN includes "employee X is on PN until Y" — never the underlying medical document.
- **Localised at render time.** The notification record stores an `i18nKey` + `params`; the FE renders in the active locale. Avoid baking server-locale text into the payload.

## 20. Audit log subsystem

Spec §11.5 mandates an audit trail.

- **Append-only.** No row is ever updated or deleted. A schema constraint or trigger enforces this.
- **Every state-changing transition writes one entry**, in the same transaction (§12).
- **Fields:** `id`, `created_at`, `actor_id`, `actor_type` (`user`, `system`, `skip-level`, `hr-override`), `entity_kind`, `entity_id`, `event_kind`, `before` (jsonb), `after` (jsonb), `reason`, `request_id`.
- **`before`/`after` snapshots** capture the fields that changed. Full-document snapshots are wasteful; one diff per field is cleaner.
- **Retention.** Audit log is retained per spec §11.5; never truncated outside an explicit, audited admin action.
- **Read endpoint.** HR + Admin only (§9). Pagination + filters: actor, entity, date range, event kind.
- **Tamper-evidence (Bonus).** Hash-chain: each row stores `prev_hash`, `row_hash`. Tampering is detectable. Skip for Basic.
- **No PII redaction at write time.** The audit log is the legal record; redaction happens at export time if needed.

## 21. Background jobs + scheduling

Year rollover is the canonical case. Spec §6.3 defines the worked examples.

- **Year-rollover job.** Two modes: dry-run (preview output, no DB writes) and apply (writes). Idempotent — running twice for the same `(year_from, year_to)` is a no-op (testing-be §10).
- **Scheduler.** A cron-style schedule (e.g. `0 2 1 1 *` — 02:00 on 1 January) fires the apply mode automatically. HR + Admin can trigger manually from the UI.
- **Output.** Per-employee summary on the notification feed + per-user audit entry with before/after balances.
- **Manual trigger requires confirmation** (FE handles the dialog; BE expects an explicit `confirm: true` body).
- **Job logging.** Job runs are recorded in a `job_run` table with start/end timestamps, status, summary stats. Visible to Admin.
- **Failure handling.** On error, the job rolls back the transaction and records the failure. Partial runs are forbidden — all-or-nothing.
- **Real queue (Bonus).** BullMQ / Sidekiq / Celery / Hangfire if the team has fluency. For Basic, an in-process scheduler firing at startup + on cron tick is sufficient.

## 22. Configuration + secrets

- **Env-var driven.** `DATABASE_URL`, `AUTH_MODE`, `STORAGE_BACKEND`, `STORAGE_ROOT`, `JWT_SECRET`, `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `EMAIL_OUTBOX_ENABLED`, … Every variable documented in `.env.example`.
- **No secrets in repo.** `.env` is `.gitignore`d. `gitleaks` runs in CI and on the scoring system.
- **Twelve-factor config.** Code in one repo, config in env. No hardcoded `localhost`, no hardcoded ports.
- **Config validation on boot.** Boot fails fast if a required variable is missing or malformed. No silent defaults for security-sensitive values.
- **Different environments = different env files.** `.env.local`, `.env.test`, `.env.production`. Never copy production values into a dev file.

## 23. Logging — structured, level discipline, redaction

- **One logger module.** `shared/logging/`. The rest of the codebase imports it; nobody calls `console.log` / `print` / `fmt.Println` directly. A lint rule enforces this.
- **Levels.** `debug`, `info`, `warn`, `error`. `debug` stripped in production.
- **Structured payload.** `log.info('absence.submitted', { absenceId, type, userId, durationMs })`. Discoverable event names; rich data in the second argument as an object.
- **One log line per request.** `info` level at handler exit with method, path, status, duration, user-id, trace-id.
- **PII redaction.** Filter keys named `token`, `password`, `secret`, `authorization`, `cookie`, `ssn`, `email`, `full_name` before printing or shipping to telemetry. Configurable allowlist.
- **No PII in error payloads** — only user IDs + entity IDs. Names, document content, medical detail never appear in logs.
- **JSON-structured output** in production; pretty-printed in dev.
- **Correlation id.** Every log line carries the trace-id (§24).
- **Error logging.** Full stack + `cause` chain preserved. Exception objects are not stringified to a single line.

## 24. Observability — metrics, tracing, health

- **`/healthz`** (basic) — process is alive; returns `200`. No dependency checks.
- **`/readyz`** (basic) — dependencies reachable (DB, storage, IdP if Bonus). Returns `200` only when the service can take traffic.
- **Trace-id per request.** Generated at the entry edge (or extracted from `traceparent` header), propagated through the application context, included in every log line and every error response.
- **Request metrics** (Bonus) — counter + histogram per route. Prometheus exposition at `/metrics` with `process_*`, `http_request_duration_seconds`, `http_requests_total{route,status}`.
- **Domain metrics** (Bonus) — counters for `absence.submitted`, `absence.approved`, `notification.sent`, etc. Useful for the scoring system's spec-conformance pass.
- **OpenTelemetry (Bonus)** — spans across handler → use case → repository. Worth it only if the team has the SDK ready.
- **No external telemetry by default.** All metrics scraped or pulled; no third-party APM tied to a SaaS in Basic.
- **Log shipping** out of scope for the hackathon.

## 25. Performance — caching, N+1, pagination

- **No N+1 on list endpoints.** The dashboard renders 30 days × team-size × multiple kinds. Eager-load with explicit joins / batched queries; never iterate-and-fetch.
- **EXPLAIN every list query** during development. Index hits visible.
- **Cursor pagination on every list.** Stable across writes; no skipped or duplicated rows under concurrent inserts.
- **List response size cap.** Default `limit=50`, max `200`. Server enforces; ignores larger values.
- **Caching is opt-in, not default.** The quota computed view (§5) may be cached per-user with an invalidate-on-write key. Notification inbox, audit log, balances dashboard — uncached for Basic.
- **HTTP `Cache-Control: no-store`** on all authenticated endpoints by default. Cache headers added explicitly per route if there's a reason.
- **GZIP / Brotli** response compression at the edge (reverse proxy or framework). Not strictly required but cheap.
- **Connection pool tuning.** Pool size ≥ CPU × 2 for a relational DB; monitored via `/readyz`.
- **Budget assertions in tests** (Bonus) — testing-be §16 names the targets (export < 5 s, calendar grid < 500 ms, approvals queue < 200 ms).

## 26. Security hardening

OWASP Top 10 awareness is a Basic expectation; specific controls follow.

### 26.1 Authn + authz (covered in §8, §9)

- Mock-login `AUTH_MODE` flag refuses to enable in production.
- Bcrypt cost ≥ 12 if passwords ever land in scope.
- RBAC deny-by-default per route.
- IDOR-prevention per fetch-by-id route.

### 26.2 Injection — SQL, NoSQL, command, LDAP

- **Parameterised queries** everywhere. No string-concat SQL. ORMs handle this; raw SQL adapters must use placeholders.
- **No `exec` / `system` / `shell_exec` calls on user input.** If shell-out is unavoidable, use `execFile` with array args, never `exec` with a single string.
- **No `eval`** in the language's standard library.

### 26.3 Input validation + output encoding

- Boundary validation per §15.
- Server-side rendering (XLSX cell values, notification message bodies) escapes special characters.
- HTTP response headers never reflect user input verbatim.

### 26.4 Cross-site

- **CSRF.** If session cookies are used, set `SameSite=Strict` + double-submit token. Bearer-token APIs (the recommended default) are immune.
- **CORS.** Origin allowlist hardcoded per environment; never `*` for authenticated routes.
- **CSP, HSTS, X-Content-Type-Options, Referrer-Policy** — set at the reverse proxy / framework middleware. Matches FE refinement §17.

### 26.5 File upload (covered in §17)

- MIME sniffing.
- Size cap.
- Path-safe filenames.
- No execution of uploaded files.

### 26.6 Cryptography

- **Hashing.** SHA-256 for non-secret hashes; bcrypt / argon2 for passwords; HS256 / RS256 for JWTs.
- **Random.** Cryptographically-secure RNG (`crypto.randomUUID`, `secrets`, `crypto/rand`). Never `Math.random()` / `rand()` for tokens.
- **No custom crypto.** Use the standard library or a vetted package.

### 26.7 Secrets

- Never logged.
- Never returned in API responses.
- Rotated via env var; redeploy required.

### 26.8 Static analysis on the scoring system

- `gitleaks` — no committed secrets.
- `trivy fs` — no known-vulnerable dependencies.
- `semgrep --config=auto` + hackathon ruleset — common patterns.
- AI security pass on declared high-risk paths (auth flow, file upload, document preview, export endpoint, anywhere user-supplied notes are persisted-and-rendered).

## 27. Rate limiting (Bonus, spec §14)

- **Per-actor + per-route.** Token-bucket or sliding-window. 60 req/min default; 10 req/min on auth endpoints; 5 req/min on export.
- **Headers.** Respond with `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`. On breach, `429` + `Retry-After`.
- **Storage.** In-memory for single-node; Redis for multi-node.
- **Exempt** the health endpoints + readiness probes.

## 28. Dependency injection + composition root

The layering in §1 makes use cases easy to test and easy to swap. DI is the mechanism.

- **Domain declares ports.** TypeScript interfaces / abstract classes / Go interfaces / Python protocols. Examples:
  ```ts
  export interface AbsenceRepository {
    save(entry: AbsenceEntry): Promise<Result<void, RepoError>>;
    findById(id: AbsenceId): Promise<Result<AbsenceEntry, RepoError>>;
    listForManager(managerId: UserId, filter: QueueFilter): Promise<AbsenceEntry[]>;
  }
  export interface Clock { now(): Instant; today(): LocalDate; }
  export interface NotificationSink { fanOut(event: DomainEvent): Promise<void>; }
  ```
- **Infrastructure provides adapters** implementing those ports.
- **Use cases depend on the port, not the adapter.** No `new PostgresAbsenceRepository()` inside a use case.
- **One composition root.** `main.ts` / `wire.go` / `composition.py` / `Program.cs` constructs the dependency graph at startup. Different roots for production, test, and seed.
- **Forbidden patterns.** Module-level singletons (created at import time, untestable). Service locators / global registries. Static imports of infrastructure from domain. A lint rule enforces the last one.
- **Allowed DI styles.** Manual constructor injection (recommended for hackathon). Framework-native (NestJS DI, Spring, ASP.NET Core DI, Wire for Go). Container libraries (tsyringe, Inversify) only if the team has fluency.
- **What gets injected vs imported.** Injected: anything touching the outside world (HTTP, DB, storage, telemetry, clock, RNG, queue). Imported: pure functions (formatters, validators, the rule engine itself).

## 29. Code-quality rules

Non-negotiable; enforced by linter + reviewer.

- **SOLID.** Single responsibility per module. Open-closed via composition. Liskov-substitutable adapters. Interface segregation — small ports beat god services. Dependency inversion per §28.
- **DRY — rule of three.** Two similar pieces stay duplicated; three is the signal to extract. Premature abstractions are worse than duplication.
- **Naming.** Intention-revealing variables. Booleans start with `is`/`has`/`can`/`should`. No single-letter names outside short scopes. Domain abbreviations (`PN`, `OCR`, `HR`, `BT`) are fine; everything else spelled out.
- **Immutability + purity.** Domain logic is pure. Treat data as immutable at the boundary. No module-level mutable state outside the composition root.
- **Type safety.** Strict mode on; `noUncheckedIndexedAccess`; no `any` outside an explicit comment with a ticket; no `as` casts outside boundary code paired with a runtime validator.
- **Discriminated unions** for state machines. Exhaustive switch enforced by lint.
- **Errors are values** in the domain (Result type). Exceptions reserved for genuinely unrecoverable bugs.
- **Comments.** Default to none. Allowed: WHY notes (workarounds, invariants, spec references). Forbidden: WHAT narration, commented-out code, "added by X" history.
- **Linting + formatting.** Framework's recommended set + the team's lint additions. Auto-format on save. Pre-commit hook runs format + lint + type-check.

## 30. Date / time / timezone handling

Attendance is timezone-sensitive — a "Monday sickday" must mean the same Monday for everyone regardless of where they open the portal. Mishandling this is the single highest source of subtle attendance bugs.

- **Authoritative timezone.** `Europe/Bratislava`. Calendar boundaries (what counts as "today", when a sickday switches to the next day, when the year-rollover job runs) computed in this zone.
- **Storage.** Timestamps in UTC with offset (ISO 8601). Calendar-day fields as `YYYY-MM-DD`.
- **TZ-aware library.** `Temporal` (Node 22+), Luxon, date-fns-tz, Java `java.time`, Python `zoneinfo`, Go `time.LoadLocation`. Never `new Date()` arithmetic across zones.
- **DST handling.** Slovakia observes daylight saving. Half-day windows are wall-clock in Bratislava (07:00-12:00, 12:30-17:00 — or per DEC-033 resolution; see §31 below). Spring-forward and fall-back days have a regression test (testing-be §19).
- **Injected clock.** Domain code consumes the `Clock` port (§28). Test composition root injects a controllable clock.
- **Year boundary.** A sickday submitted on 2 January but dated 31 December counts against the previous year (spec §6.2). The application layer evaluates "current year" via the injected clock + the entity's event date, not the request timestamp.
- **No client-clock trust.** Server clock is authoritative for all security decisions and quota arithmetic. Request timestamps from clients are advisory only.

## 31. Internationalisation (server-side)

Server emits some user-facing text: notification messages, XLSX export labels, document-decision reasons, audit-log event labels.

- **Catalogue.** Flat key-value JSON per locale, namespaced by feature. Mirrors the FE catalogue (FE refinement §6) — many keys can be shared verbatim.
- **Source of truth = Slovak (`sk-SK`).** English (`en-GB`) is the first Bonus locale.
- **Format.** ICU MessageFormat for pluralisation; `{count, plural, one {# day} other {# days}}`.
- **What is translated.** Notification message bodies, document-decision reasons (predefined codes), XLSX export labels, validation message keys (the FE renders, but the server can also format for non-FE consumers like email).
- **What is NOT translated.** Free-text user input (notes, reasons), employee names, file names.
- **Fallback.** Missing key in active locale → fall back to SK → fall back to the raw key. Server logs a `warn` on fallback.
- **Resolution.** The active locale is on the user's profile; the application layer passes it into the rendering function. Never derive from `Accept-Language` for an authenticated request — profile wins.

## 32. Compliance + data retention

GDPR applies. Slovak labour law mandates retention of attendance records for a specific period (currently 5 years; verify with HR / legal).

- **Retention policy.** Audit log, document storage, completed absence entries retained per legal minimum. Configurable per category in admin settings.
- **Self-service data export.** `GET /api/v1/me/data-export` returns the requesting user's data as a downloadable JSON archive (absences, worktime, balances, documents metadata, audit entries referencing them). Spec's GDPR "data portability" right.
- **Account deletion request.** `POST /api/v1/me/deletion-request` opens an internal ticket / notification to HR. The portal does NOT delete unilaterally because of retention law; HR processes within the legal framework.
- **Hard-delete pathway.** When HR confirms deletion (after the retention window expires), a job hard-deletes the user's PII while keeping anonymised audit references intact (`actor_id → 'deleted-user-{hash}'`).
- **Privacy notice.** First-login privacy notice version + consent timestamp stored on the user record (FE refinement §38). The BE enforces re-prompt when the version hash changes.
- **No third-party data export.** The portal never transmits PII to external SaaS.
- **Data minimisation.** Notification payloads and log lines per §19, §23 — only what the recipient is permitted to see.

## 33. Build + deploy

> **Tier note.** The external scoring system (per repo `README.md`) pulls each team's `main` branch and runs lane-specific evaluation. No special entrypoint — stack-conventional commands are used (`npm test`, `pytest`, `go test ./...`, etc.). `TEAM.md` declares team + members + stack; the scorer infers the rest from standard manifest files.

- **Single-container deploy.** A Dockerfile that builds, runs migrations on startup, exposes one port. Multi-stage build keeps the runtime image small.
- **`docker-compose.yml`** wires the BE + DB + storage (MinIO if S3) + optional Redis. `docker compose up` boots the full stack.
- **Stack-conventional build/test commands.** Repo builds and tests must run with idiomatic commands for the chosen stack (`npm install && npm test`, `pip install -r requirements.txt && pytest`, `mvn verify`, `cargo test`, etc.). Document them in `README.md`.
- **`TEAM.md` at repo root** (per repo `README.md` *TEAM.md — team manifest*) declares team, members (email matching git commits), stack. High-risk paths and intentional scope cuts go in the free-form notes body — the scorer reads them.
- **Environment hardening.** Production container runs as a non-root user. No shell in the image where possible (distroless / alpine). `HEALTHCHECK` instruction wired to `/healthz`.
- **Build reproducibility.** Pin language + framework + dependency versions. Lockfile committed.
- **No build-time secrets.** Secrets injected at run time via env vars (§22).
- **CI pipeline (per PR).** Lint → type-check → unit tests → integration tests → migrations on fresh DB → security scans → container image build → smoke test against the container.

## 34. Local dev setup + DX

Goal: a new contributor clones, runs one command, has a working portal.

- **One-command bootstrap.** `make setup` (or `npm run setup` / `./scripts/setup.sh`). Copies `.env.example` to `.env`, runs `docker compose up -d` for dependencies, runs migrations, runs seed, verifies the API responds.
- **Language version pinned.** `.tool-versions` / `.nvmrc` / `.python-version` / `go.mod` toolchain / `Cargo.toml` rust-version. Same version used in CI + scoring system.
- **Single-command server start.** `make dev` runs the BE + mocks the email outbox + tails logs.
- **Deterministic seed.** Same input → same UUIDs, same orderings. Fixed RNG seed.
- **Seed fixtures cover** the spec §13 MVP acceptance + the testing-be §18 fixture set: org tree of depth ≥ 3, ≥ 2 teams, ≥ 1 HR, ≥ 1 Admin, multiple Employees + Managers, 2026 Slovak public holidays, end-of-2026 states for Anna / Peter / Mária worked examples.
- **No real PII** in fixtures. `@example.test` emails, fictional names.
- **`.env.example` committed.** Every env var the app reads has a placeholder + one-line description.
- **`README.md` ≤ 1 page** at repo root: prerequisites, setup, dev commands, test commands, deployment. Longer docs link out.

## 35. Definition of Done

Every PR must satisfy all of these before merge.

- [ ] Behaviour matches a referenced product-spec / BE-tech-doc requirement (link the section).
- [ ] Types pass strict-mode check; no new `any` / `@ts-expect-error` without a linked ticket.
- [ ] Unit + integration tests added or updated; all green; `make test` runs headless.
- [ ] OpenAPI spec updated alongside any new / changed route.
- [ ] Migrations included for any schema change; `make migrate` from a fresh DB succeeds.
- [ ] Seed data covers the new path.
- [ ] Audit log entry written for any new state-changing action.
- [ ] Notification fan-out covered for any new state-changing action (where spec §10 says so).
- [ ] No new direct calls to infrastructure from domain (§1, §28).
- [ ] No new module-level singletons (§28).
- [ ] No `console.*` / `print` outside `shared/logging/` and tests (§23).
- [ ] PII not added to log payloads or error responses.
- [ ] `gitleaks` + `semgrep` clean on the diff.
- [ ] Author ran the affected smoke flow locally before requesting review.
- [ ] Reviewer signed off after walking the diff and the linked requirement.

## 36. Feature flags (Bonus)

Stretch goals (real auth, real email, websocket push, rate limiting, tamper-evident audit log) toggle on and off without redeploy.

- **Server-driven flag service** is the source of truth. The BE reads its own flags on startup + on focus / on a refresh hook.
- **Flag shape.** `{ key, enabled, audience?: { roles?, userIds?, teams? } }`. Audience filtering happens server-side.
- **Reading flags.** A `FeatureFlag` port injected per use case; defaults `false` on unknown.
- **Kill switch.** Every flag has an "emergency off" lever that HR / Admin can flip from the admin UI.
- **Flag lifecycle.** Flags created with a removal date in the description. Stale flags ≥ 90 days reviewed.
- **No env-var flags for runtime behaviour.** Env vars are build-time config only.

---

## Suggested team allocation for BE work

Senior + AI-assisted teams parallelise wider than the conservative split below.

If a team allocates **3-4 people** to backend:

- **1** — Domain core: entities, rule engine, quota computed view, state machine, approval routing.
- **1** — API layer: OpenAPI spec, handlers, validation, error envelope, authorisation.
- **1** — Persistence + migrations + seed + transactions + audit + notifications.
- **1** — Document storage + XLSX export pipeline + year-rollover job + scoring system wiring.

If a team allocates **2 people** to backend: prioritise domain core + API layer + persistence; defer XLSX export and year-rollover until the absence + worktime + approval flow is end-to-end green.

If a team allocates **1 person** to backend (a small full-stack team): cut OIDC, real email, observability, rate limiting, feature flags, tamper-evident audit log entirely. Ship Basic only.

## What this doc does NOT decide

- The actual language and framework. Team picks (within §1 layering + §2 contract-first constraints).
- The actual RDBMS (within §10 constraints).
- The actual storage backend (within §17 constraints).
- The actual IdP (within §8 Bonus constraints).
- The actual XLSX library (within §18 constraints).
- The actual deployment target (within §33 constraints).
