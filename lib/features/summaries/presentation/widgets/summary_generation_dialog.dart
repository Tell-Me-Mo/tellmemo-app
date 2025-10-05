import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/content_availability_service.dart';
import '../../data/models/summary_model.dart';
import 'content_availability_indicator.dart';
import '../../../../core/services/firebase_analytics_service.dart';

class SummaryGenerationDialog extends StatefulWidget {
  final String entityType; // 'project', 'program', or 'portfolio'
  final String entityId;
  final String entityName;
  final Future<SummaryModel?> Function({
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  }) onGenerate;
  final VoidCallback? onUploadContent;

  const SummaryGenerationDialog({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.onGenerate,
    this.onUploadContent,
  });

  @override
  State<SummaryGenerationDialog> createState() => _SummaryGenerationDialogState();
}

class _SummaryGenerationDialogState extends State<SummaryGenerationDialog> {
  // State variables
  bool _isCheckingAvailability = true;
  bool _isUpdatingAvailability = false; // Separate flag for updates
  ContentAvailability? _availability;
  SummaryStats? _stats;
  String? _availabilityError;
  Timer? _debounceTimer;

  // Form variables
  String _selectedFormat = 'general';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  // Generation state
  bool _isGenerating = false;
  String _generationStatus = '';
  double _generationProgress = 0.0;
  String? _generationError;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _timeoutTimer;
  Timer? _progressTimer;

  // Format descriptions
  final Map<String, String> _formatDescriptions = {
    'general': 'Comprehensive summary with all details',
    'executive': 'High-level strategic overview for executives',
    'technical': 'Technical details and implementation focus',
    'stakeholder': 'Client-facing summary with deliverables',
  };

  @override
  void initState() {
    super.initState();
    _checkContentAvailability(isInitial: true);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _progressTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  String _getEntityTypeLabel() {
    switch (widget.entityType.toLowerCase()) {
      case 'project':
        return 'Project';
      case 'program':
        return 'Program';
      case 'portfolio':
        return 'Portfolio';
      default:
        return 'Project';
    }
  }

  Future<void> _checkContentAvailability({bool isInitial = false}) async {
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    // For initial load, show loading state
    if (isInitial) {
      setState(() {
        _isCheckingAvailability = true;
        _availabilityError = null;
      });
    } else {
      // For updates, use debouncing to avoid too frequent refreshes
      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        setState(() {
          _isUpdatingAvailability = true;
        });

        await _fetchContentAvailability();
      });
      return;
    }

