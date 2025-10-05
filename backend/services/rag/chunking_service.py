"""Text chunking service for splitting documents into overlapping segments."""

import re
from typing import List, Dict, Any, Optional
from dataclasses import dataclass

from config import get_settings
from utils.logger import get_logger
from utils.monitoring import monitor_operation, monitor_sync_operation

settings = get_settings()
logger = get_logger(__name__)


@dataclass
class TextChunk:
    """Represents a text chunk with metadata."""
    index: int
    text: str
    word_count: int
    char_count: int
    start_position: int
    end_position: int
    start_sentence: int
    end_sentence: int
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert chunk to dictionary."""
        return {
            'index': self.index,
            'text': self.text,
            'word_count': self.word_count,
            'char_count': self.char_count,
            'start_position': self.start_position,
            'end_position': self.end_position,
            'start_sentence': self.start_sentence,
            'end_sentence': self.end_sentence
        }


class ChunkingService:
    """Service for chunking text into overlapping segments."""
    
    def __init__(
        self,
        chunk_size_words: Optional[int] = None,
        overlap_words: Optional[int] = None,
        preserve_sentences: bool = True
    ):
        """
        Initialize chunking service.
        
        Args:
            chunk_size_words: Target chunk size in words (default from settings)
            overlap_words: Overlap between chunks in words (default from settings)
            preserve_sentences: Whether to preserve sentence boundaries
        """
        self.chunk_size_words = chunk_size_words or settings.chunk_size_words
        self.overlap_words = overlap_words or settings.chunk_overlap_words
        self.preserve_sentences = preserve_sentences
        
        # Validate parameters
        if self.overlap_words >= self.chunk_size_words:
            raise ValueError("Overlap must be less than chunk size")
        
        logger.info(
            f"ChunkingService initialized: chunk_size={self.chunk_size_words}, "
            f"overlap={self.overlap_words}, preserve_sentences={self.preserve_sentences}"
        )
    
    @monitor_sync_operation(
        operation_name="chunk_text",
        operation_type="parsing"
    )
    def chunk_text(
        self,
        text: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> List[TextChunk]:
        """
        Split text into overlapping chunks.
        
        Args:
            text: Text to chunk
            metadata: Optional metadata to include with each chunk
            
        Returns:
            List of TextChunk objects
        """
        if not text or not text.strip():
            logger.warning("Empty text provided for chunking")
            return []
        
        # Clean and normalize text
        text = self._normalize_text(text)
        
        if self.preserve_sentences:
            return self._chunk_by_sentences(text, metadata)
        else:
            return self._chunk_by_words(text, metadata)
    
    def _normalize_text(self, text: str) -> str:
        """
        Normalize text for consistent processing.
        
        Args:
            text: Raw text
            
        Returns:
            Normalized text
        """
        # Replace multiple whitespaces with single space (ReDoS-safe)
        # This normalizes all whitespace (spaces, tabs, newlines) into single spaces
        text = ' '.join(text.split())
        
        # Strip leading/trailing whitespace
        text = text.strip()
        
        return text
    
    def _split_into_sentences(self, text: str) -> List[str]:
        """
        Split text into sentences with improved handling for different content types.
        
        Args:
            text: Text to split
            
        Returns:
            List of sentences
        """
        # Detect if this is structured transcript content
        is_transcript = self._is_structured_transcript(text)
        
        if is_transcript:
            return self._split_structured_transcript(text)
        else:
            return self._split_prose_text(text)
    
    def _is_structured_transcript(self, text: str) -> bool:
        """Check if text appears to be a structured transcript."""
        patterns = [
            r'MEETING TRANSCRIPT:',
            r'KEY DECISIONS MADE:',
            r'ACTION ITEMS:',
            r'\[[0-9:]+\]\s+\w+:',  # Timestamp pattern
            r'^\w+\s+\w+:\s',       # Speaker pattern
            r'Participants?:',
            r'Duration:'
        ]
        
        matches = sum(1 for pattern in patterns if re.search(pattern, text, re.MULTILINE | re.IGNORECASE))
        return matches >= 2  # Need at least 2 patterns to consider it structured
    
    def _split_structured_transcript(self, text: str) -> List[str]:
        """Split structured transcript content into logical segments."""
        sentences = []
        
        # Split by major sections first
        section_patterns = [
            (r'MEETING TRANSCRIPT:', 'transcript'),
            (r'KEY DECISIONS MADE:', 'decisions'),
            (r'ACTION ITEMS:', 'actions'),
            (r'Participants?:', 'participants'),
            (r'Duration:', 'metadata')
        ]
        
        sections = self._split_by_sections(text, section_patterns)
        
        for section_name, content in sections.items():
            if not content.strip():
                continue
                
            if section_name == 'transcript':
                # Split transcript by speaker turns
                speaker_segments = self._split_by_speakers(content)
                sentences.extend(speaker_segments)
            elif section_name == 'decisions':
                # Split decisions by numbered items or sentences
                decision_segments = self._split_decision_items(content)
                sentences.extend(decision_segments)
            elif section_name == 'actions':
                # Split action items by lines/bullets
                action_segments = self._split_action_items(content)
                sentences.extend(action_segments)
            else:
                # For other sections, use regular sentence splitting
                prose_sentences = self._split_prose_text(content)
                sentences.extend(prose_sentences)
        
        # Filter and clean
        cleaned_sentences = []
        for sentence in sentences:
            cleaned = sentence.strip()
            if cleaned and len(cleaned) > 10:  # Minimum meaningful length
                cleaned_sentences.append(cleaned)
        
        logger.debug(f"Structured transcript split into {len(cleaned_sentences)} segments")
        return cleaned_sentences
    
    def _split_by_sections(self, text: str, patterns: List[tuple]) -> Dict[str, str]:
        """Split text by section headers."""
        sections = {'general': ''}
        current_section = 'general'
        lines = text.split('\n')
        
        for line in lines:
            # Check if this line starts a new section
            section_found = False
            for pattern, section_name in patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    current_section = section_name
                    section_found = True
                    # Include content after the header if any
                    header_content = re.sub(pattern, '', line, flags=re.IGNORECASE).strip()
                    if header_content:
                        sections[current_section] = sections.get(current_section, '') + header_content + '\n'
                    break
            
            if not section_found:
                sections[current_section] = sections.get(current_section, '') + line + '\n'
        
        return sections
    
    def _split_by_speakers(self, content: str) -> List[str]:
        """Split transcript content by speaker turns."""
        segments = []
        
        # Look for speaker patterns like "[12:34] John Doe: spoke about..." or "John Doe: spoke about..."
        speaker_pattern = r'(?:^\[[\d:]+\]\s+)?(\w+(?:\s+\w+)*?):\s*(.+?)(?=(?:^\[[\d:]+\]\s+)?\w+(?:\s+\w+)*?:|$)'
        
        matches = re.findall(speaker_pattern, content, re.MULTILINE | re.DOTALL)
        
        for speaker, text in matches:
            # Clean up the text
            text = text.strip().replace('\n', ' ')
            text = ' '.join(text.split())  # Normalize whitespace (ReDoS-safe)
            
            if text:
                segments.append(f"{speaker}: {text}")
        
        # If no speaker patterns found, split by meaningful line breaks
        if not segments:
            lines = [line.strip() for line in content.split('\n') if line.strip()]
            segments = [line for line in lines if len(line) > 20]  # Filter very short lines
        
        return segments
    
    def _split_decision_items(self, content: str) -> List[str]:
        """Split decision content into individual decisions."""
        decisions = []
        
        # Look for numbered or bulleted lists
        item_pattern = r'(?:^|\n)\s*(?:\d+\.|[-*•])\s*(.+?)(?=(?:\n\s*(?:\d+\.|[-*•]))|$)'
        matches = re.findall(item_pattern, content, re.MULTILINE | re.DOTALL)
        
        for match in matches:
            decision = match.strip().replace('\n', ' ')
            decision = ' '.join(decision.split())  # ReDoS-safe
            if decision:
                decisions.append(f"Decision: {decision}")
        
        # If no numbered items, split by sentences
        if not decisions:
            sentences = self._split_prose_text(content)
            decisions = [f"Decision: {s}" for s in sentences if s.strip()]
        
        return decisions
    
    def _split_action_items(self, content: str) -> List[str]:
        """Split action items content."""
        actions = []
        
        # Look for action item patterns like "- John: Do something"
        action_pattern = r'(?:^|\n)\s*[-*•]\s*([^:\n]+):\s*(.+?)(?=(?:\n\s*[-*•])|$)'
        matches = re.findall(action_pattern, content, re.MULTILINE | re.DOTALL)
        
        for assignee, task in matches:
            task = task.strip().replace('\n', ' ')
            task = ' '.join(task.split())  # ReDoS-safe
            if task:
                actions.append(f"Action - {assignee.strip()}: {task}")
        
        # If no action patterns found, treat each line as an action
        if not actions:
            lines = [line.strip() for line in content.split('\n') if line.strip() and not line.strip().startswith('ACTION')]
            actions = [f"Action: {line}" for line in lines if len(line) > 10]
        
        return actions
    
    def _split_prose_text(self, text: str) -> List[str]:
        """Split regular prose text into sentences (original algorithm)."""
        # Protect common abbreviations
        protected_text = text
        abbreviations = ['Mr.', 'Mrs.', 'Dr.', 'Ms.', 'Prof.', 'Sr.', 'Jr.', 'Ph.D', 'M.D', 'B.A', 'M.A', 'B.S', 'M.S']
        for abbr in abbreviations:
            protected_text = protected_text.replace(abbr, abbr.replace('.', '<!DOT!>'))
        
        # Enhanced sentence splitting patterns
        patterns = [
            r'(?<=[.!?])\s+(?=[A-Z])',      # Standard sentence endings
            r'(?<=[.!?])\s*\n\s*(?=[A-Z])', # Sentence endings with newlines
            r'\n\s*\n+',                    # Paragraph breaks
        ]
        
        sentences = [protected_text]
        
        # Apply each pattern
        for pattern in patterns:
            new_sentences = []
            for sentence in sentences:
                parts = re.split(pattern, sentence)
                new_sentences.extend(parts)
            sentences = new_sentences
        
        # Restore dots in abbreviations and clean up
        sentences = [s.replace('<!DOT!>', '.').strip() for s in sentences if s.strip()]
        
        return sentences
    
    @monitor_sync_operation(
        operation_name="chunk_by_sentences",
        operation_type="parsing"
    )
    def _chunk_by_sentences(
        self,
        text: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> List[TextChunk]:
        """
        Chunk text while preserving sentence boundaries.
        
        Args:
            text: Text to chunk
            metadata: Optional metadata
            
        Returns:
            List of TextChunk objects
        """
        sentences = self._split_into_sentences(text)
        if not sentences:
            return []
        
        chunks = []
        current_chunk_sentences = []
        current_word_count = 0
        chunk_index = 0
        sentence_index = 0
        
        for i, sentence in enumerate(sentences):
            sentence_words = sentence.split()
            sentence_word_count = len(sentence_words)
            
            # If adding this sentence exceeds chunk size and we have content
            if current_word_count + sentence_word_count > self.chunk_size_words and current_chunk_sentences:
                # Create chunk
                chunk_text = ' '.join(current_chunk_sentences)
                chunk = self._create_chunk(
                    index=chunk_index,
                    text=chunk_text,
                    word_count=current_word_count,
                    start_sentence=sentence_index,
                    end_sentence=i - 1
                )
                chunks.append(chunk)
                
                # Prepare overlap for next chunk
                overlap_sentences = []
                overlap_word_count = 0
                
                # Add sentences from the end until we reach overlap size
                for sent in reversed(current_chunk_sentences):
                    sent_words = len(sent.split())
                    if overlap_word_count + sent_words <= self.overlap_words:
                        overlap_sentences.insert(0, sent)
                        overlap_word_count += sent_words
                    else:
                        break
                
                # Start new chunk with overlap
                current_chunk_sentences = overlap_sentences
                current_word_count = overlap_word_count
                sentence_index = i - len(overlap_sentences)
                chunk_index += 1
            
            # Add sentence to current chunk
            current_chunk_sentences.append(sentence)
            current_word_count += sentence_word_count
        
        # Add remaining sentences as final chunk
        if current_chunk_sentences:
            chunk_text = ' '.join(current_chunk_sentences)
            chunk = self._create_chunk(
                index=chunk_index,
                text=chunk_text,
                word_count=current_word_count,
                start_sentence=sentence_index,
                end_sentence=len(sentences) - 1
            )
            chunks.append(chunk)
        
        logger.info(f"Created {len(chunks)} chunks from {len(sentences)} sentences")
        return chunks
    
    @monitor_sync_operation(
        operation_name="chunk_by_words",
        operation_type="parsing"
    )
    def _chunk_by_words(
        self,
        text: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> List[TextChunk]:
        """
        Chunk text by word count without preserving sentences.
        
        Args:
            text: Text to chunk
            metadata: Optional metadata
            
        Returns:
            List of TextChunk objects
        """
        words = text.split()
        if not words:
            return []
        
        chunks = []
        chunk_index = 0
        
        # Calculate stride (how many words to move forward for each chunk)
        stride = self.chunk_size_words - self.overlap_words
        
        for i in range(0, len(words), stride):
            # Get chunk words
            chunk_words = words[i:i + self.chunk_size_words]
            
            if not chunk_words:
                break
            
            chunk_text = ' '.join(chunk_words)
            chunk = self._create_chunk(
                index=chunk_index,
                text=chunk_text,
                word_count=len(chunk_words),
                start_sentence=-1,  # Not tracking sentences
                end_sentence=-1
            )
            chunks.append(chunk)
            chunk_index += 1
            
            # Stop if we've processed all words
            if i + self.chunk_size_words >= len(words):
                break
        
        logger.info(f"Created {len(chunks)} chunks from {len(words)} words")
        return chunks
    
    def _create_chunk(
        self,
        index: int,
        text: str,
        word_count: int,
        start_sentence: int,
        end_sentence: int
    ) -> TextChunk:
        """
        Create a TextChunk object.
        
        Args:
            index: Chunk index
            text: Chunk text
            word_count: Number of words
            start_sentence: Starting sentence index
            end_sentence: Ending sentence index
            
        Returns:
            TextChunk object
        """
        return TextChunk(
            index=index,
            text=text,
            word_count=word_count,
            char_count=len(text),
            start_position=index * (self.chunk_size_words - self.overlap_words),
            end_position=(index + 1) * (self.chunk_size_words - self.overlap_words),
            start_sentence=start_sentence,
            end_sentence=end_sentence
        )
    
    @monitor_sync_operation(
        operation_name="calculate_optimal_chunk_size",
        operation_type="analysis"
    )
    def calculate_optimal_chunk_size(
        self,
        text: str,
        target_chunks: int = 10,
        min_chunk_size: int = 100,
        max_chunk_size: int = 500
    ) -> int:
        """
        Calculate optimal chunk size for a given text.
        
        Args:
            text: Text to analyze
            target_chunks: Desired number of chunks
            min_chunk_size: Minimum chunk size in words
            max_chunk_size: Maximum chunk size in words
            
        Returns:
            Optimal chunk size in words
        """
        word_count = len(text.split())
        
        if word_count == 0:
            return min_chunk_size
        
        # Calculate ideal chunk size
        ideal_size = word_count // target_chunks
        
        # Apply constraints
        optimal_size = max(min_chunk_size, min(max_chunk_size, ideal_size))
        
        logger.debug(
            f"Calculated optimal chunk size: {optimal_size} words "
            f"(text has {word_count} words, target {target_chunks} chunks)"
        )
        
        return optimal_size
    
    def get_chunk_statistics(self, chunks: List[TextChunk]) -> Dict[str, Any]:
        """
        Get statistics about chunks.
        
        Args:
            chunks: List of chunks
            
        Returns:
            Dictionary with statistics
        """
        if not chunks:
            return {
                'total_chunks': 0,
                'total_words': 0,
                'total_chars': 0,
                'avg_words_per_chunk': 0,
                'avg_chars_per_chunk': 0,
                'min_chunk_words': 0,
                'max_chunk_words': 0,
                'overlap_ratio': 0
            }
        
        word_counts = [c.word_count for c in chunks]
        char_counts = [c.char_count for c in chunks]
        
        total_words = sum(word_counts)
        total_chars = sum(char_counts)
        
        # Calculate effective overlap ratio
        expected_words = len(chunks) * self.chunk_size_words
        overlap_ratio = (expected_words - total_words) / expected_words if expected_words > 0 else 0
        
        return {
            'total_chunks': len(chunks),
            'total_words': total_words,
            'total_chars': total_chars,
            'avg_words_per_chunk': total_words / len(chunks),
            'avg_chars_per_chunk': total_chars / len(chunks),
            'min_chunk_words': min(word_counts),
            'max_chunk_words': max(word_counts),
            'overlap_ratio': overlap_ratio,
            'chunk_size_target': self.chunk_size_words,
            'overlap_target': self.overlap_words
        }


# Global service instance with default settings
chunking_service = ChunkingService()