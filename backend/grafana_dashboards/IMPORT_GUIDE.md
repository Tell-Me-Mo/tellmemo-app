# 🚀 Quick Start Guide: Import Your Grafana Dashboards

## ✅ What You Have

**7 Beautiful, Production-Ready Dashboards** with **59 panels** tracking **65+ business metrics**:

| Dashboard | Panels | Focus Area |
|-----------|--------|------------|
| 📊 Business Overview | 9 | Daily KPIs, user activity, content processing |
| 💰 LLM Cost Optimization | 8 | Track every dollar, optimize spending |
| 🏢 Organization Health | 8 | Multi-tenant tracking, per-org costs |
| ⚠️ Churn Risk Detection | 8 | Identify at-risk users proactively |
| 🎯 SLA & Performance | 8 | Meet commitments, track availability |
| 📚 Content Quality | 8 | RAG effectiveness, coverage gaps |
| 🚀 Time-to-Value | 8 | Onboarding efficiency, activation |

---

## 📥 Import in 3 Minutes

### Step 1: Open Grafana Cloud
```
https://tellmemo.grafana.net/
```

### Step 2: Import Dashboards
1. Click **"Dashboards"** (left sidebar)
2. Click **"+ Create"** → **"Import"**
3. **Upload JSON file** → Select a dashboard from `backend/grafana_dashboards/`
4. Choose **Prometheus** data source
5. Click **"Import"**

### Step 3: Repeat for All 7
Import all dashboards for complete observability!

---

## 🎯 Recommended Import Order

### For First-Time Users:
1. **📊 Business Overview** - Get familiar with core metrics
2. **💰 LLM Cost Optimization** - Understand spending patterns
3. **🎯 SLA & Performance** - Ensure system health
4. **📚 Content Quality** - Check RAG effectiveness

### For Growth Teams:
5. **⚠️ Churn Risk Detection** - Proactive retention
6. **🚀 Time-to-Value** - Optimize onboarding funnel
7. **🏢 Organization Health** - B2B multi-tenant insights

---

## 📊 Dashboard Highlights

### 1. Business Overview - Your Command Center
```
┌─────────────────────────────────────────────────┐
│  Total Users │ Questions │ Success Rate │ Cost  │
│     127      │   1,234   │    87%      │ $12.34│
├─────────────────────────────────────────────────┤
│  📈 User Questions Over Time                     │
│                           .''''''''''''          │
│                      .''''                       │
│  Questions/min  .''''                            │
│             ''''                                 │
├─────────────────────────────────────────────────┤
│  Content Processed: 45.3 GB                      │
│  Projects Created Today: 12                      │
│  Coverage Gaps: 23 queries (needs attention)     │
└─────────────────────────────────────────────────┘
```

### 2. LLM Cost Optimization - Control Spending
```
┌─────────────────────────────────────────────────┐
│  Today: $45.23  │  Avg/Query: $0.02  │  Month  │
│                 │                     │ $1,356  │
├─────────────────────────────────────────────────┤
│  💰 Cost by Provider                             │
│  ████████ Claude: $25.10                         │
│  ████ OpenAI: $12.50                             │
│  ██ DeepSeek: $7.63 (cheapest!)                  │
├─────────────────────────────────────────────────┤
│  💡 Insight: DeepSeek is 10x cheaper!            │
│     Switch to save ~$1,000/month                 │
└─────────────────────────────────────────────────┘
```

### 3. Churn Risk Detection - Save Users
```
┌─────────────────────────────────────────────────┐
│  Inactive (7d) │ Declining │  WAU   │ Stickiness│
│      23        │     15    │  487   │   42%     │
├─────────────────────────────────────────────────┤
│  ⚠️  Action Required:                            │
│  • 15 users showing 50%+ engagement decline      │
│  • Send re-engagement email campaign            │
│  • Customer success outreach for top 5          │
└─────────────────────────────────────────────────┘
```

### 4. SLA & Performance - Meet Commitments
```
┌─────────────────────────────────────────────────┐
│  SLA Compliance │ Violations │ Error Budget │ Up │
│      96.2%      │     12     │    15.3%    │99.9│
├─────────────────────────────────────────────────┤
│  🎯 P95 Response Time: 1,850ms                   │
│     Target: <2,000ms ✅ MEETING SLA              │
│                                                  │
│  📊 Operations Violating SLA Most:               │
│     1. Complex RAG queries (3 violations)        │
│     2. Multi-project search (2 violations)       │
└─────────────────────────────────────────────────┘
```

---

## 🎨 Visualization Types

Your dashboards include:

### Stat Panels
Large numbers for instant insights (Total Users, Cost Today)

### Gauges
Visual SLA compliance, success rates (0-100%)

### Time Series
Trend lines showing patterns over time

### Pie Charts
Cost distribution, provider breakdown

### Bar Charts
Top 10 organizations, rankings

### Histograms
Activity streak distribution, time-to-value spread

---

## 🔧 Troubleshooting

### "No data" in panels?

**Check 1: Metrics are flowing**
```bash
cd /root/tellmemo-app/backend
source venv/bin/activate
python test_grafana_metrics.py
```

**Check 2: Time range**
- Metrics need 1-2 minutes to appear after backend restart
- Use "Last 24 hours" time range initially

**Check 3: Service name filter**
- Should be `service_name="tellmemo-app"`
- Check in panel query → Filters

