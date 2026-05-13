# Hackathon Brief — Attendance Portal (Košice, 2026-05-13)

Welcome. This folder is the **single source of truth** for what you are building. Read it. There is nothing useful elsewhere.

## TL;DR

- **Build:** a self-contained web app that owns the company's attendance lifecycle (worktime, absences, approvals, quotas, reports). See [`product-spec.md`](product-spec.md).
- **Time:** in-person, single day.
- **Team size:** 2–7. Senior engineers with AI tooling expected.
- **Stack:** your choice. No starter code. Fixtures are stack-agnostic data only.
- **LLM access:** bring your own Premium Claude seat (Pro or Max). No organiser budget.
- **Demo:** every team demos working software at the end of the day. Eval-runner runs after demos.

## Two-bundle structure

This brief is split by audience at the file level so a BA-only cut is cheap to extract:

- **Core bundle (this folder, excluding `dev-extras/`)** — requirements + judging contract + BA materials. Anyone — BA, manager, judge, organiser — can read this end-to-end and understand *what* is being built and *how it is judged*.
- **Dev-extras bundle (`dev-extras/`)** — implementation scaffolding for build teams: OpenAPI reference, stateful mock server, backend / frontend / testing technical refinements. Layered on top of the core bundle.

Branch model: `main` carries both bundles during prep. A `requirements-only` cut can be produced at any time by `git rm -rf hackathon-brief/dev-extras/` on a fork or branch. Cross-references from core into `dev-extras/` are tolerant — they degrade to "not in this bundle" rather than break.

## Tier model — Basic vs Bonus

Two tiers. **Basic must complete first.** Bonus features are **off-limits** until every Basic acceptance scenario passes.

- **Basic** — the §13 must-have set in `product-spec.md`. The Gherkin scenarios in [`acceptance/`](acceptance/) are the rubric — they double as your TDD spec and the judge's checklist.
- **Bonus** — §14 features. Real auth, exceptions replay, Slack/ICS, analytics, etc. Counted only when Basic ≥ 90%.

If the eval-runner sees you started a Bonus axis with Basic incomplete, you forfeit Bonus points. Don't.

## Navigation

### Core bundle (everyone reads)

| Where | Audience | What |
|---|---|---|
| [`product-spec.md`](product-spec.md) | all | Behaviour spec. Read first. |
| [`acceptance/`](acceptance/) | all | Gherkin features = judging rubric. **Treat as TDD spec.** |
| [`ba/story-template.md`](ba/story-template.md) | BA | Per-story shape. |
| [`ba/slicing-guidance.md`](ba/slicing-guidance.md) | BA | Analyst playbook — slicing, dependency, Bonus ROI, team-shape recommendations. |
| [`ba/scoring-rubric.md`](ba/scoring-rubric.md) | BA, judges | How the BA bundle is scored (100 pts, parallel lane). |
| [`role-quickstarts/business-analyst.md`](role-quickstarts/business-analyst.md) | BA | 5-min entry. BAs are a parallel lane, not on a team. |

### Dev-extras bundle (`dev-extras/` — build teams read)

| Where | Audience | What |
|---|---|---|
| [`dev-extras/integration/api-reference.yaml`](dev-extras/integration/api-reference.yaml) | dev | OpenAPI 3.1 reference contract — Basic-tier routes, shared `Problem` envelope, cursor pagination, ETag/If-Match. |
| [`dev-extras/integration/mock-server/`](dev-extras/integration/mock-server/) | dev + QA | Stateful in-memory mock server (Fastify + TypeScript). Seeded users/teams/holidays/absences. Use for FE-only assignments or as a contract sanity check. Holiday + user fixtures live in [`src/store/seed.ts`](dev-extras/integration/mock-server/src/store/seed.ts). |
| [`dev-extras/backend/be-technical-refinement.md`](dev-extras/backend/be-technical-refinement.md) | backend dev | BE technical refinement — 36 sections, Basic / Bonus tier mapping. |
| [`dev-extras/frontend/fe-technical-refinement.md`](dev-extras/frontend/fe-technical-refinement.md) | frontend dev | FE technical refinement — 38 sections framework-agnostic with Basic / Bonus tier mapping. |
| [`dev-extras/testing/testing-be-technical-refinement.md`](dev-extras/testing/testing-be-technical-refinement.md) | backend QA | BE testing refinement — pyramid, H/S matrices, state-machine, fixtures, CI. |
| [`dev-extras/testing/testing-fe-technical-refinement.md`](dev-extras/testing/testing-fe-technical-refinement.md) | frontend QA | FE testing refinement — runner+browser matrix, critical flows, a11y gate, perf smoke. |

## Role start map

Don't read everything. Pick your role, follow the quickstart.

