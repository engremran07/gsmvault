import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/providers/shared_install_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class TechShell extends ConsumerStatefulWidget {
  const TechShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TechShell> createState() => _TechShellState();
}

class _TechShellState extends ConsumerState<TechShell> {
  final _drawerController = ZoomDrawerController();

  @override
  void dispose() {
    super.dispose();
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/tech/submit')) return 1;
    if (location.startsWith('/tech/inout')) return 2;
    if (location.startsWith('/tech/summary')) return 2;
    if (location.startsWith('/tech/history')) return 3;
    if (location.startsWith('/tech/reports')) return 4;
    if (location.startsWith('/tech/settings')) return -1;
    if (location.startsWith('/tech/profile')) return -1;
    if (location.startsWith('/tech/settlements')) return -1;
    if (location.startsWith('/tech/job/')) return -1;
    if (location.startsWith('/tech/jobs/filter/')) return -1;
    if (location.startsWith('/tech/ac-installs')) return -1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final pendingSettlementBatches = ref
        .watch(technicianSettlementInboxProvider)
        .maybeWhen(
          data: (jobs) => jobs
              .map((job) => job.settlementBatchId.trim())
              .where((id) => id.isNotEmpty)
              .toSet()
              .length,
          orElse: () => 0,
        );
    final sharedTeamsCount = ref
        .watch(pendingSharedInstallAggregatesProvider)
        .maybeWhen(data: (aggs) => aggs.length, orElse: () => 0);
    final isHome = _currentIndex(context) == 0;
    return ZoomDrawerWrapper(
      controller: _drawerController,
      menuScreen: const DrawerMenuContent(isAdmin: false),
      mainScreen: ShellBackNavigationScope(
        isHome: isHome,
        homeRoute: '/tech',
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
              selectedIndex: _currentIndex(context) < 0
                  ? 0
                  : _currentIndex(context),
              onDestinationSelected: (index) {
                final current = _currentIndex(context);
                if (current == index) {
                  HapticFeedback.selectionClick();
                  return;
                }
                switch (index) {
                  case 0:
                    context.go('/tech');
                  case 1:
                    context.go('/tech/submit');
                  case 2:
                    context.go('/tech/inout');
                  case 3:
                    context.go('/tech/history');
                  case 4:
                    context.go('/tech/reports');
                }
              },
              destinations: [
                NavigationDestination(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.dashboard_outlined),
                      if (sharedTeamsCount > 0)
                        Positioned(
                          right: -2,
                          top: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  selectedIcon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.dashboard_rounded),
                      if (sharedTeamsCount > 0)
                        Positioned(
                          right: -2,
                          top: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: AppLocalizations.of(context)!.home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  selectedIcon: const Icon(Icons.add_circle_rounded),
                  label: AppLocalizations.of(context)!.submit,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.swap_vert_outlined),
                  selectedIcon: const Icon(Icons.swap_vert_rounded),
                  label: AppLocalizations.of(context)!.inOut,
                ),
                NavigationDestination(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.history_outlined),
                      if (pendingSettlementBatches > 0)
                        Positioned(
                          right: -2,
                          top: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  selectedIcon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.history_rounded),
                      if (pendingSettlementBatches > 0)
                        Positioned(
                          right: -2,
                          top: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: AppLocalizations.of(context)!.history,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.summarize_outlined),
                  selectedIcon: const Icon(Icons.summarize_rounded),
                  label: AppLocalizations.of(context)!.reports,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
