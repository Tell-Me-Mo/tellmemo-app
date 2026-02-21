import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/organizations/presentation/providers/demo_data_provider.dart';

class DemoDataBanner extends ConsumerWidget {
  const DemoDataBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoDataAsync = ref.watch(demoDataProvider);

    return demoDataAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (hasDemoData) {
        if (!hasDemoData) return const SizedBox.shrink();
        return _DemoBannerContent();
      },
    );
  }
}

class _DemoBannerContent extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DemoBannerContent> createState() => _DemoBannerContentState();
}

class _DemoBannerContentState extends ConsumerState<_DemoBannerContent> {
  bool _isClearing = false;

  Future<void> _handleClearDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Demo Data'),
        content: const Text(
          'This will permanently remove all demo data from your organization. '
          'Your own data will not be affected. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Demo Data'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClearing = true);

    try {
      await ref.read(demoDataProvider.notifier).clearDemoData();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear demo data. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    return Material(
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: 8,
        ),
        child: Row(
          children: [
            Icon(
              Icons.science_outlined,
              size: 20,
              color: colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSmallScreen
                    ? 'Viewing demo data. Clear when ready.'
                    : "You're viewing demo data. Explore the app, then clear it when you're ready.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isClearing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  )
                : TextButton(
                    onPressed: _handleClearDemoData,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onTertiaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Clear Demo Data'),
                  ),
          ],
        ),
      ),
    );
  }
}
