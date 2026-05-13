# Employee-facing scenarios. Actor = an end-user without manager / HR / admin role.
# Tags: @basic = Basic-tier, must pass before any Bonus axis is counted.
#       @bonus = Bonus tier; counted only if Basic >= 90% pass.
# Pre-conditions assume the seeded fixture set under integration/fixtures/.
#
# Notification reading guide (per product-spec.md §10):
#   In @basic scenarios, "receives an X notification" asserts the in-portal
#   notification record visible on the recipient's "My notifications" screen.
#   The literal email is asserted only by @bonus @email-channel scenarios at
#   the bottom of this file; eval-runs without the email-channel Bonus pass
#   @basic by inspecting the notification record, not an SMTP capture.

Feature: Employee — worktime, absences, balances, notifications

  Background:
    Given the seeded fixture users, teams and Slovak public holidays for 2026 are loaded
    And I am logged in via mock login as employee "Anna" on team "Platform"

  # ---- Worktime ----

  @basic @worktime
  Scenario: Log a single worktime block on a working day
    When I open "Today" and submit a worktime entry from "08:00" to "16:00" on project "GENERAL"
    Then the entry is saved with no errors and no warnings
    And my notifications inbox does NOT contain a new entry

  @basic @worktime
  Scenario: Split day with two non-overlapping worktime blocks
    When I submit a worktime entry from "08:00" to "12:00" on project "ADM-1"
    And I submit a worktime entry from "13:00" to "17:00" on project "ADM-2"
    Then both entries are saved
    And the day's total hours are "8.0"
    And neither entry has the Overtime flag

  @basic @worktime @soft
  Scenario: Worktime outside working window triggers soft warning S2
    When I submit a worktime entry from "06:00" to "15:00" on project "GENERAL"
    Then the entry is saved
    And I see soft warning "Outside working window"
    And I see soft warning "Single 8h+ worktime entry; consider splitting."

  @basic @worktime
  Scenario: Overtime auto-flag when entry exceeds 8h
    When I submit a worktime entry from "07:00" to "17:30" on project "GENERAL"
    Then the entry is saved with the Overtime flag set automatically

  @basic @worktime @hard
  Scenario: Worktime is forbidden on a day with an approved absence (H6/H9)
    Given I have an approved Vacation on "2026-07-15"
    When I attempt to submit a worktime entry on "2026-07-15"
    Then the submission is blocked with hard error referencing rule "H9"
    And no worktime entry is saved

  # ---- Vacation ----

  @basic @vacation
  Scenario: Submit vacation request — reservation, no decrement before approval
    Given my vacation balance shows "23 allocated, 4 used, 19 remaining"
    When I submit a Vacation request from "2026-07-13" to "2026-07-17"
    Then the request status is "Pending"
    And my balance shows "19 remaining" with "5 reserved"
    And my direct manager receives an "Approval needed" notification

  @basic @vacation @hard
  Scenario: Vacation blocked when remaining < requested (H5)
    Given my vacation balance shows "1 remaining"
    When I attempt to submit a Vacation request from "2026-08-03" to "2026-08-07"
    Then the submission is blocked with hard error referencing rule "H5"

  @basic @vacation @soft
  Scenario: Approaching-limit soft warning S5
    Given my vacation balance shows "4 remaining"
    When I submit a Vacation request from "2026-08-03" to "2026-08-05"
    Then the request status is "Pending"
    And I see soft warning referencing rule "S5"

  @basic @vacation
  Scenario: Withdraw a Pending vacation request restores balance
    Given I have a Pending Vacation request from "2026-07-13" to "2026-07-17"
    When I withdraw the request
    Then the request status is "Withdrawn"
    And my reserved days are released back to "remaining"

  @basic @vacation
  Scenario: Cancel an Approved future vacation refunds quota
    Given today is "2026-07-10"
    And I have an Approved Vacation from "2026-07-13" to "2026-07-17"
    When I cancel the absence
    Then the request status is "Cancelled"
    And my vacation balance increases by "5"
    And an audit-log entry is recorded for the cancellation

  @basic @vacation
  Scenario: Cancellation on or after the absence date requires HR
    Given today is "2026-07-13"
    And I have an Approved Vacation starting "2026-07-13"
    When I attempt to cancel the absence
    Then the action is blocked with message routing me to HR

  # ---- Sickday ----

  @basic @sickday @hard
  Scenario: Sickday auto-approves when all hard rules pass
    Given today is "2026-05-06" (Wednesday, working day)
    And my sickday balance shows "2 remaining"
    And the day before is NOT a sickday
    When I submit a Sickday for "2026-05-06"
    Then the entry is saved with status "Approved"
    And my direct manager, my team members and the HR group receive a sickday notification

  @basic @sickday @hard
  Scenario: Half-day option is hidden for Sickday (H2)
    When I open the absence form and select type "Sickday"
    Then the half-day morning/afternoon controls are hidden or disabled

  @basic @sickday @hard
  Scenario: Sickday quota exceeded blocks submission (H3)
    Given my sickday balance shows "0 remaining"
    When I attempt to submit a Sickday for "2026-05-06"
    Then the submission is blocked with hard error referencing rule "H3"

  @basic @sickday @hard
  Scenario: Consecutive sickdays are blocked (H4) and message suggests PN
    Given yesterday "2026-05-05" is recorded as my Sickday
    When I attempt to submit a Sickday for "2026-05-06"
    Then the submission is blocked with hard error referencing rule "H4"
    And the error message suggests using "PN" instead

  @basic @sickday @hard
  Scenario: Sickday on weekend or public holiday is blocked
    Given "2026-05-08" is a Slovak public holiday in the seeded calendar
    When I attempt to submit a Sickday for "2026-05-08"
    Then the submission is blocked with a hard error stating it is not a working day

  # ---- Paragraph (doctor visit) ----

  @basic @paragraph
  Scenario: Submit half-day Paragraph with PDF — pending HR validation
    Given my Paragraph balance shows "7 remaining"
    When I submit a half-day Paragraph for the morning of "2026-05-12" with the seeded PDF "doctor.pdf"
    Then the request status is "Pending"
    And the document is attached to the absence
    And the HR group receives a "New document" notification

  @basic @paragraph @soft
  Scenario: 30-minute gap soft warning S1 between half-day Paragraph and same-day worktime
    Given I have a half-day morning Paragraph for "2026-05-12" ending at "12:00"
    When I submit a worktime entry on "2026-05-12" from "12:15" to "17:00"
    Then the entry is saved
    And I see soft warning referencing rule "S1"

  @basic @paragraph
  Scenario: Paragraph stays Pending until both manager AND HR approve (H8)
    Given I have a Pending half-day Paragraph for "2026-05-12" with attached document
    When my manager Approves the absence
    Then the absence status remains "Pending HR document validation"
    And my Paragraph balance has not yet decremented

  # ---- PN (sick leave) ----

  @basic @pn
  Scenario: Log PN spanning multiple days — no quota touched, manager + team + HR notified
    When I log PN from "2026-04-20" to "2026-04-30"
    Then the entry is saved with status "Approved"
    And no quota is decremented
    And my direct manager, my same-team members and the HR group receive a PN notification

  # ---- Notifications inbox ----

  @basic @notifications
  Scenario: My notifications screen lists every notification I received
    Given the system has produced an "Approval decision" notification and a "Document validated" notification for me today
    When I open "My notifications"
    Then I see both entries in chronological order with rendered subject and body

  # ---- Balances ----

  @basic @balances
  Scenario: Balances screen surfaces statutory + bonus split and bonus-lost flag
    Given my 2026 vacation allocations are "20 statutory + 3 bonus"
    When I open "Balances" for 2026
    Then I see "20 statutory" and "3 bonus" listed separately
    And I see a "Bonus withheld" flag with value "no"

  # ---- Bonus-tier scenarios ----

  @bonus @auth
  Scenario: Real auth — login via OIDC / magic-link / password
    Given the team has chosen one real auth mechanism declared in TEAM.md notes
    When I authenticate via that mechanism
    Then I land on my employee dashboard with my real identity bound

  @bonus @i18n
  Scenario: Multi-language UI — Slovak rule message
    Given the UI language is set to Slovak
    When I attempt to submit a Sickday for the day after a recorded Sickday
    Then the hard-error message is rendered in Slovak

  @bonus @mobile
  Scenario: Absence form is fully usable on a mobile viewport (375x667)
    When I open the absence form on a 375x667 viewport
    Then every form field is reachable without horizontal scroll
    And the submit button is tappable above the keyboard

  # ---- Bonus — Email channel mirror (counted only if email-channel Bonus is delivered) ----

  @bonus @email-channel
  Scenario: Vacation submission also delivers an "Approval needed" email when the email Bonus is implemented
    Given the email-channel Bonus is declared in TEAM.md notes
    When I submit a Vacation request from "2026-07-13" to "2026-07-17"
    Then the SMTP capture contains an "Approval needed" email addressed to my direct manager

  @bonus @email-channel
  Scenario: Sickday submission also delivers a sickday email to manager, team, and HR
    Given the email-channel Bonus is declared in TEAM.md notes
    And today is a working day with no consecutive sickday
    When I submit a Sickday for today
    Then the SMTP capture contains a sickday email addressed to my direct manager, my team members and the HR group

  @bonus @email-channel
  Scenario: Document upload also delivers a "New document" email to HR
    Given the email-channel Bonus is declared in TEAM.md notes
    When I submit a half-day Paragraph with an attached PDF
    Then the SMTP capture contains a "New document" email addressed to the HR group

  @bonus @email-channel
  Scenario: PN logging also delivers a PN email to manager, team, and HR
    Given the email-channel Bonus is declared in TEAM.md notes
    When I log PN from "2026-04-20" to "2026-04-30"
    Then the SMTP capture contains a PN email addressed to my direct manager, my same-team members and the HR group
