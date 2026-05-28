# Settle — Backend

REST API for the Settle expense-splitting app. Built with **Fastify**, **TypeScript**, **Prisma**, and **PostgreSQL**. Auth is handled by Supabase — the API just verifies the JWT on every request.

## Stack

| Layer | Choice |
|---|---|
| Framework | Fastify |
| Language | TypeScript |
| ORM | Prisma 7 |
| Database | PostgreSQL |
| Auth | Supabase JWT verification |

## Project structure

```
backend/
├── prisma/
│   └── schema.prisma       # All models: Profile, Group, Expense, Settlement, InviteToken
├── src/
│   ├── index.ts            # Server bootstrap
│   ├── lib/
│   │   ├── prisma.ts       # Prisma client singleton
│   │   └── supabase.ts     # Supabase admin client (JWT verification)
│   ├── middleware/
│   │   └── auth.ts         # Bearer token → userId on request
│   └── routes/
│       ├── profiles.ts     # GET/PUT /profiles/me
│       ├── groups.ts       # CRUD /groups
│       ├── expenses.ts     # CRUD /groups/:id/expenses
│       ├── settlements.ts  # CRUD /groups/:id/settlements
│       └── invites.ts      # GET /invites/:token, POST /invites/:token/join
└── .env.example
```

## API routes

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/health` | — | Health check |
| GET | `/profiles/me` | ✓ | Get current user profile |
| PUT | `/profiles/me` | ✓ | Create or update profile |
| GET | `/groups` | ✓ | List groups user belongs to |
| POST | `/groups` | ✓ | Create a group |
| GET | `/groups/:id` | ✓ | Get group detail |
| PATCH | `/groups/:id` | ✓ | Update group name/emoji |
| DELETE | `/groups/:id` | ✓ | Delete group (creator only) |
| GET | `/groups/:id/expenses` | ✓ | List expenses in group |
| POST | `/groups/:id/expenses` | ✓ | Add expense |
| DELETE | `/groups/:id/expenses/:expenseId` | ✓ | Soft-delete expense |
| GET | `/groups/:id/settlements` | ✓ | List settlements |
| POST | `/groups/:id/settlements` | ✓ | Record a settlement |
| GET | `/invites/:token` | — | Resolve invite (group preview) |
| POST | `/invites/:token/join` | ✓ | Join group via invite link |

## Setup

```bash
cp .env.example .env
# Fill in DATABASE_URL, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

npm install
npm run db:migrate   # runs Prisma migrations
npm run dev          # starts server on :3000
```

## Auth

Every protected route expects:

```
Authorization: Bearer <supabase-access-token>
```

The middleware calls `supabase.auth.getUser(token)` and attaches `userId` to the request. No JWT secret needed in the API — Supabase validates it.
