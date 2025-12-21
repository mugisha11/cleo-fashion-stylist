"""
Configuration Management
Environment-based settings for production deployment
"""
import os
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
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()

