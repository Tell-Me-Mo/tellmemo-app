"""
Risk and Task Analyzer Service - AI-driven extraction and update of project risks and tasks.
"""

import json
from typing import Dict, Any, Optional, List
from datetime import datetime
from services.llm.multi_llm_client import get_multi_llm_client
from services.prompts.risks_tasks_prompts_complete import get_deduplication_prompt
from config import get_settings
from utils.logger import get_logger

logger = get_logger(__name__)


class RisksTasksAnalyzer:
    """Service for AI-powered risks and tasks extraction from content."""

    def __init__(self, deduplication_confidence_threshold: float = 0.7):
        """Initialize the service."""
        settings = get_settings()
        # Use multi-provider client's configured model (PRIMARY_LLM_MODEL)
        self.llm_model = None

        # Configuration
        self.min_content_length = 300  # Lower threshold for risks/tasks
        self.min_confidence_threshold = 0.5  # Accept more tentative risks

        # Confidence threshold for deduplication decisions
        # Items marked as duplicates with confidence below this threshold will be kept
        self.deduplication_confidence_threshold = deduplication_confidence_threshold

        # Use centralized LLM client
        self.llm_client = get_multi_llm_client(settings)

        if not self.llm_client.is_available():
            logger.warning("Risks/Tasks Analyzer: LLM client not available")

    async def deduplicate_extracted_items(
        self,
        extracted_risks: List[Dict[str, Any]],
        extracted_blockers: List[Dict[str, Any]],
        extracted_tasks: List[Dict[str, Any]],
        extracted_lessons: List[Dict[str, Any]],
        existing_risks: List[Dict[str, Any]],
        existing_blockers: List[Dict[str, Any]],
        existing_tasks: List[Dict[str, Any]],
        existing_lessons: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Use AI to intelligently deduplicate extracted items against existing project items.
        This is used when items are already extracted from meeting summary.

        Args:
            extracted_risks: Risks extracted from meeting summary
            extracted_blockers: Blockers extracted from meeting summary
            extracted_tasks: Tasks extracted from meeting summary
            extracted_lessons: Lessons extracted from meeting summary
            existing_risks: Current project risks from database
            existing_blockers: Current project blockers from database
            existing_tasks: Current project tasks from database
            existing_lessons: Current project lessons from database

        Returns:
            Dict with deduplicated risks, blockers, tasks, and lessons
        """
        try:
            # If no extracted items, return empty
            if not extracted_risks and not extracted_blockers and not extracted_tasks and not extracted_lessons:
                logger.info("[DEDUP] No extracted items to deduplicate")
                return {"risks": [], "blockers": [], "tasks": [], "lessons_learned": []}

            # LOG: Input summary
            logger.info(f"[DEDUP] Starting deduplication:")
            logger.info(f"[DEDUP]   Extracted: {len(extracted_risks)} risks, {len(extracted_blockers)} blockers, {len(extracted_tasks)} tasks, {len(extracted_lessons)} lessons")
            logger.info(f"[DEDUP]   Existing: {len(existing_risks)} risks, {len(existing_blockers)} blockers, {len(existing_tasks)} tasks, {len(existing_lessons)} lessons")

            # Format existing items for Claude
            existing_risks_text = ""
            if existing_risks:
                existing_risks_text = "Current Project Risks (check for duplicates):\n"
                for risk in existing_risks[:15]:
                    existing_risks_text += f"- {risk.get('title', risk.get('description', ''))}: {risk.get('status', 'unknown')}\n"
                    if risk.get('description'):
                        existing_risks_text += f"  Description: {risk.get('description')[:100]}...\n"

            existing_blockers_text = ""
            if existing_blockers:
                existing_blockers_text = "Current Project Blockers (check for duplicates):\n"
                for blocker in existing_blockers[:15]:
                    existing_blockers_text += f"- {blocker.get('title', blocker.get('description', ''))}: {blocker.get('status', 'unknown')}\n"
                    if blocker.get('description'):
                        existing_blockers_text += f"  Description: {blocker.get('description')[:100]}...\n"

            existing_tasks_text = ""
            if existing_tasks:
                existing_tasks_text = "Current Project Tasks (check for duplicates):\n"
                for task in existing_tasks[:15]:
                    existing_tasks_text += f"- {task.get('title', task.get('description', ''))}: {task.get('status', 'unknown')}\n"
                    if task.get('description'):
                        existing_tasks_text += f"  Description: {task.get('description')[:100]}...\n"

            existing_lessons_text = ""
            if existing_lessons:
                existing_lessons_text = "Current Project Lessons (check for duplicates):\n"
                for lesson in existing_lessons[:10]:
                    existing_lessons_text += f"- {lesson.get('title', lesson.get('description', ''))}: {lesson.get('lesson_type', 'unknown')}\n"
                    if lesson.get('description'):
                        existing_lessons_text += f"  Description: {lesson.get('description')[:100]}...\n"

            # Format extracted items for Claude
            extracted_risks_text = "Newly Extracted Risks to Check:\n"
            for i, risk in enumerate(extracted_risks):
                extracted_risks_text += f"{i+1}. {risk.get('title', risk.get('description', ''))}\n"
                if risk.get('description'):
                    extracted_risks_text += f"   Description: {risk.get('description')}\n"

            extracted_blockers_text = "Newly Extracted Blockers to Check:\n"
            for i, blocker in enumerate(extracted_blockers):
                extracted_blockers_text += f"{i+1}. {blocker.get('title', blocker.get('description', ''))}\n"
                if blocker.get('description'):
                    extracted_blockers_text += f"   Description: {blocker.get('description')}\n"

            extracted_tasks_text = "Newly Extracted Tasks to Check:\n"
            for i, task in enumerate(extracted_tasks):
                task_title = task.get('title', task.get('description', ''))
                extracted_tasks_text += f"{i+1}. {task_title}\n"
                if task.get('description'):
                    extracted_tasks_text += f"   Description: {task.get('description')}\n"
                # Log tasks for debugging
                if 'cleanspeak' in task_title.lower():
                    logger.info(f"[DEDUP_DEBUG] Found CleanSpeak task: {task_title}")

            extracted_lessons_text = "Newly Extracted Lessons to Check:\n"
            for i, lesson in enumerate(extracted_lessons):
                extracted_lessons_text += f"{i+1}. {lesson.get('title', lesson.get('description', ''))}\n"
                if lesson.get('description'):
                    extracted_lessons_text += f"   Description: {lesson.get('description')}\n"

            prompt = get_deduplication_prompt(
                existing_risks_text=existing_risks_text,
                existing_blockers_text=existing_blockers_text,
                existing_tasks_text=existing_tasks_text,
                existing_lessons_text=existing_lessons_text,
                extracted_risks_text=extracted_risks_text,
                extracted_blockers_text=extracted_blockers_text,
                extracted_tasks_text=extracted_tasks_text,
                extracted_lessons_text=extracted_lessons_text
            )

            # Call Claude for intelligent deduplication
            response = await self.llm_client.create_message(
                prompt=prompt,
                model=self.llm_model,
                max_tokens=1000,
                temperature=0.2,
                system="You are a JSON API that ONLY returns valid JSON responses. Never ask questions or engage in conversation."
            )

            response_text = response.content[0].text
            logger.debug(f"[DEDUP] Claude deduplication response: {response_text[:500]}...")

            # Parse response
            import json
            if "{" in response_text and "}" in response_text:
                json_start = response_text.index("{")
                json_end = response_text.rindex("}") + 1
                json_str = response_text[json_start:json_end]
                result = json.loads(json_str)

                # Apply confidence threshold filtering
                unique_risk_nums, risk_confidence_overrides = self._apply_confidence_threshold(
                    result.get("duplicate_analysis", {}).get("risks", []),
                    result.get("unique_risk_numbers", [])
                )
                unique_blocker_nums, blocker_confidence_overrides = self._apply_confidence_threshold(
                    result.get("duplicate_analysis", {}).get("blockers", []),
                    result.get("unique_blocker_numbers", [])
                )
                unique_task_nums, task_confidence_overrides = self._apply_confidence_threshold(
                    result.get("duplicate_analysis", {}).get("tasks", []),
                    result.get("unique_task_numbers", [])
                )
                unique_lesson_nums, lesson_confidence_overrides = self._apply_confidence_threshold(
                    result.get("duplicate_analysis", {}).get("lessons", []),
                    result.get("unique_lesson_numbers", [])
                )

                unique_risks = [risk for i, risk in enumerate(extracted_risks, 1) if i in unique_risk_nums]
                unique_blockers = [blocker for i, blocker in enumerate(extracted_blockers, 1) if i in unique_blocker_nums]
                unique_tasks = [task for i, task in enumerate(extracted_tasks, 1) if i in unique_task_nums]
                unique_lessons = [lesson for i, lesson in enumerate(extracted_lessons, 1) if i in unique_lesson_nums]

                # Log confidence threshold overrides
                total_overrides = len(risk_confidence_overrides) + len(blocker_confidence_overrides) + len(task_confidence_overrides) + len(lesson_confidence_overrides)
                if total_overrides > 0:
                    logger.info(f"[DEDUP] Confidence threshold override: kept {total_overrides} items marked as duplicates with low confidence")
                    for override in (risk_confidence_overrides + blocker_confidence_overrides + task_confidence_overrides + lesson_confidence_overrides):
                        logger.debug(f"[DEDUP]   Override #{override['item_number']}: confidence={override['confidence']:.2f}, reason={override['reason']}")

                # LOG: Deduplication results
                logger.info(f"[DEDUP] Deduplication complete:")
                logger.info(f"[DEDUP]   Risks: {len(unique_risks)}/{len(extracted_risks)} unique ({len(extracted_risks) - len(unique_risks)} filtered)")
                logger.info(f"[DEDUP]   Blockers: {len(unique_blockers)}/{len(extracted_blockers)} unique ({len(extracted_blockers) - len(unique_blockers)} filtered)")
                logger.info(f"[DEDUP]   Tasks: {len(unique_tasks)}/{len(extracted_tasks)} unique ({len(extracted_tasks) - len(unique_tasks)} filtered)")
                logger.info(f"[DEDUP]   Lessons: {len(unique_lessons)}/{len(extracted_lessons)} unique ({len(extracted_lessons) - len(unique_lessons)} filtered)")

                # LOG: Filtered items details
                filtered_risk_nums = [i for i in range(1, len(extracted_risks) + 1) if i not in unique_risk_nums]
                filtered_blocker_nums = [i for i in range(1, len(extracted_blockers) + 1) if i not in unique_blocker_nums]
                filtered_task_nums = [i for i in range(1, len(extracted_tasks) + 1) if i not in unique_task_nums]
                filtered_lesson_nums = [i for i in range(1, len(extracted_lessons) + 1) if i not in unique_lesson_nums]

                if filtered_risk_nums:
                    logger.info(f"[DEDUP] Filtered risk numbers: {filtered_risk_nums}")
                    for num in filtered_risk_nums[:3]:  # Log first 3
                        if num <= len(extracted_risks):
                            logger.debug(f"[DEDUP]   Filtered risk #{num}: {extracted_risks[num-1].get('title', 'N/A')}")
                if filtered_blocker_nums:
                    logger.info(f"[DEDUP] Filtered blocker numbers: {filtered_blocker_nums}")
                    for num in filtered_blocker_nums[:3]:
                        if num <= len(extracted_blockers):
                            logger.debug(f"[DEDUP]   Filtered blocker #{num}: {extracted_blockers[num-1].get('title', 'N/A')}")
                if filtered_task_nums:
                    logger.info(f"[DEDUP] Filtered task numbers: {filtered_task_nums}")
                    for num in filtered_task_nums[:3]:
                        if num <= len(extracted_tasks):
                            logger.debug(f"[DEDUP]   Filtered task #{num}: {extracted_tasks[num-1].get('title', 'N/A')}")
                if filtered_lesson_nums:
                    logger.info(f"[DEDUP] Filtered lesson numbers: {filtered_lesson_nums}")
                    for num in filtered_lesson_nums[:3]:
                        if num <= len(extracted_lessons):
                            logger.debug(f"[DEDUP]   Filtered lesson #{num}: {extracted_lessons[num-1].get('title', 'N/A')}")

                return {
                    "risks": unique_risks,
                    "blockers": unique_blockers,
                    "tasks": unique_tasks,
                    "lessons_learned": unique_lessons,
                    "status_updates": result.get("status_updates", [])
                }
            else:
                raise ValueError("Failed to parse deduplication response")

        except Exception as e:
            logger.error(f"AI deduplication failed, falling back to all items as unique: {e}")
            # On error, return all items as unique to avoid data loss
            return {
                "risks": extracted_risks,
                "blockers": extracted_blockers,
                "tasks": extracted_tasks,
                "lessons_learned": extracted_lessons
            }

    def _apply_confidence_threshold(
        self,
        duplicate_analysis: List[Dict[str, Any]],
        original_unique_numbers: List[int]
    ) -> tuple[List[int], List[Dict[str, Any]]]:
        """
        Apply confidence threshold to duplicate decisions.
        If an item is marked as duplicate but with low confidence, keep it as unique.

        Args:
            duplicate_analysis: List of duplicate analysis results from Claude
            original_unique_numbers: Original list of unique item numbers from Claude

        Returns:
            Tuple of (updated_unique_numbers, confidence_overrides)
        """
        updated_unique_numbers = original_unique_numbers.copy()
        confidence_overrides = []

        for analysis in duplicate_analysis:
            item_number = analysis.get("extracted_number")
            is_duplicate = analysis.get("is_duplicate", False)
            confidence = analysis.get("confidence", 1.0)
            reason = analysis.get("reason", "")
            similar_to = analysis.get("similar_to", "")

            # If Claude marked as duplicate but confidence is below threshold, override and keep it
            if is_duplicate and confidence < self.deduplication_confidence_threshold:
                if item_number not in updated_unique_numbers:
                    updated_unique_numbers.append(item_number)
                    confidence_overrides.append({
                        "item_number": item_number,
                        "original_decision": "duplicate",
                        "override_decision": "unique",
                        "confidence": confidence,
                        "threshold": self.deduplication_confidence_threshold,
                        "reason": reason,
                        "similar_to": similar_to
                    })
                    logger.info(
                        f"Confidence override: keeping item {item_number} as unique "
                        f"(confidence {confidence} < threshold {self.deduplication_confidence_threshold})"
                    )

        # Sort the numbers for consistency
        updated_unique_numbers.sort()

        return updated_unique_numbers, confidence_overrides