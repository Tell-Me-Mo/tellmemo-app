"""Advanced transcript processing service with meeting intelligence extraction."""

import json
import re
from typing import List, Dict, Any, Optional, Tuple, Set
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from collections import defaultdict
import asyncio

import spacy
from sentence_transformers import SentenceTransformer

from utils.logger import get_logger
from utils.monitoring import monitor_operation, monitor_sync_operation, MonitoringContext
from services.transcription.transcript_parser import transcript_parser, ParsedTranscript

logger = get_logger(__name__)


@dataclass
class SpeakerTurn:
    """Represents a speaker turn in the meeting."""
    speaker: str
    timestamp: Optional[str]
    text: str
    duration_seconds: Optional[float]
    start_position: int
    end_position: int
    segment_id: str
    topic_id: Optional[str] = None
    sentiment: Optional[str] = None
    turn_index: int = 0


@dataclass
class TopicSegment:
    """Represents a topic segment in the meeting."""
    topic_id: str
    topic_name: str
    start_timestamp: Optional[str]
    end_timestamp: Optional[str]
    speakers: List[str]
    key_points: List[str]
    speaker_turns: List[SpeakerTurn]
    duration_seconds: Optional[float]
    semantic_score: float


@dataclass
class DecisionPoint:
    """Represents a decision made during the meeting."""
    decision_id: str
    decision_text: str
    decision_type: str  # 'formal', 'informal', 'deferred'
    participants: List[str]
    context: str
    timestamp: Optional[str]
    confidence: float
    related_topic: Optional[str] = None
    outcome: Optional[str] = None


@dataclass
class ActionItem:
    """Represents an action item from the meeting."""
    action_id: str
    task_description: str
    assignee: Optional[str]
    deadline: Optional[str]
    priority: str  # 'high', 'medium', 'low'
    context: str
    timestamp: Optional[str]
    confidence: float
    status: str = 'pending'
    dependencies: List[str] = None


@dataclass
class MeetingOutcome:
    """Represents the overall meeting outcome classification."""
    outcome_type: str  # 'decision_made', 'information_sharing', 'planning', 'review', 'problem_solving'
    key_themes: List[str]
    success_indicators: List[str]
    blockers_identified: List[str]
    follow_up_required: bool
    confidence: float


@dataclass
class TemporalRelationship:
    """Represents temporal relationships between meeting elements."""
    relationship_id: str
    from_element: str
    to_element: str
    relationship_type: str  # 'leads_to', 'caused_by', 'prerequisite_for', 'follows'
    confidence: float
    context: str


@dataclass
class AdvancedTranscriptAnalysis:
    """Complete advanced analysis of a meeting transcript."""
    original_transcript: ParsedTranscript
    speaker_turns: List[SpeakerTurn]
    topic_segments: List[TopicSegment]
    decision_points: List[DecisionPoint]
    action_items: List[ActionItem]
    meeting_outcome: MeetingOutcome
    temporal_relationships: List[TemporalRelationship]
    participant_engagement: Dict[str, Dict[str, Any]]
    meeting_statistics: Dict[str, Any]
    processing_metadata: Dict[str, Any]


