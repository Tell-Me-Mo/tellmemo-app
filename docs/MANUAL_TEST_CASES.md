# TellMeMo - Complete Manual Test Case Scenarios

## Application Overview
**TellMeMo** is an AI-powered Meeting Intelligence System that transforms meetings into searchable knowledge. It supports uploading content, asking questions in plain English, tracking actions, detecting risks, and generating summaries.

**Tech Stack:**
- **Frontend**: Flutter Web (running on port 8100)
- **Backend**: FastAPI + PostgreSQL + Qdrant (running locally)
- **AI**: Claude 3.5 Haiku (LLM), Local embeddings
- **Features**: Multi-tenant, Portfolio → Program → Project hierarchy, RAG search

---

## Table of Contents
1. [Authentication & Onboarding](#1-authentication--onboarding)
2. [Organization Management](#2-organization-management)
3. [Hierarchy Management](#3-hierarchy-management-portfolios--programs--projects)
4. [Project Management](#4-project-management)
5. [Content Upload & Processing](#5-content-upload--processing)
6. [AI Query & Search](#6-ai-query--search-rag)
7. [Summary Generation](#7-summary-generation)
8. [Risks, Tasks & Blockers](#8-risks-tasks--blockers)
9. [Lessons Learned](#9-lessons-learned)
10. [Integrations](#10-integrations)
11. [Notifications & Activities](#11-notifications--activities)
12. [Support Tickets](#12-support-tickets)
13. [Dashboard & Reports](#13-dashboard--reports)
14. [Responsive Design](#14-responsive-design--cross-platform)
15. [Error Handling & Edge Cases](#15-error-handling--edge-cases)

---

## 1. Authentication & Onboarding

### TC-1.1: User Registration (Sign Up)
**Objective**: Verify new user can create an account

**Pre-conditions**:
- Navigate to http://localhost:8100
- Not currently logged in

**Test Steps**:
1. Click "Sign Up" button on landing page
2. Enter email: `testuser@example.com`
3. Enter password: `TestPass123!`
4. Confirm password: `TestPass123!`
5. Enter full name: `Test User`
6. Click "Create Account"

**Expected Results**:
- ✅ Email validation shows error for invalid format
- ✅ Password validation enforces minimum strength
- ✅ Confirm password must match
- ✅ Account created successfully
- ✅ Redirected to organization wizard or dashboard
- ✅ Welcome email sent (check logs if email is configured)

---

### TC-1.2: User Login (Sign In)
**Objective**: Verify existing user can log in

**Pre-conditions**:
- User account exists
- Currently logged out

**Test Steps**:
1. Navigate to http://localhost:8100
2. Click "Sign In"
3. Enter email: `testuser@example.com`
4. Enter password: `TestPass123!`
5. Click "Sign In"

**Expected Results**:
- ✅ Invalid credentials show error message
- ✅ Successful login redirects to dashboard
- ✅ Session persists on page refresh
- ✅ JWT token stored securely
- ✅ User profile shows correct name

---

### TC-1.3: Password Reset
**Objective**: Verify user can reset forgotten password

**Test Steps**:
1. Click "Forgot Password" on sign-in page
2. Enter email: `testuser@example.com`
3. Click "Send Reset Link"
4. Check email for reset link (or check backend logs)
5. Click reset link
6. Enter new password: `NewPass456!`
7. Confirm new password
8. Click "Reset Password"
9. Try logging in with new password

**Expected Results**:
- ✅ Reset email sent confirmation shown
- ✅ Reset link is valid for limited time
- ✅ New password must meet strength requirements
- ✅ Password successfully changed
- ✅ Can log in with new password
- ✅ Old password no longer works

---

### TC-1.4: Change Password (Logged In)
**Objective**: Verify user can change password while logged in

**Pre-conditions**: User is logged in

**Test Steps**:
1. Click profile icon/menu in top-right
2. Select "Change Password"
3. Enter current password
4. Enter new password: `UpdatedPass789!`
5. Confirm new password
6. Click "Update Password"

**Expected Results**:
- ✅ Current password validation required
- ✅ Password updated successfully
- ✅ Success notification shown
- ✅ Session remains active
- ✅ New password works on next login

---

## 2. Organization Management

### TC-2.1: Organization Creation Wizard
**Objective**: Create first organization for new user

**Pre-conditions**:
- User logged in for first time
- No organizations exist

**Test Steps**:
1. Organization wizard should appear automatically
2. Enter organization name: `Acme Corporation`
3. Enter organization description: `Engineering team workspace`
4. Select industry (if applicable)
5. Click "Create Organization"

**Expected Results**:
- ✅ Organization created successfully
- ✅ User is automatically set as owner/admin
- ✅ Redirected to dashboard
- ✅ Organization name appears in header
- ✅ Default organization is set as active

---

### TC-2.2: Invite Team Members
**Objective**: Add members to organization

**Pre-conditions**:
- User is organization owner/admin
- Logged into organization

**Test Steps**:
1. Navigate to Settings → Organization → Members
2. Click "Invite Members"
3. Enter email: `member1@example.com`
4. Select role: `Member` (or `Admin`)
5. Click "Send Invitation"
6. (Optional) Bulk invite via CSV upload

**Expected Results**:
- ✅ Invitation sent successfully
- ✅ Email appears in "Pending Invitations" list
- ✅ Invitation email sent to invitee
- ✅ Bulk CSV upload accepts multiple emails
- ✅ Invalid emails show validation error
- ✅ Can resend invitation
- ✅ Can revoke/cancel invitation

---

### TC-2.3: Accept Invitation
**Objective**: New user accepts organization invitation

**Pre-conditions**:
- Invitation sent to email
- User may or may not have account

**Test Steps**:
1. Check email for invitation link
2. Click "Accept Invitation" link
3. If no account: Sign up with invited email
4. If has account: Log in
5. Confirm joining organization

**Expected Results**:
- ✅ Redirected to create account (if new user)
- ✅ Redirected to login (if existing user)
- ✅ Added to organization as specified role
- ✅ Can access organization workspace
- ✅ Invitation removed from pending list
- ✅ Activity logged in organization feed

---

### TC-2.4: Member Role Management
**Objective**: Change member roles and permissions

**Pre-conditions**:
- User is organization admin
- Organization has multiple members

**Test Steps**:
1. Go to Settings → Organization → Members
2. Find a member in the list
3. Click three-dot menu → "Change Role"
4. Select new role: `Admin` or `Member`
5. Confirm role change
6. Test permissions for that member

**Expected Results**:
- ✅ Role updated successfully
- ✅ Admin role grants full permissions
- ✅ Member role has limited permissions
- ✅ Cannot demote last admin
- ✅ Activity logged
- ✅ Member sees updated permissions immediately

---

### TC-2.5: Remove Member from Organization
**Objective**: Remove a member from organization

**Pre-conditions**:
- User is organization admin
- Member exists in organization

**Test Steps**:
1. Go to Settings → Organization → Members
2. Select member to remove
3. Click three-dot menu → "Remove Member"
4. Confirm removal in dialog
5. Verify member removed

**Expected Results**:
- ✅ Confirmation dialog appears
- ✅ Member removed from list
- ✅ Member loses access to organization
- ✅ Member's projects reassigned or archived
- ✅ Cannot remove yourself if last admin
- ✅ Activity logged

---

### TC-2.6: Switch Between Organizations
**Objective**: User with multiple organizations can switch context

**Pre-conditions**:
- User belongs to 2+ organizations

**Test Steps**:
1. Click organization name in header/top-left
2. View organization switcher dropdown
3. Select different organization
4. Observe dashboard and data change

**Expected Results**:
- ✅ List of all organizations shown
- ✅ Current organization highlighted
- ✅ Switching changes entire app context
- ✅ Dashboard shows new organization data
- ✅ Projects, members, etc. update
- ✅ Multi-tenant isolation verified (no data leakage)

---

## 3. Hierarchy Management (Portfolios → Programs → Projects)

### TC-3.1: Create Portfolio
**Objective**: Create a portfolio (top-level hierarchy)

**Pre-conditions**:
- User logged in
- On Hierarchy/Projects screen

**Test Steps**:
1. Navigate to Projects (Hierarchy) screen
2. Click "+ New Portfolio" (or FAB on mobile)
3. Enter portfolio name: `Digital Transformation`
4. Enter description: `Company-wide digital initiatives`
5. Click "Create"

**Expected Results**:
- ✅ Portfolio created successfully
- ✅ Appears in hierarchy tree view
- ✅ Shows in card view
- ✅ Can be favorited (star icon)
- ✅ Portfolio statistics card shows 0 programs, 0 projects
- ✅ Activity logged

---

### TC-3.2: Create Program Under Portfolio
**Objective**: Create a program within a portfolio

**Pre-conditions**:
- Portfolio exists

**Test Steps**:
1. On Hierarchy screen, find portfolio
2. Click three-dot menu → "Create Program"
3. Enter program name: `Mobile Apps Modernization`
4. Enter description
5. Verify portfolio pre-selected
6. Click "Create"

**Expected Results**:
- ✅ Program created under correct portfolio
- ✅ Hierarchy tree shows nesting
- ✅ Portfolio statistics updated (1 program)
- ✅ Program detail page accessible
- ✅ Can create standalone program (no portfolio)

---

### TC-3.3: Create Project Under Program
**Objective**: Create a project within a program

**Pre-conditions**:
- Portfolio and Program exist

**Test Steps**:
1. Navigate to program detail OR use quick action
2. Click "Create Project"
3. Enter project name: `iOS App Redesign`
4. Enter description: `Redesign iOS app with new branding`
5. Select status: `Active`
6. Assign portfolio (pre-filled if creating from program)
7. Assign program (pre-filled if creating from program)
8. Add tags (optional)
9. Click "Create Project"

**Expected Results**:
- ✅ Project created under program → portfolio
- ✅ Project appears in hierarchy
- ✅ Project detail page opens
- ✅ Statistics updated
- ✅ Can create standalone project (no program/portfolio)
- ✅ Can assign to portfolio only (no program)

---

### TC-3.4: Move Project Between Programs
**Objective**: Reassign project to different program

**Pre-conditions**:
- Multiple programs exist
- Project exists in one program

**Test Steps**:
1. On Hierarchy screen, find project
2. Click three-dot menu → "Move"
3. Select destination program
4. Confirm move

**Expected Results**:
- ✅ Project moved to new program
- ✅ Hierarchy updated
- ✅ Statistics updated for both programs
- ✅ Cannot move to different organization's program
- ✅ Activity logged

---

### TC-3.5: Move Program Between Portfolios
**Objective**: Reassign program to different portfolio

**Pre-conditions**:
- Multiple portfolios exist
- Program exists in one portfolio

**Test Steps**:
1. Find program in hierarchy
2. Click three-dot menu → "Move"
3. Select destination portfolio
4. Confirm move

**Expected Results**:
- ✅ Program moved to new portfolio
- ✅ All child projects move with it
- ✅ Statistics updated
- ✅ Can move to no portfolio (standalone)
- ✅ Activity logged

---

### TC-3.6: Delete Portfolio (with impact analysis)
**Objective**: Delete portfolio and handle child items

**Pre-conditions**:
- Portfolio with programs/projects exists

**Test Steps**:
1. Select portfolio
2. Click three-dot menu → "Delete"
3. View impact analysis dialog
4. See warning: "This will affect X programs and Y projects"
5. Choose action:
   - Archive all child items
   - Move child items to another portfolio
   - Permanently delete all
6. Confirm deletion

**Expected Results**:
- ✅ Impact analysis shows accurate counts
- ✅ Confirmation required for deletion
- ✅ Child items handled per user choice
- ✅ Cannot delete if contains active projects (without confirmation)
- ✅ Activity logged
- ✅ Hierarchy updates immediately

---

### TC-3.7: Search and Filter Hierarchy
**Objective**: Find items in hierarchy using search and filters

**Test Steps**:
1. On Hierarchy screen, use search bar
2. Enter search query: `Mobile`
3. Observe filtered results
4. Use type filters: All / Portfolios / Programs / Projects
5. Toggle favorites filter (star icon)
6. Switch view mode: Tree view ↔ Card view

**Expected Results**:
- ✅ Search filters by name and description
- ✅ Type filters work correctly
- ✅ Favorites filter shows only starred items
- ✅ Tree view shows hierarchy structure
- ✅ Card view shows flat list
- ✅ Search works in both views
- ✅ Can clear search and filters

---

### TC-3.8: Bulk Delete Items
**Objective**: Delete multiple hierarchy items at once

**Pre-conditions**:
- Multiple items exist

**Test Steps**:
1. On Hierarchy screen
2. (If available) Select multiple items via checkboxes
3. Click "Bulk Delete" action
4. Review impact analysis
5. Confirm deletion

**Expected Results**:
- ✅ Can select multiple items
- ✅ Impact analysis shows total counts
- ✅ All selected items deleted
- ✅ Child items handled appropriately
- ✅ Cannot bulk delete across organizations

---

## 4. Project Management

### TC-4.1: Create Standalone Project
**Objective**: Create a project without portfolio/program

**Pre-conditions**: User logged in

**Test Steps**:
1. Navigate to Hierarchy screen
2. Click "+ New Project"
3. Enter project name: `Q1 Planning Initiative`
4. Enter description: `Strategic planning for Q1 2025`
5. Set status: `Active`
6. Leave portfolio and program blank
7. Click "Create"

**Expected Results**:
- ✅ Project created at root level
- ✅ Appears in hierarchy (no parent)
- ✅ Project detail page opens
- ✅ Can add members later
- ✅ Activity logged

---

### TC-4.2: Edit Project Details
**Objective**: Update project information

**Pre-conditions**: Project exists

**Test Steps**:
1. Navigate to project detail page
2. Click "Edit" button (or three-dot menu → Edit)
3. Update name: `Q1 2025 Planning Initiative`
4. Update description
5. Change status: `Active` → `On Hold` → `Active`
6. Update tags
7. Click "Save Changes"

**Expected Results**:
- ✅ Changes saved successfully
- ✅ Project detail updated
- ✅ Hierarchy shows updated name
- ✅ Activity logged with changes
- ✅ Last updated timestamp updated

---

### TC-4.3: Add Members to Project
**Objective**: Assign team members to project

**Pre-conditions**:
- Project exists
- Organization has members

**Test Steps**:
1. On project detail page
2. Go to "Members" tab
3. Click "Add Member"
4. Search for member by name/email
5. Select role: `Owner`, `Editor`, or `Viewer`
6. Click "Add"
7. Repeat for multiple members

**Expected Results**:
- ✅ Member added to project
- ✅ Member can see project in their list
- ✅ Role determines permissions (edit vs view only)
- ✅ Owner can manage members
- ✅ Activity logged

---

### TC-4.4: Remove Member from Project
**Objective**: Unassign member from project

**Pre-conditions**: Project has members

**Test Steps**:
1. On project detail → Members tab
2. Find member to remove
3. Click three-dot menu → "Remove"
4. Confirm removal

**Expected Results**:
- ✅ Member removed from project
- ✅ Member loses access to project content
- ✅ Cannot remove last owner
- ✅ Member's tasks reassigned (or flagged)
- ✅ Activity logged

---

### TC-4.5: Archive Project
**Objective**: Archive completed or inactive project

**Pre-conditions**: Project with status `Active` or `Completed`

**Test Steps**:
1. On project detail page
2. Click three-dot menu → "Archive"
3. Confirm archival
4. Observe project status change

**Expected Results**:
- ✅ Project marked as archived
- ✅ Removed from active project lists (unless "Include Archived" toggled)
- ✅ Project detail still accessible
- ✅ Cannot upload new content to archived project
- ✅ Can restore/unarchive project
- ✅ Activity logged

---

### TC-4.6: Delete Project
**Objective**: Permanently delete project

**Pre-conditions**: Project exists (preferably archived)

**Test Steps**:
1. Find project in hierarchy
2. Click three-dot menu → "Delete"
3. View confirmation dialog with warning
4. Type project name to confirm (if required)
5. Click "Permanently Delete"

**Expected Results**:
- ✅ Confirmation with strong warning
- ✅ Project deleted permanently
- ✅ All content, summaries, tasks deleted
- ✅ Cannot be undone
- ✅ Activity logged
- ✅ Member notifications sent (if configured)

---

## 5. Content Upload & Processing

### TC-5.1: Upload Meeting Transcript (Text)
**Objective**: Upload a meeting transcript as text

**Pre-conditions**:
- Project exists
- User has edit permission

**Test Steps**:
1. Navigate to project detail OR use dashboard "Upload" action
2. Click "Upload Content" or "+" FAB
3. Select content type: `Meeting Transcript`
4. Select project (if not pre-selected)
5. Enter title: `Sprint Planning - Jan 15, 2025`
6. Paste transcript text:
   ```
   Team: John, Sarah, Mike
   Date: Jan 15, 2025

   Discussion:
   - Q1 OKRs review
   - Sprint 1 planning
   - Resource allocation

   Action Items:
   - John: Finalize API design by Jan 20
   - Sarah: Prepare mockups for review
   - Mike: Set up development environment
   ```
7. Set date: `2025-01-15`
8. Click "Upload"

**Expected Results**:
- ✅ Upload starts processing (loading indicator or job created)
- ✅ Content appears in Documents list
- ✅ Processing job created (check Jobs screen)
- ✅ AI extracts action items, participants, date
- ✅ Content searchable via AI Query
- ✅ Processing notification received
- ✅ Can generate summary from this content

---

### TC-5.2: Upload Audio File for Transcription
**Objective**: Upload audio file and get automatic transcription

**Pre-conditions**:
- Project exists
- Transcription service configured

**Test Steps**:
1. Click "Upload Content" → "Audio/Recording"
2. Select project
3. Click "Choose File" and select audio: `meeting.mp3` (or .wav, .m4a)
4. Enter title: `Product Roadmap Discussion`
5. Select language: `Auto-detect` or specific language
6. Set date
7. Click "Upload & Transcribe"

**Expected Results**:
- ✅ File uploaded successfully
- ✅ File size validated (rejects >100MB or configured limit)
- ✅ Supported formats: MP3, WAV, M4A, FLAC, OGG
- ✅ Transcription job created
- ✅ Progress shown via websocket or polling
- ✅ Transcribed text appears in Documents
- ✅ Can edit transcription after processing
- ✅ Audio file stored (if configured)

---

### TC-5.3: Upload Email Content
**Objective**: Upload email thread as content

**Pre-conditions**: Project exists

**Test Steps**:
1. Click "Upload Content" → "Email"
2. Select project
3. Paste email content (including headers, thread):
   ```
   From: john@company.com
   To: team@company.com
   Subject: RE: Q1 Budget Approval
   Date: Jan 10, 2025

   Hi team,

   The budget has been approved. We can proceed with...
   ```
4. Set title: `Q1 Budget Approval Email Thread`
5. Set date
6. Click "Upload"

**Expected Results**:
- ✅ Email parsed correctly
- ✅ Sender, recipients extracted
- ✅ Subject used as fallback title
- ✅ Email content searchable
- ✅ AI can analyze email threads
- ✅ Activity logged

---

### TC-5.4: View Content Processing Status
**Objective**: Monitor content processing jobs

**Pre-conditions**: Content uploaded

**Test Steps**:
1. After uploading content, navigate to "Jobs" or "Activity"
2. View processing job
3. Observe status: `Pending` → `Processing` → `Completed` or `Failed`
4. View job progress percentage (if available)
5. View websocket real-time updates

**Expected Results**:
- ✅ Job appears immediately after upload
- ✅ Status updates in real-time
- ✅ Shows progress: Uploading → Transcribing → Extracting → Embedding → Complete
- ✅ Error jobs show error message
- ✅ Can cancel in-progress job
- ✅ Completed jobs show duration

---

### TC-5.5: AI-Based Project Matching
**Objective**: Upload content without selecting project (AI selects)

**Pre-conditions**: Multiple projects exist

**Test Steps**:
1. Click "Upload Content"
2. Leave project field blank
3. Enter title: `Engineering Team Standup`
4. Paste transcript mentioning specific project keywords
5. Click "Upload"

**Expected Results**:
- ✅ AI analyzes content
- ✅ Suggests most relevant project
- ✅ Shows confidence score
- ✅ User can accept or change suggestion
- ✅ Content assigned to selected project

---

### TC-5.6: Bulk Upload (Multiple Files)
**Objective**: Upload multiple audio files or documents at once

**Pre-conditions**: Project exists

**Test Steps**:
1. Click "Upload Content"
2. Select multiple files (if file picker allows)
3. Assign to same project
4. Click "Upload All"

**Expected Results**:
- ✅ All files queued for upload
- ✅ Multiple jobs created
- ✅ Can track each job separately
- ✅ Progress shown for batch
- ✅ Notification when all complete

---

### TC-5.7: Record Meeting (Real-time)
**Objective**: Record audio directly in the app

**Pre-conditions**:
- Browser supports microphone access
- Permission granted

**Test Steps**:
1. Click "Record Meeting" button
2. Grant microphone permission (if prompted)
3. Select project
4. Click "Start Recording"
5. Speak into microphone for 1-2 minutes
6. Click "Stop Recording"
7. Review recording
8. Click "Upload & Transcribe"

**Expected Results**:
- ✅ Microphone access requested
- ✅ Recording indicator shown (red dot, timer)
- ✅ Can pause and resume recording
- ✅ Audio preview before upload
- ✅ Can discard recording
- ✅ Recording uploaded and transcribed
- ✅ Works on mobile and desktop

---

## 6. AI Query & Search (RAG)

### TC-6.1: Ask AI at Organization Level
**Objective**: Query entire organization's knowledge base

**Pre-conditions**:
- Content uploaded to multiple projects
- RAG system operational

**Test Steps**:
1. Click "Ask AI" FAB on dashboard or hierarchy screen
2. Enter query: `What are the main risks across all projects?`
3. Submit query
4. View AI response

**Expected Results**:
- ✅ AI analyzes all organization content
- ✅ Response includes relevant excerpts with sources
- ✅ Sources link to original documents
- ✅ Response time < 5 seconds
- ✅ Shows up to 10 source documents
- ✅ Conversation saved in history

---

### TC-6.2: Ask AI at Project Level
**Objective**: Query specific project's content

**Pre-conditions**:
- Project has uploaded content
- At least 2-3 meeting transcripts

**Test Steps**:
1. On project detail page
2. Click "Ask AI" button
3. Enter query: `What action items were assigned to Sarah?`
4. Submit query
5. Observe response

**Expected Results**:
- ✅ AI searches only project content
- ✅ Accurate answer with specific action items
- ✅ Sources are from current project only
- ✅ Multi-tenant isolation verified
- ✅ Follow-up questions maintain context

---

### TC-6.3: Ask AI at Portfolio/Program Level
**Objective**: Query portfolio or program scope

**Pre-conditions**:
- Portfolio/Program has projects with content

**Test Steps**:
1. Navigate to Portfolio or Program detail page
2. Click "Ask AI"
3. Enter query: `Summarize progress across all projects in this portfolio`
4. Submit

**Expected Results**:
- ✅ AI searches all child projects
- ✅ Aggregates insights
- ✅ Sources from multiple projects shown
- ✅ Respects hierarchy boundaries

---

### TC-6.4: Conversation Follow-up Questions
**Objective**: Maintain conversation context for follow-ups

**Pre-conditions**:
- Initial query submitted

**Test Steps**:
1. Ask initial question: `What were the main topics discussed in January?`
2. View response
3. Ask follow-up: `What action items came out of those discussions?`
4. Ask another: `Who was responsible for those items?`

**Expected Results**:
- ✅ AI understands context from previous questions
- ✅ Follow-ups reference earlier responses
- ✅ Conversation history visible
- ✅ Can view past conversations
- ✅ Conversation title auto-generated

---

### TC-6.5: Query with Date Filters
**Objective**: Filter search by date range

**Pre-conditions**: Content from different dates exists

**Test Steps**:
1. Click "Ask AI"
2. Enter query: `What risks were identified?`
3. Use date picker to filter: `Jan 1, 2025 - Jan 31, 2025`
4. Submit query

**Expected Results**:
- ✅ Results filtered to date range
- ✅ Only content from January shown
- ✅ Sources show dates
- ✅ Can clear date filter

---

### TC-6.6: Save and Revisit Conversation
**Objective**: Access conversation history

**Pre-conditions**: Previous conversations exist

**Test Steps**:
1. Navigate to Queries/Conversations screen
2. View list of past conversations
3. Click on a conversation
4. View full conversation history
5. Continue conversation with new query

**Expected Results**:
- ✅ Conversations sorted by recent
- ✅ Conversation titles descriptive
- ✅ Full history preserved
- ✅ Can edit conversation title
- ✅ Can delete conversation
- ✅ Conversations scoped to projects/organization

---

### TC-6.7: Query Suggestions
**Objective**: Use pre-built query suggestions

**Pre-conditions**: On Ask AI panel

**Test Steps**:
1. Open Ask AI panel
2. View query suggestions (if displayed)
3. Click a suggestion: `What action items are overdue?`
4. Observe auto-filled query
5. Submit

**Expected Results**:
- ✅ Suggestions relevant to context
- ✅ Clicking fills query field
- ✅ Can edit before submitting
- ✅ Suggestions update based on project type

---

## 7. Summary Generation

### TC-7.1: Generate Meeting Summary
**Objective**: Generate AI summary of a single meeting

**Pre-conditions**:
- Meeting transcript uploaded
- Content processed

**Test Steps**:
1. Navigate to Documents screen or project detail
2. Find meeting document
3. Click three-dot menu → "Generate Summary"
4. Select format: `General`, `Executive`, or `Technical`
5. Select date range (default: meeting date)
6. Click "Generate"

**Expected Results**:
- ✅ Summary generation job starts
- ✅ Progress shown via websocket
- ✅ Summary includes: Overview, Key Points, Action Items, Decisions, Risks
- ✅ Summary saved to Summaries list
- ✅ Can regenerate with different format
- ✅ Notification sent on completion

---

### TC-7.2: Generate Project Summary
**Objective**: Generate summary across all project content

**Pre-conditions**:
- Project has 3+ meeting transcripts

**Test Steps**:
1. On project detail page
2. Click "Generate Summary" button
3. Select summary type: `Project Summary`
4. Select date range: `Last 7 days`, `Last 30 days`, or custom
5. Select format: `General`, `Executive`, `Technical`
6. Click "Generate"

**Expected Results**:
- ✅ AI aggregates all project content
- ✅ Summary includes: Progress, Risks, Action Items, Blockers, Decisions
- ✅ References multiple meetings
- ✅ Formatted per selected type
- ✅ Can download as PDF/Markdown
- ✅ Activity logged

---

### TC-7.3: Generate Program/Portfolio Summary
**Objective**: Generate high-level summary across hierarchy

**Pre-conditions**:
- Portfolio/Program has projects with content

**Test Steps**:
1. Navigate to Portfolio or Program detail
2. Click "Generate Summary"
3. Select date range
4. Select format: `Executive` (most common for portfolio)
5. Click "Generate"

**Expected Results**:
- ✅ Summary aggregates all child projects
- ✅ High-level overview of portfolio/program health
- ✅ Lists top risks, blockers, achievements
- ✅ Can export and share
- ✅ Takes longer (more content)

---

### TC-7.4: WebSocket Real-time Summary Streaming
**Objective**: View summary generation in real-time

**Pre-conditions**: Summary generation initiated

**Test Steps**:
1. Start summary generation
2. Observe real-time streaming dialog
3. Watch summary build section by section
4. See progress: Overview → Key Points → Action Items → etc.

**Expected Results**:
- ✅ Websocket connection established
- ✅ Summary text streams progressively
- ✅ Can stop generation mid-stream
- ✅ Partial summary saved if stopped
- ✅ Connection errors handled gracefully

---

### TC-7.5: View Summaries List
**Objective**: Browse all generated summaries

**Pre-conditions**: Multiple summaries generated

**Test Steps**:
1. Navigate to Summaries screen
2. View list of all summaries
3. Filter by:
   - Project
   - Type (Meeting, Project, Weekly)
   - Format (General, Executive, Technical)
   - Date range
4. Click on a summary to view details

**Expected Results**:
- ✅ Summaries sorted by newest first
- ✅ Shows summary type, project, date
- ✅ Filtering works correctly
- ✅ Can search summaries
- ✅ "NEW" badge on recent summaries

---

### TC-7.6: Summary Detail View
**Objective**: View and interact with summary

**Pre-conditions**: Summary exists

**Test Steps**:
1. Click on a summary from list
2. View full summary content
3. Scroll through sections
4. Click "Export" button
5. Choose format: PDF or Markdown
6. Click "Delete" (if needed)

**Expected Results**:
- ✅ All sections rendered correctly
- ✅ Action items, risks, decisions formatted
- ✅ Can export to PDF (formatted)
- ✅ Can export to Markdown (.md file)
- ✅ Can copy summary text
- ✅ Can regenerate summary
- ✅ Can delete summary (with confirmation)

---

### TC-7.7: AI Insights in Summaries
**Objective**: Verify AI extracts insights correctly

**Pre-conditions**: Summary generated from rich content

**Test Steps**:
1. Review summary detail
2. Check that AI identified:
   - Action items with assignees
   - Key decisions made
   - Risks and blockers
   - Important dates
   - Participants
3. Compare to original content

**Expected Results**:
- ✅ Action items accurate
- ✅ Assignees correctly identified
- ✅ Decisions clearly stated
- ✅ Risks properly categorized
- ✅ No hallucinations (all info from sources)

---

## 8. Risks, Tasks & Blockers

### TC-8.1: View Risks Aggregation Screen
**Objective**: Access organization-wide risks dashboard

**Pre-conditions**:
- Multiple projects with risks

**Test Steps**:
1. Navigate to Risks screen (from sidebar or menu)
2. View aggregated risks from all projects
3. Filter by:
   - Severity (Low, Medium, High, Critical)
   - Status (Identified, Mitigating, Resolved, Accepted)
   - Project
4. Sort by date, severity, or project

**Expected Results**:
- ✅ Risks from all projects shown
- ✅ Color-coded by severity
- ✅ Can filter and sort
- ✅ Shows risk count per project
- ✅ Kanban view available (by status)
- ✅ List/Compact view toggle

---

### TC-8.2: Create Risk Manually
**Objective**: Add a risk to a project

**Pre-conditions**: Project exists

**Test Steps**:
1. On Risks screen or project detail
2. Click "+ Create Risk"
3. Enter risk title: `API performance degradation`
4. Enter description
5. Select severity: `High`
6. Select status: `Identified`
7. Assign to user
8. Set mitigation plan
9. Click "Create"

**Expected Results**:
- ✅ Risk created successfully
- ✅ Appears in risks list
- ✅ Assigned user notified
- ✅ Activity logged
- ✅ Can edit risk later

---

### TC-8.3: Update Risk Status
**Objective**: Track risk mitigation progress

**Pre-conditions**: Risk exists

**Test Steps**:
1. Find risk in list
2. Click on risk to open detail OR use quick-edit
3. Change status: `Identified` → `Mitigating` → `Resolved`
4. Update mitigation notes
5. Save changes

**Expected Results**:
- ✅ Status updated
- ✅ Resolved date auto-set when marked Resolved
- ✅ Activity logged
- ✅ Assigned user notified
- ✅ Risk color updated

---

### TC-8.4: Bulk Update Risks
**Objective**: Update multiple risks at once

**Pre-conditions**: Multiple risks exist

**Test Steps**:
1. On Risks screen
2. Select multiple risks (checkboxes)
3. Click "Bulk Update"
4. Choose action:
   - Change severity
   - Change status
   - Reassign
   - Delete
5. Confirm changes

**Expected Results**:
- ✅ All selected risks updated
- ✅ Confirmation dialog shown
- ✅ Activity logged for each
- ✅ Cannot mix incompatible actions

---

### TC-8.5: Export Risks
**Objective**: Export risks report

**Pre-conditions**: Risks exist

**Test Steps**:
1. On Risks screen
2. Apply filters (optional)
3. Click "Export" button
4. Select format: `CSV`, `Excel`, or `PDF`
5. Click "Download"

**Expected Results**:
- ✅ Export file generated
- ✅ All filtered risks included
- ✅ CSV has proper headers
- ✅ Excel formatted with sheets
- ✅ PDF formatted report

---

### TC-8.6: View Tasks Aggregation Screen
**Objective**: Access organization-wide tasks dashboard

**Pre-conditions**: Multiple projects with tasks

**Test Steps**:
1. Navigate to Tasks screen
2. View all tasks across projects
3. Filter by:
   - Status (To Do, In Progress, Done)
   - Priority (Low, Medium, High)
   - Assigned to me
   - Due date
4. Group by: Project, Status, Assignee, Priority

**Expected Results**:
- ✅ All tasks shown
- ✅ Grouping works correctly
- ✅ "Assigned to Me" shows only my tasks
- ✅ Overdue tasks highlighted
- ✅ Kanban view available (by status)

---

### TC-8.7: Create Task (AI-Extracted vs Manual)
**Objective**: Add task to project

**Pre-conditions**: Project exists

**Test Steps**:
1. Navigate to Tasks screen or project detail
2. Click "+ Create Task"
3. Enter task title: `Update API documentation`
4. Enter description
5. Select priority: `Medium`
6. Assign to user
7. Set due date
8. Click "Create"

**Expected Results**:
- ✅ Task created successfully
- ✅ AI-extracted tasks auto-created from meetings
- ✅ Manual tasks also supported
- ✅ Assigned user notified
- ✅ Can link task to meeting (source)
- ✅ Activity logged

---

### TC-8.8: Update Task Status
**Objective**: Track task completion

**Pre-conditions**: Task exists

**Test Steps**:
1. Find task in list
2. Drag to "In Progress" column (if Kanban) OR
3. Click on task → Change status to `In Progress`
4. Add progress notes
5. When complete, change to `Done`

**Expected Results**:
- ✅ Status updated
- ✅ Completion date auto-set
- ✅ Activity logged
- ✅ Assignee notified
- ✅ Can reopen task if needed

---

### TC-8.9: Create and Manage Blockers
**Objective**: Track project blockers

**Pre-conditions**: Project exists

**Test Steps**:
1. On project detail → Blockers tab
2. Click "+ Add Blocker"
3. Enter blocker: `Waiting for legal approval`
4. Add description and impact
5. Assign resolver
6. Click "Create"
7. Later: Mark as `Resolved` when unblocked

**Expected Results**:
- ✅ Blocker created
- ✅ Appears in blockers list
- ✅ Resolver notified
- ✅ Can link to related tasks
- ✅ Resolution date tracked
- ✅ Activity logged

---

## 9. Lessons Learned

### TC-9.1: View Lessons Learned Screen
**Objective**: Access organization-wide lessons dashboard

**Pre-conditions**: Lessons exist in projects

**Test Steps**:
1. Navigate to Lessons Learned screen
2. View all lessons across projects
3. Filter by:
   - Category (Technical, Process, Communication, etc.)
   - Type (Success, Challenge, Best Practice)
   - Impact (Low, Medium, High)
   - Project
4. Search lessons by keyword

**Expected Results**:
- ✅ All lessons shown
- ✅ Filtering works
- ✅ Search matches title and description
- ✅ Compact and detailed view toggle
- ✅ Color-coded by category

---

### TC-9.2: AI-Extracted Lessons from Meetings
**Objective**: Verify AI auto-extracts lessons

**Pre-conditions**:
- Meeting uploaded with retrospective content

**Test Steps**:
1. Upload meeting with retrospective keywords:
   ```
   What went well:
   - Team collaboration was excellent
   - Fast deployment pipeline saved time

   What to improve:
   - Need better error logging
   - Testing coverage too low
   ```
2. Wait for processing
3. Navigate to Lessons Learned
4. Find auto-extracted lessons

**Expected Results**:
- ✅ AI identifies lessons from content
- ✅ Categorizes as Success or Challenge
- ✅ Assigns appropriate category
- ✅ Links to source meeting
- ✅ Confidence score shown
- ✅ Can edit or delete AI-generated lessons

---

### TC-9.3: Create Lesson Manually
**Objective**: Add lesson learned manually

**Pre-conditions**: Project exists

**Test Steps**:
1. On Lessons screen or project detail
2. Click "+ Add Lesson"
3. Enter title: `API versioning strategy worked well`
4. Enter description
5. Select category: `Technical`
6. Select type: `Best Practice`
7. Select impact: `High`
8. Add tags (optional)
9. Click "Create"

**Expected Results**:
- ✅ Lesson created
- ✅ Appears in list
- ✅ Activity logged
- ✅ Can share with team

---

### TC-9.4: Edit and Update Lesson
**Objective**: Modify existing lesson

**Pre-conditions**: Lesson exists

**Test Steps**:
1. Find lesson in list
2. Click to open detail
3. Click "Edit"
4. Update title, description, category, or type
5. Save changes

**Expected Results**:
- ✅ Changes saved
- ✅ Last updated timestamp updated
- ✅ Activity logged
- ✅ Can revert to AI-generated (if applicable)

---

### TC-9.5: Export Lessons Report
**Objective**: Export lessons for sharing

**Pre-conditions**: Multiple lessons exist

**Test Steps**:
1. On Lessons screen
2. Apply filters (e.g., Type = Best Practice)
3. Click "Export"
4. Select format: `PDF` or `CSV`
5. Download file

**Expected Results**:
- ✅ Export includes filtered lessons
- ✅ PDF formatted nicely
- ✅ CSV includes all fields
- ✅ Can share with stakeholders

---

## 10. Integrations

### TC-10.1: View Integrations Screen
**Objective**: Access available integrations

**Pre-conditions**: User is admin

**Test Steps**:
1. Navigate to Integrations screen (Settings → Integrations)
2. View list of available integrations:
   - Fireflies (meeting transcription)
   - Transcription Service (audio → text)
   - AI Brain (custom AI config)
3. Check connection status for each

**Expected Results**:
- ✅ All integration types shown
- ✅ Status: Connected, Not Connected, or Error
- ✅ Can filter by status
- ✅ Last sync time shown

---

### TC-10.2: Connect Fireflies Integration
**Objective**: Integrate Fireflies for auto-transcript sync

**Pre-conditions**:
- User is admin
- Has Fireflies API key

**Test Steps**:
1. On Integrations screen
2. Find "Fireflies" card
3. Click "Connect" or "Configure"
4. Enter API key
5. Enter Fireflies workspace URL (if needed)
6. Select default project for synced meetings
7. Enable auto-sync toggle
8. Click "Save" or "Test Connection"
9. Verify connection successful

**Expected Results**:
- ✅ Connection test succeeds
- ✅ Status changes to "Connected"
- ✅ Activity logged
- ✅ Can view sync settings
- ✅ Webhook configured (if supported)

---

### TC-10.3: Fireflies Auto-Sync Webhook
**Objective**: Receive meeting transcripts automatically from Fireflies

**Pre-conditions**:
- Fireflies connected
- Webhook configured

**Test Steps**:
1. Have a meeting recorded in Fireflies
2. Wait for Fireflies to complete transcription
3. Fireflies sends webhook to TellMeMo
4. Check Documents screen for new transcript
5. Verify transcript content

**Expected Results**:
- ✅ Transcript received automatically
- ✅ Appears in selected project
- ✅ Title, date, participants extracted
- ✅ Processing begins immediately
- ✅ Notification sent
- ✅ Activity logged

---

### TC-10.4: Test Integration Connection
**Objective**: Validate integration credentials

**Pre-conditions**: Integration configured

**Test Steps**:
1. On Integrations screen
2. Find connected integration
3. Click "Test Connection"
4. Wait for test to complete

**Expected Results**:
- ✅ Test sends request to external API
- ✅ Success message if valid
- ✅ Error message if invalid (with details)
- ✅ Can re-configure credentials

---

### TC-10.5: Disconnect Integration
**Objective**: Remove integration

**Pre-conditions**: Integration connected

**Test Steps**:
1. On Integrations screen
2. Find integration to disconnect
3. Click three-dot menu → "Disconnect"
4. Confirm disconnection

**Expected Results**:
- ✅ Confirmation dialog shown
- ✅ Integration disconnected
- ✅ API keys removed
- ✅ Webhook disabled
- ✅ Status changes to "Not Connected"
- ✅ Activity logged

---

### TC-10.6: Configure Transcription Service
**Objective**: Set up audio transcription integration

**Pre-conditions**: User is admin

**Test Steps**:
1. On Integrations screen
2. Find "Transcription Service"
3. Click "Configure"
4. Select provider: `Whisper` (local) or `Salad` (cloud)
5. Enter API key (if Salad)
6. Click "Save"

**Expected Results**:
- ✅ Configuration saved
- ✅ Test transcription works
- ✅ Audio uploads now use this service
- ✅ Can switch providers

---

### TC-10.7: Sync Integration Data
**Objective**: Manually trigger data sync

**Pre-conditions**: Integration connected

**Test Steps**:
1. On Integrations screen
2. Find connected integration
3. Click "Sync Now"
4. Wait for sync to complete
5. Check Documents for new data

**Expected Results**:
- ✅ Sync job started
- ✅ Progress shown
- ✅ New data imported
- ✅ Last sync time updated
- ✅ Notification on completion

---

## 11. Notifications & Activities

### TC-11.1: View Notifications Center
**Objective**: Access all notifications

**Pre-conditions**: User has notifications

**Test Steps**:
1. Click notification bell icon in header
2. View notification dropdown or full-screen panel
3. Observe unread count badge
4. Scroll through notifications

**Expected Results**:
- ✅ Recent notifications shown (newest first)
- ✅ Unread count accurate
- ✅ Notification types: Upload Complete, Task Assigned, Member Added, etc.
- ✅ Click notification to view related item
- ✅ Can mark individual as read
- ✅ Can mark all as read

---

### TC-11.2: Real-time Notification Toast
**Objective**: Receive in-app notifications

**Pre-conditions**:
- App open
- WebSocket connection active

**Test Steps**:
1. Have another user (or trigger yourself):
   - Assign you a task
   - Upload content to your project
   - Add you to a project
2. Observe notification toast in app

**Expected Results**:
- ✅ Toast appears in top-right (or configured position)
- ✅ Shows icon, title, message
- ✅ Auto-dismisses after 5 seconds (or configured time)
- ✅ Can click to view item
- ✅ Can dismiss manually
- ✅ Multiple toasts stack

---

### TC-11.3: Notification Types Coverage
**Objective**: Verify all notification types work

**Test Steps**:
Trigger each type and verify:
1. **Task Assigned**: Assign task to user
2. **Task Completed**: Complete a task
3. **Upload Complete**: Upload finishes processing
4. **Summary Ready**: Summary generation completes
5. **Member Added**: Add member to project
6. **Invitation Sent**: Send org invitation
7. **Risk Created**: New risk added
8. **Comment Added**: Someone comments on ticket

**Expected Results**:
- ✅ All types generate notifications
- ✅ Notification content accurate
- ✅ Links to correct item
- ✅ Can disable specific types in settings (if available)

---

### TC-11.4: View Activity Feed (Project)
**Objective**: See project activity timeline

**Pre-conditions**: Project with activity

**Test Steps**:
1. Navigate to project detail
2. Go to "Activity" tab
3. View chronological activity feed
4. Filter by:
   - Activity type (Upload, Summary, Task, etc.)
   - Date range
   - User
5. Click activity to view detail

**Expected Results**:
- ✅ All project activities shown
- ✅ Sorted by newest first
- ✅ Shows icon, user, action, timestamp
- ✅ Filtering works
- ✅ Can load more (pagination)
- ✅ Relative timestamps (e.g., "2 hours ago")

---

### TC-11.5: Dashboard Activity Timeline
**Objective**: See recent activity across organization

**Pre-conditions**: Multiple projects with activity

**Test Steps**:
1. On dashboard
2. Find "Activity Timeline" widget (right panel on desktop)
3. View recent activity across all projects
4. Click activity to navigate

**Expected Results**:
- ✅ Shows activity from all projects
- ✅ Limited to recent (e.g., last 8 items)
- ✅ Can click to view full activity feed
- ✅ Real-time updates (if websocket)

---

### TC-11.6: Archive and Delete Notifications
**Objective**: Manage notification list

**Pre-conditions**: Multiple notifications exist

**Test Steps**:
1. Open notifications center
2. Find a notification
3. Click archive icon (if available)
4. Notification moved to archived
5. Delete a notification (if allowed)

**Expected Results**:
- ✅ Archived notifications hidden from main list
- ✅ Can view archived (toggle or separate tab)
- ✅ Deleted notifications removed permanently
- ✅ Unread count excludes archived

---

## 12. Support Tickets

### TC-12.1: Create Support Ticket
**Objective**: Submit a support ticket

**Pre-conditions**: User logged in

**Test Steps**:
1. Click "Support" button (usually in bottom-right corner)
2. Click "+ New Ticket"
3. Enter subject: `Cannot upload large audio files`
4. Select type: `Bug` (or Feature Request, Question, Other)
5. Select priority: `High`
6. Enter description with details
7. (Optional) Upload screenshot or file attachment
8. Click "Submit"

**Expected Results**:
- ✅ Ticket created successfully
- ✅ Ticket assigned ID
- ✅ Admin/support team notified
- ✅ Confirmation shown to user
- ✅ Can view ticket in "My Tickets"

---

### TC-12.2: View My Tickets
**Objective**: See all user's submitted tickets

**Pre-conditions**: User has created tickets

**Test Steps**:
1. Click "Support" button
2. View "My Tickets" tab
3. Filter by:
   - Status (Open, In Progress, Resolved, Closed)
   - Type
   - Priority
4. Click on ticket to view details

**Expected Results**:
- ✅ All user's tickets shown
- ✅ Sorted by newest first
- ✅ Shows status badge
- ✅ Filtering works
- ✅ Can search tickets

---

### TC-12.3: Add Comment to Ticket
**Objective**: Communicate on ticket thread

**Pre-conditions**: Ticket exists

**Test Steps**:
1. Open ticket detail
2. Scroll to comments section
3. Enter comment: `I tried the suggested fix but still seeing the issue`
4. (Optional) Upload screenshot
5. Click "Post Comment"

**Expected Results**:
- ✅ Comment added to ticket
- ✅ Timestamp shown
- ✅ Assignee/support notified
- ✅ Can edit own comment (if allowed)
- ✅ Can add multiple comments

---

### TC-12.4: Ticket Status Updates (Admin Side)
**Objective**: Admin updates ticket status

**Pre-conditions**:
- User is admin or support role
- Ticket exists

**Test Steps**:
1. View all tickets (admin view)
2. Open ticket
3. Change status: `Open` → `In Progress`
4. Add internal note (not visible to requester)
5. Add public comment: `Working on a fix`
6. Later, change to `Resolved`
7. Requester confirms and closes

**Expected Results**:
- ✅ Status updated
- ✅ Requester notified
- ✅ Internal notes hidden from requester
- ✅ Public comments visible
- ✅ Resolution date tracked

---

### TC-12.5: Ticket Attachments
**Objective**: Upload and download attachments

**Pre-conditions**: Ticket exists

**Test Steps**:
1. Open ticket detail
2. Click "Add Attachment"
3. Upload file: screenshot, log file, etc.
4. Submit
5. View attachment in ticket
6. Download attachment

**Expected Results**:
- ✅ File uploaded successfully
- ✅ Shows file name, size, type
- ✅ Can download attachment
- ✅ Multiple attachments supported
- ✅ File size limit enforced

---

### TC-12.6: WebSocket Real-time Ticket Updates
**Objective**: See live updates on tickets

**Pre-conditions**:
- WebSocket connection active
- Ticket open in browser

**Test Steps**:
1. Open ticket detail
2. Have admin/other user add comment or change status
3. Observe update in real-time without refresh

**Expected Results**:
- ✅ New comments appear immediately
- ✅ Status changes update live
- ✅ Notification toast shown
- ✅ No page refresh needed

---

### TC-12.7: Delete Ticket (Creator Only)
**Objective**: Remove ticket if created by mistake

**Pre-conditions**:
- User created ticket
- Ticket is own ticket

**Test Steps**:
1. Open ticket detail
2. Click three-dot menu → "Delete"
3. Confirm deletion

**Expected Results**:
- ✅ Confirmation required
- ✅ Ticket deleted
- ✅ Removed from list
- ✅ Cannot delete if replied to (optional business rule)
- ✅ Cannot delete other users' tickets

---

## 13. Dashboard & Reports

### TC-13.1: Dashboard Overview
**Objective**: View dashboard homepage

**Pre-conditions**: User logged in with data

**Test Steps**:
1. Navigate to Dashboard (default landing page)
2. Observe dashboard layout:
   - **Desktop**: Main content + right panel
   - **Mobile**: Stacked cards
3. View sections:
   - Header with greeting
   - AI Insights cards
   - Recent Projects
   - Recent Summaries
   - Quick Actions (right panel on desktop)
   - Activity Timeline (right panel on desktop)

**Expected Results**:
- ✅ Dashboard loads within 2 seconds
- ✅ Greeting personalized (Good morning, Welcome to [Org])
- ✅ All sections render
- ✅ Responsive layout works
- ✅ "NEW" badges on recent items
- ✅ Pull-to-refresh works (mobile)

---

### TC-13.2: AI Insights on Dashboard
**Objective**: View AI-generated insights

**Pre-conditions**:
- Organization has data
- AI insights computed

**Test Steps**:
1. On dashboard, find "AI Insights" section
2. View insight cards (up to 2 on desktop, 1 on mobile)
3. Read insights such as:
   - "Optimize Summary Generation" (if many meetings, few summaries)
   - "Great Progress" (if high activity)
   - "Project Management" (if many active projects)
4. Click action button (if available)

**Expected Results**:
- ✅ Insights relevant to organization data
- ✅ Color-coded by type (info, success, warning, alert)
- ✅ Action buttons functional
- ✅ Insights update as data changes

---

### TC-13.3: Quick Actions Panel
**Objective**: Use quick actions to perform tasks

**Pre-conditions**: Dashboard loaded

**Test Steps**:
**Desktop (Right Panel)**:
1. Find "Quick Actions" panel
2. Click each action:
   - "New Project"
   - "Record Meeting"
   - "Upload Transcript or Audio"
   - "Generate Summary"
3. Verify action dialog/flow opens

**Mobile (Speed Dial FAB)**:
1. Click "+" FAB
2. View speed dial menu overlay
3. Tap each action
4. Verify dialog opens

**Expected Results**:
- ✅ All actions accessible
- ✅ Dialogs open correctly
- ✅ Speed dial animates on mobile
- ✅ Can close speed dial without action

---

### TC-13.4: Recent Projects Card
**Objective**: View and navigate to projects

**Pre-conditions**: Projects exist

**Test Steps**:
1. On dashboard, find "Recent Projects" section
2. View up to 3 most recent projects
3. Click on a project card
4. Navigate to project detail

**Expected Results**:
- ✅ Shows project name, description
- ✅ Shows document count, summary count
- ✅ Shows "NEW" badge if recently created
- ✅ Clicking navigates to project detail
- ✅ "View All" button navigates to Projects screen

---

### TC-13.5: Recent Summaries Card
**Objective**: View and navigate to summaries

**Pre-conditions**: Summaries exist

**Test Steps**:
1. On dashboard, find "Recent Summaries" section
2. View up to 3 most recent summaries
3. See summary type, project, format badges
4. Click on a summary card
5. Navigate to summary detail

**Expected Results**:
- ✅ Shows summary subject, project, date
- ✅ Format badge (GENERAL, EXECUTIVE, TECHNICAL)
- ✅ "NEW" badge if recent
- ✅ Clicking navigates to summary detail
- ✅ "View All" button navigates to Summaries screen
- ✅ Shows skeleton loader while processing

---

### TC-13.6: Activity Timeline (Dashboard)
**Objective**: View recent activity on dashboard

**Pre-conditions**:
- Organization has activity
- Desktop or tablet layout

**Test Steps**:
1. On dashboard right panel, find "Activity Timeline"
2. View recent 8 activities
3. See activity icons, titles, timestamps
4. Click on an activity
5. Navigate to related item

**Expected Results**:
- ✅ Shows recent activities across org
- ✅ Color-coded icons by type
- ✅ Relative timestamps (e.g., "2h ago")
- ✅ Clicking navigates to source
- ✅ Updates in real-time (if configured)

---

### TC-13.7: Empty State (New User)
**Objective**: View dashboard with no data

**Pre-conditions**:
- New user
- No projects, no content

**Test Steps**:
1. Log in as new user
2. View dashboard
3. Observe empty state messages

**Expected Results**:
- ✅ "No projects yet" message
- ✅ "Create First Project" button
- ✅ "No summaries yet" message
- ✅ Helpful onboarding hints
- ✅ Quick actions still accessible

---

### TC-13.8: Floating Action Button (FAB)
**Objective**: Use FAB for quick access

**Pre-conditions**: Dashboard or Hierarchy screen

**Test Steps**:
**Desktop/Tablet**:
1. See "Ask AI" FAB in bottom-right
2. Click to open AI query panel

**Mobile**:
1. See "+" FAB in bottom-right
2. Click to open speed dial menu
3. Select action from menu

**Expected Results**:
- ✅ FAB always visible
- ✅ Safe area respected on mobile
- ✅ Animates on interaction
- ✅ Context-aware (Ask AI if has projects, New Project if none)

---

### TC-13.9: Refresh Dashboard Data
**Objective**: Reload dashboard data

**Pre-conditions**: Dashboard loaded

**Test Steps**:
**Mobile**: Pull down from top of dashboard
**Desktop**: Click refresh icon (if available) or reload page

**Expected Results**:
- ✅ Pull-to-refresh works on mobile
- ✅ Loading indicator shown
- ✅ All data refreshed
- ✅ Analytics logged (if configured)

---

## 14. Responsive Design & Cross-Platform

### TC-14.1: Mobile Responsive Layout (< 768px)
**Objective**: Verify mobile-optimized layout

**Pre-conditions**: Browser or device with width < 768px

**Test Steps**:
1. Open app on mobile device or resize browser to mobile width
2. Navigate through all screens:
   - Dashboard
   - Hierarchy
   - Project Detail
   - Summaries
   - Documents
3. Observe layout:
   - Single column
   - Stacked cards
   - Bottom navigation bar
   - Hamburger menu
   - Speed dial FAB

**Expected Results**:
- ✅ All content accessible
- ✅ No horizontal scroll
- ✅ Touch-friendly buttons (min 44x44px)
- ✅ Text readable (no tiny fonts)
- ✅ Images/cards scale properly
- ✅ Modals fit screen

---

### TC-14.2: Tablet Responsive Layout (768px - 1200px)
**Objective**: Verify tablet-optimized layout

**Pre-conditions**: Tablet device or browser width 768-1200px

**Test Steps**:
1. Open app on tablet or resize browser
2. Navigate through screens
3. Observe layout:
   - 2-column layout (some screens)
   - Side navigation rail (not drawer)
   - Larger cards than mobile
   - More items visible

**Expected Results**:
- ✅ Optimal use of space
- ✅ Not just stretched mobile layout
- ✅ Navigation rail on left
- ✅ Content max-width for readability

---

### TC-14.3: Desktop Responsive Layout (> 1200px)
**Objective**: Verify desktop-optimized layout

**Pre-conditions**: Desktop browser width > 1200px

**Test Steps**:
1. Open app on desktop
2. Navigate through screens
3. Observe layout:
   - Main content + right panel (Dashboard, Hierarchy)
   - Max-width 1400px (constrained)
   - Sidebar navigation
   - Multi-column cards
   - Tooltips on hover
   - Keyboard navigation

**Expected Results**:
- ✅ Optimal use of wide screen
- ✅ Right panel shows Quick Actions, Activity
- ✅ Content centered with max-width
- ✅ Hover states work
- ✅ Keyboard shortcuts (if implemented)

---

### TC-14.4: Touch vs Mouse Interactions
**Objective**: Verify appropriate interactions per device

**Mobile (Touch)**:
- ✅ Tap to open
- ✅ Swipe to dismiss
- ✅ Pull to refresh
- ✅ Long press for context menu (if supported)
- ✅ No hover states required

**Desktop (Mouse)**:
- ✅ Click to open
- ✅ Hover for tooltips
- ✅ Right-click context menu (if supported)
- ✅ Keyboard shortcuts work
- ✅ Scroll wheel works

---

### TC-14.5: Dark Mode (if supported)
**Objective**: Verify dark mode theme

**Pre-conditions**:
- Dark mode enabled in system preferences OR
- App has theme toggle

**Test Steps**:
1. Enable dark mode
2. Navigate through all screens
3. Verify colors, contrast, readability

**Expected Results**:
- ✅ Dark background, light text
- ✅ Sufficient contrast (WCAG AA)
- ✅ Colors adapted for dark mode
- ✅ Images/icons visible
- ✅ No white flashes

---

### TC-14.6: Browser Compatibility
**Objective**: Test across browsers

**Test Steps**:
Test on:
1. Chrome (latest)
2. Firefox (latest)
3. Safari (latest - macOS/iOS)
4. Edge (latest)

**Expected Results**:
- ✅ All features work on all browsers
- ✅ Layout consistent
- ✅ WebSocket support
- ✅ File upload works
- ✅ No console errors

---

## 15. Error Handling & Edge Cases

### TC-15.1: Network Errors
**Objective**: Handle loss of connection

**Test Steps**:
1. Open app
2. Disable network (airplane mode or disconnect WiFi)
3. Try to perform actions (e.g., load projects, upload content)
4. Observe error handling
5. Reconnect network
6. Retry action

**Expected Results**:
- ✅ Error message displayed
- ✅ User-friendly message (not technical jargon)
- ✅ Retry button available
- ✅ Offline indicator shown
- ✅ Auto-retry when connection restored (if supported)
- ✅ Pending actions queued (if supported)

---

### TC-15.2: API Errors (4xx, 5xx)
**Objective**: Handle API error responses

**Test Steps**:
1. Trigger various API errors:
   - 400 Bad Request (invalid input)
   - 401 Unauthorized (expired token)
   - 403 Forbidden (no permission)
   - 404 Not Found (deleted resource)
   - 409 Conflict (duplicate)
   - 429 Too Many Requests (rate limit)
   - 500 Internal Server Error
   - 503 Service Unavailable
2. Observe error handling

**Expected Results**:
- ✅ Each error type handled gracefully
- ✅ 401: Redirects to login
- ✅ 403: Permission denied message
- ✅ 404: Not found message
- ✅ 429: Rate limit message with retry-after
- ✅ 500/503: Server error message, option to retry
- ✅ No raw stack traces shown to user

---

### TC-15.3: Invalid/Missing Data
**Objective**: Handle edge cases with data

**Test Steps**:
1. Try to upload empty file
2. Try to upload file > max size
3. Try to create project with empty name
4. Try to upload content with invalid content type
5. Try to assign task to non-existent user

**Expected Results**:
- ✅ Validation errors shown before submission
- ✅ Empty fields highlighted
- ✅ Clear error messages
- ✅ Cannot submit invalid form
- ✅ Edge cases handled backend-side as well

---

### TC-15.4: Concurrent Actions / Race Conditions
**Objective**: Handle simultaneous operations

**Test Steps**:
1. Open same project in 2 browser tabs
2. In tab 1: Edit project name
3. In tab 2: Edit project description simultaneously
4. Save both
5. Observe conflict resolution

**Expected Results**:
- ✅ Last write wins (or)
- ✅ Conflict detection with merge option
- ✅ Real-time updates sync across tabs
- ✅ No data loss

---

### TC-15.5: Session Expiration
**Objective**: Handle expired auth token

**Pre-conditions**: JWT token expires after X minutes

**Test Steps**:
1. Log in
2. Leave app idle for token expiration time
3. Try to perform action (e.g., create project)
4. Observe re-authentication

**Expected Results**:
- ✅ Token refresh attempted automatically (if supported)
- ✅ If refresh fails, redirected to login
- ✅ Redirect preserves intended action (deep link)
- ✅ After login, resumes action or navigates to original page

---

### TC-15.6: XSS and Injection Prevention
**Objective**: Verify input sanitization

**Test Steps**:
1. Try to create project with name: `<script>alert('XSS')</script>`
2. Try to enter SQL injection in search: `'; DROP TABLE projects; --`
3. Try to upload file with malicious name: `../../../etc/passwd`

**Expected Results**:
- ✅ Script tags escaped and rendered as text
- ✅ No script execution
- ✅ SQL injection parameterized (no effect)
- ✅ Path traversal blocked
- ✅ CSRF protection enabled

---

### TC-15.7: Large Data Sets
**Objective**: Handle performance with large data

**Test Steps**:
1. Create organization with 50+ projects
2. Upload 100+ meetings to a project
3. Generate summary from 100+ meetings
4. Navigate to Risks screen with 500+ risks
5. Scroll through lists

**Expected Results**:
- ✅ Pagination or infinite scroll works
- ✅ No UI freezing
- ✅ Smooth scrolling (60fps)
- ✅ Search/filter remains fast
- ✅ Lazy loading images/content

---

### TC-15.8: Multi-Tenant Isolation (Security)
**Objective**: Verify no data leakage between organizations

**Pre-conditions**:
- 2 organizations exist
- User belongs to Organization A

**Test Steps**:
1. Log in as User A (Org A)
2. Note a project ID from Org B (simulate knowing the ID)
3. Try to access Org B project via URL manipulation
4. Try to query Org B content via API
5. Try to view Org B members

**Expected Results**:
- ✅ 404 Not Found for Org B resources
- ✅ Cannot access data from other orgs
- ✅ Search only returns own org data
- ✅ Vector search scoped to org
- ✅ RLS (Row Level Security) enforced

---

### TC-15.9: Accessibility (a11y)
**Objective**: Verify app is accessible

**Test Steps**:
1. Navigate with keyboard only (Tab, Enter, Esc)
2. Use screen reader (NVDA, JAWS, VoiceOver)
3. Check color contrast (WCAG AA: 4.5:1)
4. Check focus indicators
5. Check alt text on images
6. Check form labels

**Expected Results**:
- ✅ All interactive elements keyboard accessible
- ✅ Focus visible and logical
- ✅ Screen reader announces elements correctly
- ✅ ARIA labels present
- ✅ Color contrast sufficient
- ✅ Form fields labeled
- ✅ Skip to main content link (optional)

---

## Test Execution Summary Template

After completing manual testing, document results:

| Test Case ID | Description | Status | Issues Found | Notes |
|--------------|-------------|--------|--------------|-------|
| TC-1.1 | User Registration | ✅ Pass | None | |
| TC-1.2 | User Login | ✅ Pass | None | |
| TC-3.1 | Create Portfolio | ❌ Fail | UI: Save button disabled even with valid input | Bug #123 |
| TC-5.1 | Upload Transcript | ✅ Pass | None | |
| ... | ... | ... | ... | ... |

**Legend**:
- ✅ **Pass**: Feature works as expected
- ⚠️ **Pass with Issues**: Works but has minor issues
- ❌ **Fail**: Feature broken or not working
- 🚧 **Blocked**: Cannot test due to dependency
- ⏭️ **Skipped**: Not applicable or deferred

---

## Conclusion

This comprehensive manual test suite covers **15 major feature areas** with **100+ test scenarios** across:
- Authentication & Organization Management
- Hierarchy & Project Management
- Content Upload & AI Processing
- RAG Query & Search
- Summary Generation
- Risks, Tasks, Lessons Learned
- Integrations & Support
- Responsive Design & Accessibility

**Testing Strategy**:
1. **Smoke Test**: Run TC-1.1, 1.2, 3.1, 4.1, 5.1, 6.1, 7.1 to verify core flows
2. **Regression Test**: Run all scenarios before releases
3. **Exploratory Test**: Free-form testing to find edge cases
4. **User Acceptance Test (UAT)**: Have real users test workflows

**Automation Recommendations** (for future):
- Critical paths (TC-1.1 to 1.4, 5.1, 6.1, 7.1) → Automate with Cypress/Playwright
- API tests → Already covered in backend test suite (TESTING_BACKEND.md)
- Visual regression → Use Percy or Chromatic

This manual test suite ensures TellMeMo delivers a robust, user-friendly Meeting RAG System! 🚀
