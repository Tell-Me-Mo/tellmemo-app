# Changelog

All notable changes to TellMeMo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added (October 2025)

#### Email Digest System (PR #54 - 2025-10-12)
- SendGrid integration for automated email delivery
- User email preferences management (digest frequency, content types)
- Daily, weekly, and monthly digest generation with APScheduler
- Onboarding welcome emails for new users
- Inactive user reminder emails (7-day inactivity detection)
- Beautiful HTML email templates with responsive design
- JWT-based unsubscribe functionality
- Admin endpoints for testing and manual triggers
- Rate limiting for SendGrid free tier (100 emails/day)
- Empty digest prevention (no spam)
- Email preferences UI in Flutter app
- Preview digest functionality before sending
- Send test email capability

#### Intelligent LLM Provider Fallback (PR #69 - 2025-10-13)
- Automatic OpenAI fallback when Claude is overloaded (529 errors)
- Intelligent model translation (Claude Haiku → GPT-4o-mini, Sonnet → GPT-4o)
- Provider cascade architecture with configurable retry strategies
- Comprehensive fallback metadata tracking for observability
- Langfuse integration for monitoring fallback events
- Zero code changes required - transparent failover
- Configurable per-organization or globally
- Maintains equivalent model quality across providers
- Circuit Breaker Pattern - Production resilience with purgatory library
  - Automatically opens circuit after configurable threshold (default: 5 failures)
  - Prevents cascading failures by skipping primary provider when circuit is open
  - Auto-recovery with configurable timeout (default: 5 minutes)
  - Transparent integration with existing fallback system
  - Environment-based configuration (ENABLE_CIRCUIT_BREAKER, threshold, timeout)
- Detailed documentation in `backend/FALLBACK_IMPLEMENTATION.md`
- Full test coverage with 16 integration tests

#### Meeting Upload Quality Improvements (PR #73 - 2025-10-16)
- Semantic deduplication service with embedding-based similarity detection
  - Detects semantic duplicates with 85%+ similarity threshold
  - Expected to reduce semantic duplicates by 70%
- Date context enhancement to prevent incorrect year parsing
- Automatic closure detection for tasks/risks/blockers
  - Detects completion mentions in meeting transcripts
  - Auto-closes items when mentioned as "completed", "done", "resolved"
- Enhanced assignee extraction with multiple pattern matching
  - Aggressive assignee extraction with participant name extraction
  - Implicit assignment detection ("I'll do X" → speaker name)
  - Expected to reduce unassignment rate from 30% to <10%
- Database migration for title embeddings
- Backfill script for existing data

#### Item Updates Tracking System (PR #71 - 2025-10-15)
- Automatic update tracking for all item types (tasks, risks, lessons, summaries)
- Real-time Flutter UI integration with live updates
- Enhanced Updates tab with filter and improved send button
- Comprehensive test coverage for item updates functionality
- Task menu improvements with Edit and Delete options
- Consolidated delete confirmation dialogs

