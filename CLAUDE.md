# Devkit Stack — Claude Code Configuration

## Stack Overview

| Layer      | Technology                           |
|------------|--------------------------------------|
| Runtime    | Bun                                  |
| Backend    | ElysiaJS + Eden Treaty              |
| Frontend   | Next.js 15 (App Router, RSC)        |
| ORM        | Prisma 7                             |
| Database   | Neon Postgres                        |
| Auth       | Better Auth                          |
| UI         | shadcn/ui + Tailwind CSS 4          |
| Linter     | Biome                                |
| Testing    | bun:test                             |
| Git Hooks  | Lefthook                             |
| Container  | Docker                               |

## Monorepo Structure

```
apps/
  api/          # ElysiaJS backend
    src/
      controllers/   # Elysia route instances
      services/      # Business logic
      models/        # Data access + TypeBox schemas
      plugins/       # Shared Elysia plugins
    prisma/          # Schema & migrations
    generated/       # Prisma generated client
  web/          # Next.js frontend
    app/             # App Router pages & layouts
    components/      # React components (shadcn/ui)
    lib/             # Utils, Eden client, hooks
packages/       # Shared packages
```

## Coding Standards

- **Naming:** camelCase (variables, functions), PascalCase (types, components), kebab-case (files, folders)
- **Language:** TypeScript strict mode everywhere. English comments and commits only.
- **Exports:** Named exports preferred. Default exports only for Next.js pages/layouts.
- **Validation:** TypeBox (`t`) for Elysia routes, Zod for frontend forms and env vars.
- **Error handling:** Return-based (no throw). Use Result pattern or `status()` from elysia.
- **Imports:** Absolute paths via `@/` alias. Barrel exports in `index.ts` per module.

## Common Commands

```bash
# Development
bun dev                    # Start all apps
bun dev --filter api       # Backend only
bun dev --filter web       # Frontend only

# Linting & Formatting
biome check .              # Lint + format check
biome check --fix .        # Auto-fix
biome format --write .     # Format only

# Database (from apps/api/)
npx prisma generate        # Generate client
npx prisma db push         # Push schema changes
npx prisma migrate dev     # Create migration
npx prisma studio          # Open Prisma Studio

# Testing
bun test                   # Run all tests
bun test --watch           # Watch mode

# Docker
docker compose up -d       # Start services
docker compose down        # Stop services

# Git
lefthook run pre-commit    # Run pre-commit hooks manually
```

## Key Patterns

### Backend (ElysiaJS)
- **Controller** = Elysia route instance per domain (`controllers/user.ts`)
- **Service** = Business logic class, returns errors via `status()`
- **Model** = Prisma data-access + TypeBox schemas (`t`) + inferred types
- **Eden Treaty** = Type-safe API client from Elysia app type
- **Prisma 7** = Driver adapter required, generated client in `generated/prisma/`

### Frontend (Next.js)
- **RSC by default** — only add `"use client"` when needed
- **Async APIs** — `params`, `searchParams`, `cookies()`, `headers()` must be awaited
- **Server Components** fetch data directly (no API layer for reads)
- **Eden + React Query** for client-side data fetching
- **Server Actions** for mutations (forms and interactive UI)
- **shadcn/ui** components via `cn()` utility

## Suggested Agent Workflows

Use these workflows as guidelines — adapt based on task complexity.

### Full-Stack Feature
```
backend-dev → ux-designer → frontend-dev → code-reviewer
```

### Frontend Only
```
ux-designer → frontend-dev → code-reviewer
```

### Backend Only
```
backend-dev → code-reviewer
```

### UI/Design Task
```
ux-designer → frontend-dev → code-reviewer
```

> Agents are defined in `.claude/agents/`. Use `/agents` to list them.

## Context Hub

**Rule:** Every agent MUST read `.claude/context/session.md` at startup (if it exists) and update it before finishing.

This enables context transfer between agents in a workflow. The first agent creates the file; subsequent agents enrich it with their decisions and outputs.

See `.claude/context/README.md` for the session file format.

## References

- **Rules:** `.claude/rules/` — code-style, git, backend, frontend, testing
- **Agents:** `.claude/agents/` — backend-dev, ux-designer, frontend-dev, code-reviewer
- **Hooks:** `.claude/hooks/biome-format.sh` — auto Biome format on Write/Edit
- **Skills:** `.claude/skills/` — ElysiaJS, Prisma, Bun, Next.js, etc.
