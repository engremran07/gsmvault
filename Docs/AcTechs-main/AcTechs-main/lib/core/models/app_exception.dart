sealed class AppException implements Exception {
  const AppException(this.code, this.messageEn, this.messageUr, this.messageAr);

  final String code;
  final String messageEn;
  final String messageUr;
  final String messageAr;

  String message(String locale) {
    return switch (locale) {
      'ur' => messageUr,
      'ar' => messageAr,
      _ => messageEn,
    };
  }

  @override
  String toString() => '$runtimeType($code): $messageEn';
}

class AuthException extends AppException {
  const AuthException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory AuthException.wrongCredentials() => const AuthException(
    'auth_wrong_credentials',
    'Wrong username or password. Please check and try again.',
    'غلط نام یا پاس ورڈ۔ براہ کرم دوبارہ چیک کریں۔',
    'اسم مستخدم أو كلمة مرور خاطئة. يرجى المحاولة مرة أخرى.',
  );

  factory AuthException.accountDisabled() => const AuthException(
    'auth_account_disabled',
    'Your account has been deactivated. Contact your admin.',
    'آپ کا اکاؤنٹ غیر فعال ہے۔ ایڈمن سے رابطہ کریں۔',
    'تم تعطيل حسابك. تواصل مع المسؤول.',
  );

  factory AuthException.accountNotProvisioned() => const AuthException(
    'auth_account_not_provisioned',
    'Your account is not available in app records. Contact your admin.',
    'آپ کا اکاؤنٹ ایپ ریکارڈ میں موجود نہیں ہے۔ ایڈمن سے رابطہ کریں۔',
    'حسابك غير متاح في سجلات التطبيق. تواصل مع المسؤول.',
  );

  factory AuthException.tooManyAttempts() => const AuthException(
    'auth_too_many_attempts',
    'Too many failed attempts. Please wait a few minutes.',
    'بہت زیادہ ناکام کوششیں۔ چند منٹ انتظار کریں۔',
    'محاولات فاشلة كثيرة. انتظر بضع دقائق.',
  );

  factory AuthException.sessionExpired() => const AuthException(
    'auth_session_expired',
    'Your session has expired. Please sign in again.',
    'آپ کا سیشن ختم ہو گیا۔ دوبارہ سائن ان کریں۔',
    'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.',
  );

  factory AuthException.updateFailed() => const AuthException(
    'auth_update_failed',
    'Could not update your profile. Please try again.',
    'پروفائل اپ ڈیٹ نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
    'تعذر تحديث ملفك الشخصي. حاول مرة أخرى.',
  );

  factory AuthException.invalidEmail() => const AuthException(
    'auth_invalid_email',
    'Please enter a valid email address.',
    'براہ کرم درست ای میل درج کریں۔',
    'يرجى إدخال بريد إلكتروني صحيح.',
  );

  factory AuthException.emailAlreadyInUse() => const AuthException(
    'auth_email_in_use',
    'This email is already in use by another account.',
    'یہ ای میل پہلے سے کسی اور اکاؤنٹ میں استعمال ہو رہی ہے۔',
    'هذا البريد مستخدم بالفعل بواسطة حساب آخر.',
  );

  factory AuthException.weakPassword() => const AuthException(
    'auth_weak_password',
    'Password is too weak. Use at least 6 characters.',
    'پاس ورڈ کمزور ہے۔ کم از کم 6 حروف استعمال کریں۔',
    'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل.',
  );

  factory AuthException.recentLoginRequired() => const AuthException(
    'auth_recent_login_required',
    'Please sign in again before changing sensitive account details.',
    'حساس اکاؤنٹ تبدیلیوں سے پہلے دوبارہ سائن اِن کریں۔',
    'يرجى تسجيل الدخول مرة أخرى قبل تعديل بيانات الحساب الحساسة.',
  );

