class AppConstants {
  AppConstants._();

  static const String appName = 'AC Techs';
  static const String firebaseProject = 'actechs-d415e';

  // Collections
  static const String usersCollection = 'users';
  static const String jobsCollection = 'jobs';
  static const String expensesCollection = 'expenses';
  static const String earningsCollection = 'earnings';
  static const String companiesCollection = 'companies';
  static const String appSettingsCollection = 'app_settings';
  static const String acInstallsCollection = 'ac_installs';
  static const String sharedInstallAggregatesCollection =
      'shared_install_aggregates';
  static const String invoiceClaimsCollection = 'invoice_claims';
  static const String historySubCollection = 'history';
  static const String approvalConfigDocId = 'approval_config';
  static const String companyBrandingDocId = 'company_branding';

  static const String expenseTypeWork = 'work';
  static const String expenseTypeHome = 'home';
  static const String unitTypeSplitAc = 'Split AC';
  static const String unitTypeWindowAc = 'Window AC';
  static const String unitTypeFreestandingAc = 'Freestanding AC';
  static const String unitTypeCassetteAc = 'Cassette AC';
  static const String unitTypeUninstallOld = 'Uninstallation (Old AC)';
  static const String unitTypeUninstallSplit = 'Uninstallation Split';
  static const String unitTypeUninstallWindow = 'Uninstallation Window';
  static const String unitTypeUninstallFreestanding =
      'Uninstallation Freestanding';

  // AC Service Types — what a tech records per invoice
  static const List<String> acUnitTypes = [
    unitTypeSplitAc,
    unitTypeWindowAc,
    unitTypeFreestandingAc,
    unitTypeCassetteAc,
    unitTypeUninstallOld,
    unitTypeUninstallSplit,
    unitTypeUninstallWindow,
    unitTypeUninstallFreestanding,
  ];

  // Expense Categories
  static const List<String> expenseCategories = [
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
  ];

  // Earning Categories (IN — money earned from services / sales)
  static const List<String> earningCategories = [
    'Installed Bracket',
    'Installed Extra Pipe',
    'Old AC Removal',
    'Old AC Installation',
    'Sold Old AC',
    'Sold Scrap',
    'Other',
  ];

  // Home Chore Expense Categories (personal groceries etc.)
  static const List<String> homeChoreCategories = [
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
  ];

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleTechnician = 'technician';

  // Language Codes
  static const String langEnglish = 'en';
  static const String langUrdu = 'ur';
  static const String langArabic = 'ar';

  // Free Tier Limits
  static const int maxFirestoreReadsPerDay = 50000;
  static const int maxFirestoreWritesPerDay = 20000;
}
