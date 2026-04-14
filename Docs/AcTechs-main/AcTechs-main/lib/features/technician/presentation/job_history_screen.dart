import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/technician_day_in_out_summary.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';
import 'package:ac_techs/core/services/pdf_generator.dart';
import 'package:ac_techs/core/services/excel_export.dart';
import 'package:ac_techs/core/services/report_branding.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';
import 'package:ac_techs/features/settings/providers/app_branding_provider.dart';

enum _JobsReportPeriodType { month, range }

class _JobsReportOptions {
  const _JobsReportOptions({
    required this.periodType,
    required this.month,
    this.dateRange,
    required this.companyKey,
    required this.companyName,
  });

  final _JobsReportPeriodType periodType;
  final DateTime month;
  final DateTimeRange? dateRange;
  final String companyKey;
  final String companyName;
}

class JobHistoryScreen extends ConsumerStatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  ConsumerState<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends ConsumerState<JobHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _search = '';
  String _statusFilter = 'all';
  bool _sortNewest = true;
  bool _isExportingExcel = false;
  String _periodFilter = 'all';
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {});
    }
  }

  Future<Map<String, List<String>>> _sharedInstallerNamesByGroup(
    List<JobModel> jobs,
  ) async {
    final query = SharedInstallerNamesQuery.fromJobs(jobs);
    if (query.groupKeys.isEmpty) {
      return const <String, List<String>>{};
    }

    try {
      return ref.read(sharedInstallerNamesProvider(query).future);
    } catch (_) {
      return const <String, List<String>>{};
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _pickCustomDateRange() async {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: now,
      initialDateRange: _customDateRange,
      helpText: l.selectPdfDateRange,
    );
    if (picked == null) return;
    setState(() {
      _periodFilter = 'custom';
      _customDateRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
    });
  }

  DateTimeRange? _activeRange() {
    final now = DateTime.now();
    if (_periodFilter == 'today') {
      final start = DateTime(now.year, now.month, now.day);
      return DateTimeRange(start: start, end: start);
    }
    if (_periodFilter == 'month') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      return DateTimeRange(start: start, end: end);
    }
    if (_periodFilter == 'custom') {
      return _customDateRange;
    }
    return null;
  }

  String _periodLabel(AppLocalizations l) {
    final range = _activeRange();
    if (range == null) return l.all;
    if (_periodFilter == 'today') return l.today;
    if (_periodFilter == 'month') return l.thisMonth;
    return '${AppFormatters.date(range.start)} - ${AppFormatters.date(range.end)}';
  }

  ReportBrandingContext _jobsReportBranding(
    AppLocalizations l, {
    required List<JobModel> jobs,
    String? companyKey,
    String? companyName,
  }) {
    final appBranding =
        ref.read(appBrandingProvider).value ?? AppBrandingConfig.defaults();
    final companies = ref.read(activeCompaniesProvider).value ?? const [];

    var resolvedCompanyKey = companyKey ?? '';
    var resolvedCompanyName = companyName ?? '';

    if ((resolvedCompanyKey.isEmpty || resolvedCompanyKey == '__all__') &&
        jobs.isNotEmpty) {
      final companyKeys = jobs.map(_jobCompanyKey).toSet();
      if (companyKeys.length == 1) {
        resolvedCompanyKey = companyKeys.first;
        resolvedCompanyName = _jobCompanyName(l, jobs.first);
      }
    }

    final clientCompany =
        resolvedCompanyKey.isEmpty ||
            resolvedCompanyKey == '__all__' ||
            resolvedCompanyKey == '__no_company__'
        ? null
        : companies
              .where((company) => company.id == resolvedCompanyKey)
              .firstOrNull;

    return ReportBrandingContext.fromAppBranding(
      appBranding: appBranding,
      fallbackServiceName: l.ambiguousCompanyName,
      clientCompany: clientCompany,
      fallbackClientName: resolvedCompanyName,
    );
  }

  List<DateTime> _jobsReportMonths(List<JobModel> jobs) {
    final months = <DateTime>{};
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    for (final job in jobs) {
      final d = job.date;
      if (d == null || d.year < 2000) continue;
      final normalized = DateTime(d.year, d.month);
      if (normalized.isAfter(currentMonth)) continue;
      months.add(normalized);
    }

    final list = months.toList();
    list.sort((a, b) {
      final y = b.year.compareTo(a.year);
      return y != 0 ? y : b.month.compareTo(a.month);
    });
    return list;
  }

  ({DateTime first, DateTime last})? _jobsDateBounds(List<JobModel> jobs) {
    final dates = <DateTime>[];
    for (final job in jobs) {
      final d = job.date;
      if (d == null || d.year < 2000) continue;
      dates.add(DateTime(d.year, d.month, d.day));
    }
    if (dates.isEmpty) return null;
    dates.sort((a, b) => a.compareTo(b));
    return (first: dates.first, last: dates.last);
  }

  String _jobCompanyKey(JobModel job) {
    final id = job.companyId.trim();
    if (id.isNotEmpty) return id;
    final name = job.companyName.trim();
    return name.isNotEmpty ? name : '__no_company__';
  }

  String _jobCompanyName(AppLocalizations l, JobModel job) {
    final name = job.companyName.trim();
    return name.isNotEmpty ? name : l.noCompany;
  }

  bool _isInRange(DateTime date, DateTimeRange range) {
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    return !date.isBefore(start) && !date.isAfter(end);
  }

  List<JobModel> _jobsByPeriod({
    required List<JobModel> jobs,
    required _JobsReportPeriodType periodType,
    required DateTime month,
    DateTimeRange? dateRange,
  }) {
    return jobs.where((job) {
      final d = job.date;
      if (d == null) return false;
      if (periodType == _JobsReportPeriodType.range && dateRange != null) {
        return _isInRange(d, dateRange);
      }
      return d.year == month.year && d.month == month.month;
    }).toList();
  }

  Future<_JobsReportOptions?> _pickJobsReportOptions(
    List<JobModel> jobs,
  ) async {
    final l = AppLocalizations.of(context)!;
    final months = _jobsReportMonths(jobs);
    final bounds = _jobsDateBounds(jobs);
    if (months.isEmpty || bounds == null) return null;

    DateTime selectedMonth = months.first;
    DateTimeRange selectedRange = DateTimeRange(
      start: bounds.first,
      end: bounds.last,
    );
    _JobsReportPeriodType selectedPeriodType = _JobsReportPeriodType.month;
    String selectedCompanyKey = '__all__';
    String selectedCompanyName = l.all;

    List<({String key, String name})> companiesForSelection() {
      final scoped = _jobsByPeriod(
        jobs: jobs,
        periodType: selectedPeriodType,
        month: selectedMonth,
        dateRange: selectedRange,
      );
      final map = <String, String>{};
      for (final job in scoped) {
        map[_jobCompanyKey(job)] = _jobCompanyName(l, job);
      }
      final list = map.entries.map((e) => (key: e.key, name: e.value)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    }

    final picked = await showDialog<_JobsReportOptions>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            final companyItems = <({String key, String name})>[
              (key: '__all__', name: l.all),
              ...companiesForSelection(),
            ];

            if (!companyItems.any((item) => item.key == selectedCompanyKey)) {
              selectedCompanyKey = '__all__';
              selectedCompanyName = l.all;
            }

            return AlertDialog(
              title: Text(l.exportPdf),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.reportPreset),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l.monthlySummary),
                        selected:
                            selectedPeriodType == _JobsReportPeriodType.month,
                        onSelected: (_) {
                          setLocalState(() {
                            selectedPeriodType = _JobsReportPeriodType.month;
                            selectedCompanyKey = '__all__';
                            selectedCompanyName = l.all;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(l.selectPdfDateRange),
                        selected:
                            selectedPeriodType == _JobsReportPeriodType.range,
                        onSelected: (_) {
                          setLocalState(() {
                            selectedPeriodType = _JobsReportPeriodType.range;
                            selectedCompanyKey = '__all__';
                            selectedCompanyName = l.all;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selectedPeriodType == _JobsReportPeriodType.month) ...[
                    Text(l.selectDate),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<DateTime>(
                      initialValue: selectedMonth,
                      decoration: const InputDecoration(isDense: true),
                      items: months
                          .map(
                            (m) => DropdownMenuItem<DateTime>(
                              value: m,
                              child: Text(AppFormatters.monthLabel(l, m)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setLocalState(() {
                          selectedMonth = value;
                          selectedCompanyKey = '__all__';
                          selectedCompanyName = l.all;
                        });
                      },
                    ),
                  ] else ...[
                    Text(
                      '${AppFormatters.date(selectedRange.start)} - ${AppFormatters.date(selectedRange.end)}',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final pickedRange = await showDateRangePicker(
                          context: context,
                          firstDate: bounds.first,
                          lastDate: bounds.last,
                          initialDateRange: selectedRange,
                          helpText: l.selectPdfDateRange,
                        );
                        if (pickedRange == null) return;
                        setLocalState(() {
                          selectedRange = DateTimeRange(
                            start: DateTime(
                              pickedRange.start.year,
                              pickedRange.start.month,
                              pickedRange.start.day,
                            ),
                            end: DateTime(
                              pickedRange.end.year,
                              pickedRange.end.month,
                              pickedRange.end.day,
                            ),
                          );
                          selectedCompanyKey = '__all__';
                          selectedCompanyName = l.all;
                        });
                      },
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(l.selectDate),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(l.company),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCompanyKey,
                    decoration: const InputDecoration(isDense: true),
                    items: companyItems
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.key,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final selected = companyItems.firstWhere(
                        (item) => item.key == value,
                        orElse: () => (key: '__all__', name: l.all),
                      );
                      setLocalState(() {
                        selectedCompanyKey = selected.key;
                        selectedCompanyName = selected.name;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(
                    _JobsReportOptions(
                      periodType: selectedPeriodType,
                      month: selectedMonth,
                      dateRange:
                          selectedPeriodType == _JobsReportPeriodType.range
                          ? selectedRange
                          : null,
                      companyKey: selectedCompanyKey,
                      companyName: selectedCompanyName,
                    ),
                  ),
                  child: Text(l.exportPdf),
                ),
              ],
            );
          },
        );
      },
    );

    return picked;
  }

  Future<void> _exportJobsHistoryPdf({
    required List<JobModel> jobs,
    required String locale,
    required _JobsReportOptions options,
  }) async {
    final l = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider).value;
    final personName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : l.technician;

    final filteredByPeriod = _jobsByPeriod(
      jobs: jobs,
      periodType: options.periodType,
      month: options.month,
      dateRange: options.dateRange,
    );
    final filtered = options.companyKey == '__all__'
        ? filteredByPeriod
        : filteredByPeriod
              .where((job) => _jobCompanyKey(job) == options.companyKey)
              .toList();

    if (filtered.isEmpty) {
      if (!mounted) return;
      AppFeedback.error(context, message: l.noJobsForPeriod);
      return;
    }

    final reportTitle = switch (locale) {
      'ur' => 'جاب ہسٹری رپورٹ (${options.companyName})',
      'ar' => 'تقرير سجل الوظائف (${options.companyName})',
      _ => 'Jobs History Report (${options.companyName})',
    };

    try {
      final fromDate =
          options.dateRange?.start ??
          DateTime(options.month.year, options.month.month, 1);
      final toDate =
          options.dateRange?.end ??
          DateTime(options.month.year, options.month.month + 1, 0);
      final sharedInstallerNamesByGroup = await _sharedInstallerNamesByGroup(
        filtered,
      );

      final bytes = await PdfGenerator.generateJobsDetailsReport(
        jobs: filtered,
        title: reportTitle,
        locale: locale,
        sharedInstallerNamesByGroup: sharedInstallerNamesByGroup,
        technicianName: personName,
        fromDate: fromDate,
        toDate: toDate,
        maxPages: 2000,
        reportBranding: _jobsReportBranding(
          l,
          jobs: filtered,
          companyKey: options.companyKey,
          companyName: options.companyName,
        ),
      );

      final personToken = AppFormatters.slugify(personName).isEmpty
          ? 'technician'
          : AppFormatters.slugify(personName);
      final companyToken = options.companyKey == '__all__'
          ? 'all'
          : (AppFormatters.slugify(options.companyName).isEmpty
                ? 'company'
                : AppFormatters.slugify(options.companyName));
      final periodToken = options.dateRange != null
          ? '${options.dateRange!.start.year}-${options.dateRange!.start.month.toString().padLeft(2, '0')}-${options.dateRange!.start.day.toString().padLeft(2, '0')}-to-${options.dateRange!.end.year}-${options.dateRange!.end.month.toString().padLeft(2, '0')}-${options.dateRange!.end.day.toString().padLeft(2, '0')}'
          : AppFormatters.monthToken(options.month);

      await PdfGenerator.sharePdfBytes(
        bytes,
        '$personToken-$locale-$companyToken-$periodToken-jobs-history.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(context, message: l.couldNotExport);
    }
  }

  List<JobModel> _applyFilters(List<JobModel> jobs) {
    var filtered = jobs.toList();

    final range = _activeRange();
    if (range != null) {
      final start = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      filtered = filtered.where((j) {
        final d = j.date;
        if (d == null) return false;
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered
          .where(
            (j) =>
                j.clientName.toLowerCase().contains(q) ||
                j.invoiceNumber.toLowerCase().contains(q) ||
                j.sharedInstallGroupKey.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_statusFilter == 'shared') {
      filtered = filtered.where((j) => j.isSharedInstall).toList();
    } else if (_statusFilter != 'all') {
      filtered = filtered.where((j) => j.status.name == _statusFilter).toList();
    }

    filtered.sort((a, b) {
      if (_statusFilter == 'all' && a.status != b.status) {
        if (a.isPending) return -1;
        if (b.isPending) return 1;
      }
      final aDate = a.date ?? DateTime(2000);
      final bDate = b.date ?? DateTime(2000);
      return _sortNewest ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
    });

    return filtered;
  }

  List<TechnicianDayInOutSummary> _applyInOutFilters(
    List<EarningModel> earnings,
    List<ExpenseModel> expenses,
  ) {
    final activeRange = _activeRange();
    var summary = TechnicianDayInOutSummary.summarize(
      earnings: earnings,
      expenses: expenses,
      start: activeRange?.start,
      end: activeRange?.end,
    );

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      summary = summary.where((item) {
        final haystack = [
          AppFormatters.date(item.date),
          item.earningDetails.join(' '),
          item.workDetails.join(' '),
          item.homeDetails.join(' '),
        ].join(' ').toLowerCase();
        return haystack.contains(q);
      }).toList();
    }

    summary.sort(
      (a, b) =>
          _sortNewest ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
    );
    return summary;
  }

  Widget _buildJobsTab(
    AsyncValue<List<JobModel>> jobs,
    String locale,
    AppLocalizations l,
    VoidCallback refresh,
  ) {
    final approvalConfig = ref.watch(approvalConfigProvider).value;
    final jobSummary = ref.watch(technicianJobSummaryProvider).value;
    return jobs.when(
      data: (jobList) {
        final pendingCount = jobSummary?.pendingJobs ?? 0;
        final approvedCount = jobSummary?.approvedJobs ?? 0;
        final rejectedCount = jobSummary?.rejectedJobs ?? 0;
        final sharedCount = jobSummary?.sharedJobs ?? 0;
        final filtered = _applyFilters(jobList);
        final sharedNamesFuture = _sharedInstallerNamesByGroup(filtered);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
              child: ArcticSearchBar(
                hint: l.searchByClientOrInvoice,
                onChanged: (v) => setState(() => _search = v),
                trailing: SortButton<bool>(
                  currentValue: _sortNewest,
                  options: [
                    SortOption(label: l.newestFirst, value: true),
                    SortOption(label: l.oldestFirst, value: false),
                  ],
                  onSelected: (v) => setState(() => _sortNewest = v),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: StatusFilterChips(
                selected: _statusFilter,
                onSelected: (v) => setState(() => _statusFilter = v),
                pendingCount: pendingCount,
                approvedCount: approvedCount,
                rejectedCount: rejectedCount,
                sharedCount: sharedCount,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${l.date}: ${_periodLabel(l)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: ArcticTheme.arcticTextSecondary.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _search.isNotEmpty ? l.noMatchingJobs : l.noJobsYet,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: FutureBuilder<Map<String, List<String>>>(
                  future: sharedNamesFuture,
                  builder: (context, snapshot) {
                    final sharedInstallerNamesByGroup =
                        snapshot.data ?? const <String, List<String>>{};
                    return ArcticRefreshIndicator(
                      onRefresh: () async => refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final job = filtered[index];
                          return ContextMenuRegion(
                                menuItems: [
                                  ContextMenuItem(
                                    id: 'copy_invoice',
                                    label: l.copyInvoice,
                                    icon: Icons.copy_rounded,
                                  ),
                                  ContextMenuItem(
                                    id: 'export_pdf',
                                    label: l.exportAsPdf,
                                    icon: Icons.picture_as_pdf_rounded,
                                  ),
                                ],
                                onSelected: (action) async {
                                  if (action == 'copy_invoice') {
                                    Clipboard.setData(
                                      ClipboardData(text: job.invoiceNumber),
                                    );
                                    AppFeedback.success(
                                      context,
                                      message: l.invoiceCopied,
                                    );
                                  } else if (action == 'export_pdf') {
                                    try {
                                      final l = AppLocalizations.of(context)!;
                                      final sharedInstallerNamesByGroup =
                                          await _sharedInstallerNamesByGroup([
                                            job,
                                          ]);
                                      final bytes =
                                          await PdfGenerator.generateJobsDetailsReport(
                                            jobs: [job],
                                            title: l.jobs,
                                            locale: locale,
                                            sharedInstallerNamesByGroup:
                                                sharedInstallerNamesByGroup,
                                            technicianName: job.techName,
                                            fromDate: job.date,
                                            toDate: job.date,
                                            reportBranding: _jobsReportBranding(
                                              l,
                                              jobs: [job],
                                              companyKey: _jobCompanyKey(job),
                                              companyName: _jobCompanyName(
                                                l,
                                                job,
                                              ),
                                            ),
                                          );
                                      final invoiceToken =
                                          AppFormatters.slugify(
                                            job.invoiceNumber,
                                          ).isEmpty
                                          ? 'invoice'
                                          : AppFormatters.slugify(
                                              job.invoiceNumber,
                                            );
                                      await PdfGenerator.sharePdfBytes(
                                        bytes,
                                        '$invoiceToken-$locale-job.pdf',
                                      );
                                    } catch (_) {
                                      if (context.mounted) {
                                        AppFeedback.error(
                                          context,
                                          message: l.couldNotExport,
                                        );
                                      }
                                    }
                                  }
                                },
                                child: _HistoryJobCard(
                                  job: job,
                                  sharedTechnicianNames:
                                      sharedInstallerNamesByGroup[job
                                          .sharedInstallGroupKey] ??
                                      const <String>[],
                                  onTap: () => context.push(
                                    '/tech/job/${job.id}',
                                    extra: job,
                                  ),
                                  onEdit:
                                      job.canTechnicianEdit(
                                        approvalRequired:
                                            approvalConfig
                                                ?.jobApprovalRequired ??
                                            true,
                                        sharedApprovalRequired:
                                            approvalConfig
                                                ?.sharedJobApprovalRequired ??
                                            true,
                                      )
                                      ? () => context.push(
                                          '/tech/submit',
                                          extra: job,
                                        )
                                      : null,
                                ),
                              )
                              .animate(delay: (index * 80).ms)
                              .fadeIn()
                              .slideX(begin: 0.05);
                        },
                      ),
                    );
                  },
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
    );
  }

  Widget _buildInOutTab(
    AsyncValue<List<EarningModel>> earningsAsync,
    AsyncValue<List<ExpenseModel>> expensesAsync,
    AppLocalizations l,
    VoidCallback refresh,
  ) {
    return earningsAsync.when(
      data: (earnings) => expensesAsync.when(
        data: (expenses) {
          final summaries = _applyInOutFilters(earnings, expenses);
          final totalEarned = summaries.fold<double>(
            0,
            (sum, item) => sum + item.earned,
          );
          final totalExpenses = summaries.fold<double>(
            0,
            (sum, item) => sum + item.totalExpenses,
          );
          final net = totalEarned - totalExpenses;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                child: ArcticSearchBar(
                  hint: l.search,
                  onChanged: (v) => setState(() => _search = v),
                  trailing: SortButton<bool>(
                    currentValue: _sortNewest,
                    options: [
                      SortOption(label: l.newestFirst, value: true),
                      SortOption(label: l.oldestFirst, value: false),
                    ],
                    onSelected: (v) => setState(() => _sortNewest = v),
                  ),
                ),
              ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.04),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _HistoryMetricCard(
                        label: l.earningsIn,
                        value: AppFormatters.currency(totalEarned),
                        color: ArcticTheme.arcticSuccess,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HistoryMetricCard(
                        label: l.expensesOut,
                        value: AppFormatters.currency(totalExpenses),
                        color: ArcticTheme.arcticWarning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HistoryMetricCard(
                        label: l.netProfit,
                        value:
                            '${net >= 0 ? '+' : '-'} ${AppFormatters.currency(net.abs())}',
                        color: net >= 0
                            ? ArcticTheme.arcticSuccess
                            : ArcticTheme.arcticError,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 60.ms).fadeIn(duration: 240.ms).slideY(begin: 0.05),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${l.date}: ${_periodLabel(l)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ArcticTheme.arcticTextSecondary,
                    ),
                  ),
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 220.ms),
              if (summaries.isEmpty)
                Expanded(
                  child: Center(
                    child:
                        Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timeline_rounded,
                                  size: 56,
                                  color: ArcticTheme.arcticTextSecondary
                                      .withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l.noEntriesToday,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: ArcticTheme.arcticTextSecondary,
                                      ),
                                ),
                              ],
                            )
                            .animate()
                            .fadeIn(duration: 250.ms)
                            .scale(begin: const Offset(0.98, 0.98)),
                  ),
                )
              else
                Expanded(
                  child: ArcticRefreshIndicator(
                    onRefresh: () async => refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: summaries.length,
                      itemBuilder: (context, index) {
                        final s = summaries[index];
                        return _InOutHistoryCard(
                              summary: s,
                              onTap: () =>
                                  context.push('/tech/inout', extra: s.date),
                            )
                            .animate(delay: (index * 70).ms)
                            .fadeIn(duration: 220.ms)
                            .slideX(begin: 0.05);
                      },
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
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: ArcticShimmer(count: 5),
      ),
      error: (error, _) => error is AppException
          ? Center(child: ErrorCard(exception: error))
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(technicianJobsProvider);
    final earnings = ref.watch(techEarningsProvider);
    final expenses = ref.watch(techExpensesProvider);
    final locale = ref.watch(appLocaleProvider);
    final l = AppLocalizations.of(context)!;

    void refresh() {
      HapticFeedback.lightImpact();
      ref.invalidate(technicianJobsProvider);
      ref.invalidate(techEarningsProvider);
      ref.invalidate(techExpensesProvider);
    }

    return AppShortcuts(
      onRefresh: refresh,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.history),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l.jobs),
              Tab(text: l.inOut),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: l.selectDate,
              icon: const Icon(Icons.date_range_rounded),
              onSelected: (value) async {
                if (value == 'custom') {
                  await _pickCustomDateRange();
                  return;
                }
                setState(() {
                  _periodFilter = value;
                  if (value != 'custom') {
                    _customDateRange = null;
                  }
                });
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'all', child: Text(l.all)),
                PopupMenuItem(value: 'today', child: Text(l.today)),
                PopupMenuItem(value: 'month', child: Text(l.thisMonth)),
                PopupMenuItem(
                  value: 'custom',
                  child: Text(l.selectPdfDateRange),
                ),
              ],
            ),
            if (_tabController.index == 0) ...[
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: l.exportPdf,
                onPressed: () async {
                  final jobList = jobs.value;
                  if (jobList == null || jobList.isEmpty) return;
                  final options = await _pickJobsReportOptions(jobList);
                  if (options == null) return;
                  if (!mounted) return;
                  await _exportJobsHistoryPdf(
                    jobs: jobList,
                    locale: locale,
                    options: options,
                  );
                },
              ),
              IconButton(
                icon: _isExportingExcel
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined),
                tooltip: l.exportToExcel,
                onPressed: _isExportingExcel
                    ? null
                    : () async {
                        final jobList = jobs.value;
                        if (jobList == null || jobList.isEmpty) return;
                        final filtered = _applyFilters(jobList);
                        setState(() => _isExportingExcel = true);
                        try {
                          final sharedInstallerNamesByGroup =
                              await _sharedInstallerNamesByGroup(filtered);
                          await ExcelExport.exportJobsToExcel(
                            jobs: filtered,
                            sharedInstallerNamesByGroup:
                                sharedInstallerNamesByGroup,
                            reportBranding: _jobsReportBranding(
                              l,
                              jobs: filtered,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isExportingExcel = false);
                          }
                        }
                      },
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildJobsTab(jobs, locale, l, refresh),
              _buildInOutTab(earnings, expenses, l, refresh),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryJobCard extends StatelessWidget {
  const _HistoryJobCard({
    required this.job,
    required this.sharedTechnicianNames,
    required this.onTap,
    this.onEdit,
  });

  final JobModel job;
  final List<String> sharedTechnicianNames;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.clientName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.invoiceNumber} • ${AppFormatters.date(job.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: job.status.name),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l.save,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.ac_unit_rounded,
                label: AppFormatters.units(
                  job.isSharedInstall
                      ? (job.sharedContributionUnits > 0
                            ? job.sharedContributionUnits
                            : job.totalUnits)
                      : job.totalUnits,
                ),
              ),
              const SizedBox(width: 12),
              if (job.expenses > 0)
                Flexible(
                  child: _InfoChip(
                    icon: Icons.payments_outlined,
                    label: AppFormatters.currency(job.expenses),
                    color: ArcticTheme.arcticWarning,
                  ),
                ),
            ],
          ),
          if (job.isSharedInstall) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icon: Icons.groups_rounded,
                  label: l.sharedInstall,
                  color: ArcticTheme.arcticBlue,
                ),
                _InfoChip(
                  icon: Icons.receipt_long_rounded,
                  label: '${l.totalOnInvoice}: ${job.sharedInvoiceTotalUnits}',
                  color: ArcticTheme.arcticBlue,
                ),
                _InfoChip(
                  icon: Icons.person_outline,
                  label:
                      '${l.myShare}: ${job.sharedContributionUnits > 0 ? job.sharedContributionUnits : job.totalUnits}',
                  color: ArcticTheme.arcticSuccess,
                ),
                if (job.sharedInvoiceUninstallSplitUnits > 0)
                  _InfoChip(
                    icon: Icons.build_circle_outlined,
                    label:
                        '${l.uninstallSplit}: ${job.techUninstallSplitShare}/${job.sharedInvoiceUninstallSplitUnits}',
                    color: ArcticTheme.arcticWarning,
                  ),
                if (job.sharedInvoiceUninstallWindowUnits > 0)
                  _InfoChip(
                    icon: Icons.build_circle_outlined,
                    label:
                        '${l.uninstallWindow}: ${job.techUninstallWindowShare}/${job.sharedInvoiceUninstallWindowUnits}',
                    color: ArcticTheme.arcticWarning,
                  ),
                if (job.sharedInvoiceUninstallFreestandingUnits > 0)
                  _InfoChip(
                    icon: Icons.build_circle_outlined,
                    label:
                        '${l.uninstallStanding}: ${job.techUninstallFreestandingShare}/${job.sharedInvoiceUninstallFreestandingUnits}',
                    color: ArcticTheme.arcticWarning,
                  ),
                if (job.sharedInvoiceBracketCount > 0)
                  _InfoChip(
                    icon: Icons.hardware_outlined,
                    label:
                        '${l.acOutdoorBracket}: ${job.techBracketShare}/${job.sharedInvoiceBracketCount}',
                    color: ArcticTheme.arcticWarning,
                  ),
                if (sharedTechnicianNames.isNotEmpty)
                  _InfoChip(
                    icon: Icons.groups_rounded,
                    label: sharedTechnicianNames.join(', '),
                    color: ArcticTheme.arcticTextSecondary,
                  ),
              ],
            ),
          ],
          if (job.clientContact.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 15,
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
          if (job.isRejected && job.adminNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? ArcticTheme.arcticTextSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c),
        ),
      ],
    );
  }
}

