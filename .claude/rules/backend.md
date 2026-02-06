---
description: Backend patterns for ElysiaJS, Prisma, and API development
globs: apps/api/**/*.ts, **/prisma/**
---

# Backend Rules (ElysiaJS + Prisma 7)

## Architecture: Layer-Based

Organize code by technical layer, one file per domain entity in each layer.

```
src/
  controllers/       # Elysia route instances (one per domain)
    user.ts
    auth.ts
  services/          # Business logic classes
    user.ts
    auth.ts
  models/            # Prisma data-access layer + Zod schemas (PrismaBox)
    user.ts
    auth.ts
  plugins/           # Shared Elysia plugins
  index.ts           # Main server entry
```

### Controller (`controllers/user.ts`)
An Elysia instance per domain. Handles HTTP concerns, validates with Zod (via Standard Schema), delegates to service.

```typescript
// src/controllers/user.ts
import { Elysia } from "elysia"
import { z } from "zod"
import { UserService } from "../services/user"
import { createUserSchema, userResponseSchema } from "../models/user"

export const userController = new Elysia({ prefix: "/users" })
  .decorate("userService", new UserService())
  .get("/", ({ userService, query }) => userService.list(query), {
    query: z.object({
      cursor: z.string().optional(),
      limit: z.number().min(1).max(100).optional(),
    }),
  })
  .post("/", ({ userService, body }) => userService.create(body), {
    body: createUserSchema,
  })
```

### Service (`services/user.ts`)
Prefer classes (or abstract classes). No HTTP concepts. Return errors, never throw.

```typescript
// src/services/user.ts
import { status } from "elysia"

export class UserService {
  async create(input: CreateUser) {
    const existing = await prisma.user.findUnique({ where: { email: input.email } })
    if (existing) return status(409, { error: "Email already exists" })

    return prisma.user.create({ data: input })
  }
}
```

### Model (`models/user.ts`)
Zod schemas for validation + inferred types. Use PrismaBox to generate base schemas from Prisma models, then extend as needed.

```typescript
// src/models/user.ts
import { z } from "zod"

export const createUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

export const userResponseSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
})

// Infer types from schemas
export type CreateUser = z.infer<typeof createUserSchema>
export type UserResponse = z.infer<typeof userResponseSchema>
```

## Elysia Key Concepts

### Validation: Zod via Standard Schema
Elysia supports Zod natively via Standard Schema (Elysia 1.2+). Use Zod for all validation — consistent across the entire stack.

```typescript
import { Elysia } from "elysia"
import { z } from "zod"

.post("/user", ({ body }) => body, {
  body: z.object({
    name: z.string(),
    age: z.number().min(0),
  }),
})
```

Elysia also supports TypeBox natively (`t` from `elysia`), but we standardize on Zod for consistency across backend and frontend.

### Error Handling: `status()`
Use `status()` from elysia (import or context destructure):

```typescript
import { Elysia, status } from "elysia"
import { z } from "zod"

// In handler
.get("/user/:id", ({ params: { id } }) => {
  const user = findUser(id)
  if (!user) return status(404, "User not found")
  return user
}, {
  response: {
    200: z.object({ id: z.string(), name: z.string() }),
    404: z.string(),
  },
})
```

Use `onError` for module-level custom error handling.

### Encapsulation
Lifecycles don't leak between instances unless scoped:
- `local` (default) — current instance only
- `scoped` — parent + current + descendants
- `global` — all instances

### Method Chaining (Required)
Always chain methods. Each method returns a new type reference — breaking the chain loses types.

### Explicit Dependencies
Each instance is independent. Use `.use()` to compose controllers:

```typescript
// Main server
new Elysia()
  .use(userController)
  .use(authController)
  .listen(3000)
```

### Order Matters
Hooks apply only to routes registered **after** them.

## Prisma 7 Setup

Prisma 7 **requires** a driver adapter and explicit output path.

```typescript
// lib/prisma.ts
import { PrismaClient } from "../generated/prisma/client"
import { PrismaPg } from "@prisma/adapter-pg"

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL })

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }
export const prisma = globalForPrisma.prisma || new PrismaClient({ adapter })
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma
```

Schema generator block (v7):
```prisma
generator client {
  provider = "prisma-client"
  output   = "../generated/prisma"
}
```

### Migrations
- `npx prisma migrate dev --name descriptive_name` for development
- `npx prisma generate` after schema changes
- Never edit migration files after they've been applied

## Eden Treaty
Export the app type for frontend type safety:

```typescript
const app = new Elysia()
  .use(userController)
  .use(authController)
  .listen(3000)

export type App = typeof app
```

## API Conventions
- RESTful resource naming (plural nouns): `/users`, `/posts`
- Cursor-based pagination: `cursor` + `limit` params
- Never expose internal error details to clients in production
