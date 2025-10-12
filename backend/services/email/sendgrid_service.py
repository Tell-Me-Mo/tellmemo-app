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

from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class SendGridService:
    """Service for sending emails via SendGrid API"""

    def __init__(self):
        """Initialize SendGrid client"""
        self.api_key = settings.sendgrid_api_key
        self.from_email = settings.email_from_address
        self.from_name = settings.email_from_name
        self.client = None
        self.rate_limit_remaining = settings.email_digest_rate_limit
        self.rate_limit_reset_time = None

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
            error_msg = "Rate limit exceeded - email sending paused"
            logger.warning(f"{error_msg}. Resets at {self.rate_limit_reset_time}")
            return {
                "success": False,
                "error": error_msg,
                "message_id": None
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
        Check if we're within rate limits.

        Returns:
            bool: True if within limits, False if exceeded
        """
        # If rate limit is reset, allow sending
        if self.rate_limit_reset_time and datetime.utcnow() >= self.rate_limit_reset_time:
            self.rate_limit_remaining = settings.email_digest_rate_limit
            self.rate_limit_reset_time = None
            logger.info("Rate limit reset - resuming email sending")

        # Check if we have capacity
        return self.rate_limit_remaining > 0

    def _update_rate_limit(self):
        """Update rate limit counter after successful send"""
        self.rate_limit_remaining -= 1

        # Set reset time if we hit the limit
        if self.rate_limit_remaining <= 0:
            from datetime import timedelta
            self.rate_limit_reset_time = datetime.utcnow() + timedelta(days=1)
            logger.warning(
                f"⚠️ Rate limit reached ({settings.email_digest_rate_limit} emails). "
                f"Resets at {self.rate_limit_reset_time}"
            )

        # Warn at 80% capacity
        elif self.rate_limit_remaining <= settings.email_digest_rate_limit * 0.2:
            logger.warning(
                f"⚠️ Approaching rate limit: {self.rate_limit_remaining} emails remaining"
            )

    def get_rate_limit_status(self) -> Dict[str, Any]:
        """
        Get current rate limit status.

        Returns:
            Dict with rate limit info
        """
        return {
            "remaining": self.rate_limit_remaining,
            "limit": settings.email_digest_rate_limit,
            "reset_at": self.rate_limit_reset_time.isoformat() if self.rate_limit_reset_time else None,
            "percentage_used": round(
                ((settings.email_digest_rate_limit - self.rate_limit_remaining) / settings.email_digest_rate_limit) * 100,
                2
            )
        }


# Singleton instance
sendgrid_service = SendGridService()
