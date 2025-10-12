# Email Digest Feature - Technical Architecture & Implementation Plan

**Feature Branch:** `feature/email-digest-report`
**Created:** 2025-10-12
**Status:** Planning Phase

---

## Table of Contents

1. [Feature Overview](#feature-overview)
2. [Current Infrastructure Analysis](#current-infrastructure-analysis)
3. [Architecture Design](#architecture-design)
4. [Database Schema Changes](#database-schema-changes)
5. [Backend Implementation](#backend-implementation)
6. [Frontend Implementation](#frontend-implementation)
7. [Email Templates](#email-templates)
8. [Testing Strategy](#testing-strategy)
9. [Implementation Roadmap](#implementation-roadmap)
10. [Success Metrics](#success-metrics)

---

## Feature Overview

### Business Goals
- **Increase user engagement** by delivering insights via email
- **Reduce churn** by keeping users informed without requiring login
- **Expand reach** to stakeholders who don't use the platform daily
- **Automate reporting** to save time for project managers

### User Stories

**As a Project Manager**, I want to:
- Receive daily/weekly digest emails about my projects
- Configure which projects to include in digests
- Choose digest frequency (daily, weekly, monthly)
- Customize what information to include

**As an Executive**, I want to:
- Receive portfolio-level summaries via email
- Get only high-priority updates (risks, blockers, decisions)
- Unsubscribe from digests I don't need

**As a Team Member**, I want to:
- Get notifications about tasks assigned to me
- Receive summaries of meetings I attended
- Control email notification preferences

### Feature Scope

**In Scope:**
- ✅ SMTP integration with popular providers
- ✅ User email preferences (digest frequency, content types)
- ✅ Daily/weekly/monthly digest generation
- ✅ Project-level digests (activities, summaries, tasks, risks)
- ✅ Portfolio/program-level digests (rollup view)
- ✅ HTML email templates (responsive design)
- ✅ Scheduled job system for automated sending
- ✅ Email unsubscribe functionality
- ✅ Digest preview in UI before sending

**Out of Scope (Future Enhancements):**
- ❌ Real-time email notifications (instant alerts)
- ❌ Email threading/conversations
- ❌ Email reply processing
- ❌ Custom email template builder UI
- ❌ A/B testing for email content

---

## Current Infrastructure Analysis

### Existing Components

#### ✅ Notification System
- **Location:** `backend/services/notifications/notification_service.py`
- **Features:**
  - Well-structured notification types, priorities, categories
  - In-app notification delivery working
  - WebSocket real-time updates functional
  - Supports `delivered_channels` array for multi-channel delivery
  - Has `email_sent_at` timestamp field (ready for email integration)

#### ✅ Email Service (Partial)
- **Location:** `backend/services/integrations/email_service.py`
- **Current State:**
  - Only supports Supabase Auth emails (invitations, password resets)
  - Has `send_custom_email()` placeholder method
  - Has `send_weekly_report_email()` stub implementation
  - **Gap:** No actual SMTP integration for custom emails

#### ✅ Redis Queue System
- **Location:** `backend/queue_config.py`
- **Features:**
  - Multi-priority queues (high, default, low)
  - Job progress tracking via Redis pub/sub
  - Automatic retry on failure
  - Well-tested with transcription and content processing

#### ✅ Database Models
- **User Model:** Has `preferences` JSON field for storing email settings
- **Notification Model:** Ready for email delivery tracking
- **Summary Model:** Rich structured data for digest content
- **Activity Model:** Tracks all user/project activities

#### ❌ Missing Components
- **No SMTP configuration** in environment variables
- **No email digest preferences** schema/table
- **No scheduled job system** for digest generation
- **No HTML email templates**
- **No digest aggregation service**

---

## Architecture Design

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER PREFERENCE MANAGEMENT                   │
│  - User configures digest preferences in UI                     │
│  - Frequency: daily, weekly, monthly, never                     │
│  - Content types: summaries, tasks, risks, activities           │
│  - Project/portfolio selection                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SCHEDULED JOB SCHEDULER                      │
│  - APScheduler (or similar) runs periodic jobs                  │
│  - Daily: 8 AM user's timezone                                  │
│  - Weekly: Monday 8 AM                                          │
│  - Monthly: 1st of month 8 AM                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DIGEST GENERATION SERVICE                    │
│  1. Query users with digest_enabled=True for frequency          │
│  2. For each user:                                              │
│     - Fetch projects/portfolios based on preferences            │
│     - Aggregate data (activities, summaries, tasks, risks)      │
│     - Generate personalized digest content                      │
│     - Queue email job in Redis Queue (low priority)             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REDIS QUEUE (LOW PRIORITY)                   │
│  - email_digest_task(user_id, digest_data)                      │
│  - Batch processing to avoid rate limits                        │
│  - Retry on failure (max 3 attempts)                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EMAIL SENDING SERVICE                        │
│  1. Render HTML template with digest data                       │
│  2. Send via SMTP (SendGrid/AWS SES/Mailgun)                    │
│  3. Track delivery status                                       │
│  4. Update notification record (email_sent_at timestamp)        │
│  5. Log errors for failed deliveries                            │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow: Daily Digest

```
08:00 AM (User Timezone)
     │
     ▼
[APScheduler Trigger] → daily_digest_job()
     │
     ▼
Query Users:
  SELECT * FROM users
  WHERE preferences->>'digest_frequency' = 'daily'
  AND preferences->>'digest_enabled' = true
     │
     ▼
For each user:
     │
     ├─ Fetch user's organizations
     ├─ Fetch projects (based on preferences)
     ├─ Query activities (last 24 hours)
     ├─ Query summaries (last 24 hours)
     ├─ Query tasks (assigned to user, due soon)
     ├─ Query risks (high/critical severity)
     │
     ▼
Aggregate & Format Data:
  {
    "user_name": "John Doe",
    "digest_period": "Last 24 hours",
    "summary_stats": {
      "projects_active": 5,
      "new_summaries": 3,
      "pending_tasks": 7,
      "critical_risks": 2
    },
    "projects": [
      {
        "name": "Project Alpha",
        "activities": [...],
        "summaries": [...],
        "tasks": [...],
        "risks": [...]
      }
    ]
  }
     │
     ▼
Enqueue Email Job:
  queue_config.low_queue.enqueue(
    'email_digest_task',
    user_id=user.id,
    digest_data=data
  )
     │
     ▼
[RQ Worker] Process email_digest_task:
     │
     ├─ Render HTML template
     ├─ Send via SMTP
     ├─ Update notification record
     └─ Log delivery status
```

---

## Database Schema Changes

### 1. Add Email Digest Preferences to User

**No new table needed!** Use existing `users.preferences` JSON field.

**Example preferences structure:**
- `email_digest.enabled`: boolean
- `email_digest.frequency`: "daily" | "weekly" | "monthly" | "never"
- `email_digest.timezone`: User's timezone for scheduling
- `email_digest.send_time`: Preferred time (e.g., "08:00")
- `email_digest.content_types`: Array of content to include (summaries, activities, tasks_assigned, risks_critical, decisions)
- `email_digest.project_filter`: Object defining which projects to include
- `email_digest.portfolio_filter`: Object defining portfolio selection
- `email_digest.include_portfolio_rollup`: boolean
- `email_digest.last_sent_at`: ISO timestamp

### 2. Email Delivery Tracking

**Use existing `notifications` table!**

The `Notification` model already has:
- `delivered_channels` - Array to track delivery methods
- `email_sent_at` - Timestamp when email was sent
- `extra_data` (metadata) - Can store digest info

**Create new notification category:**
- Add `EMAIL_DIGEST_SENT` to `NotificationCategory` enum

### 3. Migration Script

**Alembic Migration:** `add_email_digest_preferences.py`

The migration will:
- Update existing users with default `email_digest` preferences in JSON field
- Set `enabled: false` by default
- Set default frequency to "weekly"
- Set default timezone to "UTC"
- Include default content types: summaries, tasks_assigned, risks_critical

---

## Backend Implementation

### 1. Environment Variables

**Add to `.env.example` and `.env`:**

Required configuration variables:
- `EMAIL_PROVIDER`: smtp | sendgrid | aws_ses | mailgun
- `EMAIL_FROM_ADDRESS`: Sender email address
- `EMAIL_FROM_NAME`: Sender display name

**For SMTP:**
- `SMTP_HOST`: SMTP server hostname
- `SMTP_PORT`: SMTP port (usually 587)
- `SMTP_USERNAME`: SMTP username
- `SMTP_PASSWORD`: SMTP password
- `SMTP_USE_TLS`: Enable TLS (true/false)

**For SendGrid:**
- `SENDGRID_API_KEY`: API key

**For AWS SES:**
- `AWS_SES_ACCESS_KEY_ID`: Access key
- `AWS_SES_SECRET_ACCESS_KEY`: Secret key
- `AWS_SES_REGION`: AWS region

**For Mailgun:**
- `MAILGUN_API_KEY`: API key
- `MAILGUN_DOMAIN`: Configured domain

**Digest Configuration:**
- `EMAIL_DIGEST_ENABLED`: Enable/disable feature
- `EMAIL_DIGEST_BATCH_SIZE`: Max emails per batch (default: 50)
- `EMAIL_DIGEST_RATE_LIMIT`: Max emails per hour (default: 100)

### 2. Update `config.py`

Add all environment variables to Settings class with proper types and defaults.

### 3. SMTP Service Implementation

**Create:** `backend/services/email/smtp_service.py`

**Key responsibilities:**
- Unified interface for multiple email providers
- Support SMTP, SendGrid, AWS SES, Mailgun
- Handle email sending with HTML and plain text versions
- Error handling and logging
- Return success/failure status

**Methods:**
- `send_email()`: Main method to send email via configured provider
- `_send_via_smtp()`: Standard SMTP implementation
- `_send_via_sendgrid()`: SendGrid API implementation
- `_send_via_ses()`: AWS SES implementation
- `_send_via_mailgun()`: Mailgun API implementation

### 4. Email Digest Service

**Create:** `backend/services/email/digest_service.py`

**Key responsibilities:**
- Generate daily/weekly/monthly digests
- Aggregate digest data from database
- Query users based on preferences
- Enqueue email jobs in Redis Queue

**Methods:**
- `generate_daily_digests()`: Create daily digest jobs
- `generate_weekly_digests()`: Create weekly digest jobs
- `generate_monthly_digests()`: Create monthly digest jobs
- `aggregate_digest_data()`: Collect all data for a user's digest
- `_get_user_projects()`: Fetch projects based on user preferences
- `_get_project_summaries()`: Get summaries in time period
- `_get_project_activities()`: Get activities in time period
- `_get_user_tasks()`: Get tasks assigned to user
- `_get_critical_risks()`: Get high/critical risks
- `_calculate_stats()`: Calculate summary statistics
- `_format_period()`: Format time period for display

### 5. Email Task (Redis Queue)

**Create:** `backend/tasks/email_tasks.py`

**Key responsibilities:**
- RQ task wrapper for digest email sending
- Async email sending implementation
- Job progress tracking
- Error handling and retry logic

**Functions:**
- `send_digest_email_task()`: RQ task entry point
- `_send_digest_async()`: Async implementation

**Process:**
1. Fetch user from database
2. Calculate time period based on digest type
3. Aggregate digest data via DigestService
4. Render email templates via TemplateService
5. Send email via SMTPService
6. Create notification record
7. Update user preferences with last_sent_at timestamp

### 6. Email Template Service

**Create:** `backend/services/email/template_service.py`

**Key responsibilities:**
- Render Jinja2 HTML email templates
- Render plain text fallback versions
- Handle template errors gracefully
- Provide fallback content if templates fail

**Methods:**
- `render_digest_email()`: Render HTML digest template
- `render_digest_email_text()`: Render plain text version
- `_fallback_html()`: Simple HTML fallback
- `_fallback_text()`: Simple text fallback

### 7. Scheduler Service

**Create:** `backend/services/scheduler/digest_scheduler.py`

**Key responsibilities:**
- Initialize APScheduler
- Configure cron triggers for digest jobs
- Run scheduled digest generation

**Methods:**
- `start()`: Start scheduler and register jobs
- `stop()`: Shutdown scheduler
- `_run_daily_digests()`: Execute daily digest generation
- `_run_weekly_digests()`: Execute weekly digest generation
- `_run_monthly_digests()`: Execute monthly digest generation

**Schedule:**
- Daily: Every day at 8 AM UTC
- Weekly: Every Monday at 8 AM UTC
- Monthly: 1st of each month at 8 AM UTC

### 8. API Endpoints

**Create:** `backend/routers/email_preferences.py`

**Endpoints:**

**GET `/api/email-preferences/digest`**
- Get user's current email digest preferences
- Returns preferences JSON object

**PUT `/api/email-preferences/digest`**
- Update user's email digest preferences
- Request body: EmailDigestPreferences model
- Returns updated preferences

**POST `/api/email-preferences/digest/preview`**
- Generate preview of digest email without sending
- Query param: digest_type (daily/weekly/monthly)
- Returns HTML preview and aggregated data

**POST `/api/email-preferences/digest/send-test`**
- Send test digest email immediately to current user
- Enqueues job in high-priority queue
- Returns job ID and status

---

## Email Templates

### Directory Structure

```
backend/
└── templates/
    └── email/
        ├── base.html                   # Base template with header/footer
        ├── digest_email.html           # HTML digest template
        ├── digest_email.txt            # Plain text digest template
        ├── components/
        │   ├── summary_card.html       # Summary component
        │   ├── task_list.html          # Task list component
        │   ├── risk_alert.html         # Risk alert component
        │   └── activity_feed.html      # Activity feed component
        └── styles/
            └── email_styles.css        # Inline CSS for emails
```

### Base Template Design

**File:** `backend/templates/email/base.html`

**Key features:**
- Responsive design (max-width: 600px)
- Inline CSS for email compatibility
- Header with TellMeMo branding
- Content block
- Footer with preferences and unsubscribe links
- Professional color scheme (purple gradient: #667eea to #764ba2)

**Blocks:**
- `title`: Page title
- `header_subtitle`: Subtitle in header
- `content`: Main email content

### Digest Email Template

**File:** `backend/templates/email/digest_email.html`

**Sections:**
1. **Greeting**: Personalized user greeting
2. **Summary Statistics**: 4-column stats display
   - Active Projects
   - New Summaries
   - Pending Tasks
   - Critical Risks
3. **Project Details**: Per-project breakdown
   - Recent Summaries
   - Your Tasks
   - Critical Risks
   - View Project button
4. **Call to Action**: Open TellMeMo Dashboard button

**Design Features:**
- Uses Jinja2 template inheritance
- Conditional rendering based on content availability
- Styled cards for each project
- Color-coded risk alerts (red)
- Responsive button styling

---

## Frontend Implementation

### 1. Email Preferences Screen

**Create:** `lib/features/settings/presentation/screens/email_preferences_screen.dart`

**UI Components:**

**Enable/Disable Section:**
- SwitchListTile for enabling email digests

**Frequency Selection:**
- Radio buttons for Daily, Weekly, Monthly

**Content Type Selection:**
- Checkboxes for:
  - Meeting Summaries
  - Tasks Assigned to Me
  - Critical Risks
  - Project Activities

**Action Buttons:**
- Save Preferences (primary button)
- Preview Digest (outlined button)
- Send Test Email (outlined button)

**State Management:**
- Local state for form data
- API integration for save/load preferences
- Loading states and error handling
- Success/error snackbars

### 2. API Client Integration

**Required methods:**
- `getDigestPreferences()`: Fetch current preferences
- `updateDigestPreferences()`: Save preferences
- `previewDigest()`: Get preview HTML
- `sendTestDigest()`: Trigger test email

### 3. Navigation

Add email preferences screen to settings menu with appropriate routing.

---

## Testing Strategy

### 1. Unit Tests

**Backend:**
- `test_smtp_service.py` - Test email sending with mocked SMTP
- `test_digest_service.py` - Test digest data aggregation
- `test_template_service.py` - Test template rendering
- `test_email_tasks.py` - Test RQ job execution

**Frontend:**
- `email_preferences_screen_test.dart` - Test UI interactions
- `email_preferences_provider_test.dart` - Test state management

### 2. Integration Tests

- End-to-end digest generation flow
- SMTP provider integration (SendGrid, AWS SES, etc.)
- Scheduler trigger verification
- Database preference updates

### 3. Manual Testing Checklist

- [ ] Configure SMTP credentials
- [ ] Enable email digests for test user
- [ ] Trigger manual digest send
- [ ] Verify email received with correct content
- [ ] Test unsubscribe link
- [ ] Test different frequencies (daily, weekly, monthly)
- [ ] Test different content type combinations
- [ ] Test email preview in UI
- [ ] Test HTML rendering in different email clients
- [ ] Test plain text fallback

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1)

**Backend:**
- [ ] Add SMTP configuration to `.env` and `config.py`
- [ ] Implement `SMTPService` with SMTP provider (start with one, e.g., SMTP)
- [ ] Create database migration for email preferences
- [ ] Update `User` model with default email preferences
- [ ] Create `email_preferences` API endpoints (GET, PUT)

**Frontend:**
- [ ] Create Email Preferences screen UI
- [ ] Implement API client for preferences
- [ ] Add navigation to settings

**Testing:**
- [ ] Unit test SMTP service with mock
- [ ] Test API endpoints
- [ ] Test UI interactions

### Phase 2: Digest Generation (Week 2)

**Backend:**
- [ ] Implement `DigestService` data aggregation
- [ ] Create `TemplateService` for email rendering
- [ ] Implement base HTML email template
- [ ] Implement digest email template (HTML + text)
- [ ] Create RQ task `send_digest_email_task`

**Testing:**
- [ ] Test digest data aggregation
- [ ] Test template rendering
- [ ] Test RQ task execution
- [ ] Send test digest manually

### Phase 3: Scheduling (Week 3)

**Backend:**
- [ ] Implement `DigestScheduler` with APScheduler
- [ ] Add scheduler initialization to FastAPI startup
- [ ] Configure cron triggers for daily/weekly/monthly
- [ ] Implement batch processing for rate limiting

**Testing:**
- [ ] Test scheduler triggers
- [ ] Test batch processing
- [ ] Test rate limiting
- [ ] Monitor logs for scheduled runs

### Phase 4: Polish & Features (Week 4)

**Backend:**
- [ ] Add additional SMTP providers (SendGrid, AWS SES, Mailgun)
- [ ] Implement unsubscribe functionality
- [ ] Add digest preview endpoint
- [ ] Add send test email endpoint
- [ ] Optimize database queries for performance

**Frontend:**
- [ ] Implement digest preview dialog
- [ ] Add test email send button
- [ ] Add unsubscribe management
- [ ] Polish UI/UX

**Testing:**
- [ ] End-to-end integration tests
- [ ] Load testing (simulate 1000+ users)
- [ ] Email client compatibility testing
- [ ] User acceptance testing

### Phase 5: Deployment & Monitoring

- [ ] Deploy to production
- [ ] Configure production SMTP credentials
- [ ] Set up monitoring/alerts for failed emails
- [ ] Monitor email delivery rates
- [ ] Gather user feedback
- [ ] Iterate based on analytics

---

## Success Metrics

### Technical Metrics

- **Email Delivery Rate:** >95% successfully delivered
- **Digest Generation Time:** <5 seconds per user
- **Queue Processing Time:** <10 minutes for 1000 users
- **Email Open Rate:** >30% (industry average: 20-25%)
- **Click-through Rate:** >10%
- **Unsubscribe Rate:** <2%

### Business Metrics

- **User Engagement:** +20% increase in weekly active users
- **Session Frequency:** +15% increase in login frequency
- **User Retention:** +10% improvement in 30-day retention
- **Feature Adoption:** 50% of users enable email digests

### Monitoring & Alerts

- **Failed Email Alerts:** Trigger alert if >5% emails fail
- **Scheduler Health:** Alert if scheduler stops running
- **Queue Backlog:** Alert if queue exceeds 1000 pending jobs
- **SMTP Rate Limits:** Monitor and alert on approaching limits

---

## Future Enhancements

### Phase 2 (Post-MVP)

1. **Smart Digest Timing**
   - Machine learning to determine optimal send time per user
   - Timezone-aware sending
   - Frequency auto-adjustment based on engagement

2. **Personalized Content**
   - AI-generated summaries tailored to user role
   - Priority-based content ordering
   - Dynamic content based on user behavior

3. **Interactive Emails**
   - Mark tasks complete from email (AMP for Email)
   - Reply to comments
   - Quick actions (approve/reject)

4. **Advanced Analytics**
   - Email engagement dashboard
   - A/B testing for subject lines
   - Content performance tracking

5. **Multi-channel Delivery**
   - Slack digest integration
   - Microsoft Teams integration
   - Push notifications (mobile)

---

## Appendix

### Dependencies to Add

**Backend:**
- `apscheduler==3.10.4` - Job scheduling
- `jinja2==3.1.2` - Template rendering
- `sendgrid==6.10.0` - SendGrid provider (optional)
- `boto3==1.28.85` - AWS SES provider (optional)

**Frontend:**
- `intl: ^0.18.0` - Timezone handling

### Configuration Examples

**Gmail SMTP:**
- EMAIL_PROVIDER=smtp
- SMTP_HOST=smtp.gmail.com
- SMTP_PORT=587
- SMTP_USERNAME=your-email@gmail.com
- SMTP_PASSWORD=your-app-password
- SMTP_USE_TLS=true

**SendGrid:**
- EMAIL_PROVIDER=sendgrid
- SENDGRID_API_KEY=SG.xxx

**AWS SES:**
- EMAIL_PROVIDER=aws_ses
- AWS_SES_ACCESS_KEY_ID=AKIA...
- AWS_SES_SECRET_ACCESS_KEY=xxx
- AWS_SES_REGION=us-east-1

---

## Questions & Decisions

**Q: Which SMTP provider should we use?**
A: Start with generic SMTP (supports Gmail, Outlook) for MVP. Add SendGrid/AWS SES for production scale.

**Q: How to handle email bounces?**
A: Phase 2 - implement webhook handlers for bounce/complaint notifications.

**Q: Should we use HTML or plain text?**
A: Both! HTML for rich formatting, plain text as fallback.

**Q: How to handle timezone conversion?**
A: Store user timezone in preferences, convert all times to user's local timezone in templates.

**Q: Rate limiting strategy?**
A: Batch process 50 emails at a time with 1-second delay between batches.

---

## Resources

- [SendGrid Email API Docs](https://docs.sendgrid.com/)
- [AWS SES Developer Guide](https://docs.aws.amazon.com/ses/)
- [Email Design Best Practices](https://www.campaignmonitor.com/resources/guides/email-design-best-practices/)
- [APScheduler Documentation](https://apscheduler.readthedocs.io/)
- [Jinja2 Template Designer Docs](https://jinja.palletsprojects.com/)

---

**Document End**
