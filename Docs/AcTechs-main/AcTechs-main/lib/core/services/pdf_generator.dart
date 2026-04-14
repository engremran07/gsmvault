import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart' as reshaper;
import 'package:bidi/bidi.dart' as bidi;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/services/report_branding.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/base64_image_codec.dart';
import 'package:ac_techs/core/theme/app_fonts.dart';

// â”€â”€â”€ Brand colours (mirrors arctic_theme.dart) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const _kBrandBlue = PdfColor.fromInt(0xFF00D4FF); // arctic blue
const _kBrandDark = PdfColor.fromInt(0xFF0D1117); // near-black
const _kGreen = PdfColor.fromInt(0xFF00C853);
const _kRed = PdfColor.fromInt(0xFFD50000);
const _kAmber = PdfColor.fromInt(0xFFFFB300);

// â”€â”€â”€ Isolate PDF generation (to avoid UI freeze on large reports) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Parameters passed to isolate PDF generation function.
class _PdfGenerationParams {
  final List<JobModel> jobs;
  final String title;
  final String locale;
  final Uint8List? rtlFontBytes;
  final Map<String, List<String>> sharedInstallerNamesByGroup;
  final String? technicianName;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool useDetails;
  final int maxPages;
  final String serviceCompanyName;
  final String serviceCompanyLogoBase64;
  final String serviceCompanyPhoneNumber;
  final String clientCompanyName;
  final String clientCompanyLogoBase64;

  _PdfGenerationParams({
    required this.jobs,
    required this.title,
    required this.locale,
    this.rtlFontBytes,
    this.sharedInstallerNamesByGroup = const <String, List<String>>{},
    this.technicianName, // ignore: unused_element_parameter â€” reserved for future filter by technician feature
    this.fromDate, // ignore: unused_element_parameter â€” reserved for future date range feature
    this.toDate, // ignore: unused_element_parameter â€” reserved for future date range feature
    this.useDetails = false,
    this.maxPages = 2000,
    this.serviceCompanyName = '',
    this.serviceCompanyLogoBase64 = '',
    this.serviceCompanyPhoneNumber = '',
    this.clientCompanyName = '',
    this.clientCompanyLogoBase64 = '',
  });
}

class _InOutReportParams {
  _InOutReportParams({
    required this.fontBytes,
    required this.locale,
    required this.earnings,
    required this.expenses,
    this.technicianName,
    this.reportTitle,
    this.reportDate,
    this.periodLabel,
    this.monthlyMode = false,
    this.serviceCompanyName = '',
    this.serviceCompanyLogoBase64 = '',
    this.serviceCompanyPhoneNumber = '',
    this.clientCompanyName,
    this.clientCompanyLogoBase64,
  });

  final Uint8List? fontBytes;
  final String locale;
  final List<EarningModel> earnings;
  final List<ExpenseModel> expenses;
  final String? technicianName;
  final String? reportTitle;
  final DateTime? reportDate;
  final String? periodLabel;
  final bool monthlyMode;
  final String serviceCompanyName;
  final String serviceCompanyLogoBase64;
  final String serviceCompanyPhoneNumber;
  final String? clientCompanyName;
  final String? clientCompanyLogoBase64;
}

class _CompanyInvoicesParams {
  _CompanyInvoicesParams({
    required this.fontBytes,
    required this.locale,
    required this.jobs,
    this.reportTitle,
    this.periodLabel,
    this.companyLogoBase64 = '',
    this.serviceCompanyName = '',
    this.serviceCompanyLogoBase64 = '',
    this.serviceCompanyPhoneNumber = '',
    this.clientCompanyName,
    this.clientCompanyLogoBase64,
  });

  final Uint8List? fontBytes;
  final String locale;
  final List<JobModel> jobs;
  final String? reportTitle;
  final String? periodLabel;
  final String companyLogoBase64;
  final String serviceCompanyName;
  final String serviceCompanyLogoBase64;
  final String serviceCompanyPhoneNumber;
  final String? clientCompanyName;
  final String? clientCompanyLogoBase64;
}

/// Top-level function for isolate PDF generation (called via compute()).
Future<Uint8List> _isolatePdfGeneration(_PdfGenerationParams params) async {
  final reportBranding = ReportBrandingContext(
    serviceCompany: ReportBrandIdentity(
      name: params.serviceCompanyName,
      logoBase64: params.serviceCompanyLogoBase64,
      phoneNumber: params.serviceCompanyPhoneNumber,
    ),
    clientCompany: params.clientCompanyName.trim().isEmpty
        ? null
        : ReportBrandIdentity(
            name: params.clientCompanyName,
            logoBase64: params.clientCompanyLogoBase64,
          ),
  );

  if (params.useDetails) {
    return PdfGenerator.generateJobsDetailsReport(
      jobs: params.jobs,
      title: params.title,
      locale: params.locale,
      rtlFontBytes: params.rtlFontBytes,
      sharedInstallerNamesByGroup: params.sharedInstallerNamesByGroup,
      technicianName: params.technicianName,
      fromDate: params.fromDate,
      toDate: params.toDate,
      maxPages: params.maxPages,
      reportBranding: reportBranding,
    );
  } else {
    return PdfGenerator.generateJobsReport(
      jobs: params.jobs,
      title: params.title,
      locale: params.locale,
      rtlFontBytes: params.rtlFontBytes,
      technicianName: params.technicianName,
      fromDate: params.fromDate,
      toDate: params.toDate,
      reportBranding: reportBranding,
    );
  }
}

