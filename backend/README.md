# Expense Backend

Node.js + Express + MongoDB + Redis + Socket.io. ESM modules, modular service architecture.

## Run with Docker (recommended)

```bash
cp .env.example .env
docker compose up --build
```

API at `http://localhost:4000` — health check at `/health`, base path `/api/v1`.

## Run locally (without Docker)

Requires Node 18+, MongoDB running on `localhost:27017`, and (optionally) Redis on `localhost:6379`.

```bash
cp .env.example .env
# edit MONGO_URI / REDIS_URL to point to your local services
npm install
npm run dev
```

## Seed demo data

```bash
docker compose exec api npm run seed
# or, when running locally:
npm run seed
```

Demo accounts: `alice@demo.io`, `bob@demo.io`, `cara@demo.io` — password `password123`.

## API surface (v1)

| Method | Path | Notes |
| --- | --- | --- |
| POST | `/auth/register` | name, email, password |
| POST | `/auth/login` | email, password |
| POST | `/auth/refresh` | refreshToken |
| POST | `/auth/logout` | bearer + refreshToken |
| GET  | `/auth/me` | bearer |
| GET / PATCH | `/users/me` | profile |
| GET  | `/users/search?q=` | autocomplete |
| POST | `/groups` | create group |
| GET  | `/groups` | my groups |
| GET  | `/groups/:id` | group detail |
| GET  | `/groups/:id/balances` | net balances + simplified transfers |
| POST | `/groups/:id/members` | invite by email |
| POST | `/groups/join` | join with invite code |
| POST | `/groups/:id/leave` | leave or delete if last |
| POST | `/expenses` | create (equal/exact/percent/shares) |
| GET  | `/expenses/group/:groupId` | paginated |
| GET  | `/expenses/feed` | across all my groups |
| GET  | `/expenses/analytics?months=6` | monthly category totals |
| GET / PATCH / DELETE | `/expenses/:id` | |
| POST | `/settlements` | record a payment |
| GET  | `/settlements/group/:groupId` | history |
| GET  | `/activity/feed` | my activity feed |
| GET  | `/activity/group/:groupId` | group activity |

## Socket.io events

Connect with `auth.token` = access token. Then `socket.emit('group:join', { groupId })`.

Server emits: `expense:created`, `expense:updated`, `expense:deleted`, `settlement:created`, `group:updated`, `activity:new`.

## Folder structure

```
src/
  app.js                 # express app
  config/                # env, db, redis, logger
  middleware/            # auth, validate, error
  modules/
    auth/                # controller / service / routes / validation
    users/               # model + routes
    groups/              # incl. balances + invite codes
    expenses/            # incl. splits + analytics
    settlements/
    activity/
  routes/index.js        # router mount
  seed/seed.js
  socket/index.js
  utils/                 # jwt, errors, splitCalculator, simplifyDebts
server.js
```
