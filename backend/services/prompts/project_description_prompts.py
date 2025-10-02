"""
Prompts for project description analysis and updates.
"""


def get_description_analysis_prompt(
    project_name: str,
    current_description: str,
    content_summary: str,
    content_text: str
) -> str:
    """
    Generate prompt for analyzing whether a project description should be updated.

    Args:
        project_name: Name of the project
        current_description: Current project description (may be empty)
        content_summary: Summary metadata about the content
        content_text: Excerpt of the actual content

    Returns:
        Formatted prompt string for description analysis
    """
    return f"""You are an intelligent project management assistant. Your task is to analyze new content and determine if a project's description should be updated to be more accurate and comprehensive.

Project Information:
Name: {project_name}
Current Description: {current_description if current_description.strip() else "No description currently exists"}

New Content Information:
{content_summary}

Content Excerpt (first 4000 characters):
{content_text}

Based on the new content, please analyze:
1. Does this content reveal information about the project's scope, purpose, or objectives?
2. Should a project description be created or updated based on this content?
3. Would a description help team members better understand the project?

IMPORTANT Guidelines:
- If the project has NO description (empty/blank), you MUST create one unless the content is completely meaningless
- Even technical discussions, feature planning, or status meetings reveal the project's domain and purpose
- Extract ANY available context about what the team is working on, what tools they use, what problems they're solving
- For empty projects, even partial information is better than no description
- If there IS an existing description, only update if the new content provides significant NEW insight
- Keep descriptions concise (1-3 sentences) but informative
- Focus on extracting: technology stack, project domain, team activities, business context
- For projects with generic names like "Project 1", any description is crucial for identification
- Err on the side of creating descriptions rather than leaving projects without context

Respond in JSON format:
{{
    "should_update": true/false,
    "confidence": 0.0-1.0,
    "new_description": "Updated description" (only if should_update is true),
    "reason": "Brief explanation of why the description should/shouldn't be updated"
}}"""


def get_description_analysis_system_prompt() -> str:
    """
    Get the system prompt for project description analysis.

    Returns:
        System prompt string
    """
    return "You are a project management assistant that helps keep project descriptions accurate and informative. Always respond with valid JSON."