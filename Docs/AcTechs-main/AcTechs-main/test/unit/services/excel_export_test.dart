import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/services/excel_export.dart';

void main() {
  String cellText(excel_pkg.Sheet sheet, String index) {
    return sheet
            .cell(excel_pkg.CellIndex.indexByString(index))
            .value
            ?.toString() ??
        '';
  }

  group('ExcelExport workbook builders', () {
    test(
      'buildJobsWorkbook includes shared install columns and summary totals',
      () {
        final workbook = ExcelExport.buildJobsWorkbook(
          jobs: [
            JobModel(
              techId: 'tech-1',
              techName: 'Tech One',
              companyId: 'company-1',
              companyName: 'AC Co',
              invoiceNumber: 'INV-100',
              clientName: 'Client',
              clientContact: '0500',
              isSharedInstall: true,
              sharedInstallGroupKey: 'company-1-inv-100',
              sharedInvoiceTotalUnits: 4,
              sharedContributionUnits: 2,
              sharedInvoiceSplitUnits: 4,
              sharedInvoiceBracketCount: 2,
              sharedDeliveryTeamCount: 2,
              techBracketShare: 1,
              charges: const InvoiceCharges(
                acBracket: true,
                bracketCount: 1,
                bracketAmount: 75,
              ),
              acUnits: const [AcUnit(type: 'Split AC', quantity: 2)],
              date: DateTime(2026, 4, 1),
            ),
          ],
          sharedInstallerNamesByGroup: const {
            'company-1-inv-100': ['Tech One', 'Tech Two'],
          },
          generatedAt: DateTime(2026, 4, 2, 9),
        );

        final sheet = workbook['Jobs'];
        expect(cellText(sheet, 'A1'), 'Jobs Report');
        expect(cellText(sheet, 'B5'), 'Invoice Number');
        expect(cellText(sheet, 'C6'), 'Yes');
        expect(cellText(sheet, 'D6'), 'Tech One, Tech Two');
        expect(cellText(sheet, 'A8'), 'SUMMARY');
        expect(cellText(sheet, 'D8'), '2');
        expect(cellText(sheet, 'G8'), '1');
      },
    );

    test('buildExpensesWorkbook separates work and home totals', () {
      final workbook = ExcelExport.buildExpensesWorkbook(
        expenses: [
          ExpenseModel(
            techId: 'tech-1',
            techName: 'Tech One',
            category: 'Fuel',
            amount: 120,
            expenseType: 'work',
            date: DateTime(2026, 4, 2),
          ),
          ExpenseModel(
            techId: 'tech-1',
            techName: 'Tech One',
            category: 'Groceries',
            amount: 80,
            expenseType: 'home',
            date: DateTime(2026, 4, 2),
          ),
        ],
        generatedAt: DateTime(2026, 4, 2, 9),
      );

      expect(cellText(workbook['Work Expenses'], 'A6'), 'Fuel');
      expect(cellText(workbook['Work Expenses'], 'A7'), 'TOTAL');
      expect(cellText(workbook['Work Expenses'], 'B7'), '120.0');

      expect(cellText(workbook['Home Expenses'], 'A6'), 'Groceries');
      expect(cellText(workbook['Summary'], 'A6'), 'Work Expenses');
      expect(cellText(workbook['Summary'], 'B8'), '200.0');
      expect(cellText(workbook['Summary'], 'C8'), '200.0');
    });

    test('buildEarningsWorkbook appends a total row', () {
      final workbook = ExcelExport.buildEarningsWorkbook(
        earnings: [
          EarningModel(
            techId: 'tech-1',
            techName: 'Tech One',
            category: 'Scrap Sale',
            amount: 250,
            date: DateTime(2026, 4, 2),
          ),
          EarningModel(
            techId: 'tech-1',
            techName: 'Tech One',
            category: 'Advance',
            amount: 100,
            date: DateTime(2026, 4, 2),
          ),
        ],
        generatedAt: DateTime(2026, 4, 2, 9),
      );

      final sheet = workbook['Earnings'];
      expect(cellText(sheet, 'A6'), 'Scrap Sale');
      expect(cellText(sheet, 'A8'), 'TOTAL');
      expect(cellText(sheet, 'B8'), '350.0');
    });
  });
}
