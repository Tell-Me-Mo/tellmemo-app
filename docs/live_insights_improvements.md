After analyzing the updated HLD (v4.1) with the new Adaptive Insight Processing, here are 30 key areas where the logic can be significantly improved:

🎯 CRITICAL ISSUES - Adaptive Processing Logic
1. DONE: Context Window Configuration Inconsistency
Problem: Multiple conflicting context requirements:

Configuration: context_window_size = 3
Logic: "HIGH priority → wait for 2+ chunks context"
Force trigger: "5-chunk limit"
Improvement:

# Make priority-to-context mapping explicit:
PRIORITY_CONTEXT_MAP = {
    ChunkPriority.IMMEDIATE: 0,  # Process instantly, no context needed
    ChunkPriority.HIGH: 2,       # Wait for 2 chunks of context
    ChunkPriority.MEDIUM: 3,     # Accumulate 3 chunks
    ChunkPriority.LOW: 4,        # Batch 4 chunks
}
MAX_BATCH_SIZE = 5  # Hard limit - force process regardless
2. DONE: Semantic Score Calculation Undefined
Problem: Document says "semantic score ≥ 0.3" but never explains how it's calculated.

Improvement:

def calculate_semantic_score(text: str, signals: SemanticSignals) -> float:
    """
    Semantic density score = weighted signal count / word count
    
    Weights:
    - Action + Time combo: 2.0 (highest urgency)
    - Decisions + Assignments: 1.5
    - Questions, Risks: 1.0
    - Single action/time: 0.5
    """
    words = len(text.split())
    if words < 5:
        return 0.0
    
    score = 0.0
    if signals.has_actions and signals.has_time_refs:
        score += 2.0  # Critical combo
    elif signals.has_decisions and signals.has_assignments:
        score += 1.5
    else:
        score += sum([
            1.0 if signals.has_questions else 0,
            1.0 if signals.has_risks else 0,
            0.5 if signals.has_actions else 0,
            0.5 if signals.has_time_refs else 0,
        ])
    
    return score / words  # Normalize by length
3. DONE: Gibberish Detection Too Simplistic
Problem: Only checks "uniqueness ratio < 50%". Misses common transcription errors.

Improvement:

def is_gibberish(text: str) -> bool:
    """Enhanced gibberish detection"""
    words = text.lower().split()
    
    # Check 1: Too short
    if len(words) < 3:
        return True
    
    # Check 2: Uniqueness ratio (existing)
    unique_ratio = len(set(words)) / len(words)
    if unique_ratio < 0.5:
        return True
    
    # Check 3: Filler word ratio
    FILLER_WORDS = {'um', 'uh', 'like', 'so', 'yeah', 'okay', 'well', 'you know'}
    filler_count = sum(1 for w in words if w in FILLER_WORDS)
    if filler_count / len(words) > 0.6:
        return True
    
    # Check 4: Consecutive repeated words
    for i in range(len(words) - 2):
        if words[i] == words[i+1] == words[i+2]:
            return True  # "the the the"
    
    # Check 5: No content words (all stopwords)
    content_words = [w for w in words if w not in FILLER_WORDS and len(w) > 2]
    if len(content_words) < 2:
        return True
    
    return False
4. DONE: Accumulated Context Quality Not Checked
Problem: Forces processing at 30+ words, even if most are gibberish.

Improvement:

def should_force_process(accumulated_chunks: List[str]) -> Tuple[bool, str]:
    """Smart force-process decision"""
    all_text = " ".join(accumulated_chunks)
    words = all_text.split()
    
    # Count meaningful words (exclude filler words)
    meaningful_words = [w for w in words if w.lower() not in FILLER_WORDS]
    
    if len(meaningful_words) >= 25:  # 25 meaningful words
        return True, f"accumulated {len(meaningful_words)} meaningful words"
    
    if len(accumulated_chunks) >= 5:  # 50 seconds
        # Quality check before forcing
        if len(meaningful_words) >= 15:
            return True, "max batch size reached with sufficient content"
        else:
            return False, "max batch size but insufficient meaningful content - skip"
    
    return False, "continue accumulating"