  factory AuthException.resetNetworkError() => const AuthException(
    'auth_reset_network',
    'No internet connection. Please connect and try again.',
    'انٹرنیٹ کنکشن نہیں ہے۔ براہ کرم کنکٹ کریں اور دوبارہ کوشش کریں۔',
    'لا يوجد اتصال بالإنترنت. يرجى الاتصال والمحاولة مرة أخرى.',
  );

  factory AuthException.resetRateLimit() => const AuthException(
    'auth_reset_rate_limit',
    'Too many reset requests. Please wait a few minutes and try again.',
    'بہت زیادہ ری سیٹ درخواستیں۔ براہ کرم چند منٹ انتظار کریں اور دوبارہ کوشش کریں۔',
    'طلبات إعادة تعيين كثيرة جداً. يرجى الانتظار بضع دقائق والمحاولة مرة أخرى.',
  );

  factory AuthException.resetFailed() => const AuthException(
    'auth_reset_failed',
    'Could not send reset email. Check the address and try again.',
    'ری سیٹ ای میل نہیں بھیجی جا سکی۔ پتہ چیک کریں اور دوبارہ کوشش کریں۔',
    'تعذر إرسال البريد الإلكتروني لإعادة التعيين. تحقق من العنوان وحاول مرة أخرى.',
  );

  factory AuthException.fromFirebase(String firebaseCode) {
    return switch (firebaseCode) {
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' => AuthException.wrongCredentials(),
      'user-disabled' => AuthException.accountDisabled(),
      'too-many-requests' => AuthException.tooManyAttempts(),
      _ => const AuthException(
        'auth_unknown',
        'Something went wrong. Please try again.',
        'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔',
        'حدث خطأ ما. حاول مرة أخرى.',
      ),
    };
  }
}

class NetworkException extends AppException {
  const NetworkException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory NetworkException.offline() => const NetworkException(
    'network_offline',
    "You're offline. Your work is saved and will sync automatically when connected.",
    'آپ آف لائن ہیں۔ آپ کا کام محفوظ ہے اور کنکشن ملنے پر خود بخود سنک ہوگا۔',
    'أنت غير متصل. عملك محفوظ وسيتم المزامنة تلقائياً عند الاتصال.',
  );

  factory NetworkException.syncFailed() => const NetworkException(
    'network_sync_failed',
    "Couldn't sync your data. We'll retry automatically.",
    'ڈیٹا سنک نہیں ہو سکا۔ خود بخود دوبارہ کوشش ہوگی۔',
    'تعذرت مزامنة بياناتك. سنعيد المحاولة تلقائياً.',
  );
}

class PeriodException extends AppException {
  const PeriodException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory PeriodException.locked() => const PeriodException(
    'period_locked',
    'This record falls in a locked period. Ask your admin to unlock it first.',
    'یہ ریکارڈ ایک لاک مدت میں آتا ہے۔ پہلے اپنے ایڈمن سے اسے اَن لاک کروائیں۔',
    'هذا السجل يقع ضمن فترة مقفلة. اطلب من المسؤول فتحها أولاً.',
  );
}

class JobException extends AppException {
  const JobException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory JobException.noInvoice() => const JobException(
    'job_no_invoice',
    'Please enter an invoice number.',
    'براہ کرم انوائس نمبر درج کریں۔',
    'يرجى إدخال رقم الفاتورة.',
  );

  factory JobException.noUnits() => const JobException(
    'job_no_units',
    'Add at least one AC unit before submitting.',
    'جمع کرانے سے پہلے کم از کم ایک اے سی یونٹ شامل کریں۔',
    'أضف وحدة تكييف واحدة على الأقل قبل الإرسال.',
  );

  factory JobException.saveFailed() => const JobException(
    'job_save_failed',
    "Couldn't save your job. We'll retry in a moment.",
    'آپ کا کام محفوظ نہیں ہو سکا۔ تھوڑی دیر میں دوبارہ کوشش ہوگی۔',
    'تعذر حفظ عملك. سنعيد المحاولة بعد لحظات.',
  );

