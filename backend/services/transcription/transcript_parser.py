"""Transcript parser service for handling different meeting transcript formats."""

import json
import re
from typing import List, Dict, Any, Optional, Union
from dataclasses import dataclass
from datetime import datetime
import logging

from utils.logger import get_logger
from utils.monitoring import monitor_sync_operation, MonitoringContext

logger = get_logger(__name__)


@dataclass
class ParsedTranscript:
    """Represents a parsed transcript with structured content."""
    title: str
    duration: Optional[str]
    participants: List[Dict[str, str]]
    dialogue: List[Dict[str, str]]  # speaker, timestamp, text
    decisions: List[str]
    action_items: List[Dict[str, Any]]
    raw_content: str
    format_type: str  # 'json', 'plain_text', 'structured_text'


class TranscriptParser:
    """Service for parsing different meeting transcript formats."""
    
    def __init__(self):
        """Initialize the transcript parser."""
        self.json_patterns = [
            'transcript',
            'dialogue',
            'conversation',
            'speakers',
            'messages'
        ]
        
    @monitor_sync_operation("parse_transcript", "parsing")
    def parse_transcript(self, content: str, title: str = "Meeting Transcript") -> ParsedTranscript:
        """
        Parse transcript content and extract structured information.
        
        Args:
            content: Raw transcript content
            title: Title for the transcript
            
        Returns:
            ParsedTranscript object with extracted information
        """
        try:
            # Detect format type
            format_type = self._detect_format(content)
            logger.info(f"Detected transcript format: {format_type}")
            
            # Parse based on detected format
            if format_type == 'json':
                return self._parse_json_transcript(content, title)
            elif format_type == 'structured_text':
                return self._parse_structured_text(content, title)
            else:
                return self._parse_plain_text(content, title)
                
        except Exception as e:
            logger.error(f"Failed to parse transcript: {e}")
            # Fallback to plain text parsing
            return self._parse_plain_text(content, title)
    
    def _detect_format(self, content: str) -> str:
        """
        Detect the format of the transcript content.
        
        Args:
            content: Raw content
            
        Returns:
            Format type: 'json', 'structured_text', or 'plain_text'
        """
        # Check if it's JSON
        try:
            json.loads(content.strip())
            return 'json'
        except json.JSONDecodeError:
            pass
        
        # Check for structured text patterns
        if self._is_structured_text(content):
            return 'structured_text'
            
        return 'plain_text'
    
    def _is_structured_text(self, content: str) -> bool:
        """Check if content follows structured text patterns."""
        patterns = [
            r'Meeting:', r'Attendees?:', r'Agenda:', r'Discussion:',
            r'Decisions?:', r'Action Items?:', r'Next Steps:',
            r'^Speaker.*:', r'^\w+\s+\w+:', r'Timestamp:'
        ]
        
        matches = sum(1 for pattern in patterns if re.search(pattern, content, re.MULTILINE | re.IGNORECASE))
        return matches >= 3  # Need at least 3 structured patterns
    
    @monitor_sync_operation("parse_json_transcript", "parsing")
    def _parse_json_transcript(self, content: str, title: str) -> ParsedTranscript:
        """Parse JSON-formatted transcript."""
        try:
            data = json.loads(content.strip())
            
            # Check if data is a list (array of dialogue entries)
            if isinstance(data, list):
                # Direct array of dialogue entries
                dialogue = []
                speaker_names = set()
                
                for entry in data:
                    if isinstance(entry, dict):
                        # Handle various formats of speaker information
                        speaker = entry.get('speaker', entry.get('speaker_name', entry.get('name', entry.get('from', 'Unknown'))))
                        speaker_id = entry.get('speaker_id', '')
                        
                        # Handle timestamp in various formats
                        timestamp = entry.get('timestamp', entry.get('startTime', entry.get('time', entry.get('when', ''))))
                        end_time = entry.get('endTime', '')
                        
                        # Get the text content
                        text = entry.get('text', entry.get('sentence', entry.get('message', entry.get('content', ''))))
                        
                        if speaker:
                            speaker_names.add(speaker)
                        
                        dialogue.append({
                            'speaker': speaker,
                            'timestamp': timestamp,
                            'text': text
                        })
                
                # Create participants from speaker names
                participants = [{'name': name, 'role': 'Participant'} for name in speaker_names if name != 'Unknown']
                
                return ParsedTranscript(
                    title=title,
                    duration=None,
                    participants=participants,
                    dialogue=dialogue,
                    decisions=[],
                    action_items=[],
                    raw_content=content,
                    format_type='json'
                )
            
            # Original logic for dictionary format
            # Extract basic info
            parsed_title = data.get('title', title)
            duration = data.get('duration', data.get('length'))
            
            # Extract participants
            participants = []
            if 'participants' in data:
                participants = data['participants']
            elif 'attendees' in data:
                participants = data['attendees']
            elif 'speakers' in data:
                # Convert speakers list to participant format
                speakers = data['speakers']
                if isinstance(speakers, list):
                    participants = [{'name': speaker, 'role': 'Participant'} for speaker in speakers]
            
            # Extract dialogue/transcript
            dialogue = []
            dialogue_data = None
            
            # Look for transcript data in various keys
            for key in ['transcript', 'dialogue', 'conversation', 'messages', 'content']:
                if key in data and isinstance(data[key], list):
                    dialogue_data = data[key]
                    break
            
            if dialogue_data:
                for entry in dialogue_data:
                    if isinstance(entry, dict):
                        # Standard format: speaker, timestamp, text
                        speaker = entry.get('speaker', entry.get('name', entry.get('from', 'Unknown')))
                        timestamp = entry.get('timestamp', entry.get('time', entry.get('when', '')))
                        text = entry.get('text', entry.get('message', entry.get('content', '')))
                        
                        dialogue.append({
                            'speaker': speaker,
                            'timestamp': timestamp,
                            'text': text
                        })
            
            # Extract decisions
            decisions = data.get('decisions', data.get('key_decisions', data.get('outcomes', [])))
            if isinstance(decisions, str):
                # Single decision as string
                decisions = [decisions]
            elif not isinstance(decisions, list):
                decisions = []
            
            # Extract action items
            action_items = data.get('action_items', data.get('actions', data.get('todos', [])))
            if not isinstance(action_items, list):
                action_items = []
                
            return ParsedTranscript(
                title=parsed_title,
                duration=duration,
                participants=participants,
                dialogue=dialogue,
                decisions=decisions,
                action_items=action_items,
                raw_content=content,
                format_type='json'
            )
            
        except Exception as e:
            logger.error(f"Failed to parse JSON transcript: {e}")
            raise
    
    @monitor_sync_operation("parse_structured_text", "parsing")
    def _parse_structured_text(self, content: str, title: str) -> ParsedTranscript:
        """Parse structured text transcript (with clear sections)."""
        sections = self._split_into_sections(content)
        
        # Extract participants
        participants = []
        attendees_text = sections.get('attendees', sections.get('participants', ''))
        if attendees_text:
            # Parse attendees like "John Doe (PM), Jane Smith (Dev Lead)"
            attendee_matches = re.findall(r'([^,()]+)(?:\s*\(([^)]+)\))?', attendees_text)
            for name, role in attendee_matches:
                name = name.strip()
                role = role.strip() if role else 'Participant'
                if name and name not in ['and', 'And']:  # Filter out connector words
                    participants.append({'name': name, 'role': role})
        
        # Extract dialogue from discussion section
        dialogue = []
        discussion_text = sections.get('discussion', '')
        if discussion_text:
            # Look for speaker patterns like "John: spoke about..."
            speaker_matches = re.findall(r'^([A-Z][a-zA-Z\s]+?):\s*(.+?)(?=^[A-Z][a-zA-Z\s]+?:|$)', 
                                       discussion_text, re.MULTILINE | re.DOTALL)
            for speaker, text in speaker_matches:
                dialogue.append({
                    'speaker': speaker.strip(),
                    'timestamp': '',
                    'text': text.strip()
                })
        
        # If no speaker patterns found, extract paragraphs as content blocks
        if not dialogue and discussion_text:
            paragraphs = [p.strip() for p in discussion_text.split('\n\n') if p.strip()]
            for i, paragraph in enumerate(paragraphs):
                dialogue.append({
                    'speaker': 'Discussion',
                    'timestamp': '',
                    'text': paragraph
                })
        
        # Extract decisions
        decisions = []
        decisions_text = sections.get('decisions', sections.get('key decisions', ''))
        if decisions_text:
            # Split by numbered lists or bullet points
            decision_matches = re.findall(r'(?:^|\n)\s*(?:\d+\.|\-|\*)\s*(.+?)(?=(?:\n\s*(?:\d+\.|\-|\*))|$)', 
                                        decisions_text, re.MULTILINE | re.DOTALL)
            decisions = [d.strip() for d in decision_matches if d.strip()]
            
            # If no numbered/bullet points, split by sentences
            if not decisions:
                sentences = re.split(r'[.!?]\s+', decisions_text)
                decisions = [s.strip() for s in sentences if s.strip()]
        
        # Extract action items
        action_items = []
        action_text = sections.get('action items', sections.get('action', sections.get('next steps', '')))
        if action_text:
            # Look for patterns like "- John: Do something by Friday"
            action_matches = re.findall(r'(?:^|\n)\s*(?:\-|\*|\d+\.)\s*([^:]+):\s*(.+?)(?=(?:\n\s*(?:\-|\*|\d+\.))|$)', 
                                      action_text, re.MULTILINE | re.DOTALL)
            for assignee, task in action_matches:
                action_items.append({
                    'assignee': assignee.strip(),
                    'task': task.strip(),
                    'due_date': None
                })
        
        return ParsedTranscript(
            title=title,
            duration=None,
            participants=participants,
            dialogue=dialogue,
            decisions=decisions,
            action_items=action_items,
            raw_content=content,
            format_type='structured_text'
        )
    
    @monitor_sync_operation("parse_plain_text", "parsing")
    def _parse_plain_text(self, content: str, title: str) -> ParsedTranscript:
        """Parse plain text transcript."""
        # For plain text, create a single dialogue entry
        dialogue = [{
            'speaker': 'Meeting Content',
            'timestamp': '',
            'text': content.strip()
        }]
        
        return ParsedTranscript(
            title=title,
            duration=None,
            participants=[],
            dialogue=dialogue,
            decisions=[],
            action_items=[],
            raw_content=content,
            format_type='plain_text'
        )
    
    def _split_into_sections(self, content: str) -> Dict[str, str]:
        """Split structured text into sections."""
        sections = {}
        current_section = 'general'
        current_content = []
        
        lines = content.split('\n')
        
        for line in lines:
            line_lower = line.lower().strip()
            
            # Check for section headers
            section_name = None
            for keyword in ['meeting:', 'attendees:', 'participants:', 'agenda:', 
                          'discussion:', 'decisions:', 'key decisions:', 'action items:', 
                          'action:', 'next steps:', 'blockers:', 'notes:']:
                if line_lower.startswith(keyword):
                    section_name = keyword.replace(':', '').strip()
                    break
            
            if section_name:
                # Save previous section
                if current_content:
                    sections[current_section] = '\n'.join(current_content).strip()
                
                # Start new section
                current_section = section_name
                current_content = []
                
                # Include content after the header on the same line
                header_content = line[line.lower().find(section_name) + len(section_name):].strip()
                if header_content:
                    current_content.append(header_content)
            else:
                current_content.append(line)
        
        # Save final section
        if current_content:
            sections[current_section] = '\n'.join(current_content).strip()
        
        return sections
    
    def extract_content_for_chunking(self, parsed: ParsedTranscript) -> str:
        """
        Extract content from parsed transcript optimized for chunking.
        
        Args:
            parsed: ParsedTranscript object
            
        Returns:
            String optimized for semantic chunking
        """
        content_parts = []
        
        # Add title and metadata
        content_parts.append(f"Meeting: {parsed.title}")
        
        if parsed.duration:
            content_parts.append(f"Duration: {parsed.duration}")
        
        # Add participants
        if parsed.participants:
            participant_names = [p.get('name', 'Unknown') for p in parsed.participants]
            content_parts.append(f"Participants: {', '.join(participant_names)}")
            content_parts.append("")  # Empty line for separation
        
        # Add dialogue content - the main transcript
        if parsed.dialogue:
            content_parts.append("MEETING TRANSCRIPT:")
            for entry in parsed.dialogue:
                speaker = entry.get('speaker', 'Unknown')
                text = entry.get('text', '')
                timestamp = entry.get('timestamp', '')
                
                if timestamp:
                    content_parts.append(f"[{timestamp}] {speaker}: {text}")
                else:
                    content_parts.append(f"{speaker}: {text}")
            content_parts.append("")  # Separation
        
        # Add decisions section
        if parsed.decisions:
            content_parts.append("KEY DECISIONS MADE:")
            for i, decision in enumerate(parsed.decisions, 1):
                content_parts.append(f"{i}. {decision}")
            content_parts.append("")  # Separation
        
        # Add action items section
        if parsed.action_items:
            content_parts.append("ACTION ITEMS:")
            for item in parsed.action_items:
                if isinstance(item, dict):
                    assignee = item.get('assignee', 'Unassigned')
                    task = item.get('task', str(item))
                    due_date = item.get('due_date', '')
                    
                    action_text = f"- {assignee}: {task}"
                    if due_date:
                        action_text += f" (Due: {due_date})"
                    content_parts.append(action_text)
                else:
                    content_parts.append(f"- {item}")
            content_parts.append("")  # Separation
        
        # Join all parts
        processed_content = '\n'.join(content_parts).strip()
        
        logger.info(f"Extracted content for chunking: {len(processed_content)} chars, "
                   f"{len(processed_content.split())} words")
        
        return processed_content


# Global service instance
transcript_parser = TranscriptParser()