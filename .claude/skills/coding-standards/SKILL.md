---
name: coding-standards
description: >
  MarketFlow-specific coding standards для FastAPI backend и Next.js frontend.
  Включает паттерны из Architecture.md, известные gotchas стека и примеры правильного кода.
  Используется при генерации кода и code review.
version: "1.0"
maturity: production
---

# Coding Standards: MarketFlow

## Python / FastAPI Patterns

### Service Layer Pattern (MANDATORY)

```python
# ✅ CORRECT: thin route, fat service
# backend/app/api/v1/endpoints/recommendations.py
@router.get("/{store_id}/recommendations")
async def get_recommendations(
    store_id: UUID,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user),
    _: None = Depends(check_rate_limit),
) -> List[RecommendationSchema]:
    return await recommendation_service.get_active(db, store_id, current_user.org_id)

# ❌ WRONG: business logic in route
@router.get("/{store_id}/recommendations")
async def get_recommendations(store_id: UUID, db: AsyncSession = Depends(get_async_db)):
    recs = await db.execute(select(Recommendation).where(...))
    # filtering, scoring, sorting logic here — NO!
    return [r.to_dict() for r in recs]  # also wrong: raw dict
```

### Pydantic v2 Schema Pattern

```python
# ✅ CORRECT: Pydantic v2 syntax
from pydantic import BaseModel, ConfigDict, field_validator

class RecommendationSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)  # was orm_mode=True

    id: UUID
    type: Literal['pricing', 'bid', 'content', 'inventory', 'seo']
    action: str
    est_impact_rub: float
    confidence: float = Field(ge=0.0, le=1.0)

    @field_validator('est_impact_rub')
    @classmethod
    def impact_must_be_positive(cls, v: float) -> float:
        if v < 0:
            raise ValueError('Recommendation must have positive impact')
        return v

    def model_dump(self, **kwargs):  # use this, NOT .dict()
        return super().model_dump(**kwargs)
```

### AES-GCM Encryption Pattern

```python
# backend/app/core/security.py
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os, base64, logging

logger = logging.getLogger(__name__)

def encrypt_api_key(plaintext: str, key: bytes) -> str:
    """Encrypt marketplace API key. Returns base64(nonce + ciphertext)."""
    nonce = os.urandom(12)  # CRITICAL: fresh nonce every call
    aesgcm = AESGCM(key)
    ciphertext = aesgcm.encrypt(nonce, plaintext.encode('utf-8'), None)
    return base64.b64encode(nonce + ciphertext).decode('ascii')

def decrypt_api_key(stored: str, key: bytes) -> str:
    """Decrypt marketplace API key."""
    try:
        raw = base64.b64decode(stored)
        nonce, ciphertext = raw[:12], raw[12:]
        aesgcm = AESGCM(key)
        return aesgcm.decrypt(nonce, ciphertext, None).decode('utf-8')
    except Exception as e:
        logger.error("Failed to decrypt API key: [REDACTED_ERROR]")
        raise ValueError("Invalid or corrupted API key") from e

# NEVER log the plaintext key anywhere:
# ❌ logger.info(f"Using API key: {api_key}")
# ✅ logger.info("Using API key: [REDACTED]")
```

### TimescaleDB Query Pattern

```python
# ✅ CORRECT: time_bucket для dashboard aggregation
query = """
    SELECT
        time_bucket('1 hour', time) AS bucket,
        store_id,
        SUM(gmv) AS total_gmv,
        SUM(orders) AS total_orders,
        ROUND(AVG(conversion)::numeric, 4) AS avg_conversion
    FROM sales_metrics
    WHERE time > NOW() - INTERVAL :lookback
      AND store_id = :store_id
    GROUP BY bucket, store_id
    ORDER BY bucket DESC
    LIMIT :limit
"""
result = await db.execute(text(query), {
    "lookback": "30 days",
    "store_id": str(store_id),
    "limit": 720  # 30 days * 24 hours
})
```

### Celery Task Pattern

