import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/utils/category_translator.dart';
import 'package:ac_techs/l10n/app_localizations_en.dart';

void main() {
  // Use the English localizations delegate as the test fixture.
  final l = AppLocalizationsEn();

  group('translateCategory() — AC unit types', () {
    test(
      'Split AC',
      () => expect(translateCategory('Split AC', l), isNotEmpty),
    );
    test(
      'Window AC',
      () => expect(translateCategory('Window AC', l), isNotEmpty),
    );
    test(
      'Freestanding AC',
      () => expect(translateCategory('Freestanding AC', l), isNotEmpty),
    );
    test(
      'Cassette AC',
      () => expect(translateCategory('Cassette AC', l), isNotEmpty),
    );
    test(
      'Uninstallation (Old AC)',
      () => expect(translateCategory('Uninstallation (Old AC)', l), isNotEmpty),
    );
  });

  group('translateCategory() — expense categories', () {
    for (final cat in [
      'Food',
      'Petrol',
      'Pipes',
      'Tools',
      'Tape',
      'Insulation',
      'Gas',
      'Other Consumables',
      'House Rent',
      'Other',
    ]) {
      test(cat, () => expect(translateCategory(cat, l), isNotEmpty));
    }
  });

  group('translateCategory() — home chore categories', () {
    for (final cat in [
      'Bread/Roti',
      'Meat',
      'Chicken',
      'Tea',
      'Sugar',
      'Rice',
      'Vegetables',
      'Cooking Oil',
      'Milk',
      'Spices',
      'Other Groceries',
    ]) {
      test(cat, () => expect(translateCategory(cat, l), isNotEmpty));
    }
  });

  group('translateCategory() — earning categories', () {
    for (final cat in [
      'Installed Bracket',
      'Installed Extra Pipe',
      'Old AC Removal',
      'Old AC Installation',
      'Sold Old AC',
      'Sold Scrap',
    ]) {
      test(cat, () => expect(translateCategory(cat, l), isNotEmpty));
    }
  });

  group('translateCategory() — fallback', () {
    test('unknown key returns the raw key', () {
      const unknown = 'Some Future Category';
      expect(translateCategory(unknown, l), unknown);
    });

    test('empty string returns empty string', () {
      expect(translateCategory('', l), '');
    });
  });
}
