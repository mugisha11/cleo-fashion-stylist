"""
Try-On API Endpoints
Production-grade virtual try-on service
"""
import cv2
import numpy as np
import httpx
import logging
import time
from fastapi import APIRouter, HTTPException, BackgroundTasks
from typing import Optional

from ..models.schemas import TryOnRequest, TryOnResponse
from ..services.vton import VTONProcessor
from ..services.advanced_vton import AdvancedVTONProcessor
from ..services.ensemble_vton import EnsembleVTONProcessor
from ..services.storage import StorageService
from ..core.quality import QualityChecker
from ..core.retry import RetryHandler
from ..core.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/try-on", tags=["try-on"])

# Initialize services
# Use ensemble VTON processor for production (multi-model with fallback)
ensemble_processor = EnsembleVTONProcessor(
    model_paths={
        'viton_hd': settings.VTON_MODEL_PATH,
        'hr_viton': getattr(settings, 'HR_VITON_MODEL_PATH', None),
    },
    use_gpu=settings.USE_GPU,
    face_similarity_threshold=settings.FACE_SIMILARITY_THRESHOLD
)

# Fallback processors
advanced_processor = AdvancedVTONProcessor(
    model_path=settings.VTON_MODEL_PATH,
    use_gpu=settings.USE_GPU,
    face_similarity_threshold=settings.FACE_SIMILARITY_THRESHOLD
)

basic_processor = VTONProcessor(
    model_path=settings.VTON_MODEL_PATH,
    use_gpu=settings.USE_GPU,
    face_similarity_threshold=settings.FACE_SIMILARITY_THRESHOLD
)

# Initialize storage service only if Supabase is configured
storage_service = None
if settings.SUPABASE_URL and settings.SUPABASE_KEY:
    try:
        storage_service = StorageService(
            supabase_url=settings.SUPABASE_URL,
            supabase_key=settings.SUPABASE_KEY,
            bucket_name=settings.SUPABASE_STORAGE_BUCKET
        )
    except Exception as e:
        logger.warning(f"Failed to initialize storage service: {e}")
        storage_service = None

quality_checker = QualityChecker(
    face_similarity_threshold=settings.FACE_SIMILARITY_THRESHOLD
)

retry_handler = RetryHandler(
    max_retries=settings.MAX_RETRIES,
    base_delay=settings.RETRY_DELAY
)


async def download_image(url: str) -> np.ndarray:
    """Download image from URL"""
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        response.raise_for_status()
        
        # Decode image
        image_array = np.frombuffer(response.content, dtype=np.uint8)
        image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)
        
        if image is None:
            raise ValueError(f"Failed to decode image from {url}")
        
        return image


