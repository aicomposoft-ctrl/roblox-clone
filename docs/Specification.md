# Specification: MarketFlow Platform
**Версия:** 1.0 | **Дата:** 2026-03-18

---

## USER STORIES (MVP — P0/P1)

### Epic 1: Analytics Dashboard

**US-001: Multi-platform Sales Overview**
```
As a seller (Анна),
I want to see my sales across WB and Ozon in one dashboard,
So that I don't need to switch between 4+ separate cabinets.

Acceptance Criteria:
Given I am logged in and have connected WB + Ozon accounts
When I open the dashboard
Then I see:
  - Total GMV today / this week / this month (all platforms combined)
  - GMV breakdown by platform (pie chart + table)
  - Top-10 SKUs by revenue
  - GMV trend for last 30 days (line chart)
  - Data refreshes every 15 minutes

Given my API token has expired
When I open the dashboard
Then I see a warning "WB connection lost" with a one-click reconnect button
```

**US-002: Competitor Analytics**
```
As a brand manager (Максим),
I want to see my category competitors' metrics,
So that I understand our market position.

Acceptance Criteria:
Given I have selected a product category
When I open Competitor Analysis
Then I see:
  - Top-20 competitors by GMV in my category
  - Their price range, rating, review count, ad spend estimate
  - My position vs. category average (content score, review score)
  - 30-day trend for each competitor

Given a competitor has removed their listing
When I view competitor data
Then that competitor is marked as "Listing removed" with the last known data
```

---

### Epic 2: AI Recommendations

**US-003: Daily AI Task List**
```
As a seller (Анна),
I want to receive a prioritized list of 3-5 daily actions,
So that I always know what to do to grow my revenue.

Acceptance Criteria:
Given the AI has analyzed my account data
When I open the Recommendations section
Then I see:
  - Exactly 3-5 actionable tasks ranked by estimated revenue impact
  - Each task shows: action description, estimated impact (₽), effort (easy/medium/hard)
  - Example: "Raise price of SKU #123 by 8% → est. +₽45,000/month"
  - Each recommendation has a "Mark as done" button

Given I have completed a recommendation
When I mark it as done
Then:
  - Task moves to "Completed" with timestamp
  - System tracks if revenue impact was achieved
  - After 7 days, shows actual vs. predicted impact
```

**US-004: X-Ray Audit (Lead Magnet)**
```
As a new user (any persona),
I want to get a free audit of my marketplace listings,
So that I understand the potential improvements before subscribing.

Acceptance Criteria:
Given I enter my WB seller ID without signing up
When I request the X-Ray audit
Then within 60 seconds I see:
  - Content quality score for top-10 listings (0-100)
  - Gap analysis vs. category average
  - Top-3 issues with estimated revenue impact
  - "Unlock full audit" CTA linking to signup

Given the audit is complete
When I view the results
Then I can share the audit via URL (publicly accessible for 7 days)
```

---

### Epic 3: Automation

**US-005: Bid Management Automation**
```
As a seller (Анна),
I want to set bid management rules for my WB/Ozon campaigns,
So that my ads run efficiently without daily manual adjustment.

Acceptance Criteria:
Given I have active advertising campaigns on WB
When I configure bid automation rules
Then I can set:
  - Target DRR (e.g., "Keep DRR < 12%")
  - Max bid cap per keyword/product
  - Time-based rules (e.g., "Increase bids 20% during 19:00-22:00")
  - SKU-level rules override

Given a rule is triggered
When the system adjusts a bid
Then:
  - Change is logged with reason ("DRR exceeded 12%, bid reduced by 15%")
  - I receive a Telegram notification if bid changes by >20%
  - I can view bid change history for last 30 days
```

**US-006: AI Review Responses**
```
As a brand manager (Максим),
I want AI to draft responses to customer reviews,
So that I respond to 50 reviews in under 10 minutes.

Acceptance Criteria:
Given there are unresponded reviews in my account
When I open the Reviews section
Then I see:
  - All unresponded reviews sorted by date and rating
  - AI-generated draft response for each review
  - Sentiment classification (positive/negative/neutral)
  - Response matches our brand tone (configurable)

Given I approve a response
When I click "Send"
Then the response is posted via API within 30 seconds

Given a review contains a specific complaint
When AI generates a response
Then the response acknowledges the specific issue (not generic)
```

---

### Epic 4: Managed Services

**US-007: Client Dashboard (Managed)**
```
As a brand manager (Максим) on Managed plan,
I want a dedicated reporting page with my account manager,
So that I see what the team is doing and what results we're achieving.

Acceptance Criteria:
Given I am on the Managed Basic or Full plan
When I open My Account
Then I see:
  - Monthly KPI summary: GMV, orders, DRR, content score
  - Tasks completed this month by the team
  - Upcoming planned activities
  - Direct messaging with account manager
  - Access to all historical reports (downloadable PDF)
```

---

## NON-FUNCTIONAL REQUIREMENTS

### Performance
- Dashboard: P50 < 800ms, P99 < 2000ms
- AI recommendations generation: < 5000ms
- API data sync: every 15 minutes (near real-time for premium tiers)
- Concurrent users: 1000 (MVP), 10,000 (v2)

### Security
- All API keys encrypted at rest (AES-256)
- Keys never logged or exposed in error messages
- Session tokens: JWT, 24h TTL
- 2FA: optional (TOTP), mandatory for enterprise
- Rate limiting: 100 req/min per user
- Audit log: all data access logged for 90 days

### Scalability
- Horizontal scaling for API servers (stateless)
- Database sharding by seller_id for analytics data
- Redis cache for dashboard aggregations (TTL 15 min)
- Background jobs for AI recommendation generation (async)

### Compliance
- 152-ФЗ: данные продавцов хранятся на серверах в РФ
- GDPR: N/A (только РФ клиенты в MVP)
- Audit logs for automated decisions (bid changes, AI responses)
- Compliance-ready for платформенная экономика закон (01.10.2026)

---

## FEATURE MATRIX

| Feature | Free | Starter (3990₽) | Growth (9990₽) | Pro (24990₽) | Managed |
|---------|------|-----------------|----------------|--------------|---------|
| Platforms | 1 | 1 | All (4) | All (4) | All (4) |
| SKUs tracked | 10 | 100 | 1000 | Unlimited | Unlimited |
| AI recommendations | — | 3/day | 10/day | Unlimited | Unlimited |
| Bid automation | — | — | Basic | Advanced | Advanced |
| AI review responses | — | — | 50/day | Unlimited | Unlimited |
| Competitor analysis | — | 5 competitors | 20 competitors | Unlimited | Unlimited |
| AI content generation | — | — | 20 SKU/day | Unlimited | Unlimited |
| Telegram alerts | — | ✅ | ✅ | ✅ | ✅ |
| API access | — | — | — | ✅ | ✅ |
| Dedicated manager | — | — | — | — | ✅ |
| SLA | — | Best effort | 99.5% | 99.5% | 99.9% |
| Data history | 7 days | 30 days | 90 days | 1 year | 3 years |
