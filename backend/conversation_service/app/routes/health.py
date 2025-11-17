from fastapi import APIRouter

router = APIRouter(prefix="/health", tags=["health"])


@router.get("", summary="Liveness probe")
async def healthcheck() -> dict[str, str]:
    return {"status": "ok"}
