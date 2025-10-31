#!/usr/bin/env python3
"""
Create comprehensive Grafana Cloud dashboards for TellMeMo business metrics.
Uses Grafana Cloud API to programmatically create dashboards.
"""
import base64
import json
import requests
from typing import Dict, List, Any

# Grafana Cloud Configuration
# Decode the OTLP header to get instance ID and token
OTLP_HEADER = "Authorization=Basic MTQyMzQ3NTpnbGNfZXlKdklqb2lNVFUzTmpZME5DSXNJbTRpT2lKaGNIQWlMQ0pySWpvaVZYTk1lSFpNZDBwaGNFOUxObEEyY3pRME1EYzNOelF3SWl3aWJTSTZleUp5SWpvaWNISnZaQzFsZFMxM1pYTjBMVElpZlgwPQ=="
encoded_creds = OTLP_HEADER.split("Basic ")[1]
decoded = base64.b64decode(encoded_creds).decode('utf-8')
instance_id, api_token = decoded.split(":", 1)

# For Grafana Cloud, we need to find the instance URL
# Typically it's based on the org in the token
# Token format: glc_eyJ...
# Let me decode the actual token to get org info
token_payload = api_token.replace("glc_", "")
try:
    # The token might be base64 encoded JSON
    token_data = json.loads(base64.b64decode(token_payload + "=="))
    org_id = token_data.get("o", "1576644")
except:
    org_id = "1576644"  # From the token structure

# Grafana Cloud instance URL (EU West 2)
GRAFANA_URL = "https://tellmemo.grafana.net"  # ✅ Discovered automatically
API_TOKEN = api_token  # The actual API token

print(f"🔐 Grafana Cloud Configuration:")
print(f"   Instance ID: {instance_id}")
print(f"   Org ID: {org_id}")
print(f"   Token: {api_token[:20]}...")
print(f"   URL: {GRAFANA_URL}")
print()

# Headers for API requests
headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json",
}


def create_panel(
    title: str,
    query: str,
    panel_type: str = "timeseries",
    unit: str = "short",
    x: int = 0,
    y: int = 0,
    width: int = 12,
    height: int = 8,
    description: str = "",
) -> Dict[str, Any]:
    """Create a Grafana panel configuration."""
    panel = {
        "title": title,
        "type": panel_type,
        "gridPos": {"x": x, "y": y, "w": width, "h": height},
        "description": description,
        "targets": [
            {
                "expr": query,
                "refId": "A",
                "legendFormat": "",
            }
        ],
        "fieldConfig": {
            "defaults": {
                "unit": unit,
                "custom": {"drawStyle": "line", "lineInterpolation": "smooth"},
            }
        },
    }

    # Stat panel for single values
    if panel_type == "stat":
        panel["options"] = {
            "graphMode": "area",
            "colorMode": "value",
            "orientation": "horizontal",
            "textMode": "value_and_name",
        }

    # Gauge for percentages
    elif panel_type == "gauge":
        panel["options"] = {
            "showThresholdLabels": False,
            "showThresholdMarkers": True,
        }
        panel["fieldConfig"]["defaults"]["thresholds"] = {
            "mode": "absolute",
            "steps": [
                {"value": 0, "color": "red"},
                {"value": 70, "color": "yellow"},
                {"value": 90, "color": "green"},
            ],
        }

    return panel


