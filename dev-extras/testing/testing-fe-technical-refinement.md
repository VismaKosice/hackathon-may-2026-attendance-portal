# Attendance Portal — Frontend Testing Technical Refinement

**Status:** Hackathon brief — single-day build window, team sizes 2-7, senior engineers with strong AI tooling.
**Scope:** Frontend end-to-end testing only. Framework-agnostic technical requirements. Teams pick the actual stack (Playwright, Cypress, WebdriverIO, Selenium, TestCafe, Puppeteer, Nightwatch, …) and the UI framework underneath (React / Vue / Svelte / Angular / Solid / …).
**Companion docs (canonical):**
- `hackathon-may-2026-attendance-portal/product-spec.md` — *read first.* Source of truth for product behaviour.
- `hackathon-may-2026-attendance-portal/dev-extras/frontend/fe-technical-refinement.md` — sibling FE refinement. §19.3 sets the critical-flow baseline. This doc layers on top.
**Date:** 2026-05-12

> **This document is the source of truth for frontend end-to-end testing.** It defines, framework-agnostically, what the real-browser E2E suite must prove about the user-facing system. Each section maps directly to a behaviour or contract from the product spec or the FE technical refinement. The companion scoring rubric is `hackathon-may-2026-scoring-system/agents/testing-fe.md`.

> **Real-browser E2E only.** This refinement is scoped to tests that drive a real browser (Chromium / Firefox / WebKit) against the built application. Component-level tests (Testing-Library, Vue Test Utils, JSDOM-rendered tests) are excluded from this lane — they are valuable, but they belong to the unit/integration suite, not this scoring lane.

---

## Tier mapping — what is Basic vs Bonus on the FE testing lane

The product spec's tier gate (Basic ≥ 90 % before any Bonus is counted) applies to testing too.

| Section | Tier | Notes |
|---|---|---|
| §1 Scope + what counts as an E2E test | **Basic** | Component tests not counted in this lane. |
| §2 Test runner + browser matrix | **Basic** | At minimum: Chromium headless. Bonus: + Firefox + WebKit. |
| §3 Critical flows E1-E9 | **Basic** | FE refinement §19.3 names them. This doc tightens them. |
| §4 Auth + session E2E | **Basic** | Mock login Basic; OIDC Bonus. |
| §5 Hard + soft rule UI surface | **Basic** | Every rule from spec §9 verified through the form. |
| §6 Approval workflow across users | **Basic** | Multi-session within the same browser context. |
| §7 Document upload + HR validation | **Basic** | Drag-and-drop + preview + reject flow. |
| §8 XLSX export download | **Basic** | Capture file, open workbook, assert structure. SK + EN. |
| §9 Real-time + optimistic UI | **Basic** | Cross-tab updates, rollback-on-error. |
| §10 Internationalisation | **Basic** for SK rendering; **Bonus** for SK + EN switch test. |
| §11 Theming light/dark/system | **Basic** | Toggle + persistence + system listener. |
| §12 Responsive + viewport matrix | **Basic** | Mobile + tablet + desktop. |
| §13 Accessibility audit gate | **Basic** | axe-core on every step + Lighthouse a11y ≥ 90. |
| §14 Network-failure + error states | **Basic** | 401 / 403 / 409 / 5xx + offline banner. |
| §15 Performance smoke | **Basic** | Lighthouse perf ≥ 90 on smoke routes. |
| §16 Visual regression | **Bonus** | Polish axis. |
| §17 Selectors + page-object discipline | **Basic** | Role-first selectors; CSS classes forbidden. |
| §18 Determinism + clock control | **Basic** | No magic-number waits; injected clock. |
| §19 Test data + seed reset | **Basic** | Per-test or per-suite reset. |
| §20 Flake handling | **Basic** | Quarantine, do not silently retry. |
| §21 CI + parallelisation + reporting | **Basic** | `make e2e` runnable with stack-conventional commands. |
| §22 Cross-browser coverage | **Bonus** for full matrix; **Basic** for one engine. |
| §23 Mobile-device emulation | **Basic** for E2/E3/E5 at 375×667 + 412×915 (per FE refinement §19.3). |
| §24 Coverage targets + reporting | **Basic** | Critical flows 100 %; rule surface 100 %. |