⚡ PERFORMANCE & COST OPTIMIZATIONS
5. DONE - All 6 Active Intelligence Phases Run on Every Chunk
Problem: No selective execution. Wastes LLM calls on chunks that don't need certain phases.

Improvement:

async def process_with_selective_phases(chunk_text: str, insights: List[MeetingInsight]):
    """Only run relevant phases based on chunk content"""
    active_phases = []
    
    # Phase 1: Only if question detected
    if "?" in chunk_text or any(word in chunk_text.lower() for word in 
        ["what", "when", "where", "who", "why", "how"]):
        active_phases.append(Phase.QUESTION_ANSWERING)
    
    # Phase 3: Only if decision keywords detected
    if any(word in chunk_text.lower() for word in 
        ["decided", "agreed", "approved", "let's", "we'll", "going to"]):
        active_phases.append(Phase.CONFLICT_DETECTION)
    
    # Phase 4: Only if action item was extracted
    if any(insight.type == InsightType.ACTION_ITEM for insight in insights):
        active_phases.append(Phase.ACTION_ITEM_QUALITY)
    
    # Phase 6: Always run (lightweight time tracking)
    active_phases.append(Phase.MEETING_EFFICIENCY)
    
    return await run_phases(active_phases, chunk_text, insights)
Expected Savings: ~40-60% reduction in LLM calls

6. DONE: Redundant Vector Searches Across Phases
Problem: Phases 1, 3, and 5 all do Qdrant searches independently.

Improvement:

@dataclass
class SharedSearchCache:
    """Cache semantic search results for 30 seconds"""
    search_results: List[dict]
    timestamp: datetime
    query_embedding: List[float]
    
class IntelligentPhasePipeline:
    def __init__(self):
        self.search_cache: Optional[SharedSearchCache] = None
    
    async def get_or_search(self, query: str) -> List[dict]:
        """Reuse search results across phases"""
        now = datetime.now()
        
        # Check cache validity
        if (self.search_cache and 
            (now - self.search_cache.timestamp).seconds < 30):
            
            # Check if query is similar enough
            query_emb = await embed(query)
            similarity = cosine_similarity(query_emb, self.search_cache.query_embedding)
            
            if similarity > 0.9:  # Very similar query
                logger.info("Reusing cached search results")
                return self.search_cache.search_results
        
        # Perform new search
        results = await qdrant.search(query)
        self.search_cache = SharedSearchCache(
            search_results=results,
            timestamp=now,
            query_embedding=await embed(query)
        )
        return results
Expected Savings: ~$0.08 per meeting (vector search costs)

7. DONE: Deduplication Happens Too Late
Problem: LLM extraction happens before deduplication check.

Improvement:

async def process_transcript_chunk(chunk: TranscriptChunk):
    # EARLY CHECK: Before expensive LLM calls
    if await is_duplicate_chunk(chunk.text):
        logger.info("Skipping duplicate chunk")
        return {"insights": [], "reason": "duplicate"}
    
    # PHASE 1: Passive extraction
    insights = await extract_insights(chunk)
    
    # PHASE 2: Deduplicate insights
    unique_insights = await deduplicate_insights(insights)
    
    # PHASE 3: Active intelligence (only on unique insights)
    proactive = await run_active_intelligence(unique_insights)
    
    return {"insights": unique_insights, "proactive_assistance": proactive}
8. Sliding Window Context Too Large (100 seconds)
Problem: Sending 10 chunks of full context to LLM is expensive.

Improvement:

