# /deploy [env] — Deploy MarketFlow

Деплой на VPS (AdminVPS/HOSTKEY) через Docker Compose.

## Usage

```
/deploy staging     # Deploy to staging VPS
/deploy prod        # Deploy to production VPS
/deploy status      # Check deployment status
/deploy rollback    # Rollback to previous version
/deploy logs        # Show container logs
```

## Infrastructure

| Среда | Host | URL |
|-------|------|-----|
| Staging | AdminVPS staging | staging.marketflow.ru |
| Production | AdminVPS production | app.marketflow.ru |

## Pre-deploy Checklist

```
[ ] All tests pass: pytest --cov=app (coverage >= 80%)
[ ] Type check: npm run type-check (0 errors)
[ ] No secrets in code: grep -r "api_key\|password\|secret" backend/app/ --include="*.py"
[ ] Migration ready: alembic upgrade head (tested on staging)
[ ] .env.prod has all required vars set
[ ] Docker images build without errors
```

## Deploy to Staging

```bash
# 1. Build and push images
docker build -t marketflow-backend:latest ./backend
docker build -t marketflow-frontend:latest ./frontend

# 2. SSH to staging VPS
ssh deploy@staging-vps "cd /opt/marketflow && \
  git pull origin main && \
  docker compose pull && \
  docker compose up -d --no-deps --build backend frontend workers"

# 3. Run migrations
ssh deploy@staging-vps "cd /opt/marketflow && \
  docker compose exec backend alembic upgrade head"

# 4. Health check
curl https://staging.marketflow.ru/api/health
```

## Deploy to Production

```bash
# REQUIRED: Staging must pass all smoke tests first

# 1. Tag release
git tag -a v$(date +%Y.%m.%d) -m "Release $(date +%Y-%m-%d)"
git push origin --tags

# 2. Deploy with zero-downtime
ssh deploy@prod-vps "cd /opt/marketflow && \
  git pull origin main && \
  docker compose up -d --no-deps --build --scale backend=2"

# 3. DB migration (run once)
ssh deploy@prod-vps "docker compose exec backend alembic upgrade head"

# 4. Scale down to 1 after health check
ssh deploy@prod-vps "docker compose scale backend=1"

# 5. Verify
curl https://app.marketflow.ru/api/health
```

## Rollback

```bash
# Quick rollback (Docker)
ssh deploy@prod-vps "cd /opt/marketflow && \
  docker compose down && \
  git checkout HEAD~1 && \
  docker compose up -d"

# DB rollback (if needed)
ssh deploy@prod-vps "docker compose exec backend alembic downgrade -1"
```

## Environment Variables (.env.prod)

```env
# Required for production
DATABASE_URL=postgresql+asyncpg://user:pass@timescaledb:5432/marketflow
REDIS_URL=redis://redis:6379/0
ENCRYPTION_KEY=<base64-encoded-32-bytes>   # AES-256 key for API keys
JWT_SECRET_KEY=<random-64-chars>
ANTHROPIC_API_KEY=<sk-ant-...>
MINIO_ROOT_USER=marketflow
MINIO_ROOT_PASSWORD=<strong-password>

# Marketplace API base URLs (whitelist SSRF)
WB_API_BASE=https://api.wildberries.ru
OZON_API_BASE=https://api-seller.ozon.ru
YM_API_BASE=https://api.partner.market.yandex.ru
```

## Service Health Checks

```bash
# All services
/deploy status → runs:
  docker compose ps
  curl /api/health
  docker compose exec redis redis-cli PING
  docker compose exec backend python -c "from app.core.database import engine; print('DB OK')"
```

## Monitoring

- Celery tasks: `/api/admin/celery/status`
- TimescaleDB compression: `SELECT * FROM timescaledb_information.chunks LIMIT 5`
- Redis memory: `docker compose exec redis redis-cli INFO memory`

## 152-ФЗ Compliance Check

```bash
# Verify no data leaves RU jurisdiction
curl -I https://app.marketflow.ru | grep -i "x-data-location"
# Expected: x-data-location: RU
```
