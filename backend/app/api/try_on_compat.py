"""
Compatibility endpoint for Flutter app
Maps Flutter request format to backend pipeline
"""
import logging
import uuid
import time
import httpx  # type: ignore
import numpy as np  # type: ignore
import cv2  # type: ignore
from fastapi import APIRouter, HTTPException  # type: ignore
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field, validator  # type: ignore

from ..core.config import settings
from ..core.image_utils import normalize_image, validate_image
from ..core.utils import image_to_base64, base64_to_image
from ..services.enhanced_openrouter_service import EnhancedOpenRouterService
from ..services.remove_bg_service import RemoveBGService
from ..services.segmentation_service import SegmentationService
from ..services.body_parser import BodyParser
from ..services.storage import StorageService
from ..core.quality import QualityGates
from ..stages.generation import Stage5ImageGeneration

logger = logging.getLogger(__name__)

# Note: This endpoint is NOT used - Flutter calls /tryon which is handled by tryon.py
# Keeping this file for reference but router is not registered to avoid conflicts
router = APIRouter(prefix="/tryon-compat-unused", tags=["tryon-compat"])

# Initialize services (same as tryon_api.py)
openrouter_service = EnhancedOpenRouterService()
remove_bg_service = RemoveBGService()
segmentation_service = SegmentationService(method=settings.SEGMENTATION_METHOD)
body_parser = BodyParser()
quality_gates = QualityGates()
# Use direct Gemini API for better try-on results (Nano Banana)
stage5_generation = Stage5ImageGeneration(use_pro_model=settings.GEMINI_USE_PRO_MODEL)

# Initialize storage
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


class FlutterTryOnRequest(BaseModel):
    """Flutter app try-on request format - accepts both formats"""
    user_image_url: str = Field(..., description="URL of user photo")
    # Accept both formats for compatibility
    cloth_image_url: Optional[str] = Field(None, description="URL of clothing image (singular)")
    garment_image_urls: Optional[List[str]] = Field(None, description="List of clothing image URLs")
    preserve_face: bool = Field(True, description="Preserve face in result")
    preserve_resolution: bool = Field(True, description="Preserve original resolution")
    use_diffusion: bool = Field(False, description="Use diffusion model")
    source: Optional[str] = Field(None, description="Source of request")
    user_id: Optional[str] = Field(None, description="User ID for tracking")
    
    @validator('cloth_image_url', 'garment_image_urls', always=True)
    def validate_clothing_image(cls, v, values):
        """Ensure at least one clothing image is provided"""
        if not values.get('cloth_image_url') and not values.get('garment_image_urls'):
            raise ValueError('Either cloth_image_url or garment_image_urls must be provided')
        return v


class TryOnResponse(BaseModel):
    """Response from virtual try-on API - Flutter compatible format"""
    status: str = Field(..., description="success or failed")
    result_image_url: Optional[str] = Field(None, description="CDN URL of result image")
    result_image_base64: Optional[str] = Field(None, description="Base64 encoded result image")
    result_url: Optional[str] = Field(None, description="CDN URL of result image (Flutter compatible)")
    metrics: Optional[Dict[str, Any]] = Field(None, description="Quality metrics")
    quality_scores: Optional[Dict[str, Any]] = Field(None, description="Quality scores (Flutter compatible)")
    face_similarity: Optional[float] = Field(None, description="Face similarity score (Flutter compatible)")
    model_used: Optional[str] = Field(None, description="Model used for generation (Flutter compatible)")
    trace_id: str = Field(..., description="Trace ID for this request")
    stages: Optional[Dict[str, Any]] = Field(None, description="Stage execution info")
    error: Optional[str] = Field(None, description="Error message if failed")
    stage_failed: Optional[str] = Field(None, description="Stage where failure occurred")


