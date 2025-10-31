"""
Business Metrics for TellMeMo

Tracks key business KPIs and product metrics for monitoring business health,
user engagement, and product performance.

These metrics help answer questions like:
- How many active users do we have?
- What's our LLM cost per user?
- How engaged are users with the product?
- What's our content processing throughput?
- Are users getting value from RAG queries?
"""

from typing import Optional
from opentelemetry import metrics

# Singleton business metrics instance
_business_metrics_instance: Optional["BusinessMetrics"] = None


class BusinessMetrics:
    """
    Business-focused metrics registry for TellMeMo.

    Tracks KPIs across user engagement, content processing, costs, and quality.
    """

    def __init__(self, meter_name: str = "tellmemo.business"):
        """Initialize business metrics with a dedicated meter."""
        self.meter = metrics.get_meter(meter_name)

        # === USER ENGAGEMENT METRICS ===
        self.active_users_daily = self.meter.create_up_down_counter(
            name="business.users.active.daily",
            description="Number of unique users active in the last 24 hours",
            unit="users",
        )

        self.user_sessions_total = self.meter.create_counter(
            name="business.user.sessions.total",
            description="Total number of user sessions (login events)",
            unit="sessions",
        )

        self.user_questions_total = self.meter.create_counter(
            name="business.user.questions.total",
            description="Total number of questions asked by users",
            unit="questions",
        )

        self.user_projects_created = self.meter.create_counter(
            name="business.projects.created",
            description="Total number of projects created",
            unit="projects",
        )

        self.user_engagement_duration = self.meter.create_histogram(
            name="business.user.session.duration",
            description="Duration of user sessions in seconds",
            unit="s",
        )

        # === CONTENT PROCESSING METRICS ===
        self.meetings_processed_total = self.meter.create_counter(
            name="business.meetings.processed.total",
            description="Total number of meetings processed (transcribed + summarized)",
            unit="meetings",
        )

        self.emails_processed_total = self.meter.create_counter(
            name="business.emails.processed.total",
            description="Total number of emails processed",
            unit="emails",
        )

        self.documents_uploaded_total = self.meter.create_counter(
            name="business.documents.uploaded.total",
            description="Total number of documents uploaded",
            unit="documents",
        )

        self.content_size_total = self.meter.create_counter(
            name="business.content.size.bytes",
            description="Total size of content processed in bytes",
            unit="bytes",
        )

        self.content_processing_time = self.meter.create_histogram(
            name="business.content.processing.duration",
            description="Time taken to process content (transcription + summarization)",
            unit="s",
        )

        # === RAG QUERY QUALITY METRICS ===
        self.queries_with_results = self.meter.create_counter(
            name="business.rag.queries.with_results",
            description="Number of RAG queries that returned results",
            unit="queries",
        )

        self.queries_without_results = self.meter.create_counter(
            name="business.rag.queries.without_results",
            description="Number of RAG queries that returned no results",
            unit="queries",
        )

        self.query_refinements_total = self.meter.create_counter(
            name="business.rag.query.refinements",
            description="Number of follow-up queries (indicates user refinement)",
            unit="queries",
        )

        self.query_response_quality = self.meter.create_histogram(
            name="business.rag.query.quality_score",
            description="Perceived quality score of RAG responses (0-10)",
            unit="score",
        )

        # === LLM COST METRICS ===
        self.llm_cost_per_user = self.meter.create_histogram(
            name="business.llm.cost.per_user",
            description="LLM cost per user in USD cents",
            unit="cents",
        )

        self.llm_cost_per_query = self.meter.create_histogram(
            name="business.llm.cost.per_query",
            description="LLM cost per query in USD cents",
            unit="cents",
        )

        self.monthly_llm_cost = self.meter.create_counter(
            name="business.llm.cost.monthly",
            description="Total monthly LLM cost in USD cents",
            unit="cents",
        )

        self.llm_provider_cost_breakdown = self.meter.create_counter(
            name="business.llm.cost.by_provider",
            description="LLM cost breakdown by provider (Claude, OpenAI, DeepSeek)",
            unit="cents",
        )

        # === SYSTEM HEALTH & QUALITY METRICS ===
        self.error_rate_critical = self.meter.create_counter(
            name="business.errors.critical",
            description="Number of critical errors affecting user experience",
            unit="errors",
        )

        self.user_feedback_received = self.meter.create_counter(
            name="business.feedback.received",
            description="Number of user feedback submissions",
            unit="feedback",
        )

        self.feature_usage = self.meter.create_counter(
            name="business.features.usage",
            description="Usage count of specific features",
            unit="uses",
        )

        # === PERFORMANCE METRICS ===
        self.api_response_time_p95 = self.meter.create_histogram(
            name="business.api.response_time.p95",
            description="95th percentile API response time",
            unit="ms",
        )

        self.system_availability = self.meter.create_up_down_counter(
            name="business.system.availability",
            description="System availability indicator (1 = up, 0 = down)",
            unit="status",
        )

        # === CONVERSION & RETENTION METRICS ===
        self.user_onboarding_completed = self.meter.create_counter(
            name="business.users.onboarding.completed",
            description="Number of users who completed onboarding",
            unit="users",
        )

        self.user_retention_rate = self.meter.create_histogram(
            name="business.users.retention.rate",
            description="User retention rate (% returning after 7 days)",
            unit="percent",
        )

        self.daily_revenue = self.meter.create_counter(
            name="business.revenue.daily",
            description="Daily revenue in USD cents",
            unit="cents",
        )

        # === ORGANIZATION-LEVEL METRICS (Multi-Tenant) ===
        self.org_active_users = self.meter.create_up_down_counter(
            name="business.organization.users.active",
            description="Number of active users per organization",
            unit="users",
        )

        self.org_query_volume = self.meter.create_counter(
            name="business.organization.queries.total",
            description="Total queries per organization",
            unit="queries",
        )

        self.org_llm_cost = self.meter.create_counter(
            name="business.organization.llm_cost",
            description="LLM cost per organization in USD cents",
            unit="cents",
        )

        self.org_content_volume = self.meter.create_counter(
            name="business.organization.content.volume",
            description="Total content processed per organization in bytes",
            unit="bytes",
        )

        self.org_seats_utilized = self.meter.create_histogram(
            name="business.organization.seats.utilization",
            description="Percentage of seats utilized per organization",
            unit="percent",
        )

        # === TIME-TO-VALUE METRICS ===
        self.time_to_first_query = self.meter.create_histogram(
            name="business.users.time_to_first_query",
            description="Time from signup to first successful query in seconds",
            unit="s",
        )

        self.time_to_first_project = self.meter.create_histogram(
            name="business.users.time_to_first_project",
            description="Time from signup to first project creation in seconds",
            unit="s",
        )

        self.first_query_success_rate = self.meter.create_counter(
            name="business.users.first_query_success",
            description="Success rate of first query (1=success, 0=fail)",
            unit="queries",
        )

        self.queries_until_success = self.meter.create_histogram(
            name="business.users.queries_until_success",
            description="Number of queries until first successful result",
            unit="queries",
        )

        # === CONTENT COVERAGE & QUALITY ===
        self.content_coverage_gaps = self.meter.create_counter(
            name="business.content.coverage_gaps",
            description="Queries that found no relevant content (gap detection)",
            unit="gaps",
        )

        self.content_staleness = self.meter.create_histogram(
            name="business.content.staleness",
            description="Average age of content retrieved in days",
            unit="days",
        )

        self.content_utilization_rate = self.meter.create_histogram(
            name="business.content.utilization_rate",
            description="Percentage of content accessed in last 30 days",
            unit="percent",
        )

        self.low_relevance_results = self.meter.create_counter(
            name="business.rag.low_relevance_results",
            description="Queries with low-relevance results (score < threshold)",
            unit="queries",
        )

        # === AT-RISK USER DETECTION (Churn Prediction) ===
        self.user_engagement_decline = self.meter.create_counter(
            name="business.users.engagement_decline",
            description="Users with declining engagement (churn risk)",
            unit="users",
        )

        self.inactive_users = self.meter.create_up_down_counter(
            name="business.users.inactive",
            description="Users inactive for >7 days (churn risk)",
            unit="users",
        )

        self.weekly_active_users = self.meter.create_up_down_counter(
            name="business.users.active.weekly",
            description="Number of unique users active in last 7 days",
            unit="users",
        )

        self.user_activity_streak = self.meter.create_histogram(
            name="business.users.activity_streak",
            description="Consecutive days of user activity",
            unit="days",
        )

        # === SLA & PERFORMANCE COMPLIANCE ===
        self.sla_compliance_rate = self.meter.create_histogram(
            name="business.sla.compliance_rate",
            description="Percentage of requests meeting SLA (e.g., <2s response time)",
            unit="percent",
        )

        self.sla_violations = self.meter.create_counter(
            name="business.sla.violations",
            description="Number of SLA violations (latency, errors, downtime)",
            unit="violations",
        )

        self.error_budget_remaining = self.meter.create_histogram(
            name="business.sla.error_budget_remaining",
            description="Remaining error budget for the period (percentage)",
            unit="percent",
        )

        self.availability_sla = self.meter.create_histogram(
            name="business.sla.availability",
            description="System availability percentage (target: 99.9%)",
            unit="percent",
        )

    # === HELPER METHODS ===

    def record_user_session(self, user_id: str, duration_seconds: float):
        """Record a user session."""
        self.user_sessions_total.add(1, {"user_id": user_id})
        self.user_engagement_duration.record(duration_seconds, {"user_id": user_id})

    def record_user_question(self, user_id: str, project_id: str, has_results: bool):
        """Record a user asking a question."""
        attributes = {"user_id": user_id, "project_id": project_id}
        self.user_questions_total.add(1, attributes)

        if has_results:
            self.queries_with_results.add(1, attributes)
        else:
            self.queries_without_results.add(1, attributes)

    def record_meeting_processed(
        self,
        user_id: str,
        project_id: str,
        duration_seconds: float,
        content_size_bytes: int,
        success: bool = True,
    ):
        """Record a meeting being processed (transcribed + summarized)."""
        attributes = {
            "user_id": user_id,
            "project_id": project_id,
            "status": "success" if success else "failed",
        }

        if success:
            self.meetings_processed_total.add(1, attributes)
            self.content_processing_time.record(duration_seconds, attributes)
            self.content_size_total.add(content_size_bytes, attributes)

    def record_project_created(self, user_id: str, organization_id: Optional[str] = None):
        """Record a new project creation."""
        attributes = {"user_id": user_id}
        if organization_id:
            attributes["organization_id"] = organization_id
        self.user_projects_created.add(1, attributes)

    def record_llm_cost(
        self,
        provider: str,
        cost_cents: float,
        operation_type: str,  # "query", "summarization", "transcription"
        user_id: Optional[str] = None,
    ):
        """Record LLM cost for cost tracking and optimization."""
        attributes = {
            "provider": provider,
            "operation": operation_type,
        }

        # Track total cost by provider
        self.llm_provider_cost_breakdown.add(cost_cents, attributes)
        self.monthly_llm_cost.add(cost_cents, {"provider": provider})

        # Track per-operation cost
        if operation_type == "query":
            self.llm_cost_per_query.record(cost_cents, attributes)

        # Track per-user cost if user_id is available
        if user_id:
            self.llm_cost_per_user.record(cost_cents, {**attributes, "user_id": user_id})

    def record_feature_usage(self, feature_name: str, user_id: str):
        """Record usage of a specific feature."""
        self.feature_usage.add(1, {"feature": feature_name, "user_id": user_id})

    def record_user_feedback(self, rating: int, feature: str):
        """Record user feedback (1-5 stars or 1-10 score)."""
        attributes = {"feature": feature, "rating_bucket": f"{rating}"}
        self.user_feedback_received.add(1, attributes)

    def record_critical_error(self, error_type: str, endpoint: str):
        """Record a critical error that affects user experience."""
        self.error_rate_critical.add(1, {"error_type": error_type, "endpoint": endpoint})

    def record_onboarding_completed(self, user_id: str):
        """Record a user completing onboarding flow."""
        self.user_onboarding_completed.add(1, {"user_id": user_id})

    def update_active_users(self, count: int, time_window: str = "24h"):
        """Update the count of active users in a time window."""
        self.active_users_daily.add(count, {"window": time_window})

    def record_system_availability(self, is_available: bool):
        """Record system availability status."""
        self.system_availability.add(1 if is_available else 0)

    # === ORGANIZATION-LEVEL TRACKING ===

    def record_org_query(self, organization_id: str, user_id: str, cost_cents: float = 0):
        """Record a query for organization-level tracking."""
        attributes = {"organization_id": organization_id}
        self.org_query_volume.add(1, attributes)
        if cost_cents > 0:
            self.org_llm_cost.add(cost_cents, attributes)

    def record_org_content_processed(self, organization_id: str, content_size_bytes: int):
        """Record content processed for organization."""
        self.org_content_volume.add(
            content_size_bytes,
            {"organization_id": organization_id}
        )

    def update_org_active_users(self, organization_id: str, active_user_count: int):
        """Update active users for an organization."""
        self.org_active_users.add(active_user_count, {"organization_id": organization_id})

    def record_org_seat_utilization(self, organization_id: str, utilization_percent: float):
        """Record seat utilization for an organization."""
        self.org_seats_utilized.record(
            utilization_percent,
            {"organization_id": organization_id}
        )

    # === TIME-TO-VALUE TRACKING ===

    def record_time_to_first_query(self, user_id: str, seconds_since_signup: float, success: bool):
        """Record time from signup to first query."""
        self.time_to_first_query.record(
            seconds_since_signup,
            {"user_id": user_id, "success": str(success).lower()}
        )
        self.first_query_success_rate.add(
            1 if success else 0,
            {"user_id": user_id}
        )

    def record_time_to_first_project(self, user_id: str, seconds_since_signup: float):
        """Record time from signup to first project creation."""
        self.time_to_first_project.record(
            seconds_since_signup,
            {"user_id": user_id}
        )

    def record_queries_until_success(self, user_id: str, query_count: int):
        """Record how many queries it took until first successful result."""
        self.queries_until_success.record(query_count, {"user_id": user_id})

    # === CONTENT COVERAGE & QUALITY TRACKING ===

    def record_content_coverage_gap(
        self,
        query: str,
        project_id: str,
        user_id: str,
        reason: str = "no_results"
    ):
        """Record a query that found no relevant content."""
        self.content_coverage_gaps.add(
            1,
            {
                "project_id": project_id,
                "user_id": user_id,
                "reason": reason  # "no_results", "low_relevance", "stale_content"
            }
        )

    def record_content_staleness(self, content_age_days: float, content_id: str):
        """Record the age of content being retrieved."""
        self.content_staleness.record(
            content_age_days,
            {"content_type": "meeting"}  # Can track by type
        )

    def record_low_relevance_result(
        self,
        query: str,
        project_id: str,
        relevance_score: float,
        threshold: float = 0.3
    ):
        """Record queries with low-relevance results."""
        if relevance_score < threshold:
            self.low_relevance_results.add(
                1,
                {
                    "project_id": project_id,
                    "score_range": f"{int(relevance_score * 10)}/10"
                }
            )

    # === AT-RISK USER DETECTION ===

    def flag_engagement_decline(self, user_id: str, decline_percent: float):
        """Flag a user with declining engagement (churn risk)."""
        self.user_engagement_decline.add(
            1,
            {
                "user_id": user_id,
                "decline_level": "high" if decline_percent > 50 else "medium"
            }
        )

    def update_inactive_users(self, count: int, days_inactive: int = 7):
        """Update count of inactive users (churn risk)."""
        self.inactive_users.add(count, {"days_inactive": str(days_inactive)})

    def update_weekly_active_users(self, count: int):
        """Update weekly active users count."""
        self.weekly_active_users.add(count, {"window": "7d"})

    def record_user_activity_streak(self, user_id: str, consecutive_days: int):
        """Record user's activity streak (engagement indicator)."""
        self.user_activity_streak.record(
            consecutive_days,
            {"user_id": user_id}
        )

    # === SLA COMPLIANCE TRACKING ===

    def record_sla_compliance(
        self,
        operation: str,
        response_time_ms: float,
        sla_threshold_ms: float = 2000,
        success: bool = True
    ):
        """Record SLA compliance for operations."""
        met_sla = response_time_ms <= sla_threshold_ms and success

        if not met_sla:
            self.sla_violations.add(
                1,
                {
                    "operation": operation,
                    "violation_type": "latency" if response_time_ms > sla_threshold_ms else "error"
                }
            )

    def update_sla_compliance_rate(self, compliance_percent: float, operation: str):
        """Update SLA compliance rate for an operation."""
        self.sla_compliance_rate.record(
            compliance_percent,
            {"operation": operation}
        )

    def update_error_budget(self, remaining_percent: float):
        """Update remaining error budget."""
        self.error_budget_remaining.record(remaining_percent)

    def record_availability(self, availability_percent: float):
        """Record system availability percentage."""
        self.availability_sla.record(availability_percent)


def get_business_metrics() -> BusinessMetrics:
    """
    Get the singleton BusinessMetrics instance.

    Returns:
        BusinessMetrics: Global business metrics registry

    Example:
        ```python
        from observability.business_metrics import get_business_metrics

        metrics = get_business_metrics()
        metrics.record_user_question(
            user_id="user_123",
            project_id="proj_456",
            has_results=True
        )
        ```
    """
    global _business_metrics_instance

    if _business_metrics_instance is None:
        _business_metrics_instance = BusinessMetrics()

    return _business_metrics_instance
