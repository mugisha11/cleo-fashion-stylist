"""
Simple Virtual Try-On API - REFACTORED WITH TYPED EXCEPTIONS
Uses direct Gemini API (Nano Banana) for image generation
NO string-based error matching - all typed exceptions
"""
import logging
import uuid
import httpx
import base64
from fastapi import APIRouter, HTTPException
from typing import List, Optional
from pydantic import BaseModel, Field

from ..core.config import settings
from ..core.exceptions import (
    VTONException, APIError, ImageProcessingError, ValidationError, GenerationError,
    ErrorCode
)
from ..services.storage import StorageService
from ..stages.generation import Stage5ImageGeneration
import cv2
import numpy as np

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/tryon", tags=["tryon"])

# Initialize storage (optional)
storage_service = None
if settings.SUPABASE_URL and settings.SUPABASE_KEY:
    try:
        storage_service = StorageService(
            supabase_url=settings.SUPABASE_URL,
            supabase_key=settings.SUPABASE_KEY,
            bucket_name=settings.SUPABASE_STORAGE_BUCKET
        )
    except Exception as e:
        logger.warning(f"Storage service initialization failed: {e}")

# Initialize Gemini image generation (Nano Banana) - DIRECT API ONLY
# HARD REQUIREMENT: Gemini image generation MUST use direct API, never OpenRouter
stage5_generation = Stage5ImageGeneration(use_pro_model=settings.GEMINI_USE_PRO_MODEL)


class TryOnRequest(BaseModel):
    """Request for virtual try-on"""
    user_image_url: str = Field(None, description="URL of user photo")
    garment_image_urls: List[str] = Field(..., description="List of clothing image URLs")


class TryOnBase64Request(BaseModel):
    """Request for virtual try-on with Base64 encoded user image"""
    user_image_base64: str = Field(..., description="User image as Base64 data URI or raw Base64")
    garment_images: List[str] = Field(..., description="List of clothing image URLs")
    source: str = Field(default="app", description="Source of request (app or recommendation)")


class TryOnResponse(BaseModel):
    """Response from virtual try-on API"""
    status: str = Field(..., description="success or failed")
    result_image_url: Optional[str] = Field(None, description="CDN URL of result image")
    result_image_base64: Optional[str] = Field(None, description="Result image as Base64")
    message: Optional[str] = Field(None, description="Error message if failed")
    code: Optional[str] = Field(None, description="Error code if failed")


# EXACT instruction prompt template (MUST NOT be altered)
# EXACT instruction prompt template (MUST NOT be altered)
TRY_ON_INSTRUCTION = """Redraw the person in the first image wearing the clothing from the following images.
Preserve the exact same face, hairstyle, facial features, skin tone, body shape, pose, camera angle, lighting, and background.
Only replace the clothing.

Do NOT modify the face, head, hands, body proportions, or posture.
Fit the clothing naturally to the body according to real human anatomy.
Maintain realistic fabric drape, shadows, and lighting.
This is a photorealistic virtual try-on, not an illustration or art."""


def decode_base64_image(base64_string: str) -> np.ndarray:
    """
    Decode Base64 image string to numpy array.
    Handles both data URI format and raw Base64.
    
    Args:
        base64_string: Base64 string with or without data URI prefix
        
    Returns:
        np.ndarray: Decoded image
        
    Raises:
        ImageProcessingError: If decoding fails
    """
    try:
        # Remove data URI prefix if present
        if ',' in base64_string:
            base64_string = base64_string.split(',')[1]
        
        # Decode Base64
        image_bytes = base64.b64decode(base64_string)
        image = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
        
        if image is None:
            raise ImageProcessingError(
                code=ErrorCode.IMAGE_DECODE_FAILED,
                message="Failed to decode Base64 image",
                details="Invalid Base64 format or corrupted image data"
            )
        
        return image
    except Exception as e:
        raise ImageProcessingError(
            code=ErrorCode.IMAGE_DECODE_FAILED,
            message=f"Base64 decoding failed: {str(e)}",
            details=str(e)
        )