def create_dashboard_1_business_overview() -> Dict[str, Any]:
    """Dashboard 1: Business Overview - Key KPIs and health metrics."""
    panels = []
    y_pos = 0

    # Row 1: Key Metrics (Stats)
    panels.append(create_panel(
        "Total Users",
        'sum(business_users_active_daily{window="24h"})',
        "stat", "short", 0, y_pos, 6, 4,
        "Daily active users in last 24 hours"
    ))
    panels.append(create_panel(
        "Total Questions Asked",
        'sum(increase(business_user_questions_total[24h]))',
        "stat", "short", 6, y_pos, 6, 4,
        "User questions asked in last 24 hours"
    ))
    panels.append(create_panel(
        "Questions with Results",
        'sum(increase(business_rag_queries_with_results[24h]))',
        "stat", "short", 12, y_pos, 6, 4,
        "Queries that returned results (24h)"
    ))
    panels.append(create_panel(
        "RAG Success Rate",
        'sum(business_rag_queries_with_results) / (sum(business_rag_queries_with_results) + sum(business_rag_queries_without_results)) * 100',
        "gauge", "percent", 18, y_pos, 6, 4,
        "Percentage of queries that found relevant content"
    ))

    y_pos += 4

    # Row 2: User Activity Trends
    panels.append(create_panel(
        "User Questions Over Time",
        'rate(business_user_questions_total[5m]) * 60',
        "timeseries", "reqpm", 0, y_pos, 12, 8,
        "User questions per minute"
    ))
    panels.append(create_panel(
        "RAG Query Success vs Failure",
        'sum(rate(business_rag_queries_with_results[5m])) by (job)',
        "timeseries", "short", 12, y_pos, 12, 8,
        "Queries with results vs without results over time"
    ))

    y_pos += 8

    # Row 3: Content Processing
    panels.append(create_panel(
        "Content Processed (GB)",
        'sum(business_content_size_bytes) / 1024 / 1024 / 1024',
        "stat", "gbytes", 0, y_pos, 8, 4,
        "Total content processed across all projects"
    ))
    panels.append(create_panel(
        "Projects Created",
        'sum(increase(business_projects_created[24h]))',
        "stat", "short", 8, y_pos, 8, 4,
        "New projects created in last 24 hours"
    ))
    panels.append(create_panel(
        "Content Coverage Gaps",
        'sum(increase(business_content_coverage_gaps[24h]))',
        "stat", "short", 16, y_pos, 8, 4,
        "Queries with no relevant results (indicates missing content)"
    ))

    return {
        "dashboard": {
            "title": "📊 Business Overview",
            "tags": ["tellmemo", "business", "overview"],
            "timezone": "browser",
            "refresh": "30s",
            "panels": panels,
            "schemaVersion": 36,
        },
        "overwrite": True,
    }


def create_dashboard_2_llm_costs() -> Dict[str, Any]:
    """Dashboard 2: LLM Cost Optimization - Track spending and efficiency."""
    panels = []
    y_pos = 0

    # Row 1: Cost Summary
    panels.append(create_panel(
        "Total LLM Cost (Today)",
        'sum(increase(business_llm_cost_per_query[24h])) / 100',
        "stat", "currencyUSD", 0, y_pos, 6, 4,
        "Total LLM costs in last 24 hours (USD)"
    ))
    panels.append(create_panel(
        "Cost per Query (Avg)",
        'avg(business_llm_cost_per_query) / 100',
        "stat", "currencyUSD", 6, y_pos, 6, 4,
        "Average cost per query"
    ))
    panels.append(create_panel(
        "Monthly Projected Cost",
        'sum(increase(business_llm_cost_monthly[24h])) * 30 / 100',
        "stat", "currencyUSD", 12, y_pos, 6, 4,
        "Projected monthly LLM costs based on current usage"
    ))
    panels.append(create_panel(
        "Cost per User (Avg)",
        'avg(business_llm_cost_per_user) / 100',
        "stat", "currencyUSD", 18, y_pos, 6, 4,
        "Average LLM cost per user"
    ))

    y_pos += 4

    # Row 2: Cost by Provider
    panels.append(create_panel(
        "LLM Cost by Provider",
        'sum(rate(business_llm_cost_by_provider[1h])) by (provider) * 3600 / 100',
        "timeseries", "currencyUSD", 0, y_pos, 12, 8,
        "Hourly cost breakdown by LLM provider"
    ))
    panels.append(create_panel(
        "Cost Distribution by Provider",
        'sum(business_llm_cost_by_provider) by (provider) / 100',
        "piechart", "currencyUSD", 12, y_pos, 12, 8,
        "Total cost distribution across providers"
    ))

    y_pos += 8

    # Row 3: Efficiency Metrics
    panels.append(create_panel(
        "LLM Requests per Minute",
        'sum(rate(llm_requests_total[1m])) by (llm_provider) * 60',
        "timeseries", "reqpm", 0, y_pos, 12, 8,
        "LLM request rate by provider"
    ))
    panels.append(create_panel(
        "Cost vs Query Volume",
        'sum(rate(business_llm_cost_per_query[5m])) / sum(rate(business_user_questions_total[5m]))',
        "timeseries", "currencyUSD", 12, y_pos, 12, 8,
        "Cost efficiency: dollars per user question"
    ))

    return {
        "dashboard": {
            "title": "💰 LLM Cost Optimization",
            "tags": ["tellmemo", "cost", "llm"],
            "timezone": "browser",
            "refresh": "1m",
            "panels": panels,
            "schemaVersion": 36,
        },
        "overwrite": True,
    }


