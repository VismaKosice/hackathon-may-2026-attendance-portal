# Frontend QA — Quickstart

**Audience:** Frontend QA on a hackathon build team.
**Read time:** 5 minutes.
**Then:** open [`../testing/testing-fe-technical-refinement.md`](../testing/testing-fe-technical-refinement.md) and start producing.

---

## What you are building

The E2E suite that exercises the portal in a real browser — employee day, manager approvals, HR document validation, admin config. The Gherkin in [`../../acceptance/employee.feature`](../../acceptance/employee.feature) and [`../../acceptance/manager.feature`](../../acceptance/manager.feature) drives critical flows; the FE testing refinement enumerates E1–E9.

## Judging principle

> **The spec is the contract.** UI details not covered by spec §17 are the team's discretion — do not test against undefined behaviour. Test the flows the spec defines.

If an E2E scenario passes, the user journey works. Your suite is the evidence.

## Stack picks — choose in the first 30 minutes

- **Runner:** Playwright (preferred for hackathon — auto-wait, trace viewer, network mocking built-in) • Cypress • WebdriverIO • Selenium • TestCafe • Puppeteer • Nightwatch.
- **Browser:** Chromium covers Basic. Add Firefox / WebKit for Bonus.
- **Reporter:** runner default is fine; HTML report for the judges.

## What you deliver

1. **Critical flows E1–E9** from testing refinement §3 — employee marks workday, requests absence, manager approves, HR validates document, etc.
2. **Authentication + session** — mock-login flow E2E (real OIDC is Bonus).
3. **Approval workflow across users** — same browser context, multi-user via session storage / auth header swap.
4. **Document upload + HR validation E2E** (spec §8).
5. **XLSX export download E2E** — verify the file lands + has the expected sheet shape (spec §11.1).
6. **Network-failure + error states** — disable network mid-flow, assert the UI degrades gracefully.
7. **Responsive matrix** — viewport tests at the breakpoints in FE refinement §1.

## Day shape — suggested

| Track | What you produce |
|---|---|
| **Harness pass (h0–h1)** | Runner installed, one E2E hitting the mock-login page. CI green on the empty harness. |
| **Employee flows (h1–h3)** | Mark workday, request vacation, see approval status. Use page-object pattern from §17 of testing refinement. |
| **Manager flows (h3–h5)** | Approval queue, self-approval guard surfaced in UI. |
| **HR flows (h5–h6)** | Document upload, validation, reject-with-reason. |
| **Export + edge pass (h6–h7)** | XLSX download. Network failure. Auth-expired mid-flow. |
| **Responsive + a11y (h7–end)** | Viewport tests. Keyboard nav. A11y audit gate per FE refinement §19.4. |

## AI tooling — your specific use

High-leverage FE QA use is **generating page-objects from screens** + **converting Gherkin to E2E test scripts** + **building viewport / responsive matrices**.

Prompt template:

```
You are helping me write Playwright E2E tests for an Attendance Portal.

Context:
- Acceptance scenario: [paste from acceptance/<file>.feature]
- Screen reference: [paste product-spec.md §17.<N>]
- Selectors: prefer role-based + accessible name; avoid CSS-class selectors.
- Stack: [Playwright + TS + page-object pattern]

Task:
Generate the page-object + E2E test for this scenario.
Wait on visibility, not time. No sleep(). Use deterministic seed data.
```

Then **review for flakiness**. The AI will reach for `setTimeout` and brittle CSS selectors. Replace with `getByRole` / `getByLabel` + `waitFor` patterns. Run each test 5x locally before merging — if it fails once, fix it before it ships.

## What "good" looks like

- All E1–E9 flows pass on Chromium.
- Selectors are role-based (`getByRole`, `getByLabel`) — not CSS classes that the FE dev will rename.
- No `sleep` / `setTimeout` waits. Polling helpers with a deadline only.
- Tests run in any order — no inter-test state leakage.
- Failing tests dump a screenshot + a trace. Eval-runner can replay them.
- A11y gate runs on at least one critical flow (axe-core / pa11y / equivalent).
- Network-failure path covered for at least one flow.

## Common failure modes (avoid)

- **CSS-selector coupling.** `.btn-primary-3` breaks when the FE dev refactors. Use `getByRole('button', { name: 'Approve' })`.
- **Sleep-based waits.** Hide real bugs, burn CI time. Use the runner's auto-wait or explicit `waitFor`.
- **Skipping the trace / screenshot capture.** A failed test without artefacts is unactionable for the judge.
- **Test order dependence.** Tests should set up their own state and tear it down. No "test 3 depends on test 2 having run".
- **Asserting on incidentals.** Don't assert on timestamps, generated IDs, or animation frames unless that *is* the contract.
- **Skipping the a11y gate.** Cheap to add, visible in the polish score.
- **Bonus axes before Basic ≥ 90%.** Same gate as the rest of the team.

## Links

- [`../testing/testing-fe-technical-refinement.md`](../testing/testing-fe-technical-refinement.md) — full FE testing refinement (E1–E9 flows, runner setup, page-object pattern, determinism, a11y, visual regression).
- [`../../acceptance/employee.feature`](../../acceptance/employee.feature) + [`../../acceptance/manager.feature`](../../acceptance/manager.feature) — Gherkin = judging contract.
- [`../../product-spec.md`](../../product-spec.md) §17 — UX / screens.
- [`../frontend/fe-technical-refinement.md`](../frontend/fe-technical-refinement.md) — FE refinement (a11y §4, theming §5, perf §10, error states §14).
- [`../integration/api-reference.yaml`](../integration/api-reference.yaml) — OpenAPI contract.
- [`../integration/mock-server/`](../integration/mock-server/) — stand-in API for early tests.
- [`../../README.md`](../../README.md) — judging rubric + ground rules.
