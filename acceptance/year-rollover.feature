# Year-rollover scenarios. The annual job runs at 00:05 on 1 January.
# Tier: ALL @basic — the §13 #11 acceptance item is core.
# Reference: product-spec.md §6.3 (worked examples Anna / Peter / Mária).
#
# Notification reading guide (per product-spec.md §10):
#   In @basic scenarios, "receives a notification" asserts the in-portal
#   notification record. The literal email is asserted only by the
#   @bonus @email-channel scenario at the bottom of this file.

Feature: Year rollover — statutory protected, bonus discretionary, dry-run preview

  Background:
    Given the seeded fixture users include "Anna", "Peter" and "Mária" with end-of-2026 states:
      | user  | statutory_2026 | bonus_2026 | used_2026 | leftover |
      | Anna  | 20             | 3          | 19        | 4        |
      | Peter | 20             | 3          | 15        | 8        |
      | Mária | 20             | 3          | 23        | 0        |
    And the configured carry-over limit is "5"
    And I am logged in as HR user "HR1"

  # ---- Dry-run preview ----

  @basic @rollover @dry-run
  Scenario: Dry-run preview matches §6.3 worked examples
    When I run the year-rollover dry-run for "2026 -> 2027"
    Then the preview shows the following per-user outcome:
      | user  | carried_over | statutory_2027 | bonus_2027 | bonus_withheld | total_2027 |
      | Anna  | 4            | 20             | 3          | no             | 27         |
      | Peter | 8            | 20             | 0          | yes            | 28         |
      | Mária | 0            | 20             | 3          | no             | 23         |

  @basic @rollover @dry-run
  Scenario: Dry-run does not mutate any balance or quota
    Given Anna's vacation balance for 2026 shows "4 remaining"
    When I run the year-rollover dry-run for "2026 -> 2027"
    Then Anna's 2026 balance is unchanged
    And no 2027 quota records are created

  # ---- Real run ----

  @basic @rollover @apply
  Scenario: Apply rollover after explicit confirmation, with side-by-side before/after preview
    When I open the year-rollover screen and click "Apply rollover 2026 -> 2027"
    Then a confirmation modal renders the side-by-side before/after preview for every user
    When I confirm
    Then 2027 quotas are created exactly matching the preview
    And every employee + HR receive a "Year rollover summary" notification

  @basic @rollover
  Scenario: Statutory days are never lost — even when leftover exceeds the limit
    When I run the year-rollover for "2026 -> 2027"
    Then Peter starts 2027 with statutory + carry-over = "20 + 8 = 28" days
    And Peter's bonus_2027 is "0" with bonus_withheld = "yes"

  @basic @rollover
  Scenario: Bonus retained when leftover is within the carry-over limit
    When I run the year-rollover for "2026 -> 2027"
    Then Anna's bonus_2027 is "3" with bonus_withheld = "no"

  @basic @rollover
  Scenario: Sickday / paragraph / OCR allocations reset fresh — no carry-over
    Given Anna ended 2026 with sickday_remaining = "1", paragraph_remaining = "2", ocr_remaining = "5"
    When I run the year-rollover for "2026 -> 2027"
    Then Anna's 2027 sickday_allocated = "3", paragraph_allocated = "7", ocr_allocated = "7"

  @basic @rollover @notification
  Scenario: Rollover summary notification tells employees what happened and why
    When I run the year-rollover for "2026 -> 2027"
    Then Peter receives a notification containing:
      | text snippet                                   |
      | "Carried over: 8 days"                         |
      | "Company bonus this year: 0 days"              |
      | "withheld: yes"                                |

  @basic @rollover @balances
  Scenario: Balances screen shows the bonus-withheld flag with explanatory tooltip
    When the rollover has been applied for "2026 -> 2027"
    And I open Peter's balances for 2027
    Then I see a "Bonus withheld" flag with value "yes"
    And the tooltip explains the >5-day leftover policy

  # ---- Bonus — Email channel mirror ----

  @bonus @email-channel
  Scenario: Year-rollover summary also delivers an email to every employee + HR
    Given the email-channel Bonus is declared in TEAM.md notes
    When the rollover is applied for "2026 -> 2027"
    Then the SMTP capture contains a "Year rollover summary" email addressed to every employee
    And the SMTP capture contains a "Year rollover summary" email addressed to every HR-role user
