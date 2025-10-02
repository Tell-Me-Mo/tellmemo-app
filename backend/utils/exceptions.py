"""Custom exception classes for better error handling."""

from typing import Optional, Dict, Any


class APIException(Exception):
    """Base class for API exceptions."""

    def __init__(
        self,
        message: str,
        status_code: int = 500,
        error_code: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.error_code = error_code
        self.details = details or {}


class LLMOverloadedException(APIException):
    """Exception raised when the LLM service is overloaded."""

    def __init__(self, message: str = "AI service is currently overloaded. Please try again in a few moments."):
        super().__init__(
            message=message,
            status_code=503,  # Service Unavailable
            error_code="LLM_OVERLOADED",
            details={
                "retry_after": 30,  # Suggest retry after 30 seconds
                "user_message": "The AI service is experiencing high demand. Your summary will be generated shortly. Please wait a moment and try again."
            }
        )


class LLMRateLimitException(APIException):
    """Exception raised when rate limit is exceeded."""

    def __init__(self, message: str = "AI service rate limit exceeded."):
        super().__init__(
            message=message,
            status_code=429,  # Too Many Requests
            error_code="RATE_LIMIT_EXCEEDED",
            details={
                "retry_after": 60,
                "user_message": "You've made too many requests. Please wait a minute before trying again."
            }
        )


class LLMAuthenticationException(APIException):
    """Exception raised when LLM authentication fails."""

    def __init__(self, message: str = "AI service authentication failed."):
        super().__init__(
            message=message,
            status_code=401,  # Unauthorized
            error_code="LLM_AUTH_FAILED",
            details={
                "user_message": "Authentication with AI service failed. Please contact support."
            }
        )


class LLMTimeoutException(APIException):
    """Exception raised when LLM request times out."""

    def __init__(self, message: str = "AI service request timed out."):
        super().__init__(
            message=message,
            status_code=504,  # Gateway Timeout
            error_code="LLM_TIMEOUT",
            details={
                "retry_after": 10,
                "user_message": "The request took too long to process. Please try again."
            }
        )


class InsufficientDataException(APIException):
    """Exception raised when there's not enough data to generate a summary."""

    def __init__(self, message: str = "Insufficient data for summary generation."):
        super().__init__(
            message=message,
            status_code=422,  # Unprocessable Entity
            error_code="INSUFFICIENT_DATA",
            details={
                "user_message": "Not enough content available to generate a meaningful summary. Please add more content first."
            }
        )