| You are | Bundle | Start here | Then |
|---|---|---|---|
| **Backend dev** | core + dev-extras | [`dev-extras/backend/be-technical-refinement.md`](dev-extras/backend/be-technical-refinement.md) | `acceptance/*.feature` → spec §6, §7, §9 → [`dev-extras/integration/api-reference.yaml`](dev-extras/integration/api-reference.yaml) |
| **Backend QA / SDET** | core + dev-extras | [`dev-extras/testing/testing-be-technical-refinement.md`](dev-extras/testing/testing-be-technical-refinement.md) | `acceptance/*.feature` → [`dev-extras/integration/mock-server/`](dev-extras/integration/mock-server/) |
| **Frontend dev** | core + dev-extras | [`dev-extras/frontend/fe-technical-refinement.md`](dev-extras/frontend/fe-technical-refinement.md) | spec §17 → [`dev-extras/integration/api-reference.yaml`](dev-extras/integration/api-reference.yaml) → [`dev-extras/integration/mock-server/`](dev-extras/integration/mock-server/) |
| **Frontend QA** | core + dev-extras | [`dev-extras/testing/testing-fe-technical-refinement.md`](dev-extras/testing/testing-fe-technical-refinement.md) | `acceptance/employee.feature` + `manager.feature` |
| **Business Analyst** *(parallel lane — not on a team)* | core only | [`role-quickstarts/business-analyst.md`](role-quickstarts/business-analyst.md) | [`ba/slicing-guidance.md`](ba/slicing-guidance.md) + [`ba/story-template.md`](ba/story-template.md) + [`ba/scoring-rubric.md`](ba/scoring-rubric.md) |

## Judging principle — spec is the contract

**Teams are judged on what the spec defines, not on what it leaves undefined.** Anything `product-spec.md` does not specify is the team's discretion — choose freely and judges will not penalise the choice either way. This applies to UI details not covered by §17, API shapes not pinned by the OpenAPI at [`dev-extras/integration/api-reference.yaml`](dev-extras/integration/api-reference.yaml), choice of stack, choice of libraries, and any ambiguity inside the acceptance Gherkin. Do not waste time hedging against undefined behaviour; do not waste time arguing it.

## Ground rules

1. **Pick one stack.** Don't argue stack choice past minute 30. Ship beats perfect.
2. **Acceptance Gherkin is the contract.** If a scenario passes, the feature is done. If not, it isn't.
3. **Fixtures are canonical.** Use the seeded data in [`dev-extras/integration/mock-server/src/store/seed.ts`](dev-extras/integration/mock-server/src/store/seed.ts) (users, teams, Slovak 2026 holidays, sample absences). Don't invent your own — judges replay against the same fixtures.
4. **Mock auth is fine for Basic.** Don't burn 60 minutes on OIDC before the rule engine works.
5. **Premium Claude seat per person.** Pro caps reset every 5h. Reserve Opus for hard problems; Sonnet 4.6 covers most workload.
6. **In-product AI features need your own API key.** Pro/Max seats cover Claude Code dev-time. They do **not** authenticate runtime API calls from the portal.
7. **Commit often, push often.** Eval-runner pulls your repo at demo time.
8. **At demo time, ship `eval-meta.yaml`.** Declares stack ids, `make eval` entrypoint, high-risk paths. Without it your submission can't be eval'd → you forfeit deterministic + AI eval points.

## Judging rubric

Total **160 points**.

| Axis | Max | Notes |
|---|---|---|
| Basic Gherkin pass | 100 | % scenarios in `acceptance/*.feature` Basic tier passing |
| Bonus features delivered | 30 | **Gated** — counted only if Basic ≥ 90 (≥ 90 pts above) |
| Security | 10 | `gitleaks`, `trivy fs`, `semgrep` + AI security pass on declared high-risk paths |
| Code quality | 10 | Structure / DRY (`jscpd`) / complexity. AI fallback where stack tooling fragments. |
| Polish | 10 | Judge-subjective — UX, demo flow, agent workflow shown |

**BA lane — separate parallel scoring, 100 Basic + 30 Bonus (gated) = up to 130 pts.** BAs do not staff build teams. They produce an end-of-day analysis bundle judged independently under [`ba/scoring-rubric.md`](ba/scoring-rubric.md). Bonus tier mirrors the team rubric — counted only when BA Basic ≥ 90 pts. Build teams do not depend on BAs — they build from `product-spec.md`, `acceptance/`, and `dev-extras/integration/api-reference.yaml` from hour 0.

Tiebreaker: head-to-head judge vote.

## Eval-runner — what runs after demos

Per team, ~10 minutes:

- **Stack-agnostic deterministic:** `gitleaks`, `trivy fs`, `jscpd`, `semgrep --config=auto` + hackathon ruleset.
- **Your own tests + lint** via `make eval` (the entrypoint you declare in `eval-meta.yaml`).
- **AI passes:** architecture review, deep DRY, security review of declared high-risk paths, test-quality verdict, spec-conformance against Bonus Gherkin.

Reproducibility: fixed model + temperature 0, prompts versioned in this repo, per-team logs preserved. Disputes are resolvable by re-run.

## Out of scope

See `product-spec.md` §15. Don't build native apps, multi-tenant SaaS, real Visma corporate SSO, or production Tempo migration. Generic OIDC against Google / Microsoft personal accounts is fair game (Bonus).

## Source document

This brief derives from the internal Drive doc *Attendance Portal — Functional Refinement*, 2026-05-06. The spec in this repository supersedes that doc for hackathon purposes.
