---
description: Global coding standards for the monorepo
globs:
---

# Code Style

## Naming Conventions
- **Variables & functions:** camelCase
- **Types & interfaces:** PascalCase
- **Components:** PascalCase
- **Files & folders:** kebab-case
- **Constants:** UPPER_SNAKE_CASE only for true env-level constants
- **Enums:** PascalCase members (`Status.Active`)

## TypeScript
- Strict mode — no `any` unless justified with a comment
- Prefer `interface` for object shapes, `type` for unions/intersections
- Use `satisfies` for type-safe object literals
- Generic constraints over type assertions (`as`)

## Validation
- **Zod everywhere** — single validation library across the entire stack
- **Elysia routes:** Zod schemas via Standard Schema support (Elysia 1.2+)
- **Frontend forms:** Zod schemas for form data and user input
- **Environment vars:** Zod schemas (e.g. `z.string().url()`)
- **PrismaBox:** Generate Zod schemas from Prisma models for consistent validation
- Colocate schema with its usage
- Infer types from schemas: `z.infer<typeof schema>`

## Error Handling
- Return-based errors — avoid `throw` in business logic
- Services: `return status(code, error)` (import from `elysia`)
- Result pattern where appropriate: `{ success: true, data } | { success: false, error }`
- Log errors with context (userId, action, input)

## Exports
- Named exports by default
- Default exports only for Next.js pages, layouts, and route handlers
- Barrel exports via `index.ts` per module

## Imports
- Absolute paths via `@/` alias
- Group: external, then internal, then relative — separated by blank lines
- No circular imports between modules

## Comments
- English only
- Only when the "why" isn't obvious from the code
- No TODO without a linked issue or explicit plan