def create_dashboard_3_organization_health() -> Dict[str, Any]:
    """Dashboard 3: Organization Health - Multi-tenant tracking."""
    panels = []
    y_pos = 0

    # Row 1: Organization Metrics
    panels.append(create_panel(
        "Active Organizations",
        'count(sum by (organization_id) (business_organization_queries_total))',
        "stat", "short", 0, y_pos, 6, 4,
        "Number of organizations with activity"
    ))
    panels.append(create_panel(
        "Avg Queries per Org",
        'avg(sum by (organization_id) (rate(business_organization_queries_total[24h]))) * 86400',
        "stat", "short", 6, y_pos, 6, 4,
        "Average queries per organization (24h)"
    ))
    panels.append(create_panel(
        "Top Organization (Queries)",
        'topk(1, sum by (organization_id) (rate(business_organization_queries_total[24h]))) * 86400',
        "stat", "short", 12, y_pos, 6, 4,
        "Most active organization by query volume"
    ))
    panels.append(create_panel(
        "Total Org LLM Costs (Today)",
        'sum(increase(business_organization_llm_cost[24h])) / 100',
        "stat", "currencyUSD", 18, y_pos, 6, 4,
        "Total LLM costs across all organizations"
    ))

    y_pos += 4

    # Row 2: Organization Activity
    panels.append(create_panel(
        "Queries by Organization",
        'sum(rate(business_organization_queries_total[5m])) by (organization_id) * 300',
        "timeseries", "short", 0, y_pos, 12, 8,
        "Query volume per organization (5-min rate)"
    ))
    panels.append(create_panel(
        "LLM Cost by Organization",
        'sum(rate(business_organization_llm_cost[1h])) by (organization_id) * 3600 / 100',
        "timeseries", "currencyUSD", 12, y_pos, 12, 8,
        "Hourly LLM costs per organization"
    ))

    y_pos += 8

    # Row 3: Organization Rankings
    panels.append(create_panel(
        "Top 10 Organizations (by Queries)",
        'topk(10, sum by (organization_id) (increase(business_organization_queries_total[24h])))',
        "barchart", "short", 0, y_pos, 12, 8,
        "Top 10 most active organizations"
    ))
    panels.append(create_panel(
        "Top 10 Organizations (by Cost)",
        'topk(10, sum by (organization_id) (increase(business_organization_llm_cost[24h]))) / 100',
        "barchart", "currencyUSD", 12, y_pos, 12, 8,
        "Top 10 organizations by LLM spend"
    ))

    return {
        "dashboard": {
            "title": "🏢 Organization Health",
            "tags": ["tellmemo", "organizations", "multi-tenant"],
            "timezone": "browser",
            "refresh": "1m",
            "panels": panels,
            "schemaVersion": 36,
        },
        "overwrite": True,
    }


