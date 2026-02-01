"""
Backend Localization Module
Handles multilingual support for API responses and error messages
"""
from typing import Dict, Literal, Optional

# Supported languages
SUPPORTED_LANGUAGES = ["en", "fr", "de", "ar"]
DEFAULT_LANGUAGE = "en"

# Localization messages
MESSAGES: Dict[str, Dict[str, str]] = {
    "en": {
        # Common
        "loading": "Loading...",
        "processing": "Processing...",
        "error": "Something went wrong",
        "retry": "Please try again",
        
        # Authentication
        "auth_login_success": "Login successful",
        "auth_signup_success": "Sign up successful",
        "auth_login_failed": "Login failed. Please try again.",
        "auth_signup_failed": "Sign up failed. Please try again.",
        "auth_invalid_credentials": "Invalid email or password",
        "auth_email_exists": "Email already exists",
        "auth_email_not_found": "Email not found",
        "auth_password_weak": "Password is too weak",
        
        # Virtual Try-On
        "vton_processing": "Processing your outfit...",
        "vton_analyzing": "Analyzing image...",
        "vton_generating": "Generating virtual try-on...",
        "vton_success": "Try-on completed successfully",
        "vton_failed": "Failed to process outfit",
        "vton_no_photo": "Please select a photo first",
        "vton_no_clothes": "Please select clothes first",
        "vton_invalid_image": "Invalid image format or size",
        "vton_upload_failed": "Failed to upload image",
        
        # Network & Errors
        "network_error": "Network error. Please check your connection.",
        "server_error": "Server error. Please try again later.",
        "timeout_error": "Request timed out. Please try again.",
        "not_found": "Resource not found",
        "unauthorized": "Unauthorized. Please log in again.",
        
        # API Errors
        "api_quota_exceeded": "API quota exceeded. Please try again later.",
        "api_invalid_key": "API key is not configured",
        "api_rate_limit": "Rate limit exceeded. Please try again later.",
        "api_unavailable": "API service is unavailable",
    },
    "fr": {
        # Common
        "loading": "Chargement...",
        "processing": "Traitement...",
        "error": "Une erreur est survenue",
        "retry": "Veuillez réessayer",
        
        # Authentication
        "auth_login_success": "Connexion réussie",
        "auth_signup_success": "Inscription réussie",
        "auth_login_failed": "Connexion échouée. Veuillez réessayer.",
        "auth_signup_failed": "L'inscription a échoué. Veuillez réessayer.",
        "auth_invalid_credentials": "E-mail ou mot de passe invalide",
        "auth_email_exists": "Cet e-mail existe déjà",
        "auth_email_not_found": "E-mail non trouvé",
        "auth_password_weak": "Le mot de passe est trop faible",
        
        # Virtual Try-On
        "vton_processing": "Traitement de votre tenue...",
        "vton_analyzing": "Analyse de l'image...",
        "vton_generating": "Génération de l'essayage virtuel...",
        "vton_success": "Essayage complété avec succès",
        "vton_failed": "Échec du traitement de la tenue",
        "vton_no_photo": "Veuillez d'abord sélectionner une photo",
        "vton_no_clothes": "Veuillez d'abord sélectionner des vêtements",
        "vton_invalid_image": "Format ou taille d'image invalide",
        "vton_upload_failed": "Échec du téléchargement de l'image",
        
        # Network & Errors
        "network_error": "Erreur réseau. Veuillez vérifier votre connexion.",
        "server_error": "Erreur du serveur. Veuillez réessayer plus tard.",
        "timeout_error": "La demande a expiré. Veuillez réessayer.",
        "not_found": "Ressource non trouvée",
        "unauthorized": "Non autorisé. Veuillez vous reconnecter.",
        
        # API Errors
        "api_quota_exceeded": "Quota API dépassé. Veuillez réessayer plus tard.",
        "api_invalid_key": "La clé API n'est pas configurée",
        "api_rate_limit": "Limite de débit dépassée. Veuillez réessayer plus tard.",
        "api_unavailable": "Le service API n'est pas disponible",
    },
    "de": {
        # Common
        "loading": "Wird geladen...",
        "processing": "Wird verarbeitet...",
        "error": "Ein Fehler ist aufgetreten",
        "retry": "Bitte versuchen Sie es erneut",
        
        # Authentication
        "auth_login_success": "Anmeldung erfolgreich",
        "auth_signup_success": "Registrierung erfolgreich",
        "auth_login_failed": "Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.",
        "auth_signup_failed": "Registrierung fehlgeschlagen. Bitte versuchen Sie es erneut.",
        "auth_invalid_credentials": "Ungültige E-Mail oder Passwort",
        "auth_email_exists": "Diese E-Mail existiert bereits",
        "auth_email_not_found": "E-Mail nicht gefunden",
        "auth_password_weak": "Das Passwort ist zu schwach",
        
        # Virtual Try-On
        "vton_processing": "Ihr Outfit wird verarbeitet...",
        "vton_analyzing": "Bild wird analysiert...",
        "vton_generating": "Virtuelle Anprobe wird generiert...",
        "vton_success": "Anprobe erfolgreich abgeschlossen",
        "vton_failed": "Outfit-Verarbeitung fehlgeschlagen",
        "vton_no_photo": "Bitte wählen Sie zuerst ein Foto aus",
        "vton_no_clothes": "Bitte wählen Sie zuerst Kleidung aus",
        "vton_invalid_image": "Ungültiges Bildformat oder ungültige Größe",
        "vton_upload_failed": "Bild-Upload fehlgeschlagen",
        
        # Network & Errors
        "network_error": "Netzwerkfehler. Bitte überprüfen Sie Ihre Verbindung.",
        "server_error": "Serverfehler. Bitte versuchen Sie es später erneut.",
        "timeout_error": "Anfrage-Timeout. Bitte versuchen Sie es erneut.",
        "not_found": "Ressource nicht gefunden",
        "unauthorized": "Nicht autorisiert. Bitte melden Sie sich erneut an.",
        
        # API Errors
        "api_quota_exceeded": "API-Kontingent überschritten. Bitte versuchen Sie es später erneut.",
        "api_invalid_key": "API-Schlüssel ist nicht konfiguriert",
        "api_rate_limit": "Ratenlimit überschritten. Bitte versuchen Sie es später erneut.",
        "api_unavailable": "API-Dienst ist nicht verfügbar",
    },
}


