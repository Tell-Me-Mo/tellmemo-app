# TellMeMo - User Journey & Feature Guide

## Executive Summary

This document describes the complete user experience with **TellMeMo**, a multi-tenant SaaS platform for portfolio, program, and project management with AI-powered content analysis.

**Document Status**: October 2025 - Reflects current production implementation.

---

## Table of Contents

1. [What is TellMeMo](#what-is-tellmemo)
2. [User Personas](#user-personas)
3. [Getting Started - Organization Setup](#getting-started---organization-setup)
4. [Project Management](#project-management)
5. [Content Upload & Processing](#content-upload--processing)
6. [AI-Powered Features](#ai-powered-features)
7. [Summary Generation](#summary-generation)
8. [Portfolio & Program Management](#portfolio--program-management)
9. [Collaboration Features](#collaboration-features)
10. [Integrations](#integrations)
11. [Best Practices](#best-practices)

---

## What is TellMeMo

**TellMeMo** is a multi-tenant SaaS platform that helps teams extract insights from project content using AI.

### Core Capabilities

**Content Intelligence:**
- Upload meeting transcripts, audio files, documents, and emails
- AI automatically analyzes and extracts insights
- Query your project knowledge using natural language
- Generate summaries at project, program, and portfolio levels

**Project Organization:**
- 3-tier hierarchy: Portfolio → Program → Project
- Multi-tenant architecture with organization isolation
- Role-based access control (owner, admin, member)

**AI-Powered Analysis:**
- Semantic search across all project content
- RAG-based question answering
- Automatic risk and task extraction
- Multi-format summary generation

---

## User Personas

| Persona | Role | Key Needs | Platform Usage |
|---------|------|-----------|----------------|
| **Sarah** | Project Manager | Project tracking, decision management, stakeholder communication | Daily - manages projects, uploads content, generates summaries |
| **John** | Team Lead | Technical decisions, action tracking, team coordination | Daily - uploads meetings, queries project knowledge, tracks tasks |
| **Mike** | Team Member | Task clarity, meeting context, deliverable tracking | Weekly - reviews summaries, checks assigned tasks |
| **Emily** | Executive Sponsor | High-level insights, risk visibility, strategic decisions | Monthly - reviews executive summaries, monitors portfolios |
| **Lisa** | PMO Director | Portfolio visibility, program oversight, resource optimization | Weekly - monitors multiple projects, generates program summaries |

---

## Getting Started - Organization Setup

### Step 1: User Registration

**Process:**
1. Visit TellMeMo landing page
2. Click "Sign Up"
3. Enter email and password
4. Verify email address
5. Redirected to organization setup

**What Happens:**
- User account created
- Verification email sent
- User profile initialized
- Ready to create organization

### Step 2: Create Organization

**Process:**
1. Enter organization details:
   - Name (required)
   - Description (optional)
   - Industry/domain (optional)
2. Submit to create organization
3. Automatically assigned as organization owner

**What Happens:**
- Organization workspace created
- User becomes owner with full permissions
- Organization-specific data storage initialized
- Ready to invite team members and create projects

### Step 3: Invite Team Members

**Two Methods:**

**Single Invitation:**
1. Access Member Management
2. Enter email, name, and role
3. Send invitation

**Bulk Invitation (CSV):**
1. Upload CSV file with multiple users
2. System processes and sends invitations

**Invitation Process:**
- Invitation records created
- Email notifications sent (if configured)
- Users receive invitation link
- Upon acceptance, users join organization with assigned role

**Roles Available:**
- Owner - Full access, can manage members
- Admin - Full access, limited member management
- Member - Standard access

---

## Project Management

### Hierarchy Structure

TellMeMo uses a 3-tier hierarchy:

```
Portfolio (Strategic grouping)
  └─ Program (Related projects)
      └─ Project (Individual project)
```

Projects can exist:
- Standalone (no parent)
- Under a program
- Under a portfolio directly

### Creating Projects

**Process:**
1. Navigate to Hierarchy screen
2. Click "Create Project"
3. Enter details:
   - Project name
   - Description
   - Portfolio/Program assignment (optional)
   - Status (active, on_hold, completed, archived)
4. Add team members (optional):
   - Member name
   - Email
   - Role

**What Happens:**
- Project workspace created
- Project linked to organization
- Team members added to project
- Content storage initialized

### Managing Projects

**Available Operations:**
- View project details
- Edit project information
- Move between portfolios/programs
- Add/remove team members
- Upload content
- Generate summaries
- Track risks and tasks
- Delete project (cascade deletion)

**Navigation:**
- Hierarchy tree view with expand/collapse
- Breadcrumb navigation
- Direct project access
- Portfolio/program drill-down

---

## Content Upload & Processing

### Supported Content Types

- **Meeting transcripts** (.txt, .md)
- **Audio files** (.wav, .mp3, .m4a, .webm)
- **Documents** (.pdf, .docx, .txt)
- **Email threads**
- **Project notes**

### Upload Process

**User Flow:**
1. Access project details
2. Click "Upload Content"
3. Select files (drag-and-drop or file picker)
4. Files validated automatically
5. Watch real-time upload progress
6. Receive notification when processing completes

**Processing Pipeline:**

**1. File Upload**
- File validated and securely stored
- Upload tracked with progress indicator
- Real-time status updates

**2. Transcription (for audio)**
- Audio converted to text automatically
- High-quality transcription service
- Text extracted and stored

**3. Content Processing**
- Content analyzed and indexed
- Text split into manageable segments
- Context and structure preserved
- Speaker attribution maintained (for transcripts)

**4. AI Indexing**
- Content prepared for semantic search
- Indexed for fast querying
- Made searchable across organization

**Status Tracking:**
- Uploading → Processing → Indexing → Ready
- Real-time progress updates
- Automatic error handling

### Managing Content

**Available Operations:**
- List all project content
- View content details
- Delete content
- Link content to summaries

---

## AI-Powered Features

### RAG-Based Querying

**How It Works:**
1. User asks question in natural language
2. System finds relevant content across all project materials
3. AI analyzes context and generates comprehensive answer
4. Response includes source citations linking to original content

**Example Queries:**
- "What were the key decisions in the last sprint planning?"
- "What risks were identified related to API integration?"
- "Summarize all action items assigned to John"
- "What technical challenges were discussed last week?"

**Features:**
- Conversation threading (multi-turn dialogue)
- Context-aware follow-up questions
- Source citations with content references
- Token usage and cost tracking

**Models Supported:**
- Claude Haiku (fast, cost-effective)
- Claude Sonnet (balanced)
- Claude Opus (highest quality)

### Risks & Tasks Management

**Capabilities:**
- View AI-extracted risks and tasks
- Manually add/edit/delete
- Assign to team members
- Update status (open, in_progress, resolved, closed)
- Track blockers and mitigation plans

**Risk Fields:**
- Title, description
- Severity level
- Status
- Assigned to
- Mitigation plan

**Task Fields:**
- Title, description
- Status, priority
- Assigned to
- Due date
- Question to ask
- Linked blockers

### Lessons Learned

**Process:**
1. Access Lessons Learned section
2. Document insights:
   - What went well
   - What didn't go well
   - What to improve
   - Recommendations
3. Categorize by type
4. Link to specific content

**Benefits:**
- Searchable across organization
- Included in project summaries
- Available for cross-project learning

---

## Summary Generation

### Summary Types

TellMeMo generates summaries at multiple levels:

**1. Meeting/Content Summaries**
- Individual content piece summary
- Specific to uploaded document, transcript, or audio

**2. Project Summaries**
- Aggregates all project content
- Includes risks, tasks, lessons learned
- Multiple time ranges supported

**3. Program Summaries**
- Rollup of all projects in program
- Cross-project insights
- Strategic overview

**4. Portfolio Summaries**
- Strategic-level summary
- All programs and projects
- Executive perspective

### Summary Formats

**General Format:**
- Balanced overview
- All stakeholders

**Executive Format:**
- High-level insights
- Strategic decisions
- Risk overview
- Business impact

**Technical Format:**
- Detailed technical discussion
- Implementation details
- Technical decisions
- Architecture notes

**Stakeholder Format:**
- External communication
- Progress updates
- Milestone status
- Client-facing information

### Generation Process

**User Flow:**
1. Request summary from:
   - Summaries screen
   - Project/program/portfolio detail screen
2. Select parameters:
   - Entity type
   - Summary type
   - Format
   - Date range (optional)
   - Specific content (for meeting summaries)
3. AI generates summary
4. View and share results

**Summary Contents:**
- Subject line
- Body text
- Key points
- Decisions (if applicable)
- Action items (if applicable)
- Risks (if applicable)
- Lessons learned (if applicable)
- Communication insights
- Next meeting agenda suggestions

**Features:**
- Regenerate with different format
- Token and cost tracking
- Export capabilities (planned)

---

## Portfolio & Program Management

### Portfolio Management

**Features:**
- Create and manage portfolios
- View all child programs and projects
- Track overall health status
- Assign owner and description
- Generate portfolio summaries
- Move programs between portfolios

**Portfolio Metrics:**
- Number of programs
- Number of projects (total)
- Overall health
- Risk overview

### Program Management

**Features:**
- Create and manage programs
- Assign to portfolio (optional)
- View all child projects
- Track program status
- Generate program summaries
- Move between portfolios
- Move projects between programs

**Program Metrics:**
- Number of projects
- Parent portfolio
- Overall status

### Cross-Entity Summaries

**Capabilities:**
- Aggregate content from all child entities
- Generate strategic insights
- Risk aggregation across projects
- Resource allocation view
- Strategic recommendations

---

## Collaboration Features

### Activity Feed

**What's Tracked:**
- Content uploads
- Summary generations
- Risk/task updates
- Member activities
- Project changes

**Features:**
- Filter by project
- Filter by user
- Filter by activity type
- Chronological timeline

### Real-Time Notifications

**Notification Types:**
- Organization invitations
- Content processing complete
- Summary generated
- Task assigned
- Risk escalation
- Support ticket updates

**Delivery Methods:**
- In-app notification center
- Toast notifications (non-intrusive popups)
- Real-time updates (instant delivery)

**Management:**
- Mark as read/unread
- Delete notifications
- Bulk mark all as read

### Support Ticket System

**Features:**
- Create support tickets
- Track status (open, in_progress, resolved, closed)
- Set priority (low, medium, high, urgent)
- Categorize (bug, feature_request, question, other)
- Receive instant updates
- Get admin responses

**Ticket Lifecycle:**
1. User creates ticket
2. Admin reviews and responds
3. Status updates tracked
4. Real-time notifications
5. Ticket resolved/closed

---

## Integrations

### Fireflies.ai Integration

**Setup:**
1. Access Integrations screen
2. Click "Connect Fireflies"
3. Enter Fireflies API key
4. Authorize access

**Features:**
- Sync past meeting transcripts
- List available recordings
- Import specific transcripts
- Webhook for new recordings (basic)

**Status:**
- API connection functional
- Manual sync working
- Webhook endpoint available
- Production testing ongoing

### Planned Integrations

- Slack notifications
- Microsoft Teams notifications
- Google Calendar sync
- Outlook Calendar sync
- Jira task sync
- Linear task sync
- Notion export

---

## Getting the Most from TellMeMo

### Best Practices

**Content Organization:**
- Upload content regularly
- Use descriptive titles
- Organize projects within programs/portfolios
- Keep team member lists updated

**Querying:**
- Ask specific questions
- Use follow-up questions for clarification
- Review source citations
- Save important queries

**Summary Generation:**
- Choose appropriate format for audience
- Use date ranges for focused summaries
- Regenerate in different formats as needed
- Share summaries with stakeholders

**Risk & Task Management:**
- Review AI-extracted items regularly
- Assign owners promptly
- Update status frequently
- Document mitigation plans

**Collaboration:**
- Monitor notifications
- Review activity feed
- Use support tickets for issues
- Invite team members early

### Performance Tips

**Upload Efficiency:**
- Batch similar content together
- Use appropriate file formats
- Monitor upload progress
- Check processing status in real-time

**Query Optimization:**
- Start with specific questions
- Use project-scoped queries
- Leverage conversation threading
- Review token usage

**Summary Cost Management:**
- Choose Haiku model for routine summaries (fast and economical)
- Use Sonnet model for balanced quality and speed
- Reserve Opus model for critical executive summaries (highest quality)
- Monitor AI usage costs in platform analytics

---

## Platform Status

**Current State:** Production-ready SaaS platform

**Core Strengths:**
- Enterprise-grade security with organization isolation
- AI-powered content analysis and intelligent querying
- Flexible 3-tier project hierarchy (Portfolio/Program/Project)
- Real-time collaboration and notifications
- Comprehensive feature set for project teams

**Best Suited For:**
- Teams generating lots of meeting content
- Remote/distributed teams
- Organizations needing searchable project knowledge
- Teams wanting AI-powered insights

**Platform Positioning:**
"AI-Powered Project Knowledge Platform" - Extract insights from project content, query your knowledge base, and generate intelligent summaries across your project portfolio.
