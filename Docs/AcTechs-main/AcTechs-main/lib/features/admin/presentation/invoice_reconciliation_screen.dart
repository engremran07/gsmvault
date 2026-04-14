import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/invoice_utils.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

// Top-level function for compute() isolate — must be top-level for Flutter compute
List<String> _parseExcelForReconcile(Uint8List bytes) {
  final workbook = excel_pkg.Excel.decodeBytes(bytes);
  if (workbook.tables.isEmpty) return [];

  final sheet = workbook.tables.values.first;
  final rows = sheet.rows;
  if (rows.length < 2) return [];

  // Detect invoice column from header row by looking for "invoice"/"inv" keyword
  final header = rows.first;
  int colIndex = 0;
  for (int i = 0; i < header.length; i++) {
    final cell = header[i];
    if (cell == null) continue;
    final val = cell.value?.toString().toLowerCase() ?? '';
    if (val.contains('invoice') || val.contains('inv')) {
      colIndex = i;
      break;
    }
  }

  final invoices = <String>[];
  for (int r = 1; r < rows.length; r++) {
    final row = rows[r];
    if (row.isEmpty || colIndex >= row.length) continue;
    final cell = row[colIndex];
    if (cell == null) continue;
    final val = cell.value?.toString().trim() ?? '';
    if (val.isEmpty) continue;
    final normalized = InvoiceUtils.normalize(val);
    if (normalized.isNotEmpty) invoices.add(normalized);
  }
  return invoices;
}

enum _ReconcileKind { matched, notInReport, alreadyPaid }

class _ReconcileEntry {
  const _ReconcileEntry({required this.kind, required this.job});
  final _ReconcileKind kind;
  final JobModel job;
}

class _ReconcileResults {
  const _ReconcileResults({
    required this.matched,
    required this.notInReport,
    required this.alreadyPaid,
    required this.excelCount,
  });

  final List<_ReconcileEntry> matched;
  final List<_ReconcileEntry> notInReport;
  final List<_ReconcileEntry> alreadyPaid;
  final int excelCount;

  bool get isEmpty =>
      matched.isEmpty && notInReport.isEmpty && alreadyPaid.isEmpty;
}

class InvoiceReconciliationScreen extends ConsumerStatefulWidget {
  const InvoiceReconciliationScreen({super.key});

  @override
  ConsumerState<InvoiceReconciliationScreen> createState() =>
      _InvoiceReconciliationScreenState();
}

