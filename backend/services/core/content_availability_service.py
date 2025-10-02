"""Service for checking content availability across different entity types."""

import uuid
from typing import Dict, Any, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
from datetime import datetime, timedelta

from models.content import Content
from models.project import Project
from models.program import Program
from models.portfolio import Portfolio
from models.summary import Summary, SummaryType
from utils.logger import get_logger

logger = get_logger(__name__)


class ContentAvailabilityService:
    """Service to check content availability for summary generation."""

    async def check_project_content(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        date_start: Optional[datetime] = None,
        date_end: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """Check content availability for a project."""
        try:
            # Build query for content count
            query = select(func.count(Content.id)).where(
                Content.project_id == project_id
            )

            # Add date filtering if provided
            if date_start and date_end:
                query = query.where(
                    and_(
                        Content.uploaded_at >= date_start,
                        Content.uploaded_at <= date_end
                    )
                )

            # Get content count
            result = await session.execute(query)
            content_count = result.scalar() or 0

            # Get latest content date
            latest_query = select(func.max(Content.uploaded_at)).where(
                Content.project_id == project_id
            )
            latest_result = await session.execute(latest_query)
            latest_content_date = latest_result.scalar()

            # Get content breakdown by type
            breakdown_query = select(
                Content.content_type,
                func.count(Content.id)
            ).where(
                Content.project_id == project_id
            ).group_by(Content.content_type)

            if date_start and date_end:
                breakdown_query = breakdown_query.where(
                    and_(
                        Content.uploaded_at >= date_start,
                        Content.uploaded_at <= date_end
                    )
                )

            breakdown_result = await session.execute(breakdown_query)
            content_breakdown = dict(breakdown_result.fetchall())

            # Check for recent summaries
            summary_query = select(func.count(Summary.id)).where(
                and_(
                    Summary.project_id == project_id,
                    Summary.created_at >= datetime.utcnow() - timedelta(days=7)
                )
            )
            summary_result = await session.execute(summary_query)
            recent_summaries_count = summary_result.scalar() or 0

            return {
                "has_content": content_count > 0,
                "content_count": content_count,
                "latest_content_date": latest_content_date.isoformat() if latest_content_date else None,
                "content_breakdown": content_breakdown,
                "recent_summaries_count": recent_summaries_count,
                "can_generate_summary": content_count > 0,
                "message": self._get_availability_message(content_count, "project")
            }

        except Exception as e:
            logger.error(f"Error checking project content availability: {e}")
            raise

    async def check_program_content(
        self,
        session: AsyncSession,
        program_id: uuid.UUID,
        date_start: Optional[datetime] = None,
        date_end: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """Check content availability for a program."""
        try:
            # Get all projects in the program
            projects_query = select(Project.id).where(
                Project.program_id == program_id
            )
            projects_result = await session.execute(projects_query)
            project_ids = [row[0] for row in projects_result.fetchall()]

            if not project_ids:
                return {
                    "has_content": False,
                    "content_count": 0,
                    "project_count": 0,
                    "projects_with_content": 0,
                    "can_generate_summary": False,
                    "message": "No projects found in this program"
                }

            # Count content across all projects
            content_query = select(func.count(Content.id)).where(
                Content.project_id.in_(project_ids)
            )

            if date_start and date_end:
                content_query = content_query.where(
                    and_(
                        Content.uploaded_at >= date_start,
                        Content.uploaded_at <= date_end
                    )
                )

            content_result = await session.execute(content_query)
            total_content_count = content_result.scalar() or 0

            # Count projects with content
            projects_with_content_query = select(
                func.count(func.distinct(Content.project_id))
            ).where(
                Content.project_id.in_(project_ids)
            )

            if date_start and date_end:
                projects_with_content_query = projects_with_content_query.where(
                    and_(
                        Content.uploaded_at >= date_start,
                        Content.uploaded_at <= date_end
                    )
                )

            projects_with_content_result = await session.execute(projects_with_content_query)
            projects_with_content = projects_with_content_result.scalar() or 0

            # Get content breakdown by project
            project_breakdown_query = select(
                Project.name,
                func.count(Content.id)
            ).join(
                Content, Content.project_id == Project.id
            ).where(
                Project.program_id == program_id
            ).group_by(Project.name)

            if date_start and date_end:
                project_breakdown_query = project_breakdown_query.where(
                    and_(
                        Content.uploaded_at >= date_start,
                        Content.uploaded_at <= date_end
                    )
                )

            project_breakdown_result = await session.execute(project_breakdown_query)
            project_content_breakdown = dict(project_breakdown_result.fetchall())

            return {
                "has_content": total_content_count > 0,
                "content_count": total_content_count,
                "project_count": len(project_ids),
                "projects_with_content": projects_with_content,
                "project_content_breakdown": project_content_breakdown,
                "can_generate_summary": total_content_count > 0,
                "message": self._get_availability_message(total_content_count, "program")
            }

        except Exception as e:
            logger.error(f"Error checking program content availability: {e}")
            raise

    async def check_portfolio_content(
        self,
        session: AsyncSession,
        portfolio_id: uuid.UUID,
        date_start: Optional[datetime] = None,
        date_end: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """Check content availability for a portfolio."""
        try:
            # Get all programs in the portfolio
            programs_query = select(Program.id).where(
                Program.portfolio_id == portfolio_id
            )
            programs_result = await session.execute(programs_query)
            program_ids = [row[0] for row in programs_result.fetchall()]

            # Get all projects (both direct and through programs)
            projects_query = select(Project.id).where(
                or_(
                    Project.portfolio_id == portfolio_id,
                    Project.program_id.in_(program_ids) if program_ids else False
                )
            )
            projects_result = await session.execute(projects_query)
            project_ids = [row[0] for row in projects_result.fetchall()]

            if not project_ids:
                return {
                    "has_content": False,
                    "content_count": 0,
                    "program_count": len(program_ids),
                    "project_count": 0,
                    "projects_with_content": 0,
                    "can_generate_summary": False,
                    "message": "No projects found in this portfolio"
                }

            # Count content across all projects
            content_query = select(func.count(Content.id)).where(
                Content.project_id.in_(project_ids)
            )

            if date_start and date_end:
                content_query = content_query.where(
                    and_(
                        Content.uploaded_at >= date_start,
                        Content.uploaded_at <= date_end
                    )
                )

            content_result = await session.execute(content_query)
            total_content_count = content_result.scalar() or 0

            # Count projects with content
            projects_with_content_query = select(
                func.count(func.distinct(Content.project_id))
            ).where(
                Content.project_id.in_(project_ids)
            )

            if date_start and date_end:
                projects_with_content_query = projects_with_content_query.where(
                    and_(
                        Content.uploaded_at >= date_start,
                        Content.uploaded_at <= date_end
                    )
                )

            projects_with_content_result = await session.execute(projects_with_content_query)
            projects_with_content = projects_with_content_result.scalar() or 0

            # Get program breakdown
            program_breakdown = {}
            for program_id in program_ids:
                program_data = await self.check_program_content(
                    session, program_id, date_start, date_end
                )
                # Get program name
                program_query = select(Program.name).where(Program.id == program_id)
                program_result = await session.execute(program_query)
                program_name = program_result.scalar()
                if program_name:
                    program_breakdown[program_name] = {
                        "content_count": program_data["content_count"],
                        "projects_with_content": program_data["projects_with_content"]
                    }

            return {
                "has_content": total_content_count > 0,
                "content_count": total_content_count,
                "program_count": len(program_ids),
                "project_count": len(project_ids),
                "projects_with_content": projects_with_content,
                "program_breakdown": program_breakdown,
                "can_generate_summary": total_content_count > 0,
                "message": self._get_availability_message(total_content_count, "portfolio")
            }

        except Exception as e:
            logger.error(f"Error checking portfolio content availability: {e}")
            raise

    def _get_availability_message(self, content_count: int, entity_type: str) -> str:
        """Generate appropriate message based on content availability."""
        if content_count == 0:
            return f"No content available for {entity_type} summary generation. Please upload meeting transcripts or documents first."
        elif content_count < 3:
            return f"Limited content available ({content_count} items). Summary quality may be limited."
        else:
            return f"Sufficient content available ({content_count} items) for comprehensive summary generation."

    async def get_summary_generation_stats(
        self,
        session: AsyncSession,
        entity_type: str,
        entity_id: uuid.UUID
    ) -> Dict[str, Any]:
        """Get statistics about previous summary generations."""
        try:
            # Build query based on entity type
            if entity_type == "project":
                query = select(Summary).where(Summary.project_id == entity_id)
            elif entity_type == "program":
                query = select(Summary).where(Summary.program_id == entity_id)
            elif entity_type == "portfolio":
                query = select(Summary).where(Summary.portfolio_id == entity_id)
            else:
                raise ValueError(f"Invalid entity type: {entity_type}")

            # Get all summaries
            result = await session.execute(query.order_by(Summary.created_at.desc()))
            summaries = result.scalars().all()

            if not summaries:
                return {
                    "total_summaries": 0,
                    "last_generated": None,
                    "average_generation_time": 0,
                    "formats_generated": []
                }

            # Calculate statistics
            total_summaries = len(summaries)
            last_summary = summaries[0]

            # Calculate average generation time
            generation_times = [s.generation_time_ms for s in summaries if s.generation_time_ms]
            avg_generation_time = sum(generation_times) / len(generation_times) if generation_times else 0

            # Get unique formats
            formats_generated = list(set(s.format for s in summaries if hasattr(s, 'format')))

            # Get summary types breakdown
            type_breakdown = {}
            for s in summaries:
                summary_type = s.summary_type.value if hasattr(s.summary_type, 'value') else str(s.summary_type)
                type_breakdown[summary_type] = type_breakdown.get(summary_type, 0) + 1

            return {
                "total_summaries": total_summaries,
                "last_generated": last_summary.created_at.isoformat(),
                "average_generation_time": round(avg_generation_time / 1000, 2) if avg_generation_time else 0,  # Convert to seconds
                "formats_generated": formats_generated,
                "type_breakdown": type_breakdown,
                "recent_summary_id": str(last_summary.id)
            }

        except Exception as e:
            logger.error(f"Error getting summary generation stats: {e}")
            return {
                "total_summaries": 0,
                "last_generated": None,
                "average_generation_time": 0,
                "formats_generated": []
            }


# Singleton instance
content_availability_service = ContentAvailabilityService()