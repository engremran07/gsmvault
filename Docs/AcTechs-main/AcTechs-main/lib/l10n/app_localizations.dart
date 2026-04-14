import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AC Techs'**
  String get appName;

  /// No description provided for @techMgmtSystem.
  ///
  /// In en, this message translates to:
  /// **'Technician Management System'**
  String get techMgmtSystem;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get enterValidPhone;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @minChars.
  ///
  /// In en, this message translates to:
  /// **'Min {count} characters'**
  String minChars(int count);

  /// No description provided for @technician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technician;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// No description provided for @sharedInstallApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Shared Install Approvals'**
  String get sharedInstallApprovalRequired;

  /// No description provided for @enforceMinimumBuild.
  ///
  /// In en, this message translates to:
  /// **'Enforce Minimum Build'**
  String get enforceMinimumBuild;

  /// No description provided for @minimumSupportedBuild.
  ///
  /// In en, this message translates to:
  /// **'Minimum Supported Build'**
  String get minimumSupportedBuild;

  /// No description provided for @lockRecordsBefore.
  ///
  /// In en, this message translates to:
  /// **'Lock Records Before'**
  String get lockRecordsBefore;

  /// No description provided for @noPeriodLock.
  ///
  /// In en, this message translates to:
  /// **'No period lock is active.'**
  String get noPeriodLock;

  /// No description provided for @clearPeriodLock.
  ///
  /// In en, this message translates to:
  /// **'Clear Period Lock'**
  String get clearPeriodLock;

  /// No description provided for @lockedPeriodDescription.
  ///
  /// In en, this message translates to:
  /// **'Older records cannot be created, edited, approved, rejected, or deleted.'**
  String get lockedPeriodDescription;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for Approval'**
  String get submitForApproval;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @clientNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Client Name (optional)'**
  String get clientNameOptional;

  /// No description provided for @clientContact.
  ///
  /// In en, this message translates to:
  /// **'Client Contact'**
  String get clientContact;

  /// No description provided for @clientPhone.
  ///
  /// In en, this message translates to:
  /// **'Client Phone Number'**
  String get clientPhone;

  /// No description provided for @acUnits.
  ///
  /// In en, this message translates to:
  /// **'AC Units'**
  String get acUnits;

  /// No description provided for @addUnit.
  ///
  /// In en, this message translates to:
  /// **'Add Unit'**
  String get addUnit;

  /// No description provided for @unitType.
  ///
  /// In en, this message translates to:
  /// **'Unit Type'**
  String get unitType;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @expenseAmount.
  ///
  /// In en, this message translates to:
  /// **'Expense Amount'**
  String get expenseAmount;

  /// No description provided for @expenseNote.
  ///
  /// In en, this message translates to:
  /// **'Expense Note'**
  String get expenseNote;

  /// No description provided for @adminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin Note'**
  String get adminNote;

  /// No description provided for @rejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get rejectReason;

  /// No description provided for @noJobsYet.
  ///
  /// In en, this message translates to:
  /// **'No jobs submitted yet'**
  String get noJobsYet;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @noJobsToday.
  ///
  /// In en, this message translates to:
  /// **'No jobs submitted today'**
  String get noJobsToday;

  /// No description provided for @noMatchingJobs.
  ///
  /// In en, this message translates to:
  /// **'No matching jobs'**
  String get noMatchingJobs;

  /// No description provided for @noApprovals.
  ///
  /// In en, this message translates to:
  /// **'No pending approvals'**
  String get noApprovals;

  /// No description provided for @noMatchingApprovals.
  ///
  /// In en, this message translates to:
  /// **'No matching approvals'**
  String get noMatchingApprovals;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @todaysJobs.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Jobs'**
  String get todaysJobs;

  /// No description provided for @totalJobs.
  ///
  /// In en, this message translates to:
  /// **'Total Jobs'**
  String get totalJobs;

  /// No description provided for @pendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals'**
  String get pendingApprovals;

  /// No description provided for @approvedJobs.
  ///
  /// In en, this message translates to:
  /// **'Approved Jobs'**
  String get approvedJobs;

  /// No description provided for @rejectedJobs.
  ///
  /// In en, this message translates to:
  /// **'Rejected Jobs'**
  String get rejectedJobs;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team Members'**
  String get teamMembers;

  /// No description provided for @activeMembers.
  ///
  /// In en, this message translates to:
  /// **'Active Members'**
  String get activeMembers;

  /// No description provided for @jobSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Job submitted successfully! Waiting for admin approval.'**
  String get jobSubmitted;

  /// No description provided for @jobSaved.
  ///
  /// In en, this message translates to:
  /// **'Entry added successfully.'**
  String get jobSaved;

  /// No description provided for @jobApproved.
  ///
  /// In en, this message translates to:
  /// **'Job approved!'**
  String get jobApproved;

  /// No description provided for @jobRejected.
  ///
  /// In en, this message translates to:
  /// **'Job returned with your feedback.'**
  String get jobRejected;

  /// No description provided for @couldNotApprove.
  ///
  /// In en, this message translates to:
  /// **'Could not approve. Please try again.'**
  String get couldNotApprove;

  /// No description provided for @couldNotReject.
  ///
  /// In en, this message translates to:
  /// **'Could not reject. Please try again.'**
  String get couldNotReject;

  /// No description provided for @bulkApproveSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs approved!'**
  String bulkApproveSuccess(int count);

  /// No description provided for @bulkRejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs rejected.'**
  String bulkRejectSuccess(int count);

  /// No description provided for @bulkApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Bulk approve failed. Try again.'**
  String get bulkApproveFailed;

  /// No description provided for @bulkRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Bulk reject failed. Try again.'**
  String get bulkRejectFailed;

  /// No description provided for @rejectSelectedJobs.
  ///
  /// In en, this message translates to:
  /// **'Reject Selected Jobs'**
  String get rejectSelectedJobs;

  /// No description provided for @rejectAll.
  ///
  /// In en, this message translates to:
  /// **'Reject All'**
  String get rejectAll;

  /// No description provided for @rejectJob.
  ///
  /// In en, this message translates to:
  /// **'Reject Job'**
  String get rejectJob;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export ready! {count} jobs exported to Excel.'**
  String exportSuccess(int count);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the export file. Please try again.'**
  String get exportFailed;

  /// No description provided for @noJobsForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No jobs found for this period. Try a different date range.'**
  String get noJobsForPeriod;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportExcel;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @urdu.
  ///
  /// In en, this message translates to:
  /// **'اردو'**
  String get urdu;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit the app.'**
  String get pressBackAgainToExit;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Leave this page and lose them?'**
  String get discardChangesMessage;

  /// No description provided for @leavePage.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leavePage;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate and share PDF reports'**
  String get reportsSubtitle;

  /// No description provided for @dailyInOutReport.
  ///
  /// In en, this message translates to:
  /// **'Daily In/Out Report'**
  String get dailyInOutReport;

  /// No description provided for @dailyInOutReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Today\'s earnings and expenses summary'**
  String get dailyInOutReportDesc;

  /// No description provided for @monthlyInOutReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly In/Out Report'**
  String get monthlyInOutReport;

  /// No description provided for @monthlyInOutReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Monthly earnings and expenses overview'**
  String get monthlyInOutReportDesc;

  /// No description provided for @acInstallsReport.
  ///
  /// In en, this message translates to:
  /// **'AC Installations Report'**
  String get acInstallsReport;

  /// No description provided for @acInstallsReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Installed air conditioners by date range'**
  String get acInstallsReportDesc;

  /// No description provided for @sharedInstallReport.
  ///
  /// In en, this message translates to:
  /// **'Shared Install Report'**
  String get sharedInstallReport;

  /// No description provided for @sharedInstallReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Team shared installation details'**
  String get sharedInstallReportDesc;

  /// No description provided for @paymentSettlementReport.
  ///
  /// In en, this message translates to:
  /// **'Payment Settlement Report'**
  String get paymentSettlementReport;

  /// No description provided for @paymentSettlementReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Summary of received job payments'**
  String get paymentSettlementReportDesc;

  /// No description provided for @jobsReport.
  ///
  /// In en, this message translates to:
  /// **'Jobs Report'**
  String get jobsReport;

  /// No description provided for @jobsReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed job history with filters'**
  String get jobsReportDesc;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @noDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data found for the selected period.'**
  String get noDataForPeriod;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @offlineBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. You are viewing cached data until the connection returns.'**
  String get offlineBannerMessage;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @jobHistory.
  ///
  /// In en, this message translates to:
  /// **'Job History'**
  String get jobHistory;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// No description provided for @submitJob.
  ///
  /// In en, this message translates to:
  /// **'Submit Job'**
  String get submitJob;

  /// No description provided for @submitInvoice.
  ///
  /// In en, this message translates to:
  /// **'Submit Invoice'**
  String get submitInvoice;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// No description provided for @invoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoiceDetails;

  /// No description provided for @acServices.
  ///
  /// In en, this message translates to:
  /// **'AC Services'**
  String get acServices;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service type'**
  String get serviceType;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @additionalCharges.
  ///
  /// In en, this message translates to:
  /// **'Additional Charges'**
  String get additionalCharges;

  /// No description provided for @acOutdoorBracket.
  ///
  /// In en, this message translates to:
  /// **'Outdoor Bracket'**
  String get acOutdoorBracket;

  /// No description provided for @bracketSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bracket for outdoor unit mounting'**
  String get bracketSubtitle;

  /// No description provided for @bracketCharge.
  ///
  /// In en, this message translates to:
  /// **'Bracket charge (SAR)'**
  String get bracketCharge;

  /// No description provided for @deliveryCharge.
  ///
  /// In en, this message translates to:
  /// **'Delivery Charge'**
  String get deliveryCharge;

  /// No description provided for @deliverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customer location >50 km away'**
  String get deliverySubtitle;

  /// No description provided for @deliveryChargeAmount.
  ///
  /// In en, this message translates to:
  /// **'Delivery charge (SAR)'**
  String get deliveryChargeAmount;

  /// No description provided for @locationNote.
  ///
  /// In en, this message translates to:
  /// **'Location / note (optional)'**
  String get locationNote;

  /// No description provided for @addServiceFirst.
  ///
  /// In en, this message translates to:
  /// **'Add at least one AC service before submitting.'**
  String get addServiceFirst;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmImport.
  ///
  /// In en, this message translates to:
  /// **'Confirm import'**
  String get confirmImport;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @totalUnits.
  ///
  /// In en, this message translates to:
  /// **'Total Units'**
  String get totalUnits;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @themeAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow system dark/light setting'**
  String get themeAutoDesc;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeDarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Arctic dark — easy on the eyes'**
  String get themeDarkDesc;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean and bright for outdoor use'**
  String get themeLightDesc;

  /// No description provided for @themeHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High Contrast'**
  String get themeHighContrast;

  /// No description provided for @themeHighContrastDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum readability, bold borders'**
  String get themeHighContrastDesc;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @companyBranding.
  ///
  /// In en, this message translates to:
  /// **'Company Branding'**
  String get companyBranding;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @pakistan.
  ///
  /// In en, this message translates to:
  /// **'Pakistan'**
  String get pakistan;

  /// No description provided for @saudiArabia.
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get saudiArabia;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @noTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'No team members yet'**
  String get noTeamMembers;

  /// No description provided for @noMatchingMembers.
  ///
  /// In en, this message translates to:
  /// **'No matching team members'**
  String get noMatchingMembers;

  /// No description provided for @searchByNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get searchByNameOrEmail;

  /// No description provided for @addTechnician.
  ///
  /// In en, this message translates to:
  /// **'Add Technician'**
  String get addTechnician;

  /// No description provided for @editTechnician.
  ///
  /// In en, this message translates to:
  /// **'Edit Technician'**
  String get editTechnician;

  /// No description provided for @deleteTechnician.
  ///
  /// In en, this message translates to:
  /// **'Delete Technician'**
  String get deleteTechnician;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String deleteConfirm(String name);

  /// No description provided for @deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteWarning;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @userCreated.
  ///
  /// In en, this message translates to:
  /// **'User created successfully!'**
  String get userCreated;

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully!'**
  String get userUpdated;

  /// No description provided for @userDeleted.
  ///
  /// In en, this message translates to:
  /// **'User archived successfully!'**
  String get userDeleted;

  /// No description provided for @usersActivated.
  ///
  /// In en, this message translates to:
  /// **'Users activated'**
  String get usersActivated;

  /// No description provided for @usersDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Users deactivated'**
  String get usersDeactivated;

  /// No description provided for @bulkActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate Selected'**
  String get bulkActivate;

  /// No description provided for @bulkDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Selected'**
  String get bulkDeactivate;

  /// No description provided for @bulkDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get bulkDelete;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @inOut.
  ///
  /// In en, this message translates to:
  /// **'In / Out'**
  String get inOut;

  /// No description provided for @monthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get monthlySummary;

  /// No description provided for @todaysInOut.
  ///
  /// In en, this message translates to:
  /// **'Today\'s In / Out'**
  String get todaysInOut;

  /// No description provided for @todaysEntries.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Entries'**
  String get todaysEntries;

  /// No description provided for @noEntriesToday.
  ///
  /// In en, this message translates to:
  /// **'No entries today'**
  String get noEntriesToday;

  /// No description provided for @addFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Add your first IN or OUT above'**
  String get addFirstEntry;

  /// No description provided for @inEarned.
  ///
  /// In en, this message translates to:
  /// **'IN  (Earned)'**
  String get inEarned;

  /// No description provided for @outSpent.
  ///
  /// In en, this message translates to:
  /// **'OUT  (Spent)'**
  String get outSpent;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @amountSar.
  ///
  /// In en, this message translates to:
  /// **'Amount (SAR)'**
  String get amountSar;

  /// No description provided for @amountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero.'**
  String get amountMustBePositive;

  /// No description provided for @remarksOptional.
  ///
  /// In en, this message translates to:
  /// **'Remarks (optional)'**
  String get remarksOptional;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @addEarning.
  ///
  /// In en, this message translates to:
  /// **'Add Earning'**
  String get addEarning;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount.'**
  String get enterAmount;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive amount.'**
  String get enterValidAmount;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'IN'**
  String get earned;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'OUT'**
  String get spent;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get loss;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get newestFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get oldestFirst;

  /// No description provided for @copyInvoice.
  ///
  /// In en, this message translates to:
  /// **'Copy Invoice #'**
  String get copyInvoice;

  /// No description provided for @viewInHistory.
  ///
  /// In en, this message translates to:
  /// **'View in History'**
  String get viewInHistory;

  /// No description provided for @invoiceCopied.
  ///
  /// In en, this message translates to:
  /// **'Invoice number copied!'**
  String get invoiceCopied;

  /// No description provided for @newJob.
  ///
  /// In en, this message translates to:
  /// **'New Job'**
  String get newJob;

  /// No description provided for @submitAJob.
  ///
  /// In en, this message translates to:
  /// **'Submit a Job'**
  String get submitAJob;

  /// No description provided for @sharedInstall.
  ///
  /// In en, this message translates to:
  /// **'Shared Install'**
  String get sharedInstall;

  /// No description provided for @sharedInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Enable when one invoice is split across multiple technicians.'**
  String get sharedInstallHint;

  /// No description provided for @sharedInstallMixHint.
  ///
  /// In en, this message translates to:
  /// **'Enter invoice totals by type. Technicians will enter their own unit share manually. Delivery is split equally only.'**
  String get sharedInstallMixHint;

  /// No description provided for @flushOperationGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Which operation do you need?'**
  String get flushOperationGuidanceTitle;

  /// No description provided for @flushOperationMigrationNote.
  ///
  /// In en, this message translates to:
  /// **'One-time migration or historical import keeps existing data and is the safe choice for first-time Excel onboarding.'**
  String get flushOperationMigrationNote;

  /// No description provided for @flushOperationReimportNote.
  ///
  /// In en, this message translates to:
  /// **'Flush plus re-import deletes operational data first. Use it only for a full reset or when you intentionally need to rebuild from scratch.'**
  String get flushOperationReimportNote;

  /// No description provided for @sharedInvoiceTotalUnits.
  ///
  /// In en, this message translates to:
  /// **'Invoice Total Units'**
  String get sharedInvoiceTotalUnits;

  /// No description provided for @sharedInstallLimitError.
  ///
  /// In en, this message translates to:
  /// **'Your entered units exceed the invoice total units.'**
  String get sharedInstallLimitError;

  /// No description provided for @sharedInvoiceSplitUnits.
  ///
  /// In en, this message translates to:
  /// **'Invoice Split Units'**
  String get sharedInvoiceSplitUnits;

  /// No description provided for @sharedInvoiceWindowUnits.
  ///
  /// In en, this message translates to:
  /// **'Invoice Window Units'**
  String get sharedInvoiceWindowUnits;

  /// No description provided for @sharedInvoiceFreestandingUnits.
  ///
  /// In en, this message translates to:
  /// **'Invoice Standing Units'**
  String get sharedInvoiceFreestandingUnits;

  /// No description provided for @sharedTeamSize.
  ///
  /// In en, this message translates to:
  /// **'Shared Team Size'**
  String get sharedTeamSize;

  /// No description provided for @sharedInvoiceDeliveryAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Delivery Charge (Invoice)'**
  String get sharedInvoiceDeliveryAmount;

  /// No description provided for @sharedDeliverySplitHint.
  ///
  /// In en, this message translates to:
  /// **'This delivery amount will be split equally across the shared team.'**
  String get sharedDeliverySplitHint;

  /// No description provided for @sharedDeliverySplitInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the shared team size so delivery charges can be split equally.'**
  String get sharedDeliverySplitInvalid;

  /// No description provided for @invoiceConflictNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'This invoice also exists in another company. Review before approval.'**
  String get invoiceConflictNeedsReview;

  /// No description provided for @invoiceConflictCompaniesLabel.
  ///
  /// In en, this message translates to:
  /// **'Conflicting companies: {companies}'**
  String invoiceConflictCompaniesLabel(String companies);

  /// No description provided for @splits.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get splits;

  /// No description provided for @windowAc.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get windowAc;

  /// No description provided for @standing.
  ///
  /// In en, this message translates to:
  /// **'Standing'**
  String get standing;

  /// No description provided for @cassette.
  ///
  /// In en, this message translates to:
  /// **'Cassette'**
  String get cassette;

  /// No description provided for @uninstalls.
  ///
  /// In en, this message translates to:
  /// **'Uninstalls'**
  String get uninstalls;

  /// No description provided for @uninstallSplit.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Split'**
  String get uninstallSplit;

  /// No description provided for @uninstallWindow.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Window'**
  String get uninstallWindow;

  /// No description provided for @uninstallStanding.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Standing'**
  String get uninstallStanding;

  /// No description provided for @jobStatus.
  ///
  /// In en, this message translates to:
  /// **'Job Status'**
  String get jobStatus;

  /// No description provided for @jobsPerTechnician.
  ///
  /// In en, this message translates to:
  /// **'Jobs per Technician'**
  String get jobsPerTechnician;

  /// No description provided for @technicians.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get technicians;

  /// No description provided for @recentPending.
  ///
  /// In en, this message translates to:
  /// **'Recent Pending'**
  String get recentPending;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @expensesSar.
  ///
  /// In en, this message translates to:
  /// **'Expenses (SAR)'**
  String get expensesSar;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @yourShare.
  ///
  /// In en, this message translates to:
  /// **'Your Share'**
  String get yourShare;

  /// No description provided for @installations.
  ///
  /// In en, this message translates to:
  /// **'Installations'**
  String get installations;

  /// No description provided for @earningsIn.
  ///
  /// In en, this message translates to:
  /// **'Earnings (IN)'**
  String get earningsIn;

  /// No description provided for @expensesOut.
  ///
  /// In en, this message translates to:
  /// **'Expenses (OUT)'**
  String get expensesOut;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @earningsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Earnings Breakdown'**
  String get earningsBreakdown;

  /// No description provided for @expensesBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expenses Breakdown'**
  String get expensesBreakdown;

  /// No description provided for @installationsByType.
  ///
  /// In en, this message translates to:
  /// **'Installations by Type'**
  String get installationsByType;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @searchByClientOrInvoice.
  ///
  /// In en, this message translates to:
  /// **'Search by client or invoice...'**
  String get searchByClientOrInvoice;

  /// No description provided for @searchByTechClientInvoice.
  ///
  /// In en, this message translates to:
  /// **'Search by tech, client, or invoice...'**
  String get searchByTechClientInvoice;

  /// No description provided for @exportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// No description provided for @nUnits.
  ///
  /// In en, this message translates to:
  /// **'{count} units'**
  String nUnits(int count);

  /// No description provided for @activeOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{active} / {total} active'**
  String activeOfTotal(int active, int total);

  /// No description provided for @exportToPdf.
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get exportToPdf;

  /// No description provided for @exportToExcel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcel;

  /// No description provided for @reportPreset.
  ///
  /// In en, this message translates to:
  /// **'Report Preset'**
  String get reportPreset;

  /// No description provided for @byTechnician.
  ///
  /// In en, this message translates to:
  /// **'By Technician'**
  String get byTechnician;

  /// No description provided for @uninstallRateBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Rate Breakdown'**
  String get uninstallRateBreakdown;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Export ready! {count} jobs exported to Excel.'**
  String exportReady(int count);

  /// No description provided for @couldNotExport.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the export file. Please try again.'**
  String get couldNotExport;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Technician Management System'**
  String get appSubtitle;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}'**
  String passwordResetSent(String email);

  /// No description provided for @confirmDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'This will deactivate {name} and they won\'t be able to sign in. Continue?'**
  String confirmDeleteUser(String name);

  /// No description provided for @addMoreEarning.
  ///
  /// In en, this message translates to:
  /// **'+ Add Another Earning'**
  String get addMoreEarning;

  /// No description provided for @addMoreExpense.
  ///
  /// In en, this message translates to:
  /// **'+ Add Another Expense'**
  String get addMoreExpense;

  /// No description provided for @companies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get companies;

  /// No description provided for @addCompany.
  ///
  /// In en, this message translates to:
  /// **'Add Company'**
  String get addCompany;

  /// No description provided for @editCompany.
  ///
  /// In en, this message translates to:
  /// **'Edit Company'**
  String get editCompany;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @ambiguousCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Ambiguous'**
  String get ambiguousCompanyName;

  /// No description provided for @companyPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Company Phone Number'**
  String get companyPhoneNumber;

  /// No description provided for @invoicePrefix.
  ///
  /// In en, this message translates to:
  /// **'Invoice Prefix'**
  String get invoicePrefix;

  /// No description provided for @invoiceSuffix.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceSuffix;

  /// No description provided for @selectCompany.
  ///
  /// In en, this message translates to:
  /// **'Select company'**
  String get selectCompany;

  /// No description provided for @companySelectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a company before submitting.'**
  String get companySelectionRequired;

  /// No description provided for @noCompany.
  ///
  /// In en, this message translates to:
  /// **'No company'**
  String get noCompany;

  /// No description provided for @noCompaniesYet.
  ///
  /// In en, this message translates to:
  /// **'No companies added yet'**
  String get noCompaniesYet;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changeYourName.
  ///
  /// In en, this message translates to:
  /// **'Change your display name'**
  String get changeYourName;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// No description provided for @companyCreated.
  ///
  /// In en, this message translates to:
  /// **'Company created successfully!'**
  String get companyCreated;

  /// No description provided for @companyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Company updated successfully!'**
  String get companyUpdated;

  /// No description provided for @companyActivated.
  ///
  /// In en, this message translates to:
  /// **'Company activated'**
  String get companyActivated;

  /// No description provided for @companyDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Company deactivated'**
  String get companyDeactivated;

  /// No description provided for @manageLogoAndBranding.
  ///
  /// In en, this message translates to:
  /// **'Manage Logo and Branding'**
  String get manageLogoAndBranding;

  /// No description provided for @editOwnCompanyBranding.
  ///
  /// In en, this message translates to:
  /// **'Edit AC Techs Branding'**
  String get editOwnCompanyBranding;

  /// No description provided for @manageClientCompanyBranding.
  ///
  /// In en, this message translates to:
  /// **'Manage Client Company Branding'**
  String get manageClientCompanyBranding;

  /// No description provided for @ownCompanyBrandingUpdated.
  ///
  /// In en, this message translates to:
  /// **'AC Techs branding updated successfully!'**
  String get ownCompanyBrandingUpdated;

  /// No description provided for @workExpenses.
  ///
  /// In en, this message translates to:
  /// **'Work Expenses'**
  String get workExpenses;

  /// No description provided for @homeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Home Expenses'**
  String get homeExpenses;

  /// No description provided for @importHistoryData.
  ///
  /// In en, this message translates to:
  /// **'Import Historical Data'**
  String get importHistoryData;

  /// No description provided for @importHistoryDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload one or more Excel files to import previous technician installations by technician ID/email/name.'**
  String get importHistoryDataSubtitle;

  /// No description provided for @uploadExcel.
  ///
  /// In en, this message translates to:
  /// **'Upload Excel'**
  String get uploadExcel;

  /// No description provided for @importDropFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop Excel files here'**
  String get importDropFilesTitle;

  /// No description provided for @importDropFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Supports .xlsx and .xls files, or use Upload Excel.'**
  String get importDropFilesSubtitle;

  /// No description provided for @importUnsupportedFileType.
  ///
  /// In en, this message translates to:
  /// **'Only Excel .xlsx or .xls files are supported.'**
  String get importUnsupportedFileType;

  /// No description provided for @deleteSourceAfterImport.
  ///
  /// In en, this message translates to:
  /// **'Delete source file after import (best effort)'**
  String get deleteSourceAfterImport;

  /// No description provided for @importInProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importInProgress;

  /// No description provided for @importNoFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected.'**
  String get importNoFileSelected;

  /// No description provided for @importFailedNoRows.
  ///
  /// In en, this message translates to:
  /// **'No valid rows found for import.'**
  String get importFailedNoRows;

  /// No description provided for @importCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} rows'**
  String importCompletedCount(int count);

  /// No description provided for @importSkippedCount.
  ///
  /// In en, this message translates to:
  /// **'Skipped {count} rows'**
  String importSkippedCount(int count);

  /// No description provided for @importUnresolvedTechRows.
  ///
  /// In en, this message translates to:
  /// **'{count} rows skipped: technician not found'**
  String importUnresolvedTechRows(int count);

  /// No description provided for @importRowsWithoutTechName.
  ///
  /// In en, this message translates to:
  /// **'{count} rows have no technician name'**
  String importRowsWithoutTechName(int count);

  /// No description provided for @importUniqueTechNamesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unique technician names found'**
  String importUniqueTechNamesCount(int count);

  /// No description provided for @importTopTechNamesLabel.
  ///
  /// In en, this message translates to:
  /// **'Top technician names'**
  String get importTopTechNamesLabel;

  /// No description provided for @importProgressFile.
  ///
  /// In en, this message translates to:
  /// **'Importing {current}/{total}: {fileName}'**
  String importProgressFile(int current, int total, String fileName);

  /// No description provided for @importInstalledBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Installed S/W/F: {split}/{window}/{freestanding}'**
  String importInstalledBreakdown(int split, int window, int freestanding);

  /// No description provided for @importUninstallBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Uninstall S/W/F/O: {split}/{window}/{freestanding}/{old}'**
  String importUninstallBreakdown(
    int split,
    int window,
    int freestanding,
    int old,
  );

  /// No description provided for @importSheetRowLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Row limit exceeded; only the first 5000 rows were processed.'**
  String get importSheetRowLimitExceeded;

  /// No description provided for @importTargetTechnician.
  ///
  /// In en, this message translates to:
  /// **'Target technician'**
  String get importTargetTechnician;

  /// No description provided for @importTargetTechnicianRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the technician who should receive the imported history.'**
  String get importTargetTechnicianRequired;

  /// No description provided for @importTechnicianKeyword.
  ///
  /// In en, this message translates to:
  /// **'Source technician filter'**
  String get importTechnicianKeyword;

  /// No description provided for @importTechnicianKeywordHint.
  ///
  /// In en, this message translates to:
  /// **'Example: name, email, or uid'**
  String get importTechnicianKeywordHint;

  /// No description provided for @importTechnicianKeywordHelp.
  ///
  /// In en, this message translates to:
  /// **'Only rows whose technician name, email, or ID matches this text will be imported.'**
  String get importTechnicianKeywordHelp;

  /// No description provided for @importKeywordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please filter by technician keyword to prevent accidental bulk upload.'**
  String get importKeywordRequired;

  /// No description provided for @importBundledTemplates.
  ///
  /// In en, this message translates to:
  /// **'Import bundled history templates'**
  String get importBundledTemplates;

  /// No description provided for @importBundledTemplatesMissing.
  ///
  /// In en, this message translates to:
  /// **'No bundled history templates were found in the app package.'**
  String get importBundledTemplatesMissing;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @flushDatabase.
  ///
  /// In en, this message translates to:
  /// **'Flush Database'**
  String get flushDatabase;

  /// No description provided for @flushDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all data to a clean state'**
  String get flushDatabaseSubtitle;

  /// No description provided for @normalizeStoredInvoices.
  ///
  /// In en, this message translates to:
  /// **'Normalize Legacy Invoices'**
  String get normalizeStoredInvoices;

  /// No description provided for @normalizeStoredInvoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove stored company prefixes from invoices and rebuild invoice ledgers without a full flush.'**
  String get normalizeStoredInvoicesSubtitle;

  /// No description provided for @normalizeStoredInvoicesDescription.
  ///
  /// In en, this message translates to:
  /// **'This one-time migration rewrites stored job invoice numbers, refreshes shared group keys, and rebuilds invoice claims without deleting operational data.'**
  String get normalizeStoredInvoicesDescription;

  /// No description provided for @normalizeStoredInvoicesAction.
  ///
  /// In en, this message translates to:
  /// **'Run Migration'**
  String get normalizeStoredInvoicesAction;

  /// No description provided for @normalizeStoredInvoicesSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invoice migration finished. Updated {jobs} jobs and flagged {conflicts} conflicting invoice groups.'**
  String normalizeStoredInvoicesSuccess(int jobs, int conflicts);

  /// No description provided for @flushScope.
  ///
  /// In en, this message translates to:
  /// **'Flush Scope'**
  String get flushScope;

  /// No description provided for @flushAllData.
  ///
  /// In en, this message translates to:
  /// **'All Data'**
  String get flushAllData;

  /// No description provided for @flushOnlySelectedTechnician.
  ///
  /// In en, this message translates to:
  /// **'Only selected technician data (jobs and in/out) will be flushed.'**
  String get flushOnlySelectedTechnician;

  /// No description provided for @flushStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2 — Confirm Intent'**
  String get flushStep1Title;

  /// No description provided for @flushStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2 — Final Confirmation'**
  String get flushStep2Title;

  /// No description provided for @flushWarningIntro.
  ///
  /// In en, this message translates to:
  /// **'You are about to permanently delete the following data:'**
  String get flushWarningIntro;

  /// No description provided for @flushItemJobs.
  ///
  /// In en, this message translates to:
  /// **'All job records'**
  String get flushItemJobs;

  /// No description provided for @flushItemExpenses.
  ///
  /// In en, this message translates to:
  /// **'All expense & earning records'**
  String get flushItemExpenses;

  /// No description provided for @flushItemCompanies.
  ///
  /// In en, this message translates to:
  /// **'All company records'**
  String get flushItemCompanies;

  /// No description provided for @flushItemUsers.
  ///
  /// In en, this message translates to:
  /// **'All non-admin user accounts'**
  String get flushItemUsers;

  /// No description provided for @flushItemUsersOptional.
  ///
  /// In en, this message translates to:
  /// **'Non-admin user accounts (optional)'**
  String get flushItemUsersOptional;

  /// No description provided for @flushAdminKept.
  ///
  /// In en, this message translates to:
  /// **'Admin accounts will be preserved.'**
  String get flushAdminKept;

  /// No description provided for @flushProceedIn.
  ///
  /// In en, this message translates to:
  /// **'Proceed in {seconds}s'**
  String flushProceedIn(int seconds);

  /// No description provided for @flushProceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Step 2'**
  String get flushProceed;

  /// No description provided for @flushEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your admin password to confirm'**
  String get flushEnterPassword;

  /// No description provided for @flushConfirmIn.
  ///
  /// In en, this message translates to:
  /// **'Confirm in {seconds}s'**
  String flushConfirmIn(int seconds);

  /// No description provided for @flushConfirm.
  ///
  /// In en, this message translates to:
  /// **'Flush Database'**
  String get flushConfirm;

  /// No description provided for @flushInProgress.
  ///
  /// In en, this message translates to:
  /// **'Flushing database…'**
  String get flushInProgress;

  /// No description provided for @flushDeleteUsersOption.
  ///
  /// In en, this message translates to:
  /// **'Also delete technician/user accounts'**
  String get flushDeleteUsersOption;

  /// No description provided for @flushDeleteUsersHelp.
  ///
  /// In en, this message translates to:
  /// **'If enabled, all non-admin user documents are permanently deleted.'**
  String get flushDeleteUsersHelp;

  /// No description provided for @flushDeleteUsersEnabledWarning.
  ///
  /// In en, this message translates to:
  /// **'User deletion is enabled. All technician and other non-admin user records will be permanently removed during this flush.'**
  String get flushDeleteUsersEnabledWarning;

  /// No description provided for @flushSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database flushed. Starting fresh.'**
  String get flushSuccess;

  /// No description provided for @flushFailed.
  ///
  /// In en, this message translates to:
  /// **'Flush failed. Check connection and try again.'**
  String get flushFailed;

  /// No description provided for @flushRequiresInternetMessage.
  ///
  /// In en, this message translates to:
  /// **'A live internet connection is required to verify your admin password and flush data safely.'**
  String get flushRequiresInternetMessage;

  /// No description provided for @flushPhaseVerifyingPassword.
  ///
  /// In en, this message translates to:
  /// **'Verifying admin password...'**
  String get flushPhaseVerifyingPassword;

  /// No description provided for @flushPhaseCheckingConnection.
  ///
  /// In en, this message translates to:
  /// **'Checking live connection...'**
  String get flushPhaseCheckingConnection;

  /// No description provided for @flushPhaseScanningData.
  ///
  /// In en, this message translates to:
  /// **'Scanning affected records...'**
  String get flushPhaseScanningData;

  /// No description provided for @flushPhaseDeletingOperationalData.
  ///
  /// In en, this message translates to:
  /// **'Deleting jobs and operational records...'**
  String get flushPhaseDeletingOperationalData;

  /// No description provided for @flushPhaseDeletingDerivedData.
  ///
  /// In en, this message translates to:
  /// **'Deleting shared aggregates and invoice ledgers...'**
  String get flushPhaseDeletingDerivedData;

  /// No description provided for @flushPhaseDeletingCompanies.
  ///
  /// In en, this message translates to:
  /// **'Deleting companies...'**
  String get flushPhaseDeletingCompanies;

  /// No description provided for @flushPhaseArchivingUsers.
  ///
  /// In en, this message translates to:
  /// **'Archiving non-admin users...'**
  String get flushPhaseArchivingUsers;

  /// No description provided for @flushPhaseRebuildingDerivedData.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding invoice ledgers and shared totals...'**
  String get flushPhaseRebuildingDerivedData;

  /// No description provided for @flushPhaseClearingLocalCache.
  ///
  /// In en, this message translates to:
  /// **'Scheduling local cache reset...'**
  String get flushPhaseClearingLocalCache;

  /// No description provided for @flushPhaseRefreshingAppData.
  ///
  /// In en, this message translates to:
  /// **'Refreshing app data...'**
  String get flushPhaseRefreshingAppData;

  /// No description provided for @flushProgressStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String flushProgressStep(int current, int total);

  /// No description provided for @flushWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get flushWrongPassword;

  /// No description provided for @currentBuild.
  ///
  /// In en, this message translates to:
  /// **'Current build'**
  String get currentBuild;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your app build ({build}) is no longer supported. Please install the latest APK to continue.'**
  String updateRequiredBody(int build);

  /// No description provided for @updateRequiredLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking app version...'**
  String get updateRequiredLoading;

  /// No description provided for @iUpdatedRefresh.
  ///
  /// In en, this message translates to:
  /// **'I Updated - Refresh'**
  String get iUpdatedRefresh;

  /// No description provided for @catSplitAc.
  ///
  /// In en, this message translates to:
  /// **'Split AC'**
  String get catSplitAc;

  /// No description provided for @catWindowAc.
  ///
  /// In en, this message translates to:
  /// **'Window AC'**
  String get catWindowAc;

  /// No description provided for @catFreestandingAc.
  ///
  /// In en, this message translates to:
  /// **'Freestanding AC'**
  String get catFreestandingAc;

  /// No description provided for @catCassetteAc.
  ///
  /// In en, this message translates to:
  /// **'Cassette AC'**
  String get catCassetteAc;

  /// No description provided for @catUninstallOldAc.
  ///
  /// In en, this message translates to:
  /// **'Uninstallation (Old AC)'**
  String get catUninstallOldAc;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catPetrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get catPetrol;

  /// No description provided for @catPipes.
  ///
  /// In en, this message translates to:
  /// **'Pipes'**
  String get catPipes;

  /// No description provided for @catTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get catTools;

  /// No description provided for @catTape.
  ///
  /// In en, this message translates to:
  /// **'Tape'**
  String get catTape;

  /// No description provided for @catInsulation.
  ///
  /// In en, this message translates to:
  /// **'Insulation'**
  String get catInsulation;

  /// No description provided for @catGas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get catGas;

  /// No description provided for @catOtherConsumables.
  ///
  /// In en, this message translates to:
  /// **'Other Consumables'**
  String get catOtherConsumables;

  /// No description provided for @catHouseRent.
  ///
  /// In en, this message translates to:
  /// **'House Rent'**
  String get catHouseRent;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @catInstalledBracket.
  ///
  /// In en, this message translates to:
  /// **'Installed Bracket'**
  String get catInstalledBracket;

  /// No description provided for @catInstalledExtraPipe.
  ///
  /// In en, this message translates to:
  /// **'Installed Extra Pipe'**
  String get catInstalledExtraPipe;

  /// No description provided for @catOldAcRemoval.
  ///
  /// In en, this message translates to:
  /// **'Old AC Removal'**
  String get catOldAcRemoval;

  /// No description provided for @catOldAcInstallation.
  ///
  /// In en, this message translates to:
  /// **'Old AC Installation'**
  String get catOldAcInstallation;

  /// No description provided for @catSoldOldAc.
  ///
  /// In en, this message translates to:
  /// **'Sold Old AC'**
  String get catSoldOldAc;

  /// No description provided for @catSoldScrap.
  ///
  /// In en, this message translates to:
  /// **'Sold Scrap'**
  String get catSoldScrap;

  /// No description provided for @catBreadRoti.
  ///
  /// In en, this message translates to:
  /// **'Bread/Roti'**
  String get catBreadRoti;

  /// No description provided for @catMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat'**
  String get catMeat;

  /// No description provided for @catChicken.
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get catChicken;

  /// No description provided for @catTea.
  ///
  /// In en, this message translates to:
  /// **'Tea'**
  String get catTea;

  /// No description provided for @catSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get catSugar;

  /// No description provided for @catRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get catRice;

  /// No description provided for @catVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get catVegetables;

  /// No description provided for @catCookingOil.
  ///
  /// In en, this message translates to:
  /// **'Cooking Oil'**
  String get catCookingOil;

  /// No description provided for @catMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get catMilk;

  /// No description provided for @catSpices.
  ///
  /// In en, this message translates to:
  /// **'Spices'**
  String get catSpices;

  /// No description provided for @catOtherGroceries.
  ///
  /// In en, this message translates to:
  /// **'Other Groceries'**
  String get catOtherGroceries;

  /// No description provided for @passwordResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password?'**
  String get passwordResetConfirmTitle;

  /// No description provided for @passwordResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'A reset link will be sent to {email}. Continue?'**
  String passwordResetConfirmBody(String email);

  /// No description provided for @passwordResetEmailSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Sent'**
  String get passwordResetEmailSentTitle;

  /// No description provided for @passwordResetEmailSentBody.
  ///
  /// In en, this message translates to:
  /// **'A reset link has been sent to {email}.\n\nPlease check your inbox. If you don\'t see it within a few minutes, check your Spam or Junk folder.\n\nThe link expires in 1 hour.'**
  String passwordResetEmailSentBody(String email);

  /// No description provided for @passwordResetNetworkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please connect and try again.'**
  String get passwordResetNetworkError;

  /// No description provided for @passwordResetRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many reset requests. Please wait a few minutes and try again.'**
  String get passwordResetRateLimit;

  /// No description provided for @capsLockWarning.
  ///
  /// In en, this message translates to:
  /// **'Caps Lock is on. Passwords are case-sensitive.'**
  String get capsLockWarning;

  /// No description provided for @passwordManagerHint.
  ///
  /// In en, this message translates to:
  /// **'Your browser or device can save this password after sign in.'**
  String get passwordManagerHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @emailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Email updated successfully.'**
  String get emailUpdated;

  /// No description provided for @emailChangeVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Open your inbox to confirm new email.'**
  String get emailChangeVerificationSent;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully.'**
  String get passwordUpdated;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @entriesSaved.
  ///
  /// In en, this message translates to:
  /// **'Entries saved successfully.'**
  String get entriesSaved;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted successfully.'**
  String get entryDeleted;

  /// No description provided for @entryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Entry updated successfully.'**
  String get entryUpdated;

  /// No description provided for @selectPdfDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select PDF date range'**
  String get selectPdfDateRange;

  /// No description provided for @pdfDateRangeMonthOnly.
  ///
  /// In en, this message translates to:
  /// **'Please select a date range within the selected month.'**
  String get pdfDateRangeMonthOnly;

  /// No description provided for @exportTodayCompanyInvoices.
  ///
  /// In en, this message translates to:
  /// **'Export today\'s company invoices'**
  String get exportTodayCompanyInvoices;

  /// No description provided for @noInvoicesToday.
  ///
  /// In en, this message translates to:
  /// **'No invoices found for today.'**
  String get noInvoicesToday;

  /// No description provided for @couldNotOpenSummary.
  ///
  /// In en, this message translates to:
  /// **'Could not open summary screen. Please try again.'**
  String get couldNotOpenSummary;

  /// No description provided for @userDataLoading.
  ///
  /// In en, this message translates to:
  /// **'Please wait — loading your profile...'**
  String get userDataLoading;

  /// No description provided for @couldNotSubmitJob.
  ///
  /// In en, this message translates to:
  /// **'Could not submit. Please sign out and sign back in.'**
  String get couldNotSubmitJob;

  /// No description provided for @loadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load. Please try again.'**
  String get loadingFailed;

  /// No description provided for @invoiceSopTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice SOP Flow'**
  String get invoiceSopTitle;

  /// No description provided for @excelStyleEntry.
  ///
  /// In en, this message translates to:
  /// **'Excel Style Entry'**
  String get excelStyleEntry;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @invoiceSopStep1.
  ///
  /// In en, this message translates to:
  /// **'1) Select date and company'**
  String get invoiceSopStep1;

  /// No description provided for @invoiceSopStep2.
  ///
  /// In en, this message translates to:
  /// **'2) Add invoice, client and contact'**
  String get invoiceSopStep2;

  /// No description provided for @invoiceSopStep3.
  ///
  /// In en, this message translates to:
  /// **'3) Add AC units and optional charges'**
  String get invoiceSopStep3;

  /// No description provided for @invoiceSopStep4.
  ///
  /// In en, this message translates to:
  /// **'4) Submit for admin approval'**
  String get invoiceSopStep4;

  /// No description provided for @jobsDetailsReport.
  ///
  /// In en, this message translates to:
  /// **'Jobs Details Report'**
  String get jobsDetailsReport;

  /// No description provided for @earningsReport.
  ///
  /// In en, this message translates to:
  /// **'Earnings Report'**
  String get earningsReport;

  /// No description provided for @expensesDetailedReport.
  ///
  /// In en, this message translates to:
  /// **'Expenses Report (Work & Home)'**
  String get expensesDetailedReport;

  /// No description provided for @exportJobsAsExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Jobs as Excel'**
  String get exportJobsAsExcel;

  /// No description provided for @exportJobsAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export Jobs as PDF'**
  String get exportJobsAsPdf;

  /// No description provided for @exportEarningsAsExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Earnings as Excel'**
  String get exportEarningsAsExcel;

  /// No description provided for @exportEarningsAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export Earnings as PDF'**
  String get exportEarningsAsPdf;

  /// No description provided for @exportExpensesAsExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Expenses as Excel'**
  String get exportExpensesAsExcel;

  /// No description provided for @exportExpensesAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export Expenses as PDF'**
  String get exportExpensesAsPdf;

  /// No description provided for @selectReportType.
  ///
  /// In en, this message translates to:
  /// **'Select Report Type'**
  String get selectReportType;

  /// No description provided for @jobsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs Report'**
  String get jobsReportTitle;

  /// No description provided for @earningsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings Report'**
  String get earningsReportTitle;

  /// No description provided for @expensesReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses Report'**
  String get expensesReportTitle;

  /// No description provided for @todayEarned.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get todayEarned;

  /// No description provided for @monthEarned.
  ///
  /// In en, this message translates to:
  /// **'Month\'s Earnings'**
  String get monthEarned;

  /// No description provided for @todayWorkExpenses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Work Expenses'**
  String get todayWorkExpenses;

  /// No description provided for @todayHomeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Home Expenses'**
  String get todayHomeExpenses;

  /// No description provided for @todayTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Total Expenses'**
  String get todayTotalExpenses;

  /// No description provided for @monthWorkExpenses.
  ///
  /// In en, this message translates to:
  /// **'Month\'s Work Expenses'**
  String get monthWorkExpenses;

  /// No description provided for @monthHomeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Month\'s Home Expenses'**
  String get monthHomeExpenses;

  /// No description provided for @monthTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Month\'s Total Expenses'**
  String get monthTotalExpenses;

  /// No description provided for @workExpensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Expenses'**
  String get workExpensesLabel;

  /// No description provided for @homeExpensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Home Expenses'**
  String get homeExpensesLabel;

  /// No description provided for @bracketLabel.
  ///
  /// In en, this message translates to:
  /// **'Bracket'**
  String get bracketLabel;

  /// No description provided for @deliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryLabel;

  /// No description provided for @acUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'AC Units'**
  String get acUnitsLabel;

  /// No description provided for @unitQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get unitQty;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @invoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceLabel;

  /// No description provided for @technicianLabel.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technicianLabel;

  /// No description provided for @technicianUidLabel.
  ///
  /// In en, this message translates to:
  /// **'Technician UID'**
  String get technicianUidLabel;

  /// No description provided for @approverUidLabel.
  ///
  /// In en, this message translates to:
  /// **'Approver UID'**
  String get approverUidLabel;

  /// No description provided for @sharedGroup.
  ///
  /// In en, this message translates to:
  /// **'Shared Group'**
  String get sharedGroup;

  /// No description provided for @approvedSharedInstalls.
  ///
  /// In en, this message translates to:
  /// **'Approved Shared Installs'**
  String get approvedSharedInstalls;

  /// No description provided for @contactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @itemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @noEarnings.
  ///
  /// In en, this message translates to:
  /// **'No earnings'**
  String get noEarnings;

  /// No description provided for @noWorkExpenses.
  ///
  /// In en, this message translates to:
  /// **'No work expenses'**
  String get noWorkExpenses;

  /// No description provided for @noHomeExpenses.
  ///
  /// In en, this message translates to:
  /// **'No home expenses'**
  String get noHomeExpenses;

  /// No description provided for @generateReports.
  ///
  /// In en, this message translates to:
  /// **'Generate Reports'**
  String get generateReports;

  /// No description provided for @acInstallations.
  ///
  /// In en, this message translates to:
  /// **'AC Installations'**
  String get acInstallations;

  /// No description provided for @logAcInstallations.
  ///
  /// In en, this message translates to:
  /// **'Log AC Installations'**
  String get logAcInstallations;

  /// No description provided for @noInstallationsToday.
  ///
  /// In en, this message translates to:
  /// **'No installations logged today'**
  String get noInstallationsToday;

  /// No description provided for @noManualInstallLogsToday.
  ///
  /// In en, this message translates to:
  /// **'No manual AC installation logs were added today.'**
  String get noManualInstallLogsToday;

  /// No description provided for @manualInstallLogDescription.
  ///
  /// In en, this message translates to:
  /// **'This screen tracks manual AC-install log entries. Invoice and shared-install jobs are counted separately above.'**
  String get manualInstallLogDescription;

  /// No description provided for @jobInstallationsToday.
  ///
  /// In en, this message translates to:
  /// **'Install jobs today'**
  String get jobInstallationsToday;

  /// No description provided for @manualLogsToday.
  ///
  /// In en, this message translates to:
  /// **'Manual logs today'**
  String get manualLogsToday;

  /// No description provided for @entryDetails.
  ///
  /// In en, this message translates to:
  /// **'Entry Details'**
  String get entryDetails;

  /// No description provided for @totalOnInvoice.
  ///
  /// In en, this message translates to:
  /// **'Total on Invoice'**
  String get totalOnInvoice;

  /// No description provided for @myShare.
  ///
  /// In en, this message translates to:
  /// **'My Share'**
  String get myShare;

  /// No description provided for @splitAcLabel.
  ///
  /// In en, this message translates to:
  /// **'Split AC'**
  String get splitAcLabel;

  /// No description provided for @windowAcLabel.
  ///
  /// In en, this message translates to:
  /// **'Window AC'**
  String get windowAcLabel;

  /// No description provided for @freestandingAcLabel.
  ///
  /// In en, this message translates to:
  /// **'Freestanding AC'**
  String get freestandingAcLabel;

  /// No description provided for @installationsLogged.
  ///
  /// In en, this message translates to:
  /// **'Installations logged successfully.'**
  String get installationsLogged;

  /// No description provided for @deleteInstallRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete installation record?'**
  String get deleteInstallRecord;

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitsLabel;

  /// No description provided for @invoiceUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice: {total} units'**
  String invoiceUnitsLabel(int total);

  /// No description provided for @myShareUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'My share: {share} units'**
  String myShareUnitsLabel(int share);

  /// No description provided for @shareMustNotExceedTotal.
  ///
  /// In en, this message translates to:
  /// **'My share cannot exceed total on invoice.'**
  String get shareMustNotExceedTotal;

  /// No description provided for @enterAtLeastOneUnit.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one AC unit quantity.'**
  String get enterAtLeastOneUnit;

  /// No description provided for @acInstallNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get acInstallNote;

  /// No description provided for @companyLogo.
  ///
  /// In en, this message translates to:
  /// **'Company Logo'**
  String get companyLogo;

  /// No description provided for @adminAboutBuiltBy.
  ///
  /// In en, this message translates to:
  /// **'Built and supported for AC Techs.'**
  String get adminAboutBuiltBy;

  /// No description provided for @developedByMuhammadImran.
  ///
  /// In en, this message translates to:
  /// **'Developed By Muhammad Imran'**
  String get developedByMuhammadImran;

  /// No description provided for @tapToUploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload logo'**
  String get tapToUploadLogo;

  /// No description provided for @uploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Logo'**
  String get uploadLogo;

  /// No description provided for @replaceLogo.
  ///
  /// In en, this message translates to:
  /// **'Replace Logo'**
  String get replaceLogo;

  /// No description provided for @logoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Logo is too large. Please use a smaller image to keep Firestore storage clean.'**
  String get logoTooLarge;

  /// No description provided for @removeLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get removeLogo;

  /// No description provided for @enterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity.'**
  String get enterValidQuantity;

  /// No description provided for @invoiceSettlements.
  ///
  /// In en, this message translates to:
  /// **'Invoice Settlements'**
  String get invoiceSettlements;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @paymentInbox.
  ///
  /// In en, this message translates to:
  /// **'Payment Inbox'**
  String get paymentInbox;

  /// No description provided for @awaitingTechnicianConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting technician confirmation'**
  String get awaitingTechnicianConfirmation;

  /// No description provided for @correctionRequired.
  ///
  /// In en, this message translates to:
  /// **'Correction required'**
  String get correctionRequired;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get paymentConfirmed;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @paymentDisputed.
  ///
  /// In en, this message translates to:
  /// **'Payment disputed'**
  String get paymentDisputed;

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get paidOn;

  /// No description provided for @confirmPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment received'**
  String get confirmPaymentReceived;

  /// No description provided for @rejectPayment.
  ///
  /// In en, this message translates to:
  /// **'Reject payment'**
  String get rejectPayment;

  /// No description provided for @resubmitPayment.
  ///
  /// In en, this message translates to:
  /// **'Resubmit payment'**
  String get resubmitPayment;

  /// No description provided for @settlementAdminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin note for technician'**
  String get settlementAdminNote;

  /// No description provided for @settlementTechnicianComment.
  ///
  /// In en, this message translates to:
  /// **'Add a payment comment'**
  String get settlementTechnicianComment;

  /// No description provided for @settlementBatch.
  ///
  /// In en, this message translates to:
  /// **'Settlement batch'**
  String get settlementBatch;

  /// No description provided for @paymentMarkedForConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Payment marked for technician confirmation.'**
  String get paymentMarkedForConfirmation;

  /// No description provided for @paymentConfirmedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed successfully.'**
  String get paymentConfirmedSuccess;

  /// No description provided for @paymentRejectedForCorrection.
  ///
  /// In en, this message translates to:
  /// **'Payment sent back for one correction round.'**
  String get paymentRejectedForCorrection;

  /// No description provided for @paymentResubmitted.
  ///
  /// In en, this message translates to:
  /// **'Payment resubmitted to technician.'**
  String get paymentResubmitted;

  /// No description provided for @selectJobsFirst.
  ///
  /// In en, this message translates to:
  /// **'Select at least one job first.'**
  String get selectJobsFirst;

  /// No description provided for @selectSameTechnicianJobs.
  ///
  /// In en, this message translates to:
  /// **'Select jobs from the same technician only.'**
  String get selectSameTechnicianJobs;

  /// No description provided for @selectSingleBatchToResubmit.
  ///
  /// In en, this message translates to:
  /// **'Select jobs from a single settlement batch to resubmit.'**
  String get selectSingleBatchToResubmit;

  /// No description provided for @filterByDateRange.
  ///
  /// In en, this message translates to:
  /// **'Filter by date range'**
  String get filterByDateRange;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @sharedTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team Members'**
  String get sharedTeamMembers;

  /// No description provided for @addTeamMember.
  ///
  /// In en, this message translates to:
  /// **'Add Team Member'**
  String get addTeamMember;

  /// No description provided for @removeTeamMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeTeamMember;

  /// No description provided for @sharedTeamCount.
  ///
  /// In en, this message translates to:
  /// **'Team size: {count}'**
  String sharedTeamCount(int count);

  /// No description provided for @notTeamMember.
  ///
  /// In en, this message translates to:
  /// **'You are not enrolled in this shared invoice team. Ask the first submitter to add you.'**
  String get notTeamMember;

  /// No description provided for @yourSharedTeams.
  ///
  /// In en, this message translates to:
  /// **'Your Shared Teams'**
  String get yourSharedTeams;

  /// No description provided for @pendingSharedInstalls.
  ///
  /// In en, this message translates to:
  /// **'Pending Shared Installs'**
  String get pendingSharedInstalls;

  /// No description provided for @tapToAddYourShare.
  ///
  /// In en, this message translates to:
  /// **'Tap to insert your share'**
  String get tapToAddYourShare;

  /// No description provided for @addYourShare.
  ///
  /// In en, this message translates to:
  /// **'Add Your Share'**
  String get addYourShare;

  /// No description provided for @preFilledFromSharedInstall.
  ///
  /// In en, this message translates to:
  /// **'Invoice data pre-filled from your team’s shared install. Enter only your unit share.'**
  String get preFilledFromSharedInstall;

  /// No description provided for @teamJobPending.
  ///
  /// In en, this message translates to:
  /// **'Pending your contribution'**
  String get teamJobPending;

  /// No description provided for @teamJobSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your contribution submitted'**
  String get teamJobSubmitted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @requestEditJob.
  ///
  /// In en, this message translates to:
  /// **'Request Edit'**
  String get requestEditJob;

  /// No description provided for @requestEditConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Edit?'**
  String get requestEditConfirmTitle;

  /// No description provided for @requestEditConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This job will return to pending and need admin re-approval before settlement.'**
  String get requestEditConfirmBody;

  /// No description provided for @jobEditRequested.
  ///
  /// In en, this message translates to:
  /// **'Edit request submitted. Awaiting admin re-approval.'**
  String get jobEditRequested;

  /// No description provided for @resubmittedBadge.
  ///
  /// In en, this message translates to:
  /// **'Re-submitted'**
  String get resubmittedBadge;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @permanentlyDeleteJob.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Job'**
  String get permanentlyDeleteJob;

  /// No description provided for @permanentlyDeleteJobConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this job permanently? This cannot be undone.'**
  String get permanentlyDeleteJobConfirm;

  /// No description provided for @permanentlyDeleteJobSharedWarning.
  ///
  /// In en, this message translates to:
  /// **'This is a shared install. Aggregate counters will NOT be adjusted automatically. Notify admin if totals need correction.'**
  String get permanentlyDeleteJobSharedWarning;

  /// No description provided for @jobDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job permanently deleted.'**
  String get jobDeletedSuccess;

  /// No description provided for @reconcileInvoices.
  ///
  /// In en, this message translates to:
  /// **'Reconcile Invoices'**
  String get reconcileInvoices;

  /// No description provided for @uploadCompanyReport.
  ///
  /// In en, this message translates to:
  /// **'Upload Company Report'**
  String get uploadCompanyReport;

  /// No description provided for @matchedInvoices.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get matchedInvoices;

  /// No description provided for @unmatchedInvoices.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get unmatchedInvoices;

  /// No description provided for @alreadyPaidInvoices.
  ///
  /// In en, this message translates to:
  /// **'Already Paid'**
  String get alreadyPaidInvoices;

  /// No description provided for @reconcileMarkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Matched invoices marked as paid.'**
  String get reconcileMarkedSuccess;

  /// No description provided for @settlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get settlements;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @reconciliation.
  ///
  /// In en, this message translates to:
  /// **'Reconciliation'**
  String get reconciliation;

  /// No description provided for @staleSharedInstalls.
  ///
  /// In en, this message translates to:
  /// **'Stale Shared Installs'**
  String get staleSharedInstalls;

  /// No description provided for @staleSharedInstallsDescription.
  ///
  /// In en, this message translates to:
  /// **'{count} shared install(s) older than 7 days with incomplete contributions.'**
  String staleSharedInstallsDescription(int count);

  /// No description provided for @cleanUpStale.
  ///
  /// In en, this message translates to:
  /// **'Clean Up'**
  String get cleanUpStale;

  /// No description provided for @cleanUpConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Stale Installs?'**
  String get cleanUpConfirmTitle;

  /// No description provided for @cleanUpConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will archive {count} stale shared install(s) and their associated jobs. This action can be reversed by an admin.'**
  String cleanUpConfirmMessage(int count);

  /// No description provided for @staleCleanUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Stale installs archived successfully.'**
  String get staleCleanUpSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
