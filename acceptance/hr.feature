# HR-facing scenarios. Actor = a user with the HR role.
# Tags: @basic / @bonus.
#
# Notification reading guide (per product-spec.md §10):
#   In @basic scenarios, "receives an X notification" asserts the in-portal
#   notification record on the recipient's "My notifications" screen. The
#   literal email is asserted only by @bonus @email-channel scenarios at the
#   bottom of this file.
#
# Export reading guide (per product-spec.md §11.1):
#   The canonical monthly export is a two-sheet XLSX (`Dochádzka` / `Nadčas`
#   localised) matching `Attendence_example_report.xlsx`. The legacy flat
#   CSV "date,full_name,team,flag,hours,project_code,comment,errors" is a
#   secondary informational companion only (§11.1 CSV companion subsection).

Feature: HR — documents queue, monthly export, audit log, quotas, exceptions replay (Bonus)

  Background:
    Given the seeded fixture users, teams, holidays and quotas for 2026 are loaded
    And I am logged in via mock login as HR user "HR1"

  # ---- Documents queue ----

  @basic @documents
  Scenario: Pending document appears in HR queue with file preview
    Given employee "Janka" has submitted a half-day Paragraph for "2026-05-12" with PDF "doctor.pdf"
    When I open the "Pending documents" queue
    Then I see Janka's entry with type "Paragraph", dates "2026-05-12 morning", and an inline PDF preview

  @basic @documents
  Scenario: Approving a document after manager approval finalises the absence
    Given Janka's Paragraph absence for "2026-05-12 morning" is "Pending HR document validation"
    And the manager has already Approved the absence
    When I Approve the document
    Then the absence status becomes "Approved"
    And Janka's Paragraph balance decrements by "0.5"
    And Janka receives a "Document validated" notification

  @basic @documents
  Scenario: Rejecting a document after manager approval flips absence to Rejected and refunds quota
    Given Janka's Paragraph absence for "2026-05-12 morning" is in state "Approved (manager) / Pending document"
    And Janka's Paragraph balance has decremented by "0.5"
    When I Reject the document with reason "Illegible scan"
    Then the absence status becomes "Rejected"
    And Janka's Paragraph balance is refunded by "0.5"
    And Janka receives a "Document rejected" notification containing the reason
    And an audit-log entry records the document rejection with actor "HR1" and the reason

  @basic @documents
  Scenario: Rejecting a document while absence is still Pending flips it directly to Rejected
    Given Janka's Paragraph absence is in status "Pending" with the manager approval not yet decided
    When I Reject the document
    Then the absence status becomes "Rejected" without waiting for the manager
    And no quota is decremented at any point

  # ---- Monthly export (canonical two-sheet XLSX per spec §11.1) ----

  @basic @export
  Scenario: Monthly XLSX export produces two sheets matching the reference file
    When I export the monthly report for "2026-04" as XLSX in Slovak
    Then the workbook has exactly two sheets named "Dochádzka" and "Nadčas"
    And the "Dochádzka" sheet has the first row and the first column frozen
    And every column width is set wide enough to render the longest sample value without clipping

  @basic @export
  Scenario: Attendance sheet has one row per half-day with the localised day labels
    When I export the monthly report for "2026-04" as XLSX in Slovak
    Then the "Dochádzka" sheet's "Deň" column lists each calendar day in the month twice — once with "Doobedu" and once with "Poobede"
    And every employee block has the header triple "{firstName} {lastName} | Čas | Hodiny"

  @basic @export
  Scenario: Activity labels match the localised catalogue in spec §11.1
    Given fixture entries exist for vacation, business trip, sickday, PN, paragraph, OCR, special leave, public holiday, weekend
    When I export the monthly report for that month as XLSX in Slovak
    Then the activity column uses the labels "Práca, Pracovná cesta, Dovolenka, Sickday, PN, Návšteva lekára, Sprevádzanie člena rodiny, Špeciálne voľno, Sviatok, V" respectively

  @basic @export
  Scenario: English export uses translated headers and labels
    When I export the same monthly report for "2026-04" as XLSX in English
    Then the workbook has exactly two sheets named "Attendance" and "Overtime"
    And the "Day" column uses "Morning" / "Afternoon" labels
    And the activity column uses translated labels (e.g. "Work", "Vacation", "Sick leave", "Doctor visit", "Family care", "Special leave", "Holiday", "W")

  @basic @export
  Scenario: Overtime sheet lists approved overtime entries per employee
    Given fixture user "Linda" has an approved overtime entry on "2026-04-30" from "16:30" to "20:30"
    When I export the monthly report for "2026-04" as XLSX
    Then the "Nadčas" sheet contains a block headed "Linda Robotová | Deň | Čas | Hodiny"
    And the block contains a data row "Nadčas | 30.04.2026 | 16:30 - 20:30 | 4.0"

  @basic @export @csv-companion
  Scenario: Flat CSV companion export (secondary, informational)
    When I export the monthly report for "2026-04" as the flat CSV companion
    Then the header row is exactly "date,half,full_name,activity,time_range,hours"
    And each calendar day in the period produces two rows per employee — one per half

  # ---- Audit log ----

  @basic @audit
  Scenario: Audit log records every state change with before/after snapshots
    Given a vacation request transitions Pending -> Approved -> Cancelled in the seeded fixtures
    When I open the audit log filtered by that vacation
    Then I see three rows with actor, timestamp, and before/after snapshots for each transition

  @basic @audit
  Scenario: Audit log filters work
    When I filter the audit log by user "Anna" and date range "2026-07-01..2026-07-31"
    Then only rows where actor = "Anna" or target user = "Anna" within that range are shown

  # ---- Quotas ----

  @basic @quotas
  Scenario: HR overrides a per-user quota
    When I set Anna's "Statutory vacation 2026" allocation to "25"
    Then Anna's balance screen reflects "25 statutory" allocated
    And the change is recorded in the audit log

  @basic @quotas
  Scenario: HR can edit the default sickday allocation globally
    When I change the global sickday default from "3" to "4"
    Then employees newly onboarded inherit "4"
    And existing employees keep their per-user overrides

  # ---- HR override of approval state ----

  @basic @override
  Scenario: HR overrides an approval and the audit log captures it
    Given Anna has an Approved Vacation from "2026-07-13" to "2026-07-17"
    When I override the absence to status "Rejected" with reason "Booked over a freeze period"
    Then the absence status becomes "Rejected"
    And the audit log shows the override with my user id, reason, and before/after snapshots

  # ---- Bonus ----

  @bonus @exceptions-replay
  Scenario: Exceptions-replay surfaces past entries that now violate hard rules
    Given the global sickday default has been reduced from "5" to "3" effective "2026-01-01"
    And employee "Peter" has 4 sickdays recorded in 2026 under the older rule
    When I open the Exceptions Replay screen
    Then I see Peter's 4th sickday flagged as "now violating H3 (sickday quota)"
    # Trigger mechanism (scheduled / on-config-change / on-demand button / real-time) is the team's call.

  @bonus @bulk-edit
  Scenario: HR bulk-edit quotas via uploaded CSV with diff preview
    Given I have a CSV with new statutory vacation allocations for 5 users
    When I upload the CSV to the HR quotas screen
    Then I see a per-user diff preview before any change is committed
    When I confirm
    Then the new allocations are applied and audit-logged

  # ---- Bonus — Email channel mirror ----

  @bonus @email-channel
  Scenario: Document approval also delivers a "Document validated" email
    Given the email-channel Bonus is declared in TEAM.md notes
    And Janka's Paragraph absence for "2026-05-12 morning" is "Pending HR document validation"
    And the manager has already Approved the absence
    When I Approve the document
    Then the SMTP capture contains a "Document validated" email addressed to Janka

  @bonus @email-channel
  Scenario: Document rejection also delivers a "Document rejected" email containing the reason
    Given the email-channel Bonus is declared in TEAM.md notes
    And Janka's Paragraph absence is in state "Approved (manager) / Pending document"
    When I Reject the document with reason "Illegible scan"
    Then the SMTP capture contains a "Document rejected" email addressed to Janka containing the reason
