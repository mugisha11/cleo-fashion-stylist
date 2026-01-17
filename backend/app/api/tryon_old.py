"""
Simple Virtual Try-On API
Uses OpenRouter + Gemini Nano Banana for direct image generation
"""
import logging
import uuid
import httpx  # type: ignore
import base64
from fastapi import APIRouter, HTTPException  # type: ignore
from typing import List, Optional
from pydantic import BaseModel, Field  # type: ignore

from ..core.config import settings
from ..services.storage import StorageService
from ..stages.generation import Stage5ImageGeneration
import cv2  # type: ignore
import numpy as np  # type: ignore

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

# Initialize Gemini image generation (Nano Banana)
stage5_generation = Stage5ImageGeneration(use_pro_model=settings.GEMINI_USE_PRO_MODEL)


class TryOnRequest(BaseModel):
    """Request for virtual try-on"""
    user_image_url: str = Field(..., description="URL of user photo")
    garment_image_urls: List[str] = Field(..., description="List of clothing image URLs")


class TryOnResponse(BaseModel):
    """Response from virtual try-on API"""
    status: str = Field(..., description="success or failed")
    result_image_url: Optional[str] = Field(None, description="CDN URL of result image")
    message: Optional[str] = Field(None, description="Error message if failed")


# EXACT instruction prompt template (MUST NOT be altered)
TRY_ON_INSTRUCTION = """Redraw the person in the first image wearing the clothing from the following images.
Preserve the exact same face, hairstyle, facial features, skin tone, body shape, pose, camera angle, lighting, and background.
Only replace the clothing.

Do NOT modify the face, head, hands, body proportions, or posture.
Fit the clothing naturally to the body according to real human anatomy.
Maintain realistic fabric drape, shadows, and lighting.
This is a photorealistic virtual try-on, not an illustration or art."""


async def download_image_to_base64(image_url: str) -> str:
    """Download image from URL and convert to base64 data URL"""
    try:
        # Check if already base64
        if image_url.startswith("data:image"):
            return image_url
        
        # Download from URL
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(image_url)
            response.raise_for_status()
            
            # Get content type
            content_type = response.headers.get("content-type", "image/jpeg")
            if not content_type.startswith("image/"):
                content_type = "image/jpeg"
            
            # Encode to base64
            image_bytes = response.content
            image_b64 = base64.b64encode(image_bytes).decode('utf-8')
            return f"data:{content_type};base64,{image_b64}"
    except httpx.HTTPStatusError as e:
        logger.error(f"HTTP error downloading image {image_url}: {e.response.status_code}")
        raise Exception(f"Failed to download image: HTTP {e.response.status_code}")
    except Exception as e:
        logger.error(f"Failed to download image {image_url}: {e}")
        raise Exception(f"Failed to download image: {str(e)}")


