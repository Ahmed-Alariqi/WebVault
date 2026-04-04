// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get settings => 'الإعدادات';

  @override
  String get account => 'الحساب';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get viewAndEditProfile => 'عرض وتعديل ملفك الشخصي';

  @override
  String get adminDashboard => 'لوحة التحكم';

  @override
  String get manageContentAndUsers => 'إدارة المحتوى والمستخدمين';

  @override
  String get appearance => 'المظهر';

  @override
  String get system => 'النظام';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get securityAndPrivacy => 'الأمان والخصوصية';

  @override
  String get securitySettings => 'إعدادات الأمان';

  @override
  String get securitySubtitle => 'رمز المرور، البصمة، حماية اللقطات';

  @override
  String get data => 'البيانات';

  @override
  String get exportBackup => 'تصدير نسخة احتياطية';

  @override
  String get saveAllDataAsJson => 'حفظ جميع البيانات كملف JSON';

  @override
  String get importBackup => 'استيراد نسخة احتياطية';

  @override
  String get restoreFromJson => 'استعادة من ملف JSON';

  @override
  String get exportFeatureComingSoon => 'ميزة التصدير قادمة قريباً';

  @override
  String get importFeatureComingSoon => 'ميزة الاستيراد قادمة قريباً';

  @override
  String get about => 'حول التطبيق';

  @override
  String get version => 'الإصدار';

  @override
  String get home => 'الرئيسية';

  @override
  String get discover => 'استكشاف';

  @override
  String get search => 'بحث';

  @override
  String get pages => 'الصفحات';

  @override
  String get folders => 'المجلدات';

  @override
  String get clipboard => 'الحافظة';

  @override
  String get userProfile => 'ملف المستخدم';

  @override
  String get welcomeBack => 'أهلاً بك مجدداً في خزنتك!';

  @override
  String get manageSettings => 'إدارة الإعدادات';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'طاب مساؤك';

  @override
  String get language => 'اللغة';

  @override
  String get changeLanguage => 'تغيير لغة العرض';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get vaultOverview => 'نظرة عامة';

  @override
  String get totalPages => 'الصفحات';

  @override
  String get favorites => 'المفضلة';

  @override
  String get topVault => 'الأكثر زيارة';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get yourVaultIsEmpty => 'الخزنة فارغة';

  @override
  String get addFirstPage => 'أضف صفحتك الأولى للبدء';

  @override
  String get addMyFirstPage => 'إضافة الصفحة الأولى';

  @override
  String get newPage => 'صفحة جديدة';

  @override
  String get security => 'الأمان';

  @override
  String get mostVisited => 'الأكثر زيارة';

  @override
  String get lifetimeVisits => 'زيارة';

  @override
  String get appName => 'زاد تك';

  @override
  String get newFolder => 'مجلد جديد';

  @override
  String get folderName => 'اسم المجلد';

  @override
  String get createFolder => 'إنشاء مجلد';

  @override
  String get deleteFolder => 'حذف المجلد';

  @override
  String get deleteFolderConfirmation =>
      'لن يتم حذف الصفحات، فقط إزالتها من المجلد.';

  @override
  String get folderEmpty => 'هذا المجلد فارغ';

  @override
  String get addPagesFromBrowser => 'أضف صفحات من المتصفح';

  @override
  String get addToFolder => 'إضافة إلى مجلد';

  @override
  String addedTo(String folder) {
    return 'تمت الإضافة إلى $folder';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصراً',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا توجد عناصر',
    );
    return '$_temp0';
  }

  @override
  String get noFoldersYet => 'لم يتم إنشاء مجلدات بعد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get color => 'اللون';

  @override
  String get icon => 'الأيقونة';

  @override
  String get selectStartPage => 'اختر صفحة البداية';

  @override
  String get error => 'خطأ';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get back => 'رجوع';

  @override
  String get forward => 'أمام';

  @override
  String get refresh => 'تحديث';

  @override
  String get openInBrowser => 'فتح في المتصفح';

  @override
  String get suggestToAdmin => 'اقتراح للإدارة';

  @override
  String get suggestionSent => 'تم إرسال الاقتراح للإدارة';

  @override
  String get suggestionDescription => 'وصف (اختياري)';

  @override
  String get submitSuggestion => 'إرسال الاقتراح';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get approved => 'مقبول';

  @override
  String get rejected => 'مرفوض';

  @override
  String get suggestionRejected => 'تم رفض الاقتراح';

  @override
  String get suggestionApproved => 'تم قبول الاقتراح ونشره';

  @override
  String get publish => 'نشر';

  @override
  String get userSuggestions => 'اقتراحات المستخدمين';

  @override
  String get originalUrl => 'الرابط الأصلي';

  @override
  String get suggestedBy => 'اقترحه';

  @override
  String get approve => 'موافقة';

  @override
  String get reject => 'رفض';

  @override
  String get noSuggestions => 'لا توجد اقتراحات';

  @override
  String get manageUsers => 'إدارة المستخدمين';

  @override
  String get searchUsers => 'بحث بالبريد أو الاسم...';

  @override
  String get addUser => 'إضافة مستخدم';

  @override
  String get editUser => 'تعديل مستخدم';

  @override
  String get noUsersFound => 'لا يوجد مستخدمين';

  @override
  String get howItWorks => 'كيف تعمل؟';

  @override
  String get discoverTitle => 'المستكشف';

  @override
  String get openButton => 'فتح';

  @override
  String get detailsButton => 'التفاصيل';

  @override
  String get communityTitle => 'المجتمع';

  @override
  String get dismissButton => 'تجاهل';

  @override
  String get emptySearchTitle => 'لا توجد نتائج';

  @override
  String get noMatchesFound => 'لا توجد نتائج';

  @override
  String get deleteUserTitle => 'حذف المستخدم؟';

  @override
  String deleteUserConfirm(String email) {
    return 'هل أنت متأكد من حذف $email؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get userDeleted => 'تم حذف المستخدم بنجاح';

  @override
  String get userUpdated => 'تم تحديث بيانات المستخدم';

  @override
  String get userCreated => 'تم إنشاء المستخدم';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get role => 'الدور';

  @override
  String get admin => 'مسؤول';

  @override
  String get user => 'مستخدم';

  @override
  String get save => 'حفظ';

  @override
  String get create => 'إنشاء';

  @override
  String get required => 'مطلوب';

  @override
  String get min6Chars => '6 محارف على الأقل';

  @override
  String get editChangeRole => 'تعديل / تغيير الدور';

  @override
  String lastLogin(String date) {
    return 'آخر دخول: $date';
  }

  @override
  String get backupSuccessful => 'تم إنشاء النسخة الاحتياطية بنجاح';

  @override
  String get importSuccessful => 'تم الاستيراد بنجاح';

  @override
  String get backupFailed => 'فشل إنشاء النسخة الاحتياطية';

  @override
  String get importFailed => 'فشل الاستيراد';

  @override
  String get invalidBackupFile => 'ملف نسخة احتياطية غير صالح';

  @override
  String get personalInfo => 'المعلومات الشخصية';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي';

  @override
  String get saveProfile => 'حفظ الملف الشخصي';

  @override
  String get contactSupport => 'الاتصال بالدعم';

  @override
  String get signOutLabel => 'تسجيل الخروج';

  @override
  String get getHelpFromAdmin => 'الحصول على مساعدة من مسؤول';

  @override
  String get clipboardSettings => 'إعدادات الحافظة';

  @override
  String get clipboardSettingsSubtitle =>
      'الحافظة العائمة، إذن التراكب، النسخ الذكي والنصائح';

  @override
  String get support => 'الدعم';

  @override
  String get addValue => 'إضافة قيمة';

  @override
  String get folderNotFound => 'لم يتم العثور على المجلد';

  @override
  String createdOn(String date) {
    return 'تم الإنشاء في $date';
  }

  @override
  String get createFoldersToOrganize => 'أنشئ مجلدات لتنظيم صفحاتك';

  @override
  String get egFinance => 'مثل: المالية';

  @override
  String get adminBadge => 'المدير التقني';

  @override
  String get controlCenter => 'مركز التحكم';

  @override
  String get manageVaultEcosystem => 'إدارة نظام ومحتوى تطبيق زاد التقني';

  @override
  String get management => 'الإدارة';

  @override
  String get appActivities => 'أنشطة التطبيق';

  @override
  String get analyticsTracking => 'التحليلات والتتبع';

  @override
  String get suggestionsTitle => 'الاقتراحات';

  @override
  String get reviewRequests => 'مراجعة الطلبات';

  @override
  String get websitesTitle => 'محتوى المستكشف';

  @override
  String get addEditSites => 'ادارة محتوى عناصر المستكشف';

  @override
  String get categoriesTitle => 'التصنيفات';

  @override
  String get organizeContent => 'تنظيم المحتوى';

  @override
  String get pushNotificationsTitle => 'الإشعارات المباشرة';

  @override
  String get sendOutsideAlerts => 'إرسال تنبيهات خارجية';

  @override
  String get inAppMessagesTitle => 'رسائل داخل التطبيق';

  @override
  String get popupCampaigns => 'حملات منبثقة';

  @override
  String get usersTitle => 'المستخدمين';

  @override
  String get viewAccounts => 'عرض الحسابات';

  @override
  String get managePosts => 'إدارة المنشورات';

  @override
  String get userMessagesTitle => 'رسائل المستخدمين';

  @override
  String get supportChats => 'محادثات الدعم';

  @override
  String get totalUsers => 'إجمالي المستخدمين';

  @override
  String get accessRestricted => 'الوصول مقيد';

  @override
  String get adminPrivilegesRequired => 'مطلوب صلاحيات مسؤول.';

  @override
  String get returnHome => 'العودة للرئيسية';

  @override
  String get quickClipboard => 'الحافظة السريعة';

  @override
  String get all => 'الكل';

  @override
  String get noClipboardItems => 'لا توجد عناصر بعد';

  @override
  String injectedItem(String label) {
    return 'تم إدراج \"$label\"';
  }

  @override
  String get selectTextFieldFirst => 'الرجاء تحديد حقل نصي أولاً.';

  @override
  String copiedItem(String label) {
    return 'تم نسخ \"$label\"';
  }

  @override
  String get copied => 'تم النسخ';

  @override
  String get savedToVault => 'تم الحفظ في القبو';

  @override
  String get savedExplicitlyToClipboard =>
      'تم الحفظ بشكل صريح في حافظة زاد تك!';

  @override
  String get savedToClipboard => 'تم الحفظ في حافظة زاد تك!';

  @override
  String get saveToVaultBtn => 'حفظ في القبو';

  @override
  String get promptSaveToVault =>
      'هل ترغب في حفظ هذا النص في حافظة زاد تك لاستخدامه لاحقًا؟';

  @override
  String get copiedText => 'نص منسوخ';

  @override
  String get quickAddToClipboard => 'إضافة سريعة للحافظة';

  @override
  String get pasteOrTypeText => 'الصق أو اكتب النص هنا...';

  @override
  String get manualEntry => 'إدخال يدوي';

  @override
  String get approvePublish => 'موافقة ونشر';

  @override
  String get titleLabel => 'العنوان';

  @override
  String get urlLabel => 'الرابط';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get trending => 'الرائج';

  @override
  String get popular => 'شائع';

  @override
  String get featured => 'المميز';

  @override
  String get suggestionApprovedPublished => 'تمت الموافقة على الاقتراح ونشره!';

  @override
  String errorMessage(String message) {
    return 'خطأ: $message';
  }

  @override
  String get noPendingSuggestions => 'لا توجد اقتراحات معلقة';

  @override
  String suggestedDate(String date) {
    return 'مقترح: $date';
  }

  @override
  String get manageCategoriesTitle => 'إدارة التصنيفات';

  @override
  String get seedDefaultCategories => 'زرع التصنيفات الافتراضية';

  @override
  String get noCategories => 'لا توجد تصنيفات';

  @override
  String get defaultCategoriesInjected => 'تم زرع التصنيفات الافتراضية بنجاح!';

  @override
  String failedToSeedCategories(String message) {
    return 'فشل زرع التصنيفات: $message';
  }

  @override
  String get addCategory => 'إضافة تصنيف';

  @override
  String get editCategory => 'تعديل التصنيف';

  @override
  String get categoryName => 'اسم التصنيف';

  @override
  String get addBtn => 'إضافة';

  @override
  String get manageItemsTitle => 'إدارة العناصر';

  @override
  String get noItemsYet => 'لا توجد عناصر بعد';

  @override
  String get tapPlusToAddOne => 'اضغط على + لإضافة عنصر';

  @override
  String get newItem => 'عنصر جديد';

  @override
  String get promptBadge => 'موجّه';

  @override
  String get offerBadge => 'عرض';

  @override
  String get newsBadge => 'أخبار';

  @override
  String get tutorialBadge => 'شرح';

  @override
  String get websiteBadge => 'موقع';

  @override
  String get toolBadge => 'أداة';

  @override
  String get courseBadge => 'كورس';

  @override
  String get pricingPaid => 'مدفوع';

  @override
  String get pricingFree => 'مجاني';

  @override
  String get pricingFreemium => 'مجاني جزئياً';

  @override
  String get expiredBadge => 'منتهي الصلاحية';

  @override
  String daysLeft(String days) {
    return '$daysي متبقي';
  }

  @override
  String hoursLeft(String hours) {
    return '$hoursس متبقية';
  }

  @override
  String minsLeft(String mins) {
    return '$minsد متبقية';
  }

  @override
  String get promptText => 'نص الموجّه';

  @override
  String get codeOrKey => 'الرمز / المفتاح';

  @override
  String get copiedTooltip => 'تم النسخ!';

  @override
  String get copy => 'نسخ';

  @override
  String get promptCopiedTooltip => 'تم نسخ الموجّه!';

  @override
  String get copyPrompt => 'نسخ الموجّه';

  @override
  String get tryIt => 'جرّبها';

  @override
  String get offerCopiedTooltip => 'تم نسخ الرمز!';

  @override
  String get copyCode => 'نسخ الرمز';

  @override
  String get visit => 'زيارة';

  @override
  String get visitLink => 'زيارة الرابط';

  @override
  String get openApp => 'فتح التطبيق';

  @override
  String get videoPlaybackError => 'خطأ في تشغيل الفيديو';

  @override
  String get openExternally => 'فتح خارجياً';

  @override
  String get watchTutorial => 'مشاهدة الشرح';

  @override
  String get watchVideo => 'مشاهدة الفيديو';

  @override
  String get opensOnYoutube => 'يفتح في يوتيوب';

  @override
  String get opensOnVimeo => 'يفتح في فيميو';

  @override
  String get opensInBrowser => 'يفتح في المتصفح';

  @override
  String get couldNotLoadVideo => 'تعذر تحميل الفيديو';

  @override
  String get titleMessageRequired => 'العنوان والرسالة مطلوبان';

  @override
  String get campaignUpdated => 'تم تحديث الحملة';

  @override
  String get campaignCreated => 'تم إنشاء الحملة';

  @override
  String get offlineWarningDetails =>
      'أنت غير متصل بالإنترنت. يرجى التحقق من اتصالك.';

  @override
  String failedWarning(String error) {
    return 'فشل: $error';
  }

  @override
  String get previewBadge => 'معاينة';

  @override
  String get invalidUrl => 'رابط غير صالح';

  @override
  String get closePreview => 'إغلاق المعاينة';

  @override
  String failedToUpdateStatus(String error) {
    return 'فشل في تحديث الحالة: $error';
  }

  @override
  String get deleteMessageTitle => 'حذف الرسالة؟';

  @override
  String get deleteMessageContent => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get cancelLabel => 'إلغاء';

  @override
  String get deleteLabel => 'حذف';

  @override
  String deleteFailedWarning(String error) {
    return 'فشل الحذف: $error';
  }

  @override
  String get editCampaign => 'تعديل الحملة';

  @override
  String get newCampaign => 'حملة جديدة';

  @override
  String get cancelEdit => 'إلغاء التعديل';

  @override
  String get messageLabel => 'الرسالة';

  @override
  String get campaignImageOptional => 'صورة الحملة (اختياري)';

  @override
  String get imageUploadedSuccessfully => 'تم رفع الصورة بنجاح!';

  @override
  String get uploadFailed => 'فشل الرفع. حاول مرة أخرى.';

  @override
  String get uploading => 'جاري الرفع...';

  @override
  String get uploadFromDevice => 'رفع من الجهاز';

  @override
  String get orPasteUrl => 'أو الصق الرابط';

  @override
  String get imageUrlLabel => 'رابط الصورة';

  @override
  String get buttonUrlOptional => 'رابط الزر (اختياري)';

  @override
  String get buttonTextOptional => 'نص الزر (اختياري)';

  @override
  String get campaignModeLabel => 'وضع الحملة';

  @override
  String get modeStandard => 'قياسي';

  @override
  String get modeRecurring => 'متكرر';

  @override
  String get modeHardBlock => 'توقف إجباري';

  @override
  String get modeStandardDesc => 'تظهر مرة واحدة للمستخدم. يمكنهم رفضها للأبد.';

  @override
  String get modeRecurringDesc =>
      'تظهر في كل مرة يفتح فيها المستخدم التطبيق، ولكن يمكن رفضها.';

  @override
  String get modeHardBlockDesc =>
      'تظهر دائماً، ولا يمكن رفضها. توقف التطبيق بالكامل.';

  @override
  String get targetVersionOptional =>
      'يتطلب إصدار معين (مثال: 1.0.5) (اختياري)';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get updateCampaign => 'تحديث الحملة';

  @override
  String get createCampaign => 'إنشاء الحملة';

  @override
  String get existingCampaigns => 'الحملات الحالية';

  @override
  String get noCampaignsYet => 'لا توجد حملات بعد.';

  @override
  String get activeBadge => 'نشط';

  @override
  String updateBadge(String version) {
    return 'تحديث: $version';
  }

  @override
  String get hardBlockBadge => 'توقف إجباري';

  @override
  String get recurringBadge => 'متكرر';

  @override
  String get editTooltip => 'تعديل';

  @override
  String get deleteTooltip => 'حذف';

  @override
  String get personalizeNameToggle => 'تخصيص باسم المستخدم';

  @override
  String personalizeNameHint(String userName) {
    return 'اكتب $userName في العنوان أو الرسالة لإدراج اسم المستخدم.';
  }

  @override
  String insertUserName(String userName) {
    return 'إدراج $userName';
  }

  @override
  String get defaultUserFallback => 'مستخدم';

  @override
  String get noName => 'بلا اسم';

  @override
  String get noEmail => 'بلا بريد إلكتروني';

  @override
  String get emailPasswordChangeNote =>
      'ملاحظة: لتغيير البريد الإلكتروني/كلمة المرور، يرجى استخدام لوحة تحكم المصادقة أو إضافة المنطق إلى الواجهة الخلفية.';

  @override
  String get wipeChatTitle => 'مسح كل الدردشة؟';

  @override
  String get wipeChatContent =>
      'سيؤدي هذا إلى حذف جميع المنشورات والردود والتفاعلات في المجتمع بشكل دائم لتحرير مساحة تخزين قاعدة البيانات. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get wipeChatAction => 'مسح الدردشة';

  @override
  String get chatWipedSuccess => 'تم مسح الدردشة بنجاح.';

  @override
  String chatWipedFailed(String error) {
    return 'فشل في مسح الدردشة: $error';
  }

  @override
  String pinPostFailed(String error) {
    return 'فشل في تثبيت المنشور: $error';
  }

  @override
  String get communityManagement => 'إدارة المجتمع';

  @override
  String get wipeAllChatTooltip => 'مسح كل الدردشة';

  @override
  String get wipeChatInfo =>
      'استخدم أيقونة سلة المهملات في أعلى اليمين لمسح جميع منشورات المجتمع بشكل دائم وتحرير مساحة تخزين Supabase.';

  @override
  String get noCommunityPosts => 'لا توجد منشورات في المجتمع.';

  @override
  String get unpinPostTooltip => 'إلغاء تثبيت المنشور';

  @override
  String get pinPostTooltip => 'تثبيت المنشور';

  @override
  String get deletePostTitle => 'حذف المنشور؟';

  @override
  String get deletePostContent => 'هل أنت متأكد أنك تريد حذف هذا المنشور؟';

  @override
  String get deletePostAction => 'حذف المنشور';

  @override
  String get youAreOfflineTitle => 'أنت غير متصل';

  @override
  String get youAreOfflineDesc => 'يرجى التحقق من اتصال الإنترنت الخاص بك.';

  @override
  String get authToSignIn => 'المصادقة لتسجيل الدخول';

  @override
  String get invalidEmailOrPassword =>
      'البريد الإلكتروني أو كلمة المرور غير صالحة';

  @override
  String get verifyEmailFirst => 'يرجى التحقق من بريدك الإلكتروني أولاً';

  @override
  String get networkErrorCheckConnection => 'خطأ في الشبكة. تحقق من اتصالك';

  @override
  String get loginFailedTryAgain => 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى';

  @override
  String get secureWebManager => 'اكتشف، احفظ، واسترجع فورأ';

  @override
  String get emailHint => 'your@email.com';

  @override
  String get passwordHint => '••••••••';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get useBiometrics => 'استخدام البصمة';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get passwordStrengthWeak => 'ضعيفة';

  @override
  String get passwordStrengthFair => 'مقبولة';

  @override
  String get passwordStrengthGood => 'جيدة';

  @override
  String get passwordStrengthStrong => 'قوية';

  @override
  String get emailAlreadyRegistered =>
      'هذا البريد الإلكتروني مسجل بالفعل. جرب تسجيل الدخول.';

  @override
  String get invalidEmailAddress =>
      'عنوان البريد الإلكتروني غير صالح. يرجى استخدام بريد إلكتروني حقيقي.';

  @override
  String get tooManyAttempts => 'محاولات كثيرة جدًا. يرجى الانتظار بضع دقائق.';

  @override
  String get passwordTooWeak =>
      'كلمة المرور ضعيفة جدًا. استخدم 6 أحرف على الأقل.';

  @override
  String signUpFailed(String error) {
    return 'فشل التسجيل: $error';
  }

  @override
  String get accountCreated => 'تم إنشاء الحساب!';

  @override
  String verifyEmailDesc(String email) {
    return 'لقد أرسلنا بريدًا إلكترونيًا للتحقق إلى\n$email\n\nيرجى التحقق من بريدك الإلكتروني، ثم تسجيل الدخول.';
  }

  @override
  String get goToSignIn => 'الذهاب لتسجيل الدخول';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get nameHint => 'فلان الفلاني';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get usernameOptional => 'اسم المستخدم (اختياري)';

  @override
  String get usernameHint => 'اسم_مستخدم';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get enterValidEmail => 'أدخل بريد إلكتروني صالح';

  @override
  String get passwordMinLength =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get creatingAccount => 'جاري إنشاء الحساب...';

  @override
  String get signUpWithGoogle => 'التسجيل باستخدام Google';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get faceId => 'التعرف على الوجه';

  @override
  String get fingerprint => 'بصمة الإصبع';

  @override
  String get iris => 'بصمة العين';

  @override
  String get biometrics => 'المقاييس الحيوية';

  @override
  String get immediately => 'فوراً';

  @override
  String timeoutSeconds(int seconds) {
    return '$seconds ثانية';
  }

  @override
  String timeoutMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get maximumProtection => 'حماية قصوى';

  @override
  String get goodProtection => 'حماية جيدة';

  @override
  String get basicProtection => 'حماية أساسية';

  @override
  String get pinProtection => 'حماية رمز المرور';

  @override
  String get pinLock => 'قفل برمز المرور';

  @override
  String get enabledStr => 'مُفعل';

  @override
  String get off => 'متوقف';

  @override
  String get changePin => 'تغيير رمز المرور';

  @override
  String get updateSecurityPin => 'تحديث رمز المرور الأمني الخاص بك';

  @override
  String get biometricAuth => 'المصادقة الحيوية';

  @override
  String get enabledQuickUnlock => 'مُفعل — فتح سريع';

  @override
  String get tapToEnable => 'انقر للتفعيل';

  @override
  String get notAvailableOnDevice => 'غير متوفر على هذا الجهاز';

  @override
  String get verifyToEnableBiometric => 'تحقق لتفعيل الفتح الحيوي';

  @override
  String biometricSetupFailed(String error) {
    return 'فشل إعداد المقاييس الحيوية: $error';
  }

  @override
  String get setupPinFirstForBiometric =>
      'قم بإعداد رمز مرور أولاً لتفعيل المصادقة الحيوية';

  @override
  String get appLockSettings => 'إعدادات قفل التطبيق';

  @override
  String get autoLockTimeout => 'مهلة القفل التلقائي';

  @override
  String get removePinQ => 'إزالة رمز المرور؟';

  @override
  String get removePinWarning =>
      'سيؤدي هذا إلى تعطيل قفل رمز المرور والمصادقة الحيوية. لن يكون تطبيقك محمياً بعد الآن.';

  @override
  String get remove => 'إزالة';

  @override
  String get securityTip => 'نصيحة أمنية';

  @override
  String get securityTipDesc =>
      'قم بتفعيل كلاً من رمز المرور والمقاييس الحيوية للحصول على حماية قصوى لصفحاتك المحفوظة وبيانات الحافظة.';

  @override
  String get verifyCurrentPin => 'التحقق من رمز المرور الحالي';

  @override
  String get incorrectPin => 'رمز مرور غير صحيح';

  @override
  String get enterCurrentPin => 'أدخل رمز المرور الحالي';

  @override
  String get howToSave => 'كيفية الحفظ';

  @override
  String get savingTextFromOtherApps => 'حفظ النص من التطبيقات الأخرى';

  @override
  String get savingTextInstructions =>
      '1. المشاركة: حدد نصًا في أي تطبيق، وانقر على \"مشاركة\"، واختر زاد تك.\n2. تحديد النص: حدد نصًا واختر \"زاد تك\" من القائمة المنبثقة.\n3. لوحة الإعدادات السريعة: أضف زاد تك إلى الإعدادات السريعة للوصول إلى الحافظة من أي مكان.';

  @override
  String get smartClipboard => 'الحافظة الذكية';

  @override
  String get smartBackgroundCopy => 'النسخ الذكي في الخلفية';

  @override
  String get enabledSavesEverything => 'مُفعل — يحفظ كل ما تنسخه';

  @override
  String get offManualSaveOnly => 'متوقف — الحفظ اليدوي فقط';

  @override
  String get howSmartCopyWorks => 'كيف يعمل النسخ الذكي';

  @override
  String get smartCopyDescription =>
      'عند تفعيله، يتم حفظ أي نص تنسخه في حافظة جهازك تلقائيًا في زاد تك في الخلفية (يتطلب Android 10+ تشغيل الخدمة في الخلفية).';

  @override
  String get howToUse => 'كيفية الاستخدام';

  @override
  String get tapToCopyItem => 'انقر على أي عنصر لنسخه فوراً';

  @override
  String get tapToCopyItemDesc => 'يعمل فوراً داخل شاشة الحافظة';

  @override
  String get pinImportantItems => 'تثبيت العناصر المهمة في الأعلى';

  @override
  String get pinImportantItemsDesc => 'اضغط مطولاً على أي عنصر لتثبيته';

  @override
  String get organiseWithGroups => 'التنظيم باستخدام المجموعات';

  @override
  String get organiseWithGroupsDesc =>
      'قم بإنشاء مجموعات لترتيب الحافظة وتسهيل تصفيتها';

  @override
  String get shareDirectlyToVault => 'المشاركة مباشرة إلى زاد تك';

  @override
  String get shareDirectlyToVaultDesc =>
      'في أي تطبيق: حدد النص → مشاركة → زاد تك Clipboard للحفظ';

  @override
  String get pullToRefresh => 'السحب للتحديث';

  @override
  String get pullToRefreshDesc =>
      'اسحب لأسفل في القائمة لإعادة تحميل العناصر من التخزين';

  @override
  String get identitySection => 'الهوية';

  @override
  String get organizationSection => 'التنظيم';

  @override
  String get detailsSection => 'التفاصيل';

  @override
  String get cardButtonEdit => 'تعديل';

  @override
  String get cardButtonDelete => 'حذف';

  @override
  String get confirmDeletionTitle => 'تأكيد الحذف';

  @override
  String confirmDeletionMessage(String name) {
    return 'حذف \"$name\"؟';
  }

  @override
  String get badgeInactive => 'غير نشط';

  @override
  String get badgeExpired => 'منتهي';

  @override
  String get badgeTrending => 'رائج';

  @override
  String get badgePopular => 'شائع';

  @override
  String get badgeFeatured => 'مميز';

  @override
  String get badgePrompt => 'تلقينة';

  @override
  String get badgeOffer => 'عرض';

  @override
  String get badgeAnnounce => 'إعلان';

  @override
  String get badgeTutorial => 'شرح';

  @override
  String get badgeWebsite => 'موقع';

  @override
  String get readMoreText => 'إقرأ المزيد...';

  @override
  String get copyButton => 'نسخ';

  @override
  String formPublishItem(String type) {
    return 'نشر $type';
  }

  @override
  String get formSaveChanges => 'حفظ التغييرات';

  @override
  String formNewItem(String type) {
    return '$type جديد';
  }

  @override
  String formEditItem(String type) {
    return 'تعديل $type';
  }

  @override
  String get formContentType => 'نوع المحتوى';

  @override
  String get formTypeTools => 'أدوات';

  @override
  String get formTypeCourses => 'دورات';

  @override
  String get formTypeResources => 'مواقع';

  @override
  String get formTypePrompts => 'تلقينات';

  @override
  String get formTypeOffers => 'عروض';

  @override
  String get formTypeNews => 'أخبار';

  @override
  String get formTypeTutorials => 'شروحات';

  @override
  String get formBasicInfo => 'المعلومات الأساسية';

  @override
  String formTypeTitle(String type) {
    return 'عنوان الـ $type';
  }

  @override
  String get formUrlRequiredWeb => 'الرابط (https://...)';

  @override
  String get formUrlRequiredTool => 'رابط الأداة / رابط التحميل';

  @override
  String get formUrlRequiredCourse => 'رابط الكورس / رابط التسجيل';

  @override
  String get formUrlPromptRef => 'الرابط المرجعي (اختياري)';

  @override
  String get formUrlOfferRef => 'رابط العرض / المتجر (اختياري)';

  @override
  String get formUrlNewsRef => 'رابط المقال الأصلي (اختياري)';

  @override
  String get formUrlTutorialRef => 'رابط الشرح (اختياري)';

  @override
  String get formUrlOptional => 'الرابط (اختياري)';

  @override
  String get formUrlOptionalHelper => 'اختياري: أضف رابط للمستخدمين لزيارته';

  @override
  String get formUrlToolHelper =>
      'رابط الأداة، أو رابط التحميل، أو صفحة الأداة الرئيسية';

  @override
  String get formUrlCourseHelper => 'رابط الكورس أو صفحة معلومات الكورس';

  @override
  String get formCoverImage => 'صورة الغلاف';

  @override
  String get formUploading => 'جاري الرفع...';

  @override
  String get formUploadDevice => 'رفع من الجهاز';

  @override
  String get formOrPasteUrl => 'أو الصق الرابط';

  @override
  String get formImageUrl => 'رابط الصورة';

  @override
  String get formPromptImgHelper => 'أضف صورة توضح نتيجة التلقينة';

  @override
  String get formInvalidUrl => 'رابط غير صالح';

  @override
  String get formTutorialVideo => 'فيديو توضيحي';

  @override
  String get formVideoHelper =>
      'أضف فيديو تعليمي أو توضيحي (الحد الأقصى ٥٠ ميجابايت)';

  @override
  String get formUploadingVideo => 'جاري رفع الفيديو...';

  @override
  String get formUploadVideoDevice => 'رفع فيديو من الجهاز';

  @override
  String get formVideoUrlLabel => 'رابط الفيديو (أو الصق الرابط)';

  @override
  String get formActionPromptHeader => 'محتوى التلقين';

  @override
  String get formActionOfferHeader => 'تفاصيل العرض';

  @override
  String get formActionToolHeader => 'تفاصيل الوصول';

  @override
  String get formActionCourseHeader => 'معلومات التسجيل';

  @override
  String get formActionNewsHeader => 'أهم نقاط المقال';

  @override
  String get formActionTutorialHeader => 'خطوات الشرح / ملاحظات';

  @override
  String get formActionDefaultHeader => 'محتوى إضافي';

  @override
  String get formActionPromptLabel => 'نص التلقين';

  @override
  String get formActionOfferLabel => 'كوبون / رمز الخصم';

  @override
  String get formActionToolLabel => 'مفتاح API / رمز الوصول (اختياري)';

  @override
  String get formActionCourseLabel => 'رمز التسجيل (اختياري)';

  @override
  String get formActionNewsLabel => 'أهم النقاط / ملخص';

  @override
  String get formActionTutorialLabel => 'الخطوات / التعليمات (اختياري)';

  @override
  String get formActionDefaultLabel => 'القيمة القابلة للنسخ (اختياري)';

  @override
  String get formPromptText => 'نص التلقينة';

  @override
  String get formOfferCode => 'رمز العرض / المفتاح';

  @override
  String get formAnnounceText => 'نص الإعلان';

  @override
  String get formPromptInput => 'أدخل نص التلقينة (ليقوم المستخدمون بنسخه)';

  @override
  String get formOfferInput => 'أدخل الرمز أو المفتاح أو تفاصيل العرض';

  @override
  String get formAnnounceInput => 'تفاصيل الإعلان (اختياري)';

  @override
  String get formCopyHelper => 'سيرى المستخدمون زر نسخ لهذا المحتوى';

  @override
  String formExpires(String date) {
    return 'ينتهي في: $date';
  }

  @override
  String get formSetExpiry => 'تحديد تاريخ الانتهاء (اختياري)';

  @override
  String get formCategorization => 'التصنيف';

  @override
  String get formSelectCategory => 'اختر التصنيف';

  @override
  String get formTitleRequired => 'العنوان مطلوب.';

  @override
  String get formUrlRequired => 'الرابط مطلوب للمواقع.';

  @override
  String get formPublishedSuccess => 'تم النشر بنجاح!';

  @override
  String get formUpdatedSuccess => 'تم التحديث بنجاح!';

  @override
  String get formOfflineError =>
      'أنت غير متصل بالإنترنت. يرجى التحقق من اتصالك.';

  @override
  String formSaveError(String error) {
    return 'خطأ في الحفظ: $error';
  }

  @override
  String get notifSend => 'إرسال إشعار';

  @override
  String get notifSent => 'تم إرسال الإشعار!';

  @override
  String get notifNew => 'إشعار جديد';

  @override
  String get notifDesc => 'إرسال إشعار للجميع';

  @override
  String get notifTitle => 'العنوان';

  @override
  String get notifBody => 'النص';

  @override
  String get notifUrl => 'رابط الوجهة (اختياري)';

  @override
  String get notifImage => 'صورة الإشعار (اختياري)';

  @override
  String get notifImgUploadSuccess => 'تم رفع الصورة بنجاح!';

  @override
  String get notifImgUploadFail => 'فشل الرفع. حاول مرة أخرى.';

  @override
  String get notifUploading => 'جاري الرفع...';

  @override
  String get notifUploadImg => 'رفع صورة';

  @override
  String get notifOrImgUrl => 'أو رابط الصورة';

  @override
  String get notifInvalidImg => 'رابط صورة غير صالح';

  @override
  String get notifType => 'النوع';

  @override
  String get notifTypeGeneral => 'عام';

  @override
  String get notifTypeAnnouncement => 'إعلان';

  @override
  String get notifTypeUpdate => 'تحديث';

  @override
  String get notifAlert => 'تنبيه';

  @override
  String get notifTypeNewItem => 'عنصر جديد';

  @override
  String get notifTypeGiveaway => 'مسابقة';

  @override
  String get notifTypePoll => 'تصويت';

  @override
  String notifFailed(String error) {
    return 'فشل: $error';
  }

  @override
  String get chatFailedUpload => 'فشل رفع الصورة';

  @override
  String chatError(String error) {
    return 'خطأ: $error';
  }

  @override
  String get chatSupport => 'الدعم';

  @override
  String get chatSupportSub => 'عادة يتم الرد خلال ساعات معدودة';

  @override
  String get chatInitError => 'تعذر تهيئة المحادثة.';

  @override
  String get chatSendMsg => 'أرسل لنا رسالة';

  @override
  String get chatHereToHelp => 'نحن هنا لمساعدتك!';

  @override
  String get chatUploadingImg => 'جاري رفع الصورة...';

  @override
  String get chatTypeMsg => 'اكتب رسالة...';

  @override
  String get chatTitle => 'المحادثة';

  @override
  String get chatUser => 'المستخدم';

  @override
  String get chatLoading => 'جاري التحميل...';

  @override
  String get chatNoMsgs => 'لا توجد رسائل بعد.';

  @override
  String get chatMessageUser => 'مراسلة المستخدم...';

  @override
  String get chatUserMessages => 'رسائل المستخدمين';

  @override
  String get chatNoActive => 'لا توجد محادثات نشطة.';

  @override
  String get chatConfirm => 'تأكيد';

  @override
  String get chatDeleteConfirm => 'هل أنت متأكد أنك تريد حذف هذه المحادثة؟';

  @override
  String get chatCancel => 'إلغاء';

  @override
  String get chatDelete => 'حذف';

  @override
  String get chatDeleted => 'تم حذف المحادثة';

  @override
  String chatDeleteFailed(String error) {
    return 'فشل الحذف: $error';
  }

  @override
  String get chatUnknownUser => 'مستخدم غير معروف';

  @override
  String get chatStartedConv => 'بدأ محادثة';

  @override
  String chatNew(int count) {
    return '$count جديد';
  }

  @override
  String get searchBookmarks => 'بحث في المفضلة...';

  @override
  String get searchDiscover => 'بحث في الاستكشاف...';

  @override
  String get searchVault => 'البحث في خزنتك...';

  @override
  String get communityAddReply => 'إضافة رد...';

  @override
  String get communityAddUrl => 'إضافة رابط (اختياري)';

  @override
  String get emailPlaceholder => 'you@email.com';

  @override
  String get formDescContent => 'الوصف والمحتوى';

  @override
  String get formDescPlaceholder => 'اكتب وصفاً تفصيلياً...';

  @override
  String get formDisplayVis => 'العرض والظهور';

  @override
  String get formActive => 'نشط';

  @override
  String get formActiveSub => 'إظهار هذا العنصر في قائمة الاستكشاف';

  @override
  String get formTrending => 'إظهار في الرائج';

  @override
  String get formTrendingSub => 'تمييزه في شريط العناصر الرائجة';

  @override
  String get formPopular => 'تحديد كشائع';

  @override
  String get formPopularSub => 'إظهاره في قسم الشائع';

  @override
  String get formFeaturedStatus => 'حالة التميز';

  @override
  String get formFeaturedSub => 'تحديده كعنصر مميز';

  @override
  String get formNotification => 'الإشعارات';

  @override
  String get formSendNotif => 'إرسال إشعار عند النشر';

  @override
  String get formSendNotifSub => 'إشعار جميع المستخدمين عن هذا العنصر الجديد';

  @override
  String get allItems => 'جميع العناصر';

  @override
  String get uncategorized => 'غير مصنف';

  @override
  String get label => 'التسمية';

  @override
  String get value => 'القيمة';

  @override
  String get contentToCopy => 'المحتوى للنسخ';

  @override
  String get saveToClipboard => 'حفظ في الحافظة';

  @override
  String get moveToGroup => 'نقل إلى مجموعة';

  @override
  String get selectMultiple => 'تحديد متعدد';

  @override
  String get editGroup => 'تعديل المجموعة';

  @override
  String get addGroup => 'إضافة مجموعة';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String movedTo(String group) {
    return 'تم النقل إلى \"$group\"';
  }

  @override
  String get pinToTop => 'تثبيت في الأعلى';

  @override
  String get unpin => 'إلغاء التثبيت';

  @override
  String get deleteItem => 'حذف العنصر';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get errorLoadingNotifications => 'خطأ في تحميل الإشعارات';

  @override
  String get noNotifications => 'لا توجد إشعارات';

  @override
  String get markAllRead => 'تحديد الكل كمقروء';

  @override
  String get copiedToClipboard => 'تم النسخ!';

  @override
  String get bookmarks => 'المفضلة';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get community => 'المجتمع';

  @override
  String get post => 'نشر';

  @override
  String get postPublished => 'تم نشر المنشور!';

  @override
  String get addReply => 'أضف رداً...';

  @override
  String get deleteReply => 'حذف الرد؟';

  @override
  String get whatToShare => 'ماذا تريد أن تشارك مع المجتمع؟';

  @override
  String get categoryAll => 'الكل';

  @override
  String get categoryGeneral => 'عام';

  @override
  String get categoryQuestions => 'أسئلة';

  @override
  String get categoryTips => 'نصائح';

  @override
  String get categoryResources => 'مواقع';

  @override
  String get categoryQuestion => 'سؤال';

  @override
  String get categoryTip => 'نصيحة';

  @override
  String get categoryResource => 'موقع';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get loginTitle => 'مرحباً بعودتك';

  @override
  String get registerTitle => 'إنشاء حساب جديد';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordSent => 'تم إرسال الرابط! تحقق من بريدك الإلكتروني.';

  @override
  String get addPage => 'إضافة صفحة';

  @override
  String get searchPages => 'بحث في الصفحات...';

  @override
  String get pageTitle => 'العنوان';

  @override
  String get pageUrl => 'الرابط';

  @override
  String get pageTitleHint => 'صفحتي المميزة';

  @override
  String get folder => 'المجلد';

  @override
  String get selectFolder => 'اختر مجلداً';

  @override
  String get tags => 'الوسوم';

  @override
  String get notes => 'الملاحظات';

  @override
  String get notesHint => 'ما هذه الصفحة؟';

  @override
  String get noPagesYet => 'لا توجد صفحات بعد';

  @override
  String get editPage => 'تعديل الصفحة';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get close => 'إغلاق';

  @override
  String get confirm => 'تأكيد';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get done => 'تم';

  @override
  String get edit => 'تعديل';

  @override
  String get share => 'مشاركة';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get openUrl => 'فتح';

  @override
  String get type => 'النوع';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get analyticsLabel => 'التحليلات';

  @override
  String get analyticsTitle => 'أنشطة التطبيق';

  @override
  String get analyticsSubtitle => 'مراقبة تفاعل المستخدمين وأداء المحتوى';

  @override
  String get analyticsNotEnoughData => 'بيانات غير كافية لإنشاء الرسم البياني';

  @override
  String get analyticsTotalUsers => 'إجمالي المستخدمين';

  @override
  String analyticsActiveThisWeek(int count) {
    return '$count نشط هذا الأسبوع';
  }

  @override
  String get analyticsActiveToday => 'نشط اليوم';

  @override
  String get analyticsUniqueLogins => 'تسجيلات دخول / فتح فريدة';

  @override
  String get analyticsItemViews => 'مشاهدات العناصر';

  @override
  String get analyticsTotalAcrossItems => 'الإجمالي عبر جميع العناصر';

  @override
  String get analyticsBookmarks => 'المفضلة';

  @override
  String get analyticsSavedByUsers => 'محفوظة من قبل المستخدمين';

  @override
  String get analyticsDau => 'المستخدمون النشطون يومياً (15 يوم)';

  @override
  String get analyticsTopViewed => 'الأكثر مشاهدة';

  @override
  String get analyticsNoViewData => 'لا توجد بيانات مشاهدة بعد.';

  @override
  String get analyticsMostBookmarked => 'الأكثر تفضيلاً';

  @override
  String get analyticsNoBookmarkData => 'لا توجد بيانات مفضلة بعد.';

  @override
  String get analyticsTopSearches => 'أبرز عمليات البحث (15 يوم)';

  @override
  String get analyticsNoSearchData => 'لا توجد بيانات بحث بعد.';

  @override
  String analyticsViews(int count) {
    return '$count مشاهدة';
  }

  @override
  String analyticsSaves(int count) {
    return '$count حفظ';
  }

  @override
  String analyticsSearches(int count) {
    return '$count بحث';
  }

  @override
  String get analyticsShowLess => 'عرض أقل';

  @override
  String analyticsViewAll(int count) {
    return 'عرض الكل ($count)';
  }

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int count) {
    return 'منذ $count د';
  }

  @override
  String timeHoursAgo(int count) {
    return 'منذ $count س';
  }

  @override
  String timeDaysAgo(int count) {
    return 'منذ $count ي';
  }

  @override
  String timeMinutesAgoFull(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String timeHoursAgoFull(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String timeDaysAgoFull(int count) {
    return 'منذ $count يوم';
  }

  @override
  String get discoverOpenButton => 'فتح';

  @override
  String get exploreNow => 'استكشف الآن';

  @override
  String get openLink => 'فتح الرابط';

  @override
  String get attachedLink => 'الرابط المرفق';

  @override
  String get searchPagesAndClipboard => 'البحث في الصفحات، الحافظة...';

  @override
  String get searchSavedPagesAndClipboard => 'ابحث في صفحاتك والحافظة';

  @override
  String noResultsForQuery(String query) {
    return 'لا توجد نتائج لـ \"$query\"';
  }

  @override
  String get searchResultPages => 'الصفحات';

  @override
  String get searchResultClipboard => 'الحافظة';

  @override
  String get browseDiscover => 'تصفح الاكتشاف';

  @override
  String get searchOnlineContent => 'البحث في المحتوى الإلكتروني والمواقع';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordEmailSent => 'تم إرسال الرمز!';

  @override
  String get forgotPasswordInstructions =>
      'أدخل عنوان بريدك الإلكتروني وسنرسل لك رمز تحقق لإعادة تعيين كلمة مرورك.';

  @override
  String get forgotPasswordCheckEmail =>
      'أرسلنا رمزاً مكوناً من 8 أرقام إلى بريدك الإلكتروني. أدخله أدناه.';

  @override
  String get forgotPasswordSendButton => ' إعادةإرسال الرمز';

  @override
  String get forgotPasswordBackToSignIn => 'العودة لتسجيل الدخول';

  @override
  String get forgotPasswordEmptyEmail => 'الرجاء إدخال البريد الإلكتروني';

  @override
  String get forgotPasswordFailed =>
      'فشل إرسال بريد إعادة التعيين. حاول لاحقا بعد ساعة';

  @override
  String get otpVerifyButton => 'تحقق من الرمز';

  @override
  String get otpInvalidCode => 'رمز التحقق غير صالح';

  @override
  String get enterOtp => 'رمز التحقق';

  @override
  String get enterOtpHint => 'أدخل الرمز المكون من 8 أرقام';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get updatePasswordButton => 'تحديث كلمة المرور';

  @override
  String get passwordMismatch => 'كلمات المرور غير متطابقة';

  @override
  String get passwordTooShort => 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get passwordUpdatedSuccess => 'تم تحديث كلمة المرور بنجاح!';

  @override
  String get passwordUpdateFailed => 'فشل تحديث كلمة المرور';

  @override
  String get usernameCooldownError =>
      'يمكنك تغيير اسم المستخدم مرة واحدة فقط كل 30 يوماً.';

  @override
  String usernameNextChangeDate(Object date) {
    return 'التغيير القادم مسموح في: $date';
  }

  @override
  String get notifBodyOffer => '🔥 عرض جديد متاح! تحقق منه الآن.';

  @override
  String get notifBodyPrompt => '💡 تمت إضافة prompt جديد! اضغط للاستكشاف.';

  @override
  String get notifBodyAnnouncement => '📢 إعلان جديد! اضغط للقراءة.';

  @override
  String get notifBodyDefault => '🌐 محتوى جديد أُضيف للتو! اضغط للاكتشاف.';

  @override
  String get eventSendNotif => 'إشعار المستخدمين';

  @override
  String get eventSendNotifSub => 'إرسال إشعار للمستخدمين حول هذه الفعالية';

  @override
  String get notifBodyGiveaway => '🎁 مسابقة جديدة بدأت! شارك الآن للفوز.';

  @override
  String get notifBodyPoll => '📊 تصويت جديد متاح! أدلِ بصوتك الآن.';

  @override
  String get viewGiveaway => 'عرض المسابقة';

  @override
  String get viewPoll => 'عرض التصويت';

  @override
  String get beTheFirstToPost => 'كن أول من ينشر!';

  @override
  String get createAPost => 'إنشاء منشور';

  @override
  String get shareAResourceAskAQuestion =>
      'شارك مصدراً، أو اطرح سؤالاً،\nأو قدّم نصيحة للمجتمع.';

  @override
  String get beTheFirstToReply =>
      'لا توجد ردود بعد.\nكن أول من ينضم إلى المحادثة!';

  @override
  String get aboutTaglineTitle => 'زاد تك | ZaadTech';

  @override
  String get aboutTaglineSubtitle =>
      'زاد تك هو زادك الرقمي لاكتشاف الأدوات وتنظيم كل ما تحتاجه على الإنترنت في مكان واحد.';

  @override
  String get aboutTaglineBody =>
      'يساعدك التطبيق على اكتشاف أدوات ومواقع مفيدة، وحفظ كل ما يهمك من روابط أو نصوص أو مفاتيح أو أكواد، ثم استرجاعها بسرعة عندما تحتاجها.';

  @override
  String get aboutFeaturesTitle => 'ماذا يقدم زاد تك؟';

  @override
  String get aboutFeature1Title => 'مستكشف الأدوات';

  @override
  String get aboutFeature1Body =>
      'اكتشف أدوات ومواقع وعروض واشتراكات جديدة يتم تحديثها باستمرار.';

  @override
  String get aboutFeature2Title => 'الحافظة الذكية';

  @override
  String get aboutFeature2Body =>
      'احفظ النصوص، الأكواد، المفاتيح، الإيميلات أو أي معلومات مهمة للرجوع إليها لاحقًا.';

  @override
  String get aboutFeature3Title => 'حفظ المواقع والروابط';

  @override
  String get aboutFeature3Body =>
      'احفظ أي موقع أو أداة مفيدة ونظمها داخل مجلدات خاصة بك.';

  @override
  String get aboutFeature4Title => 'استرجاع سريع أثناء التصفح';

  @override
  String get aboutFeature4Body =>
      'انسخ أي نص أو مفتاح محفوظ فورًا عبر الحافظة السريعة دون مغادرة الصفحة.';

  @override
  String get aboutFeature5Title => 'نسخ ذكي تلقائي';

  @override
  String get aboutFeature5Body =>
      'يمكنك تفعيل وضع النسخ المتقدم ليتم حفظ أي نص تنسخه تلقائيًا.';

  @override
  String get aboutFeature6Title => 'مجتمع المستخدمين';

  @override
  String get aboutFeature6Body =>
      'ناقش الأدوات، شارك التجارب، واقترح أدوات جديدة ليتم نشرها في المستكشف.';

  @override
  String get aboutGoalTitle => 'هدف زاد تك';

  @override
  String get aboutGoalBody =>
      'الهدف هو أن يكون تطبيق زادك الرقمي منصة متكاملة تجمع كل ما قد يحتاجه المهتم بالتقنية في مكان واحد؛ بدءًا من المواقع والأدوات الرقمية، وصولًا إلى أحدث العروض والخدمات والاشتراكات. كما يوفّر التطبيق خزنة رقمية خاصة تتيح للمستخدم حفظ كل ما يهمه ويخاف فقدانه أو نسيانه، ليتمكن من استرجاعه بسهولة وفي أي وقت بضغطة زر.';

  @override
  String get aboutTaglineBanner => 'زاد تك — اكتشف. احفظ. استرجع فورًا. 🚀';

  @override
  String get aboutDevLabel => 'تطوير: أحمد العريقي';

  @override
  String get manageAdPanels => 'إدارة لوحات الإعلانات';

  @override
  String get addAd => 'إضافة إعلان';

  @override
  String get editAd => 'تعديل الإعلان';

  @override
  String get noAdvertisements => 'لا توجد إعلانات';

  @override
  String get createFirstAd => 'قم بإنشاء أول لوحة إعلانية لك.';

  @override
  String get newAd => 'إعلان جديد';

  @override
  String get deleteAdTitle => 'حذف الإعلان؟';

  @override
  String get deleteAdConfirm =>
      'هل أنت متأكد أنك تريد حذف هذا الإعلان نهائياً؟';

  @override
  String get adActive => 'نشط';

  @override
  String get adHidden => 'مخفي';

  @override
  String get adActivated => 'تم تفعيل الإعلان';

  @override
  String get adHiddenMsg => 'تم إخفاء الإعلان';

  @override
  String get adDeleted => 'تم حذف الإعلان';

  @override
  String get adTitleLabel => 'عنوان الإعلان';

  @override
  String get adTitleHint => 'اسم مرجعي للمسؤول';

  @override
  String get adContentLabel => 'نص العرض (اختياري)';

  @override
  String get adContentHint => 'النص المعروض فوق الصورة';

  @override
  String get adDurationLabel => 'مدة العرض (ثواني)';

  @override
  String get adTargetScreen => 'الشاشة المستهدفة';

  @override
  String get adBothScreens => 'الرئيسية والمكتشف (كلاهما)';

  @override
  String get adShowTimer => 'إظهار الوقت المتبقي';

  @override
  String get adShowTimerSub => 'يعرض شارة انتهاء الصلاحية';

  @override
  String get adActiveStatus => 'حالة النشاط';

  @override
  String get adActiveStatusSub => 'إظهار أو إخفاء هذا الإعلان فوراً';

  @override
  String get adLinking => 'ربط الإعلان';

  @override
  String get adLinkInternal => 'ربط بعنصر داخل التطبيق';

  @override
  String get adLinkInternalSub =>
      'ابحث عن موقع، أو تلقينة، أو عرض من قسم المكتشف';

  @override
  String get adExternalUrl => 'رابط خارجي (اختياري)';

  @override
  String get adExternalUrlHint => 'https://...';

  @override
  String get adLinkSelected => 'العنصر المرتبط:';

  @override
  String get adRemoveLink => 'إزالة الرابط';

  @override
  String get adSavedSuccess => 'تم حفظ الإعلان بنجاح';

  @override
  String adSaveError(Object error) {
    return 'خطأ في حفظ الإعلان: $error';
  }

  @override
  String get adEnterImageError => 'يرجى إدخال رابط الصورة أو رفع صورة';

  @override
  String get adEndDate => 'تاريخ انتهاء الإعلان (اختياري)';

  @override
  String get basicInfo => 'المعلومات الأساسية';

  @override
  String get coverImage => 'صورة الغلاف';

  @override
  String get displaySettings => 'إعدادات العرض';

  @override
  String get adSearchInternal => 'البحث عن عنصر داخلي';

  @override
  String get adNoMatchingItems => 'لم يتم العثور على عناصر مطابقة.';

  @override
  String get adExternalUrlHelper => 'يفتح هذا الرابط في متصفح خارجي عند النقر';

  @override
  String get invalid => 'غير صالح';

  @override
  String get adEndDateSubtitle => 'حدد متى سيتوقف عرض الإعلان';

  @override
  String adDurationFormat(int duration) {
    return 'المدة $duration ثانية';
  }

  @override
  String adScreenFormat(String screen) {
    return 'الشاشة: $screen';
  }

  @override
  String adEndsFormat(String date) {
    return 'ينتهي: $date';
  }

  @override
  String get adEnded => 'انتهى';

  @override
  String adEndsInDays(int days) {
    return 'ينتهي خلال $days أيام';
  }

  @override
  String get adEndsInOneDay => 'ينتهي غداً';

  @override
  String adEndsInHours(int hours) {
    return 'ينتهي خلال $hours ساعات';
  }

  @override
  String get adEndsSoon => 'ينتهي قريباً';

  @override
  String get adminAdvertisementsTitle => 'الإعلانات';

  @override
  String get adminAdvertisementsSubtitle => 'اللوحات الإعلانية المتحركة';

  @override
  String get settingsFixNotifications => 'إصلاح الإشعارات';

  @override
  String get notifRecentNotifications => 'الإشعارات الأخيرة';

  @override
  String get notifNoRecent => 'لم يتم العثور على إشعارات أخيرة.';

  @override
  String get notifDeleteTitle => 'حذف الإشعار؟';

  @override
  String get notifDeleteConfirm => 'هل أنت متأكد أنك تريد حذف هذا الإشعار؟';

  @override
  String get notifCancel => 'إلغاء';

  @override
  String get notifDelete => 'حذف';

  @override
  String get notifStatusRegistered => 'الجهاز مسجّل. اضغط لإرسال إشعار تجريبي.';

  @override
  String get notifStatusNotRegistered =>
      'الجهاز غير مسجّل. اضغط لإعادة التشغيل مع VPN.';

  @override
  String get notifTestSent => 'تم إرسال إشعار تجريبي! ستستقبله قريباً.';

  @override
  String get notifTestFailed => 'فشل إرسال الإشعار التجريبي';

  @override
  String get notifRestartingApp =>
      'جارِ إعادة تشغيل التطبيق لتسجيل الإشعارات...';

  @override
  String get notifLoadMore => 'عرض المزيد';

  @override
  String get notifFixDialogTitle => 'تفعيل الإشعارات';

  @override
  String get notifFixDialogBody =>
      'تأكد أولاً من تشغيل VPN، ثم اضغط \'إعادة التشغيل الآن\' لإعادة تشغيل التطبيق. يجب إعادة فتح التطبيق أثناء تشغيل VPN لتسجيل الإشعارات.';

  @override
  String get notifRestartNow => 'إعادة التشغيل الآن';

  @override
  String get roleLabel => 'الدور';

  @override
  String get roleContentCreator => 'منشئ محتوى';

  @override
  String get roleUserDesc => 'مستخدم عادي بدون صلاحيات إدارية';

  @override
  String get roleContentCreatorDesc =>
      'يمكنه إدارة المواقع والتصنيفات والإشعارات وغيرها';

  @override
  String get roleAdminDesc => 'تحكم كامل في جميع أقسام لوحة الإدارة';

  @override
  String get permissionsLabel => 'صلاحيات';

  @override
  String get presetPermissions => 'الصلاحيات المتضمنة';

  @override
  String get customPermissions => 'صلاحيات مخصصة';

  @override
  String get customPermissionsHint =>
      'حدد الأقسام الإدارية التي يمكن لهذا المستخدم الوصول إليها';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get filterTitle => 'الفلاتر';

  @override
  String get filterReset => 'إعادة تعيين';

  @override
  String get filterApply => 'تطبيق الفلاتر';

  @override
  String get filterContentType => 'نوع المحتوى';

  @override
  String get filterCategory => 'الفئة';

  @override
  String get filterPricingModel => 'نموذج التسعير';

  @override
  String get filterSortBy => 'ترتيب حسب';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterAny => 'أي';

  @override
  String get filterNewest => 'الأحدث';

  @override
  String get filterOldest => 'الأقدم';

  @override
  String get filterPopular => 'الأكثر شعبية';

  @override
  String get filterTrending => 'الرائج';

  @override
  String get filterErrorLoading => 'خطأ في تحميل الفئات';

  @override
  String get adminSearchItems => 'البحث في العناصر...';

  @override
  String get adminSortNewest => 'الأحدث أولاً';

  @override
  String get adminSortOldest => 'الأقدم أولاً';

  @override
  String get adminAllTypes => 'جميع الأنواع';

  @override
  String adminItemsCount(int count) {
    return '$count عنصر';
  }

  @override
  String get collectionsTitle => 'المجموعات المميزة';

  @override
  String get collectionsEmpty => 'لا توجد مجموعات حالياً';

  @override
  String collectionItems(int count) {
    return '$count عنصر';
  }

  @override
  String get manageCollections => 'إدارة المجموعات';

  @override
  String get manageCollectionsDesc => 'إنشاء وإدارة المجموعات المميزة';

  @override
  String get newCollection => 'مجموعة جديدة';

  @override
  String get editCollection => 'تعديل المجموعة';

  @override
  String get collectionName => 'اسم المجموعة';

  @override
  String get collectionNameHint => 'مثلاً: أفضل كورسات AI 2026';

  @override
  String get collectionDescription => 'الوصف';

  @override
  String get collectionDescriptionHint => 'وصف مختصر للمجموعة';

  @override
  String get collectionCoverImage => 'رابط صورة الغلاف';

  @override
  String get collectionSaved => 'تم حفظ المجموعة بنجاح';

  @override
  String get collectionDeleted => 'تم حذف المجموعة';

  @override
  String get deleteCollectionConfirm =>
      'حذف هذه المجموعة؟ العناصر بداخلها لن تُحذف.';

  @override
  String get addItems => 'إضافة عناصر';

  @override
  String get removeFromCollection => 'إزالة من المجموعة';

  @override
  String get itemAdded => 'تمت إضافة العنصر للمجموعة';

  @override
  String get itemRemoved => 'تمت إزالة العنصر من المجموعة';

  @override
  String get searchItemsToAdd => 'ابحث عن عناصر لإضافتها...';

  @override
  String get noItemsInCollection => 'لا توجد عناصر في هذه المجموعة بعد';

  @override
  String get addToCollections => 'إضافة لمجموعات';

  @override
  String get tapToViewFull => 'اضغط على الصورة لعرضها بالحجم الكامل';

  @override
  String get closeImage => 'إغلاق';

  @override
  String get adDetailCard => 'بطاقة التفاصيل';

  @override
  String get adDetailCardSub => 'عرض بطاقة تفاصيل مع تعليمات عند النقر';

  @override
  String get adDetailInstructions => 'التعليمات';

  @override
  String get adDetailInstructionsHint => 'اكتب التعليمات المراد عرضها...';

  @override
  String get adDetailButtonText => 'نص الزر';

  @override
  String get adDetailButtonTextHint => 'مثال: احصل عليه الآن، تفاصيل اكثر...';

  @override
  String get adDetailActionType => 'نوع الإجراء';

  @override
  String get adDetailActionSupportChat => 'محادثة الدعم';

  @override
  String get adDetailActionWhatsApp => 'رقم واتساب';

  @override
  String get adDetailActionTelegram => 'احد مستخدمي تلجرام';

  @override
  String get adDetailActionExternalLink => 'رابط خارجي';

  @override
  String get adDetailActionUrl => 'الهدف (رقم/مستخدم/رابط)';

  @override
  String get adDetailActionWhatsAppHelper =>
      'مثال: +1234567890 (أدخل مفتاح الدولة بدون +)';

  @override
  String get adDetailActionTelegramHelper => 'مثال: username (بدون @)';

  @override
  String get adDetailActionExternalLinkHelper =>
      'مثال: https://example.com/...';

  @override
  String get adDetailDefaultButton => 'تفاصيل اكثر';

  @override
  String get communityReadOnly => 'المجتمع في وضع القراءة فقط';

  @override
  String get communityReadOnlyAdmin => 'وضع القراءة فقط';

  @override
  String get communityReadOnlyAdminSub => 'منع المستخدمين من النشر أو الرد';

  @override
  String get communityReadOnlyBanner =>
      'المجتمع حالياً في وضع القراءة فقط. يمكنك تصفح المنشورات لكن لا يمكنك إنشاء منشورات جديدة.';

  @override
  String get communityBannedBanner => 'تم تقييدك من النشر في المجتمع.';

  @override
  String get communityMutedBanner =>
      'أنت مكتوم مؤقتاً. يمكنك التصفح لكن لا يمكنك النشر أو الرد.';

  @override
  String communityMuteExpires(String date) {
    return 'ينتهي الكتم: $date';
  }

  @override
  String get communityBanUser => 'حظر المستخدم';

  @override
  String get communityMuteUser => 'كتم المستخدم';

  @override
  String get communityUnban => 'إلغاء الحظر';

  @override
  String get communityBanPermanent => 'حظر دائم';

  @override
  String get communityMute24h => 'كتم 24 ساعة';

  @override
  String get communityMute1w => 'كتم أسبوع';

  @override
  String get communityBanReason => 'السبب (اختياري)';

  @override
  String get communityBanned => 'تم حظر المستخدم';

  @override
  String get communityMuted => 'تم كتم المستخدم';

  @override
  String get communityUnbanned => 'تم إلغاء حظر المستخدم';

  @override
  String get communityBannedUsers => 'المستخدمون المحظورون';

  @override
  String get communityNoBannedUsers => 'لا يوجد مستخدمون محظورون أو مكتومون';

  @override
  String get communityBanType => 'محظور';

  @override
  String get communityMuteType => 'مكتوم';

  @override
  String get communityStats => 'إحصائيات المجتمع';

  @override
  String get communityTotalPosts => 'المنشورات';

  @override
  String get communityTotalReplies => 'الردود';

  @override
  String get communityPostsToday => 'اليوم';

  @override
  String get communityEditPost => 'تعديل المنشور';

  @override
  String get communityEdited => 'تم التعديل';

  @override
  String get communityEditTimeExpired => 'انتهت مهلة التعديل (15 دقيقة)';

  @override
  String get communityWelcomeMessage => 'رسالة الترحيب';

  @override
  String get communityWelcomeMessageHint =>
      'أدخل رسالة ترحيبية أو قوانين المجتمع...';

  @override
  String get communityWelcomeMessageSaved => 'تم حفظ رسالة الترحيب';

  @override
  String get communitySearchHint => 'البحث في المنشورات...';

  @override
  String get communityNoSearchResults => 'لا توجد منشورات مطابقة للبحث';

  @override
  String get sectionNewlyAdded => 'أضيف حديثاً';

  @override
  String get sectionFeatured => 'مميز';

  @override
  String get sectionTrending => 'رائج';

  @override
  String get sectionPopular => 'شائع';

  @override
  String get pinnedPost => 'مُثبت';

  @override
  String get formTagsPlaceholder => 'الهاشتاجات (مفصولة بفاصلة)';

  @override
  String get actionCommunity => 'المجتمع';

  @override
  String get actionBookmarks => 'العلامات المرجعية';

  @override
  String get actionRead => 'قراءة';

  @override
  String get actionView => 'عرض';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusApproved => 'مقبول';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get eventsTitle => 'الفعاليات';

  @override
  String get eventsSubtitle => 'إدارة المسابقات والتصويت';

  @override
  String get eventsManagement => 'إدارة الفعاليات';

  @override
  String get giveawaysTab => 'المسابقات';

  @override
  String get pollsTab => 'التصويت';

  @override
  String get noGiveaways => 'لا توجد مسابقات';

  @override
  String get noGiveawaysDesc => 'أنشئ أول مسابقة لإشراك مجتمعك!';

  @override
  String get createGiveaway => 'إنشاء مسابقة';

  @override
  String get editGiveaway => 'تعديل المسابقة';

  @override
  String get deleteGiveaway => 'حذف المسابقة';

  @override
  String get deleteGiveawayConfirm =>
      'هل أنت متأكد من حذف هذه المسابقة؟ سيتم فقدان جميع الاشتراكات.';

  @override
  String get giveawayTitle => 'عنوان المسابقة';

  @override
  String get giveawayDescription => 'وصف الجائزة';

  @override
  String get prizeImage => 'صورة الجائزة';

  @override
  String get prizeType => 'نوع الجائزة';

  @override
  String get prizeAccount => 'حساب';

  @override
  String get prizeSubscription => 'اشتراك';

  @override
  String get prizeCode => 'كود';

  @override
  String get prizeOther => 'أخرى';

  @override
  String get selectEndDate => 'اختر تاريخ الانتهاء';

  @override
  String get endDateDesc => 'موعد إغلاق التسجيل';

  @override
  String get maxEntries => 'أقصى عدد مشتركين';

  @override
  String get maxEntriesHint => 'اتركه فارغاً لعدد غير محدود';

  @override
  String get active => 'نشط';

  @override
  String get ended => 'منتهي';

  @override
  String get drawn => 'تم السحب';

  @override
  String get entries => 'مشترك';

  @override
  String get viewEntries => 'عرض المشتركين';

  @override
  String get noEntries => 'لا يوجد مشتركون بعد';

  @override
  String get drawWinner => 'اختيار فائز';

  @override
  String get drawWinnerConfirm =>
      'هل أنت متأكد؟ سيتم اختيار فائز عشوائياً ولا يمكن التراجع.';

  @override
  String get draw => 'سحب';

  @override
  String get winner => 'الفائز';

  @override
  String get winnerSelected => 'تم اختيار الفائز!';

  @override
  String get daysLeftLabel => 'يوم متبقي';

  @override
  String get hoursLeftLabel => 'ساعة متبقية';

  @override
  String get minutesLeftLabel => 'دقيقة متبقية';

  @override
  String get maxLabel => 'الحد الأقصى';

  @override
  String get giveawayLabel => 'مسابقة';

  @override
  String get enterGiveaway => 'شارك الآن';

  @override
  String get alreadyEntered => 'تم التسجيل ✓';

  @override
  String get enteredGiveaway => 'تم تسجيلك في المسابقة!';

  @override
  String get participants => 'المشاركون';

  @override
  String get timeLeft => 'الوقت المتبقي';

  @override
  String get endsOn => 'تنتهي في';

  @override
  String get congratulations => 'تهانينا للفائز!';

  @override
  String get winners => 'الفائزون';

  @override
  String get winnerCount => 'عدد الفائزين';

  @override
  String get winnerCountHint => 'عدد الفائزين المراد اختيارهم (افتراضي 1)';

  @override
  String get invalidNumber => 'رقم غير صحيح';

  @override
  String get redraw => 'إعادة السحب';

  @override
  String get redrawConfirm =>
      'سيتم مسح الفائزين الحاليين وإعادة السحب من جديد. هل تريد المتابعة؟';

  @override
  String get requestEntryData => 'طلب بيانات من المشتركين';

  @override
  String get requestEntryDataSub => 'تفعيل حقل لجمع بيانات من المشاركين';

  @override
  String get entryFieldLabel => 'عنوان الحقل';

  @override
  String get entryFieldLabelHint => 'مثال: بريدك الإلكتروني';

  @override
  String get entryValue => 'القيمة المُدخلة';

  @override
  String get enterYourValue => 'أدخل قيمتك';

  @override
  String get valueRequired => 'يرجى إدخال القيمة المطلوبة للمشاركة';

  @override
  String get notFound => 'غير موجود';

  @override
  String get noPolls => 'لا يوجد تصويت';

  @override
  String get noPollsDesc => 'أنشئ تصويتاً ودع مجتمعك يقرر!';

  @override
  String get createPoll => 'إنشاء تصويت';

  @override
  String get editPoll => 'تعديل التصويت';

  @override
  String get deletePoll => 'حذف التصويت';

  @override
  String get deletePollConfirm =>
      'هل أنت متأكد من حذف هذا التصويت؟ سيتم فقدان جميع الأصوات.';

  @override
  String get endPoll => 'إنهاء التصويت';

  @override
  String get pollQuestion => 'السؤال';

  @override
  String get pollDescription => 'الوصف (اختياري)';

  @override
  String get pollOptions => 'الخيارات';

  @override
  String get option => 'خيار';

  @override
  String get addOption => 'إضافة خيار';

  @override
  String get minTwoOptions => 'يجب إضافة خيارين على الأقل';

  @override
  String get pollEndDateDesc => 'موعد إغلاق التصويت';

  @override
  String get allowMultiple => 'السماح بتعدد الاختيارات';

  @override
  String get allowMultipleDesc => 'السماح للمستخدمين باختيار أكثر من خيار';

  @override
  String get votes => 'صوت';

  @override
  String get multipleChoice => 'متعدد الخيارات';

  @override
  String get pollLabel => 'تصويت';

  @override
  String get upload => 'رفع';

  @override
  String get searchImage => 'بحث صورة';

  @override
  String get failedToEnterGiveaway =>
      'فشل الدخول في المسابقة! حاول مرة أخرى أو تأكد من الاتصال.';

  @override
  String get usernameRequired => 'اسم المستخدم مطلوب';

  @override
  String get usernameTooShort => '3 أحرف على الأقل';

  @override
  String get usernameTaken => 'اسم المستخدم مستخدم بالفعل';

  @override
  String get usernameInvalid => 'أحرف وأرقام وشرطات سفلية فقط';

  @override
  String get usernameAvailable => 'اسم المستخدم متاح';

  @override
  String get checkingUsername => 'جاري التحقق...';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get passwordResetSent => 'تم إرسال رابط تغيير كلمة المرور';

  @override
  String get signOutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get noChanges => 'لا توجد تغييرات للحفظ';

  @override
  String get accountActions => 'الحساب';

  @override
  String get messageUser => 'مراسلة المستخدم';

  @override
  String get startingChat => 'جاري بدء المحادثة...';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get messageAdmin =>
      'أرسل رسالة إلى إدارة التطبيق لحل أي مشكلة أوالإستفسار';

  @override
  String get enteredGiveawaySuccess =>
      'تم الاشتراك بالمسابقة بنجاح! حظاً موفقاً.';

  @override
  String get votedPollSuccess => 'تم التصويت بنجاح! شكراً لمشاركتك.';
}
