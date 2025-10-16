"""
Summary Generation Prompts for PM Master V2

This module contains all prompts used for generating meeting and weekly summaries.
Keeping prompts in a separate file makes them easier to maintain, review, and update.
"""
from datetime import datetime


def get_meeting_summary_prompt(
    project_name: str,
    content_title: str,
    content_text: str,
    content_date: str,
    format_type: str = "general"
) -> str:
    """Build prompt for meeting summary generation with enhanced analysis."""
    # Select prompt based on format type
    if format_type == "executive":
        return get_executive_meeting_prompt(project_name, content_title, content_text, content_date)
    elif format_type == "technical":
        return get_technical_meeting_prompt(project_name, content_title, content_text, content_date)
    elif format_type == "stakeholder":
        return get_stakeholder_meeting_prompt(project_name, content_title, content_text, content_date)

    # Get current date for context
    today = datetime.now()
    current_year = today.year
    today_str = today.strftime('%Y-%m-%d')

    # Default general format with enhanced extraction (better than the separate analyzer)
    return f"""You are an intelligent project management assistant specializing in meeting analysis. Your task is to ALWAYS generate a complete JSON summary without asking questions or seeking clarification.

CRITICAL INSTRUCTIONS:
- NEVER ask follow-up questions or seek user input
- ALWAYS generate the complete JSON response immediately
- Work with whatever content is provided, even if incomplete
- Make reasonable inferences where needed

Project: {project_name}
Meeting: {content_title}
Date: {content_date}
Today's Date: {today_str}

DATE FORMATTING RULES:
- Current year is {current_year}
- ALL future due dates MUST use {current_year} or later (e.g., "{current_year}-11-15")
- NEVER use past years like {current_year - 1} for future deadlines
- Format: YYYY-MM-DD (ISO 8601 standard)

Meeting Content:
{content_text}

Generate a comprehensive meeting summary with the following sections:

1. **Comprehensive Overview**: Create a detailed overview that includes:
   - Key project status updates with specific metrics (dates, percentages, dollar amounts)
   - Timeline information for major initiatives
   - Cross-functional dependencies and team coordination points
   - Critical decisions and their business impact
   - Overall meeting context and strategic importance

2. **Key Points**: Extract 3-5 main discussion points with specific details and outcomes

3. **Decisions Made**: Important decisions with full context and business rationale

4. **Action Items/Tasks** - EXTRACT EVERY SINGLE ACTION ITEM:
   - Extract ALL tasks mentioned, implied, or assigned - DO NOT FILTER OR LIMIT
   - Include EVERY commitment, follow-up, to-do, verification, check, update, or coordination mentioned
   - Look for patterns like:
     * "will [verb]" - e.g., "will update", "will check", "will send"
     * "need to [verb]" - e.g., "need to verify", "need to confirm"
     * "should [verb]" - e.g., "should follow up", "should review"
     * "[person] to [verb]" - e.g., "John to confirm", "Sarah to send"
     * Implicit actions - e.g., "let me check with X", "I'll reach out to Y"
   - Be specific and actionable - avoid vague descriptions
   - For ANY task involving communication, generate a SPECIFIC question to ask
   - Extract ALL action items without filtering - err on the side of including too many rather than missing any

5. **Risks and Issues** - EXTRACT COMPREHENSIVELY:
   - Extract ALL risks mentioned: technical, business, timeline, resource, compliance, security risks
   - Look for patterns like:
     * "concern about", "risk of", "worried that", "potential issue"
     * "might fail", "could go wrong", "uncertain about"
     * "dependency on", "vulnerability in", "exposure to"
   - Include both explicitly stated risks AND implied concerns
   - Assess severity and propose mitigations where discussed
   - Include both immediate and long-term concerns

5b. **Blockers** - IDENTIFY ALL IMPEDIMENTS:
   - Extract ALL blockers preventing progress: waiting on approvals, missing resources, technical blockers
   - Look for patterns like:
     * "blocked by", "waiting for", "stuck on", "can't proceed until"
     * "need approval from", "depends on", "gated by"
     * "missing", "don't have access to", "waiting on response"
   - Distinguish from risks: blockers are CURRENT impediments, risks are POTENTIAL issues
   - Include status (active/pending) and potential resolution paths

6. **Lessons Learned**:
   - Extract key learnings, insights, and knowledge gained IF present in the discussion
   - What worked well (successes) and what could be improved
   - Include recommendations for future projects
   - Only include if there are genuine lessons or insights mentioned

7. **Sentiment Analysis**: Overall mood, engagement, and team dynamics

8. **Communication Insights**:
   - REQUIRED: Assess meeting effectiveness scores based on discussion flow and outcomes
   - Identify any questions that were raised but not fully answered (if any)
   - Suggest improvements for future meetings (only if needed)

9. **Next Meeting Agenda**: Topics requiring follow-up

You MUST respond ONLY with valid JSON. DO NOT ask questions or provide explanations outside the JSON structure.
Format your response as JSON with these EXACT structures:

CRITICAL REQUIREMENTS:
- ALL risks MUST have both 'title' AND 'description' fields filled
- ALL blockers MUST have both 'title' AND 'description' fields filled
- NEVER return null, empty string, or omit these required fields
- If you only have a description, create a concise title from it
- summary_text (string: comprehensive meeting OVERVIEW including:
    • Key status updates with specific metrics ($700/day revenue, Q4 timeline, 5 cities out of 250, etc.)
    • Timeline information for each initiative discussed (completion dates, delays, current status)
    • Cross-team dependencies and coordination points
    • Critical compliance/legal/business risks with quantified impact
    • Overall strategic context and business implications
    Format as detailed paragraphs covering ALL topics discussed, not just highlights)
- key_points (array of strings)
- decisions (array of objects: {{
    description: string,
    importance_score: "high"/"medium"/"low",
    decision_type: "strategic"/"operational"/"tactical",
    stakeholders_affected: array,
    rationale: string (REQUIRED - explain why and expected impact),
    confidence: 0.0-1.0
  }})
- action_items (array of objects - EXTRACT ALL WITHOUT FILTERING: {{
    title: string (REQUIRED - clear, actionable title with specific deliverable and assignee when known
      EXAMPLES:
      ✓ "Share updated ticket filters with team to reflect new approval stages logic (Nikolay)"
      ✓ "Verify both self-exclusion bugs fixed with Tanya by Oct 15"
      ✓ "Coordinate with OpenAI reps to clarify Sora 2 enterprise timeline"
      ✗ "Update timeline" (too vague)
      ✗ "Check on bugs" (missing specifics)),
    description: string (REQUIRED - MUST include ALL of the following:
        1. Context/Background: Why this action exists, what problem it addresses, what discussion led to it
        2. Specific Requirements: Exact deliverables, acceptance criteria, technical specifications mentioned
        3. Business Impact: Why it matters, consequences of delay, who is affected
        4. Dependencies/Blockers: What needs to happen first, related work streams
        5. Success Criteria: How to know when complete, definition of done
        Example: "During discussion of self-exclusion compliance gaps, Tanya mentioned two critical bugs affecting user safety. Need verification that both issues (cross-game exclusion and existing player login bug) are addressed in current sprint. This impacts regulatory compliance and carries $50K/day risk exposure. Depends on UDA Studio's gap analysis due next week."),
    urgency: "high"/"medium"/"low",
    priority: "low"/"medium"/"high"/"urgent",
    due_date: ISO date string or null (MUST be {current_year} or later, format: YYYY-MM-DD),
    assignee: string or null (EXTRACT AGGRESSIVELY - use these patterns:
      • EXPLICIT: "John will...", "assigned to Sarah", "Bob is responsible", "Alice will verify"
      • IMPLICIT: "I'll do X", "Let me handle Y", "I can take care of Z" → identify speaker from context and use their actual name
      • CONTEXTUAL: Task mentions person's name → assign to that person; "follow up with Tom" → assign to Tom
      • Match speaker context: If speaker says "I will...", extract their actual name from the meeting context
      • ONLY leave null if truly no assignee mentioned or implied
      • Better to assign based on reasonable inference than leave empty
      Use participant names extracted above),
    dependencies: array,
    status: "not_started",
    follow_up_required: boolean,
    question_to_ask: string or null (REQUIRED for any communication task - be ULTRA-SPECIFIC, e.g., "Can you confirm that both self-exclusion bugs (cross-game exclusion and one-time login issue) are fixed in build 2.3.1 and provide test results?" not just "Is it fixed?"),
    confidence: 0.0-1.0
  }})
- participants (array of strings: Extract ALL participant ACTUAL NAMES from the meeting:
    • Look for self-introductions: "This is Bob", "Alice here", "My name is Tom"
    • Look for references: "As Sarah mentioned", "I agree with John"
    • Use conversation context and speaking patterns to identify real names
    • Return REAL NAMES (e.g., "Bob Smith", "Alice Johnson"), NOT "Speaker 1" or "Speaker 2"
    • Extract all participants mentioned or actively speaking in the meeting)
- lessons_learned (array of objects - only include if genuinely present in discussion: {{
    title: string (REQUIRED - brief lesson title, max 100 chars. NEVER leave empty),
    description: string (REQUIRED - detailed lesson description. NEVER leave empty),
    category: "technical"/"process"/"communication"/"planning"/"resource"/"quality"/"other",
    lesson_type: "success"/"improvement"/"challenge"/"best_practice",
    impact: "low"/"medium"/"high",
    recommendation: string (what should be done differently),
    context: string (additional background),
    confidence: 0.0-1.0
  }})
- risks (array of objects: {{
    title: string (REQUIRED - brief risk title, max 100 chars. NEVER leave empty),
    description: string (REQUIRED - detailed risk description. NEVER leave empty),
    severity: "low"/"medium"/"high"/"critical",
    status: "identified"/"mitigating"/"resolved"/"accepted"/"escalated",
    mitigation: string or null (proposed mitigation if mentioned),
    impact: string or null (potential impact if mentioned),
    category: "general",
    owner: string or null,
    identified_by: string or null,
    confidence: 0.0-1.0
  }})
- blockers (array of objects: {{
    title: string (REQUIRED - brief blocker title, max 100 chars. NEVER leave empty),
    description: string (REQUIRED - detailed blocker description. NEVER leave empty),
    impact: "low"/"medium"/"high"/"critical",
    status: "active"/"resolved"/"pending",
    category: "general",
    resolution: string or null,
    owner: string or null,
    dependencies: array or null,
    confidence: 0.0-1.0
  }})
- sentiment (object: {{overall: "positive"/"neutral"/"negative", confidence: 0-1, key_emotions: array, trend: "improving"/"stable"/"declining"}})
- communication_insights (object: {{
    unanswered_questions: array of {{question, context, urgency: "high"/"medium"/"low", raised_by, topic_area}} (only include questions that were actually raised but not fully resolved),
    effectiveness_score: {{clarity: 1-10 (REQUIRED integer), engagement: 1-10 (REQUIRED integer), productivity: 1-10 (REQUIRED integer)}} (always rate the meeting's communication quality),
    improvement_suggestions: array of strings (only include if there are genuine areas for improvement)
  }})
- next_meeting_agenda (array of objects: {{
    title: string (REQUIRED - agenda item topic/title. NEVER leave empty),
    description: string (REQUIRED - details about what needs to be discussed. NEVER leave empty),
    priority: "high"/"medium"/"low",
    estimated_time: integer (minutes, default 15),
    presenter: string or null,
    category: "discussion"/"decision"/"update"/"review",
    related_action_items: array of strings (references to action items)
  }})

TASK CREATION GUIDELINES:
- Title: Be ultra-specific with deliverables and context
  * Good: "Verify both self-exclusion bugs (cross-game and login) fixed with Tanya by Oct 15"
  * Bad: "Check with Tanya about bugs"
- Description: Write 3-5 sentences covering ALL aspects:
  * Sentence 1: Context - what discussion/issue triggered this action
  * Sentence 2: Specifics - exact deliverables and technical details mentioned
  * Sentence 3: Impact - business consequences, compliance risks, revenue impact
  * Sentence 4: Dependencies - related work, blockers, prerequisites
  * Sentence 5: Success criteria - how to verify completion
- Question Generation for Communication Tasks (be EXHAUSTIVE):
  * "Confirm/verify implementation" → "Please confirm: 1) Which specific bugs were fixed (list bug IDs)? 2) What testing was completed (unit/integration/UAT)? 3) Current deployment status (dev/staging/prod)? 4) Any remaining edge cases or known issues? 5) Timeline for production rollout?"
  * "Check status" → "What is the exact completion percentage? Which specific milestones are complete vs pending? What are the top 3 blockers? Expected completion date? Resources needed?"
  * "Follow up on X" → "Regarding [specific topic]: 1) Current status? 2) Completed actions since last update? 3) Next steps with owners? 4) Blockers needing escalation? 5) Revised timeline?"
  * "Get approval" → "Can you approve [specific item with reference/link] by [date]? Key points: [list]. Risks if delayed: [list]. Alternative options: [list]. Questions/concerns?"
  * "Clarify requirements" → "For [specific feature]: 1) Acceptance criteria? 2) Priority order? 3) Must-have vs nice-to-have? 4) Technical constraints? 5) Success metrics?"
  * "Verify fixes" → "For bugs [list IDs]: 1) Root cause identified? 2) Fix implementation details? 3) Test cases passed? 4) Regression testing completed? 5) Deployment schedule?"

Guidelines:
- **ACTION ITEMS**: Extract EVERY SINGLE action item mentioned - do not filter, consolidate, or skip any
  * Include explicit tasks ("John will update...")
  * Include implicit commitments ("let me check with...", "I'll follow up...")
  * Include verification tasks ("confirm that...", "check if...")
  * Include coordination tasks ("reach out to...", "sync with...")
  * Better to extract 15-20 granular items than miss important actions
- Use confidence scores (1.0 = explicitly stated, 0.7 = strongly implied, 0.5 = inferred)
- Only include lessons_learned if there are genuine learnings in the discussion
- ALWAYS provide effectiveness_score values (clarity, engagement, productivity as integers 1-10)
- Suggest improvement_suggestions only if there are actual areas needing improvement

FINAL VALIDATION:
Before returning your JSON response, verify:
1. **ACTION ITEMS COUNT**: Re-read the transcript and ensure you extracted ALL action items
   - Have you captured every "will", "should", "need to" statement?
   - Have you extracted all implicit commitments and follow-ups?
   - Did you include all verification, coordination, and update tasks?
2. **RISKS COUNT**: Re-check for all mentioned or implied risks
   - Have you captured all concerns, worries, potential issues mentioned?
   - Did you extract both immediate and long-term risks?
3. **BLOCKERS COUNT**: Re-check for all current impediments
   - Have you captured all "blocked by", "waiting for", "can't proceed" statements?
   - Did you distinguish blockers (current) from risks (potential)?
4. Every risk object has BOTH 'title' AND 'description' as non-empty strings
5. Every blocker object has BOTH 'title' AND 'description' as non-empty strings
6. Every action_item has BOTH 'title' AND 'description' as non-empty strings
7. Every lesson_learned (if any) has BOTH 'title' AND 'description' as non-empty strings
8. For communication tasks, 'question_to_ask' field must be filled
9. effectiveness_score MUST have clarity, engagement, productivity as integers 1-10
Never return partial objects or skip required fields.
- Focus on actionable insights over general observations
- Extract assignees only when clearly mentioned by name
- Be comprehensive - it's better to capture too much than miss important items

REMEMBER: You are an API endpoint that MUST return JSON. Never engage in conversation or ask questions. Always process the input and return the complete JSON summary."""