async def generate_tryon_via_openrouter(
    user_image_url: str,
    garment_image_urls: List[str],
    trace_id: str
) -> str:
    """
    Generate try-on image using OpenRouter + Gemini Nano Banana
    
    Args:
        user_image_url: URL of user photo
        garment_image_urls: List of garment image URLs
        trace_id: Trace ID for logging
        
    Returns:
        Base64 encoded image data URL
        
    Raises:
        Exception: If generation fails
    """
    if not settings.OPENROUTER_API_KEY:
        raise ValueError("OPENROUTER_API_KEY not configured")
    
    logger.info(f"[{trace_id}] Downloading and converting images to base64...")
    
    # Download and convert all images to base64
    user_image_b64 = await download_image_to_base64(user_image_url)
    garment_images_b64 = []
    for garment_url in garment_image_urls:
        garment_b64 = await download_image_to_base64(garment_url)
        garment_images_b64.append(garment_b64)
    
    # Build content array with instruction and images (OpenRouter OpenAI-compatible format)
    content = [
        {"type": "text", "text": TRY_ON_INSTRUCTION},
        {
            "type": "image_url",
            "image_url": {"url": user_image_b64}
        }
    ]
    
    # Add all garment images
    for garment_b64 in garment_images_b64:
        content.append({
            "type": "image_url",
            "image_url": {"url": garment_b64}
        })
    
    # Prepare request payload - try multiple model names
    # OpenRouter model names for Gemini image generation
    # NOTE: Some models may not be available - using verified working models
    models_to_try = [
        "google/gemini-2.0-flash-exp",    # Primary - Verified working
        "google/gemini-1.5-pro",          # Fallback 1
        "google/gemini-flash-1.5-8b",     # Fallback 2
        "openai/dall-e-3",                 # Fallback 3 - OpenAI DALL-E
    ]
    
    payload = {
        "model": models_to_try[0],  # Start with primary
        "messages": [{
            "role": "user",
            "content": content
        }],
        "modalities": ["image", "text"]  # Request both image and text
    }
    
    logger.info(f"[{trace_id}] Sending try-on request to OpenRouter")
    logger.info(f"[{trace_id}]   - Garments: {len(garment_image_urls)}")
    logger.info(f"[{trace_id}]   - Model: {payload['model']}")
    logger.info(f"[{trace_id}]   - OpenRouter URL: {settings.OPENROUTER_BASE_URL}")
    logger.info(f"[{trace_id}]   - API Key present: {bool(settings.OPENROUTER_API_KEY)}")
    
    last_error = None
    for model in models_to_try:
        try:
            payload["model"] = model
            logger.info(f"[{trace_id}] Trying model: {model}")
            
            async with httpx.AsyncClient(timeout=120.0) as client:
                response = await client.post(
                    f"{settings.OPENROUTER_BASE_URL}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
                        "Content-Type": "application/json",
                        "HTTP-Referer": "https://cleo-fashion.com",
                        "X-Title": "Cleo Fashion VTON"
                    },
                    json=payload
                )
                
                # Log response for debugging
                logger.debug(f"[{trace_id}] Response status: {response.status_code}")
                
                if response.status_code == 404:
                    logger.warning(f"[{trace_id}] Model {model} not found (404), trying next...")
                    last_error = f"Model {model} not found"
                    continue
                
                response.raise_for_status()
                result = response.json()
                
                logger.debug(f"[{trace_id}] Response keys: {list(result.keys())}")
                
                # Extract image from response - OpenRouter returns images in 'images' field
                choices = result.get("choices", [])
                if not choices:
                    raise ValueError("No choices in response")
                
                message = choices[0].get("message", {})
                
                # Check for images field (OpenRouter format)
                images = message.get("images", [])
                if images and len(images) > 0:
                    image_item = images[0]
                    if isinstance(image_item, dict):
                        image_url_obj = image_item.get("image_url", {})
                        if isinstance(image_url_obj, dict):
                            image_data_url = image_url_obj.get("url")
                        elif isinstance(image_url_obj, str):
                            image_data_url = image_url_obj
                        else:
                            image_data_url = str(image_url_obj)
                    else:
                        image_data_url = str(image_item)
                    
                    if image_data_url and image_data_url.startswith("data:image"):
                        logger.info(f"[{trace_id}] Image generated successfully with model {model}")
                        return image_data_url
                
                # Fallback: Check content field (some models return here)
                content_response = message.get("content", [])
                if isinstance(content_response, list):
                    for item in content_response:
                        if item.get("type") == "image_url":
                            image_url_obj = item.get("image_url", {})
                            if isinstance(image_url_obj, dict):
                                image_data_url = image_url_obj.get("url")
                            else:
                                image_data_url = str(image_url_obj)
                            if image_data_url and image_data_url.startswith("data:image"):
                                logger.info(f"[{trace_id}] Image found in content field")
                                return image_data_url
                
                # Fallback: Check if content is a string with base64
                if isinstance(content_response, str) and "data:image" in content_response:
                    import re
                    match = re.search(r'data:image/[^;]+;base64,([A-Za-z0-9+/=]+)', content_response)
                    if match:
                        image_data_url = f"data:image/png;base64,{match.group(1)}"
                        logger.info(f"[{trace_id}] Image extracted from text content")
                        return image_data_url
                
                # If we get here, no image found
                logger.warning(f"[{trace_id}] No image found in response from {model}")
                logger.debug(f"[{trace_id}] Message structure: {list(message.keys())}")
                last_error = f"No image data in response from {model}"
                continue
                
        except httpx.HTTPStatusError as e:
            error_text = e.response.text if hasattr(e.response, 'text') else str(e)
            logger.error(f"[{trace_id}] HTTP error with {model}: {e.response.status_code} - {error_text[:200]}")
            last_error = f"HTTP {e.response.status_code}: {error_text[:100]}"
            if e.response.status_code == 404:
                continue  # Try next model
            elif e.response.status_code >= 400 and e.response.status_code < 500:
                raise Exception(f"OpenRouter API error {e.response.status_code}: {error_text[:200]}")
        except Exception as e:
            logger.error(f"[{trace_id}] Error with model {model}: {e}")
            last_error = str(e)
            continue
    
    # All models failed
    raise Exception(f"All models failed. Last error: {last_error}")


