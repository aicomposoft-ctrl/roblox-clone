# Secrets Management — MarketFlow

## Overview

MarketFlow хранит 4 типа секретов:
1. **JWT секреты** — генерация/валидация токенов
2. **ENCRYPTION_KEY** — AES-256-GCM для marketplace API keys
3. **Marketplace API keys** — WB/Ozon/YM токены пользователей (хранятся зашифрованными)
4. **Anthropic API key** — для AI-фич

## Encryption Protocol (AES-256-GCM)

```python
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os
import base64

def encrypt_api_key(plaintext: str, encryption_key: bytes) -> str:
    """Encrypt marketplace API key for storage."""
    aesgcm = AESGCM(encryption_key)
    nonce = os.urandom(12)        # ALWAYS fresh nonce per encryption
    ciphertext = aesgcm.encrypt(nonce, plaintext.encode(), None)
    # Store as base64(nonce + ciphertext)
    return base64.b64encode(nonce + ciphertext).decode()

def decrypt_api_key(stored: str, encryption_key: bytes) -> str:
    """Decrypt marketplace API key for use."""
    raw = base64.b64decode(stored)
    nonce = raw[:12]
    ciphertext = raw[12:]
    aesgcm = AESGCM(encryption_key)
    return aesgcm.decrypt(nonce, ciphertext, None).decode()
```

**CRITICAL:** Nonce повторное использование с тем же ключом = полная компрометация.
Генерируй `os.urandom(12)` каждый раз при шифровании.

## Key Storage

| Секрет | Где хранится | Формат | Ротация |
|--------|-------------|--------|---------|
| `ENCRYPTION_KEY` | .env / VPS env var | base64(32 bytes) | Ежегодно |
| `JWT_SECRET_KEY` | .env / VPS env var | random 64 chars | При компрометации |
| `ANTHROPIC_API_KEY` | .env / VPS env var | sk-ant-... | По необходимости |
| WB/Ozon API keys | PostgreSQL (зашифрованы) | base64(nonce+ciphertext) | Пользователь обновляет |

## Environment Variables (.env.example)

```env
# Database
DATABASE_URL=postgresql+asyncpg://marketflow:CHANGE_ME@timescaledb:5432/marketflow

# Security
ENCRYPTION_KEY=GENERATE_WITH: python -c "import os,base64; print(base64.b64encode(os.urandom(32)).decode())"
JWT_SECRET_KEY=GENERATE_WITH: openssl rand -hex 64
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_HOURS=24
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# AI
ANTHROPIC_API_KEY=sk-ant-...

# Redis
REDIS_URL=redis://redis:6379/0

# MinIO
MINIO_ROOT_USER=marketflow
MINIO_ROOT_PASSWORD=CHANGE_ME

# Marketplace API whitelisted domains (SSRF protection)
WB_API_BASE=https://api.wildberries.ru
OZON_API_BASE=https://api-seller.ozon.ru
YM_API_BASE=https://api.partner.market.yandex.ru
MM_API_BASE=https://api.megamarket.ru
```

## Rules

### Code Rules
- ❌ NEVER: `api_key = "wbtoken123..."` в коде
- ❌ NEVER: `logger.info(f"API key: {api_key}")` — всегда `[REDACTED]`
- ❌ NEVER: API key в HTTP response body или URL параметрах
- ❌ NEVER: plaintext keys в PostgreSQL
- ✅ ALWAYS: зашифровать перед сохранением в DB
- ✅ ALWAYS: расшифровывать только в момент использования (не хранить расшифрованное в памяти долго)

### Git Rules
- `.env` файлы в `.gitignore` (только `.env.example` в репо)
- Pre-commit hook: `detect-secrets scan` перед каждым коммитом
- `.secrets.baseline` обновляется при добавлении new false positives

## Generating Keys

```bash
# ENCRYPTION_KEY (AES-256 = 32 bytes)
python -c "import os,base64; print(base64.b64encode(os.urandom(32)).decode())"

# JWT_SECRET_KEY
openssl rand -hex 64

# Check for accidental secrets in code
grep -rn "sk-ant-\|wbtoken\|Bearer " backend/app/ --include="*.py" | grep -v "test\|example\|placeholder"
```

## Key Rotation Protocol

```
1. Generate new ENCRYPTION_KEY
2. Run migration script to re-encrypt all stored API keys:
   python scripts/rotate_encryption_key.py --old-key $OLD_KEY --new-key $NEW_KEY
3. Update .env on VPS: ssh deploy@vps "echo ENCRYPTION_KEY=<new> >> .env"
4. Restart services: docker compose restart backend celery
5. Verify: test marketplace connection for 5 accounts
6. Log rotation in audit trail
```
