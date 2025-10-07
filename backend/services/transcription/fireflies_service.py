"""
Fireflies.ai API integration service
"""
import logging
import httpx
from utils.logger import sanitize_for_log
from typing import Dict, Any, Optional, List
from datetime import datetime
import re

from utils.monitoring import monitor_operation, monitor_sync_operation

logger = logging.getLogger(__name__)

class FirefliesService:
    """Service for interacting with Fireflies.ai API"""
    
    BASE_URL = "https://api.fireflies.ai/graphql"
    
    def __init__(self, api_key: str):
        """Initialize Fireflies service with API key"""
        self.api_key = api_key
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
    
    @monitor_operation(
        operation_name="get_meeting_transcription",
        operation_type="external_api",
        capture_args=True,
        capture_result=True
    )
    async def get_meeting_transcription(self, meeting_id: str) -> Dict[str, Any]:
        """
        Fetch meeting transcription data from Fireflies API
        
        Args:
            meeting_id: The Fireflies meeting ID
            
        Returns:
            Dict containing title, transcript, date, and other metadata
        """
        query = """
        query GetTranscript($transcriptId: String!) {
            transcript(id: $transcriptId) {
                id
                title
                date
                duration
                transcript_url
                summary {
                    keywords
                    action_items
                    outline
                    overview
                    shorthand_bullet
                }
                organizer_email
                participants
                audio_url
                video_url
                sentences {
                    text
                    speaker_name
                    speaker_id
                    start_time
                    end_time
                }
            }
        }
        """
        
        variables = {
            "transcriptId": meeting_id
        }

        try:
            # Use proper SSL verification
            async with httpx.AsyncClient(verify=True) as client:
                # Log the request for debugging
                request_body = {
                    "query": query,
                    "variables": variables
                }
                logger.info(f"Sending Fireflies API request for meeting {sanitize_for_log(meeting_id)}")
                # Don't log sensitive headers or user-provided data
                logger.debug("Fireflies API request prepared")
                
                response = await client.post(
                    self.BASE_URL,
                    json=request_body,
                    headers=self.headers,
                    timeout=30.0
                )
                
                # Log response for debugging
                logger.info(f"Fireflies API response status: {response.status_code}")
                # Don't log response body as it may contain sensitive meeting content

                # Check for errors before raising status
                if response.status_code != 200:
                    try:
                        error_data = response.json()
                        if "errors" in error_data:
                            error_msg = error_data["errors"][0].get("message", "Unknown error")
                            logger.error(f"Fireflies API error: {sanitize_for_log(error_msg)}")
                            raise Exception("Fireflies API returned an error")
                    except:
                        pass

                response.raise_for_status()

                data = response.json()

                if "errors" in data:
                    error_msg = data["errors"][0].get("message", "Unknown error")
                    logger.error(f"Fireflies API error: {sanitize_for_log(error_msg)}")
                    raise Exception("Fireflies API returned an error")

                transcript_data = data.get("data", {}).get("transcript")

                if not transcript_data:
                    raise Exception("No transcript found for the requested meeting")
                
                # Process and format the response
                return await self._format_meeting_data(transcript_data)
                
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error when fetching Fireflies transcript: {sanitize_for_log(str(e))}")
            raise Exception("Failed to fetch transcript from Fireflies")
        except Exception as e:
            logger.error(f"Error fetching Fireflies transcript: {sanitize_for_log(str(e))}")
            raise
    
    @monitor_operation(
        operation_name="fetch_transcript_from_url",
        operation_type="external_api",
        capture_args=False,
        capture_result=False
    )
    async def _fetch_transcript_from_url(self, transcript_url: str) -> str:
        """
        Fetch transcript content from Fireflies transcript URL
        
        Args:
            transcript_url: URL to fetch transcript from
            
        Returns:
            Transcript text content
        """
        if not transcript_url:
            return ""
        
        try:
            # Use proper SSL verification
            async with httpx.AsyncClient(verify=True) as client:
                response = await client.get(
                    transcript_url,
                    headers={"Authorization": f"Bearer {self.api_key}"},
                    timeout=30.0
                )
                response.raise_for_status()
                return response.text
        except Exception as e:
            logger.error(f"Failed to fetch transcript from URL: {sanitize_for_log(str(e))}")
            return ""
    
    @monitor_operation(
        operation_name="format_meeting_data",
        operation_type="parsing",
        capture_args=False,
        capture_result=True
    )
    async def _format_meeting_data(self, transcript_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Format raw Fireflies API response into standardized format
        
        Args:
            transcript_data: Raw API response data
            
        Returns:
            Formatted meeting data dictionary
        """
        # Extract basic information
        meeting_id = transcript_data.get("id", "")
        title = transcript_data.get("title", "")
        date_str = transcript_data.get("date", "")
        duration = transcript_data.get("duration", 0)
        transcript_url = transcript_data.get("transcript_url", "")
        
        # Fetch transcript content from URL if provided
        transcript_text = ""
        if transcript_url:
            transcript_text = await self._fetch_transcript_from_url(transcript_url)
        
        # If no transcript from URL, try to build from sentences
        if not transcript_text and transcript_data.get("sentences"):
            sentences = transcript_data.get("sentences", [])
            transcript_text = " ".join([s.get("text", "") for s in sentences])
        
        # Parse date
        try:
            # Fireflies date format is typically ISO 8601
            if date_str:
                meeting_date = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
            else:
                meeting_date = datetime.now()
        except:
            meeting_date = datetime.now()
        
        # Generate title if not provided
        if not title or title.strip() == "":
            title = self._generate_title(
                transcript_text,
                meeting_date
            )
        
        # Extract participants
        participants = transcript_data.get("participants", [])
        if isinstance(participants, str):
            participants = [p.strip() for p in participants.split(",") if p.strip()]
        
        # Format transcript with speaker information if available
        formatted_transcript = self._format_transcript_with_speakers(
            transcript_data.get("sentences", []),
            transcript_text
        )
        
        # Build formatted response
        return {
            "meeting_id": meeting_id,
            "title": title,
            "transcript": formatted_transcript if formatted_transcript else transcript_text,
            "date": meeting_date.isoformat(),
            "duration": duration,
            "participants": participants,
            "organizer_email": transcript_data.get("organizer_email"),
            "audio_url": transcript_data.get("audio_url"),
            "video_url": transcript_data.get("video_url"),
            "transcript_url": transcript_url,
            "summary": transcript_data.get("summary", {}),
            "raw_transcript": transcript_text
        }
    
    @monitor_sync_operation(
        operation_name="format_transcript_with_speakers",
        operation_type="parsing"
    )
    def _format_transcript_with_speakers(
        self,
        sentences: list,
        raw_transcript: str
    ) -> str:
        """
        Format transcript with speaker information
        
        Args:
            sentences: List of sentence objects with speaker info
            raw_transcript: Fallback raw transcript text
            
        Returns:
            Formatted transcript string
        """
        if not sentences:
            return raw_transcript
        
        formatted_lines = []
        current_speaker = None
        current_text = []
        
        for sentence in sentences:
            speaker = sentence.get("speaker_name", "Unknown")
            text = sentence.get("text", "")
            
            if speaker != current_speaker:
                # Add previous speaker's text
                if current_speaker and current_text:
                    formatted_lines.append(f"{current_speaker}: {' '.join(current_text)}")
                
                # Start new speaker
                current_speaker = speaker
                current_text = [text]
            else:
                current_text.append(text)
        
        # Add last speaker's text
        if current_speaker and current_text:
            formatted_lines.append(f"{current_speaker}: {' '.join(current_text)}")
        
        return "\n\n".join(formatted_lines) if formatted_lines else raw_transcript
    
    def _generate_title(self, transcript: str, date: datetime) -> str:
        """
        Generate a title from transcript content if none provided
        
        Args:
            transcript: Meeting transcript text
            date: Meeting date
            
        Returns:
            Generated title string
        """
        # Try to extract key topics from first few lines
        if transcript:
            # Get first 500 characters
            excerpt = transcript[:500]
            
            # Look for common meeting patterns
            patterns = [
                r"(?:meeting|discussion|sync|standup|review|planning|retrospective)",
                r"(?:project|team|product|engineering|design|marketing|sales)",
                r"(?:weekly|daily|monthly|quarterly|annual)"
            ]
            
            keywords = []
            for pattern in patterns:
                matches = re.findall(pattern, excerpt, re.IGNORECASE)
                keywords.extend(matches)
            
            if keywords:
                # Capitalize and join unique keywords
                unique_keywords = list(dict.fromkeys([k.capitalize() for k in keywords[:3]]))
                title = " ".join(unique_keywords) + " Meeting"
            else:
                # Extract first meaningful sentence or phrase
                sentences = re.split(r'[.!?]', excerpt)
                if sentences and sentences[0].strip():
                    # Take first 50 characters of first sentence
                    title = sentences[0].strip()[:50]
                    if len(sentences[0].strip()) > 50:
                        title += "..."
                else:
                    title = "Meeting"
        else:
            title = "Meeting"
        
        # Add date to title
        date_str = date.strftime("%B %d, %Y")
        return f"{title} - {date_str}"
    
    @monitor_operation(
        operation_name="test_connection",
        operation_type="external_api",
        capture_args=False,
        capture_result=True
    )
    async def test_connection(self) -> bool:
        """
        Test the API connection with Fireflies
        
        Returns:
            True if connection is successful, False otherwise
        """
        query = """
        query {
            user {
                user_id
                email
            }
        }
        """
        
        try:
            # Use proper SSL verification
            async with httpx.AsyncClient(verify=True) as client:
                response = await client.post(
                    self.BASE_URL,
                    json={"query": query},
                    headers=self.headers,
                    timeout=10.0
                )
                response.raise_for_status()
                
                data = response.json()
                return "data" in data and "user" in data.get("data", {})
        except Exception as e:
            logger.error(f"Failed to test Fireflies connection: {sanitize_for_log(str(e))}")
            return False