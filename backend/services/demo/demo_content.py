"""Demo data content constants for new organization onboarding.

All string constants and structured data used by the demo seed service.
Dates are computed at runtime relative to now() so demo data always looks fresh.
"""

# =============================================================================
# Portfolio & Program
# =============================================================================

PORTFOLIO = {
    "name": "Digital Transformation Portfolio",
    "description": (
        "Strategic initiative to modernize customer-facing digital products "
        "and internal processes. Encompasses mobile app redesign, AI-powered "
        "customer support, and cloud infrastructure upgrades."
    ),
    "owner": "Sarah Chen",
    "health_status": "green",
}

PROGRAM = {
    "name": "Customer Experience Program",
    "description": (
        "A collection of projects focused on improving the end-to-end customer "
        "experience across digital channels, including mobile banking and "
        "AI-powered support tools."
    ),
}

# =============================================================================
# Project 1: Mobile Banking App Redesign
# =============================================================================

PROJECT_1 = {
    "name": "Mobile Banking App Redesign",
    "description": (
        "Complete redesign of the mobile banking application with biometric "
        "authentication (Face ID & fingerprint), infinite scroll transaction "
        "history, smart categorization, and performance optimization."
    ),
}

PROJECT_1_CONTENT = [
    {
        "content_type": "meeting",
        "title": "Sprint Planning - Week 3",
        "days_ago": 7,
        "content": """Project: Mobile Banking App Redesign
Meeting: Sprint Planning - Week 3
Duration: 45 minutes
Attendees: Sarah Chen (PM), Marcus Rodriguez (Tech Lead), Emily Park (UX Designer), James Wilson (Backend Dev), Lisa Kumar (QA)

================================================================================

[00:00] Sarah Chen:
Good morning everyone. Thanks for joining the sprint planning call. We're starting week 3 of the mobile banking app redesign project. I want to review where we are and plan the next two weeks of work.

[00:45] Sarah Chen:
First, quick wins from last sprint. We completed the new login flow design and the backend API for transaction history. Emily, the prototype looked great in stakeholder review. They loved the fingerprint authentication flow.

[01:15] Emily Park:
Thanks Sarah. The feedback was really positive. One thing though - the VP of Product asked if we could add Face ID support alongside fingerprint. Is that in scope for this sprint?

[01:30] Marcus Rodriguez:
That's doable from a technical standpoint. iOS has native support and Android has BiometricPrompt API. I'd estimate maybe 3-4 days of development work.

[01:50] James Wilson:
Yeah, I can handle that. The architecture is already set up for biometric auth. Adding Face ID is mostly configuration and testing across different devices. I'd say 3 days is realistic if we prioritize it.

[02:10] Sarah Chen:
Okay, let's add that to the sprint backlog as high priority. Emily, can you update the design specs to include Face ID flows?

[02:20] Emily Park:
Already on it. I'll have updated screens by end of day tomorrow.

[02:25] Sarah Chen:
Now, the big item for this sprint is the transaction history redesign. Marcus, can you walk us through the technical approach?

[02:40] Marcus Rodriguez:
We're moving from the old paginated list to an infinite scroll with smart categorization. The backend team finished the new API endpoints last week. We're using Redis for caching to keep load times under 200 milliseconds.

[03:05] Marcus Rodriguez:
One challenge we're facing - the legacy database schema doesn't have proper indexing on transaction dates. We're seeing query times around 2-3 seconds for users with large transaction histories.

[03:25] Sarah Chen:
That sounds like a blocker. What's the solution?

[03:30] James Wilson:
I've been working with the DBA team on this. We need to add composite indexes on user_id and transaction_date columns. The production database has 15 million records. The indexing operation will take about 4 hours and we need a maintenance window.

[03:50] Sarah Chen:
When can we schedule this?

[04:00] James Wilson:
DBA team suggested next Saturday night, 11 PM to 3 AM when traffic is lowest. We'd need approval from operations and a rollback plan.

[04:15] Sarah Chen:
I'll talk to operations today. Let's document this as a critical path item. James, you own that action item - coordinate with DBA and operations for Saturday maintenance window. I need confirmation by Wednesday EOD.

[05:20] Sarah Chen:
Emily, let's talk about the UX for transaction categorization. What's the latest?

[05:30] Emily Park:
We're going with automatic categorization using merchant data plus user ability to create custom categories. I ran user testing sessions last week with 12 participants. The feedback was mostly positive.

[06:50] Sarah Chen:
Let's put the transaction splitting feature in the backlog for a future sprint. For now, single category per transaction.

[07:30] Lisa Kumar:
Quick update on testing. I've set up automated UI tests for the login and biometric flows. We're at 78% code coverage on the auth module. I'm also setting up device testing on BrowserStack to cover the top 20 Android devices.

[08:00] Sarah Chen:
Great work Lisa. One concern - are we confident about the March 15th launch date? That gives us about 8 more weeks.

[08:15] Marcus Rodriguez:
If we get the database maintenance window and don't hit major issues, I'd say we're at about 70% confidence. The biggest risk is the performance optimization work.

[08:45] Sarah Chen:
Alright team, let's wrap up. Action items: James coordinates the database maintenance, Emily updates Face ID designs, Lisa sets up BrowserStack, and Marcus starts the infinite scroll implementation. Next standup is Wednesday. Thanks everyone!""",
    },
    {
        "content_type": "meeting",
        "title": "Design Review - Transaction History UI",
        "days_ago": 4,
        "content": """Project: Mobile Banking App Redesign
Meeting: Design Review - Transaction History UI
Duration: 60 minutes
Attendees: Emily Park (UX Designer), Marcus Rodriguez (Tech Lead), Sarah Chen (PM), David Kim (VP of Product)

================================================================================

[00:00] Emily Park:
Thanks everyone for joining the design review. Today we're walking through the transaction history redesign. I'll share the Figma prototype.

[00:20] Emily Park:
Three core design principles. First, clarity over density - showing less information per transaction but making it more scannable. Second, context-aware categorization. Third, progressive disclosure - advanced features don't overwhelm casual users.

[01:35] Emily Park:
Each transaction is a card with the merchant logo, amount, category, and date. Users can swipe left for quick actions or swipe right to mark as recurring expense.

[03:10] Emily Park:
The filtering system supports natural language. You can type "coffee last month" and it shows coffee purchases from the previous month.

[03:45] Marcus Rodriguez:
We're using a lightweight NLP library that parses common patterns. Things like "groceries this week" or "transactions over 100 dollars."

[04:05] David Kim:
Love it. This is exactly the kind of smart feature that differentiates us from competitors.

[04:15] Emily Park:
We have 12 default categories - groceries, dining, transportation, entertainment, shopping, bills, healthcare, travel, fitness, education, income, and other. Each with a distinct color and icon.

[05:40] Emily Park:
We've checked the color palette for accessibility. Using shapes in addition to colors for categories to handle color blindness.

[06:10] Emily Park:
The insights dashboard aggregates transaction data to show spending patterns over time. Monthly spending chart showing trends across categories.

[07:00] David Kim:
This is excellent work Emily. I think we're ready to move into implementation. Let's aim to have the first version ready for internal testing by end of next sprint.

[07:15] Sarah Chen:
Agreed. Marcus, can your team start the frontend implementation alongside the backend performance work?

[07:25] Marcus Rodriguez:
Yes, we can run them in parallel. I'll split the team - two engineers on frontend, one on backend optimization.

[07:45] Sarah Chen:
Perfect. Let's schedule a follow-up review in two weeks to check implementation progress. Great work everyone!""",
    },
]

