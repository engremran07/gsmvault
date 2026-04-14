import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/admin/data/historical_jobs_import_service.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/core/utils/picked_file_bytes.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class HistoricalImportScreen extends ConsumerStatefulWidget {
  const HistoricalImportScreen({super.key});

  @override
  ConsumerState<HistoricalImportScreen> createState() =>
      _HistoricalImportScreenState();
}

class _HistoricalImportScreenState
    extends ConsumerState<HistoricalImportScreen> {
  bool _isImporting = false;
  bool _isDraggingFiles = false;
  bool _isLoadingTechnicians = true;
  List<UserModel> _technicians = const [];
  UserModel? _selectedTechnician;
  CompanyModel? _selectedCompany;
  final TextEditingController _technicianKeywordController =
      TextEditingController();
  final ValueNotifier<String> _importProgress = ValueNotifier('');

  Future<bool> _showImportPreviewDialog(
    List<_PreparedImportBatch> preparedBatches,
  ) async {
    final l = AppLocalizations.of(context)!;
    final totalImportedRows = preparedBatches.fold<int>(
      0,
      (sum, b) => sum + b.parsed.jobs.length,
    );

    // Early return if no valid rows (1.6)
    if (totalImportedRows == 0) {
      return false;
    }

    final totalSkippedRows = preparedBatches.fold<int>(
      0,
      (sum, b) => sum + b.parsed.skippedRows,
    );
    final totalUnresolvedRows = preparedBatches.fold<int>(
      0,
      (sum, b) => sum + b.parsed.unresolvedTechnicians,
    );
    final totalRowsWithoutTechName = preparedBatches.fold<int>(
      0,
      (sum, b) => sum + b.parsed.rowsWithoutTechnicianName,
    );
    final mergedTechnicianCounts = <String, int>{};
    for (final batch in preparedBatches) {
      _mergeTechnicianCounts(
        mergedTechnicianCounts,
        batch.parsed.technicianNameCounts,
      );
    }
    final topTechnicians = _topTechnicianEntries(mergedTechnicianCounts);

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final maxDialogHeight = MediaQuery.of(dialogContext).size.height * 0.68;
        final isRtl =
            Localizations.localeOf(dialogContext).languageCode != 'en';

        return AlertDialog(
          title: Text(l.confirmImport),
          content: SizedBox(
            width: 560,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxDialogHeight),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: isRtl
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.importHistoryData,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(l.importCompletedCount(totalImportedRows)),
                    Text(l.importSkippedCount(totalSkippedRows)),
                    Text(l.importUnresolvedTechRows(totalUnresolvedRows)),
                    Text(l.importRowsWithoutTechName(totalRowsWithoutTechName)),
                    Text(
                      l.importUniqueTechNamesCount(
                        mergedTechnicianCounts.length,
                      ),
                    ),
                    if (topTechnicians.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l.importTopTechNamesLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      ...topTechnicians.map(
                        (entry) => Text('${entry.key}: ${entry.value}'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...preparedBatches.map((batch) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: ArcticTheme.arcticDivider,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isRtl
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                batch.fileName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              ...batch.parsed.sheetSummaries.map((sheet) {
                                final sheetTopTechnicians =
                                    _topTechnicianEntries(
                                      sheet.technicianNameCounts,
                                    );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${sheet.sheetName} • ${l.importCompletedCount(sheet.importedRows)} • ${l.importSkippedCount(sheet.skippedRows)} • ${l.importUnresolvedTechRows(sheet.unresolvedTechnicians)}\n'
                                    '${l.importRowsWithoutTechName(sheet.rowsWithoutTechnicianName)} • ${l.importUniqueTechNamesCount(sheet.technicianNameCounts.length)}\n'
                                    '${sheetTopTechnicians.isNotEmpty ? '${l.importTopTechNamesLabel}: ${_formatTechnicianEntries(sheetTopTechnicians)}\n' : ''}'
                                    '${_sheetBreakdownLine(l, sheet)}'
                                    '${_localizedSheetNote(l, sheet).isNotEmpty ? '\n${_localizedSheetNote(l, sheet)}' : ''}',
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.confirm),
            ),
          ],
        );
      },
    );

    return shouldProceed ?? false;
  }

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  @override
  void dispose() {
    _technicianKeywordController.dispose();
    _importProgress.dispose();
    super.dispose();
  }

  Future<void> _loadTechnicians() async {
    try {
      final users = await ref.read(userRepositoryProvider).usersForImport();
      final technicians =
          users
              .where((user) => user.role == AppConstants.roleTechnician)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      if (!mounted) return;
      setState(() {
        _technicians = technicians;
        _selectedTechnician = null;
        _isLoadingTechnicians = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _technicians = const [];
        _selectedTechnician = null;
        _isLoadingTechnicians = false;
      });
    }
  }

  UserModel? _findTechnicianByUid(String? uid) {
    if (uid == null) return null;
    for (final technician in _technicians) {
      if (technician.uid == uid) {
        return technician;
      }
    }
    return null;
  }

  void _mergeTechnicianCounts(
    Map<String, int> target,
    Map<String, int> source,
  ) {
    for (final entry in source.entries) {
      target[entry.key] = (target[entry.key] ?? 0) + entry.value;
    }
  }

  List<MapEntry<String, int>> _topTechnicianEntries(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.length > 5) {
      return entries.sublist(0, 5);
    }
    return entries;
  }

  String _formatTechnicianEntries(List<MapEntry<String, int>> entries) {
    return entries.map((entry) => '${entry.key} (${entry.value})').join(', ');
  }

  String _localizedSheetNote(
    AppLocalizations l,
    HistoricalImportSheetSummary sheet,
  ) {
    switch (sheet.noteCode) {
      case 'row_limit_exceeded':
        return l.importSheetRowLimitExceeded;
      default:
        return sheet.note;
    }
  }

  String _sheetBreakdownLine(
    AppLocalizations l,
    HistoricalImportSheetSummary sheet,
  ) {
    return '${l.importInstalledBreakdown(sheet.installedSplit, sheet.installedWindow, sheet.installedFreestanding)} • '
        '${l.importUninstallBreakdown(sheet.uninstallSplit, sheet.uninstallWindow, sheet.uninstallFreestanding, sheet.uninstallOld)}';
  }

  bool _isSupportedImportFileName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.xlsx') || lower.endsWith('.xls');
  }

  Future<void> _importFiles() async {
    final l = AppLocalizations.of(context)!;
    final picked = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
    );

    if (picked == null || picked.files.isEmpty) {
      if (mounted) {
        ErrorSnackbar.show(context, message: l.importNoFileSelected);
      }
      return;
    }

    await _runImport(
      sources: picked.files
          .map(_ImportSource.platformFile)
          .toList(growable: false),
    );
  }

  Future<void> _importDroppedFiles(List<XFile> files) async {
    final l = AppLocalizations.of(context)!;
    final sources = files
        .where((file) => _isSupportedImportFileName(file.name))
        .map(_ImportSource.xFile)
        .toList(growable: false);

    if (sources.isEmpty) {
      ErrorSnackbar.show(context, message: l.importUnsupportedFileType);
      return;
    }

    await _runImport(sources: sources);
  }

  Future<void> _runImport({required List<_ImportSource> sources}) async {
    final l = AppLocalizations.of(context)!;
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || !currentUser.isAdmin) return;

    final targetTechnician = _selectedTechnician;
    if (targetTechnician == null) {
      ErrorSnackbar.show(context, message: l.importTargetTechnicianRequired);
      return;
    }

    final targetCompany = _selectedCompany;
    if (targetCompany == null) {
      ErrorSnackbar.show(context, message: l.selectCompany);
      return;
    }

    setState(() => _isImporting = true);

    final keyword = _technicianKeywordController.text.trim();
    if (keyword.isEmpty) {
      setState(() => _isImporting = false);
      if (mounted) {
        ErrorSnackbar.show(context, message: l.importKeywordRequired);
      }
      return;
    }

    var importedCount = 0;
    var skippedRows = 0;
    var unresolvedTechs = 0;

    try {
      final users = _technicians; // Already loaded in initState
      final preparedBatches = <_PreparedImportBatch>[];

      for (final source in sources) {
        final bytes = await source.loadBytes();
        if (bytes == null || bytes.isEmpty) continue;

        final parsedMap =
            await compute<Map<String, dynamic>, Map<String, dynamic>>(
              parseHistoricalImportInIsolate,
              {
                'bytes': bytes,
                'users': users
                    .map(
                      (u) => {
                        'uid': u.uid,
                        'name': u.name,
                        'email': u.email,
                        'role': u.role,
                        'isActive': u.isActive,
                        'language': u.language,
                      },
                    )
                    .toList(),
                'adminUid': currentUser.uid,
                'targetUser': {
                  'uid': targetTechnician.uid,
                  'name': targetTechnician.name,
                  'email': targetTechnician.email,
                  'role': targetTechnician.role,
                  'isActive': targetTechnician.isActive,
                  'language': targetTechnician.language,
                },
                'targetCompany': {
                  'id': targetCompany.id,
                  'name': targetCompany.name,
                  'invoicePrefix': targetCompany.invoicePrefix,
                  'isActive': targetCompany.isActive,
                },
                'technicianKeyword': keyword,
              },
            );

        final parsed = HistoricalImportResult.fromJson(parsedMap);

        preparedBatches.add(
          _PreparedImportBatch(
            fileName: source.name,
            source: source,
            parsed: parsed,
          ),
        );
      }

      if (preparedBatches.isEmpty) {
        if (mounted) {
          ErrorSnackbar.show(context, message: l.importFailedNoRows);
        }
        return;
      }

      final shouldProceed = await _showImportPreviewDialog(preparedBatches);
      if (!shouldProceed) {
        return;
      }

      for (var i = 0; i < preparedBatches.length; i++) {
        final prepared = preparedBatches[i];
        final parsed = prepared.parsed;

        // Update progress (3.5)
        _importProgress.value = l.importProgressFile(
          i + 1,
          preparedBatches.length,
          prepared.fileName,
        );

        if (parsed.jobs.isNotEmpty) {
          importedCount += await ref
              .read(jobRepositoryProvider)
              .importJobs(parsed.jobs);
        }
        skippedRows += parsed.skippedRows;
        unresolvedTechs += parsed.unresolvedTechnicians;

        await prepared.source.cleanup();
      }

      if (!mounted) return;
      if (importedCount == 0) {
        ErrorSnackbar.show(context, message: l.importFailedNoRows);
      } else {
        SuccessSnackbar.show(
          context,
          message:
              '${l.importCompletedCount(importedCount)} • ${l.importSkippedCount(skippedRows)}',
        );
        if (unresolvedTechs > 0) {
          ErrorSnackbar.show(
            context,
            message: l.importUnresolvedTechRows(unresolvedTechs),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (e is AppException) {
        final locale = Localizations.localeOf(context).languageCode;
        ErrorSnackbar.show(context, message: e.message(locale));
      } else {
        ErrorSnackbar.show(context, message: l.importFailedNoRows);
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final companiesAsync = ref.watch(activeCompaniesProvider);
    final isRtl = Localizations.localeOf(context).languageCode != 'en';

    CompanyModel? findCompany(String? id, List<CompanyModel> companies) {
      if (id == null) return null;
      for (final company in companies) {
        if (company.id == id) {
          return company;
        }
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.importHistoryData)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ArcticCard(
              child: Column(
                crossAxisAlignment: isRtl
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    l.importHistoryData,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.importHistoryDataSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingTechnicians)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    companiesAsync.when(
                      data: (companies) {
                        if (_selectedCompany != null &&
                            findCompany(_selectedCompany!.id, companies) ==
                                null) {
                          _selectedCompany = null;
                        }

                        return CompanySelectorField(
                          companies: companies,
                          selectedCompanyId: _selectedCompany?.id,
                          enabled: !_isImporting,
                          includeNoCompanyOption: false,
                          labelText: l.company,
                          prefixIcon: const Icon(Icons.business_outlined),
                          onChanged: (selectedCompany) {
                            setState(() {
                              _selectedCompany = selectedCompany;
                            });
                          },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.importTargetTechnician,
                            style: Theme.of(context).textTheme.titleSmall,
                            textAlign: isRtl ? TextAlign.end : TextAlign.start,
                          ),
                        ),
                        IconButton(
                          onPressed: (_isImporting || _isLoadingTechnicians)
                              ? null
                              : _loadTechnicians,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTechnician?.uid,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.engineering_rounded),
                      ),
                      items: _technicians.map((technician) {
                        return DropdownMenuItem<String>(
                          value: technician.uid,
                          child: Text(
                            '${technician.name} • ${technician.email}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _isImporting
                          ? null
                          : (value) {
                              setState(() {
                                _selectedTechnician = _findTechnicianByUid(
                                  value,
                                );
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _technicianKeywordController,
                      enabled: !_isImporting,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l.importTechnicianKeyword,
                        hintText: l.importTechnicianKeywordHint,
                        helperText: l.importTechnicianKeywordHelp,
                        prefixIcon: const Icon(Icons.filter_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropTarget(
                      onDragDone: (detail) async {
                        if (_isDraggingFiles && mounted) {
                          setState(() => _isDraggingFiles = false);
                        }
                        await _importDroppedFiles(detail.files);
                      },
                      onDragEntered: (_) {
                        if (!_isImporting && mounted) {
                          setState(() => _isDraggingFiles = true);
                        }
                      },
                      onDragExited: (_) {
                        if (_isDraggingFiles && mounted) {
                          setState(() => _isDraggingFiles = false);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isDraggingFiles
                                ? ArcticTheme.arcticBlue
                                : ArcticTheme.arcticDivider,
                            width: _isDraggingFiles ? 2 : 1,
                          ),
                          color: _isDraggingFiles
                              ? ArcticTheme.arcticBlue.withValues(alpha: 0.08)
                              : Colors.transparent,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _isDraggingFiles
                                  ? Icons.file_download_done_rounded
                                  : Icons.upload_file_rounded,
                              size: 30,
                              color: _isDraggingFiles
                                  ? ArcticTheme.arcticBlue
                                  : ArcticTheme.arcticTextSecondary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l.importDropFilesTitle,
                              style: Theme.of(context).textTheme.titleSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.importDropFilesSubtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ArcticTheme.arcticTextSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isImporting ? null : _importFiles,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_rounded),
                      label: Text(
                        _isImporting ? l.importInProgress : l.uploadExcel,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArcticTheme.arcticBlue,
                        foregroundColor: ArcticTheme.arcticDarkBg,
                      ),
                    ),
                  ),
                  if (_isImporting)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ValueListenableBuilder<String>(
                        valueListenable: _importProgress,
                        builder: (context, progress, _) {
                          return Text(
                            progress,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: ArcticTheme.arcticTextSecondary,
                                ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparedImportBatch {
  const _PreparedImportBatch({
    required this.fileName,
    required this.source,
    required this.parsed,
  });

  final String fileName;
  final _ImportSource source;
  final HistoricalImportResult parsed;
}

class _ImportSource {
  const _ImportSource._({
    required this.name,
    required this.loadBytes,
    required this.cleanup,
  });

  factory _ImportSource.platformFile(PlatformFile source) {
    return _ImportSource._(
      name: source.name,
      loadBytes: () => loadPickedFileBytes(source),
      cleanup: () => cleanupPickedFile(source),
    );
  }

  factory _ImportSource.xFile(XFile source) {
    return _ImportSource._(
      name: source.name,
      loadBytes: source.readAsBytes,
      cleanup: () async {},
    );
  }

  final String name;
  final Future<Uint8List?> Function() loadBytes;
  final Future<void> Function() cleanup;
}
