# Backend QA / SDET — Quickstart

**Audience:** Backend QA / SDET on a hackathon build team.
**Read time:** 5 minutes.
**Then:** open [`../testing/testing-be-technical-refinement.md`](../testing/testing-be-technical-refinement.md) and start producing.

---

## What you are building

The test suite that proves the backend obeys the contract — Gherkin scenarios from [`../../acceptance/`](../../acceptance/), Hard rules H1–H10 and Soft rules S1–S6 from spec §9, the state machine in §7, quota view in §6.5, year-rollover in §6.3, XLSX export in §11.1.

The Gherkin **is** the judging contract. Your job is to make those scenarios executable and to extend coverage where the matrix demands it.

## Judging principle

> **The spec is the contract.** Anything `product-spec.md` does not specify is the team's discretion — do not write tests against undefined behaviour. Test what the spec specifies; the rest is the dev's call.

If a scenario passes, the feature is done. Your suite is the evidence.

## Stack picks — match the BE dev's choices

- **Test runner:** Node + Vitest / Jest / Mocha • Python + pytest • Go + `testing` + testify • Java/Kotlin + JUnit • C# + xUnit • Rust + `cargo test` • Ruby + RSpec.
- **BDD adapter (for Gherkin):** Cucumber.js / Cucumber-JVM / behave / godog / SpecFlow / equivalent. Or implement the scenarios as plain integration tests — Gherkin is the rubric, not the framework.
- **HTTP client:** supertest / httpx / RestAssured / equivalent.

## What you deliver

1. **All `acceptance/*.feature` scenarios passing** as executable tests.
2. **Hard rules H1–H10 coverage matrix** — each rule has positive + negative scenarios. See testing refinement §4.
3. **Soft rules S1–S6 coverage** — warnings surface, do not block.
4. **State machine transitions** — every valid + invalid transition tested per spec §7.
5. **Approval routing tests** — skip-level approval + self-approval guard.
6. **Document validation flow** — HR upload + validate + reject path (spec §8).
7. **Year-rollover** — quota carry-over per spec §6.3.
8. **XLSX export contract** — column shape + content per spec §11.1.

## Day shape — suggested

| Track | What you produce |
|---|---|
| **Harness pass (h0–h1)** | Test runner up, single fixture loaded, one acceptance scenario red. CI green on the harness itself. |
| **Acceptance pass (h1–h4)** | Wire `acceptance/employee.feature` + `manager.feature` to step definitions. Run against BE dev's endpoints as they land. |
| **Rule matrix pass (h3–h6)** | H1–H10 positive + negative; S1–S6 warning surfaces. Each rule gets its own test file. |
| **State machine pass (h5–h7)** | Every transition in spec §7. Reject invalid transitions with the right error code. |
| **Cross-flow pass (h6–h7)** | Approval routing, doc validation, year-rollover, XLSX export. |
| **Polish pass (h7–end)** | Quarantine flaky tests (with `@flaky` markers + reason). Fix or quarantine — don't silently skip. |

## AI tooling — your specific use

High-leverage QA use is **generating test cases from rule definitions** + **converting Gherkin to step definitions** + **building negative-path scenarios the dev missed**.

Prompt template:

```
You are helping me write backend tests for an Attendance Portal API.

Context:
- Spec rule: [paste product-spec.md §9 rule H<N> definition]
- Acceptance: [paste any matching scenarios from acceptance/*.feature]
- API endpoint: [paste from api-reference.yaml]
- Test stack: [Vitest + supertest]

Task:
Generate positive + negative tests for rule H<N>.
For negative path, include: expected error code, error envelope shape,
audit-log entry shape, no side-effect on quota/state.
```

Then **review and prune**. The AI will write redundant assertions and miss edge cases that matter (e.g. boundary on quota arithmetic). You catch what it misses.

## What "good" looks like

- Every Basic Gherkin scenario is green; no `.skip()`, no `pending()`.
- Hard-rule matrix has both positive + negative coverage per rule.
- Negative tests assert error code + envelope shape, not just the status code.
- State machine has a transition table test that enumerates every valid + invalid transition.
- Tests are deterministic — controlled clock, seeded random, frozen fixtures. No `sleep` waits.
- Flaky tests are quarantined explicitly with `@flaky` + a TODO line, not silently disabled.

## Common failure modes (avoid)

- **Testing implementation, not contract.** The test exists to prove the spec is obeyed. If a refactor breaks the test but the spec still passes, the test was wrong.
- **Sleep-based waits.** Use polling helpers with a deadline. `setTimeout` waits hide real bugs and burn time.
- **Skipping negative paths.** The matrix demands both. A rule that only has happy-path tests scores low on the rubric.
- **Coupling tests to the seed.** Tests should set up the state they need, not depend on the seed having a user named `alice`.
- **Asserting on incidentals.** Don't assert on `createdAt` timestamps or auto-generated IDs unless that *is* the contract.
- **Bonus tests before Basic ≥ 90%.** Same gate as the BE dev — the scoring system forfeits Bonus points.

## Links

- [`../testing/testing-be-technical-refinement.md`](../testing/testing-be-technical-refinement.md) — full BE testing refinement.
- [`../../acceptance/`](../../acceptance/) — Gherkin = judging contract.
- [`../../product-spec.md`](../../product-spec.md) §9 — rule catalogue. Read first.
- [`../../product-spec.md`](../../product-spec.md) §7 — state machine.
- [`../integration/api-reference.yaml`](../integration/api-reference.yaml) — OpenAPI contract.
- [`../integration/mock-server/`](../integration/mock-server/) — stand-in API when BE is mid-build.
- [`../../README.md`](../../README.md) — judging rubric + ground rules.
