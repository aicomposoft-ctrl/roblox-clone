# /plan [feature] — Implementation Planning

Создаёт детальный план реализации фичи на основе SPARC-документации.

## Usage

```
/plan multi-platform-dashboard
/plan bid-optimizer
/plan xray-audit
/plan review-responder
```

## Execution

### Step 1: Read relevant SPARC docs

Параллельно:
- `docs/PRD.md` → User Stories для этой фичи
- `docs/Specification.md` → Acceptance Criteria
- `docs/Pseudocode.md` → Алгоритмы и data structures
- `docs/Architecture.md` → Сервисы и интеграции
- `docs/Refinement.md` → Edge cases и testing strategy

### Step 2: Create plan file

Сохраняем план в `docs/plans/[feature]-plan.md`.

**Структура плана:**

```markdown
# Plan: [Feature Name]
**Дата:** [date] | **Версия:** 1.0

## 1. User Stories (from PRD.md)
[Paste relevant stories]

## 2. Algorithm (from Pseudocode.md)
[Paste algorithm]

## 3. Implementation Tasks
### Backend (FastAPI)
- [ ] Model: [entity] → `backend/app/models/[name].py`
- [ ] Schema: Pydantic schemas → `backend/app/schemas/[name].py`
- [ ] Service: Business logic → `backend/app/services/[name]_service.py`
- [ ] Route: API endpoint → `backend/app/api/v1/endpoints/[name].py`
- [ ] Migration: `alembic revision --autogenerate -m "add_[table]"`

### Frontend (Next.js)
- [ ] Types → `frontend/types/[name].ts`
- [ ] API client → `frontend/lib/api/[name].ts`
- [ ] Component → `frontend/components/[name]/`
- [ ] Page → `frontend/app/[route]/page.tsx`

### Workers (Celery)
- [ ] Task → `workers/tasks/[name]_tasks.py`
- [ ] Beat schedule → update `workers/celery_app.py`

## 4. Tests (from Refinement.md)
- [ ] Unit: `tests/unit/test_[name].py`
- [ ] Integration: `tests/integration/test_[name]_api.py`
- [ ] E2E: `tests/e2e/test_[name]_journey.py`

## 5. Edge Cases (from Refinement.md)
[Paste relevant edge cases]

## 6. Implementation Order
1. DB model + migration
2. Pydantic schemas
3. Service layer (with tests)
4. API routes (with integration tests)
5. Frontend types + API client
6. UI components
7. E2E tests

## 7. Estimated Checkpoints
- Checkpoint A: Backend + tests green
- Checkpoint B: Frontend connected to backend
- Checkpoint C: E2E passing + edge cases handled
```

### Step 3: Display plan

Показываем план и спрашиваем:
```
═══════════════════════════════════════════════════════════════
📋 PLAN: [feature]
Задач: [N] backend + [N] frontend + [N] tests
Сохранено: docs/plans/[feature]-plan.md
⏸️ "реализуй" — start implementation | "уточни [пункт]" — refine
═══════════════════════════════════════════════════════════════
```

### Step 4: Auto-commit plan

```bash
git add docs/plans/[feature]-plan.md
git commit -m "docs(plans): implementation plan for [feature]"
```

## Quick Commands

| Command | Action |
|---------|--------|
| `/plan list` | List all plans in docs/plans/ |
| `/plan show [name]` | Show specific plan |
| `/plan [feature]` | Create new plan |
