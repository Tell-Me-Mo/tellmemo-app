import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/responsive.dart';
import '../../features/jobs/presentation/widgets/upload_progress_indicator.dart';
import '../../core/utils/screen_info.dart';
import '../../core/widgets/notifications/notification_center.dart';
import '../../features/support_tickets/presentation/widgets/support_button.dart';

class ResponsiveShell extends ConsumerStatefulWidget {
  final Widget child;
  
  const ResponsiveShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  int _selectedIndex = 0;
  
  static const List<AdaptiveDestination> _mainDestinations = [
    AdaptiveDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
      tooltip: 'Dashboard',
      route: '/dashboard',
    ),
    AdaptiveDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: 'Projects',
      tooltip: 'Projects, Programs & Portfolios',
      route: '/hierarchy',
    ),
    AdaptiveDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: 'Documents',
      tooltip: 'Documents',
      route: '/documents',
    ),
    AdaptiveDestination(
      icon: Icon(Icons.summarize_outlined),
      selectedIcon: Icon(Icons.summarize),
      label: 'Summaries',
      tooltip: 'Summaries',
      route: '/summaries',
    ),
    AdaptiveDestination(
      icon: Icon(Icons.warning_amber_outlined),
      selectedIcon: Icon(Icons.warning_amber),
      label: 'Risks',
      tooltip: 'Risk Management',
      route: '/risks',
    ),
    AdaptiveDestination(
      icon: Icon(Icons.task_alt_outlined),
      selectedIcon: Icon(Icons.task_alt),
      label: 'Tasks',
      tooltip: 'Tasks from All Projects',
      route: '/tasks',
    ),
    AdaptiveDestination(
      icon: Icon(Icons.lightbulb_outlined),
      selectedIcon: Icon(Icons.lightbulb),
      label: 'Lessons',
      tooltip: 'Lessons Learned from All Projects',
      route: '/lessons',
    ),
    AdaptiveDestination(
      icon: Icon(Icons.extension_outlined),
      selectedIcon: Icon(Icons.extension),
      label: 'Integrations',
      tooltip: 'Integrations',
      route: '/integrations',
    ),
  ];

  static const AdaptiveDestination _profileDestination = AdaptiveDestination(
    icon: Icon(Icons.person_outline),
    selectedIcon: Icon(Icons.person),
    label: 'Profile',
    tooltip: 'Profile',
    route: '/profile',
  );

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigate to the selected destination
    final route = _mainDestinations[index].route;
    if (route != null) {
      context.go(route);
    }
  }

  void _onProfileSelected() {
    setState(() {
      _selectedIndex = -1; // Special index for profile
    });
    if (_profileDestination.route != null) {
      context.go(_profileDestination.route!);
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    // Don't highlight anything when on support tickets page
    if (location.startsWith('/support-tickets')) return -2;

    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/hierarchy') || location.startsWith('/projects')) return 1;
    if (location.startsWith('/documents')) return 2;
    if (location.startsWith('/summaries')) return 3;
    if (location.startsWith('/risks')) return 4;
    if (location.startsWith('/tasks')) return 5;
    if (location.startsWith('/lessons')) return 6;
    if (location.startsWith('/integrations')) return 7;
    if (location.startsWith('/profile')) return -1; // Special index for profile

    return 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedIndex = _calculateSelectedIndex(context);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffoldWithBottomProfile(
      mainDestinations: _mainDestinations,
      profileDestination: _profileDestination,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      onProfileSelected: _onProfileSelected,
      body: GlobalUploadProgressOverlay(
        child: widget.child,
      ),
      showAppBar: false,
    );
  }
}

class AdaptiveScaffoldWithBottomProfile extends StatefulWidget {
  final Widget body;
  final String? title;
  final List<AdaptiveDestination> mainDestinations;
  final AdaptiveDestination profileDestination;
  final int selectedIndex;
  final Function(int)? onDestinationSelected;
  final Function()? onProfileSelected;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showAppBar;

  const AdaptiveScaffoldWithBottomProfile({
    super.key,
    required this.body,
    this.title,
    required this.mainDestinations,
    required this.profileDestination,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.onProfileSelected,
    this.floatingActionButton,
    this.actions,
    this.leading,
    this.showAppBar = true,
  });