```python
# workers/tasks/marketplace_sync.py
from workers.celery_app import celery_app
from app.core.database import SyncSessionLocal  # sync session for workers!

@celery_app.task(
    bind=True,
    max_retries=3,
    default_retry_delay=60,
    name='tasks.sync_store_data'
)
def sync_store_data(self, store_id: str, platform: str) -> dict:
    """Sync marketplace data for a store. Sync task — no asyncio."""
    with SyncSessionLocal() as session:
        store = session.get(MarketplaceAccount, store_id)
        if not store or store.status != 'active':
            return {"status": "skipped", "reason": "store_inactive"}
        try:
            connector = get_connector(platform)
            data = connector.fetch_metrics(store_id)  # sync connector
            _save_metrics(session, store_id, data)
            return {"status": "success", "synced": len(data)}
        except MarketplaceRateLimitError as e:
            # Exponential backoff
            raise self.retry(exc=e, countdown=60 * (2 ** self.request.retries))
        except MarketplaceAPIError as e:
            logger.error(f"Marketplace sync failed for store {store_id}: {e}")
            store.status = 'error'
            session.commit()
            raise
```

## TypeScript / Next.js Patterns

### API Client Pattern

```typescript
// frontend/lib/api.ts — centralized API client
const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const response = await fetch(`${API_BASE}${endpoint}`, {
    credentials: 'include',  // CRITICAL: send httpOnly cookie
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  });

  if (response.status === 401) {
    // Global 401 handling — redirect to login
    window.location.href = '/login';
    throw new Error('Unauthorized');
  }

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail || 'API request failed');
  }

  return response.json();
}

// Usage:
export const recommendationsApi = {
  getActive: (storeId: string) =>
    apiRequest<Recommendation[]>(`/api/v1/stores/${storeId}/recommendations`),
  generate: (storeId: string) =>
    apiRequest<Recommendation[]>(`/api/v1/stores/${storeId}/recommendations/generate`, {
      method: 'POST'
    }),
};
```

### Dashboard Server Component Pattern

```typescript
// frontend/app/dashboard/[storeId]/page.tsx
// ✅ CORRECT: Server Component with no-store cache for real-time data
import { cookies } from 'next/headers';

export default async function DashboardPage({ params }: { params: { storeId: string } }) {
  // Fetch on server — no-store for fresh data
  const metrics = await fetch(
    `${process.env.API_URL}/api/v1/stores/${params.storeId}/metrics`,
    {
      cache: 'no-store',    // CRITICAL: real-time dashboard data
      headers: { Cookie: cookies().toString() }
    }
  ).then(r => r.json());

  return <DashboardClient initialData={metrics} storeId={params.storeId} />;
}
```

### React Query Hook Pattern

```typescript
// frontend/hooks/useRecommendations.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { recommendationsApi } from '@/lib/api/recommendations';

export function useRecommendations(storeId: string) {
  return useQuery({
    queryKey: ['recommendations', storeId],
    queryFn: () => recommendationsApi.getActive(storeId),
    staleTime: 5 * 60 * 1000,  // 5 min — recs don't change that fast
    refetchOnWindowFocus: false,
  });
}

export function useGenerateRecommendations(storeId: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: () => recommendationsApi.generate(storeId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recommendations', storeId] });
    },
  });
}
```

## Known Gotchas

| # | Gotcha | Fix |
|---|--------|-----|
| 1 | `model.dict()` deprecated Pydantic v2 | Use `model.model_dump()` |
| 2 | `orm_mode = True` deprecated | `model_config = ConfigDict(from_attributes=True)` |
| 3 | TimescaleDB + ALTER TABLE compression | Disable compression first |
| 4 | Multiple Celery Beat → duplicate tasks | ONE beat instance always |
| 5 | `\w` regex не матчит кириллицу | Use `\p{L}` with `/u` flag |
| 6 | `fetch()` кэшируется в Server Components | Add `{ cache: 'no-store' }` for real-time |
| 7 | AsyncSession в Celery task | Use separate SyncSessionLocal |
| 8 | AES nonce reuse = компрометация | `os.urandom(12)` каждый раз |
| 9 | QueryClient shared в SSR | New QueryClient per request |
| 10 | Redis set+expire = race condition | Use setex (atomic) |
