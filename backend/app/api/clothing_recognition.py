"""
Clothing Recognition API Endpoint
Processes uploaded clothing images and extracts fashion attributes
"""
import logging
import tempfile
import os
from pathlib import Path
from typing import Optional
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from fastapi.responses import JSONResponse
import aiofiles
from PIL import Image
import numpy as np
import cv2

from ..models.schemas import ClothingRecognitionRequest, ClothingRecognitionResponse
import torch
from ..services.clothing_recognition import ClothingRecognitionPipeline
from ..services.storage import StorageService
from ..core.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/clothing", tags=["clothing-recognition"])

# Initialize pipeline (lazy load models)
_pipeline: Optional[ClothingRecognitionPipeline] = None


def get_pipeline() -> ClothingRecognitionPipeline:
    """Get or create recognition pipeline"""
    global _pipeline
    if _pipeline is None:
        device = "cuda" if settings.USE_GPU and torch.cuda.is_available() else "cpu"
        _pipeline = ClothingRecognitionPipeline(
            device=device,
            min_confidence=0.6,
            max_retries=settings.MAX_RETRIES
        )
    return _pipeline


@router.post("/recognize", response_model=ClothingRecognitionResponse)
async def recognize_clothing(
    file: UploadFile = File(..., description="Clothing image file"),
    user_id: Optional[str] = None,
    store_result: bool = True
):
    """
    Recognize clothing from uploaded image
    
    - **file**: Image file (JPEG, PNG, WebP)
    - **user_id**: Optional user ID for storing results
    - **store_result**: Whether to store result in Supabase
    
    Returns structured clothing attributes including:
    - Category and subcategory
    - Colors and patterns
    - Fit and occasion
    - Style and confidence scores
    """
    # Validate file type
    allowed_types = ["image/jpeg", "image/png", "image/webp", "image/jpg"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {', '.join(allowed_types)}"
        )
    
    # Create temp file
    temp_dir = Path(settings.TEMP_DIR)
    temp_dir.mkdir(parents=True, exist_ok=True)
    
    temp_path = None
    try:
        # Save uploaded file
        suffix = Path(file.filename).suffix if file.filename else ".jpg"
        temp_path = temp_dir / f"clothing_{os.urandom(8).hex()}{suffix}"
        
        async with aiofiles.open(temp_path, 'wb') as f:
            content = await file.read()
            await f.write(content)
        
        # Validate image
        try:
            img = Image.open(temp_path)
            img.verify()
            img = Image.open(temp_path)  # Reopen after verify
        except Exception as e:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid image file: {str(e)}"
            )
        
        # Check image size
        img_array = np.array(img)
        if img_array.size == 0:
            raise HTTPException(status_code=400, detail="Empty image")
        
        # Process through pipeline
        pipeline = get_pipeline()
        
        # Process image (synchronous function, run in thread pool)
        import asyncio
        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(
            None,
            pipeline.process,
            str(temp_path)
        )
        
        # Store in Supabase if requested
        result_id = None
        if store_result and settings.SUPABASE_URL and settings.SUPABASE_KEY:
            try:
                storage_service = StorageService(
                    supabase_url=settings.SUPABASE_URL,
                    supabase_key=settings.SUPABASE_KEY,
                    bucket_name="wardrobe-recognition"
                )
                
                # Upload original image
                # Read and decode image
                img_cv = cv2.imread(str(temp_path))
                if img_cv is None:
                    raise Exception("Failed to read image file")
                
                image_url = storage_service.upload_image(
                    image=img_cv,
                    user_id=user_id or 'anonymous',
                    image_type='recognition',
                    quality=95
                )
                
                # Store recognition result in Supabase database
                from supabase import create_client
                supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
                
                recognition_data = {
                    "user_id": user_id,
                    "image_url": image_url,
                    "category": result["category"],
                    "subcategory": result.get("subcategory"),
                    "colors": result["colors"],
                    "patterns": result["patterns"],
                    "fit": result.get("fit"),
                    "occasion": result["occasion"],
                    "style": result.get("style"),
                    "confidence": result["confidence"],
                    "metadata": result.get("metadata", {})
                }
                
                db_result = supabase.table("clothing_recognitions").insert(recognition_data).execute()
                if db_result.data:
                    result_id = db_result.data[0].get("id")
                
                result["image_url"] = image_url
                result["result_id"] = result_id
                
            except Exception as e:
                logger.warning(f"Failed to store result in Supabase: {e}")
                # Continue without storing
        
        return ClothingRecognitionResponse(
            success=True,
            **result
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing clothing recognition: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process image: {str(e)}"
        )
    finally:
        # Cleanup temp file
        if temp_path and temp_path.exists():
            try:
                temp_path.unlink()
            except Exception as e:
                logger.warning(f"Failed to delete temp file: {e}")


@router.post("/recognize-url", response_model=ClothingRecognitionResponse)
async def recognize_clothing_from_url(
    request: ClothingRecognitionRequest
):
    """
    Recognize clothing from image URL
    
    - **image_url**: URL of clothing image
    - **user_id**: Optional user ID
    - **store_result**: Whether to store result
    
    Downloads image from URL and processes it.
    """
    import httpx
    
    temp_path = None
    try:
        # Download image
        async with httpx.AsyncClient() as client:
            response = await client.get(request.image_url, timeout=30.0)
            response.raise_for_status()
            
            # Save to temp file
            temp_dir = Path(settings.TEMP_DIR)
            temp_dir.mkdir(parents=True, exist_ok=True)
            
            suffix = Path(request.image_url).suffix or ".jpg"
            temp_path = temp_dir / f"clothing_url_{os.urandom(8).hex()}{suffix}"
            
            async with aiofiles.open(temp_path, 'wb') as f:
                await f.write(response.content)
        
        # Process same as file upload
        pipeline = get_pipeline()
        
        # Process image (synchronous function, run in thread pool)
        import asyncio
        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(
            None,
            pipeline.process,
            str(temp_path)
        )
        
        # Store if requested
        if request.store_result and settings.SUPABASE_URL and settings.SUPABASE_KEY:
            try:
                from supabase import create_client
                supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
                
                recognition_data = {
                    "user_id": request.user_id,
                    "image_url": request.image_url,
                    "category": result["category"],
                    "subcategory": result.get("subcategory"),
                    "colors": result["colors"],
                    "patterns": result["patterns"],
                    "fit": result.get("fit"),
                    "occasion": result["occasion"],
                    "style": result.get("style"),
                    "confidence": result["confidence"],
                    "metadata": result.get("metadata", {})
                }
                
                db_result = supabase.table("clothing_recognitions").insert(recognition_data).execute()
                if db_result.data:
                    result["result_id"] = db_result.data[0].get("id")
                
            except Exception as e:
                logger.warning(f"Failed to store result: {e}")
        
        return ClothingRecognitionResponse(
            success=True,
            **result
        )
        
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Failed to download image: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Error processing URL: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process image: {str(e)}"
        )
    finally:
        if temp_path and temp_path.exists():
            try:
                temp_path.unlink()
            except Exception:
                pass


@router.get("/health")
async def health_check():
    """Health check for clothing recognition service"""
    try:
        pipeline = get_pipeline()
        return {
            "status": "healthy",
            "device": pipeline.device,
            "models_loaded": {
                "segmenter": pipeline.segmenter.yolo_model is not None,
                "classifier": pipeline.classifier.model is not None
            }
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e)
        }
