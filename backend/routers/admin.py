from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from typing import Optional

from config import get_settings
from utils.logger import get_logger
from db.database import db_manager
from db.multi_tenant_vector_store import multi_tenant_vector_store

router = APIRouter()
settings = get_settings()
logger = get_logger(__name__)


class ResetRequest(BaseModel):
    confirm: bool


class ResetResponse(BaseModel):
    status: str
    deleted: dict
    message: str


@router.delete("/reset", response_model=ResetResponse)
async def reset_database(
    request: ResetRequest,
    x_api_key: Optional[str] = Header(None)
):
    """
    Reset both PostgreSQL and Qdrant databases for development testing.

    Requires API key authentication and development environment.
    Clears all tables and recreates empty Qdrant collection.
    """
    # Security checks
    if not settings.enable_reset_endpoint:
        raise HTTPException(status_code=403, detail="Reset endpoint is disabled")

    if not settings.is_development:
        raise HTTPException(status_code=403, detail="Reset endpoint is only available in development")

    if x_api_key != settings.reset_api_key:
        raise HTTPException(status_code=401, detail="Invalid API key")

    if not request.confirm:
        raise HTTPException(status_code=400, detail="Confirmation required")

    logger.warning("Database reset requested - clearing all data")

    deleted_counts = {
        "ticket_attachments": 0,
        "ticket_comments": 0,
        "support_tickets": 0,
        "lessons_learned": 0,
        "notifications": 0,
        "tasks": 0,
        "risks": 0,
        "integrations": 0,
        "organization_members": 0,
        "users": 0,
        "organizations": 0,
        "queries": 0,
        "summaries": 0,
        "content": 0,
        "activities": 0,
        "project_members": 0,
        "projects": 0,
        "programs": 0,
        "portfolios": 0,
        "vectors": 0
    }

    try:
        # Reset PostgreSQL database
        logger.info("Clearing PostgreSQL tables...")

        # Get table counts before deletion using raw queries
        # Support system tables
        ticket_attachments_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM ticket_attachments")
        ticket_comments_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM ticket_comments")
        tickets_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM support_tickets")

        # Project-related tables
        lessons_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM lessons_learned")
        notifications_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM notifications")
        tasks_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM tasks")
        risks_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM risks")

        # Organization and user tables
        integrations_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM integrations")
        org_members_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM organization_members")
        users_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM users")
        organizations_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM organizations")

        # Core content tables
        queries_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM queries")
        summaries_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM summaries")
        content_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM content")
        activities_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM activities")

        # Project hierarchy tables
        members_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM project_members")
        projects_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM projects")
        programs_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM programs")
        portfolios_count = await db_manager.execute_raw_query("SELECT COUNT(*) FROM portfolios")

        # Store counts
        deleted_counts["ticket_attachments"] = ticket_attachments_count[0][0] if ticket_attachments_count else 0
        deleted_counts["ticket_comments"] = ticket_comments_count[0][0] if ticket_comments_count else 0
        deleted_counts["support_tickets"] = tickets_count[0][0] if tickets_count else 0
        deleted_counts["lessons_learned"] = lessons_count[0][0] if lessons_count else 0
        deleted_counts["notifications"] = notifications_count[0][0] if notifications_count else 0
        deleted_counts["tasks"] = tasks_count[0][0] if tasks_count else 0
        deleted_counts["risks"] = risks_count[0][0] if risks_count else 0
        deleted_counts["integrations"] = integrations_count[0][0] if integrations_count else 0
        deleted_counts["organization_members"] = org_members_count[0][0] if org_members_count else 0
        deleted_counts["users"] = users_count[0][0] if users_count else 0
        deleted_counts["organizations"] = organizations_count[0][0] if organizations_count else 0
        deleted_counts["queries"] = queries_count[0][0] if queries_count else 0
        deleted_counts["summaries"] = summaries_count[0][0] if summaries_count else 0
        deleted_counts["content"] = content_count[0][0] if content_count else 0
        deleted_counts["activities"] = activities_count[0][0] if activities_count else 0
        deleted_counts["project_members"] = members_count[0][0] if members_count else 0
        deleted_counts["projects"] = projects_count[0][0] if projects_count else 0
        deleted_counts["programs"] = programs_count[0][0] if programs_count else 0
        deleted_counts["portfolios"] = portfolios_count[0][0] if portfolios_count else 0

        # Clear all tables with CASCADE to handle foreign keys
        # Order is important due to foreign key constraints
        async with db_manager.transaction():
            # Support system (deepest dependencies first)
            await db_manager.execute_raw_command("TRUNCATE TABLE ticket_attachments CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE ticket_comments CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE support_tickets CASCADE")

            # Project-related data
            await db_manager.execute_raw_command("TRUNCATE TABLE lessons_learned CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE notifications CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE tasks CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE risks CASCADE")

            # Core content
            await db_manager.execute_raw_command("TRUNCATE TABLE queries CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE summaries CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE content CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE activities CASCADE")

            # Project hierarchy
            await db_manager.execute_raw_command("TRUNCATE TABLE project_members CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE projects CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE programs CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE portfolios CASCADE")

            # Organization and users
            await db_manager.execute_raw_command("TRUNCATE TABLE integrations CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE organization_members CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE users CASCADE")
            await db_manager.execute_raw_command("TRUNCATE TABLE organizations CASCADE")

            logger.info("PostgreSQL tables cleared successfully")

        # Reset Qdrant vector database
        logger.info("Clearing Qdrant vector collections...")

        # Clear all multi-tenant collections
        org_collections = await multi_tenant_vector_store.list_organization_collections()
        for collection in org_collections:
            org_id = collection.get("organization_id")
            if org_id:
                vectors_count = collection.get("vectors_count", 0) or 0
                deleted_counts["vectors"] += vectors_count
                await multi_tenant_vector_store.delete_organization_collections(org_id)

        logger.info(f"Cleared {len(org_collections)} organization collections")

        total_deleted = sum(v for v in deleted_counts.values() if v is not None)
        logger.warning(f"Database reset completed - {total_deleted} total items deleted")

        return ResetResponse(
            status="success",
            deleted=deleted_counts,
            message=f"All data cleared successfully. Deleted {total_deleted} items total."
        )

    except Exception as e:
        logger.error(f"Database reset failed: {e}")
        raise HTTPException(status_code=500, detail=f"Reset operation failed: {str(e)}")