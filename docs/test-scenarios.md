# BDD Test Scenarios: MarketFlow Platform
**Версия:** 1.0 | **Дата:** 2026-03-18 | **Инструмент:** Gherkin / Cucumber

---

## Feature: Authentication & Authorization

```gherkin
Feature: User Authentication

  Background:
    Given the MarketFlow web application is running
    And the database is seeded with test users

  Scenario: Successful registration with email
    Given I am on the registration page
    When I fill in email "seller@example.com"
    And I fill in password "SecurePass123!"
    And I fill in company name "ООО Тест"
    And I click "Создать аккаунт"
    Then I see "Подтвердите email" message
    And a verification email is sent to "seller@example.com"
    And a trial subscription (14 days) is created

  Scenario: Login with valid credentials
    Given a user with email "seller@example.com" and password "SecurePass123!" exists
    When I submit the login form with these credentials
    Then I am redirected to "/dashboard"
    And a JWT token is set in httpOnly cookie
    And the session expires in 24 hours

  Scenario: Login with invalid credentials
    Given a user with email "seller@example.com" exists
    When I submit the login form with password "WrongPassword"
    Then I see error "Неверный email или пароль"
    And no token is set
    And the failed attempt is logged

  Scenario: Rate limiting on login endpoint
    Given I am on the login page
    When I submit the login form 5 times with wrong password within 15 minutes
    Then the 6th attempt returns HTTP 429
    And the error shows "Слишком много попыток. Попробуйте через X минут"

  Scenario: Token expiration
    Given I am logged in with a token that expires in 1 second
    When 2 seconds have passed
    And I make an API request to "/api/v1/dashboard"
    Then I receive HTTP 401
    And I am redirected to the login page
```

---

## Feature: X-Ray Audit (Lead Magnet)

```gherkin
Feature: X-Ray Audit — Free Store Analysis

  Scenario: Successful audit for existing WB seller
    Given a valid WB seller ID "12345678"
    When I request an X-Ray audit at "POST /api/v1/audit/xray"
    Then I receive HTTP 202 (audit started)
    And within 60 seconds I receive a completed audit report
    And the report contains:
      | Field                  | Requirement         |
      | listings_analyzed      | >= 1                |
      | content_score_avg      | between 0 and 100   |
      | main_issues            | list, not empty     |
      | recommendations        | list, 3-7 items     |
      | shareable_url          | valid URL           |
    And the shareable URL is accessible without authentication
    And the URL remains valid for 7 days

  Scenario: Audit for non-existent seller
    Given an invalid WB seller ID "00000000"
    When I request an X-Ray audit
    Then I receive HTTP 404
    And the error message is "Продавец не найден. Проверьте ID магазина."
    And the message is in Russian
    And no audit data is stored in the database

  Scenario: Audit for seller with empty store
    Given a valid WB seller ID with 0 active SKUs
    When I request an X-Ray audit
    Then I receive a report within 60 seconds
    And the report shows "В магазине нет активных товаров"
    And recommendations include "Добавьте первый товар для начала продаж"

  Scenario: Rate limit enforcement for unauthenticated users
    Given I have already requested 3 audits from the same IP within 1 hour
    When I request a 4th audit
    Then I receive HTTP 429
    And the error includes "retry_after" in seconds
    And the rate limit is stored in Redis with TTL 3600s

  Scenario: Large store audit performance
    Given a WB seller ID with 1000+ SKUs
    When I request an X-Ray audit
    Then I receive HTTP 202 immediately (async processing)
    And within 60 seconds the audit completes
    And the audit processes all listings (paginated internally)
    And the final report has aggregated scores

  Scenario: Shareable URL access after expiration
    Given a shareable audit URL created 8 days ago
    When I access the URL without authentication
    Then I receive HTTP 410 (Gone)
    And the message says "Отчёт истёк. Создайте новый аудит."
```

---

## Feature: Multi-Platform Dashboard

```gherkin
Feature: Sales Dashboard (US-001)

  Background:
    Given I am logged in as "seller@example.com"
    And my account has WB and Ozon connected stores

  Scenario: Dashboard loads with combined metrics
    When I navigate to "/dashboard"
    Then I see a combined GMV figure across WB and Ozon
    And I see individual breakdown by platform
    And the data is no older than 15 minutes
    And the page loads within 2000ms (P99)

  Scenario: Dashboard data refresh
    Given the dashboard is showing data from 16 minutes ago
    When I reload the page
    Then the system triggers a fresh data sync
    And updated data appears within 15 minutes
    And I see a "Обновляется..." indicator during sync

  Scenario: Marketplace API error handling
    Given the WB API returns 503 for 3 consecutive requests
    When I view the dashboard
    Then I see a warning banner: "WB: данные обновлялись NN минут назад"
    And a "Переподключить" button is visible
    And the Ozon data displays normally (independent connection)

  Scenario: Dashboard with no connected stores
    Given a new user with no connected marketplaces
    When I navigate to "/dashboard"
    Then I see an empty state: "Подключите маркетплейс для начала работы"
    And a "Подключить WB" and "Подключить Ozon" buttons are shown

  Scenario: Platform connection via API key
    Given I am on the Settings > Integrations page
    When I enter a valid WB API token
    And click "Подключить"
    Then the system validates the token against WB API
    And I see "WB подключён ✓"
    And a background sync starts immediately
    And dashboard data appears within 5 minutes

  Scenario: Invalid API key rejection
    Given I am on the Settings > Integrations page
    When I enter an invalid WB API token "invalid-token-123"
    And click "Подключить"
    Then I see error "Неверный токен WB. Проверьте раздел API в личном кабинете WB."
    And no data sync is started
    And the token is NOT stored in the database
```

---

## Feature: Competitor Analytics

```gherkin
Feature: Competitor Monitoring (US-002)

  Background:
    Given I am logged in with a Growth or Pro subscription
    And my WB store is connected

  Scenario: View top competitors in category
    Given my store sells in category "Женская одежда"
    When I navigate to "/competitors"
    Then I see up to 20 competitors in my category
    And each competitor shows:
      | Field           | Type    |
      | seller_name     | string  |
      | gmv_estimate    | ₽ value |
      | avg_price       | ₽ value |
      | avg_rating      | decimal |
      | reviews_count   | integer |
      | category_rank   | integer |
    And data is refreshed at least daily

  Scenario: Competitor data not available on Free tier
    Given I have a Free subscription
    When I navigate to "/competitors"
    Then I see "Конкурентная аналитика доступна с тарифа Growth"
    And a "Перейти на Growth" button is shown
    And no competitor data is displayed
```

---

## Feature: AI Daily Recommendations

```gherkin
Feature: AI Task Recommendations (US-003)

  Background:
    Given I am logged in with an active subscription
    And my WB store has at least 1 SKU with sales

  Scenario: Daily recommendations are generated automatically
    Given no recommendations have been generated today
    When 24 hours have passed since the last generation
    Then the Celery scheduler triggers recommendation generation
    And 3-5 new recommendations are created
    And old "pending" recommendations from previous day are expired
    And I receive a Telegram notification: "Новые задачи готовы"

  Scenario: Recommendation format and content
    When recommendations are generated for my store
    Then each recommendation has:
      | Field         | Requirement                    |
      | title         | string, < 100 chars            |
      | description   | string, actionable             |
      | ₽_impact      | positive integer (₽ estimate)  |
      | priority      | high/medium/low                |
      | category      | price/content/ads/stock/review |
    And recommendations are sorted by ₽ impact (descending)
    And no recommendation has negative ₽ impact

  Scenario: Mark recommendation as done
    Given a recommendation "Повысить цену на артикул A на 8%"
    When I click "Выполнено" on the recommendation
    Then it moves to "Completed" status with timestamp
    And after 7 days the system compares revenue:
      | Metric         | Displayed         |
      | Forecast       | +₽45,000          |
      | Actual         | actual delta      |
      | Accuracy       | (actual/forecast) |
    And the accuracy data is shown in the Insights section

  Scenario: Skip recommendation
    Given a pending recommendation
    When I click "Пропустить" and select reason "Уже сделано"
    Then the recommendation moves to "Skipped" status
    And the reason is stored
    And the ML model receives this as negative feedback

  Scenario: Recommendations for store with no sales
    Given a connected store with 0 orders in 30 days
    When recommendations are generated
    Then recommendations focus on "Активация" category only
    And include: content improvement, first promotion, pricing audit
    And DO NOT include revenue-based recommendations (no data available)
```

---

## Feature: Bid Management Automation

