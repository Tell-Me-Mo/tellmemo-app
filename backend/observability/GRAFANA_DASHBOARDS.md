# TellMeMo Grafana Cloud Dashboards

This document provides PromQL queries for creating comprehensive dashboards in Grafana Cloud to monitor TellMeMo's business and technical metrics.

## Dashboard Structure

### 1. **Business Health Dashboard**
Key business KPIs and product metrics

### 2. **Technical Performance Dashboard**
System performance, errors, and infrastructure

### 3. **Cost Optimization Dashboard**
LLM costs and resource usage

### 4. **User Engagement Dashboard**
User behavior and feature adoption

---

## 1. Business Health Dashboard

### User Metrics

**Daily Active Users (Last 24h)**
```promql
business_users_active_daily{window="24h"}
```

**Total User Sessions (Rate per minute)**
```promql
rate(business_user_sessions_total[5m])
```

**User Questions Asked (Total)**
```promql
sum(business_user_questions_total)
```

**User Questions per Hour**
```promql
rate(business_user_questions_total[1h]) * 3600
```

### Content Processing Metrics

**Meetings Processed Today**
```promql
increase(business_meetings_processed_total[24h])
```

**Meeting Processing Success Rate**
```promql
sum(rate(business_meetings_processed_total{status="success"}[5m]))
/
sum(rate(business_meetings_processed_total[5m])) * 100
```

**Total Content Processed (GB)**
```promql
sum(business_content_size_bytes) / 1024 / 1024 / 1024
```

**Average Content Processing Time**
```promql
histogram_quantile(0.5,
  sum(rate(business_content_processing_duration_bucket[5m])) by (le)
)
```

### Project Metrics

**Projects Created Today**
```promql
increase(business_projects_created[24h])
```

**Projects Created per Hour**
```promql
rate(business_projects_created[1h]) * 3600
```

---

## 2. Technical Performance Dashboard

### API Performance

**API Response Time (P50, P95, P99)**
```promql
# P50
histogram_quantile(0.50,
  sum(rate(http_server_duration_milliseconds_bucket{service_name="tellmemo-backend"}[5m])) by (le)
)

# P95
histogram_quantile(0.95,
  sum(rate(http_server_duration_milliseconds_bucket{service_name="tellmemo-backend"}[5m])) by (le)
)

# P99
histogram_quantile(0.99,
  sum(rate(http_server_duration_milliseconds_bucket{service_name="tellmemo-backend"}[5m])) by (le)
)
```

**Requests per Second**
```promql
sum(rate(http_server_requests_total{service_name="tellmemo-backend"}[1m]))
```

**Error Rate (%)**
```promql
sum(rate(http_server_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_server_requests_total[5m])) * 100
```

### RAG Query Performance

**RAG Query Latency (P95)**
```promql
histogram_quantile(0.95,
  sum(rate(rag_query_duration_bucket[5m])) by (le)
)
```

**RAG Queries per Minute**
```promql
sum(rate(rag_queries_total[1m])) * 60
```

**RAG Query Success Rate**
```promql
sum(rate(rag_queries_total{rag_status="success"}[5m]))
/
sum(rate(rag_queries_total[5m])) * 100
```

**Average Chunks Retrieved per Query**
```promql
histogram_quantile(0.50,
  sum(rate(rag_chunks_retrieved_bucket[5m])) by (le)
```

**Queries with Results vs No Results**
```promql
# With results
sum(business_rag_queries_with_results)

# Without results
sum(business_rag_queries_without_results)

# Success rate
sum(business_rag_queries_with_results)
/
(sum(business_rag_queries_with_results) + sum(business_rag_queries_without_results)) * 100
```

### LLM Performance

**LLM Request Duration (P95)**
```promql
histogram_quantile(0.95,
  sum(rate(llm_requests_duration_bucket[5m])) by (le, llm_provider)
)
```

**LLM Requests per Minute (by Provider)**
```promql
sum(rate(llm_requests_total[1m])) by (llm_provider) * 60
```

