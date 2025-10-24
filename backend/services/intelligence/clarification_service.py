"""
Clarification Service - Detects vague statements and suggests clarifying questions.

This service analyzes insights (especially action items and decisions) for vagueness
and generates context-specific clarifying questions to help teams avoid ambiguity.
"""

from dataclasses import dataclass
from typing import List, Optional, Dict, Any
import re
import logging
import json
import asyncio
from pydantic import BaseModel, Field, validator

logger = logging.getLogger(__name__)


@dataclass
class ClarificationSuggestion:
    """Suggestion for clarifying a vague statement"""
    statement: str
    vagueness_type: str  # 'time', 'assignment', 'detail', 'scope'
    confidence: float
    suggested_questions: List[str]
    reasoning: str


# Pydantic validation models for LLM responses
class VaguenessDetectionResponse(BaseModel):
    """Validated response for vagueness detection"""
    is_vague: bool
    type: Optional[str] = Field(None, description="Type of vagueness: time, assignment, detail, scope")
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    missing_info: Optional[str] = None

    @validator('type')
    def validate_type(cls, v):
        if v is not None and v not in ['time', 'assignment', 'detail', 'scope']:
            logger.warning(f"Invalid vagueness type '{v}', defaulting to 'detail'")
            return 'detail'
        return v

    @validator('confidence')
    def validate_confidence(cls, v, values):
        if values.get('is_vague') and v is not None and v < 0.75:
            logger.debug(f"Confidence {v:.2f} below threshold 0.75")
        return v


class ClarificationQuestionsResponse(BaseModel):
    """Validated response for clarification questions"""
    questions: List[str] = Field(..., min_items=1, max_items=5)

    @validator('questions')
    def validate_questions(cls, v):
        # Filter out empty or invalid questions
        valid_questions = [
            q.strip() for q in v
            if q and isinstance(q, str) and len(q.strip()) > 5 and q.strip().endswith('?')
        ]
        if not valid_questions:
            raise ValueError("No valid questions found")
        return valid_questions[:3]  # Limit to 3 questions


