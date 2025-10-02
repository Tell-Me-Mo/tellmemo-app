import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';

class ProgressIndicatorDialog extends StatelessWidget {
  final String title;
  final String? message;
  final double? progress;
  final int? currentItem;
  final int? totalItems;
  final VoidCallback? onCancel;
  final bool canDismiss;
  
  const ProgressIndicatorDialog({
    super.key,
    required this.title,
    this.message,
    this.progress,
    this.currentItem,
    this.totalItems,
    this.onCancel,
    this.canDismiss = false,
  });
  
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    double? progress,
    int? currentItem,
    int? totalItems,
    VoidCallback? onCancel,
    bool canDismiss = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: canDismiss,
      builder: (context) => ProgressIndicatorDialog(
        title: title,
        message: message,
        progress: progress,
        currentItem: currentItem,
        totalItems: totalItems,
        onCancel: onCancel,
        canDismiss: canDismiss,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProgress = progress != null || (currentItem != null && totalItems != null);
    
    return PopScope(
      canPop: canDismiss,
      child: AlertDialog(
        title: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title)),
          ],
        ),
        content: SizedBox(
          width: ResponsiveUtils.getDialogWidth(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message != null) ...[
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              if (hasProgress) ...[
                if (currentItem != null && totalItems != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Processing item $currentItem of $totalItems',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${((currentItem! / totalItems!) * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: progress ?? (currentItem! / totalItems!),
                  ),
                  duration: UIConstants.normalAnimation,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                    );
                  },
                ),
              ] else
                const LinearProgressIndicator(minHeight: 4),
            ],
          ),
        ),
        actions: onCancel != null
            ? [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ]
            : null,
      ),
    );
  }
}

class BulkOperationProgress extends StatefulWidget {
  final String operation;
  final List<String> items;
  final Future<void> Function(String item, void Function(int) onProgress) processor;
  final VoidCallback onComplete;
  final void Function(String error)? onError;
  
  const BulkOperationProgress({
    super.key,
    required this.operation,
    required this.items,
    required this.processor,
    required this.onComplete,
    this.onError,
  });
  
  @override
  State<BulkOperationProgress> createState() => _BulkOperationProgressState();
}

class _BulkOperationProgressState extends State<BulkOperationProgress> {
  int _currentIndex = 0;
  bool _cancelled = false;
  String? _currentItem;
  
  @override
  void initState() {
    super.initState();
    _processItems();
  }
  
  Future<void> _processItems() async {
    for (int i = 0; i < widget.items.length; i++) {
      if (_cancelled) break;
      
      setState(() {
        _currentIndex = i;
        _currentItem = widget.items[i];
      });
      
      try {
        await widget.processor(widget.items[i], (progress) {
          if (mounted && !_cancelled) {
            setState(() {
              // Keep _currentIndex as current item being processed
              // progress is handled separately in the UI
            });
          }
        });
      } catch (e) {
        if (widget.onError != null) {
          widget.onError!(e.toString());
        }
        break;
      }
    }
    
    if (!_cancelled && mounted) {
      widget.onComplete();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _currentIndex / widget.items.length;
    
    return AlertDialog(
      title: Text(widget.operation),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentItem != null) ...[
            Text(
              'Processing: $_currentItem',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentIndex.floor() + 1} of ${widget.items.length}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: UIConstants.shortAnimation,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 4,
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _cancelled = true;
            });
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}