**LLM Error Rate by Provider**
```promql
sum(rate(llm_errors_total[5m])) by (llm_provider, error_type)
```

**Total Tokens Processed (per hour)**
```promql
sum(rate(llm_tokens_total[1h])) by (llm_provider) * 3600
```

### Database Performance

**Database Query Duration (P95)**
```promql
histogram_quantile(0.95,
  sum(rate(db_query_duration_bucket[5m])) by (le)
)
```

**Database Queries per Second**
```promql
sum(rate(db_queries_total[1m]))
```

**Database Connection Pool Usage**
```promql
db_connection_pool_size
```

### Vector Store Performance

**Vector Search Duration (P95)**
```promql
histogram_quantile(0.95,
  sum(rate(vector_store_search_duration_bucket[5m])) by (le)
)
```

**Vector Searches per Minute**
```promql
sum(rate(vector_store_searches_total[1m])) * 60
```

---

## 3. Cost Optimization Dashboard

### LLM Costs

**Total LLM Cost Today (USD)**
```promql
sum(increase(business_llm_cost_monthly[24h])) / 100
```

**LLM Cost per Hour (USD)**
```promql
sum(rate(business_llm_cost_monthly[1h])) * 3600 / 100
```

**LLM Cost by Provider (USD per day)**
```promql
sum(increase(business_llm_cost_by_provider[24h])) by (provider) / 100
```

**Average Cost per Query (USD cents)**
```promql
histogram_quantile(0.50,
  sum(rate(business_llm_cost_per_query_bucket[5m])) by (le)
)
```

**Average Cost per User (USD cents)**
```promql
histogram_quantile(0.50,
  sum(rate(business_llm_cost_per_user_bucket[5m])) by (le)
)
```

**Monthly Cost Projection (USD)**
```promql
# Based on current day's spending rate
sum(rate(business_llm_cost_monthly[24h])) * 30 / 100
```

**Cost Breakdown: Query vs Summarization vs Other**
```promql
sum(rate(business_llm_cost_by_provider[5m])) by (operation) * 100
```

**Provider Cost Comparison (last 7 days)**
```promql
sum(increase(business_llm_cost_by_provider[7d])) by (provider) / 100
```

---

## 4. User Engagement Dashboard

### Engagement Metrics

**Average Session Duration (minutes)**
```promql
histogram_quantile(0.50,
  sum(rate(business_user_session_duration_bucket[5m])) by (le)
) / 60
```

**Questions per Active User**
```promql
sum(increase(business_user_questions_total[24h]))
/
sum(business_users_active_daily{window="24h"})
```

**Feature Usage Breakdown**
```promql
sum(business_features_usage) by (feature)
```

**User Onboarding Completion Rate**
```promql
sum(increase(business_users_onboarding_completed[7d]))
```

### Quality Metrics

**Critical Errors (last hour)**
```promql
sum(increase(business_errors_critical[1h]))
```

**User Feedback Received**
```promql
sum(business_feedback_received) by (rating_bucket, feature)
```

**Query Refinement Rate (indicates unclear results)**
```promql
sum(rate(business_rag_query_refinements[5m]))
/
sum(rate(business_user_questions_total[5m])) * 100
```

---

## 5. Infrastructure Monitoring

### System Resources

**CPU Usage (asyncpg connections)**
```promql
# PostgreSQL query performance
histogram_quantile(0.95,
  sum(rate(db_operation_duration_milliseconds_bucket{db_system="postgresql"}[5m])) by (le)
)
```

**Redis Command Latency (P95)**
```promql
histogram_quantile(0.95,
  sum(rate(redis_command_duration_seconds_bucket[5m])) by (le)
) * 1000
```

**Qdrant Vector Search Performance (P95)**
```promql
histogram_quantile(0.95,
  sum(rate(qdrant_search_duration_seconds_bucket[5m])) by (le)
) * 1000
```

---

