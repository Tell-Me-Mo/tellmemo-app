# Security Audit Report -- Post-Vibecoding Review

**Date**: 2026-02-23
**Scope**: Full codebase security audit of TellMeMo (PM Master V2)
**Auditor**: Automated security analysis via Claude
**Codebase**: FastAPI backend + Flutter frontend + Docker infrastructure

---

## Executive Summary

This audit identified **97 security findings** across the entire codebase, including **11 CRITICAL**, **30 HIGH**, **35 MEDIUM**, and **21 LOW** severity issues. The most dangerous findings are:

1. **Global SSL/TLS verification disabled process-wide** via monkey-patching in two files, affecting ALL outbound HTTPS connections including authentication
2. **Complete authentication bypass on the WebSocket `/ws/jobs` endpoint** -- any anonymous user can monitor and cancel jobs
3. **SQL injection via string interpolation** in the Row-Level Security context middleware
4. **Fail-open authentication middleware** that silently allows unauthenticated requests through on any error
5. **Empty JWT secret default** that makes tokens trivially forgeable

The codebase shows clear signs of rapid "vibecoding" development: SSL was disabled globally to work around certificate issues, authentication was made optional rather than required, and error handling defaults to allowing access rather than denying it.

---

## Findings by Severity

### CRITICAL (11 findings)

| # | Area | File | Lines | Issue |
|---|------|------|-------|-------|
| C1 | Services | `services/llm/langdetect_service.py` | 12-49 | **Global SSL bypass**: Sets `PYTHONHTTPSVERIFY=0`, replaces `ssl._create_default_https_context`, monkey-patches all `requests.Session` instances process-wide. Every HTTPS connection in the entire application is unverified. |
| C2 | Services | `services/rag/embedding_service.py` | 12-41 | **Global SSL bypass**: Identical process-wide SSL disable. Both files must be fixed. |
| C3 | Services | `services/auth/auth_service.py` | 47, 63 | **SSL disabled on Supabase auth calls**: `httpx.Client(verify=False)` on both primary and admin (service-role) Supabase clients. Service role key transmitted without TLS verification. |
| C4 | Middleware | `middleware/rls_context.py` | 44, 46, 68, 70, 101, 103 | **SQL injection via f-string interpolation**: `await connection.execute(f"SET LOCAL app.user_id = '{user_id}'")`. User/org IDs interpolated directly into SQL. |
| C5 | Middleware | `middleware/auth_middleware.py` | 143-145 | **Expired token bypass**: JWT decoded with `verify_exp: False` for cache lookup. Expired tokens authenticate via Redis cache hit. |
| C6 | Config | `config.py` | 102 | **Empty JWT secret default**: `jwt_secret: str = Field(default="")`. Application starts with empty signing key, making all JWTs forgeable. |
| C7 | WebSocket | `routers/websocket_jobs.py` | 371-396 | **Complete auth bypass**: `/ws/jobs` endpoint has zero authentication. Any anonymous client can subscribe to any job, any project, query any job status, and cancel any job. |
| C8 | WebSocket | `routers/websocket_jobs.py` | 96-107, 320-328 | **Cross-tenant data leakage**: No authorization checks on job/project subscriptions. Any client receives updates for any organization's jobs. |
| C9 | Docker | `docker-compose.prod.yml` | 9, 71, 78, 99, 125, 128, 139 | **Default passwords in production compose**: `pm_master_pass`, `redispassword123` as fallback defaults in production configuration. |
| C10 | Docker | `docker-compose.prod.yml` | 527-529 | **Elasticsearch security disabled in production**: `xpack.security.enabled=false`, no auth, no TLS. |
| C11 | Docker | `clickhouse/config.xml` + `users.xml` | config:59, users:5, users:14 | **Hardcoded weak passwords**: `clickhousepass123`, `langfuse_clickhouse_pw`, and empty password for default user -- all in version control. |

---

### HIGH (30 findings)