async def download_image(url: str, trace_id: str) -> np.ndarray:
    """
    Download and decode image from URL.
    
    Raises:
        ImageProcessingError: If download or decode fails
    """
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url)
            response.raise_for_status()
            image_bytes = response.content
            image = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
            
            if image is None:
                raise ImageProcessingError(
                    code=ErrorCode.IMAGE_DECODE_FAILED,
                    message=f"Failed to decode image from {url}",
                    details="Invalid image format or corrupted data"
                )
            
            return image
            
    except httpx.HTTPStatusError as e:
        if e.response.status_code == 404:
            raise ImageProcessingError(
                code=ErrorCode.IMAGE_DOWNLOAD_FAILED,
                message=f"Image not found at URL: {url}",
                details=f"HTTP {e.response.status_code}"
            )
        else:
            raise ImageProcessingError(
                code=ErrorCode.IMAGE_DOWNLOAD_FAILED,
                message=f"Failed to download image from {url}",
                details=f"HTTP {e.response.status_code}"
            )
    except httpx.RequestError as e:
        raise ImageProcessingError(
            code=ErrorCode.IMAGE_DOWNLOAD_FAILED,
            message=f"Network error downloading image from {url}",
            details=str(e)
        )


@router.get("/health")
async def tryon_health():
    """Health check for try-on endpoint"""
    return {
        "status": "healthy",
        "endpoint": "/tryon",
        "gemini_configured": bool(settings.GEMINI_API_KEY),
        "gemini_model": settings.GEMINI_MODEL
    }


@router.post("", response_model=TryOnResponse)
async def tryon_base64(request: TryOnBase64Request):
    """
    Virtual Try-On Endpoint with Base64 User Image
    
    Accepts Base64 encoded user image and generates try-on using Gemini.
    This is the primary endpoint for mobile/web apps.
    
    Request:
    {
        "user_image_base64": "data:image/jpeg;base64,..." or raw base64,
        "garment_images": ["https://...", "..."],
        "source": "app" or "recommendation"
    }
    
    Returns:
    {
        "status": "success",
        "result_image_base64": "data:image/jpeg;base64,..."
    }
    """
    trace_id = str(uuid.uuid4())
    
    try:
        # Validate Base64 image
        if not request.user_image_base64:
            raise ValidationError(
                code=ErrorCode.VALIDATION_MISSING_FIELD,
                message="user_image_base64 is required",
                details="Provide image as Base64 with or without data URI prefix"
            )
        
        # Validate garment images
        if not request.garment_images or len(request.garment_images) == 0:
            raise ValidationError(
                code=ErrorCode.VALIDATION_MISSING_FIELD,
                message="At least one garment image URL required",
                details="garment_images list cannot be empty"
            )
        
        logger.info(
            f"[{trace_id}] Processing Base64 try-on request from {request.source}: "
            f"{len(request.garment_images)} garment(s)"
        )
        
        # Decode user image from Base64
        logger.info(f"[{trace_id}] Decoding Base64 user image")
        user_image = decode_base64_image(request.user_image_base64)
        logger.info(f"[{trace_id}] User image decoded: {user_image.shape}")
        
        # Download first garment image
        garment_url = request.garment_images[0]
        logger.info(f"[{trace_id}] Downloading garment image from: {garment_url}")
        garment_image = await download_image(garment_url, trace_id)
        logger.info(f"[{trace_id}] Garment image downloaded: {garment_image.shape}")
        
        # Generate try-on image using DIRECT Gemini API
        try:
            generated_image = await stage5_generation.execute(
                user_image=user_image,
                garment_image=garment_image,
                prompt=TRY_ON_INSTRUCTION,
                garment_type="garment",
                aspect_ratio=None
            )
            
            # Convert to Base64
            _, buffer = cv2.imencode('.jpg', generated_image)
            image_bytes = buffer.tobytes()
            image_b64 = base64.b64encode(image_bytes).decode('utf-8')
            result_image_base64 = f"data:image/jpeg;base64,{image_b64}"
            
            logger.info(f"[{trace_id}] Try-on generated successfully using {stage5_generation.model_name}")
            
            return TryOnResponse(
                status="success",
                result_image_base64=result_image_base64,
            )
            
        except (APIError, GenerationError) as e:
            logger.error(f"[{trace_id}] Generation error: {e}")
            return TryOnResponse(
                status="failed",
                message=e.message,
                code=e.code.value
            )
        except httpx.HTTPStatusError as e:
            error_msg = f"API error HTTP {e.response.status_code}"
            logger.error(f"[{trace_id}] {error_msg}")
            return TryOnResponse(
                status="failed",
                message=error_msg,
                code="API_ERROR"
            )
        except Exception as e:
            error_msg = f"Generation error: {str(e)}"
            logger.error(f"[{trace_id}] {error_msg}")
            return TryOnResponse(
                status="failed",
                message=error_msg,
                code="GENERATION_ERROR"
            )
            
    except ValidationError as e:
        logger.error(f"[{trace_id}] Validation error: {e}")
        return TryOnResponse(
            status="failed",
            message=e.message,
            code=e.code.value
        )
    except Exception as e:
        logger.error(f"[{trace_id}] Unexpected error: {e}")
        return TryOnResponse(
            status="failed",
            message="Internal server error",
            code="SERVER_ERROR"
        )


