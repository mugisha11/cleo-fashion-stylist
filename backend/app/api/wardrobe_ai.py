"""
Wardrobe AI API
Generates professional descriptions and outfit recommendations for wardrobe items
"""
import logging
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from pydantic import BaseModel

from ..services.openai_service import OpenAIService
from ..services.openrouter_service import OpenRouterService
from ..core.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/wardrobe-ai", tags=["wardrobe-ai"])

# Initialize AI services
openai_service = None
openrouter_service = None

try:
    if settings.OPENAI_API_KEY:
        openai_service = OpenAIService()
except Exception as e:
    logger.warning(f"Failed to initialize OpenAI service: {e}")

try:
    if settings.OPENROUTER_API_KEY:
        openrouter_service = OpenRouterService()
except Exception as e:
    logger.warning(f"Failed to initialize OpenRouter service: {e}")


class ItemInfo(BaseModel):
    """Wardrobe item information for AI processing"""
    category: str
    subcategory: Optional[str] = None
    brand: Optional[str] = None
    fit: Optional[str] = None
    fabric: Optional[str] = None
    pattern: Optional[str] = None
    colors: List[str] = []
    occasion: List[str] = []
    season: List[str] = []


class DescriptionRequest(BaseModel):
    """Request for professional item description"""
    item: ItemInfo


class DescriptionResponse(BaseModel):
    """Professional description response"""
    description: str
    model: str


class RecommendationItem(BaseModel):
    """Recommended outfit combination"""
    title: str
    description: str
    reason: str
    source: str = "wardrobe"  # 'wardrobe' or 'online'
    price: Optional[float] = None  # For online items
    source_link: Optional[str] = None  # URL for online items
    source_store: Optional[str] = None  # Store name


class RecommendationsRequest(BaseModel):
    """Request for outfit recommendations"""
    main_item: ItemInfo
    wardrobe_items: Optional[List[ItemInfo]] = None
    online_items: Optional[List[dict]] = None  # External shopping items
    limit: int = 3
    include_online: bool = False  # Whether to include online shopping options


class RecommendationsResponse(BaseModel):
    """Outfit recommendations response"""
    recommendations: List[RecommendationItem]
    model: str


@router.post("/description", response_model=DescriptionResponse)
async def generate_item_description(request: DescriptionRequest):
    """
    Generate professional, user-friendly description for a wardrobe item
    
    Uses AI (Gemini Nano via OpenRouter, or OpenAI) to create:
    - Professional description of the piece and its style
    - Highlights its versatility
    - How it can be styled or worn
    - Why it appeals to the user
    """
    try:
        item = request.item
        
        # Build comprehensive prompt
        prompt = f"""You are a professional fashion stylist. Provide a concise, user-friendly, and professional description of this clothing item.

Item Details:
- Category: {item.category}
{f'- Type: {item.subcategory}' if item.subcategory else ''}
{f'- Brand: {item.brand}' if item.brand else ''}
{f'- Fit: {item.fit}' if item.fit else ''}
{f'- Fabric: {item.fabric}' if item.fabric else ''}
{f'- Pattern: {item.pattern}' if item.pattern else ''}
{f'- Colors: {", ".join(item.colors)}' if item.colors else ''}
{f'- Best For: {", ".join(item.occasion)}' if item.occasion else ''}
{f'- Seasons: {", ".join(item.season)}' if item.season else ''}

Write a professional, friendly description (2-3 sentences) that:
1. Describes the piece and its style
2. Highlights its versatility
3. Explains how it can be styled or worn
4. Makes it appealing to the user

Keep it concise, practical, and user-focused. Avoid technical jargon."""

        # Try OpenRouter first (Gemini Nano)
        description = None
        model_used = None
        
        if openrouter_service:
            try:
                logger.info("Attempting to generate description with OpenRouter (Gemini Nano)...")
                response = await openrouter_service.create_chat_completion(
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.7,
                    max_tokens=200,
                    model="google/gemini-nano-2b-vision-free",  # Free tier model
                )
                
                if response and response.get("choices"):
                    description = response["choices"][0].get("message", {}).get("content", "").strip()
                    model_used = "gemini-nano"
                    logger.info(f"✅ Generated description with {model_used}")
            except Exception as e:
                logger.warning(f"OpenRouter failed: {e}, trying OpenAI...")
        
        # Fallback to OpenAI
        if not description and openai_service:
            try:
                logger.info("Attempting to generate description with OpenAI...")
                response = await openai_service.create_chat_completion(
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.7,
                    max_tokens=200,
                )
                
                if response and response.get("choices"):
                    description = response["choices"][0].get("message", {}).get("content", "").strip()
                    model_used = "gpt-4-mini"
                    logger.info(f"✅ Generated description with {model_used}")
            except Exception as e:
                logger.warning(f"OpenAI failed: {e}")
        
        if not description:
            # Create fallback description
            parts = [
                f"A stylish {item.category.lower()}"
            ]
            if item.subcategory:
                parts[0] = f"A {item.subcategory.lower()}"
            if item.fit:
                parts.append(f"with {item.fit.lower()} fit")
            if item.pattern:
                parts.append(f"featuring a {item.pattern.lower()} pattern")
            
            description = " ".join(parts) + "."
            if item.occasion:
                description += f" Perfect for {', '.join(item.occasion).lower()}."
            
            model_used = "fallback"
            logger.info("Using fallback description")
        
        return DescriptionResponse(
            description=description,
            model=model_used or "unknown"
        )
        
    except Exception as e:
        logger.error(f"Error generating description: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate description: {str(e)}"
        )


