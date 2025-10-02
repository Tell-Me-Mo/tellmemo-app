"""
Email Service using Supabase Auth

This service leverages Supabase's built-in email capabilities for:
- User invitations
- Password resets
- Email verification

For custom emails (like weekly reports), we can use Edge Functions or external providers.
"""

import logging
from typing import Optional, Dict, Any
from datetime import datetime
import os

from config import get_settings
from services.auth.auth_service import auth_service
from models.user import User
from models.organization import Organization
from models.organization_member import OrganizationMember

logger = logging.getLogger(__name__)
settings = get_settings()


class EmailService:
    """Service for managing emails through Supabase Auth"""

    def __init__(self):
        self.frontend_url = os.getenv("FRONTEND_URL", "http://localhost:8100")
        self.auth_client = auth_service.client if auth_service.client else None

    async def send_invitation_email(
        self,
        invitation_email: str,
        invitation_token: str,
        organization_name: str = None,
        inviter_name: str = None,
        role: str = None
    ) -> bool:
        """
        Send invitation email using Supabase's inviteUserByEmail

        Note: Supabase will use the invitation email template configured in your
        Supabase dashboard. You can customize it there with variables like:
        - {{ .SiteURL }}
        - {{ .Token }}
        - Custom metadata passed in options
        """
        try:
            if not self.auth_client:
                logger.error("Supabase client not initialized")
                return False

            # Create redirect URL with our custom token for organization association
            redirect_url = f"{self.frontend_url}/invitations/accept?token={invitation_token}"

            # Send invitation through Supabase
            # This uses Supabase's built-in email templates
            response = self.auth_client.auth.admin.invite_user_by_email(
                email=invitation_email,
                options={
                    "redirect_to": redirect_url,
                    "data": {
                        # Custom metadata that can be used in email template
                        "organization_name": organization_name,
                        "inviter_name": inviter_name,
                        "role": role,
                        "invitation_token": invitation_token
                    }
                }
            )

            if response and response.user:
                logger.info(f"Invitation email sent to {invitation_email} via Supabase")
                return True
            else:
                logger.error(f"Failed to send invitation to {invitation_email}")
                return False

        except Exception as e:
            logger.error(f"Error sending invitation email via Supabase: {str(e)}")

            # In development mode, log what would have been sent
            if settings.is_development:
                logger.info(f"""
                Development Mode - Would send invitation:
                To: {invitation_email}
                Organization: {organization_name}
                Inviter: {inviter_name}
                Role: {role}
                Redirect: {redirect_url}
                """)
                return True

            return False

    async def send_password_reset_email(
        self,
        user_email: str
    ) -> bool:
        """
        Send password reset email using Supabase's resetPasswordForEmail

        This uses Supabase's built-in password reset flow and templates
        """
        try:
            if not self.auth_client:
                logger.error("Supabase client not initialized")
                return False

            # Supabase handles the password reset email
            response = self.auth_client.auth.reset_password_for_email(
                email=user_email,
                options={
                    "redirect_to": f"{self.frontend_url}/auth/reset-password"
                }
            )

            logger.info(f"Password reset email sent to {user_email} via Supabase")
            return True

        except Exception as e:
            logger.error(f"Error sending password reset email: {str(e)}")
            return False

    async def send_magic_link_email(
        self,
        user_email: str
    ) -> bool:
        """
        Send magic link for passwordless authentication

        This uses Supabase's built-in magic link feature
        """
        try:
            if not self.auth_client:
                logger.error("Supabase client not initialized")
                return False

            # Send magic link through Supabase
            response = self.auth_client.auth.sign_in_with_otp({
                "email": user_email,
                "options": {
                    "email_redirect_to": f"{self.frontend_url}/dashboard"
                }
            })

            if response:
                logger.info(f"Magic link sent to {user_email} via Supabase")
                return True

            return False

        except Exception as e:
            logger.error(f"Error sending magic link: {str(e)}")
            return False

    async def resend_confirmation_email(
        self,
        user_email: str
    ) -> bool:
        """
        Resend email confirmation for users who haven't verified their email

        This uses Supabase's built-in email verification flow
        """
        try:
            if not self.auth_client:
                logger.error("Supabase client not initialized")
                return False

            # Resend confirmation email
            response = self.auth_client.auth.resend({
                "type": "signup",
                "email": user_email
            })

            if response:
                logger.info(f"Confirmation email resent to {user_email}")
                return True

            return False

        except Exception as e:
            logger.error(f"Error resending confirmation email: {str(e)}")
            return False

    async def send_custom_email(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: str = None
    ) -> bool:
        """
        Send custom emails (like weekly reports) via Supabase Edge Functions

        For custom emails not handled by Supabase Auth, we would typically:
        1. Create a Supabase Edge Function that uses an email provider (Resend, SendGrid, etc.)
        2. Call that function from here

        For now, this is a placeholder that logs in development mode
        """
        try:
            # In a production setup, you would call a Supabase Edge Function here
            # Example:
            # response = await self.auth_client.functions.invoke(
            #     "send-email",
            #     body={
            #         "to": to_email,
            #         "subject": subject,
            #         "html": html_body,
            #         "text": text_body
            #     }
            # )

            if settings.is_development:
                logger.info(f"""
                Development Mode - Custom email:
                To: {to_email}
                Subject: {subject}
                (HTML body omitted for brevity)
                """)
                return True

            logger.warning(
                f"Custom email to {to_email} not sent - Edge Function not configured"
            )
            return False

        except Exception as e:
            logger.error(f"Error sending custom email: {str(e)}")
            return False

    async def send_weekly_report_email(
        self,
        user_email: str,
        user_name: str,
        organization_name: str,
        report_data: Dict[str, Any]
    ) -> bool:
        """
        Send weekly report email

        This would typically be sent via a Supabase Edge Function
        or scheduled job that calls an email service
        """
        subject = f"Your weekly PM Master report for {organization_name}"

        # Generate simple HTML for the report
        html_body = f"""
        <h2>Weekly Report for {organization_name}</h2>
        <p>Hi {user_name},</p>
        <p>Here's your weekly summary:</p>
        <ul>
            <li>Meetings Processed: {report_data.get('meetings_count', 0)}</li>
            <li>Summaries Generated: {report_data.get('summaries_count', 0)}</li>
            <li>Key Decisions: {report_data.get('decisions_count', 0)}</li>
            <li>Action Items: {report_data.get('actions_count', 0)}</li>
        </ul>
        <p><a href="{self.frontend_url}/dashboard">View Full Dashboard</a></p>
        """

        text_body = f"""
        Weekly Report for {organization_name}

        Hi {user_name},

        Here's your weekly summary:
        - Meetings Processed: {report_data.get('meetings_count', 0)}
        - Summaries Generated: {report_data.get('summaries_count', 0)}
        - Key Decisions: {report_data.get('decisions_count', 0)}
        - Action Items: {report_data.get('actions_count', 0)}

        View Full Dashboard: {self.frontend_url}/dashboard
        """

        return await self.send_custom_email(
            to_email=user_email,
            subject=subject,
            html_body=html_body,
            text_body=text_body
        )


# Singleton instance
email_service = EmailService()


"""
CONFIGURATION NOTES:

1. Email Templates in Supabase Dashboard:
   - Go to Authentication > Email Templates in your Supabase dashboard
   - Customize the following templates:
     * Invite user (for invitations)
     * Confirm signup (for email verification)
     * Reset password
     * Magic Link

2. Template Variables:
   You can use these variables in your Supabase email templates:
   - {{ .SiteURL }} - Your site URL
   - {{ .Token }} - The authentication token
   - {{ .TokenHash }} - Hashed version of token
   - {{ .Email }} - User's email
   - Custom metadata from the 'data' field passed in options

3. SMTP Configuration (Optional):
   If you want more control, configure custom SMTP in Supabase:
   - Go to Settings > Auth > SMTP Settings
   - Add your SMTP provider details
   - This allows emails to be sent to any address (not just team members)

4. Edge Functions for Custom Emails:
   For emails not handled by Supabase Auth (like weekly reports):
   - Create a Supabase Edge Function
   - Use an email service like Resend, SendGrid, or AWS SES
   - Call the function from this service

5. Development vs Production:
   - In development, Supabase only sends emails to team members
   - Configure custom SMTP for production use
   - Use Edge Functions for custom transactional emails
"""