def build_tiered_context(chunks: List[TranscriptChunk]) -> str:
    """Use progressive summarization"""
    if len(chunks) <= 3:
        return " ".join([c.text for c in chunks])
    
    # Recent context (last 2 chunks): Full detail
    recent = " ".join([c.text for c in chunks[-2:]])
    
    # Medium context (chunks 3-5): Key points only
    medium = chunks[-5:-2]
    medium_summary = extract_key_points(medium)
    
    # Old context (chunks 6-10): High-level summary
    old = chunks[:-5]
    old_summary = summarize_briefly(old)
    
    return f"""
    [Background Context]: {old_summary}
    [Recent Discussion]: {medium_summary}
    [Current Focus]: {recent}
    """
Expected Savings: ~30-40% token reduction = ~$0.05 per meeting

🛡️ RELIABILITY & ERROR HANDLING
9. No LLM Failure Graceful Degradation
Problem: If one phase fails, entire processing might fail.

Improvement:

async def run_active_intelligence_with_fallback(insights):
    """Run phases with graceful degradation"""
    results = {
        "proactive_assistance": [],
        "phase_status": {},
        "errors": []
    }
    
    phases = [
        ("question_answering", run_phase_1),
        ("clarification", run_phase_2),
        ("conflict_detection", run_phase_3),
        # ... etc
    ]
    
    for phase_name, phase_func in phases:
        try:
            result = await asyncio.wait_for(phase_func(insights), timeout=5.0)
            results["proactive_assistance"].extend(result)
            results["phase_status"][phase_name] = "success"
        except asyncio.TimeoutError:
            logger.warning(f"Phase {phase_name} timed out")
            results["phase_status"][phase_name] = "timeout"
        except Exception as e:
            logger.error(f"Phase {phase_name} failed: {e}")
            results["phase_status"][phase_name] = "error"
            results["errors"].append(str(e))
    
    # Success criteria: At least 50% phases succeeded
    success_count = sum(1 for s in results["phase_status"].values() if s == "success")
    results["overall_status"] = "ok" if success_count >= len(phases) / 2 else "degraded"
    
    return results
10. No Circuit Breaker for Qdrant
Problem: If Qdrant is slow/down, all phases timeout.

Improvement:

class QdrantCircuitBreaker:
    def __init__(self, failure_threshold=3, timeout_seconds=60):
        self.failure_count = 0
        self.failure_threshold = failure_threshold
        self.timeout_seconds = timeout_seconds
        self.circuit_open_until: Optional[datetime] = None
    
    async def call(self, func):
        # Check if circuit is open
        if self.circuit_open_until and datetime.now() < self.circuit_open_until:
            logger.warning("Circuit breaker open - skipping Qdrant call")
            return []  # Return empty results
        
        try:
            result = await func()
            self.failure_count = 0  # Reset on success
            return result
        except Exception as e:
            self.failure_count += 1
            logger.error(f"Qdrant failure #{self.failure_count}: {e}")
            
            if self.failure_count >= self.failure_threshold:
                # Open circuit for cooldown period
                self.circuit_open_until = datetime.now() + timedelta(seconds=self.timeout_seconds)
                logger.warning(f"Circuit breaker opened until {self.circuit_open_until}")
            
            return []  # Fail gracefully

# Usage
qdrant_breaker = QdrantCircuitBreaker()
search_results = await qdrant_breaker.call(lambda: qdrant.search(query))
11. No Empty Transcript Handling
Problem: Transcription might return empty or noise-only results.

Improvement:

NOISE_PATTERNS = [
    r'^\[music\]$',
    r'^\[background noise\]$',
    r'^\[inaudible\]$',
    r'^\[silence\]$',
    r'^♪.*♪$',
]

def is_empty_or_noise(transcript: str) -> bool:
    """Check if transcript is empty or just noise"""
    text = transcript.strip()
    
    if not text or len(text) < 3:
        return True
    
    for pattern in NOISE_PATTERNS:
        if re.match(pattern, text, re.IGNORECASE):
            return True
    
    # Check if only punctuation and whitespace
    if all(c in string.punctuation + string.whitespace for c in text):
        return True
    
    return False