#### UI/UX Enhancements
- **Right Panel UI Pattern** (PR #70 - 2025-10-14)
  - Migrated all item dialogs to consistent right panel pattern
  - Modernized form field styling across all item detail panels
  - AI assistant integration in lesson learned panel
  - Reduced notification noise for create/update operations
  - Standardized item detail panel styling and summary status badges
- **Text Selection and Truncation** (PR #72 - 2025-10-15)
  - Added text selection and copying across all detail panels
  - Read more/less text truncation for better readability
  - Comment count badges on Updates tab
  - Fixed project name truncation issues
- **Mobile UX Improvements** (PR #74 - 2025-10-17)
  - Smart title truncation at 70 characters with word-boundary detection
  - Consolidated action buttons into 3-dot menu for cleaner mobile UI
  - Tooltip displays full title on long-press
  - No changes to desktop experience

#### Infrastructure & Development
- **Redis Queue (RQ) Migration** (PR #40 - 2025-10-09)
  - Replaced custom upload_job_service with production-ready RQ
  - Multi-priority queues (high, default, low)
  - Real-time job updates via Redis pub/sub
  - Horizontal scaling support
  - RQ Dashboard for job queue visualization
- **Automated Testing Workflows** (PR #35 - 2025-10-07)
  - GitHub Actions workflows for backend and frontend tests
  - Smart path-based triggering
  - Coverage tracking with Codecov integration
  - Tests block PR merge on failure
- **Audio Recording Improvements** (PR #51 - 2025-10-10)
  - AAC codec support for iOS web browsers
  - Fixes MediaStreamTrack errors on Safari, Chrome, Firefox iOS

### Changed

#### Architecture
- Migrated from custom job service to Redis Queue (RQ) for background task processing (PR #40)
- Migrated from SnackBar to centralized NotificationService across entire app (PR #53)
- Refactored job cancellation with decorator pattern (81% code reduction) (PR #53)
- Database schema: Converted ItemUpdateType from PostgreSQL enum to VARCHAR for flexibility (PR #71)

#### Performance
- Fixed async event loop blocking in hybrid search diversity optimization (PR #72)
- Optimized upload dialog and recording lifecycle (PR #38)
- Reduced redundant API calls during recording (PR #38)

#### UI/UX
- Major refactor of simplified_project_details_screen.dart (~2000 lines reduction) (PR #53)
- Enhanced dashboard with improved layout and responsiveness (PR #36)
- Better hierarchy screen organization and navigation (PR #36)
- Improved mobile UI across integrations, organizations, and documentation views (PR #38, #39)

### Security

#### Vulnerability Fixes (PR #33 - 2025-10-05)
- Updated python-jose from 3.3.0 to 3.5.0 to patch known vulnerabilities
- Addressed ReDoS (Regular Expression Denial of Service) attack vectors
- Added input validation to prevent DoS attacks
  - Slug generation: 200 character limit
  - Text normalization: 10KB limit
- Replaced vulnerable regex patterns with safe alternatives
- Fixed security issues in organizations, text_similarity, chunking_service

#### General Security
- JWT-based authentication with automatic token generation
- Built-in user management
- Secure API key handling
- Environment variable configuration
- JWT-based email unsubscribe tokens (90-day expiration)

### Fixed

#### Backend
- Language validation and improved error handling in transcription API (PR #39)
- Backend test failures in error handling (PR #38)
- Project matcher logic with better error handling (PR #36)
- Fixed auth middleware organization switching logic (cache invalidation) (PR #40)
- Audio transcription temp file paths for container accessibility (PR #48, #49)
- Logstash HTTP port exposure for Python application logging (PR #37)

#### Frontend
- Task status updates now reflect immediately in UI without page refresh (PR #53)
- Upload dialog stuck progress and page refresh issues (PR #38)
- Mobile UI overflow in integrations cards (PR #38)
- Layout overflow in OrganizationSettingsDialog (PR #39)
- Recording functionality with better state management (PR #36)
- Permission check on web browsers for browser-native handling (PR #52)
- Fixed 7 failing tests after NotificationService migration (PR #53)
- Dialog rounded corners visual issues (PR #71)

#### Infrastructure
- Docker Compose environment variable configuration (PR #50, #74)
- YAML syntax errors in workflow files (PR #42-46)
- Nginx MIME types for Flutter WebAssembly deployment (PR #38)

### Documentation

- Created comprehensive email digest feature plan (1,462 lines) (PR #54)
- Updated HLD.md with email digest system, dual auth, and missing components
- Added INTELLIGENT_DEDUPLICATION_IMPLEMENTATION.md (380 lines) (PR #73)
- Added UPLOAD_QUALITY_EVALUATION_2025-10-13.md with progress tracking (PR #70, #73)
- Added MIGRATION_COMPLETED.md documenting UI migration (PR #70)
- Added Kafka implementation guide (docs/kafka.md) (PR #40)
- Added Redis implementation guide (docs/redis.md) (PR #40)
- Added Replicate transcription performance analysis (PR #40)
- Updated USER_JOURNEY.md with email preferences section (PR #54)
- Updated Feature Branch Model workflow documentation (PR #30, #31, #32)
- Backend and frontend testing strategy documentation (PR #35)

### Testing

- Added 30 comprehensive integration tests for email digest system (PR #54)
- Added 12 integration tests for LLM fallback (PR #69)
- Added 250+ features tested for item updates functionality (PR #71)
- Added 14 unit tests for RQ utils with 100% coverage (PR #53)
- Added 457 lines of transcription endpoint integration tests (PR #39)
- Added 483 lines of frontend widget tests (PR #39)
- Added comprehensive RQ integration tests (PR #40)
- Added no_snackbar_test.dart to prevent SnackBar usage (PR #53)
- **Overall Coverage**: Backend 97%, Frontend 99%

## [1.0.0-beta] - 2025-10-03

### Added

#### Core Features
- Initial release of TellMeMo (formerly PM Master V2)
- AI-powered meeting intelligence platform
- RAG (Retrieval Augmented Generation) for meeting analysis
- Flutter web frontend
- FastAPI backend with built-in authentication
- PostgreSQL for metadata storage
- Qdrant vector database for semantic search
- Claude 3.5 Haiku integration for LLM reasoning
- Google EmbeddingGemma-300m for local embeddings
- Docker Compose deployment configuration

#### Business Features
- User authentication system (email/password)
- Project hierarchy (Portfolio → Programs → Projects)
- Meeting transcript upload and processing
- Automatic action item extraction
- Risk detection from meeting content
- Context-aware chat interface
- Summary generation (Executive, Technical, Stakeholder, General)
- Semantic search across all content
- Multi-turn conversation with context

#### Documentation
- Documentation website (tellmemo.io)
- Comprehensive user documentation
- API documentation
- Installation guide
- Docker-first deployment documentation
- User guide with business-focused workflows
- Configuration reference with all environment variables
- Troubleshooting guide for common issues
- Updated README.md and CONTRIBUTING.md

### Changed
- Migrated from multi-service architecture to simplified 4-service core
- Moved from Supabase to built-in backend authentication
- Changed repository name from `pm_master_v2` to `tellmemo-app`
- Updated organization from `the-harpia-io` to `Tell-Me-Mo`
- Simplified deployment to Docker Compose only
- Frontend runs on port 8100 (was 80)
- Backend runs on port 8000

### Removed
- Supabase authentication dependency (now built-in)
- Langfuse from core architecture (optional)
- ELK Stack from core architecture (optional)
- Redis from core architecture (optional)
- MinIO from core architecture (optional)
- Complex multi-option deployment guides

### Fixed
- Consolidated documentation to remove duplicates
- Updated all repository URLs
- Corrected Docker Compose commands (docker compose vs docker-compose)
- Fixed port references throughout documentation

## Project Status

**Current Version:** 1.0.0-beta

**Status:** Beta - Feature complete, undergoing testing and refinement

### Supported Platforms
- Web (primary)
- macOS (via Flutter)
- iOS (via Flutter)
- Android (via Flutter)
- Windows (via Flutter)
- Linux (via Flutter)

### Browser Support
- Chrome/Edge (recommended)
- Firefox
- Safari

### Minimum Requirements
- Docker ≥20.10
- Docker Compose ≥2.0
- 8GB RAM (16GB recommended)
- 20GB disk space
- 4+ CPU cores (recommended)

### API Keys Required
- Anthropic API Key (Claude 3.5) - Primary LLM provider
- OpenAI API Key (Optional) - Fallback provider for high availability
- Hugging Face Token (for embedding models)
- SendGrid API Key (Optional) - For email digest system

## Upcoming Features

See [GitHub Issues](https://github.com/Tell-Me-Mo/tellmemo-app/issues) for planned features and enhancements.

### Planned for Future Releases
- Real-time meeting transcription
- Integration with Zoom, Google Meet, Microsoft Teams
- Calendar integration
- Slack notifications
- Mobile app improvements
- Performance optimizations
- Multi-language support
- Advanced analytics dashboard
- Team collaboration features
- Email digest enhancements:
  - Organization-level email filtering
  - Per-project opt-in/opt-out for digest inclusion
  - Email analytics tracking (open rates, clicks)
  - SendGrid webhook for bounce/spam handling
  - A/B testing for email content

## Migration Guide

### From Earlier Versions

If you're upgrading from an earlier version or different setup:

1. **Backup your data:**
   ```bash
   docker compose exec postgres pg_dump -U pm_master pm_master_db > backup.sql
   ```

2. **Update repository:**
   ```bash
   git pull origin main
   ```

3. **Update environment variables:**
   - Copy new variables from `.env.example`
   - Ensure `ANTHROPIC_API_KEY` and `HF_TOKEN` are set
   - Add `OPENAI_API_KEY` for fallback support (optional)
   - Add `SENDGRID_API_KEY` for email digests (optional)

4. **Run database migrations:**
   ```bash
   cd backend
   alembic upgrade head
   ```

5. **Restart services:**
   ```bash
   docker compose down
   docker compose pull
   docker compose up -d
   ```

6. **Start RQ workers (if using background jobs):**
   ```bash
   python backend/start_rq_worker.py
   ```

7. **Verify deployment:**
   - Check all containers are running: `docker compose ps`
   - Access UI at `http://localhost:8100`
   - Test backend API at `http://localhost:8000/docs`

## Notable Pull Requests

This changelog is based on the following merged pull requests:

- PR #74: Mobile UX improvements for item detail panels
- PR #73: Quality improvements for meeting upload processing
- PR #72: Enhanced right panel UX with text selection and truncation
- PR #71: Item updates tracking system with UI enhancements
- PR #70: Migrate item dialogs to right panel UI
- PR #69: Intelligent OpenAI fallback for Claude API overload
- PR #54: Email Digest System
- PR #53: Job cancellation improvements and NotificationService migration
- PR #51: AAC codec for iOS web browsers
- PR #40: Redis Queue (RQ) migration
- PR #39: UI/UX improvements and ELK logging
- PR #38: UI/UX improvements and bug fixes
- PR #36: Recording functionality enhancements
- PR #35: Automated testing workflows
- PR #33: Security vulnerability fixes
- PR #30-32: Feature Branch Model documentation
- PR #1-3, #23-29: Initial development and merge fixes

For complete PR history, see: https://github.com/Tell-Me-Mo/tellmemo-app/pulls?q=is%3Apr+is%3Amerged

## Support

- **Documentation:** [tellmemo.io/documentation](https://tellmemo.io/documentation)
- **Issues:** [GitHub Issues](https://github.com/Tell-Me-Mo/tellmemo-app/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Tell-Me-Mo/tellmemo-app/discussions)

---

For older changes and detailed commit history, see [Git History](https://github.com/Tell-Me-Mo/tellmemo-app/commits/main).
