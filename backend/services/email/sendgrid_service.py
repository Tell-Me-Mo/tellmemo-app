"""
SendGrid Email Service for Transactional Emails

This service handles all email delivery through SendGrid API:
- Digest emails (daily/weekly/monthly)
- Onboarding welcome emails
- Inactive user reminders
- Email unsubscribe management
"""

import logging
from typing import Optional, Dict, Any
from datetime import datetime
import time

from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email, To, Content, Personalization
from python_http_client.exceptions import HTTPError
from redis import Redis
from redis.exceptions import RedisError

from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class SendGridService:
    """Service for sending emails via SendGrid API"""

    def __init__(self):
        """Initialize SendGrid client and Redis for persistent rate limiting"""
        self.api_key = settings.sendgrid_api_key
        self.from_email = settings.email_from_address
        self.from_name = settings.email_from_name
        self.client = None

        # Redis configuration for distributed rate limiting
        self.rate_limit_key = "sendgrid:rate_limit:remaining"
        self.rate_limit_reset_key = "sendgrid:rate_limit:reset_time"
        self.redis_client: Optional[Redis] = None

        # In-memory fallback (used if Redis unavailable)
        self._memory_rate_limit_remaining = settings.email_digest_rate_limit
        self._memory_rate_limit_reset_time = None

        # Initialize Redis client for persistent rate limiting
        try:
            if settings.redis_password:
                redis_url = f"redis://:{settings.redis_password}@{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"
            else:
                redis_url = f"redis://{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"

            self.redis_client = Redis.from_url(
                redis_url,
                decode_responses=True,
                socket_connect_timeout=2,
                socket_timeout=2
            )

            # Test connection and initialize rate limit if not exists
            self.redis_client.ping()
            if not self.redis_client.exists(self.rate_limit_key):
                self.redis_client.set(self.rate_limit_key, settings.email_digest_rate_limit)
            logger.info("Redis connected for SendGrid rate limiting")

        except Exception as e:
            logger.warning(f"Redis unavailable for rate limiting, using in-memory fallback: {e}")
            self.redis_client = None

        # Initialize SendGrid client if API key is configured
        if self.api_key:
            try:
                self.client = SendGridAPIClient(api_key=self.api_key)
                logger.info("SendGrid client initialized successfully")
            except Exception as e:
                logger.error(f"Failed to initialize SendGrid client: {e}")
                self.client = None
        else:
            logger.warning("SendGrid API key not configured - email sending disabled")

    def is_configured(self) -> bool:
        """
        Check if SendGrid is properly configured.

        Returns:
            bool: True if SendGrid client is ready
        """
        return self.client is not None

    def _get_rate_limit_remaining(self) -> int:
        """
        Get rate limit remaining count from Redis or memory fallback.

        Returns:
            int: Number of emails remaining before hitting rate limit
        """
        if self.redis_client:
            try:
                remaining = self.redis_client.get(self.rate_limit_key)
                return int(remaining) if remaining else settings.email_digest_rate_limit
            except (RedisError, ValueError, TypeError) as e:
                logger.warning(f"Error reading rate limit from Redis, using memory fallback: {e}")

        # Fallback to in-memory value
        return self._memory_rate_limit_remaining

    def _set_rate_limit_remaining(self, value: int) -> bool:
        """
        Set rate limit remaining count in Redis and memory.

        Args:
            value: Number of emails remaining

        Returns:
            bool: True if successfully stored in Redis, False if using memory fallback
        """
        # Always update memory fallback
        self._memory_rate_limit_remaining = value

        if self.redis_client:
            try:
                self.redis_client.set(self.rate_limit_key, value)
                return True
            except RedisError as e:
                logger.warning(f"Error writing rate limit to Redis, using memory fallback: {e}")

        return False

    def _get_rate_limit_reset_time(self) -> Optional[datetime]:
        """
        Get rate limit reset time from Redis or memory fallback.

        Returns:
            datetime or None: When the rate limit will reset
        """
        if self.redis_client:
            try:
                reset_time_str = self.redis_client.get(self.rate_limit_reset_key)
                if reset_time_str:
                    return datetime.fromisoformat(reset_time_str)
            except (RedisError, ValueError, TypeError) as e:
                logger.warning(f"Error reading reset time from Redis, using memory fallback: {e}")

        # Fallback to in-memory value
        return self._memory_rate_limit_reset_time

    def _set_rate_limit_reset_time(self, reset_time: Optional[datetime]) -> bool:
        """
        Set rate limit reset time in Redis and memory.

        Args:
            reset_time: When the rate limit will reset (None to clear)

        Returns:
            bool: True if successfully stored in Redis, False if using memory fallback
        """
        # Always update memory fallback
        self._memory_rate_limit_reset_time = reset_time

        if self.redis_client:
            try:
                if reset_time:
                    self.redis_client.set(self.rate_limit_reset_key, reset_time.isoformat())
                else:
                    self.redis_client.delete(self.rate_limit_reset_key)
                return True
            except RedisError as e:
                logger.warning(f"Error writing reset time to Redis, using memory fallback: {e}")

        return False

    def send_email(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None,
        reply_to: Optional[str] = None,
        custom_args: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """
        Send email via SendGrid API with retry logic.

        Args:
            to_email: Recipient email address
            subject: Email subject line
            html_content: HTML email body
            text_content: Plain text fallback (optional)
            reply_to: Reply-to email address (optional)
            custom_args: Custom tracking arguments (optional)

        Returns:
            Dict with status, message_id, and error info
        """
        if not self.is_configured():
            error_msg = "SendGrid not configured - cannot send email"
            logger.error(error_msg)
            return {
                "success": False,
                "error": error_msg,
                "message_id": None
            }

        # Check rate limiting
        if not self._check_rate_limit():
            reset_time = self._get_rate_limit_reset_time()
            error_msg = "Rate limit exceeded - email sending paused"
            logger.warning(f"{error_msg}. Resets at {reset_time}")
            return {
                "success": False,
                "error": error_msg,
                "message_id": None,
                "rate_limit_reset_at": reset_time.isoformat() if reset_time else None
            }

        try:
            # Build SendGrid message
            message = self._build_sendgrid_message(
                to_email=to_email,
                subject=subject,
                html_content=html_content,
                text_content=text_content,
                reply_to=reply_to,
                custom_args=custom_args
            )

            # Send via SendGrid API
            response = self.client.send(message)

            # Process response
            return self._handle_sendgrid_response(response, to_email)

        except HTTPError as e:
            logger.error(f"SendGrid HTTP error sending to {to_email}: {e}")
            error_body = e.body if hasattr(e, 'body') else str(e)
            return {
                "success": False,
                "error": f"SendGrid API error: {error_body}",
                "message_id": None,
                "status_code": e.status_code if hasattr(e, 'status_code') else None
            }

        except Exception as e:
            logger.error(f"Unexpected error sending email to {to_email}: {e}")
            return {
                "success": False,
                "error": f"Email sending failed: {str(e)}",
                "message_id": None
            }

    def _build_sendgrid_message(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None,
        reply_to: Optional[str] = None,
        custom_args: Optional[Dict[str, str]] = None
    ) -> Mail:
        """
        Build SendGrid Mail object.

        Args:
            to_email: Recipient email
            subject: Email subject
            html_content: HTML body
            text_content: Plain text body (optional)
            reply_to: Reply-to address (optional)
            custom_args: Custom tracking args (optional)

        Returns:
            Mail object ready to send
        """
        # Create Mail object
        message = Mail(
            from_email=Email(self.from_email, self.from_name),
            to_emails=To(to_email),
            subject=subject,
            html_content=Content("text/html", html_content)
        )

        # Add plain text version if provided
        if text_content:
            message.add_content(Content("text/plain", text_content))

        # Add reply-to if provided
        if reply_to:
            message.reply_to = Email(reply_to)

        # Add custom tracking arguments if provided
        if custom_args:
            message.custom_arg = custom_args

        return message

    def _handle_sendgrid_response(self, response, to_email: str) -> Dict[str, Any]:
        """
        Process SendGrid API response.

        Args:
            response: SendGrid response object
            to_email: Recipient email (for logging)

        Returns:
            Dict with success status and message ID
        """
        status_code = response.status_code

        # Success: 2xx status codes
        if 200 <= status_code < 300:
            # Extract message ID from headers
            message_id = None
            if hasattr(response, 'headers') and 'X-Message-Id' in response.headers:
                message_id = response.headers['X-Message-Id']

            logger.info(f"✅ Email sent successfully to {to_email} (status: {status_code}, id: {message_id})")

            # Update rate limit tracking
            self._update_rate_limit()

            return {
                "success": True,
                "message_id": message_id,
                "status_code": status_code,
                "error": None
            }

        # Failure: non-2xx status
        else:
            error_msg = f"SendGrid returned status {status_code}"
            logger.error(f"❌ Failed to send email to {to_email}: {error_msg}")

            return {
                "success": False,
                "message_id": None,
                "status_code": status_code,
                "error": error_msg
            }

    def _check_rate_limit(self) -> bool:
        """
        Check if we're within rate limits using Redis-backed storage.

        Returns:
            bool: True if within limits, False if exceeded
        """
        # Get current rate limit state from Redis
        rate_limit_remaining = self._get_rate_limit_remaining()
        rate_limit_reset_time = self._get_rate_limit_reset_time()

        # If rate limit reset time has passed, reset the counter
        if rate_limit_reset_time and datetime.utcnow() >= rate_limit_reset_time:
            self._set_rate_limit_remaining(settings.email_digest_rate_limit)
            self._set_rate_limit_reset_time(None)
            logger.info("Rate limit reset - resuming email sending")
            return True

        # Check if we have capacity
        return rate_limit_remaining > 0

    def _update_rate_limit(self):
        """Update rate limit counter after successful send using Redis-backed storage"""
        # Get current remaining count
        rate_limit_remaining = self._get_rate_limit_remaining()

        # Decrement counter
        rate_limit_remaining -= 1
        self._set_rate_limit_remaining(rate_limit_remaining)

        # Set reset time if we hit the limit
        if rate_limit_remaining <= 0:
            from datetime import timedelta
            reset_time = datetime.utcnow() + timedelta(days=1)
            self._set_rate_limit_reset_time(reset_time)
            logger.warning(
                f"⚠️ Rate limit reached ({settings.email_digest_rate_limit} emails). "
                f"Resets at {reset_time}"
            )

        # Warn at 20% capacity remaining
        elif rate_limit_remaining <= settings.email_digest_rate_limit * 0.2:
            logger.warning(
                f"⚠️ Approaching rate limit: {rate_limit_remaining} emails remaining"
            )

    def get_rate_limit_status(self) -> Dict[str, Any]:
        """
        Get current rate limit status from Redis-backed storage.

        Returns:
            Dict with rate limit info
        """
        rate_limit_remaining = self._get_rate_limit_remaining()
        rate_limit_reset_time = self._get_rate_limit_reset_time()

        return {
            "remaining": rate_limit_remaining,
            "limit": settings.email_digest_rate_limit,
            "reset_at": rate_limit_reset_time.isoformat() if rate_limit_reset_time else None,
            "percentage_used": round(
                ((settings.email_digest_rate_limit - rate_limit_remaining) / settings.email_digest_rate_limit) * 100,
                2
            ),
            "storage": "redis" if self.redis_client else "memory"
        }


# Singleton instance
sendgrid_service = SendGridService()
