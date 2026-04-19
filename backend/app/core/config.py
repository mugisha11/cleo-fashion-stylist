"""
Configuration Management
Environment-based settings for production deployment
"""
import os
from pathlib import Path
from typing import Optional
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # API Configuration
    API_TITLE: str = "Cleo Fashion VTON API"
    API_VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"
    
    # Supabase Configuration
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_SERVICE_KEY", "")
    SUPABASE_STORAGE_BUCKET: str = os.getenv("SUPABASE_STORAGE_BUCKET", "tryon-results")
    
    # Model Paths
    VTON_MODEL_PATH: str = os.getenv("VTON_MODEL_PATH", "./models/hr-viton")
    HR_VITON_MODEL_PATH: str = os.getenv("HR_VITON_MODEL_PATH", "./models/hr-viton")
    PARSING_MODEL_PATH: str = os.getenv("PARSING_MODEL_PATH", "./models/schp")
    FACE_DETECTION_MODEL: str = os.getenv("FACE_DETECTION_MODEL", "retinaface")
    
    # Quality Thresholds (lowered for testing/development)
    FACE_SIMILARITY_THRESHOLD: float = float(os.getenv("FACE_SIMILARITY_THRESHOLD", "0.90"))  # Lowered from 0.98
    MIN_SHARPNESS: float = float(os.getenv("MIN_SHARPNESS", "0.2"))  # Lowered from 0.7 for testing
    MIN_POSE_CONFIDENCE: float = float(os.getenv("MIN_POSE_CONFIDENCE", "0.6"))  # Lowered from 0.8
    MIN_CLOTHING_COVERAGE: float = float(os.getenv("MIN_CLOTHING_COVERAGE", "0.5"))  # Lowered from 0.9
    
    # Stage 7 Quality Gates Thresholds (configurable for development)
    STAGE7_DISABLE_QUALITY_CHECKS: bool = os.getenv("STAGE7_DISABLE_QUALITY_CHECKS", "True").lower() == "true"  # Bypass quality checks for development (default: True)
    STAGE7_FACE_SIMILARITY_THRESHOLD: float = float(os.getenv("STAGE7_FACE_SIMILARITY_THRESHOLD", "0.70"))  # Very lenient for development
    STAGE7_POSE_DEVIATION_THRESHOLD: float = float(os.getenv("STAGE7_POSE_DEVIATION_THRESHOLD", "50.0"))  # Very lenient for development
    STAGE7_MIN_GARMENT_COVERAGE: float = float(os.getenv("STAGE7_MIN_GARMENT_COVERAGE", "0.05"))  # Very lenient (5% minimum)
    STAGE7_MAX_ARTIFACT_SCORE: float = float(os.getenv("STAGE7_MAX_ARTIFACT_SCORE", "0.8"))  # Very lenient (80% max allowed)
    
    # Retry Configuration
    MAX_RETRIES: int = int(os.getenv("MAX_RETRIES", "3"))
    RETRY_DELAY: float = float(os.getenv("RETRY_DELAY", "1.0"))
    
    # Image Processing
    MAX_IMAGE_SIZE: int = int(os.getenv("MAX_IMAGE_SIZE", "2048"))
    OUTPUT_QUALITY: int = int(os.getenv("OUTPUT_QUALITY", "95"))
    
    # GPU Configuration
    USE_GPU: bool = os.getenv("USE_GPU", "True").lower() == "true"
    GPU_DEVICE: int = int(os.getenv("GPU_DEVICE", "0"))
    
    # Storage
    TEMP_DIR: str = os.getenv("TEMP_DIR", "/tmp/vton")
    
    # OpenAI Configuration (for GPT-5-mini prompt synthesis)
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-5-mini-2025-08-07")
    OPENAI_BASE_URL: str = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
    
    # Claude AI Configuration
    CLAUDE_API_KEY: str = os.getenv("CLAUDE_API_KEY", "")
    CLAUDE_MODEL: str = os.getenv("CLAUDE_MODEL", "claude-3-5-sonnet-20241022")
    
    # OpenRouter Configuration (for GPT-4.1 Vision reasoning and Claude analysis in production-vton)
    OPENROUTER_API_KEY: str = os.getenv("OPENROUTER_API_KEY", "")
    OPENROUTER_MODEL_VISION: str = os.getenv("OPENROUTER_MODEL_VISION", "openai/gpt-4o")  # GPT-4.1 Vision
    OPENROUTER_MODEL_MINI: str = os.getenv("OPENROUTER_MODEL_MINI", "openai/gpt-4o-mini")  # GPT-4.1-mini
    OPENROUTER_BASE_URL: str = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
    
    # Google Cloud Retail fallback (optional)
    GOOGLE_RETAIL_API_KEY: str = os.getenv("GOOGLE_RETAIL_API_KEY", "")
    GOOGLE_RETAIL_PROJECT_ID: str = os.getenv("GOOGLE_RETAIL_PROJECT_ID", "")
    GOOGLE_RETAIL_LOCATION: str = os.getenv("GOOGLE_RETAIL_LOCATION", "global")
    GOOGLE_RETAIL_CATALOG: str = os.getenv("GOOGLE_RETAIL_CATALOG", "default_catalog")
    GOOGLE_RETAIL_BRANCH: str = os.getenv("GOOGLE_RETAIL_BRANCH", "0")
    GOOGLE_RETAIL_PLACEMENT: str = os.getenv("GOOGLE_RETAIL_PLACEMENT", "default_search")

    # Serper.dev Configuration for Google search fallback
    SERPER_API_KEY: str = os.getenv("SERPER_API_KEY", "")
    SERPER_API_BASE_URL: str = os.getenv("SERPER_API_BASE_URL", "https://google.serper.dev/search")

    # ASOS RapidAPI Configuration (for product image fetching)
    ASOS_RAPIDAPI_KEY: str = os.getenv("ASOS_RAPIDAPI_KEY", "")
    ASOS_RAPIDAPI_HOST: str = os.getenv("ASOS_RAPIDAPI_HOST", "asos-api6.p.rapidapi.com")
    
    # Try-On Configuration
    MIN_GARMENT_CONFIDENCE: float = float(os.getenv("MIN_GARMENT_CONFIDENCE", "0.90"))
    BODY_PARSING_METHOD: str = os.getenv("BODY_PARSING_METHOD", "mediapipe")  # mediapipe, densepose, openpose, schp
    
    # Gemini API Configuration (for Nano Banana - gemini-2.5-flash-image)
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.5-flash-image")  # Nano Banana - image generation model
    GEMINI_IMAGE_MODEL: str = ""  # Override for production-vton only; if unset uses GEMINI_MODEL. e.g. gemini-2.0-flash-preview-image-generation
    GEMINI_USE_PRO_MODEL: bool = os.getenv("GEMINI_USE_PRO_MODEL", "False").lower() == "true"  # Use Nano Banana Pro for high-quality try-ons
    
    # Remove.bg API Configuration
    REMOVE_BG_API_KEY: str = os.getenv("REMOVE_BG_API_KEY", "")
    
    # OpenRouter Gemini Models (for image generation via OpenRouter)
    OPENROUTER_MODEL_GEMINI: str = os.getenv("OPENROUTER_MODEL_GEMINI", "google/gemini-2.0-flash-exp")  # Gemini via OpenRouter
    OPENROUTER_MODEL_GEMINI_IMAGE: str = os.getenv("OPENROUTER_MODEL_GEMINI_IMAGE", "google/gemini-2.0-flash-exp")  # For image generation
    
    # Segmentation Configuration
    SEGMENTATION_METHOD: str = os.getenv("SEGMENTATION_METHOD", "rembg")  # rembg, sam, opencv
    SAM_CHECKPOINT_PATH: Optional[str] = os.getenv("SAM_CHECKPOINT_PATH", None)
    

    class Config:
        env_file = str(Path(__file__).resolve().parents[2] / ".env")
        env_file_encoding = "utf-8"
        case_sensitive = True
        extra = "ignore"  # Ignore extra environment variables not defined in the class


settings = Settings()