---

## 1. Scope — what counts as a frontend test in this lane

**Real-browser end-to-end tests only.** A qualifying test:

1. Boots a real browser engine (Chromium / Firefox / WebKit) — headless or headed.
2. Navigates to a URL served by the built application (or framework dev server with production-equivalent behaviour).
3. Drives the page via user-like actions (click, type, keyboard, drag, file input).
4. Asserts on the rendered DOM, on captured network traffic, on downloads, or on browser state (cookies, storage, history).

**Out of scope for this lane:**

- Component-level tests via `@testing-library/*`, `@vue/test-utils`, `enzyme`, `@testing-library/svelte` — these are valuable, but not counted here.
- JSDOM-based tests of any kind.
- Pure unit tests of helpers, formatters, validators.
- Backend integration tests — those belong to `testing-be-technical-refinement.md`.

**Test placement convention:** `e2e/`, `tests/e2e/`, `playwright/`, `cypress/e2e/`, `wdio/specs/`, equivalent. Filename suffixes `*.e2e.*`, `*.spec.ts` (inside an E2E folder), `*.cy.*`, `*.pw.*`.

## 2. Test runner + browser matrix

- **Pick one E2E framework.** Playwright is the recommended default (multi-browser, network interception, download capture, trace viewer, mobile emulation, accessibility plug-in). Cypress / WebdriverIO / Selenium are acceptable.
- **Browsers:**
  - **Basic.** Chromium headless on CI.
  - **Bonus.** + Firefox + WebKit headless. FE refinement §3 explicitly names all three for compatibility.
- **Viewports:**
  - Default desktop viewport 1280×800.
  - **Mobile-viewport runs for E2, E3, E5** at **375×667** and **412×915** (per FE refinement §19.3 + spec §14 mobile-friendly Bonus).
  - One Full-HD run (1920×1080) for the team-calendar grid + balances dashboard to verify the wide layout (FE refinement §1 calls out the breakpoint range).
- **Headed mode locally** is fine; CI runs are headless.
- **Trace / video / screenshot capture on failure** — Playwright `trace: 'on-first-retry'`, Cypress video recording, equivalent. Stored as build artifacts for the scoring system.

## 3. Critical flows E1-E9

FE refinement §19.3 names the nine required flows. This refinement tightens what "covered" means for each.

| Flow | Tightened requirements |
|---|---|
| **E1** Admin creates team + user; login as that user | Admin types name + roles, assigns to team, sets `direct_manager_id`. Logs out. Mock-login picks the new user. Lands on the role-correct dashboard. |
| **E2** Log worktime; visible on own dashboard | Form opens, project defaults to `GENERAL`, BT toggle accessible, overtime flag auto-appears on >8h entry, entry visible on the dashboard after save. Includes a split-day case (two non-overlapping entries on the same day). |
| **E3** Submit vacation → approve as manager → balance decrement | Cross-context flow (two browser contexts, two storage states). Employee sees balance change from "X reserved" to "X used" after manager approval. Calendar updates in the same flow. |
| **E4** Sickday consecutive blocked | Submit a sickday for yesterday (via fixture). Attempt today's sickday. Inline error references "H4" and the message contains "PN" as suggested alternative. |
| **E5** Paragraph + document upload → HR validate → reject path | Upload PDF via drag-and-drop. Manager approves. HR rejects with a reason. Absence flips to Rejected. Employee's balance recomputes (entry stops contributing to `used`). Run on mobile viewport too (camera-capture surface). |
| **E6** Overtime retroactive → manager rejects → marked uncompensated | Employee logs >8h entry; overtime flag auto-set; routes to manager; manager rejects with reason; entry is visible with "Uncompensated" label. |
| **E7** Team-calendar grid renders for current month | Grid renders for current month with one row per team member. Switch month works. Cell click opens side-panel drill-in. |
| **E8** HR exports monthly XLSX | Click export → download capture → open workbook → assert §11.1 contract for **both** SK and EN languages. See §8 below. |
| **E9** Year-rollover dry-run preview | HR runs dry-run → preview table shows Anna / Peter / Mária outcomes exactly per spec §6.3. Apply step requires confirmation modal. |

