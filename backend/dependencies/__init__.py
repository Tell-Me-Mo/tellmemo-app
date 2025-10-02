"""Dependencies module for FastAPI dependency injection."""

from dependencies.auth import (
    get_current_user,
    get_current_organization,
    get_current_user_role,
    require_role,
    get_optional_current_user,
)

__all__ = [
    'get_current_user',
    'get_current_organization',
    'get_current_user_role',
    'require_role',
    'get_optional_current_user',
]