PROJECT_1_SUMMARY = {
    "summary_type": "meeting",
    "subject": "Sprint Planning - Week 3 Summary",
    "body": (
        "The team reviewed progress on the mobile banking app redesign during the Week 3 sprint "
        "planning meeting. Key discussions centered on adding Face ID support alongside fingerprint "
        "authentication, addressing database performance issues affecting transaction history load times, "
        "and planning the transaction history UI redesign with smart categorization. The team expressed "
        "70% confidence in the March 15th launch date, contingent on resolving database indexing issues."
    ),
    "format": "general",
    "key_points": [
        "Login flow design and transaction history API completed from previous sprint",
        "VP of Product requested Face ID support - estimated at 3 days of work",
        "Database query times of 2-3 seconds identified as performance bottleneck",
        "Maintenance window needed for 4-hour database indexing operation",
        "User testing showed strong positive feedback for transaction categorization UX",
        "78% code coverage achieved on authentication module",
    ],
    "decisions": [
        {
            "decision": "Add Face ID support to this sprint as high priority",
            "rationale": "VP of Product requested it; architecture already supports biometric auth",
            "owner": "James Wilson",
        },
        {
            "decision": "Defer transaction splitting feature to future sprint",
            "rationale": "Requires significant data model redesign - a full sprint of work",
            "owner": "Sarah Chen",
        },
        {
            "decision": "Schedule database maintenance window for Saturday 11 PM - 3 AM",
            "rationale": "Lowest traffic period; 15M records need composite index on user_id and transaction_date",
            "owner": "James Wilson",
        },
    ],
    "action_items": [
        {
            "action": "Coordinate database maintenance window with DBA and operations team",
            "assignee": "James Wilson",
            "due_date": "Wednesday EOD",
            "status": "in_progress",
        },
        {
            "action": "Update design specs to include Face ID authentication flows",
            "assignee": "Emily Park",
            "due_date": "End of day tomorrow",
            "status": "completed",
        },
        {
            "action": "Set up BrowserStack for top 20 Android device testing",
            "assignee": "Lisa Kumar",
            "due_date": "This sprint",
            "status": "in_progress",
        },
        {
            "action": "Begin infinite scroll implementation for transaction history",
            "assignee": "Marcus Rodriguez",
            "due_date": "This sprint",
            "status": "in_progress",
        },
    ],
    "sentiment_analysis": {
        "overall": "positive",
        "trajectory": "stable",
        "engagement": "high",
        "topics": {
            "biometric_auth": "positive",
            "database_performance": "concerned",
            "ux_design": "very_positive",
            "timeline": "cautiously_optimistic",
        },
    },
    "risks": [
        {
            "title": "Database indexing may cause downtime",
            "description": "4-hour maintenance window needed for production database with 15M records",
            "severity": "medium",
            "owner": "James Wilson",
        },
        {
            "title": "March 15th launch date at risk",
            "description": "Team confidence at 70%, contingent on performance optimization success",
            "severity": "medium",
            "owner": "Sarah Chen",
        },
    ],
    "blockers": [
        {
            "title": "Legacy database schema lacks date indexing",
            "description": "Query times 2-3 seconds for users with large transaction histories",
            "impact": "high",
            "owner": "James Wilson",
        },
    ],
    "lessons_learned": [
        {
            "title": "Early stakeholder demos build alignment",
            "description": "Stakeholder review of prototype generated valuable feedback and buy-in",
            "category": "communication",
            "lesson_type": "success",
            "impact": "high",
        },
    ],
    "next_meeting_agenda": [
        {
            "title": "Database maintenance window status",
            "description": "Confirm Saturday maintenance window with operations",
            "priority": "high",
            "estimated_time": "5 minutes",
            "presenter": "James Wilson",
        },
        {
            "title": "Face ID implementation progress",
            "description": "Review biometric auth implementation status",
            "priority": "medium",
            "estimated_time": "10 minutes",
            "presenter": "James Wilson",
        },
        {
            "title": "Infinite scroll demo",
            "description": "Show progress on transaction history infinite scroll",
            "priority": "medium",
            "estimated_time": "15 minutes",
            "presenter": "Marcus Rodriguez",
        },
    ],
}

