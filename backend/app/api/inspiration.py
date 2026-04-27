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


class PersonalizedInspirationRequest(BaseModel):
    user_id: str
    gender: Optional[str] = None
    style_preferences: Optional[List[str]] = None
    color_preferences: Optional[List[str]] = None
    budget: Optional[str] = None
    wardrobe_count: int = 0
    occasion_preferences: Optional[List[str]] = None


class InspirationOutfit(BaseModel):
    id: str
    title: str
    description: str
    image_url: str
    key_pieces: List[str]
    occasion: str
    style: str


class PersonalizedInspirationResponse(BaseModel):
    outfits: List[InspirationOutfit]
    total_count: int
    message: Optional[str] = None


@router.post("/personalized", response_model=PersonalizedInspirationResponse)
async def get_personalized_inspiration(request: PersonalizedInspirationRequest):
    """
    Generate personalized outfit inspiration based on user preferences and wardrobe.
    Uses AI to create tailored suggestions that fill wardrobe gaps and match user style.
    """
    try:
        outfits = []
        
        # Detect wardrobe gaps based on what user already owns
        gaps = _detect_wardrobe_gaps(request.wardrobe_count)
        
        # Create tailored prompts for each gap
        for idx, gap in enumerate(gaps[:2]):  # Limit to 2 personalized outfits per request
            prompt = _build_personalized_prompt(
                gap_type=gap,
                gender=request.gender,
                styles=request.style_preferences,
                colors=request.color_preferences,
                budget=request.budget,
                occasion=request.occasion_preferences[0] if request.occasion_preferences else None
            )
            
            # Generate outfit request
            outfit_request = InspirationRequest(
                prompt=prompt,
                user_preferences={
                    'style_preferences': request.style_preferences or [],
                    'preferred_colors': request.color_preferences or [],
                    'body_type': 'average',
                    'budget': request.budget,
                },
                style=request.style_preferences[0] if request.style_preferences else 'casual',
                gender=request.gender or 'unisex'
            )
            
            try:
                # Generate the outfit image and get response
                response = await generate_outfit_inspiration(outfit_request)
                
                outfit = InspirationOutfit(
                    id=f"outfit_{idx}_{request.user_id}",
                    title=_generate_outfit_title(gap, request.style_preferences),
                    description=f"Complete {gap} outfit tailored to your style preferences",
                    image_url=response.image_base64,
                    key_pieces=_extract_key_pieces(gap),
                    occasion=request.occasion_preferences[0] if request.occasion_preferences else 'casual',
                    style=response.style
                )
                outfits.append(outfit)
                
            except Exception as e:
                logger.warning(f"Failed to generate personalized outfit for gap {gap}: {e}")
                # Fallback: create placeholder outfit
                continue
        
        # If we couldn't generate any, provide curated suggestions
        if not outfits:
            outfits = _get_curated_fallback_outfits(
                request.gender,
                request.style_preferences,
                request.color_preferences
            )
        
        return PersonalizedInspirationResponse(
            outfits=outfits,
            total_count=len(outfits),
            message="Curated outfit inspiration based on your profile and style preferences"
        )
        
    except Exception as e:
        logger.error(f"Failed to generate personalized inspiration: {e}")
        # Return fallback generic outfits
        return PersonalizedInspirationResponse(
            outfits=_get_curated_fallback_outfits(
                request.gender,
                request.style_preferences,
                request.color_preferences
            ),
            total_count=0,
            message="Showing featured outfit inspiration"
        )


def _detect_wardrobe_gaps(wardrobe_count: int) -> List[str]:
    """Detect likely wardrobe gaps based on existing wardrobe size"""
    gaps = []
    
    if wardrobe_count < 10:
        gaps.extend(['casual basics', 'layering pieces', 'formal wear'])
    elif wardrobe_count < 20:
        gaps.extend(['statement pieces', 'accessories', 'seasonal wear'])
    else:
        gaps.extend(['trending styles', 'elevated basics', 'occasion wear'])
    
    return gaps