@router.post("", response_model=TryOnResponse)
async def try_on_compat(request: FlutterTryOnRequest):
    """
    Compatibility endpoint for Flutter app
    
    Maps Flutter request format to backend pipeline format:
    - cloth_image_url (singular) -> garment_image_urls (list)
    - Other fields are passed through or ignored
    
    Uses the same pipeline as /api/tryon
    """
    trace_id = str(uuid.uuid4())
    start_time = time.time()
    stages_info = {}
    
    try:
        logger.info(f"[{trace_id}] Received try-on request from Flutter app: user_id={request.user_id}")
        
        # STAGE 1: Validate images and convert to base64/URL
        logger.info(f"[{trace_id}] STAGE 1: Validating images")
        stage1_start = time.time()
        
        # Download and validate user image
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(request.user_image_url)
            response.raise_for_status()
            user_image_bytes = response.content
        
        user_image = cv2.imdecode(np.frombuffer(user_image_bytes, np.uint8), cv2.IMREAD_COLOR)
        user_image = normalize_image(user_image, "User image")
        validate_image(user_image, "User image")
        
        # Get garment image URL(s) - handle both formats
        if request.garment_image_urls and len(request.garment_image_urls) > 0:
            garment_url = request.garment_image_urls[0]  # Use first garment
        elif request.cloth_image_url:
            garment_url = request.cloth_image_url
        else:
            raise HTTPException(status_code=400, detail="No clothing image provided")
        
        # Download garment image
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(garment_url)
            response.raise_for_status()
            garment_bytes = response.content
        
        garment_image = cv2.imdecode(np.frombuffer(garment_bytes, np.uint8), cv2.IMREAD_COLOR)
        garment_image = normalize_image(garment_image, "Garment image")
        validate_image(garment_image, "Garment image")
        
        stages_info["stage1"] = {"duration": time.time() - stage1_start, "status": "success"}
        
        # STAGE 2: Body & garment semantic analysis via OpenRouter
        logger.info(f"[{trace_id}] STAGE 2: Semantic analysis")
        stage2_start = time.time()
        
        try:
            garment_analysis = await openrouter_service.analyze_garment_with_reasoning(
                user_image=user_image,
                garment_image=garment_image,
                trace_id=trace_id
            )
            
            # Validate confidence
            if garment_analysis.get("confidence", 0) < 0.90:
                raise HTTPException(
                    status_code=400,
                    detail=f"Garment analysis confidence {garment_analysis.get('confidence')} below threshold 0.90"
                )
            
            stages_info["stage2"] = {
                "duration": time.time() - stage2_start,
                "status": "success",
                "garment_type": garment_analysis.get("garment_type"),
                "placement": garment_analysis.get("placement"),
                "confidence": garment_analysis.get("confidence")
            }
            
        except Exception as e:
            logger.error(f"[{trace_id}] Stage 2 failed: {e}", exc_info=True)
            return TryOnResponse(
                status="failed",
                trace_id=trace_id,
                error=str(e),
                stage_failed="semantic_analysis",
                result_url=None,
                quality_scores=None,
                face_similarity=None,
                model_used=None
            )
        
        # STAGE 3: Mask generation (segmentation + background removal)
        logger.info(f"[{trace_id}] STAGE 3: Mask generation")
        stage3_start = time.time()
        
        try:
            # Remove background from garment
            try:
                garment_no_bg, garment_mask = await remove_bg_service.remove_background(
                    image_bytes=cv2.imencode('.jpg', garment_image)[1].tobytes()
                )
            except Exception as e:
                logger.warning(f"[{trace_id}] Remove.bg failed, using segmentation: {e}")
                # Fallback to segmentation
                garment_no_bg, garment_mask = segmentation_service.segment_garment(garment_image)
            
            # Body parsing for allowed/forbidden regions
            body_parsing = await body_parser.parse_body(
                user_image=user_image,
                parsing_instructions=None,
                garment_classification={
                    "garment_type": garment_analysis.get("garment_type"),
                    "target_body_part": garment_analysis.get("allowed_regions", [])
                }
            )
            
            allowed_mask = body_parsing.get("allowed_mask")
            forbidden_mask = body_parsing.get("locked_mask")
            
            if allowed_mask is None or np.sum(allowed_mask) == 0:
                raise ValueError("Failed to extract valid body segments")
            
            stages_info["stage3"] = {
                "duration": time.time() - stage3_start,
                "status": "success",
                "garment_mask_coverage": float(np.sum(garment_mask > 0) / garment_mask.size),
                "allowed_mask_coverage": float(np.sum(allowed_mask > 0) / allowed_mask.size)
            }
            
        except Exception as e:
            logger.error(f"[{trace_id}] Stage 3 failed: {e}", exc_info=True)
            return TryOnResponse(
                status="failed",
                trace_id=trace_id,
                error=str(e),
                stage_failed="mask_generation",
                result_url=None,
                quality_scores=None,
                face_similarity=None,
                model_used=None
            )
        
        # STAGE 4: Prompt synthesis
        logger.info(f"[{trace_id}] STAGE 4: Prompt synthesis")
        stage4_start = time.time()
        
        try:
            generation_prompt = await openrouter_service.synthesize_prompt(
                user_image=user_image,
                garment_image=garment_image,
                garment_analysis=garment_analysis,
                trace_id=trace_id
            )
            
            stages_info["stage4"] = {
                "duration": time.time() - stage4_start,
                "status": "success",
                "prompt_length": len(generation_prompt)
            }
            
        except Exception as e:
            logger.error(f"[{trace_id}] Stage 4 failed: {e}", exc_info=True)
            return TryOnResponse(
                status="failed",
                trace_id=trace_id,
                error=str(e),
                stage_failed="prompt_synthesis",
                result_url=None,
                quality_scores=None,
                face_similarity=None,
                model_used=None
            )
        
        # STAGE 5: Image generation using Gemini Nano Banana (direct API)
        # Uses official Gemini image generation API for best results
        logger.info(f"[{trace_id}] STAGE 5: Image generation via Gemini Nano Banana")
        stage5_start = time.time()
        
        try:
            # Get garment type from analysis for better prompt
            garment_type = garment_analysis.get("garment_type", "garment")
            
            # Use direct Gemini API (Nano Banana) for professional try-on results
            # This follows the official Gemini API documentation exactly
            generated_image = await stage5_generation.execute(
                user_image=user_image,
                garment_image=garment_image,
                prompt=generation_prompt,
                garment_type=garment_type,
                aspect_ratio=None  # Auto-detect from user image
            )
            
            validate_image(generated_image, "Generated image")
            
            stages_info["stage5"] = {
                "duration": time.time() - stage5_start,
                "status": "success",
                "image_shape": generated_image.shape,
                "model": stage5_generation.model_name
            }
            
        except Exception as e:
            logger.error(f"[{trace_id}] Stage 5 (Gemini direct) failed: {e}, trying OpenRouter fallback", exc_info=True)
            
            # Fallback to OpenRouter if direct Gemini API fails
            try:
                logger.info(f"[{trace_id}] Attempting OpenRouter fallback for image generation")
                fallback_models = [
                    "google/gemini-2.0-flash-exp",
                    "google/gemini-1.5-pro",
                    "openai/dall-e-3"
                ]
                
                generated_image = await openrouter_service.generate_image_via_openrouter(
                    user_image=user_image,
                    garment_image=garment_image,
                    prompt=generation_prompt,
                    trace_id=trace_id,
                    fallback_models=fallback_models
                )
                
                validate_image(generated_image, "Generated image")
                
                stages_info["stage5"] = {
                    "duration": time.time() - stage5_start,
                    "status": "success (fallback)",
                    "image_shape": generated_image.shape,
                    "model": "OpenRouter fallback"
                }
                
            except Exception as fallback_error:
                logger.error(f"[{trace_id}] Both Gemini direct and OpenRouter fallback failed: {fallback_error}", exc_info=True)
                return TryOnResponse(
                    status="failed",
                    trace_id=trace_id,
                    error=f"Image generation failed: {str(e)}. Fallback also failed: {str(fallback_error)}",
                    stage_failed="image_generation",
                    result_url=None,
                    quality_scores=None,
                    face_similarity=None,
                    model_used=None
                )
        
        # STAGE 6: Quality scoring
        logger.info(f"[{trace_id}] STAGE 6: Quality scoring")
        stage6_start = time.time()
        
        try:
            # Quality checks
            is_valid, metrics = quality_gates.validate_all(
                original_image=user_image,
                generated_image=generated_image,
                garment_mask=allowed_mask,
                forbidden_mask=forbidden_mask,
                original_pose=None,  # Would need pose detection
                generated_pose=None
            )
            
            if not is_valid:
                logger.warning(f"[{trace_id}] Quality checks failed: {metrics}")
            
            stages_info["stage6"] = {
                "duration": time.time() - stage6_start,
                "status": "success" if is_valid else "warning",
                "metrics": metrics
            }
            
        except Exception as e:
            logger.warning(f"[{trace_id}] Quality scoring failed: {e}")
            metrics = {}
        
        # Upload result
        result_url = None
        result_base64 = None
        
        if storage_service:
            try:
                user_id = request.user_id or "anonymous"
                result_url = storage_service.upload_image(
                    image=generated_image,
                    user_id=user_id,
                    image_type="tryon_result",
                    quality=settings.OUTPUT_QUALITY
                )
            except Exception as e:
                logger.warning(f"[{trace_id}] Storage upload failed: {e}")
        
        # Also provide base64 for immediate use
        result_base64 = image_to_base64(generated_image)
        
        total_duration = time.time() - start_time
        
        # Extract face similarity from metrics for Flutter compatibility
        face_similarity = metrics.get("face_similarity", 0.0) if isinstance(metrics, dict) else 0.0
        
        # Get model used from stage5 info
        model_used = stages_info.get("stage5", {}).get("model", "gemini-2.5-flash-image")
        if "fallback" in model_used.lower():
            model_used = "openrouter"
        elif "pro" in model_used.lower():
            model_used = "gemini-pro"
        else:
            model_used = "gemini-flash"
        
        # Create response with Flutter-compatible format
        response_data = {
            "status": "success",
            "result_image_url": result_url,
            "result_image_base64": result_base64,
            "result_url": result_url,  # Flutter expects this
            "metrics": {
                **metrics,
                "total_duration": total_duration,
                "garment_analysis": {
                    "type": garment_analysis.get("garment_type"),
                    "placement": garment_analysis.get("placement"),
                    "confidence": garment_analysis.get("confidence")
                }
            },
            "quality_scores": metrics if isinstance(metrics, dict) else {},  # Flutter expects this
            "face_similarity": face_similarity,  # Flutter expects this at top level
            "model_used": model_used,  # Flutter expects this
            "trace_id": trace_id,
            "stages": stages_info
        }
        
        return TryOnResponse(**response_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[{trace_id}] Unexpected error: {e}", exc_info=True)
        return TryOnResponse(
            status="failed",
            trace_id=trace_id,
            error=f"Unexpected error: {str(e)}",
            stage_failed="unknown"
        )


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "endpoint": "/try-on",
        "compatible_with": "flutter_app"
    }
