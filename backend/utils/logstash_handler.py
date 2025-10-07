"""
Logstash Handler for Python Logging
Sends logs directly to Logstash HTTP input on port 8080
"""

import logging
import json
import socket
from datetime import datetime
from typing import Optional, Dict, Any


class LogstashHandler(logging.Handler):
    """
    Python logging handler that sends logs to Logstash TCP input.
    
    Usage:
        logger = logging.getLogger(__name__)
        logger.addHandler(LogstashHandler())
        logger.info("Test message", extra={"user_id": "123", "action": "login"})
    """
    
    def __init__(self, host: str = 'localhost', port: int = 8080,
                 app_name: str = 'pm_master', environment: str = 'development'):
        """
        Initialize Logstash handler.
        
        Args:
            host: Logstash host (default: localhost)
            port: Logstash HTTP port (default: 8080)
            app_name: Application name for logging
            environment: Environment (development, staging, production)
        """
        super().__init__()
        self.host = host
        self.port = port
        self.app_name = app_name
        self.environment = environment
        
    def emit(self, record: logging.LogRecord):
        """
        Send log record to Logstash.
        
        Args:
            record: Python LogRecord object
        """
        try:
            # Build the log entry
            log_entry = self._format_log_entry(record)
            
            # Send to Logstash via TCP
            self._send_to_logstash(log_entry)
            
        except Exception as e:
            # Don't let logging errors crash the application
            self.handleError(record)
    
    def _format_log_entry(self, record: logging.LogRecord) -> Dict[str, Any]:
        """
        Format log record as JSON for Logstash.
        
        Args:
            record: Python LogRecord object
            
        Returns:
            Dictionary formatted for Logstash
        """
        # Base log structure
        log_entry = {
            '@timestamp': datetime.utcnow().isoformat() + 'Z',
            'message': self.format(record),
            'level': record.levelname,
            'logger': record.name,
            'service': self.app_name,
            'environment': self.environment,
            'type': 'application',
            
            # Python logging metadata
            'python': {
                'module': record.module,
                'function': record.funcName,
                'line': record.lineno,
                'thread': record.thread,
                'thread_name': record.threadName,
                'process': record.process,
                'process_name': record.processName
            }
        }
        
        # Add exception info if present
        if record.exc_info:
            import traceback
            log_entry['exception'] = {
                'type': record.exc_info[0].__name__,
                'message': str(record.exc_info[1]),
                'stacktrace': traceback.format_exception(*record.exc_info)
            }
        
        # Add custom fields from 'extra' parameter
        if hasattr(record, 'user_id'):
            log_entry['user_id'] = record.user_id
            
        if hasattr(record, 'project_id'):
            log_entry['project_id'] = record.project_id
            
        if hasattr(record, 'meeting_id'):
            log_entry['meeting_id'] = record.meeting_id
            
        if hasattr(record, 'workflow_id'):
            log_entry['workflow_id'] = record.workflow_id
            
        # Add any RAG-specific fields
        if hasattr(record, 'rag_query'):
            log_entry['rag'] = {
                'query': getattr(record, 'rag_query', None),
                'chunks_retrieved': getattr(record, 'rag_chunks', None),
                'relevance_score': getattr(record, 'rag_score', None),
                'llm_model': getattr(record, 'llm_model', None),
                'tokens_used': getattr(record, 'tokens_used', None),
                'response_time_ms': getattr(record, 'response_time_ms', None)
            }
            
        # Add HTTP request fields if present
        if hasattr(record, 'request_method'):
            log_entry['request'] = {
                'method': getattr(record, 'request_method', None),
                'path': getattr(record, 'request_path', None),
                'status_code': getattr(record, 'status_code', None),
                'duration_ms': getattr(record, 'request_duration_ms', None),
                'ip': getattr(record, 'client_ip', None)
            }
            
        return log_entry
    
    def _send_to_logstash(self, log_entry: Dict[str, Any]):
        """
        Send log entry to Logstash via HTTP.

        Args:
            log_entry: Formatted log dictionary
        """
        try:
            import requests
            url = f"http://{self.host}:{self.port}"
            requests.post(url, json=log_entry, timeout=2)
        except Exception:
            # Silently fail - don't let logging errors break the app
            pass


class AsyncLogstashHandler(LogstashHandler):
    """
    Async version of LogstashHandler for non-blocking logging.
    Sends logs in background thread to avoid blocking the main application.
    """
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        import queue
        import threading
        
        self.queue = queue.Queue()
        self.thread = threading.Thread(target=self._worker, daemon=True)
        self.thread.start()
    
    def emit(self, record: logging.LogRecord):
        """Queue the record for async sending."""
        try:
            log_entry = self._format_log_entry(record)
            self.queue.put(log_entry, block=False)
        except queue.Full:
            self.handleError(record)
    
    def _worker(self):
        """Background thread worker to send logs."""
        while True:
            try:
                log_entry = self.queue.get()
                if log_entry is None:
                    break
                self._send_to_logstash(log_entry)
            except Exception:
                pass  # Silently ignore errors in background thread


# FastAPI integration example
def setup_logging(app_name: str = 'pm_master', 
                  environment: str = 'development',
                  log_level: str = 'INFO',
                  use_async: bool = True) -> logging.Logger:
    """
    Set up logging with Logstash handler.
    
    Args:
        app_name: Application name
        environment: Environment name
        log_level: Logging level
        use_async: Use async handler for non-blocking logs
        
    Returns:
        Configured logger
    """
    # Get root logger
    logger = logging.getLogger()
    logger.setLevel(getattr(logging, log_level))
    
    # Console handler for local development
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.DEBUG)
    console_formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)
    
    # Logstash handler
    Handler = AsyncLogstashHandler if use_async else LogstashHandler
    logstash_handler = Handler(
        host='localhost',
        port=8080,
        app_name=app_name,
        environment=environment
    )
    logstash_handler.setLevel(logging.INFO)
    logger.addHandler(logstash_handler)
    
    return logger


# Usage example for FastAPI
"""
from fastapi import FastAPI
from utils.logstash_handler import setup_logging

app = FastAPI()
logger = setup_logging(app_name='pm_master_api', environment='development')

@app.get("/")
async def root():
    logger.info("Root endpoint accessed", extra={
        "request_method": "GET",
        "request_path": "/",
        "client_ip": "127.0.0.1"
    })
    return {"message": "Hello World"}

@app.post("/meetings/{meeting_id}/process")
async def process_meeting(meeting_id: str):
    logger.info("Processing meeting", extra={
        "meeting_id": meeting_id,
        "action": "process_start"
    })
    
    try:
        # Your processing logic here
        result = await process_meeting_logic(meeting_id)
        
        logger.info("Meeting processed successfully", extra={
            "meeting_id": meeting_id,
            "action": "process_complete",
            "chunks_retrieved": result.chunks,
            "tokens_used": result.tokens
        })
        
    except Exception as e:
        logger.error("Meeting processing failed", extra={
            "meeting_id": meeting_id,
            "action": "process_error"
        }, exc_info=True)
        raise
"""