# TellMeMo Grafana Cloud Dashboards

🎉 **7 Beautiful Business & Technical Dashboards** - Ready to Import!

## 📊 Dashboard Overview

### 1. 📊 Business Overview (`1_business_overview.json`)
**Your main business health dashboard**

**Panels (9):**
- **Total Users** - Daily active users (24h)
- **Total Questions Asked** - User engagement metric
- **Questions with Results** - RAG effectiveness
- **RAG Success Rate** - % of queries finding relevant content (gauge)
- **User Questions Over Time** - Trend graph
- **RAG Query Success vs Failure** - Success/failure comparison
- **Content Processed (GB)** - Total content volume
- **Projects Created** - New projects today
- **Content Coverage Gaps** - Queries with no results (quality indicator)

**Key Insights:**
- Is your product being used actively?
- Are users finding what they need?
- Where are the content gaps?

---

### 2. 💰 LLM Cost Optimization (`2_llm_cost_optimization.json`)
**Track every dollar spent on LLM providers**

**Panels (8):**
- **Total LLM Cost (Today)** - Daily spending in USD
- **Cost per Query (Avg)** - Average cost efficiency
- **Monthly Projected Cost** - Forecast based on current usage
- **Cost per User (Avg)** - Per-user cost tracking
- **LLM Cost by Provider** - Hourly cost breakdown (Claude, OpenAI, DeepSeek)
- **Cost Distribution by Provider** - Pie chart of total spend
- **LLM Requests per Minute** - Request volume by provider
- **Cost vs Query Volume** - Efficiency metric ($/query)

**Key Insights:**
- Which LLM provider is most cost-effective?
- Are costs trending up or down?
- What's your monthly burn rate?

**💡 Use Case:** Discovered DeepSeek is 10x cheaper than Claude Haiku? Switch!

---

### 3. 🏢 Organization Health (`3_organization_health.json`)
**Multi-tenant B2B SaaS tracking**

**Panels (8):**
- **Active Organizations** - Orgs with recent activity
- **Avg Queries per Org** - Engagement level
- **Top Organization (Queries)** - Most active org
- **Total Org LLM Costs (Today)** - Cross-org spending
- **Queries by Organization** - Per-org query volume over time
- **LLM Cost by Organization** - Per-org cost tracking
- **Top 10 Organizations (by Queries)** - Activity leaderboard
- **Top 10 Organizations (by Cost)** - Spending leaderboard

**Key Insights:**
- Which organizations are your power users?
- Which orgs are at risk (low usage)?
- How much does each org cost to serve?

**💡 Use Case:** Identify high-value customers for upselling opportunities

---

### 4. ⚠️ Churn Risk Detection (`4_churn_risk_detection.json`)
**Proactive churn prevention**

**Panels (8):**
- **Inactive Users (7+ days)** - Users who haven't logged in
- **Users with Declining Engagement** - 50%+ activity drop
- **Weekly Active Users (WAU)** - 7-day active user count
- **DAU/WAU Ratio (Stickiness)** - Product stickiness gauge (>40% is good)
- **WAU Trend** - Weekly active users over time
- **Engagement Decline Events** - Users flagged for declining activity
- **Activity Streak Distribution** - Histogram of consecutive usage days
- **Inactive User Trend** - Growing or shrinking inactive user base

**Key Insights:**
- Which users are at risk of churning?
- Is product stickiness improving?
- What's the typical engagement pattern?

**💡 Alert Triggers:**
- Inactive >7 days = outreach email
- Engagement decline >50% = customer success intervention

---

### 5. 🎯 SLA & Performance (`5_sla_performance.json`)
**Are you meeting your commitments?**

**Panels (8):**
- **SLA Compliance Rate** - % meeting 2-second target (gauge)
- **SLA Violations (Today)** - Count of breaches
- **Error Budget Remaining** - How much buffer left? (gauge)
- **System Availability** - Uptime % (target: 99.9%)
- **SLA Compliance Over Time** - Trend graph
- **SLA Violations by Operation** - Which operations violate most?
- **RAG Query Response Time (P95)** - 95th percentile latency
- **Error Budget Trend** - Is it improving or degrading?

**Key Insights:**
- Are you meeting SLA commitments?
- Which operations are slowest?
- Do you have error budget to spare?

**💡 SLA Targets:**
- Query latency: 95% < 2 seconds
- Availability: 99.9% uptime
- Error rate: <1%

---

### 6. 📚 Content Quality (`6_content_quality.json`)
**RAG effectiveness & content coverage**

**Panels (8):**
- **Coverage Gap Rate** - % of queries with no results (gauge, target <30%)
- **Coverage Gaps (Today)** - Count of failed queries
- **Low Relevance Results** - Queries with poor matches
- **Content Utilization Rate** - % of content being accessed (gauge)
- **Coverage Gaps Over Time** - Trend of failed queries
- **Coverage Gap Rate Trend** - % failure rate over time
- **Content Staleness** - Average age of retrieved content (days)
- **Low Relevance Rate** - % of low-quality results (target <20%)

**Key Insights:**
- What % of queries fail due to missing content?
- Is content fresh or stale?
- Which projects have coverage gaps?

**💡 Alert Thresholds:**
- Coverage gap rate >30% = critical
- Low relevance >20% = warning
- Content staleness >90 days = review needed

---

### 7. 🚀 Time-to-Value (`7_time_to_value.json`)
**Onboarding & activation efficiency**

**Panels (8):**
- **Avg Time to First Query** - Median time from signup (minutes)
- **P95 Time to First Query** - 95th percentile (target <5 min)
- **First Query Success Rate** - % of first queries that succeeded (gauge, target >70%)
- **Avg Queries Until Success** - How many tries? (target <3)
- **Time to First Query Distribution** - Median over time
- **First Query Success Rate Trend** - Success rate improvement
- **Time to First Project** - Onboarding funnel metric
- **Queries Until Success Distribution** - Histogram of attempts

**Key Insights:**
- How long until users get value?
- Is onboarding smooth or frustrating?
- Where do users drop off in the funnel?

**💡 Target SLAs:**
- Time to first query: <5 minutes (P95)
- First query success rate: >70%
- Queries until success: <3 (median)

---

## 🚀 How to Import Dashboards

### Step 1: Go to Grafana Cloud
Visit: **https://tellmemo.grafana.net/**

### Step 2: Navigate to Dashboard Import
1. Click **"Dashboards"** in the left sidebar
2. Click **"+ Create"** button (top right)
3. Select **"Import"**

### Step 3: Import Each Dashboard
1. Click **"Upload JSON file"**
2. Select one of the JSON files from this directory
3. Choose your **Prometheus** data source (should be pre-configured)
4. Click **"Import"**

### Step 4: Repeat for All 7 Dashboards
Import all dashboards to get complete observability coverage!

---

## 📈 Recommended Dashboard Order

1. **Start with Business Overview** - Get familiar with key metrics
2. **Check LLM Costs** - Understand your spending
3. **Review SLA & Performance** - Ensure system health
4. **Analyze Content Quality** - Identify content gaps
5. **Monitor Churn Risk** - Proactive user retention
6. **Track Time-to-Value** - Optimize onboarding
7. **Organization Health** - Multi-tenant insights

---

## 🎨 Dashboard Features

All dashboards include:
- ✅ **Auto-refresh** - Updates every 30s-5m depending on dashboard
- ✅ **Time range selector** - View custom time periods
- ✅ **Interactive tooltips** - Hover for details
- ✅ **Beautiful gauges** - Visual SLA compliance indicators
- ✅ **Trend graphs** - Spot patterns over time
- ✅ **Tags** - Search for "tellmemo" to find all dashboards

---

## 🔍 Query Examples

### Find Expensive Queries
```promql
topk(10, business_llm_cost_per_query) / 100
```

### Churn Risk Users
```promql
business_users_inactive{period="7d"}
```

### Coverage Gaps by Project
```promql
sum(business_content_coverage_gaps) by (project_id)
```

---

## ⚙️ Data Source Configuration

**Important:** When importing, select:
- **Data Source:** Prometheus (Grafana Cloud Managed)
- **Service Name Filter:** `tellmemo-app`

The metrics are already flowing from your backend via OpenTelemetry!

---

## 🎯 Next Steps

### 1. Set Up Alerts
Create alerts for critical thresholds:
- **High Cost Alert:** `sum(rate(business_llm_cost_monthly[1h])) * 720 > 100` (>$100/month)
- **SLA Violation Alert:** `avg(business_sla_compliance_rate) < 0.95` (<95% compliance)
- **Churn Risk Alert:** `sum(business_users_inactive{period="7d"}) > 10` (>10 inactive users)

### 2. Create Weekly Reports
Use Grafana's **Reporting** feature to:
- Email weekly Business Overview snapshots to stakeholders
- Send Cost Optimization reports to finance team
- Alert customer success on churn risk trends

### 3. Customize Dashboards
Feel free to:
- Add more panels
- Change time ranges
- Create custom PromQL queries
- Duplicate and modify for specific use cases

---

## 📞 Support

If you see "No data" in panels:
1. **Check metrics are flowing:** Run `python test_grafana_metrics.py`
2. **Verify time range:** Metrics need 1-2 minutes to appear
3. **Check service name filter:** Should be `service_name="tellmemo-app"`

---

## 🎉 You Now Have

✅ **7 Production-Ready Dashboards**
✅ **65+ Business Metrics** tracked automatically
✅ **Complete Observability** - Business + Technical
✅ **Actionable Insights** for product, cost, and growth decisions

**Enjoy your beautiful dashboards!** 📊✨
