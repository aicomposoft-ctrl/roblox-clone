# Refinement: MarketFlow Platform
**Версия:** 1.0 | **Дата:** 2026-03-18

---

## EDGE CASES MATRIX

| Сценарий | Input | Expected Behavior | Handling |
|----------|-------|-------------------|----------|
| Empty marketplace account | Store connected, 0 SKUs | Show "Нет товаров" placeholder, offer to add first SKU | Empty state UI |
| API rate limit exceeded | 100+ requests/min to WB | Exponential backoff, queue remaining, user sees "Обновляется..." | Celery retry |
| SKU with 0 sales in 30 days | SKU with no orders | Not included in recommendations, flagged as "Неактивный" | Filter in query |
| Simultaneous edit + sync | User edits bid rule while sync runs | DB transaction locks, last-write-wins with timestamp | Optimistic locking |
| Trial ends mid-month | 14-day trial expires at day 14 | Graceful downgrade to Free, data retained 30 days, no auto-charge | Subscription event |
| LLM returns non-Russian text | Claude generates English description | Retry with ru prompt, fallback to template if 2nd attempt fails | LLM fallback |
| WB API returns partial data | Sync returns 80% of SKUs | Mark missing SKUs as "Данные недоступны", keep last known values | Partial sync handling |
| Concurrent bid optimization | Two users edit same rule | Last save wins, conflict notification via WebSocket | Race condition |
| Large catalog (10k+ SKUs) | User with 10,000 SKUs | Pagination, background aggregation, progressbar | Async processing |
| Negative recommendation impact | AI predicts negative impact | Filter out (never recommend negative impact actions) | Algorithm guard |
| Invalid API key on connect | User enters wrong WB token | Immediate validation, clear error "Неверный токен WB" | Pre-save validation |
| Network timeout during sync | VPS network issue | Celery retry after 60s, max 3 retries, then mark sync as failed | Circuit breaker |

---

## TESTING STRATEGY

### Unit Tests (Coverage target: 80%+)

**Critical paths to test:**
- `calculate_content_score()` — all scoring formula branches
- `generate_recommendations()` — each recommendation type
- `optimize_bids()` — all rule types, edge cases (drr=0, drr=100)
- `generate_xray_audit()` — empty store, large store, platform differences
- JWT generation and validation
- API key encryption/decryption

**Test naming convention:** `test_[function]_[scenario]_[expected]`

### Integration Tests

- WB/Ozon API connector tests (use mock server)
- PostgreSQL + TimescaleDB write/read cycle
- Celery task execution and result retrieval
- Redis cache hit/miss behavior
- WebSocket connection lifecycle

### E2E Tests (Playwright)

**Critical user journeys:**
1. Registration → Connect WB → See first dashboard → Receive recommendation
2. X-Ray audit (unauthenticated) → View results → Sign up → First login
3. Configure bid rule → Trigger bid adjustment → Verify in audit log
4. Trial expiration → Downgrade flow → Data still accessible in Free tier

### Performance Tests (Locust)

```python
# Target load: 1000 concurrent users
# Dashboard load: < 2000ms P99
# Recommendation generation: < 5000ms P99

scenarios:
  - dashboard_load: 800 users
  - recommendation_check: 150 users
  - bid_rule_update: 50 users
```

---

## TEST CASES (BDD / Gherkin)