  factory JobException.duplicateInvoice() => const JobException(
    'job_duplicate_invoice',
    'A job with this invoice number already exists.',
    'اس انوائس نمبر سے پہلے سے ایک کام موجود ہے۔',
    'يوجد عمل بهذا الرقم بالفعل.',
  );

  factory JobException.sharedUnitsExceeded({required int remaining}) =>
      JobException(
        'job_shared_units_exceeded',
        'Shared units exceed invoice total. Remaining units: $remaining.',
        'شیئرڈ یونٹس انوائس کے کل یونٹس سے زیادہ ہیں۔ باقی یونٹس: $remaining۔',
        'وحدات المشاركة تتجاوز إجمالي الفاتورة. الوحدات المتبقية: $remaining.',
      );

  factory JobException.sharedTypeUnitsExceeded({
    required String unitType,
    required int remaining,
  }) => JobException(
    'job_shared_type_units_exceeded',
    '$unitType units exceed the invoice total. Remaining units: $remaining.',
    '$unitType یونٹس انوائس کے کل سے زیادہ ہیں۔ باقی یونٹس: $remaining۔',
    'وحدات $unitType تتجاوز إجمالي الفاتورة. الوحدات المتبقية: $remaining.',
  );

  factory JobException.sharedDeliverySplitInvalid() => const JobException(
    'job_shared_delivery_split_invalid',
    'Enter the shared team size so delivery charges can be split equally.',
    'مشترکہ ٹیم کی تعداد درج کریں تاکہ ڈیلیوری چارج برابر تقسیم ہو سکے۔',
    'أدخل عدد أعضاء الفريق المشترك ليتم تقسيم رسوم التوصيل بالتساوي.',
  );

  factory JobException.sharedGroupMismatch() => const JobException(
    'job_shared_group_mismatch',
    'This shared invoice already exists with different totals. Use the same shared totals for every technician on this invoice.',
    'یہ مشترکہ انوائس مختلف کل مقدار کے ساتھ پہلے سے موجود ہے۔ اس انوائس پر ہر ٹیکنیشن کے لیے ایک ہی مشترکہ کل مقدار استعمال کریں۔',
    'هذه الفاتورة المشتركة موجودة بالفعل بإجماليات مختلفة. استخدم نفس الإجماليات المشتركة لكل فني في هذه الفاتورة.',
  );

  factory JobException.sharedUnsupportedUnitType({
    required String unitType,
  }) => JobException(
    'job_shared_unsupported_unit_type',
    '$unitType cannot be used on a shared install invoice. Use split, window, freestanding, uninstall split/window/freestanding, and bracket-only shares.',
    '$unitType کو مشترکہ انسٹال انوائس پر استعمال نہیں کیا جا سکتا۔ صرف سپلٹ، ونڈو، فری اسٹینڈنگ، اَن انسٹال سپلٹ/ونڈو/فری اسٹینڈنگ اور بریکٹ شیئر استعمال کریں۔',
    'لا يمكن استخدام $unitType في فاتورة تركيب مشتركة. استخدم فقط السبليت أو الشباك أو الأرضي أو إلغاء تركيب السبليت/الشباك/الأرضي وحصص الحوامل.',
  );

  factory JobException.permissionDenied() => const JobException(
    'job_permission_denied',
    'Permission denied. Please contact your admin.',
    'اجازت نہیں۔ براہ کرم ایڈمن سے رابطہ کریں۔',
    'ليس لديك إذن. تواصل مع المسؤول.',
  );

  factory JobException.approvedRecordLocked() => const JobException(
    'job_approved_record_locked',
    'Approved records are locked. Create a correction entry instead of editing this record.',
    'منظور شدہ ریکارڈ لاک ہیں۔ اس ریکارڈ میں ترمیم کے بجائے ایک نیا اصلاحی اندراج بنائیں۔',
    'السجلات المعتمدة مقفلة. أنشئ قيد تصحيح بدلاً من تعديل هذا السجل.',
  );

