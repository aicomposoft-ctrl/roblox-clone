# Completion: MarketFlow Platform
**Версия:** 1.0 | **Дата:** 2026-03-18

---

## DEPLOYMENT PLAN

### Pre-Deployment Checklist

**Code & Tests:**
- [ ] All unit tests passing (>80% coverage)
- [ ] Integration tests passing
- [ ] E2E tests passing for critical paths
- [ ] Security audit complete (dependency vulnerabilities, OWASP top-10)
- [ ] Performance tests: P99 < 2000ms for dashboard

**Infrastructure:**
- [ ] VPS provisioned (AdminVPS/HOSTKEY: 8 CPU, 32GB RAM, 500GB SSD)
- [ ] SSL certificates configured (Let's Encrypt)
- [ ] Firewall rules: only 80, 443, 22 exposed
- [ ] Backup storage VPS provisioned
- [ ] Monitoring VPS provisioned (optional for MVP)

**Data:**
- [ ] Database migrations run successfully on staging
- [ ] Seed data loaded (category benchmarks, initial rules)
- [ ] Backup verification: test restore from backup

**Security:**
- [ ] API keys encrypted (test encryption/decryption)
- [ ] JWT secrets rotated
- [ ] Docker secrets configured (not in .env files)
- [ ] 152-ФЗ compliance: confirm data stored in RU jurisdiction

**Rollback:**
- [ ] Previous Docker image tagged and available
- [ ] Database backup taken immediately before deploy
- [ ] Rollback procedure tested on staging

---

## DEPLOYMENT SEQUENCE

### Initial Deployment

```bash
# Step 1: Prepare VPS
ssh user@vps-ip
sudo apt update && sudo apt install -y docker.io docker-compose-plugin

# Step 2: Clone repo and configure
git clone https://github.com/org/marketflow.git
cd marketflow
cp .env.example .env.production
# Edit .env.production with real values

# Step 3: Configure Docker secrets
echo "db_password_value" | docker secret create db_password -
echo "redis_password_value" | docker secret create redis_password -
echo "jwt_secret_value" | docker secret create jwt_secret -

# Step 4: Build and start
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d

# Step 5: Database migrations
docker compose exec backend alembic upgrade head

# Step 6: Verify
docker compose ps  # All services should be "Up"
curl https://api.marketflow.ru/health  # Should return 200
```

### Rollback Procedure

```bash
# If issues detected after deployment:
docker compose down
docker compose -f docker-compose.prod.yml up -d --scale backend=0
# Restore database from backup if data was modified
pg_restore -d marketflow backup_20260318_before_deploy.dump
# Redeploy previous version
docker compose -f docker-compose.prod.yml up -d
```

---

## CI/CD CONFIGURATION

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run unit tests
        run: |
          cd backend
          pip install -r requirements.txt
          pytest tests/ -v --cov=app --cov-report=term-missing
      - name: Run frontend tests
        run: |
          cd frontend
          npm ci
          npm run test

  security_scan:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - name: OWASP dependency check
        run: |
          pip install safety
          safety check -r backend/requirements.txt
          cd frontend && npm audit

  build:
    runs-on: ubuntu-latest
    needs: [test, security_scan]
    steps:
      - name: Build Docker images
        run: |
          docker compose build
          docker tag marketflow-backend:latest marketflow-backend:${{ github.sha }}

  deploy:
    runs-on: ubuntu-latest
    needs: build
    environment: production
    steps:
      - name: Deploy to VPS
        env:
          VPS_HOST: ${{ secrets.VPS_HOST }}
          VPS_USER: ${{ secrets.VPS_USER }}
          VPS_KEY: ${{ secrets.VPS_SSH_KEY }}
        run: |
          ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "
            cd /opt/marketflow &&
            git pull &&
            docker compose pull &&
            docker compose up -d --build &&
            docker compose exec backend alembic upgrade head
          "
```

---

## MONITORING & ALERTING

### Key Metrics

| Метрика | Threshold | Alert Channel |
|---------|-----------|---------------|
| API response time P99 | > 2000ms | Telegram (dev chat) |
| Error rate (5xx) | > 1% | Telegram + Email |
| CPU usage (VPS) | > 85% | Telegram |
| RAM usage (VPS) | > 90% | Telegram |
| Disk usage | > 80% | Email |
| Database connections | > 18/20 | Telegram |
| Celery queue depth | > 1000 tasks | Telegram |
| Data sync failures | > 5 consecutive | Telegram |
| Marketplace API errors | > 10/hour | Telegram |

### Monitoring Stack

```yaml
# docker-compose.monitoring.yml
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    ports:
      - "3001:3000"

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"

  node_exporter:
    image: prom/node-exporter:latest
    # System metrics: CPU, RAM, Disk, Network
```

---

## LOGGING STRATEGY

```python
# Logging configuration (Python)
import logging
import json

class JSONFormatter(logging.Formatter):
    def format(self, record):
        return json.dumps({
            'timestamp': self.formatTime(record),
            'level': record.levelname,
            'service': 'marketflow-backend',
            'message': record.getMessage(),
            'extra': getattr(record, 'extra', {}),
            'trace_id': getattr(record, 'trace_id', None)
        })

# Log levels by component:
# - HTTP requests: INFO (request method, path, status, duration)
# - Marketplace sync: INFO (success), WARNING (partial), ERROR (failed)
# - AI generation: INFO (model used, tokens), WARNING (fallback used)
# - Bid changes: INFO (always log with full details)
# - Auth events: INFO (login, logout), WARNING (failed attempts)
# - Errors: ERROR with full stack trace + context

# Retention: 30 days in Loki, 90 days in S3 (cold storage)
```

---

## HANDOFF CHECKLISTS

### For Development Team
- [ ] Access to GitHub repository (main branch protected)
- [ ] Development environment setup guide (DEVELOPMENT_GUIDE.md)
- [ ] Local Docker Compose for development (`docker-compose.dev.yml`)
- [ ] Pre-commit hooks configured (black, flake8, isort for Python; ESLint for JS)
- [ ] Code review checklist (`.github/pull_request_template.md`)

### For QA Team
- [ ] Staging environment access
- [ ] Test accounts for all subscription tiers
- [ ] WB/Ozon sandbox accounts (or mock server)
- [ ] Bug reporting process: GitHub Issues with `bug` label
- [ ] Test case management (spreadsheet or TestRail)

### For Operations Team
- [ ] VPS SSH access
- [ ] Grafana dashboard access
- [ ] Runbook: "Marketplace sync failing"
- [ ] Runbook: "High memory usage"
- [ ] Runbook: "Database connection limit reached"
- [ ] Escalation: Telegram @devteam for P1 issues, Email for P2

---

## INFRASTRUCTURE AS CODE

```bash
# scripts/provision_vps.sh
#!/bin/bash
set -e

# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER

# Install Docker Compose plugin
apt install -y docker-compose-plugin

# Configure firewall
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable

# Configure automatic updates
apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Configure automatic Docker prune
echo "0 2 * * * docker system prune -f" | crontab -

echo "VPS provisioned successfully"
```
