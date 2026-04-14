// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'فنيين تكييف';

  @override
  String get techMgmtSystem => 'نظام إدارة الفنيين';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get enterEmail => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get enterValidEmail => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get enterValidPhone => 'يرجى إدخال رقم هاتف صالح';

  @override
  String get enterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get required => 'مطلوب';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String minChars(int count) {
    return 'الحد الأدنى $count أحرف';
  }

  @override
  String get technician => 'فني';

  @override
  String get admin => 'مسؤول';

  @override
  String get administrator => 'مسؤول إداري';

  @override
  String get home => 'الرئيسية';

  @override
  String get jobs => 'الأعمال';

  @override
  String get expenses => 'المصروفات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get approvals => 'الموافقات';

  @override
  String get sharedInstallApprovalRequired => 'موافقات التركيبات المشتركة';

  @override
  String get enforceMinimumBuild => 'فرض الحد الأدنى للبناء';

  @override
  String get minimumSupportedBuild => 'أدنى بناء مدعوم';

  @override
  String get lockRecordsBefore => 'اقفل السجلات قبل';

  @override
  String get noPeriodLock => 'لا يوجد قفل فترة مفعل حالياً.';

  @override
  String get clearPeriodLock => 'إزالة قفل الفترة';

  @override
  String get lockedPeriodDescription =>
      'لن يمكن إنشاء السجلات الأقدم أو تعديلها أو اعتمادها أو رفضها أو حذفها.';

  @override
  String get analytics => 'التحليلات';

  @override
  String get team => 'الفريق';

  @override
  String get export => 'تصدير';

  @override
  String get submit => 'إرسال';

  @override
  String get submitForApproval => 'إرسال للموافقة';

  @override
  String get submitting => 'جارٍ الإرسال...';

  @override
  String get approve => 'موافقة';

  @override
  String get reject => 'رفض';

  @override
  String get today => 'اليوم';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get approved => 'موافق عليه';

  @override
  String get rejected => 'مرفوض';

  @override
  String get invoiceNumber => 'رقم الفاتورة';

  @override
  String get clientName => 'اسم العميل';

  @override
  String get clientNameOptional => 'اسم العميل (اختياري)';

  @override
  String get clientContact => 'اتصال العميل';

  @override
  String get clientPhone => 'رقم هاتف العميل';

  @override
  String get acUnits => 'وحدات التكييف';

  @override
  String get addUnit => 'إضافة وحدة';

  @override
  String get unitType => 'النوع';

  @override
  String get quantity => 'الكمية';

  @override
  String get expenseAmount => 'مبلغ المصروف';

  @override
  String get expenseNote => 'ملاحظة المصروف';

  @override
  String get adminNote => 'ملاحظة المسؤول';

  @override
  String get rejectReason => 'سبب الرفض';

  @override
  String get noJobsYet => 'لم يتم إرسال أعمال بعد';

  @override
  String get noDataYet => 'لا توجد بيانات بعد';

  @override
  String get noJobsToday => 'لا توجد أعمال اليوم';

  @override
  String get noMatchingJobs => 'لا توجد أعمال مطابقة';

  @override
  String get noApprovals => 'لا توجد موافقات معلقة';

  @override
  String get noMatchingApprovals => 'لا توجد موافقات مطابقة';

  @override
  String get allCaughtUp => 'لا شيء معلق!';

  @override
  String get todaysJobs => 'أعمال اليوم';

  @override
  String get totalJobs => 'إجمالي الأعمال';

  @override
  String get pendingApprovals => 'الموافقات المعلقة';

  @override
  String get approvedJobs => 'الأعمال الموافق عليها';

  @override
  String get rejectedJobs => 'الأعمال المرفوضة';

  @override
  String get totalExpenses => 'إجمالي المصروفات';

  @override
  String get teamMembers => 'أعضاء الفريق';

  @override
  String get activeMembers => 'الأعضاء النشطون';

  @override
  String get jobSubmitted => 'تم إرسال العمل بنجاح! في انتظار موافقة المسؤول.';

  @override
  String get jobSaved => 'تمت إضافة الإدخال بنجاح.';

  @override
  String get jobApproved => 'تمت الموافقة على العمل!';

  @override
  String get jobRejected => 'تم إرجاع العمل مع ملاحظاتك.';

  @override
  String get couldNotApprove => 'تعذرت الموافقة. حاول مرة أخرى.';

  @override
  String get couldNotReject => 'تعذر الرفض. حاول مرة أخرى.';

  @override
  String bulkApproveSuccess(int count) {
    return 'تمت الموافقة على $count عمل!';
  }

  @override
  String bulkRejectSuccess(int count) {
    return 'تم رفض $count عمل.';
  }

  @override
  String get bulkApproveFailed => 'فشلت الموافقة الجماعية. حاول مرة أخرى.';

  @override
  String get bulkRejectFailed => 'فشل الرفض الجماعي. حاول مرة أخرى.';

  @override
  String get rejectSelectedJobs => 'رفض الأعمال المحددة';

  @override
  String get rejectAll => 'رفض الكل';

  @override
  String get rejectJob => 'رفض العمل';

  @override
  String exportSuccess(int count) {
    return 'التصدير جاهز! تم تصدير $count عمل إلى Excel.';
  }

  @override
  String get exportFailed => 'تعذر إنشاء ملف التصدير. حاول مرة أخرى.';

  @override
  String get noJobsForPeriod =>
      'لا توجد أعمال لهذه الفترة. جرب نطاق تاريخ مختلف.';

  @override
  String get exportPdf => 'تصدير PDF';

  @override
  String get exportExcel => 'تصدير إلى Excel';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get urdu => 'اردو';

  @override
  String get arabic => 'العربية';

  @override
  String get pressBackAgainToExit => 'اضغط رجوع مرة أخرى لإغلاق التطبيق.';

  @override
  String get discardChangesTitle => 'هل تريد تجاهل التغييرات؟';

  @override
  String get discardChangesMessage =>
      'لديك تغييرات غير محفوظة. هل تريد مغادرة هذه الصفحة وفقدانها؟';

  @override
  String get leavePage => 'مغادرة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get reports => 'التقارير';

  @override
  String get reportsSubtitle => 'إنشاء ومشاركة تقارير PDF';

  @override
  String get dailyInOutReport => 'تقرير الدخل/المصروفات اليومي';

  @override
  String get dailyInOutReportDesc => 'ملخص الأرباح والمصروفات اليوم';

  @override
  String get monthlyInOutReport => 'تقرير الدخل/المصروفات الشهري';

  @override
  String get monthlyInOutReportDesc =>
      'نظرة عامة على الأرباح والمصروفات الشهرية';

  @override
  String get acInstallsReport => 'تقرير تركيبات المكيفات';

  @override
  String get acInstallsReportDesc => 'المكيفات المركبة حسب نطاق التاريخ';

  @override
  String get sharedInstallReport => 'تقرير التركيب المشترك';

  @override
  String get sharedInstallReportDesc => 'تفاصيل التركيب المشترك للفريق';

  @override
  String get paymentSettlementReport => 'تقرير تسوية المدفوعات';

  @override
  String get paymentSettlementReportDesc => 'ملخص مدفوعات الأعمال المستلمة';

  @override
  String get jobsReport => 'تقرير الأعمال';

  @override
  String get jobsReportDesc => 'سجل الأعمال المفصل مع الفلاتر';

  @override
  String get selectDateRange => 'اختر نطاق التاريخ';

  @override
  String get selectMonth => 'اختر الشهر';

  @override
  String get generateReport => 'إنشاء تقرير';

  @override
  String get noDataForPeriod => 'لم يتم العثور على بيانات للفترة المحددة.';

  @override
  String get offline => 'غير متصل';

  @override
  String get offlineBannerMessage =>
      'لا يوجد اتصال بالإنترنت. أنت تشاهد بيانات مخزنة مؤقتاً حتى يعود الاتصال.';

  @override
  String get syncing => 'جارٍ المزامنة...';

  @override
  String get jobHistory => 'سجل الأعمال';

  @override
  String get jobDetails => 'تفاصيل العمل';

  @override
  String get submitJob => 'إرسال عمل';

  @override
  String get submitInvoice => 'إرسال فاتورة';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get adminPanel => 'لوحة المسؤول';

  @override
  String get welcomeBack => 'مرحباً بعودتك،';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get tapToChange => 'اضغط للتغيير';

  @override
  String get invoiceDetails => 'تفاصيل الفاتورة';

  @override
  String get acServices => 'خدمات التكييف';

  @override
  String get serviceType => 'نوع الخدمة';

  @override
  String get add => 'إضافة';

  @override
  String get additionalCharges => 'رسوم إضافية';

  @override
  String get acOutdoorBracket => 'حامل الوحدة الخارجية';

  @override
  String get bracketSubtitle => 'حامل لتركيب الوحدة الخارجية';

  @override
  String get bracketCharge => 'رسوم الحامل (ريال)';

  @override
  String get deliveryCharge => 'رسوم التوصيل';

  @override
  String get deliverySubtitle => 'موقع العميل أبعد من 50 كم';

  @override
  String get deliveryChargeAmount => 'رسوم التوصيل (ريال)';

  @override
  String get locationNote => 'الموقع / ملاحظة (اختياري)';

  @override
  String get addServiceFirst => 'أضف خدمة تكييف واحدة على الأقل قبل الإرسال.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get confirmImport => 'تأكيد الاستيراد';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get search => 'بحث';

  @override
  String get filter => 'تصفية';

  @override
  String get all => 'الكل';

  @override
  String get activate => 'تفعيل';

  @override
  String get deactivate => 'تعطيل';

  @override
  String get totalUnits => 'إجمالي الوحدات';

  @override
  String get date => 'التاريخ';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeAuto => 'تلقائي';

  @override
  String get themeAutoDesc => 'اتباع إعداد النظام الداكن/الفاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeDarkDesc => 'أزرق قطبي — مريح للعين';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeLightDesc => 'نظيف ومشرق — للاستخدام الخارجي';

  @override
  String get themeHighContrast => 'تباين عالي';

  @override
  String get themeHighContrastDesc => 'أقصى درجة قراءة وحدود عريضة';

  @override
  String get about => 'حول';

  @override
  String get version => 'الإصدار';

  @override
  String get company => 'الشركة';

  @override
  String get companyBranding => 'هوية الشركة';

  @override
  String get region => 'المنطقة';

  @override
  String get pakistan => 'باكستان';

  @override
  String get saudiArabia => 'المملكة العربية السعودية';

  @override
  String get call => 'اتصال';

  @override
  String get whatsApp => 'واتساب';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get total => 'الإجمالي';

  @override
  String get noTeamMembers => 'لا يوجد أعضاء في الفريق بعد';

  @override
  String get noMatchingMembers => 'لا يوجد أعضاء مطابقون';

  @override
  String get searchByNameOrEmail => 'البحث بالاسم أو البريد الإلكتروني...';

  @override
  String get addTechnician => 'إضافة فني';

  @override
  String get editTechnician => 'تعديل فني';

  @override
  String get deleteTechnician => 'حذف فني';

  @override
  String deleteConfirm(String name) {
    return 'هل أنت متأكد أنك تريد حذف $name؟';
  }

  @override
  String get deleteWarning => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get name => 'الاسم';

  @override
  String get role => 'الدور';

  @override
  String get userCreated => 'تم إنشاء المستخدم بنجاح!';

  @override
  String get userUpdated => 'تم تحديث المستخدم بنجاح!';

  @override
  String get userDeleted => 'تمت أرشفة المستخدم بنجاح!';

  @override
  String get usersActivated => 'تم تفعيل المستخدمين';

  @override
  String get usersDeactivated => 'تم تعطيل المستخدمين';

  @override
  String get bulkActivate => 'تفعيل المحددين';

  @override
  String get bulkDeactivate => 'تعطيل المحددين';

  @override
  String get bulkDelete => 'حذف المحددين';

  @override
  String selectedCount(int count) {
    return '$count محدد';
  }

  @override
  String get inOut => 'دخول / خروج';

  @override
  String get monthlySummary => 'الملخص الشهري';

  @override
  String get todaysInOut => 'دخول / خروج اليوم';

  @override
  String get todaysEntries => 'إدخالات اليوم';

  @override
  String get noEntriesToday => 'لا توجد إدخالات اليوم';

  @override
  String get addFirstEntry => 'أضف أول دخول أو خروج أعلاه';

  @override
  String get inEarned => 'دخول (مكتسب)';

  @override
  String get outSpent => 'خروج (مصروف)';

  @override
  String get category => 'الفئة';

  @override
  String get amountSar => 'المبلغ (ريال)';

  @override
  String get amountMustBePositive => 'يجب أن يكون المبلغ أكبر من صفر.';

  @override
  String get remarksOptional => 'ملاحظات (اختياري)';

  @override
  String get saving => 'جارٍ الحفظ...';

  @override
  String get addEarning => 'إضافة دخل';

  @override
  String get addExpense => 'إضافة مصروف';

  @override
  String get enterAmount => 'أدخل مبلغاً.';

  @override
  String get enterValidAmount => 'أدخل مبلغاً موجباً صالحاً.';

  @override
  String get earned => 'دخول';

  @override
  String get spent => 'خروج';

  @override
  String get profit => 'ربح';

  @override
  String get loss => 'خسارة';

  @override
  String get newestFirst => 'الأحدث أولاً';

  @override
  String get oldestFirst => 'الأقدم أولاً';

  @override
  String get copyInvoice => 'نسخ رقم الفاتورة';

  @override
  String get viewInHistory => 'عرض في السجل';

  @override
  String get invoiceCopied => 'تم نسخ رقم الفاتورة!';

  @override
  String get newJob => 'عمل جديد';

  @override
  String get submitAJob => 'إرسال عمل';

  @override
  String get sharedInstall => 'تركيب مشترك';

  @override
  String get sharedInstallHint =>
      'فعّل هذا الخيار عندما يتم تقسيم الفاتورة نفسها بين عدة فنيين.';

  @override
  String get sharedInstallMixHint =>
      'أدخل إجمالي وحدات الفاتورة حسب النوع. سيُدخل كل فني حصته من الوحدات يدوياً. فقط رسوم التوصيل تُقسم بالتساوي.';

  @override
  String get flushOperationGuidanceTitle => 'ما العملية التي تحتاجها؟';

  @override
  String get flushOperationMigrationNote =>
      'الترحيل لمرة واحدة أو الاستيراد التاريخي يحافظ على البيانات الحالية وهو الخيار الآمن عند بدء النقل من Excel لأول مرة.';

  @override
  String get flushOperationReimportNote =>
      'المسح ثم إعادة الاستيراد يحذف البيانات التشغيلية أولاً. استخدمه فقط لإعادة ضبط كاملة أو عندما تحتاج عمدًا إلى إعادة البناء من الصفر.';

  @override
  String get sharedInvoiceTotalUnits => 'إجمالي وحدات الفاتورة';

  @override
  String get sharedInstallLimitError =>
      'الوحدات التي أدخلتها تتجاوز إجمالي وحدات الفاتورة.';

  @override
  String get sharedInvoiceSplitUnits => 'وحدات السبليت في الفاتورة';

  @override
  String get sharedInvoiceWindowUnits => 'وحدات الشباك في الفاتورة';

  @override
  String get sharedInvoiceFreestandingUnits => 'وحدات القائم في الفاتورة';

  @override
  String get sharedTeamSize => 'عدد أعضاء الفريق المشترك';

  @override
  String get sharedInvoiceDeliveryAmount => 'إجمالي رسوم التوصيل للفاتورة';

  @override
  String get sharedDeliverySplitHint =>
      'سيتم تقسيم مبلغ التوصيل هذا بالتساوي على الفريق المشترك.';

  @override
  String get sharedDeliverySplitInvalid =>
      'أدخل عدد أعضاء الفريق المشترك ليتم تقسيم رسوم التوصيل بالتساوي.';

  @override
  String get invoiceConflictNeedsReview =>
      'هذه الفاتورة موجودة أيضاً في شركة أخرى. راجعها قبل الموافقة.';

  @override
  String invoiceConflictCompaniesLabel(String companies) {
    return 'الشركات المتعارضة: $companies';
  }

  @override
  String get splits => 'سبليت';

  @override
  String get windowAc => 'نافذة';

  @override
  String get standing => 'قائم';

  @override
  String get cassette => 'كاسيت';

  @override
  String get uninstalls => 'إزالة';

  @override
  String get uninstallSplit => 'فك تركيب سبليت';

  @override
  String get uninstallWindow => 'فك تركيب شباك';

  @override
  String get uninstallStanding => 'فك تركيب قائم';

  @override
  String get jobStatus => 'حالة العمل';

  @override
  String get jobsPerTechnician => 'أعمال لكل فني';

  @override
  String get technicians => 'الفنيون';

  @override
  String get recentPending => 'المعلقة مؤخراً';

  @override
  String get invoice => 'فاتورة';

  @override
  String get client => 'عميل';

  @override
  String get units => 'وحدات';

  @override
  String get expensesSar => 'مصروفات (ريال)';

  @override
  String get status => 'الحالة';

  @override
  String get sort => 'ترتيب';

  @override
  String get yourShare => 'حصتك';

  @override
  String get installations => 'تركيبات';

  @override
  String get earningsIn => 'الإيرادات (دخول)';

  @override
  String get expensesOut => 'المصروفات (خروج)';

  @override
  String get netProfit => 'صافي الربح';

  @override
  String get earningsBreakdown => 'تفصيل الإيرادات';

  @override
  String get expensesBreakdown => 'تفصيل المصروفات';

  @override
  String get installationsByType => 'التركيبات حسب النوع';

  @override
  String get january => 'يناير';

  @override
  String get february => 'فبراير';

  @override
  String get march => 'مارس';

  @override
  String get april => 'أبريل';

  @override
  String get may => 'مايو';

  @override
  String get june => 'يونيو';

  @override
  String get july => 'يوليو';

  @override
  String get august => 'أغسطس';

  @override
  String get september => 'سبتمبر';

  @override
  String get october => 'أكتوبر';

  @override
  String get november => 'نوفمبر';

  @override
  String get december => 'ديسمبر';

  @override
  String get history => 'السجل';

  @override
  String get searchByClientOrInvoice => 'البحث بالعميل أو الفاتورة...';

  @override
  String get searchByTechClientInvoice =>
      'البحث بالفني أو العميل أو الفاتورة...';

  @override
  String get exportAsPdf => 'تصدير كـ PDF';

  @override
  String nUnits(int count) {
    return '$count وحدات';
  }

  @override
  String activeOfTotal(int active, int total) {
    return '$active / $total نشط';
  }

  @override
  String get exportToPdf => 'تصدير إلى PDF';

  @override
  String get exportToExcel => 'تصدير إلى Excel';

  @override
  String get reportPreset => 'إعداد التقرير';

  @override
  String get byTechnician => 'حسب الفني';

  @override
  String get uninstallRateBreakdown => 'تفصيل معدل الإزالة';

  @override
  String exportReady(int count) {
    return 'التصدير جاهز! تم تصدير $count وظائف إلى Excel.';
  }

  @override
  String get couldNotExport =>
      'تعذر إنشاء ملف التصدير. يرجى المحاولة مرة أخرى.';

  @override
  String get appSubtitle => 'نظام إدارة الفنيين';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String passwordResetSent(String email) {
    return 'تم إرسال بريد إعادة تعيين كلمة المرور إلى $email';
  }

  @override
  String confirmDeleteUser(String name) {
    return 'سيتم تعطيل $name ولن يتمكن من تسجيل الدخول. متابعة؟';
  }

  @override
  String get addMoreEarning => '+ إضافة دخل آخر';

  @override
  String get addMoreExpense => '+ إضافة مصروف آخر';

  @override
  String get companies => 'الشركات';

  @override
  String get addCompany => 'إضافة شركة';

  @override
  String get editCompany => 'تعديل شركة';

  @override
  String get companyName => 'اسم الشركة';

  @override
  String get ambiguousCompanyName => 'أمبيغوس';

  @override
  String get companyPhoneNumber => 'رقم هاتف الشركة';

  @override
  String get invoicePrefix => 'بادئة الفاتورة';

  @override
  String get invoiceSuffix => 'رقم الفاتورة';

  @override
  String get selectCompany => 'اختر الشركة';

  @override
  String get companySelectionRequired => 'يرجى اختيار شركة قبل الإرسال.';

  @override
  String get noCompany => 'بدون شركة';

  @override
  String get noCompaniesYet => 'لم تتم إضافة شركات بعد';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get changeYourName => 'تغيير اسمك';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String get companyCreated => 'تم إنشاء الشركة بنجاح!';

  @override
  String get companyUpdated => 'تم تحديث الشركة بنجاح!';

  @override
  String get companyActivated => 'تم تفعيل الشركة';

  @override
  String get companyDeactivated => 'تم تعطيل الشركة';

  @override
  String get manageLogoAndBranding => 'إدارة الشعار وهوية الشركة';

  @override
  String get editOwnCompanyBranding => 'تعديل هوية AC Techs';

  @override
  String get manageClientCompanyBranding => 'إدارة هوية شركات العملاء';

  @override
  String get ownCompanyBrandingUpdated => 'تم تحديث هوية AC Techs بنجاح!';

  @override
  String get workExpenses => 'مصروفات العمل';

  @override
  String get homeExpenses => 'مصروفات المنزل';

  @override
  String get importHistoryData => 'استيراد البيانات السابقة';

  @override
  String get importHistoryDataSubtitle =>
      'قم برفع ملف أو أكثر من Excel لاستيراد تركيبات الفنيين السابقة حسب معرف/البريد/الاسم.';

  @override
  String get uploadExcel => 'رفع Excel';

  @override
  String get importDropFilesTitle => 'اسحب ملفات Excel وأفلتها هنا';

  @override
  String get importDropFilesSubtitle =>
      'يدعم ملفات .xlsx و .xls، أو استخدم زر رفع Excel.';

  @override
  String get importUnsupportedFileType =>
      'الملفات المدعومة فقط هي Excel من نوع .xlsx أو .xls.';

  @override
  String get deleteSourceAfterImport =>
      'حذف الملف المصدر بعد الاستيراد (عند الإمكان)';

  @override
  String get importInProgress => 'جارٍ الاستيراد...';

  @override
  String get importNoFileSelected => 'لم يتم اختيار ملف.';

  @override
  String get importFailedNoRows => 'لا توجد صفوف صالحة للاستيراد.';

  @override
  String importCompletedCount(int count) {
    return 'تم استيراد $count صف';
  }

  @override
  String importSkippedCount(int count) {
    return 'تم تخطي $count صف';
  }

  @override
  String importUnresolvedTechRows(int count) {
    return 'تم تخطي $count صف: لم يتم العثور على الفني';
  }

  @override
  String importRowsWithoutTechName(int count) {
    return '$count صفوف بدون اسم فني';
  }

  @override
  String importUniqueTechNamesCount(int count) {
    return 'تم العثور على $count أسماء فنيين فريدة';
  }

  @override
  String get importTopTechNamesLabel => 'أكثر أسماء الفنيين تكراراً';

  @override
  String importProgressFile(int current, int total, String fileName) {
    return 'جارٍ استيراد $current/$total: $fileName';
  }

  @override
  String importInstalledBreakdown(int split, int window, int freestanding) {
    return 'التركيب S/W/F: $split/$window/$freestanding';
  }

  @override
  String importUninstallBreakdown(
    int split,
    int window,
    int freestanding,
    int old,
  ) {
    return 'الفك S/W/F/O: $split/$window/$freestanding/$old';
  }

  @override
  String get importSheetRowLimitExceeded =>
      'تم تجاوز حد الصفوف؛ تمت معالجة أول 5000 صف فقط.';

  @override
  String get importTargetTechnician => 'الفني المستهدف';

  @override
  String get importTargetTechnicianRequired =>
      'اختر الفني الذي يجب أن تُنسب إليه البيانات التاريخية المستوردة.';

  @override
  String get importTechnicianKeyword => 'مرشح الفني المصدر';

  @override
  String get importTechnicianKeywordHint =>
      'مثال: الاسم أو البريد الإلكتروني أو uid';

  @override
  String get importTechnicianKeywordHelp =>
      'سيتم استيراد الصفوف التي يطابق فيها اسم الفني أو بريده أو معرّفه هذا النص فقط.';

  @override
  String get importKeywordRequired =>
      'يرجى تصفية كلمة مفتاح الفني لمنع التحميل الضخم العرضي.';

  @override
  String get importBundledTemplates => 'استيراد القوالب التاريخية المضمنة';

  @override
  String get importBundledTemplatesMissing =>
      'لم يتم العثور على قوالب تاريخية مضمنة داخل حزمة التطبيق.';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get flushDatabase => 'مسح قاعدة البيانات';

  @override
  String get flushDatabaseSubtitle =>
      'إعادة تعيين جميع البيانات إلى حالة نظيفة';

  @override
  String get normalizeStoredInvoices => 'توحيد الفواتير القديمة';

  @override
  String get normalizeStoredInvoicesSubtitle =>
      'إزالة بادئات الشركات المخزنة من أرقام الفواتير وإعادة بناء سجلات الفواتير دون مسح كامل.';

  @override
  String get normalizeStoredInvoicesDescription =>
      'هذا ترحيل لمرة واحدة يعيد كتابة أرقام فواتير الوظائف المخزنة، ويحدّث مفاتيح المجموعات المشتركة، ويعيد بناء مطالبات الفواتير دون حذف البيانات التشغيلية.';

  @override
  String get normalizeStoredInvoicesAction => 'تشغيل الترحيل';

  @override
  String normalizeStoredInvoicesSuccess(int jobs, int conflicts) {
    return 'اكتمل ترحيل الفواتير. تم تحديث $jobs وظيفة وتم وضع علامة على $conflicts مجموعات فواتير متعارضة.';
  }

  @override
  String get flushScope => 'نطاق التفريغ';

  @override
  String get flushAllData => 'كل البيانات';

  @override
  String get flushOnlySelectedTechnician =>
      'سيتم تفريغ بيانات الفني المحدد فقط (الأعمال والدخول/الخروج).';

  @override
  String get flushStep1Title => 'الخطوة 1 من 2 — تأكيد النية';

  @override
  String get flushStep2Title => 'الخطوة 2 من 2 — التأكيد النهائي';

  @override
  String get flushWarningIntro => 'أنت على وشك حذف البيانات التالية نهائياً:';

  @override
  String get flushItemJobs => 'جميع سجلات الأعمال';

  @override
  String get flushItemExpenses => 'جميع سجلات المصروفات والإيرادات';

  @override
  String get flushItemCompanies => 'جميع سجلات الشركات';

  @override
  String get flushItemUsers => 'جميع حسابات المستخدمين غير المسؤولين';

  @override
  String get flushItemUsersOptional =>
      'حسابات المستخدمين غير المسؤولين (اختياري)';

  @override
  String get flushAdminKept => 'سيتم الحفاظ على حسابات المسؤولين.';

  @override
  String flushProceedIn(int seconds) {
    return 'المتابعة خلال $secondsث';
  }

  @override
  String get flushProceed => 'المتابعة إلى الخطوة 2';

  @override
  String get flushEnterPassword => 'أدخل كلمة مرور المسؤول للتأكيد';

  @override
  String flushConfirmIn(int seconds) {
    return 'التأكيد خلال $secondsث';
  }

  @override
  String get flushConfirm => 'مسح قاعدة البيانات';

  @override
  String get flushInProgress => 'جارٍ مسح قاعدة البيانات…';

  @override
  String get flushDeleteUsersOption => 'احذف أيضاً حسابات الفنيين/المستخدمين';

  @override
  String get flushDeleteUsersHelp =>
      'عند التفعيل، سيتم حذف جميع مستندات المستخدمين غير المسؤولين نهائياً.';

  @override
  String get flushDeleteUsersEnabledWarning =>
      'حذف المستخدمين مفعّل. سيتم حذف جميع سجلات الفنيين وبقية المستخدمين غير المسؤولين نهائياً أثناء هذا المسح.';

  @override
  String get flushSuccess => 'تم مسح قاعدة البيانات. جاهز للبدء من جديد.';

  @override
  String get flushFailed => 'فشل المسح. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get flushRequiresInternetMessage =>
      'يلزم اتصال مباشر بالإنترنت للتحقق من كلمة مرور المسؤول ومسح البيانات بأمان.';

  @override
  String get flushPhaseVerifyingPassword =>
      'جارٍ التحقق من كلمة مرور المسؤول...';

  @override
  String get flushPhaseCheckingConnection =>
      'جارٍ التحقق من الاتصال المباشر...';

  @override
  String get flushPhaseScanningData => 'جارٍ فحص السجلات المتأثرة...';

  @override
  String get flushPhaseDeletingOperationalData =>
      'جارٍ حذف الوظائف والسجلات التشغيلية...';

  @override
  String get flushPhaseDeletingDerivedData =>
      'جارٍ حذف المجاميع المشتركة ودفاتر الفواتير...';

  @override
  String get flushPhaseDeletingCompanies => 'جارٍ حذف الشركات...';

  @override
  String get flushPhaseArchivingUsers =>
      'جارٍ أرشفة المستخدمين غير المسؤولين...';

  @override
  String get flushPhaseRebuildingDerivedData =>
      'جارٍ إعادة بناء دفاتر الفواتير والإجماليات المشتركة...';

  @override
  String get flushPhaseClearingLocalCache =>
      'جارٍ جدولة إعادة ضبط التخزين المحلي...';

  @override
  String get flushPhaseRefreshingAppData => 'جارٍ تحديث بيانات التطبيق...';

  @override
  String flushProgressStep(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get flushWrongPassword => 'كلمة المرور غير صحيحة. حاول مرة أخرى.';

  @override
  String get currentBuild => 'رقم البناء الحالي';

  @override
  String get updateRequiredTitle => 'التحديث مطلوب';

  @override
  String updateRequiredBody(int build) {
    return 'إصدار التطبيق لديك ($build) لم يعد مدعوماً. يرجى تثبيت أحدث APK للمتابعة.';
  }

  @override
  String get updateRequiredLoading => 'جارٍ التحقق من إصدار التطبيق...';

  @override
  String get iUpdatedRefresh => 'تم التحديث - إعادة تحقق';

  @override
  String get catSplitAc => 'مكيف سبليت';

  @override
  String get catWindowAc => 'مكيف نافذة';

  @override
  String get catFreestandingAc => 'مكيف قائم';

  @override
  String get catCassetteAc => 'مكيف كاسيت';

  @override
  String get catUninstallOldAc => 'إزالة (مكيف قديم)';

  @override
  String get catFood => 'طعام';

  @override
  String get catPetrol => 'بنزين';

  @override
  String get catPipes => 'أنابيب';

  @override
  String get catTools => 'أدوات';

  @override
  String get catTape => 'شريط لاصق';

  @override
  String get catInsulation => 'عزل';

  @override
  String get catGas => 'غاز';

  @override
  String get catOtherConsumables => 'مستهلكات أخرى';

  @override
  String get catHouseRent => 'إيجار المنزل';

  @override
  String get catOther => 'أخرى';

  @override
  String get catInstalledBracket => 'تركيب حامل';

  @override
  String get catInstalledExtraPipe => 'تركيب أنبوب إضافي';

  @override
  String get catOldAcRemoval => 'إزالة مكيف قديم';

  @override
  String get catOldAcInstallation => 'تركيب مكيف قديم';

  @override
  String get catSoldOldAc => 'بيع مكيف قديم';

  @override
  String get catSoldScrap => 'بيع خردة';

  @override
  String get catBreadRoti => 'خبز';

  @override
  String get catMeat => 'لحم';

  @override
  String get catChicken => 'دجاج';

  @override
  String get catTea => 'شاي';

  @override
  String get catSugar => 'سكر';

  @override
  String get catRice => 'أرز';

  @override
  String get catVegetables => 'خضروات';

  @override
  String get catCookingOil => 'زيت طبخ';

  @override
  String get catMilk => 'حليب';

  @override
  String get catSpices => 'بهارات';

  @override
  String get catOtherGroceries => 'مشتريات أخرى';

  @override
  String get passwordResetConfirmTitle => 'إعادة تعيين كلمة المرور؟';

  @override
  String passwordResetConfirmBody(String email) {
    return 'سيتم إرسال رابط إعادة التعيين إلى $email. متابعة؟';
  }

  @override
  String get passwordResetEmailSentTitle => 'تم إرسال البريد الإلكتروني';

  @override
  String passwordResetEmailSentBody(String email) {
    return 'تم إرسال رابط إعادة التعيين إلى $email.\n\nيرجى التحقق من صندوق الوارد. إذا لم تجده خلال بضع دقائق، تحقق من مجلد البريد العشوائي.\n\nينتهي صلاحية الرابط خلال ساعة واحدة.';
  }

  @override
  String get passwordResetNetworkError =>
      'لا يوجد اتصال بالإنترنت. يرجى الاتصال والمحاولة مرة أخرى.';

  @override
  String get passwordResetRateLimit =>
      'طلبات إعادة تعيين كثيرة جداً. يرجى الانتظار بضع دقائق والمحاولة مرة أخرى.';

  @override
  String get capsLockWarning =>
      'مفتاح Caps Lock مفعّل. كلمات المرور حساسة لحالة الأحرف.';

  @override
  String get passwordManagerHint =>
      'يمكن للمتصفح أو الجهاز حفظ كلمة المرور هذه بعد تسجيل الدخول.';

  @override
  String get send => 'إرسال';

  @override
  String get changeEmail => 'تغيير البريد الإلكتروني';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get emailUpdated => 'تم تحديث البريد الإلكتروني بنجاح.';

  @override
  String get emailChangeVerificationSent =>
      'تم إرسال رسالة تحقق. افتح بريدك لتأكيد البريد الإلكتروني الجديد.';

  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور بنجاح.';

  @override
  String get editEntry => 'تعديل الإدخال';

  @override
  String get entriesSaved => 'تم حفظ الإدخالات بنجاح.';

  @override
  String get entryDeleted => 'تم حذف الإدخال بنجاح.';

  @override
  String get entryUpdated => 'تم تحديث الإدخال بنجاح.';

  @override
  String get selectPdfDateRange => 'حدد نطاق تاريخ PDF';

  @override
  String get pdfDateRangeMonthOnly =>
      'يرجى اختيار نطاق تاريخ ضمن الشهر المحدد.';

  @override
  String get exportTodayCompanyInvoices => 'تصدير فواتير الشركات لليوم';

  @override
  String get noInvoicesToday => 'لا توجد فواتير لليوم.';

  @override
  String get couldNotOpenSummary => 'تعذر فتح شاشة الملخص. حاول مرة أخرى.';

  @override
  String get userDataLoading => 'يرجى الانتظار — جارٍ تحميل ملفك الشخصي...';

  @override
  String get couldNotSubmitJob =>
      'تعذر الإرسال. يرجى تسجيل الخروج وإعادة تسجيل الدخول.';

  @override
  String get loadingFailed => 'فشل التحميل. يرجى المحاولة مرة أخرى.';

  @override
  String get invoiceSopTitle => 'تدفق إجراءات الفاتورة';

  @override
  String get excelStyleEntry => 'إدخال بنمط إكسل';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get invoiceSopStep1 => '1) اختر التاريخ والشركة';

  @override
  String get invoiceSopStep2 => '2) أدخل الفاتورة والعميل والتواصل';

  @override
  String get invoiceSopStep3 => '3) أضف وحدات التكييف والرسوم الاختيارية';

  @override
  String get invoiceSopStep4 => '4) أرسل لاعتماد المسؤول';

  @override
  String get jobsDetailsReport => 'تقرير تفاصيل الوظائف';

  @override
  String get earningsReport => 'تقرير الأرباح';

  @override
  String get expensesDetailedReport => 'تقرير النفقات (العمل والمنزل)';

  @override
  String get exportJobsAsExcel => 'تصدير الوظائف إلى Excel';

  @override
  String get exportJobsAsPdf => 'تصدير الوظائف إلى PDF';

  @override
  String get exportEarningsAsExcel => 'تصدير الأرباح إلى Excel';

  @override
  String get exportEarningsAsPdf => 'تصدير الأرباح إلى PDF';

  @override
  String get exportExpensesAsExcel => 'تصدير النفقات إلى Excel';

  @override
  String get exportExpensesAsPdf => 'تصدير النفقات إلى PDF';

  @override
  String get selectReportType => 'اختر نوع التقرير';

  @override
  String get jobsReportTitle => 'تقرير الوظائف';

  @override
  String get earningsReportTitle => 'تقرير الأرباح';

  @override
  String get expensesReportTitle => 'تقرير النفقات';

  @override
  String get todayEarned => 'أرباح اليوم';

  @override
  String get monthEarned => 'أرباح الشهر';

  @override
  String get todayWorkExpenses => 'نفقات العمل اليوم';

  @override
  String get todayHomeExpenses => 'نفقات المنزل اليوم';

  @override
  String get todayTotalExpenses => 'إجمالي النفقات اليوم';

  @override
  String get monthWorkExpenses => 'نفقات العمل الشهرية';

  @override
  String get monthHomeExpenses => 'نفقات المنزل الشهرية';

  @override
  String get monthTotalExpenses => 'إجمالي النفقات الشهرية';

  @override
  String get workExpensesLabel => 'نفقات العمل';

  @override
  String get homeExpensesLabel => 'نفقات المنزل';

  @override
  String get bracketLabel => 'الحامل';

  @override
  String get deliveryLabel => 'التوصيل';

  @override
  String get acUnitsLabel => 'وحدات التكييف';

  @override
  String get unitQty => 'الكمية';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get invoiceLabel => 'الفاتورة';

  @override
  String get technicianLabel => 'الفني';

  @override
  String get technicianUidLabel => 'معرّف الفني';

  @override
  String get approverUidLabel => 'معرّف الموافق';

  @override
  String get sharedGroup => 'مجموعة التركيب المشترك';

  @override
  String get approvedSharedInstalls => 'التركيبات المشتركة الموافق عليها';

  @override
  String get contactLabel => 'الاتصال';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get notesLabel => 'الملاحظات';

  @override
  String get amountLabel => 'المبلغ';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get itemLabel => 'البند';

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String get noEarnings => 'لا توجد أرباح';

  @override
  String get noWorkExpenses => 'لا توجد نفقات عمل';

  @override
  String get noHomeExpenses => 'لا توجد نفقات منزل';

  @override
  String get generateReports => 'إنشاء التقارير';

  @override
  String get acInstallations => 'تركيبات التكييف';

  @override
  String get logAcInstallations => 'تسجيل تركيبات التكييف';

  @override
  String get noInstallationsToday => 'لا توجد تركيبات مسجلة اليوم';

  @override
  String get noManualInstallLogsToday =>
      'لم تتم إضافة أي سجلات تركيب يدوي اليوم.';

  @override
  String get manualInstallLogDescription =>
      'تعرض هذه الشاشة سجلات التركيب اليدوية فقط. يتم احتساب أعمال الفواتير والتركيبات المشتركة بشكل منفصل في الأعلى.';

  @override
  String get jobInstallationsToday => 'أعمال التركيب اليوم';

  @override
  String get manualLogsToday => 'السجلات اليدوية اليوم';

  @override
  String get entryDetails => 'تفاصيل القيد';

  @override
  String get totalOnInvoice => 'إجمالي في الفاتورة';

  @override
  String get myShare => 'حصتي';

  @override
  String get splitAcLabel => 'مكيف سبليت';

  @override
  String get windowAcLabel => 'مكيف شباك';

  @override
  String get freestandingAcLabel => 'مكيف حر';

  @override
  String get installationsLogged => 'تم تسجيل التركيب بنجاح.';

  @override
  String get deleteInstallRecord => 'حذف سجل التركيب؟';

  @override
  String get unitsLabel => 'وحدات';

  @override
  String invoiceUnitsLabel(int total) {
    return 'الفاتورة: $total وحدات';
  }

  @override
  String myShareUnitsLabel(int share) {
    return 'حصتي: $share وحدات';
  }

  @override
  String get shareMustNotExceedTotal =>
      'لا يمكن أن تتجاوز حصتي إجمالي الفاتورة.';

  @override
  String get enterAtLeastOneUnit => 'أدخل كمية وحدة مكيف واحدة على الأقل.';

  @override
  String get acInstallNote => 'ملاحظة (اختياري)';

  @override
  String get companyLogo => 'شعار الشركة';

  @override
  String get adminAboutBuiltBy => 'تم تطوير هذا التطبيق ودعمه لصالح AC Techs.';

  @override
  String get developedByMuhammadImran => 'تم التطوير بواسطة محمد عمران';

  @override
  String get tapToUploadLogo => 'اضغط لتحميل الشعار';

  @override
  String get uploadLogo => 'رفع الشعار';

  @override
  String get replaceLogo => 'استبدال الشعار';

  @override
  String get logoTooLarge =>
      'الشعار كبير جداً. استخدم صورة أصغر للحفاظ على مساحة Firestore نظيفة.';

  @override
  String get removeLogo => 'إزالة الشعار';

  @override
  String get enterValidQuantity => 'أدخل كمية صحيحة.';

  @override
  String get invoiceSettlements => 'تسويات الفواتير';

  @override
  String get markAsPaid => 'تحديد كمدفوع';

  @override
  String get paymentInbox => 'صندوق تأكيد الدفع';

  @override
  String get awaitingTechnicianConfirmation => 'بانتظار تأكيد الفني';

  @override
  String get correctionRequired => 'مطلوب تصحيح';

  @override
  String get paymentConfirmed => 'تم تأكيد الدفع';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get paymentDisputed => 'الدفع محل نزاع';

  @override
  String get paidOn => 'تم الدفع في';

  @override
  String get confirmPaymentReceived => 'تأكيد استلام الدفع';

  @override
  String get rejectPayment => 'رفض الدفع';

  @override
  String get resubmitPayment => 'إعادة إرسال الدفع';

  @override
  String get settlementAdminNote => 'ملاحظة المشرف للفني';

  @override
  String get settlementTechnicianComment => 'أضف تعليقاً على الدفع';

  @override
  String get settlementBatch => 'دفعة التسوية';

  @override
  String get paymentMarkedForConfirmation =>
      'تم وضع الدفع بانتظار تأكيد الفني.';

  @override
  String get paymentConfirmedSuccess => 'تم تأكيد الدفع بنجاح.';

  @override
  String get paymentRejectedForCorrection =>
      'تمت إعادة الدفع لجولة تصحيح واحدة.';

  @override
  String get paymentResubmitted => 'تمت إعادة إرسال الدفع إلى الفني.';

  @override
  String get selectJobsFirst => 'اختر مهمة واحدة على الأقل أولاً.';

  @override
  String get selectSameTechnicianJobs => 'اختر مهام الفني نفسه فقط.';

  @override
  String get selectSingleBatchToResubmit =>
      'اختر مهام من دفعة تسوية واحدة لإعادة الإرسال.';

  @override
  String get filterByDateRange => 'تصفية حسب نطاق التاريخ';

  @override
  String get unpaid => 'غير مدفوع';

  @override
  String get sharedTeamMembers => 'أعضاء الفريق';

  @override
  String get addTeamMember => 'إضافة عضو فريق';

  @override
  String get removeTeamMember => 'إزالة';

  @override
  String sharedTeamCount(int count) {
    return 'حجم الفريق: $count';
  }

  @override
  String get notTeamMember =>
      'أنت لست مدرجاً كعضو في فريق هذه الفاتورة المشتركة. اطلب من الفني الأول الذي قدّم هذه الفاتورة إضافتك إلى الفريق.';

  @override
  String get yourSharedTeams => 'فرقك المشتركة';

  @override
  String get pendingSharedInstalls => 'تنفيذ مشترك قيد الانتظار';

  @override
  String get tapToAddYourShare => 'اضغط لإدخال حصتك';

  @override
  String get addYourShare => 'أضف حصتك';

  @override
  String get preFilledFromSharedInstall =>
      'تم تعبئة بيانات الفاتورة مسبقاً من التنفيذ المشترك لفريقك. أدخل حصتك من الوحدات فقط.';

  @override
  String get teamJobPending => 'في انتظار مساهمتك';

  @override
  String get teamJobSubmitted => 'تم تقديم مساهمتك';

  @override
  String get undo => 'تراجع';

  @override
  String get requestEditJob => 'طلب تعديل';

  @override
  String get requestEditConfirmTitle => 'طلب تعديل؟';

  @override
  String get requestEditConfirmBody =>
      'سيعود هذا العمل إلى قيد الانتظار ويحتاج إلى إعادة موافقة المسؤول قبل التسوية.';

  @override
  String get jobEditRequested =>
      'تم تقديم طلب التعديل. في انتظار إعادة موافقة المسؤول.';

  @override
  String get resubmittedBadge => 'أُعيد تقديمه';

  @override
  String get genericError => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get permanentlyDeleteJob => 'حذف العمل نهائياً';

  @override
  String get permanentlyDeleteJobConfirm =>
      'هل تريد حذف هذا العمل نهائياً؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get permanentlyDeleteJobSharedWarning =>
      'هذا تنفيذ مشترك. لن يتم تعديل الإجماليات تلقائياً. أبلغ المسؤول إذا كانت التصحيحات ضرورية.';

  @override
  String get jobDeletedSuccess => 'تم حذف العمل نهائياً.';

  @override
  String get reconcileInvoices => 'مطابقة الفواتير';

  @override
  String get uploadCompanyReport => 'رفع تقرير الشركة';

  @override
  String get matchedInvoices => 'متطابق';

  @override
  String get unmatchedInvoices => 'غير موجود';

  @override
  String get alreadyPaidInvoices => 'مدفوع مسبقاً';

  @override
  String get reconcileMarkedSuccess => 'تم تحديد الفواتير المتطابقة كمدفوعة.';

  @override
  String get settlements => 'التسويات';

  @override
  String get importData => 'استيراد البيانات';

  @override
  String get reconciliation => 'المطابقة';

  @override
  String get staleSharedInstalls => 'تركيبات مشتركة قديمة';

  @override
  String staleSharedInstallsDescription(int count) {
    return '$count تركيب(تركيبات) مشتركة أقدم من 7 أيام مع مساهمات غير مكتملة.';
  }

  @override
  String get cleanUpStale => 'تنظيف';

  @override
  String get cleanUpConfirmTitle => 'أرشفة التركيبات القديمة؟';

  @override
  String cleanUpConfirmMessage(int count) {
    return 'سيتم أرشفة $count تركيب(تركيبات) مشتركة قديمة والوظائف المرتبطة بها. يمكن للمسؤول التراجع عن هذا.';
  }

  @override
  String get staleCleanUpSuccess => 'تمت أرشفة التركيبات القديمة بنجاح.';
}