  factory JobException.settlementLocked() => const JobException(
    'job_settlement_locked',
    'This job is locked because invoice payment settlement is already in progress or completed.',
    'یہ جاب لاک ہے کیونکہ انوائس ادائیگی کی تصدیق شروع ہو چکی ہے یا مکمل ہو چکی ہے۔',
    'تم قفل هذه المهمة لأن تسوية دفع الفاتورة بدأت بالفعل أو اكتملت.',
  );

  factory JobException.jobNotEditable() => const JobException(
    'job_not_editable',
    'This job cannot be edited in its current state.',
    'اس جاب میں موجودہ حالت میں ترمیم نہیں کی جا سکتی۔',
    'لا يمكن تعديل هذه المهمة في حالتها الحالية.',
  );

  factory JobException.settlementBatchNotFound() => const JobException(
    'job_settlement_batch_not_found',
    'The selected invoice payment batch could not be found.',
    'منتخب انوائس ادائیگی بیچ نہیں ملا۔',
    'تعذر العثور على دفعة سداد الفاتورة المحددة.',
  );

  factory JobException.settlementAlreadyFinalized() => const JobException(
    'job_settlement_already_finalized',
    'This invoice payment batch has already been finalized.',
    'اس انوائس ادائیگی بیچ کو پہلے ہی حتمی کر دیا گیا ہے۔',
    'تم إنهاء دفعة سداد الفاتورة هذه بالفعل.',
  );

  factory JobException.settlementCorrectionCycleExceeded() =>
      const JobException(
        'job_settlement_correction_cycle_exceeded',
        'Only one payment correction cycle is allowed for an invoice batch.',
        'انوائس بیچ کے لیے صرف ایک ادائیگی اصلاحی چکر کی اجازت ہے۔',
        'يسمح بدورة تصحيح دفع واحدة فقط لكل دفعة فواتير.',
      );

  factory JobException.settlementAmountMustBePositive() => const JobException(
    'job_settlement_amount_positive_required',
    'Settlement amount must be greater than zero.',
    'ادائیگی کی رقم صفر سے زیادہ ہونی چاہیے۔',
    'يجب أن يكون مبلغ التسوية أكبر من صفر.',
  );

  factory JobException.settlementPaymentMethodRequired() => const JobException(
    'job_settlement_payment_method_required',
    'Please enter the payment method before sending the settlement batch.',
    'سیٹلمنٹ بیچ بھیجنے سے پہلے ادائیگی کا طریقہ درج کریں۔',
    'يرجى إدخال طريقة الدفع قبل إرسال دفعة التسوية.',
  );

  factory JobException.notTeamMember() => const JobException(
    'job_not_team_member',
    'You are not listed as a team member for this shared invoice. '
        'Ask the first technician who submitted this invoice to include you.',
    'آپ کو اس مشترکہ انوائس کی ٹیم میں شامل نہیں کیا گیا۔ '
        'پہلے ٹیکنیشن سے کہیں کہ وہ آپ کو ٹیم میں شامل کریں۔',
    'أنت لست مدرجاً كعضو في فريق هذه الفاتورة المشتركة. '
        'اطلب من الفني الأول الذي قدّم هذه الفاتورة إضافتك إلى الفريق.',
  );

  /// Thrown when a pending shared install edit attempts to reduce unit counts.
  /// Firestore rules enforce monotone non-decreasing consumed counters to
  /// prevent fraud; this error surfaces that constraint clearly to the UI.
  factory JobException.sharedUnitReductionForbidden() => const JobException(
    'job_shared_unit_reduction_forbidden',
    'Units on a shared install cannot be reduced once submitted. '
        'Contact admin to correct the aggregate totals.',
    'مشترکہ انسٹال میں جمع کرانے کے بعد یونٹ کم نہیں کیے جا سکتے۔ '
        'کل مقدار درست کرنے کے لیے ایڈمن سے رابطہ کریں۔',
    'لا يمكن تقليل الوحدات في التركيب المشترك بعد الإرسال. '
        'تواصل مع المسؤول لتصحيح الإجماليات.',
  );
}

