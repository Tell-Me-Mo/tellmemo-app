"""
Prompts for intelligent project matching and assignment.
"""


def get_project_matching_system_prompt() -> str:
    """
    Get the system prompt for project matching.

    Returns:
        System prompt string
    """
    return "You are a project management assistant that intelligently organizes meetings into projects. Always respond with valid JSON."


def get_project_matching_prompt(
    project_context: str,
    transcript_summary: str,
    transcript_excerpt: str
) -> str:
    """
    Generate prompt for matching a transcript to an existing project or suggesting a new one.

    Args:
        project_context: Formatted list of existing projects
        transcript_summary: Summary of the meeting/transcript
        transcript_excerpt: Excerpt from the actual transcript

    Returns:
        Formatted prompt string for project matching
    """
    return f"""You are an intelligent project management assistant. Your task is to analyze a meeting transcript and determine which existing project it belongs to, or if a new project should be created.

{project_context}

New Meeting Information:
{transcript_summary}

Transcript Excerpt:
{transcript_excerpt}

Based on the meeting content, please decide:
1. Should this meeting be added to an existing project? If yes, which one?
2. Or should a new project be created? If yes, suggest a concise project name and description.

CRITICAL MATCHING CRITERIA:
- ONLY match to an existing project if there is STRONG evidence the meeting is directly related
- Evidence includes: same product/feature names, same team members, continuation of previous discussions, explicit project references
- DO NOT match just because topics are vaguely similar or in the same domain
- When in doubt, create a new project rather than forcing a match
- Confidence score should reflect how certain you are:
  * 0.9-1.0: Explicit project references, clear continuation of work
  * 0.7-0.8: Strong topical overlap with specific details matching
  * 0.5-0.6: Some overlap but uncertain
  * Below 0.5: Weak or no clear connection
- Project names should be short (2-4 words) and descriptive
- Project descriptions should be 1-2 sentences explaining the project's purpose

Respond in JSON format:
{{
    "action": "match_existing" or "create_new",
    "project_id": "uuid-of-existing-project" (only if matching existing),
    "project_name": "Name for new project" (only if creating new),
    "project_description": "Description for new project" (only if creating new),
    "confidence": 0.0-1.0,
    "reasoning": "Brief explanation of your decision"
}}"""