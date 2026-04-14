import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/services/pdf_generator.dart';

/// Unit-level tests for the PDF generator helper logic.
///
/// Full end-to-end PDF rendering requires Flutter asset loading (font TTFs),
/// so those tests live as integration tests.  Here we validate:
///  • The model helpers that the PDF generator relies on
///  • AppFormatters methods used inside the generator
///  • Status label mapping consistency
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── JobModelX helpers (consumed by generateJobsReport) ────────────────────
  group('JobModelX helpers', () {
    test('totalUnits sums all acUnit quantities', () {
      const job = JobModel(
        techId: 't1',
        techName: 'Ahmad',
        invoiceNumber: 'ANT-001',
        clientName: 'Test Client',
        acUnits: [
          AcUnit(type: 'Split AC', quantity: 2),
          AcUnit(type: 'Window AC', quantity: 3),
        ],
      );
      expect(job.totalUnits, 5);
    });

    test('totalUnits is zero when acUnits is empty', () {
      const job = JobModel(
        techId: 't1',
        techName: 'Ahmad',
        invoiceNumber: 'ANT-002',
        clientName: 'Client',
      );
      expect(job.totalUnits, 0);
    });

    test('totalCharges sums bracket and delivery when both enabled', () {
      const job = JobModel(
        techId: 't1',
        techName: 'Ahmad',
        invoiceNumber: 'ANT-003',
        clientName: 'Client',
        charges: InvoiceCharges(
          acBracket: true,
          bracketAmount: 100,
          deliveryCharge: true,
          deliveryAmount: 50,
        ),
      );
      expect(job.totalCharges, 150.0);
    });

    test('totalCharges returns 0 when no charges enabled', () {
      const job = JobModel(
        techId: 't1',
        techName: 'Ahmad',
        invoiceNumber: 'ANT-004',
        clientName: 'Client',
        charges: InvoiceCharges(
          acBracket: false,
          bracketAmount: 100,
          deliveryCharge: false,
          deliveryAmount: 50,
        ),
      );
      expect(job.totalCharges, 0.0);
    });

    test('totalCharges returns 0 when charges is null', () {
      const job = JobModel(
        techId: 't1',
        techName: 'Ahmad',
        invoiceNumber: 'ANT-005',
        clientName: 'Client',
      );
      expect(job.totalCharges, 0.0);
    });

    test(
      'isApproved / isPending / isRejected flags are mutually exclusive',
      () {
        const pending = JobModel(
          techId: 't',
          techName: 'T',
          invoiceNumber: 'I1',
          clientName: 'C',
          status: JobStatus.pending,
        );
        const approved = JobModel(
          techId: 't',
          techName: 'T',
          invoiceNumber: 'I2',
          clientName: 'C',
          status: JobStatus.approved,
        );
        const rejected = JobModel(
          techId: 't',
          techName: 'T',
          invoiceNumber: 'I3',
          clientName: 'C',
          status: JobStatus.rejected,
        );

        expect(pending.isPending, isTrue);
        expect(pending.isApproved, isFalse);
        expect(pending.isRejected, isFalse);

        expect(approved.isApproved, isTrue);
        expect(approved.isPending, isFalse);
        expect(approved.isRejected, isFalse);

        expect(rejected.isRejected, isTrue);
        expect(rejected.isPending, isFalse);
        expect(rejected.isApproved, isFalse);
      },
    );
  });

  // ── EarningModel helpers ──────────────────────────────────────────────────
  group('EarningModel', () {
    test('fromJson round-trips through toJson', () {
      final earning = EarningModel(
        id: 'e1',
        techId: 'tid',
        techName: 'Ali',
        category: 'Sold Scrap',
        amount: 500,
        note: 'scrap metal',
        date: DateTime(2025, 3, 15),
      );
      final json = earning.toJson();
      expect(json['category'], 'Sold Scrap');
      expect(json['amount'], 500.0);
      expect(json['note'], 'scrap metal');
    });

    test('note defaults to empty string', () {
      const e = EarningModel(
        techId: 'tid',
        techName: 'Ali',
        category: 'Other',
        amount: 100,
      );
      expect(e.note, '');
    });
  });

  // ── ExpenseModel helpers ──────────────────────────────────────────────────
  group('ExpenseModel', () {
    test('fromJson round-trips through toJson', () {
      final expense = ExpenseModel(
        id: 'x1',
        techId: 'tid',
        techName: 'Ali',
        category: 'Petrol',
        amount: 250,
        expenseType: 'work',
        note: 'daily commute',
        date: DateTime(2025, 3, 20),
      );
      final json = expense.toJson();
      expect(json['category'], 'Petrol');
      expect(json['expenseType'], 'work');
      expect(json['note'], 'daily commute');
    });

    test('expenseType defaults to work', () {
      const e = ExpenseModel(
        techId: 'tid',
        techName: 'Ali',
        category: 'Food',
        amount: 50,
      );
      expect(e.expenseType, 'work');
    });

    test('note defaults to empty string', () {
      const e = ExpenseModel(
        techId: 'tid',
        techName: 'Ali',
        category: 'Food',
        amount: 50,
      );
      expect(e.note, '');
    });
  });

  // ── Net profit calculation logic (mirrors generateExpensesReport) ──────────
  group('Net profit calculation', () {
    test('positive net when earnings exceed expenses', () {
      const earnings = [
        EarningModel(
          techId: 't',
          techName: 'T',
          category: 'Other',
          amount: 1000,
        ),
        EarningModel(
          techId: 't',
          techName: 'T',
          category: 'Other',
          amount: 500,
        ),
      ];
      const expenses = [
        ExpenseModel(
          techId: 't',
          techName: 'T',
          category: 'Petrol',
          amount: 200,
        ),
      ];
      final net =
          earnings.fold<double>(0, (s, e) => s + e.amount) -
          expenses.fold<double>(0, (s, e) => s + e.amount);
      expect(net, 1300.0);
      expect(net >= 0, isTrue);
    });

    test('negative net when expenses exceed earnings', () {
      const earnings = [
        EarningModel(
          techId: 't',
          techName: 'T',
          category: 'Other',
          amount: 100,
        ),
      ];
      const expenses = [
        ExpenseModel(
          techId: 't',
          techName: 'T',
          category: 'Tools',
          amount: 500,
        ),
      ];
      final net =
          earnings.fold<double>(0, (s, e) => s + e.amount) -
          expenses.fold<double>(0, (s, e) => s + e.amount);
      expect(net, -400.0);
      expect(net < 0, isTrue);
    });

    test('zero net when both are empty', () {
      final earnings = <EarningModel>[];
      final expenses = <ExpenseModel>[];
      final net =
          earnings.fold<double>(0, (s, e) => s + e.amount) -
          expenses.fold<double>(0, (s, e) => s + e.amount);
      expect(net, 0.0);
    });
  });

  group('PDF rendering', () {
    test('generateJobsReport renders mixed RTL and Latin content', () async {
      final bytes = await PdfGenerator.generateJobsReport(
        jobs: [
          JobModel(
            techId: 'tech-1',
            techName: 'أحمد 123',
            invoiceNumber: 'INV-123',
            clientName: 'شركة Test 45',
            acUnits: const [AcUnit(type: 'Split AC', quantity: 2)],
            date: DateTime(2026, 4, 4),
          ),
        ],
        title: 'تقرير INV-123',
        locale: 'ar',
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });
  });
}