12. No Handling of Partial Phase Failures
Problem: If Phase 1 succeeds but Phase 2-6 fail, what gets broadcast?

Improvement:

async def broadcast_with_partial_results(session_id: str, results: dict):
    """Send whatever succeeded, mark failed phases"""
    message = {
        "type": "insights_extracted",
        "session_id": session_id,
        "insights": results.get("insights", []),
        "proactive_assistance": results.get("proactive_assistance", []),
        "status": results.get("overall_status", "ok"),  # ok | degraded | failed
        "phase_status": results.get("phase_status", {}),
    }
    
    # Add warning if degraded
    if message["status"] == "degraded":
        message["warning"] = "Some AI features temporarily unavailable"
    
    await websocket.send_json(message)
📊 DATA MODEL & API IMPROVEMENTS
13. ProactiveAssistanceModel Should Be Sealed Union
Problem: Has 7 optional fields, only 1 should be non-null.

Improvement:

@freezed
sealed class ProactiveAssistance with _$ProactiveAssistance {
  const factory ProactiveAssistance.autoAnswer({
    required String insightId,
    required String question,
    required String answer,
    required double confidence,
    required List<AnswerSource> sources,
  }) = AutoAnswerAssistance;
  
  const factory ProactiveAssistance.clarification({
    required String insightId,
    required String statement,
    required VaguenessType type,
    required List<String> suggestedQuestions,
  }) = ClarificationAssistance;
  
  // ... other variants
  
  factory ProactiveAssistance.fromJson(Map<String, dynamic> json) =>
      _$ProactiveAssistanceFromJson(json);
}
Benefits:

Type-safe pattern matching
Impossible to have multiple types set
Smaller JSON payload
14. Add Message Versioning
Problem: No way to handle API evolution.

Improvement:

{
  "version": "4.1",
  "type": "insights_extracted",
  "insights": [...],
  "proactive_assistance": [...]
}
class LiveInsightsWebSocketService {
  void handleMessage(String data) {
    final json = jsonDecode(data);
    final version = json['version'] ?? '1.0';
    
    if (!isSupportedVersion(version)) {
      logger.warning("Unsupported API version $version");
      showUpdateRequiredDialog();
      return;
    }
    
    // Parse based on version
    switch (version) {
      case '4.1':
        _handleV41Message(json);
      case '4.0':
        _handleV40Message(json);
      default:
        _handleLegacyMessage(json);
    }
  }
}
15. Add Confidence-Based Display Thresholds
Problem: All proactive assistance shows immediately, even low-confidence ones.

Improvement:

enum DisplayMode {
  immediate,  // High confidence - show expanded
  collapsed,  // Medium confidence - show collapsed
  hidden,     // Low confidence - don't show
}

DisplayMode getDisplayMode(ProactiveAssistance assistance) {
  final confidence = assistance.confidence;
  
  return switch (assistance.type) {
    ProactiveAssistanceType.autoAnswer when confidence > 0.85 => 
      DisplayMode.immediate,
    ProactiveAssistanceType.conflictDetected when confidence > 0.80 => 
      DisplayMode.immediate,  // Conflicts are important
    _ when confidence > 0.75 => DisplayMode.collapsed,
    _ => DisplayMode.hidden,
  };
}
🎨 UX & PRODUCT IMPROVEMENTS
16. Add User Feedback Loop
Problem: No way for users to correct wrong insights.

Improvement:

class ProactiveAssistanceCard extends StatelessWidget {
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // ... existing content
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.thumb_up),
                onPressed: () => _sendFeedback(true),
              ),
              IconButton(
                icon: Icon(Icons.thumb_down),
                onPressed: () => _sendFeedback(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _sendFeedback(bool helpful) async {
    await websocket.send({
      "action": "feedback",
      "insight_id": assistance.insightId,
      "helpful": helpful,
      "type": assistance.type.toString(),
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Thank you for your feedback!")),
    );
  }
}
Backend collects this feedback to:

Adjust confidence thresholds over time
Improve prompts
Identify problematic patterns
17. Add Quiet Mode / Phase Toggle
Problem: 6 phases might be overwhelming for some users.

Improvement:

class LiveInsightsSettings {
  final Set<ProactiveAssistanceType> enabledPhases;
  final bool quietMode;  // Only show critical alerts
  
  static const defaultEnabled = {
    ProactiveAssistanceType.autoAnswer,
    ProactiveAssistanceType.conflictDetected,
    ProactiveAssistanceType.incompleteActionItem,
  };
  
  bool shouldShow(ProactiveAssistance assistance) {
    if (quietMode && assistance.priority != Priority.critical) {
      return false;
    }
    
    return enabledPhases.contains(assistance.type);
  }
}
18. Add Processing Decision Visibility
Problem: Users don't know why processing happened (debugging).

Improvement:

# Backend: Include processing decision in response
{
  "type": "insights_extracted",
  "insights": [...],
  "processing_metadata": {
    "trigger": "semantic_score_threshold",
    "priority": "IMMEDIATE",
    "semantic_score": 0.42,
    "signals_detected": ["action_verbs", "time_references"],
    "chunks_accumulated": 1,
    "decision_reason": "Action item with deadline detected"
  }
}
// Frontend: Optional debug overlay
if (kDebugMode || user.isAdmin) {
  showProcessingMetadata(result.metadata);
}
🔬 OBSERVABILITY & MONITORING
19. Add Detailed Token Usage Tracking
Problem: No per-phase cost visibility.

Improvement:

@dataclass
class PhaseMetrics:
    phase_name: str
    tokens_input: int
    tokens_output: int
    cost_usd: float
    latency_ms: float
    success: bool

class CostTracker:
    def __init__(self):
        self.phase_metrics: List[PhaseMetrics] = []
    
    async def track_phase(self, phase_name: str, func):
        start = time.time()
        try:
            result, tokens_in, tokens_out = await func()
            cost = calculate_cost(tokens_in, tokens_out)
            self.phase_metrics.append(PhaseMetrics(
                phase_name=phase_name,
                tokens_input=tokens_in,
                tokens_output=tokens_out,
                cost_usd=cost,
                latency_ms=(time.time() - start) * 1000,
                success=True,
            ))
            return result
        except Exception as e:
            self.phase_metrics.append(PhaseMetrics(
                phase_name=phase_name,
                tokens_input=0,
                tokens_output=0,
                cost_usd=0,
                latency_ms=(time.time() - start) * 1000,
                success=False,
            ))
            raise
    
    def get_session_summary(self):
        total_cost = sum(m.cost_usd for m in self.phase_metrics)
        avg_latency = sum(m.latency_ms for m in self.phase_metrics) / len(self.phase_metrics)
        success_rate = sum(1 for m in self.phase_metrics if m.success) / len(self.phase_metrics)
        
        return {
            "total_cost_usd": total_cost,
            "avg_latency_ms": avg_latency,
            "success_rate": success_rate,
            "phase_breakdown": self.phase_metrics,
        }
20. Add Adaptive Threshold Monitoring
Problem: Fixed thresholds (0.3, 0.6, 0.85) might not be optimal.

Improvement:

class AdaptiveThresholds:
    """Adjust thresholds based on historical accuracy"""
    
    def __init__(self):
        self.semantic_threshold = 0.3
        self.confidence_threshold = 0.6
        self.similarity_threshold = 0.85
        
        # Track accuracy
        self.predictions: List[Tuple[float, bool]] = []  # (score, was_useful)
    
    def record_outcome(self, score: float, was_useful: bool):
        """Record if insight with this score was useful (from user feedback)"""
        self.predictions.append((score, was_useful))
        
        # Recalibrate every 100 samples
        if len(self.predictions) % 100 == 0:
            self._recalibrate()
    
    def _recalibrate(self):
        """Use ROC curve analysis to find optimal threshold"""
        from sklearn.metrics import roc_curve
        
        scores, outcomes = zip(*self.predictions[-1000:])  # Last 1000 samples
        fpr, tpr, thresholds = roc_curve(outcomes, scores)
        
        # Find threshold that maximizes F1 score
        optimal_idx = np.argmax(2 * tpr * (1 - fpr) / (tpr + (1 - fpr)))
        new_threshold = thresholds[optimal_idx]
        
        logger.info(f"Recalibrating threshold: {self.semantic_threshold:.3f} → {new_threshold:.3f}")
        self.semantic_threshold = new_threshold
🚀 ADVANCED FEATURES
21. Add Insight Priority Evolution
Problem: Priority doesn't update as conversation evolves.

Improvement:

class InsightEvolutionTracker:
    """Track how insights evolve over time"""
    
    def __init__(self):
        self.insight_history: Dict[str, List[MeetingInsight]] = {}
    
    def track_evolution(self, new_insight: MeetingInsight):
        """Check if this insight is an evolution of a previous one"""
        similar = self._find_similar_insights(new_insight)
        
        if similar:
            original = similar[0]
            
            # Check for priority escalation
            if new_insight.priority > original.priority:
                logger.info(f"Insight escalated: {original.priority} → {new_insight.priority}")
                self._merge_and_update(original, new_insight)
                return "escalated"
            
            # Check for additional details
            if len(new_insight.content) > len(original.content) * 1.2:
                logger.info("Insight expanded with more details")
                self._merge_and_update(original, new_insight)
                return "expanded"
        
        # New unique insight
        self.insight_history[new_insight.insight_id] = [new_insight]
        return "new"
    
    def _merge_and_update(self, original: MeetingInsight, new: MeetingInsight):
        """Merge insights and update UI"""
        merged = MeetingInsight(
            insight_id=original.insight_id,
            content=f"{original.content} → {new.content}",
            priority=max(original.priority, new.priority),
            evolution_note=f"Updated at chunk {new.source_chunk_index}",
            # ... other fields
        )
        
        await websocket.send_json({
            "type": "insight_updated",
            "insight": merged.to_dict(),
        })
22. Add Multilingual Support
Problem: Regex patterns are English-only.

Improvement:

from dataclasses import dataclass

@dataclass
class LanguagePatterns:
    action_verbs: List[str]
    time_refs: List[str]
    decision_words: List[str]
    question_words: List[str]

PATTERNS = {
    "en": LanguagePatterns(
        action_verbs=["complete", "finish", "implement", "create", "build"],
        time_refs=["today", "tomorrow", "friday", "deadline", "by"],
        decision_words=["decided", "agreed", "approved", "let's"],
        question_words=["what", "when", "where", "who", "why", "how"],
    ),
    "es": LanguagePatterns(
        action_verbs=["completar", "terminar", "implementar", "crear"],
        time_refs=["hoy", "mañana", "viernes", "fecha límite"],
        decision_words=["decidimos", "acordamos", "aprobamos", "vamos a"],
        question_words=["qué", "cuándo", "dónde", "quién", "por qué", "cómo"],
    ),
    # ... more languages
}

def detect_language(text: str) -> str:
    """Detect language using langdetect or fasttext"""
    from langdetect import detect
    return detect(text)

def get_patterns(language: str) -> LanguagePatterns:
    return PATTERNS.get(language, PATTERNS["en"])
23. Add Smart Batching for Related Chunks
Problem: Chunks are processed individually even if they're part of same topic.

Improvement:

class TopicCoherenceDetector:
    """Detect if chunks belong to same topic"""
    
    async def are_related(self, chunk1: str, chunk2: str) -> bool:
        """Check if chunks discuss same topic"""
        emb1 = await embed(chunk1)
        emb2 = await embed(chunk2)
        
        similarity = cosine_similarity(emb1, emb2)
        return similarity > 0.8  # High similarity = same topic
    
    async def should_batch(self, current: str, accumulated: List[str]) -> bool:
        """Decide if current chunk should be added to batch"""
        if not accumulated:
            return True
        
        # Check coherence with last chunk
        last_chunk = accumulated[-1]
        return await self.are_related(current, last_chunk)

# Usage in adaptive processor
async def process_with_topic_awareness(chunk: TranscriptChunk):
    if await topic_detector.should_batch(chunk.text, session.accumulated_context):
        session.accumulated_context.append(chunk.text)
    else:
        # Topic changed - process accumulated batch first
        await process_accumulated_batch(session)
        session.accumulated_context = [chunk.text]
24. Add Rate-Adaptive Processing
Problem: Processing rate doesn't adapt to transcription speed.

Improvement:

class AdaptiveRateLimiter:
    def __init__(self):
        self.recent_latencies: List[float] = []
        self.processing_rate = 1.0  # chunks per second
    
    def record_latency(self, latency_ms: float):
        self.recent_latencies.append(latency_ms)
        if len(self.recent_latencies) > 10:
            self.recent_latencies.pop(0)
        
        # Adjust processing rate
        avg_latency = sum(self.recent_latencies) / len(self.recent_latencies)
        
        if avg_latency > 3000:  # Slow processing
            self.processing_rate = 0.5  # Process less frequently
            logger.warning("Slowing down processing due to high latency")
        elif avg_latency < 1000:  # Fast processing
            self.processing_rate = 1.5  # Process more aggressively
            logger.info("Increasing processing rate due to low latency")
    
    def should_process_now(self, time_since_last: float) -> bool:
        """Time-adaptive processing decision"""
        threshold = 10.0 / self.processing_rate  # Adjust threshold
        return time_since_last >= threshold
25. Add Confidence Calibration
Problem: Confidence scores might not match actual accuracy.

Improvement:

class ConfidenceCalibrator:
    """Calibrate LLM confidence scores to match actual accuracy"""
    
    def __init__(self):
        self.calibration_data: List[Tuple[float, bool]] = []
        self.calibration_model = None
    
    def calibrate(self, llm_confidence: float) -> float:
        """Map LLM confidence to calibrated probability"""
        if not self.calibration_model:
            return llm_confidence  # No calibration yet
        
        # Use isotonic regression or Platt scaling
        return self.calibration_model.predict([[llm_confidence]])[0]
    
    def update(self, llm_confidence: float, was_correct: bool):
        """Update calibration model with feedback"""
        self.calibration_data.append((llm_confidence, was_correct))
        
        if len(self.calibration_data) >= 100:
            from sklearn.isotonic import IsotonicRegression
            X = [x[0] for x in self.calibration_data]
            y = [x[1] for x in self.calibration_data]
            self.calibration_model = IsotonicRegression()
            self.calibration_model.fit(X, y)
📝 SUMMARY: Priority Ranking
Tier 1: Critical (Implement First)
Context window configuration clarity (#1)
Semantic score calculation definition (#2)
Enhanced gibberish detection (#3)
Selective phase execution (#5)
LLM failure graceful degradation (#9)
Tier 2: High Impact (Cost/Performance)
Shared vector search cache (#6)
Early deduplication (#7)
Tiered context summarization (#8)
Circuit breaker for Qdrant (#10)
Token usage tracking (#19)
Tier 3: UX & Product
User feedback loop (#16)
Quiet mode / phase toggles (#17)
Confidence-based display thresholds (#15)
Sealed union types (#13)
Message versioning (#14)
Tier 4: Advanced Features
Insight priority evolution (#21)
Multilingual support (#22)
Smart topic-based batching (#23)
Adaptive rate limiting (#24)
Confidence calibration (#25)