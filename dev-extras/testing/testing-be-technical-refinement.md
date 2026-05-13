# Attendance Portal — Backend Testing Technical Refinement

**Status:** Hackathon brief — single-day build window, team sizes 2-7, senior engineers with strong AI tooling.
**Scope:** Backend testing only. Framework-agnostic technical requirements. Teams pick the actual stack (Node + Vitest / Jest / Mocha, Python + pytest, Go + `testing` + testify, Java/Kotlin + JUnit, C# + xUnit, Rust + `cargo test`, Ruby + RSpec, …).
**Companion docs (canonical):**
- `hackathon-may-2026-attendance-portal/product-spec.md` — *read first.* Source of truth for product behaviour, hard/soft rules, state machine, quota model, approval routing, year rollover, export contract, audit log.
- `hackathon-may-2026-attendance-portal/dev-extras/frontend/fe-technical-refinement.md` — sibling FE refinement; this doc layers on top of the same tier model.
**Date:** 2026-05-12

> **This document is the source of truth for backend testing.** It defines, framework-agnostically, what the backend test suite must prove about the system. Each section maps directly to a behaviour or contract from the product spec. The companion scoring rubric is `hackathon-may-2026-scoring-system/agents/testing-be.md`.

---

## Tier mapping — what is Basic vs Bonus on the backend testing lane

The product spec's tier gate (Basic ≥ 90 % before any Bonus is counted) applies to testing too. The table below maps each section of this doc to its tier so teams do not accidentally over-invest before Basic is green.

| Section | Tier | Notes |
|---|---|---|
| §1 Scope + what counts as a backend test | **Basic** | Hard scoping. Unit tests of pure helpers do *not* count toward this lane. |
| §2 Test pyramid for the backend | **Basic** | Integration-heavy. Pure unit tests permitted in addition, but not counted here. |
| §3 API contract conformance | **Basic** | Response shapes drive FE. Schema-validate every response in tests. |
| §4 Hard rules H1-H10 matrix | **Basic** | Both positive (rule trips → block) and negative (rule absent → save) cases per rule. |
| §5 Soft rules S1-S6 matrix | **Basic** | Both positive and negative cases per rule. |
| §6 State machine + transitions | **Basic** | Allowed transitions succeed, forbidden ones fail with a clear error. |
| §7 Quota computed view | **Basic** | Spec §6.5 is load-bearing — must be verified through tests, not just code review. |
| §8 Approval routing + skip-level + self-approval | **Basic** | Org-tree routing + skip-level + self-approval guard is the test surface. |
| §9 Document validation flow | **Basic** | Spec §8. H8 hold and reject-after-approve are the two critical paths. |
| §10 Year-rollover | **Basic** | Anna / Peter / Mária worked examples + dry-run/apply equivalence. |
| §11 XLSX export contract | **Basic** | Two-sheet structure + activity catalogue + SK/EN bilingual. |
| §12 Notifications + audit log side-effects | **Basic** | Tests must assert side-effects are produced, not just primary state changes. |
| §13 Authentication + authorization tests | **Basic** | 401 / 403 negative paths per route. RBAC matrix from spec §3 is the surface. |
| §14 Persistence + transactional tests | **Basic** | Rollback-on-error, no orphan rows on failed submissions, audit + entity write atomicity. |
| §15 Concurrency + race-condition tests | **Bonus** for full coverage; **Basic** for cancel-vs-reject race only. |
| §16 Performance smoke tests | **Bonus** | Worth it only after Basic is green. |
| §17 Security tests | **Basic** | Authn bypass attempts, IDOR, RBAC negative, audit-log read-restriction. |
| §18 Test data + fixtures | **Basic** | Seed must be deterministic and reproducible from a single command. |
| §19 Test isolation + determinism | **Basic** | No order dependence, injected clock, seeded randomness. |
| §20 CI + headless run + reporting | **Basic** | `make test` (or equivalent) runnable with stack-conventional commands. |
| §21 Coverage targets | **Basic** | Numbers below are guides, not hard gates. Vanity tests penalised. |
| §22 Property-based / generative tests | **Bonus** | Strong High signal for the rule engine + quota view. |
| §23 Mutation testing | **Bonus** | Polish axis only. |
| §24 Contract testing against FE | **Bonus** | Consumer-driven contract (e.g. Pact) — stretch. |

---

## 1. Scope — what counts as a backend test

**Integration / API / contract tests only.** This refinement covers tests that exercise the backend **through its HTTP / RPC boundary** and the persistence layer behind it. A qualifying test:

1. Boots the application (or imports it) so a real handler chain runs.
2. Issues a request through an HTTP / RPC client (`supertest`, `pactum`, `fastify.inject`, `app.test_client`, `httptest`, `MockMvc`, `WebTestClient`, `RestAssured`, `Rack::Test`, …) OR drives behaviour through the application's command/query entry point.
3. Asserts on **both** the response **and** the persisted state (DB row, queue entry, event log).

**Out of scope for this lane:**

- Pure unit tests of single functions / formatters / calculators. These are valuable; write them. They simply do not count for the Testing scoring lane.
- Frontend tests of any kind (component, integration, E2E) — those belong to `testing-fe-technical-refinement.md`.

**Test placement convention:** put backend integration tests under `packages/backend/test/` (or framework-equivalent: `tests/`, `spec/`, `it/`, `integration-tests/`). Filename suffixes `*.test.*`, `*.spec.*`, `test_*.*`, `*_test.*`, `*Test.*`, `*IT.*` are all acceptable.

## 2. Test pyramid for the backend

> **Tier note.** The pyramid below is a *target*. Teams that ship integration tests against the API surface satisfy the lane even without a separate unit layer.

- **Integration tests** (boots app, hits HTTP, asserts response + DB) — the bulk of the suite. These are what `agents/testing-be.md` scores.
- **Unit tests** (pure functions: date math, quota computation in isolation, rule predicates) — valuable for fast feedback during development; *not counted* for this lane but encouraged for the rule engine.
- **Contract / schema tests** — assert response shapes match a checked-in schema (OpenAPI, JSON Schema, framework type contract).
- **End-to-end backend tests** (boots full stack including DB + storage + auth + email mock) — required for the export pipeline (§11), year rollover (§10), and document flow (§9).
- **No browser-driven tests in this lane.** Those belong to FE.

## 3. API contract conformance

The FE consumes the BE. Every response shape must be specified and verified.

- **One source of truth** — OpenAPI spec, JSON Schema, or framework-generated type contract — checked into the repo under `packages/backend/contract/` (or framework-equivalent).
- **Schema validation per response in tests** — every integration test that asserts on a response body should additionally validate against the schema. `ajv`, `jsonschema`, `pydantic`, framework type assertions, etc.
- **Error envelope shape** — agree on one envelope and verify in tests. Suggested:
  ```json
  { "errors": [ { "ruleId": "H4", "field": "date", "message": "...", "severity": "hard" } ] }
  ```
- **Pagination shape** — consistent across list endpoints; verify `next_cursor` / `total` / `items` shape in tests.
- **Timestamp format** — ISO 8601 with explicit TZ (`2026-05-12T08:00:00+02:00`); verify in tests, do not rely on the framework's default.
- **Per-route happy + error paths.** Every route must have at least one happy-path integration test and at least one negative-path test (validation failed, 401/403, 404, 409, 5xx).

## 4. Hard rules H1-H10 coverage matrix (spec §9.1)

Each hard rule MUST have a dedicated integration test (or test class / describe block) named after the rule. The matrix is the contract:

| ID | Rule | Tests must prove |
|---|---|---|
| H1 | No overlapping entries on the same day | Worktime ↔ worktime; absence ↔ absence on same slot; worktime ↔ approved absence; touching-not-overlapping does NOT trip (08:00-12:00 + 12:00-13:00 → allowed). |
| H2 | Sickday is full-day only | Half-day option returns 400 / is hidden in form schema; full-day works. |
| H3 | Sickday quota cannot be exceeded | At 0 remaining → blocked. At 1 remaining → allowed. At 3 remaining → 4th blocked. |
| H4 | No consecutive sickdays | Yesterday-sickday today-sickday → blocked, message suggests PN. Two-day gap → allowed. Sickday Fri + sickday Mon → allowed iff Sat/Sun are NOT sickdays (consecutive *calendar* days). |
| H5 | Relevant quota cannot be exceeded | At limit minus 1 + 2 days requested → blocked. Bonus exhausted but statutory available → allowed (consumption order, §6.1). |
| H6 | Worktime is forbidden on a day with approved absence | Approved absence then worktime → blocked. Withdraw absence then worktime → allowed. |
| H7 | Overtime is forbidden during any absence | Same surface as H6 for the overtime flag. PN multi-day with weekend → weekend overtime still blocked. |
| H8 | Documents required to finalise Paragraph / OCR / Special | Submission without doc is allowed (Pending). Approval transition blocked without HR-validated doc. With validated doc, Approval succeeds. |
| H9 | Full-day absence vs worktime on same day | Full-day absence then half-day worktime → blocked. Spec restates H6 — test both H6 and H9 surfaces independently. |
| H10 | Two absences cannot occupy the same morning/afternoon slot | Morning Paragraph + morning Vacation → blocked. Morning Paragraph + afternoon Vacation → allowed. Full-day Vacation + existing morning Paragraph → blocked (full-day claims both slots). |

Each test must assert:

1. The rule ID is in the response (`response.errors[].ruleId == "H4"`), not just any 400.
2. The plain-English message from spec §9.1 is present.
3. No state change persisted (DB row count for the entity is unchanged after the rejected attempt).
4. A negative case where the rule does NOT trip and the submission succeeds.

### Beyond-the-matrix coverage to reach High

- **Boundary values.** H3 (sickday quota = 3): test with 0 / 1 / 2 / 3 remaining, plus 4 remaining (negative case — must NOT fire).
- **Range edges.** H1 (overlap): existing 08:00-12:00 + new 11:59-13:00 → trip. Existing 08:00-12:00 + new 12:00-13:00 → no trip (touching, not overlapping). Existing 08:00-12:00 + new 12:01-13:00 → no trip.
- **Time-zone edge cases.** A worktime entry crossing midnight, an absence range spanning DST boundary, a sickday submitted from a different TZ than the event date.
- **Holiday edge cases.** Sickday on holiday triggers the not-working-day hard rule. Absence range that *contains* a holiday counts the holiday as zero working days (spec §4.1).
- **Multi-rule interaction.** Submit a half-day vacation that would simultaneously trigger H10 (slot conflict) and H5 (quota exceeded). Assert both rule IDs come back in the response.

## 5. Soft rules S1-S6 coverage matrix (spec §9.2)

Each soft rule MUST have a dedicated integration test. The matrix:

| ID | Rule | Tests must prove |
|---|---|---|
| S1 | 30-minute gap between half-day absence and same-day worktime | Half-day morning Paragraph + worktime starting 12:15 → warning. Starting 12:30 → no warning. |
| S2 | Worktime outside the working window (default 08:00-16:30) | Worktime 06:00-15:00 → warning. Worktime inside window → no warning. Admin override of the window respected. |
| S3 | Night-time work (between 22:00 and 06:00) | Worktime 04:30-13:00 → S3 + S4 both warn. Worktime 22:30-23:30 → S3 alone. |
| S4 | Single worktime entry exceeding 8 hours | 8h 1m entry → warns. 8h 0m entry → no warn. Two 4h entries on same day → no S4 (S4 is per-entry, not per-day; per-day overtime is the auto-flag in spec §5.1). |
| S5 | Quota approaching limit | Vacation submission leaves 2 / 1 / 0 remaining → S5. Submission leaves 3 remaining → no S5. Submission that would push below 0 → no S5 (H5 hard-blocks instead). |
| S6 | Worktime on Slovak public holiday | Worktime on a seeded holiday → warns. Worktime on regular day → no warn. |

Each test must assert:

1. The warning IS emitted when the trigger condition holds.
2. Submission still **succeeds** (entity is persisted).
3. The warning carries the rule ID `S1`..`S6`.
4. The warning is persisted on the entity so manager / HR can see it later (visible on re-fetch).
5. A negative case where the warning does NOT fire and no soft warning is on the saved entity.

## 6. State machine + transition tests (spec §7)

Spec §7 defines the absence lifecycle: `Draft → Pending → {Approved, Rejected, Withdrawn} → {Cancelled (from Approved)}`. Sickday + PN bypass Pending; both bypass paths go straight to Approved (Sickday) or Logged-as-Approved (PN). The test surface:

- **Allowed transitions succeed.** Pending → Approved, Pending → Rejected (with reason), Pending → Withdrawn (by requester), Approved → Cancelled (day-before window), Approved → Rejected (HR override).
- **Forbidden transitions fail with a clear error.** Withdrawn → Approved, Rejected → Approved, Cancelled → anything, Approved → Pending.
- **Terminal-state guards.** A second Approve on an already-Approved entry → 409 conflict, no double notification, no double quota debit.
- **Sickday bypass.** Submit sickday → entity is Approved immediately. No Pending state was ever persisted.
- **PN bypass.** Log PN → entity is Approved/Logged. Quota is uncapped — verify it does not appear in `reserved` or `used` of any quota balance.
- **Cancellation window.** Cancel on day-before → succeeds. Cancel on event day → 409, message routes to HR. HR override path succeeds.
- **Reject requires reason.** Reject without a reason → 400. With reason → the reason persists on the entity and surfaces in the audit log.

Every transition must write an audit entry (§12).

## 7. Quota computed view (spec §6.5)

This is the single most load-bearing piece of backend logic. Tests must prove the computed view, not a counter.

- **`remaining = allocated − reserved − used`** holds across every transition.
- **Pending → Approved** moves working-days from `reserved` to `used`; `remaining` does NOT change.
- **Withdraw / Reject / Cancel** causes the entity to stop contributing — no "refund" action is called.
- **Consumption order** (carry-over → statutory → bonus) is exercised. Approve a vacation when carry-over is non-zero; assert the carry-over decrements first.
- **Historical balance reproducibility.** `balance_as_of(date_X)` returns the same numbers as replaying entity states up to date_X. Write a property test or at least a snapshot test against a fixed seed.
- **Cancel-vs-reject race.** Two transitions arrive simultaneously; both resolve to the same terminal state; the entity stops contributing to `used` exactly once. Use a transaction or optimistic-lock pattern, not a counter.
- **Realised vs planned split** (spec §6.5 last bullet). `used` includes both; a `used_realised` derived view can split by today's date — verify with a fixed clock.
- **Per-entity lifecycle.** One test walks an entity through Draft → Pending → Approved → Cancelled and asserts the quota view at each step. This catches state-machine and quota-view bugs that single-transition tests miss.

If the team's implementation uses a stored counter, the tests should expose it. Reject the implementation on review.

## 8. Approval routing + skip-level + self-approval guard

- **Default routing** — every submission routes to `direct_manager_id`. Test with a fixture tree of depth ≥ 3.
- **Skip-level filter** — an ancestor opens the queue with filter "I can approve via chain" and sees descendant requests. Approve-as-ancestor works and the audit log records "skip-level" as the actor type.
- **Self-approval guard** — a manager submits their own request. Routing walks up to the first non-self ancestor. Test for a multi-step walk (LeadA1 → DeptHeadA → CEO).
- **Chain exhausted → HR group** — CEO (no manager) submits a request. Every HR-role user sees it in their queue.
- **Missing direct_manager** — clear `direct_manager_id`; new submissions route to HR group.
- **Combined skip-level + self-approval** — a manager submits a request and the next ancestor is unavailable (e.g. soft-deleted). Chain walks to the grand-manager.
- **Org-tree cycle protection** — attempt to set CEO's direct_manager to a descendant; admin endpoint returns 400.

## 9. Document validation flow (spec §8)

- **Upload happy path** — multipart upload, MIME validation (`image/png`, `image/jpeg`, `application/pdf` accepted; `text/plain` rejected with explicit message). 10 MB cap enforced.
- **Server is source of truth for type and size.** Test that a `.png` file renamed to `.pdf` is detected at the server and rejected (or stored with the true MIME and returned to the FE).
- **Attach after submit** — document attached to an existing Pending absence; H8 still applies.
- **PN attach by HR or employee (O8)** — both paths target the same PN entry.
- **HR approves document** — absence proceeds; balance moves from reserved to used (if manager already approved); employee notified.
- **HR rejects document after manager approval** — absence transitions to Rejected; entity stops contributing to `used` per §6.5 (no counter "refund"); audit entry recorded; employee notified with reason.
- **HR rejects document while absence still Pending** — absence transitions directly to Rejected without waiting for manager.
- **Re-submit after rejection** — original entity stays Rejected (terminal); a fresh submission creates a new entity.
- **Document file persists for audit after rejection** — verify the storage path is still readable.
- **Reject-after-approve + cancel race** — HR rejects the document at the same moment the employee cancels the absence. Both transitions resolve to the same terminal state per §6.5.

## 10. Year-rollover (spec §6.3)

- **Anna worked example** — leftover 4, within limit. Carry-over 4. Bonus retained. 2027 total = 27.
- **Peter worked example** — leftover 8, exceeds limit. Carry-over 8 (statutory never lost). Bonus zeroed. 2027 total = 28.
- **Mária worked example** — leftover 0. Carry-over 0. Bonus retained. 2027 total = 23.
- **Dry-run / apply equivalence** — dry-run output must be byte-equal to what apply produces. Property: `dry_run(state) == apply(state).preview_after`.
- **Dry-run does not mutate** — pre- and post-snapshots of every quota table are identical.
- **Sickday / Paragraph / OCR reset fresh** — no carry-over, no penalty.
- **Per-user summary notification** — every employee + HR receives a record on the notification feed.
- **Audit entries** — one entry per user transition, with before/after snapshots.
- **Idempotency** — running rollover twice for the same year transition is a no-op the second time (or returns 409). Pick one and test it.
- **Event-date semantics** — a sickday submitted on 2 January but dated 31 December counts against the previous year (spec §6.2).
- **Quota override mid-flight** — employee has a Pending vacation; HR overrides their quota down to less than the requested days; re-validation on the Approval transition hard-blocks (spec §9.3).

## 11. XLSX export contract (spec §11.1)

Open the generated workbook and assert structure, not byte-equality.

- **Two sheets** named `Dochádzka` + `Nadčas` (SK) or `Attendance` + `Overtime` (EN).
- **One block of three columns per employee**, alphabetical by last name.
- **One row per half-day** for the entire calendar month, including weekends + holidays.
- **Activity-label catalogue** — every catalogue value in spec §11.1 has at least one fixture entry that produces it, and the assertion checks that the right label lands in the right cell:
  - SK: Práca, Pracovná cesta, Sviatok, V (+ `Víkend` in time column), Dovolenka, Sickday, PN, Návšteva lekára, Sprevádzanie člena rodiny, Špeciálne voľno.
  - EN: Work, Business trip, Holiday, W (+ `Weekend`), Vacation, Sickday, Sick leave, Doctor visit, Family care, Special leave.
- **Half-day split** — morning Paragraph + afternoon work on the same date produces two adjacent rows (Doobedu absence + Poobede work).
- **First row + first column frozen.** Verify via the workbook's freeze pane property.
- **Hours decimals** — one digit precision; separator `.` in EN, `,` in SK.
- **Overtime sheet** — only employees with at least one overtime entry that month appear; blank-row separator between blocks.
- **CSV companion** — header `date,half,full_name,activity,time_range,hours`; two rows per employee per calendar day.
- **Authorization** — only HR + Admin can hit the export endpoint; Employee + Manager → 403.

## 12. Notifications + audit log side-effects

Backend tests must assert that **every** state change produces:

1. The expected notification records per spec §10 table.
2. The expected audit entries per spec §11.5.

Tests SHOULD use an in-memory or queryable notification store; assert by counting records and inspecting payloads.

- **Dedup rule** — when a recipient appears in multiple groups for the same event, exactly one record is produced.
- **No double-send** on idempotent re-submission.
- **Audit before/after snapshots** are non-null and contain the state field that changed.
- **HR override** records the actor as the HR user, not the original requester.
- **Skip-level approve** records the actor type as "skip-level".
- **Year-rollover** writes one summary notification per employee + one per HR user.

## 13. Authentication + authorization tests

- **Mock-login path** — pick a user; receive a session token / cookie; subsequent requests are authenticated.
- **No-cred negative** — every protected route returns 401 without a session.
- **Wrong-role negative** — RBAC matrix from spec §3 is the surface. For each capability row, test that the *forbidden* roles get 403.
- **Token / session expiry** — expired session → 401 with a discriminator (`"reason": "session_expired"`).
- **IDOR** — Employee A cannot read Employee B's absences, balances, documents. Test by ID guessing.
- **Privilege-elevation prevention is OUT of MVP scope** (spec §13 note) — do not lose hackathon time on this. Bonus only.
- **Audit-log read-restriction** — Employee + Manager → 403 on the audit log endpoint.

## 14. Persistence + transactional tests

- **Atomicity** — a submission that writes the absence + audit entry + notification record must either fully commit or fully rollback. Inject a failure mid-write (e.g. mock the notification store to throw) and assert no orphan rows.
- **Schema migrations** — tests run against the latest migration set. Document the test-DB bootstrap command in `README.md`.
- **Transactional isolation** — read-committed at minimum. Two concurrent submissions for the same employee should not both pass H1 (overlap).
- **No leaked DB connections** — assert pool size after each test reaches steady state.

## 15. Concurrency + race-condition tests

- **Cancel-vs-reject race** (Basic) — fire both transitions simultaneously; assert exactly one wins, the other returns a discriminator (`"reason": "stale_state"`), audit log records the winner.
- **Double-approve race** (Bonus) — manager and skip-level both approve at the same time; one wins, the other returns 409.
- **Two simultaneous worktime submissions** that would each independently pass H1 but overlap each other — one must fail.

Use a test harness that supports concurrency (`Promise.all`, `pytest-asyncio`, `errgroup`, `Parallel.For`, ...). Skip if the framework cannot run two requests against the same test DB cleanly.

## 16. Performance smoke tests (Bonus)

Useful for catching N+1 queries and unbounded list responses.

- Seed 500 employees, 50 teams, 12 months of entries (~50 entries / employee).
- Assert key endpoints respond under a threshold (e.g. monthly XLSX export < 5 s, team-calendar grid < 500 ms, approvals queue < 200 ms).
- Use a single load tool — `autocannon`, `locust`, `vegeta`, `wrk` — runnable with stack-conventional commands.

## 17. Security tests

- **Authn bypass attempts** — tampered token, missing signature, expired token, `none` algorithm if JWT-based.
- **IDOR sweep** — for each entity ID returned to user A, attempt access as user B.
- **SQL injection / NoSQL injection** — payloads in user-controlled string fields (notes, reasons, project codes); assert escaped behaviour.
- **XSS persistence** — submit a note containing `<script>` and assert the API returns it escaped or the FE-side renderer escapes it. (FE refinement §17 covers the FE side.)
- **File-upload guardrails** — MIME validation, magic-byte sniffing, size cap, no path traversal in filename, virus-scan-stub or hook (Bonus).
- **Rate limiting (Bonus per spec §14)** — burst test asserts the endpoint returns 429 with `Retry-After`.
- **Dependency hygiene** — `npm audit`, `pip-audit`, `cargo audit`, `mvn dependency-check`, equivalent runs in CI and fails on high/critical.
- **`gitleaks` + `trivy fs` + `semgrep --config=auto`** all pass per the scoring system.

## 18. Test data + fixtures

- **Single seed entrypoint** — `npm run seed`, `make seed`, `pytest fixtures/seed.py`, equivalent. Wipes + reseeds the test DB to a known state. Idempotent.
- **Deterministic seed** — same input data, same UUIDs / IDs / orderings. Use a fixed RNG seed.
- **Fixture set covers**:
  - Org tree of depth ≥ 3 (CEO → DeptHeads → Leads → ICs).
  - Multiple teams (≥ 2), some with members spanning the org tree.
  - At least one HR user, one Admin, several Employees, several Managers.
  - 2026 Slovak public holidays loaded.
  - End-of-2026 states matching Anna / Peter / Mária worked examples for year-rollover.
- **No real PII** — no real names beyond the seed nicknames, no real emails (`@example.test` domain or similar), no real document content (use bundled sample PDFs).
- **Factories or builders** — `factory_boy`, `factory.ts`, hand-rolled builders, etc. — preferred over inline literals.

## 19. Test isolation + determinism

- **Isolated DB per test or per file.** Transactional rollback, `truncate` between tests, container-per-file, or in-memory DB seeded per test. No order dependence.
- **Injected clock.** Every "today" / "now" comes from a `Clock` / `TimeProvider` / `time.Now()` abstraction the tests can swap. No raw `Date.now()` / `time.time()` / `LocalDateTime.now()` in domain code.
- **Seeded RNG** for any randomised behaviour.
- **No sleeps as synchronisation** — wait on the event you actually care about.
- **No order dependence** — running tests in reverse order or randomised order must produce identical results.
- **Async correctly awaited** — no fire-and-forget promises, no unhandled rejections, no warnings about unawaited goroutines.

## 20. CI + headless run + reporting

- **Single command entrypoint** — `npm test`, `make test`, `pytest`, `go test ./...`, `mvn verify`, `dotnet test`. Document the chosen command in `README.md`.
- **Headless** — no interactive prompts, no human-in-the-loop input.
- **JUnit XML report** (or framework-native) emitted to `reports/junit/*.xml` for the scoring system.
- **Coverage report** emitted to `reports/coverage/` (Cobertura XML or LCOV).
- **CI matrix** — at minimum: latest LTS of the chosen runtime. Bonus: previous LTS.
- **Test runtime budget** — full suite under 5 minutes locally. Parallelise where the framework supports it.
- **Flaky tests** — quarantine flaky tests in a separate directory with explicit `@flaky` markers (and a TODO to fix). Better to mark them than to silently disable.
- **No skip markers in main.** `it.skip`, `xit`, `@Ignore`, `@pytest.mark.skip`, `t.Skip()` not allowed in committed code.

## 21. Coverage targets

Coverage is a *guide*, not a hard gate. Numbers below are the floor for the High band on category 10 of `agents/testing-be.md`.

- **Rule engine and quota math** — ≥ 80 % statement coverage.
- **Route handlers** — ≥ 70 % statement coverage.
- **Domain services** — ≥ 70 % statement coverage.
- **Overall backend** — ≥ 60 % statement coverage.
- **Critical paths** (submission, approval, document validation, year rollover, export) — 100 % branch coverage.

Vanity tests written to hit a number are explicitly penalised — judges read the tests.

## 22. Property-based / generative tests (Bonus)

The rule engine and the quota-computed view are excellent targets for property-based tests (`fast-check`, `hypothesis`, `quickcheck`, `gopter`, …):

- **Property: `remaining = allocated − reserved − used` for any sequence of transitions.** Generate random sequences of submit / withdraw / approve / reject / cancel; after each step, assert the invariant holds.
- **Property: statutory days are never lost across year rollover.** Generate random end-of-year states; rollover; assert statutory_in + carry-over_out ≥ statutory_in.
- **Property: no two approved entries occupy the same morning/afternoon slot.** Generate random absences; assert H10 catches every conflict the property generator can find.

Property-based tests are not required for Basic but are a strong High signal.

## 23. Mutation testing (Bonus)

Stretch axis. Run a mutation tester (`Stryker`, `mutmut`, `pitest`, `go-mutesting`, …) against the rule engine and the quota-view module. Mutation score ≥ 60 % is a strong High signal.

## 24. Contract testing against FE (Bonus)

Consumer-driven contracts (`Pact`, `Spring Cloud Contract`, …) — the FE describes the requests it sends; the BE replays them as verifications. Worth it only if both lanes pre-agree on the contract format.

---

This document is the specification of the *backend testing requirements*. The team picks the framework, the runner, and the assertion style. What the tests *prove* is what is judged.
