import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Virtual Try-On'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI Fashion Try-On'**
  String get appSubtitle;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get common_processing;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get common_error;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get common_retry;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get common_settings;

  /// No description provided for @common_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get common_logout;

  /// No description provided for @common_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get common_language;

  /// No description provided for @common_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get common_english;

  /// No description provided for @common_french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get common_french;

  /// No description provided for @common_german.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get common_german;

  /// No description provided for @auth_signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get auth_signUp;

  /// No description provided for @auth_login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get auth_login;

  /// No description provided for @auth_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_email;

  /// No description provided for @auth_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_password;

  /// No description provided for @auth_confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get auth_confirmPassword;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get auth_forgotPassword;

  /// No description provided for @auth_rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get auth_rememberMe;

  /// No description provided for @auth_signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get auth_signInWithGoogle;

  /// No description provided for @auth_signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get auth_signInWithApple;

  /// No description provided for @auth_noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get auth_noAccount;

  /// No description provided for @auth_haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get auth_haveAccount;

  /// No description provided for @auth_createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get auth_createAccount;

  /// No description provided for @auth_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get auth_emailRequired;

  /// No description provided for @auth_invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get auth_invalidEmail;

  /// No description provided for @auth_passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get auth_passwordRequired;

  /// No description provided for @auth_passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get auth_passwordTooShort;

  /// No description provided for @auth_passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get auth_passwordsDoNotMatch;

  /// No description provided for @auth_loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get auth_loginSuccess;

  /// No description provided for @auth_signupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get auth_signupSuccess;

  /// No description provided for @auth_loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get auth_loginFailed;

  /// No description provided for @auth_signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed. Please try again.'**
  String get auth_signupFailed;

  /// No description provided for @auth_logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'You have been logged out'**
  String get auth_logoutSuccess;

  /// No description provided for @home_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get home_welcome;

  /// No description provided for @home_hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String home_hello(String name);

  /// No description provided for @home_tryOn.
  ///
  /// In en, this message translates to:
  /// **'Try On'**
  String get home_tryOn;

  /// No description provided for @home_recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get home_recommendations;

  /// No description provided for @home_savedOutfits.
  ///
  /// In en, this message translates to:
  /// **'Saved Outfits'**
  String get home_savedOutfits;

  /// No description provided for @home_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get home_profile;

  /// No description provided for @home_noOutfits.
  ///
  /// In en, this message translates to:
  /// **'No outfits yet'**
  String get home_noOutfits;

  /// No description provided for @home_startTryOn.
  ///
  /// In en, this message translates to:
  /// **'Start your first try-on'**
  String get home_startTryOn;

  /// No description provided for @vton_title.
  ///
  /// In en, this message translates to:
  /// **'Virtual Try-On'**
  String get vton_title;

  /// No description provided for @vton_selectPhoto.
  ///
  /// In en, this message translates to:
  /// **'Select Photo'**
  String get vton_selectPhoto;

  /// No description provided for @vton_uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get vton_uploadPhoto;

  /// No description provided for @vton_takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get vton_takePhoto;

  /// No description provided for @vton_selectClothes.
  ///
  /// In en, this message translates to:
  /// **'Select Clothes'**
  String get vton_selectClothes;

  /// No description provided for @vton_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing your outfit...'**
  String get vton_processing;

  /// No description provided for @vton_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image...'**
  String get vton_analyzing;

  /// No description provided for @vton_generatingOutfit.
  ///
  /// In en, this message translates to:
  /// **'Generating virtual try-on...'**
  String get vton_generatingOutfit;

  /// No description provided for @vton_ready.
  ///
  /// In en, this message translates to:
  /// **'Your outfit is ready!'**
  String get vton_ready;

  /// No description provided for @vton_save.
  ///
  /// In en, this message translates to:
  /// **'Save Outfit'**
  String get vton_save;

  /// No description provided for @vton_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get vton_share;

  /// No description provided for @vton_tryAnother.
  ///
  /// In en, this message translates to:
  /// **'Try Another'**
  String get vton_tryAnother;

  /// No description provided for @vton_noPhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'Please select a photo first'**
  String get vton_noPhotoSelected;

  /// No description provided for @vton_noClothesSelected.
  ///
  /// In en, this message translates to:
  /// **'Please select clothes first'**
  String get vton_noClothesSelected;

  /// No description provided for @vton_processingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to process outfit. Please try again.'**
  String get vton_processingFailed;

  /// No description provided for @vton_uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get vton_uploadFailed;

  /// No description provided for @vton_invalidImage.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid image'**
  String get vton_invalidImage;

  /// No description provided for @vton_imageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. Please select a smaller one.'**
  String get vton_imageTooLarge;

  /// No description provided for @vton_networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get vton_networkError;

  /// No description provided for @vton_serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get vton_serverError;

  /// No description provided for @vton_timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get vton_timeoutError;

  /// No description provided for @vton_unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get vton_unknownError;

  /// No description provided for @vton_quotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'API quota exceeded. Please try again later.'**
  String get vton_quotaExceeded;

  /// No description provided for @vton_invalidApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key is not configured. Please contact support.'**
  String get vton_invalidApiKey;

  /// No description provided for @clothes_shirts.
  ///
  /// In en, this message translates to:
  /// **'Shirts'**
  String get clothes_shirts;

  /// No description provided for @clothes_pants.
  ///
  /// In en, this message translates to:
  /// **'Pants'**
  String get clothes_pants;

  /// No description provided for @clothes_dresses.
  ///
  /// In en, this message translates to:
  /// **'Dresses'**
  String get clothes_dresses;

  /// No description provided for @clothes_shoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get clothes_shoes;

  /// No description provided for @clothes_accessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get clothes_accessories;

  /// No description provided for @clothes_outerwear.
  ///
  /// In en, this message translates to:
  /// **'Outerwear'**
  String get clothes_outerwear;

  /// No description provided for @clothes_allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get clothes_allCategories;

  /// No description provided for @clothes_viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get clothes_viewDetails;

  /// No description provided for @clothes_addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get clothes_addToCart;

  /// No description provided for @clothes_addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get clothes_addedToCart;

  /// No description provided for @recommendations_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily Recommendations'**
  String get recommendations_daily;

  /// No description provided for @recommendations_forYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get recommendations_forYou;

  /// No description provided for @recommendations_trending.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get recommendations_trending;

  /// No description provided for @recommendations_similar.
  ///
  /// In en, this message translates to:
  /// **'Similar Items'**
  String get recommendations_similar;

  /// No description provided for @recommendations_noRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations available'**
  String get recommendations_noRecommendations;

  /// No description provided for @recommendations_loadingRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Loading recommendations...'**
  String get recommendations_loadingRecommendations;

  /// No description provided for @profile_myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profile_myProfile;

  /// No description provided for @profile_editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profile_editProfile;

  /// No description provided for @profile_firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get profile_firstName;

  /// No description provided for @profile_lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get profile_lastName;

  /// No description provided for @profile_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profile_email;

  /// No description provided for @profile_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profile_phone;

  /// No description provided for @profile_saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profile_saveChanges;

  /// No description provided for @profile_changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profile_changePassword;

  /// No description provided for @profile_preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profile_preferences;

  /// No description provided for @profile_favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get profile_favorites;

  /// No description provided for @profile_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get profile_history;

  /// No description provided for @profile_deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profile_deleteAccount;

  /// No description provided for @profile_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profile_about;

  /// No description provided for @profile_privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profile_privacyPolicy;

  /// No description provided for @profile_termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get profile_termsOfService;

  /// No description provided for @settings_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settings_general;

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settings_privacy;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settings_darkMode;

  /// No description provided for @settings_lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get settings_lightMode;

  /// No description provided for @settings_systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_systemMode;

  /// No description provided for @settings_pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settings_pushNotifications;

  /// No description provided for @settings_emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get settings_emailNotifications;

  /// No description provided for @settings_marketingEmails.
  ///
  /// In en, this message translates to:
  /// **'Marketing Emails'**
  String get settings_marketingEmails;

  /// No description provided for @errors_firebaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not configured'**
  String get errors_firebaseNotConfigured;

  /// No description provided for @errors_noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errors_noInternet;

  /// No description provided for @errors_tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get errors_tryAgain;

  /// No description provided for @errors_contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Please contact support'**
  String get errors_contactSupport;

  /// No description provided for @errors_fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String errors_fieldRequired(String field);

  /// No description provided for @success_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get success_saved;

  /// No description provided for @success_deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get success_deleted;

  /// No description provided for @success_updated.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get success_updated;

  /// No description provided for @success_shared.
  ///
  /// In en, this message translates to:
  /// **'Shared successfully'**
  String get success_shared;

  /// No description provided for @firebase_notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase Not Configured'**
  String get firebase_notConfigured;

  /// No description provided for @firebase_setupMessage.
  ///
  /// In en, this message translates to:
  /// **'To run this app, you need to configure Firebase first.'**
  String get firebase_setupMessage;

  /// No description provided for @firebase_quickSetup.
  ///
  /// In en, this message translates to:
  /// **'Quick Setup:'**
  String get firebase_quickSetup;

  /// No description provided for @firebase_step1.
  ///
  /// In en, this message translates to:
  /// **'Login to Firebase:'**
  String get firebase_step1;

  /// No description provided for @firebase_step1Command.
  ///
  /// In en, this message translates to:
  /// **'firebase login'**
  String get firebase_step1Command;

  /// No description provided for @firebase_step2.
  ///
  /// In en, this message translates to:
  /// **'Configure FlutterFire:'**
  String get firebase_step2;

  /// No description provided for @firebase_step2Command.
  ///
  /// In en, this message translates to:
  /// **'flutterfire configure --project=ai-styling-c45cf'**
  String get firebase_step2Command;

  /// No description provided for @firebase_step3.
  ///
  /// In en, this message translates to:
  /// **'Enable services in Firebase Console'**
  String get firebase_step3;

  /// No description provided for @firebase_detailedInstructions.
  ///
  /// In en, this message translates to:
  /// **'See FIREBASE_READY.md for detailed instructions.'**
  String get firebase_detailedInstructions;

  /// No description provided for @notifications_newRecommendation.
  ///
  /// In en, this message translates to:
  /// **'New recommendation for you'**
  String get notifications_newRecommendation;

  /// No description provided for @notifications_outfitSaved.
  ///
  /// In en, this message translates to:
  /// **'Outfit saved'**
  String get notifications_outfitSaved;

  /// No description provided for @notifications_tryOnComplete.
  ///
  /// In en, this message translates to:
  /// **'Your try-on is ready'**
  String get notifications_tryOnComplete;

  /// No description provided for @notifications_updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get notifications_updateAvailable;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
