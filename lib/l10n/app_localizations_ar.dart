// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تجربة الملابس الافتراضية';

  @override
  String get appSubtitle => 'تجربة الموضة بالذكاء الاصطناعي';

  @override
  String get common_loading => 'جاري التحميل...';

  @override
  String get common_processing => 'جاري المعالجة...';

  @override
  String get common_error => 'حدث خطأ ما';

  @override
  String get common_retry => 'إعادة المحاولة';

  @override
  String get common_cancel => 'إلغاء';

  @override
  String get common_save => 'حفظ';

  @override
  String get common_close => 'إغلاق';

  @override
  String get common_next => 'التالي';

  @override
  String get common_back => 'رجوع';

  @override
  String get common_confirm => 'تأكيد';

  @override
  String get common_delete => 'حذف';

  @override
  String get common_edit => 'تعديل';

  @override
  String get common_settings => 'الإعدادات';

  @override
  String get common_logout => 'تسجيل الخروج';

  @override
  String get common_language => 'اللغة';

  @override
  String get common_english => 'English';

  @override
  String get common_french => 'Français';

  @override
  String get common_german => 'Deutsch';

  @override
  String get auth_signUp => 'إنشاء حساب';

  @override
  String get auth_login => 'تسجيل الدخول';

  @override
  String get auth_email => 'البريد الإلكتروني';

  @override
  String get auth_password => 'كلمة المرور';

  @override
  String get auth_confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get auth_forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get auth_rememberMe => 'تذكرني';

  @override
  String get auth_signInWithGoogle => 'المتابعة مع Google';

  @override
  String get auth_signInWithApple => 'المتابعة مع Apple';

  @override
  String get auth_noAccount => 'ليس لديك حساب؟';

  @override
  String get auth_haveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get auth_createAccount => 'إنشاء حساب';

  @override
  String get auth_emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get auth_invalidEmail => 'عنوان بريد إلكتروني غير صحيح';

  @override
  String get auth_passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get auth_passwordTooShort => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get auth_passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get auth_loginSuccess => 'أهلا وسهلا!';

  @override
  String get auth_signupSuccess => 'تم إنشاء الحساب بنجاح!';

  @override
  String get auth_loginFailed => 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.';

  @override
  String get auth_signupFailed => 'فشل إنشاء الحساب. يرجى المحاولة مرة أخرى.';

  @override
  String get auth_logoutSuccess => 'تم تسجيل خروجك';

  @override
  String get home_welcome => 'مرحبا';

  @override
  String home_hello(String name) {
    return 'مرحبا، $name!';
  }

  @override
  String get home_tryOn => 'جرّب الآن';

  @override
  String get home_recommendations => 'التوصيات';

  @override
  String get home_savedOutfits => 'الملابس المحفوظة';

  @override
  String get home_profile => 'الملف الشخصي';

  @override
  String get home_noOutfits => 'لا توجد ملابس حتى الآن';

  @override
  String get home_startTryOn => 'ابدأ أول تجربة ملابس';

  @override
  String get vton_title => 'تجربة الملابس الافتراضية';

  @override
  String get vton_selectPhoto => 'اختر صورة';

  @override
  String get vton_uploadPhoto => 'تحميل صورة';

  @override
  String get vton_takePhoto => 'التقط صورة';

  @override
  String get vton_selectClothes => 'اختر ملابس';

  @override
  String get vton_processing => 'جاري معالجة ملابسك...';

  @override
  String get vton_analyzing => 'جاري تحليل الصورة...';

  @override
  String get vton_generatingOutfit => 'جاري إنشاء التجربة الافتراضية...';

  @override
  String get vton_ready => 'ملابسك جاهزة!';

  @override
  String get vton_save => 'حفظ الملابس';

  @override
  String get vton_share => 'مشاركة';

  @override
  String get vton_tryAnother => 'جرّب آخر';

  @override
  String get vton_noPhotoSelected => 'يرجى اختيار صورة أولا';

  @override
  String get vton_noClothesSelected => 'يرجى اختيار ملابس أولا';

  @override
  String get vton_processingFailed => 'فشلت معالجة الملابس. يرجى المحاولة مرة أخرى.';

  @override
  String get vton_uploadFailed => 'فشل تحميل الصورة';

  @override
  String get vton_invalidImage => 'يرجى اختيار صورة صحيحة';

  @override
  String get vton_imageTooLarge => 'الصورة كبيرة جدا. يرجى اختيار صورة أصغر.';

  @override
  String get vton_networkError => 'خطأ في الشبكة. يرجى التحقق من اتصالك.';

  @override
  String get vton_serverError => 'خطأ في الخادم. يرجى المحاولة لاحقا.';

  @override
  String get vton_timeoutError => 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.';

  @override
  String get vton_unknownError => 'حدث خطأ غير معروف';

  @override
  String get vton_quotaExceeded => 'تم تجاوز حد الاستخدام. يرجى المحاولة لاحقا.';

  @override
  String get vton_invalidApiKey => 'مفتاح API غير مكون. يرجى الاتصال بالدعم.';

  @override
  String get clothes_shirts => 'القمصان';

  @override
  String get clothes_pants => 'البناطيل';

  @override
  String get clothes_dresses => 'الفساتين';

  @override
  String get clothes_shoes => 'الأحذية';

  @override
  String get clothes_accessories => 'الإكسسوارات';

  @override
  String get clothes_outerwear => 'الملابس الخارجية';

  @override
  String get clothes_allCategories => 'جميع الفئات';

  @override
  String get clothes_viewDetails => 'عرض التفاصيل';

  @override
  String get clothes_addToCart => 'إضافة إلى السلة';

  @override
  String get clothes_addedToCart => 'تمت الإضافة إلى السلة';

  @override
  String get recommendations_daily => 'التوصيات اليومية';

  @override
  String get recommendations_forYou => 'موصى به لك';

  @override
  String get recommendations_trending => 'الأكثر رواجا الآن';

  @override
  String get recommendations_similar => 'عناصر مشابهة';

  @override
  String get recommendations_noRecommendations => 'لا توجد توصيات متاحة';

  @override
  String get recommendations_loadingRecommendations => 'جاري تحميل التوصيات...';

  @override
  String get profile_myProfile => 'ملفي الشخصي';

  @override
  String get profile_editProfile => 'تعديل الملف الشخصي';

  @override
  String get profile_firstName => 'الاسم الأول';

  @override
  String get profile_lastName => 'اسم العائلة';

  @override
  String get profile_email => 'البريد الإلكتروني';

  @override
  String get profile_phone => 'رقم الهاتف';

  @override
  String get profile_saveChanges => 'حفظ التغييرات';

  @override
  String get profile_changePassword => 'تغيير كلمة المرور';

  @override
  String get profile_preferences => 'التفضيلات';

  @override
  String get profile_favorites => 'المفضلة';

  @override
  String get profile_history => 'السجل';

  @override
  String get profile_deleteAccount => 'حذف الحساب';

  @override
  String get profile_about => 'نبذة عن';

  @override
  String get profile_privacyPolicy => 'سياسة الخصوصية';

  @override
  String get profile_termsOfService => 'شروط الخدمة';

  @override
  String get settings_general => 'عام';

  @override
  String get settings_appearance => 'المظهر';

  @override
  String get settings_notifications => 'الإشعارات';

  @override
  String get settings_privacy => 'الخصوصية';

  @override
  String get settings_language => 'اللغة';

  @override
  String get settings_theme => 'المظهر';

  @override
  String get settings_darkMode => 'الوضع الليلي';

  @override
  String get settings_lightMode => 'الوضع الفاتح';

  @override
  String get settings_systemMode => 'النظام';

  @override
  String get settings_pushNotifications => 'إشعارات دفع';

  @override
  String get settings_emailNotifications => 'إشعارات البريد الإلكتروني';

  @override
  String get settings_marketingEmails => 'رسائل البريد الإلكتروني للتسويق';

  @override
  String get errors_firebaseNotConfigured => 'Firebase غير مكون';

  @override
  String get errors_noInternet => 'لا يوجد اتصال بالإنترنت';

  @override
  String get errors_tryAgain => 'يرجى المحاولة مرة أخرى';

  @override
  String get errors_contactSupport => 'يرجى الاتصال بالدعم';

  @override
  String errors_fieldRequired(String field) {
    return '$field مطلوب';
  }

  @override
  String get success_saved => 'تم الحفظ بنجاح';

  @override
  String get success_deleted => 'تم الحذف بنجاح';

  @override
  String get success_updated => 'تم التحديث بنجاح';

  @override
  String get success_shared => 'تم المشاركة بنجاح';

  @override
  String get firebase_notConfigured => 'Firebase Not Configured';

  @override
  String get firebase_setupMessage => 'To run this app, you need to configure Firebase first.';

  @override
  String get firebase_quickSetup => 'Quick Setup:';

  @override
  String get firebase_step1 => 'Login to Firebase:';

  @override
  String get firebase_step1Command => 'firebase login';

  @override
  String get firebase_step2 => 'Configure FlutterFire:';

  @override
  String get firebase_step2Command => 'flutterfire configure --project=ai-styling-c45cf';

  @override
  String get firebase_step3 => 'Enable services in Firebase Console';

  @override
  String get firebase_detailedInstructions => 'See FIREBASE_READY.md for detailed instructions.';

  @override
  String get notifications_newRecommendation => 'توصية جديدة لك';

  @override
  String get notifications_outfitSaved => 'تم حفظ الملابس';

  @override
  String get notifications_tryOnComplete => 'تجربتك جاهزة';

  @override
  String get notifications_updateAvailable => 'تحديث متاح';
}
