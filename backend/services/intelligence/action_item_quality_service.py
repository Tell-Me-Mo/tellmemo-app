"""
Action Item Quality Enhancement Service

This service detects incomplete or poorly-formed action items and suggests improvements.
It checks for:
- Missing owner/assignee (WHO)
- Missing deadline (WHEN)
- Vague or unclear descriptions (WHAT)
- Missing success criteria (optional but recommended)

Part of Phase 4: Action Item Quality Enhancement
"""

from dataclasses import dataclass
from typing import List, Optional
import re
import logging

logger = logging.getLogger(__name__)


@dataclass
class QualityIssue:
    """Issue with action item quality"""
    field: str  # 'owner', 'deadline', 'description', 'success_criteria'
    severity: str  # 'critical', 'important', 'suggestion'
    message: str
    suggested_fix: Optional[str] = None


@dataclass
class ActionItemQualityReport:
    """Quality assessment of an action item"""
    action_item: str
    completeness_score: float  # 0.0 to 1.0
    issues: List[QualityIssue]
    improved_version: Optional[str]


class ActionItemQualityService:
    """Service for checking and improving action item quality"""

    # Patterns for detecting deadlines
    DEADLINE_PATTERNS = [
        r'\bby\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
        r'\bdue\s+by\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
        r'\bby\s+(\d{1,2}/\d{1,2}|\d{1,2}-\d{1,2})\b',
        r'\bby\s+(today|tomorrow|end of week|eow|eod)\b',
        r'\bdeadline:?\s*\d+',
        r'\bdue:?\s*\d+',
        r'\bby\s+\w+\s+\d{1,2}',  # "by October 25"
        r'\bwithin\s+\d+\s+(days?|weeks?|months?)\b',
        r'\bnext\s+(week|month|quarter|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b'
    ]

    # Patterns for detecting owners/assignees
    OWNER_PATTERNS = [
        r'\b([A-Z][a-z]+)\s+(will|to|should)\s+',  # "John will...", "Sarah to..."
        r'\bassigned to:?\s*([A-Z][a-z]+)',
        r'\bowner:?\s*([A-Z][a-z]+)',
        r'\b([A-Z][a-z]+)\s+needs to\b',
        r'\b([A-Z][a-z]+)\'s?\s+task\b'
    ]

    # Vague action verbs that should be replaced
    VAGUE_VERBS = [
        'look into', 'check on', 'think about', 'consider',
        'explore', 'investigate', 'follow up', 'touch base',
        'handle', 'deal with', 'take care of'
    ]

    # Clear action verbs (suggestions)
    CLEAR_VERBS = [
        'review', 'implement', 'send', 'schedule', 'create',
        'update', 'fix', 'deploy', 'test', 'document',
        'complete', 'finalize', 'approve', 'submit'
    ]

    def __init__(self, llm_client):
        self.llm_client = llm_client

    async def check_quality(
        self,
        action_item: str,
        context: str = ""
    ) -> ActionItemQualityReport:
        """
        Check quality of an action item and suggest improvements.

        Args:
            action_item: The action item text to check
            context: Surrounding meeting context for better analysis

        Returns:
            ActionItemQualityReport with completeness score and issues
        """

        issues = []

        # Check for owner
        if not self._has_owner(action_item):
            issues.append(QualityIssue(
                field='owner',
                severity='critical',
                message='No owner specified. Action items need a clear owner.',
                suggested_fix='Add "John to..." or "Assigned to: Sarah"'
            ))

        # Check for deadline
        if not self._has_deadline(action_item):
            issues.append(QualityIssue(
                field='deadline',
                severity='critical',
                message='No deadline specified.',
                suggested_fix='Add "by Friday" or "deadline: 10/25"'
            ))

        # Check description clarity
        if len(action_item.split()) < 5:
            issues.append(QualityIssue(
                field='description',
                severity='important',
                message='Description is too brief.',
                suggested_fix='Provide more details about what needs to be done'
            ))

        # Check for vague verbs
        found_vague_verbs = [verb for verb in self.VAGUE_VERBS if verb in action_item.lower()]
        if found_vague_verbs:
            issues.append(QualityIssue(
                field='description',
                severity='important',
                message=f'Contains vague action verb: "{found_vague_verbs[0]}"',
                suggested_fix=f'Use specific verbs like: {", ".join(self.CLEAR_VERBS[:5])}'
            ))

        # Check for success criteria (optional but recommended)
        if not self._has_success_criteria(action_item):
            issues.append(QualityIssue(
                field='success_criteria',
                severity='suggestion',
                message='Consider adding success criteria for clarity.',
                suggested_fix='Add "so that..." or "resulting in..." clause'
            ))

        # Calculate completeness score
        completeness = self._calculate_completeness(issues)

        # Generate improved version if needed
        improved_version = None
        if completeness < 0.8 and len(issues) > 0:
            try:
                improved_version = await self._generate_improved_version(
                    action_item, issues, context
                )
            except Exception as e:
                logger.error(f"Failed to generate improved version: {e}")
                improved_version = None

        logger.info(
            f"Quality check for action item: completeness={completeness:.2f}, "
            f"issues={len(issues)}"
        )

        return ActionItemQualityReport(
            action_item=action_item,
            completeness_score=completeness,
            issues=issues,
            improved_version=improved_version
        )

    def _has_owner(self, text: str) -> bool:
        """Check if action item has an owner"""
        for pattern in self.OWNER_PATTERNS:
            if re.search(pattern, text, re.IGNORECASE):
                return True
        return False

    def _has_deadline(self, text: str) -> bool:
        """Check if action item has a deadline"""
        for pattern in self.DEADLINE_PATTERNS:
            if re.search(pattern, text, re.IGNORECASE):
                return True
        return False

    def _has_success_criteria(self, text: str) -> bool:
        """Check if action item has success criteria"""
        success_patterns = [
            r'\bso that\b',
            r'\bresulting in\b',
            r'\bto ensure\b',
            r'\bwith the goal of\b',
            r'\benabling\b'
        ]
        for pattern in success_patterns:
            if re.search(pattern, text, re.IGNORECASE):
                return True
        return False

    def _calculate_completeness(self, issues: List[QualityIssue]) -> float:
        """Calculate completeness score based on issues"""
        # Start with 1.0 (perfect)
        score = 1.0

        for issue in issues:
            if issue.severity == 'critical':
                score -= 0.3
            elif issue.severity == 'important':
                score -= 0.15
            else:  # suggestion
                score -= 0.05

        return max(0.0, score)

    async def _generate_improved_version(
        self,
        action_item: str,
        issues: List[QualityIssue],
        context: str
    ) -> str:
        """Use LLM to generate improved version"""

        issues_text = "\n".join([
            f"- {issue.field} ({issue.severity}): {issue.message}"
            for issue in issues
        ])

        # Extract any names from context to use as potential owners
        name_pattern = r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b'
        potential_names = list(set(re.findall(name_pattern, context[:500])))[:5]
        names_hint = f"Potential owners from context: {', '.join(potential_names)}" if potential_names else ""

        prompt = f"""You are improving an action item from a meeting.

Original Action Item:
"{action_item}"

Meeting Context:
{context[:300]}

{names_hint}

Quality Issues Found:
{issues_text}

Task: Rewrite this action item to address all quality issues while preserving the original intent.

Requirements:
1. Include a clear owner (use a name from context if available, or use a placeholder like "[Owner]")
2. Include a specific deadline (infer from context or use "[Deadline]" placeholder)
3. Use clear, actionable verbs (avoid vague verbs like "look into", "check on")
4. Keep it concise (1-2 sentences)
5. Preserve the core task/intent

Return ONLY the improved action item text, nothing else. No explanations or preambles."""

        response = await self.llm_client.create_message(
            messages=[{"role": "user", "content": prompt}],
            max_tokens=150,
            temperature=0.5
        )

        improved = response.content[0].text.strip()

        # Remove any quotes that might have been added
        improved = improved.strip('"').strip("'")

        return improved