/// Unified PDF report generator with RTL font support for all 3 locales.
///
/// All public methods are `static` so callers do not need an instance.
/// Fonts are loaded lazily and cached for the lifetime of the process.
class PdfGenerator {
  PdfGenerator._();
  static final reshaper.ArabicReshaper _reshaper = reshaper.ArabicReshaper();
  static final RegExp _arabicScriptRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    unicode: true,
  );

  static String _shapeRtlForPdf(String locale, String text) {
    if (locale != 'ur' && locale != 'ar') return text;
    if (text.isEmpty || !_arabicScriptRegex.hasMatch(text)) return text;
    final reshaped = _reshaper.reshape(text);
    return String.fromCharCodes(bidi.logicalToVisual(reshaped));
  }

  static List<String> _shapeRowForPdf(String locale, List<String> row) {
    if (locale != 'ur' && locale != 'ar') return row;
    return row.map((value) => _shapeRtlForPdf(locale, value)).toList();
  }

  static int _jobReportSplitQty(JobModel job) => job.isSharedInstall
      ? job.sharedInvoiceSplitUnits
      : job.unitsForType(AppConstants.unitTypeSplitAc);

  static int _jobReportWindowQty(JobModel job) => job.isSharedInstall
      ? job.sharedInvoiceWindowUnits
      : job.unitsForType(AppConstants.unitTypeWindowAc);

  static int _jobReportFreestandingQty(JobModel job) => job.isSharedInstall
      ? job.sharedInvoiceFreestandingUnits
      : job.unitsForType(AppConstants.unitTypeFreestandingAc);

  static int _jobReportUninstallLegacyQty(JobModel job) =>
      job.unitsForType(AppConstants.unitTypeUninstallOld);

  static int _jobReportUninstallSplitQty(JobModel job) => job.isSharedInstall
      ? job.sharedInvoiceUninstallSplitUnits
      : job.unitsForType(AppConstants.unitTypeUninstallSplit);

  static int _jobReportUninstallWindowQty(JobModel job) => job.isSharedInstall
      ? job.sharedInvoiceUninstallWindowUnits
      : job.unitsForType(AppConstants.unitTypeUninstallWindow);

  static int _jobReportUninstallFreestandingQty(JobModel job) =>
      job.isSharedInstall
      ? job.sharedInvoiceUninstallFreestandingUnits
      : job.unitsForType(AppConstants.unitTypeUninstallFreestanding);

  static int _jobReportBracketCount(JobModel job) => job.isSharedInstall
      ? job.sharedInvoiceBracketCount
      : job.effectiveBracketCount;

  static double _jobReportDeliveryAmount(JobModel job) {
    final deliveryNote = job.charges?.deliveryNote ?? '';
    final amount = job.isSharedInstall
        ? job.sharedInvoiceDeliveryAmount
        : (job.charges?.deliveryAmount ?? 0);
    if (amount <= 0 || AppFormatters.isCustomerCashPaid(deliveryNote)) {
      return 0;
    }
    return amount;
  }

  static List<String> _sharedInstallerNames(
    JobModel job,
    Map<String, List<String>> sharedInstallerNamesByGroup,
  ) {
    final groupKey = job.sharedInstallGroupKey.trim();
    final sharedNames = groupKey.isEmpty
        ? const <String>[]
        : (sharedInstallerNamesByGroup[groupKey] ?? const <String>[]);
    final fallbackName = job.techName.trim();
    final uniqueNames = <String>{
      ...sharedNames
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty),
      if (fallbackName.isNotEmpty) fallbackName,
    };
    return uniqueNames.toList(growable: false);
  }

  static String _sharedInstallerDescription(
    String locale,
    JobModel job,
    Map<String, List<String>> sharedInstallerNamesByGroup,
  ) {
    if (!job.isSharedInstall) {
      return '';
    }
    final names = _sharedInstallerNames(job, sharedInstallerNamesByGroup);
    if (names.isEmpty) {
      return locale == 'ur'
          ? 'Ù…Ø´ØªØ±Ú©Û Ø§Ù†Ø³Ù¹Ø§Ù„ Ù¹ÛŒÙ…'
          : locale == 'ar'
          ? 'ÙØ±ÙŠÙ‚ Ø§Ù„ØªØ±ÙƒÙŠØ¨ Ø§Ù„Ù…Ø´ØªØ±Ùƒ'
          : 'Shared Install Team';
    }
    final label = locale == 'ur'
        ? 'Ù…Ø´ØªØ±Ú©Û Ø§Ù†Ø³Ù¹Ø§Ù„ Ù¹ÛŒÙ…'
        : locale == 'ar'
        ? 'ÙØ±ÙŠÙ‚ Ø§Ù„ØªØ±ÙƒÙŠØ¨ Ø§Ù„Ù…Ø´ØªØ±Ùƒ'
        : 'Shared Install Team';
    return '$label: ${names.join(', ')}';
  }

  static List<List<String>> _shapeTableForPdf(
    String locale,
    List<List<String>> rows,
  ) {
    if (locale != 'ur' && locale != 'ar') return rows;
    return rows.map((row) => _shapeRowForPdf(locale, row)).toList();
  }

  static String _translateCategoryForPdf(String locale, String key) {
    if (locale == 'ar') {
      return switch (key) {
        'Installed Bracket' => 'ØªØ±ÙƒÙŠØ¨ Ø­Ø§Ù…Ù„',
        'Installed Extra Pipe' => 'ØªØ±ÙƒÙŠØ¨ Ø£Ù†Ø¨ÙˆØ¨ Ø¥Ø¶Ø§ÙÙŠ',
        'Old AC Removal' => 'Ø¥Ø²Ø§Ù„Ø© Ù…ÙƒÙŠÙ Ù‚Ø¯ÙŠÙ…',
        'Old AC Installation' => 'ØªØ±ÙƒÙŠØ¨ Ù…ÙƒÙŠÙ Ù‚Ø¯ÙŠÙ…',
        'Sold Old AC' => 'Ø¨ÙŠØ¹ Ù…ÙƒÙŠÙ Ù‚Ø¯ÙŠÙ…',
        'Sold Scrap' => 'Ø¨ÙŠØ¹ Ø®Ø±Ø¯Ø©',
        'Food' => 'Ø·Ø¹Ø§Ù…',
        'Petrol' => 'ÙˆÙ‚ÙˆØ¯',
        'Pipes' => 'Ø£Ù†Ø§Ø¨ÙŠØ¨',
        'Tools' => 'Ø£Ø¯ÙˆØ§Øª',
        'Tape' => 'Ø´Ø±ÙŠØ·',
        'Insulation' => 'Ø¹Ø²Ù„',
        'Gas' => 'ØºØ§Ø²',
        'Other Consumables' => 'Ù…Ø³ØªÙ‡Ù„ÙƒØ§Øª Ø£Ø®Ø±Ù‰',
        'House Rent' => 'Ø¥ÙŠØ¬Ø§Ø± Ø§Ù„Ù…Ù†Ø²Ù„',
        'Other' => 'Ø£Ø®Ø±Ù‰',
        'Bread/Roti' => 'Ø®Ø¨Ø²/Ø±ÙˆØªÙŠ',
        'Meat' => 'Ù„Ø­Ù…',
        'Chicken' => 'Ø¯Ø¬Ø§Ø¬',
        'Tea' => 'Ø´Ø§ÙŠ',
        'Sugar' => 'Ø³ÙƒØ±',
        'Rice' => 'Ø£Ø±Ø²',
        'Vegetables' => 'Ø®Ø¶Ø±ÙˆØ§Øª',
        'Cooking Oil' => 'Ø²ÙŠØª Ø·Ø¨Ø®',
        'Milk' => 'Ø­Ù„ÙŠØ¨',
        'Spices' => 'Ø¨Ù‡Ø§Ø±Ø§Øª',
        'Other Groceries' => 'Ø¨Ù‚Ø§Ù„Ø© Ø£Ø®Ø±Ù‰',
        _ => key,
      };
    }
    if (locale == 'ur') {
      return switch (key) {
        'Installed Bracket' => 'Ø¨Ø±ÛŒÚ©Ù¹ Ø§Ù†Ø³Ù¹Ø§Ù„',
        'Installed Extra Pipe' => 'Ø§Ø¶Ø§ÙÛŒ Ù¾Ø§Ø¦Ù¾ Ø§Ù†Ø³Ù¹Ø§Ù„',
        'Old AC Removal' => 'Ù¾Ø±Ø§Ù†Ø§ Ø§Û’ Ø³ÛŒ ÛÙ¹Ø§ÛŒØ§',
        'Old AC Installation' => 'Ù¾Ø±Ø§Ù†Ø§ Ø§Û’ Ø³ÛŒ Ø§Ù†Ø³Ù¹Ø§Ù„',
        'Sold Old AC' => 'Ù¾Ø±Ø§Ù†Ø§ Ø§Û’ Ø³ÛŒ ÙØ±ÙˆØ®Øª',
        'Sold Scrap' => 'Ø³Ú©Ø±ÛŒÙ¾ ÙØ±ÙˆØ®Øª',
        'Food' => 'Ú©Ú¾Ø§Ù†Ø§',
        'Petrol' => 'Ù¾ÛŒÙ¹Ø±ÙˆÙ„',
        'Pipes' => 'Ù¾Ø§Ø¦Ù¾Ø³',
        'Tools' => 'Ø§ÙˆØ²Ø§Ø±',
        'Tape' => 'Ù¹ÛŒÙ¾',
        'Insulation' => 'Ø§Ù†Ø³ÙˆÙ„ÛŒØ´Ù†',
        'Gas' => 'Ú¯ÛŒØ³',
        'Other Consumables' => 'Ø¯ÛŒÚ¯Ø± Ú©Ù†Ø²ÛŒÙˆÙ… Ø§ÛŒØ¨Ù„Ø²',
        'House Rent' => 'Ú¯Ú¾Ø± Ú©Ø§ Ú©Ø±Ø§ÛŒÛ',
        'Other' => 'Ø¯ÛŒÚ¯Ø±',
        'Bread/Roti' => 'Ø±ÙˆÙ¹ÛŒ',
        'Meat' => 'Ú¯ÙˆØ´Øª',
        'Chicken' => 'Ú†Ú©Ù†',
        'Tea' => 'Ú†Ø§Ø¦Û’',
        'Sugar' => 'Ú†ÛŒÙ†ÛŒ',
        'Rice' => 'Ú†Ø§ÙˆÙ„',
        'Vegetables' => 'Ø³Ø¨Ø²ÛŒØ§Úº',
        'Cooking Oil' => 'Ú©ÙˆÚ©Ù†Ú¯ Ø¢Ø¦Ù„',
        'Milk' => 'Ø¯ÙˆØ¯Ú¾',
        'Spices' => 'Ù…ØµØ§Ù„Ø­Û',
        'Other Groceries' => 'Ø¯ÛŒÚ¯Ø± Ú©Ø±ÛŒØ§Ù†Û',
        _ => key,
      };
    }
    return key;
  }

  static String _safeTableCellText(String? value, {int maxLength = 120}) {
    final cleaned = AppFormatters.safeText(value);
    if (cleaned.trim().isEmpty || cleaned == '-') return '';
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength - 3)}...';
  }

  static String _plainAmount(double value) {
    if (value <= 0) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  // â”€â”€ Font cache â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Shared between ur and ar since both now use NotoNaskhArabic for PDFs.
  static pw.Font? _cachedRtlFont;
  static Uint8List? _cachedRtlFontBytes;

  static Future<Uint8List?> _getLocaleFontBytes(String locale) async {
    if (locale != 'ur' && locale != 'ar') return null;

    final asset = AppFonts.pdfFontAsset(locale);
    if (asset == null) return null;

    if (_cachedRtlFontBytes != null) {
      return _cachedRtlFontBytes;
    }

    final byteData = await rootBundle.load(asset);
    _cachedRtlFontBytes = byteData.buffer.asUint8List();
    return _cachedRtlFontBytes;
  }

  static Future<pw.Font?> _getLocaleFont(
    String locale, {
    Uint8List? rtlFontBytes,
  }) async {
    if (locale == 'ur' || locale == 'ar') {
      if (rtlFontBytes != null) {
        return pw.Font.ttf(rtlFontBytes.buffer.asByteData());
      }

      _cachedRtlFont ??= pw.Font.ttf(
        (await _getLocaleFontBytes(locale))!.buffer.asByteData(),
      );
      return _cachedRtlFont;
    }
    return null; // pdf package's built-in Latin font
  }

  static pw.TextDirection _dir(String locale) =>
      (locale == 'ur' || locale == 'ar')
      ? pw.TextDirection.rtl
      : pw.TextDirection.ltr;

  static ({pw.MemoryImage? image, String? svg}) _decodePdfLogo(
    String? logoBase64,
  ) {
    if (logoBase64 == null || logoBase64.trim().isEmpty) {
      return (image: null, svg: null);
    }

    final bytes = Base64ImageCodec.tryDecodeBytes(logoBase64);
    if (bytes == null) return (image: null, svg: null);

    final svg = Base64ImageCodec.tryDecodeSvgBytes(bytes);
    if (svg != null) return (image: null, svg: svg);

    return (image: pw.MemoryImage(bytes), svg: null);
  }

  static pw.Widget _brandIdentityPanel({
    required ReportBrandIdentity identity,
    required pw.Font? font,
    required pw.TextDirection dir,
    required bool alignEnd,
  }) {
    final decodedLogo = _decodePdfLogo(identity.logoBase64);
    final hasLogo = decodedLogo.svg != null || decodedLogo.image != null;
    final crossAxisAlignment = alignEnd
        ? pw.CrossAxisAlignment.end
        : pw.CrossAxisAlignment.start;
    final textAlign = alignEnd ? pw.TextAlign.right : pw.TextAlign.left;

    final logoWidget = hasLogo
        ? pw.Container(
            width: 34,
            height: 34,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: decodedLogo.svg != null
                ? pw.SvgImage(svg: decodedLogo.svg!, fit: pw.BoxFit.contain)
                : pw.Image(decodedLogo.image!, fit: pw.BoxFit.contain),
          )
        : null;

    return pw.Row(
      mainAxisAlignment: alignEnd
          ? pw.MainAxisAlignment.end
          : pw.MainAxisAlignment.start,
      children: [
        if (!alignEnd && logoWidget != null) logoWidget,
        if (!alignEnd && logoWidget != null) pw.SizedBox(width: 8),
        pw.Flexible(
          child: pw.Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              pw.Text(
                identity.name.trim().isEmpty
                    ? AppConstants.appName
                    : identity.name,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _kBrandDark,
                ),
                textDirection: dir,
                textAlign: textAlign,
              ),
              if (identity.phoneNumber.trim().isNotEmpty)
                pw.Text(
                  identity.phoneNumber,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 7.5,
                    color: PdfColors.grey700,
                  ),
                  textDirection: dir,
                  textAlign: textAlign,
                ),
            ],
          ),
        ),
        if (alignEnd && logoWidget != null) pw.SizedBox(width: 8),
        if (alignEnd && logoWidget != null) logoWidget,
      ],
    );
  }

  // â”€â”€ Shared page decorators â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Top brand banner shown on every page of every report.
  static pw.Widget _pageHeader(
    pw.Context ctx, {
    required String reportTitle,
    required pw.Font? font,
    required pw.TextDirection dir,
    String? dateRange,
    ReportBrandingContext? reportBranding,
    String? brandName,
    String? logoBase64,
  }) {
    final serviceCompany =
        reportBranding?.serviceCompany ??
        ReportBrandIdentity(
          name: (brandName?.trim().isNotEmpty ?? false)
              ? brandName!.trim()
              : AppConstants.appName,
          logoBase64: logoBase64 ?? '',
        );
    final clientCompany = reportBranding?.clientCompany;

    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(14),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                flex: 4,
                child: _brandIdentityPanel(
                  identity: serviceCompany,
                  font: font,
                  dir: dir,
                  alignEnd: false,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      reportTitle,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _kBrandDark,
                      ),
                      textDirection: dir,
                      textAlign: pw.TextAlign.center,
                    ),
                    if (dateRange != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        dateRange,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 7.5,
                          color: PdfColors.grey700,
                        ),
                        textDirection: dir,
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                flex: 4,
                child: clientCompany == null
                    ? pw.SizedBox()
                    : _brandIdentityPanel(
                        identity: clientCompany,
                        font: font,
                        dir: dir,
                        alignEnd: true,
                      ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  /// Bottom strip shown on every page: confidentiality note + page numbers.
  static pw.Widget _pageFooter(
    pw.Context ctx, {
    required pw.Font? font,
    required pw.TextDirection dir,
    ReportBrandingContext? reportBranding,
  }) {
    final serviceCompany = reportBranding?.serviceCompany;
    final clientCompany = reportBranding?.clientCompany;
    final leadText = serviceCompany == null
        ? '${AppConstants.appName} - Confidential'
        : '${serviceCompany.name.trim().isEmpty ? AppConstants.appName : serviceCompany.name}${serviceCompany.phoneNumber.trim().isEmpty ? '' : ' â€¢ ${serviceCompany.phoneNumber}'}';

    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              leadText,
              style: pw.TextStyle(
                font: font,
                fontSize: 7,
                color: PdfColors.grey600,
              ),
              textDirection: dir,
            ),
            if (clientCompany != null)
              pw.Expanded(
                child: pw.Center(
                  child: pw.Text(
                    clientCompany.name,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 7,
                      color: PdfColors.grey600,
                    ),
                    textDirection: dir,
                  ),
                ),
              )
            else
              pw.SizedBox(),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}'
              '  |  ${AppFormatters.dateTime(DateTime.now())}',
              style: pw.TextStyle(
                font: font,
                fontSize: 7,
                color: PdfColors.grey600,
              ),
              textDirection: dir,
            ),
          ],
        ),
      ],
    );
  }

  /// Coloured KPI summary box (earnings / expenses / net).
  static pw.Widget _kpiBox({
    required String earningsLabel,
    required String expensesLabel,
    required String netLabel,
    required double totalEarnings,
    required double totalExpenses,
    required pw.Font? font,
    required pw.TextDirection dir,
  }) {
    final net = totalEarnings - totalExpenses;
    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      color: PdfColors.grey700,
    );
    final valStyle = pw.TextStyle(
      font: font,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text(earningsLabel, style: subStyle, textDirection: dir),
              pw.Text(
                AppFormatters.currency(totalEarnings),
                style: valStyle.copyWith(color: _kGreen),
                textDirection: dir,
              ),
            ],
          ),
          pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
          pw.Column(
            children: [
              pw.Text(expensesLabel, style: subStyle, textDirection: dir),
              pw.Text(
                AppFormatters.currency(totalExpenses),
                style: valStyle.copyWith(color: _kRed),
                textDirection: dir,
              ),
            ],
          ),
          pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
          pw.Column(
            children: [
              pw.Text(netLabel, style: subStyle, textDirection: dir),
              pw.Text(
                AppFormatters.currency(net.abs()),
                style: valStyle.copyWith(color: net >= 0 ? _kGreen : _kRed),
                textDirection: dir,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Non-financial KPI box for count-based summaries.
  static pw.Widget _statsBox({
    required String firstLabel,
    required String secondLabel,
    required String thirdLabel,
    required String firstValue,
    required String secondValue,
    required String thirdValue,
    required pw.Font? font,
    required pw.TextDirection dir,
  }) {
    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      color: PdfColors.grey700,
    );
    final valStyle = pw.TextStyle(
      font: font,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      color: _kBrandBlue,
    );

    pw.Widget statCell(String label, String value) {
      return pw.Expanded(
        child: pw.Column(
          children: [
            pw.Text(label, style: subStyle, textDirection: dir),
            pw.SizedBox(height: 2),
            pw.Text(value, style: valStyle, textDirection: dir),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        children: [
          statCell(firstLabel, firstValue),
          pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
          statCell(secondLabel, secondValue),
          pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
          statCell(thirdLabel, thirdValue),
        ],
      ),
    );
  }

  // â”€â”€ Status helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Map<String, String> _statusLabels(String locale) => {
    'pending': locale == 'ur'
        ? 'Ø²ÛŒØ± ØºÙˆØ±'
        : locale == 'ar'
        ? 'Ù‚ÙŠØ¯ Ø§Ù„Ø§Ù†ØªØ¸Ø§Ø±'
        : 'Pending',
    'approved': locale == 'ur'
        ? 'Ù…Ù†Ø¸ÙˆØ±'
        : locale == 'ar'
        ? 'Ù…ÙˆØ§ÙÙ‚ Ø¹Ù„ÙŠÙ‡'
        : 'Approved',
    'rejected': locale == 'ur'
        ? 'Ù…Ø³ØªØ±Ø¯'
        : locale == 'ar'
        ? 'Ù…Ø±ÙÙˆØ¶'
        : 'Rejected',
  };

  static PdfColor _statusColour(String status) => switch (status) {
    'approved' => _kGreen,
    'rejected' => _kRed,
    _ => _kAmber,
  };

  // â”€â”€ Public API â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Generate a paginated jobs report PDF with branded header + footer.
  static Future<Uint8List> generateJobsReport({
    required List<JobModel> jobs,
    required String title,
    String locale = 'en',
    Uint8List? rtlFontBytes,
    String? technicianName,
    DateTime? fromDate,
    DateTime? toDate,
    ReportBrandingContext? reportBranding,
  }) async {
    final font = await _getLocaleFont(locale, rtlFontBytes: rtlFontBytes);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 10,
      color: PdfColors.grey700,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    final tableHeaders = locale == 'ur'
        ? [
            'Ø§Ù†ÙˆØ§Ø¦Ø³',
            'Ù¹ÛŒÚ©Ù†ÛŒØ´Ù†',
            'Ú©Ù„Ø§Ø¦Ù†Ù¹',
            'ØªØ§Ø±ÛŒØ®',
            'ÛŒÙˆÙ†Ù¹Ø³',
            'Ø§Ø®Ø±Ø§Ø¬Ø§Øª',
            'Ø­Ø§Ù„Øª',
          ]
        : locale == 'ar'
        ? [
            'ÙØ§ØªÙˆØ±Ø©',
            'ÙÙ†ÙŠ',
            'Ø¹Ù…ÙŠÙ„',
            'ØªØ§Ø±ÙŠØ®',
            'ÙˆØ­Ø¯Ø§Øª',
            'Ù…ØµØ§Ø±ÙŠÙ',
            'Ø­Ø§Ù„Ø©',
          ]
        : [
            'Invoice',
            'Technician',
            'Client',
            'Date',
            'Units',
            'Expenses',
            'Status',
          ];

    final statusMap = _statusLabels(locale);

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} - ${AppFormatters.date(toDate)}'
        : null;

    final totalExpenses = jobs.fold<double>(0, (s, j) => s + j.expenses);
    final totalExpensesLabel = locale == 'ur'
        ? 'Ú©Ù„ Ø§Ø®Ø±Ø§Ø¬Ø§Øª'
        : locale == 'ar'
        ? 'Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„Ù…ØµØ±ÙˆÙØ§Øª'
        : 'Total Expenses';
    final totalJobsLabel = locale == 'ur'
        ? 'Ú©Ù„ Ù…Ù„Ø§Ø²Ù…ØªÛŒÚº: ${jobs.length}'
        : locale == 'ar'
        ? 'Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„ÙˆØ¸Ø§Ø¦Ù: ${jobs.length}'
        : 'Total Jobs: ${jobs.length}';
    final totalUnits = jobs.fold<int>(0, (sum, job) => sum + job.totalUnits);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: dateRange,
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          // Technician / date meta
          if (technicianName != null)
            pw.Text(technicianName, style: subStyle, textDirection: dir),
          pw.SizedBox(height: 10),

          // KPI summary box
          _statsBox(
            firstLabel: locale == 'ur'
                ? 'Ú©Ù„ Ø¬Ø§Ø¨Ø²'
                : locale == 'ar'
                ? 'Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„ÙˆØ¸Ø§Ø¦Ù'
                : 'Total Jobs',
            secondLabel: locale == 'ur'
                ? 'Ú©Ù„ ÛŒÙˆÙ†Ù¹Ø³'
                : locale == 'ar'
                ? 'Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„ÙˆØ­Ø¯Ø§Øª'
                : 'Total Units',
            thirdLabel: totalExpensesLabel,
            firstValue: '${jobs.length}',
            secondValue: '$totalUnits',
            thirdValue: AppFormatters.currency(totalExpenses),
            font: font,
            dir: dir,
          ),
          pw.SizedBox(height: 12),

          // Jobs table
          pw.TableHelper.fromTextArray(
            context: context,
            headers: _shapeRowForPdf(locale, tableHeaders),
            data: _shapeTableForPdf(
              locale,
              jobs.map((j) {
                final statusText = statusMap[j.status.name] ?? j.status.name;
                return [
                  _safeTableCellText(j.invoiceNumber, maxLength: 40),
                  _safeTableCellText(j.techName, maxLength: 35),
                  _safeTableCellText(j.clientName, maxLength: 40),
                  AppFormatters.date(j.date),
                  '${j.totalUnits}',
                  AppFormatters.currency(j.expenses),
                  _shapeRtlForPdf(locale, statusText),
                ];
              }).toList(),
            ),
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            cellAlignments: {
              for (var i = 0; i < 7; i++) i: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 3,
            ),
          ),
          pw.SizedBox(height: 10),

          // Footer summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                totalJobsLabel,
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                locale == 'ur'
                    ? 'Ú©Ù„ Ø§Ø®Ø±Ø§Ø¬Ø§Øª: ${AppFormatters.currency(totalExpenses)}'
                    : locale == 'ar'
                    ? 'Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„Ù…ØµØ§Ø±ÙŠÙ: ${AppFormatters.currency(totalExpenses)}'
                    : 'Total Expenses: ${AppFormatters.currency(totalExpenses)}',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate a monthly earnings + expenses report PDF with KPI summary.
  static Future<Uint8List> generateExpensesReport({
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
    required String title,
    String locale = 'en',
    String? technicianName,
    DateTime? fromDate,
    DateTime? toDate,
    ReportBrandingContext? reportBranding,
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 10,
      color: PdfColors.grey700,
    );
    final sectionStyle = pw.TextStyle(
      font: font,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    // i18n labels
    final earningsLabel = locale == 'ur'
        ? 'Ø¢Ù…Ø¯Ù†ÛŒ (IN)'
        : locale == 'ar'
        ? 'Ø§Ù„Ø¥ÙŠØ±Ø§Ø¯Ø§Øª (Ø§Ù„Ø¯Ø®Ù„)'
        : 'Earnings (IN)';
    final expensesLabel = locale == 'ur'
        ? 'Ø§Ø®Ø±Ø§Ø¬Ø§Øª (OUT)'
        : locale == 'ar'
        ? 'Ø§Ù„Ù…ØµØ±ÙˆÙØ§Øª (Ø§Ù„Ø®Ø±ÙˆØ¬)'
        : 'Expenses (OUT)';
    final totalEarningsLabel = locale == 'ur'
        ? 'Ú©Ù„ Ø¢Ù…Ø¯Ù†ÛŒ'
        : locale == 'ar'
        ? 'Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„Ø¥ÙŠØ±Ø§Ø¯Ø§Øª'
        : 'Total Earnings';
    final totalExpensesLabel = locale == 'ur'
        ? 'Ú©Ù„ Ø§Ø®Ø±Ø§Ø¬Ø§Øª'
        : locale == 'ar'
        ? 'Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„Ù…ØµØ±ÙˆÙØ§Øª'
        : 'Total Expenses';
    final netLabel = locale == 'ur'
        ? 'Ø®Ø§Ù„Øµ Ù…Ù†Ø§ÙØ¹'
        : locale == 'ar'
        ? 'ØµØ§ÙÙŠ Ø§Ù„Ø±Ø¨Ø­'
        : 'Net Profit';
    final earningsHeaders = locale == 'ur'
        ? ['Ø²Ù…Ø±Û', 'Ø±Ù‚Ù…', 'ØªØ§Ø±ÛŒØ®', 'Ù†ÙˆÙ¹']
        : locale == 'ar'
        ? ['Ø§Ù„ÙØ¦Ø©', 'Ø§Ù„Ù…Ø¨Ù„Øº', 'Ø§Ù„ØªØ§Ø±ÙŠØ®', 'Ù…Ù„Ø§Ø­Ø¸Ø©']
        : ['Category', 'Amount (SAR)', 'Date', 'Note'];
    final expensesHeaders = locale == 'ur'
        ? ['Ù†ÙˆØ¹', 'Ø²Ù…Ø±Û', 'Ø±Ù‚Ù…', 'ØªØ§Ø±ÛŒØ®', 'Ù†ÙˆÙ¹']
        : locale == 'ar'
        ? [
            'Ø§Ù„Ù†ÙˆØ¹',
            'Ø§Ù„ÙØ¦Ø©',
            'Ø§Ù„Ù…Ø¨Ù„Øº',
            'Ø§Ù„ØªØ§Ø±ÙŠØ®',
            'Ù…Ù„Ø§Ø­Ø¸Ø©',
          ]
        : ['Type', 'Category', 'Amount (SAR)', 'Date', 'Note'];

    final totalEarningsAmt = earnings.fold<double>(0, (s, e) => s + e.amount);
    final totalExpensesAmt = expenses.fold<double>(0, (s, e) => s + e.amount);

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} - ${AppFormatters.date(toDate)}'
        : null;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: dateRange,
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          // Technician / date meta
          if (technicianName != null) ...[
            pw.Text(technicianName, style: subStyle, textDirection: dir),
            pw.SizedBox(height: 8),
          ],

          // KPI summary
          _kpiBox(
            earningsLabel: totalEarningsLabel,
            expensesLabel: totalExpensesLabel,
            netLabel: netLabel,
            totalEarnings: totalEarningsAmt,
            totalExpenses: totalExpensesAmt,
            font: font,
            dir: dir,
          ),
          pw.SizedBox(height: 16),

          // â”€â”€ Earnings section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (earnings.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: _kGreen, width: 3),
                ),
              ),
              child: pw.Text(
                earningsLabel,
                style: sectionStyle,
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(locale, earningsHeaders),
              data: _shapeTableForPdf(
                locale,
                earnings
                    .map(
                      (e) => [
                        _shapeRtlForPdf(
                          locale,
                          _translateCategoryForPdf(locale, e.category),
                        ),
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kGreen),
              cellAlignments: {
                for (var i = 0; i < 4; i++) i: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // â”€â”€ Expenses section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (expenses.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: _kRed, width: 3)),
              ),
              child: pw.Text(
                expensesLabel,
                style: sectionStyle,
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(locale, expensesHeaders),
              data: _shapeTableForPdf(
                locale,
                expenses
                    .map(
                      (e) => [
                        _shapeRtlForPdf(locale, e.expenseType),
                        _shapeRtlForPdf(
                          locale,
                          _translateCategoryForPdf(locale, e.category),
                        ),
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kRed),
              cellAlignments: {
                for (var i = 0; i < 5; i++) i: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate a professional single-job invoice PDF.
  ///
  /// Produces an A4 document with job details, unit breakdown, charges and
  /// a signature strip â€” suitable for handing to the client.
  static Future<Uint8List> generateJobInvoice({
    required JobModel job,
    String locale = 'en',
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';
    final align = isRtl
        ? pw.CrossAxisAlignment.end
        : pw.CrossAxisAlignment.start;

    final titleStyle = pw.TextStyle(
      font: font,
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );
    final sectionStyle = pw.TextStyle(
      font: font,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final labelStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      color: PdfColors.grey700,
    );
    final valueStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 9);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    // i18n field labels
    final invoiceLabel = locale == 'ur'
        ? 'Ø§Ù†ÙˆØ§Ø¦Ø³ Ù†Ù…Ø¨Ø±'
        : locale == 'ar'
        ? 'Ø±Ù‚Ù… Ø§Ù„ÙØ§ØªÙˆØ±Ø©'
        : 'Invoice No.';
    final dateLabel = locale == 'ur'
        ? 'ØªØ§Ø±ÛŒØ®'
        : locale == 'ar'
        ? 'Ø§Ù„ØªØ§Ø±ÙŠØ®'
        : 'Date';
    final clientLabel = locale == 'ur'
        ? 'Ú©Ù„Ø§Ø¦Ù†Ù¹'
        : locale == 'ar'
        ? 'Ø§Ù„Ø¹Ù…ÙŠÙ„'
        : 'Client';
    final contactLabel = locale == 'ur'
        ? 'Ø±Ø§Ø¨Ø·Û'
        : locale == 'ar'
        ? 'Ø§Ù„ØªÙˆØ§ØµÙ„'
        : 'Contact';
    final techLabel = locale == 'ur'
        ? 'Ù¹ÛŒÚ©Ù†ÛŒØ´Ù†'
        : locale == 'ar'
        ? 'Ø§Ù„ÙÙ†ÙŠ'
        : 'Technician';
    final statusLabel = locale == 'ur'
        ? 'Ø­Ø§Ù„Øª'
        : locale == 'ar'
        ? 'Ø§Ù„Ø­Ø§Ù„Ø©'
        : 'Status';
    final companyLabel = locale == 'ur'
        ? 'Ú©Ù…Ù¾Ù†ÛŒ'
        : locale == 'ar'
        ? 'Ø§Ù„Ø´Ø±ÙƒØ©'
        : 'Company';
    final unitsLabel = locale == 'ur'
        ? 'Ø§Û’ Ø³ÛŒ ÛŒÙˆÙ†Ù¹Ø³'
        : locale == 'ar'
        ? 'ÙˆØ­Ø¯Ø§Øª Ø§Ù„ØªÙƒÙŠÙŠÙ'
        : 'AC Units';
    final chargesLabel = locale == 'ur'
        ? 'Ø§Ø¶Ø§ÙÛŒ Ú†Ø§Ø±Ø¬Ø²'
        : locale == 'ar'
        ? 'Ø±Ø³ÙˆÙ… Ø¥Ø¶Ø§ÙÙŠØ©'
        : 'Additional Charges';
    final expensesLabel = locale == 'ur'
        ? 'Ø§Ø®Ø±Ø§Ø¬Ø§Øª'
        : locale == 'ar'
        ? 'Ø§Ù„Ù…ØµØ§Ø±ÙŠÙ'
        : 'Job Expenses';
    final totalLabel = locale == 'ur'
        ? 'Ú©Ù„'
        : locale == 'ar'
        ? 'Ø§Ù„Ø¥Ø¬Ù…Ø§Ù„ÙŠ'
        : 'Total';
    final sigLabel = locale == 'ur'
        ? 'Ø¯Ø³ØªØ®Ø·'
        : locale == 'ar'
        ? 'Ø§Ù„ØªÙˆÙ‚ÙŠØ¹'
        : 'Signature';
    final stampLabel = locale == 'ur'
        ? 'Ù…ÛØ±'
        : locale == 'ar'
        ? 'Ø§Ù„Ø®ØªÙ…'
        : 'Stamp';
    final unitTypeLabel = locale == 'ur'
        ? 'Ù‚Ø³Ù…'
        : locale == 'ar'
        ? 'Ø§Ù„Ù†ÙˆØ¹'
        : 'Type';
    final qtyLabel = locale == 'ur'
        ? 'ØªØ¹Ø¯Ø§Ø¯'
        : locale == 'ar'
        ? 'Ø§Ù„ÙƒÙ…ÙŠØ©'
        : 'Qty';
    final bracketLabel = locale == 'ur'
        ? 'Ø¨Ø±ÛŒÚ©Ù¹'
        : locale == 'ar'
        ? 'Ø§Ù„Ø­Ø§Ù…Ù„'
        : 'Bracket';
    final deliveryLabel = locale == 'ur'
        ? 'ÚˆÛŒÙ„ÛŒÙˆØ±ÛŒ'
        : locale == 'ar'
        ? 'Ø§Ù„ØªÙˆØµÙŠÙ„'
        : 'Delivery';
    final yesLabel = locale == 'ur'
        ? 'ÛØ§Úº'
        : locale == 'ar'
        ? 'Ù†Ø¹Ù…'
        : 'Yes';
    final noLabel = locale == 'ur'
        ? 'Ù†ÛÛŒÚº'
        : locale == 'ar'
        ? 'Ù„Ø§'
        : 'No';
    final invoiceTitle = locale == 'ur'
        ? 'Ø³Ø±ÙˆØ³ Ø§Ù†ÙˆØ§Ø¦Ø³'
        : locale == 'ar'
        ? 'ÙØ§ØªÙˆØ±Ø© Ø§Ù„Ø®Ø¯Ù…Ø©'
        : 'Service Invoice';

    final statusText =
        _statusLabels(locale)[job.status.name] ?? job.status.name;
    final statusColor = _statusColour(job.status.name);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: align,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: invoiceTitle,
          font: font,
          dir: dir,
          dateRange: AppFormatters.date(job.date),
        ),
        footer: (ctx) => _pageFooter(ctx, font: font, dir: dir),
        build: (context) => [
          // â”€â”€ Invoice title + status badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(invoiceTitle, style: titleStyle, textDirection: dir),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: statusColor,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  statusText,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textDirection: dir,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // â”€â”€ Invoice meta grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _metaField(
                        invoiceLabel,
                        job.invoiceNumber,
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                    pw.Expanded(
                      child: _metaField(
                        dateLabel,
                        AppFormatters.date(job.date),
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                    pw.Expanded(
                      child: _metaField(
                        statusLabel,
                        statusText,
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _metaField(
                        clientLabel,
                        job.clientName,
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                    pw.Expanded(
                      child: _metaField(
                        contactLabel,
                        job.clientContact.isEmpty ? '-' : job.clientContact,
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                    pw.Expanded(
                      child: _metaField(
                        techLabel,
                        job.techName,
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                  ],
                ),
                if (job.companyName.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  _metaField(
                    companyLabel,
                    job.companyName,
                    labelStyle,
                    valueStyle,
                    dir,
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // â”€â”€ AC Units section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _sectionBanner(unitsLabel, font, sectionStyle, _kBrandBlue),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: _shapeRowForPdf(locale, [unitTypeLabel, qtyLabel]),
            data: _shapeTableForPdf(
              locale,
              job.acUnits.map((u) => [u.type, '${u.quantity}']).toList(),
            ),
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Align(
            alignment: isRtl
                ? pw.Alignment.centerLeft
                : pw.Alignment.centerRight,
            child: pw.Text(
              '$totalLabel: ${job.totalUnits}',
              style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
              textDirection: dir,
            ),
          ),
          pw.SizedBox(height: 14),

          // â”€â”€ Additional charges section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (job.charges != null) ...[
            _sectionBanner(
              chargesLabel,
              font,
              sectionStyle,
              PdfColors.blueGrey700,
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: _shapeRowForPdf(locale, [
                locale == 'ur'
                    ? 'Ø¢Ø¦Ù¹Ù…'
                    : locale == 'ar'
                    ? 'Ø§Ù„Ø¨Ù†Ø¯'
                    : 'Item',
                locale == 'ur'
                    ? 'Ø´Ø§Ù…Ù„'
                    : locale == 'ar'
                    ? 'Ù…Ø¶Ù…Ù†'
                    : 'Included',
                locale == 'ur'
                    ? 'Ø±Ù‚Ù…'
                    : locale == 'ar'
                    ? 'Ø§Ù„Ù…Ø¨Ù„Øº'
                    : 'Amount (SAR)',
              ]),
              data: [
                [
                  bracketLabel,
                  ((job.charges!.bracketCount > 0) ||
                          job.charges!.acBracket ||
                          job.charges!.bracketAmount > 0)
                      ? yesLabel
                      : noLabel,
                  job.charges!.bracketCount > 0
                      ? '${job.charges!.bracketCount}'
                      : (job.charges!.acBracket &&
                                job.charges!.bracketAmount > 0
                            ? AppFormatters.currency(job.charges!.bracketAmount)
                            : '-'),
                ],
                [
                  '$deliveryLabel${job.charges!.deliveryNote.isNotEmpty ? " (${job.charges!.deliveryNote})" : ""}',
                  job.charges!.deliveryAmount > 0 ? yesLabel : noLabel,
                  job.charges!.deliveryAmount > 0
                      ? AppFormatters.currency(job.charges!.deliveryAmount)
                      : '-',
                ],
              ],
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: isRtl
                  ? pw.Alignment.centerLeft
                  : pw.Alignment.centerRight,
              child: pw.Text(
                '$totalLabel: ${AppFormatters.currency(job.totalCharges)}',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 14),
          ],

          // â”€â”€ Job expenses section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (job.expenses > 0) ...[
            _sectionBanner(expensesLabel, font, sectionStyle, _kRed),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  job.expenseNote.isNotEmpty ? job.expenseNote : '-',
                  style: cellStyle,
                  textDirection: dir,
                ),
                pw.Text(
                  AppFormatters.currency(job.expenses),
                  style: cellStyle.copyWith(
                    fontWeight: pw.FontWeight.bold,
                    color: _kRed,
                  ),
                  textDirection: dir,
                ),
              ],
            ),
            pw.SizedBox(height: 14),
          ],

          // â”€â”€ Admin note â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (job.adminNote.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: _kAmber, width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                '${locale == "ur"
                    ? "Ø§ÛŒÚˆÙ…Ù† Ù†ÙˆÙ¹"
                    : locale == "ar"
                    ? "Ù…Ù„Ø§Ø­Ø¸Ø© Ø§Ù„Ø¥Ø¯Ø§Ø±Ø©"
                    : "Admin Note"}: ${job.adminNote}',
                style: cellStyle.copyWith(color: PdfColors.orange900),
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 14),
          ],

          // â”€â”€ Signature strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _signatureBox(sigLabel, font, dir, width: 160),
              _signatureBox(stampLabel, font, dir, width: 100),
              _signatureBox(
                '${locale == "ur"
                    ? "Ú©Ù„Ø§Ø¦Ù†Ù¹"
                    : locale == "ar"
                    ? "Ø§Ù„Ø¹Ù…ÙŠÙ„"
                    : "Client"}  $sigLabel',
                font,
                dir,
                width: 160,
              ),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate today's invoices report grouped by company with totals.
  static Future<Uint8List> generateTodayCompanyInvoicesReport({
    required List<JobModel> jobs,
    String locale = 'en',
    String? reportTitle,
    String? periodLabel,
    String companyLogoBase64 = '',
    ReportBrandingContext? reportBranding,
  }) async {
    final fontBytes = await _getLocaleFontBytes(locale);
    return compute(
      _isolateBuildCompanyInvoicesPdf,
      _CompanyInvoicesParams(
        fontBytes: fontBytes,
        locale: locale,
        jobs: jobs,
        reportTitle: reportTitle,
        periodLabel: periodLabel,
        companyLogoBase64: companyLogoBase64,
        serviceCompanyName: reportBranding?.serviceCompany.name ?? '',
        serviceCompanyLogoBase64:
            reportBranding?.serviceCompany.logoBase64 ?? '',
        serviceCompanyPhoneNumber:
            reportBranding?.serviceCompany.phoneNumber ?? '',
        clientCompanyName: reportBranding?.clientCompany?.name,
        clientCompanyLogoBase64: reportBranding?.clientCompany?.logoBase64,
      ),
    );
  }

  /// Generate detailed jobs report with bracket/delivery breakdown.
  /// Bracket logic: Include company-provided AND self-provided (both tracked).
  /// Delivery logic: Include if paid to company; exclude if customer paid cash.
  static Future<Uint8List> generateJobsDetailsReport({
    required List<JobModel> jobs,
    required String title,
    String locale = 'en',
    Uint8List? rtlFontBytes,
    Map<String, List<String>> sharedInstallerNamesByGroup =
        const <String, List<String>>{},
    String? technicianName,
    DateTime? fromDate,
    DateTime? toDate,
    int maxPages = 2000,
    ReportBrandingContext? reportBranding,
  }) async {
    final font = await _getLocaleFont(locale, rtlFontBytes: rtlFontBytes);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final cellStyle = pw.TextStyle(font: font, fontSize: 6.6);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 7,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    final tableHeaders = locale == 'ur'
        ? [
            'ØªØ§Ø±ÛŒØ®',
            'Ø§Ù†ÙˆØ§Ø¦Ø³ Ù†Ù…Ø¨Ø±',
            'Ø±Ø§Ø¨Ø·Û',
            'Ø³Ù¾Ù„Ù¹',
            'ÙˆÙ†ÚˆÙˆ',
            'Ø§ÙŽÙ† Ø§Ù†Ø³Ù¹Ø§Ù„',
            'Ø¯ÙˆÙ„Ø§Ø¨',
            'Ø¨Ø±ÛŒÚ©Ù¹',
            'ÚˆÛŒÙ„ÛŒÙˆØ±ÛŒ',
            'Ù¹ÛŒÚ©Ù†ÛŒØ´Ù†',
            'ØªÙØµÛŒÙ„',
          ]
        : locale == 'ar'
        ? [
            'Ø§Ù„ØªØ§Ø±ÙŠØ®',
            'Ø±Ù‚Ù… Ø§Ù„ÙØ§ØªÙˆØ±Ø©',
            'Ø§Ù„Ø§ØªØµØ§Ù„',
            'Ø³Ø¨Ù„ÙŠØª',
            'Ø´Ø¨Ø§Ùƒ',
            'ÙÙƒ ØªØ±ÙƒÙŠØ¨',
            'Ø¯ÙˆÙ„Ø§Ø¨',
            'Ø§Ù„Ø­Ø§Ù…Ù„',
            'Ø§Ù„ØªÙˆØµÙŠÙ„',
            'Ø§Ù„ÙÙ†ÙŠ',
            'Ø§Ù„ÙˆØµÙ',
          ]
        : [
            'Date',
            'Invoice Number',
            'Contact',
            'Split',
            'Window',
            'Uninstallation Total',
            'Free Standing',
            'Bracket',
            'Delivery',
            'Tech Name',
            'Description',
          ];

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} - ${AppFormatters.date(toDate)}'
        : null;
    final totalUnits = jobs.fold<int>(
      0,
      (s, j) =>
          s +
          _jobReportSplitQty(j) +
          _jobReportWindowQty(j) +
          _jobReportFreestandingQty(j) +
          _jobReportUninstallLegacyQty(j) +
          _jobReportUninstallSplitQty(j) +
          _jobReportUninstallWindowQty(j) +
          _jobReportUninstallFreestandingQty(j),
    );
    final totalSplitUnits = jobs.fold<int>(
      0,
      (s, j) => s + _jobReportSplitQty(j),
    );
    final totalWindowUnits = jobs.fold<int>(
      0,
      (s, j) => s + _jobReportWindowQty(j),
    );
    final totalFreestandingUnits = jobs.fold<int>(
      0,
      (s, j) => s + _jobReportFreestandingQty(j),
    );
    final totalUninstallations = jobs.fold<int>(
      0,
      (s, j) =>
          s +
          _jobReportUninstallLegacyQty(j) +
          _jobReportUninstallSplitQty(j) +
          _jobReportUninstallWindowQty(j) +
          _jobReportUninstallFreestandingQty(j),
    );
    final totalInstalledBrackets = jobs.fold<int>(
      0,
      (s, j) => s + _jobReportBracketCount(j),
    );
    final totalDeliveryCharges = jobs.fold<double>(
      0,
      (s, j) => s + _jobReportDeliveryAmount(j),
    );
    final sharedJobs = jobs.where((j) => j.isSharedInstall).toList();
    final soloJobs = jobs.where((j) => !j.isSharedInstall).toList();
    final sharedJobsCount = sharedJobs.length;
    final soloJobsCount = soloJobs.length;
    final sharedUnitsTotal = sharedJobs.fold<int>(
      0,
      (sum, j) => sum + j.sharedInstallUnitsTotal,
    );
    final soloUnitsTotal = soloJobs.fold<int>(
      0,
      (sum, j) => sum + j.totalUnits,
    );

    final sharedByTechnician = <String, ({int jobs, int units})>{};
    for (final job in sharedJobs) {
      final key = job.techName.trim().isEmpty ? '-' : job.techName.trim();
      final current = sharedByTechnician[key] ?? (jobs: 0, units: 0);
      sharedByTechnician[key] = (
        jobs: current.jobs + 1,
        units: current.units + job.sharedInstallUnitsTotal,
      );
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        maxPages: maxPages,
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(12, 12, 12, 12),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: dateRange,
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          if (technicianName != null) ...[
            pw.Text(technicianName, style: cellStyle, textDirection: dir),
            pw.SizedBox(height: 4),
          ],
          pw.TableHelper.fromTextArray(
            context: context,
            headers: _shapeRowForPdf(locale, tableHeaders),
            data: _shapeTableForPdf(
              locale,
              jobs.map((j) {
                final splitQty = _jobReportSplitQty(j);
                final windowQty = _jobReportWindowQty(j);
                final uninstallQty = _jobReportUninstallLegacyQty(j);
                final uninstallSplitQty = _jobReportUninstallSplitQty(j);
                final uninstallWindowQty = _jobReportUninstallWindowQty(j);
                final uninstallStandingQty = _jobReportUninstallFreestandingQty(
                  j,
                );
                final dolabQty = _jobReportFreestandingQty(j);
                final uninstallDetail = () {
                  final splitPart = uninstallSplitQty > 0
                      ? 'S:$uninstallSplitQty'
                      : '';
                  final windowPart = uninstallWindowQty > 0
                      ? 'W:$uninstallWindowQty'
                      : '';
                  final standingPart = uninstallStandingQty > 0
                      ? 'F:$uninstallStandingQty'
                      : '';
                  final parts = [
                    splitPart,
                    windowPart,
                    standingPart,
                  ].where((p) => p.isNotEmpty).toList();
                  if (parts.isNotEmpty) return parts.join('|');
                  return '';
                }();
                final uninstallTotal =
                    uninstallQty +
                    uninstallSplitQty +
                    uninstallWindowQty +
                    uninstallStandingQty;
                final bracketQty = _jobReportBracketCount(j);
                final bracketText = bracketQty > 0 ? '$bracketQty' : '';
                final deliveryAmount = _jobReportDeliveryAmount(j);
                final deliveryText = deliveryAmount > 0
                    ? _plainAmount(deliveryAmount)
                    : '';
                final baseDescription = j.expenseNote.isNotEmpty
                    ? AppFormatters.safeText(j.expenseNote)
                    : (j.charges != null
                          ? AppFormatters.safeText(j.charges!.deliveryNote)
                          : '');
                final sharedInstallDescription = _sharedInstallerDescription(
                  locale,
                  j,
                  sharedInstallerNamesByGroup,
                );
                final description =
                    [baseDescription, sharedInstallDescription, uninstallDetail]
                        .where((p) => p.isNotEmpty)
                        .join(
                          [
                                    baseDescription,
                                    sharedInstallDescription,
                                    uninstallDetail,
                                  ].where((p) => p.isNotEmpty).length >
                                  1
                              ? ' | '
                              : '',
                        );
                return [
                  AppFormatters.date(j.date),
                  _safeTableCellText(j.invoiceNumber, maxLength: 24),
                  j.clientContact.isEmpty
                      ? ''
                      : _safeTableCellText(j.clientContact, maxLength: 20),
                  splitQty > 0 ? '$splitQty' : '',
                  windowQty > 0 ? '$windowQty' : '',
                  uninstallTotal > 0 ? '$uninstallTotal' : '',
                  dolabQty > 0 ? '$dolabQty' : '',
                  bracketText,
                  deliveryText,
                  _safeTableCellText(j.techName, maxLength: 24),
                  _safeTableCellText(description, maxLength: 70),
                ];
              }).toList(),
            ),
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.0),
              1: const pw.FlexColumnWidth(1.0),
              2: const pw.FlexColumnWidth(1.0),
              3: const pw.FlexColumnWidth(0.55),
              4: const pw.FlexColumnWidth(0.55),
              5: const pw.FlexColumnWidth(0.75),
              6: const pw.FlexColumnWidth(0.65),
              7: const pw.FlexColumnWidth(0.75),
              8: const pw.FlexColumnWidth(0.75),
              9: const pw.FlexColumnWidth(1.0),
              10: const pw.FlexColumnWidth(2.0),
            },
            cellAlignments: {
              for (var i = 0; i < 11; i++) i: pw.Alignment.center,
              10: pw.Alignment.centerLeft,
              9: pw.Alignment.centerLeft,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 1.5,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: pw.WrapAlignment.spaceBetween,
            children: [
              pw.Text(
                '${locale == "ur"
                    ? "Ú©Ù„"
                    : locale == "ar"
                    ? "Ø§Ù„Ø¥Ø¬Ù…Ø§Ù„ÙŠ"
                    : "Total"}: ${jobs.length} ${locale == "ur"
                    ? "Ù…Ù„Ø§Ø²Ù…Øª"
                    : locale == "ar"
                    ? "ÙˆØ¸Ø§Ø¦Ù"
                    : "jobs"}',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "Ú©Ù„ ÛŒÙˆÙ†Ù¹Ø³"
                    : locale == "ar"
                    ? "Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„ÙˆØ­Ø¯Ø§Øª"
                    : "Total Units"}: $totalUnits',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "Ø³Ù¾Ù„Ù¹ ÛŒÙˆÙ†Ù¹Ø³"
                    : locale == "ar"
                    ? "ÙˆØ­Ø¯Ø§Øª Ø³Ø¨Ù„ÙŠØª"
                    : "Split Units"}: $totalSplitUnits',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "ÙˆÙ†ÚˆÙˆ ÛŒÙˆÙ†Ù¹Ø³"
                    : locale == "ar"
                    ? "ÙˆØ­Ø¯Ø§Øª Ø§Ù„Ø´Ø¨Ø§Ùƒ"
                    : "Window Units"}: $totalWindowUnits',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "Ø¯ÙˆÙ„Ø§Ø¨ ÛŒÙˆÙ†Ù¹Ø³"
                    : locale == "ar"
                    ? "ÙˆØ­Ø¯Ø§Øª Ø§Ù„Ø¯ÙˆÙ„Ø§Ø¨"
                    : "Free Standing Units"}: $totalFreestandingUnits',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "Ú©Ù„ Ø§ÙŽÙ† Ø§Ù†Ø³Ù¹Ø§Ù„"
                    : locale == "ar"
                    ? "Ø¥Ø¬Ù…Ø§Ù„ÙŠ ÙÙƒ Ø§Ù„ØªØ±ÙƒÙŠØ¨"
                    : "Total Uninstallations"}: $totalUninstallations',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "Ø§Ù†Ø³Ù¹Ø§Ù„ Ø¨Ø±ÛŒÚ©Ù¹Ø³"
                    : locale == "ar"
                    ? "Ø§Ù„Ø­ÙˆØ§Ù…Ù„ Ø§Ù„Ù…Ø±ÙƒØ¨Ø©"
                    : "Brackets Installed"}: $totalInstalledBrackets',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "ÚˆÛŒÙ„ÛŒÙˆØ±ÛŒ Ú†Ø§Ø±Ø¬Ø²"
                    : locale == "ar"
                    ? "Ø±Ø³ÙˆÙ… Ø§Ù„ØªÙˆØµÙŠÙ„"
                    : "Delivery Charges"}: ${_plainAmount(totalDeliveryCharges)}',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "Ø³ÙˆÙ„Ùˆ Ø§Ù†Ø³Ù¹Ø§Ù„"
                    : locale == "ar"
                    ? "ØªØ±ÙƒÙŠØ¨Ø§Øª ÙØ±Ø¯ÙŠØ©"
                    : "Solo Installs"}: $soloJobsCount',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "Ø´ÛŒØ¦Ø±Úˆ Ø§Ù†Ø³Ù¹Ø§Ù„"
                    : locale == "ar"
                    ? "ØªØ±ÙƒÙŠØ¨Ø§Øª Ù…Ø´ØªØ±ÙƒØ©"
                    : "Shared Installs"}: $sharedJobsCount',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "Ø´ÛŒØ¦Ø±Úˆ ÛŒÙˆÙ†Ù¹Ø³"
                    : locale == "ar"
                    ? "ÙˆØ­Ø¯Ø§Øª Ù…Ø´ØªØ±ÙƒØ©"
                    : "Shared Units"}: $sharedUnitsTotal',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "Ø³ÙˆÙ„Ùˆ ÛŒÙˆÙ†Ù¹Ø³"
                    : locale == "ar"
                    ? "ÙˆØ­Ø¯Ø§Øª ÙØ±Ø¯ÙŠØ©"
                    : "Solo Units"}: $soloUnitsTotal',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          if (sharedByTechnician.isNotEmpty) ...[
            _sectionBanner(
              locale == 'ur'
                  ? 'Ø´ÛŒØ¦Ø±Úˆ Ø§Ù†Ø³Ù¹Ø§Ù„ Ú©Ø§ ØªÙØµÛŒÙ„'
                  : locale == 'ar'
                  ? 'ØªÙØ§ØµÙŠÙ„ Ø§Ù„ØªØ±ÙƒÙŠØ¨Ø§Øª Ø§Ù„Ù…Ø´ØªØ±ÙƒØ©'
                  : 'Shared Installation Breakdown',
              font,
              pw.TextStyle(
                font: font,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              _kBrandBlue,
            ),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(
                locale,
                locale == 'ur'
                    ? [
                        'Ù¹ÛŒÚ©Ù†ÛŒØ´Ù†',
                        'Ø´ÛŒØ¦Ø±Úˆ Ø¬Ø§Ø¨Ø²',
                        'Ø´ÛŒØ¦Ø±Úˆ ÛŒÙˆÙ†Ù¹Ø³',
                      ]
                    : locale == 'ar'
                    ? [
                        'Ø§Ù„ÙÙ†ÙŠ',
                        'Ø§Ù„Ø£Ø¹Ù…Ø§Ù„ Ø§Ù„Ù…Ø´ØªØ±ÙƒØ©',
                        'Ø§Ù„ÙˆØ­Ø¯Ø§Øª Ø§Ù„Ù…Ø´ØªØ±ÙƒØ©',
                      ]
                    : ['Technician', 'Shared Jobs', 'Shared Units'],
              ),
              data: _shapeTableForPdf(
                locale,
                sharedByTechnician.entries
                    .map(
                      (entry) => [
                        _safeTableCellText(entry.key, maxLength: 28),
                        '${entry.value.jobs}',
                        '${entry.value.units}',
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.8),
                1: const pw.FlexColumnWidth(1.0),
                2: const pw.FlexColumnWidth(1.0),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 2,
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          _sectionBanner(
            locale == 'ur'
                ? 'Ø§ÙŽÙ† Ø§Ù†Ø³Ù¹Ø§Ù„ Ú©Ø§ ØªÙØµÛŒÙ„'
                : locale == 'ar'
                ? 'ØªÙØ§ØµÙŠÙ„ ÙÙƒ Ø§Ù„ØªØ±ÙƒÙŠØ¨'
                : 'Uninstallation Breakdown',
            font,
            pw.TextStyle(
              font: font,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            _kBrandBlue,
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                children: [
                  pw.Text(
                    locale == 'ur'
                        ? 'Ø³Ù¾Ù„Ù¹ Ø§ÙŽÙ† Ø§Ù†Ø³Ù¹Ø§Ù„'
                        : locale == 'ar'
                        ? 'ÙÙƒ ØªØ±ÙƒÙŠØ¨ Ø³Ø¨Ù„ÙŠØª'
                        : 'Split Uninstallations',
                    style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                    textDirection: dir,
                  ),
                  pw.Text(
                    '${jobs.fold<int>(0, (s, j) => s + j.acUnits.where((u) => u.type == AppConstants.unitTypeUninstallSplit).fold<int>(0, (x, u) => x + u.quantity))}',
                    style: cellStyle.copyWith(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: _kBrandBlue,
                    ),
                    textDirection: dir,
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    locale == 'ur'
                        ? 'Ø¯ÙˆÙ„Ø§Ø¨ Ø§ÙŽÙ† Ø§Ù†Ø³Ù¹Ø§Ù„'
                        : locale == 'ar'
                        ? 'ÙÙƒ ØªØ±ÙƒÙŠØ¨ Ø¯ÙˆÙ„Ø§Ø¨'
                        : 'Free Standing Uninstallations',
                    style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                    textDirection: dir,
                  ),
                  pw.Text(
                    '${jobs.fold<int>(0, (s, j) => s + j.acUnits.where((u) => u.type == AppConstants.unitTypeUninstallFreestanding).fold<int>(0, (x, u) => x + u.quantity))}',
                    style: cellStyle.copyWith(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: _kBrandBlue,
                    ),
                    textDirection: dir,
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    locale == 'ur'
                        ? 'ÙˆÙ†ÚˆÙˆ Ø§ÙŽÙ† Ø§Ù†Ø³Ù¹Ø§Ù„'
                        : locale == 'ar'
                        ? 'ÙÙƒ ØªØ±ÙƒÙŠØ¨ Ø§Ù„Ù†Ø§ÙØ°Ø©'
                        : 'Window Uninstallations',
                    style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                    textDirection: dir,
                  ),
                  pw.Text(
                    '${jobs.fold<int>(0, (s, j) => s + j.acUnits.where((u) => u.type == AppConstants.unitTypeUninstallWindow).fold<int>(0, (x, u) => x + u.quantity))}',
                    style: cellStyle.copyWith(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: _kBrandBlue,
                    ),
                    textDirection: dir,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate a one-page daily IN/OUT summary report for technician operations.
  static Future<Uint8List> generateTodayInOutReport({
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
    String locale = 'en',
    String? technicianName,
    String? reportTitle,
    DateTime? reportDate,
    String? periodLabel,
    bool monthlyMode = false,
    ReportBrandingContext? reportBranding,
  }) async {
    final fontBytes = await _getLocaleFontBytes(locale);
    return compute(
      _isolateBuildInOutReportPdf,
      _InOutReportParams(
        fontBytes: fontBytes,
        locale: locale,
        earnings: earnings,
        expenses: expenses,
        technicianName: technicianName,
        reportTitle: reportTitle,
        reportDate: reportDate,
        periodLabel: periodLabel,
        monthlyMode: monthlyMode,
        serviceCompanyName: reportBranding?.serviceCompany.name ?? '',
        serviceCompanyLogoBase64:
            reportBranding?.serviceCompany.logoBase64 ?? '',
        serviceCompanyPhoneNumber:
            reportBranding?.serviceCompany.phoneNumber ?? '',
        clientCompanyName: reportBranding?.clientCompany?.name,
        clientCompanyLogoBase64: reportBranding?.clientCompany?.logoBase64,
      ),
    );
  }

  /// Generate earnings report with today + month summaries by category.
  static Future<Uint8List> generateEarningsReport({
    required List<EarningModel> earnings,
    required String title,
    String locale = 'en',
    String? technicianName,
    DateTime? fromDate,
    DateTime? toDate,
    ReportBrandingContext? reportBranding,
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      color: PdfColors.grey700,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final summaryStyle = cellStyle.copyWith(fontWeight: pw.FontWeight.bold);

    final earningsHeaders = locale == 'ur'
        ? ['Ø²Ù…Ø±Û', 'Ø±Ù‚Ù…', 'ØªØ§Ø±ÛŒØ®', 'Ù†ÙˆÙ¹']
        : locale == 'ar'
        ? ['Ø§Ù„ÙØ¦Ø©', 'Ø§Ù„Ù…Ø¨Ù„Øº', 'Ø§Ù„ØªØ§Ø±ÙŠØ®', 'Ù…Ù„Ø§Ø­Ø¸Ø©']
        : ['Category', 'Amount (SAR)', 'Date', 'Note'];

    final totalEarningsAmt = earnings.fold<double>(0, (s, e) => s + e.amount);
    final today = DateTime.now();
    final todaysEarnings = earnings
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == today.year &&
              e.date!.month == today.month &&
              e.date!.day == today.day,
        )
        .toList();
    final todaysTotal = todaysEarnings.fold<double>(0, (s, e) => s + e.amount);

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} - ${AppFormatters.date(toDate)}'
        : null;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: dateRange,
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          if (technicianName != null) ...[
            pw.Text(technicianName, style: subStyle, textDirection: dir),
            pw.SizedBox(height: 8),
          ],
          // KPI summary
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.grey50,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text(
                      locale == 'ur'
                          ? 'Ø¢Ø¬ Ú©ÛŒ Ú©Ù…Ø§Ø¦ÛŒ'
                          : locale == 'ar'
                          ? 'Ø£Ø±Ø¨Ø§Ø­ Ø§Ù„ÙŠÙˆÙ…'
                          : 'Today Earned',
                      style: subStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      AppFormatters.currency(todaysTotal),
                      style: summaryStyle.copyWith(color: _kGreen),
                      textDirection: dir,
                    ),
                  ],
                ),
                pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
                pw.Column(
                  children: [
                    pw.Text(
                      locale == 'ur'
                          ? 'Ù…Ø§Û Ú©ÛŒ Ú©Ù…Ø§Ø¦ÛŒ'
                          : locale == 'ar'
                          ? 'Ø£Ø±Ø¨Ø§Ø­ Ø§Ù„Ø´Ù‡Ø±'
                          : 'Month Earned',
                      style: subStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      AppFormatters.currency(totalEarningsAmt),
                      style: summaryStyle.copyWith(color: _kGreen),
                      textDirection: dir,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          // Earnings table
          if (earnings.isNotEmpty)
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(locale, earningsHeaders),
              data: _shapeTableForPdf(
                locale,
                earnings
                    .map(
                      (e) => [
                        e.category,
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kGreen),
              cellAlignments: {
                for (var i = 0; i < 4; i++) i: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            )
          else
            pw.Text(
              locale == 'ur'
                  ? 'Ú©ÙˆØ¦ÛŒ Ú©Ù…Ø§Ø¦ÛŒ Ù†ÛÛŒÚº'
                  : locale == 'ar'
                  ? 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø£Ø±Ø¨Ø§Ø­'
                  : 'No earnings',
              style: cellStyle,
              textDirection: dir,
            ),
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate detailed expenses report split by work and home categories.
  static Future<Uint8List> generateExpensesDetailedReport({
    required List<ExpenseModel> expenses,
    required String title,
    String locale = 'en',
    String? technicianName,
    DateTime? fromDate,
    DateTime? toDate,
    ReportBrandingContext? reportBranding,
  }) async {
    const workExpenseType = 'work';
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final sectionStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    );
    final summaryStyle = cellStyle.copyWith(fontWeight: pw.FontWeight.bold);

    final workHeaders = locale == 'ur'
        ? ['Ø²Ù…Ø±Û', 'Ø±Ù‚Ù…', 'ØªØ§Ø±ÛŒØ®', 'Ù†ÙˆÙ¹']
        : locale == 'ar'
        ? ['Ø§Ù„ÙØ¦Ø©', 'Ø§Ù„Ù…Ø¨Ù„Øº', 'Ø§Ù„ØªØ§Ø±ÙŠØ®', 'Ù…Ù„Ø§Ø­Ø¸Ø©']
        : ['Category', 'Amount (SAR)', 'Date', 'Note'];

    final homeHeaders = locale == 'ur'
        ? ['Ø³Ø§Ù…Ø§Ù†', 'Ø±Ù‚Ù…', 'ØªØ§Ø±ÛŒØ®', 'Ù†ÙˆÙ¹']
        : locale == 'ar'
        ? ['Ø§Ù„Ø¨Ù†Ø¯', 'Ø§Ù„Ù…Ø¨Ù„Øº', 'Ø§Ù„ØªØ§Ø±ÙŠØ®', 'Ù…Ù„Ø§Ø­Ø¸Ø©']
        : ['Item', 'Amount (SAR)', 'Date', 'Note'];

    final workExpenses = expenses
        .where((e) => e.expenseType == workExpenseType)
        .toList();
    final homeExpenses = expenses
        .where((e) => e.expenseType != workExpenseType)
        .toList();

    final today = DateTime.now();
    final todaysWork = workExpenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == today.year &&
              e.date!.month == today.month &&
              e.date!.day == today.day,
        )
        .toList();
    final todaysHome = homeExpenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == today.year &&
              e.date!.month == today.month &&
              e.date!.day == today.day,
        )
        .toList();

    final todaysWorkTotal = todaysWork.fold<double>(0, (s, e) => s + e.amount);
    final todaysHomeTotal = todaysHome.fold<double>(0, (s, e) => s + e.amount);
    final monthWorkTotal = workExpenses.fold<double>(0, (s, e) => s + e.amount);
    final monthHomeTotal = homeExpenses.fold<double>(0, (s, e) => s + e.amount);

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} - ${AppFormatters.date(toDate)}'
        : null;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: dateRange,
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          if (technicianName != null) ...[
            pw.Text(technicianName, style: cellStyle, textDirection: dir),
            pw.SizedBox(height: 8),
          ],
          // Summary KPI box
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Today summary
                pw.Text(
                  locale == 'ur'
                      ? 'Ø¢Ø¬ Ú©Û’ Ø§Ø®Ø±Ø§Ø¬Ø§Øª'
                      : locale == 'ar'
                      ? 'Ù†ÙÙ‚Ø§Øª Ø§Ù„ÙŠÙˆÙ…'
                      : 'Today Expenses',
                  style: sectionStyle,
                  textDirection: dir,
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${locale == "ur"
                          ? "Ú©Ø§Ù…"
                          : locale == "ar"
                          ? "Ø¹Ù…Ù„"
                          : "Work"}: ${AppFormatters.currency(todaysWorkTotal)}',
                      style: cellStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      '${locale == "ur"
                          ? "Ú¯Ú¾Ø±"
                          : locale == "ar"
                          ? "Ù…Ù†Ø²Ù„"
                          : "Home"}: ${AppFormatters.currency(todaysHomeTotal)}',
                      style: cellStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      AppFormatters.currency(todaysWorkTotal + todaysHomeTotal),
                      style: summaryStyle.copyWith(color: _kRed),
                      textDirection: dir,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                // Month summary
                pw.Text(
                  locale == 'ur'
                      ? 'Ù…Ø§Û Ú©Û’ Ø§Ø®Ø±Ø§Ø¬Ø§Øª'
                      : locale == 'ar'
                      ? 'Ù†ÙÙ‚Ø§Øª Ø§Ù„Ø´Ù‡Ø±'
                      : 'Month Expenses',
                  style: sectionStyle,
                  textDirection: dir,
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${locale == "ur"
                          ? "Ú©Ø§Ù…"
                          : locale == "ar"
                          ? "Ø¹Ù…Ù„"
                          : "Work"}: ${AppFormatters.currency(monthWorkTotal)}',
                      style: cellStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      '${locale == "ur"
                          ? "Ú¯Ú¾Ø±"
                          : locale == "ar"
                          ? "Ù…Ù†Ø²Ù„"
                          : "Home"}: ${AppFormatters.currency(monthHomeTotal)}',
                      style: cellStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      AppFormatters.currency(monthWorkTotal + monthHomeTotal),
                      style: summaryStyle.copyWith(color: _kRed),
                      textDirection: dir,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          // Work expenses section
          if (workExpenses.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: _kRed, width: 3)),
              ),
              child: pw.Text(
                locale == 'ur'
                    ? 'Ú©Ø§Ù… Ú©Û’ Ø§Ø®Ø±Ø§Ø¬Ø§Øª'
                    : locale == 'ar'
                    ? 'Ù†ÙÙ‚Ø§Øª Ø§Ù„Ø¹Ù…Ù„'
                    : 'Work Expenses',
                style: sectionStyle,
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(locale, workHeaders),
              data: _shapeTableForPdf(
                locale,
                workExpenses
                    .map(
                      (e) => [
                        e.category,
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kRed),
              cellAlignments: {
                for (var i = 0; i < 4; i++) i: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
            pw.SizedBox(height: 12),
          ],
          // Home expenses section
          if (homeExpenses.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.deepOrange, width: 3),
                ),
              ),
              child: pw.Text(
                locale == 'ur'
                    ? 'Ú¯Ú¾Ø± Ú©Û’ Ø§Ø®Ø±Ø§Ø¬Ø§Øª'
                    : locale == 'ar'
                    ? 'Ù†ÙÙ‚Ø§Øª Ø§Ù„Ù…Ù†Ø²Ù„'
                    : 'Home Expenses',
                style: sectionStyle,
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(locale, homeHeaders),
              data: _shapeTableForPdf(
                locale,
                homeExpenses
                    .map(
                      (e) => [
                        e.category,
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.deepOrange,
              ),
              cellAlignments: {
                for (var i = 0; i < 4; i++) i: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  // â”€â”€ Helper widget builders â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static pw.Widget _metaField(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
    pw.TextDirection dir,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: labelStyle, textDirection: dir),
        pw.Text(value, style: valueStyle, textDirection: dir),
      ],
    );
  }

  static pw.Widget _sectionBanner(
    String label,
    pw.Font? font,
    pw.TextStyle style,
    PdfColor color,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(label, style: style),
    );
  }

  static pw.Widget _signatureBox(
    String label,
    pw.Font? font,
    pw.TextDirection dir, {
    double width = 140,
  }) {
    return pw.Container(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            height: 40,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
            textDirection: dir,
          ),
        ],
      ),
    );
  }

  // â”€â”€ Output helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Share or print the generated PDF bytes via the system share sheet.
  static Future<void> sharePdfBytes(Uint8List bytes, String fileName) async {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// Show an interactive print/share preview for a jobs report.
  /// For large reports (>20 jobs), PDF generation happens in an isolate to prevent UI freeze.
  static Future<void> previewPdf(
    BuildContext context,
    List<JobModel> jobs,
    String locale,
    ReportBrandingContext? reportBranding,
  ) async {
    if (!context.mounted) return;

    final reportTitle = locale == 'ur'
        ? 'Ù…Ù„Ø§Ø²Ù…ØªÙˆÚº Ú©ÛŒ Ø±Ù¾ÙˆØ±Ù¹'
        : locale == 'ar'
        ? 'ØªÙ‚Ø±ÙŠØ± Ø§Ù„ÙˆØ¸Ø§Ø¦Ù'
        : 'Jobs Report';

    Uint8List bytes;
    final rtlFontBytes = await _getLocaleFontBytes(locale);

    try {
      if (jobs.length > 20) {
        // Use isolate for large reports to avoid UI freeze
        bytes = await _generatePdfInIsolate(
          jobs: jobs,
          title: reportTitle,
          locale: locale,
          rtlFontBytes: rtlFontBytes,
          useDetails: true,
          maxPages: 2000,
          reportBranding: reportBranding,
        );
      } else {
        // Small reports can be generated on main thread
        bytes = await generateJobsDetailsReport(
          jobs: jobs,
          maxPages: 2000,
          title: reportTitle,
          locale: locale,
          rtlFontBytes: rtlFontBytes,
          reportBranding: reportBranding,
        );
      }
    } catch (_) {
      if (jobs.length > 20) {
        // Fallback to simpler report in isolate
        bytes = await _generatePdfInIsolate(
          jobs: jobs,
          title: reportTitle,
          locale: locale,
          rtlFontBytes: rtlFontBytes,
          useDetails: false,
          reportBranding: reportBranding,
        );
      } else {
        // Fallback for small reports
        bytes = await generateJobsReport(
          jobs: jobs,
          title: reportTitle,
          locale: locale,
          rtlFontBytes: rtlFontBytes,
          reportBranding: reportBranding,
        );
      }
    }

    if (context.mounted) {
      await Printing.layoutPdf(onLayout: (_) => bytes);
    }
  }

  /// Generate PDF in isolate for large reports.
  static Future<Uint8List> _generatePdfInIsolate({
    required List<JobModel> jobs,
    required String title,
    required String locale,
    Uint8List? rtlFontBytes,
    required bool useDetails,
    Map<String, List<String>> sharedInstallerNamesByGroup =
        const <String, List<String>>{},
    int maxPages = 2000,
    ReportBrandingContext? reportBranding,
  }) async {
    return compute(
      _isolatePdfGeneration,
      _PdfGenerationParams(
        jobs: jobs,
        title: title,
        locale: locale,
        rtlFontBytes: rtlFontBytes,
        sharedInstallerNamesByGroup: sharedInstallerNamesByGroup,
        useDetails: useDetails,
        maxPages: maxPages,
        serviceCompanyName: reportBranding?.serviceCompany.name ?? '',
        serviceCompanyLogoBase64:
            reportBranding?.serviceCompany.logoBase64 ?? '',
        serviceCompanyPhoneNumber:
            reportBranding?.serviceCompany.phoneNumber ?? '',
        clientCompanyName: reportBranding?.clientCompany?.name ?? '',
        clientCompanyLogoBase64:
            reportBranding?.clientCompany?.logoBase64 ?? '',
      ),
    );
  }

  static List<String> _inOutHeaders(String locale, bool monthlyMode) {
    if (locale == 'ur') {
      return [
        '\u062A\u0627\u0631\u06CC\u062E',
        '\u06A9\u0645\u0627\u0626\u06CC \u06A9\u06CC \u062A\u0641\u0635\u06CC\u0644',
        monthlyMode
            ? '\u0645\u0627\u06C1 \u06A9\u06CC \u06A9\u0645\u0627\u0626\u06CC'
            : '\u0622\u062C \u06A9\u06CC \u06A9\u0645\u0627\u0626\u06CC',
        '\u0627\u062E\u0631\u0627\u062C\u0627\u062A',
        '\u06AF\u06BE\u0631 \u06A9\u06D1 \u0627\u062E\u0631\u0627\u062C\u0627\u062A \u06A9\u06CC \u062A\u0641\u0635\u06CC\u0644',
        '\u06AF\u06BE\u0631 \u06A9\u06D1 \u0627\u062E\u0631\u0627\u062C\u0627\u062A',
        monthlyMode
            ? '\u0645\u0627\u06C1 \u06A9\u06D1 \u06A9\u0644 \u0627\u062E\u0631\u0627\u062C\u0627\u062A'
            : '\u0622\u062C \u06A9\u06D1 \u06A9\u0644 \u0627\u062E\u0631\u0627\u062C\u0627\u062A',
        '\u062E\u0627\u0644\u0635 \u0645\u0646\u0627\u0641\u0639/\u0646\u0642\u0635\u0627\u0646',
      ];
    } else if (locale == 'ar') {
      return [
        '\u0627\u0644\u062A\u0627\u0631\u064A\u062E',
        '\u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0623\u0631\u0628\u0627\u062D',
        monthlyMode
            ? '\u0623\u0631\u0628\u0627\u062D \u0627\u0644\u0634\u0647\u0631'
            : '\u0623\u0631\u0628\u0627\u062D \u0627\u0644\u064A\u0648\u0645',
        '\u0627\u0644\u0645\u0635\u0631\u0648\u0641\u0627\u062A',
        '\u062A\u0641\u0627\u0635\u064A\u0644 \u0645\u0635\u0631\u0648\u0641\u0627\u062A \u0627\u0644\u0645\u0646\u0632\u0644',
        '\u0645\u0628\u0644\u063A \u0645\u0635\u0631\u0648\u0641\u0627\u062A \u0627\u0644\u0645\u0646\u0632\u0644',
        monthlyMode
            ? '\u0625\u062C\u0645\u0627\u0644\u064A \u0645\u0635\u0631\u0648\u0641\u0627\u062A \u0627\u0644\u0634\u0647\u0631'
            : '\u0625\u062C\u0645\u0627\u0644\u064A \u0645\u0635\u0631\u0648\u0641\u0627\u062A \u0627\u0644\u064A\u0648\u0645',
        '\u0635\u0627\u0641\u064A \u0627\u0644\u0631\u0628\u062D/\u0627\u0644\u062E\u0633\u0627\u0631\u0629',
      ];
    }
    return [
      'Date',
      'Earning Detail',
      monthlyMode ? 'Earned This Month' : 'Earned Today',
      'Expenses',
      'Home Expenses Details',
      'Home Expenses Amount',
      monthlyMode ? 'Total Expenses This Month' : 'Total Expenses Today',
      'Net Profit/Loss',
    ];
  }

  static String _inOutDefaultTitle(String locale, bool monthlyMode) {
    if (locale == 'ur') {
      return monthlyMode
          ? '\u0645\u0627\u06C1\u0627\u0646\u06C1 \u0627\u0646/\u0622\u0624\u0679 \u0631\u067E\u0648\u0631\u0679'
          : '\u0622\u062C \u06A9\u06CC \u0627\u0646/\u0622\u0624\u0679 \u0631\u067E\u0648\u0631\u0679';
    } else if (locale == 'ar') {
      return monthlyMode
          ? '\u062A\u0642\u0631\u064A\u0631 \u0634\u0647\u0631\u064A \u0644\u0644\u062F\u062E\u0648\u0644/\u0627\u0644\u062E\u0631\u0648\u062C'
          : '\u062A\u0642\u0631\u064A\u0631 \u0627\u0644\u064A\u0648\u0645 \u0644\u0644\u062F\u062E\u0648\u0644/\u0627\u0644\u062E\u0631\u0648\u062C';
    }
    return monthlyMode ? 'Monthly In/Out Report' : 'Today In/Out Report';
  }

  static String _noCompanyLabel(String locale) {
    if (locale == 'ur') {
      return '\u0628\u063A\u06CC\u0631 \u06A9\u0645\u067E\u0646\u06CC';
    }
    if (locale == 'ar') {
      return '\u0628\u062F\u0648\u0646 \u0634\u0631\u0643\u0629';
    }
    return 'No Company';
  }

  static String _companyInvoicesDefaultTitle(String locale) {
    if (locale == 'ur') {
      return '\u0622\u062C \u06A9\u06CC \u06A9\u0645\u067E\u0646\u06CC \u0648\u0627\u0626\u0632 \u0627\u0646\u0648\u0627\u0626\u0633 \u0631\u067E\u0648\u0631\u0679';
    }
    if (locale == 'ar') {
      return '\u062A\u0642\u0631\u064A\u0631 \u0641\u0648\u0627\u062A\u064A\u0631 \u0627\u0644\u064A\u0648\u0645 \u062D\u0633\u0628 \u0627\u0644\u0634\u0631\u0643\u0629';
    }
    return 'Today Company-wise Invoices';
  }

  static String _companyInvoicesStatLabel(String locale, int index) {
    const ur = [
      '\u06A9\u0644 \u0627\u0646\u0648\u0627\u0626\u0633\u0632',
      '\u06A9\u0644 \u06CC\u0648\u0646\u0679\u0633',
      '\u06A9\u0645\u067E\u0646\u06CC\u0627\u06BA',
    ];
    const ar = [
      '\u0625\u062C\u0645\u0627\u0644\u064A \u0627\u0644\u0641\u0648\u0627\u062A\u064A\u0631',
      '\u0625\u062C\u0645\u0627\u0644\u064A \u0627\u0644\u0648\u062D\u062F\u0627\u062A',
      '\u0627\u0644\u0634\u0631\u0643\u0627\u062A',
    ];
    const en = ['Total Invoices', 'Total Units', 'Companies'];
    if (locale == 'ur') return ur[index];
    if (locale == 'ar') return ar[index];
    return en[index];
  }

  static String _companyInvoicesTotalLine(
    String locale,
    int totalInvoices,
    int totalUnits,
  ) {
    if (locale == 'ur') {
      return '\u06A9\u0644 \u0627\u0646\u0648\u0627\u0626\u0633\u0632: $totalInvoices  |  \u06A9\u0644 \u06CC\u0648\u0646\u0679\u0633: $totalUnits';
    } else if (locale == 'ar') {
      return '\u0625\u062C\u0645\u0627\u0644\u064A \u0627\u0644\u0641\u0648\u0627\u062A\u064A\u0631: $totalInvoices  |  \u0625\u062C\u0645\u0627\u0644\u064A \u0627\u0644\u0648\u062D\u062F\u0627\u062A: $totalUnits';
    }
    return 'Total Invoices: $totalInvoices  |  Total Units: $totalUnits';
  }

  // â”€â”€ Isolate builders for PDF methods that use compute() â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Uint8List> _isolateBuildInOutReportPdf(
    _InOutReportParams params,
  ) => _buildInOutReportPdfInternal(params);

  static Future<Uint8List> _buildInOutReportPdfInternal(
    _InOutReportParams params,
  ) async {
    final pw.Font? font = params.fontBytes != null
        ? pw.Font.ttf(params.fontBytes!.buffer.asByteData())
        : null;
    final locale = params.locale;
    final dir = (locale == 'ur' || locale == 'ar')
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;

    final reportBranding =
        (params.serviceCompanyName.isEmpty &&
            params.serviceCompanyLogoBase64.isEmpty)
        ? null
        : ReportBrandingContext(
            serviceCompany: ReportBrandIdentity(
              name: params.serviceCompanyName,
              logoBase64: params.serviceCompanyLogoBase64,
              phoneNumber: params.serviceCompanyPhoneNumber,
            ),
            clientCompany:
                (params.clientCompanyName?.trim().isNotEmpty ?? false)
                ? ReportBrandIdentity(
                    name: params.clientCompanyName!,
                    logoBase64: params.clientCompanyLogoBase64 ?? '',
                  )
                : null,
          );

    final periodDate = params.reportDate ?? DateTime.now();
    final earnings = params.earnings;
    final expenses = params.expenses;
    final monthlyMode = params.monthlyMode;

    final workExpenses = expenses
        .where((e) => e.expenseType == AppConstants.expenseTypeWork)
        .toList();
    final homeExpenses = expenses
        .where((e) => e.expenseType == AppConstants.expenseTypeHome)
        .toList();

    final earnedToday = earnings.fold<double>(0, (s, e) => s + e.amount);
    final workTotal = workExpenses.fold<double>(0, (s, e) => s + e.amount);
    final homeTotal = homeExpenses.fold<double>(0, (s, e) => s + e.amount);
    final totalExpenses = workTotal + homeTotal;
    final net = earnedToday - totalExpenses;

    String amountPlain(double value) => value.toStringAsFixed(0);
    String amountWithSar(double value) => AppFormatters.currency(value);

    final byDay = <DateTime, Map<String, dynamic>>{};

    Map<String, dynamic> bucketFor(DateTime? date) {
      final d = date ?? periodDate;
      final key = DateTime(d.year, d.month, d.day);
      return byDay.putIfAbsent(
        key,
        () => {
          'earned': 0.0,
          'workTotal': 0.0,
          'homeTotal': 0.0,
          'earningParts': <String>[],
          'workParts': <String>[],
          'homeParts': <String>[],
        },
      );
    }

    for (final e in earnings) {
      final bucket = bucketFor(e.date);
      bucket['earned'] = (bucket['earned'] as double) + e.amount;
      (bucket['earningParts'] as List<String>).add(
        '${_translateCategoryForPdf(locale, AppFormatters.safeText(e.category))} (${amountPlain(e.amount)})',
      );
    }

    for (final e in workExpenses) {
      final bucket = bucketFor(e.date);
      bucket['workTotal'] = (bucket['workTotal'] as double) + e.amount;
      (bucket['workParts'] as List<String>).add(
        '${_translateCategoryForPdf(locale, AppFormatters.safeText(e.category))} (${amountPlain(e.amount)})',
      );
    }

    for (final e in homeExpenses) {
      final bucket = bucketFor(e.date);
      bucket['homeTotal'] = (bucket['homeTotal'] as double) + e.amount;
      (bucket['homeParts'] as List<String>).add(
        '${_translateCategoryForPdf(locale, AppFormatters.safeText(e.category))} (${amountPlain(e.amount)})',
      );
    }

    final sortedDays = byDay.keys.toList()..sort((a, b) => a.compareTo(b));

    List<String> rowForDay(DateTime day) {
      final bucket = byDay[day]!;
      final earned = bucket['earned'] as double;
      final work = bucket['workTotal'] as double;
      final home = bucket['homeTotal'] as double;
      final rowTotalExpenses = work + home;
      final rowNet = earned - rowTotalExpenses;
      final earningParts = bucket['earningParts'] as List<String>;
      final workParts = bucket['workParts'] as List<String>;
      final homeParts = bucket['homeParts'] as List<String>;

      final earningText = earningParts.isEmpty
          ? '-'
          : _safeTableCellText(earningParts.join(' | '), maxLength: 180);
      final workText = workParts.isEmpty
          ? '-'
          : _safeTableCellText(workParts.join(' | '), maxLength: 140);
      final homeText = homeParts.isEmpty
          ? '-'
          : _safeTableCellText(homeParts.join(' | '), maxLength: 180);

      return [
        AppFormatters.date(day),
        earningText,
        amountPlain(earned),
        workText,
        homeText,
        amountPlain(home),
        amountPlain(rowTotalExpenses),
        '${rowNet >= 0 ? '+' : '-'} ${amountPlain(rowNet.abs())}',
      ];
    }

    final tableRows = sortedDays.map(rowForDay).toList();
    if (tableRows.isEmpty) {
      final fallbackDate = monthlyMode
          ? DateTime(periodDate.year, periodDate.month, 1)
          : DateTime(periodDate.year, periodDate.month, periodDate.day);
      tableRows.add([
        AppFormatters.date(fallbackDate),
        '-',
        amountPlain(0),
        '-',
        '-',
        amountPlain(0),
        amountPlain(0),
        '+ ${amountPlain(0)}',
      ]);
    }

    if (monthlyMode && tableRows.length > 1) {
      final totalLabel = locale == 'ur'
          ? '\u06A9\u0644'
          : locale == 'ar'
          ? '\u0627\u0644\u0625\u062C\u0645\u0627\u0644\u064A'
          : 'Total';
      tableRows.add([
        totalLabel,
        '-',
        amountWithSar(earnedToday),
        '-',
        '-',
        amountWithSar(homeTotal),
        amountWithSar(totalExpenses),
        '${net >= 0 ? '+' : '-'} ${amountWithSar(net.abs())}',
      ]);
    }

    final shapedHeaders = _shapeRowForPdf(
      locale,
      _inOutHeaders(locale, monthlyMode),
    );
    final shapedRows = _shapeTableForPdf(locale, tableRows);

    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(20, 16, 20, 16),
        textDirection: dir,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle:
              params.reportTitle ?? _inOutDefaultTitle(locale, monthlyMode),
          font: font,
          dir: dir,
          dateRange:
              params.periodLabel ??
              (monthlyMode
                  ? '${periodDate.month.toString().padLeft(2, '0')}/${periodDate.year}'
                  : AppFormatters.date(periodDate)),
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          if (params.technicianName != null) ...[
            pw.Text(
              params.technicianName!,
              style: cellStyle,
              textDirection: dir,
            ),
            pw.SizedBox(height: 6),
          ],
          pw.TableHelper.fromTextArray(
            context: context,
            headers: shapedHeaders,
            data: shapedRows,
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.75),
              1: const pw.FlexColumnWidth(3.2),
              2: const pw.FlexColumnWidth(1.1),
              3: const pw.FlexColumnWidth(1.8),
              4: const pw.FlexColumnWidth(2.2),
              5: const pw.FlexColumnWidth(1.1),
              6: const pw.FlexColumnWidth(1.4),
              7: const pw.FlexColumnWidth(1.0),
            },
            cellAlignments: {
              for (var i = 0; i < 8; i++) i: pw.Alignment.centerLeft,
              0: pw.Alignment.center,
              2: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 5,
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  static Future<Uint8List> _isolateBuildCompanyInvoicesPdf(
    _CompanyInvoicesParams params,
  ) => _buildCompanyInvoicesPdfInternal(params);

  static Future<Uint8List> _buildCompanyInvoicesPdfInternal(
    _CompanyInvoicesParams params,
  ) async {
    final pw.Font? font = params.fontBytes != null
        ? pw.Font.ttf(params.fontBytes!.buffer.asByteData())
        : null;
    final locale = params.locale;
    final dir = (locale == 'ur' || locale == 'ar')
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
    final isRtl = locale == 'ur' || locale == 'ar';

    final reportBranding =
        (params.serviceCompanyName.isEmpty &&
            params.serviceCompanyLogoBase64.isEmpty)
        ? null
        : ReportBrandingContext(
            serviceCompany: ReportBrandIdentity(
              name: params.serviceCompanyName,
              logoBase64: params.serviceCompanyLogoBase64,
              phoneNumber: params.serviceCompanyPhoneNumber,
            ),
            clientCompany:
                (params.clientCompanyName?.trim().isNotEmpty ?? false)
                ? ReportBrandIdentity(
                    name: params.clientCompanyName!,
                    logoBase64: params.clientCompanyLogoBase64 ?? '',
                  )
                : null,
          );

    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      color: PdfColors.grey700,
    );

    final today = DateTime.now();
    final companyMap = <String, List<JobModel>>{};
    for (final job in params.jobs) {
      final key = job.companyName.trim().isEmpty
          ? _noCompanyLabel(locale)
          : job.companyName.trim();
      companyMap.putIfAbsent(key, () => <JobModel>[]).add(job);
    }

    final sortedCompanies = companyMap.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final headers = locale == 'ur'
        ? [
            '\u06A9\u0645\u067E\u0646\u06CC',
            '\u0627\u0646\u0648\u0627\u0626\u0633\u0632',
            '\u06A9\u0644 \u06CC\u0648\u0646\u0679\u0633',
            '\u0679\u06CC\u06A9\u0646\u06CC\u0634\u0646\u0632',
          ]
        : locale == 'ar'
        ? [
            '\u0627\u0644\u0634\u0631\u0643\u0629',
            '\u0639\u062F\u062F \u0627\u0644\u0641\u0648\u0627\u062A\u064A\u0631',
            '\u0625\u062C\u0645\u0627\u0644\u064A \u0627\u0644\u0648\u062D\u062F\u0627\u062A',
            '\u0627\u0644\u0641\u0646\u064A\u0648\u0646',
          ]
        : ['Company', 'Invoices', 'Total Units', 'Technicians'];

    final title = params.reportTitle ?? _companyInvoicesDefaultTitle(locale);

    final totalInvoices = params.jobs.length;
    final totalUnits = params.jobs.fold<int>(0, (s, j) => s + j.totalUnits);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: params.periodLabel ?? AppFormatters.date(today),
          reportBranding: reportBranding,
          logoBase64: params.companyLogoBase64.isNotEmpty
              ? params.companyLogoBase64
              : null,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          _statsBox(
            firstLabel: _companyInvoicesStatLabel(locale, 0),
            secondLabel: _companyInvoicesStatLabel(locale, 1),
            thirdLabel: _companyInvoicesStatLabel(locale, 2),
            firstValue: '$totalInvoices',
            secondValue: '$totalUnits',
            thirdValue: '${sortedCompanies.length}',
            font: font,
            dir: dir,
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: _shapeRowForPdf(locale, headers),
            data: _shapeTableForPdf(
              locale,
              sortedCompanies.map((company) {
                final companyJobs = companyMap[company] ?? const <JobModel>[];
                final units = companyJobs.fold<int>(
                  0,
                  (s, j) => s + j.totalUnits,
                );
                final techs = companyJobs
                    .map((j) => j.techName.trim())
                    .where((n) => n.isNotEmpty)
                    .toSet()
                    .join(', ');
                return [
                  _safeTableCellText(company, maxLength: 42),
                  '${companyJobs.length}',
                  '$units',
                  _safeTableCellText(techs, maxLength: 120),
                ];
              }).toList(),
            ),
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerLeft,
            },
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 4,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            _companyInvoicesTotalLine(locale, totalInvoices, totalUnits),
            style: subStyle.copyWith(fontWeight: pw.FontWeight.bold),
            textDirection: dir,
          ),
        ],
      ),
    );
    return pdf.save();
  }
}
