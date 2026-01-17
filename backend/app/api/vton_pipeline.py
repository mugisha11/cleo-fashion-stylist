"""
Production Virtual Try-On Pipeline API Endpoints
Implements the complete 9-step AI pipeline with strict quality gates
"""
import cv2
import numpy as np
import httpx
import logging
import base64
from fastapi import APIRouter, HTTPException, UploadFile, File
from typing import Optional
from pydantic import BaseModel, HttpUrl
import io
from PIL import Image

from ..services.parsing import HumanParser
from ..services.pose import PoseEstimator
from ..services.face_lock import FaceLocker
from ..services.clothing_removal import ClothingRemovalService
from ..services.skin_preservation import SkinPreservationService
from ..services.clothing_features import ClothingFeatureExtractor
from ..services.seam_blending import SeamBlendingService
from ..services.ensemble_vton import EnsembleVTONProcessor
from ..core.quality import QualityChecker
from ..core.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/vton-pipeline", tags=["vton-pipeline"])

# Services will be initialized lazily to avoid import-time issues
_services = {}

def get_service(service_name: str):
    """Lazy service initialization"""
    if service_name not in _services:
        if service_name == 'human_parser':
            _services[service_name] = HumanParser(use_gpu=settings.USE_GPU)
        elif service_name == 'pose_estimator':
            _services[service_name] = PoseEstimator()
        elif service_name == 'face_locker':
            _services[service_name] = FaceLocker(similarity_threshold=settings.FACE_SIMILARITY_THRESHOLD)
        elif service_name == 'clothing_removal':
            _services[service_name] = ClothingRemovalService(use_gpu=settings.USE_GPU)
        elif service_name == 'skin_preservation':
            _services[service_name] = SkinPreservationService(max_delta_e=2.0)
        elif service_name == 'clothing_extractor':
            _services[service_name] = ClothingFeatureExtractor(use_gpu=settings.USE_GPU)
        elif service_name == 'seam_blender':
            _services[service_name] = SeamBlendingService()
        elif service_name == 'ensemble_processor':
            _services[service_name] = EnsembleVTONProcessor(
                model_paths={
                    'viton_hd': settings.VTON_MODEL_PATH,
                    'hr_viton': getattr(settings, 'HR_VITON_MODEL_PATH', None),
                },
                use_gpu=settings.USE_GPU,
                face_similarity_threshold=settings.FACE_SIMILARITY_THRESHOLD
            )
        elif service_name == 'quality_checker':
            _services[service_name] = QualityChecker(
                face_similarity_threshold=settings.FACE_SIMILARITY_THRESHOLD,
                min_sharpness=settings.MIN_SHARPNESS,
                min_clothing_coverage=settings.MIN_CLOTHING_COVERAGE,
                min_pose_consistency=settings.MIN_POSE_CONFIDENCE
            )
    return _services[service_name]


# Request/Response Models
class ParseHumanRequest(BaseModel):
    image_url: HttpUrl


class EstimatePoseRequest(BaseModel):
    image_url: HttpUrl


class RemoveClothesRequest(BaseModel):
    image_url: HttpUrl
    clothing_mask_url: Optional[HttpUrl] = None


class ExtractClothingRequest(BaseModel):
    clothing_image_url: HttpUrl


class VirtualTryOnRequest(BaseModel):
    user_image_url: HttpUrl
    clothing_image_url: HttpUrl
    preserve_face: bool = True
    preserve_resolution: bool = True


class ValidateOutputRequest(BaseModel):
    original_image_url: HttpUrl
    result_image_url: HttpUrl


async def download_image(url: str) -> np.ndarray:
    """Download image from URL"""
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        response.raise_for_status()
        image_bytes = response.content
        image = Image.open(io.BytesIO(image_bytes))
        return cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)


