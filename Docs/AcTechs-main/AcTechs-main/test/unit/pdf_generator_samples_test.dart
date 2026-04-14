import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/services/pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exports jobs detail PDF samples in en ur ar', () async {
    if (Platform.environment.containsKey('CI')) {
      return;
    }

    final outputDir = Directory('logs/pdf_samples');
    await outputDir.create(recursive: true);

    final jobs = <JobModel>[
      JobModel(
        techId: 'tech-1',
        techName: 'Ahmed Raza',
        companyId: 'company-1',
        companyName: 'AC Techs',
        invoiceNumber: 'INV-2401',
        clientName: 'Fahad Trading',
        clientContact: '+966500000001',
        date: DateTime(2026, 4, 3),
        acUnits: const [
          AcUnit(type: 'Split AC', quantity: 2),
          AcUnit(type: 'Window AC', quantity: 1),
        ],
        charges: const InvoiceCharges(
          bracketCount: 2,
          deliveryCharge: true,
          deliveryAmount: 150,
          deliveryNote: 'Company delivery',
        ),
        expenseNote: 'Solo installation sample',
      ),
      JobModel(
        techId: 'tech-2',
        techName: 'Bilal Khan',
        companyId: 'company-1',
        companyName: 'AC Techs',
        invoiceNumber: 'SHR-7788',
        clientName: 'Noor Residency',
        clientContact: '+966500000002',
        date: DateTime(2026, 4, 4),
        isSharedInstall: true,
        sharedInstallGroupKey: 'shared-group-7788',
        sharedInvoiceTotalUnits: 8,
        sharedInvoiceSplitUnits: 3,
        sharedInvoiceWindowUnits: 2,
        sharedInvoiceFreestandingUnits: 1,
        sharedInvoiceUninstallSplitUnits: 1,
        sharedInvoiceUninstallWindowUnits: 1,
        sharedInvoiceBracketCount: 4,
        sharedInvoiceDeliveryAmount: 240,
        acUnits: const [
          AcUnit(type: 'Split AC', quantity: 1),
          AcUnit(type: 'Window AC', quantity: 1),
        ],
        charges: const InvoiceCharges(
          bracketCount: 1,
          deliveryCharge: true,
          deliveryAmount: 80,
          deliveryNote: 'Shared team delivery',
        ),
        expenseNote: 'Shared install sample',
      ),
    ];

    final sharedInstallerNamesByGroup = <String, List<String>>{
      'shared-group-7788': ['Bilal Khan', 'Usman Ali', 'Saad Ahmed'],
    };

    final locales = <String, String>{
      'en': 'Jobs Sample',
      'ur': 'جابز نمونہ',
      'ar': 'عينة الوظائف',
    };

    for (final entry in locales.entries) {
      final bytes = await PdfGenerator.generateJobsDetailsReport(
        jobs: jobs,
        title: entry.value,
        locale: entry.key,
        technicianName: 'Sample Export',
        fromDate: DateTime(2026, 4, 1),
        toDate: DateTime(2026, 4, 5),
        sharedInstallerNamesByGroup: sharedInstallerNamesByGroup,
      );
      final outputFile = File('${outputDir.path}/jobs-sample-${entry.key}.pdf');
      await outputFile.writeAsBytes(bytes, flush: true);
      expect(await outputFile.exists(), isTrue);
      expect(await outputFile.length(), greaterThan(0));
    }
  });
}
