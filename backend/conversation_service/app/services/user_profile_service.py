from dataclasses import dataclass

from fastapi import HTTPException, status
from supabase import Client

from ..supabase_client import get_supabase_client


@dataclass(slots=True)
class UserProfile:
    user_id: str
    first_name: str
    primary_goal: str


class UserProfileService:
    def __init__(self, client: Client | None = None) -> None:
        self._client = client or get_supabase_client()

    def _raise_not_found(self) -> None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found",
        )

    async def fetch_profile(self, user_id: str) -> UserProfile:
        response = self._client.table("user_profiles").select(
            "first_name, primary_goal"
        ).eq("user_id", user_id).limit(1).single().execute()

        data = getattr(response, "data", None)
        if not data:
            self._raise_not_found()

        first_name = data.get("first_name")
        primary_goal = data.get("primary_goal")

        if not isinstance(first_name, str) or not isinstance(primary_goal, str):
            self._raise_not_found()

        return UserProfile(user_id=user_id, first_name=first_name, primary_goal=primary_goal)


def get_user_profile_service() -> UserProfileService:
    return UserProfileService()
