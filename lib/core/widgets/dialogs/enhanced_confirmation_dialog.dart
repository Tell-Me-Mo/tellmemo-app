import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';

enum ConfirmationSeverity {
  info,
  warning,
  danger,
}

class ImpactSummary {
  final int totalItems;
  final Map<String, int> itemsByType;
  final List<String> affectedItems;
  final String? additionalInfo;
  
  const ImpactSummary({
    required this.totalItems,
    this.itemsByType = const {},
    this.affectedItems = const [],
    this.additionalInfo,
  });
}

class EnhancedConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final ConfirmationSeverity severity;
  final ImpactSummary? impact;
  final bool requireExplicitConfirmation;
  final String? explicitConfirmationText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showUndoHint;
  
  const EnhancedConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.severity = ConfirmationSeverity.warning,
    this.impact,
    this.requireExplicitConfirmation = false,
    this.explicitConfirmationText,
    this.onConfirm,
    this.onCancel,
    this.showUndoHint = false,
  });
  
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    ConfirmationSeverity severity = ConfirmationSeverity.warning,
    ImpactSummary? impact,
    bool requireExplicitConfirmation = false,
    String? explicitConfirmationText,
    bool showUndoHint = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        severity: severity,
        impact: impact,
        requireExplicitConfirmation: requireExplicitConfirmation,
        explicitConfirmationText: explicitConfirmationText,
        showUndoHint: showUndoHint,
      ),
    );
    return result ?? false;
  }
  
  @override
  State<EnhancedConfirmationDialog> createState() => _EnhancedConfirmationDialogState();
}

class _EnhancedConfirmationDialogState extends State<EnhancedConfirmationDialog> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final _confirmationController = TextEditingController();
  bool _canConfirm = false;
  bool _showDetails = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: UIConstants.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: UIConstants.defaultCurve,
    ));
    _animationController.forward();
    
    if (widget.requireExplicitConfirmation) {
      _confirmationController.addListener(_checkConfirmationText);
    } else {
      _canConfirm = true;
    }
  }
  
  @override
  void dispose() {
    _confirmationController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _checkConfirmationText() {
    final expectedText = widget.explicitConfirmationText ?? widget.title;
    setState(() {
      _canConfirm = _confirmationController.text == expectedText;
    });
  }
  
  Color _getSeverityColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (widget.severity) {
      case ConfirmationSeverity.info:
        return theme.colorScheme.primary;
      case ConfirmationSeverity.warning:
        return Colors.orange;
      case ConfirmationSeverity.danger:
        return theme.colorScheme.error;
    }
  }
  
  IconData _getSeverityIcon() {
    switch (widget.severity) {
      case ConfirmationSeverity.info:
        return Icons.info_outline;
      case ConfirmationSeverity.warning:
        return Icons.warning_amber_rounded;
      case ConfirmationSeverity.danger:
        return Icons.dangerous_outlined;
    }
  }
  
  String _getDefaultConfirmText() {
    switch (widget.severity) {
      case ConfirmationSeverity.info:
        return 'OK';
      case ConfirmationSeverity.warning:
        return 'Proceed';
      case ConfirmationSeverity.danger:
        return 'Delete';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _getSeverityColor(context);
    final dialogWidth = ResponsiveUtils.getDialogWidth(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        titlePadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        title: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: severityColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getSeverityIcon(),
                color: severityColor,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message,
                  style: theme.textTheme.bodyMedium,
                ),
                if (widget.impact != null) ...[
                  const SizedBox(height: 16),
                  _buildImpactSection(context),
                ],
                if (widget.requireExplicitConfirmation) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Type "${widget.explicitConfirmationText ?? widget.title}" to confirm:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmationController,
                    decoration: InputDecoration(
                      hintText: 'Enter confirmation text',
                      border: const OutlineInputBorder(),
                      fillColor: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                      filled: widget.severity == ConfirmationSeverity.danger,
                    ),
                    autofocus: true,
                  ),
                ],
                if (widget.showUndoHint) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action cannot be undone',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onCancel?.call();
              Navigator.of(context).pop(false);
            },
            child: Text(widget.cancelText ?? 'Cancel'),
          ),
          AnimatedContainer(
            duration: UIConstants.shortAnimation,
            child: FilledButton(
              onPressed: _canConfirm
                  ? () {
                      widget.onConfirm?.call();
                      Navigator.of(context).pop(true);
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: widget.severity == ConfirmationSeverity.danger
                    ? theme.colorScheme.error
                    : null,
              ),
              child: Text(widget.confirmText ?? _getDefaultConfirmText()),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImpactSection(BuildContext context) {
    final theme = Theme.of(context);
    final impact = widget.impact!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Impact Summary',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (impact.affectedItems.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                  icon: Icon(
                    _showDetails ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                  ),
                  label: Text(_showDetails ? 'Hide Details' : 'Show Details'),
                  style: TextButton.styleFrom(
                    textStyle: theme.textTheme.bodySmall,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (impact.totalItems > 0) ...[
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${impact.totalItems} item${impact.totalItems != 1 ? 's' : ''} will be affected',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (impact.itemsByType.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: impact.itemsByType.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SelectionColors.getItemTypeColor(context, entry.key),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.value} ${entry.key}${entry.value != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          if (_showDetails && impact.affectedItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: impact.affectedItems.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '• ',
                          style: theme.textTheme.bodySmall,
                        ),
                        Expanded(
                          child: Text(
                            impact.affectedItems[index],
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (impact.additionalInfo != null) ...[
            const SizedBox(height: 8),
            Text(
              impact.additionalInfo!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}