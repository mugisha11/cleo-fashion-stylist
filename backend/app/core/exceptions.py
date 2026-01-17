"""
Typed Exception Hierarchy for VTON API
Eliminates string-based error matching
"""
from enum import Enum
from typing import Optional


class ErrorCode(str, Enum):
    """Canonical error codes - no string matching needed"""
    # Configuration errors
    CONFIG_MISSING_API_KEY = "CONFIG_MISSING_API_KEY"
    CONFIG_INVALID_MODEL = "CONFIG_INVALID_MODEL"
    CONFIG_INVALID_ENDPOINT = "CONFIG_INVALID_ENDPOINT"
    
    # API errors
    API_MODEL_NOT_FOUND = "API_MODEL_NOT_FOUND"  # 404 from API
    API_RATE_LIMIT = "API_RATE_LIMIT"  # 429
    API_UNAUTHORIZED = "API_UNAUTHORIZED"  # 401
    API_TIMEOUT = "API_TIMEOUT"
    API_NETWORK_ERROR = "API_NETWORK_ERROR"
    API_SERVER_ERROR = "API_SERVER_ERROR"  # 5xx
    
    # Image processing errors
    IMAGE_DOWNLOAD_FAILED = "IMAGE_DOWNLOAD_FAILED"
    IMAGE_DECODE_FAILED = "IMAGE_DECODE_FAILED"
    IMAGE_INVALID_FORMAT = "IMAGE_INVALID_FORMAT"
    
    # Generation errors
    GENERATION_NO_IMAGE = "GENERATION_NO_IMAGE"
    GENERATION_FAILED = "GENERATION_FAILED"
    
    # Validation errors
    VALIDATION_INVALID_URL = "VALIDATION_INVALID_URL"
    VALIDATION_MISSING_FIELD = "VALIDATION_MISSING_FIELD"


class VTONException(Exception):
    """Base exception for all VTON errors"""
    def __init__(
        self,
        code: ErrorCode,
        message: str,
        details: Optional[str] = None,
        http_status: int = 500
    ):
        self.code = code
        self.message = message
        self.details = details
        self.http_status = http_status
        super().__init__(self.message)
    
    def to_dict(self) -> dict:
        """Convert to API response format"""
        result = {
            "code": self.code.value,
            "message": self.message,
            "status": "failed"
        }
        if self.details:
            result["details"] = self.details
        return result


class ConfigurationError(VTONException):
    """Configuration-related errors"""
    def __init__(self, code: ErrorCode, message: str, details: Optional[str] = None):
        super().__init__(code, message, details, http_status=500)


class APIError(VTONException):
    """API-related errors (Gemini, OpenRouter)"""
    def __init__(
        self,
        code: ErrorCode,
        message: str,
        details: Optional[str] = None,
        http_status: int = 502
    ):
        super().__init__(code, message, details, http_status)


class ImageProcessingError(VTONException):
    """Image download/processing errors"""
    def __init__(self, code: ErrorCode, message: str, details: Optional[str] = None):
        super().__init__(code, message, details, http_status=400)


class ValidationError(VTONException):
    """Request validation errors"""
    def __init__(self, code: ErrorCode, message: str, details: Optional[str] = None):
        super().__init__(code, message, details, http_status=400)


class GenerationError(VTONException):
    """Image generation errors"""
    def __init__(self, code: ErrorCode, message: str, details: Optional[str] = None):
        super().__init__(code, message, details, http_status=500)
