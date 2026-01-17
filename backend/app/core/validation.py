"""
Startup-time validation for AI configuration
Fails fast if configuration is invalid
"""
import logging
import httpx
from typing import Tuple

from .config import settings
from .exceptions import ConfigurationError, ErrorCode

logger = logging.getLogger(__name__)


async def validate_gemini_configuration() -> Tuple[bool, str]:
    """
    Validate Gemini API configuration at startup.
    
    Returns:
        (is_valid, error_message)
    """
    # Check API key
    if not settings.GEMINI_API_KEY or settings.GEMINI_API_KEY.strip() == "":
        return False, "GEMINI_API_KEY is missing or empty"
    
    # Check model name
    if not settings.GEMINI_MODEL or settings.GEMINI_MODEL.strip() == "":
        return False, "GEMINI_MODEL is missing or empty"
    
    # Validate model name format (should be like "gemini-2.5-flash-image")
    valid_models = [
        "gemini-2.5-flash-image",
        "gemini-3-pro-image-preview",
        "gemini-2.0-flash-exp",
    ]
    if settings.GEMINI_MODEL not in valid_models:
        logger.warning(f"GEMINI_MODEL '{settings.GEMINI_MODEL}' not in known valid models. Proceeding anyway.")
    
    # Test API endpoint accessibility (non-blocking, just check DNS)
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            # Just check if we can resolve the domain
            response = await client.get("https://generativelanguage.googleapis.com", timeout=5.0)
            # Any response (even 404) means DNS works
            return True, ""
    except Exception as e:
        logger.warning(f"Could not reach Gemini API endpoint: {e}. This may be a network issue.")
        # Don't fail startup for network issues - might be temporary
        return True, ""
    
    return True, ""


async def validate_openrouter_configuration() -> Tuple[bool, str]:
    """
    Validate OpenRouter configuration (optional, only if used).
    
    Returns:
        (is_valid, error_message)
    """
    # OpenRouter is optional (fallback only)
    if not settings.OPENROUTER_API_KEY or settings.OPENROUTER_API_KEY.strip() == "":
        logger.warning("OPENROUTER_API_KEY not configured. OpenRouter fallback will be unavailable.")
        return True, ""  # Not required, just warn
    
    return True, ""


async def validate_all_configurations() -> None:
    """
    Validate all AI configurations at startup.
    Raises ConfigurationError if validation fails.
    """
    logger.info("Validating AI configuration...")
    
    # Validate Gemini (required)
    gemini_valid, gemini_error = await validate_gemini_configuration()
    if not gemini_valid:
        raise ConfigurationError(
            code=ErrorCode.CONFIG_MISSING_API_KEY,
            message="Gemini API configuration invalid",
            details=gemini_error
        )
    
    # Validate OpenRouter (optional)
    openrouter_valid, openrouter_error = await validate_openrouter_configuration()
    if not openrouter_valid:
        logger.warning(f"OpenRouter validation warning: {openrouter_error}")
    
    logger.info("✅ AI configuration validated successfully")
