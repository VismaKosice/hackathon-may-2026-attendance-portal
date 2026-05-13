# Story Template — Hackathon Attendance Portal

**Audience:** Business Analyst at the hackathon, producing the analysis bundle.
**Purpose:** Per-story shape; use as a fill-in template for every story in the bundle.
**Companion:** [`slicing-guidance.md`](slicing-guidance.md) for the playbook; [`scoring-rubric.md`](scoring-rubric.md) for how the bundle is judged.
**Date:** 2026-05-12

> **The spec is the contract.** Each story slices [`../product-spec.md`](../product-spec.md) — never invents new requirements. Anything the spec leaves undefined is the build team's discretion and is not judged.

---

## The template

```
ID:     S-NN  (S-01, S-02, …; assigned in slicing order)
Title:  <verb-first, 6-10 words>  e.g. "Submit vacation request from employee dashboard"
Tier:   Basic | Bonus
Spec:   product-spec §<n>  +  acceptance/<file>.feature:<scenario-name>
Size:   ~2h  (target; flag anything > 3h for re-slicing)

User story:
  As a <role>
  I want <capability>
  so that <outcome>

Acceptance criteria (Given/When/Then):

  Scenario: <happy path — name in plain English>
    Given <preconditions — system state, fixtures, who the actor is>
    When <single user action>
    Then <observable outcome — UI state, persisted state, side-effect>
    And <additional observable outcome, if any>

  Scenario: <edge / rule-trip case — name>
    Given <state that brings the rule into play>
    When <action>
    Then <expected block / warning / branch>

  # Add one Scenario per hard rule the story exercises and per branch
  # the story claims to cover. Two-to-five scenarios is typical for a
  # 2h story. More than five = re-slice.

Mapping:
  - Existing Gherkin in acceptance/: <file.feature:scenario-name OR "none — proposed new">
  - Hard rules hit: <H1 / H2 / ... or "none">
  - Soft rules hit: <S1 / S2 / ... or "none">
  - Notifications produced: <event names per spec §10 or "none">
  - Audit entries produced: <event names per spec §11.5 or "none">

Depends on:  <S-XX, S-YY>     # previous stories that must merge first
Blocks:       <S-XX>          # downstream stories waiting on this one

Demo cue: "<one sentence the demo presenter could say>"
Notes:    <optional, ≤ 2 lines — judges read these; brevity scores>
```

**Keep it on one screen.** A scrolling story is a specification document. Stop.

### Authoring rules for Given/When/Then

- **Given = state, not action.** "Anna has 3 vacation days remaining" — not "Anna logs in".
- **When = a single user action.** One verb. Multi-step setup belongs in Given via `And`.
- **Then = an observable outcome.** UI state, persisted state, notification record, audit entry. Internal implementation details (DB tables, function calls) do not belong here.
- **Use `And` / `But` for additional clauses** within the same step. `Then ... And ... And ...` is standard.
- **One scenario per outcome shape.** Approve and Reject are two scenarios, not one with branches.
- **Concrete fixtures.** "Anna" (per the seeded fixture) is stronger than "an employee". Tie to the fixture user names where you can.
- **No "should" / "could" / "might".** Then is a fact, not a hope.

### Authoring boundary — acceptance/ wins on conflict

`acceptance/*.feature` is the **judging contract** authored upfront and shipped to teams. BA-authored G/W/T in stories is **analysis output**. When the two conflict on the same scenario, `acceptance/` wins by definition — judges score teams against `acceptance/`, not against BA stories.

This means:
- **For scenarios already in `acceptance/`** — write your own G/W/T anyway (it is your analysis), but cite the existing scenario via `Mapping → Existing Gherkin`. Two formulations of the same behaviour is fine; one is the contract, one is your work.
- **For scenarios not in `acceptance/`** — mark `Mapping → none — proposed new` and write the G/W/T fresh. These are the highest-leverage outputs in your bundle: scenarios the upfront Gherkin missed.
- **Never claim a scenario is in `acceptance/` when it isn't.** Judges check. Mis-citations are penalised under the Polish axis.

---

## Worked example 1 — Basic, vertical

