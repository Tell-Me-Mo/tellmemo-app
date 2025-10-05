# Backend Testing Strategy

## Overview

This document outlines the testing strategy for the PM Master V2 FastAPI backend, including test structure, coverage targets, and feature checklist.

## Testing Philosophy

- **Integration-First**: Prioritize integration tests over unit tests (higher ROI)
- **User Flow Coverage**: Test complete workflows, not isolated functions
- **Mock External Services**: LLM APIs, vector DB for consistent tests
- **Realistic Test Data**: Use fixtures that mirror production scenarios
- **Coverage Target**: 60-70% (focus on routers/, services/, core logic)

## Test Structure

```
backend/
├── tests/
│   ├── conftest.py                 # Shared fixtures and test config
│   ├── fixtures/
│   │   ├── test_data.py           # Sample meetings, transcripts, emails
│   │   ├── mock_responses.py      # Mocked LLM/API responses
│   │   └── database.py            # Test DB setup/teardown
│   ├── unit/
│   │   ├── test_models.py         # Database model tests
│   │   ├── test_schemas.py        # Pydantic schema validation
│   │   ├── test_utils.py          # Utility functions
│   │   └── test_parsers.py        # Email/file parsing logic
│   ├── integration/
│   │   ├── test_api_projects.py   # Project CRUD endpoints
│   │   ├── test_api_meetings.py   # Meeting upload & processing
│   │   ├── test_api_summaries.py  # Summary generation
│   │   ├── test_api_search.py     # RAG search & retrieval
│   │   ├── test_api_reports.py    # Weekly report generation
│   │   └── test_rag_pipeline.py   # End-to-end RAG flow
│   ├── e2e/
│   │   ├── test_user_journey_1.py # Complete flow: upload → summary → insights
│   │   ├── test_user_journey_2.py # Weekly report generation flow
│   │   └── test_user_journey_3.py # Search & retrieval flow
│   └── performance/
│       ├── test_rag_latency.py    # RAG response time benchmarks
│       └── test_db_queries.py     # Database query performance
├── pytest.ini                      # Pytest configuration
└── requirements-dev.txt            # Testing dependencies
```

## Required Dependencies

```txt
# requirements-dev.txt
pytest>=8.0.0
pytest-asyncio>=0.23.0
pytest-cov>=4.1.0
pytest-mock>=3.12.0
httpx>=0.26.0
faker>=22.0.0
factory-boy>=3.3.0
freezegun>=1.4.0
```

## Testing Tools & Utilities

### 1. Fixtures (conftest.py)
```python
# Shared test fixtures
- test_db: PostgreSQL test database
- test_vector_db: In-memory Qdrant instance
- mock_llm_client: Mocked Claude API responses
- test_client: FastAPI TestClient
- sample_user: Test user fixture
- sample_project: Test project data
- sample_meeting: Test meeting transcript
```

### 2. Mock Services
```python
# Mock external dependencies
- MockClaudeAPI: Consistent LLM responses
- MockQdrant: Vector search without real DB
- MockEmailParser: Deterministic email parsing
- MockFileStorage: In-memory file handling
```

### 3. Test Data Factories
```python
# Factory pattern for test data
- ProjectFactory
- MeetingFactory
- EmailFactory
- SummaryFactory
```

## Feature Coverage Checklist

> **Note**: This checklist reflects the ACTUAL features implemented in the codebase (as of 2024-10-05).

### 1. Authentication & Authorization

#### 1.1 Native Authentication (native_auth.py)
- [x] User signup/registration
- [x] User login
- [x] User logout
- [x] Token refresh
- [x] Password reset
- [x] Password change
- [x] Profile update
- [x] Token verification
- [x] OTP verification

#### 1.2 OAuth Authentication (auth.py)
- [x] OAuth signup
- [x] OAuth signin
- [x] OAuth token refresh
- [x] Session management

#### 1.3 Authorization
- [x] Role-based access control (RBAC)
- [x] Organization-level permissions
- [x] Project-level permissions
- [x] Multi-tenant data isolation (RLS)

### 2. Organizations & Multi-Tenancy

