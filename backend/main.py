import os
# Set environment variable to suppress tokenizers parallelism warning
os.environ["TOKENIZERS_PARALLELISM"] = "false"

import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import sentry_sdk

from config import get_settings, configure_logging
from routers import health, projects, content, queries, admin, scheduler, activities, transcription, jobs, websocket_jobs, integrations, upload, portfolios, programs, hierarchy, hierarchy_summaries, content_availability, unified_summaries, risks_tasks, lessons_learned, auth, native_auth, organizations, invitations, websocket_notifications, support_tickets, websocket_tickets, conversations, notifications, email_preferences, email_admin
from utils.logger import get_logger
from db.database import init_database, close_database
from db.multi_tenant_vector_store import multi_tenant_vector_store
from services.rag.embedding_service import init_embedding_service
from services.scheduling.scheduler_service import scheduler_service
from services.scheduler.digest_scheduler import digest_scheduler
from services.llm.multi_llm_client import get_multi_llm_client
from middleware.auth_middleware import AuthMiddleware

settings = get_settings()
configure_logging(settings)
logger = get_logger(__name__)

# Initialize Sentry
if settings.sentry_enabled and settings.sentry_dsn:
    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        send_default_pii=True,
        traces_sample_rate=settings.sentry_traces_sample_rate,
        profiles_sample_rate=settings.sentry_profile_sample_rate,
        environment=settings.sentry_environment,
    )
    logger.info(f"Sentry initialized for environment: {settings.sentry_environment}")
elif not settings.sentry_enabled:
    logger.info("Sentry is disabled via SENTRY_ENABLED=false")
else:
    logger.warning("Sentry DSN not configured - error tracking disabled")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting PM Master V2 Backend...")
    logger.info(f"Environment: {settings.api_env}")
    logger.info(f"API running at http://{settings.api_host}:{settings.api_port}")
    
    # Initialize database connections
    try:
        await init_database()

        # Run Alembic migrations automatically on startup
        try:
            import os
            import sys
            logger.info("Running database migrations...")

            # Run migrations in a subprocess to avoid async deadlock
            # Alembic's env.py uses asyncio.run() which conflicts with FastAPI's event loop
            backend_dir = os.path.dirname(os.path.abspath(__file__))

            # Find alembic in venv or system PATH
            # Check if running in venv and use venv's alembic
            venv_alembic = os.path.join(sys.prefix, 'bin', 'alembic')
            alembic_cmd = venv_alembic if os.path.exists(venv_alembic) else 'alembic'

            logger.debug(f"Using alembic command: {alembic_cmd}")

            result = await asyncio.create_subprocess_exec(
                alembic_cmd, 'upgrade', 'head',
                cwd=backend_dir,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await result.communicate()

            if result.returncode == 0:
                logger.info("✅ Database migrations completed successfully")
                if stdout:
                    logger.debug(f"Migration output: {stdout.decode()}")
            else:
                logger.error(f"❌ Migration failed with return code {result.returncode}")
                if stderr:
                    logger.error(f"Migration error: {stderr.decode()}")
                logger.warning("⚠️ Continuing startup - migrations may have already been applied")

        except FileNotFoundError:
            logger.warning("⚠️ Alembic not found in PATH - skipping automatic migrations")
            logger.info("💡 Run migrations manually with: cd backend && alembic upgrade head")
        except Exception as migration_error:
            logger.error(f"❌ Failed to run database migrations: {migration_error}")
            import traceback
            logger.error(f"Migration traceback: {traceback.format_exc()}")
            # Continue running - migrations might have already been applied

    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        # Continue running even if database is not available initially
    
    # Initialize multi-tenant vector store connections
    try:
        await multi_tenant_vector_store.init_client()
        logger.info("Multi-tenant vector store initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize vector store: {e}")
        # Continue running even if vector store is not available initially
    
    # Initialize embedding service (MANDATORY - app will not start without it)
    try:
        await init_embedding_service()
        logger.info("✅ EmbeddingGemma model initialized successfully")
    except Exception as e:
        logger.error(f"❌ CRITICAL: Failed to initialize embedding service: {e}")
        logger.error("EmbeddingGemma model is required for the application to function")
        logger.error("Please check your HF_TOKEN and network connectivity")
        raise RuntimeError(f"Cannot start application without embedding service: {e}")

    # Initialize language detection service (optional but recommended)
    try:
        from services.llm.langdetect_service import language_detection_service
        if await language_detection_service.initialize():
            logger.info("✅ Language detection service initialized successfully")
        else:
            logger.warning("⚠️ Language detection service not available (will use default language)")
    except Exception as e:
        logger.warning(f"⚠️ Failed to initialize language detection: {e}")
        # Continue running - language detection is optional

    # Initialize multi-provider LLM client singleton
    try:
        llm_client = get_multi_llm_client(settings)
        if llm_client.is_available():
            logger.info(f"Multi-provider LLM client initialized")
        else:
            logger.warning("Multi-provider LLM client initialized but no providers configured")
    except Exception as e:
        logger.error(f"Failed to initialize multi-provider LLM client: {e}")
        # Continue running - services will handle unavailable client

    # Note: Scheduler service provides manual triggers only
    # Automated scheduling has been moved to Redis Queue (RQ)
    logger.info("Scheduler service initialized (manual weekly report triggers available)")

    # Validate email digest configuration before starting scheduler
    if settings.email_digest_enabled and not settings.sendgrid_api_key.strip():
        logger.warning("⚠️ EMAIL DIGEST CONFIGURATION WARNING:")
        logger.warning("   Email digest is enabled (EMAIL_DIGEST_ENABLED=true)")
        logger.warning("   but SendGrid API key is missing (SENDGRID_API_KEY is empty)")
        logger.warning("   Email notifications will not be sent until API key is configured")
        logger.warning("   To disable email digest, set EMAIL_DIGEST_ENABLED=false in .env")

    # Start email digest scheduler
    try:
        digest_scheduler.start()
        logger.info("Email digest scheduler started successfully")
    except Exception as e:
        logger.error(f"Failed to start email digest scheduler: {e}")
        # Continue running - digest scheduler is optional
    
    # Pre-load Whisper model at startup (only if using Whisper as default service)
    # This improves first transcription speed but consumes ~1-2GB RAM
    if settings.default_transcription_service.lower() == 'whisper':
        try:
            from services.transcription.whisper_service import get_whisper_service
            logger.info("Pre-loading Whisper transcription model...")
            whisper_service = get_whisper_service()
            if whisper_service.is_model_loaded():
                logger.info("✅ Whisper model pre-loaded successfully")
            else:
                logger.warning("⚠️ Whisper model not loaded")
        except Exception as e:
            logger.warning(f"⚠️ Failed to pre-load Whisper model: {e}")
            logger.info("Model will be loaded on first transcription request")
            # Continue running - model will load on demand
    else:
        logger.info(f"Skipping Whisper pre-load (using {settings.default_transcription_service} service)")
        logger.info("Whisper will load on-demand if needed")

    yield

    logger.info("Shutting down PM Master V2 Backend...")

    # Shutdown email digest scheduler
    try:
        digest_scheduler.stop()
        logger.info("Email digest scheduler shutdown complete")
    except Exception as e:
        logger.error(f"Error shutting down digest scheduler: {e}")

    await close_database()
    await multi_tenant_vector_store.close()


app = FastAPI(
    title="PM Master V2 - Meeting RAG System",
    description="A streamlined meeting intelligence platform using RAG for project insights",
    version="0.1.0",
    docs_url=None,  # Docs disabled for security
    redoc_url=None,  # ReDoc disabled for security
    lifespan=lifespan
)

# Note: Rate limiting (slowapi) removed due to invasive Request parameter requirement
# SlowAPI requires ALL endpoints to have Request parameter when app.state.limiter is set
# TODO: Implement rate limiting using middleware-based approach or fastapi-limiter

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add Authentication middleware
app.add_middleware(AuthMiddleware)


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "message": str(exc) if settings.is_development else "An unexpected error occurred"
        }
    )


