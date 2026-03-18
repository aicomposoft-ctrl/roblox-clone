# MarketFlow: Development Insights Index

> Error-First Protocol: `grep -i "keyword" myinsights/1nsights.md` перед дебаггингом

| ID | Краткое описание | Технология | Дата |
|----|-----------------|------------|------|
| INS-001 | TimescaleDB: cannot add column to compressed table | TimescaleDB | 2026-03-18 |
| INS-002 | Celery tasks и AsyncSession несовместимы | Celery, SQLAlchemy | 2026-03-18 |
| INS-003 | AES-GCM nonce повторное использование = компрометация | Python cryptography | 2026-03-18 |
| INS-004 | React Query QueryClient shared в SSR → state leak | Next.js, React Query | 2026-03-18 |
| INS-005 | Pydantic v2: orm_mode deprecated → ConfigDict | Pydantic v2 | 2026-03-18 |
| INS-006 | \w regex не матчит кириллицу | TypeScript/JavaScript | 2026-03-18 |
| INS-007 | fetch() кэшируется по умолчанию в Server Components | Next.js 15 | 2026-03-18 |
| INS-008 | Redis set+expire race condition → использовать setex | Redis | 2026-03-18 |
| INS-009 | Celery Beat: только ONE instance, иначе дублирование | Celery | 2026-03-18 |
| INS-010 | httpx: не переиспользовать client без connection pool | Python httpx | 2026-03-18 |

## Usage

```bash
# Найти инсайт по ключевому слову
grep -i "timescaledb\|celery\|pydantic" myinsights/1nsights.md

# Прочитать детали
cat myinsights/INS-001-timescaledb-compression-alter.md

# Добавить новый инсайт
/myinsights
```

## Capture Triggers

- Баг с неочевидной причиной (>30 мин отладки)
- Gotcha специфичное для стека MarketFlow
- Паттерн, который будет использован 3+ раз
- Security issue найденный в code review

## Pre-filled Gotchas Details

### INS-001: TimescaleDB compression + ALTER TABLE
**Ошибка:** `ERROR: cannot add column to compressed table`
```sql
-- Fix:
SELECT disable_compression_policy('sales_metrics');
ALTER TABLE sales_metrics ADD COLUMN new_col INTEGER DEFAULT 0;
SELECT add_compression_policy('sales_metrics', INTERVAL '90 days');
```

### INS-002: Celery + AsyncSession
**Проблема:** `RuntimeError: Task inside another task` или deadlock
```python
# Fix: отдельный sync session для workers
# workers/database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

SyncSessionLocal = sessionmaker(
    bind=create_engine(settings.SYNC_DATABASE_URL),
    expire_on_commit=False
)
```

### INS-003: AES-GCM нарушение уникальности nonce
**Проблема:** Повторный nonce с тем же ключом → атака GCM forgery → plaintext открывается
```python
# Fix: ВСЕГДА os.urandom(12) per encryption
nonce = os.urandom(12)  # CRITICAL: никогда не hardcode, не переиспользовать
ciphertext = aesgcm.encrypt(nonce, plaintext, None)
stored = base64.b64encode(nonce + ciphertext)
```

### INS-004: React Query SSR state leak
**Проблема:** Данные пользователя A видны пользователю B
```typescript
// Fix: new QueryClient() per request
// app/providers.tsx
function makeQueryClient() {
  return new QueryClient({ defaultOptions: { queries: { staleTime: 60 * 1000 } } })
}
```

### INS-005: Pydantic v2 orm_mode
**Проблема:** `AttributeError: 'orm_mode' is removed in V2`
```python
# Fix:
class RecommendationSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)  # was: orm_mode=True
    # .dict() → .model_dump()
    # .parse_obj() → .model_validate()
```

### INS-006: Кириллица + regex
**Проблема:** `/\w+/.test("Привет")` возвращает `false`
```typescript
// Fix: unicode property escapes
const hasRussianText = /\p{L}+/u.test(text)
const wordBoundary = /(?<!\p{L})\p{L}+(?!\p{L})/gu
```

### INS-007: Next.js 15 fetch() кэш
**Проблема:** Dashboard показывает данные 10-минутной давности
```typescript
// Fix: явный no-store для real-time данных
const data = await fetch('/api/metrics', { cache: 'no-store' })
// или
const data = await fetch('/api/metrics', { next: { revalidate: 0 } })
```

### INS-008: Redis atomic TTL
**Проблема:** set() + expire() не атомарны → TTL не ставится при сбое
```python
# Fix: setex или set с ex=
await redis.setex(key, ttl_seconds, value)
# или
await redis.set(key, value, ex=ttl_seconds)  # атомарно
```

### INS-009: Celery Beat дублирование
**Проблема:** Если запущено 2 beat процесса → каждая задача выполняется 2 раза
```yaml
# docker-compose.yml: только ONE beat service
celery-beat:
  command: celery -A workers.celery_app beat --loglevel=info
  deploy:
    replicas: 1  # CRITICAL: max 1
```

### INS-010: httpx connection pool
**Проблема:** `httpx.PoolTimeout` или file descriptor leak при большом числе запросов
```python
# Fix: lifespan client per app, не per-request
# backend/app/main.py
@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.AsyncClient(timeout=30.0, limits=httpx.Limits(max_connections=100))
    yield
    await app.state.http_client.aclose()
```