PROJECT_1_TASKS = [
    {
        "title": "Add Face ID authentication support",
        "description": (
            "Implement Face ID alongside existing fingerprint authentication. "
            "iOS uses native FaceID API, Android uses BiometricPrompt. "
            "Architecture already supports biometric auth - mostly configuration and device testing."
        ),
        "status": "in_progress",
        "priority": "high",
        "assignee": "James Wilson",
        "progress_percentage": 40,
        "due_days_from_now": 7,
    },
    {
        "title": "Implement infinite scroll for transaction history",
        "description": (
            "Replace paginated transaction list with infinite scroll. "
            "Backend APIs are ready. Use Redis caching to achieve <200ms load times. "
            "Include smart categorization with merchant logos."
        ),
        "status": "todo",
        "priority": "medium",
        "assignee": "Marcus Rodriguez",
        "progress_percentage": 0,
        "due_days_from_now": 14,
    },
    {
        "title": "Schedule database maintenance window for indexing",
        "description": (
            "Coordinate with DBA and operations team for Saturday 11 PM - 3 AM maintenance window. "
            "Need to add composite indexes on user_id and transaction_date columns. "
            "Prepare rollback procedure documentation."
        ),
        "status": "todo",
        "priority": "urgent",
        "assignee": "James Wilson",
        "progress_percentage": 0,
        "due_days_from_now": 3,
    },
]

