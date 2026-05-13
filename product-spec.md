# Attendance Portal — Functional Refinement

**Status:** Hackathon brief — single-day build window, team sizes 2–7, **senior engineers with strong AI tooling** (Claude Code / Cursor / equivalents). Scope is ambitious by design; teams are expected to ship a polished demoable application, not a sketch.
**Audience:** Hackathon teams. Read this as the source of truth for *what* the portal does. Each team picks their own implementation stack.
**Date:** 2026-05-06 (source); revised 2026-05-09.

> **Tier model.** This brief uses two scope tiers: **Basic** and **Bonus**. Basic must complete first; Bonus features are off-limits until *every* Basic acceptance scenario passes. Judges enforce the gate — Bonus axes count only when Basic ≥ 90%.

---

## 1. Problem statement

Today the company tracks attendance by emailing monthly Tempo XLSX exports to a back-office robot that flags rule violations after the fact. Employees, managers and HR have no real-time view, no approval flow, no document handling and no quota enforcement at the moment of submission.

Build a self-contained web application that owns the whole attendance lifecycle: daily worktime, planned and unplanned absences, document confirmations, manager approvals, quotas and reports. The portal **replaces Tempo** as the capture tool — there is no Tempo integration to maintain.

**Important — downstream accounting export.** The portal's monthly export still feeds an **external accounting system** that processes payroll, payouts, and other compliance-relevant outputs. The export format (the two-sheet XLSX layout and activity-label catalogue in §11.1, modelled on the reference fixture `Attendence_example_report.xlsx`) is fixed by the accounting system's contract — teams must treat it as an external interface, not as something they can redesign. Tempo's replacement is for *capture and lifecycle*; the *export contract to accounting* survives unchanged. Historical Tempo data ingest (different concern) is a separate Bonus axis in §14.

## 2. Glossary