    await _fetchContentAvailability();
  }

  Future<void> _fetchContentAvailability() async {
    try {
      // Check content availability
      final availability = await contentAvailabilityService.checkAvailability(
        entityType: widget.entityType,
        entityId: widget.entityId,
        dateStart: _startDate,
        dateEnd: _endDate,
      );

      // Get summary stats only on initial load
      SummaryStats? stats = _stats;
      if (_stats == null) {
        stats = await contentAvailabilityService.getSummaryStats(
          entityType: widget.entityType,
          entityId: widget.entityId,
        );
      }

      if (mounted) {
        setState(() {
          _availability = availability;
          if (stats != null) _stats = stats;
          _isCheckingAvailability = false;
          _isUpdatingAvailability = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availabilityError = e.toString();
          _isCheckingAvailability = false;
          _isUpdatingAvailability = false;
        });
      }
    }
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isGenerating = true;
      _generationStatus = 'Initializing...';
      _generationProgress = 0.1;
      _generationError = null;
    });

    // Log summary generation requested
    final startTime = DateTime.now();
    await FirebaseAnalyticsService().logSummaryGenerationRequested(
      entityType: widget.entityType,
      entityId: widget.entityId,
      summaryType: 'custom',
      format: _selectedFormat,
    );

    // Start progress simulation
    _startProgressSimulation();

    // Set timeout timer (60 seconds)
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (_isGenerating) {
        _handleTimeout();
      }
    });

    try {
      final summary = await widget.onGenerate(
        format: _selectedFormat,
        startDate: _startDate,
        endDate: _endDate,
      );

      _timeoutTimer?.cancel();
      _progressTimer?.cancel();

      if (summary != null) {
        // Log summary generation completed
        final generationTime = DateTime.now().difference(startTime).inMilliseconds;
        await FirebaseAnalyticsService().logSummaryGenerationCompleted(
          entityType: widget.entityType,
          entityId: widget.entityId,
          summaryType: 'custom',
          summaryId: summary.id,
          generationTime: generationTime,
        );

        setState(() {
          _isGenerating = false;
          _generationProgress = 1.0;
          _generationStatus = 'Summary generated successfully!';
        });

        // Close dialog with success
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop(summary);
          }
        });
      } else {
        throw Exception('Failed to generate summary');
      }
    } catch (e) {
      _timeoutTimer?.cancel();
      _progressTimer?.cancel();

      // Log summary generation failed
      await FirebaseAnalyticsService().logSummaryGenerationFailed(
        entityType: widget.entityType,
        entityId: widget.entityId,
        errorReason: e.toString(),
      );

      // Parse the error to check for specific error types
      final errorMessage = _parseErrorMessage(e.toString());
      final shouldRetry = _shouldRetryOnError(e.toString());

      if (shouldRetry && _retryCount < _maxRetries) {
        _retryGeneration();
      } else {
        if (mounted) { // Check mounted before setState
          setState(() {
            _isGenerating = false;
            _generationError = errorMessage;
            _generationProgress = 0.0;
          });
        }
      }
    }
  }

  String _parseErrorMessage(String error) {
    // Check for specific error codes from the backend
    if (error.contains('LLM_OVERLOADED') || error.contains('overloaded')) {
      return 'The AI service is currently experiencing high demand. Please wait a moment and try again.';
    } else if (error.contains('RATE_LIMIT_EXCEEDED')) {
      return 'Too many requests. Please wait a minute before trying again.';
    } else if (error.contains('LLM_AUTH_FAILED')) {
      return 'Authentication with AI service failed. Please contact support.';
    } else if (error.contains('LLM_TIMEOUT')) {
      return 'The request took too long to process. Please try again.';
    } else if (error.contains('INSUFFICIENT_DATA')) {
      return 'Not enough content available to generate a meaningful summary. Please add more content first.';
    } else if (error.contains('user_message')) {
      // Try to extract the user_message from the error response
      final regex = RegExp(r'"user_message"\s*:\s*"([^"]+)"');
      final match = regex.firstMatch(error);
      if (match != null) {
        return match.group(1)!;
      }
    }

    // Default error message
    if (_retryCount >= _maxRetries) {
      return 'Failed after $_maxRetries attempts. Please try again later or contact support if the issue persists.';
    } else {
      return 'Failed to generate summary: ${error.split(':').last.trim()}';
    }
  }

  bool _shouldRetryOnError(String error) {
    // Automatically retry on transient errors
    return error.contains('LLM_OVERLOADED') ||
           error.contains('overloaded') ||
           error.contains('RATE_LIMIT_EXCEEDED') ||
           error.contains('LLM_TIMEOUT') ||
           error.contains('503') ||
           error.contains('429') ||
           error.contains('504');
  }

  void _startProgressSimulation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isGenerating) {
        timer.cancel();
        return;
      }

      setState(() {
        // Slow down as we approach completion but never reach 100% until actually done
        if (_generationProgress < 0.9) {
          _generationProgress += 0.05;
        } else if (_generationProgress < 0.95) {
          _generationProgress += 0.01;
        } else if (_generationProgress < 0.99) {
          _generationProgress += 0.002;
        }
        // Stay at 99% until actually complete
        _generationProgress = _generationProgress.clamp(0.0, 0.99);
        _updateStatusMessage();
      });
    });
  }

  void _updateStatusMessage() {
    if (_generationProgress < 0.2) {
      _generationStatus = 'Initializing summary generation...';
    } else if (_generationProgress < 0.4) {
      _generationStatus = 'Collecting ${widget.entityType} data...';
    } else if (_generationProgress < 0.6) {
      _generationStatus = 'Analyzing content...';
    } else if (_generationProgress < 0.8) {
      _generationStatus = 'Generating insights with AI...';
    } else {
      _generationStatus = 'Finalizing summary...';
    }
  }

  void _handleTimeout() {
    if (_retryCount < _maxRetries) {
      _retryGeneration();
    } else {
      setState(() {
        _isGenerating = false;
        _generationError = 'Generation timed out after 60 seconds';
        _generationProgress = 0.0;
      });
    }
  }

  void _retryGeneration() {
    if (!mounted) return; // Guard against calling setState on disposed widget

    setState(() {
      _retryCount++;
      _generationStatus = 'Retrying... (Attempt ${_retryCount + 1}/$_maxRetries)';
      _generationProgress = 0.1;
    });

    // Exponential backoff: 2s, 4s, 8s with some jitter
    final baseDelay = 2.0 * (1 << (_retryCount - 1)); // 2^retryCount seconds
    final jitter = (baseDelay * 0.25 * (0.5 + (DateTime.now().millisecondsSinceEpoch % 1000) / 2000)).round();
    final delaySeconds = (baseDelay + jitter).clamp(2, 10); // Max 10 seconds delay

    Future.delayed(Duration(seconds: delaySeconds.toInt()), () {
      if (mounted) {
        _generateSummary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simplified Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate ${_getEntityTypeLabel()} Summary',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.entityName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),

              // Content without scroll
              Padding(
                padding: const EdgeInsets.all(20),
                child: _isCheckingAvailability && _availability == null
                    ? _buildLoadingContent()
                    : _availabilityError != null && _availability == null
                        ? _buildErrorContent()
                        : _isGenerating
                            ? _buildGeneratingContent()
                            : _buildFormContent(),
              ),

              // Simplified Actions
              if (!_isGenerating && !(_isCheckingAvailability && _availability == null)) ...[
                Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _availability?.canGenerateSummary == true
                            ? _generateSummary
                            : null,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Generate Summary'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Checking content availability...'),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to check content availability',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _availabilityError ?? 'Unknown error',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _checkContentAvailability,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Simple animated icon
        TweenAnimationBuilder<double>(
          key: ValueKey(_isGenerating),
          tween: Tween(begin: 0, end: _isGenerating ? 30 : 1),
          duration: Duration(seconds: _isGenerating ? 120 : 2),
          curve: Curves.linear,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 2 * 3.14159,
              child: Icon(
                Icons.auto_awesome,
                size: 48,
                color: colorScheme.primary,
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Clean progress bar
        SizedBox(
          width: 250,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _generationProgress,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _generationError != null ? colorScheme.error : colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_generationProgress * 100).toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status message
        Text(
          _generationStatus,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),

        if (_retryCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Retry attempt $_retryCount of $_maxRetries',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange,
            ),
          ),
        ],

        if (_generationError != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 8),
                Text(
                  _generationError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _retryCount = 0;
                          _generationError = null;
                        });
                        _generateSummary();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Content Availability Section
        if (_availability != null || _isUpdatingAvailability) ...[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isUpdatingAvailability && _availability != null
                ? Opacity(
                    key: const ValueKey('updating'),
                    opacity: 0.6,
                    child: _buildContentAvailabilitySection(),
                  )
                : _buildContentAvailabilitySection(),
          ),
          const SizedBox(height: 20),
        ],

        // Compact Format Selection
        Text(
          'Summary Format',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            children: ['general', 'executive', 'technical', 'stakeholder'].asMap().entries.map((entry) {
              final index = entry.key;
              final format = entry.value;
              final isSelected = _selectedFormat == format;
              final isLast = index == 3;
              return Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFormat = format;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: isSelected
                            ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                            : null,
                        border: isSelected
                            ? Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                width: isSelected ? 2 : 1.5,
                              ),
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : null,
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            _getFormatIcon(format),
                            size: 18,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  format.capitalize(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 13,
                                    color: isSelected
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _formatDescriptions[format]!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Date Range Selection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Date Range',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            // Quick presets
            Row(
              children: [
                _buildDatePreset('7d', 7),
                const SizedBox(width: 8),
                _buildDatePreset('14d', 14),
                const SizedBox(width: 8),
                _buildDatePreset('30d', 30),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isMobile = screenWidth < 600;
            return Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    label: 'From',
                    date: _startDate,
                    onDateChanged: (date) {
                      setState(() {
                        _startDate = date;
                        // Ensure end date is not before start date
                        if (_endDate.isBefore(_startDate)) {
                          _endDate = _startDate;
                        }
                      });
                      _checkContentAvailability(isInitial: false);
                    },
                    lastDate: _endDate,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: _buildDateSelector(
                    label: 'To',
                    date: _endDate,
                    onDateChanged: (date) {
                      setState(() {
                        _endDate = date;
                        // Ensure start date is not after end date
                        if (_startDate.isAfter(_endDate)) {
                          _startDate = _endDate;
                        }
                      });
                      _checkContentAvailability(isInitial: false);
                    },
                    firstDate: _startDate,
                    lastDate: DateTime.now(),
                  ),
                ),
              ],
            );
          },
        ),

      ],
    );
  }

  Widget _buildContentAvailabilitySection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_availability == null) return const SizedBox.shrink();

    final hasGoodContent = _availability!.contentCount >= 10;
    final hasMinimalContent = _availability!.contentCount >= 3;
    final hasAnyContent = _availability!.contentCount > 0;

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusMessage;

    if (!hasAnyContent) {
      statusColor = colorScheme.error;
      statusIcon = Icons.folder_off_outlined;
      statusTitle = 'No Content Available';
      statusMessage = 'No content found. Try a different date range.';
    } else if (!hasMinimalContent) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'Very Limited Content';
      statusMessage = 'Only ${_availability!.contentCount} item${_availability!.contentCount > 1 ? 's' : ''} found. Summary will be basic and may lack detail.';
    } else if (!hasGoodContent) {
      statusColor = Colors.amber.shade700;
      statusIcon = Icons.info_outline;
      statusTitle = 'Moderate Content Available';
      statusMessage = '${_availability!.contentCount} items found. Good for summary generation.';
    } else {
      statusColor = Colors.green.shade700;
      statusIcon = Icons.check_circle_outline;
      statusTitle = 'Excellent Content Available';
      statusMessage = '${_availability!.contentCount} items found. Ideal for comprehensive summary.';
    }

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      statusMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Compact content breakdown
          if (_availability!.contentBreakdown != null && _availability!.contentBreakdown!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Content Breakdown',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _availability!.contentBreakdown!.entries
                        .where((entry) => entry.value > 0)
                        .map((entry) {
                      final itemName = entry.key.toLowerCase().replaceAll('_', ' ');
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getContentTypeIcon(entry.key),
                            size: 12,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.value} $itemName${entry.value > 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],

          // Compact quality bar
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Summary Quality Expectation',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _getQualityScore(),
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getQualityLabel(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getQualityScore() {
    if (_availability == null) return 0.0;
    final count = _availability!.contentCount;

    if (count == 0) return 0.0;
    if (count < 3) return 0.25;
    if (count < 10) return 0.5;
    if (count < 20) return 0.75;
    return 1.0;
  }

  String _getQualityLabel() {
    if (_availability == null) return 'Unknown';
    final count = _availability!.contentCount;

    if (count == 0) return 'None';
    if (count < 3) return 'Basic';
    if (count < 10) return 'Good';
    if (count < 20) return 'Great';
    return 'Excellent';
  }

  IconData _getContentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'meeting':
      case 'meetings':
        return Icons.groups_outlined;
      case 'email':
      case 'emails':
        return Icons.email_outlined;
      case 'document':
      case 'documents':
        return Icons.description_outlined;
      case 'activity':
      case 'activities':
        return Icons.task_outlined;
      case 'note':
      case 'notes':
        return Icons.note_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Widget _buildDatePreset(String label, int days) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final presetStartDate = DateTime.now().subtract(Duration(days: days));
    final presetEndDate = DateTime.now();
    final isActive = _startDate.isAtSameMomentAs(
      DateTime(presetStartDate.year, presetStartDate.month, presetStartDate.day)
    ) && _endDate.isAtSameMomentAs(
      DateTime(presetEndDate.year, presetEndDate.month, presetEndDate.day)
    );

    return InkWell(
      onTap: () {
        setState(() {
          _startDate = DateTime(
            presetStartDate.year,
            presetStartDate.month,
            presetStartDate.day
          );
          _endDate = DateTime(
            presetEndDate.year,
            presetEndDate.month,
            presetEndDate.day
          );
        });
        _checkContentAvailability(isInitial: false);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required Function(DateTime) onDateChanged,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Detect mobile screen
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 365)),
          lastDate: lastDate ?? DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: colorScheme.copyWith(
                  primary: colorScheme.primary,
                  onPrimary: colorScheme.onPrimary,
                  surface: colorScheme.surface,
                  onSurface: colorScheme.onSurface,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null && picked != date) {
          onDateChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 8 : 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM dd, yyyy').format(date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd, yyyy').format(date),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCompactStat(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }


  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'executive':
        return Icons.business_center;
      case 'technical':
        return Icons.code;
      case 'stakeholder':
        return Icons.groups;
      default:
        return Icons.dashboard;
    }
  }

  String _formatLastGenerated(String dateStr) {
    final date = DateTime.parse('${dateStr}Z').toLocal();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}