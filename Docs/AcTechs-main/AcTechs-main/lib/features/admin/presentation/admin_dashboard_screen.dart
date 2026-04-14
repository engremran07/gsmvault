import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/responsive.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void refresh() {
    ref.invalidate(adminJobSummaryProvider);
    ref.invalidate(pendingApprovalsProvider);
    ref.invalidate(allTechniciansProvider);
    ref.invalidate(allCompaniesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).value;
    final adminSummary = ref.watch(adminJobSummaryProvider);
    final pending = ref.watch(pendingApprovalsProvider);
    final technicians = ref.watch(allTechniciansProvider);
    final companies = ref.watch(allCompaniesProvider);

    return AppShortcuts(
      onRefresh: refresh,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => ZoomDrawerScope.of(context).toggle(),
          ),
          title: Text(l.adminPanel),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => context.push('/admin/settings'),
            ),
          ],
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ArcticRefreshIndicator(
              onRefresh: () async => refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    l.welcomeBack,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    user?.name ?? l.admin,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards
                  adminSummary.when(
                    data: (summary) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _DashCard(
                                  title: l.totalJobs,
                                  value: '${summary.totalJobs}',
                                  icon: Icons.work_outline,
                                  color: ArcticTheme.arcticBlue,
                                  onTap: () => context.go('/admin/approvals'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DashCard(
                                  title: l.pending,
                                  value: '${summary.pendingJobs}',
                                  icon: Icons.pending_outlined,
                                  color: ArcticTheme.arcticPending,
                                  onTap: () => context.go('/admin/approvals'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DashCard(
                                  title: l.approved,
                                  value: '${summary.approvedJobs}',
                                  icon: Icons.check_circle_outline,
                                  color: ArcticTheme.arcticSuccess,
                                  onTap: () => context.go('/admin/approvals'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DashCard(
                                  title: l.expenses,
                                  value: AppFormatters.currency(
                                    summary.totalExpenses,
                                  ),
                                  icon: Icons.payments_outlined,
                                  color: ArcticTheme.arcticWarning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DashCard(
                                  title: l.splits,
                                  value: '${summary.splitUnits}',
                                  icon: Icons.ac_unit_rounded,
                                  color: ArcticTheme.arcticBlue,
                                  onTap: () => context.push(
                                    '/admin/jobs/filter/${jobAcTypeFilterToPath(JobAcTypeFilter.split)}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DashCard(
                                  title: l.windowAc,
                                  value: '${summary.windowUnits}',
                                  icon: Icons.window_rounded,
                                  color: ArcticTheme.arcticSuccess,
                                  onTap: () => context.push(
                                    '/admin/jobs/filter/${jobAcTypeFilterToPath(JobAcTypeFilter.window)}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DashCard(
                                  title: l.standing,
                                  value: '${summary.freestandingUnits}',
                                  icon: Icons.kitchen_rounded,
                                  color: ArcticTheme.arcticWarning,
                                  onTap: () => context.push(
                                    '/admin/jobs/filter/${jobAcTypeFilterToPath(JobAcTypeFilter.freestanding)}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const ArcticShimmer(height: 90, count: 2),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // Team Summary
                  technicians.when(
                    data: (techs) {
                      final active = techs.where((t) => t.isActive).length;
                      return Column(
                        children: [
                          _DashCard(
                            title: l.team,
                            value: l.activeOfTotal(active, techs.length),
                            icon: Icons.people_outline,
                            color: ArcticTheme.arcticBlue,
                            onTap: () => context.go('/admin/team'),
                          ),
                          const SizedBox(height: 12),
                          companies.when(
                            data: (items) => _DashCard(
                              title: l.companies,
                              value: '${items.where((c) => c.isActive).length}',
                              icon: Icons.apartment_rounded,
                              color: ArcticTheme.arcticWarning,
                              onTap: () => context.push('/admin/companies'),
                            ),
                            loading: () =>
                                const ArcticShimmer(height: 70, count: 1),
                            error: (e, _) => const SizedBox.shrink(),
                          ),
                        ],
                      );
                    },
                    loading: () => const ArcticShimmer(height: 70, count: 1),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // Recent Pending
                  Text(
                    l.recentPending,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  pending.when(
                    data: (jobs) {
                      if (jobs.isEmpty) {
                        return ArcticCard(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                l.noApprovals,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: jobs
                            .take(5)
                            .map(
                              (job) => ArcticCard(
                                onTap: () => context.go('/admin/approvals'),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job.clientName,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                          ),
                                          Text(
                                            '${job.techName} • ${job.invoiceNumber}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const StatusBadge(status: 'pending'),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const ArcticShimmer(count: 3),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 156;
        final iconBoxSize = isCompact ? 38.0 : 44.0;
        final iconSize = isCompact ? 18.0 : 22.0;
        final gap = isCompact ? 8.0 : 12.0;

        return ArcticCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      alignment: AlignmentDirectional.centerStart,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: color,
                              fontSize: Responsive.scaledFontSize(
                                context,
                                isCompact ? 15 : 16,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: isCompact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onTap != null && !isCompact)
                const Icon(
                  Icons.chevron_right,
                  color: ArcticTheme.arcticTextSecondary,
                ),
            ],
          ),
        );
      },
    );
  }
}
