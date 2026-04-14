// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AC Techs';

  @override
  String get techMgmtSystem => 'Technician Management System';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get enterValidPhone => 'Please enter a valid phone number';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get required => 'Required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String minChars(int count) {
    return 'Min $count characters';
  }

  @override
  String get technician => 'Technician';

  @override
  String get admin => 'Admin';

  @override
  String get administrator => 'Administrator';

  @override
  String get home => 'Home';

  @override
  String get jobs => 'Jobs';

  @override
  String get expenses => 'Expenses';

  @override
  String get profile => 'Profile';

  @override
  String get approvals => 'Approvals';

  @override
  String get sharedInstallApprovalRequired => 'Shared Install Approvals';

  @override
  String get enforceMinimumBuild => 'Enforce Minimum Build';

  @override
  String get minimumSupportedBuild => 'Minimum Supported Build';

  @override
  String get lockRecordsBefore => 'Lock Records Before';

  @override
  String get noPeriodLock => 'No period lock is active.';

  @override
  String get clearPeriodLock => 'Clear Period Lock';

  @override
  String get lockedPeriodDescription =>
      'Older records cannot be created, edited, approved, rejected, or deleted.';

  @override
  String get analytics => 'Analytics';

  @override
  String get team => 'Team';

  @override
  String get export => 'Export';

  @override
  String get submit => 'Submit';

  @override
  String get submitForApproval => 'Submit for Approval';

  @override
  String get submitting => 'Submitting...';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get today => 'Today';

  @override
  String get thisMonth => 'This Month';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get invoiceNumber => 'Invoice Number';

  @override
  String get clientName => 'Client Name';

  @override
  String get clientNameOptional => 'Client Name (optional)';

  @override
  String get clientContact => 'Client Contact';

  @override
  String get clientPhone => 'Client Phone Number';

  @override
  String get acUnits => 'AC Units';

  @override
  String get addUnit => 'Add Unit';

  @override
  String get unitType => 'Unit Type';

  @override
  String get quantity => 'Quantity';

  @override
  String get expenseAmount => 'Expense Amount';

  @override
  String get expenseNote => 'Expense Note';

  @override
  String get adminNote => 'Admin Note';

  @override
  String get rejectReason => 'Reason for rejection';

  @override
  String get noJobsYet => 'No jobs submitted yet';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get noJobsToday => 'No jobs submitted today';

  @override
  String get noMatchingJobs => 'No matching jobs';

  @override
  String get noApprovals => 'No pending approvals';

  @override
  String get noMatchingApprovals => 'No matching approvals';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get todaysJobs => 'Today\'s Jobs';

  @override
  String get totalJobs => 'Total Jobs';

  @override
  String get pendingApprovals => 'Pending Approvals';

  @override
  String get approvedJobs => 'Approved Jobs';

  @override
  String get rejectedJobs => 'Rejected Jobs';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get teamMembers => 'Team Members';

  @override
  String get activeMembers => 'Active Members';

  @override
  String get jobSubmitted =>
      'Job submitted successfully! Waiting for admin approval.';

  @override
  String get jobSaved => 'Entry added successfully.';

  @override
  String get jobApproved => 'Job approved!';

  @override
  String get jobRejected => 'Job returned with your feedback.';

  @override
  String get couldNotApprove => 'Could not approve. Please try again.';

  @override
  String get couldNotReject => 'Could not reject. Please try again.';

  @override
  String bulkApproveSuccess(int count) {
    return '$count jobs approved!';
  }

  @override
  String bulkRejectSuccess(int count) {
    return '$count jobs rejected.';
  }

  @override
  String get bulkApproveFailed => 'Bulk approve failed. Try again.';

  @override
  String get bulkRejectFailed => 'Bulk reject failed. Try again.';

  @override
  String get rejectSelectedJobs => 'Reject Selected Jobs';

  @override
  String get rejectAll => 'Reject All';

  @override
  String get rejectJob => 'Reject Job';

  @override
  String exportSuccess(int count) {
    return 'Export ready! $count jobs exported to Excel.';
  }

  @override
  String get exportFailed =>
      'Couldn\'t create the export file. Please try again.';

  @override
  String get noJobsForPeriod =>
      'No jobs found for this period. Try a different date range.';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportExcel => 'Export to Excel';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get urdu => 'اردو';

  @override
  String get arabic => 'العربية';

  @override
  String get pressBackAgainToExit => 'Press back again to exit the app.';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesMessage =>
      'You have unsaved changes. Leave this page and lose them?';

  @override
  String get leavePage => 'Leave';

  @override
  String get settings => 'Settings';

  @override
  String get reports => 'Reports';

  @override
  String get reportsSubtitle => 'Generate and share PDF reports';

  @override
  String get dailyInOutReport => 'Daily In/Out Report';

  @override
  String get dailyInOutReportDesc => 'Today\'s earnings and expenses summary';

  @override
  String get monthlyInOutReport => 'Monthly In/Out Report';

  @override
  String get monthlyInOutReportDesc => 'Monthly earnings and expenses overview';

  @override
  String get acInstallsReport => 'AC Installations Report';

  @override
  String get acInstallsReportDesc => 'Installed air conditioners by date range';

  @override
  String get sharedInstallReport => 'Shared Install Report';

  @override
  String get sharedInstallReportDesc => 'Team shared installation details';

  @override
  String get paymentSettlementReport => 'Payment Settlement Report';

  @override
  String get paymentSettlementReportDesc => 'Summary of received job payments';

  @override
  String get jobsReport => 'Jobs Report';

  @override
  String get jobsReportDesc => 'Detailed job history with filters';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get selectMonth => 'Select Month';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get noDataForPeriod => 'No data found for the selected period.';

  @override
  String get offline => 'Offline';

  @override
  String get offlineBannerMessage =>
      'No internet connection. You are viewing cached data until the connection returns.';

  @override
  String get syncing => 'Syncing...';

  @override
  String get jobHistory => 'Job History';

  @override
  String get jobDetails => 'Job Details';

  @override
  String get submitJob => 'Submit Job';

  @override
  String get submitInvoice => 'Submit Invoice';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get selectDate => 'Select Date';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get invoiceDetails => 'Invoice Details';

  @override
  String get acServices => 'AC Services';

  @override
  String get serviceType => 'Service type';

  @override
  String get add => 'Add';

  @override
  String get additionalCharges => 'Additional Charges';

  @override
  String get acOutdoorBracket => 'Outdoor Bracket';

  @override
  String get bracketSubtitle => 'Bracket for outdoor unit mounting';

  @override
  String get bracketCharge => 'Bracket charge (SAR)';

  @override
  String get deliveryCharge => 'Delivery Charge';

  @override
  String get deliverySubtitle => 'Customer location >50 km away';

  @override
  String get deliveryChargeAmount => 'Delivery charge (SAR)';

  @override
  String get locationNote => 'Location / note (optional)';

  @override
  String get addServiceFirst =>
      'Add at least one AC service before submitting.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmImport => 'Confirm import';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get activate => 'Activate';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get totalUnits => 'Total Units';

  @override
  String get date => 'Date';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeAutoDesc => 'Follow system dark/light setting';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkDesc => 'Arctic dark — easy on the eyes';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightDesc => 'Clean and bright for outdoor use';

  @override
  String get themeHighContrast => 'High Contrast';

  @override
  String get themeHighContrastDesc => 'Maximum readability, bold borders';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get company => 'Company';

  @override
  String get companyBranding => 'Company Branding';

  @override
  String get region => 'Region';

  @override
  String get pakistan => 'Pakistan';

  @override
  String get saudiArabia => 'Saudi Arabia';

  @override
  String get call => 'Call';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get total => 'Total';

  @override
  String get noTeamMembers => 'No team members yet';

  @override
  String get noMatchingMembers => 'No matching team members';

  @override
  String get searchByNameOrEmail => 'Search by name or email...';

  @override
  String get addTechnician => 'Add Technician';

  @override
  String get editTechnician => 'Edit Technician';

  @override
  String get deleteTechnician => 'Delete Technician';

  @override
  String deleteConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get deleteWarning => 'This action cannot be undone.';

  @override
  String get name => 'Name';

  @override
  String get role => 'Role';

  @override
  String get userCreated => 'User created successfully!';

  @override
  String get userUpdated => 'User updated successfully!';

  @override
  String get userDeleted => 'User archived successfully!';

  @override
  String get usersActivated => 'Users activated';

  @override
  String get usersDeactivated => 'Users deactivated';

  @override
  String get bulkActivate => 'Activate Selected';

  @override
  String get bulkDeactivate => 'Deactivate Selected';

  @override
  String get bulkDelete => 'Delete Selected';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get inOut => 'In / Out';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get todaysInOut => 'Today\'s In / Out';

  @override
  String get todaysEntries => 'Today\'s Entries';

  @override
  String get noEntriesToday => 'No entries today';

  @override
  String get addFirstEntry => 'Add your first IN or OUT above';

  @override
  String get inEarned => 'IN  (Earned)';

  @override
  String get outSpent => 'OUT  (Spent)';

  @override
  String get category => 'Category';

  @override
  String get amountSar => 'Amount (SAR)';

  @override
  String get amountMustBePositive => 'Amount must be greater than zero.';

  @override
  String get remarksOptional => 'Remarks (optional)';

  @override
  String get saving => 'Saving...';

  @override
  String get addEarning => 'Add Earning';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get enterAmount => 'Enter an amount.';

  @override
  String get enterValidAmount => 'Enter a valid positive amount.';

  @override
  String get earned => 'IN';

  @override
  String get spent => 'OUT';

  @override
  String get profit => 'Profit';

  @override
  String get loss => 'Loss';

  @override
  String get newestFirst => 'Newest first';

  @override
  String get oldestFirst => 'Oldest first';

  @override
  String get copyInvoice => 'Copy Invoice #';

  @override
  String get viewInHistory => 'View in History';

  @override
  String get invoiceCopied => 'Invoice number copied!';

  @override
  String get newJob => 'New Job';

  @override
  String get submitAJob => 'Submit a Job';

  @override
  String get sharedInstall => 'Shared Install';

  @override
  String get sharedInstallHint =>
      'Enable when one invoice is split across multiple technicians.';

  @override
  String get sharedInstallMixHint =>
      'Enter invoice totals by type. Technicians will enter their own unit share manually. Delivery is split equally only.';

  @override
  String get flushOperationGuidanceTitle => 'Which operation do you need?';

  @override
  String get flushOperationMigrationNote =>
      'One-time migration or historical import keeps existing data and is the safe choice for first-time Excel onboarding.';

  @override
  String get flushOperationReimportNote =>
      'Flush plus re-import deletes operational data first. Use it only for a full reset or when you intentionally need to rebuild from scratch.';

  @override
  String get sharedInvoiceTotalUnits => 'Invoice Total Units';

  @override
  String get sharedInstallLimitError =>
      'Your entered units exceed the invoice total units.';

  @override
  String get sharedInvoiceSplitUnits => 'Invoice Split Units';

  @override
  String get sharedInvoiceWindowUnits => 'Invoice Window Units';

  @override
  String get sharedInvoiceFreestandingUnits => 'Invoice Standing Units';

  @override
  String get sharedTeamSize => 'Shared Team Size';

  @override
  String get sharedInvoiceDeliveryAmount => 'Total Delivery Charge (Invoice)';

  @override
  String get sharedDeliverySplitHint =>
      'This delivery amount will be split equally across the shared team.';

  @override
  String get sharedDeliverySplitInvalid =>
      'Enter the shared team size so delivery charges can be split equally.';

  @override
  String get invoiceConflictNeedsReview =>
      'This invoice also exists in another company. Review before approval.';

  @override
  String invoiceConflictCompaniesLabel(String companies) {
    return 'Conflicting companies: $companies';
  }

  @override
  String get splits => 'Splits';

  @override
  String get windowAc => 'Window';

  @override
  String get standing => 'Standing';

  @override
  String get cassette => 'Cassette';

  @override
  String get uninstalls => 'Uninstalls';

  @override
  String get uninstallSplit => 'Uninstall Split';

  @override
  String get uninstallWindow => 'Uninstall Window';

  @override
  String get uninstallStanding => 'Uninstall Standing';

  @override
  String get jobStatus => 'Job Status';

  @override
  String get jobsPerTechnician => 'Jobs per Technician';

  @override
  String get technicians => 'Technicians';

  @override
  String get recentPending => 'Recent Pending';

  @override
  String get invoice => 'Invoice';

  @override
  String get client => 'Client';

  @override
  String get units => 'Units';

  @override
  String get expensesSar => 'Expenses (SAR)';

  @override
  String get status => 'Status';

  @override
  String get sort => 'Sort';

  @override
  String get yourShare => 'Your Share';

  @override
  String get installations => 'Installations';

  @override
  String get earningsIn => 'Earnings (IN)';

  @override
  String get expensesOut => 'Expenses (OUT)';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get earningsBreakdown => 'Earnings Breakdown';

  @override
  String get expensesBreakdown => 'Expenses Breakdown';

  @override
  String get installationsByType => 'Installations by Type';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get history => 'History';

  @override
  String get searchByClientOrInvoice => 'Search by client or invoice...';

  @override
  String get searchByTechClientInvoice =>
      'Search by tech, client, or invoice...';

  @override
  String get exportAsPdf => 'Export as PDF';

  @override
  String nUnits(int count) {
    return '$count units';
  }

  @override
  String activeOfTotal(int active, int total) {
    return '$active / $total active';
  }

  @override
  String get exportToPdf => 'Export to PDF';

  @override
  String get exportToExcel => 'Export to Excel';

  @override
  String get reportPreset => 'Report Preset';

  @override
  String get byTechnician => 'By Technician';

  @override
  String get uninstallRateBreakdown => 'Uninstall Rate Breakdown';

  @override
  String exportReady(int count) {
    return 'Export ready! $count jobs exported to Excel.';
  }

  @override
  String get couldNotExport =>
      'Couldn\'t create the export file. Please try again.';

  @override
  String get appSubtitle => 'Technician Management System';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String passwordResetSent(String email) {
    return 'Password reset email sent to $email';
  }

  @override
  String confirmDeleteUser(String name) {
    return 'This will deactivate $name and they won\'t be able to sign in. Continue?';
  }

  @override
  String get addMoreEarning => '+ Add Another Earning';

  @override
  String get addMoreExpense => '+ Add Another Expense';

  @override
  String get companies => 'Companies';

  @override
  String get addCompany => 'Add Company';

  @override
  String get editCompany => 'Edit Company';

  @override
  String get companyName => 'Company Name';

  @override
  String get ambiguousCompanyName => 'Ambiguous';

  @override
  String get companyPhoneNumber => 'Company Phone Number';

  @override
  String get invoicePrefix => 'Invoice Prefix';

  @override
  String get invoiceSuffix => 'Invoice Number';

  @override
  String get selectCompany => 'Select company';

  @override
  String get companySelectionRequired =>
      'Please select a company before submitting.';

  @override
  String get noCompany => 'No company';

  @override
  String get noCompaniesYet => 'No companies added yet';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get changeYourName => 'Change your display name';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get companyCreated => 'Company created successfully!';

  @override
  String get companyUpdated => 'Company updated successfully!';

  @override
  String get companyActivated => 'Company activated';

  @override
  String get companyDeactivated => 'Company deactivated';

  @override
  String get manageLogoAndBranding => 'Manage Logo and Branding';

  @override
  String get editOwnCompanyBranding => 'Edit AC Techs Branding';

  @override
  String get manageClientCompanyBranding => 'Manage Client Company Branding';

  @override
  String get ownCompanyBrandingUpdated =>
      'AC Techs branding updated successfully!';

  @override
  String get workExpenses => 'Work Expenses';

  @override
  String get homeExpenses => 'Home Expenses';

  @override
  String get importHistoryData => 'Import Historical Data';

  @override
  String get importHistoryDataSubtitle =>
      'Upload one or more Excel files to import previous technician installations by technician ID/email/name.';

  @override
  String get uploadExcel => 'Upload Excel';

  @override
  String get importDropFilesTitle => 'Drag and drop Excel files here';

  @override
  String get importDropFilesSubtitle =>
      'Supports .xlsx and .xls files, or use Upload Excel.';

  @override
  String get importUnsupportedFileType =>
      'Only Excel .xlsx or .xls files are supported.';

  @override
  String get deleteSourceAfterImport =>
      'Delete source file after import (best effort)';

  @override
  String get importInProgress => 'Importing...';

  @override
  String get importNoFileSelected => 'No file selected.';

  @override
  String get importFailedNoRows => 'No valid rows found for import.';

  @override
  String importCompletedCount(int count) {
    return 'Imported $count rows';
  }

  @override
  String importSkippedCount(int count) {
    return 'Skipped $count rows';
  }

  @override
  String importUnresolvedTechRows(int count) {
    return '$count rows skipped: technician not found';
  }

  @override
  String importRowsWithoutTechName(int count) {
    return '$count rows have no technician name';
  }

  @override
  String importUniqueTechNamesCount(int count) {
    return '$count unique technician names found';
  }

  @override
  String get importTopTechNamesLabel => 'Top technician names';

  @override
  String importProgressFile(int current, int total, String fileName) {
    return 'Importing $current/$total: $fileName';
  }

  @override
  String importInstalledBreakdown(int split, int window, int freestanding) {
    return 'Installed S/W/F: $split/$window/$freestanding';
  }

  @override
  String importUninstallBreakdown(
    int split,
    int window,
    int freestanding,
    int old,
  ) {
    return 'Uninstall S/W/F/O: $split/$window/$freestanding/$old';
  }

  @override
  String get importSheetRowLimitExceeded =>
      'Row limit exceeded; only the first 5000 rows were processed.';

  @override
  String get importTargetTechnician => 'Target technician';

  @override
  String get importTargetTechnicianRequired =>
      'Select the technician who should receive the imported history.';

  @override
  String get importTechnicianKeyword => 'Source technician filter';

  @override
  String get importTechnicianKeywordHint => 'Example: name, email, or uid';

  @override
  String get importTechnicianKeywordHelp =>
      'Only rows whose technician name, email, or ID matches this text will be imported.';

  @override
  String get importKeywordRequired =>
      'Please filter by technician keyword to prevent accidental bulk upload.';

  @override
  String get importBundledTemplates => 'Import bundled history templates';

  @override
  String get importBundledTemplatesMissing =>
      'No bundled history templates were found in the app package.';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get flushDatabase => 'Flush Database';

  @override
  String get flushDatabaseSubtitle => 'Reset all data to a clean state';

  @override
  String get normalizeStoredInvoices => 'Normalize Legacy Invoices';

  @override
  String get normalizeStoredInvoicesSubtitle =>
      'Remove stored company prefixes from invoices and rebuild invoice ledgers without a full flush.';

  @override
  String get normalizeStoredInvoicesDescription =>
      'This one-time migration rewrites stored job invoice numbers, refreshes shared group keys, and rebuilds invoice claims without deleting operational data.';

  @override
  String get normalizeStoredInvoicesAction => 'Run Migration';

  @override
  String normalizeStoredInvoicesSuccess(int jobs, int conflicts) {
    return 'Invoice migration finished. Updated $jobs jobs and flagged $conflicts conflicting invoice groups.';
  }

  @override
  String get flushScope => 'Flush Scope';

  @override
  String get flushAllData => 'All Data';

  @override
  String get flushOnlySelectedTechnician =>
      'Only selected technician data (jobs and in/out) will be flushed.';

  @override
  String get flushStep1Title => 'Step 1 of 2 — Confirm Intent';

  @override
  String get flushStep2Title => 'Step 2 of 2 — Final Confirmation';

  @override
  String get flushWarningIntro =>
      'You are about to permanently delete the following data:';

  @override
  String get flushItemJobs => 'All job records';

  @override
  String get flushItemExpenses => 'All expense & earning records';

  @override
  String get flushItemCompanies => 'All company records';

  @override
  String get flushItemUsers => 'All non-admin user accounts';

  @override
  String get flushItemUsersOptional => 'Non-admin user accounts (optional)';

  @override
  String get flushAdminKept => 'Admin accounts will be preserved.';

  @override
  String flushProceedIn(int seconds) {
    return 'Proceed in ${seconds}s';
  }

  @override
  String get flushProceed => 'Proceed to Step 2';

  @override
  String get flushEnterPassword => 'Enter your admin password to confirm';

  @override
  String flushConfirmIn(int seconds) {
    return 'Confirm in ${seconds}s';
  }

  @override
  String get flushConfirm => 'Flush Database';

  @override
  String get flushInProgress => 'Flushing database…';

  @override
  String get flushDeleteUsersOption => 'Also delete technician/user accounts';

  @override
  String get flushDeleteUsersHelp =>
      'If enabled, all non-admin user documents are permanently deleted.';

  @override
  String get flushDeleteUsersEnabledWarning =>
      'User deletion is enabled. All technician and other non-admin user records will be permanently removed during this flush.';

  @override
  String get flushSuccess => 'Database flushed. Starting fresh.';

  @override
  String get flushFailed => 'Flush failed. Check connection and try again.';

  @override
  String get flushRequiresInternetMessage =>
      'A live internet connection is required to verify your admin password and flush data safely.';

  @override
  String get flushPhaseVerifyingPassword => 'Verifying admin password...';

  @override
  String get flushPhaseCheckingConnection => 'Checking live connection...';

  @override
  String get flushPhaseScanningData => 'Scanning affected records...';

  @override
  String get flushPhaseDeletingOperationalData =>
      'Deleting jobs and operational records...';

  @override
  String get flushPhaseDeletingDerivedData =>
      'Deleting shared aggregates and invoice ledgers...';

  @override
  String get flushPhaseDeletingCompanies => 'Deleting companies...';

  @override
  String get flushPhaseArchivingUsers => 'Archiving non-admin users...';

  @override
  String get flushPhaseRebuildingDerivedData =>
      'Rebuilding invoice ledgers and shared totals...';

  @override
  String get flushPhaseClearingLocalCache => 'Scheduling local cache reset...';

  @override
  String get flushPhaseRefreshingAppData => 'Refreshing app data...';

  @override
  String flushProgressStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get flushWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get currentBuild => 'Current build';

  @override
  String get updateRequiredTitle => 'Update Required';

  @override
  String updateRequiredBody(int build) {
    return 'Your app build ($build) is no longer supported. Please install the latest APK to continue.';
  }

  @override
  String get updateRequiredLoading => 'Checking app version...';

  @override
  String get iUpdatedRefresh => 'I Updated - Refresh';

  @override
  String get catSplitAc => 'Split AC';

  @override
  String get catWindowAc => 'Window AC';

  @override
  String get catFreestandingAc => 'Freestanding AC';

  @override
  String get catCassetteAc => 'Cassette AC';

  @override
  String get catUninstallOldAc => 'Uninstallation (Old AC)';

  @override
  String get catFood => 'Food';

  @override
  String get catPetrol => 'Petrol';

  @override
  String get catPipes => 'Pipes';

  @override
  String get catTools => 'Tools';

  @override
  String get catTape => 'Tape';

  @override
  String get catInsulation => 'Insulation';

  @override
  String get catGas => 'Gas';

  @override
  String get catOtherConsumables => 'Other Consumables';

  @override
  String get catHouseRent => 'House Rent';

  @override
  String get catOther => 'Other';

  @override
  String get catInstalledBracket => 'Installed Bracket';

  @override
  String get catInstalledExtraPipe => 'Installed Extra Pipe';

  @override
  String get catOldAcRemoval => 'Old AC Removal';

  @override
  String get catOldAcInstallation => 'Old AC Installation';

  @override
  String get catSoldOldAc => 'Sold Old AC';

  @override
  String get catSoldScrap => 'Sold Scrap';

  @override
  String get catBreadRoti => 'Bread/Roti';

  @override
  String get catMeat => 'Meat';

  @override
  String get catChicken => 'Chicken';

  @override
  String get catTea => 'Tea';

  @override
  String get catSugar => 'Sugar';

  @override
  String get catRice => 'Rice';

  @override
  String get catVegetables => 'Vegetables';

  @override
  String get catCookingOil => 'Cooking Oil';

  @override
  String get catMilk => 'Milk';

  @override
  String get catSpices => 'Spices';

  @override
  String get catOtherGroceries => 'Other Groceries';

  @override
  String get passwordResetConfirmTitle => 'Reset Password?';

  @override
  String passwordResetConfirmBody(String email) {
    return 'A reset link will be sent to $email. Continue?';
  }

  @override
  String get passwordResetEmailSentTitle => 'Email Sent';

  @override
  String passwordResetEmailSentBody(String email) {
    return 'A reset link has been sent to $email.\n\nPlease check your inbox. If you don\'t see it within a few minutes, check your Spam or Junk folder.\n\nThe link expires in 1 hour.';
  }

  @override
  String get passwordResetNetworkError =>
      'No internet connection. Please connect and try again.';

  @override
  String get passwordResetRateLimit =>
      'Too many reset requests. Please wait a few minutes and try again.';

  @override
  String get capsLockWarning =>
      'Caps Lock is on. Passwords are case-sensitive.';

  @override
  String get passwordManagerHint =>
      'Your browser or device can save this password after sign in.';

  @override
  String get send => 'Send';

  @override
  String get changeEmail => 'Change Email';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get emailUpdated => 'Email updated successfully.';

  @override
  String get emailChangeVerificationSent =>
      'Verification email sent. Open your inbox to confirm new email.';

  @override
  String get passwordUpdated => 'Password updated successfully.';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get entriesSaved => 'Entries saved successfully.';

  @override
  String get entryDeleted => 'Entry deleted successfully.';

  @override
  String get entryUpdated => 'Entry updated successfully.';

  @override
  String get selectPdfDateRange => 'Select PDF date range';

  @override
  String get pdfDateRangeMonthOnly =>
      'Please select a date range within the selected month.';

  @override
  String get exportTodayCompanyInvoices => 'Export today\'s company invoices';

  @override
  String get noInvoicesToday => 'No invoices found for today.';

  @override
  String get couldNotOpenSummary =>
      'Could not open summary screen. Please try again.';

  @override
  String get userDataLoading => 'Please wait — loading your profile...';

  @override
  String get couldNotSubmitJob =>
      'Could not submit. Please sign out and sign back in.';

  @override
  String get loadingFailed => 'Failed to load. Please try again.';

  @override
  String get invoiceSopTitle => 'Invoice SOP Flow';

  @override
  String get excelStyleEntry => 'Excel Style Entry';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get invoiceSopStep1 => '1) Select date and company';

  @override
  String get invoiceSopStep2 => '2) Add invoice, client and contact';

  @override
  String get invoiceSopStep3 => '3) Add AC units and optional charges';

  @override
  String get invoiceSopStep4 => '4) Submit for admin approval';

  @override
  String get jobsDetailsReport => 'Jobs Details Report';

  @override
  String get earningsReport => 'Earnings Report';

  @override
  String get expensesDetailedReport => 'Expenses Report (Work & Home)';

  @override
  String get exportJobsAsExcel => 'Export Jobs as Excel';

  @override
  String get exportJobsAsPdf => 'Export Jobs as PDF';

  @override
  String get exportEarningsAsExcel => 'Export Earnings as Excel';

  @override
  String get exportEarningsAsPdf => 'Export Earnings as PDF';

  @override
  String get exportExpensesAsExcel => 'Export Expenses as Excel';

  @override
  String get exportExpensesAsPdf => 'Export Expenses as PDF';

  @override
  String get selectReportType => 'Select Report Type';

  @override
  String get jobsReportTitle => 'Jobs Report';

  @override
  String get earningsReportTitle => 'Earnings Report';

  @override
  String get expensesReportTitle => 'Expenses Report';

  @override
  String get todayEarned => 'Today\'s Earnings';

  @override
  String get monthEarned => 'Month\'s Earnings';

  @override
  String get todayWorkExpenses => 'Today\'s Work Expenses';

  @override
  String get todayHomeExpenses => 'Today\'s Home Expenses';

  @override
  String get todayTotalExpenses => 'Today\'s Total Expenses';

  @override
  String get monthWorkExpenses => 'Month\'s Work Expenses';

  @override
  String get monthHomeExpenses => 'Month\'s Home Expenses';

  @override
  String get monthTotalExpenses => 'Month\'s Total Expenses';

  @override
  String get workExpensesLabel => 'Work Expenses';

  @override
  String get homeExpensesLabel => 'Home Expenses';

  @override
  String get bracketLabel => 'Bracket';

  @override
  String get deliveryLabel => 'Delivery';

  @override
  String get acUnitsLabel => 'AC Units';

  @override
  String get unitQty => 'Qty';

  @override
  String get dateLabel => 'Date';

  @override
  String get invoiceLabel => 'Invoice';

  @override
  String get technicianLabel => 'Technician';

  @override
  String get technicianUidLabel => 'Technician UID';

  @override
  String get approverUidLabel => 'Approver UID';

  @override
  String get sharedGroup => 'Shared Group';

  @override
  String get approvedSharedInstalls => 'Approved Shared Installs';

  @override
  String get contactLabel => 'Contact';

  @override
  String get statusLabel => 'Status';

  @override
  String get notesLabel => 'Notes';

  @override
  String get amountLabel => 'Amount';

  @override
  String get categoryLabel => 'Category';

  @override
  String get itemLabel => 'Item';

  @override
  String get totalLabel => 'Total';

  @override
  String get noEarnings => 'No earnings';

  @override
  String get noWorkExpenses => 'No work expenses';

  @override
  String get noHomeExpenses => 'No home expenses';

  @override
  String get generateReports => 'Generate Reports';

  @override
  String get acInstallations => 'AC Installations';

  @override
  String get logAcInstallations => 'Log AC Installations';

  @override
  String get noInstallationsToday => 'No installations logged today';

  @override
  String get noManualInstallLogsToday =>
      'No manual AC installation logs were added today.';

  @override
  String get manualInstallLogDescription =>
      'This screen tracks manual AC-install log entries. Invoice and shared-install jobs are counted separately above.';

  @override
  String get jobInstallationsToday => 'Install jobs today';

  @override
  String get manualLogsToday => 'Manual logs today';

  @override
  String get entryDetails => 'Entry Details';

  @override
  String get totalOnInvoice => 'Total on Invoice';

  @override
  String get myShare => 'My Share';

  @override
  String get splitAcLabel => 'Split AC';

  @override
  String get windowAcLabel => 'Window AC';

  @override
  String get freestandingAcLabel => 'Freestanding AC';

  @override
  String get installationsLogged => 'Installations logged successfully.';

  @override
  String get deleteInstallRecord => 'Delete installation record?';

  @override
  String get unitsLabel => 'units';

  @override
  String invoiceUnitsLabel(int total) {
    return 'Invoice: $total units';
  }

  @override
  String myShareUnitsLabel(int share) {
    return 'My share: $share units';
  }

  @override
  String get shareMustNotExceedTotal =>
      'My share cannot exceed total on invoice.';

  @override
  String get enterAtLeastOneUnit => 'Enter at least one AC unit quantity.';

  @override
  String get acInstallNote => 'Note (optional)';

  @override
  String get companyLogo => 'Company Logo';

  @override
  String get adminAboutBuiltBy => 'Built and supported for AC Techs.';

  @override
  String get developedByMuhammadImran => 'Developed By Muhammad Imran';

  @override
  String get tapToUploadLogo => 'Tap to upload logo';

  @override
  String get uploadLogo => 'Upload Logo';

  @override
  String get replaceLogo => 'Replace Logo';

  @override
  String get logoTooLarge =>
      'Logo is too large. Please use a smaller image to keep Firestore storage clean.';

  @override
  String get removeLogo => 'Remove Logo';

  @override
  String get enterValidQuantity => 'Enter a valid quantity.';

  @override
  String get invoiceSettlements => 'Invoice Settlements';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get paymentInbox => 'Payment Inbox';

  @override
  String get awaitingTechnicianConfirmation =>
      'Awaiting technician confirmation';

  @override
  String get correctionRequired => 'Correction required';

  @override
  String get paymentConfirmed => 'Payment confirmed';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get paymentDisputed => 'Payment disputed';

  @override
  String get paidOn => 'Paid on';

  @override
  String get confirmPaymentReceived => 'Confirm payment received';

  @override
  String get rejectPayment => 'Reject payment';

  @override
  String get resubmitPayment => 'Resubmit payment';

  @override
  String get settlementAdminNote => 'Admin note for technician';

  @override
  String get settlementTechnicianComment => 'Add a payment comment';

  @override
  String get settlementBatch => 'Settlement batch';

  @override
  String get paymentMarkedForConfirmation =>
      'Payment marked for technician confirmation.';

  @override
  String get paymentConfirmedSuccess => 'Payment confirmed successfully.';

  @override
  String get paymentRejectedForCorrection =>
      'Payment sent back for one correction round.';

  @override
  String get paymentResubmitted => 'Payment resubmitted to technician.';

  @override
  String get selectJobsFirst => 'Select at least one job first.';

  @override
  String get selectSameTechnicianJobs =>
      'Select jobs from the same technician only.';

  @override
  String get selectSingleBatchToResubmit =>
      'Select jobs from a single settlement batch to resubmit.';

  @override
  String get filterByDateRange => 'Filter by date range';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get sharedTeamMembers => 'Team Members';

  @override
  String get addTeamMember => 'Add Team Member';

  @override
  String get removeTeamMember => 'Remove';

  @override
  String sharedTeamCount(int count) {
    return 'Team size: $count';
  }

  @override
  String get notTeamMember =>
      'You are not enrolled in this shared invoice team. Ask the first submitter to add you.';

  @override
  String get yourSharedTeams => 'Your Shared Teams';

  @override
  String get pendingSharedInstalls => 'Pending Shared Installs';

  @override
  String get tapToAddYourShare => 'Tap to insert your share';

  @override
  String get addYourShare => 'Add Your Share';

  @override
  String get preFilledFromSharedInstall =>
      'Invoice data pre-filled from your team’s shared install. Enter only your unit share.';

  @override
  String get teamJobPending => 'Pending your contribution';

  @override
  String get teamJobSubmitted => 'Your contribution submitted';

  @override
  String get undo => 'Undo';

  @override
  String get requestEditJob => 'Request Edit';

  @override
  String get requestEditConfirmTitle => 'Request Edit?';

  @override
  String get requestEditConfirmBody =>
      'This job will return to pending and need admin re-approval before settlement.';

  @override
  String get jobEditRequested =>
      'Edit request submitted. Awaiting admin re-approval.';

  @override
  String get resubmittedBadge => 'Re-submitted';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get permanentlyDeleteJob => 'Permanently Delete Job';

  @override
  String get permanentlyDeleteJobConfirm =>
      'Delete this job permanently? This cannot be undone.';

  @override
  String get permanentlyDeleteJobSharedWarning =>
      'This is a shared install. Aggregate counters will NOT be adjusted automatically. Notify admin if totals need correction.';

  @override
  String get jobDeletedSuccess => 'Job permanently deleted.';

  @override
  String get reconcileInvoices => 'Reconcile Invoices';

  @override
  String get uploadCompanyReport => 'Upload Company Report';

  @override
  String get matchedInvoices => 'Matched';

  @override
  String get unmatchedInvoices => 'Not Found';

  @override
  String get alreadyPaidInvoices => 'Already Paid';

  @override
  String get reconcileMarkedSuccess => 'Matched invoices marked as paid.';

  @override
  String get settlements => 'Settlements';

  @override
  String get importData => 'Import Data';

  @override
  String get reconciliation => 'Reconciliation';

  @override
  String get staleSharedInstalls => 'Stale Shared Installs';

  @override
  String staleSharedInstallsDescription(int count) {
    return '$count shared install(s) older than 7 days with incomplete contributions.';
  }

  @override
  String get cleanUpStale => 'Clean Up';

  @override
  String get cleanUpConfirmTitle => 'Archive Stale Installs?';

  @override
  String cleanUpConfirmMessage(int count) {
    return 'This will archive $count stale shared install(s) and their associated jobs. This action can be reversed by an admin.';
  }

  @override
  String get staleCleanUpSuccess => 'Stale installs archived successfully.';
}