class _InvoiceReconciliationScreenState
    extends ConsumerState<InvoiceReconciliationScreen> {
  CompanyModel? _selectedCompany;
  String? _fileName;
  _ReconcileResults? _results;
  bool _isProcessing = false;

  Future<void> _pickAndReconcile() async {
    final l = AppLocalizations.of(context)!;

    if (_selectedCompany == null) {
      AppFeedback.error(context, message: l.selectCompany);
      return;
    }

    final picked = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
    );

    if (picked == null || picked.files.isEmpty) {
      if (mounted) {
        AppFeedback.error(context, message: l.importNoFileSelected);
      }
      return;
    }

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        AppFeedback.error(context, message: l.importNoFileSelected);
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _fileName = file.name;
      _results = null;
    });

    try {
      // Parse Excel in a separate isolate
      final excelInvoices = await compute(_parseExcelForReconcile, bytes);
      final prefix = _selectedCompany!.invoicePrefix;

      // Normalise all Excel invoices, stripping company prefix if present
      final normalizedExcel = excelInvoices
          .map(
            (inv) => InvoiceUtils.normalizeWithCompanyPrefix(
              inv,
              companyPrefix: prefix,
            ).toLowerCase(),
          )
          .toSet();

      // Fetch DB data
      final repo = ref.read(jobRepositoryProvider);
      final candidates = await repo.fetchSettlementCandidates();
      final history = await repo.fetchSettlementHistory();

      // Filter by selected company
      final companyId = _selectedCompany!.id;
      final companyCandidates = candidates
          .where((j) => j.companyId == companyId)
          .toList();
      final companyHistory = history
          .where((j) => j.companyId == companyId)
          .toList();

      // Reconcile candidates (unpaid / correction-required)
      final matched = <_ReconcileEntry>[];
      final notInReport = <_ReconcileEntry>[];
      for (final job in companyCandidates) {
        final inv = InvoiceUtils.normalizeWithCompanyPrefix(
          job.invoiceNumber,
          companyPrefix: prefix,
        ).toLowerCase();
        if (normalizedExcel.contains(inv)) {
          matched.add(_ReconcileEntry(kind: _ReconcileKind.matched, job: job));
        } else {
          notInReport.add(
            _ReconcileEntry(kind: _ReconcileKind.notInReport, job: job),
          );
        }
      }

      // Check history (already paid) against Excel
      final alreadyPaid = <_ReconcileEntry>[];
      for (final job in companyHistory) {
        final inv = InvoiceUtils.normalizeWithCompanyPrefix(
          job.invoiceNumber,
          companyPrefix: prefix,
        ).toLowerCase();
        if (normalizedExcel.contains(inv)) {
          alreadyPaid.add(
            _ReconcileEntry(kind: _ReconcileKind.alreadyPaid, job: job),
          );
        }
      }

      if (mounted) {
        setState(() {
          _results = _ReconcileResults(
            matched: matched,
            notInReport: notInReport,
            alreadyPaid: alreadyPaid,
            excelCount: excelInvoices.length,
          );
        });
      }
    } on AppException catch (error) {
      if (mounted) {
        AppFeedback.error(
          context,
          message: error.message(Localizations.localeOf(context).languageCode),
        );
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.error(context, message: l.genericError);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<({double amount, String paymentMethod, String note})?>
  _promptPaymentDetails() async {
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

  Future<void> _markMatchedAsPaid() async {
    final l = AppLocalizations.of(context)!;
    final results = _results;
    if (results == null || results.matched.isEmpty) {
      AppFeedback.error(context, message: l.selectJobsFirst);
      return;
    }

    final details = await _promptPaymentDetails();
    if (details == null || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final adminUid = ref.read(currentUserProvider).value?.uid ?? '';
      final repo = ref.read(jobRepositoryProvider);

      // Group matched jobs by techId — markJobsAsPaid requires same-tech batch
      final byTech = <String, List<String>>{};
      for (final entry in results.matched) {
        byTech.putIfAbsent(entry.job.techId, () => []).add(entry.job.id);
      }

      for (final techEntry in byTech.entries) {
        await repo.markJobsAsPaid(
          techEntry.value,
          adminUid,
          adminNote: details.note,
          amountPerJob: details.amount,
          paymentMethod: details.paymentMethod,
        );
      }

      if (mounted) {
        AppFeedback.success(context, message: l.reconcileMarkedSuccess);
        setState(() {
          _results = null;
          _fileName = null;
        });
      }
    } on AppException catch (error) {
      if (mounted) {
        AppFeedback.error(
          context,
          message: error.message(Localizations.localeOf(context).languageCode),
        );
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.error(context, message: l.genericError);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final companiesAsync = ref.watch(allCompaniesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.reconcileInvoices)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company selector
            companiesAsync.when(
              data: (companies) {
                final active = companies
                    .where((c) => c.isActive)
                    .toList(growable: false);
                return DropdownButtonFormField<CompanyModel>(
                  initialValue: _selectedCompany,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.companyName,
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text(l.selectCompany),
                  items: active
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCompany = value;
                      _results = null;
                      _fileName = null;
                    });
                  },
                );
              },
              loading: () => const ArcticShimmer(height: 56, count: 1),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Upload button + filename
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _pickAndReconcile,
                    icon: _isProcessing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary,
                            ),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(l.uploadCompanyReport),
                  ),
                ),
              ],
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    size: 16,
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _fileName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_results != null)
                    Text(
                      '${_results!.excelCount} ${l.invoiceNumber.toLowerCase()}s',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                    ),
                ],
              ),
            ],

            // Results
            if (_results != null) ...[
              const SizedBox(height: 24),
              _buildSection(
                context,
                label: '${l.matchedInvoices} (${_results!.matched.length})',
                color: ArcticTheme.arcticSuccess,
                entries: _results!.matched,
              ),
              if (_results!.matched.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ArcticTheme.arcticSuccess,
                  ),
                  onPressed: _isProcessing ? null : _markMatchedAsPaid,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(l.markAsPaid),
                ),
              ],
              const SizedBox(height: 24),
              _buildSection(
                context,
                label:
                    '${l.unmatchedInvoices} (${_results!.notInReport.length})',
                color: ArcticTheme.arcticWarning,
                entries: _results!.notInReport,
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                label:
                    '${l.alreadyPaidInvoices} (${_results!.alreadyPaid.length})',
                color: ArcticTheme.arcticTextSecondary,
                entries: _results!.alreadyPaid,
              ),

              if (_results!.isEmpty) ...[
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    l.noDataYet,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ArcticTheme.arcticTextSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String label,
    required Color color,
    required List<_ReconcileEntry> entries,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: color),
            ),
          ],
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
            child: Text(
              '—',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ArcticTheme.arcticTextSecondary,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          ...entries.map((e) => _buildJobTile(context, e)),
        ],
      ],
    );
  }

  Widget _buildJobTile(BuildContext context, _ReconcileEntry entry) {
    final job = entry.job;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ArcticCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.invoiceNumber,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${job.techName} · ${job.clientName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ArcticTheme.arcticTextSecondary,
                    ),
                  ),
                  if (job.date != null)
                    Text(
                      AppFormatters.date(job.date!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              AppFormatters.units(job.totalUnits),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
