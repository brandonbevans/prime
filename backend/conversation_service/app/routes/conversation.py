import asyncio
import json
from typing import Any, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Request, WebSocket, status
from pydantic import BaseModel
import websockets

from ..auth import AuthenticatedUser, verify_supabase_jwt
from ..config import get_settings
from ..session_manager import ConversationSessionManager, get_session_manager
from ..services.elevenlabs_service import get_elevenlabs_service
from ..services.user_profile_service import UserProfile, get_user_profile_service

router = APIRouter(prefix="/api/conversation", tags=["conversation"])


class ConversationSessionResponse(BaseModel):
    session_id: str
    session_token: str
    ws_url: str
    expires_in_seconds: int


async def _require_auth_user(authorization: Optional[str]) -> AuthenticatedUser:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Supabase token",
        )
    return verify_supabase_jwt(token)


@router.post("/session", response_model=ConversationSessionResponse)
async def create_conversation_session(
    request: Request,
    authorization: Optional[str] = Header(default=None),
    session_manager: ConversationSessionManager = Depends(get_session_manager),
):
    user = await _require_auth_user(authorization)

    profile_service = get_user_profile_service()
    # Validate that the profile exists up-front to return a deterministic error
    await profile_service.fetch_profile(user.user_id)

    session_id, session_token = await session_manager.create_session(user.user_id)

    settings = get_settings()
    base_ws = settings.public_ws_base or str(request.base_url).rstrip("/")
    if base_ws.startswith("http"):
        base_ws = base_ws.replace("http", "ws", 1)
    ws_url = f"{base_ws}/ws/conversation?session_id={session_id}&session_token={session_token}"

    return ConversationSessionResponse(
        session_id=session_id,
        session_token=session_token,
        ws_url=ws_url,
        expires_in_seconds=settings.session_ttl_seconds,
    )


@router.websocket("/ws/conversation")
async def conversation_socket(
    websocket: WebSocket,
    session_manager: ConversationSessionManager = Depends(get_session_manager),
):
    await websocket.accept()

    session_id = websocket.query_params.get("session_id")
    session_token = websocket.query_params.get("session_token")
    if not session_id or not session_token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    try:
        session = await session_manager.consume_session(session_id, session_token)
    except HTTPException as exc:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason=exc.detail)
        return

    profile_service = get_user_profile_service()
    try:
        profile = await profile_service.fetch_profile(session.user_id)
    except HTTPException as exc:
        await websocket.close(code=status.WS_1011_INTERNAL_ERROR, reason=exc.detail)
        return

    eleven_service = get_elevenlabs_service()
    settings = get_settings()
    try:
        signed = await eleven_service.get_signed_url()
    except HTTPException as exc:
        await websocket.close(code=status.WS_1011_INTERNAL_ERROR, reason=exc.detail)
        return

    greeting = f"Hey {profile.first_name}, how is your {profile.primary_goal} going today?"

    async def client_to_elevenlabs(eleven_ws: websockets.WebSocketClientProtocol) -> None:
        try:
            init_payload = _build_initiation_payload(profile, greeting)
            await eleven_ws.send(json.dumps(init_payload))
            while True:
                message = await websocket.receive()
                if "text" in message and message["text"] is not None:
                    await eleven_ws.send(message["text"])
                elif "bytes" in message and message["bytes"] is not None:
                    await eleven_ws.send(message["bytes"])
                elif message.get("type") == "websocket.disconnect":
                    break
        finally:
            await eleven_ws.close()

    async def elevenlabs_to_client(eleven_ws: websockets.WebSocketClientProtocol) -> None:
        try:
            async for data in eleven_ws:
                if isinstance(data, (bytes, bytearray)):
                    await websocket.send_bytes(data)
                else:
                    await websocket.send_text(data)
        finally:
            await websocket.close()

    try:
        async with websockets.connect(
            signed.url,
            extra_headers={"xi-api-key": settings.elevenlabs_api_key},
            max_size=16 * 1024 * 1024,
        ) as eleven_ws:
            to_eleven = asyncio.create_task(client_to_elevenlabs(eleven_ws))
            to_client = asyncio.create_task(elevenlabs_to_client(eleven_ws))
            done, pending = await asyncio.wait(
                {to_eleven, to_client}, return_when=asyncio.FIRST_COMPLETED
            )
            for task in pending:
                task.cancel()
            for task in done:
                exc = task.exception()
                if exc:
                    raise exc
    except Exception:  # pragma: no cover - runtime safety
        await websocket.close(code=status.WS_1011_INTERNAL_ERROR)


def _build_initiation_payload(profile: UserProfile, greeting: str) -> dict[str, Any]:
    settings = get_settings()
    conversation_config: dict[str, Any] = {
        "agent": {
            "first_message": greeting,
        }
    }
    if settings.elevenlabs_voice_id:
        conversation_config.setdefault("tts", {})["voice_id"] = settings.elevenlabs_voice_id

    return {
        "type": "conversation_initiation_client_data",
        "conversation_config_overrides": conversation_config,
        "dynamic_variables": {
            "first_name": profile.first_name,
            "primary_goal": profile.primary_goal,
        },
        "user_id": profile.user_id,
    }