```gherkin
Feature: X-Ray Audit (Lead Magnet)

  Scenario: Successful audit for existing seller
    Given a valid WB seller ID "12345678"
    When I request an X-Ray audit
    Then I receive a report within 60 seconds
    And the report contains at least 1 analyzed listing
    And the report has a shareable URL
    And the URL is accessible without authentication

  Scenario: Audit for non-existent seller
    Given an invalid WB seller ID "00000000"
    When I request an X-Ray audit
    Then I receive a 404 error
    And the error message is in Russian
    And no audit data is stored

  Scenario: Rate limit enforcement
    Given I have already requested 3 audits from the same IP
    When I request a 4th audit within 1 hour
    Then I receive a 429 error
    And the error includes retry_after in seconds

Feature: Bid Optimization Rules

  Scenario: Target DRR rule reduces bids correctly
    Given a campaign with current DRR of 18%
    And a bid rule with target_drr = 12%
    When the bid optimizer runs
    Then bids are reduced by approximately 15-30%
    And the change is logged with reason "DRR превышает цель"
    And a Telegram notification is sent (change > 20%)

  Scenario: Bid rule respects maximum bid cap
    Given a campaign with target_drr suggesting +50% bid increase
    And a bid rule with max_bid = 500₽
    When the bid optimizer runs
    Then the new bid does not exceed 500₽
    And the log entry notes "Ограничен max_bid"

Feature: AI Recommendations

  Scenario: Recommendations are generated daily
    Given a connected store with active sales
    When 24 hours have passed since last recommendation generation
    Then new recommendations are automatically generated
    And old recommendations with status 'pending' are expired
    And the user receives a Telegram notification

  Scenario: Completed recommendation tracks actual impact
    Given a recommendation "Повысить цену на 8%"
    When the user marks it as done
    Then after 7 days, system compares revenue before and after
    And shows "Прогноз: +₽45,000. Факт: +₽38,200 (-15% от прогноза)"
```

---

## PERFORMANCE OPTIMIZATIONS

### Database
- TimescaleDB continuous aggregates for dashboard queries (pre-aggregate hourly/daily)
- Indexes on (store_id, time) for all analytics queries
- PostgreSQL connection pooling (PgBouncer, max 20 connections per app instance)
- Partition sales_metrics by month (TimescaleDB auto-partitioning)

### Caching Strategy
```
CACHE LAYERS:

L1: Next.js SWR (client-side, stale-while-revalidate)
  - Dashboard overview: 60 seconds TTL
  - Competitor data: 30 minutes TTL

L2: Redis (server-side)
  - Dashboard aggregations: 15 minutes TTL
  - Category benchmarks: 1 hour TTL
  - X-Ray audit results: 24 hours TTL

Cache invalidation:
  - Data sync completion → invalidate dashboard cache for that store
  - User action (bid change, etc.) → invalidate affected recommendations
```

### AI Cost Optimization
- Batch LLM calls (generate 5 review responses in one API call)
- Cache category-level insights (shared across same-category sellers)
- Use Claude Haiku for simple tasks (review responses, basic content)
- Use Claude Sonnet for complex tasks (strategy recommendations, X-Ray analysis)

---

## SECURITY HARDENING

### Input Validation
- All user inputs sanitized (Pydantic models with strict validators)
- SQL injection: parameterized queries only (SQLAlchemy ORM)
- XSS: Next.js default escaping + CSP headers
- SSRF: whitelist for external URLs (only marketplace domains)

### Rate Limiting
```
/api/v1/audit/xray: 3 req/IP/hour (unauthenticated)
/api/v1/recommendations/*: 10 req/user/hour
/api/v1/auth/login: 5 req/IP/15 minutes
/api/v1/*: 100 req/user/minute (authenticated)
```

### Audit Logging
- All authentication events
- All marketplace API key operations (add/update/delete)
- All bid changes (what, when, by whom, reason)
- All AI actions (recommendations generated, review responses sent)
- Retention: 90 days

---

## TECHNICAL DEBT ITEMS

| Item | Priority | Estimated Sprint | Notes |
|------|----------|-----------------|-------|
| Migrate from Redis pub/sub to proper WebSocket infrastructure | Medium | Sprint 4 | Current: polling, Future: true realtime |
| Add proper ML model versioning | High | Sprint 3 | Currently no model versioning |
| Implement proper secrets rotation | Medium | Sprint 5 | Currently manual key rotation |
| Add comprehensive OpenAPI docs | Low | Sprint 6 | Auto-generated but needs examples |
| Database migrations CI validation | Medium | Sprint 2 | Add Alembic migration testing |
