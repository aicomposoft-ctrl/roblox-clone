# MarketFlow Development Guide

> AI-Native платформа управления продажами на российских маркетплейсах (WB, Ozon, YM, MM)
> Аналог Easy Commerce (easycomm.ru) с AI-автоматизацией

---

## Quick Start

### Prerequisites

```bash
# Required
docker --version          # >= 24.0
docker compose version    # >= 2.20
python --version          # 3.12+
node --version            # >= 20.x
```

### First Run

```bash
# 1. Clone and setup
git clone <repo> marketflow && cd marketflow

# 2. Configure environment
cp .env.example .env
# Edit .env: set ENCRYPTION_KEY, JWT_SECRET_KEY, ANTHROPIC_API_KEY

# 3. Generate secrets
python -c "import os,base64; print('ENCRYPTION_KEY=' + base64.b64encode(os.urandom(32)).decode())"
openssl rand -hex 64 | awk '{print "JWT_SECRET_KEY=" $0}'

# 4. Start all services
docker compose up -d

# 5. Run DB migrations
docker compose exec backend alembic upgrade head

# 6. Verify health
curl http://localhost:8000/api/health
curl http://localhost:3000
```

### Service URLs (local)

| Service | URL | Purpose |
|---------|-----|---------|
| Frontend | http://localhost:3000 | Next.js app |
| Backend API | http://localhost:8000 | FastAPI |
| API Docs | http://localhost:8000/docs | Swagger UI |
| MinIO | http://localhost:9001 | Object storage console |
| Flower | http://localhost:5555 | Celery monitoring |

---

## Development Workflow

### 1. Feature Development

```bash
# Start feature via /plan command
/plan [feature-name]   # Reads SPARC docs → creates structured plan

# Or full lifecycle:
/feature [feature-name]  # Plan → Validate → Implement → Review
```

### 2. Backend Development

```bash
cd backend

# Install deps
pip install -r requirements-dev.txt

# Run locally (without Docker)
uvicorn app.main:app --reload --port 8000

# Create DB migration
alembic revision --autogenerate -m "add_[table]_table"
alembic upgrade head

# Run tests
pytest tests/unit/ -v -x                          # Fast feedback
pytest tests/ --cov=app --cov-fail-under=80       # Full + coverage
pytest tests/integration/ -v                      # Requires Docker services
```

### 3. Frontend Development

```bash
cd frontend

# Install deps
npm install

# Dev server
npm run dev              # http://localhost:3000

# Type check
npm run type-check

# Build
npm run build

# E2E tests (requires backend running)
npm run test:e2e
```

### 4. Workers Development

```bash
# Start Celery worker
celery -A workers.celery_app worker --loglevel=info

# Start Celery Beat (scheduler) — ONE instance only!
celery -A workers.celery_app beat --loglevel=info

# Monitor via Flower
celery -A workers.celery_app flower --port=5555
```

---

## Project Structure

```
marketflow/
├── frontend/                    # Next.js 15 (App Router)
│   ├── app/                     # Pages and layouts
│   │   ├── (auth)/              # Login, register
│   │   ├── dashboard/           # Main dashboard
│   │   │   ├── [storeId]/       # Per-store views
│   │   │   └── analytics/       # Reports
│   │   ├── xray/                # Free X-Ray audit (lead magnet)
│   │   └── api/                 # Next.js API routes (BFF only)
│   ├── components/              # Reusable UI components
│   │   ├── dashboard/           # Dashboard-specific
│   │   ├── recommendations/     # AI recommendations UI
│   │   └── ui/                  # shadcn/ui base components
│   ├── hooks/                   # Custom React hooks
│   ├── lib/                     # API client, utils
│   │   └── api/                 # Per-resource API clients
│   └── types/                   # Shared TypeScript types
│
├── backend/                     # FastAPI + Python 3.12
│   └── app/
│       ├── api/v1/              # Route handlers (thin!)
│       │   └── endpoints/       # Per-resource endpoints
│       ├── services/            # Business logic (fat!)
│       ├── models/              # SQLAlchemy ORM models
│       ├── schemas/             # Pydantic v2 schemas
│       ├── core/                # Config, security, database
│       └── utils/               # Pure helper functions
│
├── workers/                     # Celery tasks
│   └── tasks/                   # Per-domain task files
│
├── migrations/                  # Alembic migrations
│   └── versions/
│
├── tests/                       # Test suite
│   ├── unit/                    # Pure unit tests
│   ├── integration/             # API + DB tests
│   ├── e2e/                     # Playwright end-to-end
│   └── load/                    # Locust performance tests
│
├── docs/                        # SPARC documentation
│   ├── PRD.md                   # Product requirements
│   ├── Architecture.md          # System design
│   ├── Pseudocode.md            # Core algorithms
│   ├── Refinement.md            # Edge cases + testing
│   ├── CJM-EasyCommerce.html    # Customer Journey Maps (3 variants)
│   ├── validation-report.md     # Requirements validation
│   ├── test-scenarios.md        # BDD scenarios
│   └── features/                # Per-feature SPARC docs
│
└── .claude/                     # Claude Code toolkit
    ├── commands/                # /start, /plan, /test, /deploy
    ├── agents/                  # @planner, @code-reviewer, @architect
    ├── rules/                   # Git, security, testing, coding-style
    └── skills/                  # project-context, coding-standards
```

