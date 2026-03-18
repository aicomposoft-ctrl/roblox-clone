# /test [scope] — Run or Generate Tests

Запуск тестов или генерация тестовых файлов для MarketFlow.

## Usage

```
/test                           # Run all tests
/test backend                   # Run backend tests only
/test frontend                  # Run frontend tests only
/test generate recommendation   # Generate tests for RecommendationService
/test generate bid-optimizer    # Generate tests for BidOptimizer
/test e2e                       # Run Playwright E2E tests
/test coverage                  # Show coverage report
```

## Test Structure

```
tests/
├── unit/
│   ├── test_recommendation_service.py
│   ├── test_bid_optimizer.py
│   ├── test_content_scorer.py
│   ├── test_xray_audit.py
│   ├── test_review_responder.py
│   └── test_security.py        # AES-GCM, JWT
├── integration/
│   ├── test_auth_api.py
│   ├── test_stores_api.py
│   ├── test_recommendations_api.py
│   ├── test_bids_api.py
│   └── test_marketplace_connectors.py  # Uses mock server
├── e2e/
│   ├── test_onboarding_journey.py      # Playwright
│   ├── test_xray_audit_journey.py
│   ├── test_bid_rule_journey.py
│   └── test_trial_expiry_journey.py
└── conftest.py                 # Fixtures: DB, Redis, mock marketplace
```

## Running Tests

### Backend Tests

```bash
# All tests with coverage
cd backend && pytest --cov=app --cov-report=term-missing -v

# Specific module
pytest tests/unit/test_recommendation_service.py -v

# Integration tests (requires Docker)
pytest tests/integration/ -v --tb=short

# Fast unit tests only
pytest tests/unit/ -v -x  # -x: stop on first failure
```

### Frontend Tests

```bash
# Type checking
cd frontend && npm run type-check

# Unit/component tests
npm run test

# E2E tests (requires running backend)
npm run test:e2e
```

### Coverage Targets (from Refinement.md)

| Module | Target | Critical |
|--------|--------|---------|
| `services/recommendation_service` | 90% | ✅ |
| `services/bid_optimizer` | 90% | ✅ |
| `services/xray_audit` | 85% | ✅ |
| `core/security` | 95% | ✅ |
| `api/v1/endpoints` | 80% | ✅ |
| Overall backend | 80% | ✅ |

## Generating Tests

When `/test generate [feature]`, read from:
- `docs/Pseudocode.md` — Algorithm to test
- `docs/Refinement.md` — Edge cases matrix
- `docs/test-scenarios.md` — BDD scenarios

**Test naming:** `test_[function]_[scenario]_[expected]`

Example generated test structure:

```python
# tests/unit/test_recommendation_service.py
import pytest
from unittest.mock import AsyncMock, patch
from app.services.recommendation_service import RecommendationService

class TestGenerateRecommendations:
    """Tests for generate_recommendations() from Pseudocode.md Algorithm 1"""

    async def test_generate_recommendations_happy_path_returns_top5(self): ...
    async def test_generate_recommendations_empty_metrics_returns_empty(self): ...
    async def test_generate_recommendations_ai_failure_uses_fallback(self): ...
    async def test_generate_recommendations_expired_recs_replaced(self): ...
    async def test_generate_recommendations_negative_impact_filtered(self): ...
```

## Performance Benchmarks

```bash
# Locust load test (from Refinement.md targets)
# Target: 1000 concurrent users
# Dashboard P99 < 2000ms
# Recommendation gen P99 < 5000ms
locust -f tests/load/locustfile.py --headless -u 100 -r 10 --run-time 60s
```
