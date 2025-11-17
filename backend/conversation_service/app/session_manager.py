import asyncio
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from secrets import token_urlsafe

from fastapi import HTTPException, status

from .config import get_settings


@dataclass(slots=True)
class PendingSession:
    user_id: str
    session_token: str
    expires_at: datetime


class ConversationSessionManager:
    def __init__(self) -> None:
        self._sessions: dict[str, PendingSession] = {}
        self._lock = asyncio.Lock()
        self._settings = get_settings()

    async def create_session(self, user_id: str) -> tuple[str, str]:
        async with self._lock:
            session_id = token_urlsafe(16)
            session_token = token_urlsafe(32)
            expires_at = datetime.now(timezone.utc) + timedelta(
                seconds=self._settings.session_ttl_seconds
            )
            self._sessions[session_id] = PendingSession(
                user_id=user_id,
                session_token=session_token,
                expires_at=expires_at,
            )
            return session_id, session_token

    async def consume_session(self, session_id: str, token: str) -> PendingSession:
        async with self._lock:
            record = self._sessions.pop(session_id, None)
            if record is None or record.session_token != token:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired session",
                )
            if datetime.now(timezone.utc) > record.expires_at:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Session expired",
                )
            return record


_session_manager: ConversationSessionManager | None = None


def get_session_manager() -> ConversationSessionManager:
    global _session_manager
    if _session_manager is None:
        _session_manager = ConversationSessionManager()
    return _session_manager