class AdvancedTranscriptProcessor:
    """Advanced transcript processing service with AI-powered analysis."""
    
    def __init__(self):
        """Initialize the advanced transcript processor."""
        from config import get_settings
        self.settings = get_settings()
        self.nlp_model = None
        self.sentence_transformer = None
        self.semantic_threshold = 0.75  # For topic segmentation
        self.decision_keywords = [
            'decided', 'decision', 'choose', 'selected', 'approved', 'agreed',
            'concluded', 'resolved', 'determined', 'committed', 'voted',
            'consensus', 'final', 'settled'
        ]
        self.action_keywords = [
            'will', 'should', 'must', 'need to', 'action', 'task', 'todo',
            'responsibility', 'assigned', 'follow up', 'next step', 'by'
        ]
        self.temporal_keywords = [
            'after', 'before', 'during', 'while', 'then', 'next', 'following',
            'previously', 'earlier', 'later', 'meanwhile', 'subsequently'
        ]
        
        # Initialize models asynchronously
        self._initialize_models()
    
    def _initialize_models(self):
        """Initialize NLP models."""
        try:
            # Load spaCy model for NLP processing
            try:
                self.nlp_model = spacy.load("en_core_web_sm")
                logger.info("Loaded spaCy model: en_core_web_sm")
            except OSError:
                logger.warning("spaCy model 'en_core_web_sm' not found. Install with: python -m spacy download en_core_web_sm")
                # Use a basic model or disable NLP features
                self.nlp_model = None
            
            # Load sentence transformer for semantic analysis
            try:
                self.sentence_transformer = SentenceTransformer(self.settings.sentence_transformer_model)
                logger.info(f"Loaded SentenceTransformer: {self.settings.sentence_transformer_model}")
            except Exception as e:
                logger.warning(f"Failed to load SentenceTransformer: {e}")
                self.sentence_transformer = None
                
        except Exception as e:
            logger.error(f"Failed to initialize NLP models: {e}")
            self.nlp_model = None
            self.sentence_transformer = None
    
    @monitor_operation(
        operation_name="process_transcript",
        operation_type="parsing",
        capture_args=True,
        capture_result=True
    )
    async def process_transcript(
        self,
        transcript_content: str,
        title: str = "Meeting Transcript"
    ) -> AdvancedTranscriptAnalysis:
        """
        Process transcript with advanced analysis.
        
        Args:
            transcript_content: Raw transcript content
            title: Meeting title
            
        Returns:
            AdvancedTranscriptAnalysis with comprehensive meeting intelligence
        """
        start_time = datetime.now()
        
        try:
            # Parse the basic transcript structure
            logger.info(f"Starting advanced transcript processing for: {title}")
            parsed_transcript = transcript_parser.parse_transcript(transcript_content, title)
            
            # Extract speaker turns with detailed analysis
            speaker_turns = await self._extract_speaker_turns(parsed_transcript)
            
            # Perform topic segmentation
            topic_segments = await self._perform_topic_segmentation(speaker_turns)
            
            # Extract decision points
            decision_points = await self._extract_decision_points(speaker_turns, topic_segments)
            
            # Extract action items
            action_items = await self._extract_action_items(speaker_turns, topic_segments)
            
            # Classify meeting outcome
            meeting_outcome = await self._classify_meeting_outcome(
                speaker_turns, topic_segments, decision_points, action_items
            )
            
            # Map temporal relationships
            temporal_relationships = await self._map_temporal_relationships(
                speaker_turns, decision_points, action_items
            )
            
            # Analyze participant engagement
            participant_engagement = await self._analyze_participant_engagement(
                speaker_turns, parsed_transcript.participants
            )
            
            # Generate meeting statistics
            meeting_statistics = self._generate_meeting_statistics(
                speaker_turns, topic_segments, decision_points, action_items
            )
            
            # Processing metadata
            processing_time = (datetime.now() - start_time).total_seconds()
            processing_metadata = {
                'processing_time_seconds': processing_time,
                'nlp_model_used': 'en_core_web_sm' if self.nlp_model else None,
                'sentence_transformer_used': self.settings.sentence_transformer_model if self.sentence_transformer else None,
                'timestamp': datetime.now().isoformat(),
                'version': '1.0.0'
            }
            
            analysis = AdvancedTranscriptAnalysis(
                original_transcript=parsed_transcript,
                speaker_turns=speaker_turns,
                topic_segments=topic_segments,
                decision_points=decision_points,
                action_items=action_items,
                meeting_outcome=meeting_outcome,
                temporal_relationships=temporal_relationships,
                participant_engagement=participant_engagement,
                meeting_statistics=meeting_statistics,
                processing_metadata=processing_metadata
            )
            
            logger.info(f"Advanced transcript processing completed in {processing_time:.2f}s")
            logger.info(f"Extracted: {len(speaker_turns)} turns, {len(topic_segments)} topics, "
                       f"{len(decision_points)} decisions, {len(action_items)} actions")
            
            return analysis
            
        except Exception as e:
            logger.error(f"Advanced transcript processing failed: {e}")
            raise
    
    @monitor_operation(
        operation_name="extract_speaker_turns",
        operation_type="parsing",
        capture_args=False,
        capture_result=True
    )
    async def _extract_speaker_turns(self, parsed: ParsedTranscript) -> List[SpeakerTurn]:
        """Extract and analyze speaker turns."""
        turns = []
        turn_index = 0
        
        for i, entry in enumerate(parsed.dialogue):
            speaker = entry.get('speaker', 'Unknown')
            text = entry.get('text', '')
            timestamp = entry.get('timestamp', '')
            
            if not text.strip():
                continue
            
            # Generate unique segment ID
            segment_id = f"turn_{i:03d}_{speaker.lower().replace(' ', '_')}"
            
            # Parse duration if available in timestamp
            duration_seconds = self._parse_duration_from_timestamp(timestamp)
            
            # Analyze sentiment if NLP model is available
            sentiment = None
            if self.nlp_model:
                sentiment = self._analyze_sentiment(text)
            
            turn = SpeakerTurn(
                speaker=speaker,
                timestamp=timestamp,
                text=text,
                duration_seconds=duration_seconds,
                start_position=len(' '.join([t.text for t in turns])),
                end_position=len(' '.join([t.text for t in turns])) + len(text),
                segment_id=segment_id,
                sentiment=sentiment,
                turn_index=turn_index
            )
            
            turns.append(turn)
            turn_index += 1
        
        logger.debug(f"Extracted {len(turns)} speaker turns")
        return turns
    
    @monitor_operation(
        operation_name="perform_topic_segmentation",
        operation_type="analysis",
        capture_args=False,
        capture_result=True
    )
    async def _perform_topic_segmentation(self, speaker_turns: List[SpeakerTurn]) -> List[TopicSegment]:
        """Perform semantic topic segmentation."""
        if not speaker_turns or not self.sentence_transformer:
            logger.warning("Cannot perform topic segmentation - missing data or model")
            return self._fallback_topic_segmentation(speaker_turns)
        
        try:
            # Extract texts for embedding
            texts = [turn.text for turn in speaker_turns]
            
            # Generate embeddings
            embeddings = self.sentence_transformer.encode(texts)
            
            # Perform semantic segmentation using sliding window approach
            segments = []
            current_segment_turns = []
            current_topic_id = None
            segment_count = 0
            
            for i, turn in enumerate(speaker_turns):
                # Start new segment
                if not current_segment_turns:
                    current_segment_turns = [turn]
                    current_topic_id = f"topic_{segment_count:03d}"
                    continue
                
                # Calculate semantic similarity with current segment
                current_embedding = embeddings[i]
                segment_embeddings = embeddings[max(0, i-3):i]  # Look at previous 3 turns
                
                if len(segment_embeddings) > 0:
                    # Calculate average similarity
                    similarities = []
                    for prev_emb in segment_embeddings:
                        similarity = self._cosine_similarity(current_embedding, prev_emb)
                        similarities.append(similarity)
                    
                    avg_similarity = sum(similarities) / len(similarities)
                    
                    # If similarity drops below threshold, start new segment
                    if avg_similarity < self.semantic_threshold:
                        # Finalize current segment
                        if current_segment_turns:
                            segment = self._create_topic_segment(
                                current_topic_id, current_segment_turns, segment_count
                            )
                            segments.append(segment)
                        
                        # Start new segment
                        current_segment_turns = [turn]
                        segment_count += 1
                        current_topic_id = f"topic_{segment_count:03d}"
                    else:
                        current_segment_turns.append(turn)
                else:
                    current_segment_turns.append(turn)
            
            # Add final segment
            if current_segment_turns:
                segment = self._create_topic_segment(
                    current_topic_id, current_segment_turns, segment_count
                )
                segments.append(segment)
            
            logger.info(f"Performed semantic topic segmentation: {len(segments)} topics")
            return segments
            
        except Exception as e:
            logger.error(f"Topic segmentation failed: {e}")
            return self._fallback_topic_segmentation(speaker_turns)
    
    def _fallback_topic_segmentation(self, speaker_turns: List[SpeakerTurn]) -> List[TopicSegment]:
        """Fallback topic segmentation using heuristics."""
        if not speaker_turns:
            return []
        
        # Simple segmentation based on speaker changes and time gaps
        segments = []
        current_turns = []
        segment_count = 0
        
        for i, turn in enumerate(speaker_turns):
            if not current_turns:
                current_turns = [turn]
                continue
            
            # Start new segment based on heuristics
            should_segment = False
            
            # Long pause (if timestamps available)
            if turn.timestamp and current_turns[-1].timestamp:
                # Implement time gap detection logic here
                pass
            
            # Speaker change after substantial content
            if (turn.speaker != current_turns[-1].speaker and 
                len(' '.join(t.text for t in current_turns)) > 200):
                should_segment = True
            
            # Maximum segment size
            if len(current_turns) >= 10:
                should_segment = True
            
            if should_segment:
                # Create segment
                topic_id = f"topic_{segment_count:03d}"
                segment = self._create_topic_segment(topic_id, current_turns, segment_count)
                segments.append(segment)
                
                # Start new segment
                current_turns = [turn]
                segment_count += 1
            else:
                current_turns.append(turn)
        
        # Add final segment
        if current_turns:
            topic_id = f"topic_{segment_count:03d}"
            segment = self._create_topic_segment(topic_id, current_turns, segment_count)
            segments.append(segment)
        
        return segments
    
    def _create_topic_segment(
        self, 
        topic_id: str, 
        turns: List[SpeakerTurn], 
        segment_index: int
    ) -> TopicSegment:
        """Create a topic segment from speaker turns."""
        if not turns:
            return None
        
        # Extract key information
        speakers = list(set(turn.speaker for turn in turns))
        all_text = ' '.join(turn.text for turn in turns)
        
        # Generate topic name using keyword extraction
        topic_name = self._extract_topic_name(all_text, segment_index)
        
        # Extract key points
        key_points = self._extract_key_points(turns)
        
        # Calculate duration
        duration_seconds = sum(
            turn.duration_seconds for turn in turns 
            if turn.duration_seconds is not None
        ) or None
        
        # Assign topic_id to turns
        for turn in turns:
            turn.topic_id = topic_id
        
        return TopicSegment(
            topic_id=topic_id,
            topic_name=topic_name,
            start_timestamp=turns[0].timestamp if turns[0].timestamp else None,
            end_timestamp=turns[-1].timestamp if turns[-1].timestamp else None,
            speakers=speakers,
            key_points=key_points,
            speaker_turns=turns,
            duration_seconds=duration_seconds,
            semantic_score=0.8  # Default score
        )
    
    @monitor_operation(
        operation_name="extract_decision_points",
        operation_type="analysis",
        capture_args=False,
        capture_result=True
    )
    async def _extract_decision_points(
        self,
        speaker_turns: List[SpeakerTurn],
        topic_segments: List[TopicSegment]
    ) -> List[DecisionPoint]:
        """Extract decision points from the meeting."""
        decisions = []
        decision_count = 0
        
        for turn in speaker_turns:
            text_lower = turn.text.lower()
            
            # Check for decision keywords
            decision_indicators = []
            for keyword in self.decision_keywords:
                if keyword in text_lower:
                    decision_indicators.append(keyword)
            
            if decision_indicators:
                # Analyze the decision context
                decision_text = self._extract_decision_text(turn.text)
                decision_type = self._classify_decision_type(turn.text)
                confidence = self._calculate_decision_confidence(turn.text, decision_indicators)
                
                # Find related participants (from nearby turns)
                participants = self._find_related_participants(turn, speaker_turns)
                
                # Find related topic
                related_topic = None
                for segment in topic_segments:
                    if turn in segment.speaker_turns:
                        related_topic = segment.topic_name
                        break
                
                decision = DecisionPoint(
                    decision_id=f"decision_{decision_count:03d}",
                    decision_text=decision_text,
                    decision_type=decision_type,
                    participants=participants,
                    context=turn.text,
                    timestamp=turn.timestamp,
                    confidence=confidence,
                    related_topic=related_topic
                )
                
                decisions.append(decision)
                decision_count += 1
        
        logger.debug(f"Extracted {len(decisions)} decision points")
        return decisions
    
    @monitor_operation(
        operation_name="extract_action_items",
        operation_type="analysis",
        capture_args=False,
        capture_result=True
    )
    async def _extract_action_items(
        self,
        speaker_turns: List[SpeakerTurn],
        topic_segments: List[TopicSegment]
    ) -> List[ActionItem]:
        """Extract action items from the meeting."""
        actions = []
        action_count = 0
        
        for turn in speaker_turns:
            text_lower = turn.text.lower()
            
            # Check for action keywords
            action_indicators = []
            for keyword in self.action_keywords:
                if keyword in text_lower:
                    action_indicators.append(keyword)
            
            if action_indicators:
                # Extract task description
                task_description = self._extract_task_description(turn.text)
                
                # Extract assignee
                assignee = self._extract_assignee(turn.text, turn.speaker)
                
                # Extract deadline
                deadline = self._extract_deadline(turn.text)
                
                # Determine priority
                priority = self._determine_action_priority(turn.text)
                
                # Calculate confidence
                confidence = self._calculate_action_confidence(turn.text, action_indicators)
                
                action = ActionItem(
                    action_id=f"action_{action_count:03d}",
                    task_description=task_description,
                    assignee=assignee,
                    deadline=deadline,
                    priority=priority,
                    context=turn.text,
                    timestamp=turn.timestamp,
                    confidence=confidence
                )
                
                actions.append(action)
                action_count += 1
        
        logger.debug(f"Extracted {len(actions)} action items")
        return actions
    
    async def _classify_meeting_outcome(
        self,
        speaker_turns: List[SpeakerTurn],
        topic_segments: List[TopicSegment],
        decision_points: List[DecisionPoint],
        action_items: List[ActionItem]
    ) -> MeetingOutcome:
        """Classify the overall meeting outcome."""
        # Determine outcome type
        outcome_type = 'information_sharing'  # default
        
        if len(decision_points) > 0:
            outcome_type = 'decision_made'
        elif len(action_items) > 2:
            outcome_type = 'planning'
        elif len(topic_segments) > 3:
            outcome_type = 'review'
        
        # Extract key themes from topic segments
        key_themes = [segment.topic_name for segment in topic_segments]
        
        # Identify success indicators
        success_indicators = []
        all_text = ' '.join(turn.text for turn in speaker_turns).lower()
        
        success_keywords = ['completed', 'achieved', 'successful', 'agreed', 'resolved']
        for keyword in success_keywords:
            if keyword in all_text:
                success_indicators.append(f"Meeting contained positive outcome: {keyword}")
        
        # Identify blockers
        blockers_identified = []
        blocker_keywords = ['blocked', 'issue', 'problem', 'concern', 'risk', 'delay']
        for keyword in blocker_keywords:
            if keyword in all_text:
                blockers_identified.append(f"Potential blocker identified: {keyword}")
        
        # Determine if follow-up is required
        follow_up_required = len(action_items) > 0 or 'follow up' in all_text
        
        # Calculate confidence (simple heuristic)
        confidence = 0.7
        if len(decision_points) > 0:
            confidence += 0.1
        if len(action_items) > 0:
            confidence += 0.1
        confidence = min(confidence, 0.95)
        
        return MeetingOutcome(
            outcome_type=outcome_type,
            key_themes=key_themes,
            success_indicators=success_indicators,
            blockers_identified=blockers_identified,
            follow_up_required=follow_up_required,
            confidence=confidence
        )
    
    async def _map_temporal_relationships(
        self,
        speaker_turns: List[SpeakerTurn],
        decision_points: List[DecisionPoint],
        action_items: List[ActionItem]
    ) -> List[TemporalRelationship]:
        """Map temporal relationships between meeting elements."""
        relationships = []
        relationship_count = 0
        
        # Map decisions leading to actions
        for decision in decision_points:
            for action in action_items:
                # Check if action is mentioned after decision
                if self._is_temporally_related(decision, action, speaker_turns):
                    relationship = TemporalRelationship(
                        relationship_id=f"rel_{relationship_count:03d}",
                        from_element=decision.decision_id,
                        to_element=action.action_id,
                        relationship_type='leads_to',
                        confidence=0.8,
                        context=f"Decision '{decision.decision_text}' leads to action '{action.task_description}'"
                    )
                    relationships.append(relationship)
                    relationship_count += 1
        
        logger.debug(f"Mapped {len(relationships)} temporal relationships")
        return relationships
    
    @monitor_operation(
        operation_name="analyze_participant_engagement",
        operation_type="analysis",
        capture_args=False,
        capture_result=True
    )
    async def _analyze_participant_engagement(
        self,
        speaker_turns: List[SpeakerTurn],
        participants: List[Dict[str, str]]
    ) -> Dict[str, Dict[str, Any]]:
        """Analyze participant engagement metrics."""
        engagement = {}
        
        # Count speaking turns per participant
        speaker_stats = defaultdict(lambda: {
            'turn_count': 0,
            'word_count': 0,
            'total_time': 0,
            'topics_participated': set(),
            'questions_asked': 0,
            'decisions_influenced': 0
        })
        
        for turn in speaker_turns:
            stats = speaker_stats[turn.speaker]
            stats['turn_count'] += 1
            stats['word_count'] += len(turn.text.split())
            if turn.duration_seconds:
                stats['total_time'] += turn.duration_seconds
            if turn.topic_id:
                stats['topics_participated'].add(turn.topic_id)
            
            # Count questions
            if '?' in turn.text:
                stats['questions_asked'] += turn.text.count('?')
        
        # Convert to regular dict and calculate derived metrics
        for speaker, stats in speaker_stats.items():
            total_turns = sum(s['turn_count'] for s in speaker_stats.values())
            total_words = sum(s['word_count'] for s in speaker_stats.values())
            
            engagement[speaker] = {
                'turn_count': stats['turn_count'],
                'word_count': stats['word_count'],
                'speaking_time_seconds': stats['total_time'],
                'topics_participated': len(stats['topics_participated']),
                'questions_asked': stats['questions_asked'],
                'participation_ratio': stats['turn_count'] / total_turns if total_turns > 0 else 0,
                'word_share': stats['word_count'] / total_words if total_words > 0 else 0,
                'avg_words_per_turn': stats['word_count'] / stats['turn_count'] if stats['turn_count'] > 0 else 0,
                'engagement_score': min((stats['turn_count'] * 0.3 + 
                                       len(stats['topics_participated']) * 0.4 +
                                       stats['questions_asked'] * 0.3) / 10, 1.0)
            }
        
        logger.debug(f"Analyzed engagement for {len(engagement)} participants")
        return engagement
    
    def _generate_meeting_statistics(
        self,
        speaker_turns: List[SpeakerTurn],
        topic_segments: List[TopicSegment],
        decision_points: List[DecisionPoint],
        action_items: List[ActionItem]
    ) -> Dict[str, Any]:
        """Generate comprehensive meeting statistics."""
        total_words = sum(len(turn.text.split()) for turn in speaker_turns)
        total_duration = sum(
            turn.duration_seconds for turn in speaker_turns 
            if turn.duration_seconds is not None
        ) or 0
        
        return {
            'total_speaker_turns': len(speaker_turns),
            'total_words': total_words,
            'total_duration_seconds': total_duration,
            'average_words_per_turn': total_words / len(speaker_turns) if speaker_turns else 0,
            'unique_speakers': len(set(turn.speaker for turn in speaker_turns)),
            'topic_segments': len(topic_segments),
            'decision_points': len(decision_points),
            'action_items': len(action_items),
            'decisions_per_topic': len(decision_points) / len(topic_segments) if topic_segments else 0,
            'actions_per_decision': len(action_items) / len(decision_points) if decision_points else 0,
            'meeting_density': total_words / total_duration if total_duration > 0 else 0,
            'engagement_distribution': self._calculate_engagement_distribution(speaker_turns)
        }
    
    # Helper methods
    def _parse_duration_from_timestamp(self, timestamp: str) -> Optional[float]:
        """Parse duration from timestamp format."""
        if not timestamp:
            return None
        
        # Handle formats like [12:34] or 12:34:56
        time_pattern = r'(\d{1,2}):(\d{2})(?::(\d{2}))?'
        match = re.search(time_pattern, timestamp)
        
        if match:
            hours, minutes, seconds = match.groups()
            total_seconds = int(hours) * 3600 + int(minutes) * 60
            if seconds:
                total_seconds += int(seconds)
            return float(total_seconds)
        
        return None
    
    def _analyze_sentiment(self, text: str) -> Optional[str]:
        """Analyze sentiment of text using NLP."""
        if not self.nlp_model:
            return None
        
        # Simple sentiment analysis (can be enhanced with proper models)
        positive_words = ['good', 'great', 'excellent', 'positive', 'agree', 'yes', 'perfect']
        negative_words = ['bad', 'issue', 'problem', 'concern', 'disagree', 'no', 'wrong']
        
        text_lower = text.lower()
        positive_score = sum(1 for word in positive_words if word in text_lower)
        negative_score = sum(1 for word in negative_words if word in text_lower)
        
        if positive_score > negative_score:
            return 'positive'
        elif negative_score > positive_score:
            return 'negative'
        else:
            return 'neutral'
    
    def _cosine_similarity(self, a, b):
        """Calculate cosine similarity between two vectors."""
        import numpy as np
        return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
    
    def _extract_topic_name(self, text: str, segment_index: int) -> str:
        """Extract topic name from text."""
        # Simple keyword extraction (can be enhanced with NLP)
        words = text.lower().split()
        
        # Filter out common words
        stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'i', 'we', 'you', 'they', 'he', 'she', 'it'}
        meaningful_words = [w for w in words if w not in stop_words and len(w) > 3]
        
        # Find most frequent meaningful words
        word_freq = defaultdict(int)
        for word in meaningful_words:
            word_freq[word] += 1
        
        if word_freq:
            top_words = sorted(word_freq.items(), key=lambda x: x[1], reverse=True)[:2]
            topic_name = ' '.join([word for word, freq in top_words]).title()
        else:
            topic_name = f"Discussion {segment_index + 1}"
        
        return topic_name
    
    def _extract_key_points(self, turns: List[SpeakerTurn]) -> List[str]:
        """Extract key points from speaker turns."""
        key_points = []
        
        for turn in turns:
            # Look for sentences with decision or action indicators
            sentences = turn.text.split('.')
            for sentence in sentences:
                sentence = sentence.strip()
                if len(sentence) > 20:  # Meaningful length
                    # Check for key point indicators
                    indicators = ['decided', 'agreed', 'concluded', 'important', 'key', 'main']
                    if any(indicator in sentence.lower() for indicator in indicators):
                        key_points.append(sentence)
        
        return key_points[:3]  # Limit to top 3 key points
    
    def _extract_decision_text(self, text: str) -> str:
        """Extract the core decision text."""
        # Look for the sentence containing the decision
        sentences = text.split('.')
        for sentence in sentences:
            if any(keyword in sentence.lower() for keyword in self.decision_keywords):
                return sentence.strip()
        return text[:100] + "..." if len(text) > 100 else text
    
    def _classify_decision_type(self, text: str) -> str:
        """Classify the type of decision."""
        text_lower = text.lower()
        
        if any(word in text_lower for word in ['vote', 'formal', 'official', 'approved']):
            return 'formal'
        elif any(word in text_lower for word in ['later', 'defer', 'postpone', 'table']):
            return 'deferred'
        else:
            return 'informal'
    
    def _calculate_decision_confidence(self, text: str, indicators: List[str]) -> float:
        """Calculate confidence score for decision extraction."""
        base_confidence = 0.5
        confidence = base_confidence + (len(indicators) * 0.1)
        
        # Boost confidence for explicit decision language
        explicit_words = ['final', 'decided', 'concluded', 'resolved']
        for word in explicit_words:
            if word in text.lower():
                confidence += 0.1
        
        return min(confidence, 0.95)
    
    def _find_related_participants(self, turn: SpeakerTurn, all_turns: List[SpeakerTurn]) -> List[str]:
        """Find participants related to this decision/action."""
        participants = [turn.speaker]
        
        # Look for nearby turns (context window)
        turn_index = all_turns.index(turn) if turn in all_turns else -1
        if turn_index >= 0:
            # Check 2 turns before and after
            start_idx = max(0, turn_index - 2)
            end_idx = min(len(all_turns), turn_index + 3)
            
            for nearby_turn in all_turns[start_idx:end_idx]:
                if nearby_turn.speaker not in participants:
                    participants.append(nearby_turn.speaker)
        
        return participants
    
    def _extract_task_description(self, text: str) -> str:
        """Extract task description from action text."""
        # Look for the main action phrase
        sentences = text.split('.')
        for sentence in sentences:
            if any(keyword in sentence.lower() for keyword in self.action_keywords):
                return sentence.strip()
        return text[:100] + "..." if len(text) > 100 else text
    
    def _extract_assignee(self, text: str, speaker: str) -> Optional[str]:
        """Extract assignee from action text."""
        # Look for name patterns
        text_lower = text.lower()
        
        # Check for explicit assignment
        assignment_patterns = [
            r'(\w+)\s+will',
            r'(\w+)\s+should',
            r'(\w+)\'s\s+responsibility',
            r'assigned\s+to\s+(\w+)'
        ]
        
        for pattern in assignment_patterns:
            match = re.search(pattern, text_lower)
            if match:
                return match.group(1).title()
        
        # Default to speaker if no explicit assignment
        return speaker
    
    def _extract_deadline(self, text: str) -> Optional[str]:
        """Extract deadline from action text."""
        # Look for time expressions
        time_patterns = [
            r'by\s+(\w+day)',
            r'by\s+(\w+\s+\d{1,2})',
            r'by\s+(next\s+\w+)',
            r'deadline\s+(\w+)',
            r'due\s+(\w+day|\w+\s+\d{1,2})'
        ]
        
        for pattern in time_patterns:
            match = re.search(pattern, text.lower())
            if match:
                return match.group(1)
        
        return None
    
    def _determine_action_priority(self, text: str) -> str:
        """Determine priority level of action."""
        text_lower = text.lower()
        
        if any(word in text_lower for word in ['urgent', 'asap', 'immediately', 'critical']):
            return 'high'
        elif any(word in text_lower for word in ['important', 'soon', 'priority']):
            return 'medium'
        else:
            return 'low'
    
    def _calculate_action_confidence(self, text: str, indicators: List[str]) -> float:
        """Calculate confidence score for action extraction."""
        base_confidence = 0.6
        confidence = base_confidence + (len(indicators) * 0.08)
        
        # Boost for explicit action language
        explicit_words = ['will do', 'assigned', 'responsible', 'action item']
        for word in explicit_words:
            if word in text.lower():
                confidence += 0.1
        
        return min(confidence, 0.95)
    
    def _is_temporally_related(
        self,
        decision: DecisionPoint,
        action: ActionItem,
        speaker_turns: List[SpeakerTurn]
    ) -> bool:
        """Check if decision and action are temporally related."""
        # Simple heuristic: action mentioned within 3 turns of decision
        decision_turn_idx = -1
        action_turn_idx = -1
        
        for i, turn in enumerate(speaker_turns):
            if decision.context in turn.text:
                decision_turn_idx = i
            if action.context in turn.text:
                action_turn_idx = i
        
        if decision_turn_idx >= 0 and action_turn_idx >= 0:
            return abs(action_turn_idx - decision_turn_idx) <= 3
        
        return False
    
    def _calculate_engagement_distribution(self, speaker_turns: List[SpeakerTurn]) -> Dict[str, float]:
        """Calculate engagement distribution across speakers."""
        speaker_counts = defaultdict(int)
        for turn in speaker_turns:
            speaker_counts[turn.speaker] += 1
        
        total_turns = len(speaker_turns)
        return {
            speaker: count / total_turns 
            for speaker, count in speaker_counts.items()
        }


# Global service instance
advanced_transcript_processor = AdvancedTranscriptProcessor()