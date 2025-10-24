"""
Prompts for real-time meeting insights extraction.

Provides optimized prompts for extracting structured insights from live
meeting transcripts with minimal latency and high accuracy.
"""

from typing import List, Dict, Any, Optional


def get_realtime_insight_extraction_prompt(
    current_chunk: str,
    recent_context: str,
    related_discussions: Optional[List[Dict[str, Any]]] = None,
    speaker_info: Optional[str] = None,
    enabled_insight_types: Optional[List[str]] = None
) -> str:
    """
    Generate optimized prompt for real-time insight extraction.

    Args:
        current_chunk: The current segment being analyzed
        recent_context: Recent conversation context (last 3 chunks)
        related_discussions: Related past meeting discussions from Qdrant
        speaker_info: Optional speaker identification information
        enabled_insight_types: User-selected insight types (cost optimization)

    Returns:
        Formatted prompt for Claude Haiku optimized for speed and accuracy
    """

    # Build related discussions section
    related_text = ""
    if related_discussions:
        related_text = "\n\n### Related Past Discussions:\n"
        for idx, disc in enumerate(related_discussions[:3], 1):
            similarity = disc.get('similarity_score', 0.0)
            related_text += (
                f"{idx}. **{disc.get('title', 'Untitled')}** "
                f"(relevance: {similarity:.0%})\n"
                f"   {disc.get('snippet', '')[:150]}...\n"
            )

    # Build speaker section
    speaker_text = ""
    if speaker_info:
        speaker_text = f"\n\n### Speaker Information:\n{speaker_info}\n"

    # Build insight categories section (filtered by user preferences)
    all_categories = {
        "decision": "**DECISION**: Conclusions reached or choices made\n   - Distinguish between final and provisional decisions\n   - Note who made the decision if clear",
        "risk": "**RISK**: Potential issues, blockers, or concerns\n   - Technical risks\n   - Resource constraints\n   - Timeline concerns"
    }

    # Filter categories based on enabled types (COST OPTIMIZATION)
    if enabled_insight_types:
        # Convert camelCase to snake_case if needed (e.g., actionItem -> action_item)
        enabled_types_normalized = []
        for t in enabled_insight_types:
            # Convert camelCase to snake_case
            import re
            normalized = re.sub(r'([a-z])([A-Z])', r'\1_\2', t).lower()
            enabled_types_normalized.append(normalized)

        filtered_categories = {k: v for k, v in all_categories.items()
                             if k in enabled_types_normalized}
        if not filtered_categories:
            # Fallback to all if empty
            filtered_categories = all_categories
    else:
        filtered_categories = all_categories

    # Build categories text
    categories_text = "Extract insights ONLY in these categories:\n\n"
    for idx, (key, desc) in enumerate(filtered_categories.items(), 1):
        categories_text += f"{idx}. {desc}\n\n"

    prompt = f"""Analyze this live meeting segment and extract actionable insights in real-time.

## Recent Conversation Context
{recent_context}

## Current Segment (PRIMARY FOCUS)
{current_chunk}
{related_text}{speaker_text}

## Extraction Guidelines

{categories_text}

## Output Format

Respond with ONLY valid JSON (no markdown, no explanation):

```json
{{
  "insights": [
    {{
      "type": "decision",
      "priority": "high",
      "content": "Brief, actionable description",
      "confidence": 0.9
    }}
  ]
}}
```

## Quality Rules

1. **Precision over Recall**: Only extract clear, actionable insights
2. **Conciseness**: Keep content to 1-2 sentences maximum
3. **Confidence Scoring**:
   - 0.9-1.0: Explicitly stated, no ambiguity
   - 0.7-0.9: Strongly implied, high context
   - 0.6-0.7: Inferred from context
   - Below 0.6: Don't extract

4. **Priority Assignment**:
   - CRITICAL: Blocking issues, urgent deadlines
   - HIGH: Important but not blocking
   - MEDIUM: Standard importance
   - LOW: Nice to have, informational

5. **Field Requirements**:
   - Use `null` for optional fields when not applicable
   - `assigned_to` and `due_date` are optional
   - All other fields are required

6. **Avoid Duplicates**: Don't extract insights that are just rewording of earlier points

Extract only from the CURRENT segment. Return empty array if no insights found.
"""

    return prompt


