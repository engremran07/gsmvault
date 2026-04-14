import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/services/pdf_export_service.dart';
import 'package:ac_techs/core/services/report_branding.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/category_translator.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';
import 'package:ac_techs/features/settings/providers/app_branding_provider.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';

/// Unified daily In/Out screen — techs add earnings (IN) and expenses (OUT)
/// in a single view with a running profit/loss summary on top.
///
/// Pass [selectedDate] to view/edit entries for a historical date rather than
/// today. When [selectedDate] is set, the add-entry form is hidden.
class DailyInOutScreen extends ConsumerStatefulWidget {
  final DateTime? selectedDate;

  const DailyInOutScreen({super.key, this.selectedDate});

  @override
  ConsumerState<DailyInOutScreen> createState() => _DailyInOutScreenState();
}

enum _ReportPeriodType { month, range }

class _InOutReportOptions {
  final String locale;
  final _ReportPeriodType periodType;
  final DateTime month;
  final DateTimeRange? dateRange;

  const _InOutReportOptions({
    required this.locale,
    required this.periodType,
    required this.month,
    this.dateRange,
  });
}

class _DailyInOutScreenState extends ConsumerState<DailyInOutScreen> {
  /// true = IN (earning), false = OUT (expense)
  bool _isIn = true;
  bool _isSaving = false;
  String _expenseType = AppConstants.expenseTypeWork;
  bool _approvalBaselineReady = false;
  bool _isExportingTodayPdf = false;
  late DateTime _selectedExportMonth;
  final Set<String> _approvedKnownIds = <String>{};

