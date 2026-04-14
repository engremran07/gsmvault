import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/job_model.dart';

void main() {
  // ────────────────────────────────────────────────────────────
  group('AcUnit.fromJson()', () {
    test('parses type and quantity', () {
      final unit = AcUnit.fromJson({'type': 'Split AC', 'quantity': 3});
      expect(unit.type, 'Split AC');
      expect(unit.quantity, 3);
    });

    test('defaults quantity to 1 when absent', () {
      final unit = AcUnit.fromJson({'type': 'Window AC'});
      expect(unit.quantity, 1);
    });
  });

  group('AcUnit.toJson()', () {
    test('serialises type and quantity', () {
      const unit = AcUnit(type: 'Cassette AC', quantity: 2);
      final json = unit.toJson();
      expect(json['type'], 'Cassette AC');
      expect(json['quantity'], 2);
    });
  });

  group('AcUnit – equality', () {
    test('same type and quantity are equal', () {
      const a = AcUnit(type: 'Split AC', quantity: 1);
      const b = AcUnit(type: 'Split AC', quantity: 1);
      expect(a, b);
    });

    test('different quantity makes units unequal', () {
      const a = AcUnit(type: 'Split AC', quantity: 1);
      const b = AcUnit(type: 'Split AC', quantity: 2);
      expect(a, isNot(b));
    });
  });

  // ────────────────────────────────────────────────────────────
  group('InvoiceCharges.fromJson()', () {
    test('parses all fields', () {
      final json = {
        'acBracket': true,
        'bracketAmount': 150.0,
        'deliveryCharge': true,
        'deliveryAmount': 50.0,
        'deliveryNote': 'far location',
      };
      final charges = InvoiceCharges.fromJson(json);
      expect(charges.acBracket, isTrue);
      expect(charges.bracketAmount, 150.0);
      expect(charges.deliveryCharge, isTrue);
      expect(charges.deliveryAmount, 50.0);
      expect(charges.deliveryNote, 'far location');
    });

    test('applies all defaults when json is empty', () {
      final charges = InvoiceCharges.fromJson({});
      expect(charges.acBracket, isFalse);
      expect(charges.bracketAmount, 0.0);
      expect(charges.deliveryCharge, isFalse);
      expect(charges.deliveryAmount, 0.0);
      expect(charges.deliveryNote, '');
    });
  });

  // ────────────────────────────────────────────────────────────
  group('JobModel.fromJson()', () {
    Map<String, dynamic> baseJob() => {
      'techId': 'tech-1',
      'techName': 'Khalid',
      'invoiceNumber': 'INV-001',
      'clientName': 'Mr. Salem',
    };

    test('parses required fields', () {
      final model = JobModel.fromJson(baseJob());
      expect(model.techId, 'tech-1');
      expect(model.techName, 'Khalid');
      expect(model.invoiceNumber, 'INV-001');
      expect(model.clientName, 'Mr. Salem');
    });

    test('defaults id to empty string when absent', () {
      expect(JobModel.fromJson(baseJob()).id, '');
    });

    test('defaults status to pending when absent', () {
      expect(JobModel.fromJson(baseJob()).status, JobStatus.pending);
    });

    test('parses status "approved"', () {
      final json = {...baseJob(), 'status': 'approved'};
      expect(JobModel.fromJson(json).status, JobStatus.approved);
    });

    test('parses status "rejected"', () {
      final json = {...baseJob(), 'status': 'rejected'};
      expect(JobModel.fromJson(json).status, JobStatus.rejected);
    });

    test('defaults expenses to 0.0 when absent', () {
      expect(JobModel.fromJson(baseJob()).expenses, 0.0);
    });

    test('parses expenses amount', () {
      final json = {...baseJob(), 'expenses': 200.0};
      expect(JobModel.fromJson(json).expenses, 200.0);
    });

    test('defaults acUnits to empty list when absent', () {
      expect(JobModel.fromJson(baseJob()).acUnits, isEmpty);
    });

    test('parses acUnits list', () {
      final json = {
        ...baseJob(),
        'acUnits': [
          {'type': 'Split AC', 'quantity': 2},
          {'type': 'Window AC', 'quantity': 1},
        ],
      };
      final model = JobModel.fromJson(json);
      expect(model.acUnits.length, 2);
      expect(model.acUnits[0].type, 'Split AC');
      expect(model.acUnits[0].quantity, 2);
      expect(model.acUnits[1].type, 'Window AC');
    });

    test('parses nested charges object', () {
      final json = {
        ...baseJob(),
        'charges': {
          'acBracket': true,
          'bracketAmount': 100.0,
          'deliveryCharge': false,
          'deliveryAmount': 0.0,
          'deliveryNote': '',
        },
      };
      final model = JobModel.fromJson(json);
      expect(model.charges, isNotNull);
      expect(model.charges!.acBracket, isTrue);
      expect(model.charges!.bracketAmount, 100.0);
    });

    test('charges is null when absent', () {
      expect(JobModel.fromJson(baseJob()).charges, isNull);
    });

    test('parses date from ISO string', () {
      final json = {...baseJob(), 'date': '2024-07-20T00:00:00.000'};
      final model = JobModel.fromJson(json);
      expect(model.date!.year, 2024);
      expect(model.date!.month, 7);
      expect(model.date!.day, 20);
    });

    test('date is null when absent', () {
      expect(JobModel.fromJson(baseJob()).date, isNull);
    });
  });

  group('JobModel.toJson()', () {
    test('includes all fields', () {
      const model = JobModel(
        id: 'job-1',
        techId: 'tech-1',
        techName: 'Ali',
        invoiceNumber: 'INV-100',
        clientName: 'Client A',
        status: JobStatus.approved,
      );
      final json = model.toJson();

      expect(json['id'], 'job-1');
      expect(json['techId'], 'tech-1');
      expect(json['techName'], 'Ali');
      expect(json['invoiceNumber'], 'INV-100');
      expect(json['clientName'], 'Client A');
      expect(json['status'], 'approved');
    });
  });

  // ────────────────────────────────────────────────────────────
  group('JobModelX extensions', () {
    test('isPending returns true for pending status', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
        status: JobStatus.pending,
      );
      expect(job.isPending, isTrue);
      expect(job.isApproved, isFalse);
      expect(job.isRejected, isFalse);
    });

    test('isApproved returns true for approved status', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
        status: JobStatus.approved,
      );
      expect(job.isApproved, isTrue);
      expect(job.isPending, isFalse);
      expect(job.isRejected, isFalse);
    });

    test('isRejected returns true for rejected status', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
        status: JobStatus.rejected,
      );
      expect(job.isRejected, isTrue);
      expect(job.isPending, isFalse);
      expect(job.isApproved, isFalse);
    });

    test('totalUnits sums quantities from all AC units', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
        acUnits: [
          AcUnit(type: 'Split AC', quantity: 3),
          AcUnit(type: 'Window AC', quantity: 2),
        ],
      );
      expect(job.totalUnits, 5);
    });

    test('totalUnits is 0 for empty acUnits', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
      );
      expect(job.totalUnits, 0);
    });

    test('totalCharges returns 0 when charges is null', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
      );
      expect(job.totalCharges, 0.0);
    });

    test('totalCharges sums bracket and delivery when both enabled', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
        charges: InvoiceCharges(
          acBracket: true,
          bracketAmount: 200.0,
          deliveryCharge: true,
          deliveryAmount: 75.0,
        ),
      );
      expect(job.totalCharges, 275.0);
    });

    test('totalCharges counts only bracket when delivery disabled', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
        charges: InvoiceCharges(
          acBracket: true,
          bracketAmount: 100.0,
          deliveryCharge: false,
          deliveryAmount: 50.0,
        ),
      );
      expect(job.totalCharges, 100.0);
    });

    test('totalCharges counts only delivery when bracket disabled', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
        charges: InvoiceCharges(
          acBracket: false,
          bracketAmount: 100.0,
          deliveryCharge: true,
          deliveryAmount: 50.0,
        ),
      );
      expect(job.totalCharges, 50.0);
    });

    test('effectiveBracketCount falls back to one for historical imports', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
        charges: InvoiceCharges(acBracket: true, bracketAmount: 150.0),
      );
      expect(job.effectiveBracketCount, 1);
    });

    test('effectiveBracketCount prefers explicit bracketCount', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
        charges: InvoiceCharges(
          acBracket: true,
          bracketCount: 3,
          bracketAmount: 150.0,
        ),
      );
      expect(job.effectiveBracketCount, 3);
    });

    test('totalCharges returns 0 when both flags are false', () {
      const job = JobModel(
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
        charges: InvoiceCharges(
          acBracket: false,
          bracketAmount: 100.0,
          deliveryCharge: false,
          deliveryAmount: 50.0,
        ),
      );
      expect(job.totalCharges, 0.0);
    });

    test('toFirestore() excludes id key', () {
      const job = JobModel(
        id: 'hidden-id',
        techId: 't',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
      );
      expect(job.toFirestore().containsKey('id'), isFalse);
    });

    test('toFirestore() includes techId', () {
      const job = JobModel(
        id: 'j1',
        techId: 'my-tech',
        techName: 'T',
        invoiceNumber: 'I',
        clientName: 'C',
      );
      expect(job.toFirestore()['techId'], 'my-tech');
    });
  });

  // ────────────────────────────────────────────────────────────
  group('JobStatus enum', () {
    test('has exactly 3 values', () {
      expect(JobStatus.values.length, 3);
    });

    test('values are pending, approved, rejected', () {
      expect(
        JobStatus.values,
        containsAll([
          JobStatus.pending,
          JobStatus.approved,
          JobStatus.rejected,
        ]),
      );
    });
  });
}
