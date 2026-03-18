# Coding Style — MarketFlow

## Python / FastAPI (backend/, workers/)

### Naming
- Files: `snake_case.py`
- Classes: `PascalCase`
- Functions/variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Private methods: `_leading_underscore`

### File Organization
```
backend/
  app/
    api/v1/        # Route handlers (thin — delegate to services)
    services/      # Business logic
    models/        # SQLAlchemy ORM models
    schemas/       # Pydantic request/response models
    workers/       # Celery tasks
    core/          # Config, security, dependencies
    utils/         # Pure helper functions
```

### FastAPI Patterns
- Route handlers MUST be thin — delegate all logic to services
- Use `Depends()` for dependency injection (DB session, auth, rate limit)
- Return Pydantic models — never raw dicts from routes
- Async routes for I/O-bound endpoints; sync for CPU-bound tasks in Celery
- Use `HTTPException` for client errors; let middleware handle 500s

### Type Hints
- Required on all function signatures (Python 3.12 native types)
- Use `Optional[X]` as `X | None` (Python 3.10+ union syntax)
- Pydantic v2 — use `model_validator`, `field_validator` not v1 decorators

### Async
- `async def` for all FastAPI routes and DB calls (AsyncSession)
- `await` every async call — never fire-and-forget without background task
- Celery tasks are sync — use `asyncio.run()` if async needed inside

### Database
- Use Alembic for ALL schema changes — never manual ALTER TABLE
- SQLAlchemy AsyncSession via `async with session.begin()`
- TimescaleDB hypertables for time-series metrics (use `time_bucket()`)
- Index all foreign keys and high-cardinality filter columns

## TypeScript / Next.js (frontend/)

### Naming
- Components: `PascalCase.tsx`
- Hooks: `useHookName.ts`
- Utils: `camelCase.ts`
- API clients: `api/[resource].ts`
- Types: `PascalCase` interfaces in `types/`

### File Organization
```
frontend/
  app/               # Next.js App Router pages
  components/        # Reusable UI components
  hooks/             # Custom React hooks
  lib/               # API client, utils
  types/             # Shared TypeScript types
  public/            # Static assets
```

### Next.js App Router
- Server Components by default — use `"use client"` only when needed
- Data fetching in Server Components via `fetch()` with cache control
- Use `loading.tsx` and `error.tsx` for async page states
- API routes in `app/api/` — only for BFF patterns; prefer calling FastAPI directly

### State Management
- Server state: React Query (`@tanstack/react-query`)
- Client state: `useState`/`useReducer` — avoid global state stores for MVP
- Forms: React Hook Form + Zod validation

### API Calls
- All API calls via centralized `lib/api.ts` client
- Include credentials (`credentials: 'include'`) for cookie-based auth
- Handle 401 globally — redirect to login

## Known Gotchas

### Python / FastAPI
- **Alembic async**: Use `run_sync` for metadata operations in async context. `engine.begin()` not `engine.connect()` for DDL.
- **Celery + async**: Celery workers run sync. Don't use `asyncio.run()` inside tasks directly — use `loop.run_until_complete()` or a sync DB session.
- **Pydantic v2**: `model.dict()` is deprecated — use `model.model_dump()`. `orm_mode=True` → `model_config = ConfigDict(from_attributes=True)`.
- **TimescaleDB**: `time_bucket('1 hour', time_col)` requires the column to be a `TIMESTAMPTZ`. Compression must be disabled before adding columns.
- **AES-GCM nonce**: Generate fresh 12-byte nonce per encryption. Store as `nonce + ciphertext` combined bytes. Never reuse nonces with the same key.
- **httpx async**: Use `async with httpx.AsyncClient() as client:` — don't reuse client across requests without connection pool management.

### TypeScript / Next.js
- **App Router caching**: `fetch()` is cached by default in Server Components. Add `{ cache: 'no-store' }` for real-time data (dashboard metrics).
- **Cookies in Server Components**: Use `cookies()` from `next/headers` — only works in Server Components, not in Client Components.
- **React Query + SSR**: Initialize QueryClient per request in Server Components to avoid state leaking between users.
- **`\w` regex**: Does NOT match Cyrillic characters. Use `\p{L}` with `/u` flag for Russian text matching.

### Infrastructure
- **Redis TTL**: `setex` vs `expire` — always set TTL at creation time, not separately, to avoid race conditions.
- **Docker health checks**: TimescaleDB takes 10-15s to initialize. Set `--health-retries 10` and `--health-interval 5s`.
- **Celery beat**: Run only ONE beat instance — multiple instances cause duplicate task execution.
