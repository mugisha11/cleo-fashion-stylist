"""
Pydantic Schemas for API Requests/Responses
"""
from pydantic import BaseModel, HttpUrl, Field
from typing import Optional, List, Dict, Any, Tuple
from enum import Enum


class BaseResponse(BaseModel):
    """Base response model with common fields"""
    success: bool = Field(..., description="Whether the operation was successful")
    message: Optional[str] = Field(None, description="Optional message")


class TryOnSource(str, Enum):
    wardrobe = "wardrobe"
    web = "web"


class TryOnSource(str, Enum):
    wardrobe = "wardrobe"
    web = "web"
    url = "url"
    base64 = "base64"


class VirtualTryOnRequest(BaseModel):
    """Request for virtual try-on with OpenRouter-based reasoning"""
    # User image (one of these required)
    user_image_url: Optional[HttpUrl] = Field(None, description="URL of user photo")
    user_image_base64: Optional[str] = Field(None, description="Base64 encoded user photo")
    
    # Garment image(s) (one of these required)
    garment_image_url: Optional[HttpUrl] = Field(None, description="URL of clothing image")
    garment_image_base64: Optional[str] = Field(None, description="Base64 encoded clothing image")
    garment_images: Optional[List[HttpUrl]] = Field(None, description="Multiple garment images (URLs)")
    
    # Optional parameters
    user_id: Optional[str] = Field(None, description="User ID for storage")
    source: TryOnSource = Field(default=TryOnSource.web, description="Source of clothing")
    use_diffusion: bool = Field(False, description="Use diffusion-based refinement (slower but higher quality)")


class VirtualTryOnResponse(BaseModel):
    """Response from virtual try-on API"""
    status: str = Field(..., description="success or failed")
    output_image_url: Optional[str] = Field(None, description="URL of try-on result image")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadata with garment positions and quality scores")
    error: Optional[str] = Field(None, description="Error message if status is failed")
    stage: Optional[str] = Field(None, description="Stage where failure occurred (if failed)")


# Legacy schemas for backward compatibility (deprecated)
class TryOnRequest(BaseModel):
    user_image_url: HttpUrl = Field(..., description="URL of user photo")
    cloth_image_url: HttpUrl = Field(..., description="URL of clothing image")
    source: TryOnSource = Field(default=TryOnSource.web, description="Source of clothing")
    user_id: Optional[str] = Field(None, description="User ID for storage")
    preserve_face: bool = Field(True, description="Preserve face region (mandatory)")
    preserve_resolution: bool = Field(True, description="Maintain original image resolution")
    use_diffusion: bool = Field(False, description="Use diffusion-based generation (slower but higher quality)")
    user_query: Optional[str] = Field(None, description="Optional user question for AI reasoning")
    wardrobe_context: Optional[Dict[str, Any]] = Field(None, description="Optional wardrobe context for AI recommendations")


class TryOnResponse(BaseModel):
    success: bool
    result_url: Optional[str] = Field(None, description="URL of try-on result")
    session_id: Optional[str] = Field(None, description="Session ID for tracking")
    face_similarity: Optional[float] = Field(None, description="Face preservation score (0-1)")
    quality_scores: Optional[Dict[str, Any]] = Field(None, description="Quality check scores (may include model_used string)")
    error: Optional[str] = Field(None, description="Error message if failed")


class RecommendRequest(BaseModel):
    prompt: str = Field(..., description="Fashion prompt (e.g., 'wedding outfit')")
    wardrobe_only: bool = Field(False, description="Use only user's wardrobe")
    user_id: Optional[str] = Field(None, description="User ID for personalization")
    occasion: Optional[str] = Field(None, description="Specific occasion")
    style_keywords: Optional[List[str]] = Field(None, description="Style preferences")


class OutfitRecommendation(BaseModel):
    id: str
    image_url: str
    title: str
    description: Optional[str] = None
    tags: List[str] = []
    confidence: Optional[float] = None
    from_wardrobe: bool = False
    metadata: Dict[str, Any] = {}


class RecommendResponse(BaseModel):
    outfits: List[OutfitRecommendation]
    message: Optional[str] = None


class HealthResponse(BaseModel):
    status: str
    version: str
    gpu_available: bool


class ClothingRecognitionRequest(BaseModel):
    """Request for clothing recognition from URL"""
    image_url: HttpUrl = Field(..., description="URL of clothing image")
    user_id: Optional[str] = Field(None, description="User ID for storing results")
    store_result: bool = Field(True, description="Whether to store result in Supabase")


class ClothingRecognitionResponse(BaseModel):
    """Response from clothing recognition"""
    success: bool
    category: str = Field(..., description="Main clothing category")
    subcategory: Optional[str] = Field(None, description="Subcategory if available")
    colors: List[str] = Field(..., description="Detected colors")
    patterns: List[str] = Field(..., description="Detected patterns")
    fit: Optional[str] = Field(None, description="Estimated fit (loose/regular/tight/fitted)")
    occasion: List[str] = Field(..., description="Suitable occasions")
    style: Optional[str] = Field(None, description="Style classification")
    confidence: float = Field(..., description="Overall confidence score (0-1)")
    bbox: Optional[Tuple[int, int, int, int]] = Field(None, description="Bounding box (x, y, w, h)")
    image_url: Optional[str] = Field(None, description="URL of stored image")
    result_id: Optional[str] = Field(None, description="ID of stored result in Supabase")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata")

