# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PM Master V2** - A Flutter-based Meeting RAG System that uses Retrieval Augmented Generation to help teams extract insights from meeting transcripts and emails, generate summaries, and track project progress.

This is currently a starter Flutter project in early development phase, implementing an MVP of a meeting intelligence platform as described in HLD_MVP.md.

DO NOT RUN FLUTTER APP! IT IS ALWAYS RUNNING LOCALLY ON PORT 8100 (but you can run flutter analyzer)
DO NOT RUN PYTHON BACKEND, IT IS ALWAYS RUNNING LOCALLY

DO NOT CREATE SUMMARY .md documents if I did not ask to do it

IN Flutter - do not use hardcoded timers if need to wait for something. It is sounds like a workaround and not a clean solution.

## Key Commands

### Development Commands
```bash
# Run the Flutter app
flutter run

# Run on specific platform
flutter run -d chrome  # Web
flutter run -d macos   # macOS desktop

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Build for production
flutter build web
flutter build macos
flutter build ios
flutter build apk
```

### Code Quality
```bash
# Check for lint issues and code problems
flutter analyze

# Format code
dart format .

# Run a single test file
flutter test test/widget_test.dart
```

## Architecture & Structure

### Current State
The project is currently a basic Flutter starter template with:
- Single `lib/main.dart` file containing the default counter app
- Material Design theme configuration
- Basic stateful widget implementation

### Planned Architecture (from HLD_MVP.md)

#### Backend Stack (To Be Implemented)
- **FastAPI** - REST API & async processing
- **PostgreSQL** - Project & meeting metadata  
- **Qdrant** - Vector database for semantic search
- **Claude 3.5 Haiku** - LLM for reasoning & generation
- **SentenceTransformers** - Embeddings (all-MiniLM-L6-v2)
- **Langfuse** - LLM observability & cost tracking

#### Flutter Frontend Architecture (To Be Implemented)
The frontend will follow a feature-based architecture with:
- **State Management**: Provider or Riverpod (TBD)
- **Routing**: go_router for navigation
- **UI Framework**: Material Design 3
- **Responsive Design**: Support for desktop, tablet, and mobile

### Key Implementation Tasks (from TASKS.md)

The project has 35 development tasks organized in phases:
- **Phase 1-2**: Backend infrastructure & Core API (P0 priority)
- **Phase 3-4**: RAG System & Summary Generation
- **Phase 5-6**: Flutter Web Frontend
- **Phase 7-8**: Observability & Testing
- **Phase 9**: Deployment & DevOps

Priority tasks currently focus on backend setup before Flutter UI development.

## Development Workflow

### Task Implementation (from .claude/commands/work_on_tasks.md)

When implementing tasks:
1. **Always read** CHANGELOG.md, TASKS.md, HLD_MVP.md, and USER_JOURNEY_MVP.md first
2. **Select tasks by priority**: P0 → P1 → P2
3. **Use specialized agents**:
   - `flutter-code-searcher` - Analyze Flutter/Dart codebase patterns
4. **Update documentation**: Mark completed tasks in TASKS.md and update CHANGELOG.md
5. **Verify changes**: Run `flutter analyze` before committing

### Code Standards
- **Dart naming**: camelCase for variables/functions, PascalCase for classes
- **Use const constructors** where possible
- **Proper disposal** of controllers and subscriptions
- **Follow existing patterns** in the codebase
- **No hardcoded values** - use configuration files
- **Input validation** on all user inputs

## Key Design Documents

### HLD_MVP.md
Defines the complete MVP architecture including:
- 3-step RAG reasoning system
- Project and content management
- Meeting summary generation
- Weekly report compilation
- Flutter Web dashboard specifications

### USER_JOURNEY_MVP.md
Outlines the user experience flow for the MVP (if exists).

### TASKS.md
Contains 35 detailed development tasks with:
- Acceptance criteria for each task
- Priority levels (P0, P1, P2)
- Complexity ratings
- Dependencies between tasks
- Implementation timeline (8 weeks total)

## Current Dependencies

### Flutter/Dart
- Flutter SDK: ^3.9.0
- cupertino_icons: ^1.0.8
- flutter_lints: ^5.0.0 (dev dependency)

### Planned Dependencies (Not Yet Added)
- go_router (navigation)
- provider or riverpod (state management)
- http or dio (API client)
- flutter_markdown (rich text display)
- file_picker (file uploads)

## Testing Approach

- **Widget tests**: In `test/` directory
- **Integration tests**: To be added for complete user flows
- **API tests**: Backend testing with pytest (when implemented)
- **Target coverage**: 80% for Flutter widgets

## MCP Servers

### Dart and Flutter MCP Server

The official Dart and Flutter MCP server is configured for this project, providing AI-powered development assistance.

**Status**: ✓ Connected (local scope)

**What it provides**:
- Get current runtime errors from running applications
- Search pub.dev for packages and add them as dependencies
- Generate widget code and self-correct syntax errors
- Access to Dart/Flutter SDK tools and diagnostics

**When to use**:
- Use the IDE MCP tools (`mcp__ide__getDiagnostics`, `mcp__ide__executeCode`) for accessing Flutter/Dart diagnostics and code execution
- The MCP server runs automatically in the background when using Claude Code
- Diagnostics are available for any Dart/Flutter files in the project

**Requirements**:
- Dart SDK 3.9+ / Flutter 3.35+ (✓ Currently: Dart 3.9.2, Flutter 3.35.6)

**Configuration**:
- Configured via: `claude mcp add dart --scope local -- dart mcp-server`
- Verify status: `claude mcp list`
- Config file: `~/.claude.json` (local scope for this project)

## Important Notes

1. **Project Phase**: Early development - currently only starter template exists
2. **Backend First**: Backend infrastructure (Phases 1-4) should be completed before extensive Flutter work
3. **No Authentication**: MVP is single-user without auth requirements
4. **Docker-based Infrastructure**: All services run in Docker containers for local development
5. **Cost Optimization**: Using free/open-source models where possible (embeddings run locally)