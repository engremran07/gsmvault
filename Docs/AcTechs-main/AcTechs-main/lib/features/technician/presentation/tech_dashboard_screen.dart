import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/providers/shared_install_providers.dart';

class TechDashboardScreen extends ConsumerStatefulWidget {
  const TechDashboardScreen({super.key});

  @override
  ConsumerState<TechDashboardScreen> createState() =>
      _TechDashboardScreenState();
}

class _TechDashboardScreenState extends ConsumerState<TechDashboardScreen>
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

  void _refresh() {
    HapticFeedback.lightImpact();
    ref.invalidate(todaysJobsProvider);
    ref.invalidate(technicianJobsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).value;
    final todaysJobs = ref.watch(todaysJobsProvider);
    final jobSummary = ref.watch(technicianJobSummaryProvider);
    final settlementInbox = ref.watch(technicianSettlementInboxProvider);
    final sharedAggregates = ref.watch(pendingSharedInstallAggregatesProvider);

    return AppShortcuts(
      onRefresh: _refresh,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => ZoomDrawerScope.of(context).toggle(),
          ),
          title: Text(l.appName),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ArcticRefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                // Extra bottom padding ensures the last card clears the FAB
                // (FAB height 56 + 16 margin + 16 content gap = 88).
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 88),
                children: [
                  // Welcome
                  Text(
                    l.welcomeBack,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    user?.name ?? l.technician,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  jobSummary.when(
                    data: (summary) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: l.totalJobs,
                                  value: '${summary.totalJobs}',
                                  icon: Icons.work_outline_rounded,
                                  color: ArcticTheme.arcticBlue,
                                  onTap: () => context.go('/tech/history'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: l.pending,
                                  value: '${summary.pendingJobs}',
                                  icon: Icons.pending_outlined,
                                  color: ArcticTheme.arcticPending,
                                  onTap: () => context.go('/tech/history'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: l.approved,
                                  value: '${summary.approvedJobs}',
                                  icon: Icons.check_circle_outline,
                                  color: ArcticTheme.arcticSuccess,
                                  onTap: () => context.go('/tech/history'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // ── AC Type Breakdown ──
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: l.splits,
                                  value: '${summary.splitUnits}',
                                  icon: Icons.ac_unit_rounded,
                                  color: ArcticTheme.arcticBlue,
                                  onTap: () => context.push(
                                    '/tech/jobs/filter/${jobAcTypeFilterToPath(JobAcTypeFilter.split)}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  title: l.windowAc,
                                  value: '${summary.windowUnits}',
                                  icon: Icons.window_rounded,
                                  color: ArcticTheme.arcticSuccess,
                                  onTap: () => context.push(
                                    '/tech/jobs/filter/${jobAcTypeFilterToPath(JobAcTypeFilter.window)}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  title: l.standing,
                                  value: '${summary.freestandingUnits}',
                                  icon: Icons.kitchen_rounded,
                                  color: ArcticTheme.arcticWarning,
                                  onTap: () => context.push(
                                    '/tech/jobs/filter/${jobAcTypeFilterToPath(JobAcTypeFilter.freestanding)}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: l.acOutdoorBracket,
                                  value: '${summary.bracketCount}',
                                  icon: Icons.hardware_outlined,
                                  color: ArcticTheme.arcticPurple,
                                  onTap: () => context.push(
                                    '/tech/jobs/filter/${jobAcTypeFilterToPath(JobAcTypeFilter.bracket)}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  title: l.uninstalls,
                                  value: '${summary.uninstallTotal}',
                                  icon: Icons.build_circle_outlined,
                                  color: ArcticTheme.arcticError,
                                  onTap: () => context.push(
                                    '/tech/jobs/filter/${jobAcTypeFilterToPath(JobAcTypeFilter.uninstall)}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatCard(
                                  title: l.rejected,
                                  value: '${summary.rejectedJobs}',
                                  icon: Icons.cancel_outlined,
                                  color: ArcticTheme.arcticError,
                                  onTap: () => context.go('/tech/history'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const ArcticShimmer(height: 90, count: 1),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  settlementInbox.when(
                    data: (items) {
                      final batchCount = items
                          .map((job) => job.settlementBatchId.trim())
                          .where((id) => id.isNotEmpty)
                          .toSet()
                          .length;
                      if (batchCount == 0) return const SizedBox.shrink();
                      return ArcticCard(
                        onTap: () => context.push('/tech/settlements'),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: ArcticTheme.arcticSuccess.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payments_outlined,
                                color: ArcticTheme.arcticSuccess,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.paymentInbox,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  Text(
                                    '$batchCount ${l.settlementBatch}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: ArcticTheme.arcticTextSecondary,
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // Pending Shared Installs
                  sharedAggregates.when(
                    data: (aggregates) {
                      if (aggregates.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.pendingSharedInstalls,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    Text(
                                      l.tapToAddYourShare,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: ArcticTheme.arcticWarning,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ArcticTheme.arcticWarning.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${aggregates.length}',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: ArcticTheme.arcticWarning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...aggregates.map(
                            (agg) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ArcticCard(
                                onTap: () =>
                                    context.go('/tech/submit', extra: agg),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: ArcticTheme.arcticWarning
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.group_work_outlined,
                                        color: ArcticTheme.arcticWarning,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            agg.invoiceNumber.isNotEmpty
                                                ? agg.invoiceNumber
                                                : agg.groupKey,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            l.teamJobPending,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      ArcticTheme.arcticWarning,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: ArcticTheme.arcticWarning,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),

                  // Today's Jobs
                  Text(
                    l.todaysJobs,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  todaysJobs.when(
                    data: (jobs) {
                      if (jobs.isEmpty) {
                        return ArcticCard(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.work_off_outlined,
                                    size: 48,
                                    color: ArcticTheme.arcticTextSecondary
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l.noJobsToday,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => context.go('/tech/submit'),
                                    icon: const Icon(Icons.add_rounded),
                                    label: Text(
                                      l.submitAJob,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: jobs
                            .map(
                              (job) => ContextMenuRegion(
                                menuItems: [
                                  ContextMenuItem(
                                    id: 'copy_invoice',
                                    label: l.copyInvoice,
                                    icon: Icons.copy_rounded,
                                  ),
                                  ContextMenuItem(
                                    id: 'view_history',
                                    label: l.viewInHistory,
                                    icon: Icons.history_rounded,
                                  ),
                                ],
                                onSelected: (action) {
                                  if (action == 'copy_invoice') {
                                    Clipboard.setData(
                                      ClipboardData(text: job.invoiceNumber),
                                    );
                                    SuccessSnackbar.show(
                                      context,
                                      message: l.invoiceCopied,
                                    );
                                  } else if (action == 'view_history') {
                                    context.go('/tech/history');
                                  }
                                },
                                child: _JobCard(
                                  job: job,
                                  onTap: () => context.push(
                                    '/tech/job/${job.id}',
                                    extra: job,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const ArcticShimmer(count: 3),
                    error: (error, _) => error is AppException
                        ? ErrorCard(exception: error)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/tech/submit'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          tooltip: l.newJob,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            l.newJob,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: title,
      child: ArcticCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: color),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onTap});

  final JobModel job;
  final VoidCallback onTap;

  int get _displayUnits {
    if (!job.isSharedInstall) return job.totalUnits;
    return job.sharedContributionUnits > 0
        ? job.sharedContributionUnits
        : job.totalUnits;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ArcticCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.clientName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusBadge(status: job.status.name),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.receipt_outlined,
                size: 16,
                color: ArcticTheme.arcticTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                job.invoiceNumber,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.ac_unit_rounded,
                size: 16,
                color: ArcticTheme.arcticTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                AppFormatters.units(_displayUnits),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (job.isSharedInstall) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _DashboardInfoChip(
                  icon: Icons.groups_rounded,
                  label: l.sharedInstall,
                  color: ArcticTheme.arcticBlue,
                ),
                _DashboardInfoChip(
                  icon: Icons.receipt_long_rounded,
                  label: '${l.totalOnInvoice}: ${job.sharedInvoiceTotalUnits}',
                  color: ArcticTheme.arcticBlue,
                ),
                _DashboardInfoChip(
                  icon: Icons.person_outline_rounded,
                  label: '${l.myShare}: $_displayUnits',
                  color: ArcticTheme.arcticSuccess,
                ),
                if (job.sharedInvoiceBracketCount > 0)
                  _DashboardInfoChip(
                    icon: Icons.hardware_outlined,
                    label:
                        '${l.acOutdoorBracket}: ${job.techBracketShare}/${job.sharedInvoiceBracketCount}',
                    color: ArcticTheme.arcticWarning,
                  ),
              ],
            ),
          ],
          if (job.clientContact.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: ArcticTheme.arcticTextSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.clientContact,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await WhatsAppLauncher.openChat(job.clientContact);
                  },
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    size: 16,
                    color: ArcticTheme.arcticSuccess,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 28,
                    minWidth: 28,
                  ),
                ),
              ],
            ),
          ],
          if (job.expenses > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: ArcticTheme.arcticTextSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppFormatters.currency(job.expenses),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ArcticTheme.arcticWarning,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (job.isRejected && job.adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ArcticTheme.arcticError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: ArcticTheme.arcticError,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job.adminNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ArcticTheme.arcticError,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardInfoChip extends StatelessWidget {
  const _DashboardInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
