// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Virtuelle Anprobe';

  @override
  String get appSubtitle => 'KI-Mode-Anprobe';

  @override
  String get common_loading => 'Wird geladen...';

  @override
  String get common_processing => 'Wird verarbeitet...';

  @override
  String get common_error => 'Ein Fehler ist aufgetreten';

  @override
  String get common_retry => 'Erneut versuchen';

  @override
  String get common_cancel => 'Abbrechen';

  @override
  String get common_save => 'Speichern';

  @override
  String get common_close => 'Schließen';

  @override
  String get common_next => 'Weiter';

  @override
  String get common_back => 'Zurück';

  @override
  String get common_confirm => 'Bestätigen';

  @override
  String get common_delete => 'Löschen';

  @override
  String get common_edit => 'Bearbeiten';

  @override
  String get common_settings => 'Einstellungen';

  @override
  String get common_logout => 'Abmelden';

  @override
  String get common_language => 'Sprache';

  @override
  String get common_english => 'English';

  @override
  String get common_french => 'Français';

  @override
  String get common_german => 'Deutsch';

  @override
  String get auth_signUp => 'Registrieren';

  @override
  String get auth_login => 'Anmelden';

  @override
  String get auth_email => 'E-Mail';

  @override
  String get auth_password => 'Passwort';

  @override
  String get auth_confirmPassword => 'Passwort bestätigen';

  @override
  String get auth_forgotPassword => 'Passwort vergessen?';

  @override
  String get auth_rememberMe => 'Angemeldet bleiben';

  @override
  String get auth_signInWithGoogle => 'Mit Google fortfahren';

  @override
  String get auth_signInWithApple => 'Mit Apple fortfahren';

  @override
  String get auth_noAccount => 'Noch kein Konto?';

  @override
  String get auth_haveAccount => 'Haben Sie bereits ein Konto?';

  @override
  String get auth_createAccount => 'Konto erstellen';

  @override
  String get auth_emailRequired => 'E-Mail ist erforderlich';

  @override
  String get auth_invalidEmail => 'Ungültige E-Mail-Adresse';

  @override
  String get auth_passwordRequired => 'Passwort ist erforderlich';

  @override
  String get auth_passwordTooShort => 'Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get auth_passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get auth_loginSuccess => 'Willkommen zurück!';

  @override
  String get auth_signupSuccess => 'Konto erfolgreich erstellt!';

  @override
  String get auth_loginFailed => 'Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get auth_signupFailed => 'Registrierung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get auth_logoutSuccess => 'Sie haben sich abgemeldet';

  @override
  String get home_welcome => 'Willkommen';

  @override
  String home_hello(String name) {
    return 'Hallo, $name!';
  }

  @override
  String get home_tryOn => 'Anprobieren';

  @override
  String get home_recommendations => 'Empfehlungen';

  @override
  String get home_savedOutfits => 'Gespeicherte Outfits';

  @override
  String get home_profile => 'Profil';

  @override
  String get home_noOutfits => 'Noch keine Outfits';

  @override
  String get home_startTryOn => 'Starten Sie Ihre erste virtuelle Anprobe';

  @override
  String get vton_title => 'Virtuelle Anprobe';

  @override
  String get vton_selectPhoto => 'Foto auswählen';

  @override
  String get vton_uploadPhoto => 'Foto hochladen';

  @override
  String get vton_takePhoto => 'Foto aufnehmen';

  @override
  String get vton_selectClothes => 'Kleidung auswählen';

  @override
  String get vton_processing => 'Ihr Outfit wird verarbeitet...';

  @override
  String get vton_analyzing => 'Bild wird analysiert...';

  @override
  String get vton_generatingOutfit => 'Virtuelle Anprobe wird generiert...';

  @override
  String get vton_ready => 'Dein Outfit ist fertig!';

  @override
  String get vton_save => 'Outfit speichern';

  @override
  String get vton_share => 'Teilen';

  @override
  String get vton_tryAnother => 'Ein anderes versuchen';

  @override
  String get vton_noPhotoSelected => 'Bitte wählen Sie zuerst ein Foto aus';

  @override
  String get vton_noClothesSelected => 'Bitte wählen Sie zuerst Kleidung aus';

  @override
  String get vton_processingFailed => 'Outfit-Verarbeitung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get vton_uploadFailed => 'Bild-Upload fehlgeschlagen';

  @override
  String get vton_invalidImage => 'Bitte wählen Sie ein gültiges Bild aus';

  @override
  String get vton_imageTooLarge => 'Das Bild ist zu groß. Bitte wählen Sie ein kleineres Bild.';

  @override
  String get vton_networkError => 'Netzwerkfehler. Bitte überprüfen Sie Ihre Verbindung.';

  @override
  String get vton_serverError => 'Serverfehler. Bitte versuchen Sie es später erneut.';

  @override
  String get vton_timeoutError => 'Anfrage-Timeout. Bitte versuchen Sie es erneut.';

  @override
  String get vton_unknownError => 'Ein unbekannter Fehler ist aufgetreten';

  @override
  String get vton_quotaExceeded => 'API-Kontingent überschritten. Bitte versuchen Sie es später erneut.';

  @override
  String get vton_invalidApiKey => 'API-Schlüssel ist nicht konfiguriert. Bitte kontaktieren Sie den Support.';

  @override
  String get clothes_shirts => 'Hemden';

  @override
  String get clothes_pants => 'Hosen';

  @override
  String get clothes_dresses => 'Kleider';

  @override
  String get clothes_shoes => 'Schuhe';

  @override
  String get clothes_accessories => 'Zubehör';

  @override
  String get clothes_outerwear => 'Oberbekleidung';

  @override
  String get clothes_allCategories => 'Alle Kategorien';

  @override
  String get clothes_viewDetails => 'Details anzeigen';

  @override
  String get clothes_addToCart => 'In den Warenkorb';

  @override
  String get clothes_addedToCart => 'Zum Warenkorb hinzugefügt';

  @override
  String get recommendations_daily => 'Tägliche Empfehlungen';

  @override
  String get recommendations_forYou => 'Empfohlen für Sie';

  @override
  String get recommendations_trending => 'Gerade angesagt';

  @override
  String get recommendations_similar => 'Ähnliche Artikel';

  @override
  String get recommendations_noRecommendations => 'Keine Empfehlungen verfügbar';

  @override
  String get recommendations_loadingRecommendations => 'Empfehlungen werden geladen...';

  @override
  String get profile_myProfile => 'Mein Profil';

  @override
  String get profile_editProfile => 'Profil bearbeiten';

  @override
  String get profile_firstName => 'Vorname';

  @override
  String get profile_lastName => 'Nachname';

  @override
  String get profile_email => 'E-Mail';

  @override
  String get profile_phone => 'Telefon';

  @override
  String get profile_saveChanges => 'Änderungen speichern';

  @override
  String get profile_changePassword => 'Passwort ändern';

  @override
  String get profile_preferences => 'Einstellungen';

  @override
  String get profile_favorites => 'Favoriten';

  @override
  String get profile_history => 'Verlauf';

  @override
  String get profile_deleteAccount => 'Konto löschen';

  @override
  String get profile_about => 'Über';

  @override
  String get profile_privacyPolicy => 'Datenschutzerklärung';

  @override
  String get profile_termsOfService => 'Nutzungsbedingungen';

  @override
  String get settings_general => 'Allgemein';

  @override
  String get settings_appearance => 'Erscheinungsbild';

  @override
  String get settings_notifications => 'Benachrichtigungen';

  @override
  String get settings_privacy => 'Datenschutz';

  @override
  String get settings_language => 'Sprache';

  @override
  String get settings_theme => 'Design';

  @override
  String get settings_darkMode => 'Dunkler Modus';

  @override
  String get settings_lightMode => 'Heller Modus';

  @override
  String get settings_systemMode => 'System';

  @override
  String get settings_pushNotifications => 'Push-Benachrichtigungen';

  @override
  String get settings_emailNotifications => 'E-Mail-Benachrichtigungen';

  @override
  String get settings_marketingEmails => 'Marketing-E-Mails';

  @override
  String get errors_firebaseNotConfigured => 'Firebase ist nicht konfiguriert';

  @override
  String get errors_noInternet => 'Keine Internetverbindung';

  @override
  String get errors_tryAgain => 'Bitte versuchen Sie es erneut';

  @override
  String get errors_contactSupport => 'Bitte kontaktieren Sie den Support';

  @override
  String errors_fieldRequired(String field) {
    return '$field ist erforderlich';
  }

  @override
  String get success_saved => 'Erfolgreich gespeichert';

  @override
  String get success_deleted => 'Erfolgreich gelöscht';

  @override
  String get success_updated => 'Erfolgreich aktualisiert';

  @override
  String get success_shared => 'Erfolgreich geteilt';

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
  String get notifications_newRecommendation => 'Neue Empfehlung für Sie';

  @override
  String get notifications_outfitSaved => 'Outfit gespeichert';

  @override
  String get notifications_tryOnComplete => 'Ihre Anprobe ist fertig';

  @override
  String get notifications_updateAvailable => 'Update verfügbar';
}
