"""
Project Matcher Service - Intelligent project assignment using Claude AI
"""
import json
import uuid
from typing import Dict, Any, Optional, List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from services.hierarchy.project_service import ProjectService
from services.llm.multi_llm_client import get_multi_llm_client
from services.prompts.project_matcher_prompts import (
    get_project_matching_prompt,
    get_project_matching_system_prompt
)
from config import get_settings
from utils.logger import get_logger
from utils.monitoring import monitor_operation

logger = get_logger(__name__)


class ProjectMatcherService:
    """Service for intelligently matching content to projects using Claude AI."""

    def __init__(self):
        """Initialize the project matcher service."""
        settings = get_settings()
        self.llm_model = settings.llm_model or "claude-3-5-haiku-20241022"

        # Confidence threshold for matching to existing projects
        self.min_confidence_for_match = 0.7  # Require 70% confidence to match existing project

        # Use centralized LLM client
        self.llm_client = get_multi_llm_client(settings)

        if not self.llm_client.is_available():
            logger.warning("Project Matcher: LLM client not available")
    
    @monitor_operation("match_transcript_to_project", "ai_matching")
    async def match_transcript_to_project(
        self,
        session: AsyncSession,
        organization_id: uuid.UUID,
        transcript: str,
        meeting_title: str,
        meeting_date: Optional[datetime] = None,
        participants: Optional[list] = None
    ) -> Dict[str, Any]:
        """
        Match a transcript to the most relevant project or create a new one.
        
        Args:
            session: Database session
            transcript: Meeting transcript content
            meeting_title: Title of the meeting
            meeting_date: Date of the meeting
            participants: List of meeting participants
            
        Returns:
            Dict containing:
                - project_id: UUID of the matched or created project
                - project_name: Name of the project
                - is_new: Boolean indicating if a new project was created
                - confidence: Confidence score of the match (0-1)
                - reasoning: Explanation of the decision
        """
        # Get all active projects using ProjectService
        existing_projects = await ProjectService.list_projects(
            session=session,
            organization_id=organization_id,
            status="active"
        )
        
        # Claude client is required - no fallback
        if not self.llm_client.is_available():
            raise Exception("LLM client is not available. Cannot perform smart project matching.")
        
        # Prepare context for Claude
        project_context = self._prepare_project_context(existing_projects)
        transcript_summary = self._extract_transcript_summary(
            transcript, meeting_title, meeting_date, participants
        )
        
        # Ask Claude to match or suggest new project
        match_result = await self._ask_claude_for_match(
            project_context, 
            transcript_summary,
            transcript[:3000]  # First 3000 chars for context
        )
        
        # Process Claude's response
        if match_result["action"] == "match_existing":
            confidence = match_result.get("confidence", 0.0)

            # Check if confidence meets threshold
            if confidence < self.min_confidence_for_match:
                logger.info(
                    f"Claude suggested matching to existing project but confidence ({confidence}) "
                    f"is below threshold ({self.min_confidence_for_match}). Creating new project instead."
                )
                # Force creation of new project due to low confidence
                match_result["action"] = "create_new"
                # Use the suggested project name from reasoning or generate a default one
                if "project_name" not in match_result:
                    # Extract key topics for project name
                    keywords = self._extract_keywords(transcript[:1000])
                    project_name = f"{meeting_title or ' '.join(keywords[:3]).title()} Project"
                    match_result["project_name"] = project_name
                    match_result["project_description"] = f"Project created from meeting: {meeting_title}"
            else:
                # High confidence match - proceed with existing project
                project_id = match_result["project_id"]
                project = next(p for p in existing_projects if str(p.id) == project_id)

                logger.info(
                    f"Matched transcript to existing project: {project.name} "
                    f"(confidence: {match_result['confidence']})"
                )

                return {
                    "project_id": project.id,
                    "project_name": project.name,
                    "is_new": False,
                    "confidence": match_result["confidence"],
                    "reasoning": match_result["reasoning"]
                }
        
        if match_result["action"] == "create_new":
            # Check if a project with this name already exists
            # (Claude might suggest a name that already exists)
            existing_project = next(
                (p for p in existing_projects if p.name.lower() == match_result["project_name"].lower()),
                None
            )

            if existing_project:
                # Project with this name exists - match to it instead of creating duplicate
                logger.info(
                    f"Claude suggested creating '{match_result['project_name']}' but it already exists. "
                    f"Matching to existing project instead."
                )
                return {
                    "project_id": existing_project.id,
                    "project_name": existing_project.name,
                    "is_new": False,
                    "confidence": match_result.get("confidence", 0.8),  # High confidence since names match
                    "reasoning": f"Matched to existing project with same name. {match_result.get('reasoning', '')}"
                }

            # Create new project using ProjectService
            new_project = await ProjectService.create_project(
                session=session,
                name=match_result["project_name"],
                organization_id=organization_id,
                description=match_result["project_description"],
                created_by="fireflies_ai_matcher"
            )

            logger.info(
                f"Created new project: {new_project.name} "
                f"(confidence: {match_result['confidence']})"
            )

            return {
                "project_id": new_project.id,
                "project_name": new_project.name,
                "is_new": True,
                "confidence": match_result["confidence"],
                "reasoning": match_result["reasoning"]
            }
        
        else:
            # Unexpected response from Claude
            raise Exception(f"Unexpected Claude response: {match_result.get('action', 'unknown')}")
    
    
    def _prepare_project_context(self, projects: list) -> str:
        """Prepare project information for Claude."""
        if not projects:
            return "No existing projects."
        
        project_info = []
        for project in projects:
            info = f"- Project ID: {project.id}\n"
            info += f"  Name: {project.name}\n"
            if project.description:
                info += f"  Description: {project.description}\n"
            info += f"  Created: {project.created_at.strftime('%Y-%m-%d')}\n"
            project_info.append(info)
        
        return "Existing projects:\n" + "\n".join(project_info)
    
    def _extract_transcript_summary(
        self,
        transcript: str,
        title: str,
        date: Optional[datetime],
        participants: Optional[List[str]]
    ) -> str:
        """Extract key information from transcript for matching."""
        summary = f"Meeting Title: {title}\n"
        
        if date:
            summary += f"Date: {date.strftime('%Y-%m-%d %H:%M')}\n"
        
        if participants:
            summary += f"Participants: {', '.join(participants[:5])}\n"
        
        # Extract key topics from transcript (simple keyword extraction)
        keywords = self._extract_keywords(transcript)
        if keywords:
            summary += f"Key Topics: {', '.join(keywords[:10])}\n"
        
        return summary
    
    def _extract_keywords(self, text: str) -> list:
        """Simple keyword extraction from text."""
        # Common stop words to exclude
        stop_words = {
            'the', 'is', 'at', 'which', 'on', 'and', 'a', 'an', 'as', 
            'are', 'was', 'were', 'to', 'of', 'for', 'with', 'in', 'it',
            'that', 'this', 'be', 'have', 'has', 'had', 'do', 'does',
            'will', 'would', 'could', 'should', 'may', 'might', 'can',
            'um', 'uh', 'like', 'you', 'know', 'just', 'so', 'but'
        }
        
        # Extract words
        words = text.lower().split()
        
        # Filter and count words
        word_freq = {}
        for word in words:
            # Clean word
            word = word.strip('.,!?;:"')
            
            # Skip short words and stop words
            if len(word) < 4 or word in stop_words:
                continue
            
            word_freq[word] = word_freq.get(word, 0) + 1
        
        # Sort by frequency and return top keywords
        sorted_words = sorted(word_freq.items(), key=lambda x: x[1], reverse=True)
        return [word for word, _ in sorted_words[:15]]
    
    @monitor_operation("claude_project_matching", "llm_call", capture_args=True, capture_result=True)
    async def _ask_claude_for_match(
        self,
        project_context: str,
        transcript_summary: str,
        transcript_excerpt: str
    ) -> Dict[str, Any]:
        """Ask Claude to match transcript to project or suggest new one."""
        
        prompt = get_project_matching_prompt(
            project_context=project_context,
            transcript_summary=transcript_summary,
            transcript_excerpt=transcript_excerpt
        )

        try:
            # Call LLM API (monitoring handled by decorator)
            response = await self.llm_client.create_message(
                prompt=prompt,
                model=self.llm_model,
                max_tokens=500,
                temperature=0.3,  # Lower temperature for more consistent matching
                system=get_project_matching_system_prompt()
            )
            
            # Parse response
            response_text = response.content[0].text
            
            # Clean response (remove markdown if present)
            if "```json" in response_text:
                response_text = response_text.split("```json")[1].split("```")[0]
            elif "```" in response_text:
                response_text = response_text.split("```")[1].split("```")[0]
            
            result = json.loads(response_text.strip())
            
            # Log token usage for monitoring
            if hasattr(response, 'usage'):
                total = getattr(response.usage, 'total_tokens', None) or \
                       (getattr(response.usage, 'input_tokens', 0) + getattr(response.usage, 'output_tokens', 0))
                logger.info(f"Claude API usage: {total} tokens")
            
            # Validate response structure
            if "action" not in result:
                raise ValueError("Invalid response format from Claude")
            
            return result
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Claude response: {e}")
            raise
        except Exception as e:
            logger.error(f"Error calling Claude API: {e}")
            raise
    
    


# Singleton instance
project_matcher_service = ProjectMatcherService()