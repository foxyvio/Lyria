# Lyria — Autonomous Agent Economy Platform (MVP)

A minimal, working proof-of-concept where AI "agents" can register a skill,
list it on a marketplace, and "hire" each other — with simulated wallets
and a transaction log.

**Stack:** Rust (Axum) backend, in-memory store · Flutter frontend

---

## What's real vs. simulated (be honest with yourself here)

- ✅ Real: HTTP API, agent registration, marketplace listing, task/hiring flow,
  balance transfer logic, transaction history — all working, in-memory.
- 🔶 Simulated: "wallets" are just numbers in a Rust struct, not blockchain
  wallets. No smart contracts, no on-chain identity, no real AI task
  execution (an agent doesn't actually call OpenAI to do the work — it just
  simulates the exchange of money for a task).
- This is the right scope for an MVP: prove the *marketplace mechanics*
  work before adding blockchain, real AI calls, or persistence.

## Realistic next steps (in order of what actually reduces risk)

1. Replace in-memory `HashMap` with PostgreSQL (schema maps almost 1:1 to
   the current `Agent`/`Transaction` structs).
2. Add real agent execution: call the OpenAI/Anthropic API when a task is
   "hired" so the provider agent actually does the work.
3. Add auth (agents/owners need real accounts, not just a name string).
4. Only *then* consider a real wallet (Ethereum/Solana testnet, or simpler:
   Stripe Connect for a "wallet" abstraction humans understand).
5. Moat, if it comes, will come from getting real users trading real
   skills — not from stacking more technologies into the MVP.

---

## Backend (Rust)

```bash
cd backend
cargo build
cargo run
# Server starts on http://localhost:8080
```

### API endpoints

| Method | Path                     | Description                          |
|--------|--------------------------|---------------------------------------|
| POST   | /api/agents              | Register a new agent                  |
| GET    | /api/agents              | List all agents                       |
| GET    | /api/agents/:id          | Get one agent                         |
| GET    | /api/agents/:id/wallet   | Balance + transaction history         |
| GET    | /api/marketplace         | List all skills for sale              |
| POST   | /api/tasks               | Hire an agent (executes a "task")     |
| GET    | /api/tasks               | Full transaction log                  |

Example:
```bash
curl -X POST http://localhost:8080/api/agents \
  -H "Content-Type: application/json" \
  -d '{"owner":"Rohit","name":"DataBot","skill_name":"Data Summarizer","skill_description":"Summarizes CSV data","price_per_call":2.5}'
```

## Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run -d chrome   # or -d your-device
```

Update `lib/services/api_service.dart` → `baseUrl` to point at your deployed
backend once it's live (currently set to `http://localhost:8080/api`).

---

## Pushing this to GitHub yourself

I can't push to your GitHub from here (no network access in my sandbox, and
you should never hand a Personal Access Token to any AI chat). Do this on
your own machine instead:

```bash
cd lyria
git init
git add .
git commit -m "Lyria MVP: agent marketplace backend + dashboard"
git branch -M main
git remote add origin https://github.com/<your-username>/<repo-name>.git
git push -u origin main
```

The first push will open a browser login (or use `gh auth login` if you have
the GitHub CLI installed) — your token never has to be typed or pasted
anywhere.

## Deploying

- **Backend**: any host that runs a Rust binary — Fly.io, Railway, Render,
  or a plain VPS behind nginx. `cargo build --release` produces a single
  binary at `target/release/lyria`.
- **Frontend**: `flutter build web` produces a static site you can host on
  Vercel, Netlify, GitHub Pages, or Firebase Hosting.

