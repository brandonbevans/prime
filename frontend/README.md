## WealthIQ Frontend

Next.js App Router project styled with Tailwind v4 preview utilities. The `/conversation` route is a debugging interface for the new FastAPI voice conversation service.

## Requirements

- [pnpm](https://pnpm.io/) 10.x
- Node.js 20+
- Running Supabase project (for auth + onboarding data)
- FastAPI conversation service (`backend/conversation_service`)

## Environment variables

Copy `.env.example` from the repo root and fill in:

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
NEXT_PUBLIC_CONVERSATION_API_URL=http://localhost:8000
```

`NEXT_PUBLIC_CONVERSATION_API_URL` must point to the FastAPI service so the `/conversation` page can request WebSocket sessions.

See `backend/conversation_service/README.md` for the additional server-side variables (Supabase service key, ElevenLabs keys, etc.).

## Local development

```
# 1. Start the FastAPI service (runs uvicorn)
pnpm conversation:api

# 2. In another terminal, run the frontend
pnpm dev
```

Both commands run in `/frontend`. The `conversation:api` script wraps `uvicorn app.main:app --reload` inside `backend/conversation_service`.

Once both servers are up, visit http://localhost:3000/conversation, sign in with a Supabase user that completed onboarding, and click “Start Conversation”. The page will fetch a signed WebSocket URL from FastAPI, bridge to ElevenLabs, and play the agent’s greeting (“Hey {first_name}, how is your {primary_goal} going today?”).

## Useful scripts

| Command | Description |
| --- | --- |
| `pnpm dev` | Start the Next.js dev server |
| `pnpm build` / `pnpm start` | Production build & serve |
| `pnpm lint` | Run ESLint |
| `pnpm conversation:api` | Launch the FastAPI conversation service |
