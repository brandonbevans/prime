from dataclasses import dataclass


@dataclass(slots=True)
class AuthenticatedUser:
    user_id: str
    subject: str
