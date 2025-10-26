"""
Database models for audio recordings and transcripts.
"""

from sqlalchemy import Column, String, DateTime, Float, Text, ForeignKey, JSON, Boolean, Integer
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime

from db.database import Base


class Recording(Base):
    """Model for audio recordings."""
    
    __tablename__ = "recordings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    session_id = Column(String, unique=True, nullable=False)
    meeting_title = Column(String, nullable=False)
    
    # File information
    file_path = Column(String, nullable=False)
    file_size = Column(Integer)  # File size in bytes
    duration = Column(Float, nullable=False)  # Duration in seconds
    sample_rate = Column(Integer, default=16000)
    
    # Timestamps
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Status
    is_transcribed = Column(Boolean, default=False)
    transcription_status = Column(String, default="pending")  # pending, processing, completed, failed
    
    # Recording metadata
    recording_metadata = Column(JSON, default={})
    
    # Relationships
    # Note: Project relationship temporarily disabled until recordings table is created
    # project = relationship("Project", back_populates="recordings")
    transcripts = relationship("RecordingTranscript", back_populates="recording", cascade="all, delete-orphan")
    live_insights = relationship("LiveMeetingInsight", back_populates="recording", cascade="all, delete-orphan")
    
    def to_dict(self):
        """Convert to dictionary."""
        return {
            "id": str(self.id),
            "project_id": str(self.project_id),
            "session_id": self.session_id,
            "meeting_title": self.meeting_title,
            "file_path": self.file_path,
            "file_size": self.file_size,
            "duration": self.duration,
            "sample_rate": self.sample_rate,
            "start_time": self.start_time.isoformat() if self.start_time else None,
            "end_time": self.end_time.isoformat() if self.end_time else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "is_transcribed": self.is_transcribed,
            "transcription_status": self.transcription_status,
            "metadata": self.recording_metadata
        }


class RecordingTranscript(Base):
    """Model for recording transcripts."""
    
    __tablename__ = "recording_transcripts"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    recording_id = Column(UUID(as_uuid=True), ForeignKey("recordings.id", ondelete="CASCADE"), nullable=False)
    
    # Transcript content
    full_text = Column(Text, nullable=False)
    segments = Column(JSON, default=[])  # Array of segment objects with start, end, text
    
    # Language information
    language = Column(String, default="en")
    language_probability = Column(Float)
    
    # Processing information
    model_used = Column(String, default="whisper-large-v3")
    processing_time = Column(Float)  # Time taken to transcribe in seconds
    
    # Quality metrics
    avg_logprob = Column(Float)
    compression_ratio = Column(Float)
    no_speech_prob = Column(Float)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Recording metadata
    recording_metadata = Column(JSON, default={})
    
    # Relationships
    recording = relationship("Recording", back_populates="transcripts")
    
    def to_dict(self):
        """Convert to dictionary."""
        return {
            "id": str(self.id),
            "recording_id": str(self.recording_id),
            "full_text": self.full_text,
            "segments": self.segments,
            "language": self.language,
            "language_probability": self.language_probability,
            "model_used": self.model_used,
            "processing_time": self.processing_time,
            "avg_logprob": self.avg_logprob,
            "compression_ratio": self.compression_ratio,
            "no_speech_prob": self.no_speech_prob,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "metadata": self.recording_metadata
        }