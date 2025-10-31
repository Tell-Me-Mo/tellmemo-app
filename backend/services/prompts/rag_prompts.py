"""
Prompts for RAG (Retrieval-Augmented Generation) operations.
"""


def get_basic_rag_prompt(question: str, context: str, strategy: str = "basic") -> str:
    """
    Generate prompt for basic RAG response.

    Args:
        question: The user's question
        context: Retrieved context from vector store
        strategy: The retrieval strategy used

    Returns:
        Formatted prompt string for RAG response
    """
    strategy_instructions = {
        'basic': "Analyze the provided context carefully and answer based on the available information.",
        'multi_query': "Multiple query perspectives were used to gather comprehensive context. Synthesize insights across different aspects.",
        'hybrid_search': "Context was gathered using both semantic and keyword matching. Consider both explicit mentions and semantic relationships.",
        'intelligent': "Advanced retrieval with meeting intelligence was applied. Consider decisions, actions, and project dynamics."
    }

    return f"""You are an AI assistant specialized in analyzing meeting content using {strategy} retrieval strategy.

{strategy_instructions.get(strategy, strategy_instructions['basic'])}

Available Context:
{'='*50}
{context}
{'='*50}

User Question: {question}

Instructions:
1. Provide a comprehensive answer based on the context
2. Be specific and cite sources
3. Acknowledge gaps if information is incomplete
4. Use markdown formatting for readability

Please provide your answer:"""


def get_intelligent_rag_prompt(
    question: str,
    context: str,
    intelligence_summary: str
) -> str:
    """
    Generate prompt for intelligent RAG with meeting intelligence.

    Args:
        question: The user's question
        context: Retrieved context from vector store
        intelligence_summary: Summary of meeting intelligence insights

    Returns:
        Formatted prompt string for intelligent RAG response
    """
    return f"""You are an advanced AI assistant specialized in meeting intelligence and project analysis.

Meeting Intelligence Summary:
{intelligence_summary}

Enhanced Context:
{'='*60}
{context}
{'='*60}

User Question: {question}

Instructions for Intelligent Response:
1. Leverage both content and meeting intelligence insights
2. Provide specific, actionable answers with citations
3. Include context about decisions and consensus
4. Note assignments and timelines for actions
5. Identify gaps needing follow-up
6. Use markdown formatting

Please provide your comprehensive answer:"""


def get_live_insights_rag_prompt(question: str, context: str) -> str:
    """
    Generate prompt for live meeting insights RAG response.

    Optimized for real-time answers during meetings:
    - Concise and direct (no fluff)
    - Fast to generate (minimal token usage)
    - Focused on factual answers only

    Args:
        question: The question asked during the meeting
        context: Retrieved document context

    Returns:
        Formatted prompt string for live insights RAG response
    """
    return f"""Answer this meeting question using the provided documents. Be direct and concise.

Context from documents:
{context}

Question: {question}

Instructions:
- Answer in 1-2 sentences maximum
- State only facts from the documents
- If the answer isn't in the documents, say "Not found in documents"
- No introductions, explanations, or markdown formatting

Answer:"""


def get_rag_system_prompt() -> str:
    """
    Get the system prompt for RAG operations.

    Returns:
        System prompt string
    """
    return """You are a helpful AI assistant specialized in analyzing project and meeting content.
You provide accurate, well-structured responses based on retrieved context.
You acknowledge when information is incomplete or uncertain."""