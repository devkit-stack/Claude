# Context Hub

The Context Hub enables context transfer between agents during a workflow session.

## How It Works

1. The **first agent** in a workflow creates `.claude/context/session.md`
2. Each subsequent agent **reads** session.md at startup to understand prior decisions
3. Each agent **updates** session.md before finishing with their own work summary
4. The **code-reviewer** reads everything to review in full context

## Session File Format

```markdown
# Session Context

## Backend (backend-dev)
- Created endpoints: POST /api/users, GET /api/users/:id
- Prisma models: User, Profile
- Decisions: pagination with cursor-based, auth via Better Auth middleware
- Schema changes: added apps/api/prisma/schema.prisma

## UX/UI (ux-designer)
- Components designed: UserCard, UserList, UserProfile
- Layout: dashboard with sidebar, responsive breakpoints at md/lg
- shadcn components used: Card, Avatar, Table, Badge
- Design decisions: mobile-first, dark mode support

## Frontend (frontend-dev)
- Pages created: /dashboard/users, /dashboard/users/[id]
- Eden client setup in lib/eden.ts
- React Query hooks in hooks/useUsers.ts
- Server Components for lists, Client Components for forms

## Review Notes (code-reviewer)
- [results of review]
```

## Lifecycle

- `session.md` is **not tracked by git** (listed in `.gitignore`)
- Delete it between sessions to start fresh
- Each workflow creates a new session context
- The file grows as agents contribute — this is intentional

## Rules

- Every agent **MUST** read session.md at startup (if it exists)
- Every agent **MUST** update session.md before finishing
- If the file doesn't exist, the first agent creates it
- Never delete another agent's section — only append