```
ID:    S-04
Title: Submit vacation request — happy path
Tier:  Basic
Spec:  product-spec §4.1 + §13 #4
       acceptance/employee.feature:"Submit a vacation request for next week"
Size:  ~2h

As an employee
I want to submit a vacation request with a date range
so that my manager can approve it and my balance updates

Acceptance criteria (Given/When/Then):

  Scenario: Submit a vacation within remaining balance
    Given Anna is logged in as an employee
      And Anna has 19 vacation days remaining for 2026
      And Anna has a direct manager Tomáš
    When Anna submits a vacation request for 3 working days next month
    Then the request appears in Anna's "My entries" list with state "Pending"
      And Anna's remaining-vacation balance shows 16 (3 reserved)
      And a notification record is created for Tomáš ("AbsenceSubmitted")
      And an audit entry "absence.submitted" is written with the before/after snapshot

  Scenario: H5 hard rule blocks submission beyond remaining balance
    Given Anna has 2 vacation days remaining for 2026
    When Anna submits a vacation request for 3 working days
    Then the submission is blocked with rule discriminator "H5"
      And the inline error reads "Quota exceeded: you have 2 days remaining"
      And no entry is persisted
      And no notification is sent

  Scenario: S5 soft warning when submission leaves ≤ 2 remaining
    Given Anna has 5 vacation days remaining for 2026
    When Anna submits a vacation request for 4 working days
    Then a yellow warning shows "S5: approaching limit (1 day remaining)"
      And a "Save anyway" button is presented next to "Save"
      And clicking "Save anyway" persists the entry with the warning recorded

Mapping:
  - Existing Gherkin in acceptance/: employee.feature:"Submit a vacation request for next week" (@basic),
                                     employee.feature:"Vacation submission appears on manager's queue" (@basic)
  - Hard rules hit: H5
  - Soft rules hit: S5
  - Notifications: AbsenceSubmitted → direct manager
  - Audit: absence.submitted with before/after snapshot

Depends on:  S-01 (mock login), S-02 (user has team + direct_manager_id)
Blocks:      S-05 (manager approve), S-09 (calendar reflects)

Demo cue: "Anna submits a 3-day vacation; it lands on Tomáš's queue within 30 seconds."
Notes: Live balance badge per FE refinement §13 surfaces here.
```

## Worked example 2 — Basic, rule-only slice

```
ID:    S-04b
Title: H4 — block consecutive sickdays
Tier:  Basic
Spec:  product-spec §9.1 H4
       acceptance/employee.feature:"Cannot log a sickday on a consecutive day"
Size:  ~1h

As an employee
I want a clear inline error when I try to log a sickday adjacent to yesterday's
so that I know to use PN instead

Acceptance criteria (Given/When/Then):

  Scenario: H4 blocks back-to-back sickdays
    Given Anna logged a sickday for yesterday
    When Anna attempts to log a sickday for today
    Then the submission is blocked with rule discriminator "H4"
      And the inline error contains the suggestion "use PN instead"
      And no entry is persisted

  Scenario: H4 does not trigger across a one-day gap
    Given Anna logged a sickday for Monday
    When Anna logs a sickday for Wednesday
    Then the submission succeeds
      And the entry is persisted with state "Approved"

  Scenario: H4 honours consecutive calendar days across a weekend (proposed)
    Given Anna logged a sickday for Friday
      And Saturday and Sunday are not sickdays
    When Anna logs a sickday for Monday
    Then the submission succeeds — H4 measures consecutive *sickday* entries,
         not consecutive calendar days that happen to be working days

Mapping:
  - Existing Gherkin in acceptance/: employee.feature:"Cannot log a sickday on a consecutive day" (@basic)
  - Proposed new: "H4 does not trigger across a one-day gap",
                  "H4 honours consecutive calendar days across a weekend"
  - Hard rules hit: H4
  - Soft rules hit: none
  - Notifications: none
  - Audit: none (rejected submissions are not persisted)

Depends on:  S-04a (sickday submit happy path)
Blocks:      none

Demo cue: "Anna tries sickday today after yesterday's sickday — block + 'use PN' hint."
Notes: Error must contain rule ID 'H4' as discriminator (per FE testing §5).
       Proposed scenarios resolve the spec §9.1 H4 wording — open per DEC-026.
```

## Worked example 3 — Bonus, gated

