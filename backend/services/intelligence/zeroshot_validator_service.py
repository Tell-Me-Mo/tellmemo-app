"""Zero-Shot Classification Service for Question/Action Validation.

Uses ModernBERT-base-zeroshot-v2.0 to classify questions and actions as meaningful or not.
Initialized at app startup, blocks if model fails to load.
"""

import asyncio
from typing import Optional, Dict, Any, List, Tuple
from pathlib import Path
import os
import ssl

# CRITICAL: Apply SSL bypass BEFORE importing transformers
os.environ['PYTHONHTTPSVERIFY'] = '0'
os.environ['CURL_CA_BUNDLE'] = ''
os.environ['REQUESTS_CA_BUNDLE'] = ''
ssl._create_default_https_context = ssl._create_unverified_context

# Monkey-patch requests for HuggingFace Hub downloads
try:
    import requests
    from requests.adapters import HTTPAdapter
    import urllib3

    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    class NoSSLAdapter(HTTPAdapter):
        def init_poolmanager(self, *args, **kwargs):
            kwargs['ssl_context'] = ssl._create_unverified_context()
            return super().init_poolmanager(*args, **kwargs)

    _original_session_init = requests.Session.__init__

    def patched_session_init(self, *args, **kwargs):
        _original_session_init(self, *args, **kwargs)
        adapter = NoSSLAdapter()
        self.mount('https://', adapter)
        self.mount('http://', adapter)
        self.verify = False

    requests.Session.__init__ = patched_session_init
except ImportError:
    pass

from transformers import pipeline
import torch

from config import get_settings
from utils.logger import get_logger

settings = get_settings()
logger = get_logger(__name__)