  @override
  State<AdaptiveScaffoldWithBottomProfile> createState() => _AdaptiveScaffoldWithBottomProfileState();
}

class _AdaptiveScaffoldWithBottomProfileState extends State<AdaptiveScaffoldWithBottomProfile> {
  bool _isRailExtended = false;

  void _handleDestinationSelected(int index) {
    if (widget.onDestinationSelected != null) {
      widget.onDestinationSelected!(index);
    } else {
      final destination = widget.mainDestinations[index];
      if (destination.route != null) {
        context.go(destination.route!);
      }
    }
  }

  void _handleProfileSelected() {
    if (widget.onProfileSelected != null) {
      widget.onProfileSelected!();
    } else {
      if (widget.profileDestination.route != null) {
        context.go(widget.profileDestination.route!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenInfo = ScreenInfo.fromContext(context);

    if (screenInfo.isLargeScreen) {
      return _buildDesktopLayout(context, screenInfo);
    } else if (screenInfo.isTablet) {
      return _buildTabletLayout(context, screenInfo);
    } else {
      return _buildMobileLayout(context, screenInfo);
    }
  }

  Widget _buildMobileLayout(BuildContext context, ScreenInfo screenInfo) {
    // For mobile, we'll show only the 4 most important items + More menu

    // Remaining destinations go in the More menu
    final List<AdaptiveDestination> moreDestinations = [
      widget.mainDestinations[2], // Documents
      widget.mainDestinations[3], // Summaries
      widget.mainDestinations[6], // Lessons
      widget.mainDestinations[7], // Integrations
    ];

    // Map actual index to navigation bar index
    int navSelectedIndex = 4; // Default to More
    if (widget.selectedIndex == 0) {
      navSelectedIndex = 0; // Dashboard
    } else if (widget.selectedIndex == 1) {
      navSelectedIndex = 1; // Projects
    } else if (widget.selectedIndex == 5) {
      navSelectedIndex = 2; // Tasks
    } else if (widget.selectedIndex == 4) {
      navSelectedIndex = 3; // Risks
    }

    // Check if current selection is in More menu
    final isInMoreMenu = widget.selectedIndex == 2 ||
                        widget.selectedIndex == 3 ||
                        widget.selectedIndex == 6 ||
                        widget.selectedIndex == 7 ||
                        widget.selectedIndex == -1;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: widget.title != null ? Text(widget.title!) : null,
              leading: widget.leading,
              actions: [
                ...?widget.actions,
                const NotificationCenter(),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: _handleProfileSelected,
                  tooltip: 'Profile',
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            height: 80,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(
                  size: 26,
                  color: Theme.of(context).colorScheme.primary,
                );
              }
              return IconThemeData(
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              );
            }),
          ),
          textTheme: Theme.of(context).textTheme.copyWith(
            labelSmall: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navSelectedIndex,
          onDestinationSelected: (index) {
            if (index < 4) {
              // Map navigation bar index back to actual destination index
              final realIndex = index == 0 ? 0 :  // Dashboard
                               index == 1 ? 1 :  // Projects
                               index == 2 ? 5 :  // Tasks
                               4;                // Risks
              _handleDestinationSelected(realIndex);
            } else {
              // More menu
              _showMoreMenu(context, moreDestinations);
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: const Icon(Icons.folder),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: const Icon(Icons.check_circle_outline),
              selectedIcon: const Icon(Icons.check_circle),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: const Icon(Icons.warning_amber_outlined),
              selectedIcon: const Icon(Icons.warning_amber),
              label: 'Risks',
            ),
            NavigationDestination(
              icon: Icon(
                isInMoreMenu ? Icons.menu : Icons.menu_outlined,
                color: isInMoreMenu
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context, List<AdaptiveDestination> moreDestinations) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8.0),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ...moreDestinations.map((dest) {
                final destIndex = widget.mainDestinations.indexOf(dest);
                final isSelected = widget.selectedIndex == destIndex;
                return ListTile(
                  leading: isSelected
                      ? (dest.selectedIcon ?? dest.icon)
                      : dest.icon,
                  title: Text(dest.label),
                  selected: isSelected,
                  onTap: () {
                    Navigator.pop(context);
                    _handleDestinationSelected(destIndex);
                  },
                );
              }),
              const Divider(),
              ListTile(
                leading: widget.selectedIndex == -1
                    ? (widget.profileDestination.selectedIcon ?? widget.profileDestination.icon)
                    : widget.profileDestination.icon,
                title: Text(widget.profileDestination.label),
                selected: widget.selectedIndex == -1,
                onTap: () {
                  Navigator.pop(context);
                  _handleProfileSelected();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context, ScreenInfo screenInfo) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: widget.title != null ? Text(widget.title!) : null,
              leading: widget.leading,
              actions: widget.actions,
            )
          : null,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: widget.selectedIndex >= 0 && widget.selectedIndex < widget.mainDestinations.length
                ? widget.selectedIndex
                : null,
            onDestinationSelected: _handleDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: widget.mainDestinations
                .map((dest) => NavigationRailDestination(
                      icon: dest.icon,
                      selectedIcon: dest.selectedIcon ?? dest.icon,
                      label: Text(dest.label),
                    ))
                .toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(),
                      // Notification Center
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: const NotificationCenter(),
                      ),
                      // Support Button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: const SupportButtonExpanded(),
                      ),
                      InkWell(
                        onTap: _handleProfileSelected,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: widget.selectedIndex == -1
                                ? Theme.of(context).colorScheme.secondaryContainer
                                : Colors.transparent,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              widget.selectedIndex == -1
                                  ? (widget.profileDestination.selectedIcon ?? widget.profileDestination.icon)
                                  : widget.profileDestination.icon,
                              const SizedBox(height: 4),
                              Text(
                                widget.profileDestination.label,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: widget.selectedIndex == -1
                                      ? Theme.of(context).colorScheme.onSecondaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.body),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ScreenInfo screenInfo) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: widget.selectedIndex >= 0 && widget.selectedIndex < widget.mainDestinations.length
                ? widget.selectedIndex
                : null,
            onDestinationSelected: _handleDestinationSelected,
            extended: _isRailExtended,
            labelType: _isRailExtended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: IconButton(
                icon: Icon(_isRailExtended ? Icons.menu_open : Icons.menu),
                onPressed: () {
                  setState(() {
                    _isRailExtended = !_isRailExtended;
                  });
                },
              ),
            ),
            destinations: widget.mainDestinations
                .map((dest) => NavigationRailDestination(
                      icon: dest.icon,
                      selectedIcon: dest.selectedIcon ?? dest.icon,
                      label: Text(dest.label),
                    ))
                .toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(),
                      // Notification Center
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: const NotificationCenter(),
                      ),
                      // Support Button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SupportButtonExpanded(isExpanded: _isRailExtended),
                      ),
                      InkWell(
                        onTap: _handleProfileSelected,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(_isRailExtended ? 12 : 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: widget.selectedIndex == -1
                                ? Theme.of(context).colorScheme.secondaryContainer
                                : Colors.transparent,
                          ),
                          child: _isRailExtended
                              ? Row(
                                  children: [
                                    widget.selectedIndex == -1
                                        ? (widget.profileDestination.selectedIcon ?? widget.profileDestination.icon)
                                        : widget.profileDestination.icon,
                                    const SizedBox(width: 12),
                                    Text(
                                      widget.profileDestination.label,
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: widget.selectedIndex == -1
                                            ? Theme.of(context).colorScheme.onSecondaryContainer
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    widget.selectedIndex == -1
                                        ? (widget.profileDestination.selectedIcon ?? widget.profileDestination.icon)
                                        : widget.profileDestination.icon,
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.profileDestination.label,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: widget.selectedIndex == -1
                                            ? Theme.of(context).colorScheme.onSecondaryContainer
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Scaffold(
              appBar: widget.showAppBar
                  ? AppBar(
                      title: widget.title != null ? Text(widget.title!) : null,
                      actions: widget.actions,
                      automaticallyImplyLeading: false,
                    )
                  : null,
              body: widget.body,
              floatingActionButton: widget.floatingActionButton,
            ),
          ),
        ],
      ),
    );
  }
}