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
  models/            # Prisma data-access layer + TypeBox schemas
    user.ts
    auth.ts
  plugins/           # Shared Elysia plugins
  index.ts           # Main server entry
```

### Controller (`controllers/user.ts`)
An Elysia instance per domain. Handles HTTP concerns, validates with TypeBox, delegates to service.

```typescript
// src/controllers/user.ts
import { Elysia, t } from "elysia"
import { UserService } from "../services/user"
import { UserModel } from "../models/user"

export const userController = new Elysia({ prefix: "/users" })
  .decorate("userService", new UserService())
  .model(UserModel)
  .get("/", ({ userService, query }) => userService.list(query), {
    query: t.Object({
      cursor: t.Optional(t.String()),
      limit: t.Optional(t.Number({ minimum: 1, maximum: 100 })),
    }),
  })
  .post("/", ({ userService, body }) => userService.create(body), {
    body: "user.create",
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
TypeBox schemas for validation + inferred types. Custom errors live here too.

```typescript
// src/models/user.ts
import { t } from "elysia"

export const UserModel = {
  "user.create": t.Object({
    name: t.String({ minLength: 1 }),
    email: t.String({ format: "email" }),
  }),
  "user.response": t.Object({
    id: t.String(),
    name: t.String(),
    email: t.String(),
  }),
}

// Infer types from schemas
export type CreateUser = typeof UserModel["user.create"]["static"]
```

## Elysia Key Concepts

### Validation: TypeBox (`t`) by Default
Elysia uses TypeBox natively. Import `t` from `elysia` — not Zod.

```typescript
import { Elysia, t } from "elysia"

// TypeBox (default, recommended)
.post("/user", ({ body }) => body, {
  body: t.Object({
    name: t.String(),
    age: t.Number({ minimum: 0 }),
  }),
})
```

Zod is supported via Standard Schema but is not the default:
```typescript
import { z } from "zod"

.post("/user", ({ body }) => body, {
  body: z.object({ name: z.string(), age: z.number().min(0) }),
})
```

### Reference Models
Register schemas by name for reuse and OpenAPI docs:

```typescript
new Elysia()
  .model(UserModel)
  .prefix("model", "User")
  .post("/", ({ body }) => body, { body: "User.create" })
```

### Error Handling: `status()`
Use `status()` from elysia (import or context destructure):

```typescript
import { status } from "elysia"

// In handler
.get("/user/:id", ({ params: { id } }) => {
  const user = findUser(id)
  if (!user) return status(404, "User not found")
  return user
}, {
  response: {
    200: t.Object({ id: t.String(), name: t.String() }),
    404: t.String(),
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