#### 2.1 Organization Management (organizations.py)
- [x] Create organization
- [x] List organizations
- [x] Get organization by ID
- [~] Update organization (tests written, 500 errors - needs investigation)
- [x] Delete organization
- [x] Switch active organization
- [x] List organization members
- [ ] Add members to organization (blocked: int vs UUID type mismatch in router)
- [ ] Update member roles (blocked: int vs UUID type mismatch in router)
- [ ] Remove members from organization (blocked: int vs UUID type mismatch in router)

#### 2.2 Invitations (invitations.py)
- [x] Send organization invitations (via organizations.py) - 7 tests passing
- [x] Delete/revoke invitations - 5 tests passing
- [~] Accept invitations - 1 test passing, 5 tests have auth issues with client_factory (needs further debugging)

### 3. Project Management

#### 3.1 Project CRUD (projects.py)
- [x] Create project
- [x] List projects
- [x] Get project by ID
- [x] Update project
- [x] Archive project
- [x] Restore archived project
- [x] Delete project

#### 3.2 Project Members
- [x] Add member to project
- [x] Remove member from project
- [x] List project members (via get project)

#### 3.3 Project Assignment
- [ ] Assign project to program
- [ ] Assign project to portfolio
- [ ] Move project between programs

### 4. Hierarchy Management

#### 4.1 Portfolio Management (portfolios.py)
- [ ] Create portfolio
- [ ] List portfolios
- [ ] Get portfolio by ID
- [ ] Update portfolio
- [ ] Delete portfolio
- [ ] Get portfolio programs
- [ ] Get portfolio projects
- [ ] Portfolio statistics
- [ ] Query portfolio (RAG)
- [ ] Deletion impact analysis

#### 4.2 Program Management (programs.py)
- [ ] Create program
- [ ] List programs
- [ ] Get program by ID
- [ ] Update program
- [ ] Delete program
- [ ] Get program projects
- [ ] Assign program to portfolio
- [ ] Remove program from portfolio
- [ ] Program statistics
- [ ] Deletion impact analysis

#### 4.3 Hierarchy Operations (hierarchy.py)
- [ ] Get full hierarchy tree
- [ ] Move items in hierarchy
- [ ] Bulk move items
- [ ] Bulk delete items
- [ ] Get hierarchy path (breadcrumbs)
- [ ] Search hierarchy
- [ ] Hierarchy statistics summary

### 5. Content Management

#### 5.1 Content Upload (content.py, upload.py)
- [ ] Upload file content
- [ ] Upload text content
- [ ] Upload with AI-based project matching
- [ ] Validate file types
- [ ] File size validation
- [ ] Store content metadata

#### 5.2 Content Retrieval
- [ ] List content for project
- [ ] Get content by ID
- [ ] Filter content by type
- [ ] Filter content by date

#### 5.3 Content Availability (content_availability.py)
- [ ] Check content availability for entity
- [ ] Get summary statistics
- [ ] Batch content availability check

### 6. RAG & Query System

#### 6.1 Query Endpoints (queries.py)
- [ ] Query organization-wide
- [ ] Query specific project
- [ ] Query program
- [ ] Query portfolio
- [ ] Multi-tenant vector search

#### 6.2 RAG Pipeline
- [ ] Generate embeddings
- [ ] Store vectors in Qdrant
- [ ] Semantic search
- [ ] Retrieve top-k results
- [ ] Filter by date range
- [ ] Filter by project/program/portfolio
- [ ] Multi-tenant vector isolation

### 7. Summary Generation

#### 7.1 Unified Summaries (unified_summaries.py)
- [ ] Create project summary
- [ ] Create program summary
- [ ] Create portfolio summary
- [ ] Get summary by ID
- [ ] List summaries (with filters)
- [ ] Update summary
- [ ] Delete summary
- [ ] WebSocket streaming for summaries

#### 7.2 Hierarchy Summaries (hierarchy_summaries.py)
- [ ] Generate portfolio summaries
- [ ] Generate program summaries
- [ ] Include risks, blockers, lessons learned
- [ ] Include action items and decisions

### 8. Risks, Tasks & Blockers

#### 8.1 Risks Management (risks_tasks.py)
- [ ] Create risk
- [ ] List risks for project
- [ ] Update risk
- [ ] Delete risk
- [ ] Bulk update risks
- [ ] Assign risk to user
- [ ] Track risk mitigation

#### 8.2 Tasks Management (risks_tasks.py)
- [ ] Create task
- [ ] List tasks for project
- [ ] Update task
- [ ] Delete task
- [ ] Bulk update tasks
- [ ] Task assignment
- [ ] Task status tracking

