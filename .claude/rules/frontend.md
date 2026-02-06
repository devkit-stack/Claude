---
description: Frontend patterns for Next.js, React, and UI development
globs: apps/web/**/*.ts, apps/web/**/*.tsx
---

# Frontend Rules (Next.js 15 + shadcn/ui)

## React Server Components (RSC)
- **Server Components by default** — no directive needed
- Add `"use client"` only when required: event handlers, hooks, browser APIs
- Use `Suspense` boundaries for async Server Components

### RSC Boundaries
- Client Components **cannot** be async — only Server Components can
- Props from Server to Client must be **JSON-serializable** (no functions, Date, Map, Set, class instances)
- Exception: Server Actions (`"use server"`) can be passed as props

```tsx
// Bad: async client component
"use client"
export default async function Profile() { /* ... */ }

// Good: fetch in server parent, pass data down
export default async function Page() {
  const user = await getUser()
  return <ProfileClient user={user} />
}
```

## Async APIs (Next.js 15)

`params`, `searchParams`, `cookies()`, and `headers()` are **async** in Next.js 15+.

```tsx
// Pages and Layouts — always await params
type Props = { params: Promise<{ slug: string }> }

export default async function Page({ params }: Props) {
  const { slug } = await params
}
```

```tsx
// Cookies and Headers — always await
import { cookies, headers } from "next/headers"

export default async function Page() {
  const cookieStore = await cookies()
  const headersList = await headers()
}
```

For non-async Client Components, use `React.use()`:
```tsx
"use client"
import { use } from "react"

export default function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
}
```

## Data Fetching

### Server Components: Fetch Directly (Preferred for Reads)
No API layer needed — access database or external services directly.

```tsx
// app/users/page.tsx (Server Component)
export default async function UsersPage() {
  const users = await prisma.user.findMany()
  return <UserList users={users} />
}
```

### Client Components: Eden + React Query
For interactive client-side data fetching, use Eden Treaty with React Query.

```typescript
// lib/eden.ts
import { treaty } from "@elysiajs/eden"
import type { App } from "@api/index"

export const api = treaty<App>("localhost:3000")
```

```tsx
// hooks/use-users.ts
"use client"
import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/eden"

export function useUsers() {
  return useQuery({
    queryKey: ["users"],
    queryFn: () => api.users.get(),
  })
}
```

### Server Actions (Preferred for Mutations)
```tsx
// app/actions.ts
"use server"
import { revalidatePath } from "next/cache"

export async function createUser(formData: FormData) {
  const name = formData.get("name") as string
  await prisma.user.create({ data: { name } })
  revalidatePath("/users")
}
```

### Decision Tree
| Need | Pattern |
|------|---------|
| Read in Server Component | Fetch directly (DB, external API) |
| Read in Client Component | Eden + React Query |
| Mutation from form | Server Action |
| Mutation from interactive UI | React Query mutation + Eden |
| External API / webhooks | Route Handler |

## Avoiding Data Waterfalls

```tsx
// Bad: sequential
const user = await getUser()
const posts = await getPosts()

// Good: parallel
const [user, posts] = await Promise.all([getUser(), getPosts()])

// Good: streaming with Suspense
<Suspense fallback={<UserSkeleton />}>
  <UserSection />
</Suspense>
<Suspense fallback={<PostsSkeleton />}>
  <PostsSection />
</Suspense>
```

## App Router File Conventions
- `page.tsx` — route entry point
- `layout.tsx` — shared UI, persistent across navigations
- `loading.tsx` — Suspense fallback for the route segment
- `error.tsx` — error boundary (must be `"use client"`)
- `not-found.tsx` — 404 UI
- `(group)/` — route groups, no URL impact

## shadcn/ui
- Install: `bunx --bun shadcn@latest add <component>`
- Customize in `components/ui/` — your files, modify freely
- Use `cn()` from `lib/utils.ts` for conditional class merging
- Compose primitives into domain components

## Styling
- **Tailwind CSS 4** — utility-first
- **Mobile-first** responsive: base then `md:` then `lg:` then `xl:`
- Design tokens via CSS variables in `globals.css`
- Dark mode via `class` strategy