### Wrong data source?
- All panels should use **Prometheus** (Grafana Cloud Managed)
- Re-import and select the correct data source

---

## 📱 Mobile Access

Dashboards are fully responsive!
- Access from phone: https://tellmemo.grafana.net/
- Create **Snapshots** for sharing
- Use **Grafana Mobile App** for iOS/Android

---

## ⚙️ Advanced Features

### Set Up Alerts (Recommended)

**High LLM Cost Alert:**
```promql
Alert: sum(rate(business_llm_cost_monthly[1h])) * 720 > 100
Threshold: >$100/month projected
Action: Email to finance team
```

**Churn Risk Alert:**
```promql
Alert: sum(business_users_inactive{period="7d"}) > 10
Threshold: >10 inactive users
Action: Slack notification to customer success
```

**SLA Violation Alert:**
```promql
Alert: avg(business_sla_compliance_rate) < 0.95
Threshold: <95% compliance
Action: PagerDuty incident
```

### Create Reports

1. Go to dashboard
2. Click **Share** → **Export** → **PDF**
3. Schedule weekly email reports
4. Send to stakeholders

### Customize Panels

- **Edit any panel:** Click title → Edit
- **Add new panels:** Click "+ Add panel"
- **Clone dashboards:** Settings → Save as...
- **Create variables:** Dashboard settings → Variables

---

## 📈 Metrics Reference

### Business Metrics (65+ total)

**User Engagement (7)**
- `business_users_active_daily` - DAU
- `business_users_active_weekly` - WAU
- `business_user_sessions_total` - Sessions
- `business_user_questions_total` - Questions asked
- `business_user_feedback_submitted` - Feedback count

**LLM Costs (4)**
- `business_llm_cost_by_provider` - Cost per provider
- `business_llm_cost_per_query` - Per-query cost
- `business_llm_cost_per_user` - Per-user cost
- `business_llm_cost_monthly` - Monthly tracking

**Organization (5)**
- `business_organization_queries_total` - Query volume per org
- `business_organization_llm_cost` - LLM cost per org
- `business_organization_active_users` - Active users per org

**Content Quality (4)**
- `business_content_coverage_gaps` - Failed queries
- `business_content_low_relevance_results` - Poor matches
- `business_content_utilization_rate` - % content accessed
- `business_content_staleness` - Content age

**SLA & Performance (4)**
- `business_sla_compliance_rate` - % meeting SLA
- `business_sla_violations` - Violation count
- `business_sla_error_budget_remaining` - Buffer remaining
- `business_sla_availability` - Uptime %

**Churn Risk (4)**
- `business_users_inactive` - Inactive users
- `business_users_engagement_decline` - Declining users
- `business_users_activity_streak` - Consecutive days

**Time-to-Value (4)**
- `business_users_time_to_first_query` - Signup → first query
- `business_users_first_query_success` - First query success rate
- `business_users_queries_until_success` - Attempts to success

... and 40+ more technical metrics!

---

## 🎓 Learning Resources

### Grafana Documentation
- [Grafana Dashboard Guide](https://grafana.com/docs/grafana/latest/dashboards/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Panel Types](https://grafana.com/docs/grafana/latest/panels-visualizations/)

### TellMeMo Metrics
- See `backend/observability/business_metrics.py` for all metrics
- See `backend/observability/GRAFANA_DASHBOARDS.md` for PromQL queries
- See `backend/observability/CRITICAL_METRICS_SUMMARY.md` for explanations

---

## 🎯 Success Criteria

**You'll know it's working when you can answer:**

✅ **Business Questions:**
- How many daily active users do we have?
- What's our LLM cost per user?
- Which organizations are at risk of churning?
- Are we meeting our SLA commitments?

✅ **Product Questions:**
- How long until users get value?
- What % of queries fail due to missing content?
- Which features are most used?
- Is onboarding smooth or frustrating?

✅ **Technical Questions:**
- What's our P95 latency?
- Which LLM provider is cheapest?
- What's our actual uptime?
- Are we consuming our error budget?

---

## 🎉 Next Steps

1. **Import all 7 dashboards** (5 minutes)
2. **Pin Business Overview to favorites** (your daily driver)
3. **Set up 3 critical alerts** (cost, churn, SLA)
4. **Schedule weekly PDF reports** (stakeholder communication)
5. **Share dashboards with your team** (Settings → Permissions)

---

## 💡 Pro Tips

**Keyboard Shortcuts:**
- `d` + `k` = Dashboard search
- `Esc` = Exit panel edit mode
- `Ctrl/Cmd` + `S` = Save dashboard

**Best Practices:**
- Refresh interval: 30s-1m for business dashboards
- Use variables for filtering (project_id, organization_id)
- Clone before making major changes
- Version control: Export JSON regularly

**Performance:**
- Limit time range for faster loading
- Use recording rules for complex queries
- Cache heavy computations with Grafana vars

---

## 📞 Need Help?

**Dashboard Issues:**
- Check `backend/grafana_dashboards/README.md` for detailed guide
- Test metrics: `python test_grafana_metrics.py`
- Verify telemetry: Check `backend/logs/` for OpenTelemetry errors

**Metric Questions:**
- See metric definitions in `backend/observability/business_metrics.py`
- Query examples in `backend/observability/GRAFANA_DASHBOARDS.md`

---

**Enjoy your beautiful, actionable dashboards!** 📊✨

Your metrics are already flowing - just import and start making data-driven decisions! 🚀