These nine are mandatory. Each must assert the *outcome* (balance changed, file produced, inline error visible, calendar cell renders), not just that navigation occurred.

## 4. Authentication + session E2E

- **Mock-login (Basic).** User picker lists seeded fixture users. Clicking a user grants a session and lands on the role-correct dashboard.
- **Idle timeout.** Inject the clock forward 31 minutes; assert the silent-refresh attempt; on simulated failure, redirect to `/login` with a "Session expired" toast.
- **Hard expiry.** Inject the clock 12 h forward; assert forced re-auth.
- **Multi-tab logout via BroadcastChannel.** Open the app in two contexts sharing the same browser. Logout in tab A; tab B redirects to `/login` within ~1 s.
- **Role-gated dashboards.** Log in as Employee, Manager, HR, Admin in turn (or in parallel contexts). Assert each lands on the role-correct dashboard with the role-correct nav items.
- **Session persists across reload** within the idle window.
- **Bonus — real auth.** If OIDC is implemented, add a Bonus E2E covering the redirect-to-IdP → callback → token stored in `sessionStorage` flow. Use a mock IdP (e.g. Mock OAuth2 Server) so the test is reproducible.

## 5. Hard + soft rule UI surface (spec §9)

**Hard rules (H1-H10).** For each rule, write at least one E2E that fills the form into the rule-tripping state, attempts submission, and asserts:

1. The submit button is rendered but submission is **blocked** (request is *not* sent, OR the server's 400 is rendered cleanly).
2. An inline red error appears at the top of the form (per FE refinement §13 + §17.1).
3. The error carries a discriminator (`data-rule="H4"`, `aria-describedby`, or message text containing `H4`).
4. The error message is the plain-English message from spec §9.1.
5. Soft warnings already on the form are NOT cleared by the hard error.
6. The error is announced via `aria-live="assertive"`.

For H4, additionally assert the message contains "PN" or the localised equivalent.

For H8, the test must walk the manager → HR approve sequence; H8 blocks the *Approve* transition, not submission. Manager approves a Paragraph absence with a pending document, sees the Pending document indicator, NOT a file preview. HR queue shows the document. Manager cannot see the file content.

**Soft rules (S1-S6).** For each rule, write at least one E2E that fills the form into the warning-tripping state and asserts:

1. A yellow inline warning appears under the relevant field.
2. The warning carries the rule ID `S1`..`S6`.
3. A *Save anyway* button is rendered alongside the primary *Save*.
4. Clicking *Save anyway* submits successfully.
5. The saved entity, on re-fetch, still shows the warning (warnings persist).
6. The warning is announced via `aria-live="polite"`.

**Live validation.** Type into a worktime form field and observe the validation message update before pressing Save (debounced ~250 ms per FE refinement §13). This is spec §13 #3 "inline live validation as the user types".

## 6. Approval workflow across users

Single-user tests are not sufficient. The workflow inherently spans multiple actors.

- **Same-browser-different-context pattern.** Playwright `browser.newContext()`, Cypress `cy.session`, WebdriverIO multiremote — pick one and apply consistently.
- **Submission triggers manager queue auto-update without page reload.** Manager has the queue open in context A. Employee submits in context B. Within the polling window (30 s per FE refinement §7), context A renders the new row. Speed up by triggering a `visibilitychange` event or by advancing the clock.
- **Approval propagates to employee's notification feed without page reload.** Symmetric to the above.
- **Skip-level filter.** Grand-manager opens the queue with the skip-level filter on; sees a subordinate's request; approves it. Audit log records the actor type.
- **Withdraw-while-pending.** Employee withdraws; manager's queue removes the row.
- **Reject requires a reason.** Manager clicks Reject without typing a reason; inline validation error. Type a reason; submit; employee's feed shows the rejection with the reason.
- **HR override path.** HR overrides an Approved vacation to Rejected → employee notification appears → audit log entry visible in HR audit screen.
- **End-to-end vacation lifecycle as one test** — employee submits → manager approves → employee sees decision → balance refreshes → calendar updates → HR exports XLSX and the absence appears.

## 7. Document upload + HR validation E2E

- **Drag-and-drop.** Drop a fixture PDF onto the dropzone. Assert per-file progress bar + thumbnail / PDF preview rendered (PDF first-page rendered, per FE refinement §9).
- **Click-pick fallback.** File picker opens via click and via Space / Enter on the dropzone.
- **MIME rejection.** Drop a `.txt` file. Inline reason "Type not supported". File not submitted.
- **Size rejection.** Drop a > 10 MB file (use a fixture). Inline reason "File too large (12 MB > 10 MB limit)".
- **Multiple files.** Up to 5 files; each with its own progress bar + individual remove button.
- **Server-echo of type and size.** After submission, FE displays the server's reported type and size (FE refinement §9 "server is the source of truth").
- **HR queue surface.** HR sees the entry with file preview (image inline, PDF in sandboxed iframe per FE refinement §17). Approve and reject buttons present.
- **Reject flow with reason.** Required textarea; submit; absence flips to Rejected in the employee's view; employee's notification feed contains the reason.
- **Mobile viewport** — drag-and-drop replaced or supplemented by camera-capture; test at 375×667.

## 8. XLSX export download E2E (spec §11.1)

- **Trigger from HR UI.** Click "Export 2026-04 as XLSX". The download is captured (Playwright `download` event, Cypress `cy.readFile` of the downloads folder).
- **Open the workbook in the test.** Use an XLSX library inside the test (`xlsx`, `exceljs`, `openpyxl`, equivalent depending on test stack).
- **Structural assertions:**
  - Two sheets named `Dochádzka` + `Nadčas` (SK) or `Attendance` + `Overtime` (EN).
  - First row + first column frozen.
  - One row per half-day for the full calendar month.
  - Activity-label catalogue values from spec §11.1 appear in the right cells. Use a fixture month that contains at least one of every activity type.
  - Hours decimal separator follows locale (`,` SK, `.` EN).
- **Bilingual coverage.** The same export is requested in both SK and EN; both runs pass.
- **Authorization.** Employee account cannot reach the export endpoint via UI navigation (link not rendered) or via direct URL (403 / redirect).
- **Overtime sheet.** Includes only employees with at least one overtime entry that month.

## 9. Real-time + optimistic UI (FE refinement §7)

- **Optimistic submit.** Mock the API to delay 2 s. Submit a vacation request. The list immediately shows the new entry with a "saving" affordance (or the row is visible in the manager's queue mock). After the 2 s, the affordance clears.
- **Rollback on server error.** Mock the API to return 5xx. Submit. The optimistic row disappears; an error toast appears with retry. List returns to the pre-submission state.
- **Refetch-on-focus.** Switch tabs away and back; assert a refetch fires immediately on focus (FE refinement §7).
- **Visibility-throttled polling.** Hide the page (`page.evaluate('document.dispatchEvent(new Event("visibilitychange"))')` or framework equivalent); assert polling slows or stops.
- **Stale-while-revalidate.** List pages display existing data immediately during a refetch with a small refresh indicator in the corner — not a full-page spinner.

## 10. Internationalisation (FE refinement §6)

- **SK rendering (Basic).** Every smoke route renders Slovak text correctly with diacritics (`Dochádzka`, `Sviatok`, `Návšteva lekára`). Font subset must include Latin-extended.
- **EN rendering (Bonus).** Same routes in English; key-parity ensures no missing-key fallback to SK or to raw keys.
- **Locale switch mid-session.** Switch in profile or top-bar; rendered text updates live, no reload. The form does not lose state. Form labels translate; entered values are preserved; validation messages re-render in the new locale.
- **Date format.** `dd.MM.yyyy` in both locales (per FE refinement §6 in Slovak context).
- **Decimal separator.** Hours show `4,5` in SK and `4.5` in EN.
- **ICU plural rendering.** A list with one item renders the singular form; with multiple items, the plural form. Both languages.
- **Fallback path** — temporarily remove an EN key (via test fixture); assert fallback to SK plus a development-only console warning.
- **Re-trigger a hard rule after locale switch.** Error message is in the new locale.
- **XLSX export labels** translate per the locale at download time (covered in §8).

## 11. Theming light/dark/system (FE refinement §5)

- **Default = system.** First-load on a fresh browser context with the OS theme emulated as dark → app renders in dark mode (Playwright `colorScheme: 'dark'`, Cypress equivalent).
- **Manual toggle.** Switch to light → `data-theme="light"` on `<html>`; persists across reload.
- **System-mode live update.** With theme set to "system", flip the OS theme (`emulateMedia`); the page updates without reload.
- **Theme toggle mid-flow.** Toggle dark mode with the absence form half-filled. The form does not lose state. Focus ring still ≥ 3:1 contrast against the new background.
- **Contrast.** Trigger axe-core with contrast rules in both themes; assert no `serious` / `critical` violations on the primary smoke routes.

## 12. Responsive + viewport matrix (FE refinement §1)

Run the absence-submission and team-calendar smoke tests on at least these viewports:

- **375×667** (small mobile, iPhone 8) — primary touch input.
- **412×915** (large mobile, Pixel) — primary touch input.
- **768×1024** (tablet portrait).
- **1024×768** (tablet landscape).
- **1280×800** (desktop default).
- **1920×1080** (FHD) — calendar widens; no fixed-width container.

Assertions per viewport:

- No horizontal scrolling on body.
- Primary navigation degrades to bottom-tab bar or hamburger ≤ 767 px.
- Calendar grid stays usable: columns scroll horizontally on mobile, not the whole page.
- Form submit button is reachable above the on-screen keyboard on 375×667.
- Density-mode toggle (Comfortable / Compact) persists across viewport changes and across reload.
- Click targets remain ≥ 24×24 CSS px per WCAG 2.2 SC 2.5.8 across all viewports and density modes.

## 13. Accessibility audit gate (FE refinement §19.4)

- **axe-core wired into every E2E test step.** `@axe-core/playwright`, `cypress-axe`, `axe-webdriverjs`, `pa11y`. CI fails on any `serious` or `critical` finding.
- **Per-step or per-route invocation** — invoking axe once per page is too coarse; invoke after each major state change (form opened, error shown, dialog opened).
- **Lighthouse a11y ≥ 90** per smoke route (login, dashboard, calendar, absence form, approvals, HR export, document validation, admin users) — wired as a separate CI job using `lhci` or framework equivalent.
- **Keyboard-only flow.** Complete a full vacation submission flow using **keyboard only**. Tab through every field, Space / Enter for buttons, arrow keys in date pickers. Assert focus is never trapped and reaches the submit button.
- **Side-panel drill-in via keyboard.** Open and dismiss the team-calendar side panel via keyboard.
- **File-upload drop zone reachable by keyboard** (Enter / Space opens the picker per FE refinement §9).
- **Keyboard-trap negative test.** Open every modal/dialog and assert Tab cycles inside it without escaping. Esc dismisses.
- **Skip-to-content link.** First Tab on every page reveals it; activating focuses the main content.
- **Screen-reader-friendly assertions.** Each form-error inline message should be discoverable via `getByRole('alert')` or `getByText` *inside* an element with `aria-live="assertive"`.

## 14. Network-failure + error states (FE refinement §14)

- **401 mid-session.** Mock the API to return 401 on the next request. Assert silent-refresh attempt; on simulated failure, redirect to `/login` with toast.
- **403.** Employee account hits HR-only URL via direct navigation. Lands on `/forbidden`, designed page.
- **404.** Visit an absence ID that does not exist. Designed 404 page.
- **409 stale.** Two-context test: manager opens request in tab A; employee withdraws in tab B; manager clicks Approve in tab A → "This entry was updated by someone else — refresh and retry" inline dialog.
- **5xx with retry.** Form submission → 500 → error toast with retry button → retry succeeds.
- **Offline banner.** Set `context.setOffline(true)`. Banner appears at top: "You are offline — last refresh {timestamp}". Read-only navigation still works. Write attempts show inline "Cannot submit while offline".
- **Slow network.** Throttle to 3G; skeleton screens render; no layout shift (assert by capturing CLS via PerformanceObserver in-page).

## 15. Performance smoke E2E (FE refinement §10)

- **Lighthouse CI runs the smoke route set.** Performance ≥ 90, Accessibility ≥ 90, Best Practices ≥ 90 (PWA ≥ 90 only if the PWA Bonus is in scope).
- **Bundle-size diff** posted as PR comment via Lighthouse CI; fails on budget overrun (FE refinement §10 budgets: initial JS ≤ 200 KB gzip, per-route chunk ≤ 80 KB gzip).
- **Smoke timing in E2E.** Optionally assert key page-load times in the E2E suite (`page.goto` resolves within N ms). Use as a tripwire, not a precise gate.

## 16. Visual regression (Bonus, FE refinement §19.5)

Stretch axis. Add screenshot diffs per route, per theme, on PRs only. Tools: Playwright `toHaveScreenshot()`, Percy, Chromatic, Argos. Maintain a baseline branch.

## 17. Selectors + page-object discipline

- **Role + accessible name first.** `getByRole('button', { name: 'Save' })`, `findByRole('alert')`. NEVER CSS classes, NEVER `nth-child`, NEVER generated IDs.
- **`data-testid` used sparingly** — only when no accessible name exists (e.g. an icon-only IconButton without `aria-label`). Add `aria-label` first; use `data-testid` only as a fallback.
- **Page objects or composable fixtures.** Centralise selectors and flows. `e2e/pages/AbsenceForm.ts` exposes `fillVacation(...)`, `submit()`, `expectHardError(ruleId)`. Tests read like prose.
- **Text-only selectors are weaker** — counted but dock toward the low band when used as the primary selector.

## 18. Determinism + clock control

- **Inject the clock.** `page.clock.install()` (Playwright), `cy.clock()` (Cypress), framework equivalent. Every "today" / "now" must be controlled.
- **No `cy.wait(ms)` against magic numbers.** Allowed: `cy.wait('@alias')` to wait on a captured request.
- **No `setTimeout` in test steps** — wait on the actual event.
- **Seeded randomness.** If the UI generates UUIDs client-side, the test sets a fixed seed via fixture.
- **Stable date assertions.** Use the injected clock so `dd.MM.yyyy` strings are deterministic.
- **Animations disabled** for E2E (Playwright `reducedMotion: 'reduce'`, Cypress global CSS injection).

## 19. Test data + seed reset

- **Single seed entrypoint** — `make seed-e2e` or equivalent. Idempotent. Resets DB + filesystem + email mock between suites.
- **Per-test seed or per-suite seed** — pick one. If per-suite, document ordering assumptions.
- **Storage state per role.** Pre-authenticate a fixture user once per role (Employee, Manager, HR, Admin), save the storage state to disk, reuse across tests via Playwright `storageState` or Cypress `cy.session`. Avoids logging in for every test.
- **No real PII** in fixture data. `@example.test` emails, fictional names, sample PDFs.
- **Fixture files** for documents (PDF, JPEG, PNG, oversize file for size-rejection test, mistyped extension for MIME-spoof test).

## 20. Flake handling

- **No retries by default in CI.** A flaky test is a bug, not a "try again".
- **Flaky tests quarantined.** Move to `e2e/quarantine/` with a TODO and a ticket reference. Do NOT silently skip.
- **`test.fixme` / `test.skip` / `it.skip`** are forbidden in main branch. CI fails on their presence (lint rule or grep-based gate).
- **Trace / video on failure** captured and uploaded as a CI artefact (or to a Bonus reporting service).
- **One retry on the first run only** (Playwright `retries: process.env.CI ? 1 : 0`) is the pragmatic compromise; document it.

## 21. CI + parallelisation + reporting

- **Single command entrypoint.** `make e2e`, `npm run e2e`, `pnpm test:e2e`, `npx playwright test`, `npx cypress run`. Document the chosen command in `README.md`.
- **Headless** — no GUI on CI.
- **Parallelisation** — Playwright workers, Cypress parallelisation, framework equivalent. Tune workers to keep total suite under ~10 min on CI.
- **JUnit XML report** to `reports/e2e/junit/*.xml` for the scoring system.
- **HTML report** (Playwright report, Cypress dashboard, Allure) for human inspection.
- **Screenshots + videos** uploaded as artifacts on failure.
- **Smoke vs full suites.** A `make e2e-smoke` runs E1-E9 fast (~3 min) for PR gating; `make e2e` runs everything (~15 min) on main.

## 22. Cross-browser coverage (Bonus for full matrix)

- **Basic** — Chromium headless on CI.
- **Bonus** — Firefox + WebKit headless on CI (FE refinement §3). Three full runs per PR is expensive; consider:
  - Smoke set on all three engines.
  - Full suite on Chromium only.
  - Engine-specific tests for engine-specific code paths (rare in this app).

## 23. Mobile-device emulation

FE refinement §19.3 calls out mobile-viewport runs for E2 / E3 / E5 at 375×667 + 412×915. This refinement adds:

- **Touch event simulation.** Playwright `hasTouch: true`, Cypress `cy.viewport` with touch helpers. Drag-and-drop on the document upload must work via touch.
- **Camera-capture attribute.** Assert the `<input type="file">` carries `capture="environment"` on mobile viewports (FE refinement §9).
- **No hover-only affordances.** Hovering does nothing on touch; tap reveals.
- **iOS Safari quirks** — if WebKit is in scope, assert critical flows still work (date picker uses native input, autofocus does not bring up keyboard unexpectedly).

## 24. Coverage targets + reporting

E2E coverage is measured differently from unit-test coverage. Numbers below are the floor for the High band on category 10 of `agents/testing-fe.md`.

- **Critical flows (E1-E9)** — 100 % covered (all 9 implemented and passing).
- **Hard rules H1-H10 UI surface** — 100 % covered (one E2E per rule).
- **Soft rules S1-S6 UI surface** — 100 % covered (one E2E per rule).
- **Smoke routes** — Lighthouse a11y, performance, best-practices each ≥ 90.
- **Browser engines** — Chromium 100 %; Firefox + WebKit Bonus.
- **Viewports** — at least 3 distinct widths covered for the calendar + absence form.

Vanity tests written to hit a number are explicitly penalised — judges read the tests.

---

This document is the specification of the *frontend testing requirements*. The team picks the framework, the runner, and the assertion style. What the E2E tests *prove* about the user-facing behaviour is what is judged.