class LocalizationService:
    """Service for handling multilingual support"""
    
    @staticmethod
    def get_message(
        key: str,
        language: str = DEFAULT_LANGUAGE,
        **kwargs
    ) -> str:
        """
        Get localized message
        
        Args:
            key: Message key
            language: Language code (en, fr, de)
            **kwargs: Format arguments
            
        Returns:
            Localized message string
        """
        # Validate language
        if language not in SUPPORTED_LANGUAGES:
            language = DEFAULT_LANGUAGE
        
        # Get message
        message = MESSAGES.get(language, {}).get(key, MESSAGES[DEFAULT_LANGUAGE].get(key, key))
        
        # Format with kwargs if provided
        try:
            if kwargs:
                message = message.format(**kwargs)
        except (KeyError, ValueError) as e:
            import logging
            logging.warning(f"Error formatting message '{key}': {e}")
        
        return message
    
    @staticmethod
    def get_error_response(
        error_key: str,
        language: str = DEFAULT_LANGUAGE,
        status_code: int = 400,
        **kwargs
    ) -> dict:
        """
        Get localized error response
        
        Args:
            error_key: Error message key
            language: Language code
            status_code: HTTP status code
            **kwargs: Format arguments
            
        Returns:
            Error response dictionary
        """
        return {
            "status": "error",
            "message": LocalizationService.get_message(error_key, language, **kwargs),
            "code": error_key,
            "language": language,
        }
    
    @staticmethod
    def get_success_response(
        message_key: str,
        language: str = DEFAULT_LANGUAGE,
        data: Optional[dict] = None,
        **kwargs
    ) -> dict:
        """
        Get localized success response
        
        Args:
            message_key: Success message key
            language: Language code
            data: Additional data to include
            **kwargs: Format arguments
            
        Returns:
            Success response dictionary
        """
        response = {
            "status": "success",
            "message": LocalizationService.get_message(message_key, language, **kwargs),
            "language": language,
        }
        
        if data:
            response["data"] = data
        
        return response


def get_language_from_request(request_data: Optional[dict] = None, headers: Optional[dict] = None) -> str:
    """
    Extract language from request
    
    Args:
        request_data: Request body/query parameters
        headers: Request headers
        
    Returns:
        Language code (en, fr, de)
    """
    # Check request body/params
    if request_data and isinstance(request_data, dict):
        language = request_data.get("language", "").lower()
        if language in SUPPORTED_LANGUAGES:
            return language
    
    # Check Accept-Language header
    if headers:
        accept_language = headers.get("Accept-Language", "").lower()
        # Extract first language preference
        if accept_language:
            lang_code = accept_language.split(",")[0].split("-")[0]
            if lang_code in SUPPORTED_LANGUAGES:
                return lang_code
    
    return DEFAULT_LANGUAGE
