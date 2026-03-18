# /start — Bootstrap MarketFlow Project

Bootstrap проекта MarketFlow из SPARC-документации.

## Execution

### Phase 1: Read SPARC docs
Параллельно читаем все документы из `docs/`:
- `docs/PRD.md` — продукт, фичи, персоны
- `docs/Architecture.md` — стек, сервисы, диаграммы
- `docs/Specification.md` — функциональные требования
- `docs/Pseudocode.md` — алгоритмы и структуры данных

### Phase 2: Setup project structure

Создаём структуру директорий согласно Architecture.md:

```
marketflow/
├── frontend/           # Next.js 15 (App Router)
│   ├── app/
│   ├── components/
│   ├── hooks/
│   ├── lib/
│   └── types/
├── backend/            # FastAPI + Python 3.12
│   └── app/
│       ├── api/v1/
│       ├── services/
│       ├── models/
│       ├── schemas/
│       ├── workers/
│       ├── core/
│       └── utils/
├── workers/            # Celery tasks
├── shared/             # Shared types & schemas
├── docker-compose.yml
├── Dockerfile
└── .env.example
```

### Phase 3: Scaffold core files

Создаём базовые файлы:

**Backend:**
- `backend/app/main.py` — FastAPI entrypoint
- `backend/app/core/config.py` — Settings (Pydantic BaseSettings)
- `backend/app/core/security.py` — JWT + AES-GCM encrypt/decrypt
- `backend/app/core/database.py` — AsyncSession + TimescaleDB setup
- `backend/app/api/v1/router.py` — Route aggregator
- `backend/requirements.txt` — Python deps

**Frontend:**
- `frontend/app/layout.tsx` — Root layout
- `frontend/app/page.tsx` — Landing page shell
- `frontend/app/dashboard/page.tsx` — Dashboard shell
- `frontend/lib/api.ts` — API client (fetch + credentials)

**Infrastructure:**
- `docker-compose.yml` — All services
- `.env.example` — Environment variables template
- `alembic.ini` + `migrations/` — DB migrations setup

### Phase 4: Verify

```bash
# Backend health check
cd backend && pip install -r requirements.txt && python -c "from app.main import app; print('OK')"

# Frontend type check
cd frontend && npm install && npm run type-check
```

### Phase 5: Git initial commit

```bash
git add .
git commit -m "feat(backend): scaffold FastAPI + TimescaleDB + Celery"
```

## Success Criteria
- [ ] All directories created
- [ ] Core files have valid syntax
- [ ] docker-compose.yml starts without errors
- [ ] No secrets in code (only in .env.example placeholders)
