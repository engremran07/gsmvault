import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';

void main() {
  group('AppConstants – app info', () {
    test('appName is "AC Techs"', () {
      expect(AppConstants.appName, 'AC Techs');
    });

    test('firebaseProject is non-empty', () {
      expect(AppConstants.firebaseProject, isNotEmpty);
    });
  });

  group('AppConstants – Firestore collection names', () {
    test('usersCollection is "users"', () {
      expect(AppConstants.usersCollection, 'users');
    });

    test('jobsCollection is "jobs"', () {
      expect(AppConstants.jobsCollection, 'jobs');
    });

    test('expensesCollection is "expenses"', () {
      expect(AppConstants.expensesCollection, 'expenses');
    });

    test('earningsCollection is "earnings"', () {
      expect(AppConstants.earningsCollection, 'earnings');
    });

    test('companiesCollection is "companies"', () {
      expect(AppConstants.companiesCollection, 'companies');
    });

    test('all collection names are unique', () {
      final names = [
        AppConstants.usersCollection,
        AppConstants.jobsCollection,
        AppConstants.expensesCollection,
        AppConstants.earningsCollection,
        AppConstants.companiesCollection,
      ];
      expect(names.toSet().length, names.length);
    });
  });

  group('AppConstants – expense type strings', () {
    test('expenseTypeWork is "work"', () {
      expect(AppConstants.expenseTypeWork, 'work');
    });

    test('expenseTypeHome is "home"', () {
      expect(AppConstants.expenseTypeHome, 'home');
    });

    test('expenseTypeWork and expenseTypeHome are different', () {
      expect(AppConstants.expenseTypeWork, isNot(AppConstants.expenseTypeHome));
    });
  });

  group('AppConstants – role strings', () {
    test('roleAdmin is "admin"', () {
      expect(AppConstants.roleAdmin, 'admin');
    });

    test('roleTechnician is "technician"', () {
      expect(AppConstants.roleTechnician, 'technician');
    });

    test('roleAdmin and roleTechnician are different', () {
      expect(AppConstants.roleAdmin, isNot(AppConstants.roleTechnician));
    });
  });

  group('AppConstants – language codes', () {
    test('langEnglish is "en"', () {
      expect(AppConstants.langEnglish, 'en');
    });

    test('langUrdu is "ur"', () {
      expect(AppConstants.langUrdu, 'ur');
    });

    test('langArabic is "ar"', () {
      expect(AppConstants.langArabic, 'ar');
    });

    test('all language codes are unique', () {
      final codes = [
        AppConstants.langEnglish,
        AppConstants.langUrdu,
        AppConstants.langArabic,
      ];
      expect(codes.toSet().length, codes.length);
    });
  });

  group('AppConstants – acUnitTypes', () {
    test('contains 8 AC unit types', () {
      expect(AppConstants.acUnitTypes.length, 8);
    });

    test('contains "Split AC"', () {
      expect(AppConstants.acUnitTypes, contains('Split AC'));
    });

    test('contains "Window AC"', () {
      expect(AppConstants.acUnitTypes, contains('Window AC'));
    });

    test('contains "Freestanding AC"', () {
      expect(AppConstants.acUnitTypes, contains('Freestanding AC'));
    });

    test('contains "Cassette AC"', () {
      expect(AppConstants.acUnitTypes, contains('Cassette AC'));
    });

    test('contains "Uninstallation (Old AC)"', () {
      expect(AppConstants.acUnitTypes, contains('Uninstallation (Old AC)'));
    });

    test('contains "Uninstallation Split"', () {
      expect(AppConstants.acUnitTypes, contains('Uninstallation Split'));
    });

    test('contains "Uninstallation Window"', () {
      expect(AppConstants.acUnitTypes, contains('Uninstallation Window'));
    });

    test('all AC unit type names are unique', () {
      const types = AppConstants.acUnitTypes;
      expect(types.toSet().length, types.length);
    });
  });

  group('AppConstants – expenseCategories', () {
    test('contains 10 expense categories', () {
      expect(AppConstants.expenseCategories.length, 10);
    });

    test('contains "Food"', () {
      expect(AppConstants.expenseCategories, contains('Food'));
    });

    test('contains "Petrol"', () {
      expect(AppConstants.expenseCategories, contains('Petrol'));
    });

    test('contains "Other"', () {
      expect(AppConstants.expenseCategories, contains('Other'));
    });

    test('all expense category names are unique', () {
      const cats = AppConstants.expenseCategories;
      expect(cats.toSet().length, cats.length);
    });
  });

  group('AppConstants – earningCategories', () {
    test('contains 7 earning categories', () {
      expect(AppConstants.earningCategories.length, 7);
    });

    test('contains "Sold Old AC"', () {
      expect(AppConstants.earningCategories, contains('Sold Old AC'));
    });

    test('contains "Sold Scrap"', () {
      expect(AppConstants.earningCategories, contains('Sold Scrap'));
    });

    test('contains "Installed Bracket"', () {
      expect(AppConstants.earningCategories, contains('Installed Bracket'));
    });

    test('contains "Other"', () {
      expect(AppConstants.earningCategories, contains('Other'));
    });

    test('all earning category names are unique', () {
      const cats = AppConstants.earningCategories;
      expect(cats.toSet().length, cats.length);
    });
  });

  group('AppConstants – homeChoreCategories', () {
    test('contains 11 home chore categories', () {
      expect(AppConstants.homeChoreCategories.length, 11);
    });

    test('contains "Bread/Roti"', () {
      expect(AppConstants.homeChoreCategories, contains('Bread/Roti'));
    });

    test('contains "Meat"', () {
      expect(AppConstants.homeChoreCategories, contains('Meat'));
    });

    test('contains "Other Groceries"', () {
      expect(AppConstants.homeChoreCategories, contains('Other Groceries'));
    });

    test('all home chore category names are unique', () {
      const cats = AppConstants.homeChoreCategories;
      expect(cats.toSet().length, cats.length);
    });
  });

  group('AppConstants – Firestore limits', () {
    test('maxFirestoreReadsPerDay is positive', () {
      expect(AppConstants.maxFirestoreReadsPerDay, greaterThan(0));
    });

    test('maxFirestoreWritesPerDay is positive', () {
      expect(AppConstants.maxFirestoreWritesPerDay, greaterThan(0));
    });

    test('reads per day is greater than writes per day', () {
      expect(
        AppConstants.maxFirestoreReadsPerDay,
        greaterThan(AppConstants.maxFirestoreWritesPerDay),
      );
    });
  });
}
