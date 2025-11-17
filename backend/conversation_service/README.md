# Conversation Service

FastAPI microservice that brokers authenticated voice conversations between the WealthIQ frontend and ElevenLabs Conversational AI.

## Requirements
- Python 3.11+
- `uvicorn` for local dev (`pip install -e .[dev]` or `pip install uvicorn`)

## Environment Variables
Create a `.env` file under `backend/conversation_service/` with the following keys:

```
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_JWT_SECRET=
ELEVENLABS_API_KEY=
ELEVENLABS_AGENT_ID=
ELEVENLABS_VOICE_ID=
CORS_ALLOWED_ORIGINS=http://localhost:3000
PUBLIC_HTTP_BASE=http://localhost:8000
PUBLIC_WS_BASE=ws://localhost:8000
```

See `frontend/README.md` for frontend-specific variables.

## Running Locally

```bash
cd backend/conversation_service
uvicorn app.main:app --reload
```

Then open [http://localhost:8000/health](http://localhost:8000/health).