PROJECT_1_RISKS = [
    {
        "title": "Database indexing migration may cause downtime",
        "description": (
            "Production database has 15M records. Adding composite indexes on user_id "
            "and transaction_date requires a 4-hour maintenance window. Risk of extended "
            "downtime if indexing fails or takes longer than expected."
        ),
        "severity": "medium",
        "status": "identified",
        "mitigation": (
            "Schedule during lowest traffic period (Saturday 11 PM - 3 AM). "
            "Prepare rollback procedure. Test indexing on staging environment first."
        ),
        "impact": "Service unavailability during maintenance window",
        "probability": 0.3,
        "assigned_to": "James Wilson",
    },
    {
        "title": "Third-party payment API rate limits",
        "description": (
            "Payment processing API has strict rate limits that may degrade performance "
            "during peak hours when many users access transaction history simultaneously."
        ),
        "severity": "high",
        "status": "mitigating",
        "mitigation": (
            "Implement request queuing and response caching. "
            "Negotiate higher rate limits with payment provider."
        ),
        "impact": "Degraded transaction history performance during peak usage",
        "probability": 0.4,
        "assigned_to": "Marcus Rodriguez",
    },
]

PROJECT_1_BLOCKER = {
    "title": "Legacy database schema lacks proper indexing on transaction dates",
    "description": (
        "Query times are 2-3 seconds for users with large transaction histories. "
        "The database needs composite indexes on user_id and transaction_date columns. "
        "This is blocking the infinite scroll implementation from meeting performance targets."
    ),
    "impact": "high",
    "status": "active",
    "owner": "James Wilson",
    "category": "technical",
}

PROJECT_1_LESSON = {
    "title": "Early stakeholder demos build alignment and surface requirements",
    "description": (
        "Presenting the login flow prototype to stakeholders early in the sprint "
        "generated valuable feedback (Face ID request) and built executive buy-in. "
        "This validates the practice of demoing work-in-progress rather than waiting "
        "for completion."
    ),
    "category": "communication",
    "lesson_type": "success",
    "impact": "high",
    "recommendation": (
        "Schedule stakeholder demos at the end of each sprint. "
        "Include interactive prototypes when possible."
    ),
}

# =============================================================================
# Project 2: Customer Support AI Chatbot
# =============================================================================

PROJECT_2 = {
    "name": "Customer Support AI Chatbot",
    "description": (
        "AI-powered chatbot to handle tier-1 customer support queries, integrated "
        "with the knowledge base and ticketing system. Targets 60% deflection rate "
        "for common inquiries while maintaining high customer satisfaction."
    ),
}