@router.get("/health")
async def tryon_health():
    """Health check for try-on endpoint"""
    return {
        "status": "healthy",
        "endpoint": "/tryon",
        "openrouter_configured": bool(settings.OPENROUTER_API_KEY),
        "openrouter_url": settings.OPENROUTER_BASE_URL
    }


@router.post("", response_model=TryOnResponse)
async def tryon(request: TryOnRequest):
    """
    Simple Virtual Try-On Endpoint
    
    Takes user photo and clothing images, generates try-on using Gemini Nano Banana via OpenRouter.
    No intermediate pipelines, no segmentation, no masks.
    
    Request:
    {
        "user_image_url": "https://...",
        "garment_image_urls": ["https://...", "..."]
    }
    
    Returns:
    {
        "status": "success",
        "result_image_url": "https://..." or "data:image/jpeg;base64,..."
    }
    """
    trace_id = str(uuid.uuid4())
    
    try:
        # Validate URLs (basic validation only)
        if not request.user_image_url or not request.user_image_url.startswith(("http://", "https://", "data:image")):
            raise HTTPException(status_code=400, detail="Invalid user_image_url")
        
        if not request.garment_image_urls or len(request.garment_image_urls) == 0:
            raise HTTPException(status_code=400, detail="At least one garment_image_url required")
        
        for url in request.garment_image_urls:
            if not url.startswith(("http://", "https://", "data:image")):
                raise HTTPException(status_code=400, detail=f"Invalid garment_image_url: {url}")
        
        logger.info(f"[{trace_id}] Processing try-on request: {len(request.garment_image_urls)} garment(s)")
        
        # Download and prepare images for direct Gemini API
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                # Download user image
                logger.info(f"[{trace_id}] Downloading user image from: {request.user_image_url}")
                user_response = await client.get(request.user_image_url)
                user_response.raise_for_status()
                user_image_bytes = user_response.content
                user_image = cv2.imdecode(np.frombuffer(user_image_bytes, np.uint8), cv2.IMREAD_COLOR)
                if user_image is None:
                    raise ValueError(f"Failed to decode user image from {request.user_image_url}. Invalid image format.")
                logger.info(f"[{trace_id}] User image downloaded: {user_image.shape}")
                
                # Download first garment image (for simplicity, use first garment)
                garment_url = request.garment_image_urls[0]
                logger.info(f"[{trace_id}] Downloading garment image from: {garment_url}")
                garment_response = await client.get(garment_url)
                garment_response.raise_for_status()
                garment_image_bytes = garment_response.content
                garment_image = cv2.imdecode(np.frombuffer(garment_image_bytes, np.uint8), cv2.IMREAD_COLOR)
                if garment_image is None:
                    raise ValueError(f"Failed to decode garment image from {garment_url}. Invalid image format.")
                logger.info(f"[{trace_id}] Garment image downloaded: {garment_image.shape}")
        except httpx.HTTPStatusError as e:
            error_msg = f"Failed to download image: HTTP {e.response.status_code} from {e.request.url}"
            logger.error(f"[{trace_id}] {error_msg}")
            raise HTTPException(status_code=400, detail=error_msg)
        except httpx.RequestError as e:
            error_msg = f"Network error downloading image: {str(e)}"
            logger.error(f"[{trace_id}] {error_msg}")
            raise HTTPException(status_code=400, detail=error_msg)
        except ValueError as e:
            logger.error(f"[{trace_id}] Image decode error: {e}")
            raise HTTPException(status_code=400, detail=str(e))
        
        # Create try-on prompt
        try_on_prompt = """Redraw the person in the second image wearing the clothing from the first image.
Preserve the exact same face, hairstyle, facial features, skin tone, body shape, pose, camera angle, lighting, and background.
Only replace the clothing.

Do NOT modify the face, head, hands, body proportions, or posture.
Fit the clothing naturally to the body according to real human anatomy.
Maintain realistic fabric drape, shadows, and lighting.
This is a photorealistic virtual try-on, not an illustration or art."""
        
        # Generate try-on image using direct Gemini API (Nano Banana)
        direct_api_error = None
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
            
        except Exception as e:
            direct_api_error = str(e)
            logger.warning(f"[{trace_id}] Direct Gemini API failed: {direct_api_error}")
            
            # Check if it's a configuration error (don't try fallback)
            if "GEMINI_API_KEY not configured" in direct_api_error or "not configured" in direct_api_error.lower():
                raise Exception(f"Gemini API configuration error: {direct_api_error}")
            
            # Check if it's a model/endpoint error (don't try fallback)
            if "404" in direct_api_error or ("not found" in direct_api_error.lower() and "model" in direct_api_error.lower()):
                raise Exception(f"Gemini API endpoint or model issue: {direct_api_error}")
            
            # For other errors, try OpenRouter fallback
            logger.info(f"[{trace_id}] Trying OpenRouter fallback...")
            try:
                result_image_data_url = await generate_tryon_via_openrouter(
                    user_image_url=request.user_image_url,
                    garment_image_urls=request.garment_image_urls,
                    trace_id=trace_id
                )
            except Exception as openrouter_error:
                # Both direct API and OpenRouter failed
                error_msg = f"Image generation failed. Direct API error: {direct_api_error[:200]}. Fallback also failed: {str(openrouter_error)[:200]}"
                logger.error(f"[{trace_id}] {error_msg}")
                raise Exception(error_msg)
        
        # Optionally upload to storage if available
        result_image_url = result_image_data_url
        if storage_service and result_image_data_url.startswith("data:image"):
            try:
                # Extract base64 and upload
                image_b64 = result_image_data_url.split(",")[1]
                image_bytes = base64.b64decode(image_b64)
                
                # Convert to numpy array for storage service
                from PIL import Image  # type: ignore
                import io
                
                img = Image.open(io.BytesIO(image_bytes))
                img_array = np.array(img)
                if len(img_array.shape) == 3 and img_array.shape[2] == 3:
                    # Convert RGB to BGR for OpenCV (cv2 already imported at top)
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
                # Continue with base64 URL
        
        return TryOnResponse(
            status="success",
            result_image_url=result_image_url
        )
        
    except HTTPException:
        raise
    except ValueError as e:
        logger.error(f"[{trace_id}] Validation error: {e}", exc_info=True)
        return TryOnResponse(
            status="failed",
            message=f"Validation error: {str(e)}"
        )
    except Exception as e:
        error_msg = str(e)
        logger.error(f"[{trace_id}] Try-on failed: {error_msg}", exc_info=True)
        
        # Provide more specific error messages
        if "GEMINI_API_KEY not configured" in error_msg or "not configured" in error_msg.lower():
            return TryOnResponse(
                status="failed",
                message="Gemini API key not configured. Please set GEMINI_API_KEY environment variable."
            )
        elif "404" in error_msg and ("model" in error_msg.lower() or "endpoint" in error_msg.lower()):
            # Only show "not found" if it's actually a 404 for model/endpoint
            if "gemini" in error_msg.lower():
                return TryOnResponse(
                    status="failed",
                    message=f"Gemini API endpoint or model not found. Please verify GEMINI_MODEL setting and API endpoint. Technical details: {error_msg[:200]}"
                )
            else:
                return TryOnResponse(
                    status="failed",
                    message=f"API endpoint or model not found. Please check your API configuration. Technical details: {error_msg[:200]}"
                )
        elif "429" in error_msg or "too many requests" in error_msg.lower() or "rate limit" in error_msg.lower():
            return TryOnResponse(
                status="failed",
                message="API rate limit exceeded. Please wait a moment and try again. The service is temporarily busy."
            )
        elif "401" in error_msg or "unauthorized" in error_msg.lower() or "permission" in error_msg.lower():
            return TryOnResponse(
                status="failed",
                message="Authentication failed. Please check API key configuration."
            )
        elif "timeout" in error_msg.lower():
            return TryOnResponse(
                status="failed",
                message="Request timed out. Please try again."
            )
        elif "getaddrinfo failed" in error_msg.lower() or "dns" in error_msg.lower() or "network" in error_msg.lower():
            return TryOnResponse(
                status="failed",
                message="Network connection error. Cannot reach Gemini API. Please check your internet connection and firewall settings."
            )
        else:
            # Return the actual error message (truncated for safety)
            # Clean up common error patterns to avoid confusion
            clean_error = error_msg
            if "not found" in clean_error.lower() and "404" not in clean_error:
                # If it says "not found" but isn't a 404, it's probably a different error
                clean_error = clean_error.replace("not found", "unavailable").replace("Not found", "Unavailable")
            
            return TryOnResponse(
                status="failed",
                message=f"Try-on generation failed: {clean_error[:300]}"
            )
