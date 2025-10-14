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
                        right: 20,
                        top: MediaQuery.of(context).padding.top + 20,
                        bottom: 0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Title Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: widget.headerIconColor
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  widget.headerIcon,
                                  size: 22,
                                  color: widget.headerIconColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.subtitle,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Header Actions
                              if (widget.headerActions != null)
                                ...widget.headerActions!,
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _handleClose,
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                          // Tab Bar
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: TabBar(
                              controller: _tabController,
                              tabs: const [
                                Tab(
                                  icon: Icon(Icons.info_outline, size: 18),
                                  text: 'Main',
                                  height: 48,
                                ),
                                Tab(
                                  icon: Icon(Icons.comment_outlined, size: 18),
                                  text: 'Updates',
                                  height: 48,
                                ),
                              ],
                              labelColor: colorScheme.primary,
                              unselectedLabelColor: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              indicatorColor: colorScheme.primary,
                              indicatorWeight: 2.5,
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              unselectedLabelStyle:
                                  theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                              dividerColor: Colors.transparent,
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
