---
description: Git conventions for commits, branches and PRs
globs:
---

# Git Conventions

## Commit Messages
Conventional Commits in English. Format:

```
type(scope): short description

Optional body with context.
```

### Types
- `feat` — New feature
- `fix` — Bug fix
- `refactor` — Code restructuring (no behavior change)
- `chore` — Tooling, config, dependencies
- `docs` — Documentation only
- `test` — Adding or updating tests
- `perf` — Performance improvement
- `ci` — CI/CD changes
- `style` — Formatting (no logic change)

### Scopes
- `api` — Backend (ElysiaJS)
- `web` — Frontend (Next.js)
- `db` — Prisma schema/migrations
- `auth` — Authentication
- `ui` — UI components
- `config` — Project configuration

### Examples
```
feat(api): add user registration endpoint
fix(web): resolve hydration mismatch on dashboard
chore(db): add index on users.email
refactor(api): extract auth middleware to shared module
```

## Branch Naming
```
feat/short-description
fix/short-description
chore/short-description
refactor/short-description
```

## Pull Requests
- Title matches conventional commit format
- Description includes: what changed, why, how to test
- Link related issues
- Keep PRs focused — one concern per PR
- Squash merge to main
