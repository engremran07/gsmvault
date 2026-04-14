import 'dart:typed_data';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/invoice_utils.dart';

class HistoricalImportResult {
  const HistoricalImportResult({
    required this.jobs,
    required this.skippedRows,
    required this.unresolvedTechnicians,
    required this.rowsWithoutTechnicianName,
    required this.technicianNameCounts,
    required this.sheetSummaries,
  });

  factory HistoricalImportResult.fromJson(Map<String, dynamic> json) {
    return HistoricalImportResult(
      jobs: (json['jobs'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => JobModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      skippedRows: (json['skippedRows'] as num?)?.toInt() ?? 0,
      unresolvedTechnicians:
          (json['unresolvedTechnicians'] as num?)?.toInt() ?? 0,
      rowsWithoutTechnicianName:
          (json['rowsWithoutTechnicianName'] as num?)?.toInt() ?? 0,
      technicianNameCounts: _stringIntMapFromJson(json['technicianNameCounts']),
      sheetSummaries:
          (json['sheetSummaries'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (item) => HistoricalImportSheetSummary.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
    );
  }

  final List<JobModel> jobs;
  final int skippedRows;
  final int unresolvedTechnicians;
  final int rowsWithoutTechnicianName;
  final Map<String, int> technicianNameCounts;
  final List<HistoricalImportSheetSummary> sheetSummaries;

  Map<String, dynamic> toJson() {
    return {
      'jobs': jobs.map((job) => job.toJson()).toList(),
      'skippedRows': skippedRows,
      'unresolvedTechnicians': unresolvedTechnicians,
      'rowsWithoutTechnicianName': rowsWithoutTechnicianName,
      'technicianNameCounts': technicianNameCounts,
      'sheetSummaries': sheetSummaries.map((s) => s.toJson()).toList(),
    };
  }
}

class HistoricalImportSheetSummary {
  const HistoricalImportSheetSummary({
    required this.sheetName,
    required this.importedRows,
    required this.skippedRows,
    required this.unresolvedTechnicians,
    required this.rowsWithoutTechnicianName,
    required this.technicianNameCounts,
    required this.installedSplit,
    required this.installedWindow,
    required this.installedFreestanding,
    required this.uninstallSplit,
    required this.uninstallWindow,
    required this.uninstallFreestanding,
    required this.uninstallOld,
    this.note = '',
    this.noteCode = '',
  });

  factory HistoricalImportSheetSummary.fromJson(Map<String, dynamic> json) {
    return HistoricalImportSheetSummary(
      sheetName: json['sheetName'] as String? ?? '',
      importedRows: (json['importedRows'] as num?)?.toInt() ?? 0,
      skippedRows: (json['skippedRows'] as num?)?.toInt() ?? 0,
      unresolvedTechnicians:
          (json['unresolvedTechnicians'] as num?)?.toInt() ?? 0,
      rowsWithoutTechnicianName:
          (json['rowsWithoutTechnicianName'] as num?)?.toInt() ?? 0,
      technicianNameCounts: _stringIntMapFromJson(json['technicianNameCounts']),
      installedSplit: (json['installedSplit'] as num?)?.toInt() ?? 0,
      installedWindow: (json['installedWindow'] as num?)?.toInt() ?? 0,
      installedFreestanding:
          (json['installedFreestanding'] as num?)?.toInt() ?? 0,
      uninstallSplit: (json['uninstallSplit'] as num?)?.toInt() ?? 0,
      uninstallWindow: (json['uninstallWindow'] as num?)?.toInt() ?? 0,
      uninstallFreestanding:
          (json['uninstallFreestanding'] as num?)?.toInt() ?? 0,
      uninstallOld: (json['uninstallOld'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
      noteCode: json['noteCode'] as String? ?? '',
    );
  }

  final String sheetName;
  final int importedRows;
  final int skippedRows;
  final int unresolvedTechnicians;
  final int rowsWithoutTechnicianName;
  final Map<String, int> technicianNameCounts;
  final int installedSplit;
  final int installedWindow;
  final int installedFreestanding;
  final int uninstallSplit;
  final int uninstallWindow;
  final int uninstallFreestanding;
  final int uninstallOld;
  final String note;
  final String noteCode;

  Map<String, dynamic> toJson() {
    return {
      'sheetName': sheetName,
      'importedRows': importedRows,
      'skippedRows': skippedRows,
      'unresolvedTechnicians': unresolvedTechnicians,
      'rowsWithoutTechnicianName': rowsWithoutTechnicianName,
      'technicianNameCounts': technicianNameCounts,
      'installedSplit': installedSplit,
      'installedWindow': installedWindow,
      'installedFreestanding': installedFreestanding,
      'uninstallSplit': uninstallSplit,
      'uninstallWindow': uninstallWindow,
      'uninstallFreestanding': uninstallFreestanding,
      'uninstallOld': uninstallOld,
      'note': note,
      'noteCode': noteCode,
    };
  }
}

Map<String, int> _stringIntMapFromJson(dynamic raw) {
  if (raw is! Map) {
    return const <String, int>{};
  }

  final map = <String, int>{};
  for (final entry in raw.entries) {
    final key = entry.key?.toString() ?? '';
    if (key.isEmpty) {
      continue;
    }
    map[key] = (entry.value as num?)?.toInt() ?? 0;
  }
  return map;
}

Map<String, dynamic> parseHistoricalImportInIsolate(
  Map<String, dynamic> payload,
) {
  final usersRaw = payload['users'] as List<dynamic>? ?? const <dynamic>[];
  final users = usersRaw
      .map(
        (item) => UserModel(
          uid: (item as Map)['uid'] as String? ?? '',
          name: item['name'] as String? ?? '',
          email: item['email'] as String? ?? '',
          role: item['role'] as String? ?? 'technician',
          isActive: item['isActive'] as bool? ?? true,
          language: item['language'] as String? ?? 'en',
        ),
      )
      .toList();

  final targetUserMap = payload['targetUser'] as Map<String, dynamic>?;
  final targetUser = targetUserMap == null
      ? null
      : UserModel(
          uid: targetUserMap['uid'] as String? ?? '',
          name: targetUserMap['name'] as String? ?? '',
          email: targetUserMap['email'] as String? ?? '',
          role: targetUserMap['role'] as String? ?? 'technician',
          isActive: targetUserMap['isActive'] as bool? ?? true,
          language: targetUserMap['language'] as String? ?? 'en',
        );

  final targetCompanyMap = payload['targetCompany'] as Map<String, dynamic>?;
  final targetCompany = targetCompanyMap == null
      ? null
      : CompanyModel(
          id: targetCompanyMap['id'] as String? ?? '',
          name: targetCompanyMap['name'] as String? ?? '',
          invoicePrefix: targetCompanyMap['invoicePrefix'] as String? ?? '',
          isActive: targetCompanyMap['isActive'] as bool? ?? true,
        );

  final result = HistoricalJobsImportService.parseExcel(
    bytes: payload['bytes'] as Uint8List,
    users: users,
    adminUid: payload['adminUid'] as String,
    targetUser: targetUser,
    targetCompany: targetCompany,
    technicianKeyword: payload['technicianKeyword'] as String?,
  );

  return result.toJson();
}

class HistoricalJobsImportService {
  HistoricalJobsImportService._();

  static const int _maxDataRowsPerSheet = 5000;

  static const Map<String, int> _monthTokens = {
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static HistoricalImportResult parseExcel({
    required Uint8List bytes,
    required List<UserModel> users,
    required String adminUid,
    UserModel? targetUser,
    CompanyModel? targetCompany,
    String? technicianKeyword,
  }) {
    final workbook = excel_pkg.Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      return const HistoricalImportResult(
        jobs: [],
        skippedRows: 0,
        unresolvedTechnicians: 0,
        rowsWithoutTechnicianName: 0,
        technicianNameCounts: <String, int>{},
        sheetSummaries: [],
      );
    }

    final byUid = <String, UserModel>{};
    final byEmail = <String, UserModel>{};
    final byName = <String, UserModel>{};
    for (final u in users) {
      byUid[_normalizeLookup(u.uid)] = u;
      byEmail[_normalizeLookup(u.email)] = u;
      byName[_normalizeLookup(u.name)] = u;
    }

    final jobsByInvoice = <String, JobModel>{};
    final sheetSummaries = <HistoricalImportSheetSummary>[];
    final globalTechnicianNameCounts = <String, int>{};
    var skipped = 0;
    var unresolvedTech = 0;
    var rowsWithoutTechnicianName = 0;
    final normalizedKeyword = _normalizeLookup(technicianKeyword ?? '');

    for (final entry in workbook.tables.entries) {
      final sheetName = entry.key;
      final sheet = entry.value;
      final rows = sheet.rows;
      if (rows.isEmpty) continue;

      final sheetPeriodDate = _sheetPeriodDate(sheetName);
      final sheetPeriodLabel = _sheetPeriodLabel(sheetName, sheetPeriodDate);

      final headerMap = _buildHeaderMap(rows.first);
      if (headerMap.isEmpty) continue;

      var sheetImportedRows = 0;
      var sheetSkippedRows = 0;
      var sheetUnresolvedTechnicians = 0;
      var sheetRowsWithoutTechnicianName = 0;
      final sheetTechnicianNameCounts = <String, int>{};
      var sheetInstalledSplit = 0;
      var sheetInstalledWindow = 0;
      var sheetInstalledFreestanding = 0;
      var sheetUninstallSplit = 0;
      var sheetUninstallWindow = 0;
      var sheetUninstallFreestanding = 0;
      var sheetUninstallOld = 0;
      var sheetNote = '';
      var sheetNoteCode = '';
      final sheetUniqueInvoices = <String>{};

      final maxRowIndex = rows.length > _maxDataRowsPerSheet + 1
          ? _maxDataRowsPerSheet
          : rows.length - 1;
      if (rows.length > _maxDataRowsPerSheet + 1) {
        sheetNote = 'Row limit exceeded; only first 5000 rows were processed.';
        sheetNoteCode = 'row_limit_exceeded';
      }

      for (var i = 1; i <= maxRowIndex; i++) {
        final row = rows[i];
        if (_rowIsEmpty(row)) continue;

        final sourceTechName = _value(row, headerMap, [
          'tech name',
          'technician name',
        ]);
        if (sourceTechName.isEmpty) {
          rowsWithoutTechnicianName++;
          sheetRowsWithoutTechnicianName++;
        } else {
          _incrementTechnicianCount(globalTechnicianNameCounts, sourceTechName);
          _incrementTechnicianCount(sheetTechnicianNameCounts, sourceTechName);
        }

        final rawInvoice = _value(row, headerMap, [
          'invoice number',
          'invoice',
        ]);
        final invoice = InvoiceUtils.normalizeWithCompanyPrefix(
          rawInvoice,
          companyPrefix: targetCompany?.invoicePrefix,
        );
        if (invoice.isEmpty) {
          skipped++;
          sheetSkippedRows++;
          continue;
        }

        if (normalizedKeyword.isNotEmpty &&
            !_rowMatchesKeyword(row, headerMap, normalizedKeyword)) {
          skipped++;
          sheetSkippedRows++;
          continue;
        }

        final tech =
            targetUser ?? _resolveUser(row, headerMap, byUid, byEmail, byName);
        if (tech == null) {
          unresolvedTech++;
          sheetUnresolvedTechnicians++;
          continue;
        }

        final splitQty = _intValue(row, headerMap, ['split']);
        final windowQty = _intValue(row, headerMap, ['window']);
        final standingQty = _intValue(row, headerMap, [
          'free standing',
          'freestanding',
          'dolab',
        ]);
        final uninstallTotal = _intValue(row, headerMap, [
          'uninstallation total',
          'uninstallation',
        ]);

        final description = _value(row, headerMap, ['description', 'note']);
        final uninstallSplitTagged = _extractTaggedValue(description, 'S');
        final uninstallWindowTagged = _extractTaggedValue(description, 'W');
        final uninstallStandingTagged = _extractTaggedValue(description, 'F');

        final uninstallDistribution = _distributeUninstallTypes(
          uninstallTotal: uninstallTotal,
          splitInstalled: splitQty,
          windowInstalled: windowQty,
          freestandingInstalled: standingQty,
          splitTagged: uninstallSplitTagged,
          windowTagged: uninstallWindowTagged,
          freestandingTagged: uninstallStandingTagged,
        );

        final units = <AcUnit>[];
        if (splitQty > 0) {
          units.add(
            AcUnit(type: AppConstants.unitTypeSplitAc, quantity: splitQty),
          );
        }
        if (windowQty > 0) {
          units.add(
            AcUnit(type: AppConstants.unitTypeWindowAc, quantity: windowQty),
          );
        }
        if (standingQty > 0) {
          units.add(
            AcUnit(
              type: AppConstants.unitTypeFreestandingAc,
              quantity: standingQty,
            ),
          );
        }
        if (uninstallDistribution.old > 0) {
          units.add(
            AcUnit(
              type: AppConstants.unitTypeUninstallOld,
              quantity: uninstallDistribution.old,
            ),
          );
        }
        if (uninstallDistribution.split > 0) {
          units.add(
            AcUnit(
              type: AppConstants.unitTypeUninstallSplit,
              quantity: uninstallDistribution.split,
            ),
          );
        }
        if (uninstallDistribution.window > 0) {
          units.add(
            AcUnit(
              type: AppConstants.unitTypeUninstallWindow,
              quantity: uninstallDistribution.window,
            ),
          );
        }
        if (uninstallDistribution.freestanding > 0) {
          units.add(
            AcUnit(
              type: AppConstants.unitTypeUninstallFreestanding,
              quantity: uninstallDistribution.freestanding,
            ),
          );
        }

        if (units.isEmpty) {
          skipped++;
          sheetSkippedRows++;
          continue;
        }

        final invoiceKey = invoice.toLowerCase();
        sheetUniqueInvoices.add(invoiceKey);
        sheetInstalledSplit += splitQty;
        sheetInstalledWindow += windowQty;
        sheetInstalledFreestanding += standingQty;
        sheetUninstallSplit += uninstallDistribution.split;
        sheetUninstallWindow += uninstallDistribution.window;
        sheetUninstallFreestanding += uninstallDistribution.freestanding;
        sheetUninstallOld += uninstallDistribution.old;

        final bracket = _doubleValue(row, headerMap, ['bracket']);
        final delivery = _doubleValue(row, headerMap, ['delivery']);
        final date =
            _dateValue(row, headerMap, ['date']) ??
            sheetPeriodDate ??
            DateTime.now();
        final contact = _value(row, headerMap, ['contact', 'client contact']);
        final clientName = _value(row, headerMap, ['client name']);
        final rowCompanyName = _value(row, headerMap, ['company']);
        final companyName = rowCompanyName.isNotEmpty
            ? rowCompanyName
            : (targetCompany?.name ?? '');

        final existing = jobsByInvoice[invoiceKey];
        if (existing == null) {
          jobsByInvoice[invoiceKey] = JobModel(
            techId: tech.uid,
            techName: tech.name,
            companyId: targetCompany?.id ?? '',
            companyName: companyName,
            invoiceNumber: invoice,
            clientName: clientName.isEmpty
                ? _importedClientName(sheetPeriodLabel, invoice)
                : clientName,
            clientContact: contact,
            acUnits: units,
            status: JobStatus.approved,
            expenses: 0,
            expenseNote: description,
            adminNote: _buildAdminImportNote(),
            importMeta: {
              'sourceSheet': sheetName,
              'sourcePeriod': sheetPeriodLabel,
              'sourceTechnician': sourceTechName,
              'importedBy': adminUid,
            },
            approvedBy: adminUid,
            charges: InvoiceCharges(
              acBracket: bracket > 0,
              bracketCount: bracket > 0 ? 1 : 0,
              bracketAmount: bracket,
              deliveryCharge: delivery > 0,
              deliveryAmount: delivery,
              deliveryNote: description,
            ),
            date: date,
            submittedAt: date,
            reviewedAt: date,
          );
        } else {
          jobsByInvoice[invoiceKey] = existing.copyWith(
            clientName:
                existing.clientName.trim().isEmpty &&
                    clientName.trim().isNotEmpty
                ? clientName
                : existing.clientName,
            clientContact:
                existing.clientContact.trim().isEmpty &&
                    contact.trim().isNotEmpty
                ? contact
                : existing.clientContact,
            acUnits: _mergeUnits(existing.acUnits, units),
            expenseNote: _mergeText(existing.expenseNote, description),
            charges: _mergeCharges(
              existing.charges,
              bracket,
              delivery,
              description,
            ),
            date: existing.date ?? date,
            submittedAt: existing.submittedAt ?? date,
            reviewedAt: existing.reviewedAt ?? date,
          );
        }
      }

      sheetImportedRows = sheetUniqueInvoices.length;

      sheetSummaries.add(
        HistoricalImportSheetSummary(
          sheetName: sheetName,
          importedRows: sheetImportedRows,
          skippedRows: sheetSkippedRows,
          unresolvedTechnicians: sheetUnresolvedTechnicians,
          rowsWithoutTechnicianName: sheetRowsWithoutTechnicianName,
          technicianNameCounts: sheetTechnicianNameCounts,
          installedSplit: sheetInstalledSplit,
          installedWindow: sheetInstalledWindow,
          installedFreestanding: sheetInstalledFreestanding,
          uninstallSplit: sheetUninstallSplit,
          uninstallWindow: sheetUninstallWindow,
          uninstallFreestanding: sheetUninstallFreestanding,
          uninstallOld: sheetUninstallOld,
          note: sheetNote,
          noteCode: sheetNoteCode,
        ),
      );
    }

    return HistoricalImportResult(
      jobs: jobsByInvoice.values.toList(),
      skippedRows: skipped,
      unresolvedTechnicians: unresolvedTech,
      rowsWithoutTechnicianName: rowsWithoutTechnicianName,
      technicianNameCounts: globalTechnicianNameCounts,
      sheetSummaries: sheetSummaries,
    );
  }

  static List<AcUnit> _mergeUnits(List<AcUnit> first, List<AcUnit> second) {
    final totals = <String, int>{};
    for (final unit in first) {
      totals[unit.type] = (totals[unit.type] ?? 0) + unit.quantity;
    }
    for (final unit in second) {
      totals[unit.type] = (totals[unit.type] ?? 0) + unit.quantity;
    }

    return totals.entries
        .map((entry) => AcUnit(type: entry.key, quantity: entry.value))
        .toList();
  }

  static String _mergeText(String existing, String incoming) {
    final a = existing.trim();
    final b = incoming.trim();
    if (a.isEmpty) return b;
    if (b.isEmpty || a == b) return a;
    return '$a | $b';
  }

  static InvoiceCharges _mergeCharges(
    InvoiceCharges? existing,
    double bracket,
    double delivery,
    String description,
  ) {
    final current = existing ?? const InvoiceCharges();
    final nextBracket = bracket > current.bracketAmount
        ? bracket
        : current.bracketAmount;
    final nextDelivery = delivery > current.deliveryAmount
        ? delivery
        : current.deliveryAmount;

    return current.copyWith(
      acBracket: current.acBracket || bracket > 0,
      bracketCount: current.bracketCount > 0
          ? current.bracketCount
          : ((current.acBracket || current.bracketAmount > 0 || bracket > 0)
                ? 1
                : 0),
      bracketAmount: nextBracket,
      deliveryCharge: current.deliveryCharge || delivery > 0,
      deliveryAmount: nextDelivery,
      deliveryNote: _mergeText(current.deliveryNote, description),
    );
  }

  static bool _rowIsEmpty(List<excel_pkg.Data?> row) {
    for (final cell in row) {
      final text = _normalizeCellText(cell?.value?.toString() ?? '');
      if (text.isNotEmpty) return false;
    }
    return true;
  }

  static Map<String, int> _buildHeaderMap(List<excel_pkg.Data?> headerRow) {
    final map = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final key = _normalizeHeaderKey(
        (headerRow[i]?.value?.toString() ?? '').trim().toLowerCase(),
      );
      if (key.isNotEmpty) map[key] = i;
    }

    if (!map.containsKey('split')) {
      final contactIndex = map['contact'];
      final windowIndex = map['window'];
      if (contactIndex != null && windowIndex != null) {
        final candidateIndex = windowIndex - 1;
        if (candidateIndex > contactIndex &&
            candidateIndex < headerRow.length) {
          final candidateHeader =
              (headerRow[candidateIndex]?.value?.toString() ?? '').trim();
          if (candidateHeader.isEmpty && candidateIndex > contactIndex) {
            map['split'] = candidateIndex;
          }
        }
      }
      if (!map.containsKey('split') && windowIndex != null && windowIndex > 1) {
        for (var checkIdx = 0; checkIdx < windowIndex; checkIdx++) {
          final header = (headerRow[checkIdx]?.value?.toString() ?? '').trim();
          if (header.isEmpty &&
              (contactIndex == null || checkIdx > contactIndex) &&
              !map.containsValue(checkIdx)) {
            map['split'] = checkIdx;
            break;
          }
        }
      }
    }

    return map;
  }

  static String _normalizeHeaderKey(String rawKey) {
    final normalized = rawKey
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_\-.]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 /]'), '')
        .trim();

    return switch (normalized) {
      'inv' ||
      'invoice no' ||
      'invoice #' ||
      'invoice number' ||
      'invoice' => 'invoice number',
      'tech' ||
      'tech name' ||
      'technician' ||
      'technician name' => 'technician name',
      'technician email' || 'tech email' || 'email' => 'technician email',
      'technician id' || 'tech id' || 'techid' || 'uid' => 'technician id',
      'client' || 'customer' || 'client name' => 'client name',
      'contact no' || 'phone' || 'mobile' || 'client contact' => 'contact',
      'free standing' ||
      'freestanding' ||
      'standing' ||
      'dolab' => 'freestanding',
      'uninstall' ||
      'uninstallation total' ||
      'uninstalation' ||
      'uninstalation split/window' => 'uninstallation total',
      'delery' || 'delivery charges' || 'delivery charge' => 'delivery',
      'c' || 'remarks' || 'description' || 'note' => 'description',
      'company' || 'company name' || 'co' || 'co name' => 'company',
      _ => normalized,
    };
  }

  static String _normalizeCellText(String raw) {
    return raw
        .replaceAll(RegExp(r'[\u00A0\u2007\u202F]'), ' ')
        .replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  static String _normalizeLookup(String raw) {
    return _normalizeCellText(raw).toLowerCase();
  }

  static String _normalizeNumericText(String raw) {
    final normalized = _normalizeCellText(raw).replaceAll(',', '');
    final direct = normalized.replaceAll(RegExp(r'[^0-9.\-+]'), '');
    if (direct.isNotEmpty) {
      return direct;
    }

    final match = RegExp(r'[-+]?\d+(?:\.\d+)?').firstMatch(normalized);
    return match?.group(0) ?? '';
  }

  static String _value(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    List<String> possibleKeys,
  ) {
    for (final k in possibleKeys) {
      final idx = headerMap[_normalizeHeaderKey(k)];
      if (idx == null || idx >= row.length) continue;
      final v = _normalizeCellText(row[idx]?.value?.toString() ?? '');
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static int _intValue(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    List<String> keys,
  ) {
    final raw = _value(row, headerMap, keys);
    if (raw.isEmpty) return 0;

    final normalized = _normalizeNumericText(raw);
    return int.tryParse(normalized) ??
        double.tryParse(normalized)?.round() ??
        0;
  }

  static double _doubleValue(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    List<String> keys,
  ) {
    final raw = _value(row, headerMap, keys);
    if (raw.isEmpty) return 0;

    final normalized = _normalizeNumericText(raw);
    return double.tryParse(normalized) ?? 0;
  }

  static DateTime? _dateValue(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    List<String> keys,
  ) {
    final raw = _value(row, headerMap, keys);
    if (raw.isEmpty) return null;

    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    final excelSerial = double.tryParse(raw);
    if (excelSerial != null) {
      return _excelSerialToDate(excelSerial);
    }

    final parts = raw.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]) ?? 1;
      final m = int.tryParse(parts[1]) ?? 1;
      final y = int.tryParse(parts[2]) ?? DateTime.now().year;
      return DateTime(y, m, d);
    }
    return null;
  }

  static DateTime _excelSerialToDate(double serial) {
    final wholeDays = serial.floor();
    final fractionalDay = serial - wholeDays;
    final baseDate = DateTime(1899, 12, 30);
    final dayPart = Duration(days: wholeDays);
    final timePart = Duration(milliseconds: (fractionalDay * 86400000).round());
    return baseDate.add(dayPart).add(timePart);
  }

  static int _extractTaggedValue(String description, String tag) {
    final regex = RegExp('(^|\\s|\\|)$tag:(\\d+)', caseSensitive: false);
    final match = regex.firstMatch(description);
    return match == null ? 0 : int.tryParse(match.group(2) ?? '') ?? 0;
  }

  static _UninstallDistribution _distributeUninstallTypes({
    required int uninstallTotal,
    required int splitInstalled,
    required int windowInstalled,
    required int freestandingInstalled,
    required int splitTagged,
    required int windowTagged,
    required int freestandingTagged,
  }) {
    var split = splitTagged;
    var window = windowTagged;
    var freestanding = freestandingTagged;

    final taggedTotal = split + window + freestanding;
    final effectiveTotal = uninstallTotal > taggedTotal
        ? uninstallTotal
        : taggedTotal;

    var remaining = effectiveTotal - taggedTotal;

    // If some uninstall units are not typed in Excel, infer them from the
    // installed AC mix on the same invoice before falling back to old AC.
    final splitCapacity = (splitInstalled - split).clamp(0, 9999);
    final splitAdd = remaining > splitCapacity ? splitCapacity : remaining;
    split += splitAdd;
    remaining -= splitAdd;

    final windowCapacity = (windowInstalled - window).clamp(0, 9999);
    final windowAdd = remaining > windowCapacity ? windowCapacity : remaining;
    window += windowAdd;
    remaining -= windowAdd;

    final freestandingCapacity = (freestandingInstalled - freestanding).clamp(
      0,
      9999,
    );
    final freestandingAdd = remaining > freestandingCapacity
        ? freestandingCapacity
        : remaining;
    freestanding += freestandingAdd;
    remaining -= freestandingAdd;

    final old = remaining.clamp(0, 9999);
    return _UninstallDistribution(
      split: split,
      window: window,
      freestanding: freestanding,
      old: old,
    );
  }

  static bool _rowMatchesKeyword(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    String keyword,
  ) {
    final candidates = [
      _value(row, headerMap, ['tech name', 'technician name']),
      _value(row, headerMap, ['technician email', 'tech email', 'email']),
      _value(row, headerMap, ['technician id', 'tech id', 'techid', 'uid']),
    ];

    for (final candidate in candidates) {
      if (_normalizeLookup(candidate).contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  static String _buildAdminImportNote() {
    return 'Imported historical record';
  }

  static DateTime? _sheetPeriodDate(String sheetName) {
    final normalized = sheetName.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    int? month;
    for (final token in _monthTokens.entries) {
      if (normalized.contains(token.key)) {
        month = token.value;
        break;
      }
    }

    final yearMatch = RegExp(r'(20\d{2})').firstMatch(normalized);
    final year = yearMatch == null ? null : int.tryParse(yearMatch.group(1)!);

    if (month == null || year == null) return null;
    return DateTime(year, month, 1);
  }

  static String _sheetPeriodLabel(String sheetName, DateTime? period) {
    if (period != null) {
      final monthLabel = _monthNames[period.month - 1];
      return '$monthLabel ${period.year}';
    }
    final cleaned = sheetName.trim();
    return cleaned.isEmpty ? 'Unknown Period' : cleaned;
  }

  static String _importedClientName(String periodLabel, String invoice) {
    final normalizedPeriod = periodLabel.trim();
    final normalizedInvoice = invoice.trim();

    if (normalizedPeriod.isNotEmpty && normalizedInvoice.isNotEmpty) {
      return 'Imported $normalizedPeriod • $normalizedInvoice';
    }
    if (normalizedInvoice.isNotEmpty) {
      return 'Imported • $normalizedInvoice';
    }
    if (normalizedPeriod.isNotEmpty) {
      return 'Imported $normalizedPeriod';
    }
    return 'Imported Record';
  }

  static UserModel? _resolveUser(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    Map<String, UserModel> byUid,
    Map<String, UserModel> byEmail,
    Map<String, UserModel> byName,
  ) {
    final uid = _normalizeLookup(
      _value(row, headerMap, ['technician id', 'tech id', 'techid', 'uid']),
    );
    if (uid.isNotEmpty && byUid.containsKey(uid)) return byUid[uid];

    final email = _normalizeLookup(
      _value(row, headerMap, ['technician email', 'tech email', 'email']),
    );
    if (email.isNotEmpty && byEmail.containsKey(email)) return byEmail[email];

    final name = _normalizeLookup(
      _value(row, headerMap, ['tech name', 'technician name']),
    );
    if (name.isNotEmpty && byName.containsKey(name)) return byName[name];

    if (name.isNotEmpty) {
      final matches = byName.entries
          .where(
            (entry) => entry.key.contains(name) || name.contains(entry.key),
          )
          .map((entry) => entry.value)
          .toSet()
          .toList();
      if (matches.length == 1) {
        return matches.first;
      }
    }

    return null;
  }

  static void _incrementTechnicianCount(
    Map<String, int> counts,
    String rawName,
  ) {
    final name = _normalizeCellText(rawName);
    if (name.isEmpty) {
      return;
    }

    final normalized = _normalizeLookup(name);
    final existingKey = counts.keys.firstWhere(
      (key) => _normalizeLookup(key) == normalized,
      orElse: () => '',
    );

    final targetKey = existingKey.isEmpty ? name : existingKey;
    counts[targetKey] = (counts[targetKey] ?? 0) + 1;
  }
}

class _UninstallDistribution {
  const _UninstallDistribution({
    required this.split,
    required this.window,
    required this.freestanding,
    required this.old,
  });

  final int split;
  final int window;
  final int freestanding;
  final int old;
}
