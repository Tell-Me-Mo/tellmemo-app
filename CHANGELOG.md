# Changelog

All notable changes to TellMeMo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
- User authentication system (email/password)
- Project hierarchy (Portfolio → Programs → Projects)
- Meeting transcript upload and processing
- Automatic action item extraction
- Risk detection from meeting content
- Context-aware chat interface
- Summary generation (Executive, Technical, Stakeholder, General)
- Semantic search across all content
- Multi-turn conversation with context
- Documentation website (tellmemo.io)
- Comprehensive user documentation
- API documentation
- **Email Digest System** (2025-10-12) ✨ NEW
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
- **Intelligent LLM Provider Fallback** (2025-10-13) ✨ NEW
  - Automatic OpenAI fallback when Claude is overloaded (529 errors)
  - Intelligent model translation (Claude Haiku → GPT-4o-mini, Sonnet → GPT-4o)
  - Provider cascade architecture with configurable retry strategies
  - Comprehensive fallback metadata tracking for observability
  - Langfuse integration for monitoring fallback events
  - Zero code changes required - transparent failover
  - Configurable per-organization or globally
  - Maintains equivalent model quality across providers
  - Detailed documentation in `backend/FALLBACK_IMPLEMENTATION.md`
  - Full test coverage with 12 integration tests

### Changed
- Migrated from multi-service architecture to simplified 4-service core
- Moved from Supabase to built-in backend authentication
- Changed repository name from `pm_master_v2` to `tellmemo-app`
- Updated organization from `the-harpia-io` to `Tell-Me-Mo`
- Simplified deployment to Docker Compose only
- Frontend runs on port 8100 (was 80)
- Backend runs on port 8000
- Made Langfuse, ELK Stack, and Redis optional (not in core deployment)

### Removed
- Supabase authentication dependency (now built-in)
- Langfuse from core architecture (optional)
- ELK Stack from core architecture (optional)
- Redis from core architecture (optional)
- MinIO from core architecture (optional)
- Complex multi-option deployment guides

### Security
- JWT-based authentication with automatic token generation
- Built-in user management
- Secure API key handling
- Environment variable configuration

### Fixed
- Consolidated documentation to remove duplicates
- Updated all repository URLs
- Corrected Docker Compose commands (docker compose vs docker-compose)
- Fixed port references throughout documentation

### Documentation
- Created comprehensive installation guide
- Docker-first deployment documentation
- User guide with business-focused workflows
- Configuration reference with all environment variables
- Troubleshooting guide for common issues
- API reference documentation
- Updated README.md for clarity
- Updated CONTRIBUTING.md with Docker-first approach

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

4. **Restart services:**
   ```bash
   docker compose down
   docker compose pull
   docker compose up -d
   ```

5. **Verify deployment:**
   - Check all containers are running: `docker compose ps`
   - Access UI at `http://localhost:8100`
   - Test backend API at `http://localhost:8000/docs`

## Support

- **Documentation:** [tellmemo.io/documentation](https://tellmemo.io/documentation)
- **Issues:** [GitHub Issues](https://github.com/Tell-Me-Mo/tellmemo-app/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Tell-Me-Mo/tellmemo-app/discussions)

---

For older changes and detailed commit history, see [Git History](https://github.com/Tell-Me-Mo/tellmemo-app/commits/main).
