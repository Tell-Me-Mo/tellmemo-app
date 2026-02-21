"""Utilities for validating and sanitizing text content before storage."""

from fastapi import HTTPException

# Common binary file signatures
_BINARY_SIGNATURES = ['\x89PNG', '\xff\xd8\xff', 'GIF8', '%PDF']

# Non-printable character threshold (10% of sampled content)
_NON_PRINTABLE_THRESHOLD = 0.1
_SAMPLE_SIZE = 1000


def sanitize_text_content(content: str) -> str:
    """
    Sanitize and validate text content for storage.

    Strips null bytes, detects binary content, and returns clean text.
    Raises HTTPException(400) if the content appears to be binary data.
    """
    # Strip null bytes that break PostgreSQL UTF-8
    sanitized = content.replace('\x00', '')

    # Detect binary file signatures at start of content
    if any(sanitized.startswith(sig) for sig in _BINARY_SIGNATURES):
        raise HTTPException(
            status_code=400,
            detail="Binary file content detected. Please upload a text file or paste text content."
        )

    # Check for high ratio of non-printable characters
    sample = sanitized[:_SAMPLE_SIZE]
    if sample:
        non_printable = sum(1 for c in sample if ord(c) < 32 and c not in '\n\r\t')
        if non_printable / len(sample) > _NON_PRINTABLE_THRESHOLD:
            raise HTTPException(
                status_code=400,
                detail="Content appears to be binary data, not text. Please upload a valid text transcript."
            )

    return sanitized