#### 8.3 Blockers Management (risks_tasks.py)
- [ ] Create blocker
- [ ] List blockers for project
- [ ] Update blocker
- [ ] Delete blocker
- [ ] Blocker resolution tracking

### 9. Lessons Learned

#### 9.1 Lessons Learned CRUD (lessons_learned.py)
- [ ] Create lesson learned
- [ ] List lessons for project
- [ ] Update lesson learned
- [ ] Delete lesson learned
- [ ] Batch create lessons

### 10. Background Jobs & Scheduling

#### 10.1 Job Management (jobs.py)
- [ ] List active jobs
- [ ] Get job statistics
- [ ] Get job by ID
- [ ] Cancel job
- [ ] Stream job progress (SSE)
- [ ] List jobs for project
- [ ] WebSocket job updates (websocket_jobs.py)

#### 10.2 Scheduler (scheduler.py)
- [ ] Get scheduler status
- [ ] Trigger project reports
- [ ] Reschedule jobs
- [ ] Auto-generate summaries on schedule

### 11. Integrations

#### 11.1 Integration Management (integrations.py)
- [ ] List available integrations
- [ ] Connect integration
- [ ] Disconnect integration
- [ ] Test integration connection
- [ ] Sync integration data
- [ ] Fireflies webhook handler
- [ ] Get integration activity

#### 11.2 Transcription Services (transcription.py)
- [ ] Fireflies transcription
- [ ] Salad transcription
- [ ] Audio buffer management
- [ ] WebSocket audio streaming (websocket_audio.py)

### 12. Notifications & Activities

#### 12.1 Notifications (notifications.py)
- [ ] Create notification
- [ ] List notifications
- [ ] Get unread count
- [ ] Mark notification as read
- [ ] Bulk mark as read
- [ ] Archive notification
- [ ] Delete notification
- [ ] Bulk create notifications
- [ ] WebSocket notifications (websocket_notifications.py)

#### 12.2 Activity Feed (activities.py)
- [ ] Get activity feed
- [ ] Filter by entity type
- [ ] Activity timeline
- [ ] User activity tracking

### 13. Support Tickets

#### 13.1 Ticket Management (support_tickets.py)
- [ ] Create support ticket
- [ ] List tickets
- [ ] Get ticket by ID
- [ ] Update ticket status
- [ ] Delete ticket
- [ ] Add comment to ticket
- [ ] List ticket comments
- [ ] Upload ticket attachment
- [ ] Download ticket attachment
- [ ] WebSocket ticket updates (websocket_tickets.py)

### 14. Conversations

#### 14.1 Conversation Management (conversations.py)
- [ ] Create conversation
- [ ] List conversations for project
- [ ] Get conversation by ID
- [ ] Update conversation
- [ ] Delete conversation
- [ ] Multi-turn chat history

### 15. System & Admin

#### 15.1 Health & Monitoring (health.py)
- [ ] Health check endpoint
- [ ] Database health
- [ ] Vector DB health
- [ ] LLM service health

### 16. Cross-Cutting Concerns

#### 16.1 Error Handling
- [ ] 4xx client error responses
- [ ] 5xx server error responses
- [ ] Validation error formatting
- [ ] LLM API error handling
- [ ] Database error handling
- [ ] Vector DB error handling

#### 16.2 Observability (Langfuse)
- [ ] LLM request logging
- [ ] Token usage tracking
- [ ] Latency monitoring
- [ ] Cost tracking
- [ ] Trace storage

#### 16.3 Security
- [ ] Input sanitization
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CORS configuration
- [ ] Rate limiting
- [ ] JWT token validation
- [ ] Multi-tenant data isolation (RLS)

#### 16.4 Data Validation
- [ ] Pydantic schema validation
- [ ] Type checking
- [ ] Business logic validation
- [ ] File type validation
- [ ] File size limits

---

**Test Coverage Status:**
- ✅ **Fully Tested**: Native Authentication (9/9 features, 32 tests)
- ✅ **Fully Tested**: OAuth Authentication (4/4 features, 25+ tests)
- ✅ **Fully Tested**: Authorization (4/4 features, 20 tests)
- ✅ **Partially Tested**: Organization Management (7/10 features, 20 tests passing, 3 blocked by backend bug)
- ✅ **Mostly Tested**: Invitations (3/4 features, 16/22 tests passing, 1 feature not implemented, 6 tests need fixture refactoring)
- ✅ **Fully Tested**: Project CRUD (7/7 features, 34 tests passing)
- ✅ **Fully Tested**: Project Members (3/3 features, included in 34 project tests)
- ❌ **Not Tested**: All other features