| # | Area | File | Lines | Issue |
|---|------|------|-------|-------|
| H1 | Config | `config.py` | 18 | Hardcoded default DB password `pm_master_pass` |
| H2 | Config | `config.py` | 119 | Hardcoded default API key `development_api_key_change_in_production` |
| H3 | Config | `config.py` | 99 | Empty default for `supabase_jwt_secret` |
| H4 | Main | `main.py` | 46 | Sentry `send_default_pii=True` sends JWT tokens and PII to third party |
| H5 | Main | `main.py` | 254-256 | **No rate limiting anywhere** -- entirely removed from application |
| H6 | Middleware | `middleware/auth_middleware.py` | 82-87 | **Fail-open auth**: Missing token → request proceeds unauthenticated |
| H7 | Middleware | `middleware/auth_middleware.py` | 240-242 | **Fail-open on error**: Any auth exception → request proceeds unauthenticated |
| H8 | Docker | `docker-compose.yml` | 13, 41-42, 64 | DB ports (Postgres, Qdrant, Redis) exposed on `0.0.0.0` |
| H9 | Docker | `docker-compose.prod.yml` | 602, 606 | Kibana exposed on `0.0.0.0:5601` without authentication |
| H10 | Docker | `docker-compose.prod.yml` + `.yml` | 90-108, 76-88 | RQ Dashboard exposed without authentication (both dev and prod) |
| H11 | Docker | `clickhouse/config.xml` | 15, 60-65 | ClickHouse listens on all interfaces with unrestricted network access and admin default user |
| H12 | Router | `routers/auth.py` + `native_auth.py` | Various | No password complexity validation on signup/reset |
| H13 | Router | `routers/auth.py` + `native_auth.py` | Various | No rate limiting on login/signup/password-reset endpoints |
| H14 | Router | `routers/native_auth.py` | 358-396 | Password change does not require current password (account takeover with stolen token) |
| H15 | Router | `routers/admin.py` | 25-43 | Admin reset endpoint: only API key auth (no user auth), default key `development_reset_key` |
| H16 | Router | `routers/transcription.py` | 84-88 | No file extension validation on audio upload -- any file type accepted |
| H17 | Router | `routers/queries.py` | 172, 316, 472, 652 | Exception details leaked to clients via `detail=str(e)` |
| H18 | Router | `routers/support_tickets.py` | 616-762 | No file size limit on attachment upload (reads entire file into memory) |
| H19 | Router | `routers/support_tickets.py` | 333-440 | Ticket update has no authorization check (any org member can update any ticket) |
| H20 | Router | `routers/organizations.py` | 892-963 | Invitation tokens exposed in API list responses |
| H21 | Router | `routers/organizations.py` | 786-911 | Members can invite with admin role (privilege escalation) |
| H22 | WebSocket | `websocket_live_insights.py` | 927-963, 1126-1159 | Missing session authorization -- any authenticated user can join any org's live meeting |
| H23 | WebSocket | `websocket_live_insights.py` | 1173-1185, 672-758 | Cross-tenant historical data leak via SYNC_STATE (no org filter) |
| H24 | WebSocket | `websocket_jobs.py` | 216-231 | Full RQ metadata exposed including internal paths and error traces |
| H25 | WebSocket | `websocket_jobs.py` | 26-48 | Unbounded connections/subscriptions enabling DoS |
| H26 | Services | `services/auth/native_auth_service.py` | 31 | JWT secret falls back to random value on each restart |
| H27 | Services | `services/auth/native_auth_service.py` | 117-152 | No token type validation (refresh token usable as access token) |
| H28 | Services | `services/llm/multi_llm_client.py` | 152, 270, 474 | SSL disabled in dev mode for Claude/OpenAI/DeepSeek API calls |
| H29 | Services | `services/rag/` (4 files) | Various | `trust_remote_code=True` in 5 SentenceTransformer loading sites (remote code execution risk) |
| H30 | Services | `services/rag/enhanced_rag_service_refactored.py` + `conversation_context_service.py` | 672-687, 89-102 | Prompt injection: user input directly interpolated into LLM prompts without sanitization |
| H31 | Frontend | `lib/core/storage/secure_storage_mobile.dart` | 9-11 | Tokens stored in plaintext SharedPreferences (not encrypted) |
| H32 | Frontend | `lib/core/network/interceptors.dart` | 10-14 | Debug logs expose Authorization headers and request bodies |
| H33 | Frontend | `lib/core/services/auth_service.dart` | 88-94 | Dev method with hardcoded test token `dev_token_123` in production code |
| H34 | Dependencies | `requirements.txt` | 1 | `python-jose==3.5.0` has CVE-2024-33663 (JWT bypass) and CVE-2024-33664 (DoS) |
| H35 | Dependencies | `requirements.txt` | 5-6 | `--pre` and `--extra-index-url` enable supply chain attacks globally |

