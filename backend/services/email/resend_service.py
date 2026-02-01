"""
Resend Email Service for Transactional Emails

This service handles all email delivery through Resend API:
- Digest emails (daily/weekly/monthly)
- Onboarding welcome emails
- Inactive user reminders
- Email unsubscribe management

Resend API Reference: https://resend.com/docs/api-reference/emails/send-email
Free tier: 3,000 emails/month, 100 emails/day
"""

import logging
import hashlib
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta

import resend
from resend.exceptions import ResendError
from redis import Redis
from redis.exceptions import RedisError

from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Resend free tier limits
RESEND_DAILY_LIMIT = 100
RESEND_MONTHLY_LIMIT = 3000


class ResendService:
    """
    Service for sending emails via Resend API.

    Features:
    - Redis-backed distributed rate limiting for multi-instance deployments
    - Automatic quota tracking (daily/monthly)
    - Idempotency key support to prevent duplicate sends
    - Proper error handling for all Resend error types
    """

    def __init__(self):
        """Initialize Resend client and Redis for persistent rate limiting"""
        self.api_key = settings.resend_api_key
        self.from_email = settings.email_from_address
        self.from_name = settings.email_from_name
        self.configured = False

        # Redis keys for distributed rate limiting
        self.daily_quota_key = "resend:quota:daily"
        self.daily_reset_key = "resend:quota:daily_reset"
        self.monthly_quota_key = "resend:quota:monthly"
        self.monthly_reset_key = "resend:quota:monthly_reset"
        self.redis_client: Optional[Redis] = None

        # In-memory fallback (used if Redis unavailable)
        self._memory_daily_remaining = RESEND_DAILY_LIMIT
        self._memory_monthly_remaining = RESEND_MONTHLY_LIMIT
        self._memory_daily_reset: Optional[datetime] = None
        self._memory_monthly_reset: Optional[datetime] = None

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

            # Test connection and initialize quotas if not exist
            self.redis_client.ping()
            if not self.redis_client.exists(self.daily_quota_key):
                self.redis_client.set(self.daily_quota_key, RESEND_DAILY_LIMIT)
            if not self.redis_client.exists(self.monthly_quota_key):
                self.redis_client.set(self.monthly_quota_key, RESEND_MONTHLY_LIMIT)
            logger.info("Redis connected for Resend rate limiting")

        except Exception as e:
            logger.warning(f"Redis unavailable for rate limiting, using in-memory fallback: {e}")
            self.redis_client = None

        # Initialize Resend client if API key is configured
        if self.api_key:
            resend.api_key = self.api_key
            self.configured = True
            logger.info("Resend client initialized successfully")
        else:
            logger.warning("Resend API key not configured - email sending disabled")

    def is_configured(self) -> bool:
        """Check if Resend is properly configured."""
        return self.configured

    # ==================== Redis-backed Rate Limiting ====================

    def _get_daily_remaining(self) -> int:
        """Get daily quota remaining from Redis or memory fallback."""
        if self.redis_client:
            try:
                remaining = self.redis_client.get(self.daily_quota_key)
                return int(remaining) if remaining else RESEND_DAILY_LIMIT
            except (RedisError, ValueError, TypeError) as e:
                logger.warning(f"Error reading daily quota from Redis: {e}")
        return self._memory_daily_remaining

    def _set_daily_remaining(self, value: int) -> bool:
        """Set daily quota remaining in Redis and memory."""
        self._memory_daily_remaining = value
        if self.redis_client:
            try:
                self.redis_client.set(self.daily_quota_key, value)
                return True
            except RedisError as e:
                logger.warning(f"Error writing daily quota to Redis: {e}")
        return False

    def _get_monthly_remaining(self) -> int:
        """Get monthly quota remaining from Redis or memory fallback."""
        if self.redis_client:
            try:
                remaining = self.redis_client.get(self.monthly_quota_key)
                return int(remaining) if remaining else RESEND_MONTHLY_LIMIT
            except (RedisError, ValueError, TypeError) as e:
                logger.warning(f"Error reading monthly quota from Redis: {e}")
        return self._memory_monthly_remaining

    def _set_monthly_remaining(self, value: int) -> bool:
        """Set monthly quota remaining in Redis and memory."""
        self._memory_monthly_remaining = value
        if self.redis_client:
            try:
                self.redis_client.set(self.monthly_quota_key, value)
                return True
            except RedisError as e:
                logger.warning(f"Error writing monthly quota to Redis: {e}")
        return False

    def _get_daily_reset_time(self) -> Optional[datetime]:
        """Get daily quota reset time from Redis or memory fallback."""
        if self.redis_client:
            try:
                reset_time_str = self.redis_client.get(self.daily_reset_key)
                if reset_time_str:
                    return datetime.fromisoformat(reset_time_str)
            except (RedisError, ValueError, TypeError) as e:
                logger.warning(f"Error reading daily reset time from Redis: {e}")
        return self._memory_daily_reset

    def _set_daily_reset_time(self, reset_time: Optional[datetime]) -> bool:
        """Set daily quota reset time in Redis and memory."""
        self._memory_daily_reset = reset_time
        if self.redis_client:
            try:
                if reset_time:
                    self.redis_client.set(self.daily_reset_key, reset_time.isoformat())
                else:
                    self.redis_client.delete(self.daily_reset_key)
                return True
            except RedisError as e:
                logger.warning(f"Error writing daily reset time to Redis: {e}")
        return False

    def _get_monthly_reset_time(self) -> Optional[datetime]:
        """Get monthly quota reset time from Redis or memory fallback."""
        if self.redis_client:
            try:
                reset_time_str = self.redis_client.get(self.monthly_reset_key)
                if reset_time_str:
                    return datetime.fromisoformat(reset_time_str)
            except (RedisError, ValueError, TypeError) as e:
                logger.warning(f"Error reading monthly reset time from Redis: {e}")
        return self._memory_monthly_reset

    def _set_monthly_reset_time(self, reset_time: Optional[datetime]) -> bool:
        """Set monthly quota reset time in Redis and memory."""
        self._memory_monthly_reset = reset_time
        if self.redis_client:
            try:
                if reset_time:
                    self.redis_client.set(self.monthly_reset_key, reset_time.isoformat())
                else:
                    self.redis_client.delete(self.monthly_reset_key)
                return True
            except RedisError as e:
                logger.warning(f"Error writing monthly reset time to Redis: {e}")
        return False

    def _check_rate_limit(self) -> Dict[str, Any]:
        """
        Check if we're within rate limits using Redis-backed storage.

        Returns:
            Dict with 'allowed' bool and optional 'error' message
        """
        now = datetime.utcnow()

        # Check and reset daily quota if needed
        daily_reset = self._get_daily_reset_time()
        if daily_reset and now >= daily_reset:
            self._set_daily_remaining(RESEND_DAILY_LIMIT)
            self._set_daily_reset_time(None)
            logger.info("Daily quota reset - resuming email sending")

        # Check and reset monthly quota if needed
        monthly_reset = self._get_monthly_reset_time()
        if monthly_reset and now >= monthly_reset:
            self._set_monthly_remaining(RESEND_MONTHLY_LIMIT)
            self._set_monthly_reset_time(None)
            logger.info("Monthly quota reset - resuming email sending")

        # Check monthly quota first (more restrictive long-term)
        monthly_remaining = self._get_monthly_remaining()
        if monthly_remaining <= 0:
            monthly_reset = self._get_monthly_reset_time()
            return {
                "allowed": False,
                "error": "Monthly email quota exceeded (3,000/month) - upgrade plan or wait for reset",
                "error_type": "monthly_quota",
                "reset_at": monthly_reset.isoformat() if monthly_reset else None
            }

        # Check daily quota
        daily_remaining = self._get_daily_remaining()
        if daily_remaining <= 0:
            daily_reset = self._get_daily_reset_time()
            return {
                "allowed": False,
                "error": "Daily email quota exceeded (100/day) - wait 24 hours",
                "error_type": "daily_quota",
                "reset_at": daily_reset.isoformat() if daily_reset else None
            }

        return {"allowed": True}

    def _update_rate_limit(self, count: int = 1):
        """
        Update rate limit counters after successful send using Redis-backed storage.

        Args:
            count: Number of emails sent (for batch operations)
        """
        now = datetime.utcnow()

        # Update daily quota
        daily_remaining = self._get_daily_remaining() - count
        self._set_daily_remaining(max(0, daily_remaining))

        if daily_remaining <= 0:
            # Set reset time to next day at midnight UTC
            tomorrow = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
            self._set_daily_reset_time(tomorrow)
            logger.warning(f"Daily quota exhausted ({RESEND_DAILY_LIMIT}/day). Resets at {tomorrow}")
        elif daily_remaining <= RESEND_DAILY_LIMIT * 0.2:
            logger.warning(f"Approaching daily limit: {daily_remaining} emails remaining")

        # Update monthly quota
        monthly_remaining = self._get_monthly_remaining() - count
        self._set_monthly_remaining(max(0, monthly_remaining))

        if monthly_remaining <= 0:
            # Set reset time to first day of next month
            if now.month == 12:
                next_month = now.replace(year=now.year + 1, month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
            else:
                next_month = now.replace(month=now.month + 1, day=1, hour=0, minute=0, second=0, microsecond=0)
            self._set_monthly_reset_time(next_month)
            logger.warning(f"Monthly quota exhausted ({RESEND_MONTHLY_LIMIT}/month). Resets at {next_month}")
        elif monthly_remaining <= RESEND_MONTHLY_LIMIT * 0.2:
            logger.warning(f"Approaching monthly limit: {monthly_remaining} emails remaining")

    # ==================== End Rate Limiting ====================

    def _generate_idempotency_key(
        self,
        to_email: str,
        subject: str,
        purpose: Optional[str] = None
    ) -> str:
        """
        Generate idempotency key to prevent duplicate email sends.

        Time window varies by purpose:
        - digest/daily/weekly/monthly: Daily window (prevent duplicates across hour boundaries)
        - Other types: Hourly window (allow resending after 1 hour)

        Args:
            to_email: Recipient email
            subject: Email subject
            purpose: Optional purpose identifier (e.g., 'digest', 'onboarding')

        Returns:
            256-char max idempotency key
        """
        # Use daily window for digest-type emails to prevent duplicates across hour boundaries
        # Use hourly window for other email types to allow resending sooner
        daily_purposes = {'digest', 'daily_digest', 'weekly_digest', 'monthly_digest', 'weekly', 'monthly'}

        if purpose and purpose.lower() in daily_purposes:
            time_window = datetime.utcnow().strftime("%Y-%m-%d")  # Daily window
        else:
            time_window = datetime.utcnow().strftime("%Y-%m-%d-%H")  # Hourly window

        key_data = f"{to_email}:{subject}:{purpose or 'default'}:{time_window}"

        # Hash to ensure under 256 char limit
        return hashlib.sha256(key_data.encode()).hexdigest()

    def send_email(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None,
        reply_to: Optional[str] = None,
        custom_args: Optional[Dict[str, str]] = None,
        idempotency_key: Optional[str] = None,
        attachments: Optional[List[Dict[str, Any]]] = None,
        scheduled_at: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Send email via Resend API.

        Args:
            to_email: Recipient email address (or comma-separated for multiple, max 50)
            subject: Email subject line
            html_content: HTML email body
            text_content: Plain text fallback (auto-generated from HTML if omitted)
            reply_to: Reply-to email address
            custom_args: Custom tracking arguments as tags (max 256 chars each)
            idempotency_key: Unique key to prevent duplicate sends (auto-generated if not provided)
            attachments: List of attachment dicts with 'content'/'path' and 'filename'
            scheduled_at: Schedule send time (ISO 8601 or natural language like "in 1 hour")

        Returns:
            Dict with success status, message_id, and error info
        """
        if not self.is_configured():
            return {
                "success": False,
                "error": "Resend not configured - RESEND_API_KEY is empty",
                "message_id": None
            }

        # Pre-send rate limit check
        rate_check = self._check_rate_limit()
        if not rate_check["allowed"]:
            logger.warning(f"Rate limit exceeded for {to_email}: {rate_check['error']}")
            return {
                "success": False,
                "error": rate_check["error"],
                "error_type": rate_check.get("error_type"),
                "message_id": None,
                "rate_limit_reset_at": rate_check.get("reset_at")
            }

        try:
            # Build recipient list
            recipients = [e.strip() for e in to_email.split(",")] if "," in to_email else [to_email]

            # Validate recipient count (Resend max is 50)
            if len(recipients) > 50:
                return {
                    "success": False,
                    "error": "Too many recipients (max 50 per request)",
                    "message_id": None
                }

            # Build Resend params
            params: Dict[str, Any] = {
                "from": f"{self.from_name} <{self.from_email}>",
                "to": recipients,
                "subject": subject,
                "html": html_content,
            }

            # Add optional text version
            if text_content:
                params["text"] = text_content

            # Add reply-to
            if reply_to:
                params["reply_to"] = reply_to

            # Convert custom_args to tags format
            # Tags must be ASCII alphanumeric, underscores, dashes only
            if custom_args:
                tags = []
                for key, value in custom_args.items():
                    # Sanitize tag names/values (max 256 chars each)
                    safe_key = "".join(c for c in key if c.isalnum() or c in "_-")[:256]
                    safe_value = str(value)[:256]
                    if safe_key and safe_value:
                        tags.append({"name": safe_key, "value": safe_value})
                if tags:
                    params["tags"] = tags

            # Add attachments if provided
            if attachments:
                params["attachments"] = attachments

            # Add scheduled send time
            if scheduled_at:
                params["scheduled_at"] = scheduled_at

            # Generate idempotency key if not provided
            # Purpose extracted from custom_args if available
            purpose = custom_args.get("email_type") if custom_args else None
            idem_key = idempotency_key or self._generate_idempotency_key(to_email, subject, purpose)

            # Build send options with idempotency key
            send_options: Dict[str, Any] = {"idempotency_key": idem_key}

            # Send via Resend API with idempotency key in options
            response = resend.Emails.send(params, send_options)

            # Extract message ID from response
            # Response is a dataclass with 'id' attribute
            message_id = response.get("id") if isinstance(response, dict) else getattr(response, "id", None)

            if message_id:
                # Update rate limit counters (count recipients for quota tracking)
                recipient_count = len(recipients)
                self._update_rate_limit(recipient_count)

                logger.info(f"Email sent successfully to {to_email} (id: {message_id})")
                return {
                    "success": True,
                    "message_id": message_id,
                    "error": None
                }
            else:
                logger.error(f"Resend returned no message ID for {to_email}")
                return {
                    "success": False,
                    "message_id": None,
                    "error": "No message ID in response"
                }

        except ResendError as e:
            error_message = str(e)
            logger.error(f"Resend API error sending to {to_email}: {error_message}")

            # Parse error type for specific handling
            error_response = self._handle_resend_error(e, to_email)
            return error_response

        except Exception as e:
            logger.error(f"Unexpected error sending email to {to_email}: {e}")
            return {
                "success": False,
                "error": f"Unexpected error: {str(e)}",
                "message_id": None
            }

    def _handle_resend_error(self, error: ResendError, to_email: str) -> Dict[str, Any]:
        """
        Handle Resend API errors with specific responses.

        Error codes reference: https://resend.com/docs/api-reference/errors
        """
        error_str = str(error).lower()

        # Rate limit errors (429)
        if "rate_limit_exceeded" in error_str:
            logger.warning(f"Rate limit exceeded for {to_email} - implement backoff")
            return {
                "success": False,
                "error": "Rate limit exceeded - too many requests per second",
                "error_type": "rate_limit",
                "message_id": None,
                "retry_after": 1  # Resend allows 2 req/sec, so wait 1 second
            }

        if "daily_quota_exceeded" in error_str:
            logger.warning(f"Daily quota exceeded - cannot send to {to_email}")
            return {
                "success": False,
                "error": "Daily email quota exceeded - wait 24 hours or upgrade plan",
                "error_type": "daily_quota",
                "message_id": None
            }

        if "monthly_quota_exceeded" in error_str:
            logger.error(f"Monthly quota exceeded - cannot send to {to_email}")
            return {
                "success": False,
                "error": "Monthly email quota exceeded - upgrade plan required",
                "error_type": "monthly_quota",
                "message_id": None
            }

        # Validation errors (422)
        if "invalid_from_address" in error_str:
            logger.error(f"Invalid from address: {self.from_email}")
            return {
                "success": False,
                "error": f"Invalid sender address format: {self.from_email}",
                "error_type": "validation",
                "message_id": None
            }

        if "validation_error" in error_str or "missing_required_field" in error_str:
            return {
                "success": False,
                "error": f"Validation error: {error}",
                "error_type": "validation",
                "message_id": None
            }

        # Authentication errors (401/403)
        if "invalid_api_key" in error_str or "missing_api_key" in error_str:
            logger.error("Invalid or missing Resend API key")
            return {
                "success": False,
                "error": "Invalid API key - check RESEND_API_KEY configuration",
                "error_type": "auth",
                "message_id": None
            }

        # Domain verification errors (403)
        if "domain" in error_str and ("verify" in error_str or "mismatch" in error_str):
            logger.error(f"Domain verification issue for {self.from_email}")
            return {
                "success": False,
                "error": f"Domain not verified - verify {self.from_email.split('@')[1]} in Resend dashboard",
                "error_type": "domain",
                "message_id": None
            }

        # Idempotency errors (409)
        if "idempotent" in error_str:
            logger.warning(f"Idempotency conflict for {to_email}")
            return {
                "success": False,
                "error": "Duplicate request detected - email may have already been sent",
                "error_type": "duplicate",
                "message_id": None
            }

        # Server errors (500)
        if "internal_server_error" in error_str or "application_error" in error_str:
            return {
                "success": False,
                "error": "Resend service temporarily unavailable - retry later",
                "error_type": "server",
                "message_id": None,
                "retry_after": 60
            }

        # Generic error
        return {
            "success": False,
            "error": f"Resend API error: {error}",
            "error_type": "unknown",
            "message_id": None
        }

    def send_batch(
        self,
        emails: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Send multiple emails in a batch (up to 100 emails).

        Args:
            emails: List of email dicts, each containing:
                - to: recipient email
                - subject: email subject
                - html: HTML content
                - text: optional plain text
                - reply_to: optional reply-to address
                - tags: optional list of tag dicts

        Returns:
            Dict with success status and list of results
        """
        if not self.is_configured():
            return {
                "success": False,
                "error": "Resend not configured",
                "results": []
            }

        if len(emails) > 100:
            return {
                "success": False,
                "error": "Batch size exceeds maximum of 100 emails",
                "results": []
            }

        # Pre-send rate limit check for batch size
        rate_check = self._check_rate_limit()
        if not rate_check["allowed"]:
            logger.warning(f"Rate limit exceeded for batch send: {rate_check['error']}")
            return {
                "success": False,
                "error": rate_check["error"],
                "error_type": rate_check.get("error_type"),
                "results": [],
                "rate_limit_reset_at": rate_check.get("reset_at")
            }

        # Check if batch would exceed remaining quota
        daily_remaining = self._get_daily_remaining()
        if len(emails) > daily_remaining:
            logger.warning(f"Batch size ({len(emails)}) exceeds daily remaining ({daily_remaining})")
            return {
                "success": False,
                "error": f"Batch size ({len(emails)}) exceeds daily quota remaining ({daily_remaining})",
                "error_type": "daily_quota",
                "results": []
            }

        try:
            # Format emails for batch send and track original recipients
            batch_params = []
            recipients = []
            for email in emails:
                to_addr = email["to"]
                recipients.append(to_addr)
                params = {
                    "from": f"{self.from_name} <{self.from_email}>",
                    "to": [to_addr] if isinstance(to_addr, str) else to_addr,
                    "subject": email["subject"],
                    "html": email["html"],
                }
                if email.get("text"):
                    params["text"] = email["text"]
                if email.get("reply_to"):
                    params["reply_to"] = email["reply_to"]
                if email.get("tags"):
                    params["tags"] = email["tags"]
                batch_params.append(params)

            # Send batch
            response = resend.Batch.send(batch_params)

            # Response contains list of results for each email
            # Each result has either 'id' (success) or 'error' (failure)
            raw_results = response.get("data", []) if isinstance(response, dict) else getattr(response, "data", [])

            # Process results with granular per-email status
            processed_results = []
            successful_count = 0
            failed_count = 0

            for i, result in enumerate(raw_results):
                recipient = recipients[i] if i < len(recipients) else f"email_{i}"

                if isinstance(result, dict):
                    if result.get("id"):
                        # Success
                        processed_results.append({
                            "recipient": recipient,
                            "success": True,
                            "message_id": result["id"],
                            "error": None
                        })
                        successful_count += 1
                    elif result.get("error"):
                        # Individual email failed
                        processed_results.append({
                            "recipient": recipient,
                            "success": False,
                            "message_id": None,
                            "error": result.get("error", {}).get("message", str(result["error"]))
                        })
                        failed_count += 1
                        logger.warning(f"Batch email failed for {recipient}: {result.get('error')}")
                    else:
                        # Has id attribute (dataclass response)
                        msg_id = getattr(result, "id", None)
                        if msg_id:
                            processed_results.append({
                                "recipient": recipient,
                                "success": True,
                                "message_id": msg_id,
                                "error": None
                            })
                            successful_count += 1
                        else:
                            processed_results.append({
                                "recipient": recipient,
                                "success": False,
                                "message_id": None,
                                "error": "Unknown response format"
                            })
                            failed_count += 1
                else:
                    # Dataclass with id attribute
                    msg_id = getattr(result, "id", None)
                    if msg_id:
                        processed_results.append({
                            "recipient": recipient,
                            "success": True,
                            "message_id": msg_id,
                            "error": None
                        })
                        successful_count += 1
                    else:
                        processed_results.append({
                            "recipient": recipient,
                            "success": False,
                            "message_id": None,
                            "error": "Unknown response format"
                        })
                        failed_count += 1

            # Update rate limit counters only for successful sends
            if successful_count > 0:
                self._update_rate_limit(successful_count)

            logger.info(f"Batch sent: {successful_count} succeeded, {failed_count} failed")

            # Return partial success if some emails failed
            return {
                "success": failed_count == 0,
                "partial_success": successful_count > 0 and failed_count > 0,
                "results": processed_results,
                "summary": {
                    "total": len(emails),
                    "successful": successful_count,
                    "failed": failed_count
                },
                "error": f"{failed_count} emails failed to send" if failed_count > 0 else None
            }

        except ResendError as e:
            logger.error(f"Batch send error: {e}")
            # Return error with empty results for all emails
            return {
                "success": False,
                "partial_success": False,
                "error": str(e),
                "results": [
                    {"recipient": r, "success": False, "message_id": None, "error": str(e)}
                    for r in recipients
                ] if recipients else [],
                "summary": {
                    "total": len(emails),
                    "successful": 0,
                    "failed": len(emails)
                }
            }
        except Exception as e:
            logger.error(f"Unexpected batch error: {e}")
            return {
                "success": False,
                "partial_success": False,
                "error": str(e),
                "results": [],
                "summary": {
                    "total": len(emails),
                    "successful": 0,
                    "failed": len(emails)
                }
            }

    def get_rate_limit_status(self) -> Dict[str, Any]:
        """
        Get current rate limit status from Redis-backed storage.

        Returns:
            Dict with rate limit info including quotas and usage percentages
        """
        daily_remaining = self._get_daily_remaining()
        monthly_remaining = self._get_monthly_remaining()
        daily_reset = self._get_daily_reset_time()
        monthly_reset = self._get_monthly_reset_time()

        return {
            "provider": "resend",
            "storage": "redis" if self.redis_client else "memory",
            "quotas": {
                "daily": {
                    "limit": RESEND_DAILY_LIMIT,
                    "remaining": daily_remaining,
                    "used": RESEND_DAILY_LIMIT - daily_remaining,
                    "percentage_used": round(
                        ((RESEND_DAILY_LIMIT - daily_remaining) / RESEND_DAILY_LIMIT) * 100, 2
                    ),
                    "reset_at": daily_reset.isoformat() if daily_reset else None
                },
                "monthly": {
                    "limit": RESEND_MONTHLY_LIMIT,
                    "remaining": monthly_remaining,
                    "used": RESEND_MONTHLY_LIMIT - monthly_remaining,
                    "percentage_used": round(
                        ((RESEND_MONTHLY_LIMIT - monthly_remaining) / RESEND_MONTHLY_LIMIT) * 100, 2
                    ),
                    "reset_at": monthly_reset.isoformat() if monthly_reset else None
                }
            },
            "rate_limit": {
                "requests_per_second": 2  # Resend default
            },
            "limits": {
                "free_daily": RESEND_DAILY_LIMIT,
                "free_monthly": RESEND_MONTHLY_LIMIT,
                "max_recipients_per_email": 50,
                "max_batch_size": 100,
                "max_attachment_size_mb": 40
            }
        }


# Singleton instance
resend_service = ResendService()
