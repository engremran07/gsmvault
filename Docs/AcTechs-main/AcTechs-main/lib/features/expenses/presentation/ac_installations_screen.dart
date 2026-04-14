import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';

class AcInstallationsScreen extends ConsumerStatefulWidget {
  const AcInstallationsScreen({super.key});

  @override
  ConsumerState<AcInstallationsScreen> createState() =>
      _AcInstallationsScreenState();
}

class _AcInstallationsScreenState extends ConsumerState<AcInstallationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final todaysJobsAsync = ref.watch(todaysJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.acInstallations),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: ArcticTheme.arcticBlue,
            tooltip: l.logAcInstallations,
            onPressed: () => context.push('/tech/submit'),
          ),
        ],
      ),
      body: SafeArea(
        child: ArcticRefreshIndicator(
          onRefresh: () async {
            // Invalidate the parent stream; todaysJobsProvider is now derived from it
            ref.invalidate(technicianJobsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInstallSourceCard(theme, todaysJobsAsync),
              const SizedBox(height: 16),
              _buildJobInstallSection(theme, todaysJobsAsync),
            ],
          ),
        ),
      ),
    );
  }

  int _countUnits(List<JobModel> jobs, String type) {
    return jobs.fold<int>(
      0,
      (sum, job) =>
          sum +
          job.acUnits
              .where((unit) => unit.type == type)
              .fold<int>(0, (unitSum, unit) => unitSum + unit.quantity),
    );
  }

  Widget _buildInstallSourceCard(
    ThemeData theme,
    AsyncValue<List<JobModel>> todaysJobsAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    final jobs = todaysJobsAsync.value ?? const <JobModel>[];
    final splitCount = _countUnits(jobs, 'Split AC');
    final windowCount = _countUnits(jobs, 'Window AC');
    final freestandingCount = _countUnits(jobs, 'Freestanding AC');
    final cassetteCount = _countUnits(jobs, 'Cassette AC');

    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.jobInstallationsToday, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            l.manualInstallLogDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ArcticTheme.arcticTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InstallSummaryChip(label: l.splitAcLabel, value: splitCount),
              _InstallSummaryChip(label: l.windowAcLabel, value: windowCount),
              _InstallSummaryChip(
                label: l.freestandingAcLabel,
                value: freestandingCount,
              ),
              _InstallSummaryChip(label: l.cassette, value: cassetteCount),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
  }

  Widget _buildJobInstallSection(
    ThemeData theme,
    AsyncValue<List<JobModel>> todaysJobsAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    final jobs = todaysJobsAsync.value ?? const <JobModel>[];

    if (todaysJobsAsync.isLoading) {
      return const Center(child: LinearProgressIndicator());
    }

    if (jobs.isEmpty) {
      return ArcticCard(
        child: Column(
          children: [
            const Icon(
              Icons.air_outlined,
              size: 56,
              color: ArcticTheme.arcticTextSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              l.noJobsToday,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ArcticTheme.arcticTextSecondary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.jobInstallationsToday, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...List.generate(
          jobs.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == jobs.length - 1 ? 0 : 12),
            child: _buildJobCard(theme, jobs[index], l),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildJobCard(ThemeData theme, JobModel job, AppLocalizations l) {
    final unitSummary = job.acUnits
        .where((unit) => unit.quantity > 0)
        .map((unit) => '${unit.type}: ${unit.quantity}')
        .join(' • ');

    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.date != null ? AppFormatters.date(job.date!) : '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
              ),
              StatusBadge(status: job.status.name),
            ],
          ),
          const SizedBox(height: 8),
          Text(job.invoiceNumber, style: theme.textTheme.titleMedium),
          if (unitSummary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(unitSummary, style: theme.textTheme.bodyMedium),
          ],
          if (job.isSharedInstall) ...[
            const SizedBox(height: 8),
            _buildInstallTypeRow(
              theme,
              label: l.totalOnInvoice,
              total: job.totalUnits,
              share: job.sharedContributionUnits > 0
                  ? job.sharedContributionUnits
                  : job.totalUnits,
              l: l,
            ),
          ],
          if (job.adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              job.adminNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: job.isRejected
                    ? ArcticTheme.arcticError
                    : ArcticTheme.arcticWarning,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildInstallTypeRow(
    ThemeData theme, {
    required String label,
    required int total,
    required int share,
    required AppLocalizations l,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArcticTheme.arcticBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ArcticTheme.arcticBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: ${AppFormatters.units(total)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${l.myShare}: ${AppFormatters.units(share)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: ArcticTheme.arcticBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallSummaryChip extends StatelessWidget {
  const _InstallSummaryChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    const color = ArcticTheme.arcticBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$value ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }
}
