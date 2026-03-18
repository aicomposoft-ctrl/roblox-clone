# MarketFlow

**AI-Native платформа управления продажами на российских маркетплейсах**

> Аналог Easy Commerce (easycomm.ru) — CAT analytics + AI automation + Managed Services

[![Python](https://img.shields.io/badge/Python-3.12-blue)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green)](https://fastapi.tiangolo.com)
[![Next.js](https://img.shields.io/badge/Next.js-15-black)](https://nextjs.org)
[![TimescaleDB](https://img.shields.io/badge/TimescaleDB-2.x-orange)](https://timescale.com)

---

## What is MarketFlow?

MarketFlow — это AI-Native платформа полного цикла для 1.26 млн продавцов Wildberries, Ozon, Яндекс Маркет и MegaMarket.

**Проблема:** Продавцы тратят 15-20 ч/неделю на ручную аналитику при комиссиях 30%+ и ДРР рекламы 18-30%.

**Решение:** AI-агент как «виртуальный менеджер маркетплейса» — заменяет команду из 3-5 человек за 10% цены.

### Key Features

| Feature | MVP | v1.0 |
|---------|-----|------|
| Unified Dashboard (WB+Ozon+YM+MM) | ✅ | ✅ |
| AI Recommendations (топ-5 действий с ROI) | ✅ | ✅ |
| Bid Management (manual) | ✅ | ✅ |
| SEO Card Optimizer | ✅ | ✅ |
| **Bid Autopilot (AI agent)** | — | ✅ |
| **AI Content Generator** | — | ✅ |
| **Free X-Ray Audit (lead magnet)** | — | ✅ |
| Competitor Analytics | — | ✅ |
| AI Review Responder | — | ✅ |
| Telegram Notifications | ✅ | ✅ |

---

## Quick Start

```bash
# Prerequisites: Docker 24+, Docker Compose 2.20+

git clone <repo> marketflow && cd marketflow
cp .env.example .env

# Generate secrets
python -c "import os,base64; print('ENCRYPTION_KEY=' + base64.b64encode(os.urandom(32)).decode())" >> .env
openssl rand -hex 64 | awk '{print "JWT_SECRET_KEY=" $0}' >> .env

# Add your Anthropic API key to .env
echo "ANTHROPIC_API_KEY=sk-ant-..." >> .env

docker compose up -d
docker compose exec backend alembic upgrade head

# Open http://localhost:3000
```

See [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) for detailed setup.

---

## Architecture

```
nginx (80/443) → frontend (Next.js :3000) + backend (FastAPI :8000)
                                               ↓
                              timescaledb (:5432) + redis (:6379)
                                               ↓
                              celery workers + celery beat (scheduled jobs)
                                               ↓
                              WB API | Ozon API | YM API | MM API
```

**Pattern:** Distributed Monolith (Monorepo)
**Infra:** VPS (AdminVPS/HOSTKEY) — 152-ФЗ RU jurisdiction
**Deploy:** Docker Compose direct deploy

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 15, Tailwind CSS, Shadcn/ui |
| Backend | FastAPI 0.115, Python 3.12 |
| Analytics DB | TimescaleDB (PostgreSQL 16) |
| Cache/Queue | Redis 7, Celery 5.3 |
| ML | CatBoost 1.2 |
| AI | Anthropic Claude (claude-haiku-4-5 / claude-sonnet-4-6) |
| Storage | MinIO |
| Proxy | Nginx |
| Migrations | Alembic |

---

## Documentation

| Document | Description |
|----------|-------------|
| [PRD.md](docs/PRD.md) | Product requirements, personas, feature roadmap |
| [Architecture.md](docs/Architecture.md) | System design, services, ADRs |
| [Pseudocode.md](docs/Pseudocode.md) | Core algorithms (Recommendation, Bid, X-Ray, Review) |
| [Refinement.md](docs/Refinement.md) | Edge cases matrix, testing strategy |
| [Solution_Strategy.md](docs/Solution_Strategy.md) | First Principles + Game Theory analysis |
| [CJM-EasyCommerce.html](docs/CJM-EasyCommerce.html) | Customer Journey Maps (3 variants with micro-trends) |
| [validation-report.md](docs/validation-report.md) | Requirements validation (swarm of 5 agents) |
| [test-scenarios.md](docs/test-scenarios.md) | BDD scenarios (Gherkin) |

---

## Market Context

Based on PARANOID-mode research (Phase 0 discovery of easycomm.ru):

- **Target:** 1.26 млн продавцов WB+Ozon, рынок 5.3 трлн₽ (2025)
- **Competitor:** Easy Commerce — #1 по аналитике для маркетплейсов (Рейтинг Рунета)
- **Gap:** Easy Commerce нет AI-автоматизации → наша дифференциация
- **Window:** 12-18 месяцев пока incumbents реагируют (Nash Equilibrium)

See [docs/M3-MarketCompetition.md](docs/M3-MarketCompetition.md) for full competitive analysis.

---

## Development

```bash
# Plan a feature
/plan multi-platform-dashboard

# Full feature lifecycle
/feature bid-autopilot

# Run tests
/test backend

# Deploy to staging
/deploy staging
```

See [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) for full workflow.

---

## License

Proprietary — MarketFlow Platform © 2026