PROJECT_2_CONTENT = [
    {
        "content_type": "meeting",
        "title": "Chatbot Architecture Planning",
        "days_ago": 10,
        "content": """Project: Customer Support AI Chatbot
Meeting: Architecture Planning Session
Duration: 50 minutes
Attendees: Alex Rivera (Tech Lead), Sarah Chen (PM), Nina Patel (ML Engineer), Tom Blake (Backend Dev)

================================================================================

[00:00] Alex Rivera:
Let's kick off the architecture planning for the chatbot. We need to make decisions on the NLP stack, integration approach, and deployment strategy.

[01:00] Nina Patel:
For the NLP pipeline, I recommend a hybrid approach. Use a fine-tuned BERT model for intent classification combined with an LLM for response generation. The BERT model handles routing - determining what the user wants - and the LLM generates contextual responses.

[02:30] Alex Rivera:
What about using just the LLM for everything?

[02:45] Nina Patel:
Pure LLM approach is expensive at scale. With 50,000 monthly support queries, we'd spend roughly $15,000/month on API calls. The hybrid approach cuts that by 60% because BERT handles classification locally and we only call the LLM for complex responses.

[03:30] Sarah Chen:
Cost optimization is important. What's our accuracy target?

[03:40] Nina Patel:
85% intent classification accuracy is our target. Based on the training data analysis, we have good coverage for the top 15 intent categories. The challenge is the long tail of unusual queries.

[04:15] Tom Blake:
For integration with the ticketing system, I suggest using webhooks for real-time escalation. When the chatbot can't resolve an issue, it creates a pre-populated ticket with conversation context, reducing agent handling time.

[05:00] Alex Rivera:
Good. We also need a fallback strategy. If the chatbot confidence is below 70%, it should offer to connect the user with a human agent immediately.

[06:00] Sarah Chen:
What about the training data? I heard compliance needs to review it before we can use support ticket history.

[06:15] Nina Patel:
Yes, we need anonymized versions of about 50,000 historical tickets. Compliance said they need 2-3 weeks for the review and anonymization process. I've submitted the request.

[07:00] Sarah Chen:
That's a potential bottleneck. Let's track that as a blocker. In the meantime, can we start with synthetic training data?

[07:20] Nina Patel:
We can create synthetic data for the most common intents - password reset, account balance, transaction disputes. It won't be as good as real data but lets us start building and testing the pipeline.

[08:00] Sarah Chen:
Great plan. Let's target a working prototype in 3 weeks using synthetic data, then fine-tune with real data once compliance clears it. Action items: Nina starts the training pipeline, Tom builds the ticketing integration, Alex designs the conversation flow architecture.""",
    },
    {
        "content_type": "meeting",
        "title": "Chatbot Integration Testing Kickoff",
        "days_ago": 3,
        "content": """Project: Customer Support AI Chatbot
Meeting: Integration Testing Kickoff
Duration: 35 minutes
Attendees: Alex Rivera (Tech Lead), Tom Blake (Backend Dev), Nina Patel (ML Engineer), Lisa Kumar (QA)

================================================================================

[00:00] Alex Rivera:
We're starting integration testing this week. The chatbot prototype is working with synthetic data. Let's plan our testing approach.

[01:00] Lisa Kumar:
I've prepared a test suite with 200 test cases covering the top 15 intent categories. Each test case has an input message, expected intent, and expected response pattern.

[02:00] Nina Patel:
Current accuracy on synthetic data is 82%. We're slightly below our 85% target, but I expect improvement once we get the real training data from compliance.

[03:00] Tom Blake:
The ticketing integration is functional. When confidence drops below 70%, it creates a ticket with full conversation context. I tested with 50 escalation scenarios and all tickets were created correctly.

[04:00] Alex Rivera:
What about edge cases? Users sending emojis, multiple questions in one message, non-English queries?

[04:30] Lisa Kumar:
I have test cases for those. Emoji-only messages default to the human handoff. Multiple questions trigger a "let me help you one at a time" response. Non-English queries get a polite message asking to continue in English, with plans for multi-language support later.

[05:30] Alex Rivera:
Good coverage. Let's run the full test suite by Friday and review results Monday. Focus on any patterns where the chatbot gives incorrect responses - those are the ones that could damage customer trust.

[06:00] Sarah Chen:
One more thing - compliance just approved the first batch of anonymized tickets. 12,000 records. Nina, how quickly can you retrain?

[06:20] Nina Patel:
Give me 2-3 days for data preprocessing and retraining. We should see a noticeable accuracy improvement with real data.""",
    },
]

