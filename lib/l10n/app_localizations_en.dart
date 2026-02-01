// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Virtual Try-On';

  @override
  String get appSubtitle => 'AI Fashion Try-On';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_processing => 'Processing...';

  @override
  String get common_error => 'Something went wrong';

  @override
  String get common_retry => 'Try Again';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_close => 'Close';

  @override
  String get common_next => 'Next';

  @override
  String get common_back => 'Back';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_settings => 'Settings';

  @override
  String get common_logout => 'Logout';

  @override
  String get common_language => 'Language';

  @override
  String get common_english => 'English';

  @override
  String get common_french => 'Français';

  @override
  String get common_german => 'Deutsch';

  @override
  String get auth_signUp => 'Sign Up';

  @override
  String get auth_login => 'Log In';

  @override
  String get auth_email => 'Email';

  @override
  String get auth_password => 'Password';

  @override
  String get auth_confirmPassword => 'Confirm Password';

  @override
  String get auth_forgotPassword => 'Forgot Password?';

  @override
  String get auth_rememberMe => 'Remember Me';

  @override
  String get auth_signInWithGoogle => 'Continue with Google';

  @override
  String get auth_signInWithApple => 'Continue with Apple';

  @override
  String get auth_noAccount => 'Don\'t have an account?';

  @override
  String get auth_haveAccount => 'Already have an account?';

  @override
  String get auth_createAccount => 'Create Account';

  @override
  String get auth_emailRequired => 'Email is required';

  @override
  String get auth_invalidEmail => 'Invalid email address';

  @override
  String get auth_passwordRequired => 'Password is required';

  @override
  String get auth_passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get auth_passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get auth_loginSuccess => 'Welcome back!';

  @override
  String get auth_signupSuccess => 'Account created successfully!';

  @override
  String get auth_loginFailed => 'Login failed. Please try again.';

  @override
  String get auth_signupFailed => 'Sign up failed. Please try again.';

  @override
  String get auth_logoutSuccess => 'You have been logged out';

  @override
  String get home_welcome => 'Welcome';

  @override
  String home_hello(String name) {
    return 'Hello, $name!';
  }

  @override
  String get home_tryOn => 'Try On';

  @override
  String get home_recommendations => 'Recommendations';

  @override
  String get home_savedOutfits => 'Saved Outfits';

  @override
  String get home_profile => 'Profile';

  @override
  String get home_noOutfits => 'No outfits yet';

  @override
  String get home_startTryOn => 'Start your first try-on';

  @override
  String get vton_title => 'Virtual Try-On';

  @override
  String get vton_selectPhoto => 'Select Photo';

  @override
  String get vton_uploadPhoto => 'Upload Photo';

  @override
  String get vton_takePhoto => 'Take Photo';

  @override
  String get vton_selectClothes => 'Select Clothes';

  @override
  String get vton_processing => 'Processing your outfit...';

  @override
  String get vton_analyzing => 'Analyzing image...';

  @override
  String get vton_generatingOutfit => 'Generating virtual try-on...';

  @override
  String get vton_ready => 'Your outfit is ready!';

  @override
  String get vton_save => 'Save Outfit';

  @override
  String get vton_share => 'Share';

  @override
  String get vton_tryAnother => 'Try Another';

  @override
  String get vton_noPhotoSelected => 'Please select a photo first';

  @override
  String get vton_noClothesSelected => 'Please select clothes first';

  @override
  String get vton_processingFailed => 'Failed to process outfit. Please try again.';

  @override
  String get vton_uploadFailed => 'Failed to upload image';

  @override
  String get vton_invalidImage => 'Please select a valid image';

  @override
  String get vton_imageTooLarge => 'Image is too large. Please select a smaller one.';

  @override
  String get vton_networkError => 'Network error. Please check your connection.';

  @override
  String get vton_serverError => 'Server error. Please try again later.';

  @override
  String get vton_timeoutError => 'Request timed out. Please try again.';

  @override
  String get vton_unknownError => 'An unknown error occurred';

  @override
  String get vton_quotaExceeded => 'API quota exceeded. Please try again later.';

  @override
  String get vton_invalidApiKey => 'API key is not configured. Please contact support.';

  @override
  String get clothes_shirts => 'Shirts';

  @override
  String get clothes_pants => 'Pants';

  @override
  String get clothes_dresses => 'Dresses';

  @override
  String get clothes_shoes => 'Shoes';

  @override
  String get clothes_accessories => 'Accessories';

  @override
  String get clothes_outerwear => 'Outerwear';

  @override
  String get clothes_allCategories => 'All Categories';

  @override
  String get clothes_viewDetails => 'View Details';

  @override
  String get clothes_addToCart => 'Add to Cart';

  @override
  String get clothes_addedToCart => 'Added to cart';

  @override
  String get recommendations_daily => 'Daily Recommendations';

  @override
  String get recommendations_forYou => 'Recommended for You';

  @override
  String get recommendations_trending => 'Trending Now';

  @override
  String get recommendations_similar => 'Similar Items';

  @override
  String get recommendations_noRecommendations => 'No recommendations available';

  @override
  String get recommendations_loadingRecommendations => 'Loading recommendations...';

  @override
  String get profile_myProfile => 'My Profile';

  @override
  String get profile_editProfile => 'Edit Profile';

  @override
  String get profile_firstName => 'First Name';

  @override
  String get profile_lastName => 'Last Name';

  @override
  String get profile_email => 'Email';

  @override
  String get profile_phone => 'Phone';

  @override
  String get profile_saveChanges => 'Save Changes';

  @override
  String get profile_changePassword => 'Change Password';

  @override
  String get profile_preferences => 'Preferences';

  @override
  String get profile_favorites => 'Favorites';

  @override
  String get profile_history => 'History';

  @override
  String get profile_deleteAccount => 'Delete Account';

  @override
  String get profile_about => 'About';

  @override
  String get profile_privacyPolicy => 'Privacy Policy';

  @override
  String get profile_termsOfService => 'Terms of Service';

  @override
  String get settings_general => 'General';

  @override
  String get settings_appearance => 'Appearance';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_privacy => 'Privacy';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_darkMode => 'Dark Mode';

  @override
  String get settings_lightMode => 'Light Mode';

  @override
  String get settings_systemMode => 'System';

  @override
  String get settings_pushNotifications => 'Push Notifications';

  @override
  String get settings_emailNotifications => 'Email Notifications';

  @override
  String get settings_marketingEmails => 'Marketing Emails';

  @override
  String get errors_firebaseNotConfigured => 'Firebase is not configured';

  @override
  String get errors_noInternet => 'No internet connection';

  @override
  String get errors_tryAgain => 'Please try again';

  @override
  String get errors_contactSupport => 'Please contact support';

  @override
  String errors_fieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get success_saved => 'Saved successfully';

  @override
  String get success_deleted => 'Deleted successfully';

  @override
  String get success_updated => 'Updated successfully';

  @override
  String get success_shared => 'Shared successfully';

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
  String get notifications_newRecommendation => 'New recommendation for you';

  @override
  String get notifications_outfitSaved => 'Outfit saved';

  @override
  String get notifications_tryOnComplete => 'Your try-on is ready';

  @override
  String get notifications_updateAvailable => 'Update available';
}