---

### MEDIUM (35 findings)

| # | Area | Issue |
|---|------|-------|
| M1 | Config | `enable_reset_endpoint` defaults to `True` |
| M2 | Config | Redis password defaults to empty |
| M3 | Config | Debug logging and hot reload enabled by default |
| M4 | Main | CORS allows all methods and headers with credentials |
| M5 | Main | Exception messages leaked in development mode (which is the default) |
| M6 | Main | No security headers middleware (X-Frame-Options, CSP, HSTS, etc.) |
| M7 | Middleware | Invalid Bearer format silently passes through auth |
| M8 | Middleware | New refresh tokens returned in response headers (log exposure risk) |
| M9 | Middleware | User email logged on every authenticated request |
| M10 | Middleware | RLS `SET LOCAL` followed by `COMMIT` -- RLS context lost, effectively not enforced |
| M11 | Router | Token not invalidated on signout (JWT remains valid) |
| M12 | Router | Refresh token not invalidated after use (no rotation) |
| M13 | Router | File upload missing role check (viewers can upload) |
| M14 | Router | Project ownership not validated on upload (IDOR) |
| M15 | Router | Ticket deletion has incomplete admin check |
| M16 | Router | File path exposed in support ticket attachment response |
| M17 | Router | Invitation acceptance allows any authenticated user (no email match check) |
| M18 | Router | Invitation tokens have no expiration |
| M19 | Router | Organization deletion has no confirmation mechanism |
| M20 | Router | No input length validation on query text (LLM cost amplification) |
| M21 | Router | Prompt injection possible via user queries to RAG |
| M22 | Router | Transcription file size checked after full write to disk |
| M23 | WebSocket | No rate limiting on any WebSocket endpoint |
| M24 | WebSocket | No max message size enforcement |
| M25 | WebSocket | JWT tokens passed in WebSocket query strings (log exposure) |
| M26 | WebSocket | Client-controlled `client_id` enables connection hijacking |
| M27 | Frontend | Sentry sends PII with 100% sampling |
| M28 | Frontend | Implicit auth flow for Supabase (less secure than PKCE) |
| M29 | Frontend | Custom URL scheme `pm-master://` for deep links (hijackable) |
| M30 | Frontend | Race condition in token refresh with hardcoded 500ms delay |
| M31 | Frontend | No input validation/encoding on URL path parameters |
| M32 | Frontend | Production URL with dev-mode logging flags as defaults |
| M33 | Frontend | Markdown rendered without link sanitization |
| M34 | Docker | Elasticsearch output from Logstash has no authentication |
| M35 | Docker | Backend containers run as root |

---

### LOW (21 findings)

