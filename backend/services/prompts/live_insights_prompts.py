"""
Prompts for real-time meeting intelligence (live insights).

This module contains prompts for:
- Streaming intelligence detection (questions, actions, answers)
- GPT-generated answers (Tier 4 fallback)
- Meeting context search
"""

from typing import Optional


def get_streaming_intelligence_system_prompt() -> str:
    """
    Get the system prompt for GPT-5-mini streaming intelligence detection.

    This prompt instructs GPT to detect questions, actions, and answers
    in real-time meeting transcripts and output them as NDJSON.

    Returns:
        System prompt string for streaming intelligence
    """
    return """You are a real-time meeting intelligence assistant. Your job is to analyze live meeting transcripts as they stream in and detect questions, action items, and answers.

CRITICAL OUTPUT FORMAT: Newline-delimited JSON (NDJSON)
- Each detection MUST be a SINGLE-LINE complete JSON object with NO line breaks inside
- Each object MUST end with a newline character
- COMPACT JSON ONLY - remove all unnecessary whitespace and line breaks
- NO markdown formatting, NO code blocks, NO explanations, NO commentary
- Example of CORRECT format: {"type":"question","id":"q_123","text":"What is the budget?"}\n

WRONG (multi-line):
{
  "type": "question",
  "id": "q_123"
}

RIGHT (single-line):
{"type":"question","text":"What is the budget?","speaker":"John","category":"factual","confidence":0.95}

DETECTION TYPES:

1. QUESTION (single-line format):
{"type":"question","text":"The exact question as spoken","speaker":"Speaker A","category":"factual","confidence":0.95}

2. ACTION (single-line format):
{"type":"action","description":"Clear action description","owner":"John","deadline":"2025-11-30","speaker":"Speaker B","completeness":0.7,"confidence":0.92}

3. ACTION_UPDATE (single-line format):
{"type":"action_update","action_text":"Clear action description to match","owner":"Sarah","deadline":"2025-12-05","completeness":1.0,"confidence":0.88}

4. ANSWER (single-line format):
{"type":"answer","question_text":"The original question being answered","answer_text":"The answer as spoken","speaker":"Speaker C","confidence":0.90}

IMPORTANT: Do NOT include "timestamp" field in your output - the backend will add the correct timestamp automatically.

DETECTION RULES:

Questions:
- ONLY detect genuine questions that require an answer
- Detect explicit questions (ending with "?")
- Detect implicit questions ("I'm wondering about...", "Does anyone know...")
- DO NOT detect greetings ("hello", "hi everyone", "good morning") - these are NOT questions
- DO NOT detect acknowledgments ("thank you", "got it", "perfect")
- DO NOT detect rhetorical questions or questions not seeking information
- Ignore questions already answered in the same transcript
- Include speaker attribution if available
- Confidence threshold: Only output questions with confidence >0.80

Actions:
- Detect commitments ("I will...", "We should...", "Let's...")
- Detect task assignments ("John, can you...", "Sarah will...")
- Detect deadlines ("by Friday", "before Q4", "next week")
- Calculate completeness: 0.0-1.0 based on clarity of description, owner, and deadline
  - Description only: 0.4
  - Description + owner OR deadline: 0.7
  - Description + owner + deadline: 1.0
- Track action updates as more information emerges

Answers:
- Detect when a question is answered in subsequent conversation
- Match answers to questions using the EXACT question text
- Confidence >0.85 required to mark as answered
- Include both the original question text AND the answer text for matching

Action Updates:
- When more details emerge about an action, output an action_update
- Include the original action description text to match it to the existing action
- Update owner, deadline, or completeness as new information appears

IMPORTANT OUTPUT RULES:
- DO NOT generate IDs - the backend will assign unique IDs
- DO NOT include "timestamp" field - the backend will add the correct timestamp automatically
- For answers: include "question_text" to match to the original question
- For action_updates: include "action_text" to match to the original action
- CRITICAL: Each JSON object MUST be on EXACTLY ONE LINE with NO internal line breaks
- Use compact JSON format with no spaces after colons or commas
- Each object ends with a newline character (\\n)
- Do NOT output explanations, commentary, markdown, or code blocks
- If no detections in a transcript chunk, output nothing (empty response)
- Example correct output format (without timestamps):
{"type":"question","text":"What is the budget?","speaker":"John","category":"factual","confidence":0.95}
{"type":"action","description":"Update spreadsheet","owner":"Sarah","deadline":"2025-11-30","speaker":"John","completeness":1.0,"confidence":0.92}
{"type":"answer","question_text":"What is the budget?","answer_text":"The budget is $250,000","speaker":"Mike","confidence":0.95}"""


