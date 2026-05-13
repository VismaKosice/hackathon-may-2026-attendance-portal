# Hackathon Brief — Attendance Portal (Košice, 2026-05-13)

Welcome. This folder is the **single source of truth** for what you are building. Read it. There is nothing useful elsewhere.

## TL;DR

- **Build:** a self-contained web app that owns the company's attendance lifecycle (worktime, absences, approvals, quotas, reports). See [`product-spec.md`](product-spec.md).
- **Time:** in-person, single day.
- **Team size:** 2–7. Senior engineers with AI tooling expected.
- **Stack:** your choice. No starter code. Fixtures are stack-agnostic data only.
- **AI tooling:** bring your own. A Premium Claude seat (Pro or Max) is **recommended**; any equivalent capable LLM assistant works. No organiser budget.
- **Demo:** every team demos working software at the end of the day. External scoring system runs after demos against each team's `main` branch.

## Two-bundle structure

This brief is split by audience at the file level so a BA-only cut is cheap to extract:

- **Core bundle (this folder, excluding `dev-extras/`)** — requirements + judging contract + BA materials. Anyone — BA, manager, judge, organiser — can read this end-to-end and understand *what* is being built and *how it is judged*.
- **Dev-extras bundle (`dev-extras/`)** — implementation scaffolding for build teams: entity sketch, integration baselines (auth, email, fixtures), NFRs, frontend UX baseline, dev/QA role quickstarts. Layered on top of the core bundle.

Branch model: `main` carries both bundles during prep. A `requirements-only` cut can be produced at any time by `git rm -rf hackathon-brief/dev-extras/` on a fork or branch. Cross-references from core into `dev-extras/` are tolerant — they degrade to "not in this bundle" rather than break.

## Tier model — Basic vs Bonus

Two tiers. **Basic must complete first.** Bonus features are **off-limits** until every Basic acceptance scenario passes.

- **Basic** — the §13 must-have set in `product-spec.md`. The Gherkin scenarios in [`acceptance/`](acceptance/) are the rubric — they double as your TDD spec and the judge's checklist.
- **Bonus** — §14 features. Real auth, exceptions replay, Slack/ICS, analytics, etc. Counted only when Basic ≥ 90%.

If the scoring system sees you started a Bonus axis with Basic incomplete, you forfeit Bonus points. Don't.

## Navigation

### Core bundle (everyone reads)