class ClarificationService:
    """Service for detecting vague statements and suggesting clarifications"""

    # Refined patterns - reduced false positives (Oct 2025)
    # Only trigger on genuinely vague statements, not normal language
    VAGUE_PATTERNS = {
        'time': [
            r'\b(eventually|sometime)\b',  # Removed "soon", "later" (too common)
            r'\b(probably|maybe|might)\s+(next|this)\s+(week|month)\b',
            r'\basap\b',
            r'\bwhen (we|you) (can|have time|get around to)\b'
        ],
        'assignment': [
            r'\b(someone|somebody|anyone)\s+(should|needs to|has to|will|must|can|could)\b',
            r'\bit would be good if\b',
            r'\bwhoever (is|has) (available|free)\b'
        ],
        'detail': [
            r'\bthe (bug|issue|problem)(?!\s+(with|in|about|is|was|that|where|when))',  # More exclusions
            r'\bthat thing\b',  # Removed "that feature/item" (often clear from context)
            r'\bstuff (needs|should|has to)\b',  # Only very vague language
            r'\b(fix|update) (it|this|that)(?!\s+\w)',  # Only if not followed by details
        ],
        'scope': [
            r'\b(probably|maybe|possibly|perhaps)\s+(we|I|they)\s+(should|could|might)\b',  # More specific
            r'\bkind of|sort of\b',
            r'\bI think\b(?!\s+(we should|it\'s|that|the))',  # More exclusions
            r'\bnot sure (if|whether|about)\b'
        ]
    }

    # Whitelist - phrases that look vague but are actually acceptable
    VAGUENESS_WHITELIST = {
        'time': [
            r'\bnext (week|month|quarter|sprint)\b',  # Common planning language
            r'\bsoon\b(?=\s+(as possible|after))',  # "soon as possible" is acceptable
            r'\blater (today|this week|next week)\b',  # Relative but clear timeframe
            r'\b(by|before|after) (next|this) (week|month|sprint)\b',  # Relative deadlines are acceptable
            r'\bin \d+ (days?|weeks?|months?)\b'  # "in 2 weeks" is specific enough
        ],
        'assignment': [
            r'\bwe need to\b',  # Team action, not vague assignment
            r'\bteam (will|should|needs to|to)\b',  # Team ownership clear
            r'\beveryone (should|needs to|to)\b',  # Broadcast action
            r'\b[A-Z][a-z]+ (will|should|needs to|to)\b',  # Named person actions (e.g., "John will...")
            r'\bI (will|should|need to|to)\b'  # First-person commitment is clear
        ],
        'detail': [
            r'\b(complete|finish|review|update|fix|implement|clarify|address|schedule) \w+\b',  # Action + object = clear
            r'\bschedule (a |the )?\w+\b',  # "schedule demo" is clear enough
            r'\bthe \w+ (integration|module|feature|service|component|implementation|audit|monitoring)\b',  # Technical terms clear
            r'\b(OAuth|JWT|API|database|security|performance|testing)\b',  # Technical specifics
            r'\b(action item|task|issue|bug|feature)\s+\d+\b'  # Numbered items are specific
        ],
        'scope': [
            r'\bI think (we should|that|the)\b',  # Opinion followed by specifics
            r'\bmaybe (we can|next|after)\b',  # Tentative but clear direction
            r'\b(complete|implement|fix|update|address|clarify)\b'  # Action verbs indicate clear intent
        ]
    }

    CLARIFICATION_TEMPLATES = {
        'time': [
            "What is the specific deadline or target date?",
            "By when should this be completed?",
            "What's the timeframe for this?"
        ],
        'assignment': [
            "Who specifically will handle this?",
            "Who is the owner for this task?",
            "Which team member will be responsible?"
        ],
        'detail': [
            "Can you provide more specifics?",
            "What are the exact details or requirements?",
            "Which specific item are you referring to?"
        ],
        'scope': [
            "What level of certainty do we have?",
            "Should we treat this as confirmed or tentative?",
            "Do we need to make a firm decision on this?"
        ]
    }

    def __init__(self, llm_client):
        self.llm_client = llm_client

    async def _llm_call_with_retry(
        self,
        prompt: str,
        max_tokens: int = 200,
        temperature: float = 0.1,
        max_retries: int = 2
    ) -> Optional[str]:
        """
        Call LLM with retry logic and exponential backoff.

        Args:
            prompt: The prompt to send to the LLM
            max_tokens: Maximum tokens in response
            temperature: Temperature for generation
            max_retries: Maximum number of retry attempts

        Returns:
            LLM response text or None if all retries fail
        """
        for attempt in range(max_retries + 1):
            try:
                response = await self.llm_client.create_message(
                    prompt=prompt,
                    max_tokens=max_tokens,
                    temperature=temperature
                )
                return response.content[0].text.strip()

            except Exception as e:
                if attempt < max_retries:
                    # Exponential backoff: 0.5s, 1s, 2s...
                    wait_time = 0.5 * (2 ** attempt)
                    logger.warning(
                        f"LLM call failed (attempt {attempt + 1}/{max_retries + 1}): {e}. "
                        f"Retrying in {wait_time}s..."
                    )
                    await asyncio.sleep(wait_time)
                else:
                    logger.error(f"LLM call failed after {max_retries + 1} attempts: {e}")
                    return None

        return None

    def _robust_json_parse(self, response_text: str, expected_type: str = "object") -> Optional[any]:
        """
        Robust JSON parser with multiple fallback strategies.

        Args:
            response_text: Raw LLM response text
            expected_type: "object" for {} or "array" for []

        Returns:
            Parsed JSON object/array or None if parsing fails
        """
        if not response_text:
            return None

        original_text = response_text

        # Step 1: Remove markdown code blocks
        if '```' in response_text:
            match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', response_text, re.DOTALL)
            if match:
                response_text = match.group(1).strip()
            else:
                response_text = re.sub(r'```(?:json)?', '', response_text).strip()

        # Step 2: Extract JSON structure (find first and last bracket)
        if expected_type == "array":
            start_idx = response_text.find('[')
            end_idx = response_text.rfind(']')
        else:  # object
            start_idx = response_text.find('{')
            end_idx = response_text.rfind('}')

        if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
            response_text = response_text[start_idx:end_idx+1]

        # Step 3: Fix common JSON issues - contractions
        contractions = {
            "we're": "we are", "it's": "it is", "you're": "you are",
            "they're": "they are", "isn't": "is not", "aren't": "are not",
            "wasn't": "was not", "weren't": "were not", "haven't": "have not",
            "hasn't": "has not", "hadn't": "had not", "won't": "will not",
            "wouldn't": "would not", "don't": "do not", "doesn't": "does not",
            "didn't": "did not", "can't": "cannot", "couldn't": "could not",
            "shouldn't": "should not", "I'm": "I am", "he's": "he is",
            "she's": "she is", "that's": "that is", "there's": "there is",
            "who's": "who is", "what's": "what is", "where's": "where is",
            "when's": "when is", "why's": "why is", "how's": "how is"
        }
        for contraction, expansion in contractions.items():
            response_text = response_text.replace(contraction, expansion)
            response_text = response_text.replace(contraction.capitalize(), expansion.capitalize())

        # Step 4: Try to parse JSON
        try:
            return json.loads(response_text)
        except json.JSONDecodeError as e:
            logger.debug(f"Initial JSON parse failed: {e}")

            # Step 5: Handle multiple JSON objects (LLM returned comma-separated objects)
            if expected_type == "object" and response_text.count('{') > 1:
                # Try to parse as array by wrapping in brackets
                try:
                    array_text = f"[{response_text}]"
                    parsed_array = json.loads(array_text)
                    if isinstance(parsed_array, list) and len(parsed_array) > 0:
                        logger.info(f"Recovered {len(parsed_array)} objects from comma-separated JSON")

                        # For vagueness detection, select object with highest confidence
                        if all(isinstance(obj, dict) and 'confidence' in obj for obj in parsed_array):
                            best_obj = max(parsed_array, key=lambda x: x.get('confidence', 0))
                            logger.info(f"Selected highest confidence object: {best_obj.get('confidence', 0):.2f}")
                            return best_obj

                        # Otherwise return first valid object
                        return parsed_array[0] if isinstance(parsed_array[0], dict) else None
                except json.JSONDecodeError:
                    logger.debug("Failed to parse as array of objects")

            # Step 6: Try regex extraction as last resort
            if expected_type == "array":
                # Extract quoted strings that look like questions
                matches = re.findall(r'"([^"]+\?)"', original_text)
                if matches and len(matches) >= 2:
                    logger.info(f"Recovered {len(matches)} items via regex extraction")
                    return matches

            logger.warning(f"All JSON parsing strategies failed. Original: {original_text[:200]}")
            return None

    def _is_whitelisted(self, statement: str, vague_type: str) -> bool:
        """
        Check if statement matches whitelist patterns (acceptable "vague" language).
        Added Oct 2025 to reduce false positives on normal business language.

        Args:
            statement: The statement to check
            vague_type: Type of vagueness (time, assignment, detail, scope)

        Returns:
            True if statement is whitelisted (should NOT alert), False otherwise
        """
        whitelist = self.VAGUENESS_WHITELIST.get(vague_type, [])
        for pattern in whitelist:
            if re.search(pattern, statement, re.IGNORECASE):
                logger.debug(f"Statement matches whitelist pattern for {vague_type}: {pattern}")
                return True
        return False

    def _has_specific_details(self, statement: str) -> bool:
        """
        Check if statement contains specific technical details or concrete information.
        Helps filter out false positives where context makes intent clear.

        Args:
            statement: The statement to check

        Returns:
            True if statement has sufficient specificity, False if genuinely vague
        """
        # Check for technical specificity indicators
        specificity_indicators = [
            r'\b(API|database|frontend|backend|UI|UX|service|module|component)\b',
            r'\b(OAuth|JWT|PostgreSQL|MongoDB|TypeScript|JavaScript|Python)\b',  # Technologies
            r'\b\d+\s+(days?|weeks?|months?|hours?|minutes?)\b',  # Quantified time
            r'\b(version|release|milestone|sprint)\s+\d+',  # Versions/iterations
            r'\b[A-Z][a-z]+\s+(will|should|to|needs to)\b',  # Named person + action
            r'\b(by|before|until)\s+(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|today|tomorrow)\b',  # Specific dates
            r'\b(complete|finish|implement|deploy|test|review|update)\s+\w+\s+\w+',  # Action + multi-word object
        ]

        for pattern in specificity_indicators:
            if re.search(pattern, statement, re.IGNORECASE):
                return True

        # Check statement length - longer statements usually have more context
        word_count = len(statement.split())
        if word_count >= 8:  # 8+ words likely has sufficient detail
            return True

        return False

    def _has_sufficient_context(
        self,
        statement: str,
        context: str,
        vague_type: str
    ) -> bool:
        """
        Check if surrounding context provides sufficient clarity for a potentially vague statement.
        Added Oct 2025 to reduce false positives.

        Args:
            statement: The potentially vague statement
            context: Surrounding meeting context
            vague_type: Type of vagueness detected (time, assignment, detail, scope)

        Returns:
            True if context provides clarity, False if still vague
        """
        if not context:
            return False

        # Create search window: 100 chars before statement + statement + 100 chars after
        # Find statement in context
        statement_pos = context.find(statement)
        if statement_pos == -1:
            # Statement not in context, check full context
            search_text = context
        else:
            start = max(0, statement_pos - 100)
            end = min(len(context), statement_pos + len(statement) + 100)
            search_text = context[start:end]

        # Type-specific context checks
        if vague_type == 'assignment':
            # Check for owner mentions
            owner_patterns = [
                r'\b(John|Sarah|Mike|Lisa|Alice|Bob|Tom|Jane|David|Emma)\b',  # Common names
                r'\b(assigned to|owner:|responsible:)\b',
                r'\b([A-Z][a-z]+)\s+(will|can|should|to)\s+',  # "John will", "Sarah to"
            ]
            for pattern in owner_patterns:
                if re.search(pattern, search_text, re.IGNORECASE):
                    return True

        elif vague_type == 'time':
            # Check for deadline mentions
            deadline_patterns = [
                r'\b(by|before|until)\s+\w+\s+\d+',  # "by October 25"
                r'\b(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b',
                r'\b(today|tomorrow|next week|this week|EOD|end of day)\b',
                r'\b(deadline|due date|target date)\b',
                r'\bby\s+(end of|start of)\s+(week|month|quarter)\b',
            ]
            for pattern in deadline_patterns:
                if re.search(pattern, search_text, re.IGNORECASE):
                    return True

        elif vague_type == 'detail':
            # Check for specific details nearby
            detail_patterns = [
                r'\b(specifically|exactly|in detail|details:)\b',
                r'\b(API|database|frontend|backend|UI|UX)\b',  # Technical specifics
                r'\b\d+\s+(items|tasks|bugs|features)\b',  # Quantities
                r'\b(version|release|milestone)\s+\d+',  # Versions
            ]
            for pattern in detail_patterns:
                if re.search(pattern, search_text, re.IGNORECASE):
                    return True

        elif vague_type == 'scope':
            # Check for firm commitments nearby
            firm_patterns = [
                r'\b(definitely|certainly|confirmed|approved|decided)\b',
                r'\b(we will|we shall|agreed to)\b',
                r'\b(committed|committed to|commitment)\b',
            ]
            for pattern in firm_patterns:
                if re.search(pattern, search_text, re.IGNORECASE):
                    return True

        return False

    async def detect_vagueness(
        self,
        statement: str,
        context: str = ""
    ) -> Optional[ClarificationSuggestion]:
        """
        Detect if a statement is vague and needs clarification.
        Enhanced with multi-layer filtering (Oct 2025) to reduce false positives.
        Returns None if statement is clear enough.
        """
        if not statement or len(statement.strip()) < 5:
            return None

        # Check pattern-based vagueness (fast, high precision)
        for vague_type, patterns in self.VAGUE_PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, statement, re.IGNORECASE):
                    logger.info(f"Detected {vague_type} vagueness via pattern: {pattern}")

                    # Layer 1: Whitelist check - acceptable "vague" phrases
                    if self._is_whitelisted(statement, vague_type):
                        logger.debug(
                            f"Pattern matched but statement is whitelisted for {vague_type}, "
                            f"skipping alert"
                        )
                        continue

                    # Layer 2: Specificity check - does statement have concrete details?
                    if self._has_specific_details(statement):
                        logger.debug(
                            f"Pattern matched but statement has specific details, "
                            f"skipping alert"
                        )
                        continue

                    # Layer 3: Context check - does surrounding context provide clarity?
                    if self._has_sufficient_context(statement, context, vague_type):
                        logger.debug(
                            f"Pattern matched but context provides clarity for {vague_type}, "
                            f"skipping alert"
                        )
                        continue

                    # All filters passed - genuinely vague, generate clarification
                    return await self._generate_clarification(
                        statement=statement,
                        vagueness_type=vague_type,
                        context=context,
                        confidence=0.75  # Lowered from 0.90 to 0.75 (Oct 2025) to reduce false positives
                    )

        # Use LLM for more subtle vagueness (slower, broader coverage)
        llm_result = await self._llm_detect_vagueness(statement, context)
        if llm_result:
            return llm_result

        return None

    async def _generate_clarification(
        self,
        statement: str,
        vagueness_type: str,
        context: str,
        confidence: float
    ) -> ClarificationSuggestion:
        """Generate clarifying questions for a vague statement"""

        # Get template questions
        base_questions = self.CLARIFICATION_TEMPLATES.get(vagueness_type, [
            "Can you provide more details?",
            "What specific information is needed?"
        ])

        # Escape quotes in statement and context for safety
        statement_escaped = statement.replace('"', '\\"').replace('\n', ' ')
        context_escaped = (context.replace('"', '\\"').replace('\n', ' ') if context else "No additional context")

        # Use LLM to customize questions based on context
        # Improved prompt with stricter JSON requirements and examples
        prompt = f"""Generate 2-3 specific clarifying questions for this vague meeting statement.

Statement: {statement_escaped}
Context: {context_escaped}
Vagueness Type: {vagueness_type}

Base templates:
{chr(10).join(f"- {q}" for q in base_questions)}

CRITICAL REQUIREMENTS:
1. Respond with ONLY a valid JSON array - nothing else
2. No markdown, no code blocks, no explanations
3. Each question must end with a question mark
4. Use proper JSON string escaping
5. No unescaped quotes or apostrophes inside strings

GOOD examples:
["What is the specific deadline?", "Who will handle this task?"]
["When should this be completed by?", "What are the success criteria?"]

BAD examples:
```json ["question"]```  <- No markdown blocks
Here are the questions: ["question"]  <- No extra text
["What's the deadline?"]  <- Use "What is" instead

Output only the JSON array:"""

        # Call LLM with retry logic
        response_text = await self._llm_call_with_retry(
            prompt=prompt,
            max_tokens=200,
            temperature=0.1,
            max_retries=2
        )

        # Parse response with robust JSON parsing
        questions = base_questions[:3]  # Default fallback

        if response_text:
            parsed_questions = self._robust_json_parse(response_text, expected_type="array")

            if isinstance(parsed_questions, list) and len(parsed_questions) > 0:
                try:
                    # Validate using Pydantic model
                    validated = ClarificationQuestionsResponse(questions=parsed_questions)
                    questions = validated.questions
                    logger.debug(f"Successfully validated {len(questions)} clarification questions")
                except Exception as e:
                    logger.warning(f"Question validation failed: {e}. Using base questions.")
                    questions = base_questions[:3]
            else:
                logger.warning("Failed to parse questions from LLM response, using base questions")
        else:
            logger.warning("Empty or failed LLM response, using base questions")

        return ClarificationSuggestion(
            statement=statement,
            vagueness_type=vagueness_type,
            confidence=confidence,
            suggested_questions=questions[:3],  # Limit to 3 questions
            reasoning=f"Detected {vagueness_type} vagueness in statement"
        )

    async def _llm_detect_vagueness(
        self,
        statement: str,
        context: str
    ) -> Optional[ClarificationSuggestion]:
        """Use LLM to detect subtle vagueness"""

        # Escape quotes in statement and context for JSON safety
        statement_escaped = statement.replace('"', '\\"').replace('\n', ' ')
        context_escaped = (context.replace('"', '\\"').replace('\n', ' ') if context else "No additional context")

        prompt = f"""Analyze this meeting statement for vagueness or missing critical information.

Statement: {statement_escaped}
Context: {context_escaped}

Determine if the statement is vague or missing critical details. Focus on identifying the MOST CRITICAL vagueness issue (if any).

CRITICAL REQUIREMENTS:
1. Respond with EXACTLY ONE JSON object - nothing else
2. If multiple vagueness types exist, report only the MOST IMPORTANT one
3. No markdown, no code blocks, no explanations, no multiple objects
4. Use simple descriptions (no apostrophes or quotes inside strings)
5. Use proper JSON formatting

Valid types: time, assignment, detail, scope
Confidence: 0.0 to 1.0 (use 0.75+ only for genuinely vague statements that require clarification)

GOOD examples:
{{"is_vague": false}}
{{"is_vague": true, "type": "time", "confidence": 0.85, "missing_info": "needs specific deadline"}}
{{"is_vague": true, "type": "assignment", "confidence": 0.9, "missing_info": "no owner specified"}}

BAD examples:
```json {{"is_vague": false}}```  <- No markdown blocks
Analysis: {{"is_vague": true...}}  <- No extra text
{{"missing_info": "it's unclear"}}  <- Use "it is unclear" instead
{{"is_vague": true, "type": "time", ...}}, {{"is_vague": true, "type": "detail", ...}}  <- NEVER output multiple objects

Output EXACTLY ONE JSON object:"""

        # Call LLM with retry logic
        response_text = await self._llm_call_with_retry(
            prompt=prompt,
            max_tokens=150,
            temperature=0.1,
            max_retries=2
        )

        # Parse response with robust JSON parsing
        if not response_text:
            logger.warning("Empty response from LLM vagueness detection")
            return None

        parsed_result = self._robust_json_parse(response_text, expected_type="object")

        if not parsed_result or not isinstance(parsed_result, dict):
            logger.warning("Failed to parse vagueness detection response as JSON object")
            return None

        try:
            # Validate using Pydantic model
            result = VaguenessDetectionResponse(**parsed_result)

            # Process validated result - increased threshold to reduce false positives
            if result.is_vague and result.confidence and result.confidence >= 0.75:
                vague_type = result.type or 'detail'
                confidence = result.confidence

                logger.debug(
                    f"Vagueness detected: type={vague_type}, confidence={confidence:.2f}, "
                    f"missing_info={result.missing_info}"
                )

                return await self._generate_clarification(
                    statement=statement,
                    vagueness_type=vague_type,
                    context=context,
                    confidence=confidence
                )
            else:
                if result.is_vague and result.confidence:
                    logger.debug(
                        f"Vagueness confidence {result.confidence:.2f} below threshold 0.75, skipping"
                    )

        except Exception as e:
            logger.warning(f"Vagueness detection validation failed: {e}")
            return None

        return None