class AdminException extends AppException {
  const AdminException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory AdminException.rejectNoReason() => const AdminException(
    'admin_reject_no_reason',
    'Please add a reason so the technician knows what to fix.',
    'براہ کرم وجہ بتائیں تاکہ ٹیکنیشن کو پتا چلے کیا ٹھیک کرنا ہے۔',
    'يرجى إضافة سبب ليعرف الفني ما يجب إصلاحه.',
  );

  factory AdminException.noPermission() => const AdminException(
    'admin_no_permission',
    "You don't have admin access for this action.",
    'آپ کو اس عمل کے لیے ایڈمن رسائی نہیں ہے۔',
    'ليس لديك صلاحية المسؤول لهذا الإجراء.',
  );

  factory AdminException.flushFailed() => const AdminException(
    'admin_flush_failed',
    "Database flush failed. Please check your connection and try again.",
    'ڈیٹا بیس فلش ناکام ہوا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔',
    'فشل مسح قاعدة البيانات. تحقق من اتصالك وحاول مرة أخرى.',
  );

  factory AdminException.wrongPassword() => const AdminException(
    'admin_wrong_password',
    'Incorrect password. Please try again.',
    'غلط پاس ورڈ۔ دوبارہ کوشش کریں۔',
    'كلمة المرور غير صحيحة. حاول مرة أخرى.',
  );

  factory AdminException.userSaveFailed() => const AdminException(
    'admin_user_save_failed',
    "Couldn't save user changes. Please try again.",
    'صارف کی تبدیلیاں محفوظ نہیں ہو سکیں۔ دوبارہ کوشش کریں۔',
    'تعذر حفظ تغييرات المستخدم. حاول مرة أخرى.',
  );

  factory AdminException.flushRequiresInternet() => const AdminException(
    'admin_flush_requires_internet',
    'Database flush requires a live internet connection. Reconnect and try again.',
    'ڈیٹا بیس فلش کے لیے فعال انٹرنیٹ کنکشن ضروری ہے۔ دوبارہ کنکٹ ہو کر کوشش کریں۔',
    'يتطلب مسح قاعدة البيانات اتصالاً مباشراً بالإنترنت. أعد الاتصال ثم حاول مرة أخرى.',
  );

  factory AdminException.activeSettlementBatchesPreventFlush() =>
      const AdminException(
        'admin_active_settlements_prevent_flush',
        'Flush is blocked while invoice settlement batches are still awaiting resolution.',
        'جب تک انوائس سیٹلمنٹ بیچ زیر التواء ہیں، فلش بلاک رہے گا۔',
        'تم حظر التفريغ ما دامت دفعات تسوية الفواتير بانتظار المعالجة.',
      );
}

class ExpenseException extends AppException {
  const ExpenseException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory ExpenseException.saveFailed() => const ExpenseException(
    'expense_save_failed',
    "Couldn't save your entry. Please check your connection and try again.",
    'آپ کا اندراج محفوظ نہیں ہو سکا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔',
    'تعذر حفظ الإدخال. تحقق من اتصالك وحاول مرة أخرى.',
  );

  factory ExpenseException.deleteFailed() => const ExpenseException(
    'expense_delete_failed',
    "Couldn't delete the entry. Please try again.",
    'اندراج حذف نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
    'تعذر حذف الإدخال. حاول مرة أخرى.',
  );

  factory ExpenseException.userSaveFailed() => const ExpenseException(
    'user_save_failed',
    "Couldn't save changes. Please try again.",
    'تبدیلیاں محفوظ نہیں ہو سکیں۔ دوبارہ کوشش کریں۔',
    'تعذر حفظ التغييرات. حاول مرة أخرى.',
  );

  factory ExpenseException.permissionDenied() => const ExpenseException(
    'expense_permission_denied',
    "You don't have permission to save this expense. Contact your admin.",
    'آپ کو یہ خرچہ محفوظ کرنے کی اجازت نہیں۔ اپنے ایڈمن سے رابطہ کریں۔',
    'ليست لديك صلاحية لحفظ هذا المصروف. تواصل مع المسؤول.',
  );