| Where | Audience | What |
|---|---|---|
| [`product-spec.md`](product-spec.md) | all | Behaviour spec. Read first. |
| [`acceptance/`](acceptance/) | all | Gherkin features = judging rubric. **Treat as TDD spec.** |
| [`demo-format.md`](demo-format.md) *(TBD)* | all | Run order, time per team, required artifacts. |
| `TEAM.md` *(every team's repo root — schema below)* | all | Team manifest read by the external scoring system. **Without it, your team is skipped entirely.** |
| [`ba/story-template.md`](ba/story-template.md) | BA | Per-story shape. |
| [`ba/slicing-guidance.md`](ba/slicing-guidance.md) | BA | Analyst playbook — slicing, dependency, Bonus ROI, team-shape recommendations. |
| [`ba/scoring-rubric.md`](ba/scoring-rubric.md) | BA, judges | How the BA bundle is scored (100 Basic + 30 Bonus = up to 130 pts, **individual lane** — does not contribute to team scores). |
| [`role-quickstarts/business-analyst.md`](role-quickstarts/business-analyst.md) | BA | 5-min entry. BAs are a parallel lane, not on a team. |
| [`role-quickstarts/solo-or-multi.md`](role-quickstarts/solo-or-multi.md) | all | Vertical slice plan for 1–3 person teams. |

### Dev-extras bundle (`dev-extras/` — build teams read)

| Where | Audience | What |
|---|---|---|
| [`dev-extras/domain/entities.md`](dev-extras/domain/entities.md) *(TBD)* | dev | Entity sketch derived from the spec. Reference, not prescription. |
| [`dev-extras/integration/auth-options.md`](dev-extras/integration/auth-options.md) *(TBD)* | dev | Mock login (Basic) vs real auth options (Bonus). |
| [`dev-extras/integration/email-stub.md`](dev-extras/integration/email-stub.md) *(TBD)* | dev | Recommended local SMTP capture (MailHog / Mailpit). |
| [`dev-extras/integration/fixtures/`](dev-extras/integration/fixtures/) *(TBD)* | dev + QA | Users, teams, holidays, quotas, in-flight absences, sample docs. |
| [`dev-extras/nfr/performance.yaml`](dev-extras/nfr/performance.yaml) *(TBD)* | dev | Latency + calendar grid render targets. |
| [`dev-extras/nfr/time-budget.yaml`](dev-extras/nfr/time-budget.yaml) *(TBD)* | dev | Build-window cap + per-phase guidance. |
| [`dev-extras/frontend/fe-technical-refinement.md`](dev-extras/frontend/fe-technical-refinement.md) | frontend dev | FE technical refinement — 38 sections framework-agnostic (responsive, PWA, a11y WCAG 2.2 AA, theming, i18n, real-time, auth, file upload, perf budgets, design system, state, forms, security, testing, build, code architecture, DI, TZ handling, API contract, etc.) with Basic / Bonus tier mapping. |
| [`dev-extras/role-quickstarts/`](dev-extras/role-quickstarts/) | dev / QA | Per-role 5-min entry: [backend-dev](dev-extras/role-quickstarts/backend-dev.md), [backend-qa](dev-extras/role-quickstarts/backend-qa.md), [frontend-dev](dev-extras/role-quickstarts/frontend-dev.md), [frontend-qa](dev-extras/role-quickstarts/frontend-qa.md). |

## Role start map

Don't read everything. Pick your role, follow the quickstart.

| You are | Bundle | Start here | Then |
|---|---|---|---|
| **Backend dev** | core + dev-extras | [`dev-extras/role-quickstarts/backend-dev.md`](dev-extras/role-quickstarts/backend-dev.md) | `dev-extras/domain/entities.md` → `acceptance/*.feature` → spec §6, §7, §9 |
| **Backend QA / SDET** | core + dev-extras | [`dev-extras/role-quickstarts/backend-qa.md`](dev-extras/role-quickstarts/backend-qa.md) | `acceptance/*.feature` → `dev-extras/integration/fixtures/` |
| **Frontend dev** | core + dev-extras | [`dev-extras/role-quickstarts/frontend-dev.md`](dev-extras/role-quickstarts/frontend-dev.md) | `dev-extras/frontend/fe-technical-refinement.md` → spec §17 |
| **Frontend QA** | core + dev-extras | [`dev-extras/role-quickstarts/frontend-qa.md`](dev-extras/role-quickstarts/frontend-qa.md) | `acceptance/employee.feature` + `manager.feature` |
| **Business Analyst** *(parallel lane — not on a team)* | core only | [`role-quickstarts/business-analyst.md`](role-quickstarts/business-analyst.md) | [`ba/slicing-guidance.md`](ba/slicing-guidance.md) + [`ba/story-template.md`](ba/story-template.md) + [`ba/scoring-rubric.md`](ba/scoring-rubric.md) |
| **Solo or 2-person team** | core + dev-extras | [`role-quickstarts/solo-or-multi.md`](role-quickstarts/solo-or-multi.md) | vertical slice plan |

## Judging principle — spec is the contract

**Teams are judged on what the spec defines, not on what it leaves undefined.** Anything `product-spec.md` does not specify is the team's discretion — choose freely and judges will not penalise the choice either way. This applies to UI details not covered by §17, API shapes not pinned by the OpenAPI at [`dev-extras/integration/api-reference.yaml`](dev-extras/integration/api-reference.yaml), choice of stack, choice of libraries, and any ambiguity inside the acceptance Gherkin. Do not waste time hedging against undefined behaviour; do not waste time arguing it.

## Ground rules

1. **Pick one stack.** Don't argue stack choice past minute 30. Ship beats perfect.
2. **Acceptance Gherkin is the contract.** If a scenario passes, the feature is done. If not, it isn't.
3. **Fixtures are canonical.** Use the data in `dev-extras/integration/fixtures/`. Don't invent your own users, holidays, or year-rollover scenarios — judges replay against the same fixtures.
4. **Mock auth is fine for Basic.** Don't burn 60 minutes on OIDC before the rule engine works.
5. **Capable AI assistant per person (recommended).** A Premium Claude seat (Pro or Max) or equivalent makes the build window viable. With Claude specifically: Pro caps reset every 5h — reserve Opus for hard problems, Sonnet covers most workload.
6. **In-product AI features need your own API key.** Dev-time AI assistants cover authoring; they do **not** authenticate runtime API calls from the portal.
7. **Commit often, push often.** The scoring system pulls your `main` branch on every cycle.
8. **`TEAM.md` at the repo root.** Required — declares team name, members (with the email used in your git commits), and stack. Without it your team is skipped by the scoring system. See *TEAM.md — team manifest* below for the schema.

## Judging rubric

Total **160 points**.

| Axis | Max | Notes |
|---|---|---|
| Basic Gherkin pass | 100 | % scenarios in `acceptance/*.feature` Basic tier passing |
| Bonus features delivered | 30 | **Gated** — counted only if Basic ≥ 90 (≥ 90 pts above) |
| Security | 10 | `gitleaks`, `trivy fs`, `semgrep` + AI security pass on declared high-risk paths |
| Code quality | 10 | Structure / DRY (`jscpd`) / complexity. AI fallback where stack tooling fragments. |
| Polish | 10 | Judge-subjective — UX, demo flow, agent workflow shown |

**BA lane — individual scoring, 100 Basic + 30 Bonus (gated) = up to 130 pts.** BAs are ranked **per-individual** on a dedicated BA tab; **BA scores never contribute to any team's total score**. BAs do not staff build teams. They produce an end-of-day analysis bundle judged independently under [`ba/scoring-rubric.md`](ba/scoring-rubric.md). Bonus tier mirrors the team rubric — counted only when BA Basic ≥ 90 pts. Build teams do not depend on BAs — they build from `product-spec.md`, `acceptance/`, and the OpenAPI spec under [`dev-extras/integration/api-reference.yaml`](dev-extras/integration/api-reference.yaml) from hour 0.

Tiebreaker: head-to-head judge vote.

## Scoring — what runs after demos

An external scoring system pulls each team's `main` branch and scores per lane. Teams do not run anything locally for scoring — just commit, push, and ensure `TEAM.md` is present at the repo root.

Lanes are selected per member role declared in `TEAM.md`. A team with no `FE` member is skipped in the FE lane; same for `BE` and `Testing`. The functional lane always runs.

## TEAM.md — team manifest

Every team commits a `TEAM.md` file to the **root** of their repo on `main` before the build window ends. The scoring system reads it on every cycle; without it, your team is skipped entirely.

### Required schema

YAML front-matter + free-form notes body:

```markdown
---
team: <YourTeamName>            # display name, unique across the event
members:
  - name: <First Last>
    email: <first.last@visma.com>   # MUST match the email used in your git commits
    github: <github-handle>
    role: FE                          # allowed: FE, BE, Testing, FE+BE, FE+Testing, BE+Testing, FE+BE+Testing, BA
  # at least one member required; add as many as the team has
stack:
  frontend: <react | vue | svelte | angular | other>
  backend:  <nodejs | python | java | go | dotnet | other>
  database: <postgres | sqlite | mysql | mongo | none>   # optional
---

# <YourTeamName>

<!-- Free-form notes for the scoring agents: build/run instructions, intentional scope cuts, third-party services, links. Keep it short. -->
```

### How the scorer uses this file

- Read from `main` at the **root** of your repo on every cycle.
- Commits attributed to a member when the commit author's email matches `members[].email` **exactly**. Use your real Visma email in git (`git config user.email`).
- A team with no `FE` in any member's `role` is skipped in the FE lane; same logic for `BE` and `Testing`. Functional always runs.
- `BA` (Business Analyst) members do not contribute to any team-lane rubric — see *Scoring — BA lane* below.

### What to do at the start of the day

1. Create your team repo.
2. Copy `TEAM.md` to the repo root and fill in `team`, `members`, `stack`. Remove every `<...>` placeholder.
3. Configure `git config user.email` per member to match `members[].email`.
4. Commit + push to `main`.

## Out of scope

See `product-spec.md` §15. Don't build native apps, multi-tenant SaaS, real Visma corporate SSO, or production Tempo migration. Generic OIDC against Google / Microsoft personal accounts is fair game (Bonus).

## Source document

This brief derives from the internal Drive doc *Attendance Portal — Functional Refinement*, 2026-05-06. The spec in this repository supersedes that doc for hackathon purposes.
