# Frontend Developer — Quickstart

**Audience:** Frontend developer on a hackathon build team.
**Read time:** 5 minutes.
**Then:** open [`../frontend/fe-technical-refinement.md`](../frontend/fe-technical-refinement.md) and start producing.

---

## What you are building

The user-facing Attendance Portal — employee day, manager approvals, HR document handling, admin team config. See [`../../product-spec.md`](../../product-spec.md) §17 (UX/screens) and §13 (must-have feature list).

The OpenAPI 3.1 reference at [`../integration/api-reference.yaml`](../integration/api-reference.yaml) is the API contract. A runnable mock at [`../integration/mock-server/`](../integration/mock-server/) lets you build the FE without waiting on BE.

## Judging principle

> **The spec is the contract.** UI details not covered by §17 are your discretion — judges do not penalise reasonable choices. Pick a design system, pick component patterns, ship.

The Gherkin in [`../../acceptance/`](../../acceptance/) drives the E2E suite — your screens must support those flows.

## Stack picks — choose in the first 30 minutes

Framework-agnostic. Pick one and commit:

- **Framework:** React / Vue / Svelte / Angular / Solid / Preact / Qwik.
- **Bundler:** Vite is the safe default (works for React / Vue / Svelte / Solid). Angular has its own toolchain.
- **State:** built-in (React Query / Pinia / Svelte stores) before reaching for Redux / Zustand.
- **Styling:** any — Tailwind, CSS modules, vanilla extract, design-system kit.

No starter code. The mock server gives you a real API surface from hour 0.

## What you deliver

1. **Employee day** — calendar grid, mark workdays / absences, see approval status, see notifications.
2. **Manager view** — approvals queue, team calendar, self-approval guard surfaced in UI.
3. **HR view** — document validation, reject with reason (stored + emailed if email feature is on).
4. **Admin view** — team config, holidays, project codes (per spec §17).
5. **Mock-login UI** — pick a user, no real auth required for Basic.
6. **XLSX export trigger** — button → download (BE owns the file).
7. **Responsive + theming + a11y** — see FE refinement §1, §4, §5.

## Day shape — suggested

| Track | What you produce |
|---|---|
| **Skeleton pass (h0–h1)** | Scaffold app, routing, mock-login page, hit `/me` on the mock server. CI green on empty test suite. |
| **Calendar pass (h1–h3)** | Calendar grid component. Mark workdays / absences. Wire to mock server. |
| **Approval pass (h3–h5)** | Manager approvals queue. Self-approval guard visible (button disabled + tooltip). |
| **Document pass (h4–h6)** | Upload UI + HR validation view. Reject-with-reason form. |
| **Admin pass (h5–h7)** | Team / holiday / project-code config. |
| **Polish pass (h7–end)** | Loading + empty + error states. A11y audit pass. Dark mode. Responsive sanity check on mobile + desktop. |

Switch from mock server to real BE as soon as the BE dev's endpoints land. Should be a base URL change.

## AI tooling — your specific use

High-leverage FE use is **scaffolding screens from spec §17** + **generating form validation from rule definitions** + **building the calendar component** (date math is high-bug-density).

Prompt template:

```
You are helping me build an Attendance Portal frontend.

Context:
- Spec section: [paste product-spec.md §17.<N>]
- API endpoint: [paste from api-reference.yaml]
- Stack: [React + Vite + Tailwind + React Query]

Task:
Generate the [page / component] for <X>.
Include: loading state, error state, optimistic update (where the spec allows),
accessible form labels, keyboard nav.
```

Then **trim and theme**. The AI will produce generic Bootstrap-looking UI. Apply your design system, cut anything not in §17, and verify keyboard / screen-reader behaviour on the critical flows.

## What "good" looks like

- All `acceptance/employee.feature` + `acceptance/manager.feature` E2E scenarios pass.
- Calendar renders within the FE perf budget (FE refinement §10).
- Forms have visible validation; error states are not silent.
- A11y: keyboard reaches every interactive element; visible focus ring; semantic HTML; WCAG 2.2 AA on the critical flows.
- Dark mode works (no white flashes on load).
- Responsive: usable at 360px width and at 1440px+.
- API contract obeyed — no hand-rolled shapes that diverge from `api-reference.yaml`.

## Common failure modes (avoid)

- **Building screens before deciding the design system.** Inconsistent button styles cost polish points. Pick a tokens set in hour 0.
- **Hand-rolling the calendar grid for a week.** Use a library if one fits (FullCalendar, vue-cal, react-big-calendar) — the spec does not award points for from-scratch date math.
- **Coupling components to the BE shape.** Adapt at the data layer (React Query selectors, Vuex/Pinia getters, Svelte stores). Components consume view models.
- **Skipping loading + empty + error states.** Judges open the app with no data. Empty states matter for polish.
- **A11y as an afterthought.** Adding `aria-label` everywhere on h7 is fake compliance. Use semantic HTML from h0.
- **Bonus axes before Basic ≥ 90%.** Same gate as everyone else. Don't.

## Links

- [`../frontend/fe-technical-refinement.md`](../frontend/fe-technical-refinement.md) — full FE refinement (responsive, PWA, a11y, theming, i18n, real-time, auth, perf, design system, state, forms, security, testing, build, code architecture).
- [`../integration/api-reference.yaml`](../integration/api-reference.yaml) — OpenAPI 3.1 contract.
- [`../integration/mock-server/`](../integration/mock-server/) — runnable mock API (use it before BE is ready).
- [`../../product-spec.md`](../../product-spec.md) §17 — UX / screens. Read first.
- [`../../product-spec.md`](../../product-spec.md) §13 — must-have feature list.
- [`../../acceptance/`](../../acceptance/) — Gherkin scenarios FE QA exercises.
- [`../../README.md`](../../README.md) — overall judging rubric + ground rules.