| # | Area | Issue |
|---|------|-------|
| L1 | Config | DB URL built via string interpolation (special char issues) |
| L2 | Config | Sentry 100% trace/profile sampling (cost/performance) |
| L3 | Config | Weak default passwords in `.env.example` |
| L4 | Config | All-zeros Langfuse encryption key in `.env.example` |
| L5 | Main | Uvicorn reload enabled by default |
| L6 | Router | Hardcoded localhost redirect URL for password reset |
| L7 | Router | No `limit` parameter upper bound on content list |
| L8 | Router | Unsanitized filename passed to background worker |
| L9 | Router | Invitation token in URL path (log exposure) |
| L10 | WebSocket | `print()` instead of logger in tickets WebSocket |
| L11 | WebSocket | Bare `except` clauses swallowing errors |
| L12 | WebSocket | Stale DB session on long-lived connections |
| L13 | Frontend | AppConfig.debugPrint exposes config details |
| L14 | Frontend | Admin database reset method exists in client code |
| L15 | Frontend | Auth token refresh uses bare Dio without interceptors |
| L16 | Frontend | No certificate pinning configured |
| L17 | Docker | Unversioned base image tags |
| L18 | Docker | Build tools left in production image |
| L19 | Docker | Docker socket mounted for Filebeat |
| L20 | Docker | ClickHouse trace-level logging in production |
| L21 | Dependencies | Test/dev dependencies in production requirements.txt |

---

## Top 10 Priority Fixes

These are ordered by risk and effort. Each should be addressed before any production deployment.

### 1. Remove Global SSL Bypasses (C1, C2, C3)
**Files**: `services/llm/langdetect_service.py`, `services/rag/embedding_service.py`, `services/auth/auth_service.py`
**Action**: Delete all `os.environ['PYTHONHTTPSVERIFY'] = '0'`, `ssl._create_default_https_context` overrides, `requests.Session.__init__` monkey-patches, and `verify=False`. Install proper CA certificates instead.

### 2. Fix SQL Injection in RLS Context (C4)
**File**: `middleware/rls_context.py`
**Action**: Replace all f-string SQL: `f"SET LOCAL app.user_id = '{user_id}'"` → use parameterized queries: `text("SET LOCAL app.user_id = :uid"), {"uid": user_id}`. Also fix the `COMMIT` that invalidates RLS context (M10).

### 3. Add Authentication to WebSocket Jobs Endpoint (C7, C8)
**File**: `routers/websocket_jobs.py`
**Action**: Add `token: str = Query(...)` parameter and call `get_current_user_ws()`. Add organization-level authorization checks on all job/project subscriptions.

### 4. Fix Fail-Open Authentication Middleware (H6, H7, C5)
**File**: `middleware/auth_middleware.py`
**Action**: Return 401 for missing/invalid tokens on non-public paths. Remove `verify_exp: False` from cache lookup decode. Return 503 on auth processing errors instead of passing through.

### 5. Require JWT Secret at Startup (C6, H26)
**Files**: `config.py`, `services/auth/native_auth_service.py`
**Action**: Add startup validator that halts application if `JWT_SECRET` is empty. Remove random fallback generation.

### 6. Add Rate Limiting (H5, H13)
**File**: `main.py` + auth routers
**Action**: Implement rate limiting via middleware or `fastapi-limiter` with Redis. Critical minimums: 5/min on login, 3/hr on forgot-password, 20/min on queries.

### 7. Secure Docker Production Configuration (C9, C10, C11, H9, H10)
**Files**: `docker-compose.prod.yml`, `clickhouse/config.xml`, `clickhouse/users.xml`
**Action**: Remove all default password fallbacks from production compose. Enable Elasticsearch security. Remove or authenticate RQ Dashboard and Kibana. Bind all services to `127.0.0.1`. Externalize ClickHouse passwords.

### 8. Add Authorization to WebSocket Live Insights (H22, H23)
**File**: `routers/websocket_live_insights.py`
**Action**: Verify authenticated user belongs to the organization that owns the session before allowing connection. Add `organization_id` filter to `get_session_state` query.

### 9. Fix Frontend Token Storage (H31)
**Files**: `lib/core/storage/secure_storage_mobile.dart`
**Action**: Restore `flutter_secure_storage` package for mobile/desktop platforms. Use Android Keystore / iOS Keychain for token storage.

### 10. Remove Vulnerable Dependency (H34)
**File**: `requirements.txt`
**Action**: Remove `python-jose` (has CVE-2024-33663 and CVE-2024-33664). Already using `pyjwt` which is actively maintained and sufficient.

---

## Patterns Observed (Vibecoding Anti-Patterns)

