// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Essayage Virtuel';

  @override
  String get appSubtitle => 'Essayage Virtuel IA';

  @override
  String get common_loading => 'Chargement...';

  @override
  String get common_processing => 'Traitement...';

  @override
  String get common_error => 'Une erreur est survenue';

  @override
  String get common_retry => 'Réessayer';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_close => 'Fermer';

  @override
  String get common_next => 'Suivant';

  @override
  String get common_back => 'Retour';

  @override
  String get common_confirm => 'Confirmer';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_settings => 'Paramètres';

  @override
  String get common_logout => 'Déconnexion';

  @override
  String get common_language => 'Langue';

  @override
  String get common_english => 'English';

  @override
  String get common_french => 'Français';

  @override
  String get common_german => 'Deutsch';

  @override
  String get auth_signUp => 'S\'inscrire';

  @override
  String get auth_login => 'Se connecter';

  @override
  String get auth_email => 'E-mail';

  @override
  String get auth_password => 'Mot de passe';

  @override
  String get auth_confirmPassword => 'Confirmer le mot de passe';

  @override
  String get auth_forgotPassword => 'Mot de passe oublié?';

  @override
  String get auth_rememberMe => 'Se souvenir de moi';

  @override
  String get auth_signInWithGoogle => 'Continuer avec Google';

  @override
  String get auth_signInWithApple => 'Continuer avec Apple';

  @override
  String get auth_noAccount => 'Pas encore de compte?';

  @override
  String get auth_haveAccount => 'Vous avez déjà un compte?';

  @override
  String get auth_createAccount => 'Créer un compte';

  @override
  String get auth_emailRequired => 'L\'e-mail est requis';

  @override
  String get auth_invalidEmail => 'Adresse e-mail invalide';

  @override
  String get auth_passwordRequired => 'Le mot de passe est requis';

  @override
  String get auth_passwordTooShort => 'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get auth_passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get auth_loginSuccess => 'Bienvenue!';

  @override
  String get auth_signupSuccess => 'Compte créé avec succès!';

  @override
  String get auth_loginFailed => 'Connexion échouée. Veuillez réessayer.';

  @override
  String get auth_signupFailed => 'L\'inscription a échoué. Veuillez réessayer.';

  @override
  String get auth_logoutSuccess => 'Vous avez été déconnecté';

  @override
  String get home_welcome => 'Bienvenue';

  @override
  String home_hello(String name) {
    return 'Bonjour, $name!';
  }

  @override
  String get home_tryOn => 'Essayer';

  @override
  String get home_recommendations => 'Recommandations';

  @override
  String get home_savedOutfits => 'Tenues enregistrées';

  @override
  String get home_profile => 'Profil';

  @override
  String get home_noOutfits => 'Aucune tenue pour l\'instant';

  @override
  String get home_startTryOn => 'Commencez votre premier essayage virtuel';

  @override
  String get vton_title => 'Essayage Virtuel';

  @override
  String get vton_selectPhoto => 'Sélectionner une photo';

  @override
  String get vton_uploadPhoto => 'Télécharger une photo';

  @override
  String get vton_takePhoto => 'Prendre une photo';

  @override
  String get vton_selectClothes => 'Sélectionner des vêtements';

  @override
  String get vton_processing => 'Traitement de votre tenue...';

  @override
  String get vton_analyzing => 'Analyse de l\'image...';

  @override
  String get vton_generatingOutfit => 'Génération de l\'essayage virtuel...';

  @override
  String get vton_ready => 'Votre tenue est prête!';

  @override
  String get vton_save => 'Enregistrer la tenue';

  @override
  String get vton_share => 'Partager';

  @override
  String get vton_tryAnother => 'Essayer une autre';

  @override
  String get vton_noPhotoSelected => 'Veuillez d\'abord sélectionner une photo';

  @override
  String get vton_noClothesSelected => 'Veuillez d\'abord sélectionner des vêtements';

  @override
  String get vton_processingFailed => 'Échec du traitement de la tenue. Veuillez réessayer.';

  @override
  String get vton_uploadFailed => 'Échec du téléchargement de l\'image';

  @override
  String get vton_invalidImage => 'Veuillez sélectionner une image valide';

  @override
  String get vton_imageTooLarge => 'L\'image est trop grande. Veuillez en sélectionner une plus petite.';

  @override
  String get vton_networkError => 'Erreur réseau. Veuillez vérifier votre connexion.';

  @override
  String get vton_serverError => 'Erreur du serveur. Veuillez réessayer plus tard.';

  @override
  String get vton_timeoutError => 'La demande a expiré. Veuillez réessayer.';

  @override
  String get vton_unknownError => 'Une erreur inconnue s\'est produite';

  @override
  String get vton_quotaExceeded => 'Quota API dépassé. Veuillez réessayer plus tard.';

  @override
  String get vton_invalidApiKey => 'La clé API n\'est pas configurée. Veuillez contacter le support.';

  @override
  String get clothes_shirts => 'Chemises';

  @override
  String get clothes_pants => 'Pantalons';

  @override
  String get clothes_dresses => 'Robes';

  @override
  String get clothes_shoes => 'Chaussures';

  @override
  String get clothes_accessories => 'Accessoires';

  @override
  String get clothes_outerwear => 'Vêtements de dessus';

  @override
  String get clothes_allCategories => 'Toutes les catégories';

  @override
  String get clothes_viewDetails => 'Voir les détails';

  @override
  String get clothes_addToCart => 'Ajouter au panier';

  @override
  String get clothes_addedToCart => 'Ajouté au panier';

  @override
  String get recommendations_daily => 'Recommandations quotidiennes';

  @override
  String get recommendations_forYou => 'Recommandé pour vous';

  @override
  String get recommendations_trending => 'Tendances maintenant';

  @override
  String get recommendations_similar => 'Articles similaires';

  @override
  String get recommendations_noRecommendations => 'Aucune recommandation disponible';

  @override
  String get recommendations_loadingRecommendations => 'Chargement des recommandations...';

  @override
  String get profile_myProfile => 'Mon profil';

  @override
  String get profile_editProfile => 'Modifier le profil';

  @override
  String get profile_firstName => 'Prénom';

  @override
  String get profile_lastName => 'Nom de famille';

  @override
  String get profile_email => 'E-mail';

  @override
  String get profile_phone => 'Téléphone';

  @override
  String get profile_saveChanges => 'Enregistrer les modifications';

  @override
  String get profile_changePassword => 'Changer le mot de passe';

  @override
  String get profile_preferences => 'Préférences';

  @override
  String get profile_favorites => 'Favoris';

  @override
  String get profile_history => 'Historique';

  @override
  String get profile_deleteAccount => 'Supprimer le compte';

  @override
  String get profile_about => 'À propos';

  @override
  String get profile_privacyPolicy => 'Politique de confidentialité';

  @override
  String get profile_termsOfService => 'Conditions d\'utilisation';

  @override
  String get settings_general => 'Général';

  @override
  String get settings_appearance => 'Apparence';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_privacy => 'Confidentialité';

  @override
  String get settings_language => 'Langue';

  @override
  String get settings_theme => 'Thème';

  @override
  String get settings_darkMode => 'Mode sombre';

  @override
  String get settings_lightMode => 'Mode clair';

  @override
  String get settings_systemMode => 'Système';

  @override
  String get settings_pushNotifications => 'Notifications push';

  @override
  String get settings_emailNotifications => 'Notifications par e-mail';

  @override
  String get settings_marketingEmails => 'E-mails marketing';

  @override
  String get errors_firebaseNotConfigured => 'Firebase n\'est pas configuré';

  @override
  String get errors_noInternet => 'Pas de connexion Internet';

  @override
  String get errors_tryAgain => 'Veuillez réessayer';

  @override
  String get errors_contactSupport => 'Veuillez contacter le support';

  @override
  String errors_fieldRequired(String field) {
    return '$field est requis';
  }

  @override
  String get success_saved => 'Enregistré avec succès';

  @override
  String get success_deleted => 'Supprimé avec succès';

  @override
  String get success_updated => 'Mis à jour avec succès';

  @override
  String get success_shared => 'Partagé avec succès';

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
  String get notifications_newRecommendation => 'Nouvelle recommandation pour vous';

  @override
  String get notifications_outfitSaved => 'Tenue enregistrée';

  @override
  String get notifications_tryOnComplete => 'Votre essayage est prêt';

  @override
  String get notifications_updateAvailable => 'Mise à jour disponible';
}