def create_dashboard_4_churn_risk() -> Dict[str, Any]:
    """Dashboard 4: Churn Risk Detection - Identify at-risk users."""
    panels = []
    y_pos = 0

    # Row 1: Churn Indicators
    panels.append(create_panel(
        "Inactive Users (7+ days)",
        'sum(business_users_inactive{period="7d"})',
        "stat", "short", 0, y_pos, 6, 4,
        "Users with no activity in last 7 days"
    ))
    panels.append(create_panel(
        "Users with Declining Engagement",
        'sum(increase(business_users_engagement_decline[24h]))',
        "stat", "short", 6, y_pos, 6, 4,
        "Users showing 50%+ decline in activity"
    ))
    panels.append(create_panel(
        "Weekly Active Users (WAU)",
        'sum(business_users_active_weekly{window="7d"})',
        "stat", "short", 12, y_pos, 6, 4,
        "Users active in last 7 days"
    ))
    panels.append(create_panel(
        "DAU/WAU Ratio (Stickiness)",
        'sum(business_users_active_daily{window="24h"}) / sum(business_users_active_weekly{window="7d"}) * 100',
        "gauge", "percent", 18, y_pos, 6, 4,
        "User stickiness (higher is better, >40% is good)"
    ))

    y_pos += 4

    # Row 2: Engagement Trends
    panels.append(create_panel(
        "WAU Trend",
        'sum(business_users_active_weekly{window="7d"})',
        "timeseries", "short", 0, y_pos, 12, 8,
        "Weekly active users over time"
    ))
    panels.append(create_panel(
        "Engagement Decline Events",
        'sum(rate(business_users_engagement_decline[1h])) * 3600',
        "timeseries", "short", 12, y_pos, 12, 8,
        "Users flagged for declining engagement (per hour)"
    ))

    y_pos += 8

    # Row 3: User Activity
    panels.append(create_panel(
        "Activity Streak Distribution",
        'sum(business_users_activity_streak) by (le)',
        "histogram", "short", 0, y_pos, 12, 8,
        "Distribution of user activity streaks (consecutive days)"
    ))
    panels.append(create_panel(
        "Inactive User Trend",
        'sum(business_users_inactive{period="7d"})',
        "timeseries", "short", 12, y_pos, 12, 8,
        "Trend of inactive users over time"
    ))

    return {
        "dashboard": {
            "title": "⚠️ Churn Risk Detection",
            "tags": ["tellmemo", "churn", "retention"],
            "timezone": "browser",
            "refresh": "5m",
            "panels": panels,
            "schemaVersion": 36,
        },
        "overwrite": True,
    }


def create_dashboard_5_sla_performance() -> Dict[str, Any]:
    """Dashboard 5: SLA & Performance - Track SLA compliance."""
    panels = []
    y_pos = 0

    # Row 1: SLA Metrics
    panels.append(create_panel(
        "SLA Compliance Rate",
        'avg(business_sla_compliance_rate) * 100',
        "gauge", "percent", 0, y_pos, 6, 4,
        "% of requests meeting SLA (target: >95%)"
    ))
    panels.append(create_panel(
        "SLA Violations (Today)",
        'sum(increase(business_sla_violations[24h]))',
        "stat", "short", 6, y_pos, 6, 4,
        "Total SLA violations in last 24 hours"
    ))
    panels.append(create_panel(
        "Error Budget Remaining",
        'avg(business_sla_error_budget_remaining) * 100',
        "gauge", "percent", 12, y_pos, 6, 4,
        "Remaining error budget (target: >10%)"
    ))
    panels.append(create_panel(
        "System Availability",
        'avg(business_sla_availability) * 100',
        "gauge", "percent", 18, y_pos, 6, 4,
        "Overall system availability (target: 99.9%)"
    ))

    y_pos += 4

    # Row 2: Performance Trends
    panels.append(create_panel(
        "SLA Compliance Over Time",
        'avg(business_sla_compliance_rate) * 100',
        "timeseries", "percent", 0, y_pos, 12, 8,
        "SLA compliance rate trend"
    ))
    panels.append(create_panel(
        "SLA Violations by Operation",
        'sum(rate(business_sla_violations[5m])) by (operation) * 300',
        "timeseries", "short", 12, y_pos, 12, 8,
        "SLA violations per operation type"
    ))

    y_pos += 8

    # Row 3: Response Times
    panels.append(create_panel(
        "RAG Query Response Time (P95)",
        'histogram_quantile(0.95, sum(rate(business_sla_compliance_rate_bucket[5m])) by (le))',
        "timeseries", "ms", 0, y_pos, 12, 8,
        "95th percentile RAG query response time (SLA: <2000ms)"
    ))
    panels.append(create_panel(
        "Error Budget Trend",
        'avg(business_sla_error_budget_remaining) * 100',
        "timeseries", "percent", 12, y_pos, 12, 8,
        "Error budget remaining over time"
    ))

    return {
        "dashboard": {
            "title": "🎯 SLA & Performance",
            "tags": ["tellmemo", "sla", "performance"],
            "timezone": "browser",
            "refresh": "30s",
            "panels": panels,
            "schemaVersion": 36,
        },
        "overwrite": True,
    }


