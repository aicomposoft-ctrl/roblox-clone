# Git Workflow — MarketFlow

## Branch Strategy

```
main                    # Production-ready only
├── develop             # Integration branch
│   ├── feat/[scope]-[name]     # Feature branches
│   ├── fix/[scope]-[name]      # Bug fixes
│   └── chore/[scope]-[name]    # Config, deps, CI
```

## Commit Convention

```
feat(scope): description      # New feature
fix(scope): description       # Bug fix
refactor(scope): description  # Restructure, no behavior change
test(scope): description      # Tests
docs(scope): description      # Documentation
chore(scope): description     # Build, CI, config
```

**Scopes:** `frontend`, `backend`, `workers`, `shared`, `db`, `ci`, `docs`

## Rules

1. **Commit after each logical unit** — не батчить несвязанные изменения
2. **Imperative mood** — "Add feature" не "Added feature"
3. **Never mix** migration + feature code в одном коммите
4. **Always test** перед push на develop
5. **Tag releases** — `git tag -a v2026.03.18 -m "Release description"`

## Git Hooks (pre-commit)

```bash
# .git/hooks/pre-commit — auto-generated
#!/bin/sh
# 1. Check for secrets
detect-secrets scan --baseline .secrets.baseline

# 2. Python linting
cd backend && python -m ruff check app/

# 3. TypeScript type check
cd frontend && npm run type-check --silent

# 4. No console.log in production code
grep -r "console\.log\|print(" backend/app frontend/app \
  --include="*.py" --include="*.ts" --include="*.tsx" \
  --exclude-dir=tests && echo "Remove debug logs!" && exit 1 || true
```

## Workflow Steps

### Feature Development

```bash
# 1. Start from develop
git checkout develop && git pull

# 2. Create feature branch
git checkout -b feat/backend-recommendation-engine

# 3. Implement with incremental commits
git add backend/app/services/recommendation_service.py
git commit -m "feat(backend): add recommendation score calculation"

git add tests/unit/test_recommendation_service.py
git commit -m "test(backend): unit tests for recommendation scoring"

# 4. Before PR: ensure CI passes
pytest tests/ && npm run type-check

# 5. Squash-merge to develop (optional)
git checkout develop
git merge --squash feat/backend-recommendation-engine
git commit -m "feat(backend): AI recommendation engine with scoring"
```

### Hotfix

```bash
git checkout main
git checkout -b fix/backend-bid-optimizer-drr-zero
# Fix + test
git commit -m "fix(backend): handle drr=0 in bid optimizer without division"
# PR to both main AND develop
```

## Release Process

```bash
# 1. Merge develop → main (after all tests pass)
git checkout main && git merge develop

# 2. Tag
git tag -a v$(date +%Y.%m.%d) -m "Release $(date +%Y-%m-%d): [features]"

# 3. Push
git push origin main --tags

# 4. Deploy
/deploy prod
```
