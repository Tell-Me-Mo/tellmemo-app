#!/usr/bin/env python3
"""Test script for enhanced summary generation with new action items and decisions format."""

import asyncio
import json
from datetime import datetime
from services.summaries.summary_service_refactored import SummaryService

async def test_enhanced_parsing():
    """Test the enhanced parsing of action items and decisions."""
    
    service = SummaryService()
    
    # Test response text that mimics Claude's response with enhanced format
    test_response = json.dumps({
        "summary_text": "This was a productive meeting discussing project roadmap and technical decisions.",
        "key_points": [
            "Discussed Q1 roadmap priorities",
            "Reviewed technical architecture",
            "Aligned on team responsibilities"
        ],
        "decisions": [
            {
                "description": "Adopt microservices architecture for the new platform",
                "importance_score": "critical",
                "decision_type": "technical",
                "stakeholders_affected": ["Engineering", "DevOps", "Product"],
                "rationale": "Better scalability and team independence"
            },
            {
                "description": "Delay feature X to Q2 to focus on infrastructure",
                "importance_score": "7",
                "decision_type": "strategic",
                "stakeholders_affected": ["Product", "Sales"],
                "rationale": "Infrastructure stability is critical for growth"
            }
        ],
        "action_items": [
            {
                "description": "Create detailed microservices migration plan",
                "urgency": "high",
                "due_date": "2025-01-15",
                "assignee": "John Smith",
                "dependencies": ["Architecture review completion"],
                "status": "not_started",
                "follow_up_required": True
            },
            {
                "description": "Set up monitoring dashboards for new services",
                "urgency": "medium",
                "due_date": "next week",
                "assignee": "DevOps Team",
                "dependencies": [],
                "status": "not_started",
                "follow_up_required": False
            },
            {
                "description": "Communicate timeline changes to stakeholders",
                "urgency": "critical",
                "due_date": None,
                "assignee": "Product Manager",
                "dependencies": [],
                "status": "in_progress",
                "follow_up_required": True
            }
        ],
        "participants": ["John Smith", "Jane Doe", "Bob Johnson"],
        "risks": [
            {
                "description": "Migration complexity might delay timeline",
                "severity": "high",
                "mitigation": "Hire additional contractors for migration"
            }
        ],
        "blockers": [
            {
                "description": "Lack of monitoring infrastructure",
                "impact": "high",
                "resolution": "Fast-track monitoring setup"
            }
        ],
        "sentiment": {
            "overall": "positive",
            "trajectory": ["neutral", "positive", "positive"],
            "topics": {"architecture": "positive", "timeline": "mixed"},
            "engagement": {"John Smith": "high", "Jane Doe": "medium"},
            "dynamics": {
                "collaboration_score": 0.8,
                "consensus_level": 0.7,
                "conflict_indicators": 0.1
            }
        }
    })
    
    # Parse the response
    parsed_data = service._parse_claude_response(
        response_text=test_response,
        content_type="meeting",
        content_title="Test Meeting"
    )
    
    print("=" * 60)
    print("ENHANCED SUMMARY PARSING TEST RESULTS")
    print("=" * 60)
    
    # Validate action items
    print("\n✅ ACTION ITEMS VALIDATION:")
    print("-" * 40)
    for i, item in enumerate(parsed_data.get("action_items", []), 1):
        print(f"\nAction Item {i}:")
        print(f"  Description: {item.get('description')}")
        print(f"  Urgency: {item.get('urgency')}")
        print(f"  Due Date: {item.get('due_date', 'Not set')}")
        print(f"  Assignee: {item.get('assignee', 'Unassigned')}")
        print(f"  Dependencies: {item.get('dependencies', [])}")
        print(f"  Status: {item.get('status')}")
        print(f"  Follow-up Required: {item.get('follow_up_required')}")
        
        # Validate structure
        assert "description" in item, f"Action item {i} missing description"
        assert "urgency" in item, f"Action item {i} missing urgency"
        assert "status" in item, f"Action item {i} missing status"
        assert isinstance(item.get("follow_up_required"), bool), f"Action item {i} follow_up_required should be boolean"
    
    # Validate decisions
    print("\n✅ DECISIONS VALIDATION:")
    print("-" * 40)
    for i, decision in enumerate(parsed_data.get("decisions", []), 1):
        print(f"\nDecision {i}:")
        print(f"  Description: {decision.get('description')}")
        print(f"  Importance: {decision.get('importance_score')}")
        print(f"  Type: {decision.get('decision_type')}")
        print(f"  Stakeholders: {decision.get('stakeholders_affected', [])}")
        print(f"  Rationale: {decision.get('rationale', 'Not provided')}")
        
        # Validate structure
        assert "description" in decision, f"Decision {i} missing description"
        assert "importance_score" in decision, f"Decision {i} missing importance_score"
        assert "decision_type" in decision, f"Decision {i} missing decision_type"
        assert isinstance(decision.get("stakeholders_affected"), list), f"Decision {i} stakeholders_affected should be a list"
    
    # Test backward compatibility with string format
    print("\n✅ BACKWARD COMPATIBILITY TEST:")
    print("-" * 40)
    
    old_format_response = json.dumps({
        "summary_text": "Test summary",
        "key_points": ["Point 1"],
        "decisions": ["Simple decision string"],
        "action_items": ["Simple action item string"],
        "participants": []
    })
    
    parsed_old = service._parse_claude_response(
        response_text=old_format_response,
        content_type="meeting",
        content_title="Test"
    )
    
    # Check that old string format is converted to new format
    old_action = parsed_old["action_items"][0]
    print(f"\nOld format action item converted:")
    print(f"  Original: 'Simple action item string'")
    print(f"  Converted description: {old_action.get('description')}")
    print(f"  Default urgency: {old_action.get('urgency')}")
    print(f"  Default status: {old_action.get('status')}")
    
    old_decision = parsed_old["decisions"][0]
    print(f"\nOld format decision converted:")
    print(f"  Original: 'Simple decision string'")
    print(f"  Converted description: {old_decision.get('description')}")
    print(f"  Default importance: {old_decision.get('importance_score')}")
    print(f"  Default type: {old_decision.get('decision_type')}")
    
    assert old_action["description"] == "Simple action item string"
    assert old_action["urgency"] == "medium"
    assert old_action["status"] == "not_started"
    
    assert old_decision["description"] == "Simple decision string"
    assert old_decision["importance_score"] == "medium"
    assert old_decision["decision_type"] == "operational"
    
    print("\n" + "=" * 60)
    print("✅ ALL TESTS PASSED SUCCESSFULLY!")
    print("=" * 60)
    print("\nThe enhanced summary format is working correctly with:")
    print("  - Action items with urgency, deadlines, dependencies, and status")
    print("  - Decisions with importance scores, types, and stakeholders")
    print("  - Backward compatibility with old string format")
    print("  - Proper data structure validation")

if __name__ == "__main__":
    asyncio.run(test_enhanced_parsing())