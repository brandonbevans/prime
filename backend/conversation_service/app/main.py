from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .routes import conversation, health
from .services.elevenlabs_service import get_elevenlabs_service

settings = get_settings()

app = FastAPI(title=settings.app_name)

# Dev: Allow all CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(conversation.router)


@app.on_event("shutdown")
async def shutdown_event() -> None:
    eleven = get_elevenlabs_service()
    await eleven.close()
