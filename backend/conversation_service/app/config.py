from functools import lru_cache
from typing import List, Optional

from pydantic import AnyHttpUrl, Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration for the Conversation Service."""

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    app_name: str = Field(default="Conversation Service")
    environment: str = Field(default="development")

    supabase_url: AnyHttpUrl
    supabase_service_role_key: str
    supabase_jwt_secret: str

    elevenlabs_api_key: str
    elevenlabs_agent_id: str
    elevenlabs_voice_id: Optional[str] = None
    elevenlabs_model_id: str = Field(default="eleven_flash_v2_5")

    cors_allowed_origins: List[str] = Field(
        default_factory=list, validation_alias="cors_allowed_origins"
    )
    public_http_base: Optional[AnyHttpUrl] = None
    public_ws_base: Optional[AnyHttpUrl] = None

    session_ttl_seconds: int = Field(default=120, ge=30, le=600)

    log_level: str = Field(default="INFO")

    @model_validator(mode="before")
    @classmethod
    def split_origins(
        cls, data: "Settings | dict[str, object]"
    ) -> "Settings | dict[str, object]":
        if isinstance(data, dict):
            raw = data.get("cors_allowed_origins")
            if isinstance(raw, str):
                data["cors_allowed_origins"] = [
                    origin.strip() for origin in raw.split(",") if origin.strip()
                ]
        return data


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[arg-type]
