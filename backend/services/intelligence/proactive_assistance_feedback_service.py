"""
Proactive Assistance Feedback Service

Handles user feedback collection, storage, and analytics to improve AI assistance quality.

Features:
- Collect user feedback (helpful/not helpful)
- Track feedback by assistance type
- Calculate acceptance rates and confidence correlation
- Identify problematic patterns
- Suggest threshold adjustments

Analytics:
- Acceptance rate by assistance type
- Confidence score correlation with feedback
- False positive/negative detection
- Temporal trends
"""

import logging
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from models.proactive_assistance_feedback import ProactiveAssistanceFeedback
from utils.logger import get_logger

logger = get_logger(__name__)


@dataclass
class FeedbackMetrics:
    """Aggregate feedback metrics for analytics."""
    total_feedback: int
    helpful_count: int
    not_helpful_count: int
    acceptance_rate: float
    avg_confidence_helpful: float
    avg_confidence_not_helpful: float
    confidence_correlation: float  # Positive = higher confidence → more helpful
    sample_size_sufficient: bool  # True if sample size >= 30


@dataclass
class AssistanceTypeMetrics:
    """Metrics for a specific assistance type."""
    assistance_type: str
    metrics: FeedbackMetrics
    recommended_confidence_threshold: Optional[float]  # Based on feedback analysis
    needs_improvement: bool  # True if acceptance rate < 70%


