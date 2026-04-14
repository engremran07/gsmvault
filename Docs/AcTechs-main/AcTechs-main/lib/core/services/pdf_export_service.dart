import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/services/pdf_generator.dart';
import 'package:ac_techs/core/services/report_branding.dart';

class PdfExportService {
  PdfExportService._();

  static Future<void> shareInOutReport({
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
    required String fileName,
    String locale = 'en',
    String? technicianName,
    String? reportTitle,
    DateTime? reportDate,
    String? periodLabel,
    bool monthlyMode = false,
    ReportBrandingContext? reportBranding,
  }) async {
    final bytes = await PdfGenerator.generateTodayInOutReport(
      earnings: earnings,
      expenses: expenses,
      locale: locale,
      technicianName: technicianName,
      reportTitle: reportTitle,
      reportDate: reportDate,
      periodLabel: periodLabel,
      monthlyMode: monthlyMode,
      reportBranding: reportBranding,
    );

    await PdfGenerator.sharePdfBytes(bytes, fileName);
  }

  static Future<void> shareCompanyInvoicesReport({
    required List<JobModel> jobs,
    required String fileName,
    String locale = 'en',
    String? reportTitle,
    String? periodLabel,
    String companyLogoBase64 = '',
    ReportBrandingContext? reportBranding,
  }) async {
    final bytes = await PdfGenerator.generateTodayCompanyInvoicesReport(
      jobs: jobs,
      locale: locale,
      reportTitle: reportTitle,
      periodLabel: periodLabel,
      companyLogoBase64: companyLogoBase64,
      reportBranding: reportBranding,
    );

    await PdfGenerator.sharePdfBytes(bytes, fileName);
  }

  static Future<void> previewJobsReport({
    required BuildContext context,
    required List<JobModel> jobs,
    required String locale,
    ReportBrandingContext? reportBranding,
  }) {
    return PdfGenerator.previewPdf(context, jobs, locale, reportBranding);
  }

  static Future<void> sharePdfBytes(Uint8List bytes, String fileName) {
    return PdfGenerator.sharePdfBytes(bytes, fileName);
  }
}
