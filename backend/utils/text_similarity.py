"""
Text similarity utilities for deduplication and matching.
"""
import re
from difflib import SequenceMatcher


def normalize_text(text: str) -> str:
    """
    Normalize text for comparison by removing special characters,
    converting to lowercase, and removing extra whitespace.

    Args:
        text: Text to normalize

    Returns:
        Normalized text
    """
    if not text:
        return ""

    # Convert to lowercase
    text = text.lower()

    # Remove special characters except spaces and alphanumeric
    text = re.sub(r'[^a-z0-9\s]', ' ', text)

    # Replace multiple spaces with single space
    text = re.sub(r'\s+', ' ', text)

    # Strip leading/trailing whitespace
    text = text.strip()

    return text


def are_tasks_similar(task1: str, task2: str, threshold: float = 0.75) -> bool:
    """
    Check if two task titles/descriptions are similar enough to be considered duplicates.

    Args:
        task1: First task title/description
        task2: Second task title/description
        threshold: Similarity threshold (0-1), default 0.75

    Returns:
        True if tasks are similar enough to be duplicates
    """
    if not task1 or not task2:
        return False

    # Normalize both texts
    norm1 = normalize_text(task1)
    norm2 = normalize_text(task2)

    # If normalized texts are identical, they're duplicates
    if norm1 == norm2:
        return True

    # FIRST: Check for patterns that indicate different items despite similar wording
    # This should come early to avoid false positives

    # Check for different quarters/numbers
    quarter_pattern = r'\b(q\d|quarter\s*\d|fy\d+|q1|q2|q3|q4)\b'
    quarters1 = set(re.findall(quarter_pattern, norm1))
    quarters2 = set(re.findall(quarter_pattern, norm2))
    if quarters1 and quarters2 and quarters1 != quarters2:
        return False  # Different quarters = different tasks

    # Check for opposite actions (login vs logout, enable vs disable, etc.)
    opposites = [
        ('login', 'logout'),
        ('enable', 'disable'),
        ('start', 'stop'),
        ('open', 'close'),
        ('add', 'remove'),
        ('create', 'delete'),
        ('upload', 'download'),
        ('increase', 'decrease'),
        ('show', 'hide'),
    ]

    for word1, word2 in opposites:
        if (word1 in norm1 and word2 in norm2) or (word2 in norm1 and word1 in norm2):
            return False  # Opposite actions = different tasks

    # Check for key technology/system mentions
    # Extract technology names (e.g., CleanSpeak, Fireflies, etc.)
    tech_pattern = r'\b(cleanspeak|fireflies|qdrant|supabase|claude|gpt|api|sdk|implementation|integration)\b'

    tech1 = set(re.findall(tech_pattern, norm1))
    tech2 = set(re.findall(tech_pattern, norm2))

    # Special handling for CleanSpeak and similar technology-specific tasks
    # If both mention the same specific technology (not generic terms), they're likely duplicates
    specific_tech = {'cleanspeak', 'fireflies', 'qdrant', 'supabase', 'claude', 'gpt'}
    specific_tech1 = tech1.intersection(specific_tech)
    specific_tech2 = tech2.intersection(specific_tech)

    # If they mention DIFFERENT specific technologies, they're NOT similar
    if specific_tech1 and specific_tech2 and specific_tech1 != specific_tech2:
        return False

    if specific_tech1 and specific_tech1 == specific_tech2:
        # If they both mention the same specific technology, consider them similar
        # This catches cases like "Investigate CleanSpeak" and "Resolve CleanSpeak"
        return True

    # Check for similar action words when there's overlap in content
    action_pattern = r'\b(investigate|resolve|implement|setup|configure|fix|check|verify|confirm|analyze|review|examine)\b'
    actions1 = set(re.findall(action_pattern, norm1))
    actions2 = set(re.findall(action_pattern, norm2))

    # If they share significant words and have action words, check more carefully
    words1 = set(norm1.split())
    words2 = set(norm2.split())
    common_words = words1.intersection(words2)

    # Calculate Jaccard similarity for word overlap
    if len(words1) > 0 and len(words2) > 0:
        jaccard_sim = len(common_words) / len(words1.union(words2))

        # If high word overlap and both have action words, likely similar
        if jaccard_sim >= 0.5 and (actions1 or actions2):
            return True


    # Use sequence matcher for fuzzy matching
    similarity = SequenceMatcher(None, norm1, norm2).ratio()

    # Check if one is a subset of another (for different length strings)
    if len(norm1) < len(norm2):
        if norm1 in norm2:
            return True
    elif len(norm2) < len(norm1):
        if norm2 in norm1:
            return True

    return similarity >= threshold


def find_similar_tasks(new_task: str, existing_tasks: list, threshold: float = 0.75) -> list:
    """
    Find all existing tasks that are similar to a new task.

    Args:
        new_task: New task title/description
        existing_tasks: List of existing task titles/descriptions
        threshold: Similarity threshold

    Returns:
        List of indices of similar existing tasks
    """
    similar_indices = []

    for i, existing in enumerate(existing_tasks):
        if are_tasks_similar(new_task, existing, threshold):
            similar_indices.append(i)

    return similar_indices