def get_streaming_intelligence_user_prompt(
    transcript_buffer: str,
    recent_questions: Optional[list] = None,
    recent_actions: Optional[list] = None
) -> str:
    """
    Generate user prompt for streaming intelligence with transcript context.

    Args:
        transcript_buffer: Formatted transcript (last 60 seconds)
        recent_questions: List of recent questions for context
        recent_actions: List of recent actions for context

    Returns:
        Formatted user prompt with transcript and context
    """
    context_parts = []

    if recent_questions:
        questions_text = "\n".join([
            f"- [{q.get('id')}] {q.get('text')} (status: {q.get('status', 'unknown')})"
            for q in recent_questions[:5]
        ])
        context_parts.append(f"Recent Questions:\n{questions_text}")

    if recent_actions:
        actions_text = "\n".join([
            f"- [{a.get('id')}] {a.get('description')} (owner: {a.get('owner', 'unassigned')}, completeness: {a.get('completeness', 0)})"
            for a in recent_actions[:5]
        ])
        context_parts.append(f"Recent Actions:\n{actions_text}")

    context = "\n\n".join(context_parts) if context_parts else "No recent context"

    return f"""CONTEXT (for reference only):
{context}

TRANSCRIPT TO ANALYZE:
{transcript_buffer}

Analyze the transcript above and output detected questions, actions, and answers as NDJSON."""


def get_gpt_generated_answer_system_prompt() -> str:
    """
    Get the system prompt for GPT-generated answers (Tier 4 fallback).

    This prompt is used when RAG, meeting context, and live monitoring
    all fail to find an answer.

    Returns:
        System prompt string for Tier 4 answer generation
    """
    return """You are a knowledgeable assistant helping answer questions that were not found in documents or meeting discussion.

Your role is to provide helpful, general knowledge answers when no other sources have information.

IMPORTANT CONSTRAINTS:
- Only answer if you are confident (>70% confidence)
- Be concise (2-3 sentences maximum)
- Acknowledge uncertainty when appropriate
- Do not fabricate specific company data or internal information
- Suggest where to find authoritative information if possible
- Always include a disclaimer that this is AI-generated from general knowledge

OUTPUT FORMAT: JSON only, no explanations
{
  "answer": "Your detailed answer here",
  "confidence": 0.75,
  "sources": "general knowledge",
  "disclaimer": "This answer is AI-generated and not from your documents or meeting. Please verify accuracy."
}"""


def get_gpt_generated_answer_user_prompt(
    question_text: str,
    speaker: Optional[str] = None,
    meeting_context: Optional[str] = None
) -> str:
    """
    Generate user prompt for GPT-generated answer (Tier 4).

    Args:
        question_text: The question that needs answering
        speaker: Who asked the question
        meeting_context: Brief summary of meeting context

    Returns:
        Formatted user prompt for answer generation
    """
    speaker_text = f"Asked by: {speaker}" if speaker else "Speaker: Unknown"
    context_text = f"Meeting context: {meeting_context}" if meeting_context else "Meeting context: Not available"

    return f"""CONTEXT:
Question: "{question_text}"
{speaker_text}
{context_text}

TASK:
Generate a helpful answer based on your general knowledge. If you cannot answer confidently (>70%), respond with confidence below threshold.

Remember:
- Only answer if confidence >70%
- Be concise (2-3 sentences max)
- Do not fabricate company-specific data
- Include the required disclaimer

Provide your response as JSON:"""


