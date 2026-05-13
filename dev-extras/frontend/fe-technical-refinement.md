# Attendance Portal — Frontend Technical Refinement

**Status:** Hackathon brief — single-day build window, team sizes 2-7, senior engineers with strong AI tooling.
**Scope:** Frontend only. Framework-agnostic technical requirements. Teams pick the actual stack (React / Vue / Svelte / Angular / Solid / etc.).
**Companion doc (canonical):** `hackathon-may-2026-attendance-portal/product-spec.md` — read first. This FE doc layers on top of the product spec and inherits the Basic / Bonus tier model + judging rubric.
**Date:** 2026-05-11

## Tier mapping — what is Basic vs Bonus on the FE

The product spec's tier gate (Basic ≥ 90 % before any Bonus is counted) applies to FE requirements too. The table below maps each section of this doc to its tier so teams do not accidentally over-invest before Basic is green.

| Section | Tier | Notes |
|---|---|---|
| §1 Devices + responsive | **Basic** | Desktop + mobile both expected on the demo viewport set. Ultrawide-aware layout is also Basic — no fixed max-width container. |
| §2 PWA + offline | **Bonus** | Per product-spec §14: PWA / installable shell is a Bonus axis. Skip the service worker until Basic Gherkin is green. |
| §3 Browser matrix | **Basic** | Modern evergreen only. |
| §4 Accessibility WCAG 2.2 AA | **Basic** | The `axe-core` and Lighthouse a11y gates contribute to the **Polish 10 pts** rubric axis. |
| §5 Theming (light/dark/system) | **Basic** | Tokens-driven; system preference is the default. Cheap to keep. |
| §6 i18n | **Basic** for SK (default language); **Bonus** for second locale (EN). Per product-spec §14 multi-language Bonus axis. The translation catalogue infrastructure is Basic so a second locale is a drop-in later. |
| §7 Real-time | **Basic** = polling + optimistic UI. **Bonus** = websocket / SSE push (per product-spec §14). |
| §8 Auth | **Basic** = mock-login (pick user, no password). **Bonus** = real OIDC / magic-link / password + bcrypt. |
| §9 File upload UX | **Basic** | Documents are required for Paragraph/OCR/Special (H8) — without upload UX the Basic flow fails. Camera capture is desirable but acceptable to drop if mobile (§14 mobile-friendly) is also being skipped. |
| §10 Performance budgets | **Basic** | Lighthouse CI scores feed the **Polish 10 pts** and contribute to bundle-size sanity in the scoring system. |
| §11 Design system | **Basic** | Pick A / B / D (never build all atoms from scratch); tokens-driven. |
| §12-16 State / forms / loading-states / notifications / routing | **Basic** | These are the shell + interaction quality bar; Basic Gherkin will fail without them. |
| §17 Security | **Basic** | Contributes to the **Security 10 pts** rubric axis. The scoring system runs `gitleaks`, `trivy fs`, `semgrep --config=auto` + hackathon ruleset against your repo. |
| §18 Telemetry | **Bonus** | Useful but skippable until Basic is green. |
| §19 Testing | **Basic** for unit + integration + axe-core gate. **E2E** is Basic for the §13 critical flows; broader E2E and visual regression are Bonus polish. |
| §20 Build + deploy | **Basic** | Repo builds + tests with stack-conventional commands; `TEAM.md` present at repo root. |
| §21 Code architecture | **Basic** | Layering contributes to the **Code Quality 10 pts** rubric axis (`jscpd` for duplication, AI fallback for structure). |
| §22 Code-quality rules | **Basic** | Same rubric axis. Strict types + no module-level singletons + lint-enforced layering. |
| §23 Dependency injection | **Basic** | Foundation for the §22 layering and §19 testing. |
| §24 Date / time / TZ | **Basic** | Attendance correctness depends on TZ handling; Basic Gherkin will fail in DST edge cases without it. |
| §25 API contract | **Basic** | Required for FE/BE alignment; the scoring system replays scenarios that depend on response shapes matching the spec. |
| §26 Concurrent edit / conflict | **Basic** (UX) — at minimum show a sensible 409 dialog and offer refresh-and-retry. ETag round-trip is **Bonus**. |
| §27 Persisted-state migration | **Bonus** | Hackathon scope rarely ships multiple deploys to the same browser. Skip unless time allows. |
| §28 Export confidentiality | **Basic** (filename + role check + no PII in URLs). **Bonus**: download watermark. |
| §29 Resilience | **Basic** (timeout + abort) — circuit breaker is **Bonus**. |
| §30 Feature flags | **Bonus** | Worth it only if you actually intend to ship more than one stretch axis. |
| §31 Logging | **Basic** | Cheap; protects you in the scoring system's Security pass. |
| §32 Local dev setup | **Basic** | The scoring system pulls your `main` branch; the bootstrap path must work cold with stack-conventional commands. |
| §33 Definition of Done | **Basic** | Process gate. |
| §34 Print styles | **Bonus** | Polish axis only. |
| §35 Keyboard shortcuts | **Bonus** | Polish axis only. The discoverable `?` overlay alone is acceptable. |
| §36 Onboarding tour | **Bonus** | Polish axis only. |
| §37 Heavy library policy | **Basic** | Hits Lighthouse Performance ≥ 90 gate. |
| §38 Privacy / consent | **Basic** | Slovak labour law + GDPR. The first-login privacy notice is mandatory. |

The **external scoring system** (per repo `README.md`) pulls each team's `main` branch and runs lane-specific evaluation. For the FE lane:
- `TEAM.md` present at repo root with a member whose `role` includes `FE`.
- Repo builds + tests with stack-conventional commands (e.g. `npm install && npm test`).
- Repo passes `gitleaks`, `trivy fs`, `jscpd`, `semgrep --config=auto` + hackathon ruleset.
- Your unit + integration + E2E suites are runnable headless.
- AI passes scrutinise architecture, DRY, security of declared high-risk paths, test quality, and Bonus Gherkin conformance.

Sections §17, §19, §20 below cover the FE side of each.

---

## 1. Device support + responsive

The portal targets a full range of screen sizes. **Mobile-first** authoring with progressive enhancement, no fixed maximum-width container.

- **Breakpoints:**
  - Mobile: 320 - 767 px
  - Tablet: 768 - 1023 px
  - Desktop: 1024 - 1919 px
  - Full-HD+: 1920 - 2559 px
  - Ultrawide: 2560 - 3439 px
  - 4K / UHD: 3440 px and above
- **Layout strategy:** fluid widths + CSS Grid with `auto-fill` / `minmax`. Dashboards add columns on wider screens (4-6 cards visible at FHD+, 6-8 on ultrawide). Team-calendar grid widens; horizontal scroll only when truly necessary.
- **Density modes:** "Comfortable" (default) and "Compact". Persisted on the user profile alongside locale and theme. Useful for HR/Admin who live in the portal.
- **Pointer:** primary touch on ≤767, hover-aware on ≥1024, hybrid in between. No hover-only affordances.
- **Orientation:** portrait + landscape both work on mobile and tablet.

## 2. PWA + offline

> **Tier note (product-spec §14).** PWA / installable shell is a **Bonus** axis. Skip the service worker until Basic Gherkin is green. The rest of this section becomes relevant only when the Bonus is in scope.

Installable, offline-tolerant shell. Read-only after-offline behaviour for v1.

- **Installable** via Web App Manifest: maskable icons (192, 512, 1024), `display: standalone`, dynamic `theme_color` derived from current theme.
- **Service worker scope:** app shell (HTML/CSS/JS) + static assets only. Pre-cache build manifest; runtime cache for fonts.
- **Offline behaviour:** app loads, navigates between cached routes. Any API request shows a non-blocking offline banner "You are offline — last refresh {timestamp}". Write attempts are blocked client-side with an inline message "Cannot submit while offline".
- **No queued writes.** Absence rules (consecutive-sickday, quota) require server truth; offline replay creates conflicts. Out of scope for v1.
- **Update flow:** new service worker version on activate shows an in-app prompt "New version available — refresh?" with a button. No silent forced reloads.
- **Push notifications:** out of scope for v1. Stretch.

## 3. Browser support matrix

Modern evergreen only. Internal app, IT-managed corporate environment expected.

- **Baseline:**
  - Desktop: last 2 versions of Chrome, Edge, Firefox, Safari.
  - Mobile: last 2 versions of iOS Safari, Chrome Android.