## Alert Rules

### Critical Alerts

**High Error Rate**
```promql
(sum(rate(http_server_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_server_requests_total[5m]))) * 100 > 5
```
Alert when error rate exceeds 5% for 5 minutes

**LLM Cost Spike**
```promql
sum(rate(business_llm_cost_monthly[1h])) * 24 / 100 > 50
```
Alert when daily cost projection exceeds $50

**Slow RAG Queries**
```promql
histogram_quantile(0.95,
  sum(rate(rag_query_duration_bucket[5m])) by (le)
) > 5
```
Alert when P95 RAG query time exceeds 5 seconds

**Low Query Success Rate**
```promql
sum(rate(rag_queries_total{rag_status="success"}[5m]))
/
sum(rate(rag_queries_total[5m])) * 100 < 80
```
Alert when RAG query success rate drops below 80%

**Database Connection Pool Exhaustion**
```promql
db_connection_pool_size > 90
```
Alert when connection pool usage exceeds 90%

---

## Creating Dashboards in Grafana Cloud

1. **Log in to Grafana Cloud**: https://yourorg.grafana.net
2. **Create New Dashboard**: Click "+" → "Dashboard"
3. **Add Panel**: Click "Add visualization"
4. **Select Data Source**: Choose "Prometheus" or "Mimir"
5. **Paste Query**: Copy the PromQL query from above
6. **Configure Panel**: Set title, units, thresholds
7. **Save Dashboard**: Click "Save" icon

### Recommended Dashboard Panels

**Business Health Dashboard:**
- Daily Active Users (Stat panel)
- Questions Asked Today (Stat panel)
- Meetings Processed (Stat panel)
- LLM Cost Today (Stat panel with red threshold > $10)
- Questions per Hour (Time series)
- Content Processing Time (Time series)

**Technical Performance Dashboard:**
- API Response Time P95 (Time series)
- Requests per Second (Time series)
- Error Rate % (Time series with red threshold)
- RAG Query Latency (Time series)
- Database Query Performance (Time series)

**Cost Dashboard:**
- Total Cost Today (Big stat panel)
- Cost by Provider (Pie chart)
- Cost per Query Trend (Time series)
- Monthly Projection (Stat panel with warning threshold)

---

## Viewing Traces in Grafana Cloud

1. Go to **Explore** → Select **Tempo** data source
2. Use TraceQL to query traces:

**Find slow RAG queries:**
```traceql
{service.name="tellmemo-backend" && duration > 2s && span.name=~".*rag.*"}
```

**Find LLM errors:**
```traceql
{service.name="tellmemo-backend" && status=error && span.name=~".*llm.*"}
```

**Find traces for a specific user:**
```traceql
{service.name="tellmemo-backend" && resource.user_id="user_123"}
```

---

## Next Steps

1. Import these queries into Grafana Cloud
2. Set up alert rules for critical metrics
3. Create team-specific dashboards
4. Set up Slack/Email notifications for alerts
5. Review metrics weekly to identify optimization opportunities

---

## 6. Organization Health Dashboard (Multi-Tenant)

### Organization Metrics

**Active Users per Organization**
```promql
sum(business_organization_users_active) by (organization_id)
```

**Query Volume by Organization**
```promql
sum(rate(business_organization_queries_total[1h])) by (organization_id) * 3600
```

**LLM Cost per Organization (Daily)**
```promql
sum(increase(business_organization_llm_cost[24h])) by (organization_id) / 100
```

**Content Processed by Organization (GB)**
```promql
sum(business_organization_content_volume) by (organization_id) / 1024 / 1024 / 1024
```

**Seat Utilization per Organization (%)**
```promql
histogram_quantile(0.50,
  sum(rate(business_organization_seats_utilization_bucket[5m])) by (le, organization_id)
)
```

**Top 10 Organizations by Query Volume**
```promql
topk(10,
  sum(rate(business_organization_queries_total[24h])) by (organization_id)
)
```