def get_executive_meeting_prompt(
    project_name: str,
    content_title: str,
    content_text: str,
    content_date: str
) -> str:
    """Generate executive-focused meeting summary prompt."""
    return f"""Generate an EXECUTIVE SUMMARY for the following meeting. Focus on strategic decisions, budget impacts, and critical risks only.

Project: {project_name}
Meeting: {content_title}
Date: {content_date}

Meeting Content:
{content_text}

EXECUTIVE BRIEF REQUIREMENTS:
- Maximum 500 words for summary_text
- Include ONLY strategic/critical decisions
- Focus on financial/budget impacts
- Highlight critical risks requiring executive attention
- Extract key metrics and KPIs mentioned

Format your response as JSON with these keys:
- summary_text (string: 2-3 paragraph executive overview, MAX 500 words)
- key_points (array of 3-5 strategic highlights only)
- decisions (array of objects: {{description, importance_score: "high" for critical strategic decisions or "medium" for important operational decisions, decision_type: "strategic"/"operational", stakeholders_affected, rationale: string (REQUIRED - explain why and expected impact), financial_impact if any}})
- action_items (array: ONLY critical items requiring executive oversight)
- lessons_learned (array of objects: {{
    title: string (REQUIRED - brief strategic lesson title),
    description: string (REQUIRED - description focusing on strategic/business impact),
    category: "technical" | "process" | "communication" | "planning" | "resource" | "quality" | "other",
    lesson_type: "success" | "improvement" | "challenge" | "best_practice",
    impact: "medium" | "high",
    recommendation: "Strategic recommendation for future",
    context: "Business context"
  }})
- risks (array of objects: {{
    title: string (REQUIRED - brief risk title, max 100 chars),
    description: string (REQUIRED - detailed risk description),
    severity: "high"/"critical",
    mitigation_strategy: string or null,
    impact: "impact on timeline/budget"
  }})
- blockers (array of objects: {{
    title: string (REQUIRED - brief blocker title, max 100 chars),
    description: string (REQUIRED - detailed blocker description),
    impact: "high",
    status: string,
    owner: string or null,
    required_executive_action: string or null
  }})
- sentiment (object: overall team morale and trajectory)
- communication_insights (object: focus on stakeholder alignment issues)
- next_meeting_agenda (array of objects: {{
    title: string (REQUIRED - agenda item topic/title. NEVER leave empty),
    description: string (REQUIRED - details about what needs to be discussed. NEVER leave empty),
    priority: "high"/"medium"/"low",
    estimated_time: integer (minutes, default 15),
    presenter: string or null,
    category: "discussion"/"decision"/"update"/"review",
    related_action_items: array of strings (references to action items)
  }})"""