# Conditionally include auth router based on AUTH_PROVIDER setting
# Both routers use /api/v1/auth prefix, so only one should be active
if settings.auth_provider == "supabase":
    app.include_router(auth.router, tags=["auth"])
    logger.info("Using Supabase authentication")
else:  # backend/native auth
    app.include_router(native_auth.router, tags=["native-auth"])
    logger.info("Using native backend authentication")

app.include_router(organizations.router, tags=["organizations"])
app.include_router(invitations.router, tags=["invitations"])
app.include_router(health.router, prefix="/api/v1", tags=["health"])
app.include_router(portfolios.router)
app.include_router(programs.router)
app.include_router(hierarchy.router)
app.include_router(projects.router)
app.include_router(content.router, prefix="/api/v1/projects", tags=["content"])
app.include_router(upload.router, prefix="/api/v1/upload", tags=["upload"])
app.include_router(queries.router, prefix="/api/v1/projects", tags=["queries"])
app.include_router(conversations.router, prefix="/api/v1/projects", tags=["conversations"])
app.include_router(scheduler.router, prefix="/api/v1/scheduler", tags=["scheduler"])
app.include_router(activities.router, tags=["activities"])
app.include_router(websocket_jobs.router, tags=["websocket"])
app.include_router(transcription.router, tags=["transcription"])
app.include_router(jobs.router, prefix="/api/v1", tags=["jobs"])
app.include_router(integrations.router, tags=["integrations"])
app.include_router(hierarchy_summaries.router, prefix="/api/v1/hierarchy", tags=["hierarchy-summaries"])
app.include_router(unified_summaries.router, prefix="/api/v1/summaries", tags=["unified-summaries"])
app.include_router(content_availability.router, prefix="/api/v1/content-availability", tags=["content-availability"])
app.include_router(risks_tasks.router)
app.include_router(lessons_learned.router)
app.include_router(notifications.router)
app.include_router(websocket_notifications.router, tags=["websocket"])
app.include_router(support_tickets.router)
app.include_router(websocket_tickets.router, tags=["websocket"])
app.include_router(email_preferences.router)

if settings.enable_reset_endpoint and settings.is_development:
    app.include_router(admin.router, prefix="/api/v1/admin", tags=["admin"])
    app.include_router(email_admin.router, tags=["admin-email"])
    logger.warning("Database reset endpoint is enabled (DEVELOPMENT MODE)")


# Root endpoint disabled for security - was exposing environment details
# @app.get("/")
# async def root():
#     return {
#         "name": "PM Master V2 API",
#         "version": "0.1.0",
#         "status": "running",
#         "environment": settings.api_env,
#         "docs": f"http://{settings.api_host}:{settings.api_port}/docs"
#     }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=settings.api_reload,
        log_level=settings.api_log_level
    )