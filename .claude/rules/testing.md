---
description: Testing standards and patterns
globs:
---

# Testing Rules

## Framework
- **bun:test** for all tests
- Test files colocated with source: `*.test.ts` / `*.test.tsx`

## Backend: `app.handle()` Pattern

Test Elysia modules directly with `app.handle()` — no HTTP server needed:

```typescript
import { describe, expect, it } from "bun:test"
import { userModule } from "@/modules/user"

describe("GET /users", () => {
  it("returns a list of users", async () => {
    const res = await userModule.handle(
      new Request("http://localhost/users")
    )
    expect(res.status).toBe(200)

    const body = await res.json()
    expect(body).toBeArray()
  })
})
```

### POST with Body
```typescript
it("creates a user", async () => {
  const res = await userModule.handle(
    new Request("http://localhost/users", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "Alice", email: "alice@test.com" }),
    })
  )
  expect(res.status).toBe(200)
})
```

## Backend: Eden Treaty Testing

Use Eden Treaty for type-safe integration tests:

```typescript
import { describe, expect, it } from "bun:test"
import { treaty } from "@elysiajs/eden"
import { userModule } from "@/modules/user"

const api = treaty(userModule)

describe("User Module", () => {
  it("creates a user with Eden", async () => {
    const { data, error } = await api.users.post({
      name: "Alice",
      email: "alice@test.com",
    })

    expect(error).toBeNull()
    expect(data?.name).toBe("Alice")
  })
})
```

## Mocking Dependencies

Use `.decorate()` to inject mock dependencies:

```typescript
import { app } from "@/index"

it("uses mock database", async () => {
  const mockDb = {
    getUsers: () => [{ id: "1", name: "Test User" }],
  }

  const testApp = app.decorate("db", mockDb)

  const res = await testApp.handle(
    new Request("http://localhost/users")
  )
  const data = await res.json()
  expect(data).toEqual([{ id: "1", name: "Test User" }])
})
```

## Frontend Testing
- Test components via user interactions, not implementation details
- Mock Eden client for API calls
- Test Server Components as async functions

## Structure: Arrange-Act-Assert

```typescript
it("creates a user with valid data", async () => {
  // Arrange
  const input = { name: "Alice", email: "alice@test.com" }

  // Act
  const { data, error } = await api.users.post(input)

  // Assert
  expect(error).toBeNull()
  expect(data?.name).toBe("Alice")
})
```

## Guidelines
- Test behavior, not implementation
- One assertion concept per test (multiple `expect` OK if same concept)
- Descriptive test names: "does X when Y" or "returns Z for invalid input"
- No test interdependence — each test sets up its own state
- Coverage target: critical paths first (auth, payments, data mutations)

## Commands
```bash
bun test                        # All tests
bun test --watch                # Watch mode
bun test path/to/file.test.ts  # Single file
```
