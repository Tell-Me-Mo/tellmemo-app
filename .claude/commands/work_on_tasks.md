MANDATORY WORKFLOW FOR TASK COMPLETION - FOLLOW ALL STEPS

⚠️ CRITICAL RULES:
1. NEVER create .sql migration files - use alembic
2. ALWAYS investigate codebase AND database before implementation
3. USE flutter-code-searcher to understand existing patterns first

STEP 1: INITIAL SCAN (REQUIRED)
Execute these commands:
- cat CHANGELOG-TASKS.md | tail -50  (Read last ~2 weeks of changes)
- cat TASKS-MEETINGS-ASSISTNACE.md                 (Read ALL tasks and general info about the app)
- cat docs/PROACTIVE_MEETING_ASSISTANCE_HLD.md (Understand the entire requirements)

Identify:
- Recent changes in related areas
- Task dependencies and completion status
- Current code patterns and conventions

STEP 2: TASK SELECTION (REQUIRED)
MUST select by priority: P0 then P1 then P2

ANNOUNCE: "Starting Task: [Task Name] - [Task ID]"
EXPLAIN: Why this task was chosen
VERIFY: All dependencies are met

STEP 3: RESEARCH & INVESTIGATION (REQUIRED)

### A. CODEBASE INVESTIGATION (ALWAYS DO THIS FIRST)

USE flutter-code-searcher Agent to:
1. Find existing related implementations
2. Identify current patterns and conventions
3. Locate similar features to use as reference
4. Understand the architecture layers involved

EXAMPLE PROMPTS:
- "Find all existing implementations related to [feature]"
- "Locate how [similar feature] is currently implemented"
- "Search for patterns used in [domain/data/presentation] layer"
- "Find all database interactions for [entity]"

### C. SPECIALIZED AGENT RESEARCH

### flutter-code-searcher Agent
USE WHEN:
- Analyzing existing Flutter/Dart codebase structure
- Finding state management patterns (Provider, Riverpod, Bloc)
- Locating navigation flows and routes
- Searching for platform-specific implementations
- Exploring widget hierarchies
- Finding specific Flutter components or patterns

### General Research Agent
USE WHEN:
- Unknown Flutter packages: "Flutter [package] implementation guide 2025"
- Specific patterns: "Flutter [pattern] best practices with examples"
- Error solutions: "Flutter [specific error] solution"

STEP 4: IMPLEMENTATION (REQUIRED)

### IMPLEMENTATION APPROACH:

For SIMPLE tasks (single file):
- Implement directly following existing patterns

For COMPLEX tasks (multiple files/components):

USE SPECIALIZED AGENTS IN PARALLEL:

For UI/UX Tasks:
- flutter-code-searcher: Find existing patterns to follow
- General agent: Implement the designed component

MUST include:
- All acceptance criteria implementation
- Error handling
- Input validation
- Comments for complex logic
- Proper Clean Architecture separation

STEP 5: UPDATE TASKS-MEETINGS-ASSISTNACE.md (REQUIRED)
Execute for each completed criterion:
- Replace [ ] with [x]
- Add line: Status: COMPLETED - [YYYY-MM-DD HH:MM]
- Note any partial completions

STEP 6: UPDATE CHANGELOG-TASKS.md (REQUIRED)
Add at the TOP under ## [Unreleased]:

### [YYYY-MM-DD]
#### [Added/Changed/Fixed]
- [Task Name]: [What was done]
  - Implementation: [Key technical details]
  - Files: [main files created/modified]

STEP 7: VERIFICATION (REQUIRED)
Execute:
- flutter analyze
- Verify all acceptance criteria are met
- Confirm all files are saved

DO NOT run the app

STEP 8: CODE REVIEW CHECKLIST (REQUIRED)
Before committing, verify ALL items:

### Code Quality:
- [ ] No console.log, print, or debugPrint statements left
- [ ] No commented-out code blocks
- [ ] No TODO comments (unless added to TASKS-MEETINGS-ASSISTNACE.md)
- [ ] No hardcoded values (URLs, credentials, magic numbers)
- [ ] All error messages are user-friendly and specific

### Naming & Conventions:
- [ ] Dart: camelCase for variables/functions, PascalCase for classes
- [ ] SQL: snake_case for tables/columns
- [ ] Consistent with existing codebase patterns
- [ ] Meaningful variable/function names (no x, temp, data)

### Security:
- [ ] No exposed API keys or secrets
- [ ] No sensitive data in logs or error messages
- [ ] Input validation on all user inputs
- [ ] SQL queries use parameterization (no string concatenation)

### Flutter Specific:
- [ ] Used const constructors where possible
- [ ] Disposed controllers/subscriptions properly
- [ ] No setState after dispose
- [ ] Keys used correctly for widget lists

### Clean Code:
- [ ] Functions under 50 lines (extract if longer)
- [ ] No duplicate code (DRY principle)
- [ ] Single responsibility per function/class
- [ ] Proper null safety handling (no ! without null check)

### Final Checks:
- [ ] flutter analyze shows zero issues
- [ ] All imports are used (no unused imports)
- [ ] Code matches acceptance criteria exactly
- [ ] No test/temporary code left

If ANY item fails: FIX before proceeding to commit

STEP 9: COMMIT (REQUIRED)
Execute:
git add .
git commit -m "feat: [Task Name] - [Brief description]

- Implemented [key points]
- Updated TASKS-MEETINGS-ASSISTNACE.md and CHANGELOG-TASKS.md

Task ID: [from GAPS-TASKS-MEETINGS-ASSISTNACE.md]"

VERIFICATION CHECKPOINT:
Before saying complete, confirm:
- Task implemented? 
- TASKS-MEETINGS-ASSISTNACE.md updated?
- CHANGELOG-TASKS.md updated?
- Code analyzed?
- Code review checklist passed?
- Changes committed?

IF ANY STEP BLOCKED:
- Add "Status: BLOCKED - [reason]" to GAPS-TASKS-MEETINGS-ASSISTNACE.md
- Document specific blocker
- Move to next available task

START NOW: Execute Step 1 commands and report findings.