class ProactiveAssistanceFeedbackService:
    """Service for managing proactive assistance feedback and analytics."""

    # Minimum sample size for statistical significance
    MIN_SAMPLE_SIZE = 30

    # Target acceptance rate (70%)
    TARGET_ACCEPTANCE_RATE = 0.70

    async def record_feedback(
        self,
        db: AsyncSession,
        session_id: str,
        insight_id: str,
        project_id: str,
        organization_id: str,
        user_id: str,
        assistance_type: str,
        is_helpful: bool,
        confidence_score: Optional[float] = None,
        feedback_text: Optional[str] = None,
        feedback_category: Optional[str] = None,
        metadata: Optional[Dict] = None
    ) -> ProactiveAssistanceFeedback:
        """
        Record user feedback for a proactive assistance suggestion.

        Args:
            db: Database session
            session_id: Live meeting session ID
            insight_id: Unique ID of the proactive assistance
            project_id: Project UUID
            organization_id: Organization UUID
            user_id: User UUID
            assistance_type: Type of assistance (auto_answer, clarification_needed, etc.)
            is_helpful: True if thumbs up, False if thumbs down
            confidence_score: Original confidence score of the assistance
            feedback_text: Optional detailed feedback from user
            feedback_category: Optional category (wrong_answer, not_relevant, etc.)
            metadata: Optional metadata for context

        Returns:
            Created feedback record
        """
        try:
            feedback = ProactiveAssistanceFeedback(
                session_id=session_id,
                insight_id=insight_id,
                project_id=project_id,
                organization_id=organization_id,
                user_id=user_id,
                assistance_type=assistance_type,
                is_helpful=is_helpful,
                confidence_score=confidence_score,
                feedback_text=feedback_text,
                feedback_category=feedback_category,
                feedback_metadata=metadata
            )

            db.add(feedback)
            await db.commit()
            await db.refresh(feedback)

            logger.info(
                f"Recorded {'positive' if is_helpful else 'negative'} feedback for "
                f"{assistance_type} (insight_id={insight_id})"
            )

            return feedback

        except Exception as e:
            logger.error(f"Error recording feedback: {e}")
            await db.rollback()
            raise

    async def get_feedback_metrics(
        self,
        db: AsyncSession,
        assistance_type: Optional[str] = None,
        project_id: Optional[str] = None,
        organization_id: Optional[str] = None,
        days: int = 30
    ) -> FeedbackMetrics:
        """
        Get aggregate feedback metrics.

        Args:
            db: Database session
            assistance_type: Filter by assistance type (None = all types)
            project_id: Filter by project (None = all projects)
            organization_id: Filter by organization (None = all orgs)
            days: Number of days to analyze (default: 30)

        Returns:
            Aggregate feedback metrics
        """
        try:
            # Build query filters
            filters = [
                ProactiveAssistanceFeedback.created_at >= datetime.utcnow() - timedelta(days=days)
            ]
            if assistance_type:
                filters.append(ProactiveAssistanceFeedback.assistance_type == assistance_type)
            if project_id:
                filters.append(ProactiveAssistanceFeedback.project_id == project_id)
            if organization_id:
                filters.append(ProactiveAssistanceFeedback.organization_id == organization_id)

            # Count helpful vs not helpful
            helpful_query = select(func.count()).where(
                and_(*filters, ProactiveAssistanceFeedback.is_helpful == True)
            )
            not_helpful_query = select(func.count()).where(
                and_(*filters, ProactiveAssistanceFeedback.is_helpful == False)
            )

            helpful_result = await db.execute(helpful_query)
            not_helpful_result = await db.execute(not_helpful_query)

            helpful_count = helpful_result.scalar() or 0
            not_helpful_count = not_helpful_result.scalar() or 0
            total_feedback = helpful_count + not_helpful_count

            # Calculate acceptance rate
            acceptance_rate = helpful_count / total_feedback if total_feedback > 0 else 0.0

            # Calculate average confidence scores
            avg_conf_helpful_query = select(
                func.avg(ProactiveAssistanceFeedback.confidence_score)
            ).where(
                and_(*filters, ProactiveAssistanceFeedback.is_helpful == True)
            )
            avg_conf_not_helpful_query = select(
                func.avg(ProactiveAssistanceFeedback.confidence_score)
            ).where(
                and_(*filters, ProactiveAssistanceFeedback.is_helpful == False)
            )

            avg_conf_helpful_result = await db.execute(avg_conf_helpful_query)
            avg_conf_not_helpful_result = await db.execute(avg_conf_not_helpful_query)

            avg_confidence_helpful = avg_conf_helpful_result.scalar() or 0.0
            avg_confidence_not_helpful = avg_conf_not_helpful_result.scalar() or 0.0

            # Calculate confidence correlation (simple difference)
            confidence_correlation = avg_confidence_helpful - avg_confidence_not_helpful

            return FeedbackMetrics(
                total_feedback=total_feedback,
                helpful_count=helpful_count,
                not_helpful_count=not_helpful_count,
                acceptance_rate=acceptance_rate,
                avg_confidence_helpful=avg_confidence_helpful,
                avg_confidence_not_helpful=avg_confidence_not_helpful,
                confidence_correlation=confidence_correlation,
                sample_size_sufficient=total_feedback >= self.MIN_SAMPLE_SIZE
            )

        except Exception as e:
            logger.error(f"Error calculating feedback metrics: {e}")
            raise

    async def get_metrics_by_type(
        self,
        db: AsyncSession,
        project_id: Optional[str] = None,
        organization_id: Optional[str] = None,
        days: int = 30
    ) -> List[AssistanceTypeMetrics]:
        """
        Get feedback metrics broken down by assistance type.

        Args:
            db: Database session
            project_id: Filter by project (None = all projects)
            organization_id: Filter by organization (None = all orgs)
            days: Number of days to analyze (default: 30)

        Returns:
            List of metrics per assistance type
        """
        try:
            # Get all unique assistance types
            types_query = select(ProactiveAssistanceFeedback.assistance_type).distinct()
            types_result = await db.execute(types_query)
            assistance_types = [row[0] for row in types_result]

            results = []
            for assistance_type in assistance_types:
                metrics = await self.get_feedback_metrics(
                    db=db,
                    assistance_type=assistance_type,
                    project_id=project_id,
                    organization_id=organization_id,
                    days=days
                )

                # Recommend confidence threshold adjustment
                recommended_threshold = None
                if metrics.sample_size_sufficient:
                    # If acceptance rate is low and avg confidence for helpful is > current threshold
                    # Recommend raising threshold
                    if metrics.acceptance_rate < self.TARGET_ACCEPTANCE_RATE:
                        if metrics.avg_confidence_helpful > 0.75:
                            recommended_threshold = min(0.95, metrics.avg_confidence_helpful + 0.05)

                needs_improvement = (
                    metrics.sample_size_sufficient and
                    metrics.acceptance_rate < self.TARGET_ACCEPTANCE_RATE
                )

                results.append(AssistanceTypeMetrics(
                    assistance_type=assistance_type,
                    metrics=metrics,
                    recommended_confidence_threshold=recommended_threshold,
                    needs_improvement=needs_improvement
                ))

            return results

        except Exception as e:
            logger.error(f"Error getting metrics by type: {e}")
            raise

    async def get_problematic_patterns(
        self,
        db: AsyncSession,
        organization_id: Optional[str] = None,
        days: int = 7
    ) -> Dict[str, List[str]]:
        """
        Identify problematic patterns from negative feedback.

        Args:
            db: Database session
            organization_id: Filter by organization (None = all orgs)
            days: Number of days to analyze (default: 7)

        Returns:
            Dictionary mapping assistance_type to list of issues
        """
        try:
            filters = [
                ProactiveAssistanceFeedback.is_helpful == False,
                ProactiveAssistanceFeedback.created_at >= datetime.utcnow() - timedelta(days=days)
            ]
            if organization_id:
                filters.append(ProactiveAssistanceFeedback.organization_id == organization_id)

            # Query negative feedback
            query = select(ProactiveAssistanceFeedback).where(and_(*filters))
            result = await db.execute(query)
            feedback_records = result.scalars().all()

            # Group by assistance type and collect patterns
            patterns: Dict[str, List[str]] = {}
            for record in feedback_records:
                if record.assistance_type not in patterns:
                    patterns[record.assistance_type] = []

                if record.feedback_category:
                    patterns[record.assistance_type].append(record.feedback_category)
                elif record.feedback_text:
                    patterns[record.assistance_type].append("Manual feedback provided")

            # Summarize patterns
            summary = {}
            for assistance_type, issues in patterns.items():
                unique_issues = list(set(issues))
                summary[assistance_type] = unique_issues

            return summary

        except Exception as e:
            logger.error(f"Error identifying problematic patterns: {e}")
            raise


# Singleton instance
_feedback_service: Optional[ProactiveAssistanceFeedbackService] = None


def get_feedback_service() -> ProactiveAssistanceFeedbackService:
    """Get singleton feedback service instance."""
    global _feedback_service
    if _feedback_service is None:
        _feedback_service = ProactiveAssistanceFeedbackService()
    return _feedback_service
