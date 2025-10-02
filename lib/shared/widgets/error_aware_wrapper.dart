import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/error_handler_provider.dart';

/// A wrapper widget that listens for async errors from providers
/// and shows appropriate error dialogs using the global error handler
class ErrorAwareWrapper extends ConsumerWidget {
  final Widget child;
  final List<ProviderListenable<AsyncValue>> providers;
  final bool showErrorDialogs;
  final VoidCallback? onRetry;

  const ErrorAwareWrapper({
    super.key,
    required this.child,
    required this.providers,
    this.showErrorDialogs = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to each provider for errors
    for (final provider in providers) {
      ref.listen(provider, (previous, next) {
        if (next.hasError && showErrorDialogs) {
          // Use post-frame callback to ensure context is still valid
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.errorHandler.handleError(
                context: context,
                error: next.error!,
                stackTrace: next.stackTrace,
                onRetry: onRetry != null
                    ? () async {
                        onRetry!();
                      }
                    : null,
              );
            }
          });
        }
      });
    }

    return child;
  }
}

/// Example usage in a screen:
///
/// ErrorAwareWrapper(
///   providers: [
///     currentOrganizationProvider,
///     userOrganizationsProvider,
///   ],
///   child: YourScreenContent(),
/// )