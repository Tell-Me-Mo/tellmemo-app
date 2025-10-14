import 'package:flutter/material.dart';
import '../../core/utils/screen_info.dart';

/// Base widget for item detail panels with tab structure
/// Provides a consistent right-side panel UI with Main view and Updates/Comments tabs
class ItemDetailPanel extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData headerIcon;
  final Color headerIconColor;
  final VoidCallback onClose;
  final Widget mainViewContent;
  final Widget updatesContent;
  final List<Widget>? headerActions;
  final double rightOffset;
  final bool initiallyShowUpdates;

  const ItemDetailPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.headerIcon,
    required this.headerIconColor,
    required this.onClose,
    required this.mainViewContent,
    required this.updatesContent,
    this.headerActions,
    this.rightOffset = 0.0,
    this.initiallyShowUpdates = false,
  });

  @override
  State<ItemDetailPanel> createState() => _ItemDetailPanelState();
}

class _ItemDetailPanelState extends State<ItemDetailPanel>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initiallyShowUpdates ? 1 : 0,
    );

    // Listen to tab changes to update the segmented control UI
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  /// Helper method to add consistent spacing between action items
  /// Skips adding spacing if the action is already a SizedBox or Container (divider)
  List<Widget> _buildSpacedActions(List<Widget> actions) {
    final spacedActions = <Widget>[];
    for (int i = 0; i < actions.length; i++) {
      final currentAction = actions[i];
      spacedActions.add(currentAction);

      // Add spacing after each action except the last one
      // Skip if current action is already a spacer or divider
      if (i < actions.length - 1 &&
          currentAction is! SizedBox &&
          currentAction is! Container) {
        spacedActions.add(const SizedBox(width: 4));
      }
    }
    return spacedActions;
  }

  /// Builds a single segmented tab button
  Widget _buildSegmentedTab({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenInfo = ScreenInfo.fromContext(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final panelWidth = screenInfo.isMobile
        ? MediaQuery.of(context).size.width
        : MediaQuery.of(context).size.width * 0.45;
    final maxWidth = 600.0;
    final actualWidth = panelWidth > maxWidth ? maxWidth : panelWidth;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Backdrop
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return _animationController.value > 0
                  ? GestureDetector(
                      onTap: _handleClose,
                      child: Container(
                        color: Colors.black
                            .withValues(alpha: 0.5 * _animationController.value),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          // Panel
          Positioned(
            right: widget.rightOffset,
            top: 0,
            bottom: screenInfo.isMobile ? keyboardHeight : 0,
            width: actualWidth,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(-8, 0),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 16,
                        top: MediaQuery.of(context).padding.top + 20,
                        bottom: 0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Title Row
                          Row(
                            children: [
                              // Icon with refined styling
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: widget.headerIconColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: widget.headerIconColor
                                        .withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  widget.headerIcon,
                                  size: 20,
                                  color: widget.headerIconColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Title and Subtitle with improved typography
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.subtitle,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Header Actions with proper spacing
                              if (widget.headerActions != null) ...[
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _buildSpacedActions(widget.headerActions!),
                                ),
                              ],
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: _handleClose,
                                tooltip: 'Close',
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(40, 40),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          // Segmented Control Tabs
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildSegmentedTab(
                                      context: context,
                                      icon: Icons.info_outline,
                                      label: 'Overview',
                                      isSelected: _tabController.index == 0,
                                      onTap: () {
                                        setState(() {
                                          _tabController.animateTo(0);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: _buildSegmentedTab(
                                      context: context,
                                      icon: Icons.comment_outlined,
                                      label: 'Updates',
                                      isSelected: _tabController.index == 1,
                                      onTap: () {
                                        setState(() {
                                          _tabController.animateTo(1);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          widget.mainViewContent,
                          widget.updatesContent,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