  factory ExpenseException.approvedRecordLocked() => const ExpenseException(
    'expense_approved_record_locked',
    'Approved records are locked. Create a correction entry instead of editing this record.',
    'منظور شدہ ریکارڈ لاک ہیں۔ اس ریکارڈ میں ترمیم کے بجائے ایک نیا اصلاحی اندراج بنائیں۔',
    'السجلات المعتمدة مقفلة. أنشئ قيد تصحيح بدلاً من تعديل هذا السجل.',
  );
}

class EarningException extends AppException {
  const EarningException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory EarningException.saveFailed() => const EarningException(
    'earning_save_failed',
    "Couldn't save your earning. Please check your connection and try again.",
    'آپ کی آمدنی محفوظ نہیں ہو سکی۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔',
    'تعذر حفظ الإيراد. تحقق من اتصالك وحاول مرة أخرى.',
  );

  factory EarningException.deleteFailed() => const EarningException(
    'earning_delete_failed',
    "Couldn't delete the earning. Please try again.",
    'آمدنی حذف نہیں ہو سکی۔ دوبارہ کوشش کریں۔',
    'تعذر حذف الإيراد. حاول مرة أخرى.',
  );

  factory EarningException.updateFailed() => const EarningException(
    'earning_update_failed',
    "Couldn't save changes to the earning. Please try again.",
    'آمدنی میں تبدیلیاں محفوظ نہیں ہو سکیں۔ دوبارہ کوشش کریں۔',
    'تعذر حفظ تغييرات الإيراد. حاول مرة أخرى.',
  );

  factory EarningException.permissionDenied() => const EarningException(
    'earning_permission_denied',
    "You don't have permission to save this earning. Contact your admin.",
    'آپ کو یہ آمدنی محفوظ کرنے کی اجازت نہیں۔ اپنے ایڈمن سے رابطہ کریں۔',
    'ليست لديك صلاحية لحفظ هذا الإيراد. تواصل مع المسؤول.',
  );

  factory EarningException.approvedRecordLocked() => const EarningException(
    'earning_approved_record_locked',
    'Approved records are locked. Create a correction entry instead of editing this record.',
    'منظور شدہ ریکارڈ لاک ہیں۔ اس ریکارڈ میں ترمیم کے بجائے ایک نیا اصلاحی اندراج بنائیں۔',
    'السجلات المعتمدة مقفلة. أنشئ قيد تصحيح بدلاً من تعديل هذا السجل.',
  );
}

class AcInstallException extends AppException {
  const AcInstallException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory AcInstallException.saveFailed() => const AcInstallException(
    'ac_install_save_failed',
    "Couldn't save the installation record. Please check your connection and try again.",
    'تنصیب ریکارڈ محفوظ نہیں ہو سکا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔',
    'تعذر حفظ سجل التركيب. تحقق من اتصالك وحاول مرة أخرى.',
  );

  factory AcInstallException.deleteFailed() => const AcInstallException(
    'ac_install_delete_failed',
    "Couldn't delete the installation record. Please try again.",
    'تنصیب ریکارڈ حذف نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
    'تعذر حذف سجل التركيب. حاول مرة أخرى.',
  );

  factory AcInstallException.updateFailed() => const AcInstallException(
    'ac_install_update_failed',
    "Couldn't update the installation record. Please try again.",
    'تنصیب ریکارڈ اپ ڈیٹ نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
    'تعذر تحديث سجل التركيب. حاول مرة أخرى.',
  );

  factory AcInstallException.approvedRecordLocked() => const AcInstallException(
    'ac_install_approved_record_locked',
    'Approved records are locked. Create a correction entry instead of editing this record.',
    'منظور شدہ ریکارڈ لاک ہیں۔ اس ریکارڈ میں ترمیم کے بجائے ایک نیا اصلاحی اندراج بنائیں۔',
    'السجلات المعتمدة مقفلة. أنشئ قيد تصحيح بدلاً من تعديل هذا السجل.',
  );
}