- **Worktime entry** — A block of time on a *single calendar day* during which the employee is working. Has a start time and an end time. One record per day per block (a split day with morning + afternoon work creates two entries).
- **Absence entry** — A *single record* covering one day or a range of consecutive days during which the employee is not working: vacation, sickday, sick leave (PN), doctor visit (Paragraph), family-member care (OCR), special leave, paternity leave. A 2-week PN is **one entry**, not 14 — opening it on day 5 shows the same record as day 1 or day 14. State transitions, comments, and audit events apply to the entry as a whole.
- **Half-day absence** — An absence that covers only the morning or only the afternoon of a single day.
- **Business trip (BT)** — Worktime spent away from the regular workplace.
- **Overtime** — Worktime exceeding the standard 8-hour day, requiring approval.
- **Quota** — The yearly allocated amount of a particular leave type for an employee.
- **Carry-over** — Unused vacation days from the previous year that are added to this year's balance.
- **Approval** — A pending decision a manager (or HR) must make on a submitted request.
- **Hard rule** — A rule that blocks submission. The user cannot save the entry until the violation is resolved.
- **Soft rule** — A rule that warns the user but still saves the entry. Visible to manager and HR.
- **Direct manager** — The single user listed on the employee's `direct_manager_id` field. Default approver for routed requests. See §7.1 for full routing semantics including skip-level.
- **Skip-level approval** — Any *ancestor* of the requester in the org tree (manager's manager, etc.) may also approve a request routed to a subordinate manager. See §7.1.
- **HR group** — The HR-role users collectively. Receive document validation requests and act as fallback approvers when no direct manager is set or when a self-approval guard exhausts the chain.
- **Reserved (quota slot)** — A quota amount held against an employee's balance while a request is in Pending. The slot is *visible as deducted* on the balance screen but is not yet a final decrement; if the request is Withdrawn or Rejected, the slot is released back. The decrement becomes final only on Approval.
- **Audit log** — Immutable record of every state change of an absence, approval, document, or quota. Each entry stores actor, timestamp, before-snapshot, after-snapshot. See §11.5.
- **Team** — A grouping of users assigned by Admin. The team-calendar view (§11.2) and same-team notification list (§10) key off this field. Independent of the org tree (a team's members may report to different managers).
- **Project code** — An optional tag on a worktime entry (`GENERAL` is the default). Free-form per company policy; the export (§11.1) carries whatever the user logged.

## 3. Personas, roles and permissions

| Capability | Employee | Manager | HR | Admin |
|---|---|---|---|---|
| Log own worktime | yes | yes | yes | yes |
| Log own absences | yes | yes | yes | yes |
| Submit vacation/paragraph/OCR/special/overtime requests | yes | yes | yes | yes |
| Upload own documents | yes | yes | yes | yes |
| See own balance & history | yes | yes | yes | yes |
| Approve/reject requests routed to me (direct reports) | no | yes | yes (any) | no |
| Approve via skip-level chain (any descendant in the org tree) | no | yes | yes (any) | no |
| See team calendar | own row only | yes (own team) | yes (any team) | yes |
| Validate uploaded documents | no | no | yes | no |
| Configure per-user quota overrides | no | no | yes | no |
| Configure global quota rules | no | no | yes | yes |
| Generate monthly HR reports | no | no | yes | yes |
| Manage users, teams, manager links, roles | no | no | no | yes |
| Import / edit public-holiday calendar | no | no | no | yes |

A user can hold multiple roles. A manager is also an employee for their own absences. **Self-approval guard:** if the routed direct manager is the requester themselves, walk up the org tree to the first non-self ancestor; if exhausted (no ancestor) → HR group.

## 4. Absence types — rules and examples

Each absence type is its own product feature with its own rules. The portal must clearly label which type the employee is logging.

### 4.1 Vacation

**Purpose:** planned paid time off.
**Approval:** required, by direct manager (or any ancestor in the org tree).
**Quota:** statutory + company-bonus (see §6).
**Granularity:** full day or half day (morning OR afternoon).
**Document:** none.

**Example.** Anna has 23 vacation days for 2026 (20 statutory + 3 bonus) and has used 4. She submits 2026-07-13 → 2026-07-17 (5 working days). The portal:
1. Counts the working days. **Working day = calendar day in range, minus Saturdays and Sundays, minus Slovak public holidays.** In this case 5 (range is Mon–Fri, no weekend or holiday).
2. Confirms 5 ≤ 19 remaining.
3. Records the request as Pending.
4. Notifies her manager.
5. The 5 days are *reserved* but not yet decremented from the balance — they decrement only when the manager approves.

If the manager rejects, the entry transitions to Rejected and Anna is notified by email. Per §6.5, the entry stops contributing to `reserved` / `used` automatically; nothing is "refunded" because nothing was deducted as a counter — the computed remaining simply updates. Same model on Withdraw or Cancel — see §7 for the full state machine and §7.3 for cancellation rules.

### 4.2 Sickday (company benefit)

**Purpose:** short, self-declared sick day without a doctor's note.
**Approval:** none — auto-approved on submission, but every hard rule must pass.
**Quota:** 3 per calendar year, no carry-over.
**Granularity:** full day only — the portal must not offer the half-day option for sickdays.
**Document:** none.

**Hard limits enforced at submission time:**
- The employee has at least 1 sickday remaining for the current year.
- The day immediately before the requested date is *not* already a sickday — sickdays cannot be back-to-back across calendar days.
- The requested date is a working day (not weekend, not Slovak public holiday).

**Notification:** manager + everyone on the same team + HR group are emailed.

**Example A — allowed.** Peter used 1 sickday in March 2026. On 2026-05-06 (Wednesday) he submits a sickday for the same day. The portal accepts: 2 remaining, no consecutive sickday, working day → auto-approved → emails fire.

**Example B — blocked.** Peter took a sickday yesterday (2026-05-05). Today he tries to log another for 2026-05-06. The portal blocks with the message *"Consecutive sickdays are not allowed."* The user must pick a non-adjacent day or use sick leave (PN) instead.

### 4.3 Sick leave / PN (incapacity for work) and paternity leave

**Purpose:** doctor-certified illness or 2-week paternity leave following the birth of a child.
**Approval:** self-declared (no manager approval needed to log), but documented later by HR with the doctor's papers.
**Quota:** none — uncapped.
**Granularity:** full days, can span multiple calendar days including weekends and holidays.
**Document:** doctor's papers required eventually; HR can attach them on the employee's behalf. An accident report is required for accident-caused PN.

**Notification:** direct manager, HR group, and the same-team members are emailed.

**Example.** Mária is on PN from 2026-04-20 to 2026-04-30. She logs PN on the portal that morning. Manager + team + HR get email. HR receives the paper certificate from the doctor on 2026-05-02 and attaches it to the existing PN entry. No quota is touched.

### 4.4 Paragraph — doctor visit

**Purpose:** legally entitled time off for the employee's own doctor visit / treatment.
**Approval:** required, by direct manager.
**Quota:** 7 days per calendar year.
**Granularity:** full day or half day (morning or afternoon).
**Document:** required — doctor's confirmation must be uploaded by the employee. HR validates.

**Special rule (half-day).** A half-day Paragraph and the worktime on the same day must be separated by at least 30 minutes of gap. This is a *soft warning*: the user can still save, but the entry is flagged for HR's attention.

**Example.** Janka has a 09:00 doctor's appointment on 2026-05-12. She submits a half-day Paragraph for the morning of 2026-05-12. She also wants to work in the afternoon. The portal recommends she log her worktime as starting no earlier than 12:30 (i.e. 30 minutes after the morning slot ends at 12:00). If she logs worktime starting at 12:15, she sees a yellow warning *"Half-day absence must be separated from working time by at least 30 minutes."* She can still save. Manager and HR see the warning on the entry.

She uploads a photo of the confirmation. Manager approves the absence. HR opens the document, validates it as legible, marks it Approved → the entry's state is now Approved and contributes 0.5 working-days to `used` per §6.5 (no counter mutation; the computed remaining drops accordingly). If HR rejects the document (illegible, wrong period, etc.), the entry transitions to Rejected; it stops contributing to `used` automatically; Janka is emailed with the reason. The rejected document file remains attached to the entry for audit trail.

### 4.5 OCR — accompanying a family member

**Purpose:** care / accompanying a family member for a medical visit, illness or treatment.
**Approval:** required, by direct manager.
**Quota:** 7 days per calendar year.
**Granularity:** full day or half day.
**Document:** required.

Identical workflow to Paragraph. The 30-minute gap soft rule applies the same way to half-day OCR.

**Eligible family member**, per the rule text the team should display in the portal's help: own child, adopted child of the employee or spouse, child entrusted by court order; sick spouse or sick parent of either spouse.

### 4.6 Special leave

**Purpose:** life events such as wedding, funeral, blood donation.
**Approval:** required, by direct manager.
**Quota:** legal entitlement; portal treats it as a soft cap (HR can configure).
**Granularity:** full day or half day.
**Document:** required.

The 30-minute gap soft rule applies to half-day special leave the same way.

## 5. Worktime, project codes and business trip

### 5.1 Worktime entry

A worktime entry has:
- a date (always one calendar day),
- a start time and an end time within that day,
- an optional project code (the portal must offer a default value of `GENERAL` so an employee can submit worktime without picking a project),
- an optional free-text note,
- an optional Business-Trip flag,
- an Overtime flag the system sets automatically when **the day's total worktime exceeds 8 hours** — including the cumulative case where no single entry is >8h but two or more entries combined exceed 8h. The flag attaches to the entry that pushes the day past the threshold; the day is then flagged as overtime and triggers the approval flow (§10, §7 state machine).

Multiple worktime entries on the same day are allowed (split work blocks) as long as they do not overlap each other and do not overlap any approved absence on that day.

**Example — split day.** Tomáš logs 08:00-12:00 on project `ADM-1`, then 13:00-17:00 on `ADM-2`. Total 8h, two entries, no overlap → both saved.

**Example — soft warning.** Tomáš logs a single block 04:30-13:00. The portal saves the entry but warns:
- 04:30–06:00 falls in the night-time range → S3 "Night-time work (between 22:00 and 06:00)".
- The block is 8.5h continuous → S4 "Single 8h+ worktime entry; consider splitting."

HR and the manager see both warnings on the report.

### 5.2 Project codes

Project codes are *not mandatory* per team policy. A free-text comment is enough on a `GENERAL` entry. Teams pick how granular they want to be. The HR monthly report shows whatever was logged. **`GENERAL` is reserved as the system default project code** — Admin / HR may not create a custom project with the same code.

### 5.3 Business trip

Business-trip worktime is logged as a regular worktime entry with the Business-Trip flag turned on. The portal pre-fills the time window 08:00–16:30 (the standard working day per §12.2) for travel-only days (early-morning or late-evening travel logs as one full standard day to keep payroll consistent). No approval is required — the trip is visible to the manager on the team calendar. **A BT-flagged entry is still a worktime entry** and is subject to the same hard rules as any other worktime — H6 / H7 / H9 still apply (BT cannot coexist with an approved absence on the same day).

## 6. Quotas and balances

### 6.1 Vacation quota — two stacked allocations

Vacation comes in two parts that the portal must surface separately on the balance screen:

- **Statutory** — Slovak legal entitlement, default 20 days. Configurable per employee (some employees are entitled to more by law, e.g. age- or care-based).
- **Company bonus** — extra company benefit, default 3 days. Configurable globally and per employee.

Both buckets are spent together: the portal shows a combined "remaining" number in the UI but tracks them as two separate allocations internally for the carry-over rule below.

**Consumption order** (load-bearing for the bucket display and for year-end leftover composition): every approved vacation day is debited in this fixed order — (1) **carry-over from previous year** first, (2) **statutory** of the current year, (3) **company bonus** last. This ordering means the bonus is the most exposed to remaining unused at year-end, which is what gives the over-accumulation penalty (§6.3) its teeth. The bucket-by-bucket "remaining" is visible to HR on the balances screen (§11.3); employees see the combined number plus the "bonus withheld" flag.

### 6.2 Other quotas

| Quota | Default | Carry-over | Granularity |
|---|---|---|---|
| Sickday | 3 days | none, expires 31 December (event date) | full day |
| Paragraph | 7 days | none | half-day allowed |
| OCR | 7 days | none | half-day allowed |
| Special leave | per legal entitlement | configurable | half-day allowed |

All defaults are configurable globally by HR and can be overridden per employee. The **carry-over limit** in §6.3 is a global-only setting (no per-employee override). Quotas are bound to the **event date** of the entry, not the submission date — a sickday submitted on 2 January for a 31 December event counts against the previous year's quota.

### 6.3 Year rollover (annual job, runs at 00:05 on 1 January)

For each active employee:

1. Compute the leftover vacation = unused statutory + unused company bonus from the previous year.
2. Compute the carried-over amount and the bonus penalty:
   - **Slovak labour law forbids forfeiting statutory vacation.** No matter how many statutory days the employee carries over, they keep them all.
   - If leftover ≤ carry-over limit (global setting, default 5) → carry the full leftover. The employee keeps their full company-bonus allocation in the new year.
   - If leftover > carry-over limit → still carry the **full** leftover (statutory cannot be lost). **However**, the *company* bonus is the company's discretionary benefit, and the company policy is to withhold it from employees who over-accumulate: the company-bonus quota for the new year is set to 0.
3. Allocate the new year's quotas: fresh statutory (per employee setting), fresh company bonus (0 if the bonus was withheld, otherwise default), fresh sickday/paragraph/OCR.
4. Email the employee + HR a rollover summary: "Carried over: X days. Company bonus this year: Y days (withheld: yes/no)."

**Worked examples**

- *Anna ends 2026 with 4 vacation days unused.* Leftover 4, ≤ limit. Carry-over 4. Bonus retained for 2027 → starts 2027 with 27 days (20 statutory + 4 carry-over + 3 bonus).
- *Peter ends 2026 with 8 vacation days unused, limit is 5.* Leftover 8, > limit. Carry-over **8** (statutory days are not lost). Bonus withheld → starts 2027 with **28** days (20 statutory + 8 carry-over + 0 bonus).
- *Mária ends 2026 with 0 unused.* Carry-over 0. Bonus retained. She starts 2027 with 23 days.

The "bonus withheld" flag is shown on the employee's balance screen with a tooltip explaining the policy, so people understand what happened and why.

**Why Peter starts 2027 with more days than Anna — and why this is correct.** The visible 2027 balance (Peter 28 vs Anna 27) is *misleading at first glance*. The carry-over portion is just unused 2026 entitlement deferred into 2027 — not a fresh allocation. In *fresh lifetime entitlement*, Peter is **3 days down** because his 2027 bonus was zeroed (Anna: 23 + 23 = 46 fresh days across two years; Peter: 23 + 20 = 43; Mária: 23 + 23 = 46). The policy intent is to nudge employees to use vacation in-year — losing the bonus is the only available stick because Slovak labour law forbids forfeiting statutory days. The tooltip on the balance screen should explain this so employees understand the 28-vs-27 visual is not a reward for hoarding.

### 6.4 Approaching-limit warnings

The portal raises a soft warning the moment a submission would leave the employee at or below 2 vacation days remaining, or at exactly 1 sickday remaining. This is informational — submission still proceeds.

### 6.5 Quota as a computed view (not a stored counter)

The portal models quota balances as a **computed view over the absence-entry table**, never as a stored counter that gets debited and credited. Concretely:

- `allocated` = the per-employee yearly entitlement (from the quota config table; updated only on year rollover or HR override).
- `reserved` = sum of working-days across entries in state Pending for the current year (subject to the consumption order in §6.1).
- `used` = sum of working-days across entries in state Approved for the current year (subject to the consumption order in §6.1).
- `remaining` = `allocated − reserved − used`.

**No "refund" or "decrement" action exists.** A state transition on an entry (Pending → Withdrawn, Approved → Rejected, Approved → Cancelled, Pending → Rejected) automatically changes which sum the entry contributes to; the computed `remaining` updates in lockstep. Audit log records the *state change*, not a quota-counter mutation.

Consequences:
- The cancel-vs-reject race (an absence cancelled by the employee at the same moment HR rejects its document) cannot double-refund — both transitions resolve to the same terminal state; the entry stops contributing to `used` exactly once.
- Historical balance queries are reproducible by replaying entry states as of a target date; no separate counter to reconcile.
- "Used" is naturally split into **realised** (entries whose date range has fully elapsed) vs **planned** (entries whose date range is today or in the future). The balance screen MAY surface this split.

## 7. Approval workflow

Every planned absence and every overtime request goes through the same state machine:

```
Draft -> Pending -> Approved
                 -> Rejected
                 -> Withdrawn (by employee while still Pending)
```

**Draft** is a real persisted state — the employee has filled out (and saved) a request but has not yet submitted it for approval. Drafts are visible only to the requester, do not reserve quota, and do not notify anyone. The employee can edit a Draft freely or delete it. Submitting a Draft moves it to Pending (or directly to Approved for auto-approved types — see below).

Approved and Rejected are final. **Withdrawn is also terminal** — the request can no longer be approved or rejected, and any reserved quota is released back to the employee's balance. HR may override Approved or Rejected (e.g., correcting a mistaken approval) but every override must be visible in the audit log; HR does not override Withdrawn (the employee re-submits a new request instead).

**Sickday and PN bypass the Pending state.** The state machine above applies to manager-approved absence types (Vacation, Paragraph, OCR, Special leave, Overtime). **Sickday is auto-approved on submission** (subject to all hard rules in §9.1) — it has no Pending state and no manager involvement; HR may still override it post-hoc. **PN is self-declared** — the entry is recorded as Approved on submission with no manager involvement; HR attaches doctor's papers asynchronously. PN never decrements a quota (uncapped per §4.3).

### 7.1 Routing

- **Default approver:** the employee's `direct_manager_id`.
- **Skip-level allowed:** any ancestor in the org tree (manager's manager, etc.) MAY also approve a routed request. The approvals queue exposes two filters: *routed-to-me* (default) and *I-can-approve-via-chain*.
- **No direct manager set:** routes to the HR group.
- **Self-approval guard:** if the routed approver is the requester themselves, walk up to the first non-self ancestor; if exhausted → HR group.

Each user has exactly one `direct_manager_id` (nullable at top of tree). Fixtures must seed a small tree (e.g. CEO → 2 dept heads → leads → ICs).

### 7.2 Manager actions

A manager opens the approvals queue. **By default the queue shows requests routed to me** (direct reports); the **skip-level filter** ("I can approve via chain") is opt-in and exposes any pending request from a descendant in the org tree (per §7.1). For each pending request the manager sees:
- requester name + team,
- absence type and dates,
- remaining quota for the requester (so they can judge fairness),
- any soft warnings on the entry,
- a presence-of-document indicator if a document is attached. **The manager does not see, preview, or validate the document content** — that is HR's responsibility (§8.2).

The manager picks Approve or Reject; reject requires a free-text reason. The decision triggers an email to the employee. On approve, the entry transitions Pending → Approved; per §6.5, this immediately moves its working-days from `reserved` to `used` in the computed quota view (no counter mutation).

### 7.3 Withdrawal and cancellation

While the request is Pending, the employee can withdraw it from their own dashboard with one click. After approval, the employee can still *cancel* the absence (e.g. they no longer need the day off). Cancellation transitions the entry to a Cancelled state; per §6.5 the entry then stops contributing to `used`, so the computed remaining updates without any counter mutation. The cancellation writes an audit entry. Cancellation is allowed up to and including the day before the absence; cancelling on or after the absence date requires HR.

**Auto-approved types (Sickday) and self-declared types (PN) have no Pending state** — therefore Withdraw does not apply to them. Only Cancel applies, with the same day-before / HR-after rules.

## 8. Documents

### 8.1 Upload

Paragraph, OCR and Special-leave requests require a document. Sickday and Vacation do not. **PN papers may be attached by either the employee or HR** — see §16 O8; both paths target the same PN entry.

The employee uploads the document while filling out the absence form — drag-and-drop or file picker. **Accepted MIME types: `image/png`, `image/jpeg`, `application/pdf`. Per-file size cap: 10 MB.** The document is linked to the absence entry the moment the request is submitted. **Documents may also be attached after submission** (before the absence reaches a final state) — useful when a doctor's note arrives after the employee has already logged the absence. H8 still applies: the absence cannot reach Approved until HR has validated a document.

### 8.2 HR validation

HR has a dedicated "Pending documents" queue. Each entry shows the requester, absence type, dates, the file (preview), and a free-text reason field. HR approves or rejects.

- **Approve.** No further action needed; the absence proceeds through the normal manager-approval path.
- **Reject** *after* the absence is already manager-approved. The portal:
  1. Transitions the entry to Rejected. Per §6.5, the entry stops contributing to `used` automatically — no counter is "refunded".
  2. Emails the employee with HR's reason.
  3. Writes an audit entry capturing the state change (actor, before, after).
  4. The rejected document file remains attached to the entry for audit. HR may still delete it via an audit-log override if needed.

If the absence is still Pending when HR rejects the document, the portal moves it directly to Rejected without waiting for the manager.

**Re-attempting after a document rejection.** Rejected is terminal (per §7). The employee submits a *fresh* absence request with a new document — the rejected entry stays in history.

## 9. Validation rules — full catalogue

The portal validates *every* worktime and absence submission with a consistent rule set. Hard rules block one of the entry's transitions (most commonly *submission* — click Save → rule fires → save fails; H8 instead blocks the *Approval* transition without preventing submission as Pending). Soft rules show a yellow warning but allow the entry to save and progress.

### 9.1 Hard rules

| ID | Rule | Plain-English explanation |
|---|---|---|
| H1 | No overlapping entries on the same day. | A new worktime block must not overlap an existing one. An absence must not overlap another absence in the same morning/afternoon slot. Worktime and an existing approved absence on the same day cannot coexist. |
| H2 | Sickday is full-day only. | The half-day option must be hidden / disabled for sickday. |
| H3 | Sickday quota cannot be exceeded. | If the employee already used 3 sickdays this year, a 4th is blocked. |
| H4 | Sickdays cannot be on consecutive calendar days. | If yesterday was a sickday, today cannot be — even if there are sickdays remaining. The user is told to take PN instead. |
| H5 | The relevant quota cannot be exceeded. | Vacation/Paragraph/OCR/Special are blocked when remaining < requested. |
| H6 | Worktime is forbidden on a day with an approved absence. | If the day already has an approved vacation/sickday/PN/etc., new worktime is blocked. To work that day, the employee must withdraw/cancel the absence first. |
| H7 | Overtime is forbidden during any absence. | Logical extension of H6. |
| H8 | Documents are required to *finalise* Paragraph/OCR/Special. | The submission can be saved without a doc, but the absence cannot reach Approved until HR has validated a document. |
| H9 | A full-day absence and worktime on the same day cannot coexist. | Stronger restatement of H6 in the case where the absence is already in the system. |
| H10 | Two absences cannot occupy the same morning/afternoon slot. | If the morning is already Paragraph, a vacation half-day for the same morning is blocked; the afternoon slot is independent (a half-day afternoon vacation is allowed). This includes a **full-day** absence colliding with an existing half-day on either slot — a full-day claims both slots, so it conflicts with any pre-existing half-day. The employee must instead take a half-day for the free slot. |

### 9.2 Soft rules

| ID | Rule | Plain-English explanation |
|---|---|---|
| S1 | 30-minute gap between half-day absence and same-day worktime. | If a morning Paragraph ends at 12:00, worktime should not start before 12:30. Vice versa for afternoon absences. |
| S2 | Worktime outside the working window. | Worktime entries with a start before the configured day-start (default 08:00) or an end after the configured day-end (default 16:30) are flagged. Allowed but unusual. The default window can be overridden globally by Admin (§12.2). |
| S3 | Night-time work (between 22:00 and 06:00). | Late-night / very-early hours are unusual; the portal flags but does not block. |
| S4 | A single worktime entry exceeding 8 hours. | The system suggests splitting into morning + afternoon blocks. |
| S5 | Quota approaching limit. | Informational warning when a submission would leave the employee at **2, 1, or 0 vacation days remaining** after submission, or at exactly 1 sickday remaining. (When the submission would push the balance below 0, H5 hard-blocks instead — S5 only fires when the submission still fits.) |
| S6 | Worktime on a Slovak public holiday. | Allowed but flagged so HR can verify the entry is deliberate (per §12.1). Soft warning only. |

### 9.3 Validation timing

Validation runs:
- when the user clicks Save on the form,
- when the user edits an existing entry,
- on every state transition of an entry (Pending → Approved, Approved → Cancelled, etc.) — quota or rule-config changes between submission and approval must be re-evaluated. Example: Anna submits a 5-day vacation when she has 19 remaining; before her manager approves, HR overrides her quota down to 3. The Approval transition re-validates and H5 hard-blocks the approve action.
- as a dry-run inside the year-rollover preview (so HR can see what would happen before pressing the button).

Soft warnings persist on the saved entry and are visible to the manager and to HR on every report and in the team calendar.

## 10. Notifications

Notifications are delivered on **two layers**:

- **Basic — in-portal notification feed.** Every event in the table below MUST produce an in-portal notification record visible to each recipient on their *My notifications* screen (§13 #13). State-change visibility (manager queue auto-updates, employee balance refresh, etc.) is also Basic.
- **Bonus — email channel.** Sending the same events as email is **Bonus** (see §14). Slack / Teams / ICS / calendar sync are Bonus axes layered on top of the same dispatcher.

Each event has a single template; the portal must not double-send. **Each unique recipient address receives at most one notification per event, even when the recipient appears in multiple recipient groups** (e.g. an HR-role user who is also on the requester's team gets one record, not two).

> **Gherkin reading guide.** Where the `acceptance/` Gherkin scenarios assert that a recipient "receives an X email", the assertion is Basic only insofar as the **in-portal notification record** is produced and visible on the recipient's *My notifications* screen. The literal email is delivered only when the email-channel Bonus (§14) is implemented; eval-runs without that Bonus pass the same scenario by inspecting the notification record rather than an SMTP capture. Teams should treat "email" in Basic Gherkin as shorthand for "notification event of that kind"; teams implementing the email Bonus additionally satisfy a corresponding `@bonus @email-channel` scenario that asserts an SMTP capture exists for the same event.

| Trigger | Recipients | What the message says |
|---|---|---|
| Vacation / Paragraph / OCR / Special / Overtime submitted | direct manager (or HR group if escalated) | "Approval needed: {employee} requests {type} for {dates}." + portal link |
| Approval decision (Approve / Reject) | the employee who submitted | "Your {type} request was {approved/rejected}." + reason if rejected |
| **Withdrawal** (employee withdraws Pending request) | direct manager (queue is now shorter) | "{employee} withdrew their {type} request for {dates}." |
| **Cancellation** (employee cancels Approved future absence) | direct manager + HR group | "{employee} cancelled their {type} for {dates}." |
| Sickday logged | direct manager + same-team members + HR group | "{employee} on sickday {date}." |
| PN logged | direct manager + same-team members + HR group | "PN from {date_from}{ until {date_to}}." |
| Document uploaded | HR group | "New document for {employee} {type} {dates}." |
| Document validated | the **employee whose absence carries the document** (regardless of who attached it — see §16 O8) | "Document for {type} {dates} {approved/rejected}." + reason if rejected |
| Quota approaching (fired once at submission when S5 triggers; not periodic) | the employee + HR | "Vacation balance: {n} days left." |
| Year rollover summary (1 January) | every employee + HR | "Carried over: {n} days. Bonus lost: yes/no." |

The "same-team members" list is everyone whose `team` field equals the requester's team, excluding the requester. The HR group is the email distribution `hr-kosice@visma.com` (used only when the email channel Bonus is implemented) **plus** every user holding the HR role (used for in-portal feed entries). The dedup rule above prevents double-delivery when both lists overlap.

## 11. Reports

### 11.1 Monthly HR export (XLSX)

The monthly export must match the **external accounting system's** layout byte-for-byte. The reference fixture file is `Attendence_example_report.xlsx` (in the parent Hackatlon folder; teams may copy it into their own repo). The export is a single Excel workbook with **two sheets**, both bilingual per the user's selected language at download time. Slovak is the default; the download dialog offers a language override per export.

#### Sheet 1: Attendance (sheet name localised — Slovak: `Dochádzka`, English: `Attendance`)

Wide matrix layout. One row per **half-day** (morning + afternoon) for the entire calendar month, including weekends and holidays. One **block of three columns per employee**. Employees ordered alphabetically by last name.

| Column index | Header (localised) | Meaning |
|---|---|---|
| 1 | Day | Day, formatted `dd.MM.yyyy {morning-label}` or `dd.MM.yyyy {afternoon-label}`. Two rows per calendar day. SK: `Deň` / `Doobedu` / `Poobede`. EN: `Day` / `Morning` / `Afternoon`. |
| 2, 5, 8, … | `{firstName} {lastName}` | Activity label for that employee for that half-day. Employee names themselves are never translated. |
| 3, 6, 9, … | Time | Time range as a string, e.g. `08:00 - 12:00`. SK header: `Čas`. EN header: `Time`. Weekends and absences without a specific time use the conventional `08:00 - 12:00` / `12:30 - 16:30` split. |
| 4, 7, 10, … | Hours | Hours as a decimal number, e.g. `4.0`. `0.0` for weekend rows. SK header: `Hodiny`. EN header: `Hours`. |

**Activity-label catalogue** (column 2 / 5 / 8 …):

| Source data | Slovak | English |
|---|---|---|
| Worktime entry on a working day | `Práca` | `Work` |
| Worktime entry with BT flag | `Pracovná cesta` | `Business trip` |
| Public holiday | `Sviatok` | `Holiday` |
| Weekend — activity column | `V` | `W` |
| Weekend — time column (literal text instead of a range) | `Víkend` | `Weekend` |
| Approved vacation absence (statutory or bonus, indistinguishable in this sheet) | `Dovolenka` | `Vacation` |
| Approved sickday | `Sickday` | `Sickday` |
| Approved PN / paternity | `PN` | `Sick leave` |
| Approved Paragraph / doctor visit | `Návšteva lekára` | `Doctor visit` |
| Approved OCR / family-member care | `Sprevádzanie člena rodiny` | `Family care` |
| Approved special leave | `Špeciálne voľno` | `Special leave` |

A half-day absence emits the absence label on its half and the work label (or weekend / holiday label) on the other half. Example: morning Paragraph + afternoon work on 2026-04-08 in Slovak renders as `08.04.2026 Doobedu | Návšteva lekára | 08:00 - 12:00 | 4.0` then `08.04.2026 Poobede | Práca | 12:30 - 16:30 | 4.0`.

**Worked example (excerpt — 3 employees on 2026-04-01, Slovak export):**

```
Deň                | Jožko Mrkvička | Čas           | Hodiny | Linda Robotová | Čas           | Hodiny | Dunčo Ušatý | Čas           | Hodiny
01.04.2026 Doobedu | Práca          | 08:00 - 12:00 | 4.0    | Práca          | 07:00 - 11:00 | 4.0    | Práca       | 08:30 - 12:30 | 4.0
01.04.2026 Poobede | Práca          | 12:30 - 16:30 | 4.0    | Práca          | 11:30 - 15:30 | 4.0    | Práca       | 13:00 - 17:00 | 4.0
```

#### Sheet 2: Overtime (sheet name localised — Slovak: `Nadčas`, English: `Overtime`)

A separate sheet that lists only approved overtime entries. One block per employee who has at least one overtime entry that month. Employees with no overtime that month are omitted.

Each block:

| Row | Col 1 | Col 2 | Col 3 | Col 4 |
|---|---|---|---|---|
| Header row | `{firstName} {lastName}` | Day header | Time header | Hours header |
| Data row(s) | Overtime label | date `dd.MM.yyyy` | time range `HH:MM - HH:MM` | hours decimal |
| Blank row | — | — | — | — | (separator between employees) |

**Overtime catalogue labels:**

| Source data | Slovak | English |
|---|---|---|
| Sheet name | `Nadčas` | `Overtime` |
| Data-row activity label | `Nadčas` | `Overtime` |
| Day header | `Deň` | `Day` |
| Time header | `Čas` | `Time` |
| Hours header | `Hodiny` | `Hours` |

**Example block (Slovak):**

```
Linda Robotová  | Deň          | Čas             | Hodiny
Nadčas          | 30.04.2026   | 16:30 - 20:30   | 4.0
                |              |                 |
Dunčo Ušatý     | Deň          | Čas             | Hodiny
Nadčas          | 24.04.2026   | 17:00 - 21:00   | 4.0
Nadčas          | 25.04.2026   | 08:00 - 14:00   | 6.0
```

#### Generation rules

- Download allowed for HR + Admin only.
- Date range is a single full calendar month picked by HR.
- Export language defaults to the user's portal preference; the download dialog allows a per-export override.
- Half-day labels follow the locale catalogue: SK `Doobedu` / `Poobede`, EN `Morning` / `Afternoon`. The data segment (`dd.MM.yyyy`) is locale-independent.
- Weekend rows always render the localised weekend marker (SK `V` + `Víkend`, EN `W` + `Weekend`) regardless of any logged worktime; weekend-logged worktime is preserved in the audit log and in the Bonus Exceptions Replay screen (§11.6) but does not enter the attendance sheet — payroll treats it separately.
- Public holidays override the activity column with the localised `Sviatok` / `Holiday` label; the time and hours still reflect the standard half-day split.
- Hours are decimals with one digit precision (`4.0`, `4.5`, `6.0`). Decimal separator follows locale (`.` for EN, `,` for SK).
- The XLSX has the first row (header) and the first column (Day) frozen for easy scrolling, and column widths set sensibly so labels are not truncated in either language.

#### CSV companion (optional, secondary)

A flat CSV companion file may be offered for HR scripts that prefer one row per person per half-day:

`date | half | full_name | activity | time_range | hours`

The same locale catalogue applies — `activity` is in the picked language; the `half` column and the header line follow the same locale rules. The CSV is informational only; the XLSX above is the canonical export.

### 11.2 Team calendar (in-portal view)

Rows are team members (everyone whose `team` field matches the selected team), columns are days of the picked month. Calendar is keyed off `team` membership, NOT the org tree (per glossary §2). A manager whose direct reports span multiple teams sees one team at a time and switches via a team picker.

Each cell shows:
- absence type (colour-coded), or
- worktime hours total, or
- "BT" badge if any business-trip entry, or
- "Pending" badge if there is a pending approval routed to the manager.

The manager can click a cell to drill in.

### 11.3 Balances report (per-user)

For the picked year and user: every quota (statutory vacation, bonus vacation, sickday, paragraph, OCR) with allocated, used (per §6.5 — sum of Approved entries), reserved (sum of Pending), carried-over, remaining, and a "bonus lost?" flag. The "bonus lost?" flag is derived: it is `true` iff the picked year's `bonus_allocation == 0` while the previous year would have allocated the default — i.e. the over-accumulation penalty (§6.3) fired into this year. The balance screen MAY also surface the realised-vs-planned split.

### 11.4 Pending approvals queue

Manager dashboard default: every Pending request routed to them (`direct_manager_id` match), sorted oldest first. The skip-level filter from §7.2 ("I can approve via chain") is opt-in and broadens the queue to any Pending request from a descendant in the org tree. HR dashboard: every Pending document.

### 11.5 Audit log

HR/Admin only. Filter by user, date, **action** (Submit, Approve, Reject, Withdraw, Cancel, HR-Override, Document-Approve, Document-Reject, Quota-Override, Year-Rollover-Apply). Every state change of an absence, approval, document, or per-user quota override is recorded with actor, timestamp, before-snapshot, after-snapshot. (Whether HR/Admin global *configuration* edits — global quota defaults, public holiday list, half-day windows — are also audited is open.)

### 11.6 Exceptions replay (Bonus tier)

**Behaviour, not mechanism.** The portal must surface submissions that *now* violate hard rules under current configuration; HR can review and act. Trigger mechanism is left to each team — scheduled job, on-config-change hook, on-demand button, or real-time recompute are all acceptable. Judges score on the resulting screen + correctness of flagged entries, not on how the recompute is wired.

## 12. Calendar handling

### 12.1 Public holidays

Slovak public holidays are imported once at setup time and cached in the portal. The reference seed (15 SK 2026 holidays) lives in `dev-extras/integration/mock-server/src/store/seed.ts` (`SK_HOLIDAYS_2026`); teams may re-encode it in whatever shape their stack prefers. The Admin can edit the list at runtime to handle ad-hoc changes (e.g. moved holidays).

A worktime entry on a public holiday is allowed but produces a soft warning so HR can verify it was a deliberate choice.

### 12.2 Half-day time ranges

A standard working day is **08:00–12:00 + 12:30–16:30 = 8h** with a 30-minute lunch break between 12:00 and 12:30. Half-day absence ranges are derived directly:

- **Morning half-day: 08:00–12:00** (4 working hours covered by absence)
- **Afternoon half-day: 12:30–16:30** (4 working hours covered by absence)

The 30-minute lunch break keeps S1 ("30 min gap between half-day absence and same-day worktime") trivially satisfiable when the employee logs worktime in the standard slot. The user does not configure these ranges; the Admin can override globally if the company changes its working pattern.

Worktime logged with a start before 08:00 or an end after 16:30 triggers S2 (outside working window, soft). Worktime logged between 22:00 and 06:00 triggers S3 (night-time work, soft). Both are warnings only and never block submission.

## 13. Basic acceptance — what must work end-to-end on demo day

The senior + AI-assisted baseline. **All of the following are required and must pass the Gherkin acceptance scenarios in `acceptance/` before any Bonus axis is counted.**

**Suggested build order** (informative, not enforced): identity + mock auth (#1, #2) → worktime (#3) → first absence type — vacation full loop (#4) → sickday (#5) and Paragraph + document flow (#6) → manager calendar + approvals queue (#7, #8) → reports + balances (#9, #14) → year-rollover engine (#11) → audit log (#12) → notifications inbox (#13). Items #10 (HR documents queue) and #14 (balances) piggyback on the data model laid down by earlier items.

> **Note on role separation.** The role matrix in §3 is a *logical* separation (HR sees documents, Admin manages structure) — it is not a security boundary. Privilege-elevation prevention (e.g. preventing an Admin from granting themselves the HR role) is **out of MVP scope**. Don't lose hackathon time hardening it.

1. Admin creates teams, assigns managers (sets `direct_manager_id` on each user, building the org tree), invites users with roles. UI is polished, validates input, shows feedback.
2. **Mock login** — pick a user from the seeded list, no password. (Real auth — OIDC / magic-link / password+bcrypt — is **Bonus**, see §14.)
3. Employee logs daily worktime: project optional, BT toggle, overtime auto-detect on entries > 8 h. Inline live validation as the user types, not just on submit.
4. Employee submits a vacation request → manager's approvals queue updates without reload → manager approves → employee's *My notifications* feed shows the decision and balance refresh → team calendar reflects the change → vacation balance recomputes per §6.5. The whole loop renders without page reloads. **Email delivery of the same events is Bonus (§14).**
5. Employee logs a sickday: every hard rule is enforced (full-day only, ≤ 3/year, no consecutive sickdays, working day only) → in-portal notification records produced for manager + team + HR. The block message is human-friendly and suggests the right alternative (e.g. "use PN"). **Email delivery is Bonus.**
6. Employee submits a Paragraph absence with a PDF → manager approves → HR validates the document. Reject path also works end-to-end: HR rejects, absence transitions to Rejected (per §6.5 the entry stops contributing to `used`), in-portal notification produced for the employee, audit log updated. **Email delivery is Bonus.**
7. Manager team calendar is a real grid: rows = team members, columns = days of current month, colour-coded cells, click-through to entry detail, pending-approval badges, BT badges. Switching months works.
8. Manager approvals queue is live: appears immediately on submission, supports approve / reject with a reason, decision propagates to the employee instantly. **Skip-level approve via chain** works — an ancestor in the org tree can approve a request routed to a subordinate manager.
9. HR exports a monthly XLSX matching the two-sheet layout in §11.1. The Slovak export must match `Attendence_example_report.xlsx` (sheet names `Dochádzka` + `Nadčas`, activity labels per the catalogue in §11.1). The English export produces the same layout with translated headers and labels (`Attendance` + `Overtime`, etc.). The user's portal language preference picks the default; the download dialog allows a per-export override. The XLSX has the first row and the first column frozen and column widths set sensibly. A flat CSV companion is optional and informational only.
10. HR documents queue is real: list of pending docs with file preview (image inline, PDF in iframe), approve / reject + reason. The employee's *My notifications* feed surfaces the validation outcome instantly (email is Bonus).
11. Year-rollover dry-run on a fixture set produces correct outcomes for: leftover within limit (no bonus loss), leftover exceeding limit (bonus zeroed and excess lost), zero leftover. A button on the HR screen runs the rollover for real, with a confirmation modal and a side-by-side before/after preview.
12. Audit log screen for HR / Admin: filterable by user, action, date. Each row shows actor, before-snapshot, after-snapshot.
13. *My notifications* screen per user: every notification record produced for me, in chronological order, with the rendered subject + body. (When the email channel Bonus is implemented, the same record corresponds 1:1 with the email actually sent.)
14. Quota & balances screen per user: every quota type with allocated / used / **reserved** (Pending entries per §6.5) / carried-over / remaining / lost-bonus flag, plus an annual usage chart by month.

## 14. Bonus tier — only counted if Basic ≥ 90%

Off-limits until every Basic scenario passes. Judges enforce the gate.

- **Real auth** — Google / Microsoft OIDC, magic-link email, or password + bcrypt.
- **§11.6 Exceptions replay** — surface submissions now violating hard rules under current config; trigger mechanism is the team's call.
- **Skip-level *policy* enforcement** — beyond the baseline permission to skip-level approve, allow a configurable rule per team (e.g. vacation > 5 consecutive days requires both direct manager and skip-level).
- **Notification & calendar axes** — four related but distinct mechanisms; teams can pick any subset. Email is the foundational dispatcher, the others layer on it.
  - **Email delivery channel** (foundational) — fan out the in-portal notification records of §10 over SMTP. Single template per event; respect the dedup rule. Most other notification axes assume a working email dispatcher.
  - **Slack and/or Teams notification channels** — push the same events to chat. The dispatcher should be pluggable; reuse the email template registry.
  - **Calendar synchronisation** — push approved absences to a shared Google or Outlook team calendar. Read-only is fine. Distinct from notifications: mutates a calendar resource rather than sending a message.
  - **Public ICS feed** per team and per user — read-only feed consumers subscribe to from their own calendar app. Pull-model, not push.
- **Mobile-friendly responsive UI.** The team calendar can degrade gracefully on phones; the absence form should work fully on mobile.
- **PWA or installable shell**, so employees can launch the portal as an app on their phone home screen.
- **Multi-language UI.** Slovak + English at minimum. The rule messages are user-visible and benefit most.
- **Tempo XLSX import.** Drop a historical Tempo export onto the HR screen, the portal ingests it, classifies entries with the new rule engine, shows the diff before committing. The classify-against-current-rules step shares its replay engine with §11.6 (Exceptions replay) — implement the engine once and reuse for both axes.
- **HR bulk-edit of quotas** via uploaded CSV; preview diff before applying.
- **Manager analytics:** team-level absence patterns (heat map of absences by week), average approval latency, soft-warning hot spots.
- **Live websocket updates** so the manager's approvals queue updates without refresh when an employee submits.
- **Two-factor auth** for HR and Admin roles.
- **Rate limiting** — per-IP / per-user request throttles on submission, login, and document upload endpoints. Anti-abuse / anti-DoS posture.
- **Audit-log tampering protection** — append-only table with a hash chain (each row's hash includes the previous row's hash). Detects retroactive edits of audit entries.
- **UX polish axes** (§17.2) — live balance badge, side-panel calendar drill-in, keyboard shortcut, designed empty states, skeleton loaders, in-progress data preservation. Each axis can be picked up independently; collectively they sharpen demo quality without affecting correctness.

## 15. Out of scope (do not attempt in a single day, even with AI)

- Migration of *production* historical Tempo data with full data integrity. (The §14 Bonus axis "Tempo XLSX import" is a sandbox version — drop a file, see the diff, optionally commit. Out-of-scope here is the harder problem: real-data validation, dedup against existing entries, conflict resolution, and a rollback path.)
- Multi-tenant SaaS architecture.
- Multi-country support beyond Slovak rules.
- Real Visma corporate SSO integration end-to-end including provisioning. (A generic OIDC flow against Google or Microsoft personal account is fair game and counts as Bonus.)
- Native iOS / Android apps.
- Offline mode with conflict resolution.

## 16. Open questions and chosen defaults

Tier placement (Basic vs Bonus) is now settled. Remaining defaults:

| # | Question | Default applied if a team does not address it |
|---|---|---|
| O1 | What auth mechanism for the demo? | **Mock login (Basic).** Real auth is Bonus. |
| O2 | "Same-team members" for sickday/PN notifications — same `team` only, or also project teammates? | Same `team` only. |
| O3 | What happens when an Approved absence is later cancelled by the employee? | Withdrawal allowed up to one day before; quota refunded; audit entry written. After that day, HR-only. |
| O4 | Half-day morning vs afternoon time ranges? | Morning 08:00–12:00, afternoon 12:30–16:30 (per §12.2). |
| O5 | Should public holidays block worktime entries? | Soft warn only. |
| O6 | First-year prorated entitlement for new hires? | Out of MVP — full year entitlement on join. |
| O7 | Self-approving manager — escalate where? | Walk up org tree to first non-self ancestor; HR group if exhausted. |
| O8 | PN doctor's papers — uploaded by employee or HR? | Either is fine; the document attaches to the same PN entry. |

Further open questions raised during spec authoring (PN/paternity workflow split, cancel-vs-reject race, H7 vs PN weekends, split-day export rows, audit-log scope of HR config edits, accident-PN documents, special-leave soft-cap wording, sickday consecutive-working-days definition) are tracked organiser-side. Their resolution may produce small clarifications in this spec; no behaviour-affecting change is expected before the event.

## 17. UX guidance

The bullets below are split into a **Basic UX baseline** (required for the §13 acceptance scenarios to feel genuinely usable) and **Polish Bonus axes** (counted only when Basic ≥ 90%; see also §14).

### 17.1 Basic UX baseline (required)

- A landing page / dashboard for each role: Employee sees their balances, today's entry, pending requests; Manager sees the approvals queue and the team calendar; HR sees the documents queue, monthly export button, and configuration screens.
- An absence-submission form that picks the type first (because the rules differ per type), then surfaces the right fields (full vs half day, document upload if required).
- Hard-rule errors render inline at the top of the form, in red, with the rule's plain-English message; soft warnings render in yellow and have a "Save anyway" button.
- The team calendar is a grid, one row per team member, one column per day, scroll-free for the current month on a normal laptop. (Side-panel drill-in is Polish Bonus — see §17.2.)
- *My notifications* screen surfacing the in-portal notification feed (§10) so the user can review their event history.
- Date fields default sensibly: today for "from", same as "from" for "to" until the user changes it.

### 17.2 Polish Bonus axes (counted when Basic ≥ 90%)

- **Live "remaining balance" badge** on the absence form, recomputed as the user changes dates (per §6.5 the recompute is straightforward — sum entries given the candidate dates).
- **Calendar side-panel drill-in** — clicking a calendar cell opens the day's detail in a side panel without leaving the page.
- **Keyboard shortcut to log today's worktime** in two keystrokes.
- **Designed empty states** — not blank panels; tell the user what to do next.
- **Skeleton screens for loading states** instead of spinners.
- **In-progress data preservation across accidental navigation** — auto-save form work into the Draft state (§7) so it survives a closed tab or back-button.

## 18. Suggested team split for the hackathon

Senior teams with AI tooling can run wider in parallel than the conservative split below. Adjust based on individual familiarity with the chosen stack.

If a team has 4-7 people:
- 1 — Identity, teams, mock auth (Basic) and/or real auth (Bonus), RBAC, admin console.
- 1 — Validation rules + quota math + year-rollover engine. (§9 + §6 are the spec.)
- 1-2 — Absence + approvals + documents flows, end-to-end including the email loop.
- 1 — Worktime + overtime + business trip + live form validation UX.
- 1 — Reports + team calendar grid + balances charts + audit log screen.
- 1 — In-portal *My notifications* inbox (Basic) + dispatcher scaffolding for the email channel and Slack/ICS/calendar-sync axes (Bonus per §10 / §14) once Basic is green.

If a team has 2-3 people: build vertical slices in the order Identity + mock auth → Worktime → Vacation flow → Sickday flow → Paragraph + documents → Reports. Aim to finish one slice every ~2 hours so the demo has at least four end-to-end flows.

**If the team includes a Business Analyst**, route them to `ba/story-template.md` and `ba/slicing-guidance.md` (core bundle). They continuously refine the slice plan as build progresses, surface scope risks against the §13 acceptance set, and keep the team focused on the Basic tier before any Bonus drift.

---

This document is the specification of the *product behaviour*. Implementation choices (programming language, database, UI framework, deployment, auth mechanism) are entirely up to each team.
