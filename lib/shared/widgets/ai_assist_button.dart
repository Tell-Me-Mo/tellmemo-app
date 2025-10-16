import 'package:flutter/material.dart';

/// A reusable AI assist button widget that displays a green sparkle icon
/// and triggers an AI field assist dialog when pressed.
///
/// This button is typically used next to field labels in detail panels
/// to provide AI-powered insights about specific field content.
class AIAssistButton extends StatelessWidget {
  /// The callback function to invoke when the button is pressed
  final VoidCallback onPressed;

  /// Optional tooltip text (defaults to 'Ask AI for more information')
  final String? tooltip;

  /// Optional icon size (defaults to 16)
  final double iconSize;

  /// Optional accent color (defaults to green shade 400)
  final Color? accentColor;

  const AIAssistButton({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.iconSize = 16,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = theme.colorScheme.primary;
    final effectiveAccentColor = accentColor ?? defaultColor;

    return IconButton(
      icon: Icon(
        Icons.auto_awesome,
        size: iconSize,
        color: effectiveAccentColor,
      ),
      onPressed: onPressed,
      tooltip: tooltip ?? 'Ask AI for more information',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
      style: IconButton.styleFrom(
        backgroundColor: effectiveAccentColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