@router.post("", response_model=TryOnResponse)
async def process_tryon(request: TryOnRequest, background_tasks: BackgroundTasks):
    """
    Process virtual try-on with face preservation
    
    Complete pipeline:
    1. Download images
    2. Pose estimation
    3. Human parsing
    4. Face locking
    5. VTON inference
    6. Quality checks
    7. Retry if needed
    8. Upload result
    """
    try:
        # Download images
        logger.info(f"Downloading images for try-on")
        user_image = await download_image(str(request.user_image_url))
        clothing_image = await download_image(str(request.cloth_image_url))
        
        # Validate images
        if user_image is None or user_image.size == 0:
            raise HTTPException(status_code=400, detail="Invalid user image")
        if clothing_image is None or clothing_image.size == 0:
            raise HTTPException(status_code=400, detail="Invalid clothing image")
        
        # Process with retry logic
        async def process_with_quality_check():
            # Use ensemble processor (tries multiple models automatically)
            try:
                result = ensemble_processor.process(
                    user_image=user_image,
                    clothing_image=clothing_image,
                    preserve_resolution=request.preserve_resolution,
                    max_retries=settings.MAX_RETRIES
                )
            except Exception as e:
                logger.warning(f"Ensemble VTON failed, trying advanced: {e}")
                try:
                    result = advanced_processor.process(
                        user_image=user_image,
                        clothing_image=clothing_image,
                        preserve_resolution=request.preserve_resolution,
                        use_diffusion=getattr(request, 'use_diffusion', False)
                    )
                except Exception as e2:
                    logger.warning(f"Advanced VTON failed, using basic: {e2}")
                    # Final fallback to basic processor
                    result = basic_processor.process(
                        user_image=user_image,
                        clothing_image=clothing_image,
                        preserve_resolution=request.preserve_resolution
                    )
            
            if not result.get('success'):
                raise Exception(result.get('error', 'VTON processing failed'))
            
            result_image = result['result_image']
            face_region = result.get('face_region')
            model_used = result.get('model_used', 'unknown')
            quality_scores_from_result = result.get('quality_scores', {})
            
            # Additional quality check (ensemble already does this, but double-check)
            passed, scores, error_msg = quality_checker.check_all(
                original_image=user_image,
                result_image=result_image,
                face_region=face_region
            )
            
            # Merge scores from ensemble and quality checker
            merged_scores = {**quality_scores_from_result, **scores}
            
            if not passed:
                raise Exception(f"Quality check failed: {error_msg}")
            
            return result_image, merged_scores, result.get('face_similarity', 0.0), model_used
        
        # Retry until quality passes
        retry_result = await retry_handler.retry_async(
            process_with_quality_check,
            quality_check=lambda r: (r[1] is not None, "")  # Simplified check
        )
        
        # Unpack result tuple
        result_image = retry_result[0]
        quality_scores = retry_result[1]
        face_similarity = retry_result[2]
        model_used = retry_result[3] if len(retry_result) > 3 else 'unknown'
        
        # Upload result
        user_id = request.user_id or "anonymous"
        
        if storage_service is None:
            # Fallback: save to temp file and return local path
            import tempfile
            import os
            from PIL import Image
            
            temp_dir = tempfile.gettempdir()
            result_filename = f"tryon_{user_id}_{int(time.time())}.jpg"
            result_path = os.path.join(temp_dir, result_filename)
            
            # Save image
            Image.fromarray(cv2.cvtColor(result_image, cv2.COLOR_BGR2RGB)).save(result_path, quality=settings.OUTPUT_QUALITY)
            result_url = f"file://{result_path}"
            session_id = f"temp_{int(time.time())}"
            
            logger.warning("Supabase not configured - using temporary file storage")
        else:
            result_url = storage_service.upload_image(
                image=result_image,
                user_id=user_id,
                image_type="tryon_result",
                quality=settings.OUTPUT_QUALITY
            )
            
            if result_url is None:
                raise HTTPException(status_code=500, detail="Failed to upload result")
            
            # Save metadata
            original_url = str(request.user_image_url)
            clothing_url = str(request.cloth_image_url)
            session_id = storage_service.save_tryon_metadata(
                user_id=user_id,
                original_image_url=original_url,
                clothing_image_url=clothing_url,
                result_image_url=result_url,
                metadata={
                    'face_similarity': face_similarity,
                    'quality_scores': quality_scores,
                    'source': request.source.value,
                    'preserve_face': request.preserve_face,
                    'preserve_resolution': request.preserve_resolution
                }
            )
        
        # Prepare quality scores with model info
        final_quality_scores = quality_scores or {}
        if isinstance(final_quality_scores, dict):
            final_quality_scores['model_used'] = model_used
        
        return TryOnResponse(
            success=True,
            result_url=result_url,
            session_id=session_id,
            face_similarity=face_similarity,
            quality_scores=final_quality_scores
        )
        
    except Exception as e:
        logger.error(f"Try-on error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Try-on processing failed: {str(e)}"
        )


@router.get("/status/{session_id}")
async def get_tryon_status(session_id: str):
    """Get try-on session status"""
    try:
        # Query Supabase for session
        # TODO: Implement status check
        return {
            "session_id": session_id,
            "status": "completed"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