def create_dashboard_6_content_quality() -> Dict[str, Any]:
    """Dashboard 6: Content Quality - RAG effectiveness."""
    panels = []
    y_pos = 0

    # Row 1: Quality Metrics
    panels.append(create_panel(
        "Coverage Gap Rate",
        'sum(rate(business_content_coverage_gaps[5m])) / sum(rate(business_user_questions_total[5m])) * 100',
        "gauge", "percent", 0, y_pos, 6, 4,
        "% of queries with no relevant results (target: <30%)"
    ))
    panels.append(create_panel(
        "Coverage Gaps (Today)",
        'sum(increase(business_content_coverage_gaps[24h]))',
        "stat", "short", 6, y_pos, 6, 4,
        "Queries that found no relevant content"
    ))
    panels.append(create_panel(
        "Low Relevance Results",
        'sum(increase(business_content_low_relevance_results[24h]))',
        "stat", "short", 12, y_pos, 6, 4,
        "Queries with low-quality matches"
    ))
    panels.append(create_panel(
        "Content Utilization Rate",
        'avg(business_content_utilization_rate) * 100',
        "gauge", "percent", 18, y_pos, 6, 4,
        "% of content being accessed"
    ))

    y_pos += 4

    # Row 2: Coverage Trends
    panels.append(create_panel(
        "Coverage Gaps Over Time",
        'sum(rate(business_content_coverage_gaps[5m])) * 300',
        "timeseries", "short", 0, y_pos, 12, 8,
        "Coverage gap trend (queries with no results)"
    ))
    panels.append(create_panel(
        "Coverage Gap Rate Trend",
        'sum(rate(business_content_coverage_gaps[5m])) / sum(rate(business_user_questions_total[5m])) * 100',
        "timeseries", "percent", 12, y_pos, 12, 8,
        "Coverage gap rate over time (% of failed queries)"
    ))

    y_pos += 8

    # Row 3: Content Analysis
    panels.append(create_panel(
        "Content Staleness",
        'avg(business_content_staleness) / 86400',
        "timeseries", "days", 0, y_pos, 12, 8,
        "Average age of retrieved content (days)"
    ))
    panels.append(create_panel(
        "Low Relevance Rate",
        'sum(rate(business_content_low_relevance_results[5m])) / sum(rate(business_user_questions_total[5m])) * 100',
        "timeseries", "percent", 12, y_pos, 12, 8,
        "% of queries with low-relevance results (target: <20%)"
    ))

    return {
        "dashboard": {
            "title": "📚 Content Quality",
            "tags": ["tellmemo", "content", "rag", "quality"],
            "timezone": "browser",
            "refresh": "1m",
            "panels": panels,
            "schemaVersion": 36,
        },
        "overwrite": True,
    }