PROJECT_2_SUMMARY = {
    "summary_type": "meeting",
    "subject": "Chatbot Architecture Planning Summary",
    "body": (
        "The team defined the technical architecture for the AI chatbot, choosing a hybrid approach "
        "with BERT for intent classification and LLM for response generation. This reduces API costs "
        "by 60% compared to a pure LLM approach. The target is 85% intent classification accuracy "
        "across 15 intent categories. Key decisions include a webhook-based ticketing integration "
        "for seamless escalation and a 70% confidence threshold for human handoff."
    ),
    "format": "general",
    "key_points": [
        "Hybrid NLP approach: BERT for intent classification + LLM for response generation",
        "Cost optimization: hybrid approach saves 60% vs pure LLM ($6K vs $15K/month)",
        "Target: 85% intent classification accuracy across 15 categories",
        "Webhook integration with ticketing system for automated escalation",
        "70% confidence threshold for human agent handoff",
        "Compliance review needed for 50K historical support tickets (2-3 weeks)",
    ],
    "decisions": [
        {
            "decision": "Use hybrid BERT + LLM architecture instead of pure LLM",
            "rationale": "60% cost reduction while maintaining response quality",
            "owner": "Alex Rivera",
        },
        {
            "decision": "Start with synthetic training data while awaiting compliance approval",
            "rationale": "Allows pipeline development to proceed without blocking on compliance",
            "owner": "Nina Patel",
        },
        {
            "decision": "Set 70% confidence threshold for human agent escalation",
            "rationale": "Balances automation rate with customer satisfaction",
            "owner": "Alex Rivera",
        },
    ],
    "action_items": [
        {
            "action": "Build NLP training pipeline with synthetic data",
            "assignee": "Nina Patel",
            "due_date": "This sprint",
            "status": "in_progress",
        },
        {
            "action": "Build ticketing system webhook integration",
            "assignee": "Tom Blake",
            "due_date": "This sprint",
            "status": "completed",
        },
        {
            "action": "Design conversation flow architecture",
            "assignee": "Alex Rivera",
            "due_date": "This sprint",
            "status": "in_progress",
        },
    ],
    "sentiment_analysis": {
        "overall": "positive",
        "trajectory": "improving",
        "engagement": "high",
        "topics": {
            "architecture": "positive",
            "cost_optimization": "positive",
            "compliance_timeline": "concerned",
            "accuracy_targets": "cautiously_optimistic",
        },
    },
    "risks": [
        {
            "title": "NLP accuracy below target threshold",
            "description": "Model may not achieve 85% accuracy without real training data",
            "severity": "high",
            "owner": "Nina Patel",
        },
    ],
    "blockers": [
        {
            "title": "Compliance review blocking training data access",
            "description": "50K historical tickets need anonymization before use",
            "impact": "medium",
            "owner": "Nina Patel",
        },
    ],
    "lessons_learned": [
        {
            "title": "Start compliance review early for AI/ML projects",
            "description": "Data compliance can take weeks and blocks model training",
            "category": "process",
            "lesson_type": "improvement",
            "impact": "high",
        },
    ],
    "next_meeting_agenda": [
        {
            "title": "Integration test results review",
            "description": "Review results from 200-case test suite",
            "priority": "high",
            "estimated_time": "15 minutes",
            "presenter": "Lisa Kumar",
        },
        {
            "title": "Retraining progress with real data",
            "description": "Accuracy improvement after retraining with anonymized tickets",
            "priority": "high",
            "estimated_time": "10 minutes",
            "presenter": "Nina Patel",
        },
    ],
}

