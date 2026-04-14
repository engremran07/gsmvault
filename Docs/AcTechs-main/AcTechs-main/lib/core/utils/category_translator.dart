import 'package:ac_techs/l10n/app_localizations.dart';

/// Translates English category keys (stored in Firestore) into
/// the current locale's display string.
///
/// Unknown / future categories fall back to the raw English key.
String translateCategory(String key, AppLocalizations l) {
  return switch (key) {
    // AC unit types
    'Split AC' => l.catSplitAc,
    'Window AC' => l.catWindowAc,
    'Freestanding AC' => l.catFreestandingAc,
    'Cassette AC' => l.catCassetteAc,
    'Uninstallation (Old AC)' => l.catUninstallOldAc,
    'Uninstallation Split' => l.uninstallSplit,
    'Uninstallation Window' => l.uninstallWindow,
    'Uninstallation Freestanding' => l.uninstallStanding,

    // Expense categories
    'Food' => l.catFood,
    'Petrol' => l.catPetrol,
    'Pipes' => l.catPipes,
    'Tools' => l.catTools,
    'Tape' => l.catTape,
    'Insulation' => l.catInsulation,
    'Gas' => l.catGas,
    'Other Consumables' => l.catOtherConsumables,
    'House Rent' => l.catHouseRent,
    'Other' => l.catOther,

    // Home chore categories
    'Bread/Roti' => l.catBreadRoti,
    'Meat' => l.catMeat,
    'Chicken' => l.catChicken,
    'Tea' => l.catTea,
    'Sugar' => l.catSugar,
    'Rice' => l.catRice,
    'Vegetables' => l.catVegetables,
    'Cooking Oil' => l.catCookingOil,
    'Milk' => l.catMilk,
    'Spices' => l.catSpices,
    'Other Groceries' => l.catOtherGroceries,

    // Earning categories
    'Installed Bracket' => l.catInstalledBracket,
    'Installed Extra Pipe' => l.catInstalledExtraPipe,
    'Old AC Removal' => l.catOldAcRemoval,
    'Old AC Installation' => l.catOldAcInstallation,
    'Sold Old AC' => l.catSoldOldAc,
    'Sold Scrap' => l.catSoldScrap,

    // Fallback — show raw key for unknown categories
    _ => key,
  };
}
