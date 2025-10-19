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
  final int? commentCount; // Number of comments to display as badge (null or 0 = no badge)
  final bool showMobileBottomBar; // Whether to show a sticky bottom bar in mobile (for edit/create modes)

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
    this.commentCount,
    this.showMobileBottomBar = false,
  });

  @override
  State<ItemDetailPanel> createState() => _ItemDetailPanelState();
}

class _ItemDetailPanelState extends State<ItemDetailPanel>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  // Swipe gesture state
  double _dragOffset = 0.0;

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
    _tabController.addListener(_onTabChanged);

    _animationController.forward();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      if (mounted) {  // Add mounted check
        widget.onClose();
      }
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details, double panelWidth) {
    setState(() {
      // Only allow dragging to the right (positive delta)
      if (details.delta.dx > 0) {
        _dragOffset += details.delta.dx;
        // Clamp the offset to prevent dragging too far
        _dragOffset = _dragOffset.clamp(0.0, panelWidth);
      }
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details, double panelWidth) {
    final velocity = details.primaryVelocity ?? 0;
    final dismissThreshold = panelWidth * 0.3; // 30% of panel width

    if (_dragOffset > dismissThreshold || velocity > 300) {
      // Close the panel
      _handleClose();
    } else {
      // Animate back to original position
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  void _handleHorizontalDragCancel() {
    setState(() {
      _dragOffset = 0.0;
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

  /// Extracts primary actions (TextButton, FilledButton) from headerActions
  /// Used for the mobile bottom action bar
  List<Widget> _extractPrimaryActions(List<Widget> actions) {
    final primaryActions = <Widget>[];

    for (final action in actions) {
      // Include TextButton (Cancel) and FilledButton (Save/Create)
      if (action is TextButton || action is FilledButton) {
        primaryActions.add(action);
      }
    }

    return primaryActions;
  }

  /// Extracts secondary actions (IconButton, PopupMenuButton) from headerActions
  /// Used for the mobile 3-dot menu when bottom bar is shown
  List<Widget> _extractSecondaryActions(List<Widget> actions) {
    final secondaryActions = <Widget>[];

    for (final action in actions) {
      // Exclude TextButton and FilledButton (they go to bottom bar)
      if (action is! TextButton && action is! FilledButton) {
        secondaryActions.add(action);
      }
    }

    return secondaryActions;
  }

  /// Builds mobile-friendly actions menu from headerActions
  /// Converts all action widgets into a single PopupMenuButton for mobile view
  Widget _buildMobileActionsMenu(BuildContext context, List<Widget> actions) {
    final theme = Theme.of(context);

    return PopupMenuButton<VoidCallback>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Actions',
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      onSelected: (callback) => callback(),
      itemBuilder: (BuildContext context) {
        final menuItems = <PopupMenuEntry<VoidCallback>>[];

        for (int i = 0; i < actions.length; i++) {
          final action = actions[i];

          // Skip SizedBox and Container (spacers/dividers)
          if (action is SizedBox && action.width != null) continue;

          // Handle Container dividers - convert to PopupMenuDivider
          if (action is Container && action.constraints == null) {
            menuItems.add(const PopupMenuDivider());
            continue;
          }

          PopupMenuItem<VoidCallback>? menuItem;

          // Convert TextButton to menu item
          if (action is TextButton) {
            final textButton = action;
            final child = textButton.child;
            final onPressed = textButton.onPressed;

            if (child is Text && onPressed != null) {
              menuItem = PopupMenuItem<VoidCallback>(
                value: onPressed,
                child: Row(
                  children: [
                    Icon(
                      Icons.close,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(child.data ?? 'Cancel'),
                  ],
                ),
              );
            }
          }

          // Convert FilledButton to menu item
          else if (action is FilledButton) {
            final filledButton = action;
            IconData? iconData;
            String? labelText;
            VoidCallback? onPressed = filledButton.onPressed;

            // Extract icon and label from FilledButton.icon
            if (filledButton.child is Row) {
              final row = filledButton.child as Row;
              for (var child in row.children) {
                if (child is Icon) {
                  iconData = child.icon;
                } else if (child is Text) {
                  labelText = child.data;
                }
              }
            }

            if (labelText != null) {
              menuItem = PopupMenuItem<VoidCallback>(
                value: onPressed ?? () {},
                enabled: onPressed != null,
                child: Row(
                  children: [
                    Icon(
                      iconData ?? Icons.save,
                      size: 20,
                      color: onPressed != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      labelText,
                      style: TextStyle(
                        color: onPressed != null
                            ? null
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                      ),
                    ),
                  ],
                ),
              );
            }
          }

          // Convert IconButton to menu item
          else if (action is IconButton) {
            final iconButton = action;
            final icon = iconButton.icon;
            final tooltip = iconButton.tooltip ?? '';
            final onPressed = iconButton.onPressed;

            IconData? iconData;
            if (icon is Icon) {
              iconData = icon.icon;
            }

            if (iconData != null && tooltip.isNotEmpty) {
              menuItem = PopupMenuItem<VoidCallback>(
                value: onPressed ?? () {},
                enabled: onPressed != null,
                child: Row(
                  children: [
                    Icon(
                      iconData,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(tooltip),
                  ],
                ),
              );
            }
          }

          // Convert PopupMenuButton to nested menu items
          else if (action is PopupMenuButton) {
            // For nested PopupMenuButton, we extract its items
            // This handles the "More actions" menu case
            final popupButton = action as PopupMenuButton<String>;
            final items = popupButton.itemBuilder(context);

            for (var item in items) {
              if (item is PopupMenuItem<String>) {
                final popupItem = item;
                menuItems.add(
                  PopupMenuItem<VoidCallback>(
                    value: () => popupButton.onSelected?.call(popupItem.value!),
                    enabled: popupItem.enabled,
                    child: popupItem.child!,
                  ),
                );
              } else if (item is PopupMenuDivider) {
                menuItems.add(item);
              }
            }
            continue;
          }

          if (menuItem != null) {
            menuItems.add(menuItem);
          }
        }

        return menuItems;
      },
    );
  }

  /// Builds the sticky bottom action bar for mobile edit/create mode
  Widget _buildMobileBottomBar(BuildContext context, List<Widget> actions) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _buildSpacedActions(actions),
          ),
        ),
      ),
    );
  }

  /// Builds a single segmented tab button
  Widget _buildSegmentedTab({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? badgeCount, // Optional badge count
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showBadge = badgeCount != null && badgeCount > 0;

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
              if (showBadge) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayTitle(String title, bool isMobile) {
    if (!isMobile) return title;

    // In mobile view, simplify titles by removing "Create New" or "Create" prefix
    String processedTitle = title;
    if (title.startsWith('Create New ')) {
      processedTitle = title.replaceFirst('Create New ', 'New ');
    } else if (title.startsWith('Create ')) {
      processedTitle = title.replaceFirst('Create ', 'New ');
    }

    // Truncate long titles for mobile (max 70 characters for 2 lines)
    // Since we allow maxLines: 2, we can show more content before truncating
    // This allows titles to use the available vertical space efficiently
    const int maxMobileLength = 70;
    if (processedTitle.length > maxMobileLength) {
      // Find the last space before the cutoff to avoid breaking words
      int cutoff = maxMobileLength;
      int lastSpace = processedTitle.lastIndexOf(' ', maxMobileLength);
      if (lastSpace > maxMobileLength - 20) { // Only use word boundary if it's reasonable
        cutoff = lastSpace;
      }
      return '${processedTitle.substring(0, cutoff).trim()}...';
    }

    return processedTitle;
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
            child: GestureDetector(
              // Only enable horizontal drag on mobile
              onHorizontalDragUpdate: screenInfo.isMobile
                  ? (details) => _handleHorizontalDragUpdate(details, actualWidth)
                  : null,
              onHorizontalDragEnd: screenInfo.isMobile
                  ? (details) => _handleHorizontalDragEnd(details, actualWidth)
                  : null,
              onHorizontalDragCancel: screenInfo.isMobile
                  ? _handleHorizontalDragCancel
                  : null,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  // Calculate combined offset: slide animation + drag offset
                  final slideOffset = _slideAnimation.value.dx;
                  final dragOffsetNormalized = _dragOffset / actualWidth;
                  final combinedOffset = slideOffset + dragOffsetNormalized;

                  return Transform.translate(
                    offset: Offset(combinedOffset * actualWidth, 0),
                    child: child,
                  );
                },
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
                                    Tooltip(
                                      message: widget.title, // Show full title on hover/long press
                                      waitDuration: const Duration(milliseconds: 500),
                                      child: Text(
                                        _getDisplayTitle(widget.title, screenInfo.isMobile),
                                        style:
                                            theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 2, // Allow 2 lines for better mobile readability
                                        overflow: TextOverflow.ellipsis,
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
                              if (widget.headerActions != null && widget.headerActions!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                // Mobile: Show 3-dot menu (or secondary actions if bottom bar is shown), Desktop: Show all actions
                                if (screenInfo.isMobile) ...[
                                  // If bottom bar is shown, only show secondary actions in menu
                                  if (widget.showMobileBottomBar) ...[
                                    () {
                                      final secondaryActions = _extractSecondaryActions(widget.headerActions!);
                                      return secondaryActions.isNotEmpty
                                          ? _buildMobileActionsMenu(context, secondaryActions)
                                          : const SizedBox.shrink();
                                    }(),
                                  ] else
                                    _buildMobileActionsMenu(context, widget.headerActions!),
                                ] else
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
                                      badgeCount: widget.commentCount,
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
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          widget.mainViewContent,
                          widget.updatesContent,
                        ],
                      ),
                    ),
                    // Mobile Bottom Action Bar (only in edit/create mode)
                    if (screenInfo.isMobile &&
                        widget.showMobileBottomBar &&
                        widget.headerActions != null &&
                        widget.headerActions!.isNotEmpty)
                      _buildMobileBottomBar(
                        context,
                        _extractPrimaryActions(widget.headerActions!),
                      ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
