"""Service for handling support ticket email notifications."""
from typing import Optional, List
from datetime import datetime
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from models.support_ticket import SupportTicket, TicketComment
from models.user import User
from models.organization import Organization
from services.integrations.email_service import EmailService
from utils.logger import get_logger

logger = get_logger(__name__)


class TicketNotificationService:
    """Service for sending email notifications for ticket events."""

    def __init__(self):
        self.email_service = EmailService()

    async def notify_ticket_created(
        self,
        ticket: SupportTicket,
        creator: User,
        organization: Organization,
        db: AsyncSession
    ):
        """Send notifications when a new ticket is created."""
        try:
            # Notify all admins in the organization
            admins = await self._get_organization_admins(organization.id, db)

            for admin in admins:
                if admin.id != creator.id:  # Don't notify the creator
                    await self._send_ticket_created_email(
                        admin.email,
                        admin.name or admin.email,
                        ticket,
                        creator.name or creator.email,
                        organization.name
                    )

            logger.info(f"Sent ticket creation notifications for ticket {ticket.id}")
        except Exception as e:
            logger.error(f"Failed to send ticket creation notifications: {str(e)}")

    async def notify_comment_added(
        self,
        ticket: SupportTicket,
        comment: TicketComment,
        commenter: User,
        organization: Organization,
        db: AsyncSession
    ):
        """Send notifications when a comment is added to a ticket."""
        try:
            # Notify ticket creator if they didn't add the comment
            if ticket.created_by != commenter.id:
                creator = await db.get(User, ticket.created_by)
                if creator:
                    await self._send_comment_added_email(
                        creator.email,
                        creator.name or creator.email,
                        ticket,
                        comment,
                        commenter.name or commenter.email,
                        organization.name
                    )

            # Notify assigned user if different from creator and commenter
            if ticket.assigned_to and ticket.assigned_to != commenter.id and ticket.assigned_to != ticket.created_by:
                assignee = await db.get(User, ticket.assigned_to)
                if assignee:
                    await self._send_comment_added_email(
                        assignee.email,
                        assignee.name or assignee.email,
                        ticket,
                        comment,
                        commenter.name or commenter.email,
                        organization.name
                    )

            logger.info(f"Sent comment notifications for ticket {ticket.id}")
        except Exception as e:
            logger.error(f"Failed to send comment notifications: {str(e)}")

    async def notify_status_changed(
        self,
        ticket: SupportTicket,
        old_status: str,
        new_status: str,
        changed_by: User,
        organization: Organization,
        db: AsyncSession
    ):
        """Send notifications when ticket status changes."""
        try:
            # Notify ticket creator
            if ticket.created_by != changed_by.id:
                creator = await db.get(User, ticket.created_by)
                if creator:
                    await self._send_status_changed_email(
                        creator.email,
                        creator.name or creator.email,
                        ticket,
                        old_status,
                        new_status,
                        changed_by.name or changed_by.email,
                        organization.name
                    )

            logger.info(f"Sent status change notification for ticket {ticket.id}")
        except Exception as e:
            logger.error(f"Failed to send status change notification: {str(e)}")

    async def notify_ticket_assigned(
        self,
        ticket: SupportTicket,
        assignee: User,
        assigned_by: User,
        organization: Organization,
        db: AsyncSession
    ):
        """Send notification when a ticket is assigned to someone."""
        try:
            # Notify the assignee
            await self._send_ticket_assigned_email(
                assignee.email,
                assignee.name or assignee.email,
                ticket,
                assigned_by.name or assigned_by.email,
                organization.name
            )

            # Also notify the ticket creator
            if ticket.created_by != assignee.id and ticket.created_by != assigned_by.id:
                creator = await db.get(User, ticket.created_by)
                if creator:
                    await self._send_assignment_notification_to_creator(
                        creator.email,
                        creator.name or creator.email,
                        ticket,
                        assignee.name or assignee.email,
                        assigned_by.name or assigned_by.email,
                        organization.name
                    )

            logger.info(f"Sent assignment notifications for ticket {ticket.id}")
        except Exception as e:
            logger.error(f"Failed to send assignment notifications: {str(e)}")

    async def _get_organization_admins(self, org_id: str, db: AsyncSession) -> List[User]:
        """Get all admin users in an organization."""
        from models.organization_member import OrganizationMember, OrganizationRole

        query = select(User).join(
            OrganizationMember,
            User.id == OrganizationMember.user_id
        ).where(
            OrganizationMember.organization_id == org_id,
            OrganizationMember.role.in_([OrganizationRole.admin, OrganizationRole.owner])
        )

        result = await db.execute(query)
        return result.scalars().all()

    async def _send_ticket_created_email(
        self,
        to_email: str,
        to_name: str,
        ticket: SupportTicket,
        creator_name: str,
        org_name: str
    ):
        """Send ticket creation email."""
        subject = f"[{org_name}] New Support Ticket: {ticket.title}"

        html_content = f"""
        <h2>New Support Ticket Created</h2>
        <p>Hi {to_name},</p>
        <p>A new support ticket has been created in {org_name}:</p>

        <div style="border: 1px solid #ddd; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3>{ticket.title}</h3>
            <p><strong>Type:</strong> {ticket.type.replace('_', ' ').title()}</p>
            <p><strong>Priority:</strong> {ticket.priority.title()}</p>
            <p><strong>Created by:</strong> {creator_name}</p>
            <p><strong>Description:</strong></p>
            <p>{ticket.description}</p>
        </div>

        <p>
            <a href="{self._get_ticket_url(ticket.id)}"
               style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
                View Ticket
            </a>
        </p>

        <p>Best regards,<br>PM Master Support System</p>
        """

        await self.email_service.send_email(
            to_email=to_email,
            subject=subject,
            html_content=html_content
        )

    async def _send_comment_added_email(
        self,
        to_email: str,
        to_name: str,
        ticket: SupportTicket,
        comment: TicketComment,
        commenter_name: str,
        org_name: str
    ):
        """Send comment notification email."""
        subject = f"[{org_name}] New Comment on: {ticket.title}"

        html_content = f"""
        <h2>New Comment on Support Ticket</h2>
        <p>Hi {to_name},</p>
        <p>{commenter_name} added a comment to your ticket:</p>

        <div style="border: 1px solid #ddd; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3>{ticket.title}</h3>
            <div style="background: #f5f5f5; padding: 10px; border-radius: 5px; margin-top: 10px;">
                <p><strong>{commenter_name}:</strong></p>
                <p>{comment.comment}</p>
            </div>
        </div>

        <p>
            <a href="{self._get_ticket_url(ticket.id)}"
               style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
                View Conversation
            </a>
        </p>

        <p>Best regards,<br>PM Master Support System</p>
        """

        await self.email_service.send_email(
            to_email=to_email,
            subject=subject,
            html_content=html_content
        )

    async def _send_status_changed_email(
        self,
        to_email: str,
        to_name: str,
        ticket: SupportTicket,
        old_status: str,
        new_status: str,
        changed_by: str,
        org_name: str
    ):
        """Send status change notification email."""
        subject = f"[{org_name}] Ticket Status Updated: {ticket.title}"

        status_color = {
            'open': '#007bff',
            'in_progress': '#ffa500',
            'waiting_for_user': '#ffcc00',
            'resolved': '#28a745',
            'closed': '#6c757d'
        }.get(new_status, '#6c757d')

        html_content = f"""
        <h2>Ticket Status Updated</h2>
        <p>Hi {to_name},</p>
        <p>The status of your ticket has been updated:</p>

        <div style="border: 1px solid #ddd; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3>{ticket.title}</h3>
            <p>
                <strong>Status changed from:</strong>
                <span style="text-transform: uppercase;">{old_status.replace('_', ' ')}</span>
                <strong> to </strong>
                <span style="background: {status_color}; color: white; padding: 2px 8px; border-radius: 3px; text-transform: uppercase;">
                    {new_status.replace('_', ' ')}
                </span>
            </p>
            <p><strong>Changed by:</strong> {changed_by}</p>
            {f'<p><strong>Resolution Notes:</strong> {ticket.resolution_notes}</p>' if ticket.resolution_notes else ''}
        </div>

        <p>
            <a href="{self._get_ticket_url(ticket.id)}"
               style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
                View Ticket
            </a>
        </p>

        <p>Best regards,<br>PM Master Support System</p>
        """

        await self.email_service.send_email(
            to_email=to_email,
            subject=subject,
            html_content=html_content
        )

    async def _send_ticket_assigned_email(
        self,
        to_email: str,
        to_name: str,
        ticket: SupportTicket,
        assigned_by: str,
        org_name: str
    ):
        """Send assignment notification to assignee."""
        subject = f"[{org_name}] Ticket Assigned to You: {ticket.title}"

        priority_color = {
            'low': '#28a745',
            'medium': '#007bff',
            'high': '#ffa500',
            'critical': '#dc3545'
        }.get(ticket.priority, '#6c757d')

        html_content = f"""
        <h2>Ticket Assigned to You</h2>
        <p>Hi {to_name},</p>
        <p>{assigned_by} has assigned the following ticket to you:</p>

        <div style="border: 1px solid #ddd; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3>{ticket.title}</h3>
            <p><strong>Type:</strong> {ticket.type.replace('_', ' ').title()}</p>
            <p>
                <strong>Priority:</strong>
                <span style="background: {priority_color}; color: white; padding: 2px 8px; border-radius: 3px;">
                    {ticket.priority.upper()}
                </span>
            </p>
            <p><strong>Status:</strong> {ticket.status.replace('_', ' ').title()}</p>
            <p><strong>Description:</strong></p>
            <p>{ticket.description}</p>
        </div>

        <p>
            <a href="{self._get_ticket_url(ticket.id)}"
               style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
                View Ticket
            </a>
        </p>

        <p>Best regards,<br>PM Master Support System</p>
        """

        await self.email_service.send_email(
            to_email=to_email,
            subject=subject,
            html_content=html_content
        )

    async def _send_assignment_notification_to_creator(
        self,
        to_email: str,
        to_name: str,
        ticket: SupportTicket,
        assignee_name: str,
        assigned_by: str,
        org_name: str
    ):
        """Send assignment notification to ticket creator."""
        subject = f"[{org_name}] Your Ticket Has Been Assigned: {ticket.title}"

        html_content = f"""
        <h2>Your Ticket Has Been Assigned</h2>
        <p>Hi {to_name},</p>
        <p>Your support ticket has been assigned to {assignee_name} by {assigned_by}:</p>

        <div style="border: 1px solid #ddd; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3>{ticket.title}</h3>
            <p><strong>Assigned to:</strong> {assignee_name}</p>
            <p><strong>Status:</strong> {ticket.status.replace('_', ' ').title()}</p>
        </div>

        <p>{assignee_name} will be working on your ticket and will update you on the progress.</p>

        <p>
            <a href="{self._get_ticket_url(ticket.id)}"
               style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
                View Ticket
            </a>
        </p>

        <p>Best regards,<br>PM Master Support System</p>
        """

        await self.email_service.send_email(
            to_email=to_email,
            subject=subject,
            html_content=html_content
        )

    def _get_ticket_url(self, ticket_id: str) -> str:
        """Get the URL for viewing a ticket."""
        # This should be configured based on your frontend URL
        from config import get_settings
        settings = get_settings()
        base_url = getattr(settings, 'frontend_url', 'http://localhost:8100')
        return f"{base_url}/support-tickets?ticket={ticket_id}"


# Global instance
ticket_notification_service = TicketNotificationService()