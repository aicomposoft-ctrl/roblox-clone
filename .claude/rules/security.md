# Security Rules — MarketFlow

## Authentication

- JWT tokens MUST be stored in httpOnly cookies (SameSite=Strict)
- Token TTL: access=24h, refresh=7d
- Refresh endpoint: `POST /auth/refresh` — check refresh token validity before issuing new pair
- NEVER expose JWT tokens in URL parameters, localStorage, or response body logs
- On logout: invalidate refresh token in Redis (allowlist pattern)

## API Key Management (Marketplace Keys)

- WB/Ozon/YM API keys MUST be encrypted with AES-256-GCM before storing
- Use Python `cryptography` library: `from cryptography.hazmat.primitives.ciphers.aead import AESGCM`
- Encryption key stored in env var `ENCRYPTION_KEY` (base64-encoded 32 bytes)
- Keys stored in DB as `ciphertext||nonce` — NEVER plaintext
- NEVER log API keys — redact in all log output as `[REDACTED]`
- NEVER include API keys in error messages, stack traces, or HTTP responses
- See `.claude/rules/secrets-management.md` for full protocol

## Input Validation

- Validate all user inputs at API boundary (FastAPI Pydantic models)
- Use parameterized queries everywhere — NEVER string interpolation in SQL
- Sanitize HTML content before rendering (strip scripts)
- Validate marketplace seller IDs are numeric strings before making external calls
- File uploads (if any): validate MIME type + extension + size limit

## SSRF Protection

- Whitelist external HTTP calls to marketplace domains only:
  ```python
  ALLOWED_DOMAINS = ["api.wildberries.ru", "api-seller.ozon.ru", "api.partner.market.yandex.ru"]
  ```
- Block requests to RFC1918 ranges (10.x, 172.16.x, 192.168.x) and localhost
- Use `httpx` with explicit timeout and domain validation

## Rate Limiting

- Unauthenticated X-Ray audits: 3/IP/hour (Redis sliding window)
- Authenticated API: 100 req/user/min
- Marketplace API proxy calls: respect platform rate limits (WB: 60 req/min)
- Rate limit headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`

## Data Residency (152-ФЗ)

- All user data MUST be stored on AdminVPS/HOSTKEY (RU jurisdiction)
- No data replication to non-RU cloud providers
- Audit log retention: 1 year minimum
- PD deletion: complete removal within 30 days of request

## Transport Security

- HTTPS mandatory (Nginx TLS termination)
- HSTS header: `max-age=31536000; includeSubDomains`
- CSP header: restrict script-src to self
- X-Frame-Options: DENY

## Dependency Security

- Run `pip-audit` on every CI build for Python deps
- Run `npm audit` on every CI build for frontend deps
- Block merges with HIGH severity vulnerabilities (CVSS >= 7.0)

## Secrets in Code

- NEVER commit secrets to git
- Use `.env` files locally, never committed (in .gitignore)
- Production secrets via environment variables only
- Pre-commit hook: `detect-secrets` scan before every commit