**Total Features**: ~200+ individual test items
**Currently Tested**: 20% (40/200 features)
**Target**: 60-70% coverage
**Current Coverage**: TBD (run `pytest --cov` to check)

## Backend Code Issues Found During Testing

| Priority | Issue | File:Lines | Fix Required | Status |
|----------|-------|------------|--------------|--------|
| 🔴 Critical | Member endpoints use `int` instead of `UUID` | `organizations.py:948-949,1025-1026` | Change `organization_id: int` → `UUID`, `user_id: int` → `UUID` in `update_member_role` and `remove_member` | ✅ FIXED |
| 🔴 Critical | Organization update uses timezone-aware datetime | `organizations.py:480` | Change `datetime.now(timezone.utc)` → `datetime.utcnow()` to match model | ✅ FIXED |
| 🔴 Critical | Invitation endpoints use `int` instead of `UUID` | `organizations.py:758,884` | Change `organization_id: int` → `UUID` in `invite_member` and `list_pending_invitations` | ✅ FIXED |
| 🔴 Critical | InvitationResponse schema uses `int` instead of `UUID` | `organizations.py:117-123` | Change `id`, `organization_id`, `invited_by` from `int` → `UUID` | ✅ FIXED |
| 🔴 Critical | `OrganizationMember.joined_at` not nullable | `organization_member.py:53` | Change `nullable=False` → `nullable=True` and remove `default=datetime.utcnow` | ✅ FIXED |
| 🔴 Critical | Pending invitations have `joined_at` set | `organizations.py:838` | Explicitly set `joined_at=None` for pending invitations | ✅ FIXED |
| 🟡 Minor | Slug generation differs from test expectation | `organizations.py:143-169` | Update test (current behavior is better) | ❌ Not Fixed |
| 🟡 Minor | Returns 403 instead of 401 for unauth | Multiple endpoints | Update tests to accept 403 | ❌ Not Fixed |
| 🔵 Info | Test infrastructure limitation | `conftest.py` | Shared client fixture prevents multi-user testing in same test - needs refactoring | Known Limitation |
| 🔴 Critical | Projects router missing API prefix | `projects.py:16-19` | Add `prefix="/api/v1/projects"` to APIRouter definition | ✅ FIXED |
| 🔴 Critical | Main.py has duplicate prefix for projects | `main.py:251` | Remove `prefix="/api/projects"` from include_router | ✅ FIXED |
| 🔴 Critical | `archive_project` missing organization_id param | `project_service.py:273` | Add `organization_id: UUID` parameter and validate in WHERE clause | ✅ FIXED |
| 🔴 Critical | `restore_project` missing organization_id param | `project_service.py:308` | Add `organization_id: UUID` parameter and validate project belongs to org | ✅ FIXED |
| 🔴 Critical | `add_member` missing organization_id param | `project_service.py:407` | Add `organization_id: UUID` parameter to validate project ownership | ✅ FIXED |
| 🔴 Critical | `remove_member` missing organization_id param | `project_service.py:450` | Add `organization_id: UUID` and rename `email` to `member_email` for consistency | ✅ FIXED |
| 🔴 Critical | `remove_member` uses wrong variable name | `project_service.py:471,474` | Change `email` to `member_email` in logging statements | ✅ FIXED |

**Impact Before Fixes**: 60+ tests blocked by critical bugs (30+ organization bugs, 30+ project bugs)
**Impact After Fixes**: All critical backend bugs FIXED! All 34 project tests passing, 16/22 invitation tests passing (6 have test infrastructure issues, not backend bugs)

---

## Test Execution

### Run All Tests
```bash
pytest
```

### Run with Coverage
```bash
pytest --cov=. --cov-report=term-missing --cov-report=html
```

### Run Specific Test Types
```bash
# Unit tests only
pytest tests/unit/

# Integration tests only
pytest tests/integration/

# E2E tests only
pytest tests/e2e/

# Specific test file
pytest tests/integration/test_api_meetings.py

# Specific test function
pytest tests/integration/test_api_meetings.py::test_upload_meeting_success
```

