# 📋 PLAYBOOK SYNTHESIS: Easy Commerce Analog
**Режим:** VERIFIED (PARANOID, 0.99) | **Дата:** 2026-03-18

---

## PRODUCT DISCOVERY BRIEF (итог Phase 0)

**Компания-аналог:** Easy Commerce (easycomm.ru)
**URL:** https://easycomm.ru
**Индустрия:** MarketplaceTech / E-commerce Services
**География:** Россия (WB, Ozon, YM, MM)
**Выбранный CJM:** Гибрид A+B (Data-First Agency + SaaS PLG), с опцией роста к C (AI-Native)

---

## EXECUTIVE SUMMARY

Easy Commerce — лидер (#1 в 3 категориях Рейтинга Рунета) российского рынка full-service агентств для маркетплейсов. Компания уникально совмещает:
1. **Managed Services** (ведение магазинов на WB/Ozon/YM/MM)
2. **Proprietary SaaS** (CAT — аналитика, E-commerce Tool — единое окно)
3. **Data Intelligence** (>100k SKU проанализировано, бенчмарки по категориям)

**Ключевая возможность для аналога:** Ни один игрок не предлагает **AI-Native Full-Stack** — сочетание аналитики, исполнения и AI-автоматизации в единой платформе. Gap между «инструментами» (MPSTATS) и «агентствами» (Easy Commerce) = Blue Ocean.

---

## 90-DAY LAUNCH PLAYBOOK

### Дни 1-30: Foundation
- [ ] Зарегистрировать ООО, открыть счёт
- [ ] Нанять core team: CTO, Lead PM, 2 Marketplace Analyst
- [ ] Получить доступы к API: Ozon (открытый), WB (партнёрский), YM
- [ ] Разработать MVP CAT v0.1 (базовая аналитика 1 площадки)
- [ ] Заключить договора с первыми 2-3 beta-клиентами (managed services)
- [ ] Запустить Telegram-канал с контентом о трендах маркетплейсов

### Дни 31-60: PMF Discovery
- [ ] Провести 20+ customer discovery интервью с брендами и селлерами
- [ ] Запустить freemium версию CAT для 50 beta-пользователей
- [ ] Собрать первые кейсы с измеримыми результатами
- [ ] Протестировать 3 ценовых гипотезы
- [ ] Настроить реферальную механику в Telegram-боте
- [ ] Первая публикация кейса на Sostav.ru или vc.ru

### Дни 61-90: Первые деньги
- [ ] Конвертировать 10+ beta в платных SaaS-клиентов
- [ ] Подписать 3+ managed services контракта (100к₽+/мес каждый)
- [ ] Запустить AI-рекомендации v1 (на основе данных beta-пользователей)
- [ ] Подать заявку на Рейтинг Рунета
- [ ] Начать переговоры с потенциальными партнёрами (логистика, PIM-системы)
- [ ] Закрыть Pre-Seed раунд или привлечь angel-инвестора

---

## BS-CHECK (Brutal Honesty Review)

### ✅ Что реально сильно
1. Рынок действительно огромный (5.3 трлн₽ e-com, 1.26М продавцов)
2. Болевая точка реальная (комиссии 30%+, ДРР 18-30% — бренды теряют деньги)
3. Easy Commerce доказала PMF: #1 в рейтинге, кейсы с ×2-3 результатами
4. AI-автоматизация — настоящий тренд, не хайп (McKinsey $3-5T к 2030)

### ⚠️ Что сложнее чем кажется
1. **API зависимость:** WB постоянно ограничивает третьесторонние сервисы. Нет API = нет продукта. Нужен план B.
2. **Easy Commerce = сильный конкурент:** #1 в нише уже существует с данными 100k+ SKU. Нужна чёткая дифференциация, не «то же самое но чуть лучше».
3. **Sales cycle:** Managed services — это B2B с 2-4 месячным циклом. При зависимости только от этого — cash flow проблема на старте.
4. **AI Claims:** Все говорят «AI-powered». Нужно показать конкретный AI результат, а не просто заявить.

### ❌ Что нужно проверить ПЕРВЫМ
1. Готовы ли бренды платить за SaaS отдельно от managed? (или только пакет)
2. Какой реальный churn у Easy Commerce? (косвенный индикатор удовлетворённости)
3. Открыт ли рынок для ещё одного агентства или он winner-take-most?
4. Может ли WB/Ozon сами запустить аналог CAT (уже делают)?

---

## SPARC CONTEXT (передача в Phase 1)

```yaml
Project:
  name: "EasyComm Analog — AI-Native MarketplaceTech Platform"
  domain: "E-commerce SaaS + Managed Services"
  geography: "Russia (Wildberries, Ozon, Яндекс Маркет, MegaMarket)"

Architecture:
  pattern: "Distributed Monolith (Monorepo)"
  containers: "Docker + Docker Compose"
  infrastructure: "VPS (AdminVPS/HOSTKEY)"
  deploy: "Docker Compose direct deploy"
  ai_integration: "MCP servers"

Target Segments:
  primary: "Mid-market brands 50M-2B₽/year (managed services + SaaS)"
  secondary: "SMB sellers 5-50M₽/month (SaaS PLG)"
  tertiary: "Enterprise 2B₽+/year (AI-Native platform)"

Key Differentiator:
  blue_ocean: "AI-агент как виртуальный менеджер маркетплейса"
  triz_principle: "#10 Prior Action — AI подготавливает решения заранее"

Competitors:
  direct: ["Easy Commerce (#1)", "Kokoc/Кнопка (agency)"]
  indirect: ["MPSTATS (SaaS analytics)", "SellerFox", "SelSup"]

Monetization:
  saas_entry: "3,990₽/мес (Starter) → 24,990₽/мес (Pro)"
  managed: "100,000₽/мес (Basic) → 250,000₽+/мес (Full)"
  model: "Freemium PLG → Managed upsell"

Validated Cases (from Easy Commerce):
  - "Tom Tailor: +40% продаж за 8 недель"
  - "Сенежская: -87% расходов, +83% выручки за 3 недели"
  - "Бытовая химия: ×3 выручка за 1 месяц"

Micro-Trends (PARANOID 0.99):
  - "Agentic Commerce: McKinsey $3-5T к 2030"
  - "Marketplace Tools Market: CAGR 22.4% (ResearchAndMarkets)"
  - "Комиссии WB/Ozon: 30%+ в 2025 = триггер спроса"
  - "ACO (Agentic Commerce Optimization) заменяет SEO"
  - "Закон о платформенной экономике: вступает 01.10.2026"

CJM Winner: "Hybrid A+B: SaaS PLG entry + Managed upsell"
  aha_moment: "X-Ray аудит с шок-данными (A) + AI-план за 5 мин (B)"
  paywall: "14-day trial → подписка OR demo → managed контракт"
  core_loop: "Connect → AI tasks → Results → Habit → Referral"
```

---

## CONFIDENCE SUMMARY (All Modules)

| Модуль | Avg Confidence | Verified Facts |
|--------|:--------------:|:--------------:|
| M1: Fact Sheet | 0.92 | 31/41 |
| M2: Product & Customers | 0.88 | 25/32 |
| M3: Market & Competition | 0.88 | 25/31 |
| M4: Business & Finance | 0.72 | 12/18 |
| M5: Growth Engine | 0.84 | 15/20 |
| **ИТОГО Phase 0** | **0.85** | **108/142 (76%)** |

> Общий confidence 0.85 соответствует moderate threshold — достаточно для перехода к Phase 1 (SPARC Planning).
> Ключевые gaps требуют customer discovery интервью, а не дополнительного research.
