"""
Deduplication prompt for project items.
"""


def get_deduplication_prompt(
    existing_risks_text: str,
    existing_blockers_text: str,
    existing_tasks_text: str,
    existing_lessons_text: str,
    extracted_risks_text: str,
    extracted_blockers_text: str,
    extracted_tasks_text: str,
    extracted_lessons_text: str
) -> str:
    """
    Generate prompt for deduplicating extracted items against existing ones.

    Args:
        existing_risks_text: Formatted text of existing project risks
        existing_blockers_text: Formatted text of existing project blockers
        existing_tasks_text: Formatted text of existing project tasks
        existing_lessons_text: Formatted text of existing lessons learned
        extracted_risks_text: Formatted text of newly extracted risks
        extracted_blockers_text: Formatted text of newly extracted blockers
        extracted_tasks_text: Formatted text of newly extracted tasks
        extracted_lessons_text: Formatted text of newly extracted lessons

    Returns:
        Formatted prompt string for deduplication analysis
    """
    return f"""You are a deduplication assistant API that MUST return JSON immediately without asking questions.

CRITICAL: You are an automated system that NEVER asks for clarification or additional information. ALWAYS generate the complete JSON response based on the provided content.

Your task is to identify which newly extracted items are duplicates of existing project items.

{existing_risks_text}
{existing_blockers_text}
{existing_tasks_text}
{existing_lessons_text}

{extracted_risks_text}
{extracted_blockers_text}
{extracted_tasks_text}
{extracted_lessons_text}

For each newly extracted item, determine if it's a duplicate of an existing item. Use STRICT semantic similarity - items are duplicates if they address the same fundamental issue or action.

An item is a DUPLICATE if:
- It refers to the same core issue/task/lesson/blocker (even with slightly different wording)
- It involves the same person doing the same type of action (e.g., "Confirm X with Elena" vs "Verify X with Elena")
- It's a subset or superset of an existing item
- It's a status update to an existing item
- The action verbs are synonymous (confirm/verify/check, investigate/analyze/review, resolve)
- It mentions the same technology/system/component (e.g., all tasks about "CleanSpeak")

SPECIFIC DUPLICATE PATTERNS TO CATCH:
- Tasks with same person and similar action: "Confirm X with Person" = "Verify X with Person" = "Check X with Person"
- Communication tasks: "Confirm Transaction ID Mapping with Elena" = "Confirm Transaction ID Reporting with Elena"
- Investigation tasks: "Investigate GTM Event Tracking for PWA" = "Check GTM Event Tracking for PWA"
- Risks with same root cause: "Data inconsistency risk" = "Data integrity issues" = "Data reporting discrepancies"
- Technical investigations: "Investigate X" = "Analyze X" = "Review X" = "Examine X"
- Setup/Configuration tasks: "Setup X" = "Configure X" = "Implement X"
- Implementation tasks about same system: "Investigate CleanSpeak Implementation" = "Resolve CleanSpeak Implementation" = "CleanSpeak Implementation Across Studios"
- Cross-studio/cross-team tasks: "X Across Studios" = "X Implementation Inconsistencies" = "X for Different Studios"

COMPLETION/RESOLUTION DETECTION (Critical - applies to ALL item types):
When analyzing duplicates, you MUST detect if the meeting content mentions completion/resolution of existing items.
This is a PRIMARY function - detecting status changes is as important as detecting duplicates.

TASKS - Automatically mark as "completed" when meeting mentions:
- Completion keywords: "completed", "done", "finished", "delivered", "shipped", "deployed", "launched"
- Implementation keywords: "implemented", "fixed", "built", "created", "accomplished"
- Past tense verbs: "completed X", "finished Y", "delivered Z", "shipped the feature"
- Confirmation phrases: "confirmed it's done", "verified completion", "deployment successful"
- Examples:
  • "We finished implementing the payment gateway" → Mark task as completed
  • "Elena confirmed the transaction mapping is deployed" → Mark task as completed
  • "The API integration is now live in production" → Mark task as completed

RISKS - Automatically mark as "resolved" when meeting mentions:
- Resolution keywords: "resolved", "mitigated", "closed", "addressed", "handled", "fixed"
- Status phrases: "no longer a concern", "risk has passed", "issue is resolved"
- Mitigation complete: "mitigation complete", "successfully addressed", "risk eliminated"
- Past tense: "resolved the risk", "mitigated successfully", "addressed the concern"
- Examples:
  • "We resolved the API rate limiting issue" → Mark risk as resolved
  • "The security vulnerability has been fixed" → Mark risk as resolved
  • "Data consistency risk no longer applies" → Mark risk as resolved

BLOCKERS - Automatically mark as "resolved" when meeting mentions:
- Unblocking keywords: "unblocked", "resolved", "cleared", "removed", "fixed", "delivered"
- Status phrases: "no longer blocking", "blocker cleared", "dependency delivered", "issue resolved"
- Team unblocked: "team is unblocked", "can now proceed", "blocker removed"
- Past tense: "blocker was removed", "unblocked the team", "dependency delivered"
- Examples:
  • "The deployment pipeline blocker is now resolved" → Mark blocker as resolved
  • "DevOps delivered the infrastructure we needed" → Mark blocker as resolved
  • "Database access has been granted, team is unblocked" → Mark blocker as resolved

IMPORTANT RULES:
- Blockers and risks are separate entities. A blocker should NOT be considered a duplicate of a risk even if they describe similar issues.
- ALWAYS include status updates when completion/resolution is mentioned, even for pure duplicates
- Include items in "status_updates" if there's a clear status change mentioned in the new content
- For duplicates WITH status changes: Mark as duplicate AND add to status_updates with new_status
- For duplicates WITHOUT status changes: Just mark as duplicate (exclude from unique lists)
- BE AGGRESSIVE about catching both duplicates AND status changes - both are critical

Return a JSON with arrays of item numbers to KEEP (not duplicates) and confidence scores for each decision:
{{
    "unique_risk_numbers": [list of risk numbers that are NOT duplicates],
    "unique_blocker_numbers": [list of blocker numbers that are NOT duplicates],
    "unique_task_numbers": [list of task numbers that are NOT duplicates],
    "unique_lesson_numbers": [list of lesson numbers that are NOT duplicates],
    "duplicate_analysis": {{
        "risks": [
            {{
                "extracted_number": number,
                "is_duplicate": true/false,
                "confidence": 0.0-1.0,
                "reason": "brief explanation of why duplicate/unique",
                "similar_to": "title of existing item if duplicate"
            }}
        ],
        "blockers": [...],
        "tasks": [...],
        "lessons": [...]
    }},
    "status_updates": [
        {{
            "type": "risk" or "blocker" or "task" or "lesson",
            "extracted_number": number,
            "existing_title": "title of existing item being updated",
            "new_status": "completed" (for tasks) or "resolved" (for risks/blockers) or "in_progress" or other valid status
        }}
    ]

CRITICAL: For status_updates array:
- ALWAYS include when completion/resolution is mentioned in the meeting
- "new_status" must be: "completed" for tasks, "resolved" for risks/blockers
- Include even if the extracted item is a duplicate (this triggers auto-closure)
- Example: Meeting says "Task X is done" → Add to status_updates with "new_status": "completed"
}}

Be STRICT about duplicates - if two items address the same fundamental issue or action, mark as duplicate. Only keep truly unique items that add new value or address different concerns."""