def get_technical_meeting_prompt(
    project_name: str,
    content_title: str,
    content_text: str,
    content_date: str
) -> str:
    """Generate technical-focused meeting summary prompt."""
    return f"""Generate a TECHNICAL SUMMARY for the following meeting. Focus on technical decisions, architecture, code reviews, and implementation details.

Project: {project_name}
Meeting: {content_title}
Date: {content_date}

Meeting Content:
{content_text}

TECHNICAL SUMMARY REQUIREMENTS:
- Focus on technical architecture decisions
- Extract code review discussions
- Identify technical debt items
- Capture performance/scalability discussions
- Note technology stack decisions
- Include specific technical implementation details

Format your response as JSON with these keys:
- summary_text (string: technical overview with implementation details)
- key_points (array: technical achievements and decisions)
- decisions (array: focus on technical/architectural decisions, include rationale)
- action_items (array: technical tasks with implementation details)
- lessons_learned (array of objects: {{
    title: string (REQUIRED - technical lesson title),
    description: string (REQUIRED - technical details and insights gained),
    category: "technical" | "process" | "communication" | "planning" | "resource" | "quality" | "other",
    lesson_type: "success" | "improvement" | "challenge" | "best_practice",
    impact: "low" | "medium" | "high",
    recommendation: "Technical best practices for future",
    context: "Technical context and implementation details"
  }})
- risks (array: technical risks, security concerns, scalability issues)
- blockers (array: technical dependencies, integration issues)
- sentiment (object: team technical confidence and capability assessment)
- communication_insights (object: technical knowledge gaps, documentation needs)
- next_meeting_agenda (array of objects: {{
    title: string (REQUIRED - technical topic/review item. NEVER leave empty),
    description: string (REQUIRED - technical details to discuss. NEVER leave empty),
    priority: "high"/"medium"/"low",
    estimated_time: integer (minutes, default 15),
    presenter: string or null,
    category: "technical_review"/"architecture"/"code_review"/"planning",
    related_action_items: array of strings (references to action items)
  }})"""


