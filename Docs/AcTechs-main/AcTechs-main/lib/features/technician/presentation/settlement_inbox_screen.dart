import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class SettlementInboxScreen extends ConsumerStatefulWidget {
  const SettlementInboxScreen({super.key});

  @override
  ConsumerState<SettlementInboxScreen> createState() =>
      _SettlementInboxScreenState();
}

class _SettlementInboxScreenState extends ConsumerState<SettlementInboxScreen> {
  final Set<String> _processingBatchIds = <String>{};

  Future<String?> _promptComment(BuildContext context) async {
    final controller = TextEditingController();
    final l = AppLocalizations.of(context)!;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.rejectPayment),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: l.settlementTechnicianComment),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _confirmBatch(String batchId) async {
    HapticFeedback.mediumImpact();
    final l = AppLocalizations.of(context)!;
    setState(() => _processingBatchIds.add(batchId));
    try {
      await ref.read(jobRepositoryProvider).confirmSettlementBatch(batchId);
      if (!mounted) return;
      AppFeedback.success(context, message: l.paymentConfirmedSuccess);
      ref.invalidate(technicianSettlementInboxProvider);
    } on AppException catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: error.message(Localizations.localeOf(context).languageCode),
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: JobException.saveFailed().message(
          Localizations.localeOf(context).languageCode,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingBatchIds.remove(batchId));
      }
    }
  }

  Future<void> _rejectBatch(String batchId) async {
    HapticFeedback.mediumImpact();
    final l = AppLocalizations.of(context)!;
    final comment = await _promptComment(context);
    if (comment == null || comment.isEmpty) return;

    setState(() => _processingBatchIds.add(batchId));
    try {
      await ref
          .read(jobRepositoryProvider)
          .rejectSettlementBatch(batchId, comment);
      if (!mounted) return;
      AppFeedback.success(context, message: l.paymentRejectedForCorrection);
      ref.invalidate(technicianSettlementInboxProvider);
    } on AppException catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: error.message(Localizations.localeOf(context).languageCode),
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: JobException.saveFailed().message(
          Localizations.localeOf(context).languageCode,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingBatchIds.remove(batchId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final inboxAsync = ref.watch(technicianSettlementInboxProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.paymentInbox)),
      body: SafeArea(
        child: ArcticRefreshIndicator(
          onRefresh: () async {
            ref.invalidate(technicianSettlementInboxProvider);
          },
          child: inboxAsync.when(
            data: (jobs) {
              if (jobs.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                    Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.payments_rounded,
                                size: 44,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l.allCaughtUp,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 220.ms)
                        .scale(begin: const Offset(0.92, 0.92)),
                  ],
                );
              }

              final byBatch = <String, List<JobModel>>{};
              for (final job in jobs) {
                byBatch
                    .putIfAbsent(job.settlementBatchId, () => <JobModel>[])
                    .add(job);
              }
              final entries = byBatch.entries.toList(growable: false);

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final batchId = entries[index].key;
                  final items = entries[index].value;
                  final first = items.first;
                  final isProcessing = _processingBatchIds.contains(batchId);
                  return ArcticCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l.settlementBatch}: ${batchId.substring(0, batchId.length > 12 ? 12 : batchId.length)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${items.length} ${l.jobs} • ${AppFormatters.date(first.settlementRequestedAt ?? first.date)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ArcticTheme.arcticTextSecondary,
                                  ),
                            ),
                            if (first.settlementAdminNote
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(first.settlementAdminNote),
                            ],
                            if (first.settlementAmount > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${l.amountSar}: ${AppFormatters.currency(first.settlementAmount)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (first.settlementPaymentMethod
                                  .trim()
                                  .isNotEmpty)
                                Text(
                                  '${l.paymentMethod}: ${first.settlementPaymentMethod}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (first.settlementPaidAt != null)
                                Text(
                                  '${l.paidOn}: ${AppFormatters.date(first.settlementPaidAt!)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                            const SizedBox(height: 10),
                            ...items.map(
                              (job) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(job.invoiceNumber)),
                                    Text(AppFormatters.date(job.date)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isProcessing
                                        ? null
                                        : () => _rejectBatch(batchId),
                                    icon: const Icon(Icons.close_rounded),
                                    label: Text(l.rejectPayment),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: isProcessing
                                        ? null
                                        : () => _confirmBatch(batchId),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    label: Text(l.confirmPaymentReceived),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate(delay: Duration(milliseconds: index * 70))
                      .fadeIn(duration: 220.ms)
                      .slideY(begin: 0.04);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: ArcticShimmer(count: 5),
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
      ),
    );
  }
}