def create_dashboard_7_time_to_value() -> Dict[str, Any]:
    """Dashboard 7: Time-to-Value - Onboarding efficiency."""
    panels = []
    y_pos = 0

    # Row 1: Onboarding Metrics
    panels.append(create_panel(
        "Avg Time to First Query",
        'histogram_quantile(0.50, sum(rate(business_users_time_to_first_query_bucket[24h])) by (le)) / 60',
        "stat", "m", 0, y_pos, 6, 4,
        "Median time from signup to first query (minutes)"
    ))
    panels.append(create_panel(
        "P95 Time to First Query",
        'histogram_quantile(0.95, sum(rate(business_users_time_to_first_query_bucket[24h])) by (le)) / 60',
        "stat", "m", 6, y_pos, 6, 4,
        "95th percentile time to first query (target: <5 min)"
    ))
    panels.append(create_panel(
        "First Query Success Rate",
        'sum(increase(business_users_first_query_success{success="true"}[24h])) / sum(increase(business_users_first_query_success[24h])) * 100',
        "gauge", "percent", 12, y_pos, 6, 4,
        "% of first queries that succeeded (target: >70%)"
    ))
    panels.append(create_panel(
        "Avg Queries Until Success",
        'avg(business_users_queries_until_success)',
        "stat", "short", 18, y_pos, 6, 4,
        "Average attempts before successful query (target: <3)"
    ))

    y_pos += 4

    # Row 2: Time-to-Value Trends
    panels.append(create_panel(
        "Time to First Query Distribution",
        'histogram_quantile(0.50, sum(rate(business_users_time_to_first_query_bucket[1h])) by (le)) / 60',
        "timeseries", "m", 0, y_pos, 12, 8,
        "Median time to first query over time (minutes)"
    ))
    panels.append(create_panel(
        "First Query Success Rate Trend",
        'sum(rate(business_users_first_query_success{success="true"}[5m])) / sum(rate(business_users_first_query_success[5m])) * 100',
        "timeseries", "percent", 12, y_pos, 12, 8,
        "First query success rate over time"
    ))

    y_pos += 8

    # Row 3: Onboarding Funnel
    panels.append(create_panel(
        "Time to First Project",
        'histogram_quantile(0.50, sum(rate(business_users_time_to_first_project_bucket[24h])) by (le)) / 60',
        "timeseries", "m", 0, y_pos, 12, 8,
        "Median time from signup to first project creation"
    ))
    panels.append(create_panel(
        "Queries Until Success Distribution",
        'sum(business_users_queries_until_success) by (le)',
        "histogram", "short", 12, y_pos, 12, 8,
        "Distribution of attempts before successful query"
    ))

    return {
        "dashboard": {
            "title": "🚀 Time-to-Value",
            "tags": ["tellmemo", "onboarding", "activation"],
            "timezone": "browser",
            "refresh": "5m",
            "panels": panels,
            "schemaVersion": 36,
        },
        "overwrite": True,
    }


def create_dashboards():
    """Create all dashboards in Grafana Cloud."""
    dashboards = [
        ("Business Overview", create_dashboard_1_business_overview),
        ("LLM Cost Optimization", create_dashboard_2_llm_costs),
        ("Organization Health", create_dashboard_3_organization_health),
        ("Churn Risk Detection", create_dashboard_4_churn_risk),
        ("SLA & Performance", create_dashboard_5_sla_performance),
        ("Content Quality", create_dashboard_6_content_quality),
        ("Time-to-Value", create_dashboard_7_time_to_value),
    ]

    print(f"📊 Creating {len(dashboards)} Grafana Cloud Dashboards...\n")

    created = []
    failed = []

    for name, dashboard_func in dashboards:
        try:
            print(f"Creating: {name}...")
            dashboard_json = dashboard_func()

            # Create dashboard via API
            response = requests.post(
                f"{GRAFANA_URL}/api/dashboards/db",
                headers=headers,
                json=dashboard_json,
            )

            if response.status_code in [200, 201]:
                result = response.json()
                dashboard_url = f"{GRAFANA_URL}{result.get('url', '')}"
                print(f"   ✅ Created: {dashboard_url}")
                created.append((name, dashboard_url))
            else:
                print(f"   ❌ Failed: {response.status_code} - {response.text[:200]}")
                failed.append((name, response.text))

        except Exception as e:
            print(f"   ❌ Error: {e}")
            failed.append((name, str(e)))

    # Summary
    print(f"\n{'='*60}")
    print(f"✅ Successfully Created: {len(created)}/{len(dashboards)}")
    print(f"{'='*60}\n")

    if created:
        print("📊 Your Dashboards:")
        for name, url in created:
            print(f"   • {name}")
            print(f"     {url}\n")

    if failed:
        print(f"\n❌ Failed: {len(failed)}")
        for name, error in failed:
            print(f"   • {name}: {error[:100]}...")

    print(f"\n💡 Access all dashboards at: {GRAFANA_URL}/dashboards")
    print(f"🔍 Search for tag: 'tellmemo' to find your dashboards")


if __name__ == "__main__":
    create_dashboards()