@router.post("/recommendations", response_model=RecommendationsResponse)
async def generate_outfit_recommendations(request: RecommendationsRequest):
    """
    Generate outfit recommendations that match the selected item
    
    Returns 3 outfit combinations with:
    - Title/Name of the outfit
    - Description of the vibe/style
    - Why it works with the main item
    - Can include recommendations from wardrobe or online shopping
    """
    try:
        main_item = request.main_item
        limit = min(request.limit, 5)  # Max 5 recommendations
        
        # Format wardrobe items for context
        wardrobe_context = ""
        if request.wardrobe_items:
            wardrobe_items = request.wardrobe_items[:20]  # Limit to 20 items
            items_list = []
            for i, item in enumerate(wardrobe_items, 1):
                items_list.append(
                    f"{i}. {item.subcategory or item.category} - "
                    f"{', '.join(item.colors) if item.colors else 'Unknown color'} "
                    f"{f'({item.pattern})' if item.pattern else ''}"
                )
            wardrobe_context = "Available Wardrobe Pieces:\n" + "\n".join(items_list)
        
        # Format online items for context if available
        online_context = ""
        if request.include_online and request.online_items:
            online_items = request.online_items[:10]  # Limit to 10 items
            items_list = []
            for i, item in enumerate(online_items, 1):
                store = item.get('store', 'Online')
                price = item.get('price', 'Check price')
                name = item.get('name', 'Item')
                items_list.append(f"{i}. {name} from {store} (${price})")
            online_context = "Available Online Shopping Options:\n" + "\n".join(items_list)
        
        prompt = f"""You are a professional fashion stylist. Suggest how this wardrobe item can be combined with other pieces to create complete, cohesive outfits.

Main Item:
- Category: {main_item.category}
- Type: {main_item.subcategory or 'General'}
- Colors: {', '.join(main_item.colors) if main_item.colors else 'Various'}
- Pattern: {main_item.pattern or 'Solid'}
- Best For: {', '.join(main_item.occasion) if main_item.occasion else 'Versatile'}

{wardrobe_context}

{online_context}

Suggest {limit} specific outfit combinations that:
1. Include the main item
2. Are cohesive and stylish
3. Work for different occasions or moods
4. Can include items from wardrobe OR online shopping (mark source as 'wardrobe' or 'online')

For each outfit, provide:
- Name/Title (e.g., "Casual Weekend Look")
- Description (1 sentence about the vibe)
- Why it works (1 sentence explaining the combination)
- Source: wardrobe or online

Format each outfit as:
**Title:** [Name]
**Description:** [Vibe]
**Why it works:** [Reason]
**Source:** wardrobe or online

Separate each outfit with a blank line."""

        # Try OpenRouter first
        recommendations = []
        model_used = None
        
        if openrouter_service:
            try:
                logger.info("Attempting to generate recommendations with OpenRouter...")
                response = await openrouter_service.create_chat_completion(
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.8,
                    max_tokens=600,
                    model="google/gemini-nano-2b-vision-free",  # Free tier model
                )
                
                if response and response.get("choices"):
                    raw_text = response["choices"][0].get("message", {}).get("content", "").strip()
                    recommendations = _parse_recommendations(raw_text)
                    model_used = "gemini-nano"
                    logger.info(f"✅ Generated {len(recommendations)} recommendations with {model_used}")
            except Exception as e:
                logger.warning(f"OpenRouter failed: {e}, trying OpenAI...")
        
        # Fallback to OpenAI
        if not recommendations and openai_service:
            try:
                logger.info("Attempting to generate recommendations with OpenAI...")
                response = await openai_service.create_chat_completion(
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.8,
                    max_tokens=600,
                )
                
                if response and response.get("choices"):
                    raw_text = response["choices"][0].get("message", {}).get("content", "").strip()
                    recommendations = _parse_recommendations(raw_text)
                    model_used = "gpt-4-mini"
                    logger.info(f"✅ Generated {len(recommendations)} recommendations with {model_used}")
            except Exception as e:
                logger.warning(f"OpenAI failed: {e}")
        
        # Fallback recommendations
        if not recommendations:
            recommendations = [
                RecommendationItem(
                    title="Casual Everyday Look",
                    description="Perfect for running errands or casual hangouts",
                    reason="Comfortable and versatile with everyday basics",
                    source="wardrobe"
                ),
                RecommendationItem(
                    title="Professional Work Outfit",
                    description="Ideal for office settings or formal occasions",
                    reason="Polished and appropriate for professional environments",
                    source="wardrobe"
                ),
                RecommendationItem(
                    title="Elevate with New Pieces",
                    description="Complete the look with complementary items",
                    reason="Perfect additions to enhance your existing wardrobe",
                    source="online",
                    source_store="Top Retailers"
                ),
            ]
            model_used = "fallback"
            logger.info("Using fallback recommendations")
        
        # Limit to requested amount
        recommendations = recommendations[:limit]
        
        return RecommendationsResponse(
            recommendations=recommendations,
            model=model_used or "unknown"
        )
        
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate recommendations: {str(e)}"
        )


def _parse_recommendations(text: str) -> List[RecommendationItem]:
    """Parse AI-generated outfit recommendations from text"""
    try:
        recommendations = []
        
        # Split by outfit sections (look for ** markers)
        sections = text.split("**Title:**")[1:]  # Skip first empty part
        
        for section in sections:
            lines = section.strip().split("\n")
            
            title = ""
            description = ""
            reason = ""
            source = "wardrobe"  # Default to wardrobe
            
            for line in lines:
                line = line.strip()
                if line.startswith("**Description:**"):
                    description = line.replace("**Description:**", "").strip()
                elif line.startswith("**Why it works:**"):
                    reason = line.replace("**Why it works:**", "").strip()
                elif line.startswith("**Source:**"):
                    source_text = line.replace("**Source:**", "").strip().lower()
                    if 'online' in source_text:
                        source = "online"
                    else:
                        source = "wardrobe"
                elif not title and line:
                    title = line.strip()
            
            if title and description and reason:
                recommendations.append(
                    RecommendationItem(
                        title=title,
                        description=description,
                        reason=reason,
                        source=source
                    )
                )
        
        return recommendations if recommendations else []
    except Exception as e:
        logger.warning(f"Error parsing recommendations: {e}")
        return []
