"""
Email Template Service using Jinja2

This service renders HTML and plain text email templates:
- Digest emails (daily/weekly/monthly)
- Onboarding welcome emails
- Inactive user reminder emails
"""

import logging
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
import os

from jinja2 import Environment, FileSystemLoader, TemplateNotFound, select_autoescape

from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class TemplateService:
    """Service for rendering email templates with Jinja2"""

    def __init__(self):
        """Initialize Jinja2 environment"""
        # Get backend directory path
        backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        templates_dir = os.path.join(backend_dir, 'templates', 'email')

        # Initialize Jinja2 environment
        self.env = Environment(
            loader=FileSystemLoader(templates_dir),
            autoescape=select_autoescape(['html', 'xml']),
            trim_blocks=True,
            lstrip_blocks=True
        )

        # Add custom filters
        self.env.filters['format_date'] = self._format_date
        self.env.filters['format_datetime'] = self._format_datetime
        self.env.filters['truncate_text'] = self._truncate_text

        logger.info(f"Template service initialized with directory: {templates_dir}")

    def render_digest_email(self, context: Dict[str, Any]) -> str:
        """
        Render HTML digest email template.

        Args:
            context: Template context with digest data

        Returns:
            Rendered HTML string
        """
        try:
            template = self.env.get_template('digest_email.html')
            return template.render(**context)
        except TemplateNotFound:
            logger.error("Digest email template not found")
            return self._fallback_html(context.get('user_name', 'there'))
        except Exception as e:
            logger.error(f"Error rendering digest email template: {e}")
            return self._fallback_html(context.get('user_name', 'there'))

    def render_digest_email_text(self, context: Dict[str, Any]) -> str:
        """
        Render plain text digest email.

        Args:
            context: Template context with digest data

        Returns:
            Rendered plain text string
        """
        try:
            template = self.env.get_template('digest_email.txt')
            return template.render(**context)
        except TemplateNotFound:
            logger.error("Digest email text template not found")
            return self._fallback_text(context.get('user_name', 'there'))
        except Exception as e:
            logger.error(f"Error rendering digest email text template: {e}")
            return self._fallback_text(context.get('user_name', 'there'))

    def render_onboarding_email(self, context: Dict[str, Any]) -> str:
        """
        Render HTML onboarding email template.

        Args:
            context: Template context with user data

        Returns:
            Rendered HTML string
        """
        try:
            template = self.env.get_template('onboarding_email.html')
            return template.render(**context)
        except TemplateNotFound:
            logger.error("Onboarding email template not found")
            return self._fallback_onboarding_html(context.get('user_name', 'there'))
        except Exception as e:
            logger.error(f"Error rendering onboarding email template: {e}")
            return self._fallback_onboarding_html(context.get('user_name', 'there'))

    def render_onboarding_email_text(self, context: Dict[str, Any]) -> str:
        """
        Render plain text onboarding email.

        Args:
            context: Template context with user data

        Returns:
            Rendered plain text string
        """
        try:
            template = self.env.get_template('onboarding_email.txt')
            return template.render(**context)
        except TemplateNotFound:
            logger.error("Onboarding email text template not found")
            return self._fallback_onboarding_text(context.get('user_name', 'there'))
        except Exception as e:
            logger.error(f"Error rendering onboarding email text template: {e}")
            return self._fallback_onboarding_text(context.get('user_name', 'there'))

    def render_inactive_reminder_email(self, context: Dict[str, Any]) -> str:
        """
        Render HTML inactive user reminder email.

        Args:
            context: Template context with user data

        Returns:
            Rendered HTML string
        """
        try:
            template = self.env.get_template('inactive_reminder.html')
            return template.render(**context)
        except TemplateNotFound:
            logger.error("Inactive reminder email template not found")
            return self._fallback_inactive_html(context.get('user_name', 'there'))
        except Exception as e:
            logger.error(f"Error rendering inactive reminder email template: {e}")
            return self._fallback_inactive_html(context.get('user_name', 'there'))

    def render_inactive_reminder_email_text(self, context: Dict[str, Any]) -> str:
        """
        Render plain text inactive user reminder email.

        Args:
            context: Template context with user data

        Returns:
            Rendered plain text string
        """
        try:
            template = self.env.get_template('inactive_reminder.txt')
            return template.render(**context)
        except TemplateNotFound:
            logger.error("Inactive reminder email text template not found")
            return self._fallback_inactive_text(context.get('user_name', 'there'))
        except Exception as e:
            logger.error(f"Error rendering inactive reminder email text template: {e}")
            return self._fallback_inactive_text(context.get('user_name', 'there'))

    # Custom Jinja2 filters

    def _format_date(self, value: datetime, format: str = '%B %d, %Y') -> str:
        """Format datetime as date string"""
        if not value:
            return ''
        return value.strftime(format)

    def _format_datetime(self, value: datetime, format: str = '%B %d, %Y at %I:%M %p') -> str:
        """Format datetime as datetime string"""
        if not value:
            return ''
        return value.strftime(format)

    def _truncate_text(self, value: str, length: int = 100) -> str:
        """Truncate text to specified length"""
        if not value:
            return ''
        if len(value) <= length:
            return value
        return value[:length].strip() + '...'

    # Fallback templates (simple HTML/text when templates are missing)

    def _fallback_html(self, user_name: str) -> str:
        """Simple fallback HTML for digest emails"""
        return f"""
        <html>
        <body>
            <h1>Your TellMeMo Digest</h1>
            <p>Hi {user_name},</p>
            <p>Your digest is ready, but the template is currently unavailable.</p>
            <p><a href="{settings.frontend_url}/dashboard">View Dashboard</a></p>
        </body>
        </html>
        """

    def _fallback_text(self, user_name: str) -> str:
        """Simple fallback plain text for digest emails"""
        return f"""
        Your TellMeMo Digest

        Hi {user_name},

        Your digest is ready, but the template is currently unavailable.

        View Dashboard: {settings.frontend_url}/dashboard
        """

    def _fallback_onboarding_html(self, user_name: str) -> str:
        """Simple fallback HTML for onboarding emails"""
        return f"""
        <html>
        <body>
            <h1>Welcome to TellMeMo!</h1>
            <p>Hi {user_name},</p>
            <p>Thanks for signing up! Get started by creating your first project.</p>
            <p><a href="{settings.frontend_url}/dashboard">Get Started</a></p>
        </body>
        </html>
        """

    def _fallback_onboarding_text(self, user_name: str) -> str:
        """Simple fallback plain text for onboarding emails"""
        return f"""
        Welcome to TellMeMo!

        Hi {user_name},

        Thanks for signing up! Get started by creating your first project.

        Get Started: {settings.frontend_url}/dashboard
        """

    def _fallback_inactive_html(self, user_name: str) -> str:
        """Simple fallback HTML for inactive reminder emails"""
        return f"""
        <html>
        <body>
            <h1>Ready to get started with TellMeMo?</h1>
            <p>Hi {user_name},</p>
            <p>We noticed you haven't recorded any meetings yet. It's easy to get started!</p>
            <p><a href="{settings.frontend_url}/dashboard">Record Your First Meeting</a></p>
        </body>
        </html>
        """

    def _fallback_inactive_text(self, user_name: str) -> str:
        """Simple fallback plain text for inactive reminder emails"""
        return f"""
        Ready to get started with TellMeMo?

        Hi {user_name},

        We noticed you haven't recorded any meetings yet. It's easy to get started!

        Record Your First Meeting: {settings.frontend_url}/dashboard
        """


# Singleton instance
template_service = TemplateService()
