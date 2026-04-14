import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class InvoiceSettlementsScreen extends ConsumerStatefulWidget {
  const InvoiceSettlementsScreen({super.key});

  @override
  ConsumerState<InvoiceSettlementsScreen> createState() =>
      _InvoiceSettlementsScreenState();
}

class _InvoiceSettlementsScreenState
    extends ConsumerState<InvoiceSettlementsScreen> {
  static const String _scopePending = 'pending';
  static const String _scopeHistory = 'history';

  final Set<String> _selected = <String>{};
  String _search = '';
  String _scope = _scopePending;
  DateTimeRange? _dateRange;
  bool _isProcessing = false;

  List<JobModel> _filterJobs(List<JobModel> jobs) {
    return jobs
        .where((job) {
          final matchesSearch = _search.trim().isEmpty
              ? true
              : [
                  job.invoiceNumber,
                  job.clientName,
                  job.techName,
                  job.companyName,
                ].join(' ').toLowerCase().contains(_search.toLowerCase());
          final matchesDate =
              _dateRange == null ||
              (job.date != null &&
                  !job.date!.isBefore(_dateRange!.start) &&
                  !job.date!.isAfter(
                    DateTime(
                      _dateRange!.end.year,
                      _dateRange!.end.month,
                      _dateRange!.end.day,
                      23,
                      59,
                      59,
                    ),
                  ));
          return matchesSearch && matchesDate;
        })
        .toList(growable: false);
  }

  Future<String?> _promptNote(
    BuildContext context,
    String title,
    String hint,
  ) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<({double amount, String paymentMethod, String note})?>
  _promptSettlementPaymentDetails(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    final methodController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final value =
        await showDialog<({double amount, String paymentMethod, String note})>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l.markAsPaid),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(hintText: l.amountLabel),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '') ?? 0;
                      return amount > 0 ? null : l.amountMustBePositive;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: methodController,
                    decoration: InputDecoration(hintText: l.paymentMethod),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? l.required
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l.settlementAdminNote,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 0;
                  Navigator.of(dialogContext).pop((
                    amount: amount,
                    paymentMethod: methodController.text.trim(),
                    note: noteController.text.trim(),
                  ));
                },
                child: Text(l.save),
              ),
            ],
          ),
        );

    amountController.dispose();
    methodController.dispose();
    noteController.dispose();
    return value;
  }

  Future<void> _pickRange() async {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: now,
      initialDateRange: _dateRange,
      helpText: l.selectPdfDateRange,
    );
    if (picked == null) return;
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
    });
  }

  Future<void> _markPaid(List<JobModel> selectedJobs) async {
    final l = AppLocalizations.of(context)!;
    if (selectedJobs.isEmpty) {
      AppFeedback.error(context, message: l.selectJobsFirst);
      return;
    }
    if (selectedJobs.map((job) => job.techId).toSet().length != 1) {
      AppFeedback.error(context, message: l.selectSameTechnicianJobs);
      return;
    }

    final settlementDetails = await _promptSettlementPaymentDetails(context);
    if (!mounted) return;
    if (settlementDetails == null) return;
    final admin = ref.read(currentUserProvider).value;
    if (admin == null) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(jobRepositoryProvider)
          .markJobsAsPaid(
            selectedJobs.map((job) => job.id).toList(growable: false),
            admin.uid,
            adminNote: settlementDetails.note,
            amountPerJob: settlementDetails.amount,
            paymentMethod: settlementDetails.paymentMethod,
          );
      if (!mounted) return;
      AppFeedback.success(context, message: l.paymentMarkedForConfirmation);
      setState(() => _selected.clear());
    } on AppException catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: error.message(Localizations.localeOf(context).languageCode),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _resubmit(List<JobModel> selectedJobs) async {
    final l = AppLocalizations.of(context)!;
    if (selectedJobs.isEmpty) {
      AppFeedback.error(context, message: l.selectJobsFirst);
      return;
    }
    final batchIds = selectedJobs
        .map((job) => job.settlementBatchId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    if (batchIds.length != 1) {
      AppFeedback.error(context, message: l.selectSingleBatchToResubmit);
      return;
    }

    final note = await _promptNote(
      context,
      l.resubmitPayment,
      l.settlementAdminNote,
    );
    final admin = ref.read(currentUserProvider).value;
    if (admin == null) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(jobRepositoryProvider)
          .resubmitSettlementBatch(
            batchIds.first,
            admin.uid,
            adminNote: note ?? '',
          );
      if (!mounted) return;
      AppFeedback.success(context, message: l.paymentResubmitted);
      setState(() => _selected.clear());
    } on AppException catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: error.message(Localizations.localeOf(context).languageCode),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _resolveDisputed(List<JobModel> selectedJobs) async {
    final l = AppLocalizations.of(context)!;
    if (selectedJobs.isEmpty) {
      AppFeedback.error(context, message: l.selectJobsFirst);
      return;
    }

    final batchIds = selectedJobs
        .map((job) => job.settlementBatchId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    if (batchIds.length != 1) {
      AppFeedback.error(context, message: l.selectSingleBatchToResubmit);
      return;
    }

    final note = await _promptNote(
      context,
      l.paymentDisputed,
      l.settlementAdminNote,
    );
    final admin = ref.read(currentUserProvider).value;
    if (admin == null) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(jobRepositoryProvider)
          .resolveDisputedSettlement(
            batchIds.first,
            admin.uid,
            resolutionNote: note ?? '',
          );
      if (!mounted) return;
      AppFeedback.success(context, message: l.paymentConfirmedSuccess);
      setState(() => _selected.clear());
      ref.invalidate(adminSettlementHistoryProvider);
      ref.invalidate(settlementSummaryProvider);
    } on AppException catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: error.message(Localizations.localeOf(context).languageCode),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _statusLabel(AppLocalizations l, JobSettlementStatus status) {
    switch (status) {
      case JobSettlementStatus.unpaid:
        return l.unpaid;
      case JobSettlementStatus.awaitingTechnician:
        return l.awaitingTechnicianConfirmation;
      case JobSettlementStatus.correctionRequired:
        return l.correctionRequired;
      case JobSettlementStatus.confirmed:
        return l.paymentConfirmed;
      case JobSettlementStatus.disputedFinal:
        return l.paymentDisputed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settlementsAsync = _scope == _scopeHistory
        ? ref.watch(adminSettlementHistoryProvider)
        : ref.watch(adminSettlementCandidatesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.invoiceSettlements)),
      body: SafeArea(
        child: settlementsAsync.when(
          data: (jobs) {
            final filtered = _filterJobs(jobs);
            final selectedJobs = filtered
                .where((job) => _selected.contains(job.id))
                .toList(growable: false);
            final canMarkPaid =
                selectedJobs.isNotEmpty &&
                selectedJobs.every((job) => job.isUnpaid);
            final canResubmit =
                selectedJobs.isNotEmpty &&
                selectedJobs.every((job) => job.isSettlementCorrectionRequired);
            final canResolveDisputed =
                selectedJobs.isNotEmpty &&
                selectedJobs.every((job) => job.isSettlementDisputedFinal);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(l.pending),
                        selected: _scope == _scopePending,
                        onSelected: (_) {
                          setState(() {
                            _scope = _scopePending;
                            _selected.clear();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(l.history),
                        selected: _scope == _scopeHistory,
                        onSelected: (_) {
                          setState(() {
                            _scope = _scopeHistory;
                            _selected.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
                  child: ArcticSearchBar(
                    hint: l.searchByTechClientInvoice,
                    onChanged: (value) => setState(() => _search = value),
                    trailing: IconButton(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.date_range_rounded),
                      tooltip: l.filterByDateRange,
                    ),
                  ),
                ),
                if (_dateRange != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _dateRange = null),
                        icon: const Icon(Icons.close_rounded),
                        label: Text(
                          '${AppFormatters.date(_dateRange!.start)} - ${AppFormatters.date(_dateRange!.end)}',
                        ),
                      ),
                    ),
                  ),
                if (_selected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                    child: BulkActionBar(
                      selectedCount: _selected.length,
                      isProcessing: _isProcessing,
                      onClear: () => setState(() => _selected.clear()),
                      actions: [
                        if (canMarkPaid)
                          BulkAction(
                            label: l.markAsPaid,
                            icon: Icons.payments_outlined,
                            color: ArcticTheme.arcticSuccess,
                            onPressed: () => _markPaid(selectedJobs),
                          ),
                        if (canResubmit)
                          BulkAction(
                            label: l.resubmitPayment,
                            icon: Icons.refresh_rounded,
                            color: ArcticTheme.arcticWarning,
                            onPressed: () => _resubmit(selectedJobs),
                          ),
                        if (canResolveDisputed)
                          BulkAction(
                            label: l.paymentConfirmed,
                            icon: Icons.gavel_rounded,
                            color: ArcticTheme.arcticSuccess,
                            onPressed: () => _resolveDisputed(selectedJobs),
                          ),
                      ],
                    ).animate().fadeIn(duration: 180.ms).slideY(begin: -0.05),
                  ),
                Expanded(
                  child: ArcticRefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(adminSettlementCandidatesProvider);
                      ref.invalidate(adminSettlementHistoryProvider);
                      ref.invalidate(settlementSummaryProvider);
                    },
                    child: filtered.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  l.noJobsForPeriod,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final job = filtered[index];
                              final selected = _selected.contains(job.id);
                              return ArcticCard(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: CheckboxListTile(
                                      value: selected,
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value ?? false) {
                                            _selected.add(job.id);
                                          } else {
                                            _selected.remove(job.id);
                                          }
                                        });
                                      },
                                      title: Text(job.invoiceNumber),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${job.techName} • ${job.clientName}',
                                          ),
                                          Text(
                                            '${AppFormatters.date(job.date)} • ${_statusLabel(l, job.settlementStatus)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: ArcticTheme
                                                      .arcticTextSecondary,
                                                ),
                                          ),
                                          if (job.settlementTechnicianComment
                                              .trim()
                                              .isNotEmpty)
                                            Text(
                                              job.settlementTechnicianComment,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: ArcticTheme
                                                        .arcticWarning,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate(
                                    delay: Duration(milliseconds: index * 60),
                                  )
                                  .fadeIn(duration: 220.ms)
                                  .slideY(begin: 0.05);
                            },
                          ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: ArcticShimmer(count: 6),
          ),
          error: (error, _) => Center(
            child: ErrorCard(
              exception: error is AppException
                  ? error
                  : JobException.saveFailed(),
            ),
          ),
        ),
      ),
    );
  }
}