- **No IE11, no legacy Edge, no Opera Mini.**
- **Allowed modern features:** ES2022, CSS subgrid, container queries, `:has()`, native `<dialog>`, View Transitions API.
- **No polyfills shipped.** A user on an unsupported browser sees a banner "Please update your browser to continue".
- **CI runs E2E on at least one Chromium + Firefox + WebKit headless build.**

## 4. Accessibility — WCAG 2.2 AA

Mandatory bar. Internal app touching disability-related data (sickdays, PN, OCR).

- **Keyboard:** every interactive control reachable + operable from the keyboard alone. Visible focus ring with ≥ 3:1 contrast against background. No keyboard traps. Skip-to-content link at the top of every page.
- **Screen reader:** semantic HTML first (`<button>`, `<table>`, `<nav>`, `<dialog>`). ARIA only where semantics do not fit. Form fields use real `<label>`s + programmatically associated descriptions + error messages.
- **Contrast:** body text ≥ 4.5:1, large text ≥ 3:1, UI components and graphical objects ≥ 3:1. Validation reds and warning yellows are tested against background in both themes.
- **Target size:** clickable area ≥ 24 × 24 CSS px (WCAG 2.2 SC 2.5.8). Calendar cells, approval action buttons, file-delete icons all meet this.
- **Motion:** respect `prefers-reduced-motion`. Calendar animations and side-panel slides fall back to instant.
- **Form errors:** announced via `aria-live="polite"` on inline messages and `aria-invalid` on the field. Required fields marked with text "(required)", not just colour or asterisk.
- **Tables:** team-calendar grid uses `<table>` with `<th scope="row">` per employee and `<th scope="col">` per day; `<caption>` present.
- **Audit gate (CI):** `axe-core` automated audit runs in CI on the built bundle. Pull requests fail on any `serious` or `critical` violation.
- **Manual audit:** one keyboard-only walkthrough plus one screen-reader walkthrough (NVDA on Windows, VoiceOver on macOS/iOS) per main flow (login, log worktime, submit vacation, approve, upload document) before demo.

## 5. Theming — light + dark + system

- **Storage:** user-profile field `theme: "light" | "dark" | "system"`. Default `system`. Persisted on the user record so it follows across devices.
- **Implementation:** CSS custom properties on `:root`. Theme switch toggles `data-theme="dark"` on `<html>` → variables rebind, no JS re-render needed.
- **Token scope:** colour (surface, text, border, accent, semantic states), radius, shadow, focus ring. Spacing and type ramp are theme-independent.
- **System mode:** listens to `prefers-color-scheme`. Live-updates if the OS theme changes mid-session.
- **Logos and screenshots:** SVG logos use `currentColor` where possible; raster assets ship in both light and dark variants.
- **Contrast verified in both themes** as part of the accessibility CI gate.

## 6. Internationalisation

> **Tier note (product-spec §14).** Slovak alone = **Basic** (the demo language). A second locale (English) is **Bonus** — the "Multi-language UI" axis. The catalogue + lookup infrastructure described below is **Basic** so a translator can drop in a second locale later without code changes.

- **Baseline locales:** Slovak (default for new users). English is the first Bonus locale. Switch in user profile is **live**; no reload, no re-login.
- **Catalogue:** flat key-value JSON per locale, namespaced by feature (e.g. `absence.submit.button`). Owned by translators, not developers.
- **What is translated:** UI labels, validation messages, email templates, document-decision reasons (predefined codes), XLSX export labels (per functional-doc §11.1).
- **What is NOT translated:** dates (locale-appropriate format: `dd.MM.yyyy` for both SK and EN given the SK context), numbers (decimal separator `.` for EN, `,` for SK), employee names, free-text notes, file names.
- **Pluralisation:** ICU MessageFormat. Both SK and EN plural rules baked in. Example: `{count, plural, one {# day} other {# days}}`.
- **Fallback:** missing key in active locale → fall back to Slovak → fall back to the raw key. Console warning in development only.
- **CI step:** key parity check across locale files. Any missing or stale key fails the build.
- **RTL:** out of scope. Layout uses logical properties (`margin-inline-start`, not `margin-left`) so RTL can be added later without rework.
- **Adding a new locale = translator copying the SK file and editing.** No code changes.

## 7. Real-time update strategy

- **Baseline = polling + optimistic UI.** Locks in this combination explicitly; websockets are a stretch.
- **Polling cadence:**
  - Approvals queue (manager) and documents queue (HR): every **30 s** when tab visible, every **5 min** when hidden, **instantly** on focus.
  - Team calendar: every **60 s** when visible.
  - Own balances and own entries: refetch on every navigation to the page; no background polling.
  - Notifications inbox: every **30 s** when visible.
- **Optimistic UI:** own submit / withdraw / cancel / approve / reject mutations update local UI instantly. On server error → snap back to server state + show error toast. On server success returning different shape (e.g. recalculated quota) → reconcile silently.
- **Stale-while-revalidate:** every list refetch shows last data immediately and spins a small refresh indicator in the corner. No full-page spinner on poll cycles.
- **Visibility detection** via `document.visibilityState` to throttle polling when hidden, save battery on mobile.
- **Stretch — websocket / SSE push:** if implemented, replaces polling for approvals + notifications. Polling stays as fallback when the socket fails.

## 8. Authentication and session

> **Tier note.** **Basic = mock-login** — a user-picker bound to seeded fixture users; no password. The whole flow below (OIDC + PKCE) is the **Bonus** real-auth path. Implement the Basic path first; teams that finish Basic with time left implement the OIDC path and declare it in `TEAM.md` notes.

- **Protocol (Bonus):** OIDC standard. Authorisation Code + PKCE flow. No implicit, no resource-owner-password.
- **Provider:** team picks (Auth0, Keycloak, Microsoft, Google, or a mock issuer for the hackathon demo).
- **Token storage:** access token + ID token in `sessionStorage`. Refresh token is NOT stored client-side — silent refresh via the IdP's iframe / `prompt=none` redirect.
- **XSS hardening required** because tokens are JS-readable. See §17 for the full CSP. Critical points:
  - No inline scripts.
  - No `dangerouslySetInnerHTML` / `v-html` / `[innerHTML]` outside an explicit sanitised allow-list.
  - File previews open in a sandboxed `<iframe sandbox="allow-same-origin">` only.
- **Idle timeout:** 30 min inactivity → silent refresh attempt → if refresh fails, redirect to login.
- **Hard expiry:** 12 h since login → forced re-auth.
- **Multi-tab:** broadcast token-refresh and logout events across tabs via `BroadcastChannel`.
- **Logout:** clears `sessionStorage`, hits IdP end-session endpoint, redirects to `/logged-out`.
- **Demo fallback:** a mock issuer that lets demoers pick a user without setting up an external IdP. Behind a non-production guard.

## 9. File upload UX

Used for paragraph / OCR / special-leave document confirmations.

- **Triggers:** drag-and-drop zone + click-to-pick button + camera capture on mobile (`<input type="file" accept="image/*,application/pdf" capture="environment" multiple>`).
- **Multi-file:** up to **5 files per upload, max 10 MB each**. Both numbers globally configurable by Admin.
- **Accepted types:** PDF, JPEG, PNG, HEIC. Rejected files show inline reason ("File too large (12 MB > 10 MB limit)", "Type not supported").
- **Preview before submit:**
  - Image: thumbnail rendered from `URL.createObjectURL`.
  - PDF: first-page rendered using a PDF rendering worker (e.g. PDF.js or equivalent — framework-agnostic).
  - HEIC: convert to JPEG preview client-side or show a generic icon if the conversion library is not bundled.
- **Progress:** per-file progress bar, individual cancel button, retry-on-failure with exponential backoff.
- **State after upload:** thumbnails persist on the form; user can remove individual files before submitting the absence request.
- **Security:** server is the source of truth for type and size; client checks are UX-only. The UI must display the size and type returned by the server so a spoofed extension does not mislead HR during validation.
- **Camera capture** falls back gracefully when the browser does not honour the `capture` attribute.
- **Accessibility:** drop zone has `role="button"`, is keyboard-pickable (Enter / Space opens the file picker), and uses `aria-describedby` to point to the constraints (size, type, count).

## 10. Performance budgets

