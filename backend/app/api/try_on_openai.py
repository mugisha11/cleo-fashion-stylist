"""
OpenAI-based Virtual Try-On API
Uses DALL-E 3 for image generation via OpenAI API
"""
import logging
import uuid
import base64
import httpx
from fastapi import APIRouter, HTTPException
from typing import List
from pydantic import BaseModel, Field

from ..core.config import settings
from ..core.exceptions import APIError, ValidationError, ErrorCode

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/try-on-openai", tags=["try-on-openai"])


class TryOnRequest(BaseModel):
    """Request for virtual try-on"""
    user_image_url: str = Field(..., description="URL of user photo")
    garment_image_urls: List[str] = Field(..., description="List of clothing image URLs")


class TryOnResponse(BaseModel):
    """Response for virtual try-on"""
    status: str
    result_image_url: str


@router.get("/health")
async def openai_tryon_health():
    """Health check for OpenAI try-on endpoint"""
    return {
        "status": "healthy",
        "endpoint": "/try-on-openai",
        "openai_configured": bool(settings.OPENAI_API_KEY),
        "model": "dall-e-3"
    }


@router.post("", response_model=TryOnResponse)
async def try_on_openai(request: TryOnRequest):
    """
    Virtual Try-On using DALL-E 3 (OpenAI)
    
    Uses OpenAI's DALL-E 3 for image generation.
    Generates a photorealistic virtual try-on result.
    
    Request:
    {
        "user_image_url": "https://...",
        "garment_image_urls": ["https://..."]
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
        
        logger.info(f"[{trace_id}] Processing try-on request with OpenAI DALL-E 3")
        
        # Create try-on prompt for DALL-E 3
        try_on_prompt = """You are a professional fashion virtual try-on AI.

User has provided:
1. A photo of a person (user_image_url)
2. A photo of clothing/garment (garment_image_urls[0])

Your task: Generate a photorealistic image of the person wearing the clothing.

CRITICAL REQUIREMENTS:
- Preserve the exact same FACE, facial features, skin tone, hairstyle
- Preserve body shape, pose, posture, and camera angle
- Preserve the background and lighting conditions
- Preserve hands and exposed skin areas
- ONLY change the clothing - replace old clothes with the new garment
- Fit clothing naturally to the body with realistic drape and shadows
- Maintain photorealistic quality - this is NOT a drawing or illustration
- Keep the same proportions and positioning

The result should look like a professional fashion photography virtual try-on result."""
        
        # Call OpenAI DALL-E 3 API
        api_key = settings.OPENAI_API_KEY
        if not api_key:
            raise APIError(
                code=ErrorCode.CONFIG_MISSING_API_KEY,
                message="OpenAI API key not configured",
                details="Set OPENAI_API_KEY in environment"
            )
        
        logger.info(f"[{trace_id}] Calling OpenAI DALL-E 3 API")
        
        async with httpx.AsyncClient(timeout=60) as client:
            # For DALL-E 3, we use text prompts enhanced with image URLs
            response = await client.post(
                "https://api.openai.com/v1/images/generations",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "dall-e-3",
                    "prompt": try_on_prompt + f"\n\nUser image: {request.user_image_url}\nGarment image: {request.garment_image_urls[0]}",
                    "n": 1,
                    "size": "1024x1024",
                    "quality": "hd",
                    "style": "natural"
                }
            )
        
        if response.status_code != 200:
            error_body = response.text
            logger.error(f"[{trace_id}] OpenAI API error: {response.status_code} - {error_body[:200]}")
            
            if response.status_code == 429:
                raise APIError(
                    code=ErrorCode.API_RATE_LIMIT,
                    message="OpenAI API rate limit exceeded",
                    details="Please wait a moment and try again"
                )
            elif response.status_code == 401:
                raise APIError(
                    code=ErrorCode.API_UNAUTHORIZED,
                    message="OpenAI API authentication failed",
                    details="Check OPENAI_API_KEY configuration"
                )
            elif response.status_code >= 500:
                raise APIError(
                    code=ErrorCode.API_SERVER_ERROR,
                    message="OpenAI API server error",
                    details=f"HTTP {response.status_code}"
                )
            else:
                raise APIError(
                    code=ErrorCode.API_SERVER_ERROR,
                    message=f"OpenAI API error: HTTP {response.status_code}",
                    details=error_body[:200]
                )
        
        # Parse response
        result = response.json()
        image_url = result.get("data", [{}])[0].get("url")
        
        if not image_url:
            raise APIError(
                code=ErrorCode.API_SERVER_ERROR,
                message="Invalid response from OpenAI API",
                details="No image URL in response"
            )
        
        logger.info(f"[{trace_id}] Image generated successfully!")
        
        return TryOnResponse(
            status="success",
            result_image_url=image_url
        )
        
    except ValidationError:
        raise
    except APIError:
        raise
    except httpx.TimeoutException:
        logger.error(f"[{trace_id}] Request timeout")
        raise APIError(
            code=ErrorCode.API_TIMEOUT,
            message="Request to OpenAI API timed out",
            details="The API did not respond within 60 seconds"
        )
    except httpx.RequestError as e:
        logger.error(f"[{trace_id}] Request error: {e}")
        raise APIError(
            code=ErrorCode.API_SERVER_ERROR,
            message="Network error communicating with OpenAI API",
            details=str(e)
        )
    except Exception as e:
        logger.error(f"[{trace_id}] Unexpected error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )
