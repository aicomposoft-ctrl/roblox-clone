---
name: project-context
description: >
  Domain knowledge skill для MarketFlow. Содержит бизнес-логику маркетплейсов,
  структуру рынка, персоны клиентов и ключевые алгоритмы платформы.
  Используется агентами planner, code-reviewer, architect для контекста.
version: "1.0"
maturity: production
---

# Project Context: MarketFlow Platform

## Domain: Russian Marketplace Management

### Market Context

| Параметр | Значение |
|----------|----------|
| Рынок | Российский e-commerce, 5.3 трлн₽ (2025) |
| Продавцы | 1.26 млн на WB+Ozon |
| Комиссии | 30%+ (было 15-20%) |
| ДРР рекламы | 18-30% (было 8%) |
| Ручной труд | 15-20 ч/неделю на аналитику |

### Competitor Landscape

| Игрок | Фокус | Слабость |
|-------|-------|----------|
| Easy Commerce | Managed services + CAT analytics | Нет AI-автоматизации |
| MPSTATS | Аналитика, большая база | Только аналитика, нет исполнения |
| SellerFox | SaaS для продавцов | Нет managed services |
| WB/Ozon tools | Встроенные | Один маркетплейс, нет AI |

### User Personas

**Анна (Seller, SMB):**
- Оборот: 8М₽/мес, WB+Ozon, команда 2 чел.
- Боль: 6 ч/день на ручную операционку
- JTBD: Управлять двумя площадками без утопания в таблицах
- Платит: 10-25к₽/мес за SaaS

**Максим (Brand Manager):**
- Компания: FMCG бренд, 300М₽/год на маркетплейсах
- Боль: Нет data-driven отчёта, продажи упали на 20%
- JTBD: Конкретные действия → рост без SEO-специалиста
- Платит: 150-400к₽/мес за managed services

**Дмитрий (Enterprise E-com Director):**
- Компания: Федеральный ритейлер, 5Б₽+/год
- Боль: Маркетплейсы 35% выручки, команда не справляется
- JTBD: Стратегический технопартнёр с гарантиями
- Платит: 500к-2М₽/мес за enterprise платформу

## Business Rules

### Recommendation Engine
- Максимум 5 активных рекомендаций на магазин одновременно
- Рекомендации истекают через 48 часов
- Negative impact рекомендации никогда не показываются
- Impact estimate в рублях обязателен (причина доверия)
- Сортировка: по убыванию est_impact_rub

### Bid Optimizer
- Уведомление в Telegram при изменении ставки > 20%
- Проверка правил каждые 15 мин (Celery Beat schedule)
- ДРР = (рекламные расходы / GMV) * 100%
- drr_target из BidRule.params — не глобальная настройка
- История изменений хранится в audit_log таблице

### Content Scoring (X-Ray Audit)
- Максимальный score: 100 баллов
- Штрафы: нет главного фото (-25), нет описания (-20), нет характеристик (-15)
- Бесплатный аудит: 3 запроса/IP/час (Redis sliding window)
- Платный аудит: 100 запросов/юзер/мин
- Аудит сохраняется в MinIO (PDF export)

### Review Responder
- Классификация: positive/neutral/negative sentiment
- claude-haiku-4-5 для генерации (не claude-sonnet-4-6 — оверкилл)
- Validation: ответ должен быть на русском языке
- Fallback: template-based response при 2-й ошибке LLM

### Subscription Tiers

| Tier | Цена | SKU | API синхр. | AI features |
|------|------|-----|-----------|------------|
| Free | 0₽ | 100 | Ручная | ❌ |
| Starter | 7.900₽/мес | 1.000 | Авто (15 мин) | Базовые рекомендации |
| Growth | 19.900₽/мес | 10.000 | Авто (5 мин) | Все AI фичи |
| Pro | 49.900₽/мес | Unlim | Авто (1 мин) | + Managed dashboard |
| Enterprise | Custom | Unlim | Real-time | Full managed |

## API Integration Notes

### Wildberries API
- Base URL: `https://api.wildberries.ru`
- Auth: API token в header `Authorization`
- Rate limit: 60 requests/min
- Endpoints: /api/v1/supplier/stocks, /api/v1/analytics/...

### Ozon API
- Base URL: `https://api-seller.ozon.ru`
- Auth: `Client-Id` + `Api-Key` headers
- Rate limit: 120 requests/min
- Endpoints: /v1/product/list, /v1/analytics/...

### Yandex Market API
- Base URL: `https://api.partner.market.yandex.ru`
- Auth: OAuth token
- Endpoints: /campaigns/{campaignId}/orders, ...

## Key Metrics (KPI)

| Метрика | Target MVP | Target v1 |
|---------|-----------|----------|
| Dashboard load time | <2s P99 | <1.5s P99 |
| Recommendation gen | <5s P99 | <3s P99 |
| WB sync latency | <5 min | <1 min (Pro) |
| Uptime | 99.5% | 99.9% |
| CSAT | >4.0/5 | >4.3/5 |
