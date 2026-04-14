import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/services/excel_export.dart';
import 'package:ac_techs/core/services/pdf_export_service.dart';
import 'package:ac_techs/core/services/report_branding.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/settings/providers/app_branding_provider.dart';

enum _AdminInOutPeriodType { month, range }

class _AdminInOutReportOptions {
  const _AdminInOutReportOptions({
    required this.locale,
    required this.techId,
    required this.techName,
    required this.periodType,
    required this.month,
    this.dateRange,
  });

  final String locale;
  final String techId;
  final String techName;
  final _AdminInOutPeriodType periodType;
  final DateTime month;
  final DateTimeRange? dateRange;
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isExporting = false;
  bool _isExportingTodayCompanyPdf = false;
  bool _isExportingInOutPdf = false;
  String _periodFilter = 'all';
  String _reportPreset = 'all';
  String _technicianFilter = 'all';
  DateTimeRange? _customDateRange;

  Color _chartLabelColor(BuildContext context, Color background) {
    final theme = Theme.of(context);
    final useLightForeground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark;

    if (useLightForeground) {
      return theme.brightness == Brightness.dark
          ? theme.colorScheme.onSurface
          : theme.colorScheme.surface;
    }

    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : theme.colorScheme.onSurface;
  }

  Future<({List<EarningModel> earnings, List<ExpenseModel> expenses})>
  _fetchAdminInOutData() async {
    final earnings = await ref.read(earningRepositoryProvider).fetchEarnings();
    final expenses = await ref.read(expenseRepositoryProvider).fetchExpenses();
    return (earnings: earnings, expenses: expenses);
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

  List<DateTime> _invoiceReportMonths(List<JobModel> jobs) {
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

  List<DateTime> _inOutMonthsForTech({
    required String techId,
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
  }) {
    final months = <DateTime>{};
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    void add(DateTime? d) {
      if (d == null || d.year < 2000) return;
      final m = DateTime(d.year, d.month);
      if (m.isAfter(currentMonth)) return;
      months.add(m);
    }

    for (final item in earnings) {
      if (item.techId != techId) continue;
      add(item.date);
    }
    for (final item in expenses) {
      if (item.techId != techId) continue;
      add(item.date);
    }

    final list = months.toList()
      ..sort((a, b) {
        final y = b.year.compareTo(a.year);
        return y != 0 ? y : b.month.compareTo(a.month);
      });
    return list;
  }

  ({DateTime first, DateTime last})? _inOutBoundsForTech({
    required String techId,
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
  }) {
    final dates = <DateTime>[];

    void add(DateTime? d) {
      if (d == null) return;
      dates.add(DateTime(d.year, d.month, d.day));
    }

    for (final item in earnings) {
      if (item.techId == techId) add(item.date);
    }
    for (final item in expenses) {
      if (item.techId == techId) add(item.date);
    }

    if (dates.isEmpty) return null;
    dates.sort((a, b) => a.compareTo(b));
    return (first: dates.first, last: dates.last);
  }

  Future<_AdminInOutReportOptions?> _pickAdminInOutOptions({
    required List<UserModel> technicians,
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
  }) async {
    final l = AppLocalizations.of(context)!;
    if (technicians.isEmpty) return null;

    String selectedTechId = technicians.first.uid;
    String selectedTechName = technicians.first.name;
    String selectedLocale = ref.read(appLocaleProvider);
    _AdminInOutPeriodType selectedPeriodType = _AdminInOutPeriodType.month;

    List<DateTime> months = _inOutMonthsForTech(
      techId: selectedTechId,
      earnings: earnings,
      expenses: expenses,
    );
    if (months.isEmpty) return null;
    DateTime selectedMonth = months.first;
    var bounds = _inOutBoundsForTech(
      techId: selectedTechId,
      earnings: earnings,
      expenses: expenses,
    );
    if (bounds == null) return null;
    DateTimeRange selectedRange = DateTimeRange(
      start: bounds.first,
      end: bounds.last,
    );

    return showDialog<_AdminInOutReportOptions>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: Text(l.exportPdf),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.technician),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTechId,
                    decoration: const InputDecoration(isDense: true),
                    items: technicians
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t.uid,
                            child: Text(t.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final selected = technicians.firstWhere(
                        (t) => t.uid == value,
                        orElse: () => technicians.first,
                      );
                      final nextMonths = _inOutMonthsForTech(
                        techId: selected.uid,
                        earnings: earnings,
                        expenses: expenses,
                      );
                      final nextBounds = _inOutBoundsForTech(
                        techId: selected.uid,
                        earnings: earnings,
                        expenses: expenses,
                      );
                      if (nextMonths.isEmpty || nextBounds == null) return;

                      setLocalState(() {
                        selectedTechId = selected.uid;
                        selectedTechName = selected.name;
                        months = nextMonths;
                        bounds = nextBounds;
                        selectedMonth = months.first;
                        selectedRange = DateTimeRange(
                          start: bounds!.first,
                          end: bounds!.last,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(l.language),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLocale,
                    decoration: const InputDecoration(isDense: true),
                    items: [
                      DropdownMenuItem(value: 'en', child: Text(l.english)),
                      DropdownMenuItem(value: 'ur', child: Text(l.urdu)),
                      DropdownMenuItem(value: 'ar', child: Text(l.arabic)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => selectedLocale = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(l.reportPreset),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l.monthlySummary),
                        selected:
                            selectedPeriodType == _AdminInOutPeriodType.month,
                        onSelected: (_) => setLocalState(
                          () =>
                              selectedPeriodType = _AdminInOutPeriodType.month,
                        ),
                      ),
                      ChoiceChip(
                        label: Text(l.selectPdfDateRange),
                        selected:
                            selectedPeriodType == _AdminInOutPeriodType.range,
                        onSelected: (_) => setLocalState(
                          () =>
                              selectedPeriodType = _AdminInOutPeriodType.range,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (selectedPeriodType == _AdminInOutPeriodType.month) ...[
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
                        setLocalState(() => selectedMonth = value);
                      },
                    ),
                  ] else ...[
                    Text(
                      '${AppFormatters.date(selectedRange.start)} - ${AppFormatters.date(selectedRange.end)}',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: bounds!.first,
                          lastDate: bounds!.last,
                          initialDateRange: selectedRange,
                          helpText: l.selectPdfDateRange,
                        );
                        if (picked == null) return;
                        setLocalState(() {
                          selectedRange = DateTimeRange(
                            start: DateTime(
                              picked.start.year,
                              picked.start.month,
                              picked.start.day,
                            ),
                            end: DateTime(
                              picked.end.year,
                              picked.end.month,
                              picked.end.day,
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(l.selectDate),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(
                    _AdminInOutReportOptions(
                      locale: selectedLocale,
                      techId: selectedTechId,
                      techName: selectedTechName,
                      periodType: selectedPeriodType,
                      month: selectedMonth,
                      dateRange:
                          selectedPeriodType == _AdminInOutPeriodType.range
                          ? selectedRange
                          : null,
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
  }

  Future<void> _exportAdminInOutPdf({
    required _AdminInOutReportOptions options,
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
  }) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _isExportingInOutPdf = true);
    try {
      final normalizedMonth = DateTime(options.month.year, options.month.month);
      final normalizedRange = options.dateRange == null
          ? null
          : DateTimeRange(
              start: DateTime(
                options.dateRange!.start.year,
                options.dateRange!.start.month,
                options.dateRange!.start.day,
              ),
              end: DateTime(
                options.dateRange!.end.year,
                options.dateRange!.end.month,
                options.dateRange!.end.day,
                23,
                59,
                59,
              ),
            );

      final scopedEarnings = earnings.where((item) {
        if (item.techId != options.techId) return false;
        final d = item.date;
        if (d == null) return false;
        if (normalizedRange != null) {
          return !d.isBefore(normalizedRange.start) &&
              !d.isAfter(normalizedRange.end);
        }
        return d.year == normalizedMonth.year &&
            d.month == normalizedMonth.month;
      }).toList();

      final scopedExpenses = expenses.where((item) {
        if (item.techId != options.techId) return false;
        final d = item.date;
        if (d == null) return false;
        if (normalizedRange != null) {
          return !d.isBefore(normalizedRange.start) &&
              !d.isAfter(normalizedRange.end);
        }
        return d.year == normalizedMonth.year &&
            d.month == normalizedMonth.month;
      }).toList();

      if (scopedEarnings.isEmpty && scopedExpenses.isEmpty) {
        if (mounted) {
          ErrorSnackbar.show(context, message: l.noJobsForPeriod);
        }
        return;
      }

      final languageLabel = switch (options.locale) {
        'ur' => l.urdu,
        'ar' => l.arabic,
        _ => l.english,
      };
      final periodLabel = normalizedRange != null
          ? '${AppFormatters.date(normalizedRange.start)} - ${AppFormatters.date(normalizedRange.end)}'
          : AppFormatters.monthLabelForLocale(options.locale, normalizedMonth);
      final reportTitle = switch (options.locale) {
        'ur' => '${options.techName} ┌®█î Ï▒┘¥┘êÏ▒┘╣ ($languageLabel)',
        'ar' => 'Ï¬┘éÏ▒┘èÏ▒ ${options.techName} ($languageLabel)',
        _ => 'Report of ${options.techName} ($languageLabel)',
      };
      final techToken = AppFormatters.slugify(options.techName).isEmpty
          ? 'technician'
          : AppFormatters.slugify(options.techName);
      final periodToken = normalizedRange != null
          ? '${normalizedRange.start.year}-${normalizedRange.start.month.toString().padLeft(2, '0')}-${normalizedRange.start.day.toString().padLeft(2, '0')}-to-${normalizedRange.end.year}-${normalizedRange.end.month.toString().padLeft(2, '0')}-${normalizedRange.end.day.toString().padLeft(2, '0')}'
          : AppFormatters.monthToken(normalizedMonth);

      await PdfExportService.shareInOutReport(
        earnings: scopedEarnings,
        expenses: scopedExpenses,
        fileName: '$techToken-${options.locale}-$periodToken-in-out.pdf',
        locale: options.locale,
        technicianName: options.techName,
        reportTitle: reportTitle,
        reportDate: normalizedRange?.start ?? normalizedMonth,
        periodLabel: periodLabel,
        monthlyMode: true,
        reportBranding: _appOnlyReportBranding(l),
      );
    } catch (_) {
      if (mounted) {
        ErrorSnackbar.show(context, message: l.couldNotExport);
      }
    } finally {
      if (mounted) setState(() => _isExportingInOutPdf = false);
    }
  }

  Future<({DateTime month, String companyKey, String companyName})?>
  _pickInvoiceReportOptions(List<JobModel> jobs) async {
    final l = AppLocalizations.of(context)!;
    final months = _invoiceReportMonths(jobs);
    if (months.isEmpty) return null;

    DateTime selectedMonth = months.first;
    String selectedCompanyKey = '__all__';
    String selectedCompanyName = l.all;

    String companyKey(JobModel job) {
      final id = job.companyId.trim();
      if (id.isNotEmpty) return id;
      final name = job.companyName.trim();
      return name.isNotEmpty ? name : '__no_company__';
    }

    String companyName(JobModel job) {
      final name = job.companyName.trim();
      return name.isNotEmpty ? name : l.noCompany;
    }

    List<({String key, String name})> companiesForMonth(DateTime month) {
      final map = <String, String>{};
      for (final job in jobs) {
        final d = job.date;
        if (d == null) continue;
        if (d.year != month.year || d.month != month.month) continue;
        map[companyKey(job)] = companyName(job);
      }
      final entries = map.entries
          .map((e) => (key: e.key, name: e.value))
          .toList();
      entries.sort((a, b) => a.name.compareTo(b.name));
      return entries;
    }

    final picked =
        await showDialog<
          ({DateTime month, String companyKey, String companyName})
        >(
          context: context,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setLocalState) {
                final monthCompanies = companiesForMonth(selectedMonth);
                final companyItems = <({String key, String name})>[
                  (key: '__all__', name: l.all),
                  ...monthCompanies,
                ];

                if (!companyItems.any((c) => c.key == selectedCompanyKey)) {
                  selectedCompanyKey = '__all__';
                  selectedCompanyName = l.all;
                }

                return AlertDialog(
                  title: Text(l.exportTodayCompanyInvoices),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 12),
                      Text(l.company),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCompanyKey,
                        decoration: const InputDecoration(isDense: true),
                        items: companyItems
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c.key,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final selected = companyItems.firstWhere(
                            (c) => c.key == value,
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
                      onPressed: () => Navigator.of(ctx).pop((
                        month: selectedMonth,
                        companyKey: selectedCompanyKey,
                        companyName: selectedCompanyName,
                      )),
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

  AdminJobsQuery? _activeAdminQuery() {
    final range = _activeRange();
    final techId = _technicianFilter == 'all' ? null : _technicianFilter;
    if (range == null && techId == null) {
      return null;
    }

    return AdminJobsQuery(
      start: range == null
          ? null
          : DateTime(range.start.year, range.start.month, range.start.day),
      end: range == null
          ? null
          : DateTime(
              range.end.year,
              range.end.month,
              range.end.day,
              23,
              59,
              59,
            ),
      techId: techId,
    );
  }

  AsyncValue<AdminJobSummary> _summaryAsync() {
    final query = _activeAdminQuery();
    if (query == null) {
      return ref.watch(adminJobSummaryProvider);
    }
    return ref.watch(adminScopedJobSummaryProvider(query));
  }

  Future<List<JobModel>> _fetchJobsForCurrentScope() {
    final query = _activeAdminQuery();
    if (query == null) {
      return ref.read(jobRepositoryProvider).fetchAllAdminJobs();
    }
    return ref.read(filteredAdminJobsProvider(query).future);
  }

  String _periodLabel(AppLocalizations l) {
    final range = _activeRange();
    if (range == null) return l.all;
    if (_periodFilter == 'today') return l.today;
    if (_periodFilter == 'month') return l.thisMonth;
    return '${AppFormatters.date(range.start)} - ${AppFormatters.date(range.end)}';
  }

  ReportBrandingContext _appOnlyReportBranding(AppLocalizations l) {
    final appBranding =
        ref.read(appBrandingProvider).value ?? AppBrandingConfig.defaults();
    return ReportBrandingContext.fromAppBranding(
      appBranding: appBranding,
      fallbackServiceName: l.ambiguousCompanyName,
    );
  }

  ReportBrandingContext _companyInvoiceBranding(
    AppLocalizations l, {
    required String companyKey,
    required String companyName,
  }) {
    final appBranding =
        ref.read(appBrandingProvider).value ?? AppBrandingConfig.defaults();
    final companies = ref.read(allCompaniesProvider).value ?? const [];
    final clientCompany =
        companyKey == '__all__' || companyKey == '__no_company__'
        ? null
        : companies.where((company) => company.id == companyKey).firstOrNull;

    return ReportBrandingContext.fromAppBranding(
      appBranding: appBranding,
      fallbackServiceName: l.ambiguousCompanyName,
      clientCompany: clientCompany,
      fallbackClientName: companyName,
    );
  }

  Future<void> _exportToPdf(List<JobModel> jobs) async {
    final locale = ref.read(appLocaleProvider);
    try {
      await PdfExportService.previewJobsReport(
        context: context,
        jobs: jobs,
        locale: locale,
        reportBranding: _appOnlyReportBranding(AppLocalizations.of(context)!),
      );
    } catch (_) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotExport,
        );
      }
    }
  }

  Future<void> _exportToExcel(List<JobModel> jobs) async {
    setState(() => _isExporting = true);
    final localizations = AppLocalizations.of(context)!;

    try {
      if (jobs.isEmpty) {
        if (mounted) {
          ErrorSnackbar.show(context, message: localizations.noJobsForPeriod);
        }
        return;
      }

      final sharedInstallerNamesByGroup = await _sharedInstallerNamesByGroup(
        jobs,
      );

      await ExcelExport.exportJobsToExcel(
        jobs: jobs,
        sharedInstallerNamesByGroup: sharedInstallerNamesByGroup,
        reportBranding: _appOnlyReportBranding(localizations),
      );

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: localizations.exportReady(jobs.length),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, message: localizations.couldNotExport);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportTodayCompanyInvoicesPdf({
    required List<JobModel> jobs,
    required DateTime month,
    required String companyKey,
    required String companyName,
  }) async {
    setState(() => _isExportingTodayCompanyPdf = true);
    try {
      final l = AppLocalizations.of(context)!;
      final locale = ref.read(appLocaleProvider);

      String companyFilterKey(JobModel job) {
        final id = job.companyId.trim();
        if (id.isNotEmpty) return id;
        final name = job.companyName.trim();
        return name.isNotEmpty ? name : '__no_company__';
      }

      final scopedJobs = jobs.where((job) {
        final d = job.date;
        if (d == null) return false;
        if (d.year != month.year || d.month != month.month) return false;
        if (companyKey == '__all__') return true;
        return companyFilterKey(job) == companyKey;
      }).toList();

      if (scopedJobs.isEmpty) {
        if (mounted) {
          ErrorSnackbar.show(context, message: l.noJobsForPeriod);
        }
        return;
      }

      final reportTitle = switch (locale) {
        'ur' => '┌®┘à┘¥┘å█î Ïº┘å┘êÏºÏªÏ│ Ï▒┘¥┘êÏ▒┘╣ ($companyName)',
        'ar' => 'Ï¬┘éÏ▒┘èÏ▒ ┘ü┘êÏºÏ¬┘èÏ▒ Ïº┘äÏ┤Ï▒┘âÏ® ($companyName)',
        _ => 'Company Invoice Report ($companyName)',
      };

      final periodLabel = AppFormatters.monthLabel(l, month);
      final companyToken = AppFormatters.slugify(
        companyName.isEmpty ? l.noCompany : companyName,
      );
      final fileName =
          '${companyToken.isEmpty ? 'company' : companyToken}-${AppFormatters.monthToken(month)}-invoice-report.pdf';

      await PdfExportService.shareCompanyInvoicesReport(
        jobs: scopedJobs,
        fileName: fileName,
        locale: locale,
        reportTitle: reportTitle,
        periodLabel: periodLabel,
        reportBranding: _companyInvoiceBranding(
          l,
          companyKey: companyKey,
          companyName: companyName,
        ),
      );
    } catch (_) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotExport,
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingTodayCompanyPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = _summaryAsync();
    final usersAsync = ref.watch(allUsersProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.analytics),
        actions: [
          PopupMenuButton<String>(
            tooltip: l.technicians,
            icon: const Icon(Icons.manage_accounts_outlined),
            onSelected: (value) {
              setState(() => _technicianFilter = value);
            },
            itemBuilder: (_) {
              final users = usersAsync.value ?? const <UserModel>[];
              final techs = users.where((u) => !u.isAdmin).toList();
              return [
                PopupMenuItem(value: 'all', child: Text(l.all)),
                ...techs.map(
                  (u) => PopupMenuItem(value: u.uid, child: Text(u.name)),
                ),
              ];
            },
          ),
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
              PopupMenuItem(value: 'custom', child: Text(l.selectPdfDateRange)),
            ],
          ),
          IconButton(
            onPressed: _isExportingInOutPdf
                ? null
                : () async {
                    final users = usersAsync.value;
                    if (users == null) {
                      return;
                    }
                    final inOutData = await _fetchAdminInOutData();
                    if (!mounted) return;
                    final techs = users.where((u) => !u.isAdmin).toList();
                    final picked = await _pickAdminInOutOptions(
                      technicians: techs,
                      earnings: inOutData.earnings,
                      expenses: inOutData.expenses,
                    );
                    if (picked == null) return;
                    await _exportAdminInOutPdf(
                      options: picked,
                      earnings: inOutData.earnings,
                      expenses: inOutData.expenses,
                    );
                  },
            icon: _isExportingInOutPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.receipt_long_rounded),
            tooltip: l.inOut,
          ),
          IconButton(
            onPressed: _isExportingTodayCompanyPdf
                ? null
                : () async {
                    final jobs = await _fetchJobsForCurrentScope();
                    if (!mounted || jobs.isEmpty) return;
                    final picked = await _pickInvoiceReportOptions(jobs);
                    if (picked == null) return;
                    _exportTodayCompanyInvoicesPdf(
                      jobs: jobs,
                      month: picked.month,
                      companyKey: picked.companyKey,
                      companyName: picked.companyName,
                    );
                  },
            icon: _isExportingTodayCompanyPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.apartment_rounded),
            tooltip: l.exportTodayCompanyInvoices,
          ),
          IconButton(
            onPressed: () async {
              final jobs = await _fetchJobsForCurrentScope();
              if (!mounted || jobs.isEmpty) return;
              await _exportToPdf(jobs);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l.exportToPdf,
          ),
          IconButton(
            onPressed:
                _isExporting || ((summaryAsync.value?.totalJobs ?? 0) == 0)
                ? null
                : () async {
                    final jobs = await _fetchJobsForCurrentScope();
                    if (!mounted || jobs.isEmpty) return;
                    await _exportToExcel(jobs);
                  },
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: l.exportToExcel,
          ),
        ],
      ),
      body: SafeArea(
        child: summaryAsync.when(
          data: (summary) {
            final techTotals = summary.technicianJobCounts;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.reportPreset,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment<String>(
                      value: 'all',
                      label: Text(l.all),
                      icon: const Icon(Icons.dashboard_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'byTech',
                      label: Text(l.byTechnician),
                      icon: const Icon(Icons.manage_accounts_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'uninstall',
                      label: Text(l.uninstallRateBreakdown),
                      icon: const Icon(Icons.build_circle_outlined),
                    ),
                  ],
                  selected: {_reportPreset},
                  onSelectionChanged: (selection) {
                    setState(() => _reportPreset = selection.first);
                  },
                  showSelectedIcon: false,
                ),
                if (_reportPreset == 'byTech') ...[
                  const SizedBox(height: 8),
                  Text(
                    '${l.technician}: ${_technicianFilter == 'all' ? l.all : (usersAsync.value?.firstWhere(
                                (u) => u.uid == _technicianFilter,
                                orElse: () => const UserModel(uid: '', name: '', email: ''),
                              ).name ?? l.all)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ArcticTheme.arcticTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${l.date}: ${_periodLabel(l)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                    ),
                  ),
                ),
                if (_reportPreset == 'uninstall') ...[
                  ArcticCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.uninstallRateBreakdown,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: l.uninstallSplit,
                          value:
                              '${summary.uninstallSplitUnits} (${summary.uninstallTotal == 0 ? 0 : ((summary.uninstallSplitUnits / summary.uninstallTotal) * 100).toStringAsFixed(1)}%)',
                        ),
                        const Divider(height: 16),
                        _SummaryRow(
                          label: l.uninstallWindow,
                          value:
                              '${summary.uninstallWindowUnits} (${summary.uninstallTotal == 0 ? 0 : ((summary.uninstallWindowUnits / summary.uninstallTotal) * 100).toStringAsFixed(1)}%)',
                        ),
                        const Divider(height: 16),
                        _SummaryRow(
                          label: l.uninstallStanding,
                          value:
                              '${summary.uninstallStandingUnits} (${summary.uninstallTotal == 0 ? 0 : ((summary.uninstallStandingUnits / summary.uninstallTotal) * 100).toStringAsFixed(1)}%)',
                        ),
                        const Divider(height: 16),
                        _SummaryRow(
                          label: l.catUninstallOldAc,
                          value:
                              '${summary.uninstallOldUnits} (${summary.uninstallTotal == 0 ? 0 : ((summary.uninstallOldUnits / summary.uninstallTotal) * 100).toStringAsFixed(1)}%)',
                        ),
                        const Divider(height: 16),
                        _SummaryRow(
                          label: l.uninstalls,
                          value: '${summary.uninstallTotal}',
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                ],
                // Status Pie Chart
                ArcticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.jobStatus,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (summary.totalJobs == 0)
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.noDataYet,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ArcticTheme.arcticTextSecondary,
                                  ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              Expanded(
                                child: RepaintBoundary(
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 3,
                                      centerSpaceRadius: 40,
                                      sections: [
                                        PieChartSectionData(
                                          value: summary.approvedJobs
                                              .toDouble(),
                                          color: ArcticTheme.arcticSuccess,
                                          title: '${summary.approvedJobs}',
                                          titleStyle: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: _chartLabelColor(
                                                  context,
                                                  ArcticTheme.arcticSuccess,
                                                ),
                                              ),
                                          radius: 50,
                                        ),
                                        PieChartSectionData(
                                          value: summary.pendingJobs.toDouble(),
                                          color: ArcticTheme.arcticPending,
                                          title: '${summary.pendingJobs}',
                                          titleStyle: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: _chartLabelColor(
                                                  context,
                                                  ArcticTheme.arcticPending,
                                                ),
                                              ),
                                          radius: 50,
                                        ),
                                        PieChartSectionData(
                                          value: summary.rejectedJobs
                                              .toDouble(),
                                          color: ArcticTheme.arcticError,
                                          title: '${summary.rejectedJobs}',
                                          titleStyle: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: _chartLabelColor(
                                                  context,
                                                  ArcticTheme.arcticError,
                                                ),
                                              ),
                                          radius: 50,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Legend(
                                    color: ArcticTheme.arcticSuccess,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.approved,
                                  ),
                                  const SizedBox(height: 8),
                                  _Legend(
                                    color: ArcticTheme.arcticPending,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.pending,
                                  ),
                                  const SizedBox(height: 8),
                                  _Legend(
                                    color: ArcticTheme.arcticError,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.rejected,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                // Jobs per Technician Bar Chart
                ArcticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.jobsPerTechnician,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (techTotals.isEmpty)
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.noDataYet,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ArcticTheme.arcticTextSecondary,
                                  ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 200,
                          child: RepaintBoundary(
                            child: BarChart(
                              BarChartData(
                                barGroups: techTotals
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => BarChartGroupData(
                                        x: e.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: e.value.jobCount.toDouble(),
                                            color: ArcticTheme.arcticBlue,
                                            width: 20,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(6),
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() < techTotals.length) {
                                          final name = techTotals[value.toInt()]
                                              .displayName;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              name.length > 6
                                                  ? '${name.substring(0, 6)}..'
                                                  : name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: ArcticTheme
                                                        .arcticTextSecondary,
                                                  ),
                                            ),
                                          );
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),

                // Summary
                ArcticCard(
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.totalJobs,
                        value: '${summary.totalJobs}',
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.totalUnits,
                        value: AppFormatters.units(
                          summary.invoiceAwareUnitTotal,
                        ),
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: '${l.sharedInstall} ${l.jobs}',
                        value: '${summary.sharedJobsCount}',
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label:
                            '${l.sharedInstall} ${l.invoice} ${l.totalUnits}',
                        value: AppFormatters.units(summary.sharedInvoiceUnits),
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: '${l.sharedInstall} ${l.invoice}',
                        value: '${summary.sharedInvoiceCount}',
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: '${l.sharedInstall} ${l.acOutdoorBracket}',
                        value: '${summary.sharedInvoiceBrackets}',
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.totalExpenses,
                        value: AppFormatters.currency(summary.totalExpenses),
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.technicians,
                        value: '${summary.technicianCount}',
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: ArcticShimmer(count: 3, height: 120),
          ),
          error: (error, _) => error is AppException
              ? Center(child: ErrorCard(exception: error))
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
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
