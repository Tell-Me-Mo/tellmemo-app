# Backend Tests

This directory contains the test suite for the PM Master V2 backend, following the integration-first testing strategy outlined in [TESTING_BACKEND.md](../../TESTING_BACKEND.md).

## Test Structure

```
tests/
├── conftest.py              # Shared fixtures and test configuration
├── integration/             # Integration tests for API endpoints
│   └── test_native_auth.py # Native authentication tests (32 tests)
└── README.md               # This file
```

## Quick Start

### Prerequisites

1. **PostgreSQL Database**: Ensure PostgreSQL is running with the test database created:
   ```bash
   # Database credentials (from docker-compose.yml):
   POSTGRES_USER=pm_master
   POSTGRES_PASSWORD=pm_master_pass
   POSTGRES_DB=pm_master_db (production)

   # Create test database:
   PGPASSWORD=pm_master_pass psql -h localhost -U pm_master -d postgres -c "CREATE DATABASE pm_master_test;"
   ```

2. **Environment Variables**: The test suite uses these settings:
   ```bash
   TESTING=1
   TEST_DATABASE_URL=postgresql+asyncpg://pm_master:pm_master_pass@localhost:5432/pm_master_test
   ```

### Running Tests

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/integration/test_native_auth.py

# Run with verbose output
pytest -v

# Run with coverage
pytest --cov=routers --cov=services --cov-report=term-missing --cov-report=html

# Run only integration tests
pytest -m integration

# Run and skip slow tests
pytest -m "not slow"
```

## Current Test Coverage

### Native Authentication (✅ Complete)
- **File**: `tests/integration/test_native_auth.py`
- **Tests**: 32 passing
- **Coverage**: 65% overall
  - `routers/native_auth.py`: 72%
  - `services/auth/native_auth_service.py`: 58%
- **Features Tested**:
  - User signup/registration (5 tests)
  - User login (5 tests)
  - User logout (1 test)
  - Token refresh (5 tests)
  - Password reset (2 tests)
  - Password change (3 tests)
  - Profile update (3 tests)
  - Token verification (4 tests)
  - OTP verification (1 test)
  - Edge cases (3 tests)

## Test Fixtures

The `conftest.py` file provides shared fixtures:

### Database Fixtures
- `db_session`: Fresh database session for each test
- `client`: Async HTTP client for API testing
- `authenticated_client`: HTTP client with valid JWT token

### User Fixtures
- `test_user`: Standard test user with credentials
- `test_user_token`: Valid access token for test user
- `test_user_refresh_token`: Valid refresh token
- `inactive_user`: Inactive user for testing access control
- `test_organization`: Test organization with test user as admin

### Data Fixtures
- `sample_signup_data`: User registration data
- `sample_login_data`: User login credentials
- `invalid_login_data`: Invalid credentials for testing failures
- `sample_profile_update`: Profile update data

## Writing New Tests

Follow the integration-first approach:

```python
import pytest
from httpx import AsyncClient

@pytest.mark.integration
async def test_feature_success(
    client: AsyncClient,
    test_user: User
):
    """Test successful feature execution."""
    # Arrange
    request_data = {"key": "value"}

    # Act
    response = await client.post("/api/v1/endpoint", json=request_data)

    # Assert
    assert response.status_code == 200
    data = response.json()
    assert "expected_field" in data
```

## Test Markers

- `@pytest.mark.integration`: Integration tests (API endpoints)
- `@pytest.mark.slow`: Slow-running tests
- `@pytest.mark.e2e`: End-to-end tests

## Coverage Goals

Following TESTING_BACKEND.md strategy:
- **Overall**: 60-70%
- **Critical Paths** (routers/, services/): 80%
- **Models**: 70%
- **Utils**: 50%

## Next Steps

See [TESTING_BACKEND.md](../../TESTING_BACKEND.md) feature checklist for remaining test coverage:
- OAuth Authentication
- Organizations & Multi-Tenancy
- Project Management
- Content Management
- RAG & Query System
- And more...

## Troubleshooting

### Database Connection Errors
```bash
# Ensure PostgreSQL is running
docker-compose up postgres -d

# Recreate test database
PGPASSWORD=pm_master_pass psql -h localhost -U pm_master -d postgres -c "DROP DATABASE IF EXISTS pm_master_test;"
PGPASSWORD=pm_master_pass psql -h localhost -U pm_master -d postgres -c "CREATE DATABASE pm_master_test;"
```

### Import Errors
```bash
# Ensure you're in the backend directory
cd backend
pytest
```

### Coverage Reports
HTML coverage reports are generated in `htmlcov/index.html`:
```bash
pytest --cov=. --cov-report=html
open htmlcov/index.html
```
