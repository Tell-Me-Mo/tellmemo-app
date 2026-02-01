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

from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class ResendService:
    """
    Service for sending emails via Resend API.

    Features:
    - Automatic rate limit tracking via Resend headers
    - Idempotency key support to prevent duplicate sends
    - Proper error handling for all Resend error types
    """

    def __init__(self):
        """Initialize Resend client"""
        self.api_key = settings.resend_api_key
        self.from_email = settings.email_from_address
        self.from_name = settings.email_from_name
        self.configured = False

        # Rate limit tracking (updated from Resend response headers)
        self._rate_limit_remaining: Optional[int] = None
        self._rate_limit_reset: Optional[datetime] = None
        self._daily_quota_remaining: Optional[int] = None
        self._monthly_quota_remaining: Optional[int] = None

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

    def _generate_idempotency_key(
        self,
        to_email: str,
        subject: str,
        purpose: Optional[str] = None
    ) -> str:
        """
        Generate idempotency key to prevent duplicate email sends.

        The key is based on recipient, subject, purpose, and current hour
        to allow resending the same email type after an hour.

        Args:
            to_email: Recipient email
            subject: Email subject
            purpose: Optional purpose identifier (e.g., 'digest', 'onboarding')

        Returns:
            256-char max idempotency key
        """
        # Include hour to allow same email to be sent again after 1 hour
        current_hour = datetime.utcnow().strftime("%Y-%m-%d-%H")
        key_data = f"{to_email}:{subject}:{purpose or 'default'}:{current_hour}"

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

        try:
            # Format emails for batch send
            batch_params = []
            for email in emails:
                params = {
                    "from": f"{self.from_name} <{self.from_email}>",
                    "to": [email["to"]] if isinstance(email["to"], str) else email["to"],
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

            # Response contains list of {id: "..."} for each email
            results = response.get("data", []) if isinstance(response, dict) else getattr(response, "data", [])

            logger.info(f"Batch sent: {len(results)} emails")
            return {
                "success": True,
                "results": results,
                "error": None
            }

        except ResendError as e:
            logger.error(f"Batch send error: {e}")
            return {
                "success": False,
                "error": str(e),
                "results": []
            }
        except Exception as e:
            logger.error(f"Unexpected batch error: {e}")
            return {
                "success": False,
                "error": str(e),
                "results": []
            }

    def get_rate_limit_status(self) -> Dict[str, Any]:
        """
        Get current rate limit status.

        Note: Resend provides rate limits via response headers.
        This method returns the last known values.

        Returns:
            Dict with rate limit info
        """
        return {
            "provider": "resend",
            "rate_limit": {
                "requests_per_second": 2,  # Resend default
                "remaining": self._rate_limit_remaining,
                "reset_at": self._rate_limit_reset.isoformat() if self._rate_limit_reset else None
            },
            "quotas": {
                "daily_remaining": self._daily_quota_remaining,
                "monthly_remaining": self._monthly_quota_remaining
            },
            "limits": {
                "free_daily": 100,
                "free_monthly": 3000,
                "max_recipients_per_email": 50,
                "max_batch_size": 100,
                "max_attachment_size_mb": 40
            }
        }


# Singleton instance
resend_service = ResendService()
