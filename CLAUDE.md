# MarketFlow Platform

AI-Native платформа управления продажами на российских маркетплейсах (WB, Ozon, YM, MM).

---

## Overview

**MarketFlow** = AI-агент как «виртуальный менеджер маркетплейса». Гибридная платформа:
- **SaaS Analytics** — единый дашборд WB+Ozon+YM+MM в реальном времени
- **AI Automation** — ставки, контент, отзывы на автопилоте
- **Managed Services** — full-service для enterprise-брендов

**Target:** 1.26 млн продавцов WB+Ozon теряют деньги из-за комиссий 30%+ и неэффективной операционки.

**Docs:** `docs/PRD.md` | `docs/Solution_Strategy.md` | `docs/Architecture.md` | `docs/Final_Summary.md`

---

## Problem & Solution

**Problem:** Продавцы тратят 8+ часов/день на ручную работу. Инструменты есть, но нет AI-native единого окна с исполнением.

**Solution (TRIZ #10 Prior Action):** AI-агент готовит решения ДО того, как менеджер открывает дашборд. Nash Equilibrium: первый AI-native игрок занимает доминирующую позицию пока incumbents (MPSTATS, SellerFox) игнорируют 12-18 месяцев.

**Differentiator:** Unified Dashboard + AI Recommendations + Bid Automation + Managed Services в одном продукте.

---

## Architecture

**Pattern:** Distributed Monolith (Monorepo) на VPS (AdminVPS/HOSTKEY)
**Deploy:** Docker Compose direct deploy

```
frontend/          # Next.js 15 (App Router)
backend/           # FastAPI (Python 3.12)
workers/           # Celery tasks
shared/            # Types, schemas, utils
docs/              # SPARC documentation
```

**Services (Docker Compose):**
- `nginx` — reverse proxy (80/443)
- `frontend` — Next.js (port 3000)
- `backend` — FastAPI (port 8000)
- `timescaledb` — PostgreSQL + TimescaleDB extension
- `redis` — cache + queue broker
- `celery` — background workers
- `minio` — object storage (reports, audit exports)

**Ref:** `docs/Architecture.md`

---

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | Next.js (App Router) | 15.x |
| Backend | FastAPI + Python | 3.12 + 0.115.x |
| Analytics DB | TimescaleDB (PostgreSQL) | PG 16 + 2.x |
| Cache | Redis | 7.x |
| Queue | Celery | 5.3.x |
| ML | CatBoost | 1.2.x |
| AI | Anthropic Claude API | claude-haiku-4-5 / claude-sonnet-4-6 |
| Storage | MinIO | latest |
| Proxy | Nginx | latest |
| Migrations | Alembic | 1.13.x |

---

## Key Algorithms

From `docs/Pseudocode.md`:

```python
# 1. Recommendation Generator O(n*m)
generate_recommendations(store_id, limit=5) -> List[Recommendation]
  # FETCH metrics → CALCULATE scores → SORT by impact → AI enhancement → SAVE

# 2. Bid Optimizer
optimize_bids(store_id) -> List[BidAdjustment]
  # FETCH rules → CALCULATE current_drr → IF drr > target: reduce_bid()
  # LOG adjustment + NOTIFY via Telegram if change > 20%

# 3. X-Ray Audit Generator O(n)
generate_xray_audit(seller_id, platform) -> AuditReport
  # FETCH listings → SCORE each listing → AGGREGATE → AI ANALYSIS → SAVE

# 4. Review Response Generator
generate_review_response(review_id, store_id) -> DraftResponse
  # CLASSIFY sentiment → SELECT template → CALL claude-haiku-4-5 → VALIDATE
```

---

## Security Rules

- JWT tokens in httpOnly cookies (24h TTL), refresh via `/auth/refresh`
- All marketplace API keys encrypted at rest: AES-256-GCM via Python `cryptography`
- Keys stored in DB only as ciphertext — NEVER in logs, env vars, or frontend
- SSRF protection: whitelist external URLs to marketplace domains only
- Rate limits: 3 X-Ray/IP/hour (unauth), 100 req/user/min (auth)
- 152-ФЗ compliance: data stored in RU jurisdiction (AdminVPS/HOSTKEY)
- See `.claude/rules/security.md` and `.claude/rules/secrets-management.md`

---

## Parallel Execution Strategy

Maximize parallel tool calls for independent operations:

```
✅ PARALLEL — run together:
   - Read multiple docs simultaneously
   - Run tests + linting + type-checking simultaneously
   - Generate multiple files if content is independent

❌ SEQUENTIAL — wait for previous:
   - DB migration → seed data → start app
   - Generate CLAUDE.md → then reference it in agents
   - Read file → edit file (must read first)
```

Use `Task` tool for independent subtasks. For complex features spawn specialized agents:
- `@planner` — implementation planning from Pseudocode.md
- `@code-reviewer` — quality review with edge cases from Refinement.md
- `@architect` — system design decisions from Architecture.md

---

## Swarm Agents

Multi-agent parallel execution for validation and review:

```
Validation swarm (5 agents):
  agent-1: validator-stories (INVEST criteria)
  agent-2: validator-acceptance (SMART criteria)
  agent-3: validator-architecture (constraint compliance)
  agent-4: validator-pseudocode (story coverage)
  agent-5: validator-coherence (cross-document consistency)

Review swarm (5 agents):
  agent-1: code-quality
  agent-2: architecture-compliance
  agent-3: security-review
  agent-4: performance-review
  agent-5: testing-coverage
```

---

## Git Workflow

```
feat(scope): description      # New feature
fix(scope): description       # Bug fix
refactor(scope): description  # Restructure, no behavior change
test(scope): description      # Tests
docs(scope): description      # Documentation
chore(scope): description     # Build, CI, config
```

Scopes: `frontend`, `backend`, `workers`, `shared`, `db`, `ci`, `docs`

**Rules:** Commit after each logical unit. Never mix unrelated changes. Imperative mood.

---

## Available Agents

| Agent | Trigger | Purpose |
|-------|---------|---------|
| `@planner` | "план", "реализовать", "как сделать" | Feature planning from Pseudocode.md |
| `@code-reviewer` | "проверь", "review", "найди ошибки" | Code review with edge cases |
| `@architect` | "архитектура", "design", "решение" | System design decisions |

---

## Available Skills

| Skill | Path | Purpose |
|-------|------|---------|
| sparc-prd-mini | `.claude/skills/sparc-prd-mini/` | Feature SPARC documentation |
| requirements-validator | `.claude/skills/requirements-validator/` | Validate user stories (INVEST+SMART) |
| brutal-honesty-review | `.claude/skills/brutal-honesty-review/` | Unvarnished code review |
| explore | `.claude/skills/explore/` | Socratic task clarification |
| goap-research | `.claude/skills/goap-research-ed25519/` | Verified research (PARANOID mode) |
| problem-solver-enhanced | `.claude/skills/problem-solver-enhanced/` | TRIZ + Game Theory problem solving |
| project-context | `.claude/skills/project-context/` | MarketFlow domain knowledge |
| coding-standards | `.claude/skills/coding-standards/` | FastAPI + Next.js standards |
| testing-patterns | `.claude/skills/testing-patterns/` | Test generation patterns |
| security-patterns | `.claude/skills/security-patterns/` | API key encryption patterns |
| feature-navigator | `.claude/skills/feature-navigator/` | Roadmap navigation |

---

## Quick Commands

| Command | Description |
|---------|-------------|
| `/start` | Bootstrap project from SPARC docs |
| `/feature [name]` | Full feature lifecycle (Plan→Validate→Implement→Review) |
| `/plan [feature]` | Quick implementation planning |
| `/test [scope]` | Run or generate tests |
| `/deploy [env]` | Deploy to environment |
| `/next` | Show sprint progress and next tasks |
| `/go [feature]` | Autonomous feature execution |
| `/run [mvp\|all]` | Autonomous full project build |
| `/docs [scope]` | Generate bilingual documentation |
| `/myinsights` | Capture development insights |

---

## Development Insights

Knowledge base: `myinsights/1nsights.md` (index) + `myinsights/INS-NNN-*.md` (details)

**Error-First Protocol:** Before debugging, grep the insights index:
```bash
grep -i "keyword" myinsights/1nsights.md
```

**Capture trigger:** After solving a non-trivial bug, discovering a gotcha, or finding a better pattern — run `/myinsights`.

---

## Feature Development Lifecycle

```
/feature [name]
  Phase 0: PRE-FLIGHT — verify skills exist
  Phase 1: PLAN — sparc-prd-mini → docs/features/<name>/sparc/
  Phase 2: VALIDATE — 5-agent swarm, min score 70/100
  Phase 3: IMPLEMENT — from validated SPARC docs (no hallucination)
  Phase 4: REVIEW — brutal-honesty-review swarm
```

Feature docs: `docs/features/` | Feature rule: `.claude/rules/feature-lifecycle.md`

---

## Feature Roadmap

**File:** `.claude/feature-roadmap.json`

```
/next          # Show sprint progress + top 3 next tasks
/next update   # Scan codebase, suggest status updates
/next [id]     # Mark feature done, cascade unblocking
```

---

## Implementation Plans

Auto-saved to `docs/plans/` on session end.

```
/plan [feature]   # Create implementation plan
/plan list        # List all plans
/plan show [id]   # Show specific plan
```

---

## Automation Commands

```
/go [feature]     # Smart pipeline: scoring → /plan | /feature
/run mvp          # Bootstrap → implement next+in_progress features
/run all          # Implement ALL features until done
/docs             # Generate bilingual RU+EN documentation
```

Command hierarchy: `/run` → `/start` → `/next` → `/go` → `/plan` | `/feature`

---

## Resources

- SPARC docs: `docs/`
- Validation report: `docs/validation-report.md`
- BDD scenarios: `docs/test-scenarios.md`
- CJM analysis: `docs/CJM-EasyCommerce.html`
- Market research: `docs/Research_Findings.md`
- Development guide: `DEVELOPMENT_GUIDE.md`
- MCP config: `.mcp.json`
