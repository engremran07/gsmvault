import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';

class JobDetailsScreen extends ConsumerWidget {
  const JobDetailsScreen({required this.jobId, this.initialJob, super.key});

  final String jobId;
  final JobModel? initialJob;

  Future<List<String>> _sharedTechnicianNames(
    WidgetRef ref,
    JobModel job,
  ) async {
    if (!job.isSharedInstall || job.sharedInstallGroupKey.trim().isEmpty) {
      return const <String>[];
    }

    try {
      final namesByGroup = await ref.read(
        sharedInstallerNamesProvider(
          SharedInstallerNamesQuery.fromKeys([job.sharedInstallGroupKey]),
        ).future,
      );
      return (namesByGroup[job.sharedInstallGroupKey] ?? const <String>[])
          .where((name) => name.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final jobsAsync = ref.watch(technicianJobsProvider);
    final approvalConfig = ref.watch(approvalConfigProvider).value;
    final resolvedJob = jobsAsync.maybeWhen(
      data: (jobs) => initialJob ?? _findJob(jobs, jobId),
      orElse: () => initialJob,
    );
    final title = (resolvedJob?.invoiceNumber.trim().isNotEmpty ?? false)
        ? resolvedJob!.invoiceNumber.trim()
        : l.jobDetails;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(title)),
      body: SafeArea(
        child: jobsAsync.when(
          data: (jobs) {
            final job = initialJob ?? _findJob(jobs, jobId);
            if (job == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l.noMatchingJobs,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ArcticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.clientName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StatusBadge(status: job.status.name),
                        ],
                      ),
                      if (job.canTechnicianEdit(
                        approvalRequired:
                            approvalConfig?.jobApprovalRequired ?? true,
                        sharedApprovalRequired:
                            approvalConfig?.sharedJobApprovalRequired ?? true,
                      )) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/tech/submit', extra: job),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l.save),
                          ),
                        ),
                      ],
                      if (job.isApproved &&
                          job.isUnpaid &&
                          !job.isSharedInstall &&
                          job.editRequestedAt == null &&
                          (approvalConfig?.jobApprovalRequired ?? true)) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dlg) => AlertDialog(
                                  title: Text(l.requestEditConfirmTitle),
                                  content: Text(l.requestEditConfirmBody),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dlg).pop(false),
                                      child: Text(l.cancel),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(dlg).pop(true),
                                      child: Text(l.confirm),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              if (!context.mounted) return;
                              try {
                                await ref
                                    .read(jobRepositoryProvider)
                                    .resubmitForApproval(job.id);
                                if (!context.mounted) return;
                                AppFeedback.success(
                                  context,
                                  message: l.jobEditRequested,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                AppFeedback.error(
                                  context,
                                  message: l.genericError,
                                );
                              }
                            },
                            icon: const Icon(Icons.edit_off_outlined),
                            label: Text(l.requestEditJob),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ArcticTheme.arcticPending,
                              side: const BorderSide(
                                color: ArcticTheme.arcticPending,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.business_outlined,
                        label: l.company,
                        value: job.companyName,
                      ),
                      _DetailRow(
                        icon: Icons.receipt_long_outlined,
                        label: l.invoiceNumber,
                        value: job.invoiceNumber,
                      ),
                      _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: l.clientName,
                        value: job.clientName,
                      ),
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: l.clientPhone,
                        value: job.clientContact,
                        trailing: job.clientContact.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () async {
                                  await WhatsAppLauncher.openChat(
                                    job.clientContact,
                                  );
                                },
                                icon: const FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: ArcticTheme.arcticSuccess,
                                  size: 16,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                      ),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: l.date,
                        value: AppFormatters.date(job.date),
                      ),
                      _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: l.technician,
                        value: job.techName,
                      ),
                      // Expenses belong to the daily In/Out system — not displayed here.
                      if (job.adminNote.trim().isNotEmpty)
                        _DetailRow(
                          icon: Icons.info_outline_rounded,
                          label: l.adminNote,
                          value: job.adminNote,
                          valueColor: job.isRejected
                              ? ArcticTheme.arcticError
                              : ArcticTheme.arcticTextPrimary,
                        ),
                    ],
                  ),
                ),
                if (job.isSharedInstall) ...[
                  const SizedBox(height: 12),
                  ArcticCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.sharedInstall,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<String>>(
                          future: _sharedTechnicianNames(ref, job),
                          builder: (context, snapshot) {
                            final names = snapshot.data ?? const <String>[];
                            if (names.isEmpty) return const SizedBox.shrink();
                            return _DetailRow(
                              icon: Icons.groups_rounded,
                              label: l.technicians,
                              value: names.join(', '),
                            );
                          },
                        ),
                        const Divider(height: 16),
                        // ── Per-type breakdown: Invoice total vs. tech share ──
                        if (job.sharedInvoiceSplitUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.ac_unit_rounded,
                            label: l.splitAcLabel,
                            invoiceValue: '${job.sharedInvoiceSplitUnits}',
                            myShareValue: '${job.techSplitShare}',
                          ),
                        if (job.sharedInvoiceWindowUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.window_outlined,
                            label: l.windowAcLabel,
                            invoiceValue: '${job.sharedInvoiceWindowUnits}',
                            myShareValue: '${job.techWindowShare}',
                          ),
                        if (job.sharedInvoiceFreestandingUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.vertical_align_bottom_rounded,
                            label: l.freestandingAcLabel,
                            invoiceValue:
                                '${job.sharedInvoiceFreestandingUnits}',
                            myShareValue: '${job.techFreestandingShare}',
                          ),
                        if (job.sharedInvoiceBracketCount > 0)
                          _SharedTypeRow(
                            icon: Icons.hardware_outlined,
                            label: l.acOutdoorBracket,
                            invoiceValue: '${job.sharedInvoiceBracketCount}',
                            myShareValue: '${job.techBracketShare}',
                          ),
                        if (job.sharedInvoiceUninstallSplitUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.build_circle_outlined,
                            label: l.uninstallSplit,
                            invoiceValue:
                                '${job.sharedInvoiceUninstallSplitUnits}',
                            myShareValue: '${job.techUninstallSplitShare}',
                          ),
                        if (job.sharedInvoiceUninstallWindowUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.build_circle_outlined,
                            label: l.uninstallWindow,
                            invoiceValue:
                                '${job.sharedInvoiceUninstallWindowUnits}',
                            myShareValue: '${job.techUninstallWindowShare}',
                          ),
                        if (job.sharedInvoiceUninstallFreestandingUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.build_circle_outlined,
                            label: l.uninstallStanding,
                            invoiceValue:
                                '${job.sharedInvoiceUninstallFreestandingUnits}',
                            myShareValue:
                                '${job.techUninstallFreestandingShare}',
                          ),
                        if (job.sharedInvoiceDeliveryAmount > 0) ...[
                          const Divider(height: 16),
                          _SharedTypeRow(
                            icon: Icons.local_shipping_outlined,
                            label: l.sharedInvoiceDeliveryAmount,
                            invoiceValue: AppFormatters.currency(
                              job.sharedInvoiceDeliveryAmount,
                            ),
                            myShareValue: AppFormatters.currency(
                              job.charges?.deliveryAmount ??
                                  (job.sharedDeliveryTeamCount > 0
                                      ? job.sharedInvoiceDeliveryAmount /
                                            job.sharedDeliveryTeamCount
                                      : 0),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ArcticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.acUnits,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (job.acUnits.isEmpty)
                        Text('-', style: Theme.of(context).textTheme.bodyMedium)
                      else
                        ...job.acUnits.map(
                          (unit) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    unit.type,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  'x${unit.quantity}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: ArcticTheme.arcticTextSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const ArcticShimmer(count: 3),
          error: (error, _) => error is AppException
              ? ErrorCard(exception: error)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  JobModel? _findJob(List<JobModel> jobs, String id) {
    for (final job in jobs) {
      if (job.id == id) {
        return job;
      }
    }
    return null;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ArcticTheme.arcticTextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: valueColor),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[trailing!],
        ],
      ),
    );
  }
}

/// Two-column breakdown row for shared install types.
/// Shows [Invoice total] on the left and [Your share] highlighted on the right.
class _SharedTypeRow extends StatelessWidget {
  const _SharedTypeRow({
    required this.icon,
    required this.label,
    required this.invoiceValue,
    required this.myShareValue,
  });

  final IconData icon;
  final String label;
  final String invoiceValue;
  final String myShareValue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ArcticTheme.arcticTextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.invoice,
                            style: textTheme.labelSmall?.copyWith(
                              color: ArcticTheme.arcticTextSecondary,
                            ),
                          ),
                          Text(invoiceValue, style: textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.yourShare,
                            style: textTheme.labelSmall?.copyWith(
                              color: ArcticTheme.arcticBlue,
                            ),
                          ),
                          Text(
                            myShareValue,
                            style: textTheme.bodyMedium?.copyWith(
                              color: ArcticTheme.arcticBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