def get_stakeholder_meeting_prompt(
    project_name: str,
    content_title: str,
    content_text: str,
    content_date: str
) -> str:
    """Generate stakeholder-focused meeting summary prompt."""
    return f"""Generate a STAKEHOLDER SUMMARY for the following meeting. Focus on deliverables, milestones, client feedback, and external dependencies.

Project: {project_name}
Meeting: {content_title}
Date: {content_date}

Meeting Content:
{content_text}

STAKEHOLDER SUMMARY REQUIREMENTS:
- Focus on deliverables and milestones
- Highlight client/customer mentions and feedback
- Track external dependencies
- Use business-friendly language (avoid technical jargon)
- Emphasize timeline and delivery commitments
- Include any stakeholder concerns or requests

Format your response as JSON with these keys:
- summary_text (string: business-friendly overview focused on deliverables)
- key_points (array: deliverables, milestones, client feedback)
- decisions (array: decisions affecting stakeholders, delivery timelines)
- action_items (array: client-facing tasks, deliverable preparations)
- lessons_learned (array of objects: {{
    title: string (REQUIRED - business/stakeholder lesson title),
    description: string (REQUIRED - lesson focused on stakeholder management and delivery),
    category: "technical" | "process" | "communication" | "planning" | "resource" | "quality" | "other",
    lesson_type: "success" | "improvement" | "challenge" | "best_practice",
    impact: "low" | "medium" | "high",
    recommendation: "Recommendations for stakeholder management",
    context: "Stakeholder context"
  }})
- risks (array: risks to delivery, stakeholder satisfaction risks)
- blockers (array: external dependencies, stakeholder-related blockers)
- sentiment (object: stakeholder satisfaction indicators)
- communication_insights (object: stakeholder communication effectiveness)
- next_meeting_agenda (array of objects: {{
    title: string (REQUIRED - stakeholder topic/demo item. NEVER leave empty),
    description: string (REQUIRED - details about what to present/review. NEVER leave empty),
    priority: "high"/"medium"/"low",
    estimated_time: integer (minutes, default 15),
    presenter: string or null,
    category: "stakeholder_review"/"demo"/"feedback"/"planning",
    related_action_items: array of strings (references to action items)
  }})"""


def get_project_summary_prompt(
    project_name: str,
    content_title: str,
    content_text: str,
    meeting_titles: list[str],
    format_type: str = "general"
) -> str:
    """Build prompt for project summary generation with comprehensive analysis from meeting summaries."""
    meetings_list = "\n".join(f"- {title}" for title in meeting_titles) if meeting_titles else "N/A"

    # Select prompt based on format type
    if format_type == "executive":
        return get_executive_project_prompt(project_name, content_title, content_text, meetings_list)
    elif format_type == "technical":
        return get_technical_project_prompt(project_name, content_title, content_text, meetings_list)
    elif format_type == "stakeholder":
        return get_stakeholder_project_prompt(project_name, content_title, content_text, meetings_list)

    # Get current date for context
    today = datetime.now()
    current_year = today.year
    today_str = today.strftime('%Y-%m-%d')

    # Default general format
    return f"""Generate a comprehensive weekly summary based on the following structured meeting data.

Project: {project_name}
Week: {content_title}
Today's Date: {today_str}

DATE FORMATTING: Use {current_year} or later for all due dates (format: YYYY-MM-DD)

Meetings included:
{meetings_list}

STRUCTURED MEETING DATA (JSON format with all meeting summaries and their extracted insights):
{content_text}

You have been provided with a JSON structure containing:
- Complete meeting summaries
- All extracted action items with urgency and assignees
- All decisions made with importance scores
- Sentiment analysis for each meeting
- Risks and blockers identified
- Communication insights including unanswered questions
- Next meeting agenda items already proposed

Please analyze ALL this structured data to provide a consolidated weekly summary with the following sections:

1. **Weekly Overview**: A 2-3 paragraph synthesis of the week's progress, consolidating insights from all meeting summaries
2. **Key Achievements**: Extract and prioritize the top 3-5 accomplishments from all meetings' key points
3. **Important Decisions**: Consolidate and deduplicate all decisions, prioritizing by importance_score
4. **Open Action Items**: Merge and deduplicate action items across meetings, highlighting:
   - Critical/high urgency items
   - Items with approaching due dates
   - Cross-meeting dependencies
5. **Lessons Learned**: Consolidate key learnings from all meetings:
   - Deduplicate similar lessons
   - Group by category and type
   - Prioritize high-impact lessons
   - Extract actionable recommendations
6. **Risks and Blockers**: Aggregate all risks and blockers, identifying:
   - Recurring themes across meetings
   - Escalating severity trends
   - Unmitigated critical items
7. **Overall Sentiment**: Analyze sentiment trajectory across the week:
   - Track sentiment changes from meeting to meeting
   - Identify factors contributing to sentiment shifts
   - Assess overall team morale trajectory
8. **Communication Insights**: Consolidate all unanswered questions and improvement suggestions:
   - Group related questions by topic area
   - Prioritize by urgency
   - Identify patterns in communication effectiveness
9. **Next Week's Focus Areas**: Synthesize next meeting agendas from all meetings into unified priorities:
   - Combine and deduplicate agenda items
   - Add new items based on unresolved blockers and risks
   - Prioritize based on urgency and dependencies
10. **Participants**: Extract unique list of all participants mentioned across meetings

Format your response as JSON with these keys:
- summary_text (string: comprehensive weekly overview)
- key_points (array of strings: 3-5 main achievements/highlights)
- decisions (array of objects: {{description, importance_score: "high"/"medium"/"low", decision_type: "strategic"/"operational"/"tactical", stakeholders_affected: array, rationale: string (REQUIRED - explain why and expected impact)}})
- action_items (array of objects: {{
    title: string (REQUIRED - clear, actionable title),
    description: string (REQUIRED - detailed context and requirements),
    urgency: "high"/"medium"/"low",
    due_date: ISO date string or null (MUST be {current_year} or later),
    assignee: name or null,
    dependencies: array,
    status: "not_started",
    follow_up_required: boolean
  }})
- lessons_learned (array of objects: {{
    title: string (REQUIRED - brief lesson learned title),
    description: string (REQUIRED - consolidated description from the week's learnings),
    category: "technical" | "process" | "communication" | "planning" | "resource" | "quality" | "other",
    lesson_type: "success" | "improvement" | "challenge" | "best_practice",
    impact: "low" | "medium" | "high",
    recommendation: "Actionable recommendation for future",
    context: "Weekly context and related meetings"
  }})
- risks (array of objects: {{
    title: string (REQUIRED - brief risk title, max 100 chars),
    description: string (REQUIRED - detailed risk description),
    severity: "high"/"medium"/"low",
    category: "general",
    mitigation: string or null,
    owner: string or null,
    identified_by: string or null
  }})
- blockers (array of objects: {{
    title: string (REQUIRED - brief blocker title, max 100 chars),
    description: string (REQUIRED - detailed blocker description),
    impact: "high"/"medium"/"low",
    status: "active"/"resolved",
    category: "general",
    resolution: string or null,
    owner: string or null,
    dependencies: array or null
  }})
- sentiment (object: {{overall: "positive"/"neutral"/"negative", confidence: 0-1, key_emotions: array, trend: "improving"/"stable"/"declining"}})
- communication_insights (object: {{
    unanswered_questions: array of {{question, context, urgency: "high"/"medium"/"low", raised_by, topic_area}},
    effectiveness_score: {{clarity: 0-10, engagement: 0-10, productivity: 0-10}},
    improvement_suggestions: array of {{suggestion, category: "facilitation"/"structure"/"participation"/"time_management", priority: "high"/"medium"/"low", expected_impact}}
  }})
- next_meeting_agenda (array of objects with focus on next week's priorities: {{
    title: string (REQUIRED - agenda item topic/title. NEVER leave empty),
    description: string (REQUIRED - details about what needs to be discussed. NEVER leave empty),
    priority: "high"/"medium"/"low",
    estimated_time: integer (minutes),
    presenter: name or null,
    related_action_items: array,
    category: "follow-up"/"review"/"decision"/"discussion"/"presentation"/"planning"/"blocker-resolution"
  }})
- participants (array of strings)"""


