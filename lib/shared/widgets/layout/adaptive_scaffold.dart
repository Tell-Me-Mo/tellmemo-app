import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/screen_info.dart';

class AdaptiveScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final Function(int)? onDestinationSelected;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showAppBar;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.title,
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.floatingActionButton,
    this.actions,
    this.leading,
    this.showAppBar = true,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  bool _isRailExtended = false;

  void _handleDestinationSelected(int index) {
    if (widget.onDestinationSelected != null) {
      widget.onDestinationSelected!(index);
    } else {
      final destination = widget.destinations[index];
      if (destination.route != null) {
        context.go(destination.route!);
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
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: widget.title != null ? Text(widget.title!) : null,
              leading: widget.leading,
              actions: widget.actions,
            )
          : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: _handleDestinationSelected,
        destinations: widget.destinations
            .map((dest) => NavigationDestination(
                  icon: dest.icon,
                  selectedIcon: dest.selectedIcon ?? dest.icon,
                  label: dest.label,
                  tooltip: dest.tooltip,
                ))
            .toList(),
      ),
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
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: _handleDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: widget.destinations
                .map((dest) => NavigationRailDestination(
                      icon: dest.icon,
                      selectedIcon: dest.selectedIcon ?? dest.icon,
                      label: Text(dest.label),
                    ))
                .toList(),
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
            selectedIndex: widget.selectedIndex,
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
            destinations: widget.destinations
                .map((dest) => NavigationRailDestination(
                      icon: dest.icon,
                      selectedIcon: dest.selectedIcon ?? dest.icon,
                      label: Text(dest.label),
                    ))
                .toList(),
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

class AdaptiveDestination {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? tooltip;
  final String? route;

  const AdaptiveDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.route,
  });
}