**Organizations at Risk (Low Activity)**
```promql
sum(business_organization_queries_total) by (organization_id) < 10
```

---

## 7. Time-to-Value Dashboard

### Onboarding Efficiency

**Average Time to First Query (seconds)**
```promql
histogram_quantile(0.50,
  sum(rate(business_users_time_to_first_query_bucket[5m])) by (le)
)
```

**Time to First Query Distribution (P50, P95)**
```promql
# P50
histogram_quantile(0.50,
  sum(rate(business_users_time_to_first_query_bucket[5m])) by (le)
)

# P95
histogram_quantile(0.95,
  sum(rate(business_users_time_to_first_query_bucket[5m])) by (le)
)
```

**First Query Success Rate**
```promql
sum(business_users_first_query_success{success="true"})
/
sum(business_users_first_query_success) * 100
```

**Average Time to First Project (hours)**
```promql
histogram_quantile(0.50,
  sum(rate(business_users_time_to_first_project_bucket[5m])) by (le)
) / 3600
```

**Average Queries Until Success**
```promql
histogram_quantile(0.50,
  sum(rate(business_users_queries_until_success_bucket[5m])) by (le)
)
```

**Users Taking >10 Queries to Get Value (Problem Indicator)**
```promql
histogram_quantile(0.95,
  sum(rate(business_users_queries_until_success_bucket[5m])) by (le)
) > 10
```

---

## 8. Content Quality Dashboard

### Content Coverage

**Content Coverage Gaps (Last Hour)**
```promql
sum(increase(business_content_coverage_gaps[1h])) by (reason)
```

**Coverage Gap Rate (%)**
```promql
sum(rate(business_content_coverage_gaps[5m]))
/
sum(rate(business_user_questions_total[5m])) * 100
```

**Gaps by Project (Top 10 Projects with Most Gaps)**
```promql
topk(10,
  sum(increase(business_content_coverage_gaps[24h])) by (project_id)
)
```

**Low Relevance Results Rate**
```promql
sum(rate(business_rag_low_relevance_results[5m]))
/
sum(rate(business_user_questions_total[5m])) * 100
```

### Content Freshness

**Average Content Age (days)**
```promql
histogram_quantile(0.50,
  sum(rate(business_content_staleness_bucket[5m])) by (le)
)
```

**Stale Content Usage (>30 days old)**
```promql
sum(business_content_staleness > 30)
```

---

## 9. Churn Risk Dashboard

### At-Risk User Detection

**Weekly Active Users (WAU)**
```promql
business_users_active_weekly{window="7d"}
```

**Inactive Users (>7 days)**
```promql
sum(business_users_inactive{days_inactive="7"})
```

**Users with Declining Engagement**
```promql
sum(increase(business_users_engagement_decline[24h])) by (decline_level)
```

**High-Risk Churn Users (High Decline)**
```promql
sum(business_users_engagement_decline{decline_level="high"})
```

**Average Activity Streak (days)**
```promql
histogram_quantile(0.50,
  sum(rate(business_users_activity_streak_bucket[5m])) by (le)
)
```

**Users with Streak <3 days (Low Engagement)**
```promql
histogram_quantile(0.50,
  sum(rate(business_users_activity_streak_bucket[5m])) by (le)
) < 3
```

### Retention Tracking

**DAU/WAU Ratio (Stickiness)**
```promql
business_users_active_daily{window="24h"}
/
business_users_active_weekly{window="7d"}
```

---

## 10. SLA & Performance Dashboard

### SLA Compliance

**Overall SLA Compliance Rate (%)**
```promql
histogram_quantile(0.50,
  sum(rate(business_sla_compliance_rate_bucket[5m])) by (le)
)
```

**SLA Compliance by Operation**
```promql
histogram_quantile(0.50,
  sum(rate(business_sla_compliance_rate_bucket[5m])) by (le, operation)
)
```

**SLA Violations (Last Hour)**
```promql
sum(increase(business_sla_violations[1h])) by (operation, violation_type)
```

