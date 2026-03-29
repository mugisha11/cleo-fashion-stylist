"""
Inspiration API Endpoints
Generate personalized outfit inspiration images
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import logging
import base64
from io import BytesIO

from ..stages.generation import Stage5ImageGeneration
from ..core.config import settings
from ..core.lifespan_manager import get_resource_manager

router = APIRouter(prefix="/inspiration", tags=["inspiration"])

logger = logging.getLogger(__name__)


class InspirationRequest(BaseModel):
    prompt: str
    user_preferences: Optional[Dict[str, Any]] = None
    style: Optional[str] = "casual"
    gender: Optional[str] = "unisex"


class InspirationResponse(BaseModel):
    image_base64: str
    prompt_used: str
    style: str


@router.post("/generate-outfit", response_model=InspirationResponse)
async def generate_outfit_inspiration(request: InspirationRequest):
    """
    Generate a personalized outfit inspiration image based on user preferences
    """
    try:
        # Get the httpx client from resource manager
        resource_manager = get_resource_manager()
        httpx_client = resource_manager.get_httpx_client()

        # Initialize image generation service
        stage5 = Stage5ImageGeneration(
            use_pro_model=False,
            httpx_client=httpx_client
        )

        # Enhance prompt based on user preferences
        enhanced_prompt = _enhance_prompt_with_preferences(
            request.prompt,
            request.user_preferences,
            request.style,
            request.gender
        )

        logger.info(f"Generating inspiration image with prompt: {enhanced_prompt}")

        # Generate image using Gemini
        generated_image = await stage5.generate_image_from_prompt(enhanced_prompt)

        if generated_image is None:
            raise HTTPException(status_code=500, detail="Failed to generate image")

        # Convert to base64
        image_base64 = _image_to_base64(generated_image)

        return InspirationResponse(
            image_base64=image_base64,
            prompt_used=enhanced_prompt,
            style=request.style or "casual"
        )

    except Exception as e:
        logger.error(f"Failed to generate inspiration image: {e}")
        raise HTTPException(status_code=500, detail=f"Image generation failed: {str(e)}")


@router.post("/generate-multiple-outfits")
async def generate_multiple_outfits(requests: List[InspirationRequest]):
    """
    Generate multiple outfit inspiration images
    """
    results = []
    for req in requests:
        try:
            result = await generate_outfit_inspiration(req)
            results.append(result)
        except Exception as e:
            logger.warning(f"Failed to generate one outfit: {e}")
            # Add a fallback response
            results.append(InspirationResponse(
                image_base64="",  # Empty for failed generation
                prompt_used=req.prompt,
                style=req.style or "casual"
            ))

    return {"outfits": results}


def _enhance_prompt_with_preferences(
    base_prompt: str,
    user_preferences: Optional[Dict[str, Any]],
    style: str,
    gender: str
) -> str:
    """Enhance the prompt with user preferences for better personalization"""

    enhanced_parts = [base_prompt]

    if user_preferences:
        # Add gender-specific details
        if gender and gender != "unisex":
            enhanced_parts.append(f"Designed for {gender}")

        # Add style preferences
        preferred_styles = user_preferences.get('style_preferences', [])
        if preferred_styles:
            enhanced_parts.append(f"In {', '.join(preferred_styles)} style")

        # Add color preferences
        preferred_colors = user_preferences.get('preferred_colors', [])
        if preferred_colors:
            enhanced_parts.append(f"Using colors: {', '.join(preferred_colors)}")

        # Add body type considerations
        body_type = user_preferences.get('body_type')
        if body_type:
            enhanced_parts.append(f"Flattering for {body_type} body type")

    # Add quality and realism requirements
    enhanced_parts.extend([
        "Photorealistic fashion photography",
        "Professional lighting and composition",
        "High fashion magazine quality",
        "Detailed textures and fabrics",
        "Realistic shadows and highlights"
    ])

    return ". ".join(enhanced_parts)


def _image_to_base64(image_array) -> str:
    """Convert numpy array image to base64 string"""
    try:
        # Convert BGR to RGB if needed
        if len(image_array.shape) == 3 and image_array.shape[2] == 3:
            # Assume BGR format from OpenCV
            image_rgb = image_array[:, :, ::-1]  # BGR to RGB
        else:
            image_rgb = image_array

        # Convert to PIL Image
        from PIL import Image
        pil_image = Image.fromarray(image_rgb.astype('uint8'))

        # Save to BytesIO
        buffer = BytesIO()
        pil_image.save(buffer, format='PNG')
        buffer.seek(0)

        # Encode to base64
        image_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
        return f"data:image/png;base64,{image_base64}"

    except Exception as e:
        logger.error(f"Failed to convert image to base64: {e}")
        return ""