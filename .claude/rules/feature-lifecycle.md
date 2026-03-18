# Feature Lifecycle — MarketFlow

## Standard Feature Lifecycle (/feature command)

```
/feature [name]
  Phase 0: PRE-FLIGHT — проверка скиллов
  Phase 1: PLAN — sparc-prd-mini → docs/features/[name]/sparc/
  Phase 2: VALIDATE — 5-agent swarm (min score 70/100)
  Phase 3: IMPLEMENT — из validated SPARC docs (no hallucination)
  Phase 4: REVIEW — brutal-honesty-review swarm
```

## Feature Prioritization (from PRD.md)

### MVP Features (P0 — реализуются первыми)
1. `multi-platform-dashboard` — единый дашборд WB+Ozon
2. `ai-recommendations` — топ-3 задачи с impact estimate
3. `seo-optimizer` — AI-оптимизация карточек товаров
4. `bid-manager` — управление ставками WB/Ozon

### v1.0 Features (P0 after MVP)
5. `bid-autopilot` — автономный AI bid optimizer
6. `content-generator` — AI-генерация описаний 50 SKU за 10 мин
7. `xray-audit` — бесплатный аудит (лид-магнит)

### v1.0 Features (P1)
8. `competitor-analytics` — позиции конкурентов в категории
9. `review-responder` — AI-ответы на отзывы
10. `telegram-integration` — алерты без входа в кабинет

## Feature Doc Structure

```
docs/features/[name]/
├── sparc/
│   ├── PRD.md              # Feature-level PRD
│   ├── Specification.md    # AC + NFR
│   ├── Pseudocode.md       # Algorithms
│   ├── Architecture.md     # Feature architecture decisions
│   └── Refinement.md       # Edge cases + tests
├── validation-report.md    # Phase 2 output
└── implementation-notes.md # Phase 3+4 notes
```

## Validation Gate (Phase 2)

| Агент | Критерий | Блокирует |
|-------|----------|-----------|
| validator-stories | INVEST score ≥70 | ✅ |
| validator-acceptance | SMART testability ≥70 | ✅ |
| validator-architecture | Совместимость с Architecture.md | ✅ |
| validator-pseudocode | Покрытие всех stories | ✅ |
| validator-coherence | Cross-doc consistency | ✅ |

**Exit criteria:** Нет BLOCKED, средний ≥70, нет противоречий

## Implementation Rules

### NEVER implement without validated docs
- Phase 3 начинается ТОЛЬКО после 🟢 READY из Phase 2
- Каждая реализованная функция ссылается на алгоритм из Pseudocode.md
- Каждый edge case из Refinement.md покрыт тестом

### Commit discipline во время фичи
```bash
# После DB model + migration
git commit -m "feat(db): add [entity] model and migration"

# После service layer
git commit -m "feat(backend): [feature] service with core business logic"

# После API routes
git commit -m "feat(backend): [feature] REST endpoints"

# После frontend
git commit -m "feat(frontend): [feature] UI components and page"

# После tests
git commit -m "test([scope]): [feature] unit + integration tests"
```

## Feature Estimation Template

| Component | Tasks | Points |
|-----------|-------|--------|
| DB model + migration | 2 | 1 SP |
| Pydantic schemas | 2 | 0.5 SP |
| Service layer | 3-5 | 2 SP |
| API routes | 2-3 | 1 SP |
| Frontend components | 3-5 | 2 SP |
| Unit tests | N | 1 SP |
| Integration tests | 2-3 | 1 SP |
| E2E tests | 1-2 | 1 SP |
| **Total** | | **~9.5 SP** |

## /next Command Integration

```bash
/next           # Show sprint progress + top 3 next features from roadmap
/next [id]      # Mark feature done, show what's unblocked
/next update    # Scan codebase, suggest status updates
```