def get_insight_refinement_prompt(
    raw_insights: List[Dict[str, Any]],
    full_context: str
) -> str:
    """
    Generate prompt for refining and consolidating insights.

    Used for post-processing to merge similar insights and improve quality.

    Args:
        raw_insights: List of raw extracted insights
        full_context: Full meeting context for verification

    Returns:
        Prompt for insight refinement
    """

    insights_json = "\n".join([
        f"{idx + 1}. {insight}"
        for idx, insight in enumerate(raw_insights)
    ])

    prompt = f"""Review and refine these extracted meeting insights for quality and consistency.

## Extracted Insights
{insights_json}

## Full Meeting Context
{full_context}

## Refinement Tasks

1. **Merge Duplicates**: Combine insights that refer to the same action/decision/question
2. **Improve Clarity**: Rewrite vague insights to be more specific
3. **Verify Context**: Ensure insights are accurate based on full context
4. **Adjust Priority**: Re-evaluate priority levels based on full picture
5. **Remove Noise**: Eliminate low-value or redundant insights

## Output Format

Return refined insights as JSON array with the same structure:

```json
{{
  "refined_insights": [
    {{
      "type": "decision",
      "priority": "high",
      "content": "Refined, clear description",
      "confidence": 0.95,
      "merged_from": ["insight_id_1", "insight_id_2"]
    }}
  ],
  "removed_count": 3,
  "merged_count": 2
}}
```

Focus on quality over quantity. Aim for actionable, non-redundant insights.
"""

    return prompt


def get_contradiction_detection_prompt(
    current_statement: str,
    past_discussion: str,
    context: str
) -> str:
    """
    Generate prompt for detecting contradictions with past discussions.

    Args:
        current_statement: Statement from current meeting
        past_discussion: Related discussion from past meeting
        context: Current conversation context

    Returns:
        Prompt for contradiction analysis
    """

    prompt = f"""Analyze if the current statement contradicts a past discussion.

## Current Statement
{current_statement}

## Past Discussion
{past_discussion}

## Current Context
{context}

## Analysis Task

Determine if there is a meaningful contradiction between the current statement and past discussion.

A contradiction exists if:
1. Both statements address the same topic
2. They make incompatible claims or decisions
3. The difference is significant (not just refinement or clarification)

## Output Format

```json
{{
  "is_contradiction": true,
  "confidence": 0.85,
  "explanation": "Brief explanation of the contradiction",
  "severity": "high",
  "recommendation": "What should be clarified or reconciled"
}}
```

**Severity Levels**:
- HIGH: Major strategic or technical conflict
- MEDIUM: Important difference in approach or decision
- LOW: Minor inconsistency, likely refinement

If no meaningful contradiction, return `is_contradiction: false` with confidence score.
"""

    return prompt


def get_meeting_summary_prompt_realtime(
    insights_by_type: Dict[str, List[Dict[str, Any]]],
    total_duration_minutes: int,
    participant_count: int
) -> str:
    """
    Generate prompt for creating a summary from real-time insights.

    Args:
        insights_by_type: Insights grouped by type
        total_duration_minutes: Meeting duration
        participant_count: Number of participants

    Returns:
        Prompt for generating meeting summary
    """

    insights_summary = ""
    for insight_type, insights in insights_by_type.items():
        insights_summary += f"\n\n### {insight_type.upper()} ({len(insights)})\n"
        for insight in insights[:10]:  # Top 10 per type
            insights_summary += f"- {insight.get('content')}\n"

    prompt = f"""Generate a concise meeting summary from real-time extracted insights.

## Meeting Metadata
- Duration: {total_duration_minutes} minutes
- Participants: {participant_count}

## Extracted Insights
{insights_summary}

## Summary Format

Create a structured summary with:

1. **Key Outcomes** (2-3 sentences)
2. **Decisions Made** (bulleted list)
3. **Risks Identified** (if any)
4. **Next Steps** (what happens after this meeting)

Keep it concise and actionable. Focus on what matters most.

Output as structured JSON:

```json
{{
  "summary": {{
    "key_outcomes": "2-3 sentence overview",
    "decisions": ["decision 1", "decision 2"],
    "risks": ["risk 1"],
    "next_steps": ["step 1"]
  }}
}}
```
"""

    return prompt
