# TellMeMo - Technical Architecture Documentation

## Executive Summary

TellMeMo is a production SaaS platform for AI-powered project intelligence. This document describes the implemented technical architecture, system components, and operational capabilities.

**Document Status**: October 2025 - Reflects actual production implementation.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Core Components](#core-components)
5. [Data Flow](#data-flow)
6. [Database Schema](#database-schema)
7. [API Endpoints](#api-endpoints)
8. [Security](#security)
9. [Deployment](#deployment)

---

## System Overview

### What TellMeMo Does

TellMeMo helps teams extract insights from project content using AI:

- **Content Processing**: Upload transcripts, audio, documents, and emails
- **AI Analysis**: Semantic search and RAG-based question answering
- **Smart Summaries**: Generate summaries at project, program, and portfolio levels
- **Project Organization**: 3-tier hierarchy (Portfolio → Program → Project)
- **Collaboration**: Real-time notifications, activity tracking, support tickets

### Key Capabilities

**Content Intelligence:**
- Audio transcription (Whisper)
- Text chunking and embedding
- Semantic search across all content
- Multi-turn conversation support

**AI Features:**
- Natural language querying
- Source citation
- Multi-format summaries (general, executive, technical, stakeholder)
- Risk and task extraction
- Lessons learned tracking

**Project Management:**
- Organization workspaces with member management
- Portfolio/Program/Project hierarchy
- Team collaboration features
- Activity feed and notifications

---

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│                      Flutter Web Application                    │
│              (Riverpod State Management + GoRouter)            │
└─────────────────────────────────────────────────────────────────┘
                                │
                    HTTPS / WebSocket
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│                  FastAPI Python Backend                         │
│     REST API Endpoints + WebSocket Connections                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PROCESSING LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│  Redis Queue │ Transcription  │ Chunking │ Embedding │ RAG     │
│  (RQ Jobs)   │ Whisper/Salad/ │ Service  │ Service   │ Service │
│              │ Replicate      │          │           │         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      STORAGE LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  PostgreSQL │  Qdrant   │  Redis    │  Claude API │  Supabase  │
│  (Metadata) │  (Vectors)│  (Queue)  │  (LLM)      │  (Auth)    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  MONITORING & OBSERVABILITY                     │
├─────────────────────────────────────────────────────────────────┤
│  Sentry (Errors)  │  Langfuse (LLM)  │  Firebase Analytics     │
└─────────────────────────────────────────────────────────────────┘
```

### Multi-Tenant Architecture

- **Organization Isolation**: Each organization has dedicated data space
- **Row-Level Security (RLS)**: PostgreSQL policies enforce data separation
- **Vector Isolation**: Separate Qdrant collections per organization
- **Authentication**: Supabase handles user authentication and sessions

---

## Technology Stack

### Backend Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **API Framework** | FastAPI 0.104+ | Async REST API server |
| **Language** | Python 3.11+ | Backend programming |
| **Database** | PostgreSQL 15+ | Primary data storage |
| **Vector DB** | Qdrant 1.7+ | Semantic search |
| **ORM** | SQLAlchemy 2.0+ | Database operations |
| **Migrations** | Alembic | Database versioning |
| **Auth** | Supabase Auth | User authentication |
| **LLM** | Anthropic Claude | AI generation (Haiku/Sonnet/Opus) |
| **Embeddings** | EmbeddingGemma | Local embedding model |
| **Transcription** | OpenAI Whisper + Salad Cloud + Replicate | Audio to text (242x speedup with Replicate) |
| **Job Queue** | Redis Queue (RQ) | Background job processing with multi-priority queues |
| **Cache & Pub/Sub** | Redis | Job state management and real-time updates |
| **Monitoring** | Sentry + Langfuse | Error & LLM tracking |
| **Queue Dashboard** | RQ Dashboard | Job queue visualization and management |

### Frontend Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Framework** | Flutter 3.24+ | Web application |
| **Language** | Dart 3.5+ | Frontend programming |
| **State Management** | Riverpod 2.5+ | Application state |
| **Routing** | GoRouter 14+ | Navigation |
| **HTTP Client** | Dio 5.4+ | API communication |
| **UI Framework** | Material Design 3 | Design system |
| **Analytics** | Firebase Analytics | User tracking |
| **Monitoring** | Sentry Flutter | Error tracking |

### Infrastructure

- **Development**: Docker Compose (local PostgreSQL + Qdrant + Redis)
- **Production Backend**: Hetzner VPS
- **Database**: Managed PostgreSQL instance
- **Vector Database**: Qdrant Cloud
- **Job Queue**: Redis (in-memory or managed instance)
- **Queue Dashboard**: RQ Dashboard for job monitoring
- **Deployment**: Git-based with automated migrations

---

## Core Components

### 1. Authentication System

**Technology**: Supabase Auth + JWT

**Features:**
- Email/password authentication
- Email verification
- Password reset
- Session management
- JWT token validation
- Multi-organization support

**Flow:**
1. User signs up with email/password
2. Supabase creates account and sends verification
3. User verifies email
4. User signs in and receives JWT token
5. Token included in all API requests
6. Backend validates token and extracts user context

### 2. Organization Management

**Multi-Tenant Structure:**
- Users belong to one or more organizations
- Organizations have members with roles (owner, admin, member)
- All data scoped to organization

**Features:**
- Organization creation
- Member invitations (single or CSV bulk)
- Role management
- Organization settings

**Database Tables:**
- `users` - User accounts
- `organizations` - Organization master data
- `organization_members` - User-organization relationships
- `organization_invitations` - Pending invitations

### 3. Hierarchy Management

**3-Tier Structure:**
```
Portfolio (Strategic grouping)
  ├─ Program (Related projects)
  │   ├─ Project
  │   └─ Project
  └─ Program
      └─ Project

Standalone Projects (no parent)
```

**Features:**
- Create portfolios, programs, projects
- Move items between parents
- Cascade deletion handling
- Hierarchy navigation and statistics

**Database Tables:**
- `portfolios` - Portfolio data
- `programs` - Program data (with optional portfolio_id)
- `projects` - Project data (with optional program_id/portfolio_id)
- `project_members` - Project team members

### 4. Content Upload & Processing

**Supported Formats:**
- Text files (.txt, .md)
- Audio files (.wav, .mp3, .m4a, .webm)
- Documents (.pdf, .docx)
- Raw text input

**Processing Pipeline:**

**Step 1: Upload**
- File validation (type, size)
- Secure storage
- Upload job creation
- WebSocket progress updates

**Step 2: Transcription (Audio Only)**
- Local Whisper transcription (small files, slower)
- Salad Cloud transcription (large files, cost-effective)
- Replicate "incredibly-fast-whisper" (242x speedup, 30-min audio in ~20s)
- Text extraction and storage

**Step 3: Chunking**
- Content split into ~500-word chunks
- Context preservation with overlap
- Metadata attachment (speaker, timestamps)

**Step 4: Embedding**
- EmbeddingGemma generates 768-dim vectors
- Batch processing for efficiency
- Vector storage in Qdrant

**Step 5: Indexing**
- Vectors stored in organization-specific collection
- Metadata includes: project_id, content_id, chunk_index, organization_id
- Ready for semantic search

**Services:**
- **Job Management (Redis Queue)**:
  - `queue_config.py` - Multi-priority queue configuration (high, default, low)
  - `content_tasks.py` - Content processing jobs
  - `transcription_tasks.py` - Transcription jobs
  - `integration_tasks.py` - Integration sync jobs
  - `summary_tasks.py` - Summary generation jobs
- **Transcription Services**:
  - `whisper_service.py` - Local Whisper transcription
  - `salad_transcription_service.py` - Salad Cloud API
  - `replicate_transcription_service.py` - Replicate API (incredibly-fast-whisper)
- **Processing Services**:
  - `chunking_service.py` - Text chunking
  - `embedding_service.py` - Embedding generation
  - `multi_tenant_vector_store.py` - Qdrant operations
  - `redis_cache_service.py` - Redis caching and pub/sub

### 5. RAG-Based Querying

**Query Processing:**
1. User submits natural language question
2. Generate embedding for query (EmbeddingGemma)
3. Semantic search in Qdrant (organization + project filtered)
4. Retrieve top-K relevant chunks (default: 10)
5. Send chunks + query to Claude
6. Generate answer with source citations
7. Store query and response in database

**Conversation Threading:**
- Multi-turn dialogue support
- Context maintained across follow-ups
- Conversation history stored

**Models Supported:**
- Claude Haiku (fast, economical)
- Claude Sonnet 3.5 (balanced)
- Claude Opus (highest quality)

**Database Tables:**
- `queries` - Query history
- `conversations` - Conversation threads

**Services:**
- `rag_service.py` - RAG orchestration
- `multi_llm_client.py` - LLM provider abstraction
- `rag_prompts.py` - Prompt templates

### 6. Summary Generation

**Summary Types:**
- Meeting/Content summaries (single item)
- Project summaries (all project content)
- Program summaries (all program projects)
- Portfolio summaries (all portfolio content)

**Summary Formats:**
- General (balanced overview)
- Executive (high-level, strategic)
- Technical (detailed, implementation-focused)
- Stakeholder (external communication)

**Generation Process:**
1. Select entity (project/program/portfolio)
2. Query all relevant content
3. Optionally filter by date range
4. Select format and summary type
5. Claude generates structured summary
6. Store with metadata (tokens, cost, generation time)

**Summary Structure:**
- Subject line
- Body text
- Key points
- Decisions (if applicable)
- Action items (if applicable)
- Risks (if applicable)
- Lessons learned (if applicable)
- Communication insights
- Next meeting agenda suggestions

**Database Tables:**
- `summaries` - All summary types with flexible schema

**Services:**
- `summary_service_refactored.py` - Unified summary generation
- `portfolio_prompts.py` - Portfolio/program prompts
- `project_description_prompts.py` - Project description generation

### 7. Risks & Tasks Management

**Features:**
- Manual CRUD for risks and tasks
- AI-assisted extraction (basic)
- Assignment to team members
- Status tracking
- Blocker management

**Risk Fields:**
- Title, description, severity, status
- Assigned to, mitigation plan
- Organization and project scope

**Task Fields:**
- Title, description, status, priority
- Assigned to, due date
- Question to ask (context field)
- Linked blockers

**Database Tables:**
- `risks` - Risk tracking
- `tasks` - Task tracking
- `blockers` - Task blockers

### 8. Lessons Learned

**Purpose**: Capture and share project insights

**Features:**
- Document what went well/poorly
- Categorize by type
- Link to specific content
- Searchable across organization
- Included in summaries

**Database Tables:**
- `lessons_learned` - Knowledge repository

### 9. Activity Feed

**Tracked Activities:**
- Content uploads
- Summary generations
- Risk/task updates
- Member activities
- Project changes

**Database Tables:**
- `activities` - Activity log

### 10. Notification System

**Notification Types:**
- Organization invitations
- Content processing complete
- Summary generated
- Task assigned
- Risk escalation
- Support ticket updates

**Delivery:**
- In-app notification center
- Toast notifications
- Real-time WebSocket updates via Redis Pub/Sub

**Database Tables:**
- `notifications` - Notification records

**WebSocket Endpoints:**
- `/ws/notifications` - Real-time notification stream
- `/ws/jobs` - Upload job progress (powered by Redis Pub/Sub)
- `/ws/tickets` - Support ticket updates

**Real-Time Architecture:**
- Redis Pub/Sub channels for job status updates
- Multiple connection types: binary for RQ, JSON for pub/sub
- Supports horizontal scaling across multiple backend instances

### 11. Support Ticket System

**Features:**
- Create tickets with priority and category
- Status tracking (open, in_progress, resolved, closed)
- Admin responses
- Real-time updates

**Database Tables:**
- `support_tickets` - Ticket data
- `support_ticket_responses` - Responses

### 12. Background Job Queue System

**Technology**: Redis Queue (RQ)

**Features:**
- **Multi-Priority Queues**: high, default, low priority queues
- **Task Modules**:
  - `content_tasks.py` - Content upload and processing
  - `transcription_tasks.py` - Audio transcription jobs
  - `integration_tasks.py` - External integration syncs
  - `summary_tasks.py` - Summary generation
- **Job Management**:
  - Automatic retries on failure
  - Job state persistence in Redis
  - Real-time status tracking
  - Failed job monitoring
- **Dashboard**: RQ Dashboard for visual job monitoring
- **Scalability**:
  - Horizontal scaling with multiple workers
  - Shared state via Redis
  - No single point of failure

**Real-Time Updates:**
- Redis Pub/Sub for job status broadcasts
- WebSocket integration for client notifications
- Multiple connection types: binary (RQ) and JSON (pub/sub)

**Performance:**
- Non-blocking async job processing
- Priority-based execution
- Efficient resource utilization
- Supports background job retries

### 13. Fireflies Integration

**Capabilities:**
- Connect Fireflies.ai account with API key
- Sync past transcripts
- Import specific recordings
- Webhook endpoint for new recordings

**Status**: Basic implementation, production testing ongoing

**Database Tables:**
- `integrations` - Integration configurations (encrypted API keys)

---

## Data Flow

### Upload and Process Content

```
User uploads file
     │
     ▼
FastAPI validates and stores file
     │
     ▼
Redis Queue job enqueued (high/default/low priority)
     │
     ▼
Redis Pub/Sub notifies job created
     │
     ▼
[If Audio] → Transcription task (Whisper/Salad/Replicate) → Text
[If Text]  → Direct to chunking task
     │
     ▼
Chunking task (500-word chunks)
     │
     ▼
Embedding task (EmbeddingGemma)
     │
     ▼
Qdrant storage (organization collection)
     │
     ▼
PostgreSQL metadata updated
     │
     ▼
Redis Pub/Sub notifies completion → WebSocket updates client
     │
     ▼
User receives notification
```

### Query Processing (RAG)

```
User asks question
     │
     ▼
Generate query embedding
     │
     ▼
Semantic search in Qdrant (org + project filtered)
     │
     ▼
Retrieve top-K chunks
     │
     ▼
Send to Claude with prompt
     │
     ▼
Claude generates answer
     │
     ▼
Store query + response in PostgreSQL
     │
     ▼
Return to user with sources
```

### Summary Generation

```
User requests summary
     │
     ▼
Query relevant content from database/Qdrant
     │
     ▼
Apply date range filter (if specified)
     │
     ▼
Retrieve related data (risks, tasks, lessons)
     │
     ▼
Send to Claude with format-specific prompt
     │
     ▼
Claude generates summary
     │
     ▼
Store in summaries table
     │
     ▼
Track tokens and cost in Langfuse
     │
     ▼
Return to user
```

---

## Database Schema

### Core Tables

**users**
- id, email, created_at, updated_at
- Managed by Supabase

**organizations**
- id, name, description, created_at, updated_at

**organization_members**
- id, organization_id, user_id, role, joined_at

**organization_invitations**
- id, organization_id, email, name, role, status, token, expires_at

**portfolios**
- id, name, description, owner, organization_id, health_status, created_at, updated_at

**programs**
- id, name, description, portfolio_id (nullable), organization_id, created_at, updated_at

**projects**
- id, name, description, status, portfolio_id (nullable), program_id (nullable), organization_id, created_by, created_by_id, created_at, updated_at

**project_members**
- id, project_id, name, email, role

**content**
- id, project_id, title, file_path, content_type, status, metadata, organization_id, created_at

**queries**
- id, project_id, query_text, response_text, sources, token_count, llm_cost, organization_id, created_at

**conversations**
- id, project_id, title, organization_id, created_at

**summaries**
- id, entity_type, entity_id, content_id, summary_type, subject, body, key_points, decisions, action_items, risks, blockers, lessons_learned, sentiment_analysis, communication_insights, cross_meeting_insights, next_meeting_agenda, format, token_count, generation_time_ms, llm_cost, created_by, date_range_start, date_range_end, organization_id, project_id, program_id, portfolio_id, created_at

**risks**
- id, project_id, title, description, severity, status, assigned_to, assigned_to_email, mitigation_plan, organization_id, created_at, updated_at

**tasks**
- id, project_id, title, description, status, priority, assigned_to, assigned_to_email, due_date, question_to_ask, organization_id, created_at, updated_at

**blockers**
- id, task_id, description, status, organization_id, created_at, updated_at

**lessons_learned**
- id, project_id, title, description, category, impact, created_by, organization_id, created_at

**activities**
- id, organization_id, project_id, user_id, activity_type, description, metadata, created_at

**notifications**
- id, user_id, organization_id, title, message, type, is_read, link, created_at

**support_tickets**
- id, user_id, organization_id, title, description, status, priority, category, assigned_to, created_at, updated_at, resolved_at

**support_ticket_responses**
- id, ticket_id, user_id, message, created_at

**integrations**
- id, organization_id, integration_type, config (encrypted), status, created_at, updated_at

### Qdrant Schema

**Collection per Organization**: `org_{organization_id}`

**Point Structure**:
```json
{
  "id": "content_uuid_chunk_index",
  "vector": [768 dimensions],
  "payload": {
    "content_id": "uuid",
    "project_id": "uuid",
    "organization_id": "uuid",
    "chunk_index": 0,
    "content": "chunk text...",
    "metadata": {}
  }
}
```

---

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Register new user
- `POST /api/auth/signin` - Login
- `POST /api/auth/signout` - Logout
- `POST /api/auth/reset-password` - Password reset

### Organizations
- `POST /api/organizations` - Create organization
- `GET /api/organizations` - List user's organizations
- `GET /api/organizations/{org_id}` - Get details
- `PUT /api/organizations/{org_id}` - Update
- `DELETE /api/organizations/{org_id}` - Delete

### Invitations
- `POST /api/organizations/{org_id}/invitations` - Send invitation
- `POST /api/organizations/{org_id}/invitations/bulk` - Bulk CSV invite
- `GET /api/organizations/{org_id}/invitations` - List invitations
- `POST /api/invitations/{invitation_id}/accept` - Accept
- `POST /api/invitations/{invitation_id}/reject` - Reject
- `DELETE /api/invitations/{invitation_id}` - Cancel

### Hierarchy
- `POST /api/portfolios` - Create portfolio
- `GET /api/portfolios` - List portfolios
- `GET /api/portfolios/{portfolio_id}` - Get portfolio
- `PUT /api/portfolios/{portfolio_id}` - Update portfolio
- `DELETE /api/portfolios/{portfolio_id}` - Delete portfolio
- `POST /api/programs` - Create program
- `GET /api/programs` - List programs
- `GET /api/programs/{program_id}` - Get program
- `PUT /api/programs/{program_id}` - Update program
- `DELETE /api/programs/{program_id}` - Delete program
- `GET /api/hierarchy` - Get full hierarchy tree
- `PUT /api/hierarchy/move-project` - Move project
- `PUT /api/hierarchy/move-program` - Move program

### Projects
- `POST /api/projects` - Create project
- `GET /api/projects` - List projects
- `GET /api/projects/{project_id}` - Get project
- `PUT /api/projects/{project_id}` - Update project
- `DELETE /api/projects/{project_id}` - Delete project

### Content Upload
- `POST /api/upload/file` - Upload file
- `POST /api/upload/text` - Upload raw text
- `GET /api/projects/{project_id}/content` - List content
- `GET /api/projects/{project_id}/content/{content_id}` - Get content
- `DELETE /api/projects/{project_id}/content/{content_id}` - Delete content

### Queries (RAG)
- `POST /api/projects/{project_id}/queries` - Submit query
- `GET /api/projects/{project_id}/queries` - List queries
- `GET /api/projects/{project_id}/queries/{query_id}` - Get query
- `DELETE /api/projects/{project_id}/queries/{query_id}` - Delete query

### Conversations
- `POST /api/projects/{project_id}/conversations` - Create conversation
- `GET /api/projects/{project_id}/conversations` - List conversations
- `GET /api/conversations/{conversation_id}` - Get conversation

### Summaries
- `POST /api/summaries/generate` - Generate summary
- `GET /api/summaries` - List summaries (with filters)
- `GET /api/summaries/{summary_id}` - Get summary
- `POST /api/summaries/{summary_id}/regenerate` - Regenerate
- `DELETE /api/summaries/{summary_id}` - Delete summary

### Risks & Tasks
- `POST /api/projects/{project_id}/risks` - Create risk
- `GET /api/projects/{project_id}/risks` - List risks
- `PUT /api/projects/{project_id}/risks/{risk_id}` - Update risk
- `DELETE /api/projects/{project_id}/risks/{risk_id}` - Delete risk
- `POST /api/projects/{project_id}/tasks` - Create task
- `GET /api/projects/{project_id}/tasks` - List tasks
- `PUT /api/projects/{project_id}/tasks/{task_id}` - Update task
- `DELETE /api/projects/{project_id}/tasks/{task_id}` - Delete task

### Lessons Learned
- `POST /api/projects/{project_id}/lessons-learned` - Create lesson
- `GET /api/projects/{project_id}/lessons-learned` - List lessons
- `GET /api/lessons-learned` - Organization-wide lessons

### Activities
- `GET /api/activities` - List activities
- `GET /api/projects/{project_id}/activities` - Project activities

### Notifications
- `GET /api/notifications` - List notifications
- `PUT /api/notifications/{notification_id}/read` - Mark as read
- `PUT /api/notifications/mark-all-read` - Mark all as read
- `DELETE /api/notifications/{notification_id}` - Delete

### Support Tickets
- `POST /api/support-tickets` - Create ticket
- `GET /api/support-tickets` - List tickets
- `GET /api/support-tickets/{ticket_id}` - Get ticket
- `PUT /api/support-tickets/{ticket_id}` - Update ticket
- `POST /api/support-tickets/{ticket_id}/responses` - Add response

### Integrations
- `POST /api/integrations/fireflies/connect` - Connect Fireflies
- `GET /api/integrations/fireflies/transcripts` - List transcripts
- `POST /api/integrations/fireflies/sync/{transcript_id}` - Sync transcript
- `POST /api/integrations/fireflies/webhook` - Webhook receiver

### WebSocket Endpoints
- `WS /ws/jobs` - Upload job progress
- `WS /ws/notifications` - Real-time notifications
- `WS /ws/tickets` - Ticket updates

### Scheduler
- `POST /api/scheduler/schedule-summary` - Schedule automated summary
- `GET /api/scheduler/schedules` - List schedules
- `DELETE /api/scheduler/schedules/{schedule_id}` - Cancel schedule

### Job Queue Management
- **RQ Dashboard**: `http://localhost:9181` - Visual interface for monitoring jobs
- Jobs organized by priority: high, default, low
- Real-time job status tracking
- Failed job retry management
- Worker pool monitoring

### Health
- `GET /api/health` - Health check

---

## Security

### Authentication & Authorization

**Supabase Authentication:**
- Email/password authentication
- Email verification required
- JWT token-based sessions
- Secure password hashing

**Authorization:**
- Organization-scoped access (RLS policies)
- Role-based permissions (owner, admin, member)
- Project-level access control
- API key validation for integrations

### Data Security

**At Rest:**
- PostgreSQL encryption at rest
- Encrypted integration API keys
- Secure credential storage

**In Transit:**
- HTTPS/TLS for all API communication
- Secure WebSocket connections (WSS)

**Multi-Tenancy:**
- Row-Level Security (RLS) in PostgreSQL
- Organization-scoped Qdrant collections
- Strict data isolation between organizations

### Input Validation

- Pydantic models for request validation
- SQL injection prevention via SQLAlchemy
- File type and size validation
- Rate limiting per organization

---

## Deployment

### Development Environment

**Docker Compose Setup:**
- PostgreSQL container
- Qdrant container
- Backend service (hot reload)
- Frontend (Flutter web dev server)

**Local Configuration:**
- Environment variables via .env
- Database migrations via Alembic
- Seeding scripts for test data

### Production Environment

**Backend:**
- Hetzner VPS (dedicated server)
- Uvicorn ASGI server
- Python virtual environment
- Systemd service management

**Database:**
- Managed PostgreSQL instance
- Automated backups
- Connection pooling

**Vector Database:**
- Qdrant Cloud (managed service)
- Organization-scoped collections
- Automated backups

**Frontend:**
- Flutter web build
- Static hosting (configuration TBD)

**Deployment Process:**
1. Git push to repository
2. SSH to production server
3. Pull latest code
4. Run database migrations (Alembic)
5. Restart backend service
6. Deploy frontend build

**Monitoring:**
- Sentry for error tracking
- Langfuse for LLM monitoring
- Firebase Analytics for user tracking
- Custom logging infrastructure

---

## Performance Characteristics

### Response Times (Production)

- **Query Response**: 3-6 seconds (RAG queries)
- **Content Upload**: Real-time progress tracking
- **Summary Generation**: 5-15 seconds (varies by size)
- **API Latency**: <200ms (p95)
- **Semantic Search**: <100ms (Qdrant)

### Capacity

- **Current Deployment**: Single server (horizontally scalable)
- **Concurrent Users**: Tested to 50+ simultaneous
- **Content Processing**: Redis Queue with multi-worker support
- **Database**: PostgreSQL connection pooling
- **Job Queue**: Multi-priority queues (high, default, low)
- **Scalability**: Horizontal scaling enabled via Redis Queue
  - Multiple worker instances can process jobs concurrently
  - Shared job state via Redis
  - No single point of failure for background processing

### Cost Optimization

- **Embeddings**: Local model (no API costs)
- **Transcription**:
  - Replicate (242x speedup, ~20s for 30-min audio)
  - Salad Cloud (cost-effective for large batches)
  - Local Whisper (free but slower)
- **LLM**: Model selection (Haiku for routine, Sonnet/Opus for quality)
- **Monitoring**: Langfuse tracks per-operation costs
- **Job Queue**: Redis Queue (open-source, no licensing costs)

---

## Observability

### Error Tracking

**Sentry Integration:**
- Backend error tracking
- Frontend error tracking
- Stack traces and context
- User session replay
- Performance monitoring

### LLM Monitoring

**Langfuse Integration:**
- Request/response logging
- Token usage tracking
- Cost per operation
- Model performance metrics
- Trace analysis

### Application Logging

- Structured logging (JSON)
- Log levels (DEBUG, INFO, WARNING, ERROR)
- Correlation IDs for request tracking
- Background job logging

### Analytics

**Firebase Analytics:**
- User behavior tracking
- Feature usage statistics
- Conversion funnels
- User retention

---

## Technical Constraints

### Current Limitations

- **Single Server**: Not load-balanced (can be scaled)
- **Email Integration**: SMTP not configured (notifications in-app only)
- **Fireflies**: Basic integration (not fully production-tested)
- **Mobile**: Web-only (no native mobile apps)
- **Export**: Limited export capabilities

### Design Decisions

**Why EmbeddingGemma (Local):**
- No API costs for embeddings
- Fast inference on CPU
- Sufficient quality for semantic search
- Data privacy (no external API calls)

**Why Anthropic Claude:**
- Superior reasoning capabilities
- Large context window (200K tokens)
- Structured output support
- Reliable API performance

**Why Qdrant:**
- Fast semantic search
- Excellent filtering capabilities
- Multi-tenancy support
- Cloud-managed option available

**Why Flutter Web:**
- Single codebase for web (and future mobile)
- High performance
- Rich UI capabilities
- Strong typing (Dart)

**Why FastAPI:**
- Async/await native support
- Automatic API documentation
- Fast performance
- Python ML ecosystem

---

## Conclusion

TellMeMo is a production-ready SaaS platform with a robust technical architecture. The system successfully implements:

- **Multi-tenant SaaS** with organization isolation and RLS
- **AI-powered intelligence** using RAG and LLM generation
- **Scalable architecture** ready for horizontal scaling
- **Real-time features** via WebSocket connections
- **Comprehensive monitoring** with Sentry and Langfuse
- **Secure authentication** via Supabase
- **Flexible hierarchy** for project organization

The architecture balances cost efficiency (local embeddings), performance (Qdrant semantic search), and quality (Claude LLM) while maintaining security and scalability.
