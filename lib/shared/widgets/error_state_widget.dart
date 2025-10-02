import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final bool isFullScreen;

  const ErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Check if it's a connection error
    final isConnectionError = _isConnectionError(error);

    final errorContent = Container(
      padding: EdgeInsets.all(isFullScreen ? 48 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: isFullScreen ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Error Icon with animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isConnectionError
                      ? colorScheme.warning.withValues(alpha: 0.1)
                      : colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isConnectionError
                      ? Icons.signal_wifi_off_rounded
                      : Icons.error_outline_rounded,
                    size: 40,
                    color: isConnectionError
                      ? colorScheme.warning
                      : colorScheme.error,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Error Title
          Text(
            isConnectionError
              ? 'Service Unavailable'
              : 'Something went wrong',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Error Description
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              isConnectionError
                ? 'Please check your connection and try again.'
                : _getReadableError(error),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onRetry != null) ...[
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        body: Center(child: errorContent),
      );
    }

    return errorContent;
  }


  bool _isConnectionError(String error) {
    final lowerError = error.toLowerCase();
    return lowerError.contains('connection') ||
           lowerError.contains('xmlhttprequest') ||
           lowerError.contains('network') ||
           lowerError.contains('failed to connect') ||
           lowerError.contains('socket') ||
           lowerError.contains('dio') ||
           lowerError.contains('timeout');
  }

  String _getReadableError(String error) {
    // Clean up technical error messages
    if (error.contains('XMLHttpRequest')) {
      return 'Unable to connect to the server. Please check your connection and try again.';
    }

    if (error.contains('timeout')) {
      return 'The request took too long to complete. Please try again.';
    }

    if (error.contains('404')) {
      return 'The requested resource was not found.';
    }

    if (error.contains('403') || error.contains('401')) {
      return 'You don\'t have permission to access this resource.';
    }

    if (error.contains('500')) {
      return 'The server encountered an error. Please try again later.';
    }

    // If it's already a clean message, return as-is
    if (error.length < 100 && !error.contains('Exception')) {
      return error;
    }

    // Default fallback
    return 'An unexpected error occurred. Please try again or contact support if the issue persists.';
  }
}

// Extension for Material 3 colors
extension ColorSchemeExtension on ColorScheme {
  Color get warning => Colors.orange;
}