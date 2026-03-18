#!/bin/bash
# MarketFlow — Codespaces Post-Create Setup Script
# Runs after devcontainer is created

set -e  # Exit on error

echo "🚀 Setting up MarketFlow development environment..."
WORKDIR=$(pwd)

# ── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[setup]${NC} $1"; }
ok()  { echo -e "${GREEN}[ok]${NC} $1"; }
warn(){ echo -e "${YELLOW}[warn]${NC} $1"; }

# ── 1. System packages ───────────────────────────────────────────────────────
log "Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    libpq-dev \
    gcc \
    curl \
    wget \
    jq \
    postgresql-client \
    redis-tools \
    make
ok "System packages installed"

# ── 2. Python dependencies ───────────────────────────────────────────────────
log "Setting up Python environment..."
pip install --upgrade pip --quiet

if [ -f "backend/requirements.txt" ]; then
    log "Installing backend dependencies..."
    pip install -r backend/requirements.txt --quiet
    ok "Backend Python deps installed"
else
    warn "backend/requirements.txt not found — installing base deps"
    pip install --quiet \
        fastapi==0.115.0 \
        uvicorn[standard]==0.30.0 \
        sqlalchemy[asyncio]==2.0.36 \
        asyncpg==0.29.0 \
        alembic==1.13.0 \
        pydantic==2.9.0 \
        pydantic-settings==2.5.0 \
        python-jose[cryptography]==3.3.0 \
        cryptography==43.0.0 \
        redis==5.1.0 \
        celery==5.3.6 \
        anthropic==0.34.0 \
        httpx==0.27.0 \
        python-multipart==0.0.12 \
        catboost==1.2.7 \
        pytest==8.3.0 \
        pytest-asyncio==0.24.0 \
        pytest-cov==5.0.0 \
        black==24.10.0 \
        ruff==0.7.0 \
        mypy==1.11.0 \
        detect-secrets==1.5.0
    ok "Base Python deps installed"
fi

# ── 3. Node.js dependencies ─────────────────────────────────────────────────
if [ -f "frontend/package.json" ]; then
    log "Installing frontend dependencies..."
    cd frontend && npm install --silent
    cd "$WORKDIR"
    ok "Frontend deps installed"
else
    warn "frontend/package.json not found — skipping"
fi

# ── 4. Environment file ──────────────────────────────────────────────────────
log "Setting up .env..."
if [ ! -f ".env" ]; then
    cp .env.example .env

    # Auto-generate secrets
    ENCRYPTION_KEY=$(python3 -c "import os,base64; print(base64.b64encode(os.urandom(32)).decode())")
    JWT_SECRET_KEY=$(openssl rand -hex 64)

    sed -i "s|ENCRYPTION_KEY=GENERATE_ME_32_BYTES_BASE64|ENCRYPTION_KEY=${ENCRYPTION_KEY}|g" .env
    sed -i "s|JWT_SECRET_KEY=GENERATE_ME_64_HEX_CHARS|JWT_SECRET_KEY=${JWT_SECRET_KEY}|g" .env
    sed -i "s|POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD|POSTGRES_PASSWORD=marketflow_dev_2026|g" .env
    sed -i "s|marketflow:CHANGE_ME_STRONG_PASSWORD@timescaledb|marketflow:marketflow_dev_2026@localhost|g" .env
    sed -i "s|MINIO_ROOT_PASSWORD=CHANGE_ME_MINIO_PASSWORD|MINIO_ROOT_PASSWORD=marketflow_minio|g" .env
    sed -i "s|APP_ENV=development|APP_ENV=development|g" .env

    ok ".env created with auto-generated secrets"
    warn "Add your ANTHROPIC_API_KEY to .env manually!"
else
    ok ".env already exists — skipping"
fi

# ── 5. Start services via Docker Compose ─────────────────────────────────────
log "Starting supporting services (TimescaleDB, Redis, MinIO)..."
if command -v docker &> /dev/null; then
    # Start only DB services (not full app)
    docker compose up -d timescaledb redis minio 2>/dev/null || warn "Docker services may need manual start"

    log "Waiting for TimescaleDB to be ready (may take 15s)..."
    for i in {1..20}; do
        if docker compose exec -T timescaledb pg_isready -U marketflow -d marketflow &>/dev/null 2>&1; then
            ok "TimescaleDB ready"
            break
        fi
        sleep 2
        echo -n "."
    done

    ok "Services started"
else
    warn "Docker not available — start services manually: docker compose up -d timescaledb redis minio"
fi

# ── 6. Git configuration ─────────────────────────────────────────────────────
log "Configuring git..."
git config --global core.autocrlf input
git config --global pull.rebase false

# detect-secrets baseline
if command -v detect-secrets &> /dev/null; then
    if [ ! -f ".secrets.baseline" ]; then
        detect-secrets scan > .secrets.baseline 2>/dev/null || true
    fi
fi
ok "Git configured"

# ── 7. Create project structure (if not exists) ───────────────────────────────
log "Creating project directories..."
mkdir -p \
    backend/app/{api/v1/endpoints,services,models,schemas,core,utils} \
    backend/tests/{unit,integration,e2e,load} \
    frontend/app/{dashboard,xray,\(auth\)} \
    frontend/{components,hooks,lib/api,types,public} \
    workers/tasks \
    migrations/versions \
    nginx \
    db/init \
    docs/{features,plans}

# Create __init__.py files for Python packages
find backend/app -type d -exec touch {}/__init__.py \;
find workers -type d -exec touch {}/__init__.py \;
ok "Project structure created"

# ── 8. Summary ───────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ MarketFlow dev environment ready!${NC}"
echo ""
echo "📍 Services:"
echo "   Frontend:    http://localhost:3000  (after: cd frontend && npm run dev)"
echo "   Backend API: http://localhost:8000  (after: cd backend && uvicorn app.main:app --reload)"
echo "   API Docs:    http://localhost:8000/docs"
echo "   MinIO:       http://localhost:9001"
echo ""
echo "🚀 Quick start:"
echo "   1. Add ANTHROPIC_API_KEY to .env"
echo "   2. docker compose up -d"
echo "   3. docker compose exec backend alembic upgrade head"
echo "   4. Open terminals for backend + frontend"
echo ""
echo "📋 Claude Code commands:"
echo "   /start     — bootstrap project"
echo "   /plan      — plan a feature"
echo "   /test      — run tests"
echo ""
echo -e "${YELLOW}⚠️  Add ANTHROPIC_API_KEY to .env before starting backend!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
