# Insights Capture — MarketFlow

## Protocol

После решения нетривиального бага, обнаружения gotcha или нахождения лучшего паттерна — запускай `/myinsights`.

## When to Capture

**Обязательно:**
- Баг с неочевидной причиной (потратил > 30 мин)
- Gotcha специфичное для MarketFlow/стека
- Паттерн который будет использован 3+ раз
- Security issue найденный в code review

**Не нужно:**
- Тривиальные typo fixes
- Стандартные CRUD операции
- Изменения документации

## Capture Format

### Index entry (myinsights/1nsights.md)

```markdown
| INS-NNN | [Краткое описание] | [технология] | [дата] |
```

### Detail file (myinsights/INS-NNN-[slug].md)

```markdown
# INS-NNN: [Краткое описание]
**Дата:** YYYY-MM-DD | **Технология:** Python/FastAPI/TimescaleDB/Next.js/Celery
**Контекст:** MarketFlow — [feature]

## Проблема
[Что пошло не так или почему стандартный подход не работал]

## Решение
```code
[Фрагмент кода с фиксом или паттерном]
```

## Почему это работает
[Объяснение root cause]

## Применимость
[Где ещё это может встретиться в MarketFlow]

## Ключевые слова
[для grep: timescaledb, celery, pydantic, jwt, aes-gcm, etc.]
```

## MarketFlow-Specific Gotchas (предзаполненные)

### INS-001: TimescaleDB compression + ALTER TABLE
**Проблема:** `ERROR: cannot add column to compressed table`
**Fix:** `SELECT disable_compression_policy('sales_metrics'); ALTER TABLE...; SELECT add_compression_policy('sales_metrics', INTERVAL '90 days');`

### INS-002: Celery + AsyncSession не совместимы напрямую
**Проблема:** Celery workers sync, FastAPI async — нельзя переиспользовать AsyncSession
**Fix:** Отдельный sync `SessionLocal` для workers

### INS-003: AES-GCM nonce повторное использование
**Проблема:** Повторный nonce с тем же ключом → катастрофическая утечка plaintext
**Fix:** Всегда `os.urandom(12)` per encryption, хранить как `nonce + ciphertext`

### INS-004: React Query + SSR state leak
**Проблема:** Shared QueryClient между запросами → данные утекают между юзерами
**Fix:** `new QueryClient()` per request в Server Components

### INS-005: Pydantic v2 orm_mode deprecated
**Проблема:** `orm_mode = True` → AttributeError в Pydantic v2
**Fix:** `model_config = ConfigDict(from_attributes=True)`

## Search Protocol

Перед дебаггингом:
```bash
grep -i "keyword" myinsights/1nsights.md
# Нашёл? → читай INS-NNN файл
# Не нашёл? → дебаггируй → после решения → /myinsights
```
