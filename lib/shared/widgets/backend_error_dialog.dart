import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class BackendErrorDialog extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const BackendErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  static void show({
    required BuildContext context,
    required Object error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackendErrorDialog(
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorDetails = _getErrorDetails();

    return AlertDialog(
      icon: Icon(
        errorDetails.icon,
        size: 48,
        color: errorDetails.iconColor,
      ),
      title: Text(
        errorDetails.title,
        style: theme.textTheme.headlineSmall,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            errorDetails.message,
            style: theme.textTheme.bodyMedium,
          ),
          if (errorDetails.details != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.errorContainer,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error Details',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorDetails.details!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onRetry != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: Text(onRetry != null ? 'Cancel' : 'OK'),
        ),
      ],
    );
  }

  _ErrorDetails _getErrorDetails() {
    if (error is DioException) {
      final dioError = error as DioException;
      final statusCode = dioError.response?.statusCode;
      final responseData = dioError.response?.data;

      // Parse error message from response
      String? apiMessage;
      if (responseData is Map<String, dynamic>) {
        apiMessage = responseData['message'] ?? responseData['error'];
      }

      switch (dioError.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return _ErrorDetails(
            icon: Icons.schedule,
            iconColor: Colors.orange,
            title: 'Connection Timeout',
            message: 'The request took too long to complete. This might be due to a slow connection or server issues.',
            details: apiMessage,
          );

        case DioExceptionType.connectionError:
          return _ErrorDetails(
            icon: Icons.wifi_off,
            iconColor: Colors.red,
            title: 'Connection Error',
            message: 'Unable to connect to the server. Please check your internet connection and try again.',
            details: dioError.message,
          );

        case DioExceptionType.cancel:
          return _ErrorDetails(
            icon: Icons.cancel,
            iconColor: Colors.grey,
            title: 'Request Cancelled',
            message: 'The operation was cancelled.',
            details: null,
          );

        case DioExceptionType.badCertificate:
          return _ErrorDetails(
            icon: Icons.security,
            iconColor: Colors.red,
            title: 'Security Error',
            message: 'There was a security issue with the connection. Please contact support.',
            details: 'Certificate validation failed',
          );

        case DioExceptionType.badResponse:
          if (statusCode != null) {
            switch (statusCode) {
              case 400:
                return _ErrorDetails(
                  icon: Icons.error_outline,
                  iconColor: Colors.orange,
                  title: 'Invalid Request',
                  message: apiMessage ?? 'The request was invalid. Please check your input and try again.',
                  details: 'Status code: $statusCode',
                );
              case 401:
                return _ErrorDetails(
                  icon: Icons.lock,
                  iconColor: Colors.orange,
                  title: 'Authentication Required',
                  message: 'Your session has expired. Please sign in again.',
                  details: null,
                );
              case 403:
                return _ErrorDetails(
                  icon: Icons.block,
                  iconColor: Colors.red,
                  title: 'Access Denied',
                  message: 'You don\'t have permission to perform this action.',
                  details: apiMessage,
                );
              case 404:
                return _ErrorDetails(
                  icon: Icons.search_off,
                  iconColor: Colors.orange,
                  title: 'Not Found',
                  message: apiMessage ?? 'The requested resource was not found.',
                  details: null,
                );
              case 409:
                return _ErrorDetails(
                  icon: Icons.warning,
                  iconColor: Colors.orange,
                  title: 'Conflict',
                  message: apiMessage ?? 'There was a conflict with the current state of the resource.',
                  details: null,
                );
              case 429:
                return _ErrorDetails(
                  icon: Icons.speed,
                  iconColor: Colors.orange,
                  title: 'Too Many Requests',
                  message: 'You\'ve made too many requests. Please wait a moment and try again.',
                  details: null,
                );
              case 500:
              case 502:
              case 503:
              case 504:
                return _ErrorDetails(
                  icon: Icons.cloud_off,
                  iconColor: Colors.red,
                  title: 'Server Error',
                  message: 'The server is experiencing issues. Please try again later.',
                  details: 'Status code: $statusCode\n${apiMessage ?? ''}',
                );
              default:
                return _ErrorDetails(
                  icon: Icons.error,
                  iconColor: Colors.red,
                  title: 'Request Failed',
                  message: apiMessage ?? 'An error occurred while processing your request.',
                  details: 'Status code: $statusCode',
                );
            }
          }
          break;

        case DioExceptionType.unknown:
          return _ErrorDetails(
            icon: Icons.error,
            iconColor: Colors.red,
            title: 'Unexpected Error',
            message: dioError.message ?? 'An unexpected error occurred. Please try again.',
            details: apiMessage,
          );
      }
    }

    // Handle non-Dio errors
    return _ErrorDetails(
      icon: Icons.error_outline,
      iconColor: Colors.red,
      title: 'Error',
      message: error.toString(),
      details: null,
    );
  }
}

class _ErrorDetails {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? details;

  const _ErrorDetails({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.details,
  });
}