```gherkin
Feature: Bid Optimization Rules (US-005)

  Background:
    Given I am logged in with a Growth or Pro subscription
    And my WB account has active advertising campaigns

  Scenario: Create Target DRR rule
    Given I navigate to "Биды > Правила"
    When I create a rule:
      | Field       | Value        |
      | campaign    | "Летняя коллекция" |
      | target_drr  | 12%          |
      | max_bid     | 500₽         |
    And click "Сохранить"
    Then the rule is saved with status "Active"
    And within 30 minutes the rule triggers for the first time
    And the first triggered bid adjustment is logged with timestamp and reason

  Scenario: Target DRR rule reduces bids correctly
    Given a campaign with current DRR of 18%
    And a bid rule with target_drr = 12%
    When the bid optimizer runs
    Then bids are reduced by approximately 15-30%
    And the change is logged with reason "DRR превышает цель"
    And a Telegram notification is sent if change > 20%

  Scenario: Max bid cap enforcement
    Given a campaign where target_drr calculation suggests +50% bid increase
    And a bid rule with max_bid = 500₽
    When the bid optimizer runs
    Then the new bid does not exceed 500₽
    And the log entry shows "Ограничен max_bid: предлагалось X₽, применено 500₽"

  Scenario: Bid rule audit log
    Given a bid rule that has triggered 5 times today
    When I view "Биды > История"
    Then I see 5 log entries with:
      | Field         | Content                |
      | timestamp     | ISO datetime           |
      | campaign      | campaign name          |
      | old_bid       | previous bid ₽         |
      | new_bid       | new bid ₽              |
      | reason        | human-readable string  |
      | drr_at_time   | DRR% at decision time  |

  Scenario: Simultaneous rule edit and optimization
    Given a bid rule is being optimized by the Celery task
    When I simultaneously edit the same rule in the UI
    Then the edit uses optimistic locking
    And the last save wins (with timestamp)
    And if conflict detected: I see "Правило было изменено. Ваши данные сохранены."

  Scenario: Rule with zero bids (edge case)
    Given a campaign with all bids at 0₽
    And a bid rule with target_drr = 10%
    When the bid optimizer runs
    Then bids are NOT set to negative values
    And the log entry shows "Невозможно снизить ставку: уже 0₽"
```

---

## Feature: AI Review Responses

```gherkin
Feature: Review Management (US-006)

  Background:
    Given I am logged in with a Growth or Pro subscription
    And my WB store has at least 1 unanswered review

  Scenario: AI draft generation for new review
    Given a new 1-star review: "Ужасное качество, пришло рваное"
    When the review sync runs
    Then within 60 seconds an AI draft is generated:
      | Requirement                              |
      | Response < 500 characters                |
      | Acknowledges the issue (negative tone)   |
      | Offers resolution                        |
      | Written in Russian                       |
      | Does NOT mention competitors             |
      | No offensive content                     |
    And the draft is saved with status "pending_review"

  Scenario: Bulk respond to 50 reviews in 5 minutes
    Given 50 unanswered reviews across WB and Ozon
    When I click "Ответить на все (AI)"
    Then AI drafts are generated for all 50 reviews in batch
    And within 5 minutes all 50 have drafts
    And I can review/edit each draft before sending
    And "Отправить все" sends all approved drafts

  Scenario: Send review response
    Given an AI draft for review #789
    When I approve the draft and click "Отправить"
    Then the response is sent to WB API within 30 seconds
    And the review status updates to "Answered"
    And the send event is logged in audit log

  Scenario: LLM generates non-Russian response
    Given a Russian review text
    When Claude API returns an English-language draft
    Then the system detects the language mismatch
    And retries the LLM call with explicit "respond in Russian" prompt
    And if the second attempt also fails: uses a Russian template fallback
    And logs "LLM fallback used for review #ID"

  Scenario: Positive review response
    Given a 5-star review: "Отличный товар, пришёл быстро!"
    When AI draft is generated
    Then the draft:
      | Requirement                              |
      | Thanks the customer                      |
      | Highlights mentioned feature (delivery) |
      | Invites return purchase                  |
      | NOT defensive or apologetic              |
```

---

## Feature: Subscription Lifecycle

```gherkin
Feature: Subscription Management

  Scenario: Trial starts on registration
    Given a new user registers
    Then a 14-day trial subscription is automatically created
    And the user has access to Growth tier features
    And trial end date is stored in the database
    And a reminder is scheduled for day 11 (3 days before expiry)

  Scenario: Trial expiration — graceful downgrade
    Given a user on trial subscription
    When the trial expires at day 14
    Then the subscription is automatically downgraded to Free
    And the user sees a "Ваш пробный период завершён" banner
    And all data (stores, recommendations, audit history) is retained 30 days
    And no automatic charge occurs

  Scenario: Trial expiration Telegram notification
    Given a user on trial with Telegram connected
    When the trial ends at midnight
    Then within 5 minutes a Telegram message is sent:
      "Ваш пробный период завершился. Данные сохранены 30 дней.
       Выбрать тариф: [ссылка]"

  Scenario: Upgrade from Free to Starter
    Given I am on the Free plan
    When I select "Starter — 3,990₽/мес" and complete payment
    Then my subscription is immediately upgraded to Starter
    And I gain access to Starter features
    And the first payment is charged
    And a receipt is emailed

  Scenario: Data retention on Free tier
    Given I was on Growth plan with 1000 recommendations
    When I downgrade to Free
    Then all historical data is retained (read-only)
    And new recommendation generation is paused
    And I see "Обновление данных приостановлено. Перейдите на платный тариф."

  Scenario: Cancel subscription mid-month
    Given I am on Growth plan (billed monthly)
    When I cancel my subscription on day 15
    Then access continues until end of billing period
    And auto-renewal is disabled
    And I see "Тариф активен до DD.MM.YYYY. Автоматическое продление отключено."
    And no refund is issued (service terms)
```

