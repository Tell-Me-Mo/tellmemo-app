import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../widgets/backend_error_dialog.dart';

/// Global error handler provider
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler(ref);
});

class ErrorHandler {
  final Ref ref;

  ErrorHandler(this.ref);

  /// Handle an error and show appropriate UI feedback
  /// Returns true if the error was handled, false if it should be rethrown
  Future<bool> handleError({
    required BuildContext context,
    required Object error,
    StackTrace? stackTrace,
    Future<void> Function()? onRetry,
    bool showDialog = true,
  }) async {
    // Check if it's a DioException
    if (error is DioException) {
      final statusCode = error.response?.statusCode;

      // Special handling for auth errors
      if (statusCode == 401 || statusCode == 403) {
        // Let auth handlers deal with this
        return false;
      }

      // For other errors, show dialog if requested
      if (showDialog && context.mounted) {
        BackendErrorDialog.show(
          context: context,
          error: error,
          onRetry: onRetry != null
              ? () async {
                  try {
                    await onRetry();
                  } catch (retryError) {
                    if (context.mounted) {
                      // If retry fails, show error again
                      handleError(
                        context: context,
                        error: retryError,
                        onRetry: onRetry,
                        showDialog: true,
                      );
                    }
                  }
                }
              : null,
        );
        return true;
      }
    }

    // For non-Dio errors, show generic error dialog if requested
    if (showDialog && context.mounted) {
      BackendErrorDialog.show(
        context: context,
        error: error,
        onRetry: onRetry != null
            ? () async {
                try {
                  await onRetry();
                } catch (retryError) {
                  if (context.mounted) {
                    handleError(
                      context: context,
                      error: retryError,
                      onRetry: onRetry,
                      showDialog: true,
                    );
                  }
                }
              }
            : null,
      );
      return true;
    }

    return false;
  }

  /// Execute an async operation with automatic error handling
  Future<T?> executeWithErrorHandling<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    bool showDialog = true,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;

    Future<T?> attemptOperation() async {
      try {
        return await operation();
      } catch (error, stackTrace) {
        if (error is DioException) {
          final statusCode = error.response?.statusCode;

          // Don't retry on client errors (4xx) except for specific cases
          if (statusCode != null && statusCode >= 400 && statusCode < 500) {
            // Only retry on 429 (rate limit) or 408 (timeout)
            if (statusCode != 429 && statusCode != 408) {
              if (context.mounted) {
                await handleError(
                  context: context,
                  error: error,
                  stackTrace: stackTrace,
                  showDialog: showDialog,
                );
              }
              return null;
            }
          }

          // For server errors or network issues, retry
          if (retryCount < maxRetries) {
            retryCount++;

            // Exponential backoff
            await Future.delayed(Duration(seconds: retryCount * 2));

            return attemptOperation();
          }
        }

        // Max retries reached or non-retryable error
        if (context.mounted) {
          await handleError(
            context: context,
            error: error,
            stackTrace: stackTrace,
            onRetry: () async {
              retryCount = 0;
              await attemptOperation();
            },
            showDialog: showDialog,
          );
        }
        return null;
      }
    }

    return attemptOperation();
  }
}

/// Extension to easily access error handler from BuildContext
extension ErrorHandlerExtension on BuildContext {
  ErrorHandler get errorHandler {
    return ProviderScope.containerOf(this).read(errorHandlerProvider);
  }
}