---

## Core Algorithms Reference

From `docs/Pseudocode.md`:

### 1. Recommendation Generator
```
Input: store_id → Output: List[Recommendation] (max 5, sorted by est_impact_rub DESC)
Steps: FETCH metrics (30d) → CALCULATE scores → FILTER negative → AI enhance → SAVE
Expiry: 48 hours from creation
```

### 2. Bid Optimizer
```
Input: store_id → Output: List[BidAdjustment]
Steps: FETCH rules → CALCULATE drr → IF drr > target: reduce_bid
Notify Telegram if change > 20%
```

### 3. X-Ray Audit
```
Input: seller_id, platform → Output: AuditReport
Steps: FETCH listings → SCORE each (content_score/100) → AGGREGATE → AI ANALYSIS → SAVE
Rate limit: 3/IP/hour (unauth), 100/user/min (auth)
```

### 4. Review Responder
```
Input: review_id → Output: DraftResponse
Steps: CLASSIFY sentiment → SELECT template → CALL claude-haiku-4-5 → VALIDATE (must be RU)
Fallback: template if 2nd LLM attempt fails
```

---

## Security Checklist

Before committing:
```
[ ] No API keys/tokens in code
[ ] Marketplace keys encrypted (AES-256-GCM) before DB save
[ ] JWT in httpOnly cookie (not localStorage)
[ ] SSRF whitelist enforced for external HTTP calls
[ ] Rate limiting on public endpoints
[ ] No secrets in logs (use [REDACTED])
[ ] .env not committed (check .gitignore)
```

Run:
```bash
detect-secrets scan .
grep -rn "api_key\|password\|secret\|token" backend/app/ --include="*.py" \
  | grep -v "test\|example\|hash\|env\|settings" | grep -v "#"
```

---

## Deployment

### Staging
```bash
/deploy staging
```

### Production (requires staging pass)
```bash
/deploy prod
```

See `.claude/commands/deploy.md` for full deployment protocol.

---

## Available Claude Code Commands

| Command | Description |
|---------|-------------|
| `/start` | Bootstrap project from SPARC docs |
| `/feature [name]` | Full feature lifecycle (Plan→Validate→Implement→Review) |
| `/plan [feature]` | Quick implementation planning |
| `/test [scope]` | Run or generate tests |
| `/deploy [env]` | Deploy to staging/prod |
| `/myinsights` | Capture development insights |
| `/next` | Show sprint progress + top 3 next tasks |
| `/go [feature]` | Smart autonomous feature execution |
| `/docs` | Generate bilingual RU+EN documentation |

## Available Agents

| Agent | Trigger | Purpose |
|-------|---------|---------|
| `@planner` | "план", "как реализовать" | Feature planning |
| `@code-reviewer` | "проверь", "review" | Code review with edge cases |
| `@architect` | "архитектура", "design" | System design decisions |

---

## Troubleshooting

### Common Issues

**TimescaleDB "cannot add column to compressed table":**
```sql
SELECT disable_compression_policy('sales_metrics');
ALTER TABLE sales_metrics ADD COLUMN new_col INTEGER;
SELECT add_compression_policy('sales_metrics', INTERVAL '90 days');
```

**Celery task not executing:**
```bash
# Check only ONE beat instance is running
docker compose ps | grep beat
# Check Redis connection
docker compose exec redis redis-cli PING
```

**Frontend 401 on dashboard:**
```bash
# Check cookie is httpOnly and SameSite=Strict
curl -v http://localhost:8000/api/v1/auth/login \
  -d '{"email":"test@test.com","password":"test"}' \
  -H "Content-Type: application/json"
# Verify Set-Cookie header
```

**AES decrypt fails:**
```
Check that ENCRYPTION_KEY is the same key used for encryption.
Keys are per-environment — staging and prod use different keys.
```

### Insights Knowledge Base

Before debugging, search insights:
```bash
grep -i "keyword" myinsights/1nsights.md
```