class ZeroShotValidatorService:
    """
    Service for validating questions and actions using zero-shot classification.

    Uses ModernBERT-base-zeroshot-v2.0 for fast, accurate classification without training data.
    Follows singleton pattern similar to EmbeddingService.
    """

    _instance: Optional['ZeroShotValidatorService'] = None
    _pipeline: Optional[Any] = None
    _model_lock = asyncio.Lock()

    # Classification categories (no hardcoded patterns needed!)
    QUESTION_CATEGORIES = {
        "meaningful_question": (
            "This is a genuine question seeking factual information, clarification, "
            "or project-related answers that should be tracked and answered"
        ),
        "non_meaningful_question": (
            "This is a greeting, technical check, rhetorical question, acknowledgment, "
            "or social pleasantry that doesn't need tracking or answering"
        )
    }

    ACTION_CATEGORIES = {
        "action_item": (
            "a task, assignment, or work item that someone needs to do"
        ),
        "not_an_action": (
            "a comment, opinion, or statement that is not a task"
        )
    }

    def __new__(cls):
        """Singleton pattern to ensure single model instance."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        """Initialize zero-shot validator service."""
        if not hasattr(self, '_initialized'):
            self._initialized = True
            self.model_name = settings.zeroshot_model
            self.question_threshold = settings.zeroshot_question_threshold
            self.action_threshold = settings.zeroshot_action_threshold
            self.cache_dir = Path.home() / ".cache" / "huggingface" / "transformers"

            logger.info(f"Zero-shot validator initialized with model: {self.model_name}")
            logger.info(f"Question threshold: {self.question_threshold}, Action threshold: {self.action_threshold}")

    async def get_pipeline(self) -> Any:
        """
        Get or download the zero-shot classification pipeline.
        Uses async lock to prevent multiple downloads.

        Returns:
            Transformers pipeline for zero-shot classification
        """
        async with self._model_lock:
            if self._pipeline is None:
                logger.info(f"Loading zero-shot model: {self.model_name}")

                # Run pipeline loading in executor to avoid blocking
                loop = asyncio.get_event_loop()
                self._pipeline = await loop.run_in_executor(
                    None,
                    self._load_pipeline
                )

                # Verify pipeline with test classification
                test_result = await loop.run_in_executor(
                    None,
                    lambda: self._pipeline(
                        "What is the budget for Q4?",
                        candidate_labels=["meaningful", "not meaningful"],
                        multi_label=False
                    )
                )

                logger.info(
                    f"Pipeline loaded successfully. Test classification: "
                    f"{test_result['labels'][0]} ({test_result['scores'][0]:.3f})"
                )

            return self._pipeline

    def _load_pipeline(self) -> Any:
        """
        Load the zero-shot classification pipeline synchronously.

        Returns:
            Loaded transformers pipeline
        """
        # Determine device
        device = 0 if torch.cuda.is_available() else -1  # 0 = GPU, -1 = CPU
        device_name = "cuda" if device == 0 else "cpu"

        logger.info(f"Loading ModernBERT on device: {device_name}")

        # Create cache directory if it doesn't exist
        self.cache_dir.mkdir(parents=True, exist_ok=True)

        # Get HF token from settings
        hf_token = settings.hf_token if hasattr(settings, 'hf_token') and settings.hf_token else None

        try:
            # Load pipeline with optimal settings
            # Note: Pass token and trust_remote_code at pipeline level to avoid conflicts
            classifier = pipeline(
                "zero-shot-classification",
                model=self.model_name,
                device=device,
                token=hf_token,
                trust_remote_code=True,  # Pass at pipeline level
                torch_dtype=torch.bfloat16 if torch.cuda.is_available() else torch.float32,  # bf16 for 2x speed on GPU
                model_kwargs={
                    "cache_dir": str(self.cache_dir)
                }
            )

            logger.info(f"✅ Successfully loaded {self.model_name}")
            logger.info(f"   Device: {device_name}")
            logger.info(f"   Dtype: {'bfloat16' if torch.cuda.is_available() else 'float32'}")

            return classifier

        except Exception as e:
            error_msg = str(e).lower()

            if "403" in error_msg or "access" in error_msg or "gated" in error_msg:
                logger.error("❌ ACCESS DENIED: You don't have access to the model")
                logger.error(f"   Solution: Request access at https://huggingface.co/{self.model_name}")
            elif "401" in error_msg or "token" in error_msg:
                logger.error("❌ AUTHENTICATION FAILED: Invalid or missing HF_TOKEN")
                logger.error("   Solution: Check HF_TOKEN in .env file")
            elif "ssl" in error_msg or "certificate" in error_msg:
                logger.error("❌ SSL/NETWORK ERROR: Cannot connect to Hugging Face")
                logger.error("   Solution: Check network connectivity")
            else:
                logger.error(f"❌ DOWNLOAD FAILED: {e}")

            raise RuntimeError(f"Failed to load zero-shot model: {e}")

    async def validate_question(
        self,
        question_text: str,
        return_details: bool = False
    ) -> Tuple[bool, float]:
        """
        Validate if a question is meaningful and should be tracked.

        Args:
            question_text: The question text to validate
            return_details: If True, return classification details

        Returns:
            Tuple of (is_meaningful, confidence_score)
        """
        try:
            if not question_text or not question_text.strip():
                return False, 0.0

            pipeline = await self.get_pipeline()

            # Run classification in executor
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None,
                lambda: pipeline(
                    question_text,
                    candidate_labels=list(self.QUESTION_CATEGORIES.keys()),
                    hypothesis_template="{}",  # Use simple template for better accuracy
                    multi_label=False
                )
            )

            # Extract results
            top_label = result['labels'][0]
            top_score = result['scores'][0]

            is_meaningful = (
                top_label == "meaningful_question" and
                top_score >= self.question_threshold
            )

            logger.debug(
                f"Question validation: '{question_text[:50]}...' -> "
                f"{top_label} ({top_score:.3f}) - {'KEEP' if is_meaningful else 'FILTER'}"
            )

            if return_details:
                return is_meaningful, top_score, result

            return is_meaningful, top_score

        except Exception as e:
            logger.error(f"Failed to validate question: {e}")
            # On error, default to accepting the question (fail-open)
            return True, 0.5

    async def validate_action(
        self,
        action_text: str,
        return_details: bool = False
    ) -> Tuple[bool, float]:
        """
        Validate if an action is meaningful and should be tracked.

        Args:
            action_text: The action description to validate
            return_details: If True, return classification details

        Returns:
            Tuple of (is_meaningful, confidence_score)
        """
        try:
            if not action_text or not action_text.strip():
                return False, 0.0

            pipeline = await self.get_pipeline()

            # Run classification in executor
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None,
                lambda: pipeline(
                    action_text,
                    candidate_labels=list(self.ACTION_CATEGORIES.keys()),
                    hypothesis_template="{}",
                    multi_label=False
                )
            )

            # Extract results
            top_label = result['labels'][0]
            top_score = result['scores'][0]

            is_meaningful = (
                top_label == "action_item" and
                top_score >= self.action_threshold
            )

            logger.debug(
                f"Action validation: '{action_text[:50]}...' -> "
                f"{top_label} ({top_score:.3f}) - {'KEEP' if is_meaningful else 'FILTER'}"
            )

            if return_details:
                return is_meaningful, top_score, result

            return is_meaningful, top_score

        except Exception as e:
            logger.error(f"Failed to validate action: {e}")
            # On error, default to accepting the action (fail-open)
            return True, 0.5

    async def validate_batch(
        self,
        texts: List[str],
        validation_type: str = "question"
    ) -> List[Tuple[bool, float]]:
        """
        Validate multiple questions or actions in batch for efficiency.

        Args:
            texts: List of texts to validate
            validation_type: "question" or "action"

        Returns:
            List of (is_meaningful, confidence) tuples
        """
        try:
            if not texts:
                return []

            pipeline = await self.get_pipeline()

            # Select appropriate categories and threshold
            categories = (
                self.QUESTION_CATEGORIES if validation_type == "question"
                else self.ACTION_CATEGORIES
            )
            threshold = (
                self.question_threshold if validation_type == "question"
                else self.action_threshold
            )

            # Run batch classification in executor
            loop = asyncio.get_event_loop()
            results = await loop.run_in_executor(
                None,
                lambda: [
                    pipeline(
                        text,
                        candidate_labels=list(categories.keys()),
                        hypothesis_template="{}",
                        multi_label=False
                    )
                    for text in texts
                ]
            )

            # Process results
            validations = []
            for result in results:
                top_label = result['labels'][0]
                top_score = result['scores'][0]

                # Check if action_item (for actions) or meaningful_question (for questions)
                is_meaningful = (
                    (top_label == "action_item" or top_label == "meaningful_question") and
                    top_score >= threshold
                )

                validations.append((is_meaningful, top_score))

            logger.info(
                f"Batch validation complete: {len(texts)} {validation_type}s, "
                f"{sum(1 for v, _ in validations if v)} passed"
            )

            return validations

        except Exception as e:
            logger.error(f"Failed batch validation: {e}")
            # On error, default to accepting all (fail-open)
            return [(True, 0.5) for _ in texts]

    def get_model_info(self) -> Dict[str, Any]:
        """
        Get information about the zero-shot classifier.

        Returns:
            Dictionary with model information
        """
        return {
            'model_name': self.model_name,
            'question_threshold': self.question_threshold,
            'action_threshold': self.action_threshold,
            'pipeline_loaded': self._pipeline is not None,
            'cache_directory': str(self.cache_dir),
            'device': 'cuda' if torch.cuda.is_available() else 'cpu',
            'question_categories': list(self.QUESTION_CATEGORIES.keys()),
            'action_categories': list(self.ACTION_CATEGORIES.keys())
        }

    async def warm_up(self) -> None:
        """
        Warm up the model by loading it and running test classifications.
        Reduces latency on first real request.
        """
        try:
            logger.info("Warming up zero-shot classifier...")

            # Load pipeline
            await self.get_pipeline()

            # Test question validation
            test_question = "What is the budget for Q4?"
            is_valid, confidence = await self.validate_question(test_question)
            logger.info(
                f"Test question validation: '{test_question}' -> "
                f"{'valid' if is_valid else 'invalid'} ({confidence:.3f})"
            )

            # Test action validation
            test_action = "Update the spreadsheet with Q4 numbers"
            is_valid, confidence = await self.validate_action(test_action)
            logger.info(
                f"Test action validation: '{test_action}' -> "
                f"{'valid' if is_valid else 'invalid'} ({confidence:.3f})"
            )

            logger.info("Zero-shot classifier warmed up successfully")

        except Exception as e:
            logger.error(f"❌ Failed to warm up zero-shot classifier: {e}")
            logger.error("This is a CRITICAL error - question/action filtering will not work")
            raise


# Global zero-shot validator service instance
zeroshot_validator_service = ZeroShotValidatorService()


async def init_zeroshot_validator():
    """Initialize and warm up the zero-shot validator service (MANDATORY)."""
    try:
        logger.info("🚀 Initializing ModernBERT zero-shot classifier...")
        await zeroshot_validator_service.warm_up()
        info = zeroshot_validator_service.get_model_info()
        logger.info(f"✅ Zero-shot validator ready: {info}")

        # Verify the model is actually ModernBERT
        if 'modernbert' not in info['model_name'].lower():
            raise RuntimeError(f"Expected ModernBERT model, got: {info['model_name']}")

        logger.info("🎉 ModernBERT zero-shot classifier validation successful")

    except Exception as e:
        logger.error(f"❌ CRITICAL: Failed to initialize zero-shot validator: {e}")
        logger.error("ModernBERT classifier is REQUIRED for question/action filtering")
        logger.error("Possible solutions:")
        logger.error("  1. Check HF_TOKEN in .env file")
        logger.error("  2. Ensure network connectivity to huggingface.co")
        logger.error(f"  3. Verify access to {settings.zeroshot_model}")
        logger.error("  4. Check available disk space (~500MB needed)")
        raise