---

## Feature: Managed Client Dashboard (US-007)

```gherkin
Feature: Managed Service Dashboard

  Background:
    Given I am logged in as a MarketFlow account manager
    And I manage 3 client stores: "BrandA", "BrandB", "BrandC"

  Scenario: View aggregated KPIs for all managed clients
    When I navigate to "/managed"
    Then I see a summary table with all clients:
      | Column          | Requirement            |
      | client_name     | string                 |
      | monthly_gmv     | ₽ value                |
      | gmv_growth      | % vs previous month    |
      | drr_current     | %                      |
      | top_issue       | string                 |
    And data is refreshed daily

  Scenario: Monthly KPI summary per client
    Given today is the first day of the month
    When the monthly report job runs
    Then each managed client receives a PDF/email report with:
      | Section              | Content                |
      | GMV comparison       | This month vs last     |
      | DRR trend            | Weekly chart           |
      | Top recommendations  | 3 completed tasks      |
      | Next month forecast  | AI prediction          |

  Scenario: Client data isolation
    Given account manager A manages "BrandA" and "BrandB"
    And account manager B manages "BrandC"
    When manager A requests data for "BrandC"
    Then they receive HTTP 403
    And the access attempt is logged in audit log

  Scenario: Drill-down into specific client
    Given I am on the managed dashboard
    When I click on client "BrandA"
    Then I navigate to the full dashboard for "BrandA"
    And I see all BrandA data as if I were logged in as BrandA
    And a breadcrumb shows "Managed > BrandA"
```

---

## Feature: Security

```gherkin
Feature: Security Requirements

  Scenario: SQL injection prevention
    Given the login form
    When I submit email "admin'--" and password "anything"
    Then I receive a standard "Неверный email или пароль" response
    And no SQL error is exposed
    And the attempt is logged

  Scenario: API key encryption at rest
    Given I store a WB API key "wb-token-abc123"
    When I inspect the database directly
    Then the stored value is encrypted (AES-256-GCM)
    And the plaintext key is not visible in any log

  Scenario: HTTPS enforcement
    Given an HTTP request to "http://api.marketflow.ru/api/v1/dashboard"
    When the request arrives at Nginx
    Then it is redirected to HTTPS with 301
    And HSTS header is set (max-age=31536000)

  Scenario: XSS prevention in user-generated content
    Given a review text containing "<script>alert('xss')</script>"
    When the review is displayed in the UI
    Then the script tag is escaped/stripped
    And no JavaScript executes in the browser

  Scenario: Marketplace API key never sent to logs
    Given a valid WB API key is in use
    When a WB API call fails with an error
    Then the error log DOES NOT contain the API key
    And the log contains "[REDACTED]" in place of the key
```

---

## Summary

| Feature Area         | Scenarios | Happy Path | Error Cases | Edge Cases | Security |
|---------------------|-----------|------------|-------------|------------|----------|
| Authentication       | 5         | 2          | 2           | 1          | 1 (rate limit) |
| X-Ray Audit          | 6         | 1          | 2           | 2          | 1 (rate limit) |
| Dashboard            | 5         | 2          | 1           | 1          | 1        |
| Competitor Analytics | 2         | 1          | 0           | 0          | 1 (tier) |
| AI Recommendations   | 5         | 2          | 1           | 2          | 0        |
| Bid Management       | 6         | 2          | 2           | 2          | 0        |
| Review Responses     | 5         | 2          | 1           | 1          | 1        |
| Subscription         | 6         | 3          | 1           | 2          | 0        |
| Managed Dashboard    | 4         | 2          | 0           | 1          | 1        |
| Security             | 5         | 0          | 0           | 0          | 5        |
| **TOTAL**            | **49**    | **17**     | **10**      | **12**     | **10**   |