```
ID:    S-B-03
Title: Email delivery channel for submission events
Tier:  Bonus
Spec:  product-spec §14 "Email delivery channel (foundational)"
       acceptance/employee.feature:"@bonus @email-channel" block
Size:  ~2h

As an employee
I want the same notifications I see in the portal delivered to my inbox
so that I don't have to refresh the portal to know my request was approved

Acceptance criteria (Given/When/Then):

  Scenario: Email mirrors AbsenceApproved notification
    Given Anna submitted a vacation request
      And Tomáš is Anna's direct manager
      And the email outbox is configured (MailHog at the documented endpoint)
    When Tomáš approves the request
    Then an in-portal notification record is created for Anna
      And one email is delivered to Anna's seeded address
      And the email subject and body match the registered template for "AbsenceApproved"
      And no duplicate email is delivered if the approval is replayed (idempotency)

  Scenario: Recipients in multiple groups receive exactly one email
    Given Anna submitted a sickday triggering fan-out to manager + same-team + HR
      And one HR user is also Anna's direct manager
    When the system fans out the AbsenceSubmitted event
    Then that HR user receives exactly one email
      And the dedup key is (event_id, recipient_id)

Mapping:
  - Existing Gherkin in acceptance/: employee.feature @bonus @email-channel block
  - Hard rules hit: none (Bonus axis on top of Basic notifications)
  - Soft rules hit: none
  - Notifications: AbsenceSubmitted, AbsenceApproved, AbsenceRejected (Basic),
                   email channel layered on top (Bonus per spec §14)
  - Audit: notification.dispatched (per email)

Depends on:  S-13 (in-portal notification feed working — Basic gate)
Blocks:      S-B-04 (Slack channel reuses dispatcher)

Demo cue: "Approve → MailHog shows the email within 5 seconds."
Notes: Gated — recommend only when team is on track for Basic ≥ 90%.
       Template registry stays pluggable so Slack/Teams reuse the dispatcher.
```

---

## Slicing rules

1. **2-hour target.** If you cannot see how a senior + AI pair finishes the slice in ~2h, split it. Carve along rule boundaries (one hard rule per story), state-machine transitions (Submit → Approve as two stories), or persona surface (Employee submit vs Manager approve).
2. **At least one Given/When/Then scenario per story.** A story with no G/W/T is a refactor task, not a slice. Most stories have 2-5 scenarios (happy path + 1-2 rule trips + 1-2 edges).
3. **Vertical slices beat horizontal layers.** "Submit vacation end-to-end" beats "build absence DB schema". Stay demo-able.
4. **Hard rule + happy path can be one story.** "Submit vacation with H5 check" is fine. Split only if the happy path itself is heavy.
5. **No story without a Demo cue.** If you cannot name what a presenter would say, the story is not shaped for hackathon delivery.
6. **Notification + audit are part of the story.** A "submit vacation" story that omits audit + notification fan-out is incomplete per spec §10 + §11.5. Cover them in a G/W/T scenario or `And` clauses.
7. **Withdraw / cancel are their own stories.** They share the form but trigger different transitions and notification fan-outs.
8. **Bonus stories carry a gate note.** Annotate every Bonus story with "Recommend only after Basic ≥ 90%" — your bundle is honest about sequencing.
9. **Do not invent requirements.** If the spec is silent, leave the story silent. You may *propose* a G/W/T scenario marked `(proposed)` that surfaces the gap — judges read these as analytical contributions, not as new requirements imposed on teams. The team is still free to choose otherwise; the spec's silence is the team's discretion.

## Definition of Done — per story

A story is considered "done" when a team that uses it could say all of these are true. You do not enforce this — you describe it.

- [ ] Linked Gherkin scenario(s) pass.
- [ ] Hard rule(s) named in the story trip with the spec §9.1 message.
- [ ] Notification record(s) and audit entry written (or "none" was declared upfront).
- [ ] Demo cue rehearsed once against a real running portal.
- [ ] Code merged into `main` — the scoring system pulls each team's `main` branch.

## What this template is NOT

- A user-research artefact. Personas are settled (spec §3); no discovery loop.
- A backlog-grooming ritual. You produce, you do not facilitate.
- A signing-off mechanism. The Gherkin scenario is the gate, not the BA.
- A test-case repository. Acceptance references Gherkin; do not duplicate Given/When/Then in the story body.
- A coordination tool. Owner / Pair fields removed by design — teams own their own assignment.

## Tool tips

- **Index in a spreadsheet or table.** Columns: `ID | Title | Tier | Size | Depends-on | Blocks | Demo cue`. The bundle ships this index as a CSV / Markdown table alongside the per-story files.
- **One file per story** under `stories/S-NN.md` is reviewer-friendly; one big file is also acceptable if the bundle is small.
- **AI-assist for drafting.** Paste the spec §13 item into Claude with this template; ask "split into 2h hackathon stories". Review + adjust. Show the prompt in the bundle — visible AI direction earns Polish points (per [`scoring-rubric.md`](scoring-rubric.md)).
- **Cluster by acceptance feature file.** Stories touching `employee.feature` co-evolve; same for `manager.feature`, `hr.feature`. Useful when judges scan for coverage.
