import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/category_translator.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';
import 'package:ac_techs/features/expenses/data/ac_install_repository.dart';
import 'package:ac_techs/features/expenses/providers/ac_install_providers.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  String _search = '';
  final Set<String> _selected = {};
  bool _isBulkProcessing = false;
  bool _isApprovingInOut = false;

  Map<String, List<JobModel>> _sharedJobGroups(List<JobModel> jobs) {
    final groups = <String, List<JobModel>>{};
    for (final job in jobs) {
      if (!job.isSharedInstall || job.sharedInstallGroupKey.isEmpty) continue;
      groups
          .putIfAbsent(job.sharedInstallGroupKey, () => <JobModel>[])
          .add(job);
    }
    return groups;
  }

  int _jobContributionUnits(JobModel job) {
    if (!job.isSharedInstall) return job.totalUnits;
    return job.sharedContributionUnits > 0
        ? job.sharedContributionUnits
        : job.totalUnits;
  }

  int _sharedInvoiceUnits(Map<String, List<JobModel>> groups) {
    return groups.values.fold<int>(
      0,
      (sum, entries) => sum + entries.first.sharedInvoiceTotalUnits,
    );
  }

  String _sharedTechnicianNames(
    JobModel job,
    Map<String, List<JobModel>> groups,
  ) {
    if (!job.isSharedInstall || job.sharedInstallGroupKey.isEmpty) {
      return job.techName;
    }

    final names =
        (groups[job.sharedInstallGroupKey] ?? const <JobModel>[])
            .map((entry) => entry.techName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    return names.join(', ');
  }

  Widget _buildInvoiceConflictWarning(JobModel job, AppLocalizations l) {
    final companies = job.invoiceConflictCompanies.join(', ');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArcticTheme.arcticWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArcticTheme.arcticWarning.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: ArcticTheme.arcticWarning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.invoiceConflictNeedsReview,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (companies.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l.invoiceConflictCompaniesLabel(companies),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  List<JobModel> _filter(List<JobModel> jobs) {
    if (_search.isEmpty) return jobs;
    final q = _search.toLowerCase();
    return jobs
        .where(
          (j) =>
              j.clientName.toLowerCase().contains(q) ||
              j.techName.toLowerCase().contains(q) ||
              j.invoiceNumber.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _bulkApprove() async {
    if (_selected.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _isBulkProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      final repo = ref.read(jobRepositoryProvider);
      await repo.bulkApproveJobs(_selected.toList(), admin.uid);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(
            context,
          )!.bulkApproveSuccess(_selected.length),
        );
        setState(() => _selected.clear());
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.bulkApproveFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _isBulkProcessing = false);
    }
  }

  Future<void> _bulkReject() async {
    if (_selected.isEmpty) return;
    HapticFeedback.mediumImpact();
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rejectSelectedJobs),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.rejectReason,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(AppLocalizations.of(context)!.rejectAll),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _isBulkProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      final repo = ref.read(jobRepositoryProvider);
      for (final id in _selected) {
        await repo.rejectJob(id, admin.uid, reason);
      }
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(
            context,
          )!.bulkRejectSuccess(_selected.length),
        );
        setState(() => _selected.clear());
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.bulkRejectFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _isBulkProcessing = false);
    }
  }

  void _refreshApprovals() {
    ref.invalidate(pendingApprovalsProvider);
    ref.invalidate(approvedSharedInstallsProvider);
    ref.invalidate(pendingEarningsProvider);
    ref.invalidate(pendingExpensesProvider);
    ref.invalidate(pendingAcInstallsProvider);
  }

  Future<void> _approvePendingInOut({
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
  }) async {
    if (earnings.isEmpty && expenses.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final admin = ref.read(currentUserProvider).value;
    if (admin == null) return;

    setState(() => _isApprovingInOut = true);
    try {
      final earningRepo = ref.read(earningRepositoryProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);

      for (final earning in earnings) {
        await earningRepo.approveEarning(earning.id, admin.uid);
      }
      for (final expense in expenses) {
        await expenseRepo.approveExpense(expense.id, admin.uid);
      }

      if (!mounted) return;
      SuccessSnackbar.show(
        context,
        message: '${l.approved}: ${earnings.length + expenses.length}',
      );
    } catch (_) {
      if (!mounted) return;
      ErrorSnackbar.show(context, message: l.bulkApproveFailed);
    } finally {
      if (mounted) setState(() => _isApprovingInOut = false);
    }
  }

  Future<String?> _promptRejectionReason(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.reject),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.rejectReason,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );
    return reason;
  }

  Future<void> _showJobVerificationDialog(
    JobModel job, {
    required int groupSize,
    required String sharedTechnicianNames,
    bool allowActions = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    final historyFuture = ref
        .read(jobRepositoryProvider)
        .fetchJobHistory(job.id);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(job.invoiceNumber),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (job.hasInvoiceConflict) _buildInvoiceConflictWarning(job, l),
              Text('${l.technician}: ${job.techName}'),
              Text('${l.client}: ${job.clientName}'),
              Text('${l.totalUnits}: ${job.totalUnits}'),
              if (job.isSharedInstall)
                Text(
                  '${l.sharedInstall}: ${l.totalOnInvoice} ${AppFormatters.units(job.sharedInvoiceTotalUnits)} • ${l.myShare} ${AppFormatters.units(_jobContributionUnits(job))}',
                ),
              if (job.isSharedInstall &&
                  job.sharedInvoiceUninstallSplitUnits > 0)
                Text(
                  '${l.uninstallSplit}: ${job.techUninstallSplitShare}/${job.sharedInvoiceUninstallSplitUnits}',
                ),
              if (job.isSharedInstall &&
                  job.sharedInvoiceUninstallWindowUnits > 0)
                Text(
                  '${l.uninstallWindow}: ${job.techUninstallWindowShare}/${job.sharedInvoiceUninstallWindowUnits}',
                ),
              if (job.isSharedInstall &&
                  job.sharedInvoiceUninstallFreestandingUnits > 0)
                Text(
                  '${l.uninstallStanding}: ${job.techUninstallFreestandingShare}/${job.sharedInvoiceUninstallFreestandingUnits}',
                ),
              if (job.isSharedInstall && job.sharedInvoiceBracketCount > 0)
                Text(
                  '${l.acOutdoorBracket}: ${job.techBracketShare}/${job.sharedInvoiceBracketCount}',
                ),
              if (job.isSharedInstall) Text(l.sharedTeamCount(groupSize)),
              if (job.isSharedInstall && sharedTechnicianNames.isNotEmpty)
                Text('${l.sharedTeamMembers}: $sharedTechnicianNames'),
              if (job.expenseNote.trim().isNotEmpty) Text(job.expenseNote),
              const SizedBox(height: 12),
              _ApprovalHistorySection(
                future: historyFuture,
                title: l.history,
                statusLabel: l.statusLabel,
                dateLabel: l.date,
                reasonLabel: l.rejectReason,
                approvedLabel: l.approved,
                rejectedLabel: l.rejected,
                pendingLabel: l.pending,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          IconButton(
            tooltip: l.permanentlyDeleteJob,
            icon: const Icon(Icons.delete_forever_outlined),
            color: Theme.of(ctx).colorScheme.error,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final confirm1 = await showDialog<bool>(
                context: context,
                builder: (dlg) => AlertDialog(
                  title: Text(l.permanentlyDeleteJob),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.permanentlyDeleteJobConfirm),
                      if (job.isSharedInstall) ...[
                        const SizedBox(height: 12),
                        Text(
                          l.permanentlyDeleteJobSharedWarning,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ArcticTheme.arcticPending),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dlg).pop(false),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dlg).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: Text(l.delete),
                    ),
                  ],
                ),
              );
              if (confirm1 != true) return;
              if (!mounted) return;
              final confirm2 = await showDialog<bool>(
                context: context,
                builder: (dlg) => AlertDialog(
                  title: Text(l.permanentlyDeleteJob),
                  content: Text(l.deleteWarning),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dlg).pop(false),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dlg).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: Text(l.delete),
                    ),
                  ],
                ),
              );
              if (confirm2 != true || !mounted) return;
              try {
                await ref.read(jobRepositoryProvider).hardDeleteJob(job.id);
                if (!mounted) return;
                AppFeedback.success(context, message: l.jobDeletedSuccess);
              } catch (e) {
                if (!mounted) return;
                AppFeedback.error(context, message: l.genericError);
              }
            },
          ),
          if (allowActions)
            OutlinedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final reason = await _promptRejectionReason(context);
                if (reason == null || reason.isEmpty) return;
                final admin = ref.read(currentUserProvider).value;
                if (admin == null) return;
                await ref
                    .read(jobRepositoryProvider)
                    .rejectJob(job.id, admin.uid, reason);
              },
              child: Text(l.reject),
            ),
          if (allowActions)
            FilledButton(
              onPressed: () async {
                final admin = ref.read(currentUserProvider).value;
                if (admin == null) return;
                await ref
                    .read(jobRepositoryProvider)
                    .approveJob(job.id, admin.uid);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(l.approve),
            ),
        ],
      ),
    );
  }

  Future<void> _showInOutVerificationDialog(_PendingInOutEntry entry) async {
    final l = AppLocalizations.of(context)!;
    final historyFuture = entry.isEarning
        ? ref.read(earningRepositoryProvider).fetchHistory(entry.id)
        : ref.read(expenseRepositoryProvider).fetchHistory(entry.id);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(entry.isEarning ? l.inEarned : l.outSpent),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l.technician}: ${entry.techName}'),
              Text('${l.category}: ${entry.category}'),
              Text('${l.amountSar}: ${AppFormatters.currency(entry.amount)}'),
              if (entry.note.trim().isNotEmpty) Text(entry.note),
              const SizedBox(height: 12),
              _ApprovalHistorySection(
                future: historyFuture,
                title: l.history,
                statusLabel: l.statusLabel,
                dateLabel: l.date,
                reasonLabel: l.rejectReason,
                approvedLabel: l.approved,
                rejectedLabel: l.rejected,
                pendingLabel: l.pending,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final reason = await _promptRejectionReason(context);
              if (reason == null || reason.isEmpty) return;
              final admin = ref.read(currentUserProvider).value;
              if (admin == null) return;
              if (entry.isEarning) {
                await ref
                    .read(earningRepositoryProvider)
                    .rejectEarning(entry.id, admin.uid, reason);
              } else {
                await ref
                    .read(expenseRepositoryProvider)
                    .rejectExpense(entry.id, admin.uid, reason);
              }
            },
            child: Text(l.reject),
          ),
          FilledButton(
            onPressed: () async {
              final admin = ref.read(currentUserProvider).value;
              if (admin == null) return;
              if (entry.isEarning) {
                await ref
                    .read(earningRepositoryProvider)
                    .approveEarning(entry.id, admin.uid);
              } else {
                await ref
                    .read(expenseRepositoryProvider)
                    .approveExpense(entry.id, admin.uid);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(l.approve),
          ),
        ],
      ),
    );
  }

  Future<void> _showAcInstallVerificationDialog(AcInstallModel install) async {
    final l = AppLocalizations.of(context)!;
    final historyFuture = ref
        .read(acInstallRepositoryProvider)
        .fetchInstallHistory(install.id);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.acInstallations),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l.technician}: ${install.techName}'),
              Text(
                '${l.totalOnInvoice}: ${AppFormatters.units(install.totalInvoiceUnits)}',
              ),
              Text(
                '${l.myShare}: ${AppFormatters.units(install.totalPersonalUnits)}',
              ),
              if (install.note.trim().isNotEmpty) Text(install.note.trim()),
              if (install.adminNote.trim().isNotEmpty)
                Text('${l.rejectReason}: ${install.adminNote.trim()}'),
              const SizedBox(height: 12),
              _ApprovalHistorySection(
                future: historyFuture,
                title: l.history,
                statusLabel: l.statusLabel,
                dateLabel: l.date,
                reasonLabel: l.rejectReason,
                approvedLabel: l.approved,
                rejectedLabel: l.rejected,
                pendingLabel: l.pending,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final reason = await _promptRejectionReason(context);
              if (reason == null || reason.isEmpty) return;
              final admin = ref.read(currentUserProvider).value;
              if (admin == null) return;
              await ref
                  .read(acInstallRepositoryProvider)
                  .rejectInstall(install.id, admin.uid, reason);
            },
            child: Text(l.reject),
          ),
          FilledButton(
            onPressed: () async {
              final admin = ref.read(currentUserProvider).value;
              if (admin == null) return;
              await ref
                  .read(acInstallRepositoryProvider)
                  .approveInstall(install.id, admin.uid);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(l.approve),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingApprovalsProvider);
    final approvedSharedAsync = ref.watch(approvedSharedInstallsProvider);
    final pendingEarnings = ref.watch(pendingEarningsProvider);
    final pendingExpenses = ref.watch(pendingExpensesProvider);
    final pendingAcInstalls = ref.watch(pendingAcInstallsProvider);
    final pendingInOut =
        <_PendingInOutEntry>[
          ...(pendingEarnings.value ?? const <EarningModel>[]).map(
            (e) => _PendingInOutEntry(
              id: e.id,
              isEarning: true,
              techName: e.techName,
              category: e.category,
              amount: e.amount,
              note: e.note,
              date: e.date,
            ),
          ),
          ...(pendingExpenses.value ?? const <ExpenseModel>[]).map(
            (e) => _PendingInOutEntry(
              id: e.id,
              isEarning: false,
              techName: e.techName,
              category: e.category,
              amount: e.amount,
              note: e.note,
              date: e.date,
            ),
          ),
        ]..sort(
          (a, b) =>
              (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)),
        );
    final successTone = Theme.of(context).brightness == Brightness.light
        ? ArcticTheme.lightSuccess
        : ArcticTheme.arcticSuccess;

    return AppShortcuts(
      onRefresh: _refreshApprovals,
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.approvals)),
        body: SafeArea(
          child: pending.when(
            data: (jobs) {
              final filtered = _filter(jobs);
              final sharedGroups = _sharedJobGroups(filtered);
              final sharedJobsCount = filtered
                  .where((job) => job.isSharedInstall)
                  .length;
              final sharedInvoiceUnits = _sharedInvoiceUnits(sharedGroups);
              final approvedShared =
                  approvedSharedAsync.value ?? const <JobModel>[];
              final approvedSharedGroups = _sharedJobGroups(approvedShared);
              final filteredApprovedShared = _filter(approvedShared);
              final pendingAcInstallItems =
                  pendingAcInstalls.value ?? const <AcInstallModel>[];
              _selected.removeWhere((id) => !filtered.any((j) => j.id == id));

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      12,
                      16,
                      8,
                    ),
                    child: ArcticSearchBar(
                      hint: AppLocalizations.of(
                        context,
                      )!.searchByTechClientInvoice,
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    BulkActionBar(
                      selectedCount: _selected.length,
                      isProcessing: _isBulkProcessing,
                      onClear: () => setState(() => _selected.clear()),
                      actions: [
                        BulkAction(
                          label: AppLocalizations.of(context)!.approve,
                          icon: Icons.check_rounded,
                          color: ArcticTheme.arcticSuccess,
                          onPressed: _bulkApprove,
                        ),
                        BulkAction(
                          label: AppLocalizations.of(context)!.reject,
                          icon: Icons.close_rounded,
                          color: ArcticTheme.arcticError,
                          onPressed: _bulkReject,
                        ),
                      ],
                    ),
                  if (sharedGroups.isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        0,
                        16,
                        8,
                      ),
                      child: ArcticCard(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _SharedApprovalMetric(
                              label:
                                  '${AppLocalizations.of(context)!.sharedInstall} ${AppLocalizations.of(context)!.invoice}',
                              value: '${sharedGroups.length}',
                            ),
                            _SharedApprovalMetric(
                              label:
                                  '${AppLocalizations.of(context)!.sharedInstall} ${AppLocalizations.of(context)!.jobs}',
                              value: '$sharedJobsCount',
                            ),
                            _SharedApprovalMetric(
                              label:
                                  '${AppLocalizations.of(context)!.sharedInstall} ${AppLocalizations.of(context)!.totalUnits}',
                              value: AppFormatters.units(sharedInvoiceUnits),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (pendingEarnings.hasValue || pendingExpenses.hasValue)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        0,
                        16,
                        8,
                      ),
                      child: ArcticCard(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final count =
                                (pendingEarnings.value?.length ?? 0) +
                                (pendingExpenses.value?.length ?? 0);
                            final summaryText =
                                '${AppLocalizations.of(context)!.inOut} ${AppLocalizations.of(context)!.pending}: $count';
                            final approveButton = FilledButton.icon(
                              onPressed: _isApprovingInOut
                                  ? null
                                  : () => _approvePendingInOut(
                                      earnings:
                                          pendingEarnings.value ??
                                          const <EarningModel>[],
                                      expenses:
                                          pendingExpenses.value ??
                                          const <ExpenseModel>[],
                                    ),
                              icon: _isApprovingInOut
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                AppLocalizations.of(context)!.approve,
                              ),
                            );

                            if (constraints.maxWidth < 440) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    summaryText,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  approveButton,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    summaryText,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                approveButton,
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  if (filtered.isEmpty &&
                      pendingAcInstallItems.isEmpty &&
                      pendingInOut.isEmpty &&
                      filteredApprovedShared.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 64,
                              color: successTone.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _search.isNotEmpty
                                  ? AppLocalizations.of(
                                      context,
                                    )!.noMatchingApprovals
                                  : AppLocalizations.of(context)!.allCaughtUp,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              AppLocalizations.of(context)!.noApprovals,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ArcticRefreshIndicator(
                        onRefresh: () async => _refreshApprovals(),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (pendingAcInstallItems.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  AppLocalizations.of(context)!.acInstallations,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              ...pendingAcInstallItems.map(
                                (install) => _PendingAcInstallCard(
                                  install: install,
                                  onTap: () =>
                                      _showAcInstallVerificationDialog(install),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (pendingInOut.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${AppLocalizations.of(context)!.inOut} ${AppLocalizations.of(context)!.pending}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              ...pendingInOut.map(
                                (entry) => _InOutPendingCard(
                                  entry: entry,
                                  onTap: () =>
                                      _showInOutVerificationDialog(entry),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (filtered.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  AppLocalizations.of(context)!.jobs,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ...filtered.asMap().entries.map((entry) {
                              final index = entry.key;
                              final job = entry.value;
                              final groupSize = job.isSharedInstall
                                  ? (sharedGroups[job.sharedInstallGroupKey]
                                            ?.length ??
                                        1)
                                  : 1;
                              return SwipeActionCard(
                                    key: ValueKey(job.id),
                                    onSwipeRight: () async {
                                      // Approve on swipe right
                                      final approvedMsg = AppLocalizations.of(
                                        context,
                                      )!.jobApproved;
                                      final failMsg = AppLocalizations.of(
                                        context,
                                      )!.couldNotApprove;
                                      try {
                                        await ref
                                            .read(jobRepositoryProvider)
                                            .approveJob(
                                              job.id,
                                              ref
                                                      .read(currentUserProvider)
                                                      .value
                                                      ?.uid ??
                                                  '',
                                            );
                                        if (!context.mounted) return;
                                        AppFeedback.success(
                                          context,
                                          message: approvedMsg,
                                        );
                                      } catch (_) {
                                        if (!context.mounted) return;
                                        AppFeedback.error(
                                          context,
                                          message: failMsg,
                                        );
                                      }
                                    },
                                    onSwipeLeft: () =>
                                        _showRejectDialogFor(job),
                                    rightIcon: Icons.check_rounded,
                                    leftIcon: Icons.close_rounded,
                                    child: _ApprovalCard(
                                      job: job,
                                      groupSize: groupSize,
                                      isSelected: _selected.contains(job.id),
                                      onTap: () => _showJobVerificationDialog(
                                        job,
                                        groupSize: groupSize,
                                        sharedTechnicianNames:
                                            _sharedTechnicianNames(
                                              job,
                                              sharedGroups,
                                            ),
                                      ),
                                      onSelect: (v) {
                                        setState(() {
                                          if (v) {
                                            _selected.add(job.id);
                                          } else {
                                            _selected.remove(job.id);
                                          }
                                        });
                                      },
                                    ),
                                  )
                                  .animate(delay: (index * 80).ms)
                                  .fadeIn()
                                  .slideX(begin: 0.05);
                            }),
                            if (filteredApprovedShared.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.approvedSharedInstalls,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              ...filteredApprovedShared.map((job) {
                                final approvedGroupSize =
                                    approvedSharedGroups[job
                                            .sharedInstallGroupKey]
                                        ?.length ??
                                    1;
                                return ArcticCard(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  onTap: () => _showJobVerificationDialog(
                                    job,
                                    groupSize: approvedGroupSize,
                                    sharedTechnicianNames:
                                        _sharedTechnicianNames(
                                          job,
                                          approvedSharedGroups,
                                        ),
                                    allowActions: false,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job.techName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${job.invoiceNumber} • ${AppFormatters.date(job.date)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Chip(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.sharedInstall,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          Chip(
                                            label: Text(
                                              '${AppLocalizations.of(context)!.myShare}: ${AppFormatters.units(_jobContributionUnits(job))}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          if (_sharedTechnicianNames(
                                            job,
                                            approvedSharedGroups,
                                          ).isNotEmpty)
                                            Chip(
                                              label: Text(
                                                '${AppLocalizations.of(context)!.technicians}: ${_sharedTechnicianNames(job, approvedSharedGroups)}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelSmall,
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: ArcticShimmer(count: 5),
            ),
            error: (error, _) => error is AppException
                ? Center(child: ErrorCard(exception: error))
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Future<void> _showRejectDialogFor(JobModel job) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rejectJob),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.rejectReason,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      await ref
          .read(jobRepositoryProvider)
          .rejectJob(job.id, admin.uid, reason);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.jobRejected,
        );
      }
    } catch (_) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotReject,
        );
      }
    }
  }
}

class _ApprovalCard extends ConsumerStatefulWidget {
  const _ApprovalCard({
    required this.job,
    required this.groupSize,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
  });

  final JobModel job;
  final int groupSize;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelect;

  @override
  ConsumerState<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<_ApprovalCard> {
  bool _isProcessing = false;

  Color get _successTone => Theme.of(context).brightness == Brightness.light
      ? ArcticTheme.lightSuccess
      : ArcticTheme.arcticSuccess;

  Color get _warningTone => Theme.of(context).brightness == Brightness.light
      ? ArcticTheme.lightWarning
      : ArcticTheme.arcticWarning;

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      await ref
          .read(jobRepositoryProvider)
          .approveJob(widget.job.id, admin.uid);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.jobApproved,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotApprove,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showRejectDialog() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rejectJob),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.rejectReason,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      await ref
          .read(jobRepositoryProvider)
          .rejectJob(widget.job.id, admin.uid, reason);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.jobRejected,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotReject,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final textSecondary =
        Theme.of(context).textTheme.bodySmall?.color ??
        ArcticTheme.arcticTextSecondary;
    final chipBg = Theme.of(context).cardColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: ArcticCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (job.hasInvoiceConflict) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _warningTone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _warningTone.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: _warningTone,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.invoiceConflictNeedsReview,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  Checkbox(
                    value: widget.isSelected,
                    onChanged: (v) => widget.onSelect(v ?? false),
                    activeColor: colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        job.techName.isNotEmpty
                            ? job.techName[0].toUpperCase()
                            : 'T',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.techName,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${job.invoiceNumber} • ${AppFormatters.date(job.date)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 24, color: dividerColor),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: textSecondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      job.clientName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (job.clientContact.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: textSecondary),
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
                        color: ArcticTheme.arcticSuccess,
                        size: 16,
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
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.ac_unit_rounded, size: 16, color: textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    AppFormatters.units(
                      job.isSharedInstall
                          ? (job.sharedContributionUnits > 0
                                ? job.sharedContributionUnits
                                : job.totalUnits)
                          : job.totalUnits,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (job.expenses > 0) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: _warningTone,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        AppFormatters.currency(job.expenses),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: _warningTone),
                      ),
                    ),
                  ],
                ],
              ),
              if (job.editRequestedAt != null) ...[
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(
                    Icons.edit_off_outlined,
                    size: 14,
                    color: ArcticTheme.arcticPending,
                  ),
                  label: Text(
                    l.resubmittedBadge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ArcticTheme.arcticPending,
                    ),
                  ),
                  backgroundColor: ArcticTheme.arcticPending.withValues(
                    alpha: 0.12,
                  ),
                  side: BorderSide(
                    color: ArcticTheme.arcticPending.withValues(alpha: 0.5),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
              if (job.isSharedInstall) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text(
                        l.sharedInstall,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      backgroundColor: chipBg,
                      side: BorderSide(color: dividerColor),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Chip(
                      label: Text(
                        '${l.totalOnInvoice}: ${job.sharedInvoiceTotalUnits}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      backgroundColor: chipBg,
                      side: BorderSide(color: dividerColor),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Chip(
                      label: Text(
                        '${l.myShare}: ${job.sharedContributionUnits > 0 ? job.sharedContributionUnits : job.totalUnits}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      backgroundColor: chipBg,
                      side: BorderSide(color: dividerColor),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (job.sharedInvoiceBracketCount > 0)
                      Chip(
                        label: Text(
                          '${l.acOutdoorBracket}: ${job.techBracketShare}/${job.sharedInvoiceBracketCount}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        backgroundColor: chipBg,
                        side: BorderSide(color: dividerColor),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    Chip(
                      label: Text(
                        '${l.technicians}: ${widget.groupSize}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      backgroundColor: chipBg,
                      side: BorderSide(color: dividerColor),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
              if (job.acUnits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: job.acUnits
                      .map(
                        (u) => Chip(
                          label: Text(
                            '${translateCategory(u.type, AppLocalizations.of(context)!)} × ${u.quantity}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          backgroundColor: chipBg,
                          side: BorderSide(color: dividerColor),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _showRejectDialog,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.reject),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _approve,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ArcticTheme.arcticDarkBg,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.approve),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _successTone,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingInOutEntry {
  const _PendingInOutEntry({
    required this.id,
    required this.isEarning,
    required this.techName,
    required this.category,
    required this.amount,
    required this.note,
    this.date,
  });

  final String id;
  final bool isEarning;
  final String techName;
  final String category;
  final double amount;
  final String note;
  final DateTime? date;
}

class _PendingAcInstallCard extends ConsumerStatefulWidget {
  const _PendingAcInstallCard({required this.install, required this.onTap});

  final AcInstallModel install;
  final VoidCallback onTap;

  @override
  ConsumerState<_PendingAcInstallCard> createState() =>
      _PendingAcInstallCardState();
}

class _PendingAcInstallCardState extends ConsumerState<_PendingAcInstallCard> {
  bool _isProcessing = false;

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      await ref
          .read(acInstallRepositoryProvider)
          .approveInstall(widget.install.id, admin.uid);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.approved,
        );
      }
    } catch (_) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotApprove,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.reject),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.rejectReason,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      await ref
          .read(acInstallRepositoryProvider)
          .rejectInstall(widget.install.id, admin.uid, reason);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.rejected,
        );
      }
    } catch (_) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotReject,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final install = widget.install;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ArcticCard(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              install.techName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${AppLocalizations.of(context)!.date}: ${AppFormatters.date(install.date)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(
                    '${AppLocalizations.of(context)!.totalOnInvoice}: ${AppFormatters.units(install.totalInvoiceUnits)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(
                    '${AppLocalizations.of(context)!.myShare}: ${AppFormatters.units(install.totalPersonalUnits)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            if (install.note.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                install.note.trim(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _reject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(AppLocalizations.of(context)!.reject),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _approve,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(AppLocalizations.of(context)!.approve),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalHistorySection extends StatelessWidget {
  const _ApprovalHistorySection({
    required this.future,
    required this.title,
    required this.statusLabel,
    required this.dateLabel,
    required this.reasonLabel,
    required this.approvedLabel,
    required this.rejectedLabel,
    required this.pendingLabel,
  });

  final Future<List<ApprovalHistoryEntry>> future;
  final String title;
  final String statusLabel;
  final String dateLabel;
  final String reasonLabel;
  final String approvedLabel;
  final String rejectedLabel;
  final String pendingLabel;

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return approvedLabel;
      case 'rejected':
        return rejectedLabel;
      case 'pending':
        return pendingLabel;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ApprovalHistoryEntry>>(
      future: future,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        if (entries == null || entries.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ArcticTheme.arcticCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ArcticTheme.arcticDivider.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$statusLabel: ${_statusText(entry.previousStatus)} -> ${_statusText(entry.newStatus)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (entry.changedAt != null)
                        Text(
                          '$dateLabel: ${AppFormatters.dateTime(entry.changedAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (entry.reason.trim().isNotEmpty)
                        Text(
                          '$reasonLabel: ${entry.reason}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InOutPendingCard extends StatelessWidget {
  const _InOutPendingCard({required this.entry, required this.onTap});

  final _PendingInOutEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final subtitle = '${entry.techName} • ${AppFormatters.date(entry.date)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ArcticCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isEarning ? l.inEarned : l.outSpent,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '${entry.category} • ${AppFormatters.currency(entry.amount)}',
                ),
                if (entry.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.note,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SharedApprovalMetric extends StatelessWidget {
  const _SharedApprovalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ArcticTheme.arcticTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: ArcticTheme.arcticBlue),
        ),
      ],
    );
  }
}
