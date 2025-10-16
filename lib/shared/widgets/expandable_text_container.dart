import 'package:flutter/material.dart';

/// A widget that displays text with automatic truncation and "read more" functionality.
///
/// This widget handles long text content by truncating it to a maximum character
/// limit and providing a toggle to expand/collapse the full text. It also includes
/// input validation for edge cases like empty strings and extremely long strings.
class ExpandableTextContainer extends StatefulWidget {
  /// The text content to display
  final String text;

  /// The color scheme used for styling
  final ColorScheme colorScheme;

  /// Maximum character limit before truncation (default: 200)
  final int maxCharacters;

  /// Maximum allowed string length (default: 100,000 characters)
  /// Prevents performance issues with extremely long strings
  final int maxAllowedLength;

  /// Whether to show the text as a placeholder (lighter color)
  final bool showAsPlaceholder;

  const ExpandableTextContainer({
    super.key,
    required this.text,
    required this.colorScheme,
    this.maxCharacters = 200,
    this.maxAllowedLength = 100000,
    this.showAsPlaceholder = false,
  });

  @override
  State<ExpandableTextContainer> createState() => _ExpandableTextContainerState();
}

class _ExpandableTextContainerState extends State<ExpandableTextContainer> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Input validation: handle empty strings
    if (widget.text.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No content available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: widget.colorScheme.onSurface.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Input validation: truncate extremely long strings for performance
    final safeText = widget.text.length > widget.maxAllowedLength
        ? '${widget.text.substring(0, widget.maxAllowedLength)}... [Content truncated due to length]'
        : widget.text;

    final shouldTruncate = safeText.length > widget.maxCharacters;
    final displayText = shouldTruncate && !_isExpanded
        ? '${safeText.substring(0, widget.maxCharacters)}...'
        : safeText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            displayText,
            style: widget.showAsPlaceholder
                ? TextStyle(color: widget.colorScheme.onSurfaceVariant)
                : null,
          ),
          if (shouldTruncate) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Read less' : 'Read more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: widget.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
