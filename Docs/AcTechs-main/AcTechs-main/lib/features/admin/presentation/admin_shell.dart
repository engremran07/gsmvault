import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _drawerController = ZoomDrawerController();

  @override
  void dispose() {
    super.dispose();
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/approvals')) return 1;
    if (location.startsWith('/admin/analytics')) return 2;
    if (location.startsWith('/admin/team')) return 3;
    if (location.startsWith('/admin/settlements')) return -1;
    if (location.startsWith('/admin/import')) return -1;
    if (location.startsWith('/admin/jobs/filter/')) return -1;
    if (location.startsWith('/admin/job/')) return -1;
    if (location.startsWith('/admin/companies')) {
      return -1; // accessed from dashboard card
    }
    if (location.startsWith('/admin/settings')) return -1; // Not in bottom nav
    if (location.startsWith('/admin/flush')) return -1; // Not in bottom nav
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final isHome = idx == 0;
    return ZoomDrawerWrapper(
      controller: _drawerController,
      menuScreen: const DrawerMenuContent(isAdmin: true),
      mainScreen: ShellBackNavigationScope(
        isHome: isHome,
        homeRoute: '/admin',
        child: Scaffold(
          body: widget.child,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: idx < 0 ? 0 : idx,
              onDestinationSelected: (index) {
                final current = idx;
                if (current == index) {
                  HapticFeedback.selectionClick();
                  return;
                }
                switch (index) {
                  case 0:
                    context.go('/admin');
                  case 1:
                    context.go('/admin/approvals');
                  case 2:
                    context.go('/admin/analytics');
                  case 3:
                    context.go('/admin/team');
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard_rounded),
                  label: AppLocalizations.of(context)!.dashboard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.pending_actions_outlined),
                  selectedIcon: const Icon(Icons.pending_actions_rounded),
                  label: AppLocalizations.of(context)!.approvals,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.analytics_outlined),
                  selectedIcon: const Icon(Icons.analytics_rounded),
                  label: AppLocalizations.of(context)!.analytics,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_outline_rounded),
                  selectedIcon: const Icon(Icons.people_rounded),
                  label: AppLocalizations.of(context)!.team,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