PROJECT_2_TASKS = [
    {
        "title": "Train NLP model on anonymized support ticket dataset",
        "description": (
            "Retrain the BERT intent classification model using 12,000 anonymized "
            "support tickets from compliance. Preprocess data, augment with synthetic "
            "examples, and fine-tune to achieve 85% accuracy target."
        ),
        "status": "in_progress",
        "priority": "high",
        "assignee": "Nina Patel",
        "progress_percentage": 30,
        "due_days_from_now": 10,
    },
    {
        "title": "Build fallback escalation to human agents",
        "description": (
            "Implement the escalation flow for when chatbot confidence is below 70%. "
            "Create pre-populated support tickets with full conversation context. "
            "Ensure smooth handoff experience for the customer."
        ),
        "status": "todo",
        "priority": "medium",
        "assignee": "Tom Blake",
        "progress_percentage": 0,
        "due_days_from_now": 14,
    },
    {
        "title": "Integrate chatbot with ticketing system API",
        "description": (
            "Complete webhook-based integration between chatbot and the ticketing system. "
            "Handle ticket creation, status updates, and agent assignment. "
            "Include conversation history in ticket context."
        ),
        "status": "todo",
        "priority": "medium",
        "assignee": "Tom Blake",
        "progress_percentage": 0,
        "due_days_from_now": 21,
    },
]

PROJECT_2_RISKS = [
    {
        "title": "NLP accuracy below target threshold",
        "description": (
            "The intent classification model may not achieve the 85% accuracy target on "
            "domain-specific financial queries without sufficient real training data. "
            "Current accuracy on synthetic data is 82%."
        ),
        "severity": "high",
        "status": "identified",
        "mitigation": (
            "Augment synthetic data with real anonymized tickets. "
            "Implement active learning to improve accuracy on edge cases. "
            "Consider domain-specific fine-tuning."
        ),
        "impact": "Incorrect responses could damage customer trust and increase escalations",
        "probability": 0.35,
        "assigned_to": "Nina Patel",
    },
    {
        "title": "Customer trust in AI-generated responses",
        "description": (
            "Users may distrust automated responses for financial queries. "
            "Need clear AI disclosure and easy escalation path to human agents."
        ),
        "severity": "medium",
        "status": "identified",
        "mitigation": (
            "Add clear 'AI Assistant' label to all chatbot messages. "
            "Provide one-click escalation to human agent at any point. "
            "Run customer feedback surveys after chatbot interactions."
        ),
        "impact": "Low adoption rate and negative customer feedback",
        "probability": 0.25,
        "assigned_to": "Alex Rivera",
    },
]

PROJECT_2_BLOCKER = {
    "title": "Waiting for anonymized training data from compliance",
    "description": (
        "Legal/compliance team needs to review and anonymize 50K historical support tickets "
        "before they can be used for model training. First batch of 12K tickets has been "
        "approved, but full dataset is needed for production accuracy targets."
    ),
    "impact": "medium",
    "status": "pending",
    "owner": "Nina Patel",
    "category": "compliance",
}

PROJECT_2_LESSON = {
    "title": "Start compliance review early for AI/ML projects",
    "description": (
        "The 2-3 week compliance review for training data created a bottleneck in the ML pipeline. "
        "Starting this process at project kickoff rather than after architecture planning would "
        "have saved significant time."
    ),
    "category": "process",
    "lesson_type": "improvement",
    "impact": "high",
    "recommendation": (
        "For any AI/ML project, submit data compliance requests in the first week. "
        "Use synthetic data to build the pipeline while waiting for real data approval."
    ),
}