def get_meeting_context_search_system_prompt() -> str:
    """
    Get the system prompt for meeting context search (Tier 2).

    This prompt instructs GPT-5-mini to search the current meeting
    transcript for answers to questions.

    Returns:
        System prompt string for meeting context search
    """
    return """You are a semantic search assistant specialized in finding answers within meeting transcripts.

Your task is to search the provided meeting transcript for answers to specific questions.

RULES:
- Only return an answer if you find relevant information in the transcript
- Confidence threshold: >75% to return found_answer=true
- Use exact quotes from the transcript
- Include speaker attribution
- Include timestamps in [HH:MM:SS] format
- Maximum 3 relevant quotes per question
- Do not fabricate information not in the transcript

OUTPUT FORMAT: JSON only
{
  "found_answer": true/false,
  "answer_text": "Synthesized answer from transcript quotes",
  "quotes": [
    {
      "text": "Exact quote from transcript",
      "speaker": "Speaker A",
      "timestamp": "[00:15:30]"
    }
  ],
  "confidence": 0.85
}

If no answer found or confidence <75%, return:
{
  "found_answer": false,
  "answer_text": null,
  "quotes": [],
  "confidence": 0.0
}"""


def get_meeting_context_search_user_prompt(
    question_text: str,
    transcript: str,
    speaker: Optional[str] = None
) -> str:
    """
    Generate user prompt for meeting context search.

    Args:
        question_text: The question to search for
        transcript: The formatted meeting transcript
        speaker: Who asked the question (for context)

    Returns:
        Formatted user prompt for context search
    """
    speaker_text = f" (asked by {speaker})" if speaker else ""

    return f"""QUESTION TO ANSWER{speaker_text}:
"{question_text}"

MEETING TRANSCRIPT:
{transcript}

Search the transcript above and determine if the question was already answered. Provide your response as JSON."""


# Example transcript for testing/documentation
EXAMPLE_TRANSCRIPT = """[10:15:30] Speaker A: "Hello everyone, thanks for joining. I wanted to discuss our Q4 infrastructure budget. Does anyone have the latest numbers?"

[10:16:05] Speaker B: "I think Sarah sent that in an email last week. Let me check."

[10:16:45] Speaker C: "The budget is $250,000 for infrastructure, including cloud costs and new servers."

[10:17:20] Speaker A: "Perfect, thank you. John, can you update the spreadsheet with those numbers by Friday?"

[10:17:35] Speaker D (John): "Sure, I'll update it by end of week."
"""

# Expected NDJSON output for the example (IDs and timestamps are generated by backend, not in GPT output)
EXAMPLE_NDJSON_OUTPUT = """{"type":"question","text":"Does anyone have the latest numbers?","speaker":"Speaker A","category":"factual","confidence":0.98}
{"type":"action","description":"Update the spreadsheet with infrastructure budget numbers","owner":"John","deadline":"2025-11-30","speaker":"Speaker A","completeness":1.0,"confidence":0.95}
{"type":"answer","question_text":"Does anyone have the latest numbers?","answer_text":"The budget is $250,000 for infrastructure, including cloud costs and new servers.","speaker":"Speaker C","confidence":0.97}"""

# Example GPT-generated answer
EXAMPLE_GPT_ANSWER = {
    "question": "What's the typical ROI timeline for infrastructure investments?",
    "expected_response": {
        "answer": "Typical infrastructure investments show ROI within 18-36 months, depending on the scope. Cloud infrastructure often delivers faster returns (12-18 months) compared to on-premises hardware (24-36 months). However, this varies significantly based on organization size and usage patterns.",
        "confidence": 0.78,
        "sources": "general knowledge",
        "disclaimer": "This answer is AI-generated and not from your documents or meeting. Please verify accuracy."
    }
}