def get_executive_project_prompt(
    project_name: str,
    content_title: str,
    content_text: str,
    meetings_list: str
) -> str:
    """Generate executive-focused project summary prompt."""
    return f"""Generate an EXECUTIVE PROJECT SUMMARY. Focus on strategic progress, key decisions, and critical issues only.

Project: {project_name}
Period: {content_title}
Meetings included:
{meetings_list}

STRUCTURED MEETING DATA:
{content_text}

EXECUTIVE PROJECT BRIEF REQUIREMENTS:
- Maximum 750 words for summary_text
- Strategic progress against objectives
- Critical decisions and their business impact
- Budget/resource implications
- High-level risks and mitigation status
- Team performance indicators
- Key metrics and KPIs for the week

Format your response as JSON with these keys:
- summary_text (string: executive brief, MAX 750 words)
- key_points (array: 3-5 strategic achievements only)
- decisions (array of objects: {{description, importance_score: "high" for strategic/"medium" for operational, decision_type: "strategic"/"operational", stakeholders_affected: array, rationale: string explaining why this decision was made and its expected impact - REQUIRED, must not be empty}})
- action_items (array: critical items for executive attention)
- lessons_learned (array of objects: {{
    title: string (REQUIRED - brief lesson title),
    description: string (REQUIRED - detailed lesson description),
    category: string,
    lesson_type: string,
    impact: "high",
    recommendation: "strategic recommendation"
  }})
- risks (array of objects: {{
    title: string (REQUIRED - brief risk title, max 100 chars),
    description: string (REQUIRED - detailed risk description),
    severity: "high"/"critical",
    mitigation_strategy: string or null,
    potential_impact: string or null
  }})
- blockers (array of objects: {{
    title: string (REQUIRED - brief blocker title, max 100 chars),
    description: string (REQUIRED - detailed blocker description),
    impact: "high",
    status: string,
    owner: string or null,
    required_executive_action: string or null
  }})
- sentiment (object: organizational health indicators)
- communication_insights (object: leadership and alignment issues)
- next_meeting_agenda (array of objects: {{
    title: string (REQUIRED - strategic planning topic. NEVER leave empty),
    description: string (REQUIRED - strategic details to plan/discuss. NEVER leave empty),
    priority: "high"/"medium"/"low",
    estimated_time: integer (minutes, default 15),
    presenter: string or null,
    category: "strategic_planning"/"review"/"decision",
    related_action_items: array of strings
  }})
- participants (array: key stakeholders mentioned)"""


def get_technical_project_prompt(
    project_name: str,
    content_title: str,
    content_text: str,
    meetings_list: str
) -> str:
    """Generate technical-focused project summary prompt."""
    return f"""Generate a TECHNICAL PROJECT SUMMARY. Focus on development progress, technical decisions, and engineering metrics.

Project: {project_name}
Period: {content_title}
Meetings included:
{meetings_list}

STRUCTURED MEETING DATA:
{content_text}

TECHNICAL PROJECT REQUIREMENTS:
- Development velocity and sprint progress
- Technical decisions and architecture changes
- Code quality metrics and review outcomes
- Bug fixes and technical debt addressed
- Performance improvements
- Technology stack updates
- DevOps and infrastructure changes

Format your response as JSON with these keys:
- summary_text (string: technical progress report)
- key_points (array: technical milestones achieved)
- decisions (array: technical/architectural decisions)
- action_items (array: development tasks and technical improvements)
- risks (array: technical risks, security vulnerabilities)
- blockers (array: technical blockers, dependency issues)
- sentiment (object: team technical confidence)
- communication_insights (object: knowledge sharing, documentation gaps)
- next_meeting_agenda (array of objects: {{
    title: string (REQUIRED - technical planning topic. NEVER leave empty),
    description: string (REQUIRED - technical details to plan/review. NEVER leave empty),
    priority: "high"/"medium"/"low",
    estimated_time: integer (minutes, default 15),
    presenter: string or null,
    category: "technical_planning"/"review"/"architecture",
    related_action_items: array of strings
  }})
- participants (array: technical team members)"""


def get_stakeholder_project_prompt(
    project_name: str,
    content_title: str,
    content_text: str,
    meetings_list: str
) -> str:
    """Generate stakeholder-focused project summary prompt."""
    return f"""Generate a STAKEHOLDER PROJECT SUMMARY. Focus on deliverables, milestones, and client-facing progress.

Project: {project_name}
Period: {content_title}
Meetings included:
{meetings_list}

STRUCTURED MEETING DATA:
{content_text}

STAKEHOLDER PROJECT REQUIREMENTS:
- Progress on deliverables and milestones
- Client feedback and satisfaction indicators
- Timeline adherence and schedule updates
- External dependencies status
- Upcoming demos or client meetings
- Business value delivered
- Clear, non-technical language

Format your response as JSON with these keys:
- summary_text (string: business-friendly progress update)
- key_points (array: delivered value, milestones reached)
- decisions (array: decisions affecting delivery/stakeholders)
- action_items (array: client-facing preparations)
- risks (array: delivery risks, stakeholder concerns)
- blockers (array: external dependencies)
- sentiment (object: client satisfaction trends)
- communication_insights (object: stakeholder engagement effectiveness)
- next_meeting_agenda (array of objects: {{
    title: string (REQUIRED - client review/demo topic. NEVER leave empty),
    description: string (REQUIRED - what to present/review with client. NEVER leave empty),
    priority: "high"/"medium"/"low",
    estimated_time: integer (minutes, default 15),
    presenter: string or null,
    category: "client_review"/"demo"/"feedback",
    related_action_items: array of strings
  }})
- participants (array: stakeholders and client contacts)"""