class _HistoryMetricCard extends StatelessWidget {
  const _HistoryMetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ArcticCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ArcticTheme.arcticTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InOutHistoryCard extends StatelessWidget {
  const _InOutHistoryCard({required this.summary, this.onTap});

  final TechnicianDayInOutSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ArcticCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppFormatters.date(summary.date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${summary.net >= 0 ? '+' : '-'} ${AppFormatters.currency(summary.net.abs())}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: summary.net >= 0
                      ? ArcticTheme.arcticSuccess
                      : ArcticTheme.arcticError,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.trending_up_rounded,
                label:
                    '${l.earningsIn}: ${AppFormatters.currency(summary.earned)}',
                color: ArcticTheme.arcticSuccess,
              ),
              _InfoChip(
                icon: Icons.work_history_outlined,
                label:
                    '${l.workExpenses}: ${AppFormatters.currency(summary.workExpenses)}',
                color: ArcticTheme.arcticWarning,
              ),
              _InfoChip(
                icon: Icons.home_outlined,
                label:
                    '${l.homeExpenses}: ${AppFormatters.currency(summary.homeExpenses)}',
                color: ArcticTheme.arcticBlue,
              ),
            ],
          ),
          if (summary.earningDetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              summary.earningDetails.join(' | '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (summary.homeDetails.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              summary.homeDetails.join(' | '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ArcticTheme.arcticTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