def _build_personalized_prompt(
    gap_type: str,
    gender: Optional[str],
    styles: Optional[List[str]],
    colors: Optional[List[str]],
    budget: Optional[str],
    occasion: Optional[str]
) -> str:
    """Build a detailed prompt for personalized outfit generation"""
    
    style_hint = ', '.join(styles) if styles else 'contemporary'
    color_hint = ', '.join(colors) if colors else 'neutral with pops of color'
    budget_hint = budget.lower() if budget else 'mid-range'
    gender_hint = f"for {gender}" if gender and gender != 'unisex' else 'unisex'
    occasion_hint = f"suitable for {occasion}" if occasion else 'everyday wear'
    
    return (
        f"Create a professional fashion outfit {gender_hint} featuring {gap_type}. "
        f"Style: {style_hint}. Colors: {color_hint}. "
        f"Budget level: {budget_hint}. Occasion: {occasion_hint}. "
        f"Professional fashion photography with perfect lighting and styling."
    )


def _generate_outfit_title(gap_type: str, style_preferences: Optional[List[str]]) -> str:
    """Generate a descriptive title for the outfit"""
    
    style = style_preferences[0].title() if style_preferences else 'Modern'
    
    title_map = {
        'casual basics': f'{style} Everyday Essentials',
        'layering pieces': f'{style} Layering Made Easy',
        'formal wear': f'{style} Elevated Elegance',
        'statement pieces': f'{style} Bold & Confident',
        'accessories': f'{style} Accessory Inspiration',
        'seasonal wear': f'{style} Season-Perfect Style',
        'trending styles': f'{style} On-Trend Now',
        'elevated basics': f'{style} Refined Foundations',
        'occasion wear': f'{style} Occasion Ready',
    }
    
    return title_map.get(gap_type, f'{style} Outfit Inspiration')


def _extract_key_pieces(gap_type: str) -> List[str]:
    """Extract key pieces for a given gap type"""
    
    pieces_map = {
        'casual basics': ['white tee', 'fitted jeans', 'sneakers', 'light jacket'],
        'layering pieces': ['blazer', 'cardigan', 'denim jacket', 'oversized shirt'],
        'formal wear': ['tailored trousers', 'blazer', 'dress shoes', 'elegant blouse'],
        'statement pieces': ['patterned blouse', 'bold jacket', 'statement bag'],
        'accessories': ['structured handbag', 'elegant jewelry', 'quality scarf'],
        'seasonal wear': ['lightweight fabrics', 'seasonal colors', 'weather-appropriate'],
        'trending styles': ['current silhouettes', 'on-trend colors', 'fashion-forward pieces'],
        'elevated basics': ['premium white shirt', 'tailored trousers', 'quality basics'],
        'occasion wear': ['sophisticated dress', 'polished shoes', 'elegant accessories'],
    }
    
    return pieces_map.get(gap_type, ['outfit pieces'])


def _get_curated_fallback_outfits(
    gender: Optional[str],
    styles: Optional[List[str]],
    colors: Optional[List[str]]
) -> List[InspirationOutfit]:
    """Return curated fallback outfits when generation fails"""
    
    style_name = styles[0] if styles else 'Modern'
    
    return [
        InspirationOutfit(
            id="fallback_1",
            title=f"{style_name} Casual Elegance",
            description="A timeless casual outfit perfect for everyday styling",
            image_url="",  # No image for fallback
            key_pieces=['white shirt', 'tailored blazer', 'dark jeans', 'white sneakers'],
            occasion="casual",
            style=style_name.lower()
        ),
        InspirationOutfit(
            id="fallback_2",
            title=f"{style_name} Smart Casual",
            description="Elevated basics that work for any occasion",
            image_url="",
            key_pieces=['neutral blouse', 'tailored trousers', 'classic loafers', 'structured bag'],
            occasion="business casual",
            style=style_name.lower()
        ),
    ]