"""
Project Description Service (Refactored) - Pure business logic for AI-driven description updates.
Follows clean architecture principles by separating concerns.
"""

import json
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
from services.llm.multi_llm_client import get_multi_llm_client
from services.prompts.project_description_prompts import (
    get_description_analysis_prompt,
    get_description_analysis_system_prompt
)
from config import get_settings
from utils.logger import get_logger

logger = get_logger(__name__)


class ProjectDescriptionAnalyzer:
    """Service for AI-powered project description analysis (pure business logic)."""
    
    def __init__(self):
        """Initialize the service."""
        settings = get_settings()
        self.llm_model = settings.llm_model or "claude-3-5-haiku-20241022"

        # Configuration
        self.min_content_length = 500  # Minimum content length to trigger analysis
        self.min_confidence_threshold = 0.6  # Minimum confidence to apply updates
        self.cooldown_hours = 24  # Hours to wait before analyzing similar content again

        # Use centralized LLM client
        self.llm_client = get_multi_llm_client(settings)

        if not self.llm_client.is_available():
            logger.warning("Project Description Analyzer: LLM client not available")

    def should_trigger_analysis(
        self,
        content_text: str,
        content_type: str,
        last_change_time: Optional[datetime] = None
    ) -> bool:
        """
        Determine if content should trigger description analysis using smart triggers.
        
        Args:
            content_text: The content to analyze
            content_type: Type of content (meeting/email)
            last_change_time: Timestamp of last description change
            
        Returns:
            True if analysis should be triggered
        """
        try:
            # Check content type - only process meetings and emails
            if content_type not in ["meeting", "email"]:
                logger.debug(f"Content type {content_type} not eligible for description updates")
                return False
            
            # Check content length
            if len(content_text) < self.min_content_length:
                logger.debug(f"Content length {len(content_text)} below minimum {self.min_content_length}")
                return False
            
            # Check cooldown period
            if last_change_time:
                cooldown_time = datetime.utcnow() - timedelta(hours=self.cooldown_hours)
                if last_change_time > cooldown_time:
                    logger.debug(f"Within cooldown period, last change: {last_change_time}")
                    return False
            
            logger.info("Smart triggers indicate analysis should be performed")
            return True
            
        except Exception as e:
            logger.error(f"Error in smart triggers evaluation: {e}")
            # On error, err on the side of caution and don't trigger
            return False

    def prepare_content_summary(self, content_data: Dict[str, Any]) -> str:
        """Prepare content summary for Claude analysis."""
        summary = f"Content Type: {content_data['content_type'].title()}\n"
        summary += f"Title: {content_data['title']}\n"
        
        if content_data.get('date'):
            summary += f"Date: {content_data['date']}\n"
        
        if content_data.get('uploaded_by'):
            summary += f"Uploaded by: {content_data['uploaded_by']}\n"
        
        # Word count
        content_text = content_data['content']
        word_count = len(content_text.split())
        summary += f"Word Count: {word_count}\n"
        
        # Extract key topics (simple keyword extraction)
        keywords = self._extract_keywords(content_text)
        if keywords:
            summary += f"Key Topics: {', '.join(keywords[:15])}\n"
        
        return summary

    def _extract_keywords(self, text: str) -> List[str]:
        """Simple keyword extraction from text."""
        stop_words = {
            'the', 'is', 'at', 'which', 'on', 'and', 'a', 'an', 'as',
            'are', 'was', 'were', 'to', 'of', 'for', 'with', 'in', 'it',
            'that', 'this', 'be', 'have', 'has', 'had', 'do', 'does',
            'will', 'would', 'could', 'should', 'may', 'might', 'can',
            'um', 'uh', 'like', 'you', 'know', 'just', 'so', 'but',
            'we', 'they', 'them', 'their', 'our', 'your', 'my', 'me'
        }
        
        # Extract words
        words = text.lower().split()
        
        # Filter and count words
        word_freq = {}
        for word in words:
            # Clean word
            word = word.strip('.,!?;:"()[]{}')
            
            # Skip short words and stop words
            if len(word) < 4 or word in stop_words:
                continue
            
            word_freq[word] = word_freq.get(word, 0) + 1
        
        # Sort by frequency and return top keywords
        sorted_words = sorted(word_freq.items(), key=lambda x: x[1], reverse=True)
        return [word for word, _ in sorted_words[:20]]

    async def analyze_for_description_update(
        self,
        current_description: str,
        project_name: str,
        content_data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Analyze content using Claude to determine if description should be updated.
        
        Args:
            current_description: Current project description
            project_name: Name of the project
            content_data: Dict with content information
            
        Returns:
            Analysis result or None if no update recommended
        """
        try:
            # Ensure Claude client is available
            if not self.llm_client.is_available():
                logger.warning("LLM client not available, cannot analyze content")
                return None
            
            # Prepare content summary for Claude
            content_summary = self.prepare_content_summary(content_data)

            # Only use meeting summary - no fallback to raw content
            if not content_data.get('summary'):
                logger.info("No meeting summary available, skipping project description analysis")
                return None

            # Use the rich meeting summary for better context
            summary = content_data['summary']
            content_text = self._format_summary_for_analysis(summary)
            logger.info("Using meeting summary for project description analysis")
            
            # Ask Claude to analyze if description should be updated
            analysis_result = await self._ask_claude_for_description_analysis(
                current_description=current_description,
                project_name=project_name,
                content_summary=content_summary,
                content_text=content_text
            )
            
            # Validate analysis result
            if not analysis_result or analysis_result.get("should_update") is False:
                logger.info(f"Claude recommends no description update for project {project_name}")
                return None
            
            confidence = analysis_result.get("confidence", 0.0)
            if confidence < self.min_confidence_threshold:
                logger.info(
                    f"Claude confidence {confidence} below threshold {self.min_confidence_threshold}, "
                    f"skipping description update for project {project_name}"
                )
                return None
            
            logger.info(
                f"Claude recommends description update for project {project_name} "
                f"(confidence: {confidence})"
            )
            
            return {
                "should_update": True,
                "new_description": analysis_result.get("new_description"),
                "reason": analysis_result.get("reason"),
                "confidence": confidence
            }
            
        except Exception as e:
            logger.error(f"Failed to analyze content for description update: {e}")
            return None

    def _format_summary_for_analysis(self, summary: Dict[str, Any]) -> str:
        """
        Format meeting summary data for Claude analysis.

        Args:
            summary: Meeting summary data from summary service

        Returns:
            Formatted text containing key summary information
        """
        try:
            parts = []

            # Add summary text
            if summary.get('summary_text'):
                parts.append(f"Meeting Summary:\n{summary['summary_text']}")

            # Add key points
            if summary.get('key_points'):
                key_points = summary['key_points'][:10]  # Limit to 10 points
                parts.append(f"\nKey Points:\n- " + "\n- ".join(key_points))

            # Add decisions
            if summary.get('decisions'):
                decisions = summary['decisions'][:5]  # Limit to 5 decisions
                decision_texts = []
                for decision in decisions:
                    if isinstance(decision, dict):
                        desc = decision.get('description', '')
                        importance = decision.get('importance_score', '')
                        decision_texts.append(f"{desc} (Importance: {importance})")
                    else:
                        decision_texts.append(str(decision))
                if decision_texts:
                    parts.append(f"\nKey Decisions:\n- " + "\n- ".join(decision_texts))

            # Add risk summary
            risks_blockers = summary.get('risks_and_blockers', {})
            if isinstance(risks_blockers, dict):
                risks = risks_blockers.get('risks', [])
                blockers = risks_blockers.get('blockers', [])
                if risks or blockers:
                    parts.append(f"\nRisks Identified: {len(risks)}")
                    parts.append(f"Blockers Identified: {len(blockers)}")

                    # Add high-severity risks
                    high_risks = []
                    for risk in risks[:3]:  # Top 3 risks
                        if isinstance(risk, dict):
                            title = risk.get('title', risk.get('description', ''))
                            severity = risk.get('severity', '')
                            if severity in ['high', 'critical']:
                                high_risks.append(f"{title} (Severity: {severity})")
                    if high_risks:
                        parts.append("High Priority Risks:\n- " + "\n- ".join(high_risks))

            # Add action items summary
            if summary.get('action_items'):
                action_items = summary['action_items']
                parts.append(f"\nAction Items: {len(action_items)} tasks identified")

                # Add high priority tasks
                high_priority = []
                for task in action_items[:3]:  # Top 3 tasks
                    if isinstance(task, dict):
                        title = task.get('title', task.get('description', ''))
                        priority = task.get('priority', task.get('urgency', ''))
                        if priority in ['high', 'urgent']:
                            high_priority.append(f"{title} (Priority: {priority})")
                if high_priority:
                    parts.append("High Priority Tasks:\n- " + "\n- ".join(high_priority))

            # Add lessons learned if present
            if summary.get('lessons_learned'):
                lessons = summary['lessons_learned']
                parts.append(f"\nLessons Learned: {len(lessons)} insights captured")

            # Combine all parts
            content_text = "\n".join(parts)

            # Limit total size to ~3000 chars to leave room for other context
            if len(content_text) > 3000:
                content_text = content_text[:2997] + "..."

            return content_text

        except Exception as e:
            logger.error(f"Error formatting summary for analysis: {e}")
            # Return raw summary text as fallback
            return str(summary.get('summary_text', ''))[:3000] if summary else ""

    async def _ask_claude_for_description_analysis(
        self,
        current_description: str,
        project_name: str,
        content_summary: str,
        content_text: str
    ) -> Dict[str, Any]:
        """Ask Claude to analyze if project description should be updated."""
        
        # Debug logging
        logger.info(f"=== CLAUDE ANALYSIS DEBUG ===")
        logger.info(f"Project name: '{project_name}'")
        logger.info(f"Current description: '{current_description}'")
        logger.info(f"Content summary: {content_summary}")
        logger.info(f"Content text length: {len(content_text)} chars")
        logger.info(f"Content text preview: {content_text[:300]}...")
        
        prompt = get_description_analysis_prompt(
            project_name=project_name,
            current_description=current_description,
            content_summary=content_summary,
            content_text=content_text
        )

        try:
            response = await self.llm_client.create_message(
                prompt=prompt,
                model=self.llm_model,
                max_tokens=600,
                temperature=0.2,  # Lower temperature for consistent analysis
                system=get_description_analysis_system_prompt()
            )
            
            # Parse response
            response_text = response.content[0].text
            logger.info(f"Claude raw response: {response_text}")
            
            # Clean response (remove markdown if present)
            if "```json" in response_text:
                response_text = response_text.split("```json")[1].split("```")[0]
            elif "```" in response_text:
                response_text = response_text.split("```")[1].split("```")[0]
            
            logger.info(f"Claude cleaned response: {response_text.strip()}")
            result = json.loads(response_text.strip())
            logger.info(f"Claude parsed result: {result}")
            
            # Log token usage
            if hasattr(response, 'usage'):
                total = getattr(response.usage, 'total_tokens', None) or \
                       (getattr(response.usage, 'input_tokens', 0) + getattr(response.usage, 'output_tokens', 0))
                logger.info(f"Claude API usage for description analysis: {total} tokens")
            
            # Validate response structure
            required_fields = ["should_update", "confidence", "reason"]
            for field in required_fields:
                if field not in result:
                    raise ValueError(f"Missing required field '{field}' in Claude response")
            
            return result
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Claude response for description analysis: {e}")
            raise
        except Exception as e:
            logger.error(f"Error calling Claude API for description analysis: {e}")
            raise


# Singleton instance
project_description_analyzer = ProjectDescriptionAnalyzer()