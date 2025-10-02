import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SupportButton extends ConsumerWidget {
  const SupportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Tooltip(
      message: 'Support',
      child: IconButton(
        icon: Badge(
          isLabelVisible: false,
          child: Icon(
            Icons.help_outline,
            color: theme.colorScheme.onSurface,
          ),
        ),
        onPressed: () {
          // Navigate to support tickets screen
          context.go('/support-tickets');
        },
      ),
    );
  }
}

class SupportButtonExpanded extends ConsumerWidget {
  final bool isExpanded;

  const SupportButtonExpanded({
    super.key,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        // Navigate to support tickets screen
        context.go('/support-tickets');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isExpanded ? 12 : 8),
        child: isExpanded
            ? Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Support',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              )
            : Tooltip(
                message: 'Support',
                child: Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.onSurface,
                ),
              ),
      ),
    );
  }
}