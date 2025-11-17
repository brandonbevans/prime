from dataclasses import dataclass

import httpx
from fastapi import HTTPException, status

from ..config import get_settings


@dataclass(slots=True)
class SignedUrl:
    url: str


class ElevenLabsService:
    def __init__(self) -> None:
        self._client = httpx.AsyncClient(
            base_url="https://api.elevenlabs.io",
            timeout=httpx.Timeout(20.0, connect=10.0),
        )

    async def get_signed_url(self) -> SignedUrl:
        settings = get_settings()
        endpoint = f"/v1/convai/conversation/get-signed-url?agent_id={settings.elevenlabs_agent_id}"
        headers = {"xi-api-key": settings.elevenlabs_api_key}
        try:
            resp = await self._client.get(endpoint, headers=headers)
            resp.raise_for_status()
        except httpx.HTTPError as exc:  # pragma: no cover - network
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Failed to obtain ElevenLabs signed URL",
            ) from exc

        data = resp.json()
        signed_url = data.get("signed_url")
        if not isinstance(signed_url, str):
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="ElevenLabs response missing signed_url",
            )
        return SignedUrl(url=signed_url)

    async def close(self) -> None:
        await self._client.aclose()


_elevenlabs_service: ElevenLabsService | None = None


def get_elevenlabs_service() -> ElevenLabsService:
    global _elevenlabs_service
    if _elevenlabs_service is None:
        _elevenlabs_service = ElevenLabsService()
    return _elevenlabs_service
