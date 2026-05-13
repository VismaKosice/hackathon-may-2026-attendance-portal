# Manager-facing scenarios. Actor = a user with the Manager role plus an underlying Employee role.
# Tags: @basic / @bonus.
#
# Notification reading guide (per product-spec.md §10):
#   In @basic scenarios, "receives an X notification" asserts the in-portal
#   notification record on the recipient's "My notifications" screen. The
#   literal email is asserted only by @bonus @email-channel scenarios at the
#   bottom of this file.

Feature: Manager — approvals queue, team calendar, skip-level chain

  Background:
    Given the seeded fixture org tree is loaded:
      | user      | direct_manager |
      | CEO       |                |
      | DeptHeadA | CEO            |
      | DeptHeadB | CEO            |
      | LeadA1    | DeptHeadA      |
      | Anna      | LeadA1         |
      | Peter     | LeadA1         |
    And I am logged in via mock login as manager "LeadA1"

  # ---- Approvals queue ----

  @basic @approvals
  Scenario: Pending request from a direct report appears in routed-to-me filter
    Given employee "Anna" submits a Vacation request from "2026-07-13" to "2026-07-17"
    When I open the approvals queue with filter "Routed to me"
    Then I see Anna's request with type "Vacation", dates "2026-07-13..2026-07-17", her remaining quota and any soft warnings

  @basic @approvals
  Scenario: Approve a vacation request decrements quota immediately and notifies employee
    Given Anna has a Pending Vacation from "2026-07-13" to "2026-07-17"
    When I Approve the request
    Then Anna's vacation balance decrements by "5" immediately
    And Anna receives an "Approved" notification
    And the team calendar reflects the absence on "2026-07-13..2026-07-17"

  @basic @approvals
  Scenario: Reject requires a reason and surfaces it to the employee
    Given Anna has a Pending Vacation from "2026-07-13" to "2026-07-17"
    When I attempt to Reject the request without a reason
    Then the action is blocked with an inline validation error
    When I Reject with reason "Coverage conflict — please re-pick"
    Then the request status is "Rejected"
    And Anna receives a "Rejected" notification containing the reason

  @basic @approvals
  Scenario: Approvals queue updates without page reload when an employee submits
    Given my approvals queue is open and currently shows 0 entries
    When employee "Peter" submits a Vacation request from "2026-08-03" to "2026-08-04"
    Then the queue updates to show 1 entry referencing Peter
    And no full page reload occurred

  # ---- Skip-level approve via chain ----

  @basic @skip-level
  Scenario: Ancestor in org tree can approve a request routed to a subordinate manager
    Given employee "Anna" submits a Vacation request routed to "LeadA1"
    And I am logged in as "DeptHeadA" (Anna's grandparent in the org tree)
    When I open the approvals queue with filter "I can approve via chain"
    Then Anna's request appears in the queue
    When I Approve the request as "DeptHeadA"
    Then the request status is "Approved"
    And the audit log records "DeptHeadA" as the approving actor (skip-level)

  # ---- Self-approval guard ----

  @basic @self-approval
  Scenario: Manager submitting own request escalates one level up
    Given I am logged in as "LeadA1"
    And LeadA1's direct_manager is "DeptHeadA"
    When I submit a Vacation request as "LeadA1" from "2026-09-01" to "2026-09-05"
    Then the routed approver is "DeptHeadA", not "LeadA1"
    And "DeptHeadA" sees the request in their routed-to-me queue

  @basic @self-approval
  Scenario: Top-of-tree self-approval routes to HR group
    Given I am logged in as "CEO"
    And "CEO" has no direct_manager
    When I submit a Vacation request as "CEO"
    Then the routed approver is the HR group
    And every HR-role user sees the request in their routed-to-me queue

  # ---- Team calendar ----

  @basic @team-calendar
  Scenario: Team calendar grid renders the current month with one row per team member
    When I open the team calendar for the current month
    Then I see one row per member of my selected team (per §11.2 — keyed off the `team` field, not the org tree) with one column per day
    And each cell renders one of: absence type colour, worktime hours, "BT" badge, or "Pending" badge

  @basic @team-calendar
  Scenario: Click-through opens day detail in side panel without navigation
    Given the team calendar shows an Approved Vacation cell for "Anna" on "2026-07-15"
    When I click that cell
    Then a side panel opens with the absence detail
    And the URL has not changed to a new page

  @basic @team-calendar
  Scenario: Switching months renders the new month's data
    When I open the team calendar for "2026-05" and then switch to "2026-06"
    Then the grid re-renders with the columns for "2026-06"

  # ---- Manager view of pending overtime ----

  @basic @overtime
  Scenario: Overtime request submitted via long worktime entry routes to direct manager
    Given employee "Peter" submits a worktime entry "2026-05-06" from "07:00" to "21:00"
    Then the entry is saved with the Overtime flag
    And an Overtime approval request is routed to me

  # ---- Bonus ----

  @bonus @approvals @policy
  Scenario: Skip-level POLICY enforcement (stretch)
    Given the team policy requires both direct manager AND skip-level approval for vacation > 5 consecutive days
    And employee "Anna" submits a Vacation from "2026-07-13" to "2026-07-21" (7 working days)
    When I (LeadA1) Approve the request
    Then the request status is "Pending skip-level approval"
    When "DeptHeadA" Approves the request
    Then the request status is "Approved"

  @bonus @realtime
  Scenario: Live websocket updates push new requests instantly
    Given my approvals queue is open with a websocket connection established
    When employee "Peter" submits a request
    Then the queue receives a websocket message and renders the new row within 1s

  # ---- Bonus — Email channel mirror ----

  @bonus @email-channel
  Scenario: Approve decision also delivers an "Approved" email to the requester
    Given the email-channel Bonus is declared in TEAM.md notes
    And Anna has a Pending Vacation from "2026-07-13" to "2026-07-17"
    When I Approve the request
    Then the SMTP capture contains an "Approved" email addressed to Anna

  @bonus @email-channel
  Scenario: Reject decision also delivers a "Rejected" email containing the reason
    Given the email-channel Bonus is declared in TEAM.md notes
    And Anna has a Pending Vacation from "2026-07-13" to "2026-07-17"
    When I Reject with reason "Coverage conflict — please re-pick"
    Then the SMTP capture contains a "Rejected" email addressed to Anna containing the reason
