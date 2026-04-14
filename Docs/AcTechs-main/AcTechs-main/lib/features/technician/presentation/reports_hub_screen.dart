import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/services/pdf_export_service.dart';
import 'package:ac_techs/core/services/pdf_generator.dart';
import 'package:ac_techs/core/services/report_branding.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/settings/providers/app_branding_provider.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen> {
  bool _isGenerating = false;
  String? _activeReport;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.reports),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => ZoomDrawerScope.of(context).toggle(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── Header ──
            Text(
              l.reportsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),

            // ── Daily In/Out ──
            _ReportCard(
              icon: Icons.today_rounded,
              color: ArcticTheme.arcticSuccess,
              title: l.dailyInOutReport,
              subtitle: l.dailyInOutReportDesc,
              isLoading: _activeReport == 'dailyInOut',
              onTap: _isGenerating ? null : () => _generateDailyInOut(l),
            ),

            // ── Monthly In/Out ──
            _ReportCard(
              icon: Icons.calendar_month_rounded,
              color: ArcticTheme.arcticBlue,
              title: l.monthlyInOutReport,
              subtitle: l.monthlyInOutReportDesc,
              isLoading: _activeReport == 'monthlyInOut',
              onTap: _isGenerating ? null : () => _generateMonthlyInOut(l),
            ),

            // ── AC Installs ──
            _ReportCard(
              icon: Icons.ac_unit_rounded,
              color: ArcticTheme.arcticPurple,
              title: l.acInstallsReport,
              subtitle: l.acInstallsReportDesc,
              isLoading: _activeReport == 'acInstalls',
              onTap: _isGenerating ? null : () => _generateAcInstalls(l),
            ),

            // ── Jobs Report ──
            _ReportCard(
              icon: Icons.work_rounded,
              color: ArcticTheme.arcticWarning,
              title: l.jobsReport,
              subtitle: l.jobsReportDesc,
              isLoading: _activeReport == 'jobs',
              onTap: _isGenerating ? null : () => _generateJobsReport(l),
            ),

            // ── Shared Install ──
            _ReportCard(
              icon: Icons.group_work_rounded,
              color: ArcticTheme.arcticBlueDark,
              title: l.sharedInstallReport,
              subtitle: l.sharedInstallReportDesc,
              isLoading: _activeReport == 'sharedInstall',
              onTap: _isGenerating ? null : () => _generateSharedInstalls(l),
            ),

            // ── Payment Settlement ──
            _ReportCard(
              icon: Icons.payments_rounded,
              color: ArcticTheme.arcticSuccess,
              title: l.paymentSettlementReport,
              subtitle: l.paymentSettlementReportDesc,
              isLoading: _activeReport == 'settlement',
              onTap: _isGenerating ? null : () => _generateSettlementReport(l),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Report generation helpers ──────────────────────────────────────────

  ReportBrandingContext? _buildBranding() {
    final appBranding =
        ref.read(appBrandingProvider).value ?? AppBrandingConfig.defaults();
    return ReportBrandingContext.fromAppBranding(
      appBranding: appBranding,
      fallbackServiceName: 'AC Techs',
    );
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  String get _techName =>
      ref.read(currentUserProvider).value?.name ?? 'Technician';

  Future<void> _generateDailyInOut(AppLocalizations l) async {
    _setActive('dailyInOut');
    try {
      final today = DateTime.now();
      final month = DateTime(today.year, today.month);
      final earnings =
          ref.read(monthlyEarningsProvider(month)).value ?? <EarningModel>[];
      final expenses =
          ref.read(monthlyExpensesProvider(month)).value ?? <ExpenseModel>[];

      final todayEarnings = earnings
          .where((e) => _isSameDay(e.date, today))
          .toList();
      final todayExpenses = expenses
          .where((e) => _isSameDay(e.date, today))
          .toList();

      if (todayEarnings.isEmpty && todayExpenses.isEmpty) {
        _showEmpty(l);
        return;
      }

      await PdfExportService.shareInOutReport(
        earnings: todayEarnings,
        expenses: todayExpenses,
        fileName:
            'daily_inout_${AppFormatters.date(today).replaceAll('/', '-')}.pdf',
        locale: _locale,
        technicianName: _techName,
        reportTitle: l.dailyInOutReport,
        reportDate: today,
        reportBranding: _buildBranding(),
      );
    } catch (e) {
      if (mounted) AppFeedback.error(context, message: e.toString());
    } finally {
      _clearActive();
    }
  }

  Future<void> _generateMonthlyInOut(AppLocalizations l) async {
    final picked = await _pickMonth();
    if (picked == null) return;

    _setActive('monthlyInOut');
    try {
      final month = DateTime(picked.year, picked.month);
      final earnings =
          ref.read(monthlyEarningsProvider(month)).value ?? <EarningModel>[];
      final expenses =
          ref.read(monthlyExpensesProvider(month)).value ?? <ExpenseModel>[];

      if (earnings.isEmpty && expenses.isEmpty) {
        _showEmpty(l);
        return;
      }

      await PdfExportService.shareInOutReport(
        earnings: earnings,
        expenses: expenses,
        fileName:
            'monthly_inout_${picked.year}_${picked.month.toString().padLeft(2, '0')}.pdf',
        locale: _locale,
        technicianName: _techName,
        reportTitle: l.monthlyInOutReport,
        reportDate: month,
        monthlyMode: true,
        reportBranding: _buildBranding(),
      );
    } catch (e) {
      if (mounted) AppFeedback.error(context, message: e.toString());
    } finally {
      _clearActive();
    }
  }

  Future<void> _generateAcInstalls(AppLocalizations l) async {
    final range = await _pickDateRange();
    if (range == null) return;

    _setActive('acInstalls');
    try {
      final allJobs = ref.read(technicianJobsProvider).value ?? <JobModel>[];
      final filtered = allJobs
          .where(
            (j) =>
                j.date != null &&
                !j.date!.isBefore(range.start) &&
                !j.date!.isAfter(range.end),
          )
          .toList();

      if (filtered.isEmpty) {
        _showEmpty(l);
        return;
      }

      final bytes = await PdfGenerator.generateJobsDetailsReport(
        jobs: filtered,
        title: l.acInstallsReport,
        locale: _locale,
        reportBranding: _buildBranding(),
      );
      await PdfGenerator.sharePdfBytes(
        bytes,
        'ac_installs_${AppFormatters.date(range.start).replaceAll('/', '-')}_${AppFormatters.date(range.end).replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      if (mounted) AppFeedback.error(context, message: e.toString());
    } finally {
      _clearActive();
    }
  }

  Future<void> _generateJobsReport(AppLocalizations l) async {
    final range = await _pickDateRange();
    if (range == null) return;

    _setActive('jobs');
    try {
      final allJobs = ref.read(technicianJobsProvider).value ?? <JobModel>[];
      final filtered = allJobs
          .where(
            (j) =>
                j.date != null &&
                !j.date!.isBefore(range.start) &&
                !j.date!.isAfter(range.end),
          )
          .toList();

      if (filtered.isEmpty) {
        _showEmpty(l);
        return;
      }

      final bytes = await PdfGenerator.generateJobsDetailsReport(
        jobs: filtered,
        title: l.jobsReport,
        locale: _locale,
        reportBranding: _buildBranding(),
      );
      await PdfGenerator.sharePdfBytes(
        bytes,
        'jobs_report_${AppFormatters.date(range.start).replaceAll('/', '-')}_${AppFormatters.date(range.end).replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      if (mounted) AppFeedback.error(context, message: e.toString());
    } finally {
      _clearActive();
    }
  }

  Future<void> _generateSharedInstalls(AppLocalizations l) async {
    _setActive('sharedInstall');
    try {
      final allJobs = ref.read(technicianJobsProvider).value ?? <JobModel>[];
      final shared = allJobs.where((j) => j.isSharedInstall).toList();

      if (shared.isEmpty) {
        _showEmpty(l);
        return;
      }

      final bytes = await PdfGenerator.generateJobsDetailsReport(
        jobs: shared,
        title: l.sharedInstallReport,
        locale: _locale,
        reportBranding: _buildBranding(),
      );
      await PdfGenerator.sharePdfBytes(
        bytes,
        'shared_installs_${AppFormatters.date(DateTime.now()).replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      if (mounted) AppFeedback.error(context, message: e.toString());
    } finally {
      _clearActive();
    }
  }

  Future<void> _generateSettlementReport(AppLocalizations l) async {
    _setActive('settlement');
    try {
      final allJobs = ref.read(technicianJobsProvider).value ?? <JobModel>[];
      final settled = allJobs
          .where((j) => j.settlementStatus != JobSettlementStatus.unpaid)
          .toList();

      if (settled.isEmpty) {
        _showEmpty(l);
        return;
      }

      final bytes = await PdfGenerator.generateJobsDetailsReport(
        jobs: settled,
        title: l.paymentSettlementReport,
        locale: _locale,
        reportBranding: _buildBranding(),
      );
      await PdfGenerator.sharePdfBytes(
        bytes,
        'settlement_report_${AppFormatters.date(DateTime.now()).replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      if (mounted) AppFeedback.error(context, message: e.toString());
    } finally {
      _clearActive();
    }
  }

  // ── Pickers ────────────────────────────────────────────────────────────

  Future<DateTime?> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2023),
      lastDate: now,
      helpText: AppLocalizations.of(context)!.selectMonth,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    return picked;
  }

  Future<DateTimeRange?> _pickDateRange() async {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      helpText: AppLocalizations.of(context)!.selectDateRange,
    );
  }

  // ── State helpers ──────────────────────────────────────────────────────

  void _setActive(String key) {
    if (!mounted) return;
    setState(() {
      _isGenerating = true;
      _activeReport = key;
    });
    HapticFeedback.mediumImpact();
  }

  void _clearActive() {
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _activeReport = null;
    });
  }

  void _showEmpty(AppLocalizations l) {
    if (mounted) AppFeedback.info(context, message: l.noDataForPeriod);
    _clearActive();
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ── Reusable report card widget ──────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: color,
                          ),
                        )
                      : Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