### Run with Markers
```bash
# Fast tests only (skip slow integration tests)
pytest -m "not slow"

# Critical path tests only
pytest -m critical
```

## CI/CD Integration

### GitHub Actions Workflow
```yaml
# .github/workflows/backend-tests.yml
name: Backend Tests

on:
  pull_request:
    paths:
      - 'backend/**'
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: testdb
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Run tests
        env:
          DATABASE_URL: postgresql://postgres:testpass@localhost:5432/testdb
        run: |
          pytest --cov=. --cov-report=xml --cov-report=term-missing

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
          fail_ci_if_error: true
```

## Coverage Goals

### Minimum Coverage Thresholds
- **Overall**: 60%
- **Critical Paths** (routers/, services/): 80%
- **Models** (database.py, models.py): 70%
- **Utils** (utils/): 50%

### Coverage Report
```bash
# Generate HTML coverage report
pytest --cov=. --cov-report=html

# Open in browser
open htmlcov/index.html
```

## Best Practices

### ✅ Do:
1. **Mock External APIs**: Never hit real Claude API or external services in tests
2. **Use Fixtures**: Reuse test data across multiple tests
3. **Test Happy Path First**: Then edge cases and error scenarios
4. **Isolate Tests**: Each test should be independent
5. **Descriptive Names**: `test_upload_meeting_with_invalid_format_returns_422`
6. **Arrange-Act-Assert**: Clear test structure
7. **Test Error Cases**: Don't just test success scenarios

### ❌ Don't:
1. **Test Implementation Details**: Test behavior, not internals
2. **Skip Test Cleanup**: Always clean up database/resources
3. **Hard-code Test Data**: Use factories and fixtures
4. **Test Framework Code**: Don't test FastAPI internals
5. **Ignore Flaky Tests**: Fix or remove unstable tests
6. **Commit Commented Tests**: Delete or fix broken tests

## Example Test Cases

### Integration Test Example
```python
# tests/integration/test_api_meetings.py
import pytest
from fastapi.testclient import TestClient

@pytest.mark.asyncio
async def test_upload_meeting_and_generate_summary(
    test_client: TestClient,
    sample_project,
    sample_meeting_transcript,
    mock_llm_client
):
    # Arrange
    upload_data = {
        "project_id": sample_project.id,
        "transcript": sample_meeting_transcript,
        "date": "2024-01-15",
        "participants": ["Alice", "Bob"]
    }

    # Act
    response = test_client.post("/api/v1/meetings", json=upload_data)

    # Assert
    assert response.status_code == 201
    meeting_id = response.json()["id"]

    # Verify summary was generated
    summary_response = test_client.get(f"/api/v1/meetings/{meeting_id}/summary")
    assert summary_response.status_code == 200
    assert "action_items" in summary_response.json()
```

### E2E Test Example
```python
# tests/e2e/test_user_journey_1.py
@pytest.mark.asyncio
async def test_complete_meeting_intelligence_flow(test_client, mock_services):
    """Test: Upload meeting → Generate summary → Search insights → Generate report"""

    # Step 1: Create project
    project = test_client.post("/api/v1/projects", json={"name": "Q1 Planning"})
    project_id = project.json()["id"]

    # Step 2: Upload meeting
    meeting = test_client.post("/api/v1/meetings", json={
        "project_id": project_id,
        "transcript": "Meeting about Q1 goals...",
        "date": "2024-01-15"
    })
    assert meeting.status_code == 201

    # Step 3: Get summary
    summary = test_client.get(f"/api/v1/meetings/{meeting.json()['id']}/summary")
    assert summary.status_code == 200
    assert len(summary.json()["action_items"]) > 0

    # Step 4: Search insights
    search = test_client.post("/api/v1/search", json={
        "query": "What are the Q1 goals?",
        "project_id": project_id
    })
    assert search.status_code == 200
    assert len(search.json()["results"]) > 0

    # Step 5: Generate weekly report
    report = test_client.post("/api/v1/reports/weekly", json={
        "project_id": project_id,
        "week_start": "2024-01-15"
    })
    assert report.status_code == 200
    assert "summary" in report.json()
```

---

**Last Updated**: 2024-01-15
**Coverage Target**: 60-70%
**Current Coverage**: TBD (run `pytest --cov` to check)