def get_placeholder_meeting_summary(
    project_name: str,
    content_title: str
) -> dict:
    """Generate a placeholder summary when Claude API is not available."""
    summary_text = f"""Meeting Summary for {content_title}
    
This is a placeholder summary for the meeting '{content_title}' in project '{project_name}'.
The actual summary would include key discussion points, decisions made, and action items identified during the meeting.

Claude API is not configured or available, so this placeholder is shown instead."""
    
    return {
        "summary_text": summary_text,
        "key_points": [
            f"Discussion point from {content_title}",
            "Key topic covered in the meeting",
            "Important update shared"
        ],
        "decisions": [
            "Decision placeholder - actual decisions would be extracted from meeting"
        ],
        "action_items": [
            f"Action item from {content_title}",
            "Follow-up task to be completed"
        ],
        "participants": ["Participant 1", "Participant 2"],
        "risks": [],
        "blockers": [],
        "sentiment": {
            "overall": "neutral",
            "confidence": 0.5,
            "key_emotions": ["engaged"],
            "trend": "stable"
        },
        "communication_insights": {},
        "next_meeting_agenda": []
    }


def get_placeholder_weekly_summary(
    project_name: str,
    content_title: str
) -> dict:
    """Generate a placeholder weekly summary when Claude API is not available."""
    summary_text = f"""Weekly Summary for {content_title}
    
This is a placeholder summary for the week '{content_title}' in project '{project_name}'.
The actual summary would consolidate insights from all meetings during this week.

Claude API is not configured or available, so this placeholder is shown instead."""
    
    return {
        "summary_text": summary_text,
        "key_points": [
            f"Weekly achievement from {content_title}",
            "Progress made during the week",
            "Milestone reached"
        ],
        "decisions": [
            "Weekly decision placeholder"
        ],
        "action_items": [
            f"Consolidated action from {content_title}",
            "Weekly task to be completed"
        ],
        "participants": ["Team Member 1", "Team Member 2", "Team Member 3"],
        "risks": ["Potential risk identified"],
        "blockers": [],
        "sentiment": {
            "overall": "positive",
            "confidence": 0.7,
            "key_emotions": ["productive", "collaborative"],
            "trend": "improving"
        },
        "communication_insights": {
            "unanswered_questions": [],
            "effectiveness_score": {
                "clarity": 7,
                "engagement": 8,
                "productivity": 7
            },
            "improvement_suggestions": []
        },
        "next_meeting_agenda": [
            {
                "title": "Review weekly progress",
                "description": "Discuss achievements and plan for next week",
                "priority": "high",
                "estimated_time": 30,
                "presenter": "Team Lead",
                "related_action_items": [],
                "category": "review"
            }
        ]
    }