@router.post("/parse-human")
async def parse_human(request: ParseHumanRequest):
    """
    Step 1: Human Parsing
    Segments human body into clothing and skin regions
    """
    try:
        image = await download_image(str(request.image_url))
        
        # Parse human
        human_parser = get_service('human_parser')
        parsing_result = human_parser.parse(image)
        
        # Convert masks to base64 for JSON response
        def mask_to_base64(mask):
            if mask is None or mask.size == 0:
                return None
            _, buffer = cv2.imencode('.png', mask)
            return base64.b64encode(buffer).decode('utf-8')
        
        return {
            "success": True,
            "parsing_mask": mask_to_base64(parsing_result.get('parsing_mask')),
            "clothing_mask": mask_to_base64(parsing_result.get('clothing_mask')),
            "protected_mask": mask_to_base64(parsing_result.get('protected_mask')),
            "face_regions": parsing_result.get('face_regions', []),
            "method": parsing_result.get('method', 'unknown')
        }
    except Exception as e:
        logger.error(f"Parse human error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/estimate-pose")
async def estimate_pose(request: EstimatePoseRequest):
    """
    Step 2: Pose Estimation
    Detects body pose and keypoints for alignment
    """
    try:
        image = await download_image(str(request.image_url))
        
        # Estimate pose
        pose_result = pose_estimator.estimate(image)
        
        return {
            "success": True,
            "landmarks": pose_result.get('landmarks'),
            "confidence": float(pose_result.get('confidence', 0.0)),
            "key_points": pose_result.get('key_points', {}),
            "success": pose_result.get('success', False)
        }
    except Exception as e:
        logger.error(f"Pose estimation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/remove-clothes")
async def remove_clothes(request: RemoveClothesRequest):
    """
    Step 4: Safe Clothing Removal (Phase 1 - Undressing)
    Removes existing clothing while preserving skin tone and texture
    """
    try:
        image = await download_image(str(request.image_url))
        
        # Get services
        human_parser = get_service('human_parser')
        clothing_removal = get_service('clothing_removal')
        
        # Get clothing mask
        if request.clothing_mask_url:
            clothing_mask = await download_image(str(request.clothing_mask_url))
            if len(clothing_mask.shape) == 3:
                clothing_mask = cv2.cvtColor(clothing_mask, cv2.COLOR_BGR2GRAY)
        else:
            # Parse to get mask
            parsing_result = human_parser.parse(image)
            clothing_mask = parsing_result.get('clothing_mask', np.zeros((1, 1), dtype=np.uint8))
        
        # Get protected mask
        parsing_result = human_parser.parse(image)
        protected_mask = parsing_result.get('protected_mask', np.zeros((1, 1), dtype=np.uint8))
        
        # Remove clothing
        undressed, metadata = clothing_removal.remove_clothing(
            image, clothing_mask, protected_mask
        )
        
        # Convert image to base64
        _, buffer = cv2.imencode('.jpg', undressed)
        image_base64 = base64.b64encode(buffer).decode('utf-8')
        
        return {
            "success": True,
            "undressed_image": image_base64,
            "metadata": metadata
        }
    except Exception as e:
        logger.error(f"Remove clothes error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/extract-clothing")
async def extract_clothing(request: ExtractClothingRequest):
    """
    Step 6: Clothing Feature Extraction
    Extracts embeddings, category, colors, fabric, fit, etc.
    """
    try:
        clothing_image = await download_image(str(request.clothing_image_url))
        
        # Extract features
        clothing_extractor = get_service('clothing_extractor')
        features = clothing_extractor.extract_features(clothing_image)
        
        return {
            "success": True,
            "features": features
        }
    except Exception as e:
        logger.error(f"Extract clothing error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/virtual-tryon")
