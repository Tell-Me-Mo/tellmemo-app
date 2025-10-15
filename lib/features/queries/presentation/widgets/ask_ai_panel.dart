import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/screen_info.dart';
import '../providers/query_provider.dart' show queryProvider, QueryState, ConversationItem, generateFollowUpSuggestions;
import 'query_suggestions.dart';
import 'typing_indicator.dart';
import '../../../../core/services/notification_service.dart';

class AskAIPanel extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final String? contextInfo;
  final String? conversationId;
  final VoidCallback onClose;
  final double rightOffset;  // Allow custom positioning from right edge
  final String entityType;  // 'project' or 'program'
  final String? autoSubmitQuestion;  // Optional question to auto-submit on open

  const AskAIPanel({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.onClose,
    this.contextInfo,
    this.conversationId,
    this.rightOffset = 0.0,
    this.entityType = 'project',
    this.autoSubmitQuestion,
  });

  @override
  ConsumerState<AskAIPanel> createState() => _AskAIPanelState();
}

class _AskAIPanelState extends ConsumerState<AskAIPanel> with TickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _historyAnimationController;
  late Animation<double> _historyAnimation;
  bool _showSuggestions = false;
  int _visibleItemCount = 20;
  bool _isLoadingMore = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _historyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _historyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _historyAnimationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && _queryController.text.isNotEmpty;
      });
    });

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200 &&
            !_isLoadingMore) {
          _loadMoreItems();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always clear conversation if conversationId provided (item-specific dialogs)
      if (widget.conversationId != null) {
        ref.read(queryProvider.notifier).clearConversation();
      }

      // Load conversations with entity context
      ref.read(queryProvider.notifier).loadConversations(
        widget.projectId,
        entityType: widget.entityType,
        contextId: widget.conversationId,  // Pass the context ID
      );

      // Auto-submit question if provided
      if (widget.autoSubmitQuestion != null && widget.autoSubmitQuestion!.isNotEmpty) {
        _queryController.text = widget.autoSubmitQuestion!;
        // Submit after a short delay to ensure the panel is ready
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _submitQuery();
          }
        });
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _historyAnimationController.dispose();
    _queryController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  void _submitQuery({bool isFollowUp = false}) {
    if (_queryController.text.trim().isEmpty) return;

    String question = _queryController.text.trim();

    if (widget.contextInfo != null && ref.read(queryProvider).conversation.isEmpty) {
      question = '${widget.contextInfo}\n\nUser question: $question';
    }

    ref.read(queryProvider.notifier).submitQuery(
      projectId: widget.projectId,
      question: question,
      isFollowUp: isFollowUp,
      entityType: widget.entityType,
      contextId: widget.conversationId,  // Pass context ID
    );

    _queryController.clear();
    setState(() {
      _showSuggestions = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _cleanQuestionForDisplay(String question) {
    if (question.contains('User question:')) {
      final parts = question.split('User question:');
      if (parts.length > 1) {
        return parts.last.trim();
      }
    }
    return question;
  }

  void _selectSuggestion(String suggestion) {
    _queryController.text = suggestion;
    _submitQuery();
  }

  void _loadMoreItems() {
    if (_visibleItemCount < ref.read(queryProvider).conversation.length) {
      setState(() {
        _isLoadingMore = true;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _visibleItemCount = (_visibleItemCount + 10).clamp(
              0,
              ref.read(queryProvider).conversation.length,
            );
            _isLoadingMore = false;
          });
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final queryState = ref.watch(queryProvider);
    final screenInfo = ScreenInfo.fromContext(context);
    final hasConversation = queryState.conversation.isNotEmpty;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final panelWidth = screenInfo.isMobile
      ? MediaQuery.of(context).size.width
      : MediaQuery.of(context).size.width * 0.45;
    final maxWidth = 600.0;
    final actualWidth = panelWidth > maxWidth ? maxWidth : panelWidth;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
      children: [
        // Backdrop
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return _animationController.value > 0
              ? GestureDetector(
                  onTap: _handleClose,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5 * _animationController.value),
                  ),
                )
              : const SizedBox.shrink();
          },
        ),
        // Panel
        Positioned(
          right: widget.rightOffset,
          top: 0,
          bottom: screenInfo.isMobile ? keyboardHeight : 0,
          width: actualWidth,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.psychology_outlined,
                            size: 24,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ask AI Assistant',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.projectName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (hasConversation)
                          TextButton.icon(
                            onPressed: () {
                              ref.read(queryProvider.notifier).clearConversation();
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('New'),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _handleClose,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),
                  // Conversation History Section
                  if (!screenInfo.isMobile || keyboardHeight == 0)
                    _buildConversationHistory(theme, colorScheme),
                  // Content
                  Expanded(
                    child: hasConversation
                      ? _buildConversationView(theme, queryState)
                      : _buildEmptyState(theme),
                  ),
                  // Input area
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                      bottom: screenInfo.isMobile
                        ? 16
                        : MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Example chips only shown when no conversation and keyboard not visible
                        if (!hasConversation && (!screenInfo.isMobile || keyboardHeight == 0)) ...[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildExampleChip('What are the key decisions?', colorScheme),
                                const SizedBox(width: 8),
                                _buildExampleChip('Show action items', colorScheme),
                                const SizedBox(width: 8),
                                _buildExampleChip('What are the blockers?', colorScheme),
                                const SizedBox(width: 8),
                                _buildExampleChip('Latest updates', colorScheme),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Input field and send button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  TextField(
                                    controller: _queryController,
                                    focusNode: _focusNode,
                                    enabled: !queryState.isLoading,
                                    maxLines: null,
                                    minLines: 1,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _submitQuery(isFollowUp: hasConversation),
                                    decoration: InputDecoration(
                                      hintText: hasConversation
                                        ? 'Ask a follow-up question...'
                                        : 'Ask about your project...',
                                      filled: true,
                                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _showSuggestions = value.isNotEmpty && _focusNode.hasFocus;
                                      });
                                    },
                                  ),
                                  if (_showSuggestions && (!screenInfo.isMobile || keyboardHeight == 0))
                                    Positioned(
                                      bottom: 60,
                                      left: 0,
                                      right: 0,
                                      child: QuerySuggestions(
                                        query: _queryController.text,
                                        onSuggestionSelected: _selectSuggestion,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: queryState.isLoading
                                  ? null
                                  : () => _submitQuery(isFollowUp: hasConversation),
                                icon: queryState.isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded, color: Colors.white),
                                tooltip: 'Send',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildConversationView(ThemeData theme, QueryState queryState) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && queryState.conversation.length <= 20) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final totalItems = queryState.conversation.length;
    final visibleItems = totalItems > 20
        ? _visibleItemCount.clamp(0, totalItems)
        : totalItems;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: visibleItems +
          (queryState.error != null ? 1 : 0) +
          (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoadingMore && index == visibleItems) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading more messages...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (queryState.error != null &&
            index == visibleItems + (_isLoadingMore ? 1 : 0)) {
          return _buildErrorMessage(theme, queryState.error!);
        }

        if (index < visibleItems) {
          final item = queryState.conversation[index];
          return _buildConversationItem(theme, item, index);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildConversationItem(ThemeData theme, ConversationItem item, int index) {
    final queryState = ref.watch(queryProvider);
    final colorScheme = theme.colorScheme;
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User question
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'You',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeFormat.format(item.timestamp),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _cleanQuestionForDisplay(item.question),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // AI answer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.2),
                      Colors.green.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  size: 14,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AI Assistant',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        if (!item.isAnswerPending && item.confidence > 0.8)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'High confidence',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.green,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (!item.isAnswerPending && item.answer.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.copy_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            tooltip: 'Copy',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: item.answer));
                              ref.read(notificationServiceProvider.notifier).showSuccess('Copied to clipboard');
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (item.isAnswerPending)
                      _buildTypingIndicator(theme)
                    else ...[
                      MarkdownBody(
                        data: item.answer,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.bodyMedium,
                          blockquotePadding: const EdgeInsets.all(12),
                          blockquoteDecoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: colorScheme.primary,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (item.sources.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: item.sources
                              .take(3)
                              .map((source) => Chip(
                                    label: Text(
                                      source,
                                      style: const TextStyle(fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.2),
                                    side: BorderSide.none,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  ))
                              .toList(),
                        ),
                      ],
                      // Follow-up suggestions
                      if (index == queryState.conversation.length - 1 && !queryState.isLoading) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: generateFollowUpSuggestions(item.answer, item.question)
                              .map((suggestion) => ActionChip(
                                    label: Text(
                                      suggestion,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.2),
                                    side: BorderSide.none,
                                    onPressed: () {
                                      _queryController.text = suggestion;
                                      _submitQuery(isFollowUp: true);
                                    },
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Row(
      children: [
        TypingIndicator(
          color: Colors.green,
          dotSize: 6,
          spacing: 3,
        ),
        const SizedBox(width: 12),
        Text(
          'Thinking...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(ThemeData theme, String error) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.1),
                    Colors.green.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 48,
                color: Colors.green.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ask me anything',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'I can help you find information, analyze patterns,\nand provide insights about your project.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String text, ColorScheme colorScheme) {
    return ActionChip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.3),
      side: BorderSide(
        color: colorScheme.outline.withValues(alpha: 0.2),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      onPressed: () {
        _queryController.text = text;
        _submitQuery();
      },
    );
  }

  Widget _buildConversationHistory(ThemeData theme, ColorScheme colorScheme) {
    final queryState = ref.watch(queryProvider);
    final dateFormat = DateFormat('MMM d, HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Toggle button
          InkWell(
            onTap: () {
              setState(() {
                _showHistory = !_showHistory;
                if (_showHistory) {
                  _historyAnimationController.forward();
                } else {
                  _historyAnimationController.reverse();
                }
              });
            },
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                children: [
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _showHistory ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.history,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Conversation History',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (queryState.sessions.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${queryState.sessions.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_showHistory)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(queryProvider.notifier).createNewSession(widget.projectId);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Chat'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: theme.textTheme.labelMedium,
                      ),
                    ),
                ],
                ),
              ),
            ),
          ),
          // History list
          if (_showHistory)
            SizedBox(
              height: 195,
              child: FadeTransition(
                opacity: _historyAnimation,
                child: queryState.sessions.isEmpty
                  ? Center(
                      child: Text(
                        'No previous conversations',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: queryState.sessions.length,
                      itemBuilder: (context, index) {
                        final session = queryState.sessions[index];
                        final isActive = session.id == queryState.activeSessionId;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                ref.read(queryProvider.notifier).switchToSession(widget.projectId, session.id);
                                setState(() {
                                  _showHistory = false;
                                  _historyAnimationController.reverse();
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive
                                    ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                                    : null,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isActive
                                      ? colorScheme.primary.withValues(alpha: 0.3)
                                      : colorScheme.outlineVariant.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (isActive)
                                      Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.title,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: isActive ? FontWeight.w600 : null,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${dateFormat.format(session.createdAt)} • ${session.items.length} messages',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                        color: colorScheme.error.withValues(alpha: 0.6),
                                      ),
                                      onPressed: () {
                                        ref.read(queryProvider.notifier).deleteSession(widget.projectId, session.id);
                                      },
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}