def get_program_summary_prompt(program_name: str, summary_title: str, aggregated_content: str, project_list: list, format_type: str = "general") -> str:
    """Generate a prompt for program-level summary based on format type."""

    if format_type == "executive":
        return f"""
You are an executive assistant preparing a strategic program summary for executives.
Focus on high-level insights, strategic alignment, and key decisions across all projects.

Program: {program_name}
Period: {summary_title}
Projects in Program ({len(project_list)}): {', '.join(project_list)}

Aggregated Project Content:
{aggregated_content}

Generate an EXECUTIVE program summary with:
1. Strategic overview (50 words)
2. Cross-project synergies and dependencies
3. Major decisions and their strategic impact
4. Program-level risks and mitigation strategies
5. Resource allocation insights
6. Key performance indicators across projects
7. Executive recommendations

Limit: 300 words. Focus on strategic value and decision-making insights.

Format your response as JSON with these keys:
- summary_text (string: executive program overview, MAX 300 words)
- key_points (array of strings: strategic highlights only)
- decisions (array of objects with strategic/financial impact)
- action_items (array of critical items requiring executive oversight)
- risks (array of high-level program risks)
- blockers (array requiring executive intervention)
- financial_summary (object: {{budget_utilization, roi_projection, cost_variance}})
- strategic_alignment (object: {{alignment_score: 0-100, key_objectives_met, recommendations}})
"""
    elif format_type == "technical":
        return f"""
You are a technical program manager preparing a detailed technical summary.
Focus on technical decisions, architecture changes, and implementation details across projects.

Program: {program_name}
Period: {summary_title}
Projects in Program ({len(project_list)}): {', '.join(project_list)}

Aggregated Project Content:
{aggregated_content}

Generate a TECHNICAL program summary with:
1. Technical architecture decisions across projects
2. Integration points and dependencies
3. Technical debt and refactoring needs
4. Performance metrics and optimizations
5. Security considerations
6. Technology stack changes
7. Technical roadblocks and solutions

Include code patterns, API changes, and technical specifications where relevant.

Format your response as JSON with these keys:
- summary_text (string: technical program overview)
- key_points (array of strings: technical achievements and milestones)
- decisions (array of technical decisions with rationale)
- action_items (array of technical tasks and assignments)
- risks (array of technical risks and debt)
- blockers (array of technical impediments)
- technical_metrics (object: {{code_quality_score, test_coverage, performance_metrics, security_score}})
- architecture_insights (object: {{patterns_adopted, tech_stack_changes, integration_points}})
"""
    elif format_type == "stakeholder":
        return f"""
You are preparing a program summary for external stakeholders.
Focus on deliverables, milestones, and business value across all projects.

Program: {program_name}
Period: {summary_title}
Projects in Program ({len(project_list)}): {', '.join(project_list)}

Aggregated Project Content:
{aggregated_content}

Generate a STAKEHOLDER program summary with:
1. Program objectives and progress
2. Completed deliverables across projects
3. Upcoming milestones and timelines
4. Business value delivered
5. Stakeholder impact analysis
6. Communication points
7. Next steps and expectations

Limit: 250 words for summary_text. Use clear, non-technical language.

You MUST respond ONLY with valid JSON. DO NOT ask questions or provide explanations outside the JSON structure.
Format your response as JSON with these EXACT structures:
- summary_text (string: stakeholder program overview, MAX 250 words)
- key_points (array of strings: 3-5 business value highlights and outcomes)
- decisions (array of objects: {{
    description: string (clear business decision description),
    importance_score: "high"/"medium"/"low",
    decision_type: "strategic"/"operational"/"tactical",
    stakeholders_affected: array of strings (stakeholder groups),
    rationale: string (business justification)
  }})
- action_items (array of objects: {{
    title: string (REQUIRED - clear action title),
    description: string (REQUIRED - detailed stakeholder-relevant action),
    urgency: "high"/"medium"/"low",
    due_date: ISO date string or null,
    assignee: string or null (responsible party),
    dependencies: array of strings,
    status: "not_started"/"in_progress"/"completed",
    follow_up_required: boolean
  }})
- risks (array of objects: {{
    title: string (REQUIRED - brief risk title, max 100 chars),
    description: string (REQUIRED - detailed business risk description),
    severity: "critical"/"high"/"medium"/"low",
    category: string (business/market/operational/financial),
    mitigation: string or null (mitigation strategy),
    owner: string or null
  }})
- blockers (array of objects: {{
    title: string (REQUIRED - brief blocker title, max 100 chars),
    description: string (REQUIRED - detailed blocker description),
    impact: "critical"/"high"/"medium"/"low",
    status: "active"/"resolved"/"pending",
    resolution: string or null (resolution approach),
    target_date: ISO date string or null
  }})
- value_delivered (object: {{
    features_completed: array of strings,
    business_outcomes: array of strings,
    user_impact: array of strings
  }})
- stakeholder_feedback (object: {{
    satisfaction_level: string,
    key_concerns: array of strings,
    requests: array of strings
  }})
- next_meeting_agenda (array of objects: {{
    title: string (REQUIRED - agenda item topic/title. NEVER leave empty),
    description: string (REQUIRED - details about what needs to be discussed. NEVER leave empty),
    priority: "high"/"medium"/"low",
    estimated_time: number (minutes)
  }})

IMPORTANT: All arrays of decisions, action_items, risks, and blockers MUST contain properly structured objects, not simple strings.
"""
    else:  # general format
        return f"""
You are summarizing a program that contains multiple projects.

Program: {program_name}
Period: {summary_title}
Projects in Program ({len(project_list)}): {', '.join(project_list)}

Aggregated Project Content:
{aggregated_content}

Generate a comprehensive program summary that includes:
1. Overall program progress and status
2. Key achievements across all projects
3. Major decisions and their impact
4. Cross-project dependencies and synergies
5. Program-level risks and issues
6. Resource utilization and team performance
7. Next steps and recommendations

Provide a balanced view covering all aspects of the program.

Format your response as JSON with these keys:
- summary_text (string: comprehensive program overview)
- key_points (array of strings: major program achievements and milestones)
- decisions (array of objects: {{description, importance_score, decision_type, stakeholders_affected, rationale: string (REQUIRED - explain why and expected impact)}})
- action_items (array of objects: {{
    title: string (REQUIRED - clear action title),
    description: string (REQUIRED - detailed action description),
    urgency: string,
    due_date: ISO date string or null,
    assignee: string or null,
    dependencies: array,
    status: string
  }})
- sentiment_analysis (object: {{overall: "positive"/"neutral"/"negative", trajectory: array of strings, topics: object with topic sentiments, engagement: object with participant engagement levels, scores: {{positive: 0-1, neutral: 0-1, negative: 0-1}}}})
- risks (array of objects: {{
    title: string (REQUIRED - brief risk title, max 100 chars),
    description: string (REQUIRED - detailed risk description),
    severity: string,
    category: string,
    mitigation: string or null,
    owner: string or null
  }})
- blockers (array of objects: {{
    title: string (REQUIRED - brief blocker title, max 100 chars),
    description: string (REQUIRED - detailed blocker description),
    impact: string,
    status: string,
    category: string,
    resolution: string or null,
    owner: string or null
  }})
- communication_insights (object: {{unanswered_questions: array, follow_ups: array, clarity_issues: array, agenda_alignment: object, effectiveness_score: object, improvement_suggestions: array}})
- cross_project_dependencies (array of objects: {{from_project, to_project, dependency_type, status, impact}})
- resource_metrics (object: {{utilization_rate, team_capacity, budget_status, timeline_status}})
- program_health (object: {{overall_status: "on-track"/"at-risk"/"delayed", confidence_score: 0-100, trend: "improving"/"stable"/"declining"}})
"""