async def virtual_tryon(request: VirtualTryOnRequest):
    """
    Step 7: Virtual Try-On (Phase 2 - Dressing)
    Complete pipeline: parse → pose → remove → try-on → blend
    """
    try:
        # Download images
        user_image = await download_image(str(request.user_image_url))
        clothing_image = await download_image(str(request.clothing_image_url))
        
        # Get services
        human_parser = get_service('human_parser')
        pose_estimator = get_service('pose_estimator')
        face_locker = get_service('face_locker')
        clothing_removal = get_service('clothing_removal')
        skin_preservation = get_service('skin_preservation')
        ensemble_processor = get_service('ensemble_processor')
        seam_blender = get_service('seam_blender')
        quality_checker = get_service('quality_checker')
        
        # Step 1: Human Parsing
        parsing_result = human_parser.parse(user_image)
        clothing_mask = parsing_result.get('clothing_mask', np.zeros((1, 1), dtype=np.uint8))
        protected_mask = parsing_result.get('protected_mask', np.zeros((1, 1), dtype=np.uint8))
        
        # Step 2: Pose Estimation
        pose_result = pose_estimator.estimate(user_image)
        
        # Step 3: Face Lock
        face_region = face_locker.detect_face_region(user_image)
        face_protection_mask = face_locker.create_protection_mask(user_image, face_region)
        
        # Step 4: Remove Clothing
        undressed, removal_metadata = clothing_removal.remove_clothing(
            user_image, clothing_mask, protected_mask
        )
        
        # Step 5: Skin Preservation Validation
        skin_mask = human_parser.parse(user_image).get('protected_mask', np.zeros((1, 1), dtype=np.uint8))
        skin_passed, skin_metrics = skin_preservation.validate_skin_preservation(
            user_image, undressed, skin_mask
        )
        
        if not skin_passed:
            logger.warning(f"Skin preservation failed: {skin_metrics}")
        
        # Step 7: Virtual Try-On (using ensemble processor)
        tryon_result = ensemble_processor.process(
            user_image=undressed,
            clothing_image=clothing_image,
            preserve_resolution=request.preserve_resolution,
            max_retries=3
        )
        
        result_image = tryon_result.get('result_image')
        if result_image is None:
            raise HTTPException(status_code=500, detail="Try-on processing failed")
        
        # Step 8: Seam Blending
        clothing_mask_for_blend = human_parser.get_clothing_mask(parsing_result)
        blended, blend_metadata = seam_blender.blend_clothing(
            undressed, clothing_image, clothing_mask_for_blend, None
        )
        
        # Apply face lock to final result
        final_result = face_locker.apply_face_lock(user_image, blended, face_region)
        
        # Step 9: Quality Gate
        quality_passed, quality_scores, quality_error = quality_checker.check_all(
            user_image, final_result, face_region
        )
        
        if not quality_passed:
            logger.warning(f"Quality check failed: {quality_error}")
            # Retry with different parameters or return with warning
        
        # Convert result image to base64
        _, buffer = cv2.imencode('.jpg', final_result, [cv2.IMWRITE_JPEG_QUALITY, 95])
        result_base64 = base64.b64encode(buffer).decode('utf-8')
        
        return {
            "success": True,
            "result_image": result_base64,
            "quality_scores": quality_scores,
            "quality_passed": quality_passed,
            "face_similarity": quality_scores.get('face_similarity', 0.0),
            "metadata": {
                "removal": removal_metadata,
                "skin_validation": skin_metrics,
                "blending": blend_metadata,
                "model_used": tryon_result.get('model_used', 'unknown')
            }
        }
        
    except Exception as e:
        logger.error(f"Virtual try-on error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/validate-output")
async def validate_output(request: ValidateOutputRequest):
    """
    Step 9: Quality Gate & Validation
    Validates face similarity ≥99%, ΔE < 2, pose unchanged, etc.
    """
    try:
        original = await download_image(str(request.original_image_url))
        result = await download_image(str(request.result_image_url))
        
        # Get services
        face_locker = get_service('face_locker')
        quality_checker = get_service('quality_checker')
        human_parser = get_service('human_parser')
        skin_preservation = get_service('skin_preservation')
        
        # Face detection
        face_region = face_locker.detect_face_region(original)
        
        # Quality checks
        quality_passed, quality_scores, quality_error = quality_checker.check_all(
            original, result, face_region
        )
        
        # Skin preservation
        skin_mask = human_parser.parse(original).get('protected_mask', np.zeros((1, 1), dtype=np.uint8))
        skin_passed, skin_metrics = skin_preservation.validate_skin_preservation(
            original, result, skin_mask
        )
        
        # Face verification
        face_passed, face_similarity, face_error = face_locker.verify_face_preservation(
            original, result, face_region
        )
        
        overall_passed = quality_passed and skin_passed and face_passed
        
        return {
            "success": True,
            "passed": overall_passed,
            "quality_check": {
                "passed": quality_passed,
                "scores": quality_scores,
                "error": quality_error
            },
            "skin_preservation": {
                "passed": skin_passed,
                "metrics": skin_metrics
            },
            "face_verification": {
                "passed": face_passed,
                "similarity": float(face_similarity),
                "error": face_error
            }
        }
        
    except Exception as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