  /// Batch entry rows — each has its own category, amount, remark
  final List<_EntryRow> _entryRows = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedExportMonth = DateTime(now.year, now.month);
    _entryRows.add(
      _EntryRow(
        category: AppConstants.earningCategories.first,
        amountController: TextEditingController(),
        remarkController: TextEditingController(),
      ),
    );
  }

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  DateTime _effectiveExportMonth(List<DateTime> monthsWithData) {
    if (monthsWithData.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month);
    }
    for (final month in monthsWithData) {
      if (_sameMonth(month, _selectedExportMonth)) {
        return month;
      }
    }
    return monthsWithData.first;
  }

  @override
  void dispose() {
    for (final row in _entryRows) {
      row.amountController.dispose();
      row.remarkController.dispose();
    }
    super.dispose();
  }

  void _onDirectionChanged(bool isIn) {
    setState(() {
      _isIn = isIn;
      if (isIn) {
        _expenseType = AppConstants.expenseTypeWork;
      }
      // Reset rows when switching mode so entered earning amounts/remarks
      // never bleed into expense entries (or vice versa).
      for (final row in _entryRows) {
        row.amountController.dispose();
        row.remarkController.dispose();
      }
      _entryRows
        ..clear()
        ..add(
          _EntryRow(
            category: isIn
                ? AppConstants.earningCategories.first
                : _expenseCategories.first,
            amountController: TextEditingController(),
            remarkController: TextEditingController(),
          ),
        );
    });
  }

  List<String> get _expenseCategories =>
      _expenseType == AppConstants.expenseTypeHome
      ? AppConstants.homeChoreCategories
      : AppConstants.expenseCategories;

  List<String> get _categories =>
      _isIn ? AppConstants.earningCategories : _expenseCategories;

  void _addRow() {
    setState(() {
      _entryRows.add(
        _EntryRow(
          category: _categories.first,
          amountController: TextEditingController(),
          remarkController: TextEditingController(),
        ),
      );
    });
  }

  void _removeRow(int index) {
    if (_entryRows.length > 1) {
      setState(() {
        _entryRows[index].amountController.dispose();
        _entryRows[index].remarkController.dispose();
        _entryRows.removeAt(index);
      });
    }
  }

  Future<void> _addEntries() async {
    HapticFeedback.mediumImpact();
    // Validate all rows have amounts
    bool hasValid = false;
    for (final row in _entryRows) {
      final amountText = row.amountController.text.trim();
      if (amountText.isNotEmpty) {
        final amount = double.tryParse(amountText);
        if (amount == null || amount <= 0) {
          AppFeedback.error(
            context,
            message: AppLocalizations.of(context)!.enterValidAmount,
          );
          return;
        }
        hasValid = true;
      }
    }

    if (!hasValid) {
      AppFeedback.error(
        context,
        message: AppLocalizations.of(context)!.enterAmount,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      final approvalConfig = ref.read(approvalConfigProvider).value;
      final requiresApproval = approvalConfig?.inOutApprovalRequired ?? true;
      final lockedBeforeDate = approvalConfig?.lockedBeforeDate;

      final now = DateTime.now();

      for (final row in _entryRows) {
        final amountText = row.amountController.text.trim();
        if (amountText.isEmpty) continue;
        final amount = double.tryParse(amountText);
        if (amount == null || amount <= 0) continue;
        final remark = row.remarkController.text.trim();

        if (_isIn) {
          final earning = EarningModel(
            techId: user.uid,
            techName: user.name,
            category: row.category,
            amount: amount,
            note: remark,
            status: requiresApproval
                ? EarningApprovalStatus.pending
                : EarningApprovalStatus.approved,
            adminNote: '',
            date: now,
            createdAt: now,
            reviewedAt: requiresApproval ? null : now,
          );
          await ref
              .read(earningRepositoryProvider)
              .addEarning(earning, lockedBeforeDate: lockedBeforeDate);
        } else {
          final expense = ExpenseModel(
            techId: user.uid,
            techName: user.name,
            category: row.category,
            amount: amount,
            note: remark,
            expenseType: _expenseType,
            status: requiresApproval
                ? ExpenseApprovalStatus.pending
                : ExpenseApprovalStatus.approved,
            adminNote: '',
            date: now,
            createdAt: now,
            reviewedAt: requiresApproval ? null : now,
          );
          await ref
              .read(expenseRepositoryProvider)
              .addExpense(expense, lockedBeforeDate: lockedBeforeDate);
        }
      }

      if (mounted) {
        // Reset all rows to single empty row
        for (final row in _entryRows) {
          row.amountController.dispose();
          row.remarkController.dispose();
        }
        _entryRows.clear();
        _entryRows.add(
          _EntryRow(
            category: _categories.first,
            amountController: TextEditingController(),
            remarkController: TextEditingController(),
          ),
        );
        setState(() {});
        AppFeedback.success(
          context,
          message: AppLocalizations.of(context)!.entriesSaved,
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        AppFeedback.error(context, message: e.message(locale));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteEarning(String id) async {
    try {
      final lockedBeforeDate = ref
          .read(approvalConfigProvider)
          .value
          ?.lockedBeforeDate;
      await ref
          .read(earningRepositoryProvider)
          .archiveEarning(id, lockedBeforeDate: lockedBeforeDate);
      if (mounted) {
        AppFeedback.undo(
          context,
          message: AppLocalizations.of(context)!.entryDeleted,
          undoLabel: AppLocalizations.of(context)!.undo,
          onUndo: () => ref.read(earningRepositoryProvider).restoreEarning(id),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        AppFeedback.error(context, message: e.message(locale));
      }
    }
  }

  Future<void> _deleteExpense(String id) async {
    try {
      final lockedBeforeDate = ref
          .read(approvalConfigProvider)
          .value
          ?.lockedBeforeDate;
      await ref
          .read(expenseRepositoryProvider)
          .archiveExpense(id, lockedBeforeDate: lockedBeforeDate);
      if (mounted) {
        AppFeedback.undo(
          context,
          message: AppLocalizations.of(context)!.entryDeleted,
          undoLabel: AppLocalizations.of(context)!.undo,
          onUndo: () => ref.read(expenseRepositoryProvider).restoreExpense(id),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        AppFeedback.error(context, message: e.message(locale));
      }
    }
  }

  Future<void> _updateEarning(EarningModel earning) async {
    try {
      final lockedBeforeDate = ref
          .read(approvalConfigProvider)
          .value
          ?.lockedBeforeDate;
      await ref
          .read(earningRepositoryProvider)
          .updateEarning(earning, lockedBeforeDate: lockedBeforeDate);
      if (mounted) {
        AppFeedback.success(
          context,
          message: AppLocalizations.of(context)!.entryUpdated,
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        AppFeedback.error(context, message: e.message(locale));
      }
    }
  }

  Future<void> _updateExpense(ExpenseModel expense) async {
    try {
      final lockedBeforeDate = ref
          .read(approvalConfigProvider)
          .value
          ?.lockedBeforeDate;
      await ref
          .read(expenseRepositoryProvider)
          .updateExpense(expense, lockedBeforeDate: lockedBeforeDate);
      if (mounted) {
        AppFeedback.success(
          context,
          message: AppLocalizations.of(context)!.entryUpdated,
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        AppFeedback.error(context, message: e.message(locale));
      }
    }
  }

  List<DateTime> _availableReportMonths({
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
  }) {
    final months = <DateTime>{};
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    const minSupportedYear = 2000;

    void addIfValid(DateTime? rawDate) {
      if (rawDate == null) return;
      if (rawDate.year < minSupportedYear) return;
      final normalized = DateTime(rawDate.year, rawDate.month);
      if (normalized.isAfter(currentMonth)) return;
      months.add(normalized);
    }

    for (final e in earnings) {
      addIfValid(e.date);
    }
    for (final e in expenses) {
      addIfValid(e.date);
    }

    if (months.isEmpty) return const [];

    // UX rule: when current-year data exists, only show current year months.
    final currentYearMonths = months.where((m) => m.year == now.year).toList();
    final candidateMonths = currentYearMonths.isNotEmpty
        ? currentYearMonths
        : months.toList();

    final sorted = candidateMonths
      ..sort((a, b) {
        final y = b.year.compareTo(a.year);
        return y != 0 ? y : b.month.compareTo(a.month);
      });
    return sorted;
  }

  Future<void> _pickExportMonthFromCalendar(
    List<DateTime> monthsWithData,
  ) async {
    if (monthsWithData.isEmpty) return;
    final current = _effectiveExportMonth(monthsWithData);
    final first = monthsWithData.last;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(first.year, first.month, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() {
      _selectedExportMonth = DateTime(picked.year, picked.month);
    });
  }

  ({DateTime first, DateTime last})? _reportDateBounds({
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
  }) {
    final dates = <DateTime>[];

    void add(DateTime? value) {
      if (value == null) return;
      dates.add(DateTime(value.year, value.month, value.day));
    }

    for (final item in earnings) {
      add(item.date);
    }
    for (final item in expenses) {
      add(item.date);
    }

    if (dates.isEmpty) return null;
    dates.sort((a, b) => a.compareTo(b));
    return (first: dates.first, last: dates.last);
  }

  Future<_InOutReportOptions?> _pickReportOptions({
    required List<DateTime> monthsWithData,
    required ({DateTime first, DateTime last}) dateBounds,
  }) async {
    if (monthsWithData.isEmpty) return null;
    final l = AppLocalizations.of(context)!;

    DateTime selectedMonth = _effectiveExportMonth(monthsWithData);
    String selectedLocale = ref.read(appLocaleProvider);
    _ReportPeriodType selectedPeriodType = _ReportPeriodType.month;
    DateTimeRange selectedRange = DateTimeRange(
      start: dateBounds.first,
      end: dateBounds.last,
    );

    final result = await showDialog<_InOutReportOptions>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            title: Text(l.exportPdf),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      selected: selectedPeriodType == _ReportPeriodType.month,
                      onSelected: (_) {
                        setLocalState(() {
                          selectedPeriodType = _ReportPeriodType.month;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: Text(l.selectPdfDateRange),
                      selected: selectedPeriodType == _ReportPeriodType.range,
                      onSelected: (_) {
                        setLocalState(() {
                          selectedPeriodType = _ReportPeriodType.range;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (selectedPeriodType == _ReportPeriodType.month) ...[
                  Text(l.selectDate),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<DateTime>(
                    initialValue: selectedMonth,
                    decoration: const InputDecoration(isDense: true),
                    items: monthsWithData
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
                        firstDate: dateBounds.first,
                        lastDate: dateBounds.last,
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
                  _InOutReportOptions(
                    locale: selectedLocale,
                    periodType: selectedPeriodType,
                    month: selectedMonth,
                    dateRange: selectedPeriodType == _ReportPeriodType.range
                        ? selectedRange
                        : null,
                  ),
                ),
                child: Text(l.exportPdf),
              ),
            ],
          ),
        );
      },
    );

    return result;
  }

  Future<void> _exportTodayInOutPdf({
    required DateTime month,
    DateTimeRange? dateRange,
    required String reportLocale,
    required List<EarningModel> allEarnings,
    required List<ExpenseModel> allExpenses,
  }) async {
    final l = AppLocalizations.of(context)!;

    setState(() => _isExportingTodayPdf = true);
    try {
      final normalizedMonth = DateTime(month.year, month.month);
      final normalizedRange = dateRange == null
          ? null
          : DateTimeRange(
              start: DateTime(
                dateRange.start.year,
                dateRange.start.month,
                dateRange.start.day,
              ),
              end: DateTime(
                dateRange.end.year,
                dateRange.end.month,
                dateRange.end.day,
                23,
                59,
                59,
              ),
            );

      final earnings = allEarnings.where((item) {
        final d = item.date;
        if (d == null) return false;
        if (normalizedRange != null) {
          return !d.isBefore(normalizedRange.start) &&
              !d.isAfter(normalizedRange.end);
        }
        return d.year == normalizedMonth.year &&
            d.month == normalizedMonth.month;
      }).toList();

      final expenses = allExpenses.where((item) {
        final d = item.date;
        if (d == null) return false;
        if (normalizedRange != null) {
          return !d.isBefore(normalizedRange.start) &&
              !d.isAfter(normalizedRange.end);
        }
        return d.year == normalizedMonth.year &&
            d.month == normalizedMonth.month;
      }).toList();

      if (earnings.isEmpty && expenses.isEmpty) {
        if (mounted) {
          ErrorSnackbar.show(context, message: l.noEntriesToday);
        }
        return;
      }

      if (!mounted) return;
      final user = ref.read(currentUserProvider).value;
      final personName = (user?.name.trim().isNotEmpty ?? false)
          ? user!.name.trim()
          : l.technician;
      final languageLabel = switch (reportLocale) {
        'ur' => l.urdu,
        'ar' => l.arabic,
        _ => l.english,
      };
      final periodLabel = normalizedRange != null
          ? '${AppFormatters.date(normalizedRange.start)} - ${AppFormatters.date(normalizedRange.end)}'
          : AppFormatters.monthLabelForLocale(reportLocale, normalizedMonth);
      final reportTitle = switch (reportLocale) {
        'ur' => '$personName کی رپورٹ ($languageLabel)',
        'ar' => 'تقرير $personName ($languageLabel)',
        _ => 'Report of $personName ($languageLabel)',
      };
      final personToken = AppFormatters.slugify(personName).isEmpty
          ? 'technician'
          : AppFormatters.slugify(personName);
      final fileSuffix = normalizedRange != null
          ? '${normalizedRange.start.year}-${normalizedRange.start.month.toString().padLeft(2, '0')}-${normalizedRange.start.day.toString().padLeft(2, '0')}-to-${normalizedRange.end.year}-${normalizedRange.end.month.toString().padLeft(2, '0')}-${normalizedRange.end.day.toString().padLeft(2, '0')}'
          : '${AppFormatters.monthNameToken(normalizedMonth)}-${normalizedMonth.year}';

      await PdfExportService.shareInOutReport(
        earnings: earnings,
        expenses: expenses,
        fileName: '$personToken-$reportLocale-$fileSuffix-in-out.pdf',
        locale: reportLocale,
        technicianName: personName,
        reportTitle: reportTitle,
        reportDate: normalizedRange?.start ?? normalizedMonth,
        periodLabel: periodLabel,
        monthlyMode: true,
        reportBranding: ReportBrandingContext.fromAppBranding(
          appBranding:
              ref.read(appBrandingProvider).value ??
              AppBrandingConfig.defaults(),
          fallbackServiceName: l.ambiguousCompanyName,
        ),
      );
    } catch (_) {
      if (mounted) {
        ErrorSnackbar.show(context, message: l.couldNotExport);
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingTodayPdf = false);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return ArcticTheme.arcticSuccess;
      case 'rejected':
        return ArcticTheme.arcticError;
      default:
        return ArcticTheme.arcticWarning;
    }
  }

  String _directionLabel(_EntryItem item, AppLocalizations l) {
    if (item.isIn) return l.inEarned;
    if (item.expenseType == AppConstants.expenseTypeHome) {
      return l.homeExpenses;
    }
    return l.workExpenses;
  }

  Future<void> _showEntryDetailsSheet(_EntryItem item) async {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
            child: ArcticCard(
              margin: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.entryDetails,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      StatusBadge(status: item.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (item.isIn
                                      ? ArcticTheme.arcticSuccess
                                      : ArcticTheme.arcticError)
                                  .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _directionLabel(item, l),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: item.isIn
                                ? ArcticTheme.arcticSuccess
                                : ArcticTheme.arcticError,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(
                            item.status,
                          ).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _statusColor(item.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _EntryDetailRow(
                    label: l.category,
                    value: translateCategory(item.category, l),
                  ),
                  _EntryDetailRow(
                    label: l.amountSar,
                    value:
                        '${item.isIn ? '+' : '-'} SAR ${item.amount.toStringAsFixed(0)}',
                    valueColor: item.isIn
                        ? ArcticTheme.arcticSuccess
                        : ArcticTheme.arcticError,
                  ),
                  _EntryDetailRow(
                    label: l.date,
                    value: AppFormatters.dateTime(item.date ?? item.createdAt),
                  ),
                  if (item.note.isNotEmpty)
                    _EntryDetailRow(label: l.remarksOptional, value: item.note),
                  if (item.adminNote.isNotEmpty)
                    _EntryDetailRow(
                      label: l.adminNote,
                      value: item.adminNote,
                      valueColor: ArcticTheme.arcticWarning,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _confirmDeleteEntry(item);
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(l.delete),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ArcticTheme.arcticError,
                            side: const BorderSide(
                              color: ArcticTheme.arcticError,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Edit is only meaningful for pending entries.
                      // Approved entries are locked by the repository.
                      // Rejected entries have no resubmit Firestore path;
                      // tech should delete and re-add instead (BUG E fix).
                      if (item.status == 'pending')
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _showEditEntryDialog(item);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l.editEntry),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditEntryDialog(_EntryItem item) async {
    final l = AppLocalizations.of(context)!;
    final amountCtrl = TextEditingController(
      text: item.amount == item.amount.roundToDouble()
          ? item.amount.toStringAsFixed(0)
          : item.amount.toString(),
    );
    final noteCtrl = TextEditingController(text: item.note);
    final formKey = GlobalKey<FormState>();

    String selectedExpenseType = item.expenseType;
    List<String> currentCategories = item.isIn
        ? AppConstants.earningCategories
        : (selectedExpenseType == AppConstants.expenseTypeHome
              ? AppConstants.homeChoreCategories
              : AppConstants.expenseCategories);
    String selectedCategory = currentCategories.contains(item.category)
        ? item.category
        : currentCategories.first;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            title: Text(l.editEntry),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!item.isIn) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _DirectionButton(
                              label: l.workExpenses,
                              icon: Icons.work_outline_rounded,
                              isSelected:
                                  selectedExpenseType ==
                                  AppConstants.expenseTypeWork,
                              color: ArcticTheme.arcticWarning,
                              onTap: () {
                                setLocalState(() {
                                  selectedExpenseType =
                                      AppConstants.expenseTypeWork;
                                  currentCategories =
                                      AppConstants.expenseCategories;
                                  if (!currentCategories.contains(
                                    selectedCategory,
                                  )) {
                                    selectedCategory = currentCategories.first;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DirectionButton(
                              label: l.homeExpenses,
                              icon: Icons.home_work_outlined,
                              isSelected:
                                  selectedExpenseType ==
                                  AppConstants.expenseTypeHome,
                              color: ArcticTheme.arcticBlue,
                              onTap: () {
                                setLocalState(() {
                                  selectedExpenseType =
                                      AppConstants.expenseTypeHome;
                                  currentCategories =
                                      AppConstants.homeChoreCategories;
                                  if (!currentCategories.contains(
                                    selectedCategory,
                                  )) {
                                    selectedCategory = currentCategories.first;
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      menuMaxHeight: 280,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: l.category,
                        prefixIcon: Icon(
                          item.isIn
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                      ),
                      items: currentCategories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(translateCategory(c, l)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setLocalState(() => selectedCategory = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      enableInteractiveSelection: true,
                      decoration: InputDecoration(
                        hintText: l.amountSar,
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l.enterAmount;
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return l.enterValidAmount;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteCtrl,
                      textInputAction: TextInputAction.done,
                      enableInteractiveSelection: true,
                      decoration: InputDecoration(
                        hintText: l.remarksOptional,
                        prefixIcon: const Icon(
                          Icons.note_outlined,
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.of(ctx).pop(true);
                },
                child: Text(l.save),
              ),
            ],
          ),
        );
      },
    );

    if (shouldSave != true) {
      amountCtrl.dispose();
      noteCtrl.dispose();
      return;
    }

    final amount = double.parse(amountCtrl.text.trim());
    final note = noteCtrl.text.trim();
    final approvalConfig = ref.read(approvalConfigProvider).value;
    final requiresApproval = approvalConfig?.inOutApprovalRequired ?? true;

    if (item.isIn) {
      await _updateEarning(
        EarningModel(
          id: item.id,
          techId: item.techId,
          techName: item.techName,
          category: selectedCategory,
          amount: amount,
          note: note,
          status: requiresApproval
              ? EarningApprovalStatus.pending
              : EarningApprovalStatus.approved,
          // When approval is off and entry becomes approved, always clear
          // any stale rejection metadata to prevent a conflicting state
          // where status='approved' but adminNote still holds a rejection
          // reason (BUG G fix).
          approvedBy: '',
          adminNote: '',
          date: item.date,
          createdAt: item.createdAt,
          reviewedAt: requiresApproval ? null : item.reviewedAt,
        ),
      );
    } else {
      await _updateExpense(
        ExpenseModel(
          id: item.id,
          techId: item.techId,
          techName: item.techName,
          category: selectedCategory,
          amount: amount,
          note: note,
          expenseType: selectedExpenseType,
          status: requiresApproval
              ? ExpenseApprovalStatus.pending
              : ExpenseApprovalStatus.approved,
          // BUG G fix: same as earning — always clear stale rejection metadata.
          approvedBy: '',
          adminNote: '',
          date: item.date,
          createdAt: item.createdAt,
          reviewedAt: requiresApproval ? null : item.reviewedAt,
        ),
      );
    }

    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _confirmDeleteEntry(_EntryItem item) async {
    final l = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.delete),
        content: Text(l.deleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ArcticTheme.arcticError,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    if (item.isIn) {
      await _deleteEarning(item.id);
    } else {
      await _deleteExpense(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final allEarningsAsync = ref.watch(techEarningsProvider);
    final allExpensesAsync = ref.watch(techExpensesProvider);
    final selectedDate = widget.selectedDate;
    final earningsAsync = selectedDate != null
        ? ref.watch(dailyEarningsProvider(selectedDate))
        : ref.watch(todaysEarningsProvider);
    final expensesAsync = selectedDate != null
        ? ref.watch(dailyExpensesProvider(selectedDate))
        : ref.watch(todaysExpensesProvider);
    final allEarnings = allEarningsAsync.value ?? const <EarningModel>[];
    final allExpenses = allExpensesAsync.value ?? const <ExpenseModel>[];
    final monthsWithData = _availableReportMonths(
      earnings: allEarnings,
      expenses: allExpenses,
    );
    final dateBounds = _reportDateBounds(
      earnings: allEarnings,
      expenses: allExpenses,
    );

    ref.listen<AsyncValue<List<JobModel>>>(technicianJobsProvider, (
      prev,
      next,
    ) {
      next.whenData((jobs) {
        final approvedIds = jobs
            .where((j) => j.isApproved)
            .map((j) => j.id)
            .toSet();

        if (!_approvalBaselineReady) {
          _approvedKnownIds
            ..clear()
            ..addAll(approvedIds);
          _approvalBaselineReady = true;
          return;
        }

        final newlyApproved = approvedIds.difference(_approvedKnownIds);
        if (newlyApproved.isNotEmpty && mounted) {
          _approvedKnownIds.addAll(newlyApproved);
          SuccessSnackbar.show(
            context,
            message: AppLocalizations.of(context)!.jobApproved,
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.selectedDate != null
                ? AppFormatters.dateTime(widget.selectedDate)
                : l.todaysInOut,
          ),
        ),
        actions: [
          IconButton(
            icon: _isExportingTodayPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l.exportPdf,
            onPressed:
                _isExportingTodayPdf ||
                    allEarningsAsync.isLoading ||
                    allExpensesAsync.isLoading
                ? null
                : () async {
                    if (dateBounds == null) return;
                    final picked = await _pickReportOptions(
                      monthsWithData: monthsWithData,
                      dateBounds: dateBounds,
                    );
                    if (picked == null) return;
                    if (!mounted) return;
                    await _exportTodayInOutPdf(
                      month: picked.month,
                      dateRange: picked.dateRange,
                      reportLocale: picked.locale,
                      allEarnings: allEarnings,
                      allExpenses: allExpenses,
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.air_rounded),
            tooltip: l.logAcInstallations,
            onPressed: () => context.push('/tech/ac-installs'),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: l.monthlySummary,
            onPressed: monthsWithData.isEmpty
                ? null
                : () => _pickExportMonthFromCalendar(monthsWithData),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: ArcticRefreshIndicator(
            onRefresh: () async {
              final month = widget.selectedDate ?? DateTime.now();
              ref.invalidate(
                monthlyEarningsProvider(DateTime(month.year, month.month)),
              );
              ref.invalidate(
                monthlyExpensesProvider(DateTime(month.year, month.month)),
              );
            },
            child: ListView(
              // Bottom padding: FAB(56) + FAB margin(16) + gap(16) = 88
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 88),
              children: [
                // ── Summary Card ──
                _buildSummaryCard(theme, earningsAsync, expensesAsync),
                const SizedBox(height: 20),

                // ── Add Entry Form (hidden when viewing a historical date) ──
                if (widget.selectedDate == null) ...[
                  _buildAddForm(theme),
                  const SizedBox(height: 24),
                ],

                // ── Today's Entries ──
                Row(
                  children: [
                    const Icon(
                      Icons.list_alt_rounded,
                      color: ArcticTheme.arcticBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(l.todaysEntries, style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),

                _buildEntryList(theme, earningsAsync, expensesAsync),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Summary: IN | OUT | Profit/Loss ──
  Widget _buildSummaryCard(
    ThemeData theme,
    AsyncValue<List<EarningModel>> earningsAsync,
    AsyncValue<List<ExpenseModel>> expensesAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    final totalIn =
        earningsAsync.value?.fold<double>(0, (s, e) => s + e.amount) ?? 0;
    final totalOut =
        expensesAsync.value?.fold<double>(0, (s, e) => s + e.amount) ?? 0;
    final net = totalIn - totalOut;
    final isProfit = net >= 0;

    return ArcticCard(
      child: Column(
        children: [
          Row(
            children: [
              // IN
              Expanded(
                child: Column(
                  children: [
                    const Icon(
                      Icons.arrow_downward_rounded,
                      color: ArcticTheme.arcticSuccess,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(l.earned, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      'SAR ${totalIn.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: ArcticTheme.arcticSuccess,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(width: 1, height: 50, color: ArcticTheme.arcticDivider),
              // OUT
              Expanded(
                child: Column(
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      color: ArcticTheme.arcticError,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(l.spent, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      'SAR ${totalOut.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: ArcticTheme.arcticError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(width: 1, height: 50, color: ArcticTheme.arcticDivider),
              // Net
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      isProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isProfit
                          ? ArcticTheme.arcticSuccess
                          : ArcticTheme.arcticError,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isProfit ? l.profit : l.loss,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SAR ${net.abs().toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isProfit
                            ? ArcticTheme.arcticSuccess
                            : ArcticTheme.arcticError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Add Entry Form ──
  Widget _buildAddForm(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // IN / OUT Toggle
          Row(
            children: [
              Expanded(
                child: _DirectionButton(
                  label: l.inEarned,
                  icon: Icons.arrow_downward_rounded,
                  isSelected: _isIn,
                  color: ArcticTheme.arcticSuccess,
                  onTap: () => _onDirectionChanged(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DirectionButton(
                  label: l.outSpent,
                  icon: Icons.arrow_upward_rounded,
                  isSelected: !_isIn,
                  color: ArcticTheme.arcticError,
                  onTap: () => _onDirectionChanged(false),
                ),
              ),
            ],
          ),
          if (!_isIn) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DirectionButton(
                    label: l.workExpenses,
                    icon: Icons.work_outline_rounded,
                    isSelected: _expenseType == AppConstants.expenseTypeWork,
                    color: ArcticTheme.arcticWarning,
                    onTap: () {
                      setState(() {
                        _expenseType = AppConstants.expenseTypeWork;
                        for (final row in _entryRows) {
                          row.category = _expenseCategories.first;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DirectionButton(
                    label: l.homeExpenses,
                    icon: Icons.home_work_outlined,
                    isSelected: _expenseType == AppConstants.expenseTypeHome,
                    color: ArcticTheme.arcticBlue,
                    onTap: () {
                      setState(() {
                        _expenseType = AppConstants.expenseTypeHome;
                        for (final row in _entryRows) {
                          row.category = _expenseCategories.first;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Batch entry rows
          ...List.generate(_entryRows.length, (i) {
            final row = _entryRows[i];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < _entryRows.length - 1 ? 12 : 0,
              ),
              child: Column(
                children: [
                  if (i > 0) ...[
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('cat_${_isIn}_$i'),
                          initialValue: row.category,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: l.category,
                            prefixIcon: Icon(
                              _isIn
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: ArcticTheme.arcticTextSecondary,
                            ),
                            isDense: true,
                          ),
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(translateCategory(c, l)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => row.category = v);
                          },
                        ),
                      ),
                      if (_entryRows.length > 1) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                          ),
                          color: ArcticTheme.arcticError,
                          onPressed: () => _removeRow(i),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ObjectKey(row.amountController),
                    controller: row.amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: l.amountSar,
                      prefixIcon: const Icon(
                        Icons.payments_outlined,
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ObjectKey(row.remarkController),
                    controller: row.remarkController,
                    textInputAction: TextInputAction.done,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: l.remarksOptional,
                      prefixIcon: const Icon(
                        Icons.note_outlined,
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // Add another row button
          OutlinedButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              _isIn ? l.addMoreEarning : l.addMoreExpense,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArcticTheme.arcticBlue,
              side: BorderSide(
                color: ArcticTheme.arcticBlue.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Submit all button
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _addEntries,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ArcticTheme.arcticDarkBg,
                      ),
                    )
                  : Icon(_isIn ? Icons.add_rounded : Icons.remove_rounded),
              label: Text(
                _isSaving
                    ? l.saving
                    : _isIn
                    ? l.addEarning
                    : l.addExpense,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ── Merged chronological entry list ──
  Widget _buildEntryList(
    ThemeData theme,
    AsyncValue<List<EarningModel>> earningsAsync,
    AsyncValue<List<ExpenseModel>> expensesAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    // Show loading if either is loading
    if (earningsAsync.isLoading || expensesAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final earnings = earningsAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];

    if (earnings.isEmpty && expenses.isEmpty) {
      return ArcticCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: ArcticTheme.arcticTextSecondary,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  l.noEntriesToday,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.addFirstEntry,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Merge into a single sorted list (newest first)
    final items =
        <_EntryItem>[
          for (final e in earnings)
            _EntryItem(
              id: e.id,
              isIn: true,
              techId: e.techId,
              techName: e.techName,
              category: e.category,
              amount: e.amount,
              note: e.note,
              approvedBy: e.approvedBy,
              adminNote: e.adminNote,
              status: e.status.name,
              date: e.date,
              createdAt: e.createdAt,
              reviewedAt: e.reviewedAt,
            ),
          for (final e in expenses)
            _EntryItem(
              id: e.id,
              isIn: false,
              techId: e.techId,
              techName: e.techName,
              category: e.category,
              amount: e.amount,
              note: e.note,
              approvedBy: e.approvedBy,
              adminNote: e.adminNote,
              expenseType: e.expenseType,
              status: e.status.name,
              date: e.date,
              createdAt: e.createdAt,
              reviewedAt: e.reviewedAt,
            ),
        ]..sort(
          (a, b) =>
              (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)),
        );

    return Column(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: ArcticTheme.arcticError,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsetsDirectional.only(end: 20),
            child: Icon(
              Icons.delete_rounded,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          onDismissed: (_) {
            if (item.isIn) {
              _deleteEarning(item.id);
            } else {
              _deleteExpense(item.id);
            }
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showEntryDetailsSheet(item),
              child: ArcticCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Direction icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            (item.isIn
                                    ? ArcticTheme.arcticSuccess
                                    : ArcticTheme.arcticError)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.isIn
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: item.isIn
                            ? ArcticTheme.arcticSuccess
                            : ArcticTheme.arcticError,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translateCategory(item.category, l),
                            style: theme.textTheme.titleSmall,
                          ),
                          if (item.note.isNotEmpty)
                            Text(
                              item.note,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ArcticTheme.arcticTextSecondary,
                              ),
                            ),
                          if (!item.isIn &&
                              item.expenseType == AppConstants.expenseTypeHome)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: ArcticTheme.arcticBlue.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l.homeExpenses,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: ArcticTheme.arcticBlue,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l.editEntry,
                      onPressed: () => _showEditEntryDialog(item),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: ArcticTheme.arcticBlue,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      tooltip: l.delete,
                      onPressed: () => _confirmDeleteEntry(item),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: ArcticTheme.arcticError,
                        size: 20,
                      ),
                    ),
                    // Amount
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          '${item.isIn ? "+" : "-"} SAR ${item.amount.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: item.isIn
                                ? ArcticTheme.arcticSuccess
                                : ArcticTheme.arcticError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: (50 + entry.key * 40).ms),
        );
      }).toList(),
    );
  }
}

// ── Batch entry row data ──
class _EntryRow {
  _EntryRow({
    required this.category,
    required this.amountController,
    required this.remarkController,
  });

  String category;
  final TextEditingController amountController;
  final TextEditingController remarkController;
}

// ── Data holder for merged list ──
class _EntryItem {
  const _EntryItem({
    required this.id,
    required this.isIn,
    required this.techId,
    required this.techName,
    required this.category,
    required this.amount,
    required this.note,
    required this.status,
    this.approvedBy = '',
    this.adminNote = '',
    this.expenseType = AppConstants.expenseTypeWork,
    this.date,
    this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final bool isIn;
  final String techId;
  final String techName;
  final String category;
  final double amount;
  final String note;
  final String status;
  final String approvedBy;
  final String adminNote;
  final String expenseType;
  final DateTime? date;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
}

// ── IN / OUT toggle button ──
class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : ArcticTheme.arcticDivider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? color : ArcticTheme.arcticTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? color : ArcticTheme.arcticTextSecondary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryDetailRow extends StatelessWidget {
  const _EntryDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ArcticTheme.arcticTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: valueColor == null ? null : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