**SLA Violation Rate (%)**
```promql
sum(rate(business_sla_violations[5m]))
/
sum(rate(business_user_questions_total[5m])) * 100
```

**Error Budget Remaining (%)**
```promql
histogram_quantile(0.50,
  sum(rate(business_sla_error_budget_remaining_bucket[5m])) by (le)
)
```

**System Availability (Current)**
```promql
histogram_quantile(0.50,
  sum(rate(business_sla_availability_bucket[5m])) by (le)
)
```

**Availability SLA Met (Target: 99.9%)**
```promql
histogram_quantile(0.50,
  sum(rate(business_sla_availability_bucket[5m])) by (le)
) >= 99.9
```

---

## New Alert Rules (Critical Metrics)

### Organization Alerts

**Organization Churn Risk (Low Activity)**
```promql
sum(rate(business_organization_queries_total[7d])) by (organization_id) < 50
```
Alert when organization query volume drops below 50/week

**Organization High Cost (Budget Overrun)**
```promql
sum(rate(business_organization_llm_cost[24h])) by (organization_id) / 100 > 100
```
Alert when organization daily LLM cost exceeds $100

### Content Quality Alerts

**High Content Coverage Gap Rate**
```promql
sum(rate(business_content_coverage_gaps[5m]))
/
sum(rate(business_user_questions_total[5m])) * 100 > 30
```
Alert when >30% of queries find no relevant content

**Low Relevance Results Spike**
```promql
sum(rate(business_rag_low_relevance_results[5m])) * 60 > 10
```
Alert when >10 low-relevance results per minute

### Time-to-Value Alerts

**Slow Time-to-First-Query (Poor Onboarding)**
```promql
histogram_quantile(0.95,
  sum(rate(business_users_time_to_first_query_bucket[5m])) by (le)
) > 300
```
Alert when P95 time-to-first-query exceeds 5 minutes

**Low First Query Success Rate**
```promql
sum(business_users_first_query_success{success="true"})
/
sum(business_users_first_query_success) * 100 < 50
```
Alert when <50% of first queries succeed

### Churn Risk Alerts

**High Inactive User Count**
```promql
sum(business_users_inactive{days_inactive="7"}) > 20
```
Alert when >20 users inactive for 7+ days

**WAU Declining**
```promql
rate(business_users_active_weekly{window="7d"}[1w]) < -0.1
```
Alert when WAU declining by >10%

### SLA Alerts

**SLA Compliance Below Target**
```promql
histogram_quantile(0.50,
  sum(rate(business_sla_compliance_rate_bucket[5m])) by (le, operation)
) < 95
```
Alert when SLA compliance drops below 95%

**Error Budget Exhausted**
```promql
histogram_quantile(0.50,
  sum(rate(business_sla_error_budget_remaining_bucket[5m])) by (le)
) < 10
```
Alert when error budget drops below 10%

---

## Metric Summary: What We Track

### 65+ Business Metrics Across 10 Categories:

1. **User Engagement (7)** - DAU, WAU, sessions, questions, projects, duration
2. **Content Processing (5)** - Meetings, emails, docs, size, processing time
3. **RAG Quality (4)** - Success rate, refinements, relevance, query latency
4. **LLM Costs (4)** - Per user, per query, per provider, monthly total
5. **System Health (5)** - Errors, feedback, features, availability, performance
6. **Retention (3)** - Onboarding, retention rate, revenue
7. **Organizations (5)** - Active users, queries, costs, content, seat utilization
8. **Time-to-Value (4)** - TTFQ, first project, first success, queries until value
9. **Content Quality (4)** - Coverage gaps, staleness, utilization, low relevance
10. **At-Risk Users (4)** - Engagement decline, inactive, WAU, activity streaks
11. **SLA Compliance (4)** - Compliance rate, violations, error budget, availability

**Total: 65+ metrics tracking all critical business KPIs**