These systemic issues indicate rapid development without security review:

1. **"Just disable SSL"**: Two files globally disable SSL for the entire Python process to work around certificate download issues. This is the #1 vibecoding anti-pattern.

2. **"Fail open" authentication**: The auth middleware defaults to allowing access when anything goes wrong -- missing token, bad format, exception. This is backwards; production auth should fail closed.

3. **"I'll add auth later"**: The `/ws/jobs` WebSocket endpoint was shipped with zero authentication. The `native_auth` password change endpoint doesn't require the current password.

4. **"Default to development"**: `api_env` defaults to `development`, `enable_reset_endpoint` defaults to `True`, logging defaults to `debug`, `api_reload` defaults to `True`. Every environment defaults to the least secure configuration.

5. **"Just log everything"**: Auth headers, JWT tokens, user emails, prompt content, and exception details are logged liberally. Development-friendly logging becomes a security liability.

6. **"One size fits all"**: `--pre` and `--extra-index-url` in the global requirements file affect every package install, creating supply chain risk for all 100+ dependencies.

---

## Files Audited

### Backend (Python)
- `backend/config.py`
- `backend/main.py`
- `backend/middleware/auth_middleware.py`
- `backend/middleware/rls_context.py`
- `backend/dependencies/auth.py`
- `backend/routers/auth.py`
- `backend/routers/native_auth.py`
- `backend/routers/admin.py`
- `backend/routers/upload.py`
- `backend/routers/transcription.py`
- `backend/routers/queries.py`
- `backend/routers/content.py`
- `backend/routers/support_tickets.py`
- `backend/routers/organizations.py`
- `backend/routers/invitations.py`
- `backend/routers/websocket_jobs.py`
- `backend/routers/websocket_live_insights.py`
- `backend/routers/websocket_notifications.py`
- `backend/routers/websocket_tickets.py`
- `backend/services/auth/auth_service.py`
- `backend/services/auth/native_auth_service.py`
- `backend/services/llm/langdetect_service.py`
- `backend/services/llm/multi_llm_client.py`
- `backend/services/llm/gpt5_streaming.py`
- `backend/services/rag/embedding_service.py`
- `backend/services/rag/enhanced_rag_service_refactored.py`
- `backend/services/rag/conversation_context_service.py`
- `backend/services/rag/hybrid_search.py`
- `backend/services/rag/multi_query_retrieval.py`
- `backend/services/rag/intelligent_chunking.py`
- `backend/services/demo/demo_data_service.py`
- `backend/db/database.py`
- `backend/db/multi_tenant_vector_store.py`
- `backend/requirements.txt`
- `backend/requirements-dev.txt`

### Frontend (Flutter/Dart)
- `lib/main.dart`
- `lib/config.dart`
- `lib/firebase_options.dart`
- `lib/core/config/api_config.dart`
- `lib/core/config/app_config.dart`
- `lib/core/config/supabase_config.dart`
- `lib/core/network/api_client.dart`
- `lib/core/network/dio_client.dart`
- `lib/core/network/interceptors.dart`
- `lib/core/network/organization_interceptor.dart`
- `lib/core/storage/secure_storage_mobile.dart`
- `lib/core/storage/secure_storage_web.dart`
- `lib/core/services/auth_service.dart`
- `lib/features/auth/` (all files)
- `pubspec.yaml`

### Infrastructure
- `Dockerfile` (frontend)
- `backend/Dockerfile`
- `docker-compose.yml`
- `docker-compose.prod.yml`
- `.dockerignore` / `backend/.dockerignore`
- `.env.example`
- `.gitignore`
- `Makefile`
- `filebeat/filebeat.yml`
- `logstash/config/logstash.yml`
- `logstash/pipeline/logstash.conf`
- `backend/clickhouse/config.xml`
- `backend/clickhouse/users.xml`
- `.github/workflows/` (all 7 workflow files)

### Git History
- Full commit history scanned for leaked secrets
- No real API keys or production credentials found in history
- Firebase API keys present (by design, but verify Security Rules)