def get_portfolio_summary_prompt(portfolio_name: str, summary_title: str, aggregated_content: str, program_list: list, project_list: list, format_type: str = "general") -> str:
    """Generate a prompt for portfolio-level summary based on format type."""

    if format_type == "executive":
        return f"""
You are an executive assistant preparing a strategic portfolio summary for C-level executives.
Focus on portfolio-wide strategic insights, organizational alignment, and executive decisions.

Portfolio: {portfolio_name}
Period: {summary_title}
Programs ({len(program_list)}): {', '.join(program_list) if program_list else 'None'}
Total Projects ({len(project_list)}): {', '.join(project_list)}

Aggregated Portfolio Content:
{aggregated_content}

Generate an EXECUTIVE portfolio summary with:
1. Portfolio strategic overview (75 words)
2. Business value and ROI across programs
3. Strategic alignment and organizational impact
4. Executive decisions and board-level items
5. Portfolio-wide risks and opportunities
6. Resource optimization and capacity planning
7. Strategic recommendations and priorities

Limit: 400 words. Focus on C-level insights and strategic value.

Format your response as JSON with these keys:
- summary_text (string: executive portfolio overview, MAX 400 words)
- key_points (array of strings: C-level strategic highlights)
- decisions (array of strategic decisions with board-level impact)
- action_items (array of critical items for executive action)
- risks (array of portfolio-level strategic risks)
- blockers (array requiring C-level intervention)
- executive_dashboard (object: {{portfolio_value, roi_actual_vs_projected, strategic_goal_alignment, market_position}})
- board_items (array of objects: {{topic, recommendation, impact_analysis, required_approval}})
- investment_analysis (object: {{total_investment, realized_value, projected_returns, recommendation}})
"""
    elif format_type == "technical":
        return f"""
You are a chief architect preparing a technical portfolio summary.
Focus on enterprise architecture, technology standards, and cross-program technical strategies.

Portfolio: {portfolio_name}
Period: {summary_title}
Programs ({len(program_list)}): {', '.join(program_list) if program_list else 'None'}
Total Projects ({len(project_list)}): {', '.join(project_list)}

Aggregated Portfolio Content:
{aggregated_content}

Generate a TECHNICAL portfolio summary with:
1. Enterprise architecture decisions and patterns
2. Technology standardization across programs
3. Technical debt assessment and remediation
4. Platform and infrastructure considerations
5. Security and compliance status
6. Innovation and R&D initiatives
7. Technical capability roadmap

Include architectural diagrams references, technology stack evolution, and technical standards.

Format your response as JSON with these keys:
- summary_text (string: technical portfolio overview)
- key_points (array of strings: enterprise architecture achievements)
- decisions (array of technical/architectural decisions)
- action_items (array of technical initiatives and standards)
- risks (array of technical debt and security risks)
- blockers (array of technical/infrastructure impediments)
- enterprise_architecture (object: {{maturity_level, standardization_score, integration_complexity, technical_debt_ratio}})
- technology_landscape (object: {{platforms_in_use, consolidation_opportunities, innovation_initiatives, compliance_status}})
- capability_assessment (object: {{current_capabilities, gaps_identified, roadmap_priorities}})
"""
    elif format_type == "stakeholder":
        return f"""
You are preparing a portfolio summary for board members and external stakeholders.
Focus on business outcomes, strategic initiatives, and stakeholder value.

Portfolio: {portfolio_name}
Period: {summary_title}
Programs ({len(program_list)}): {', '.join(program_list) if program_list else 'None'}
Total Projects ({len(project_list)}): {', '.join(project_list)}

Aggregated Portfolio Content:
{aggregated_content}

Generate a STAKEHOLDER portfolio summary with:
1. Portfolio vision and strategic objectives
2. Business outcomes and value delivered
3. Major milestones and achievements
4. Stakeholder benefits and impact
5. Market position and competitive advantages
6. Partnership and collaboration updates
7. Future outlook and commitments

Limit: 350 words for summary_text. Use clear business language suitable for external communication.

You MUST respond ONLY with valid JSON. DO NOT ask questions or provide explanations outside the JSON structure.
Format your response as JSON with these EXACT structures:
- summary_text (string: stakeholder portfolio overview, MAX 350 words)
- key_points (array of strings: 5-7 strategic business outcomes and value delivered)
- decisions (array of objects: {{
    description: string (strategic business decision),
    importance_score: "high"/"medium"/"low",
    decision_type: "strategic"/"operational"/"tactical",
    stakeholders_affected: array of strings (board/investors/customers/partners),
    rationale: string (business case and expected impact)
  }})
- action_items (array of objects: {{
    title: string (REQUIRED - clear action title),
    description: string (REQUIRED - detailed stakeholder commitment or action),
    urgency: "high"/"medium"/"low",
    due_date: ISO date string or null,
    assignee: string or null (responsible executive/team),
    dependencies: array of strings,
    status: "not_started"/"in_progress"/"completed",
    follow_up_required: boolean
  }})
- risks (array of objects: {{
    title: string (REQUIRED - brief risk title, max 100 chars),
    description: string (REQUIRED - detailed market/business risk description),
    severity: "critical"/"high"/"medium"/"low",
    category: string (market/financial/regulatory/operational/reputational),
    mitigation: string or null (mitigation strategy),
    owner: string or null (risk owner)
  }})
- blockers (array of objects: {{
    title: string (REQUIRED - brief blocker title, max 100 chars),
    description: string (REQUIRED - detailed issue requiring stakeholder resolution),
    impact: "critical"/"high"/"medium"/"low",
    status: "active"/"resolved"/"pending",
    resolution: string or null (proposed resolution),
    target_date: ISO date string or null
  }})
- business_outcomes (object: {{
    revenue_impact: string,
    market_share_change: string,
    customer_satisfaction: string,
    operational_efficiency: string
  }})
- stakeholder_matrix (array of objects: {{
    stakeholder_group: string,
    engagement_level: "high"/"medium"/"low",
    satisfaction_score: number (1-10),
    key_concerns: array of strings
  }})
- value_realization (object: {{
    planned_benefits: array of strings,
    realized_benefits: array of strings,
    benefit_realization_rate: string (percentage),
    next_quarter_targets: array of strings
  }})
- next_meeting_agenda (array of objects: {{
    title: string (REQUIRED - agenda item topic/title. NEVER leave empty),
    description: string (REQUIRED - details about what needs to be discussed. NEVER leave empty),
    priority: "high"/"medium"/"low",
    estimated_time: number (minutes)
  }})

IMPORTANT: All arrays of decisions, action_items, risks, and blockers MUST contain properly structured objects with all specified fields, not simple strings.
"""
    else:  # general format
        return f"""
You are summarizing a portfolio that contains multiple programs and projects.

Portfolio: {portfolio_name}
Period: {summary_title}
Programs ({len(program_list)}): {', '.join(program_list) if program_list else 'None'}
Total Projects ({len(project_list)}): {', '.join(project_list)}

Aggregated Portfolio Content:
{aggregated_content}

Generate a comprehensive portfolio summary that includes:
1. Portfolio health and overall status
2. Program and project performance overview
3. Strategic achievements and milestones
4. Cross-program synergies and dependencies
5. Portfolio-level risks and mitigation strategies
6. Resource allocation and capacity analysis
7. Strategic recommendations and next steps

Provide a holistic view of the entire portfolio with insights at multiple levels.

Format your response as JSON with these keys:
- summary_text (string: comprehensive portfolio overview)
- key_points (array of strings: major portfolio achievements)
- decisions (array of objects: {{description, importance_score, decision_type, stakeholders_affected, rationale: string (REQUIRED - explain why and expected impact)}})
- action_items (array of objects: {{
    title: string (REQUIRED - clear action title),
    description: string (REQUIRED - detailed action description),
    urgency: string,
    due_date: ISO date string or null,
    assignee: string or null,
    dependencies: array,
    status: string
  }})
- sentiment_analysis (object: {{overall: "positive"/"neutral"/"negative", trajectory: array of strings, topics: object with topic sentiments, engagement: object with participant engagement levels, scores: {{positive: 0-1, neutral: 0-1, negative: 0-1}}}})
- risks (array of objects: {{
    title: string (REQUIRED - brief risk title, max 100 chars),
    description: string (REQUIRED - detailed risk description),
    severity: string,
    category: string,
    mitigation: string or null,
    owner: string or null
  }})
- blockers (array of objects: {{
    title: string (REQUIRED - brief blocker title, max 100 chars),
    description: string (REQUIRED - detailed blocker description),
    impact: string,
    status: string,
    category: string,
    resolution: string or null,
    owner: string or null
  }})
- communication_insights (object: {{unanswered_questions: array, follow_ups: array, clarity_issues: array, agenda_alignment: object, effectiveness_score: object, improvement_suggestions: array}})
- program_performance (array of objects: {{program_name, status, health_score, key_metrics}})
- portfolio_metrics (object: {{total_budget, budget_consumed, overall_timeline_status, resource_allocation}})
- strategic_initiatives (array of objects: {{initiative_name, progress_percentage, impact_assessment, next_milestones}})
- governance_items (array of objects: {{item_type, description, decision_required, escalation_level}})
- cross_project_dependencies (array of objects: {{from_project, to_project, dependency_type, status, impact}})
- executive_dashboard (object: {{key_highlights, portfolio_health_score, strategic_alignment_score, risk_level, upcoming_milestones}})
"""