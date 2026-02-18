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
  String get appName => 'مدير الخزنة';

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
  String get approve => 'قبول';

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
}