Targets measured at the 75th percentile on a mid-range mobile device on simulated 4G.

- **Core Web Vitals:**
  - LCP ≤ 2.5 s
  - INP ≤ 200 ms
  - CLS ≤ 0.1
- **Bundle budgets:**
  - Initial JS ≤ 200 KB gzip
  - Per-route chunk ≤ 80 KB gzip
  - Initial CSS ≤ 50 KB gzip
  - Fonts: max 2 weights, Latin + Latin-extended subset (Slovak diacritics), `font-display: swap`, preloaded
- **Images:** WebP everywhere; avatars and previews lazy-loaded with `loading="lazy"`; PDF first-page previews rendered on demand.
- **CI gates** (Lighthouse CI on smoke routes — login, dashboard, calendar, absence form, approvals, HR export, document validation, admin users):
  - Performance ≥ 90
  - Accessibility ≥ 90
  - Best Practices ≥ 90
  - PWA ≥ 90
  - Bundle-size diff vs `main` posted as a PR comment; fails on budget overrun.
- **Runtime:**
  - Team-calendar grid is virtualised when ≥ 50 employees × 31 days (~1500 cells).
  - List virtualisation kicks in at > 100 rows for approvals queue, audit log, notifications inbox.
  - Date pickers and dropdowns are code-split, loaded on first open.
- **No render-blocking 3rd-party scripts.** Telemetry beacons (if any) are async, deferred until after first paint.
- **Stretch:** real-user monitoring via a self-hosted, privacy-respecting beacon (no third-party trackers).

## 11. Design system + tokens

Teams must adopt one of these three patterns. Building every atom from scratch is **forbidden** — accessibility is too hard to get right alone within a single-day window.

- **Option A.** Headless component library (Radix / Headless UI / Ariakit or framework-equivalent) + custom styling.
- **Option B.** Styled component library (MUI / Mantine / Ant / Chakra or equivalent) that supports tokens + dark mode out of the box.
- **Option D.** Hybrid — A's primitives where flexibility matters (dialog, popover, dropdown, tabs) + small custom atoms for the rest, tokens-driven.

**Required: shared design-token JSON** consumed by both themes. Required keys:

- **Colour:** `surface.{base|raised|sunken|inverse}`, `text.{primary|secondary|muted|inverse}`, `border.{default|focus|error|warning|success}`, `accent.{primary|secondary}`, `state.{error|warning|success|info}` (each with `bg` + `fg`).
- **Spacing scale:** 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 px. No magic numbers in CSS.
- **Type ramp:** caption / body / body-strong / heading-sm / heading-md / heading-lg / display. Line-height and weight set per role.
- **Radius:** 0 / 4 / 8 / 12 / 999 (pill).
- **Shadow:** elevation-0 / 1 / 2 / 3 (each defined for light and dark).
- **Focus ring:** width + offset + colour (one per theme).

Tokens are consumed via CSS custom properties so theme switching is runtime, no JS re-render needed. The token file is kept framework-agnostic so a native build could pick it up later.

**Component coverage required for the app:**
Button (primary / secondary / ghost / danger), Input, Textarea, Select, Date picker, Time picker, File-drop zone, Checkbox, Radio, Switch, Tabs, Dialog / modal, Side panel / drawer, Popover, Tooltip, Toast, Badge, Avatar, Card, Table, Skeleton loader, Empty-state illustration, Calendar cell, Stepper.