@router.post("/legacy", response_model=TryOnResponse)
async def tryon(request: TryOnRequest):
    """
    Simple Virtual Try-On Endpoint (LEGACY - use base64 endpoint instead)
    
    Uses DIRECT Gemini API (Nano Banana) for image generation.
    NO OpenRouter fallback for Gemini image models (hard requirement).
    
    Request:
    {
        "user_image_url": "https://...",
        "garment_image_urls": ["https://...", "..."]
    }
    
    Returns:
    {
        "status": "success",
        "result_image_url": "data:image/jpeg;base64,..."
    }
    """
    trace_id = str(uuid.uuid4())
    
    try:
        # Validate URLs
        if not request.user_image_url or not request.user_image_url.startswith(("http://", "https://", "data:image")):
            raise ValidationError(
                code=ErrorCode.VALIDATION_INVALID_URL,
                message="Invalid user_image_url",
                details="URL must start with http://, https://, or data:image"
            )
        
        if not request.garment_image_urls or len(request.garment_image_urls) == 0:
            raise ValidationError(
                code=ErrorCode.VALIDATION_MISSING_FIELD,
                message="At least one garment_image_url required",
                details="garment_image_urls list cannot be empty"
            )
        
        for url in request.garment_image_urls:
            if not url.startswith(("http://", "https://", "data:image")):
                raise ValidationError(
                    code=ErrorCode.VALIDATION_INVALID_URL,
                    message=f"Invalid garment_image_url: {url}",
                    details="URL must start with http://, https://, or data:image"
                )
        
        logger.info(f"[{trace_id}] Processing try-on request: {len(request.garment_image_urls)} garment(s)")
        
        # Download and prepare images
        logger.info(f"[{trace_id}] Downloading user image from: {request.user_image_url}")
        user_image = await download_image(request.user_image_url, trace_id)
        logger.info(f"[{trace_id}] User image downloaded: {user_image.shape}")
        
        garment_url = request.garment_image_urls[0]
        logger.info(f"[{trace_id}] Downloading garment image from: {garment_url}")
        garment_image = await download_image(garment_url, trace_id)
        logger.info(f"[{trace_id}] Garment image downloaded: {garment_image.shape}")
        
        # Create try-on prompt
        try_on_prompt = """Redraw the person in the second image wearing the clothing from the first image.
Preserve the exact same face, hairstyle, facial features, skin tone, body shape, pose, camera angle, lighting, and background.
Only replace the clothing.

Do NOT modify the face, head, hands, body proportions, or posture.
Fit the clothing naturally to the body according to real human anatomy.
Maintain realistic fabric drape, shadows, and lighting.
This is a photorealistic virtual try-on, not an illustration or art."""
        
        # Generate try-on image using DIRECT Gemini API (Nano Banana)
        # HARD REQUIREMENT: No OpenRouter fallback for Gemini image models
        try:
            generated_image = await stage5_generation.execute(
                user_image=user_image,
                garment_image=garment_image,
                prompt=try_on_prompt,
                garment_type="garment",
                aspect_ratio=None
            )
            
            # Convert generated image to base64 data URL
            _, buffer = cv2.imencode('.jpg', generated_image)
            image_bytes = buffer.tobytes()
            image_b64 = base64.b64encode(image_bytes).decode('utf-8')
            result_image_data_url = f"data:image/jpeg;base64,{image_b64}"
            
            logger.info(f"[{trace_id}] Image generated successfully using {stage5_generation.model_name}")
            
        except httpx.HTTPStatusError as e:
            # Map HTTP status codes to typed exceptions
            if e.response.status_code == 404:
                raise APIError(
                    code=ErrorCode.API_MODEL_NOT_FOUND,
                    message="Gemini model or endpoint not found",
                    details=f"HTTP 404: {e.response.text[:200]}"
                )
            elif e.response.status_code == 429:
                raise APIError(
                    code=ErrorCode.API_RATE_LIMIT,
                    message="API rate limit exceeded",
                    details="Please wait a moment and try again"
                )
            elif e.response.status_code == 401:
                raise APIError(
                    code=ErrorCode.API_UNAUTHORIZED,
                    message="Gemini API authentication failed",
                    details="Check GEMINI_API_KEY configuration"
                )
            elif e.response.status_code >= 500:
                raise APIError(
                    code=ErrorCode.API_SERVER_ERROR,
                    message="Gemini API server error",
                    details=f"HTTP {e.response.status_code}: {e.response.text[:200]}"
                )
            else:
                raise APIError(
                    code=ErrorCode.API_SERVER_ERROR,
                    message=f"Gemini API error: HTTP {e.response.status_code}",
                    details=e.response.text[:200]
                )
        except httpx.TimeoutException:
            raise APIError(
                code=ErrorCode.API_TIMEOUT,
                message="Request to Gemini API timed out",
                details="The API did not respond within the timeout period"
            )
        except httpx.RequestError as e:
            raise APIError(
                code=ErrorCode.API_NETWORK_ERROR,
                message="Network error connecting to Gemini API",
                details=str(e)
            )
        except (APIError, GenerationError):
            # Re-raise typed exceptions from generation stage
            raise
        except ValueError as e:
            # ValueError from generation stage - check error message for specific cases
            error_str = str(e)
            if "GEMINI_API_KEY not configured" in error_str or "not configured" in error_str.lower():
                raise APIError(
                    code=ErrorCode.CONFIG_MISSING_API_KEY,
                    message="Gemini API key not configured",
                    details="Set GEMINI_API_KEY environment variable"
                )
            elif "No image generated" in error_str:
                raise GenerationError(
                    code=ErrorCode.GENERATION_NO_IMAGE,
                    message="No image generated in response",
                    details="Gemini API did not return an image"
                )
            else:
                raise GenerationError(
                    code=ErrorCode.GENERATION_FAILED,
                    message="Image generation failed",
                    details=error_str
                )
        
        # Optionally upload to storage
        result_image_url = result_image_data_url
        if storage_service and result_image_data_url.startswith("data:image"):
            try:
                image_b64 = result_image_data_url.split(",")[1]
                image_bytes = base64.b64decode(image_b64)
                
                from PIL import Image
                import io
                
                img = Image.open(io.BytesIO(image_bytes))
                img_array = np.array(img)
                if len(img_array.shape) == 3 and img_array.shape[2] == 3:
                    img_array = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
                
                uploaded_url = storage_service.upload_image(
                    image=img_array,
                    user_id="anonymous",
                    image_type="tryon_result"
                )
                if uploaded_url:
                    result_image_url = uploaded_url
                    logger.info(f"[{trace_id}] Image uploaded to storage: {uploaded_url}")
            except Exception as e:
                logger.warning(f"[{trace_id}] Storage upload failed, returning base64: {e}")
        
        return TryOnResponse(
            status="success",
            result_image_url=result_image_url
        )
        
    except VTONException as e:
        # VTON exceptions are handled by global exception handler
        # But we can also return them in the response format
        logger.error(f"[{trace_id}] {e.code.value}: {e.message}")
        return TryOnResponse(
            status="failed",
            message=e.message,
            code=e.code.value
        )
    except HTTPException:
        raise
    except Exception as e:
        # Catch-all for unexpected errors
        logger.error(f"[{trace_id}] Unexpected error: {e}", exc_info=True)
        raise GenerationError(
            code=ErrorCode.GENERATION_FAILED,
            message="Unexpected error during try-on generation",
            details=str(e)[:300]
        )
