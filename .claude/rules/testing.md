# Testing Rules — MarketFlow

## Coverage Targets (from Refinement.md)

| Module | Target | Blocking |
|--------|--------|---------|
| `services/recommendation_service` | 90% | ✅ CI fails below |
| `services/bid_optimizer` | 90% | ✅ CI fails below |
| `services/xray_audit_service` | 85% | ✅ CI fails below |
| `services/review_service` | 80% | ✅ CI fails below |
| `core/security` (AES-GCM, JWT) | 95% | ✅ CI fails below |
| `api/v1/endpoints` | 80% | ✅ CI fails below |
| Overall backend | 80% | ✅ CI fails below |

## Test Naming Convention

```
test_[function]_[scenario]_[expected_result]

# Examples:
test_generate_recommendations_empty_metrics_returns_empty_list
test_optimize_bids_drr_zero_no_division_error
test_encrypt_api_key_fresh_nonce_unique_each_time
test_jwt_expired_token_raises_401
test_xray_audit_large_catalog_paginates
```

## Critical Test Cases (Mandatory)

### Recommendation Engine
```python
# Из Pseudocode.md Algorithm 1 + Refinement.md Edge Cases
test_generate_recommendations_happy_path_returns_max_5
test_generate_recommendations_0_skus_returns_empty_not_error
test_generate_recommendations_ai_failure_falls_back_to_rule_based
test_generate_recommendations_expired_recs_replaced_not_duplicated
test_generate_recommendations_negative_impact_filtered_out
test_generate_recommendations_sorts_by_impact_desc
```

### Bid Optimizer
```python
# DRR edge cases из Refinement.md
test_optimize_bids_drr_zero_no_division_error
test_optimize_bids_drr_100_max_reduction_applied
test_optimize_bids_drr_above_target_reduces_bid
test_optimize_bids_drr_below_target_increases_bid
test_optimize_bids_change_over_20pct_sends_telegram_notification
test_optimize_bids_time_based_rule_respects_schedule
```

### Security
```python
# AES-GCM нарушения из Refinement.md
test_encrypt_api_key_round_trip_decrypts_correctly
test_encrypt_api_key_different_nonce_each_call
test_decrypt_api_key_wrong_key_raises_error
test_decrypt_api_key_corrupted_ciphertext_raises_error
test_jwt_valid_token_returns_claims
test_jwt_expired_token_raises_401
test_jwt_tampered_signature_raises_403
```

### Content Score
```python
test_calculate_content_score_perfect_listing_returns_100
test_calculate_content_score_missing_title_penalty_applied
test_calculate_content_score_missing_images_penalty_applied
test_calculate_content_score_russian_text_detected_not_latin
```

## Test Infrastructure (conftest.py)

```python
# tests/conftest.py
import pytest
from httpx import AsyncClient
from app.main import app
from app.core.database import get_db
from tests.factories import StoreFactory, RecommendationFactory

@pytest.fixture
async def async_client():
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest.fixture
async def db_session():
    # Use test DB (separate from production)
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSession(test_engine) as session:
        yield session
    # Teardown
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture
def mock_marketplace_api():
    """Mock WB/Ozon API responses for integration tests"""
    with respx.mock(base_url="https://api.wildberries.ru") as mock:
        mock.get("/api/v1/supplier/stocks").respond(200, json={"stocks": []})
        yield mock

@pytest.fixture
def encryption_key():
    """Test AES-256 key"""
    return os.urandom(32)
```

## Running Tests

```bash
# Fast feedback loop (unit only)
pytest tests/unit/ -v -x --tb=short

# Full backend suite with coverage
pytest tests/ --cov=app --cov-report=term-missing --cov-fail-under=80

# Integration tests (requires Docker services)
docker compose up -d timescaledb redis
pytest tests/integration/ -v --tb=short

# E2E (requires full stack)
docker compose up -d
pytest tests/e2e/ -v

# Performance (Locust)
# Target: 1000 concurrent, Dashboard P99 < 2000ms
locust -f tests/load/locustfile.py --headless -u 1000 -r 50 --run-time 120s
```

## CI Pipeline (GitHub Actions)

```yaml
# .github/workflows/test.yml
jobs:
  test:
    steps:
      - run: pytest tests/unit/ tests/integration/ --cov=app --cov-fail-under=80
      - run: pip-audit  # Security audit
      - run: npm run type-check
      - run: npm audit --audit-level high
```

## Test Data Factories

```python
# tests/factories.py — use factory_boy
class StoreFactory(factory.Factory):
    class Meta:
        model = MarketplaceAccount
    id = factory.LazyFunction(uuid4)
    platform = factory.Iterator(['wildberries', 'ozon'])
    status = 'active'
    # NEVER use real API keys — use dummy encrypted values
    api_key_encrypted = factory.LazyFunction(
        lambda: encrypt_api_key("test_key_" + secrets.token_hex(8), TEST_ENCRYPTION_KEY)
    )
```