**Documentation:** every component gets a one-page reference (props, a11y notes, do / don't). Storybook if time allows; otherwise a `/styleguide` route inside the app.

## 12. State management patterns

- **Server state** (everything fetched from the API: balances, entries, approvals, documents, calendar) — managed by a query / caching layer (TanStack Query, SWR, RTK Query, Apollo, or framework-equivalent). Each query specifies: cache key, staleness, refetch-on-focus, optimistic mutation, rollback on error.
- **UI state** (modal open, form draft, side-panel selection, theme, density, locale) — local component state for ephemeral; an app-level store (Zustand / Pinia / Signals / context, framework-equivalent) for cross-cutting.
- **No globalising of server state.** Server state never lives in the app-level store — only in the query cache. Avoids two sources of truth.
- **No prop-drilling beyond 2 levels.** Deeper goes through context or store.
- **Forms** have their own local state (see §13) — neither in server cache nor in the global store until submitted.
- **URL is part of state:** filters, pagination, sort, selected month, picked team are encoded as query params. Links, browser back / forward, reloads all behave correctly.
- **Hydration:** if SSR is used, server state is dehydrated → client rehydrates. SPA-only: query cache is pre-warmed from an in-memory snapshot when navigating between routes.

## 13. Forms and validation UX

- **Validation timing:**
  - **On blur** for individual fields (do not yell while typing).
  - **On submit** for whole-form errors (overlap, quota, consecutive sickday).
  - **Live** (debounced ~250 ms) for fields that drive the live balance preview, e.g. absence date-range changes → remaining-balance badge updates immediately.
- **Error display:**
  - Hard-rule violations: red inline message under the field + top-of-form summary "Cannot save: 2 issues — fix and try again" with anchor links to each invalid field. `aria-live="assertive"` for the summary, `aria-invalid` per field.
  - Soft warnings: yellow inline + a distinct "Save anyway" button next to "Save". `aria-live="polite"`.
- **Submit button states:** Idle → Submitting (spinner, disabled) → Success (confirmation toast, button resets) → Error (button re-enabled, toast + inline error).
- **Draft preservation:** open forms auto-save to `sessionStorage` every 5 s; restored if the user navigates away accidentally and returns. Cleared on successful submit or explicit cancel.
- **Date picker:** native on mobile (better UX); custom on desktop (consistent with theme, keyboard-friendly per WCAG). Weekends + holidays visually marked; picking a holiday raises the appropriate soft warning inline.
- **Half-day picker:** two radio chips (Morning / Afternoon), shown only when "half day" mode is selected.
- **Live balance badge** on the absence form: shows current remaining + projected remaining after this submission. Re-computes on every date change.
- **Multi-step flows:** vacation submission is at most 2 steps (Form → Confirm). Document-required flows show the upload section conditionally rather than as a separate step. No 4-step wizards.

## 14. Loading, empty, error states

- **Loading skeletons** for every list and card; no spinners except inline button state and global refresh indicators. Skeletons match the eventual layout shape so the page does not shift on load (CLS budget).
- **Empty states are designed, not blank:**
  - Pending approvals: "No requests waiting on you" + illustration + secondary CTA "View team calendar".
  - Documents queue: "All documents validated" + illustration.
  - My entries (new user): "No entries yet — log your first day" + primary CTA.
  - Calendar (no team yet): "You are not on a team — ask an Admin to add you".
- **Error boundaries at three levels:**
  - **Route-level:** full-page "Something went wrong — reload" with a "Report this" link.
  - **Card-level:** in-place error card with retry button; surrounding UI unaffected.
  - **Inline action:** toast + inline rollback for failed mutations.
- **Offline state:** non-blocking top banner "You are offline — last refresh {timestamp}". Read-only flows still work; write attempts show "Cannot submit while offline" inline.
- **Network errors have specific messages where possible:**
  - 401 → re-auth prompt
  - 403 → "You don't have permission"
  - 409 → "This entry was updated by someone else — refresh and retry"
  - 5xx → "Server error — try again in a minute"

## 15. Notifications surface (in-app)

- **Toast** (transient): 4 s default for info / success, 7 s for warnings, sticky until dismissed for errors. Top-right on desktop, top-centre on mobile. Stacked with a max of 3 visible; older ones queue.
- **Notifications inbox** (persistent): bell icon in the top bar with an unread badge. Click → side panel listing all notifications the user received (mirrors emails sent to them, per functional-doc §10). Filterable by kind, sorted newest first. Mark-as-read on click; "Mark all read" action.
- **Deep links:** clicking a notification navigates to the source object (approval, absence, document).
- **Mobile:** bell + side panel become a full-screen sheet.

## 16. Routing and navigation

- **Routes (minimum set):**
  - `/login`, `/logged-out`
  - `/` — role-aware dashboard (resolves at runtime to employee / manager / HR / admin home)
  - `/me/balances`, `/me/entries`, `/me/notifications`, `/me/profile`
  - `/absences/new`, `/absences/:id`
  - `/worktime/new`, `/worktime/:id`
  - `/overtime/new`, `/overtime/:id`
  - `/team-calendar?team={id}&month={yyyy-mm}` (manager + HR)
  - `/approvals` (manager + HR queue)
  - `/documents` (HR queue)
  - `/reports/monthly`, `/reports/balances`, `/reports/audit-log` (HR + admin)
  - `/admin/users`, `/admin/teams`, `/admin/quotas`, `/admin/holidays`, `/admin/settings`
  - `/styleguide` (development only)
- **Guards:** every route declares required role(s). Users lacking a role land on `/forbidden` — do not silently redirect, it confuses managers who are also employees.
- **Layout shell:** persistent top bar (logo, locale switcher, theme switcher, notifications bell, profile menu) + left rail nav (collapses to a bottom-tab bar on mobile). Content area scrolls; shell is fixed.
- **Navigation events:** every route change announces a friendly page title to screen readers via `aria-live="polite"` on a hidden `<h1>`.
- **404 + 403** are real designed pages, not generic browser errors.
- **Deep linking** works for every list filter, picked team, picked month, selected entry. Refresh restores the same view.

## 17. Security hardening (FE)

### Content-Security-Policy (strict, response-header preferred)

```
default-src 'self';
script-src 'self';
style-src 'self' 'unsafe-inline';
img-src 'self' data: blob:;
font-src 'self';
connect-src 'self' {api_origin} {idp_origin} {telemetry_origin};
frame-src 'self' {idp_origin};
frame-ancestors 'none';
object-src 'none';
base-uri 'self';
form-action 'self' {idp_origin};
```

If the framework requires hashed inline scripts, use SHA-256 hash or per-request nonce; do not weaken to `unsafe-inline` or `unsafe-eval`. Prefer extracted styles to remove the `style-src 'unsafe-inline'` allowance.

### Other security headers

- `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: camera=(self), microphone=(), geolocation=(), payment=()`

### XSS hygiene

- No `dangerouslySetInnerHTML` / `v-html` / `[innerHTML]` outside an explicit allow-list of sanitised fields.
- User-supplied notes + file names are auto-escaped by the framework's templating engine; if rendered into attribute values, additionally encoded.
- File previews in `<iframe sandbox="allow-same-origin">` only — `allow-scripts` is never permitted.

### Token-storage hardening

Because tokens live in `sessionStorage` (per §8):

- Strict CSP above blocks injected `<script>`.
- `BroadcastChannel` clears tokens across tabs on logout.
- `visibilitychange` listener: if the tab has been hidden longer than the idle timeout, clear the in-memory copy and require re-auth on focus.
- Never log tokens to console or to telemetry.

### Transport

- HTTPS only in production. The service worker only registers on HTTPS / localhost.
- No mixed content. All assets and API calls over HTTPS.
- Subresource Integrity (SRI) on any CDN-loaded font or asset. Prefer self-hosting fonts to skip SRI altogether.

### Dependency hygiene

- Dependency audit runs in CI on every PR. Fails on `high` or `critical` advisories.

## 18. Telemetry + analytics

- **In scope:**
  - **Errors:** unhandled exceptions, unhandled promise rejections, framework error-boundary events are reported to a server endpoint (Sentry-style — self-hosted or commercial, team picks). Scrubbed of tokens, emails, file names.
  - **Performance:** Core Web Vitals beacon (LCP, INP, CLS) per session, sampled.
  - **Audit-relevant events** (login success / failure, role impersonation by HR) go to the **backend audit log**, not FE telemetry.
- **Out of scope for v1:** product analytics (PostHog, Mixpanel, Amplitude). Stretch if HR + Admin want usage patterns.
- **Privacy:**
  - GDPR-compliant: no third-party trackers, no cookies for analytics, IPs hashed or truncated, opt-out toggle in the user profile.
  - No PII (emails, names, document content) in error payloads — only user IDs.
- **DNT:** if the browser sends `DNT: 1` or the user has opted out, no beacons are sent.
- **Telemetry endpoint origin** is added to `connect-src` in CSP.

## 19. Testing strategy (FE)

Three layers + an accessibility audit gate.

### 19.1 Unit (component level)

- Every leaf component: render with realistic props, assert presence of role + label, simulate keyboard + pointer interaction.
- Token-driven theming components are rendered in both light + dark, asserting colour contrast via `axe-core` snapshot.
- Pure helpers (date math, formatters, validation-message lookup, locale fallback) fully unit-tested.

### 19.2 Integration (page level)

- Each page rendered with a mocked API (MSW or equivalent). Tests cover the page's golden path + one error path + one empty-state path.
- Form submission flows: invalid field → inline error → fix → submit → success toast → list updates.
- Routing: navigate via in-app links, assert URL + page title + page-level `<h1>`.

### 19.3 End-to-end (real browser)

- Tool: Playwright (or equivalent supporting Chromium + WebKit + Firefox).
- Required critical-flow tests (each mapped to functional-doc §13 MVP acceptance):
  - **E1.** Admin creates team + user; login as that user.
  - **E2.** Log worktime; visible on own dashboard.
  - **E3.** Submit vacation → approve as manager → balance decrement.
  - **E4.** Sickday consecutive blocked with the right inline message.
  - **E5.** Paragraph + document upload → HR validate → reject path refunds quota.
  - **E6.** Overtime retroactive → manager rejects → marked uncompensated.
  - **E7.** Team-calendar grid renders for current month.
  - **E8.** HR exports monthly XLSX; downloaded file matches the schema, **for both SK and EN runs**.
  - **E9.** Year-rollover dry-run preview shows the right outcomes (carry-over within limit, exceeding limit with bonus loss, zero leftover).
- Mobile-viewport runs for E2, E3, E5 (camera-capture form path) at 375×667 + 412×915.

### 19.4 Accessibility audit gate

- `axe-core` runs on every E2E test step. PR fails on any `serious` or `critical` finding.
- Lighthouse a11y score ≥ 90 per smoke route.

### 19.5 Visual regression (stretch)

- Screenshot diff per route, per theme, on PRs only.

### 19.6 Coverage targets

- ≥ 80 % statement coverage on tokens / formatters / helpers / validation.
- ≥ 60 % overall component coverage.
- Coverage is a guide, not a hard gate. Do not write meaningless tests to hit a number.

## 20. Build and deployment shape

> **Tier note.** The external scoring system (per repo `README.md`) pulls each team's `main` branch and runs lane-specific evaluation. No special entrypoint — stack-conventional commands are used. `TEAM.md` at the repo root is mandatory; without it your team is skipped. **Basic** therefore includes: `TEAM.md` present + filled, stack-conventional build/test commands work cold, repo passes `gitleaks` / `trivy fs` / `jscpd` / `semgrep --config=auto`.

- **Single-page app baseline.** SSR optional. If the chosen framework offers SSR cheaply (Next, Nuxt, SvelteKit, etc.), enable it for the landing / login routes only — SEO is not a goal, but SSR helps LCP.
- **Build output:**
  - Hashed asset filenames + long-cache headers (`Cache-Control: public, max-age=31536000, immutable`).
  - `index.html` has `Cache-Control: no-cache` so service-worker updates land instantly.
  - Service worker is at the top level, named per framework default, versioned.
- **Environments:** local, staging, production. Each gets its own IdP issuer URL, API origin, CSP `connect-src`. Environment config is injected at build time via env vars, not baked into source.
- **Hosting target:** team picks. Static-host (Netlify, Vercel, Cloudflare Pages, S3+CloudFront, Nginx) or single-container (Caddy serving the dist + a reverse-proxy to the API on `/api`). Both must be capable of setting the security headers in §17.
- **CI pipeline (per PR):**
  1. Install dependencies (cached).
  2. Lint + type-check.
  3. Unit + integration tests with coverage.
  4. Build.
  5. Bundle-size gate vs `main`.
  6. Lighthouse CI on smoke routes.
  7. E2E (Playwright) headless across Chromium + WebKit + Firefox.
  8. Accessibility gate (`axe-core` from E2E + Lighthouse a11y).
  9. Dependency audit.
  10. Visual regression (stretch).
- **CI = scoring parity (Basic):** wire your CI to run the same stack-conventional commands the scoring system uses (`npm install && npm test`, `pytest`, etc.). Same chain locally and in CI: install → lint → type-check → test → build → bundle-size gate → lighthouse → E2E → axe. Each step exits non-zero on failure.
- **`TEAM.md` requirements** (per repo `README.md` *TEAM.md — team manifest*): team display name, members (with `role` including `FE` for FE-lane scoring + git-commit email match), stack. Declare intentional scope cuts and high-risk paths in the notes body — FE high-risk paths typically include: auth flow, file upload, document preview iframe, export download endpoint, anywhere user-supplied notes are rendered.
- **Release flow:** merge to `main` → auto-deploy to staging → manual promote to production. Service worker activates on the user's next visit; the user is prompted to refresh.
- **Rollback:** previous build artefact retained for at least 7 days; promote-back is a single-command operation.
- **No secrets in the FE bundle.** Anything starting with `VITE_PUBLIC_` / `NEXT_PUBLIC_` / equivalent is shipped to the browser and must be considered public. API keys, IdP client secrets stay server-side.

---

## 21. Code architecture — layering and module boundaries

The FE codebase is split into **layers** with one-way dependencies. Higher layers may call lower layers; never the reverse.

```
┌───────────────────────────────────────────────────────────────┐
│ Presentation       routes, pages, components, hooks, stores   │
├───────────────────────────────────────────────────────────────┤
│ Domain             entities, value objects, validation rules, │
│                    use cases, pure business logic             │
├───────────────────────────────────────────────────────────────┤
│ Infrastructure     API client, auth client, storage, i18n,    │
│                    file upload transport, telemetry beacons   │
└───────────────────────────────────────────────────────────────┘
```

- **Domain is framework-agnostic.** Pure TS / JS. No DOM, no framework imports, no fetch. Domain code is testable in Node without a browser. Validation rules (the same ones described in functional-doc §9) live here as pure functions returning `{hardErrors, softWarnings}`.
- **Infrastructure adapters implement domain ports.** The domain defines an interface (e.g. `AbsenceRepository`); the infrastructure provides the HTTP-backed implementation. Domain never imports a concrete fetch / Axios call.
- **Presentation talks to use cases, not directly to infrastructure.** A page calls `useSubmitVacation()` which delegates to a `SubmitVacationUseCase` that orchestrates validation + repository call.
- **Feature folders, not type folders.** Organise by feature, not by `components/`, `hooks/`, `services/`, `types/`. Each feature folder has its own `presentation/`, `domain/`, `infrastructure/`, `index.ts` public barrel.

```
src/
├── app/                       # shell, routing, providers, layout
├── features/
│   ├── auth/
│   │   ├── presentation/      # LoginPage, useCurrentUser hook
│   │   ├── domain/            # token types, session rules
│   │   ├── infrastructure/    # OIDC client, session storage
│   │   └── index.ts           # public API of this feature
│   ├── worktime/
│   ├── absences/
│   ├── approvals/
│   ├── documents/
│   ├── reports/
│   ├── notifications/
│   └── admin/
├── shared/
│   ├── ui/                    # design system components, tokens
│   ├── i18n/
│   ├── http/                  # base API client, interceptors
│   ├── result/                # Result<T, E> + helpers
│   └── testing/               # MSW handlers, builders, fixtures
└── main.ts                    # composition root (DI wiring)
```

- **One public barrel per feature.** Other features may only import from `features/x/index.ts`, never from internals (`features/x/infrastructure/...`). A lint rule enforces this.
- **No cross-feature presentation imports.** If two features need to share a component, it moves to `shared/ui`. If they need to share domain logic, it moves to `shared/domain`. Cross-feature reaching is a smell.
- **The composition root** (`main.ts` or framework equivalent) is the only place that wires concrete implementations to abstract ports. See §23.
- **File-size guideline:** a file longer than ~300 lines is a smell — it likely covers more than one responsibility. Split.
- **Function-length guideline:** a function longer than ~40 lines is a smell — extract sub-functions or pull the logic into the domain layer.

## 22. Code-quality rules

Non-negotiable; enforced by linter + reviewer.

### 22.1 SOLID applied to FE

- **Single responsibility:** every component, hook, use case, and adapter has one reason to change. "A login form" is a responsibility; "a login form that also validates and dispatches and shows toasts" is three.
- **Open / closed:** extend behaviour through composition (wrapper components, higher-order hooks) rather than mutating shared modules.
- **Liskov substitution:** any concrete implementation of a domain port (e.g. `AbsenceRepository`) is interchangeable with any other in tests.
- **Interface segregation:** prefer small focused ports over one fat service. A `BalanceReader` and a `BalanceMutator` beat a god `BalanceService` that nobody fully uses.
- **Dependency inversion:** see §23.

### 22.2 DRY — but pragmatic

- **Rule of three.** Two similar-looking pieces of code may stay duplicated. Three is the signal to extract. Premature abstractions are worse than duplication.
- **Extraction targets:** formatters, validators, mapping functions, presentational primitives, recurring layout patterns.
- **Do not DRY across feature boundaries** when the meaning is different. Two screens both showing a `<UserRow>` shape is fine; if one is "manager picks an approver" and the other is "HR audits a user", they are different concepts even if the markup looks similar.

### 22.3 Naming

- **Variables and functions:** intention-revealing. `remainingVacationAfterRequest`, not `rva`. `isApprovalRoutedToHr`, not `flag`.
- **Booleans:** start with `is`, `has`, `can`, `should`. Never naked `disabled` — `isDisabled` or `disabledReason`.
- **Components:** `PascalCase`, suffix matches role (`*Page`, `*Card`, `*Dialog`, `*Form`).
- **Hooks:** `use*`, named after the data or action they expose (`useTeamCalendar`, `useSubmitVacation`).
- **Files:** kebab-case for non-component files (`absence-repository.ts`), PascalCase for component files (`AbsenceForm.tsx`).
- **No abbreviations** unless the project has one in the glossary (`PN`, `OCR`, `BT`, `HR` are domain abbreviations; everything else spelled out).

### 22.4 Immutability + pure functions

- **Domain logic is pure.** No mutation, no side effects, no hidden state. Pass everything in; return everything out.
- **Treat data as immutable** at the boundary. Use spread / immer-style updates / framework-native immutability helpers. Reducers / selectors never mutate their inputs.
- **No global mutable state** outside the explicit app store. Module-level `let` variables are forbidden except in the composition root and in caches built by adapters.

### 22.5 Type safety

- **Strict mode on:** `strict`, `noUncheckedIndexedAccess`, `noImplicitOverride`, `exactOptionalPropertyTypes`. PRs do not merge with type errors.
- **No `any` outside an explicit `// @ts-expect-error: third-party signature is wrong` comment with a linked ticket.**
- **No `as` casts** except at boundaries (raw API response → domain entity), and every cast is paired with a runtime validator (Zod / Valibot / Yup / equivalent).
- **Discriminated unions** for state machines (loading / success / error). No `T | undefined` floating around if you actually have three meaningful states.
- **Domain types live in `domain/`** and are imported by adapters; adapters never invent their own copies.

### 22.6 Null + error handling

- **No nulls in the domain.** Use `undefined` for "absent", or — preferred for outcomes — a `Result<T, E>` discriminated union.
- **Errors are values, not control flow** in the domain. The validation engine returns a `ValidationResult`, it does not throw.
- **Exceptions** are reserved for genuinely unrecoverable bugs (out-of-memory, programming mistake). User-input failures, network failures, server errors are `Result.Err`.
- **At the presentation boundary**, the use case returns `Result<T, E>`; the component matches on the union and renders accordingly.

### 22.7 Comments + documentation

- **Default to no comments.** Well-named code documents itself.
- **Allowed comments:** non-obvious WHY (a workaround, an invariant, a domain rule reference like `// per functional-doc H4`), public API JSDoc on exported feature barrels, TODO with linked ticket ID.
- **Forbidden comments:** WHAT-the-code-does narration, redundant docstrings, commented-out code, "added by X on Y" history (Git already knows).

### 22.8 Linting + formatting

- **Auto-format on save** (Prettier / Biome / dprint). Format diffs do not enter PRs.
- **Lint rules:**
  - Framework's recommended rule set + a11y plugin.
  - Import-order rule + no-cross-feature-internal-imports rule (enforced by `import/no-restricted-paths` or equivalent).
  - No-`console.log` in production builds (warn in dev).
  - No floating promises.
  - Exhaustive switch on discriminated unions (`@typescript-eslint/switch-exhaustiveness-check` or equivalent).
- **Pre-commit hook** runs format + lint + type-check on staged files.
- **CI** runs the full suite — pre-commit is convenience only, not the gate.

### 22.9 Pull-request hygiene

- One concern per PR. Big sweeping refactors are separate from feature PRs.
- PRs include a screenshot or short GIF for any visual change.
- Author runs the affected smoke flow locally before requesting review.
- Reviewer checks: does this follow the layering in §21? are types honest? are tests meaningful? is the change minimal?

## 23. Dependency injection

The whole point of the layering in §21 is to make components and use cases **easy to test and easy to swap**. Dependency injection is the mechanism.

### 23.1 Inversion of control

- **Domain code declares ports** (TypeScript interfaces).
  Example port:
  ```ts
  export interface AbsenceRepository {
    submit(input: SubmitAbsenceInput): Promise<Result<AbsenceEntry, ApiError>>;
    listForUser(userId: UserId): Promise<Result<AbsenceEntry[], ApiError>>;
  }
  ```
- **Infrastructure provides adapters** that implement those ports against the real HTTP API.
- **Use cases depend on the port, not the adapter.**
  ```ts
  export class SubmitVacationUseCase {
    constructor(
      private readonly absences: AbsenceRepository,
      private readonly clock: Clock,
      private readonly validation: ValidationEngine,
    ) {}
    async execute(input: SubmitVacationInput): Promise<Result<AbsenceEntry, SubmitError>> { /* ... */ }
  }
  ```
- **No `new HttpAbsenceRepository()` inside a use case.** The use case receives its dependencies; it does not construct them.

### 23.2 Composition root

- **One place** in the app wires concrete implementations to ports: the composition root (e.g. `src/main.ts` or a `compose.ts` module).
- **Composition root constructs the dependency graph once** at startup and exposes it to the presentation layer (via the framework's context / provider mechanism).
- **Different roots for different environments:**
  - Real composition root for production / staging.
  - Test composition root for E2E (swap HTTP adapter for a mock issuer + MSW network layer).
  - Story / playground composition root for the design-system route (`/styleguide`).

### 23.3 Allowed DI styles

Pick **one** and stay consistent:

- **Manual constructor injection** (the example above). Simplest. Recommended for hackathon scope.
- **DI container** (InversifyJS, tsyringe, Awilix, framework-native DI in Angular / NestJS). Worthwhile only if the team is already comfortable with one; otherwise it adds learning cost without much payoff for a 12-h build.
- **Context + factory pattern** (framework-native: React context with a typed `useService<T>()` hook, Vue's `inject/provide`, Svelte's context API). Idiomatic in component frameworks. Recommended where the framework already encourages it.

### 23.4 Forbidden patterns

- **Module-level singletons created at import time.** They cannot be replaced in tests; they leak state between specs.
- **Service locators / global registries** that components call directly. The "what do I depend on?" answer must be visible from the function signature.
- **Static imports of infrastructure from domain.** A lint rule (per §22.8) enforces this.

### 23.5 What gets injected vs imported

- **Injected (replaceable in tests):** anything that touches the outside world — HTTP, storage, telemetry, clock, RNG, file upload transport, navigation.
- **Imported (pure functions, not replaceable):** formatters, validators, mappers, the validation engine itself (pure), token helpers, design-system components.

### 23.6 Testing benefits

- **Use cases** are tested with stubbed repositories; no network, no DOM. Hundreds of these run in seconds.
- **Components** are tested with stubbed use cases; no domain logic in the test, only UI behaviour. (For pages, the integration test in §19.2 uses MSW to give a realistic network response; for individual components, stubs are simpler.)
- **Adapters** get their own contract tests against a mock backend.

---

## 24. Date, time, timezone handling

Attendance is timezone-sensitive — a "Monday sickday" must mean the same Monday for the employee, manager, HR, and payroll regardless of who opens the portal from where. Mishandling this is the single highest source of subtle attendance bugs.

- **Storage:** the API exchanges timestamps in **ISO 8601 UTC** with offset (e.g. `2026-05-11T07:30:00+02:00`). Calendar-day-scoped fields (an absence date, a holiday) use `YYYY-MM-DD` with no time component.
- **Authoritative timezone:** `Europe/Bratislava`. Calendar boundaries (what counts as "today", when a sickday switches to the next day, when the year-rollover job runs) are computed in this zone regardless of the viewer's device timezone.
- **DST handling:** Slovakia observes daylight saving. A half-day starting at 12:30 on a DST-spring-forward day still means 12:30 wall-clock in Bratislava, not a fixed UTC offset. Use a TZ-aware library (Temporal API where available, Luxon / date-fns-tz / dayjs-utc / Day.js plugin elsewhere); never raw `new Date()` arithmetic.
- **Display:** dates rendered in the user's locale format (SK: `dd.MM.yyyy`, EN: same in this context). Times rendered in 24-hour clock. Relative times ("3 minutes ago") only on the notifications inbox.
- **Half-day windows** (§13 + functional-doc §12.2) are wall-clock in Bratislava: morning 07:00-12:00, afternoon 12:30-17:00. The 30-minute gap soft rule (S1) compares wall-clock minutes after applying the local zone.
- **Cross-midnight worktime entries** are not allowed by the rules engine (functional-doc H1 / S3). FE blocks at submit time before the API hears about it.
- **Calendar week numbering:** ISO 8601 (week starts Monday). Weekday-aware controls render `Po Ut St Št Pi So Ne` in SK and `Mon Tue Wed Thu Fri Sat Sun` in EN.
- **Clock skew:** never trust the device clock for security decisions. The "today" highlight on the calendar uses the device clock; the actual server validation uses the server clock.
- **CI test:** at least one test runs with the system clock set to a DST boundary day to catch arithmetic bugs.

## 25. API contract + type generation

FE and BE must not drift on payload shapes. Drift causes silent runtime failures and breaks the legacy parity guarantee on the monthly export (functional-doc §13.9).

- **Single source of truth:** an OpenAPI 3.1 specification (or TypeSpec compiling to OpenAPI) checked into the repo. The BE generates server stubs from it; the FE generates client types from it. Editing API code by hand without updating the spec is forbidden.
- **Code generation in CI:** a generated client (e.g. `openapi-typescript`, `orval`, `oazapfts`, framework-equivalent) writes typed request + response interfaces into `src/shared/http/generated/`. The folder is `.gitignore`d and regenerated on every install + on spec change.
- **Runtime validation at the boundary:** generated types provide compile-time safety; a runtime validator (Zod / Valibot schema generated from the same spec) verifies actual API responses match. Mismatched responses log to telemetry and fail loudly in development.
- **Mock server from spec:** MSW handlers (used in §19.2 integration tests) are seeded from the spec's examples so FE testing does not invent shapes the BE never returns.
- **Versioning:** the API is `/api/v1/...`. Breaking changes bump to `/api/v2` and the FE supports both during the cutover window.
- **Contract tests:** the CI pipeline runs contract tests (Pact-style or schema-based) that fail if the BE's actual response shape diverges from the spec.

## 26. Concurrent edit + conflict resolution

Two managers may try to approve the same request; HR may cancel an absence the employee has just withdrawn. The FE must handle these without losing data or showing stale truth.

- **Optimistic concurrency via ETag:** every mutable resource includes an `ETag` header on GET. The FE echoes it via `If-Match` on PUT / PATCH / DELETE. The server returns `412 Precondition Failed` (or `409 Conflict`) when the resource was modified since.
- **FE conflict UX:** on a `409` / `412`:
  - Toast: "This entry changed since you opened it. Showing the latest version."
  - Refetch the resource.
  - Re-open the form pre-filled with the latest server state, highlighting the diff between the user's attempted edit and the server state.
  - "Apply my changes anyway" requires explicit click; "Discard mine" is the default.
- **Idempotency:** state-changing requests include an `Idempotency-Key` header (UUID v7) so retries do not double-submit. Keys are kept in-memory for the lifetime of the form.
- **Last-write-wins is forbidden** for approvals, decisions, and quota changes. The above pattern is mandatory there.
- **Last-write-wins is acceptable** for self-owned drafts (an employee editing their own pending request) — the latest blur wins.
- **Realtime alignment:** when the websocket stretch (§7) is implemented, an inbound change event invalidates the corresponding query cache and shows a non-blocking "Updated by {someone}" toast.

## 27. Persisted-state migration

The FE persists data in `sessionStorage` (auth tokens, form drafts) and in indexedDB / localStorage (theme, density, locale, last-seen route, optional shell cache metadata). Across deploys the shape of these objects can change.

- **Versioned schema:** every persisted object has a `__schemaVersion` field. The current version is a constant in code.
- **Migration on read:** if the stored version is older, run a migration function (`v1 → v2`, `v2 → v3`, …). Migrations are pure functions, unit-tested, and idempotent.
- **Migration failure:** if the migration cannot resolve (corrupted blob, unknown version), drop the value, log a `warn`, fall back to defaults. Never crash the app on a stale storage entry.
- **No migrations from production data in dev** — the test composition root (§23.2) seeds fresh defaults.
- **Token storage is exempt** — tokens are short-lived and always cleared on logout / hard expiry, so no migration is required.
- **CI test:** a "stale storage" test seeds an old shape and asserts the app loads.

## 28. Export confidentiality

The monthly XLSX (functional-doc §11.1) contains personal attendance data for an entire team or company. Treat downloads as sensitive.

- **Filename convention:** `attendance-{yyyy}-{mm}-{teamSlug-or-all}-{lang}.xlsx`. Example: `attendance-2026-04-backend-sk.xlsx`. Lowercase, kebab-case, no PII in the name.
- **Authorization:** download endpoint is HR + Admin only. The FE never offers the download button to other roles. The BE re-validates the role on every request — never trust the FE alone.
- **No PII in URLs.** Query params hold `year`, `month`, `team_id`, `lang` only — no employee names or IDs of unrelated people.
- **No PII in telemetry.** The download event is recorded as `report.export.monthly` with `team_id` + `lang` + `actor_user_id`; never names, never the file content.
- **Watermark (stretch):** add a footer to each sheet: `Generated by {actor.fullName} on {iso-datetime} ({lang})`. Discourages screenshot-and-leak by making the source obvious. Off by default; configurable globally.
- **Browser cleanup:** the FE revokes the blob URL (`URL.revokeObjectURL`) after the user clicks the download link, so the file is not retained in the page's memory.
- **No client-side caching of the file** on the service worker.
- **HTTPS-only delivery.** The download request never proceeds over plain HTTP.
- **Audit trail:** every export is recorded server-side with actor, timestamp, scope, and IP. Visible in the HR audit-log screen (functional-doc §11.5).

## 29. Resilience — retry, backoff, timeout, circuit breaker

A central HTTP client handles transient failures consistently across the app.

- **One client.** All API calls go through `shared/http/api-client.ts` — no scattered raw `fetch` / `axios` calls.
- **Timeouts:** 10 s default per request. File-upload requests inherit a longer 60 s upload timeout, plus per-chunk progress timeout of 15 s.
- **Retry policy:**
  - Idempotent requests (GET, HEAD, OPTIONS, PUT with `If-Match`, DELETE with `If-Match`, anything with an `Idempotency-Key` per §26): retry up to 3 times.
  - Non-idempotent POST without an idempotency key: **never retry**. Show the error to the user.
  - Backoff: exponential with jitter — 400 ms, 1 s, 2.5 s.
  - Retriable status codes: 408, 425, 429 (respect `Retry-After`), 500, 502, 503, 504.
  - Non-retriable: 4xx other than the above.
- **Circuit breaker** per logical endpoint family (e.g. `/api/absences/*`): if 5 consecutive requests fail with a 5xx in a 30-second window, the breaker opens. While open, the FE shows a single banner "Service degraded — some features unavailable" and uses cached lists if available, blocks mutations. The breaker half-opens after 60 s with a probe request.
- **`AbortController`** on every request; in-flight requests are cancelled on route change.
- **No request fan-out** on render — `useEffect` (or framework equivalent) declares its dependencies honestly so the request fires once per intent.

## 30. Feature flags

Stretch goals (§14 of functional doc, §7 / §10 / §19.5 here) toggle on and off without redeploy. Same mechanism enables A/B for any future experiments.

- **Server-driven flag service** is the source of truth. The FE fetches the flag manifest on app startup and refreshes it on focus.
- **Flag shape:** `{ key: string, enabled: boolean, audience?: { roles?: Role[]; userIds?: UserId[]; teams?: TeamId[] } }`. Audience filtering happens on the server before flags reach the FE — the FE never receives flags for users not in the audience.
- **Reading flags:** `useFeatureFlag('websocket-live-updates')` returns a boolean. Defaults to `false` if the flag is unknown, so a missing flag never breaks production.
- **Component-level gating** for whole features; `if (!flag) return null` for stretch UI.
- **Kill switch:** every flag has an "emergency off" lever HR/Admin can flip if a stretch feature misbehaves.
- **Flag lifecycle:** flags created with a removal date in the description. Stale flags ≥ 90 days reviewed for promotion-to-default or deletion.
- **No environment-variable flags for runtime behaviour.** Env vars are for build-time configuration only (API origin, IdP issuer, etc.).
- **CI:** an E2E run executes with all stretch flags **on** to catch interactions before they reach production.

## 31. Logging conventions (development + client-side runtime)

- **Single logger module** in `shared/logging/`. The rest of the codebase imports `log` from it; nobody uses `console.log` directly. A lint rule enforces this.
- **Levels:** `debug`, `info`, `warn`, `error`. `debug` calls are stripped from the production bundle by the build tool.
- **Structured payload:** `log.info('absence.submitted', { absenceId, type, userId })`. Free-text messages are short and discoverable; rich data goes in the second argument as an object.
- **Redaction:** the logger filters out keys named `token`, `password`, `secret`, `authorization`, `cookie` (configurable allow-list) before printing or sending to telemetry.
- **No PII** (emails, full names, document contents, file names) in client-side logs. User identifier is the user ID only.
- **Production behaviour:** `warn` and `error` calls are forwarded to the telemetry beacon (§18). `info` and `debug` stay in the console (and `debug` only in development).
- **Error objects** are logged with `cause` chain preserved.
- **No `console.log` ever lands in `main`.** Pre-commit hook fails on `console.*` references outside `shared/logging/` and tests.

## 32. Local dev setup + DX standards

Goal: a new contributor goes from clone to running portal in under 5 minutes.

- **Node version pinned.** `.nvmrc` (and `.tool-versions` for asdf users) at repo root. CI uses the same version.
- **Package manager pinned.** `"packageManager": "pnpm@x.y.z"` (or npm / yarn) in `package.json`; Corepack handles activation. Mixing managers is forbidden.
- **`.env.example`** committed; contains every env var the app reads, with safe placeholder values and one-line descriptions.
- **Onboarding script:** `pnpm setup` (or `npm run setup`) bootstraps the environment: copies `.env.example` to `.env`, runs `pnpm install`, generates API types from the OpenAPI spec, runs the test composition root once to verify the mock issuer + MSW handlers boot.
- **Dev server command** is a single npm script: `pnpm dev`. It runs the app + MSW mock backend in parallel by default.
- **VS Code workspace recommended extensions** committed in `.vscode/extensions.json` (ESLint, Prettier / Biome, the framework's official extension, EditorConfig, Playwright).
- **EditorConfig** committed for cross-editor consistency.
- **Devcontainer (optional):** a `.devcontainer/` folder provides a reproducible environment for users on Windows / WSL / Codespaces.
- **README** at repo root, ≤ 1 page: prerequisites, setup, dev commands, test commands, deployment. Longer docs link out from there.

## 33. Definition of Done

Every PR must satisfy all of these before merge. The checklist lives in the PR template.

- [ ] Behaviour matches a referenced functional-doc / FE-tech-doc requirement (link the section).
- [ ] Types pass strict-mode check; no new `any` or `@ts-expect-error` without a linked ticket.
- [ ] Unit, integration, and (where relevant) E2E tests added or updated; all green.
- [ ] `axe-core` audit on touched routes returns no `serious` / `critical` findings.
- [ ] Lighthouse Performance + A11y + Best-Practices + PWA ≥ 90 on touched routes.
- [ ] Bundle-size CI gate green.
- [ ] One screenshot or short GIF attached for any visible change, in both light and dark theme.
- [ ] No new direct calls to infrastructure from domain (layering rule §21).
- [ ] No new module-level singletons, service locators, or import-time side effects (§23.4).
- [ ] No `console.*` outside `shared/logging/` and test files.
- [ ] No new `TODO` / `FIXME` without a linked ticket ID.
- [ ] Storage shape changes accompanied by a migration (§27).
- [ ] User-visible strings go through the i18n catalogue (SK + EN both updated).
- [ ] Author ran the affected smoke flow locally before requesting review.
- [ ] Reviewer signed off after walking the diff and the linked requirement.

## 34. Print styles

HR and payroll occasionally print balance reports and audit-log slices for filing. Print should not look like a screenshot of dark-mode UI.

- **`@media print` stylesheet** forces light theme, removes background colours, simplifies tables to one-pixel grey borders.
- **Hide non-essentials:** navigation, sidebars, footers, action buttons, theme/locale switchers, notification bell — all `display: none` in print.
- **Repeat table headers** across pages with `thead { display: table-header-group }`.
- **No `position: fixed`** in print (causes ghost overlays).
- **Page breaks:** `break-inside: avoid` on rows and cards so a record never splits across pages.
- **Print-friendly URLs:** `a[href^="http"]::after { content: " (" attr(href) ")" }` so printed links remain useful.
- **What prints well:** monthly export preview, balances per user, audit log filtered slice. Each has a "Print this view" affordance.
- **What does not print:** team calendar grid (too wide), forms, dashboards. Hide the print button on those pages.

## 35. Keyboard shortcuts catalogue

Power users (HR, Admin, managers approving many requests) benefit from keyboard shortcuts. They are also part of the WCAG 2.2 keyboard-operability story (§4).

- **Help overlay:** `?` opens a modal listing every shortcut, grouped by section. Always reachable.
- **Global:**
  - `g d` — go to dashboard
  - `g c` — go to team calendar
  - `g a` — go to approvals queue
  - `g n` — go to notifications inbox
  - `g s` — go to settings
  - `/` — focus search
  - `?` — open shortcuts overlay
  - `Esc` — close any modal / side panel
  - `t` — toggle theme
  - `l` — toggle locale
- **Lists (approvals queue, audit log, notifications, employees):**
  - `j` — move focus to next row
  - `k` — move focus to previous row
  - `Enter` — open the focused row's detail
  - `a` — approve focused approval (manager / HR only)
  - `r` — reject focused approval (manager / HR only, requires reason → focuses the reason input)
- **Forms:**
  - `Ctrl/Cmd + Enter` — submit form
  - `Esc` — cancel (with unsaved-changes confirmation)
- **Conflicts:** shortcuts never override browser-native ones (Ctrl+T, Ctrl+W, etc.).
- **Accessibility:** every shortcut also has a discoverable button — keyboard shortcuts are an accelerator, not the only path.
- **Discoverability:** the first time a user lands in a list view, a one-shot tooltip suggests `?`.

## 36. Onboarding + first-run experience

A new user's first session should be productive within 60 seconds.

- **Welcome screen** on first login after profile setup: 3-step guided tour, skippable, dismissable forever ("Don't show me this again").
  - Step 1 — "Here's where you log worktime."
  - Step 2 — "Here's where you submit absences."
  - Step 3 — "Here's where your balance lives."
- **Tour implementation:** non-modal pop-overs anchored to real UI elements, dismissable with `Esc`. Reachable later from the Help menu ("Show tour").
- **Empty-state CTAs** (per §14) push the user toward the next useful action.
- **Profile completeness banner** appears at the top of the dashboard until the user has set their preferred theme, locale, density, and full name. Dismissable but reappears each session until complete.
- **Manager first-run** additionally shows a tour of the approvals queue.
- **HR first-run** additionally shows a tour of the documents queue + monthly export + quota config.
- **Admin first-run** additionally shows a tour of user / team / quota management.
- **Tour completion** is tracked per user so subsequent logins go straight to the dashboard.

## 37. Heavy library policy

Heavy libraries inflate bundle size, slow first paint, and risk INP regressions. Policy keeps them off the critical path.

- **Lazy-loaded by default:** PDF.js, charting libraries (Chart.js / Recharts / ECharts / equivalent), heavy date pickers, HEIC decoders, rich-text editors, anything > 30 KB gzip.
- **Imported only at the point of need:** dynamic `import()` inside the route or component that actually uses the lib. A loading skeleton fills the slot while the chunk arrives.
- **Server-side preference:** if a heavy operation can be done on the server (e.g. PDF first-page render, image resize, XLSX generation), prefer that route. The FE shows the result, the BE does the work.
- **WebAssembly allowed** for genuinely CPU-heavy paths (HEIC decode, certain charts, PDF.js renderer). Each WASM import must:
  - Be lazy-loaded.
  - Be profiled — main-thread time documented in the PR.
  - Use a Web Worker if it would block the main thread > 50 ms (INP budget).
- **Audit per quarter:** bundle analyzer (`rollup-plugin-visualizer`, `webpack-bundle-analyzer`, equivalent) run on `main`; the largest 10 chunks reviewed for opportunities to split or replace.
- **Forbidden:** loading any heavy lib synchronously on the login / dashboard route. They are stretch features, not critical path.
- **Library swap-out plan:** if a heavy lib accounts for > 10 % of the initial bundle and is used on < 10 % of routes, it must be lazy-split or replaced with a lighter alternative.

## 38. Privacy notice + consent UX

GDPR applies because the portal processes personal attendance data, and Slovak labour law requires informed consent for storing certain employee data digitally.

- **First-login privacy notice:** a non-dismissable dialog on first authenticated session that summarises:
  - What data the portal stores (attendance, absences, documents, audit log).
  - How long it is kept (configurable per data category by Admin; defaults documented).
  - Who can see what (employee → own; manager → team; HR → all; admin → metadata).
  - The user's rights (access, rectification, erasure subject to legal retention obligations).
  - Link to the company's full privacy policy.
- **Consent is recorded** on the user profile with a timestamp + the version hash of the notice text. New notice version → consent re-prompt.
- **No third-party cookies, no third-party trackers.** §18 already commits to this; the notice surfaces it.
- **Telemetry opt-out** is a toggle in the user profile (`Send anonymous error reports — on / off`). Default on; respects DNT immediately regardless of toggle.
- **Data export (self-service)** is a button in the user profile that downloads the user's own data in JSON. Implementing it is a stretch but the UI placeholder is in the baseline so the GDPR "data portability" right is visibly addressed.
- **Account deletion request** is a button in the user profile that opens a ticket with HR. The portal does not delete unilaterally because Slovak labour law mandates retention of attendance records for specific periods; HR processes the request within the legal framework.
- **Cookie notice technically not required** because the portal uses no cookies — but the privacy notice still covers `sessionStorage` and other client-side persistence under the same umbrella, which is the legally safer interpretation.

---

## Suggested team split for FE work

Senior + AI-assisted teams can parallelise wider than the conservative split below.

If a team has 4-7 people focusing on FE:

- **1** — Design system, tokens, theming, locale catalogue, layout shell.
- **1** — Identity + auth flow + role-aware routing + admin console.
- **1** — Worktime + absence forms + live validation + balance badge + file upload UX.
- **1** — Team calendar grid + approvals queue + documents queue + side panels.
- **1** — Reports + balances charts + audit-log screen + monthly export download dialog (SK + EN).
- **1** — PWA shell + service worker + offline banner + notifications inbox + telemetry beacons.
- **1** — Testing infra (Playwright + axe-core + Lighthouse CI + MSW mocks) + dependency audit + CI pipeline.

If a team has 2-3 people focusing on FE: prioritise design system + auth + worktime + absence forms + approvals + team calendar + monthly export. Stretch (PWA, websocket, visual regression) only after the baseline is green.

## What this doc does NOT decide

- The actual JavaScript framework. Team picks.
- The actual styling solution (CSS-in-JS vs CSS modules vs vanilla CSS vs Tailwind). Team picks; tokens-driven either way.
- The actual headless / styled component library (within the constraints of §11).
- The actual hosting provider (within §20 constraints).
- The actual error / RUM service (within §18 constraints).
- The actual IdP (within §8 constraints).

Every decision left to the team is constrained by the requirements in this doc. A wrong-shaped choice (e.g. building all atoms from scratch, or storing tokens in `localStorage`) is out of compliance and must be revised before merge.
